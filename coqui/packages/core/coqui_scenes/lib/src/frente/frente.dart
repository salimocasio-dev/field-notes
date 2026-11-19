// Port of historia/escenas/frente.js: the scene "El frente", the front of grandma's house (order 14). Line for line,
// minus its background function `bg` and minus what the sheet's `dropped` list says is dropped; every screen position
// replaced by what the sheet's `code` list gives for that line (frente_places.dart). frente.js was written before the
// kit and is ported as it is, not onto `Escena`.
//
// The old file's names are kept, Spanish ones and capitals included, so the port reads line for line against it
// (page 12, sections 4 and 6): the lints on names are off in this file.
// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'dart:async';
import 'dart:math' as math;

import 'package:coqui_pixel/coqui_pixel.dart' hide AVK, mkAve;
import 'package:coqui_scenes/src/frente/frente_places.dart';
import 'package:coqui_scenes/src/frente/frente_set.dart';
import 'package:coqui_scenes/src/scene_set.dart';
import 'package:coqui_scenes/src/sheet_cache.dart';

/// The scene "frente", made from its sheet (the registry's factory: the sheet must be read first, `loadScene`).
Scene createFrente() => Frente(sheetOf('frente'));

// "#RRGGBB" as 0xFFBBGGRR, once (page 12, section 6)
int _hex(String h) =>
    0xFF000000 |
    (int.parse(h.substring(5, 7), radix: 16) << 16) |
    (int.parse(h.substring(3, 5), radix: 16) << 8) |
    int.parse(h.substring(1, 3), radix: 16);

// JavaScript: Math.round
int _round(num v) => (v + 0.5).floor();

const int _white = 0xFFFFFFFF;
final int _pink = _hex('#FF8FB8'),
    _yellowFly = _hex('#FFE070'),
    _rainC = _hex('#C4DCF6'),
    _rainFar = _hex('#DCEBFA'),
    _towelBlue = _hex('#3A86E6'),
    _drop = _hex('#8CC4F8'),
    _steam = _hex('#E8F0F8'),
    _dust = _hex('#E8DCC0'),
    _bolt = _hex('#FFF4B0'),
    _crumb = _hex('#E0B060'),
    _birdBelly = _hex('#E8F4FF'),
    _birdEye = _hex('#20140A');

/// "rgba(255,255,255,.5)": the flash (.5 of 255, rounded).
const int _flashC = 0x80FFFFFF;

/* ---------- the picture ---------- */
// frente.js: bg -> the set (frente_set.dart), as the sheet says (dropped: frente.js:140)

// small living things, so the place is never still

// frente.js: mkCloud
Sprite mkCloud() {
  final b = Buf(40, 15);
  b.ell(20, 9, 13, 5, RP.cloud);
  b.ell(11, 10, 8, 4, RP.cloud);
  b.ell(30, 10, 9, 4, RP.cloud);
  b.ell(22, 5, 7, 4.5, RP.cloud);
  return b.done();
}

// frente.js: FLY
const List<List<String>> FLY = [
  ['pp...pp', 'ppp.ppp', '.ppdpp.', '..pdp..', '...d...'],
  ['.......', 'ppp.ppp', 'pppdppp', '.ppdpp.', '...d...'],
];

// frente.js: fly
void fly(Ctx g, num x, num y, int col, int fl) {
  final rows = FLY[fl];
  for (var j = 0; j < rows.length; j++) {
    final rw = rows[j];
    for (var i = 0; i < rw.length; i++) {
      final ch = rw[i];
      if (ch != '.') fr(g, x + i, y + j, 1, 1, ch == 'd' ? OUT : col);
    }
  }
}

// the storm cloud: the thing at stake when rain is coming
// frente.js: NB
final List<int> NB = [
  _hex('#2E3848'),
  _hex('#414C60'),
  _hex('#566378'),
  _hex('#6E7B90'),
  _hex('#8A96A8'),
];

// frente.js: mkNube
Sprite mkNube() {
  final b = Buf(98, 22);
  b.ell(49, 13, 34, 7, NB);
  b.ell(23, 14, 19, 6, NB);
  b.ell(75, 14, 19, 6, NB);
  b.ell(38, 8, 16, 6, NB);
  b.ell(60, 8, 15, 6, NB);
  return b.outline().done();
}

// frente.js: BOLT
const List<String> BOLT = [
  '..##',
  '..#.',
  '.##.',
  '###.',
  '.##.',
  '.#..',
  '##..',
  '#...',
];

// frente.js: TOWEL
const List<String> TOWEL = [
  '...####....',
  '..######...',
  '.#########.',
  '###########',
  '#bbbbbbbbb#',
  '###########',
];

// frente.js: towel
// wrapped on top of his head, like after a bath
void towel(Ctx g, num x, num y) {
  for (var j = 0; j < TOWEL.length; j++) {
    final rw = TOWEL[j];
    for (var i = 0; i < rw.length; i++) {
      if (rw[i] != '.') fr(g, x + i - 1, y + j - 1, 3, 3, OUT);
    }
  }
  for (var j = 0; j < TOWEL.length; j++) {
    final rw = TOWEL[j];
    for (var i = 0; i < rw.length; i++) {
      if (rw[i] != '.') {
        fr(g, x + i, y + j, 1, 1, rw[i] == 'b' ? _towelBlue : _white);
      }
    }
  }
}

/* ---------- story 2: the cake, its plate, and the bird ---------- */

// frente.js: SPONGE, FROST
final int SPONGE = _hex('#F2D08A'), FROST = _hex('#FF8FB8');

// frente.js: mkAve (El frente's own bird, with a wing over its eyes: "tapa")
Sprite mkAve(String st, int fl) {
  final R = st == 'round',
      b = Buf(R ? 24 : 18, R ? 18 : 14),
      B = RP.blue,
      cx = R ? 11 : 8,
      cy = R ? 10 : 8;
  b.cap(cx - 6, cy - 1, cx - 9, cy - 3, 1.2, [B[1]]);
  b.ell(cx, cy, R ? 8 : 5.5, R ? 6.5 : 4.2, B);
  b.ell(cx - 1, cy + (R ? 2.5 : 1.5), R ? 5 : 3.4, R ? 3.4 : 2.2, [_birdBelly]);
  b.ell(cx + (R ? 6 : 5), cy - (R ? 4 : 3), R ? 3.8 : 3.3, R ? 3.6 : 3.1, B);
  if (st == 'sleep' || R) {
    b.rect(cx + (R ? 6 : 5), cy - (R ? 4 : 3), 2, 1, OUT);
  } else {
    b.px(cx + 6, cy - 4, _white);
    b.px(cx + 6, cy - 3, _birdEye);
    b.px(cx + 7, cy - 3, _birdEye);
  }
  b.rect(cx + (R ? 9 : 8), cy - (R ? 4 : 3), R ? 3 : 2, R ? 2 : 1, RP.yel[2]);
  b.px(cx + (R ? 9 : 8), cy - (R ? 2 : 2), RP.orng[2]);
  if (st == 'tapa') {
    b.cap(cx - 1, cy, cx + 6, cy - 4, 1.8, [
      B[0],
      B[1],
    ]); // a wing over its own eyes
  } else if (fl != 0) {
    b.ell(cx - 1, cy - 4, 3.6, 2, [B[0], B[1]]);
  } else {
    b.ell(cx - 1, cy + 1, 3.6, 2, [B[0], B[1]]);
  }
  if (!R) {
    b.px(cx - 1, cy + 4, RP.orng[1]);
    b.px(cx + 2, cy + 4, RP.orng[1]);
  }
  return b.outline().done();
}

// frente.js: AVK. The bird is drawn bigger than its pixels, so it reads at phone size
const double AVK = 1.6;

/* ---------- story 3: hide and seek. A small palm, a birdhouse on a post, late afternoon ---------- */
// frente.js: mkCasita, mkPalmita -> the set (their only callers, frente.js:97, :100, :122, :125, are dropped)

// frente.js: dish
// a round white plate
void dish(Ctx g, num x, num y, num w) {
  g.fillStyle = OUT;
  g.beginPath();
  g.ellipse(x + w / 2, y + 5, w / 2 + 1, 6, 0, 0, 7);
  g.fill();
  g.fillStyle = _white;
  g.beginPath();
  g.ellipse(x + w / 2, y + 5, w / 2, 5, 0, 0, 7);
  g.fill();
  g.fillStyle = RP.grey[3];
  g.beginPath();
  g.ellipse(x + w / 2, y + 5, w / 2 - 6, 2.6, 0, 0, 7);
  g.fill();
}

