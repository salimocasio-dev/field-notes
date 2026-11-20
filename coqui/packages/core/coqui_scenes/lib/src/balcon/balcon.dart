// Port of historia/escenas/balcon.js: the scene "El balcón", abuela's porch seen from the yard (order 30b). Line for line,
// minus its background function `bg` and minus what the sheet's `dropped` list says is dropped (the three furniture
// sprites, the frog's dotted shadow); every screen position replaced by what the sheet's `code` list gives for its line
// (balcon_places.dart). balcon.js is written on the kit, so this is an `Escena`; its set is [BalconSet].
//
// The old file's names are kept, Spanish ones and capitals included, so the port reads line for line against it
// (page 12, sections 4 and 6): the lints on names are off in this file.
// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_pixel/coqui_pixel.dart' hide tarjeta;
import 'package:coqui_scenes/src/balcon/balcon_places.dart';
import 'package:coqui_scenes/src/balcon/balcon_set.dart';
import 'package:coqui_scenes/src/scene_set.dart';
import 'package:coqui_scenes/src/sheet_cache.dart';

/// The scene "balcon", made from its sheet (the registry's factory: the sheet must be read first, `loadScene`), drawing its
/// random numbers from [rng], the game's one random source.
Scene createBalcon({Rng? rng}) => Balcon(sheetOf('balcon'), rng: rng);

// JavaScript: Math.round
int _round(num v) => (v + 0.5).floor();

// JavaScript: `x || 0` for a number of W
num _n(Object? v) => jsTruthy(v) ? v as num : 0;

List<Map<String, dynamic>> _ms(Object? l) => l == null
    ? <Map<String, dynamic>>[]
    : (l as List).cast<Map<String, dynamic>>();

const int _white = 0xFFFFFFFF;

// balcon.js: JUGO, AGUA
final List<int> JUGO = [
      hexColour('#C86A10'),
      hexColour('#F2A024'),
      hexColour('#FFD070'),
    ],
    AGUA = [hexColour('#5A9AE0'), hexColour('#9CCBF5'), hexColour('#DCEEFF')];

final int _glass = hexColour('#8FB9C4'),
    _glassBottom = hexColour('#6E9AA8'),
    _straw = hexColour('#EC6050'),
    _jugGlass = hexColour('#F4FAFF'),
    _dropC = hexColour('#7CC0FF'),
    _card = hexColour('#FFFDF4'),
    _cardOff = hexColour('#B9B2A2'),
    _termoHot = hexColour('#FF7A60'),
    _termoRed = hexColour('#E8443C'),
    _sun3 = hexColour('#FF8A20'),
    _sun1 = hexColour('#FFC030'),
    _sun0 = hexColour('#FFE680'),
    _fanRim = hexColour('#D0403A'),
    _fanY = hexColour('#FFE070'),
    _fanP = hexColour('#FF8FB8'),
    _fanStick = hexColour('#B88040');

/// "rgba(255,255,255,.55)": white at .55 (of 255, rounded: 140).
const int _milk = 0x8CFFFFFF;

/// "rgba(255,90,40,.2)": the sun's flare at .2 (of 255: 51).
const int _flare = 0x33285AFF;

// balcon.js: VT
// a glass: t = n (plain), g (big), p (small)
const Map<String, List<int>> VT = {
  'n': [9, 13],
  'g': [11, 17],
  'p': [7, 9],
};

// balcon.js: vaso
// a glass: t = n (plain), g (big), p (small); k = jugo or agua; lv = how full, 0 to 1
void vaso(Ctx g, num cx, num by, String t, String k, num lv) {
  final w = VT[t]![0],
      h = VT[t]![1],
      x = _round(cx - w / 2),
      y = by - h,
      col = k == 'agua' ? AGUA : JUGO,
      n = _round((h - 3) * math.max(0, math.min(1, lv)));
  fr(g, x - 1, y, w + 2, h, OUT);
  fr(g, x, y + h, w, 1, OUT);
  // balcon.js: `g.clearRect&&0` does nothing
  // empty glass: pale, see-through, never a white card
  fr(g, x, y, w, h, _glass);
  fr(g, x, y, w, h, _milk);
  if (n > 0) {
    fr(g, x, y + h - 1 - n, w, n, col[1]);
    fr(g, x, y + h - 1 - n, w, 1, col[2]);
    fr(g, x + w - 2, y + h - n, 1, n - 1, col[0]);
    // ice in the water
    if (k == 'agua' && n > 4) {
      fr(g, x + 2, y + h - n + 1, 2, 2, _white);
      if (w > 7) fr(g, x + w - 4, y + h - n + 3, 2, 2, _white);
    }
  }
  fr(g, x, y + h - 1, w, 1, _glassBottom);
  fr(g, x + 1, y + 1, 1, h - 3, _white);
  fr(g, x, y, w, 1, _white);
  // a straw in the juice glass, full or empty
  if (k == 'jugo') {
    fr(g, x + w - 3, y - 4, 1, 5, OUT);
    fr(g, x + w - 2, y - 4, 1, h + 1, _straw);
    fr(g, x + w - 1, y - 4, 1, 5, OUT);
    fr(g, x + w - 3, y - 5, 3, 1, OUT);
  }
}

// balcon.js: jarra
// a jug: orange for juice, clear blue for water. A narrow neck with a spout, a wide belly, a handle.
void jarra(Ctx g, num cx, num by, String k) {
  final col = k == 'agua' ? AGUA : JUGO, x = cx - 6, y = by - 21, G = _jugGlass;
  // outline: neck, spout, belly
  fr(g, x + 1, y, 9, 7, OUT);
  fr(g, x - 2, y, 4, 3, OUT);
  fr(g, x - 1, y + 6, 13, 15, OUT);
  fr(g, x, y + 21, 11, 1, OUT);
  // handle
  fr(g, x + 11, y + 7, 4, 2, OUT);
  fr(g, x + 14, y + 8, 2, 8, OUT);
  fr(g, x + 11, y + 15, 4, 2, OUT);
  fr(g, x + 2, y + 1, 7, 6, G);
  fr(g, x - 1, y + 1, 3, 1, G);
  fr(g, x, y + 7, 11, 13, G);
  fr(g, x + 12, y + 8, 2, 1, G);
  fr(g, x + 14, y + 9, 1, 6, G);
  fr(g, x + 12, y + 15, 2, 1, G);
  fr(g, x, y + 9, 11, 11, col[1]);
  fr(g, x, y + 9, 11, 1, col[2]);
  fr(g, x + 9, y + 10, 2, 10, col[0]);
  fr(g, x + 1, y + 8, 1, 11, _white);
  fr(g, x + 3, y + 2, 1, 4, _white);
  // ice in the water; a slice of orange in the juice
  if (k == 'agua') {
    fr(g, x + 3, y + 11, 2, 2, _white);
    fr(g, x + 6, y + 14, 2, 2, _white);
  } else {
    fr(g, x + 4, y + 12, 3, 3, JUGO[2]);
    fr(g, x + 5, y + 13, 1, 1, JUGO[0]);
  }
}

// balcon.js: gota
// a drop of sweat
void gota(Ctx g, num x, num y) {
  fr(g, x - 1, y - 2, 3, 1, OUT);
  fr(g, x - 2, y - 1, 5, 4, OUT);
  fr(g, x - 1, y + 3, 3, 1, OUT);
  fr(g, x, y - 2, 1, 1, AGUA[2]);
  fr(g, x - 1, y - 1, 3, 4, _dropC);
  fr(g, x - 1, y - 1, 1, 2, _white);
}

/* ---------- what is at stake, in the corner of the screen ---------- */

// balcon.js: tarjeta
void tarjeta(Ctx g, num x, num y, num w, num h) {
  g.fillStyle = OUT;
  g.fillRect(x - 1, y, w + 2, h);
  g.fillRect(x, y - 1, w, h + 2);
  g.fillStyle = _card;
  g.fillRect(x, y, w, h);
}