/// The scene "El frente" (frente.js: `ESCENAS.frente`). Its set is [FrenteSet]; this is the sprite layer and what can
/// happen here.
class Frente extends SetScene {
  Frente(this.sheet) {
    _p = FrentePlaces(sheet, frenteEngine());
    final p = _p;
    ABAT = {
      'puerta': p.abuela('abuela.puerta'),
      'ventana': p.pt('abuela.ventana'),
      'paso': p.abuela('abuela.paso'),
    };
    _abVentanaMesa = p.pt('abuela.ventana.mesa');
    PERCH = {
      'ventana': p.pt('ave.ventana.posa'),
      'puerta': p.pt('ave.puerta.posa'),
    };
    HOLE = {
      'ventana': p.pt('ave.ventana.hueco'),
      'puerta': p.pt('ave.puerta.hueco'),
    };
    SPOT = {
      'palma_grande': p.pt('ave.palma'),
      'palma_pequena': p.pt('ave.palmita'),
      'casa_pequena': p.pt('ave.casita'),
      'casa_grande': p.pt('ave.puerta.hueco'),
    };
    LUGAR = {for (final k in sheet.lugar.keys) k: sheet.lugarOf(k, p.e)};
    CAM = {
      for (final k in const ['wide', 'casa', 'puerta', 'ventana', 'cuadro'])
        k: p.view(k),
    };
    _handAt = {
      'casa': p.ptRound('mano.casa'),
      'puerta': p.ptRound('mano.puerta'),
      'ventana': p.ptRound('mano.ventana'),
      'casa_grande': p.ptRound('mano.casa'),
      'casa_pequena': p.ptRound('mano.casa_pequena'),
      'palma_grande': p.ptRound('mano.palma_grande'),
      'palma_pequena': p.ptRound('mano.palma_pequena'),
    };
    _handAbuela = p.ptRound('mano.puerta');
    heartAt = p.pt('corazon');
    _boxes = {
      for (final k in const [
        'palma_grande',
        'palma_pequena',
        'casa_pequena',
        'casa_grande',
        'casa',
        'puerta',
        'ventana',
      ])
        k: p.box(k),
    };
    _hits = {
      for (final k in const [
        'palma_pequena',
        'casa_pequena',
        'palma_grande',
        'casa_grande',
        'puerta',
        'ventana',
        'casa',
        'palma',
      ])
        k: p.hitBox(k),
    };
    _sol = sheet.things['sol']!.screen!.circle;
    final plato = sheet.frames['abuela.plato']!;
    _platoAt = p.via('abuela.plato', plato.old[0], plato.old[1]);
  }

  @override
  final Sheet sheet;

  late final FrentePlaces _p;

  /// frente.js: `SW`, `SH`.
  @override
  int get SW => 240;
  @override
  int get SH => 216;

  @override
  String get id => 'frente';

  @override
  PpEngine newEngine({bool still = false}) => frenteEngine(still: still);

  @override
  PpEngine get projection => _p.e;

  // the old file's globals, through the host
  Map<String, dynamic> get W => host.W;
  int get F => host.F;

  Map<String, dynamic> _q() => W['cq'] as Map<String, dynamic>;

  // frente.js: ABAT (sheet: spot abuela.puerta, point abuela.ventana, spot abuela.paso)
  late final Map<String, List<num>> ABAT;
  late final List<num> _abVentanaMesa;

  // frente.js: PERCH, HOLE (sheet: points ave.*.posa, ave.*.hueco)
  late final Map<String, List<num>> PERCH;
  late final Map<String, List<num>> HOLE;

  // frente.js: SPOT, where the bird hides in each (sheet: points ave.palma, ave.palmita, ave.casita, ave.puerta.hueco)
  late final Map<String, List<num>> SPOT;

  // frente.js: LUGAR (sheet: lugar)
  late final Map<String, List<num>> LUGAR;

  // frente.js: NX, where the storm cloud stands at each step (sky: unchanged)
  static const List<num> NX = [22, 76, 140];

  @override
  late final Map<String, List<num>> CAM;

  @override
  late final List<num> heartAt;

  late final Map<String, List<int>> _handAt;
  late final List<int> _handAbuela;
  late final Map<String, List<int>> _boxes, _hits;
  late final List<num> _sol;
  late final List<num> _platoAt;

  @override
  Map<String, List<num>> get lugar => LUGAR;

  /// El frente has no kit and no list of things (frente.js has no `cosas`).
  @override
  List<Thing> get cosas => const [];

  @override
  Map<String, dynamic> fresh(Map<String, dynamic> story) => {
    'trozo': null,
    'hojas': null,
    'asoma': 0,
    'escondite': 0,
    'rustle': null,
    'abierto': null,
    'piernas': 0,
    'dusk': 0,
    'rondas': 0,
    'mios': 0,
    'tapado': 0,
    'ave': null,
    'plato': null,
    'mesa': 0,
    'abIn': null,
    'caliente': 0,
    'door': 0,
    'win': 0,
    'lamp': 0,
    'peek': 0,
    'ab': null,
    'storm': 0,
    'nube': null,
    'nube2': null,
    'nube3': null,
    'dark': 0,
    'rain': 0,
    'wet': 0,
    'gotas': 0,
    'flash': 0,
    'dentro': null,
    'tab': null,
    'shake': 0,
  };

  /* ---------- the set ---------- */

  // the sheet's setKey table, from W (setKey.params.*.fromW, written here as the table gives it)
  @override
  String setKey(Map<String, dynamic> W) {
    final door = W['door'] == 1
        ? 'open'
        : W['door'] == .5
        ? 'half'
        : 'shut';
    final win = jsTruthy(W['win']) ? 'open' : 'shut';
    final lights = jsTruthy(W['lamp']);
    final dark = (W['dark'] as num?) ?? 0;
    final sky = W['dusk'] == 2
        ? 'sunset'
        : W['dusk'] == 1
        ? 'dusk'
        : dark >= .33 || jsTruthy(W['rain'])
        ? 'rain'
        : dark >= .27
        ? 'storm2'
        : jsTruthy(W['storm']) || dark > 0
        ? 'storm'
        : 'day';
    final hide = jsTruthy(W['escondite']);
    final rustle = hide && jsTruthy(W['rustle'])
        ? W['rustle'] as String
        : 'none';
    final side = (F >> 1) % 2 != 0 ? 1 : -1;
    return FrenteState(
      door: door,
      win: win,
      lights: lights,
      sky: sky,
      hide: hide,
      rustle: rustle,
      side: rustle == 'none' ? 1 : side,
    ).key;
  }

  @override
  void buildSetFor(PpEngine e, PpBuild b, String key) =>
      FrenteSet(e, b, FrenteState.fromKey(key)).buildSet();

  // the sheet's shadows: coqui and abuela (cast as its `cast` text says: the frog at .3 with his radius; abuela from
  // .3 to 2 in steps of .35 over her spot, her spot's height added). A character casts only while more than half faded
  // in, as frente-preview.html does it (`q.al > .5`, `W.ab.al == null || W.ab.al > .5`): the sheet's `when` text does
  // not say so, the preview is what the readers saw.
  @override
  List<ShadowCast> shadows(Map<String, dynamic> W) {
    final out = <ShadowCast>[];
    final e = _p.e, sh = sheet.shadows;
    final q = W['cq'] as Map<String, dynamic>?;
    // coqui: W.cq.vis, more than half in, and he is not in the window (W.tab); at the ground under his feet
    if (q != null &&
        jsTruthy(q['vis']) &&
        !jsTruthy(W['tab']) &&
        _moreThanHalf(q['al'])) {
      final b = frogBox(q),
          g = e.unproject(b.x + b.w / 2, (q['y'] as num) + 25);
      out.add((x: g.x, y: g.y, z: .3, r: sh['coqui']!.radius));
    }
    // abuela: W.ab with en puerta or paso, with no `al` or more than half in; at her spot
    final ab = W['ab'] as Map<String, dynamic>?;
    if (ab != null &&
        (ab['en'] == 'puerta' || ab['en'] == 'paso') &&
        (ab['al'] == null || _moreThanHalf(ab['al']))) {
      final s = sheet.spots['abuela.${ab['en']}']!.world,
          r = sh['abuela']!.radius;
      for (num z = .3; z <= 2; z += .35) {
        out.add((x: s[0], y: s[1], z: (z + s[2]).toDouble(), r: r));
      }
    }
    return out;
  }

  // JavaScript: `al > .5` (a missing `al` is not more than half)
  static bool _moreThanHalf(Object? al) => al is num && al > .5;

  /* ---------- small living things ---------- */

  // frente.js: ambient
  void ambient(Ctx g) {
    g.drawImage(
      host.lib.spr('cloud', mkCloud),
      _round(250 - (F / 4).remainder(310)),
      0,
    );
    final m1 = _p.pt('mariposa.1'), m2 = _p.pt('mariposa.2');
    fly(
      g,
      _round(m1[0] + 34 * math.sin(F / 41) + 6 * math.sin(F / 7)),
      _round(m1[1] + 9 * math.sin(F / 29) + 3 * math.sin(F / 5)),
      _pink,
      (F >> 1) % 2,
    );
    fly(
      g,
      _round(m2[0] + 13 * math.sin(F / 33 + 2) + 4 * math.sin(F / 6)),
      _round(m2[1] + 7 * math.sin(F / 19) + 2 * math.sin(F / 4)),
      _yellowFly,
      ((F >> 1) + 1) % 2,
    );
  }

  // frente.js: rain
  void rain(Ctx g) {
    for (var i = 0; i < 64; i++) {
      final x = (i * 61 + F * 3) % SW, y = (i * 97 + F * 13) % SH;
      fr(g, x, y, 1, 4, _rainC);
      fr(g, x - 1, y + 4, 1, 2, _rainC);
    }
    for (var i = 0; i < 9; i++) {
      final x = (i * 83 + ((F >> 1) * 37)) % SW,
          y = 126 + ((i * 29 + (F >> 1) * 11) % 84);
      fr(g, x - 2, y, 5, 1, _rainFar);
    }
  }

  // frente.js: mesa
  // a table inside, with the cake on it (frame ventana.lado)
  void mesa(Ctx c) {
    final o = _p.off('ventana.lado'), ox = o[0], oy = o[1];
    fr(c, 108 + ox, 75 + oy, 20, 2, RP.wood[3]);
    fr(c, 108 + ox, 77 + oy, 20, 1, RP.wood[0]);
    fr(c, 110 + ox, 78 + oy, 2, 3, RP.wood[1]);
    fr(c, 124 + ox, 78 + oy, 2, 3, RP.wood[1]);
    fr(c, 111 + ox, 74 + oy, 14, 1, _white);
    fr(c, 112 + ox, 68 + oy, 12, 6, SPONGE);
    fr(c, 112 + ox, 67 + oy, 12, 2, FROST);
    fr(c, 111 + ox, 67 + oy, 1, 7, OUT);
    fr(c, 124 + ox, 67 + oy, 1, 7, OUT);
    fr(c, 112 + ox, 66 + oy, 12, 1, OUT);
    fr(c, 117 + ox, 65 + oy, 2, 2, RP.red[2]);
    // steam: it is hot
    if (jsTruthy(W['caliente'])) {
      for (var k = 0; k < 3; k++) {
        for (var j = 0; j < 3; j++) {
          final y = 64 - j * 3 - ((F >> 1) + k * 2) % 3,
              x = 113 + k * 4 + (((F >> 2) + j + k) % 2);
          fr(c, x + ox, y + oy, 2, 2, j == 2 ? _steam : _white);
        }
      }
    }
  }

  // frente.js: avePos
  List<num> avePos(Map<String, dynamic> v) {
    if (v['mode'] == 'head' && jsTruthy(W['tapado'])) {
      final q = _q(), b = host.frogBox(q);
      return [b.x + b.w / 2, b.y + _round(q['dy'] as num) + 19];
    }
    if (v['mode'] == 'circle') {
      return [
        _round(150 + 56 * math.cos(F / 13)),
        _round(22 + 7 * math.sin(F / 13 * 2)),
      ];
    }
    if (v['mode'] == 'head') {
      final q = _q(), b = host.frogBox(q);
      return [b.x + b.w / 2, b.y + _round(q['dy'] as num) + 2];
    }
    return [_round(v['x'] as num), _round(v['y'] as num)];
  }

  // frente.js: drawAve
  void drawAve(Ctx c, Map<String, dynamic>? v) {
    if (v == null || v['mode'] == 'none') return;
    final p = avePos(v),
        st = jsTruthy(v['st']) ? v['st'] as String : 'n',
        fl = (v['mode'] == 'circle' || v['mode'] == 'fly') ? (F >> 1) % 2 : 0,
        im = host.lib.spr(
          'ave$st$fl',
          () => mkAve(st == 'round' ? 'round' : st, fl),
        ),
        w = im.w,
        h = im.h,
        dir = v['mode'] == 'circle'
            ? (math.sin(F / 13) > 0 ? -1 : 1)
            : (jsTruthy(v['dir']) ? v['dir'] as num : 1),
        H = _round(h * AVK);
    c.save();
    c.smoothing = false;
    c.translate(p[0].toDouble(), (p[1] - H + 2).toDouble());
    c.scale(dir * AVK, AVK);
    c.drawImage(im, -_round(w / 2), 0);
    c.restore();
    if (jsTruthy(v['slice'])) {
      final sx = p[0] + (dir < 0 ? -19 : 11), sy = p[1] - 14;
      fr(c, sx - 1, sy - 1, 9, 7, OUT);
      fr(c, sx, sy, 7, 5, SPONGE);
      fr(c, sx, sy, 7, 2, FROST);
    }
    if (st == 'round') {
      // z: asleep
      final z = (F >> 3) % 3, zx = p[0] + 12 + z * 2, zy = p[1] - H - 4 - z * 2;
      fr(c, zx, zy, 4, 1, _white);
      fr(c, zx + 3, zy + 1, 1, 1, _white);
      fr(c, zx + 2, zy + 2, 1, 1, _white);
      fr(c, zx + 1, zy + 3, 1, 1, _white);
      fr(c, zx, zy + 4, 4, 1, _white);
    }
    if (st == 'feliz' && (F >> 2) % 2 != 0) {
      fr(c, p[0] - 2, p[1] - H - 5, 2, 2, _pink);
      fr(c, p[0] + 1, p[1] - H - 5, 2, 2, _pink);
      fr(c, p[0] - 1, p[1] - H - 3, 3, 2, _pink);
    }
  }

  // frente.js: escondite
  void escondite(Ctx c, int a) {
    final R = W['rustle'];
    // frente.js: `sh` (the rustling prop one pixel to the side) and `op` (W.abierto, read and never used): their only
    // readers were the two lines below that the set now draws
    // the small palm, front right: frente.js:97 -> the set (hide=1, rustle palma)

    // the birdhouse on its post, front left: frente.js:100 -> the set (hide=1, rustle casa)
    // the frog's legs sticking out (frame casita)
    if (jsTruthy(W['piernas'])) {
      final o = _p.off('casita');
      fr(c, 70 + o[0], 130 + o[1], 2, 6, RP.tan[2]);
      fr(c, 75 + o[0], 130 + o[1], 2, 6, RP.tan[2]);
      fr(c, 69 + o[0], 135 + o[1], 4, 2, RP.tan[4]);
      fr(c, 74 + o[0], 135 + o[1], 4, 2, RP.tan[4]);
    }
    // leaves rustle (frames palma, palmita)
    if (jsTruthy(R) && (R == 'palma' || R == 'todo') && (F >> 1) % 2 != 0) {
      final o = _p.off('palma'), o2 = _p.off('palmita');
      fr(c, 44 + o[0], 40 + o[1], 2, 2, RP.grn[4]);
      fr(c, 80 + o[0], 46 + o[1], 2, 2, RP.grn[4]);
      fr(c, 180 + o2[0], 120 + o2[1], 2, 2, RP.grn[4]);
      fr(c, 208 + o2[0], 126 + o2[1], 2, 2, RP.grn[4]);
    }
  }

  // frente.js: plato
  // the plates: the frog's slices on the left, the bird's on the right
  void plato(Ctx g, num x, num y, num n, String who) {
    final ic = who == 'cq'
            ? host.lib.spr('cq.7_0', () => mkCoqui(.7, 0, false))
            : host.lib.spr('aven0', () => mkAve('n', 0)),
        iw = ic.w,
        ix = who == 'cq' ? x : x + 3 * 17 + 4;
    g.drawImage(ic, ix, y + 6);
    final px = who == 'cq' ? x + iw + 4 : x;
    dish(g, px - 3, y + 18, 3 * 17 + 6);
    for (var i = 0; i < 3; i++) {
      final sx = px + 1 + i * 17;
      if (i < n) {
        fr(g, sx - 1, y + 1, 15, 20, OUT);
        fr(g, sx, y + 8, 13, 12, SPONGE);
        fr(g, sx, y + 2, 13, 6, FROST);
        fr(g, sx + 5, y - 1, 3, 3, RP.red[2]);
      }
    }
  }

  // frente.js: hud
  // the plate at stake, always in the same corner of the screen (display: unchanged)
  @override
  void hud(Ctx c, Map<String, dynamic> W, int a) {
    final g = c;
    if (jsTruthy(W['rondas'])) {
      plato(g, 5, 6, (W['mios'] as num?) ?? 0, 'cq');
      plato(g, host.DW - 3 * 17 - 26, 6, (W['lost'] as num?) ?? 0, 'ave');
      return;
    }
    if (W['plato'] == null) return;
    const x = 5, y = 5;
    // the second copies of the hide-and-seek helpers that stand here in frente.js (lines 113 to 134) are never called
    // from hud; its plate is the one dish() above
    // the plate at stake, in the corner of the screen, at double size
    dish(g, x - 3, y + 19, 62);
    final n = W['plato'] as num;
    for (var i = 0; i < 3; i++) {
      final sx = x + 3 + i * 19;
      if (i < n) {
        fr(g, sx - 1, y + 1, 16, 21, OUT);
        fr(g, sx, y + 8, 14, 13, SPONGE);
        fr(g, sx, y + 2, 14, 6, FROST);
        fr(g, sx + 5, y - 1, 4, 4, RP.red[2]);
        fr(g, sx + 6, y - 2, 2, 1, OUT);
        fr(g, sx, y + 13, 14, 1, _crumb);
      } else {
        fr(g, sx + 3, y + 19, 3, 2, SPONGE);
        fr(g, sx + 9, y + 20, 2, 1, SPONGE);
        fr(g, sx + 6, y + 18, 1, 1, FROST);
      }
    }
  }