// balcon.js: mini
void mini(Ctx g, num x, num y, Object? on) {
  final o = jsTruthy(on);
  g.fillStyle = o ? OUT : _cardOff;
  g.fillRect(x - 1, y, 11, 14);
  g.fillRect(x, y + 14, 9, 1);
  g.fillStyle = o ? _jugGlass : _card;
  g.fillRect(x, y, 9, 14);
  if (o) {
    final col = on == 'jugo' ? JUGO : AGUA;
    fr(g, x, y + 4, 9, 10, col[1]);
    fr(g, x, y + 4, 9, 1, col[2]);
    fr(g, x + 1, y + 1, 1, 11, _white);
    if (on != 'jugo') fr(g, x + 3, y + 6, 2, 2, _white);
  }
}

// balcon.js: nivel
// how hot abuela is: every drink brings it down, every wrong move sends it up
int nivel(Map<String, dynamic> W) =>
    math.max(0, math.min(4, 2 + _n(W['lost']) - _n(W['fresco']))).toInt();

// balcon.js: abanico
// a paper fan, or half of one: pleats from a pivot at the bottom, a red rim. a0..a1 in degrees, 0 = up
void abanico(Ctx g, num x, num y, num r, num a0, num a1) {
  for (var dy = -r - 1; dy <= 0; dy++) {
    for (var dx = -r - 1; dx <= r + 1; dx++) {
      final d = math.sqrt(dx * dx + dy * dy),
          an = math.atan2(dx, -dy) * 180 / math.pi;
      if (an < a0 || an > a1) continue;
      if (d > r + .5 && d <= r + 1.5) {
        fr(g, x + dx, y + dy, 1, 1, OUT);
      } else if (d <= r + .5 && d >= 1) {
        fr(
          g,
          x + dx,
          y + dy,
          1,
          1,
          d > r - 1
              ? _fanRim
              : ((an + 90) / 15).floor().remainder(2) != 0
              ? _fanY
              : _fanP,
        );
      }
    }
  }
  fr(g, x - 1, y, 3, 3, OUT);
  fr(g, x, y, 1, 2, _fanStick);
}

// balcon.js: medio
void medio(Ctx g, num x, num y, num d) =>
    abanico(g, x, y, 8, d < 0 ? -70 : 5, d < 0 ? -5 : 70);

/// The pixels of each of the sheet's `front` parts (set-kit.js `PART_TAGS`: the part of the set that drew a pixel
/// last), by set key, then by part. A state's are the same on every engine.
final Map<String, Map<String, Int32List>> _frontPixels = {};

/// The scene "El balcón" (balcon.js: `KIT.escena({id:"balcon", ...})`). Its set is [BalconSet]; this is the sprite
/// layer and what can happen here.
class Balcon extends Escena implements SetScene, SetOverSprites {
  /// [rng] is the game's one random source (balcon.js `azar`: `Math.random()`): the story runner's. A scene made without it
  /// (a picture, a test of its sprites) draws no random number.
  Balcon(this.sheet, {Rng? rng}) : _rngGiven = rng {
    _p = BalconPlaces(sheet, balconEngine());
    final p = _p;
    X2 = [p.ptRound('mesa.izq')[0], p.ptRound('mesa.der')[0]];
    MESA_Y = p.number('MESA_Y');
    ABS = p.ptRound('ABS');
    _talkLado = p.ptRound('talk.lado');
    PERCH = p.ptRound('PERCH');
    ASIENTO = p.ptRound('ASIENTO');
    AB = {
      'puerta': p.abuela('abuela.puerta'),
      'mesa': p.abuela('abuela.mesa'),
      'lado': p.abuela('abuela.lado'),
    };
    LUGAR = {for (final k in sheet.lugar.keys) k: sheet.lugarOf(k, p.e)};
    BEHIND = p.number('behind');
    _centro = p.ptRound('mesa.centro')[0];
    _derX = p.ptRound('mesa.der')[0];
    _fanMesa = p.ptRound('mesa.abanico');
    _suelo1 = p.ptRound('suelo.abanico.1');
    _suelo2 = p.ptRound('suelo.abanico.2');
    final sube = p.frog('sube');
    if (sube.x != LUGAR['jardin']![0]) {
      throw SheetError(
        'the spot sube is not under jardin (x ${sube.x}, not ${LUGAR['jardin']![0]})',
      );
    }
    _subeY = sube.y;
    CAM = {for (final k in sheet.views.keys) k: p.view(k)};
    heartAt = p.ptRound('corazon');
    _abSilla = sheet.things['abuela']!.places!['silla']!.box!;
    _door = p.clipWorld('puerta.hueco');
    // balcon.js: COSAS
    cosas = [
      for (final id in IDS) cosaMesa(id),
      Thing(
        id: 'abuela',
        si: (w) =>
            jsTruthy(w['ab']) &&
            _moreThanHalf((w['ab'] as Map<String, dynamic>)['al']),
        box: abCaja,
        m: 1,
      ),
      Thing(id: 'mesa', box: p.box('mesa'), m: 0),
      Thing(id: 'silla_pequena', box: p.box('silla_pequena'), m: 2),
      Thing(id: 'silla_grande', box: p.box('silla_grande'), m: 2),
      Thing(
        id: 'puerta',
        box: p.box('puerta'),
        m: 2,
        hand: p.ptRound('mano.puerta'),
      ),
      Thing(
        id: 'ventana',
        box: p.box('ventana'),
        m: 1,
        hand: p.ptRound('mano.ventana'),
      ),
      Thing(id: 'balcon', box: p.box('balcon'), m: 0),
    ];
  }

  @override
  final Sheet sheet;

  late final BalconPlaces _p;
  final Rng? _rngGiven;

  @override
  String get id => 'balcon';

  @override
  PpEngine newEngine({bool still = false}) => balconEngine(still: still);

  @override
  PpEngine get projection => _p.e;