  // frente.js: draw
  @override
  void draw(Ctx c, Map<String, dynamic> W, int a) {
    final q = W['cq'] as Map<String, dynamic>;
    Sprite AB(String pose, int op) =>
        host.lib.spr('ab$pose$op', () => mkAbuela(pose, op != 0));
    // frente.js:140 c.drawImage(bg) -> the set, for setKey(W)
    if (!jsTruthy(W['storm']) && !jsTruthy(W['dusk'])) ambient(c);
    if (jsTruthy(W['escondite'])) escondite(c, a);
    final e = _p.e;
    // the frog peeks out from behind the door (clip puerta.hueco; point cq.asoma)
    if (jsTruthy(W['asoma']) && W['door'] == .5) {
      c.save();
      clipToWorld(c, e, _p.clipWorld('puerta.hueco'));
      final at = _p.pt('cq.asoma');
      c.drawImage(
        host.lib.spr('cq.6_0', () => mkCoqui(.6, 0, false)),
        at[0],
        at[1],
      );
      c.restore();
    }
    // she is behind the door as it opens (clip puerta.hueco; spot abuela.puerta)
    if (jsTruthy(W['peek']) && W['door'] == .5) {
      c.save();
      clipToWorld(c, e, _p.clipWorld('puerta.hueco'));
      c.drawImage(AB('idle', 0), ABAT['puerta']![0], ABAT['puerta']![1]);
      c.restore();
    }
    final ab = W['ab'] as Map<String, dynamic>?;
    if (ab != null) {
      final pose = ab['pose'] == 'wave'
          ? 'wave${a % 2}'
          : ab['pose'] == 'dedo'
          ? 'dedo${(a >> 1) % 2}'
          : (jsTruthy(ab['pose']) ? ab['pose'] as String : 'idle');
      final op =
          ((jsTruthy(ab['bub']) && ab['bub'] != 'amor') ||
                  host.TALK == 'abuela') &&
              a % 2 != 0
          ? 1
          : 0;
      c.globalAlpha = ab['al'] == null ? 1 : (ab['al'] as num).toDouble();
      if (ab['en'] == 'ventana') {
        // head and shoulders in the window (clip ventana.hueco; point abuela.ventana, or abuela.ventana.mesa)
        c.save();
        clipToWorld(c, e, _p.clipWorld('ventana.hueco'));
        if (W['win'] == 1 && jsTruthy(W['mesa'])) mesa(c);
        final at = jsTruthy(W['tab']) || jsTruthy(W['mesa'])
            ? _abVentanaMesa
            : ABAT['ventana']!;
        c.drawImage(AB(pose, op), at[0], at[1]);
        // and the frog beside her (frame ventana.lado)
        if (jsTruthy(W['tab'])) {
          final o = _p.off('ventana.lado');
          final bl = (F % 47) < 2 ? 1 : 0,
              sh = jsTruthy(W['shake']) && a % 2 != 0 ? 1 : 0;
          c.drawImage(
            host.lib.spr('cq.42_$bl', () => mkCoqui(.42, bl, false)),
            112 + sh + o[0],
            (W['tab'] == 'mojado' ? 68 : 67) + o[1],
          );
          if (W['tab'] == 'mojado') {
            final t = _p.pt('toalla');
            towel(c, t[0], t[1]);
            for (var k = 0; k < 2; k++) {
              fr(
                c,
                113 + k * 13 + o[0],
                70 + ((F + k * 4) % 8) + o[1],
                1,
                2,
                _drop,
              );
            }
          }
        }
        c.restore();
        if (W['tab'] == 'gotas' && jsTruthy(W['shake'])) {
          final o = _p.off('ventana.lado');
          const drops = [
            [110, 64],
            [120, 62],
            [127, 66],
          ];
          for (var i = 0; i < drops.length; i++) {
            final p = drops[i];
            fr(
              c,
              p[0] + o[0] + (a % 2 != 0 ? 1 : -1) * (i - 1),
              p[1] + o[1] - (a % 3),
              1,
              2,
              _drop,
            );
          }
        }
      } else if (ab['en'] == 'paso') {
        // on the step, with her plate (spot abuela.paso; frame abuela.plato)
        c.drawImage(AB(pose, op), ABAT['paso']![0], ABAT['paso']![1]);
        if (jsTruthy(W['rondas'])) {
          final n = 3 - ((W['mios'] as num?) ?? 0) - ((W['lost'] as num?) ?? 0),
              P = _platoAt;
          for (var i = 0; i < n; i++) {
            fr(c, P[0] + 5 + i * 4, P[1] + 27, 4, 3, SPONGE);
            fr(c, P[0] + 5 + i * 4, P[1] + 27, 4, 1, FROST);
          }
          if (n > 0) fr(c, P[0] + 3, P[1] + 30, 15, 1, _white);
        }
      } else {
        c.drawImage(AB(pose, op), ABAT['puerta']![0], ABAT['puerta']![1]);
      }
      c.globalAlpha = 1;
    }
    // he is going: dust behind, facing away
    if (jsTruthy(q['vis']) && jsTruthy(W['polvo'])) {
      final b = host.frogBox(q);
      const d = [
        [-6, 0],
        [-11, -2],
        [-16, 1],
      ];
      for (var i = 0; i < d.length; i++) {
        fr(
          c,
          b.x + d[i][0],
          b.y + b.h - 3 + d[i][1],
          3 - (i > 1 ? 1 : 0),
          2,
          _dust,
        );
      }
      fr(c, b.x + b.w + 1, b.y + b.h - 6, 4, 1, OUT);
      fr(c, b.x + b.w + 4, b.y + b.h - 7, 1, 3, OUT);
    }
    if (jsTruthy(q['vis'])) {
      c.globalAlpha = (q['al'] as num).toDouble();
      host.frog(c, q, a);
      c.globalAlpha = 1;
      final b = host.frogBox(q);
      if (jsTruthy(W['wet'])) {
        for (var k = 0; k < 3; k++) {
          fr(
            c,
            b.x + 3 + k * _round(b.w / 3),
            b.y + ((F * 2 + k * 5) % 12),
            1,
            2,
            _drop,
          );
        }
      }
      if (jsTruthy(W['gotas'])) {
        final t = F - (W['gotas'] as num);
        for (var k = 0; k < 3; k++) {
          final y = math.min(b.y + 2, b.y - 26 + (t - k * 3) * 5);
          if (t >= k * 3) fr(c, b.x + 5 + k * _round(b.w / 4), y, 2, 3, _drop);
        }
      }
    }
    drawAve(c, W['ave'] as Map<String, dynamic>?);
    // wings out over his eyes
    if (jsTruthy(W['tapado']) && jsTruthy(W['ave'])) {
      final p = avePos(W['ave'] as Map<String, dynamic>), f = (F >> 1) % 2;
      for (final d in const [-1, 1]) {
        final x = p[0] + d * (11 + f);
        fr(c, x - 4, p[1] - 14, 8, 7, OUT);
        fr(c, x - 3, p[1] - 13, 6, 5, RP.blue[2]);
        fr(c, x - 3, p[1] - 13, 6, 1, RP.blue[3]);
      }
    }
    // a slice on its way to the frog
    if (jsTruthy(W['trozo'])) {
      final t = W['trozo'] as Map<String, dynamic>,
          k = jsTruthy(t['k']) ? t['k'] as num : 1,
          w = math.max(3, _round(9 * k)),
          tx = t['x'] as num,
          ty = t['y'] as num;
      fr(c, tx - 4 - 1, ty - 4, w + 2, 9, OUT);
      fr(c, tx - 4, ty - 3, w, 7, SPONGE);
      fr(c, tx - 4, ty - 3, w, 3, FROST);
      if (jsTruthy(t['k']) && (t['k'] as num) < 1) {
        fr(c, tx + 6, ty + 5, 1, 1, SPONGE);
        fr(c, tx - 6, ty + 6, 1, 1, SPONGE);
      }
    }
    // leaves fly as he looks
    final hojas = W['hojas'] as Map<String, dynamic>?;
    if (hojas != null && F - (hojas['f'] as num) < 12) {
      final h = hojas,
          k = F - (h['f'] as num),
          hx = h['x'] as num,
          hy = h['y'] as num;
      const d = [
        [-1, -1],
        [1, -1],
        [-1, 0],
        [1, 0],
        [0, -1],
      ];
      for (var i = 0; i < d.length; i++) {
        fr(
          c,
          hx + d[i][0] * (4 + k * 2) + i,
          hy + d[i][1] * (3 + k) + k,
          3,
          2,
          i % 2 != 0 ? RP.grn[4] : RP.grn[2],
        );
      }
    }
    // frente.js:163-165 the pale sun, the W.dark wash and the W.dusk washes -> the set (sky)
    // the lights are on inside: the set draws the window and the door lit (W.lamp). There is no glow laid over them
    for (final key in const ['nube3', 'nube2', 'nube']) {
      final n = W[key] as Map<String, dynamic>?;
      if (n == null) continue;
      // draw() moves the cloud (W changes as it draws: frente.js does this)
      n['x'] = (n['x'] as num) + ((n['tx'] as num) - (n['x'] as num)) * .14;
      if (((n['tx'] as num) - (n['x'] as num)).abs() < .6) n['x'] = n['tx'];
      final x = _round(n['x'] as num);
      c.drawImage(host.lib.spr('nube', mkNube), x, 0);
      // rain already falling from the cloud, far off
      if (!jsTruthy(W['rain'])) {
        for (var i = 0; i < 16; i++) {
          fr(
            c,
            x + 9 + (i * 23 + F * 2) % 80,
            21 + (i * 7 + F * 4) % 26,
            1,
            4,
            _rainC,
          );
        }
      }
    }
    if (jsTruthy(W['rain'])) rain(c);
    if (jsTruthy(W['flash']) && F - (W['flash'] as num) < 3) {
      c.fillStyle = _flashC;
      c.fillRect(0, 0, SW, SH);
      final nube = W['nube'] as Map<String, dynamic>?;
      if (nube != null) {
        for (var j = 0; j < BOLT.length; j++) {
          final rw = BOLT[j];
          for (var i = 0; i < rw.length; i++) {
            if (rw[i] == '#') {
              fr(
                c,
                _round(nube['x'] as num) + 44 + i * 2,
                21 + j * 2,
                2,
                2,
                _bolt,
              );
            }
          }
        }
      }
    }
    // bubbles last, so they stay bright
    if (ab != null && jsTruthy(ab['bub'])) {
      final bubK = ab['bub'] as String;
      final at = ab['en'] == 'ventana'
          ? _p.pt('globo.ventana')
          : _p.via(
              'abuela.puerta',
              bubK == 'como' ? 141 : 147,
              bubK == 'como' ? 66 : 69,
            );
      host.bub(c, bubK, at[0], at[1], a);
    }
    final dentro = W['dentro'];
    if (jsTruthy(dentro)) {
      final at = dentro == 'ventana'
          ? _p.pt('dentro.ventana')
          : _p.pt('dentro.puerta');
      host.bub(c, 'quien', at[0], at[1], a);
    }
    if (jsTruthy(q['vis']) && jsTruthy(q['bub'])) {
      final b = host.frogBox(q);
      host.bub(c, q['bub'] as String, b.x + (b.w.toInt() >> 1), b.y, a);
    }
  }

  // frente.js: talkAt
  // where a speech bubble points: just above the speaker's head (or above the picture bubble, if one shows). null = not seen.
  @override
  List<num>? talkAt(String who, Map<String, dynamic> W) {
    final k = who;
    if (k != 'abuela') return null;
    final ab = W['ab'] as Map<String, dynamic>?;
    if (ab != null) {
      final bub = jsTruthy(ab['bub']);
      if (ab['en'] == 'paso') return _p.via('abuela.paso', 124, bub ? 40 : 56);
      if (ab['en'] == 'ventana') {
        return _p.via(
          'ventana',
          jsTruthy(W['mesa']) ? 105 : 112,
          bub ? 38 : 60,
        );
      }
      return _p.via(
        'abuela.puerta',
        ab['bub'] == 'como' ? 141 : 156,
        bub ? 47 : 56,
      );
    }
    final dentro = W['dentro'];
    if (jsTruthy(dentro)) {
      return dentro == 'ventana'
          ? _p.pt('habla.dentro.ventana')
          : _p.pt('habla.dentro.puerta');
    }
    return null;
  }

  // frente.js: box
  @override
  List<num>? box(String k, Map<String, dynamic> W) {
    if (k == 'abuela') {
      final ab = W['ab'] as Map<String, dynamic>?;
      if (ab != null && ab['en'] == 'ventana') {
        return _p.clipBox('ventana.hueco');
      }
      if (ab != null && ab['en'] == 'paso') {
        final o = _p.off('abuela.paso');
        return [110 + o[0], 58 + o[1], 36, 50];
      }
      final o = _p.off('abuela.puerta');
      return [151 + o[0], 56 + o[1], 29, 49];
    }
    final e =
        const {
          'palma_grande',
          'palma_pequena',
          'casa_pequena',
          'casa_grande',
        }.contains(k)
        ? _boxes[k]
        : null;
    if (e != null) return e;
    if (k == 'nube') {
      final n = W['nube'] as Map<String, dynamic>?;
      return [_round(n != null ? n['x'] as num : 0), 0, 98, 22];
    }
    return const {'casa', 'puerta', 'ventana'}.contains(k) ? _boxes[k] : null;
  }

  // frente.js: hit
  @override
  String? hit(num x, num y, Map<String, dynamic> W) {
    bool inb(List<num> b) =>
        x >= b[0] && x < b[0] + b[2] && y >= b[1] && y < b[1] + b[3];
    final ab = W['ab'];
    if (jsTruthy(ab) && inb(box('abuela', W)!)) return 'abuela';
    if (jsTruthy(W['escondite'])) {
      if (inb(_hits['palma_pequena']!)) return 'palma_pequena';
      if (inb(_hits['casa_pequena']!)) return 'casa_pequena';
      if (inb(_hits['palma_grande']!)) return 'palma_grande';
      if (inb(_hits['casa_grande']!) &&
          !(jsTruthy(ab) && inb(box('abuela', W)!))) {
        return 'casa_grande';
      }
    }
    final ave = W['ave'] as Map<String, dynamic>?;
    if (ave != null && ave['mode'] != 'none') {
      final p = avePos(ave);
      if ((x - p[0]).abs() < 16 && y > p[1] - 24 && y < p[1] + 5) {
        return 'pajaro';
      }
    }
    // the plate in the corner of the display (hud draws it there, at the display's own pixels): frente.js:190 turns the
    // picture point into display pixels with the view's zoom (`(x - cam[0]) * DW / cam[2]`), then sx < 66 and sy < 36
    if (W['plato'] != null) {
      final d = pictureToDisplay(host.cam, x, y);
      if (d.x < 66 && d.y < 36) return 'bizcocho';
    }
    final q = W['cq'] as Map<String, dynamic>, fb = host.frogBox(q);
    if (jsTruthy(q['vis']) &&
        x >= fb.x &&
        x < fb.x + fb.w &&
        y >= fb.y &&
        y < fb.y + fb.h) {
      return 'coqui';
    }
    final nube = W['nube'] as Map<String, dynamic>?;
    if (jsTruthy(W['storm']) &&
        nube != null &&
        inb([(nube['x'] as num) - 2, 0, 102, 24])) {
      return 'nube';
    }
    // a finger slightly off still counts
    if (inb(_hits['puerta']!)) return 'puerta';
    if (inb(_hits['ventana']!)) return 'ventana';
    // frente.js:195 (the roof) and :196 (the walls): one box, the house's (the sheet's code)
    if (inb(_hits['casa']!)) return 'casa';
    final sc = _sol;
    if (!jsTruthy(W['storm']) &&
        (x - sc[0]) * (x - sc[0]) + (y - sc[1]) * (y - sc[1]) < sc[2] * sc[2]) {
      return 'sol';
    }
    if (inb(_hits['palma']!)) return 'palma';
    return null;
  }

  // frente.js: handAt
  @override
  List<num>? handAt(String k) {
    if (k == 'abuela') {
      final b = box('abuela', W);
      return b != null
          ? [_round(b[0] + b[2] / 2), _round(b[1] + b[3] / 2)]
          : _handAbuela;
    }
    return _handAt[k];
  }

  // frente.js: poke
  @override
  dynamic poke(String what) {
    if (what == 'pajaro') host.SFX.pio();
    if (what == 'nube') {
      host.SFX.trueno(.35);
      W['flash'] = F;
    } else if (what == 'abuela' &&
        W['ab'] != null &&
        !jsTruthy((W['ab'] as Map<String, dynamic>)['bub'])) {
      (W['ab'] as Map<String, dynamic>)['bub'] = 'amor';
      final my = host.runId;
      unawaited(
        host.sleep(1500 / host.FAST).then((_) {
          final ab = W['ab'] as Map<String, dynamic>?;
          if (my == host.runId && ab != null && ab['bub'] == 'amor') {
            ab['bub'] = null;
          }
        }),
      );
    }
    return null;
  }

  /* ---------- what can happen here ---------- */

  Future<void> wait(num ms) => host.wait(ms);