  // the host: the glyphs and bubbles balcon.js adds when it loads (`GL.sol`, ..., `Object.assign(BUBL, ...)`) go into
  // the game's tables when the scene is given its host
  SceneHost? _host;
  @override
  SceneHost get host => _host!;
  @override
  set host(SceneHost h) {
    _host = h;
    _glyphs(h);
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

  // the sheet's setKey table, from W (setKey.params.*.fromW: "W.door: 0 shut, 1 open", "W.win: 0 shut, 1 open"; the
  // old background's key was "bal" + W.door + "_" + W.win)
  @override
  String setKey(Map<String, dynamic> W) => BalconState(
    door: jsTruthy(W['door']) ? 'open' : 'shut',
    win: jsTruthy(W['win']) ? 'open' : 'shut',
  ).key;

  @override
  void buildSet(PpEngine e, PpBuild b, Map<String, dynamic> W) =>
      buildSetFor(e, b, setKey(W));

  @override
  void buildSetFor(PpEngine e, PpBuild b, String key) {
    final s = BalconSet(e, b, BalconState.fromKey(key));
    // the first bake of a state also records which part drew each pixel (the sheet's front: the furniture's own pixels)
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

  // the sheet's shadows, as balcon-preview.html casts them: the frog (W.cq.vis, more than half in, not sitting on the
  // small chair) at .3 with his radius, from the ground point under his feet on screen (unproject(b.x + b.w / 2,
  // q.y + 25)); abuela standing (not en silla; no `al` or more than half in) at .3, .65, 1, 1.35, 1.7 with hers, from
  // the ground point under her feet on screen (unproject(ab.x, ab.y - 1)).
  @override
  List<ShadowCast> shadows(Map<String, dynamic> W) {
    final out = <ShadowCast>[];
    final e = _p.e, sh = sheet.shadows;
    final q = W['cq'] as Map<String, dynamic>?;
    if (q != null) {
      final L = LUGAR['silla_pequena']!;
      final sent =
          ((q['x'] as num) - L[0]).abs() < 3 &&
          ((q['y'] as num) - L[1]).abs() < 3 &&
          !jsTruthy(q['dy']);
      if (jsTruthy(q['vis']) && _moreThanHalf(q['al']) && !sent) {
        final b = frogBox(q),
            g = e.unproject(b.x + b.w / 2, (q['y'] as num) + 25);
        out.add((x: g.x, y: g.y, z: .3, r: sh['coqui']!.radius));
      }
    }
    final ab = W['ab'] as Map<String, dynamic>?;
    if (ab != null &&
        ab['en'] != 'silla' &&
        (ab['al'] == null || _moreThanHalf(ab['al']))) {
      final g = e.unproject(ab['x'] as num, (ab['y'] as num) - 1),
          r = sh['abuela']!.radius;
      for (final z in const [.3, .65, 1.0, 1.35, 1.7]) {
        out.add((x: g.x, y: g.y, z: z, r: r));
      }
    }
    return out;
  }

  // JavaScript: `al > .5` (a missing `al` is not more than half)
  static bool _moreThanHalf(Object? al) => al is num && al > .5;

  /* ---------- the furniture in front: the sheet's front ---------- */

  PpEngine? _frameEngine;
  Uint32List? _setFrame;
  Float32List? _setZ;
  Map<String, Int32List>? _frontNow;

  // the set as this frame shows it (wind, shadows), before the sprite layer (drawFrame's step 4)
  @override
  void setFramed(PpEngine engine, BakedSet baked, Map<String, dynamic> W) {
    _frameEngine = engine;
    _setFrame = Uint32List.fromList(engine.pix);
    _setZ = baked.zb;
    _frontNow = _frontPixels[setKey(W)];
  }

  // balcon-preview.html: PREVIEW.front (sheet: front). A piece of furniture's own pixels, drawn again at its old line,
  // only where that pixel is nearer than abuela: bakedZ[i] > vAb / COS - (row + .5 - OY) * tan 30 / S. A frame drawn
  // with no set (a player with no screen draws the sprite layer on a scratch picture) has none to draw again.
  void front(String part) {
    final ab = W['ab'] as Map<String, dynamic>?;
    if (ab == null || ab['al'] == 0) return;
    final e = _frameEngine, s = _setFrame, Z = _setZ;
    if (e == null || s == null || Z == null) return;
    final list = _frontNow?[part];
    if (list == null) {
      throw StateError(
        'balcon: the part tags of the state ${setKey(W)} are not known: its set was not baked by this scene',
      );
    }
    final COS = math.sqrt(3) / 2, T30 = math.tan(math.pi / 6);
    final List<num> wp;
    if (ab['en'] == 'silla') {
      wp = sheet.points['ABS']!.world;
    } else {
      final u = ((ab['x'] as num) - e.OX) / e.S,
          v = ((ab['y'] as num) - 1 - e.OY + .3 * COS * e.S) / (e.S * .5);
      wp = [(u + v) / math.sqrt2, (v - u) / math.sqrt2, .3];
    }
    final vAb = (wp[0] + wp[1]) / math.sqrt2;
    final pix = e.pix, W0 = e.W;
    for (final i in list) {
      final row = i ~/ W0;
      if (!(Z[i] > vAb / COS - (row + .5 - e.OY) * T30 / e.S)) continue;
      pix[i] = 0xFF000000 | (s[i] & 0xFFFFFF);
    }
  }

  /* ---------- drawing ---------- */

  // balcon.js: GL.sol, GL.jugo, GL.agua, GL.equis (and their GC), Object.assign(BUBL, ...)
  void _glyphs(SceneHost h) {
    final GL = h.lib.GL, GC = h.lib.GC;
    GL['sol'] = const [
      '...#...',
      '.#.#.#.',
      '..###..',
      '#######',
      '..###..',
      '.#.#.#.',
      '...#...',
    ];
    GC['sol'] = hexColour('#F0A010');
    // a glass of juice, with its straw
    GL['jugo'] = const [
      '.....oo',
      'o....oo',
      'o#####o',
      'o#w###o',
      'o#w###o',
      'o#####o',
      'o#####o',
      'o#####o',
      '.ooooo.',
    ];
    GC['jugo'] = JUGO[1];
    // a glass of water, with ice
    GL['agua'] = const [
      'o.....o',
      'o.....o',
      'o#####o',
      'o#w#w#o',
      'o#w###o',
      'o###w#o',
      'o#####o',
      'o#####o',
      '.ooooo.',
    ];
    GC['agua'] = AGUA[1];
    GL['equis'] = const ['#...#', '.#.#.', '..#..', '.#.#.', '#...#'];
    GC['equis'] = hexColour('#D0403A');
    h.BUBL.addAll(const {
      'calor': ['sol', 'sad'],
      'no': ['equis'],
      'q': ['q'],
      'quiere_agua': ['agua'],
      'no_jugo_si_agua': ['jugo', 'equis', 'agua'],
      'jugo_q': ['jugo', 'q'],
      'agua_q': ['agua', 'q'],
      'feliz': ['ok'],
    });
  }

  /* ---------- where things are ---------- */

  // balcon.js: X2 (sheet: points mesa.izq, mesa.der), MESA_Y (sheet: MESA_Y), ABS, PERCH, ASIENTO (sheet: points).
  // X4 is never read; SILLA and SILLITA placed the chairs' sprites: the set draws them (sheet: dropped)
  late final List<int> X2;
  late final int MESA_Y;
  late final List<int> ABS, PERCH, ASIENTO;

  // order 30b: the tail of her bubble while she sits and the score boards are up (sheet: point talk.lado; code line 158)
  late final List<int> _talkLado;

  // balcon.js: AB, where abuela stands (her feet) (sheet: spots abuela.puerta, abuela.mesa, abuela.lado)
  late final Map<String, List<int>> AB;

  // balcon.js: LUGAR (sheet: lugar)
  late final Map<String, List<num>> LUGAR;

  // balcon.js:126 and :141, `ab.y < 144` (sheet: behind)
  late final int BEHIND;

  // the table's middle x (sheet: point mesa.centro; balcon.js: the 120 of dos("sm"), aveva and aparta), the right place's
  // x (mesa.der: recibe's 132), her half fan on the table (mesa.abanico: order 30b, at the table's front, its y too),
  // the two halves on the floor (suelo.abanico.*)
  late final int _centro, _derX;
  late final List<int> _fanMesa, _suelo1, _suelo2;

  // acts.sube: the foot of the steps (sheet: spot sube; its x is jardin's)
  late final int _subeY;

  // abCaja in her chair (sheet: things.abuela.box.silla.new)
  late final List<int> _abSilla;

  // the doorway's clip (sheet: clips puerta.hueco)
  late final List<List<num>> _door;

  @override
  late final Map<String, List<num>> CAM;

  @override
  late final List<num> heartAt;

  @override
  Map<String, List<num>> get lugar => LUGAR;

  // balcon.js: IDS
  static const List<String> IDS = [
    'jugo',
    'agua',
    'vaso_silla',
    'vaso_mesa',
    'vaso_grande',
    'vaso_pequeno',
  ];

  // balcon.js: enMesa
  Map<String, dynamic>? enMesa(Object? id) {
    for (final v in _ms(W['vasos'])) {
      if (v['id'] == id) return v;
    }
    for (final v in _ms(W['jarras'])) {
      if (v['id'] == id) return v;
    }
    return null;
  }

  // balcon.js: cajaDe
  List<num> cajaDe(Map<String, dynamic> v) {
    if (jsTruthy(v['t'])) {
      final s = VT[v['t']]!,
          y = jsTruthy(v['y']) ? v['y'] as num : MESA_Y,
          x = v['x'] as num;
      return [_round(x - s[0] / 2) - 4, y - s[1] - 6, s[0] + 8, s[1] + 9];
    }
    return [(v['x'] as num) - 9, MESA_Y - 24, 26, 27];
  }

  // balcon.js: cosaMesa
  Thing cosaMesa(String id) => Thing(
    id: id,
    m: 0,
    si: (w) => enMesa(id) != null && !jsTruthy(enMesa(id)!['mano']),
    box: (Map<String, dynamic> w) => cajaDe(enMesa(id)!),
  );

  // balcon.js: abCaja
  List<num> abCaja(Map<String, dynamic> w) {
    final ab = w['ab'] as Map<String, dynamic>;
    return ab['en'] == 'silla'
        ? _abSilla
        : [_round(ab['x'] as num) - 13, _round(ab['y'] as num) - 50, 26, 50];
  }

  // balcon.js: COSAS
  @override
  late final List<Thing> cosas;

  @override
  Map<String, dynamic> fresh(Map<String, dynamic> story) => {
    'door': 0,
    'win': 0,
    'ab': <String, dynamic>{
      'en': 'puerta',
      'x': AB['puerta']![0],
      'y': AB['puerta']![1],
      'pose': 'idle',
      'bub': null,
      'al': 1,
      'trae': 0,
    },
    'ave': null,
    'vasos': <dynamic>[],
    'jarras': <dynamic>[],
    'abvaso': null,
    'vierte': null,
    'sobre': 0,
    'abanico': 0,
    'trozos': 0,
    'enSuelo': 0,
    'fuente': 0,
    'fanMedio': 0,
    'bebiendo': 0,
    'vmios': null,
    'vsuyos': null,
    'cqfan': 0,
    'fanMesa': 0,
    'calor': 0,
    'fresco': 0,
    'sudor': 0,
    'rojo': 0,
    'azul': 0,
    'splash': 0,
    'rondas': 0,
    'mios': 0,
    'termo': 0,
    'cq': <String, dynamic>{
      'x': LUGAR['jardin']![0],
      'y': LUGAR['jardin']![1],
      's': 1,
      'dy': 0,
      'al': 1,
      'vis': 1,
      'bub': null,
    },
  };

  // balcon.js: bub2
  // picture bubbles are drawn at twice their size here, so they read on a phone
  void bub2(Ctx c, String k, num tx, num ty, int a) {
    c.save();
    c.translate(tx.toDouble(), ty.toDouble());
    c.scale(2, 2);
    host.bub(c, k, 0, 0, a);
    c.restore();
  }

  // balcon.js: rana
  void rana(Ctx g, Map<String, dynamic> q, int a) {
    final b = frogBox(q),
        bl = (F % 47) < 2 ? 1 : 0,
        op = (q['bub'] == 'hola' || host.TALK == 'coqui') && a % 2 != 0 ? 1 : 0;
    // balcon.js:117 `sent` (sitting on the small chair) only kept the dotted shadow off: balcon.js:118, the shadow, is
    // dropped (the engine casts his: sheet shadows.coqui, which reads `sent` itself)
    final s = q['s'] as num;
    g.drawImage(
      host.lib.spr('cq${jsNum(s)}_$bl$op', () => mkCoqui(s, bl, op != 0)),
      b.x,
      b.y + _round(q['dy'] as num),
    );
  }

  // balcon.js: draw
  @override
  void draw(Ctx c, Map<String, dynamic> W, int a) {
    final q = W['cq'] as Map<String, dynamic>,
        ab = W['ab'] as Map<String, dynamic>?;
    // balcon.js:121 c.drawImage(bg) -> the set, for setKey(W)
    final habla = ab != null && (host.TALK == 'abuela' && a % 2 != 0) ? 1 : 0;
    void dePie() {
      final ab = W['ab'] as Map<String, dynamic>;
      final pose = ab['pose'] == 'wave'
              ? 'wave${a % 2}'
              : (ab['pose'] == 'offer' || jsTruthy(ab['trae']))
              ? 'offer'
              : 'idle',
          x = _round(ab['x'] as num) - 30,
          y = _round(ab['y'] as num) - 50;
      c.globalAlpha = ab['al'] == null ? 1 : (ab['al'] as num).toDouble();
      Sprite im() =>
          host.lib.spr('ab$pose$habla', () => mkAbuela(pose, habla != 0));
      if (ab['en'] == 'puerta') {
        // the doorway (sheet: clips puerta.hueco)
        c.save();
        clipToWorld(c, _p.e, _door);
        c.drawImage(im(), x, y);
        c.restore();
      } else {
        c.drawImage(im(), x, y);
      }
      if (jsTruthy(ab['trae'])) {
        fr(c, x + 1, y + 26, 22, 3, OUT);
        fr(c, x + 2, y + 26, 20, 2, RP.wood[3]);
        vaso(c, x + 7, y + 26, 'n', 'jugo', 1);
        vaso(c, x + 18, y + 26, 'n', 'agua', 1);
      }
      c.globalAlpha = 1;
    }

    // behind the furniture
    if (ab != null && ab['en'] != 'silla' && (ab['y'] as num) < BEHIND) {
      dePie();
    }
    // balcon.js:127 the big chair's sprite -> the set (sheet: front silla_grande)
    front('silla_grande');
    if (ab != null &&
        ab['en'] == 'silla' &&
        (ab['al'] is num && (ab['al'] as num) > 0)) {
      final f = ab['pose'] == 'fan' ? 'fan${(F >> 2) % 2}' : ab['pose'],
          pose = const ['fan0', 'fan1', 'vaso', 'bebe', 'zzz'].contains(f)
              ? f as String
              : 'idle';
      c.drawImage(
        host.lib.spr(
          'abS$pose$habla',
          () => mkAbuelaS(pose, habla != 0, false),
        ),
        ABS[0],
        ABS[1],
      );
      if (ab['pose'] == 'fan') {
        final d = (F >> 2) % 2;
        if (jsTruthy(W['fanMedio'])) {
          medio(c, ABS[0] + 31 + d, ABS[1] + 16, 1);
        } else {
          abanico(c, ABS[0] + 31 + d, ABS[1] + 16, 8, -60, 60);
        }
      }
      final abvaso = W['abvaso'] as Map<String, dynamic>?;
      if (abvaso != null) {
        final bb = ab['pose'] == 'bebe';
        vaso(
          c,
          ABS[0] + (bb ? 30 : 36),
          ABS[1] + (bb ? 17 : 28),
          'n',
          abvaso['k'] as String,
          abvaso['lv'] as num,
        );
      }
      // she tips the water jug over her own head
      if (jsTruthy(W['sobre'])) {
        c.save();
        c.translate((ABS[0] + 30).toDouble(), (ABS[1] - 2).toDouble());
        c.rotate(-1.05);
        jarra(c, 0, 8, 'agua');
        c.restore();
        for (var i = 0; i < 5; i++) {
          fr(
            c,
            ABS[0] + 16 + (i % 2),
            ABS[1] - 10 + ((F * 2 + i * 3).remainder(12)),
            2,
            3,
            i % 2 != 0 ? AGUA[1] : _white,
          );
        }
      }
      // she is hot: drops of sweat
      for (var k = 0; k < _n(W['sudor']); k++) {
        final t = (F + k * 5).remainder(12);
        gota(
          c,
          ABS[0] + 17 + (k - 1) * (8 + t),
          ABS[1] + 6 - _round(t * 1.2) + _round(t * t / 9),
        );
      }
    }
    // balcon.js:135, :136 the small chair's and the table's sprites -> the set (sheet: front silla_pequena, mesa)
    front('silla_pequena');
    front('mesa');
    for (final v in _ms(W['vasos'])) {
      if (!jsTruthy(v['mano'])) {
        vaso(
          c,
          v['x'] as num,
          jsTruthy(v['y']) ? v['y'] as num : MESA_Y,
          v['t'] as String,
          v['k'] as String,
          v['lv'] as num,
        );
      }
    }
    if (jsTruthy(W['fanMesa'])) medio(c, _fanMesa[0], _fanMesa[1], 1);
    // the two halves of her fan, on the floor
    if (jsTruthy(W['enSuelo'])) {
      medio(c, _suelo1[0], _suelo1[1], -1);
      medio(c, _suelo2[0], _suelo2[1], 1);
    }
    for (final v in _ms(W['jarras'])) {
      if (!jsTruthy(v['mano'])) {
        jarra(c, v['x'] as num, MESA_Y, v['k'] as String);
      }
    }
    if (ab != null && ab['en'] != 'silla' && (ab['y'] as num) >= BEHIND) {
      dePie();
    }
    // the two halves of her paper fan fall
    if (jsTruthy(W['trozos']) && F - (W['trozos'] as num) < 14) {
      final t = F - (W['trozos'] as num);
      medio(c, _round(ABS[0] + 34 - t), ABS[1] + 16 + t * 3, -1);
      medio(c, _round(ABS[0] + 38 + t * .5), ABS[1] + 16 + t * 3, 1);
    }
    if (jsTruthy(q['vis'])) {
      c.globalAlpha = (q['al'] as num).toDouble();
      rana(c, q, a);
      c.globalAlpha = 1;
      final b = frogBox(q), dy = _round(q['dy'] as num);
      // drops of sweat: one for every drink he still needs
      for (var k = 0; k < _n(W['calor']); k++) {
        final t = (F + k * 5).remainder(12),
            x = b.x + _round(b.w / 2) + (k - 1) * (7 + t),
            y = b.y + dy + 3 - _round(t * 1.4) + _round(t * t / 9);
        gota(c, x, y);
      }
      // his half of the fan: he keeps it, and fans himself
      if (jsTruthy(W['cqfan'])) {
        medio(c, b.x - 2 + ((F >> 2) % 2), b.y + dy + _round(b.h * .6), -1);
      }
      // a little fountain
      if (jsTruthy(W['fuente'])) {
        final t = F - (W['fuente'] as num);
        for (var i = 0; i < 10; i++) {
          final u = ((t * 2 + i * 3).remainder(20)) / 20,
              x = b.x + b.w / 2 + (i % 2 != 0 ? 1 : -1) * u * 14,
              y = b.y + dy + 6 - _round(34 * u * (1 - u) * 2.2) + _round(u * 8);
          fr(c, _round(x), y, 2, 2, i % 3 != 0 ? AGUA[1] : _white);
        }
      }
      Map<String, dynamic>? m;
      for (final v in _ms(W['vasos'])) {
        if (jsTruthy(v['mano'])) {
          m = v;
          break;
        }
      }
      if (m != null) {
        if (jsTruthy(W['bebiendo'])) {
          vaso(
            c,
            b.x + _round(b.w / 2) + 1,
            b.y + dy + _round(b.h * .74),
            m['t'] as String,
            m['k'] as String,
            m['lv'] as num,
          );
        } else {
          vaso(
            c,
            b.x + b.w + 1,
            b.y + dy + _round(b.h * .8),
            m['t'] as String,
            m['k'] as String,
            m['lv'] as num,
          );
        }
      }
      Map<String, dynamic>? j;
      for (final v in _ms(W['jarras'])) {
        if (v['mano'] == 1) {
          j = v;
          break;
        }
      }
      if (j != null) jarra(c, b.x + b.w + 7, b.y + dy + b.h, j['k'] as String);
    }
    // pouring into her glass
    if (jsTruthy(W['vierte'])) {
      final x = ABS[0] + 36, y0 = ABS[1] + 8;
      for (var i = 0; i < 7; i++) {
        fr(
          c,
          x,
          y0 + ((i * 2 + F).remainder(12)),
          1,
          2,
          W['vierte'] == 'agua' ? AGUA[1] : JUGO[1],
        );
      }
    }
    drawAve(c, W['ave'] as Map<String, dynamic>?);
    // water splashes off her head and shoulders
    if (jsTruthy(W['splash'])) {
      final t = F - (W['splash'] as num);
      for (var i = 0; i < 22; i++) {
        final u = ((t * 2 + i * 5).remainder(24)) / 24,
            dir = i % 2 != 0 ? 1 : -1,
            x = ABS[0] + 17 + dir * (4 + u * (8 + i % 7 * 2)),
            y = ABS[1] + 2 + _round(u * u * 44) - _round(u * 10);
        fr(c, _round(x) - 1, y - 1, 4, 4, OUT);
        fr(c, _round(x), y, 2, 2, i % 3 != 0 ? AGUA[1] : _white);
      }
      fr(c, ABS[0] + 2, ABS[1] + 50, 34, 2, AGUA[1]);
      fr(c, ABS[0] + 6, ABS[1] + 52, 26, 1, AGUA[2]);
    }
    if (jsTruthy(W['rojo']) && F - (W['rojo'] as num) < 5) {
      c.fillStyle = _flare;
      c.fillRect(0, 0, SW, SH);
    }
    if (ab != null && jsTruthy(ab['bub'])) {
      final at = talkAt('abuela', W)!;
      bub2(c, ab['bub'] as String, at[0], at[1] + 38, a);
    }
    if (jsTruthy(q['vis']) && jsTruthy(q['bub'])) {
      final b = frogBox(q);
      bub2(c, q['bub'] as String, b.x + (b.w.toInt() >> 1), b.y + 2, a);
    }
    // the set as framed is this frame's only (drawFrame gives it again before the next)
    _frameEngine = null;
    _setFrame = null;
    _setZ = null;
  }

  // balcon.js: talkAt
  @override
  List<num>? talkAt(String who, Map<String, dynamic> W) {
    final ab = W['ab'] as Map<String, dynamic>?;
    if (who != 'abuela' || ab == null) return null;
    final al = ab['al'];
    if (al is num && al < .5) return null;
    final bub = jsTruthy(ab['bub']);
    return ab['en'] == 'silla'
        ? (jsTruthy(W['rondas'])
              ? [_talkLado[0], _talkLado[1] - (bub ? 38 : 0)]
              : [ABS[0] + 17, ABS[1] - (bub ? 39 : 1)])
        : [
            _round(ab['x'] as num),
            _round(ab['y'] as num) - 51 - (bub ? 38 : 0),
          ];
  }

  // balcon.js: respIcon
  // the picture answers of the Say move: a glass of juice, a glass of water
  @override
  dynamic respIcon(Ctx c, String k, num x, num y, num w, num h, int a) {
    vaso(c, x + w / 2, y + h - 7, 'g', k, 1);
    return null;
  }

  /* ---------- what is at stake, in the corner of the screen ---------- */

  // balcon.js: tanteo
  void tanteo(Ctx g, num x, num y, num n, String who) {
    final ic = who == 'cq'
            ? host.lib.spr('cq.7_0', () => mkCoqui(.7, 0, false))
            : host.lib.spr('kaven0', () => mkAve('n', false)),
        gx = who == 'cq' ? x + 27 : x + 3,
        ix = who == 'cq' ? x + 1 : x + 45;
    tarjeta(g, x - 2, y - 2, who == 'cq' ? 70 : 68, 25);
    g.drawImage(ic, ix, y + (who == 'cq' ? 0 : 4));
    final ks = (who == 'cq' ? W['vmios'] : W['vsuyos']) as List? ?? const [];
    for (var i = 0; i < 3; i++) {
      mini(
        g,
        gx + i * 14,
        y + 3,
        i < n ? (i < ks.length && jsTruthy(ks[i]) ? ks[i] : 'agua') : 0,
      );
    }
  }

  // balcon.js: termo
  void termo(Ctx g, num x, num y, int n, int a) {
    final hot = n >= 3 && a % 2 != 0,
        m = math.min(3, n),
        red = hot ? _termoHot : _termoRed;
    tarjeta(g, x - 3, y - 3, 50, 62);
    fr(g, x + 1, y - 1, 12, 45, OUT);
    fr(g, x + 2, y, 10, 44, _white);
    g.fillStyle = OUT;
    g.beginPath();
    g.arc(x + 7, y + 47, 9, 0, 7);
    g.fill();
    g.fillStyle = red;
    g.beginPath();
    g.arc(x + 7, y + 47, 7.5, 0, 7);
    g.fill();
    // five marks; it starts on the third
    final hgt = const [4, 13, 22, 31, 40][n];
    fr(g, x + 5, y + 42 - hgt, 4, hgt + 3, red);
    for (var i = 0; i < 5; i++) {
      fr(g, x + 12, y + 2 + i * 9, 4, 1, OUT);
    }
    final sx = x + 31, sy = y + 16, r = 5 + m;
    g.fillStyle = OUT;
    g.beginPath();
    g.arc(sx, sy, r + 1, 0, 7);
    g.fill();
    g.fillStyle = n >= 3
        ? _sun3
        : n != 0
        ? _sun1
        : _sun0;
    g.beginPath();
    g.arc(sx, sy, r, 0, 7);
    g.fill();
    if (n != 0) {
      for (var k = 0; k < 8; k++) {
        final an = k * math.pi / 4 + (a % 2 != 0 ? .2 : 0);
        fr(
          g,
          _round(sx + math.cos(an) * (r + 3)) - 1,
          _round(sy + math.sin(an) * (r + 3)) - 1,
          2,
          2,
          n >= 3 ? _sun3 : _sun1,
        );
      }
    }
  }

  // balcon.js: hud
  @override
  void hud(Ctx c, Map<String, dynamic> W, int a) {
    final g = c;
    if (jsTruthy(W['rondas'])) {
      tanteo(g, 5, 5, _n(W['mios']), 'cq');
      tanteo(g, host.DW - 71, 5, _n(W['lost']), 'ave');
    }
    if (jsTruthy(W['termo'])) termo(g, host.DW - 51, 7, nivel(W), a);
  }

  /* ---------- what can happen here ---------- */

  // balcon.js: glu, chorro, azar
  void glu() => host.tone(300, 0, .09, 'sine', .09, 170);
  void chorro() {
    for (var i = 0; i < 4; i++) {
      host.tone(700 + i * 90, i * .07, .08, 'sine', .05, 500);
    }
  }

  // DECISION(order 30b): the scene's random draws come from the game's one Rng, as Math.random was one: the one the registry's
  // factory is given (`createBalcon`, from the story runner's `rng`)
  Rng get _rng =>
      _rngGiven ??
      (throw StateError(
        'El balcón was made without a random source (Rng) but draws a random number',
      ));
  bool azar() => _rng.next() < .5;

  // balcon.js: abCamina
  Future<void> abCamina(num tx, num ty) async {
    final ab = W['ab'] as Map<String, dynamic>;
    if (ab['en'] == 'silla') {
      ab['x'] = AB['lado']![0];
      ab['y'] = AB['lado']![1];
    }
    ab['en'] = 'camina';
    if (ab['pose'] != 'offer') ab['pose'] = 'idle';
    final x0 = ab['x'] as num,
        y0 = ab['y'] as num,
        dx = tx - x0,
        dy = ty - y0,
        n = math.max(3, _round(math.sqrt(dx * dx + dy * dy) / 6));
    for (var i = 1; i <= n; i++) {
      ab['x'] = x0 + (tx - x0) * i / n;
      ab['y'] = y0 + (ty - y0) * i / n - (i % 2);
      await wait(host.TICK);
    }
    ab['x'] = tx;
    ab['y'] = ty;
  }

  // balcon.js: dos
  // the glasses abuela fills: one is his, one is hers. Where each one stands is drawn fresh.
  List<Map<String, dynamic>> dos(Object? que) {
    final s = azar() ? 0 : 1;
    Map<String, dynamic> g(String id, String k, String t, num x, [num? y]) => {
      'id': id,
      'k': k,
      't': t,
      'lv': 1,
      'x': x,
      'y': y,
    };
    if (que == 'gp') {
      return [
        g('vaso_grande', 'jugo', 'g', X2[s]),
        g('vaso_pequeno', 'jugo', 'p', X2[1 - s]),
      ];
    }
    // one on the small chair, one on the table
    if (que == 'sm') {
      return [
        g('vaso_silla', 'agua', 'n', ASIENTO[0], ASIENTO[1] - 1),
        g('vaso_mesa', 'agua', 'n', _centro),
      ];
    }
    if (que == 'fin') {
      return [g('fin1', 'agua', 'n', X2[0]), g('fin2', 'agua', 'n', X2[1])];
    }
    return [g('jugo', 'jugo', 'n', X2[s]), g('agua', 'agua', 'n', X2[1 - s])];
  }

  // balcon.js: brillo
  void brillo() => host.fx({
    't': 'star',
    'n': 8,
    'pts': [
      for (final v in _ms(W['vasos']))
        [v['x'], (jsTruthy(v['y']) ? v['y'] as num : MESA_Y) - 20],
    ],
  });

  // balcon.js: acts.ir (the kit's), as the old acts call it
  Future<void> ir(String a) => acts['ir']!({'a': a});

  Map<String, dynamic>? _vMano() {
    for (final v in _ms(W['vasos'])) {
      if (jsTruthy(v['mano'])) return v;
    }
    return null;
  }

  Map<String, dynamic>? _vId(Object? id) {
    for (final v in _ms(W['vasos'])) {
      if (v['id'] == id) return v;
    }
    return null;
  }

  Map<String, dynamic> get _ab => W['ab'] as Map<String, dynamic>;
  Map<String, dynamic> get _cq => W['cq'] as Map<String, dynamic>;
  Map<String, dynamic>? get _abvaso => W['abvaso'] as Map<String, dynamic>?;

  // balcon.js: acts
  @override
  late final Map<String, Act> ownActs = {
    'sube': (o) async {
      await host.hopTo(LUGAR['jardin']![0], _subeY, 1, .9);
      await host.hopTo(
        LUGAR['balcon']![0],
        LUGAR['balcon']![1],
        2,
        LUGAR['balcon']![2],
      );
    },
    // abuela walks to her chair and sits down
    'absienta': (o) async {
      final ab = _ab;
      if (ab['en'] == 'silla') return;
      ab['pose'] = 'idle';
      ab['trae'] = 0;
      await abCamina(AB['lado']![0], AB['lado']![1]);
      await wait(150);
      ab['en'] = 'silla';
      SFX.blip();
      await wait(450);
    },
    // she gets up and goes in through the door
    'abentra': (o) async {
      final ab = _ab;
      await abCamina(AB['puerta']![0], AB['puerta']![1]);
      ab['en'] = 'puerta';
      for (var i = 4; i >= 0; i--) {
        ab['al'] = i / 5;
        await wait(host.TICK);
      }
      await wait(200);
    },
    // and comes back with two glasses for the table
    'absale': (o) async {
      final ab = _ab;
      ab['trae'] = 1;
      ab['en'] = 'puerta';
      for (var i = 1; i <= 5; i++) {
        ab['al'] = i / 5;
        await wait(host.TICK);
      }
      await abCamina(AB['mesa']![0], AB['mesa']![1]);
      await wait(200);
    },
    'pone2': (o) async {
      _ab['trae'] = 0;
      W['vasos'] = dos('ja');
      SFX.blip();
      brillo();
      await wait(450);
    },
    // she fills fresh glasses
    'sirve': (o) async {
      final ab = W['ab'] as Map<String, dynamic>?;
      if (ab != null && ab['en'] == 'silla') ab['pose'] = 'vaso';
      W['vasos'] = dos(o['que']);
      chorro();
      brillo();
      await wait(650);
    },
    // the frog picks a glass up from the table, puts it back, or drinks the one he holds
    'coge': (o) async {
      final v = enMesa(o['en']);
      await ir('mesa');
      if (v == null) return;
      await wait(120);
      v['mano'] = 1;
      SFX.blip();
      await wait(350);
    },
    'suelta': (o) async {
      final v = _vMano();
      if (v != null) {
        await wait(150);
        v['mano'] = 0;
        SFX.blip();
        await wait(250);
      }
    },
    'bebecq': (o) async {
      final v = _vMano();
      if (v == null) return;
      W['bebiendo'] = 1;
      await wait(200);
      for (final l in const [.66, .33, 0]) {
        v['lv'] = l;
        glu();
        host.bounce(3);
        await wait(320);
      }
      W['bebiendo'] = 0;
      W['ultimo'] = v['k'];
      W['calor'] = math.max(0, _n(W['calor']) - 1);
      SFX.luz();
      await wait(200);
      v['mano'] = 0;
      await wait(200);
    },
    // abuela takes a glass (from the table, or back out of the frog's hand) and drinks it: that one was hers
    'abcoge': (o) async {
      final v = _vId(o['en']);
      if (v == null) return;
      await wait(150);
      W['vasos'] = [
        for (final x in _ms(W['vasos']))
          if (!identical(x, v)) x,
      ];
      _ab['pose'] = 'vaso';
      W['abvaso'] = <String, dynamic>{'k': v['k'], 'lv': v['lv']};
      SFX.blip();
      await wait(350);
    },
    'abbebe': (o) async {
      final ab = _ab;
      if (_abvaso == null) return;
      ab['pose'] = 'bebe';
      for (final l in const [.66, .33, 0]) {
        _abvaso!['lv'] = math.min(_abvaso!['lv'] as num, l);
        glu();
        await wait(300);
      }
      ab['pose'] = 'vaso';
      await wait(250);
      W['abvaso'] = null;
    },
    'aveventana': (o) => aveventana(),
    // the bird flies down beside a glass, drinks it, and goes to sit on the small chair
    'aveva': (o) async {
      final v = _vId(o['en']);
      if (v == null) return;
      final lado = (v['x'] as num) < _centro ? 1 : -1;
      await aveVa(
        (v['x'] as num) + lado * 19,
        jsTruthy(v['y']) ? v['y'] as num : MESA_Y,
        9,
        -lado,
      );
      SFX.pio();
      await wait(250);
    },
    'avebebe': (o) async {
      final v = _vId(o['en']), a = W['ave'] as Map<String, dynamic>?;
      if (v == null || a == null) return;
      W['ultimoAve'] = v['k'];
      for (final l in const [.66, .33, 0]) {
        a['dip'] = 3;
        v['lv'] = l;
        glu();
        await wait(240);
        a['dip'] = 0;
        await wait(160);
      }
      a['st'] = 'feliz';
      SFX.pio();
      await wait(450);
      a['st'] = 'n';
    },
    'avesilla': (o) async {
      await aveVa(ASIENTO[0], ASIENTO[1], 9, -1);
      SFX.pio();
      await wait(350);
    },
    'gana': (o) async {
      W['mios'] = _n(W['mios']) + 1;
      final l = (W['vmios'] as List?) ?? (W['vmios'] = <dynamic>[]);
      l.add(jsTruthy(W['ultimo']) ? W['ultimo'] : 'agua');
      SFX.right();
      _cq['bub'] = 'amor';
      await wait(800);
      _cq['bub'] = null;
    },
    // the ending of El jugo: who drank more decides who gets the small chair
    'marcador': (o) async {
      final a = W['ave'] as Map<String, dynamic>?,
          mio = _n(W['mios']),
          suyo = _n(W['lost']),
          gano = mio > suyo,
          amigo = V['mem_amigo'] == '1';
      if (W['ab'] != null) _ab['pose'] = 'idle';
      W['vasos'] = <dynamic>[];
      await host.camGo('wide', 9);
      if (gano || amigo) {
        if (a != null) await aveventana();
        await ir('silla_pequena');
        if (gano) {
          W['heart'] = 1;
          SFX.win();
          if (mio >= 3) {
            host.fx({
              't': 'star',
              'n': 30,
              'pts': [
                [60, 50],
                [180, 54],
                [120, 42],
                [96, 64],
                [150, 60],
              ],
            });
          }
        } else {
          _cq['bub'] = 'amor';
          SFX.coqui();
        }
      } else {
        if (a != null) {
          await aveVa(ASIENTO[0], ASIENTO[1], 9, -1);
          a['st'] = 'round';
          SFX.pio();
        }
        await ir('balcon');
        _cq['bub'] = 'mal';
        SFX.coqui();
      }
      await wait(700);
      _cq['bub'] = null;
    },
    /* ---- story 5: abuela is hot ---- */
    // the frog carries a jug to her and fills her glass
    'lleva': (o) async {
      final j = enMesa(o['en']);
      if (j == null) return;
      await ir('mesa');
      await wait(120);
      j['mano'] = 1;
      SFX.blip();
      await wait(250);
      await ir('abuela');
      _ab['pose'] = 'vaso';
      W['abvaso'] = <String, dynamic>{'k': o['en'], 'lv': 0};
      await wait(200);
      W['vierte'] = o['en'];
      chorro();
      for (final l in const [.4, .7, 1]) {
        _abvaso!['lv'] = l;
        await wait(170);
      }
      W['vierte'] = null;
      await wait(250);
      await ir('mesa');
      j['mano'] = 0;
      await wait(150);
      await ir('decir');
    },
    // she drinks, and cools down a step
    'bebe': (o) async {
      final ab = _ab;
      if (_abvaso == null) return;
      ab['pose'] = 'bebe';
      for (final l in const [.66, .33, 0]) {
        _abvaso!['lv'] = l;
        glu();
        await wait(330);
      }
      ab['pose'] = 'vaso';
      W['fresco'] = _n(W['fresco']) + 1;
      W['azul'] = F;
      W['sudor'] = math.min(3, nivel(W));
      SFX.luz();
      await wait(500);
      W['abvaso'] = null;
      ab['pose'] = jsTruthy(W['abanico']) ? 'fan' : 'idle';
    },
    // she will not drink that one: she puts the glass down on the table, and it stays there
    'aparta': (o) async {
      if (_abvaso == null) return;
      final k = _abvaso!['k'];
      await wait(300);
      W['abvaso'] = null;
      (W['vasos'] as List).add(<String, dynamic>{
        'id': 'aparte',
        'k': k,
        't': 'n',
        'lv': 1,
        'x': _centro,
      });
      SFX.blip();
      await wait(400);
      _ab['pose'] = jsTruthy(W['abanico']) ? 'fan' : 'idle';
    },
    // the frog, eager, holds up a jug to show her; then puts it back
    'muestra': (o) async {
      final j = enMesa(o['en']);
      if (j == null) return;
      await ir('mesa');
      await wait(120);
      j['mano'] = 1;
      SFX.blip();
      host.bounce(4);
      await wait(300);
    },
    'deja': (o) async {
      for (final j in _ms(W['jarras'])) {
        if (j['mano'] == 1) j['mano'] = 0;
      }
      SFX.blip();
      await wait(250);
      await ir('decir');
    },
    // he picks up the two halves of her fan and gives them to her. She fans herself with one half, and keeps it.
    'recoge': (o) async {
      await ir('abuela');
      await wait(150);
      W['enSuelo'] = 0;
      SFX.blip();
      host.bounce(4);
      await wait(350);
      W['abanico'] = 1;
      W['fanMedio'] = 1;
      _ab['pose'] = 'fan';
      SFX.luz();
      await wait(450);
      await ir('decir');
    },
    // her paper fan tears in two
    // she hands him the other half; or, after a wrong answer, it is left on the table
    'dafan': (o) async {
      await ir('abuela');
      _ab['bub'] = 'amor';
      await wait(300);
      W['cqfan'] = 1;
      SFX.luz();
      host.bounce(5);
      await wait(600);
      _ab['bub'] = null;
      await ir('decir');
    },
    'fanmesa': (o) async {
      W['fanMesa'] = 1;
      SFX.blip();
      await wait(500);
    },
    'rompe': (o) async {
      W['abanico'] = 0;
      _ab['pose'] = 'idle';
      W['trozos'] = F;
      host.tone(900, 0, .12, 'sawtooth', .05, 200);
      host.tone(500, .1, .15, 'sawtooth', .04, 120);
      W['sudor'] = 2;
      await wait(950);
      W['enSuelo'] = 1;
      await wait(300);
    },
    // she fills a glass for the frog and holds it out; he takes it
    'ofrece': (o) async {
      _ab['pose'] = 'vaso';
      W['abvaso'] = <String, dynamic>{'k': o['en'], 'lv': 1};
      chorro();
      await wait(500);
    },
    'recibe': (o) async {
      await ir('abuela');
      final k = _abvaso != null ? _abvaso!['k'] : 'agua';
      W['abvaso'] = null;
      _ab['pose'] = jsTruthy(W['abanico']) ? 'fan' : 'idle';
      (W['vasos'] as List).add(<String, dynamic>{
        'id': 'mio',
        'k': k,
        't': 'n',
        'lv': 1,
        'x': _derX,
        'mano': 1,
      });
      SFX.blip();
      await wait(250);
      await ir('decir');
    },
    // the two jugs on the table. Which side each is on is drawn fresh.
    'pone': (o) async {
      final s = azar() ? 0 : 1;
      W['jarras'] = [
        <String, dynamic>{'id': 'jugo', 'k': 'jugo', 'x': X2[s]},
        <String, dynamic>{'id': 'agua', 'k': 'agua', 'x': X2[1 - s]},
      ];
    },
    'cqbebe': (o) async {
      final v = _vMano();
      if (v == null) return;
      W['bebiendo'] = 1;
      await wait(200);
      for (final l in const [.66, .33, 0]) {
        v['lv'] = l;
        glu();
        host.bounce(3);
        await wait(320);
      }
      W['bebiendo'] = 0;
      W['vasos'] = [
        for (final x in _ms(W['vasos']))
          if (!identical(x, v)) x,
      ];
      _cq['bub'] = 'amor';
      await wait(600);
      _cq['bub'] = null;
    },
    // he drinks the water, and squirts a little fountain
    'cqhielo': (o) async {
      final v = _vMano();
      if (v == null) return;
      W['bebiendo'] = 1;
      await wait(200);
      for (final l in const [.66, .33, 0]) {
        v['lv'] = l;
        glu();
        host.bounce(3);
        await wait(320);
      }
      W['bebiendo'] = 0;
      W['vasos'] = [
        for (final x in _ms(W['vasos']))
          if (!identical(x, v)) x,
      ];
      W['fuente'] = F;
      chorro();
      host.bounce(6);
      await wait(1000);
      W['fuente'] = 0;
    },
    // the last picture, by how hot it got
    'final': (o) async {
      final ab = _ab, n = nivel(W);
      if (n <= 0) {
        ab['pose'] = 'idle';
        W['sudor'] = 0;
        ab['bub'] = 'feliz';
        await wait(1100);
        ab['bub'] = null;
      } else if (n == 1) {
        ab['pose'] = jsTruthy(W['abanico']) ? 'fan' : 'idle';
        W['sudor'] = 0;
        await wait(900);
      } else if (n == 2) {
        ab['pose'] = jsTruthy(W['abanico']) ? 'fan' : 'idle';
        W['sudor'] = 1;
        await wait(1000);
      } else {
        Map<String, dynamic>? j;
        for (final v in _ms(W['jarras'])) {
          if (v['k'] == 'agua') {
            j = v;
            break;
          }
        }
        if (j != null) j['mano'] = 2;
        ab['pose'] = 'bebe';
        W['sobre'] = 1;
        W['sudor'] = 0;
        await wait(450);
        W['splash'] = F;
        chorro();
        SFX.drop();
        await wait(300);
        SFX.drop();
        await wait(250);
        chorro();
        await wait(1500);
        W['sobre'] = 0;
        ab['pose'] = 'idle';
        if (j != null) j['mano'] = 0;
        W['fresco'] = 9;
        SFX.luz();
        await wait(500);
        W['splash'] = 0;
        ab['bub'] = 'feliz';
        await wait(900);
        ab['bub'] = null;
      }
    },
    'fin': (o) async {
      final stake = S['stake'] as Map<String, dynamic>;
      if (stake['thing'] == 'calor'
          ? !jsTruthy(W['lost'])
          : _n(W['mios']) > _n(W['lost'])) {
        W['heart'] = 1;
        SFX.win();
        host.fx({
          't': 'star',
          'n': 36,
          'pts': [
            [60, 50],
            [180, 54],
            [120, 42],
            [96, 64],
            [150, 60],
          ],
        });
      } else {
        SFX.coqui();
      }
      await wait(1600);
    },
  };

  // balcon.js: acts.aveventana
  Future<void> aveventana() async {
    final v = W['ave'] as Map<String, dynamic>?;
    if (v != null &&
        v['mode'] != 'none' &&
        ((v['x'] as num) - PERCH[0]).abs() +
                ((v['y'] as num) - PERCH[1]).abs() >
            3) {
      await aveVa(PERCH[0], PERCH[1], 9, -1);
      await wait(200);
    }
  }

  // balcon.js: stake
  // the thing at stake takes a step: the bird gets a glass, or the heat climbs
  @override
  Future<void> stake(int lost, int max, String en) async {
    // she waits; the sun flares; the thermometer climbs
    if ((S['stake'] as Map<String, dynamic>)['thing'] == 'calor') {
      W['rojo'] = F;
      W['sudor'] = math.min(3, nivel(W));
      host.tone(400, 0, .4, 'sawtooth', .03, 1200);
      await wait(800);
      return;
    }
    final l = (W['vsuyos'] as List?) ?? (W['vsuyos'] = <dynamic>[]);
    l.add(jsTruthy(W['ultimoAve']) ? W['ultimoAve'] : 'agua');
    SFX.munch();
    await wait(450);
  }

  // balcon.js: poke
  @override
  dynamic poke(String what) {
    if (what == 'pajaro') {
      SFX.pio();
    } else if (what == 'abuela' && W['ab'] != null && !jsTruthy(_ab['bub'])) {
      _ab['bub'] = 'amor';
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

  // balcon.js: estado
  @override
  String estado(Map<String, dynamic> W) {
    String r(Object? v) => v is num ? jsNum(_round(v)) : 'NaN';
    final ave = W['ave'] as Map<String, dynamic>?,
        abvaso = W['abvaso'] as Map<String, dynamic>?;
    final vasos = _ms(W['vasos'])
        .map(
          (v) =>
              '${v['id']}@${jsNum(v['x'] as num)}:${jsNum(v['lv'] as num)}${jsTruthy(v['mano']) ? 'm' : ''}',
        )
        .join(',');
    final jarras = _ms(W['jarras'])
        .map((v) => '${v['id']}${jsTruthy(v['mano']) ? 'm' : ''}')
        .join(',');
    return 'vasos=$vasos jarras=$jarras mios=${jsNum(_n(W['mios']))}'
        ' abvaso=${abvaso != null ? '${abvaso['k']}:${jsNum(abvaso['lv'] as num)}' : '-'}'
        ' nivel=${nivel(W)} abanico=${jsNum(_n(W['abanico']))} suelo=${jsNum(_n(W['enSuelo']))}'
        ' fuente=${jsTruthy(W['fuente']) ? 1 : 0} cqfan=${jsNum(_n(W['cqfan']))} fanMesa=${jsNum(_n(W['fanMesa']))}'
        ' calor=${jsNum(_n(W['calor']))} sudor=${jsNum(_n(W['sudor']))} splash=${jsTruthy(W['splash']) ? 1 : 0}'
        ' ave=${ave != null ? '${ave['mode']}/${jsTruthy(ave['st']) ? ave['st'] : ''}@${r(ave['x'])},${r(ave['y'])}' : '-'}';
  }

  // remap is not in the old file. Page 12, section 5: every position a story, pair or level file holds goes through the
  // sheet's remap table. A frog's point gives his box and size at the spot it means ([x, y, scale]); abuela's point gives
  // where she stands there ([ab.x, ab.y]); a point of the old scene gives its screen place today; an x on the table gives
  // the new x; a pair rectangle gives the crop of the pictures it was; a level picture's x gives itself back (the level
  // pictures are the sheet's, whole).
  @override
  List<num> remap(List<num> xy) {
    switch (xy.length) {
      case 1:
        final r = sheet.remap('x', xy);
        if (r.to.level) return xy;
        return [r.x!];
      case 2:
        final r = sheet.remapPoint(xy[0], xy[1]);
        final to = r.to;
        if (to.spot != null) {
          final s = sheet.spots[to.spot]!;
          if (s.scale != null) {
            final f = sheet.frogAt(to.spot!, _p.e);
            return [f.x, f.y, f.scale];
          }
          return _p.abuela(to.spot!);
        }
        if (to.none != null) return xy;
        if (to.point != null) return _p.ptRound(to.point!);
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
              in r.crops?.values ?? const <({List<int> crop, int zoom})>[])
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