  @override
  late final Map<String, Future<void> Function(Map<String, dynamic> o)> acts = {
    'ir': ir,
    // the frog goes there and knocks
    'tocar': (o) async {
      await ir({'a': o['en']});
      final b = box(o['en'] as String, W)!;
      host.SFX.toc();
      host.bounce(5);
      host.fx(<String, dynamic>{
        't': 'knock',
        'n': 7,
        'x': _round(b[0] + b[2] / 2),
        'y': _round(b[1] + b[3] / 2),
      });
      await wait(560);
    },
    // the lights come on inside (frames ventana and puerta)
    'luz': (o) async {
      W['lamp'] = 1;
      host.SFX.luz();
      host.fx(<String, dynamic>{
        't': 'star',
        'n': 12,
        'pts': [
          _p.via('ventana', 92, 54),
          _p.via('ventana', 132, 56),
          _p.via('ventana', 112, 50),
          _p.via('puerta', 150, 47),
          _p.via('puerta', 182, 49),
          _p.via('puerta', 166, 43),
        ],
      });
      await wait(450);
    },
    // her voice, from behind the shut door or window
    'dentro': (o) async {
      W['dentro'] = o['en'];
    },
    'calla': (o) async {
      W['dentro'] = null;
      if (W['ab'] != null) (W['ab'] as Map<String, dynamic>)['bub'] = null;
      _q()['bub'] = null;
    },
    'burbuja': (o) async {
      if (o['quien'] == 'cq') {
        _q()['bub'] = o['que'];
        host.SFX.coqui();
        host.bounce(6);
      } else if (W['ab'] != null) {
        (W['ab'] as Map<String, dynamic>)['bub'] = o['que'];
      }
    },
    'pose': (o) async {
      if (W['ab'] != null) (W['ab'] as Map<String, dynamic>)['pose'] = o['que'];
    },
    'abre': (o) async {
      if (o['que'] == 'puerta') {
        await host.camGo('puerta');
        host.SFX.creak();
        W['peek'] = 1;
        W['door'] = .5;
        await wait(650);
        W['door'] = 1;
        W['peek'] = 0;
        W['ab'] = <String, dynamic>{
          'en': 'puerta',
          'pose': 'idle',
          'bub': null,
          'al': 1,
        };
        await wait(250);
      } else {
        await host.camGo('ventana');
        host.SFX.creak();
        await wait(350);
        W['win'] = 1;
        W['ab'] = <String, dynamic>{
          'en': 'ventana',
          'pose': 'idle',
          'bub': null,
          'al': 1,
        };
        await wait(350);
      }
    },
    // in he goes: by the door, or with a jump through the window
    'entra': (o) async {
      final q = _q();
      if (o['por'] == 'puerta') {
        for (var i = 4; i >= 0; i--) {
          (W['ab'] as Map<String, dynamic>)['al'] = i / 5;
          await wait(host.TICK);
        }
        W['ab'] = null;
        await wait(200);
        // spot puerta.dentro
        final d = _p.frog('puerta.dentro');
        await host.hopTo(d.x, d.y, 2, d.scale);
        await wait(120);
        host.SFX.hop();
        for (var i = 4; i >= 0; i--) {
          q['al'] = i / 5;
          q['y'] = (q['y'] as num) - 2;
          await wait(host.TICK);
        }
        q['vis'] = 0;
        W['wet'] = 0;
        W['gotas'] = 0;
        await wait(300);
        host.SFX.creak();
        W['door'] = .5;
        await wait(420);
        W['door'] = 0;
        await wait(350);
      } else {
        host.SFX.hop();
        // spot ventana.dentro: the jump ends on the sill (the .72 is where he starts, LUGAR.ventana)
        final d = _p.frog('ventana.dentro');
        final x0 = q['x'] as num, y0 = q['y'] as num;
        const n = 9;
        for (var i = 1; i <= n; i++) {
          final t = i / n;
          q['x'] = _round(x0 + (d.x - x0) * t);
          q['y'] = _round(y0 + (d.y - y0) * t);
          q['dy'] = -12 * math.sin(math.pi * t);
          q['s'] = _round((.72 - .26 * t) * 100) / 100;
          if (i > n - 3) q['al'] = (n - i) / 3;
          await wait(host.TICK);
        }
        q['vis'] = 0;
        q['dy'] = 0;
        W['wet'] = 0;
        W['gotas'] = 0;
        await wait(350);
      }
    },
    // thunder: the storm cloud shows at the edge of the sky
    'trueno': (o) async {
      W['storm'] = 1;
      W['flash'] = F;
      host.SFX.trueno();
      W['dark'] = .22;
      W['nube'] = <String, dynamic>{'x': -100, 'tx': NX[0]};
      await wait(1000);
    },
    'atras': (o) => atras(),
    'llueve': (o) => llueve(),
    // a few drops catch him just before he is in
    'gotas': (o) async {
      W['gotas'] = F;
      for (var k = 0; k < 3; k++) {
        await wait(210);
        host.SFX.drop();
      }
      host.bounce(4);
      await wait(500);
    },
    // the last picture: grandma and the frog at the window
    'cuadro': (o) async {
      final lost = (W['lost'] as num?) ?? 0, steps = _stake()['steps'] as num;
      W['tab'] = lost >= steps
          ? 'mojado'
          : lost != 0
          ? 'gotas'
          : 'seco';
      W['ab'] ??= <String, dynamic>{
        'en': 'ventana',
        'pose': 'idle',
        'bub': null,
        'al': 1,
      };
      final ab = W['ab'] as Map<String, dynamic>;
      ab['en'] = 'ventana';
      // its own view: the heart must sit whole in the ending picture, and the frog is inside, beside her
      await host.camGo('cuadro');
      if (W['tab'] == 'seco') {
        ab['pose'] = 'wave';
        await wait(900);
      } else if (W['tab'] == 'gotas') {
        W['shake'] = 1;
        host.SFX.drop();
        await wait(250);
        host.SFX.drop();
        await wait(700);
        W['shake'] = 0;
        W['tab'] = 'seco';
        ab['bub'] = 'bien';
        await wait(1100);
        ab['bub'] = null;
      } else {
        await wait(500);
      }
    },
    /* ---- story 2 ---- */
    // the frog opens it
    'abrir': (o) async {
      final k = o['que'] as String;
      await ir({'a': k});
      host.SFX.creak();
      await wait(250);
      if (k == 'ventana') {
        W['win'] = 1;
      } else {
        W['door'] = .5;
        await wait(300);
        W['door'] = 1;
      }
      if (W['abIn'] == k) {
        W['ab'] = <String, dynamic>{
          'en': k,
          'pose': 'idle',
          'bub': null,
          'al': 1,
        };
      }
      await wait(350);
    },
    // the frog shuts it
    'cerrar': (o) async {
      final k = o['en'] as String;
      await ir({'a': k});
      host.bounce(5);
      host.SFX.slam();
      if (k == 'ventana') {
        W['win'] = 0;
      } else {
        W['door'] = .5;
        await wait(120);
        W['door'] = 0;
      }
      final ab = W['ab'] as Map<String, dynamic>?;
      if (ab != null && ab['en'] == k) W['ab'] = null;
      host.fx(<String, dynamic>{
        't': 'star',
        'n': 6,
        'pts': [HOLE[k]],
      });
      await wait(380);
    },
    // abuela shuts it from inside
    'abcierra': (o) async {
      final k = o['que'] as String;
      await host.camGo(k);
      host.SFX.slam();
      if (k == 'ventana') {
        W['win'] = 0;
      } else {
        W['door'] = 0;
      }
      W['ab'] = null;
      W['abIn'] = k;
      await wait(450);
    },
    // she goes off to the back, with the cake
    'vete': (o) async {
      for (var i = 4; i >= 0; i--) {
        if (W['ab'] != null) (W['ab'] as Map<String, dynamic>)['al'] = i / 5;
        await wait(host.TICK);
      }
      W['ab'] = null;
      W['abIn'] = null;
      W['mesa'] = 0;
      W['caliente'] = 0;
      await wait(200);
    },
    // the frog leans in at the window
    'asoma': (o) async {
      await ir({'a': 'ventana'});
      final q = _q();
      host.SFX.hop();
      for (var i = 1; i <= 4; i++) {
        q['y'] = (q['y'] as num) - 3;
        await wait(host.TICK);
      }
      await wait(300);
    },
    'baja': (o) async {
      final q = _q();
      host.bounce(4);
      for (var i = 1; i <= 4; i++) {
        q['y'] = (q['y'] as num) + 3;
        await wait(host.TICK);
      }
    },
    'pajaro': (o) async {
      W['ave'] = <String, dynamic>{
        'mode': 'fly',
        'x': -12,
        'y': 40,
        'dir': 1,
        'st': 'n',
      };
      host.SFX.pio();
      await aveA(150 + 56, 22, 12);
      _ave()['mode'] = 'circle';
      await wait(500);
    },
    'bonk': (o) async {
      final v = _ave(), h = HOLE[o['en']]!;
      v['x'] = avePos(v)[0];
      v['y'] = avePos(v)[1];
      v['mode'] = 'fly';
      v['dir'] = h[0] >= (v['x'] as num) ? 1 : -1;
      host.SFX.swoop();
      await aveA(h[0], h[1], 8);
      host.SFX.bonk();
      host.fx(<String, dynamic>{
        't': 'knock',
        'n': 7,
        'x': h[0],
        'y': h[1] - 4,
      });
      v['st'] = 'sleep';
      await aveA(h[0] - (v['dir'] as num) * 6, h[1] + 10, 4);
      await wait(350);
      v['st'] = 'n';
      await aveA(150, 26, 10);
      v['mode'] = 'circle';
    },
    'posa': (o) async {
      final v = _ave(), p = PERCH[o['en']]!;
      v['x'] = avePos(v)[0];
      v['y'] = avePos(v)[1];
      v['mode'] = 'fly';
      v['dir'] = p[0] >= (v['x'] as num) ? 1 : -1;
      await aveA(p[0], p[1], 10);
      v['mode'] = 'sit';
      v['dir'] = o['en'] == 'puerta' ? -1 : 1;
      host.SFX.pio();
      await wait(400);
    },
    'come': (o) async {
      final ab = W['ab'] as Map<String, dynamic>?;
      final k = ab != null ? ab['en'] as String : 'puerta';
      await ir({'a': k});
      W['plato'] = math.max(0, (W['plato'] as num) - 1);
      final h = HOLE[k]!, b = host.frogBox(_q());
      final trozo = <String, dynamic>{'x': h[0], 'y': h[1]};
      W['trozo'] = trozo;
      for (var i = 1; i <= 6; i++) {
        trozo['x'] = h[0] + (b.x + b.w / 2 - h[0]) * i / 6;
        trozo['y'] = h[1] + (b.y + 8 - h[1]) * i / 6;
        await wait(host.TICK);
      }
      for (final kk in const [1, .7, .4]) {
        trozo['k'] = kk;
        host.SFX.munch();
        host.bounce(3);
        await wait(320);
      }
      W['trozo'] = null;
      host.fx(<String, dynamic>{
        't': 'star',
        'n': 8,
        'pts': [
          [b.x + b.w / 2 - 8, b.y + 12],
          [b.x + b.w / 2 + 8, b.y + 10],
        ],
      });
      _q()['bub'] = 'amor';
      await wait(900);
      _q()['bub'] = null;
    },
    'regala': (o) async {
      final v = _ave(), ab = W['ab'] as Map<String, dynamic>?;
      final k = ab != null ? ab['en'] as String : 'puerta', h = HOLE[k]!;
      W['plato'] = math.max(0, (W['plato'] as num) - 1);
      v['x'] = avePos(v)[0];
      v['y'] = avePos(v)[1];
      v['mode'] = 'fly';
      v['dir'] = h[0] >= (v['x'] as num) ? 1 : -1;
      host.SFX.pio();
      await aveA(h[0], h[1] - 6, 8);
      v['slice'] = 1;
      await wait(300);
      final b = host.frogBox(_q());
      v['dir'] = b.x + b.w / 2 >= (v['x'] as num) ? 1 : -1;
      await aveA(b.x + b.w / 2, b.y + 2, 10);
      v['slice'] = 0;
      v['mode'] = 'head';
      host.SFX.munch();
      await wait(250);
      host.SFX.pio();
      _q()['bub'] = 'amor';
      await wait(1000);
      _q()['bub'] = null;
    },
    'fin2': (o) async {
      await host.camGo('wide', 9);
      final v = W['ave'] as Map<String, dynamic>?;
      final lost = (W['lost'] as num?) ?? 0;
      if (v != null && v['mode'] != 'head') {
        v['x'] = avePos(v)[0];
        v['y'] = avePos(v)[1];
        v['mode'] = 'fly';
        v['dir'] = 1;
        // point ave.techo
        final t = _p.pt('ave.techo');
        await aveA(t[0], t[1], 10);
        v['mode'] = 'sit';
        v['st'] = lost >= 2
            ? 'round'
            : lost != 0
            ? 'feliz'
            : 'n';
        host.SFX.pio();
      } else if (v != null) {
        v['st'] = lost >= 2
            ? 'round'
            : lost != 0
            ? 'feliz'
            : 'n';
      }
      if (lost == 0) {
        W['heart'] = 1;
        host.SFX.win();
        final b = host.cam;
        host.fx(<String, dynamic>{
          't': 'star',
          'n': 40,
          'pts': [
            [b[0] + 8, b[1] + 14],
            [b[0] + b[2] - 8, b[1] + 16],
            [b[0] + b[2] / 2 - 20, b[1] + 8],
            [b[0] + b[2] / 2 + 22, b[1] + 10],
          ].map((p) => [_round(p[0]), _round(p[1])]).toList(),
        });
      } else {
        host.SFX.coqui();
        if (lost >= 2) _q()['bub'] = 'mal';
      }
      await wait(1800);
    },
    /* ---- story 3 ---- */
    'tapa': (o) async {
      W['abierto'] = null;
      final b = host.frogBox(_q());
      if (W['ave'] == null || _ave()['mode'] == 'none') {
        W['ave'] = <String, dynamic>{
          'mode': 'fly',
          'x': -10,
          'y': 60,
          'dir': 1,
          'st': 'n',
        };
      }
      final v = _ave();
      if (v['mode'] != 'head') {
        v['x'] = avePos(v)[0];
        v['y'] = avePos(v)[1];
        v['mode'] = 'fly';
        v['dir'] = b.x + b.w / 2 >= (v['x'] as num) ? 1 : -1;
        await aveA(b.x + b.w / 2, b.y + 2, 8);
      }
      v['mode'] = 'head';
      host.SFX.pio();
      await wait(250);
      W['tapado'] = 1;
      await wait(900);
      W['tapado'] = 0;
      v['x'] = avePos(v)[0];
      v['y'] = avePos(v)[1];
      v['mode'] = 'fly';
      v['dir'] = 1;
      host.SFX.swoop();
      await aveA(250, -20, 7);
      v['mode'] = 'none';
      await wait(300);
    },
    'mueve': (o) async {
      W['rustle'] = o['que'];
      for (var k = 0; k < 3; k++) {
        host.tone(300 + k * 40, 0, .12, 'sawtooth', .012, 200);
        await wait(160);
      }
      await wait(300);
    },
    'mira': (o) async {
      final k = o['en'] as String;
      W['rustle'] = null;
      await ir({'a': k});
      await wait(150);
      if (k == 'casa_grande') {
        host.SFX.creak();
        W['door'] = .5;
        await wait(200);
        W['door'] = 1;
      } else {
        host.SFX.blip();
        W['abierto'] = k;
        W['hojas'] = <String, dynamic>{
          'x': SPOT[k]![0],
          'y': SPOT[k]![1],
          'f': F,
        };
      }
      await wait(400);
      if (host.V['p'] == k) {
        W['ave'] = <String, dynamic>{
          'mode': 'sit',
          'x': SPOT[k]![0],
          'y': SPOT[k]![1],
          'dir': -1,
          'st': 'n',
        };
        host.SFX.pio();
        host.bounce(6);
        await wait(500);
      } else {
        host.fx(<String, dynamic>{
          't': 'star',
          'n': 5,
          'pts': [SPOT[k]],
        });
        await wait(500);
      }
    },
    'sale': (o) async {
      final k = o['en'] as String;
      W['ave'] = <String, dynamic>{
        'mode': 'sit',
        'x': SPOT[k]![0],
        'y': SPOT[k]![1],
        'dir': 1,
        'st': 'feliz',
      };
      host.SFX.pio();
      await wait(160);
      host.SFX.pio();
      await wait(700);
    },
    'gana': (o) async {
      W['mios'] = ((W['mios'] as num?) ?? 0) + 1;
      host.SFX.right();
      _q()['bub'] = 'amor';
      await wait(800);
      _q()['bub'] = null;
    },
    'limpia': (o) async {
      W['abierto'] = null;
      W['rustle'] = null;
      if (jsTruthy(W['door'])) W['door'] = 0;
      if (W['ave'] != null) _ave()['mode'] = 'none';
      await atras();
    },
    'tapate': (o) async {
      final Map<String, dynamic> v;
      if (W['ave'] != null && _ave()['mode'] != 'none') {
        v = _ave();
      } else {
        v = <String, dynamic>{
          'mode': 'fly',
          'x': 250,
          'y': 60,
          'dir': -1,
          'st': 'n',
        };
        W['ave'] = v;
      }
      v['x'] = avePos(v)[0];
      v['y'] = avePos(v)[1];
      v['mode'] = 'fly';
      v['dir'] = -1;
      // point ave.cesped
      final t = _p.pt('ave.cesped');
      await aveA(t[0], t[1], 9);
      v['mode'] = 'sit';
      v['st'] = 'tapa';
      host.SFX.pio();
      await wait(500);
    },
    'esconde': (o) async {
      final k = o['en'] as String, q = _q();
      await ir({'a': k});
      if (k == 'casa_grande') {
        host.SFX.creak();
        W['door'] = 1;
        await wait(250);
        // spot puerta.escondido
        final d = _p.frog('puerta.escondido');
        await host.hopTo(d.x, d.y, 1, d.scale);
        q['vis'] = 0;
        W['door'] = .5;
        W['asoma'] = 1;
        await wait(400);
      } else {
        host.SFX.hop();
        // spot casa_pequena.dentro
        final d = _p.frog('casa_pequena.dentro');
        for (var i = 0; i < 4; i++) {
          q['x'] = (q['x'] as num) + (d.x - (q['x'] as num)) / 2;
          q['y'] = (q['y'] as num) + (d.y - (q['y'] as num)) / 2;
          q['s'] = math.max(.5, (q['s'] as num) - .08);
          await wait(host.TICK);
        }
        q['vis'] = 0;
        W['piernas'] = 1;
        await wait(400);
      }
    },
    'busca_ave': (o) async {
      final v = _ave(), k = o['en'] as String;
      v['st'] = 'n';
      for (final s in const ['palma_grande', 'palma_pequena']) {
        v['x'] = avePos(v)[0];
        v['y'] = avePos(v)[1];
        v['mode'] = 'fly';
        v['dir'] = SPOT[s]![0] >= (v['x'] as num) ? 1 : -1;
        await aveA(SPOT[s]![0], SPOT[s]![1], 8);
        v['mode'] = 'sit';
        host.SFX.pio();
        await wait(450);
      }
      v['mode'] = 'fly';
      // points ave.puerta.lado and ave.casita.techo
      final t = k == 'casa_grande'
          ? _p.pt('ave.puerta.lado')
          : _p.pt('ave.casita.techo');
      v['dir'] = t[0] >= (v['x'] as num) ? 1 : -1;
      await aveA(t[0], t[1], 9);
      v['mode'] = 'sit';
      if (k == 'casa_pequena') {
        // on the roof, puzzled, then it looks down
        v['st'] = 'n';
        await wait(700);
        v['dir'] = -(v['dir'] as num);
        await wait(300);
      }
      final pa = avePos(v);
      host.fx(<String, dynamic>{
        't': 'knock',
        'n': 10,
        'x': pa[0],
        'y': pa[1] - 30,
      });
      host.SFX.pio();
      await wait(600);
      final q = _q();
      W['piernas'] = 0;
      if (k == 'casa_grande') {
        host.SFX.creak();
        W['door'] = 1;
      }
      W['asoma'] = 0;
      q['vis'] = 1;
      q['s'] = .8;
      await ir({'a': 'patio'});
      W['door'] = 0;
      host.bounce(8);
      host.SFX.coqui();
    },
    'atardece': (o) async {
      W['dusk'] = 2;
      await wait(700);
    },
    'devuelve': (o) async {
      final b = host.frogBox(_q());
      W['ave'] = <String, dynamic>{
        'mode': 'fly',
        'x': 250,
        'y': 30,
        'dir': -1,
        'st': 'n',
        'slice': 1,
      };
      host.SFX.pio();
      await aveA(b.x + b.w + 8, b.y + 6, 10);
      _ave()['mode'] = 'sit';
      await wait(300);
      _ave()['slice'] = 0;
      W['lost'] = (W['lost'] as num) - 1;
      W['mios'] = ((W['mios'] as num?) ?? 0) + 1;
      host.SFX.right();
      _q()['bub'] = 'amor';
      await wait(1100);
      _q()['bub'] = null;
    },
    'avecasa': (o) async {
      final v = W['ave'] as Map<String, dynamic>?;
      if (v == null || v['mode'] == 'none') {
        W['ave'] = <String, dynamic>{
          'mode': 'fly',
          'x': 200,
          'y': 40,
          'dir': -1,
          'st': 'n',
        };
      }
      final w = _ave();
      w['x'] = avePos(w)[0];
      w['y'] = avePos(w)[1];
      w['mode'] = 'fly';
      w['dir'] = -1;
      // point ave.casita.entra
      final t = _p.pt('ave.casita.entra');
      await aveA(t[0], t[1], 10);
      w['mode'] = 'none';
      host.SFX.pio();
      await wait(400);
    },
    'abentra': (o) async {
      host.SFX.creak();
      W['door'] = 1;
      await wait(500);
      if (W['ab'] != null) {
        (W['ab'] as Map<String, dynamic>)['en'] = 'puerta';
        (W['ab'] as Map<String, dynamic>)['pose'] = 'wave';
      }
      await wait(900);
      if (W['ab'] != null) (W['ab'] as Map<String, dynamic>)['pose'] = 'idle';
      for (var i = 7; i >= 0; i--) {
        if (W['ab'] != null) (W['ab'] as Map<String, dynamic>)['al'] = i / 8;
        await wait(host.TICK);
      }
      W['ab'] = null;
      await wait(400);
      host.SFX.creak();
      W['door'] = .5;
      await wait(250);
      host.SFX.slam();
      W['door'] = 0;
      await wait(400);
    },
    'marcador': (o) async {
      if (((W['mios'] as num?) ?? 0) > ((W['lost'] as num?) ?? 0)) {
        W['heart'] = 1;
        host.SFX.win();
        host.fx(<String, dynamic>{
          't': 'star',
          'n': 30,
          'pts': [
            [60, 20],
            [180, 24],
            [120, 12],
            [100, 30],
            [150, 30],
          ],
        });
      } else {
        _q()['bub'] = 'mal';
        host.SFX.coqui();
      }
      await wait(1600);
      _q()['bub'] = null;
    },
    'vetecq': (o) async {
      final q = _q();
      for (var h = 0; h < 3; h++) {
        host.SFX.hop();
        await host.hopTo((q['x'] as num) + 38, (q['y'] as num) + 4, 1);
      }
      host.SFX.coqui();
      await wait(500);
      host.SFX.coqui();
      q['vis'] = 0;
      await wait(800);
    },
    // only the dry ending is a celebration
    'fin': (o) async {
      final b = host.cam, lost = (W['lost'] as num?) ?? 0;
      if (lost == 0) {
        W['heart'] = 1;
        host.SFX.win();
        host.fx(<String, dynamic>{
          't': 'star',
          'n': 40,
          'pts': [
            [b[0] + 8, b[1] + 14],
            [b[0] + b[2] - 8, b[1] + 16],
            [b[0] + b[2] / 2 - 20, b[1] + 8],
            [b[0] + b[2] / 2 + 22, b[1] + 10],
            [b[0] + 6, b[1] + b[3] / 2],
            [b[0] + b[2] - 6, b[1] + b[3] / 2],
          ].map((p) => [_round(p[0]), _round(p[1])]).toList(),
        });
      } else if (lost < (_stake()['steps'] as num)) {
        host.SFX.win();
      } else {
        host.SFX.coqui();
      }
      await wait(1700);
    },
  };

  Map<String, dynamic> _ave() => W['ave'] as Map<String, dynamic>;
  Map<String, dynamic> _stake() => host.S['stake'] as Map<String, dynamic>;

  // frente.js: acts.ir
  Future<void> ir(Map<String, dynamic> o) async {
    final L = LUGAR[o['a'] ?? o['en']]!, q = _q();
    final dx = (q['x'] as num) - L[0],
        dy = (q['y'] as num) - L[1],
        d = math.sqrt(dx * dx + dy * dy);
    if (d < 3) return;
    await host.hopTo(
      L[0],
      L[1],
      math.max(1, math.min(4, _round(d / 28))),
      L[2],
    );
  }

  // frente.js: acts.atras (spot patio)
  Future<void> atras() async {
    await host.hopTo(
      LUGAR['patio']![0],
      LUGAR['patio']![1],
      2,
      LUGAR['patio']![2],
    );
  }

  // frente.js: acts.llueve
  Future<void> llueve() async {
    (W['nube'] as Map<String, dynamic>)['tx'] = NX[2];
    W['nube2'] = <String, dynamic>{'x': -100, 'tx': 44};
    W['nube3'] = <String, dynamic>{'x': 250, 'tx': 176};
    W['dark'] = .33;
    host.SFX.trueno(.5);
    W['flash'] = F;
    await wait(700);
    W['rain'] = 1;
    host.SFX.lluvia();
    if (jsTruthy(_q()['vis'])) W['wet'] = 1;
    await wait(700);
  }

  // frente.js: aveA
  Future<void> aveA(num tx, num ty, int n) async {
    final v = _ave(), x0 = v['x'] as num, y0 = v['y'] as num;
    for (var i = 1; i <= n; i++) {
      final t = i / n;
      v['x'] = x0 + (tx - x0) * t;
      v['y'] = y0 + (ty - y0) * t - math.sin(math.pi * t) * 6;
      await wait(host.TICK);
    }
    v['x'] = tx;
    v['y'] = ty;
  }

  // frente.js: roba
  // the bird takes a slice: in through the open place, out with it in its beak
  Future<void> roba(String? en) async {
    final v = _ave(), h = HOLE[en] ?? HOLE['ventana']!;
    v['x'] = avePos(v)[0];
    v['y'] = avePos(v)[1];
    v['mode'] = 'fly';
    v['dir'] = h[0] >= (v['x'] as num) ? 1 : -1;
    host.SFX.swoop();
    await aveA(h[0], h[1], 8);
    v['mode'] = 'none';
    await wait(400);
    W['plato'] = math.max(0, (W['plato'] as num) - 1);
    host.SFX.munch();
    v['mode'] = 'fly';
    v['slice'] = 1;
    v['x'] = h[0];
    v['y'] = h[1];
    v['dir'] = 1;
    host.SFX.pio();
    await aveA(h[0] + 30, 24, 9);
    await wait(250);
    v['slice'] = 0;
    v['mode'] = 'circle';
    await wait(300);
  }

  // frente.js: stake
  // the thing at stake takes a step. Rain: the cloud comes closer, and at the last step it rains. Cake: the bird takes a slice.
  @override
  Future<void> stake(int lost, int max, String en) async {
    final thing = _stake()['thing'];
    if (thing == 'bizcocho') {
      await roba(en);
      return;
    }
    if (thing == 'rondas') {
      // the bird's plate gets the slice
      host.SFX.munch();
      await wait(500);
      return;
    }
    if (lost >= max) {
      await llueve();
      return;
    }
    host.SFX.trueno(.6);
    W['flash'] = F;
    (W['nube'] as Map<String, dynamic>)['tx'] =
        NX[math.min(2, _round(lost * 2 / max))];
    W['dark'] = .22 + .05 * lost;
    await wait(900);
  }

  // frente.js: remap is not in the old file. Page 12, section 5: every position a story, pair or level file holds goes
  // through the sheet's remap table. A frog's point gives his box and size at the spot it means ([x, y, scale]); a
  // point that is not used gives itself back; a view rectangle gives the view; a crop or a point gives the zoom-1
  // window over the place it means; an x alone gives the new x.
  @override
  List<num> remap(List<num> xy) {
    final e = _p.e;
    switch (xy.length) {
      case 1:
        return [sheet.remapX(xy[0])];
      case 2:
        final r = sheet.remapPoint(xy[0], xy[1]);
        final to = r.to;
        if (to.spot != null) {
          final f = sheet.frogAt(to.spot!, e);
          return [f.x, f.y, f.scale];
        }
        if (to.none != null) return xy;
        final w = to.world!, p = e.project(w[0], w[1], w[2]);
        return [p.sx, p.sy];
      case 4:
        SheetRemap r;
        try {
          r = sheet.remapCam(xy);
        } on SheetError {
          r = sheet.remapCrop(xy);
        }
        final to = r.to;
        if (to.view != null) return sheet.viewOf(to.view!, e);
        return r.crop!;
      default:
        throw SheetError('a position is 1, 2 or 4 numbers, not $xy');
    }
  }
}
