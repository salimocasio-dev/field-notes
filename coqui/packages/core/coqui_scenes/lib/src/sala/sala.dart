// Port of historia/escenas/sala.js: the scene "La sala", abuela's living room and her family (order 31b). Line for line,
// minus its background function `bg` and minus what the sheet's `dropped` list says is dropped (the lamp, the sofa, the
// armchair, the blanket, the low table, the frames' wood, paper and nail, the plant, the frog's dotted shadow); every
// screen position replaced by what the sheet's `code` list gives for its line (sala_places.dart), and the places the
// sheet's `moves` list moves, each at its line. sala.js is written on the kit, so this is an `Escena`; its set is
// [SalaSet].
//
// What La sala's sheet has that the earlier ones did not, and how it is kept here (as sala-preview.html keeps it):
// - `talk`: where a bubble goes ([Sala.talkPlace], sala-preview.html `PREVIEW.talk`).
// - `moves`: seven pieces of sala.js's source and their replacements, each applied at its line (a comment says so).
// - `smoothing`: the three places sala.js turns smoothing on (lines 120, 121, 137) keep it on, with the canvas's own
//   `smoothing` and `snapshot` (the sheet's `smoothing.places`).
// - the photos: drawn in marco()'s own coordinates at their frame (`points.foto.<i>`, turned by its angle when the frame
//   hangs crooked), clipped to the frame's opening in the set (`clips`).
// - the low table in front (`front.parts.mesita`): its own pixels drawn again inside each character drawn before it,
//   where nearer.
//
// The old file's names are kept, Spanish ones and capitals included, so the port reads line for line against it
// (page 12, sections 4 and 6): the lints on names are off in this file.
// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_pixel/coqui_pixel.dart' hide tarjeta;
import 'package:coqui_scenes/src/sala/sala_places.dart';
import 'package:coqui_scenes/src/sala/sala_set.dart';
import 'package:coqui_scenes/src/scene_set.dart';
import 'package:coqui_scenes/src/sheet_cache.dart';

/// The scene "sala", made from its sheet (the registry's factory: the sheet must be read first, `loadScene`), drawing its
/// random numbers from [rng], the game's one random source.
Scene createSala({Rng? rng}) => Sala(sheetOf('sala'), rng: rng);

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

// JavaScript: a number of W in arithmetic (`W.pastel - 1`: null is 0, a string that is no number is NaN)
num _arith(Object? v) => v == null ? 0 : _plus(v);

// JavaScript: how `"" + v` writes a value of W (estado)
String _js(Object? v) => v == null
    ? 'null'
    : v is num
    ? jsNum(v)
    : '$v';

const int _white = 0xFFFFFFFF;

// sala.js: SPONGE, FROST
final int SPONGE = hexColour('#F2D08A'), FROST = hexColour('#FF8FB8');

final int _frosting = hexColour('#FFFDF4'),
    _crust = hexColour('#D8B060'),
    _cut = hexColour('#C89A50'),
    _cover = hexColour('#D8D8E4'),
    _coverHi = hexColour('#F2F2F8'),
    _knob = hexColour('#9494A6'),
    _steam = hexColour('#E8F0F8'),
    _coffee = hexColour('#5A3418'),
    _coffeeHi = hexColour('#8A5A38'),
    _cam = hexColour('#3A3A46'),
    _lens = hexColour('#9CCBF5'),
    _photo = hexColour('#BFE0F0'),
    _floorC = hexColour('#E2CA98'),
    _shoe = hexColour('#7A4A1E'),
    _shoeHi = hexColour('#A8682C'),
    _card = hexColour('#FFFDF4');

/// "rgba(255,255,255,.75)": white at .75 (of 255, rounded: 191).
const int _flashC = 0xBFFFFFFF;

/// The pixels of each of the sheet's `front` parts (set-kit.js `PART_TAGS`: the part of the set that drew a pixel
/// last), by set key, then by part. A state's are the same on every engine.
final Map<String, Map<String, Int32List>> _frontPixels = {};

// sala.js: mkTrozo
// a slice of abuela's cake, and the cake itself
Sprite mkTrozo(bool mord) {
  final b = Buf(13, 11);
  void put(int x, int y, int c) {
    if (mord &&
        (x > 6 ||
            math.sqrt((x - 7) * (x - 7) + (y - 1.5) * (y - 1.5)) < 2.7 ||
            math.sqrt((x - 7) * (x - 7) + (y - 5.5) * (y - 5.5)) < 2.4)) {
      return;
    }
    b.px(x + 1, y + 3, c);
  }

  for (var y = 0; y < 7; y++) {
    for (var x = 0; x < 11; x++) {
      final top = x >= 6
          ? 0
          : x >= 3
          ? 1
          : 2;
      if (y < top) continue;
      put(
        x,
        y,
        y < top + 2
            ? FROST
            : y == top + 3 && y < 6
            ? _frosting
            : y == 6
            ? _crust
            : SPONGE,
      );
    }
  }
  if (!mord) b.rect(9, 1, 2, 2, RP.red[2]);
  b.outline();
  if (mord) {
    b.px(10, 9, SPONGE);
    b.px(12, 8, SPONGE);
    b.px(11, 6, FROST);
  }
  return b.done();
}

// sala.js: plato
// an empty plate, a crumb or two
void plato(Ctx g, num x, num y) {
  fr(g, x - 6, y, 12, 2, OUT);
  fr(g, x - 5, y, 10, 1, _white);
  fr(g, x - 2, y - 1, 1, 1, SPONGE);
  fr(g, x + 2, y - 1, 1, 1, FROST);
}

// sala.js: taza
// abuelo's cup of coffee: three sips full, less after every spill
void taza(Ctx g, num x, num y, int n, [num? k0]) {
  final k = k0 == null || k0 == 0 ? 1 : k0;
  fr(g, x - k, y, 9 * k + 2 * k, 8 * k, OUT);
  fr(g, x, y + 8 * k, 9 * k, k, OUT);
  fr(g, x + 9 * k + k, y + 2 * k, 3 * k, k, OUT);
  fr(g, x + 11 * k + k, y + 3 * k, k, 3 * k, OUT);
  fr(g, x + 9 * k + k, y + 6 * k, 3 * k, k, OUT);
  fr(g, x, y, 9 * k, 8 * k, _white);
  final hgt = const [0, 2, 4, 6][n] * k;
  if (hgt != 0) fr(g, x + k, y + 8 * k - hgt - k, 7 * k, hgt, _coffee);
  if (hgt != 0) fr(g, x + k, y + 8 * k - hgt - k, 7 * k, k, _coffeeHi);
  fr(g, x, y + 7 * k, 9 * k, k, _cover);
}

// sala.js: tarjeta
void tarjeta(Ctx g, num x, num y, num w, num h) {
  g.fillStyle = OUT;
  g.fillRect(x - 1, y, w + 2, h);
  g.fillRect(x, y - 1, w, h + 2);
  g.fillStyle = _card;
  g.fillRect(x, y, w, h);
}

/// The scene "La sala" (sala.js: `KIT.escena({id:"sala", ...})`). Its set is [SalaSet]; this is the sprite layer and
/// what can happen here.
class Sala extends Escena implements SetScene, SetOverSprites {
  /// [rng] is the game's one random source (sala.js `azar`: `Math.random()`): the story runner's. A scene made without it
  /// (a picture, a test of its sprites) draws no random number.
  Sala(this.sheet, {Rng? rng}) : _rngGiven = rng {
    _p = SalaPlaces(sheet, salaEngine());
    final p = _p;
    // sala.js:75 SITIO (sheet: code line 75, spots sitio.*)
    SITIO = {
      for (final id in const [
        'mama',
        'papa',
        'abuelo',
        'bebe',
        'abuela',
        'hermano',
        'hermana',
      ])
        id: p.sitio(id),
    };
    // sala.js:76 LUGAR (sheet: lugar, the frog's spots frog.*)
    LUGAR = {for (final k in sheet.lugar.keys) k: sheet.lugarOf(k, p.e)};
    // sala.js:77 PARADOS, APARTE, JUNTOS, CAMARA (sheet: spots parados.*, aparte.*, juntos.*, camara)
    PARADOS = [p.spot('parados.0'), p.spot('parados.1')];
    APARTE = [p.spot('aparte.0'), p.spot('aparte.1')];
    // sheet moves, line 77: JUNTOS=[[96,196],[144,196]] -> JUNTOS=[[80,196],[160,196]] (spots juntos.0, juntos.1)
    JUNTOS = [p.spot('juntos.0'), p.spot('juntos.1')];
    CAMARA = p.spot('camara');
    CAM = {for (final k in sheet.views.keys) k: p.view(k)};
    heartAt = [for (final v in p.pt('corazon')) _round(v)];
    _bizcocho = p.pt('bizcocho');
    _camMesa = p.pt('camMesa');
    _estrellas = p.pts('destapa.estrellas');
    _tresDesde = p.pt('tres.desde');
    _hudPlato = p.pt('hud.plato');
    _retrato = p.rect('retrato');
    _fotoStar = [
      for (final s in p.codeOf(209, 'new') as List)
        [for (final v in s as List) v as num],
    ];
    _fotoStar7 = [
      for (final s in p.codeOf(221, 'new') as List)
        [for (final v in s as List) v as num],
    ];
    _puertaHermano = p.spot('puerta.hermano');
    _puertaHermana = p.spot('puerta.hermana');
    _sortMesa = sheet.frontParts['mesita']!.sortY!;
    _talk = sheet.talk!;
    // sala.js:81 COSAS (sheet: code lines 82, 83, things.<id>.box)
    cosas = [
      for (final id in const [
        'hermano',
        'hermana',
        'bebe',
        'abuela',
        'mama',
        'papa',
        'abuelo',
      ])
        persona(id),
      Thing(
        id: 'bizcocho',
        si: (w) => w['pastel'] is num && (w['pastel'] as num) > 0,
        box: p.box('bizcocho'),
        m: 1,
      ),
      Thing(id: 'mesita', box: p.box('mesita'), m: 0),
      Thing(id: 'sofa', box: p.box('sofa'), m: 0),
      Thing(id: 'butaca', box: p.box('butaca'), m: 0),
      Thing(id: 'fotos', box: p.box('fotos'), m: 0),
      Thing(id: 'lampara', box: p.box('lampara'), m: 0),
      Thing(id: 'puerta', box: p.box('puerta'), m: 0),
      Thing(id: 'ventana', box: p.box('ventana'), m: 0),
      Thing(id: 'sala', box: p.box('sala'), m: 0),
    ];
  }

  @override
  final Sheet sheet;

  late final SalaPlaces _p;
  final Rng? _rngGiven;

  @override
  String get id => 'sala';

  @override
  PpEngine newEngine({bool still = false}) => salaEngine(still: still);

  @override
  PpEngine get projection => _p.e;

  // the host: the glyphs and bubbles sala.js adds when it loads (`GL.biz`, `GL.gaf`, `Object.assign(BUBL, ...)`) go
  // into the game's tables when the scene is given its host
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

  // the sheet's setKey table, from W (setKey.params.*.fromW: "W.luz: the floor lamp lit (1) or not (0)"; "for i in
  // 0..2: W.fotos[i] && !W.fotos[i].ok ? "1" (crooked) : "0""), as sala-preview.html's setOf reads it
  @override
  String setKey(Map<String, dynamic> W) {
    final f = W['fotos'] is List ? W['fotos'] as List : const [];
    String crooked(int i) {
      final v = i < f.length ? f[i] : null;
      return v is Map && !jsTruthy(v['ok']) ? '1' : '0';
    }

    return SalaState(
      luz: W['luz'] == 0 ? '0' : '1',
      fotos: '${crooked(0)}${crooked(1)}${crooked(2)}',
    ).key;
  }

  @override
  void buildSet(PpEngine e, PpBuild b, Map<String, dynamic> W) =>
      buildSetFor(e, b, setKey(W));

  @override
  void buildSetFor(PpEngine e, PpBuild b, String key) {
    final s = SalaSet(e, b, SalaState.fromKey(key));
    // the first bake of a state also records which part drew each pixel (the sheet's front: the low table's own pixels)
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

  // the sheet's shadows, as sala-preview.html casts them: the frog (W.cq.vis, not .5 or less faded) at .3 with his
  // radius, from the floor point under his feet on screen (unproject(b.x + b.w / 2, q.y + 25)); everyone visible, not
  // .5 or less faded, standing (not sent) and not on mamá's lap (z), from the floor point under their feet on screen
  // (unproject(round(x), round(y) - 1)): the baby at .2 with his radius, the others at .3, .65, 1, 1.35, 1.7 with theirs
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
          jsTruthy(p['sent']) ||
          jsTruthy(p['z'])) {
        continue;
      }
      final id = en.key;
      final r = id == 'bebe'
          ? radii['bebe']!
          : FAM[id] != null && FAM[id]!.nino
          ? radii['nino']!
          : radii['grown']!;
      final g = e.unproject(_round(p['x'] as num), _round(p['y'] as num) - 1);
      for (final z
          in id == 'bebe' ? const [.2] : const [.3, .65, 1.0, 1.35, 1.7]) {
        out.add((x: g.x, y: g.y, z: z, r: r));
      }
    }
    return out;
  }

  // JavaScript: `al <= .5` (a missing `al` is not)
  static bool _atMostHalf(Object? al) => al is num && al <= .5;

  /* ---------- the low table in front: the sheet's front ---------- */

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

  // sala-preview.html: PREVIEW.front (sheet: front). The set's own pixels of the low table, again, inside each character
  // drawn before it ([lista], sorted, up to the table), only where that pixel is nearer than that character:
  // bakedZ[i] > v / COS - (row + .5 - OY) * tan 30 / S, v of the floor point under the character's feet. Their boxes:
  // people [x - 24, y - alto - 2, 48, alto + 3], the frog his box. A frame drawn with no set (a player with no screen)
  // has none to draw again.
  void front(String part, List<SalaItem> lista) {
    final e = _frameEngine, s = _setFrame, Z = _setZ;
    if (e == null || s == null || Z == null) return;
    final list = _frontNow?[part];
    if (list == null) {
      throw StateError(
        'sala: the part tags of the state ${setKey(W)} are not known: its set was not baked by this scene',
      );
    }
    final COS = math.sqrt(3) / 2, T30 = math.tan(math.pi / 6);
    // the character's feet on the floor: v = (x + y) / R2 of the floor point under them
    double vOf(num sy) => (sy - e.OY) / (e.S * .5);
    final me = lista.indexWhere((o) => o.mesa);
    final pix = e.pix, W0 = e.W, H0 = e.H;
    for (final o in lista.sublist(0, me < 0 ? 0 : me)) {
      List<num> r;
      double v;
      if (o.id == 'coqui') {
        final q = W['cq'] as Map<String, dynamic>, b = frogBox(q);
        r = [b.x, b.y + _round(q['dy'] as num), b.w, b.h];
        v = vOf((q['y'] as num) + 25);
      } else if (o.id != null) {
        final p = G(o.id!)!, h = alto(o.id!);
        r = [
          _round(p['x'] as num) - 24,
          _round(p['y'] as num) - h - 2,
          48,
          h + 3,
        ];
        v = vOf(_round(p['y'] as num) - 1);
      } else {
        continue;
      }
      final y0 = math.max(0, r[1]),
          y1 = math.min(H0, r[1] + r[3]),
          x0 = math.max(0, r[0]),
          x1 = math.min(W0, r[0] + r[2]);
      for (final i in list) {
        final y = i ~/ W0, x = i - y * W0;
        if (y < y0 || y >= y1 || x < x0 || x >= x1) continue;
        if (!(Z[i] > v / COS - (y + .5 - e.OY) * T30 / e.S)) continue;
        pix[i] = 0xFF000000 | (s[i] & 0xFFFFFF);
      }
    }
  }

  /* ---------- drawing ---------- */

  // sala.js: GL.biz, GC.biz, GL.gaf, Object.assign(BUBL, ...)
  void _glyphs(SceneHost h) {
    final GL = h.lib.GL, GC = h.lib.GC;
    GL['biz'] = const [
      '...oo....',
      '..o##o...',
      '.ooooooo.',
      'owwwwwwwo',
      'o#######o',
      'o#######o',
      'ooooooooo',
    ];
    GC['biz'] = hexColour('#F2D08A');
    GL['gaf'] = const ['ooo.ooo', 'o.ooo.o', 'ooo.ooo'];
    h.BUBL.addAll(const {
      'bizcocho': ['biz'],
      'q': ['q'],
      'gafas_q': ['gaf', 'q'],
      'feliz': ['ok'],
    });
  }

  /* ---------- where things are ---------- */

  // sala.js: SITIO (sheet: code line 75), LUGAR (sheet: lugar), PARADOS, APARTE, JUNTOS, CAMARA (sheet: spots)
  late final Map<String, List<num>> SITIO;
  late final Map<String, List<num>> LUGAR;
  late final List<List<int>> PARADOS, APARTE, JUNTOS;
  late final List<int> CAMARA;

  // the cake and the camera on the low table (sheet: points bizcocho, camMesa; code line 114), the stars over the cake
  // (destapa.estrellas: line 162), where the slices fly from and to (tres.desde, hud.plato: lines 163, 174), the region
  // of the photo of everyone (retrato: line 190), the stars over a new photo (code lines 209, 221)
  late final List<double> _bizcocho, _camMesa, _tresDesde, _hudPlato, _retrato;
  late final List<List<double>> _estrellas;
  late final List<List<num>> _fotoStar, _fotoStar7;

  // acts.corren: where the children appear in the doorway (sheet: spots puerta.hermano, puerta.hermana; code line 198)
  late final List<int> _puertaHermano, _puertaHermana;

  // the low table's place in the list sorted by y (sheet: front.parts.mesita.sortY; sala.js:114 `y:165`)
  late final num _sortMesa;

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

  // sala.js: alto
  int alto(String id) {
    if (id == 'abuela') return 51;
    if (id == 'bebe') return 28;
    if (FAM[id]!.nino) return 44;
    final p = G(id);
    return p != null && jsTruthy(p['sent']) ? 49 : 56;
  }

  // sala.js: caja
  List<num>? caja(String id) {
    final p = G(id);
    if (p != null &&
        p['vis'] != 0 &&
        (p['al'] == null || (p['al'] as num) > .3)) {
      return [
        _round(p['x'] as num) - 11,
        _round(p['y'] as num) - alto(id),
        22,
        alto(id),
      ];
    }
    return null;
  }

  // sala.js: persona
  Thing persona(String id) => Thing(
    id: id,
    m: 1,
    si: (w) {
      final g = w['gente'] as Map<String, dynamic>?;
      return g != null && g[id] != null && (g[id] as Map)['vis'] != 0;
    },
    box: (Map<String, dynamic> w) => caja(id),
  );

  // sala.js: COSAS
  @override
  late final List<Thing> cosas;

  // sala.js: G0
  Map<String, dynamic> G0() => {
    'mama': <String, dynamic>{
      'x': SITIO['mama']![0],
      'y': SITIO['mama']![1],
      'sent': 1,
      'pose': 'idle',
    },
    'papa': <String, dynamic>{
      'x': SITIO['papa']![0],
      'y': SITIO['papa']![1],
      'sent': 1,
      'pose': 'idle',
    },
    'abuelo': <String, dynamic>{
      'x': SITIO['abuelo']![0],
      'y': SITIO['abuelo']![1],
      'sent': 1,
      'pose': 'idle',
    },
    'bebe': <String, dynamic>{
      'x': SITIO['bebe']![0],
      'y': SITIO['bebe']![1],
      'est': 'idle',
    },
    'abuela': <String, dynamic>{
      'x': SITIO['abuela']![0],
      'y': SITIO['abuela']![1],
      'pose': 'idle',
      'dir': -1,
    },
    'hermano': <String, dynamic>{
      'x': SITIO['hermano']![0],
      'y': SITIO['hermano']![1],
      'pose': 'idle',
      'vis': 0,
    },
    'hermana': <String, dynamic>{
      'x': SITIO['hermana']![0],
      'y': SITIO['hermana']![1],
      'pose': 'idle',
      'vis': 0,
    },
  };

  // sala.js: fresh
  @override
  Map<String, dynamic> fresh(Map<String, dynamic> story) => {
    'gente': G0(),
    'fotos': <dynamic>[null, null, null],
    'luz': 1,
    'pastel': null,
    'plato': null,
    'lleva': 0,
    'vuela': null,
    'flash': 0,
    'ave': null,
    'cafe': 0,
    'relleno': 0,
    'aciertos': 0,
    'apodo': null,
    'visor': null,
    'borroso': 0,
    'tapaojos': null,
    'golpe': 0,
    'gotas': null,
    'camMesa': 0,
    'retrato': null,
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

  /* ---------- drawing ---------- */

  // sala.js: marco, as sala-preview.html draws it (sheet: code lines 52 to 60)
  // a picture frame's photo, once one is taken: the set draws the frame, its paper and its nail; this draws the photo, in
  // marco()'s own coordinates at its frame (points.foto.<i>, or foto.<i>.torcida turned by its angle: the frame hangs
  // crooked when the photo came out wrong, baked, no swing), clipped to the frame's opening in the set (clips: the quad
  // on the screen, set before the translate). f = {q:[who is in it], ok, pata:1 (only the frog's foot at the edge),
  // pies:1 (abuelo's slippers)}
  void marco(Ctx g, int i, Object? f0) {
    if (f0 is! Map) return;
    final f = f0;
    final k = 'foto.$i${jsTruthy(f['ok']) ? '' : '.torcida'}';
    final P = sheet.screenPoint(k), clip = _p.clipScreen(k);
    g.save();
    g.beginPath();
    g.moveTo(clip[0][0], clip[0][1]);
    for (var j = 1; j < 4; j++) {
      g.lineTo(clip[j][0], clip[j][1]);
    }
    g.clip();
    g.translate(P.xy[0], P.xy[1]);
    if (!jsTruthy(f['ok'])) g.rotate(P.angle!);
    // the photo's ground (sheet: code line 53)
    fr(g, -14, -6, 28, 34, _photo);
    {
      g.save();
      if (jsTruthy(f['pies'])) {
        fr(g, -8, 14, 16, 8, _floorC);
        for (final p in const [
          [-6, 10],
          [1, 11],
        ]) {
          fr(g, p[0] - 1, p[1] - 1, 7, 9, OUT);
          fr(g, p[0], p[1], 5, 7, _shoe);
          fr(g, p[0], p[1], 5, 2, _shoeHi);
        }
      } else {
        final q = (f['q'] as List?) ?? const [];
        for (var kk = 0; kk < q.length; kk++) {
          final id = q[kk] as String;
          if (id == 'coqui') {
            g.drawImage(
              host.lib.spr('cq.5_f', () => mkCoqui(.5, 0, false)),
              q.length > 1 ? -1 : -8,
              12,
            );
            continue;
          }
          final im = id == 'abuela'
                  ? host.lib.spr('abidle0', () => mkAbuela('idle', false))
                  : host.lib.spr(
                      'pf$id',
                      () => mkPersona(FAM[id]!, 'idle', false, false),
                    ),
              sx = id == 'abuela' ? 22 : PX - 8;
          g.drawImageRect(
            im,
            sx,
            0,
            16,
            22,
            q.length > 1 ? -10 + kk * 2 : -8,
            3,
            16,
            22,
          );
        }
        if (jsTruthy(f['pata'])) {
          fr(g, 5, 17, 4, 5, OUT);
          fr(g, 6, 18, 3, 4, RP.tan[3]);
        }
      }
      g.restore();
    }
    g.restore();
  }

  // sala.js: trozo
  void trozo(Ctx g, num x, num y, [num? k0, Object? mord]) {
    final k = k0 == null || k0 == 0 ? 1 : k0;
    final m = jsTruthy(mord);
    final im = host.lib.spr('trozo${m ? 1 : 0}', () => mkTrozo(m));
    g.smoothing = false;
    g.drawImage(
      im,
      _round(x - 1),
      _round(y - 2 * k - 1),
      _round(13 * k),
      _round(11 * k),
    );
  }

  // sala.js: bizcocho
  // the cake on its dish: one block, cut into slices; it gets shorter as slices go
  void bizcocho(Ctx g, num x, num y, Object? n) {
    fr(g, x - 4, y + 9, 34, 3, OUT);
    fr(g, x - 3, y + 9, 32, 2, _white);
    if (n == 'tapado') {
      g.fillStyle = OUT;
      g.beginPath();
      g.ellipse(x + 13, y + 9, 15, 13, 0, math.pi, 0);
      g.fill();
      g.fillStyle = _cover;
      g.beginPath();
      g.ellipse(x + 13, y + 9, 14, 12, 0, math.pi, 0);
      g.fill();
      fr(g, x + 6, y + 1, 3, 5, _coverHi);
      fr(g, x + 11, y - 5, 4, 3, OUT);
      fr(g, x + 12, y - 4, 2, 2, _knob);
      // steam: it is hot
      for (var k = 0; k < 3; k++) {
        for (var j = 0; j < 3; j++) {
          fr(
            g,
            x + 5 + k * 8 + (((F >> 2) + j + k) % 2),
            y - 8 - j * 4 - ((F >> 1) + k * 2) % 3,
            2,
            2,
            j == 2 ? _steam : _white,
          );
        }
      }
      return;
    }
    if (!jsTruthy(n)) return;
    final nn = n as num, w = nn * 4, x0 = x - 3;
    fr(g, x0 - 1, y - 1, w + 2, 11, OUT);
    fr(g, x0, y, w, 9, SPONGE);
    fr(g, x0, y, w, 3, FROST);
    fr(g, x0, y + 5, w, 1, _frosting);
    for (var i = 0; i < nn; i++) {
      if (i != 0) {
        fr(g, x0 + i * 4, y, 1, 9, i.remainder(1) != 0 ? SPONGE : _cut);
      }
      fr(g, x0 + i * 4 + 1, y - 3, 2, 2, OUT);
      fr(g, x0 + i * 4 + 1, y - 2, 2, 2, RP.red[2]);
    }
  }

  // sala.js: gente
  void gente(Ctx c, String id, int a) {
    final p = G(id);
    if (p == null || p['vis'] == 0) return;
    final x = _round(p['x'] as num),
        y = _round(p['y'] as num),
        habla = host.TALK == id && a % 2 != 0 ? 1 : 0,
        h = alto(id);
    c.globalAlpha = p['al'] == null ? 1 : (p['al'] as num).toDouble();
    if (id == 'bebe') {
      final e = jsTruthy(p['est']) ? p['est'] as String : 'idle',
          im = host.lib.spr('bb$e${a % 2}', () => mkBebe(e, a % 2 != 0));
      c.drawImage(im, x - 13, y - 28);
    } else if (id == 'abuela') {
      final pose = p['pose'] == 'wave'
              ? 'wave${a % 2}'
              : p['pose'] == 'dedo'
              ? 'dedo${(a >> 1) % 2}'
              : (jsTruthy(p['pose']) ? p['pose'] as String : 'idle'),
          im = host.lib.spr('ab$pose$habla', () => mkAbuela(pose, habla != 0));
      c.save();
      c.translate(x.toDouble(), (y - 50).toDouble());
      if (_dir(p) < 0) c.scale(-1, 1);
      c.drawImage(im, -30, 0);
      c.restore();
      if (jsTruthy(p['lleva'])) {
        final hx = x + (_dir(p) < 0 ? 16 : -22), hy = y - 27;
        if (p['lleva'] == 'plato') {
          fr(c, hx - 3, hy + 7, 16, 3, OUT);
          fr(c, hx - 2, hy + 7, 14, 2, _white);
          for (var k = 0; k < 3; k++) {
            trozo(c, hx - 2 + k * 5, hy - 1, .6, k < _n(W['lost']));
          }
        } else {
          trozo(c, hx, hy);
        }
      }
    } else {
      final pose = p['pose'] == 'wave'
          ? 'wave${a % 2}'
          : (jsTruthy(p['pose']) ? p['pose'] as String : 'idle');
      final w = (jsTruthy(p['gafas']) || jsTruthy(p['dormido']))
          ? FAM[id]!.copyWith(
              gafas: jsTruthy(p['gafas']) ? p['gafas'] : null,
              dormido: jsTruthy(p['dormido']),
            )
          : FAM[id]!;
      final k =
          'p$id$pose$habla${jsTruthy(p['sent']) ? 1 : 0}'
          '${jsTruthy(p['gafas']) ? _js(p['gafas']) : ''}${jsTruthy(p['dormido']) ? 'z' : ''}';
      final im = host.lib.spr(
        k,
        () => mkPersona(w, pose, habla != 0, jsTruthy(p['sent'])),
      );
      c.save();
      c.translate(
        x.toDouble(),
        (y - im.h + 1 + (jsTruthy(p['rie']) && a % 2 != 0 ? -1 : 0)).toDouble(),
      );
      if (_dir(p) < 0) c.scale(-1, 1);
      c.drawImage(im, -PX, 0);
      c.restore();
      if (jsTruthy(p['dormido'])) {
        final z = (F >> 3) % 3;
        void Z(num zx, num zy, num k) {
          fr(c, zx - 1, zy - 1, 4 * k + 2, 5 * k + 2, OUT);
          for (final r in const [
            [0, 0, 4, 1],
            [3, 1, 1, 1],
            [2, 2, 1, 1],
            [1, 3, 1, 1],
            [0, 4, 4, 1],
          ]) {
            fr(c, zx + r[0] * k, zy + r[1] * k, r[2] * k, r[3] * k, _white);
          }
        }

        Z(x + 6 + z * 2, y - h - 5 - z * 2, 2);
        Z(x + 17 + z * 2, y - h - 12 - z * 2, 1);
      }
      if (pose == 'taza') {
        final d = _dir(p) < 0 ? -1 : 1, cx = x + d * 13, cy = y - h + 26;
        taza(
          c,
          cx - 4,
          cy - 8,
          jsTruthy(W['relleno']) ? 3 : math.max(0, 3 - _n(W['lost'])).toInt(),
          1,
        );
      }
    }
    if (jsTruthy(p['trozo'])) {
      trozo(c, x - 4, y - _round(h * .52), 1, p['trozo'] == 'mordido');
    } else if (jsTruthy(p['servido']) && id != 'bebe') {
      plato(c, x, y - _round(h * (jsTruthy(p['sent']) ? .36 : .5)));
    }
    c.globalAlpha = 1;
  }

  // JavaScript: `p.dir < 0` (a missing dir is not)
  static num _dir(Map<String, dynamic> p) =>
      p['dir'] is num ? p['dir'] as num : 0;

  // sala.js: rana
  void rana(Ctx g, Map<String, dynamic> q, int a) {
    final b = frogBox(q),
        bl = (F % 47) < 2 ? 1 : 0,
        op = (q['bub'] == 'hola' || host.TALK == 'coqui') && a % 2 != 0 ? 1 : 0;
    // sala.js:101, the dotted shadow, is dropped (sheet: shadows.dropped): the engine casts his
    final s = q['s'] as num;
    g.drawImage(
      host.lib.spr('cq${jsNum(s)}_$bl$op', () => mkCoqui(s, bl, op != 0)),
      b.x,
      b.y + _round(q['dy'] as num),
    );
  }

  // sala.js: bub2
  // picture bubbles are drawn at twice their size here, so they read on a phone
  void bub2(Ctx c, String k, num tx, num ty, int a) {
    c.save();
    c.translate(tx.toDouble(), ty.toDouble());
    c.scale(2, 2);
    host.bub(c, k, 0, 0, a);
    c.restore();
  }

  // the canvas of the last frame drawn (sala.js `sc`, the scene's picture): what acts.retrato takes the photo of everyone
  // from
  Ctx? _sc;

  // a frame's canvas for W.borroso, 20 x 18 (sala.js:120 `spr("bor", ...)`: one canvas, drawn over at each frame)
  Sprite? _bor;

  // sala.js: draw
  @override
  void draw(Ctx c, Map<String, dynamic> W, int a) {
    _sc = c;
    final q = W['cq'] as Map<String, dynamic>,
        Gm = (W['gente'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    // sala.js:107 c.drawImage(spr("sala",bg)) -> the set, for setKey(W)
    final fotos = W['fotos'] is List ? W['fotos'] as List : const [];
    for (var i = 0; i < 3; i++) {
      marco(c, i, i < fotos.length ? fotos[i] : null);
    }
    // sala.js:109, :110, :111 the lamp, the sofa, the armchair and the blanket -> the set (sheet: dropped)
    // everyone, and the low table, from the back of the room to the front
    final lista = <SalaItem>[
      for (final id in Gm.keys)
        if (Gm[id] != null && (Gm[id] as Map)['vis'] != 0)
          SalaItem(
            jsTruthy((Gm[id] as Map)['z'])
                ? (Gm[id] as Map)['z'] as num
                : (Gm[id] as Map)['y'] as num,
            () => gente(c, id, a),
            id: id,
          ),
    ];
    // sala.js:114 the low table's sprite -> the set (sheet: front mesita: its own pixels again, at its place in the list);
    // the cake at points.bizcocho, the camera at points.camMesa; its jump on W.golpe is not drawn (setKey.notRead)
    late final List<SalaItem> sorted;
    lista.add(
      SalaItem(_sortMesa, () {
        front('mesita', sorted);
        if (W['pastel'] != null) {
          bizcocho(c, _bizcocho[0], _bizcocho[1], W['pastel']);
        }
        if (jsTruthy(W['camMesa'])) {
          final K = _camMesa;
          fr(c, K[0], K[1], 16, 10, OUT);
          fr(c, K[0] + 1, K[1] + 1, 14, 8, _cam);
          fr(c, K[0] + 5, K[1] + 3, 5, 5, _lens);
        }
      }, mesa: true),
    );
    if (jsTruthy(q['vis'])) {
      lista.add(
        SalaItem((q['y'] as num) + 27, () {
          c.globalAlpha = (q['al'] as num).toDouble();
          rana(c, q, a);
          c.globalAlpha = 1;
          final b = frogBox(q), dy = _round(q['dy'] as num);
          if (jsTruthy(W['lleva'])) {
            trozo(c, b.x + _round(b.w / 2) - 4, b.y + dy - 9);
          }
          // a child's hands over his eyes
          if (jsTruthy(W['tapaojos'])) {
            final s = q['s'] as num;
            for (final u in const [.3, .7]) {
              c.fillStyle = OUT;
              c.beginPath();
              c.arc(b.x + b.w * u, b.y + dy + 7 * s, 5.2 * s, 0, 7);
              c.fill();
              c.fillStyle = FAM[W['tapaojos'] as String]!.piel[3];
              c.beginPath();
              c.arc(b.x + b.w * u, b.y + dy + 7 * s, 4.2 * s, 0, 7);
              c.fill();
            }
          }
        }, id: 'coqui'),
      );
    }
    // JavaScript's sort is stable: the index breaks a tie
    final byRow = [...lista.indexed]
      ..sort((m, n) {
        final d = m.$2.y.compareTo(n.$2.y);
        return d != 0 ? d : m.$1.compareTo(n.$1);
      });
    sorted = [for (final e in byRow) e.$2];
    for (final o in sorted) {
      o.d();
    }
    final vuela = W['vuela'] as Map<String, dynamic>?;
    if (vuela != null) {
      trozo(
        c,
        _round(vuela['x'] as num) - 4,
        _round(vuela['y'] as num) - 4,
        jsTruthy(vuela['k']) ? vuela['k'] as num : 1,
        vuela['mord'],
      );
    }
    // coffee slops out
    final gotas = W['gotas'] as Map<String, dynamic>?;
    if (gotas != null && F - (gotas['f'] as num) < 10) {
      final t = F - (gotas['f'] as num);
      for (var i = 0; i < 4; i++) {
        fr(
          c,
          _round((gotas['x'] as num) + (i - 1.5) * 3 * (1 + t / 4)),
          _round((gotas['y'] as num) + t * t / 3 - t + i % 2 * 2),
          2,
          2,
          _coffee,
        );
      }
    }
    // what abuelo sees without his glasses (sheet: smoothing.places, sala.js:120 and :121): the whole picture drawn so far
    // (the new set with the sprites on it), down to 20 x 18 with smoothing on, and back up to 240 x 216 with smoothing on,
    // then off
    if (jsTruthy(W['borroso'])) {
      final t = _bor ??= Sprite(20, 18, Uint32List(20 * 18)),
          g = Ctx(t.px, t.w, t.h);
      g.smoothing = true;
      g.drawImageRect(c.snapshot(0, 0, SW, SH), 0, 0, SW, SH, 0, 0, 20, 18);
      c.save();
      c.smoothing = true;
      c.drawImageRect(t, 0, 0, 20, 18, 0, 0, SW, SH);
      c.restore();
      c.smoothing = false;
    }
    if (jsTruthy(W['flash']) && F - (W['flash'] as num) < 3) {
      c.fillStyle = _flashC;
      c.fillRect(0, 0, SW, SH);
    }
    for (final id in Gm.keys) {
      final p = Gm[id] as Map<String, dynamic>?;
      if (p != null && jsTruthy(p['bub']) && p['vis'] != 0) {
        final at = talkAt(id, W);
        if (at != null) bub2(c, p['bub'] as String, at[0], at[1] + 38, a);
      }
    }
    // the frog's bubble, where the sheet's talk puts it
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

  // sala-preview.html: PREVIEW.talk (sheet: talk). Where a bubble's tail goes: the first of the sheet's places beside the
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
          (p['al'] != null && (p['al'] as num) <= .3)) {
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
    num field(String f) => _n(w[f]);
    if (w['plato'] != null) boards.add(T.board('plato', field)!);
    if (jsTruthy(w['cafe'])) boards.add(T.board('cafe', field)!);
    if (jsTruthy(w['visor'])) boards.add(T.board('visor', field)!);
    if (jsTruthy(w['retrato'])) boards.add(T.board('retrato', field)!);
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

  // sala.js: talkAt, with the sheet's talk (sala-preview.html: the bubble beside the head when over it would land on a
  // face or leave the view)
  @override
  List<num>? talkAt(String who, Map<String, dynamic> W) {
    final k = who;
    final p =
        (W['gente'] as Map<String, dynamic>?)?[k] as Map<String, dynamic>?;
    if (p == null ||
        p['vis'] == 0 ||
        (p['al'] != null && (p['al'] as num) < .5)) {
      return null;
    }
    final t = talkPlace(
      [_round(p['x'] as num), _round(p['y'] as num) - alto(k) - 1],
      6,
      p['bub'],
      W,
    );
    return [t[0], t[1] - (jsTruthy(p['bub']) ? 38 : 0)];
  }

  /* ---------- what is at stake, in the corner of the screen ---------- */

  // the little window of the camera, 5 x 5 (sala.js:137 `spr("vis", ...)`)
  Sprite? _vis;

  // sala.js: hud
  @override
  void hud(Ctx c, Map<String, dynamic> W, int a) {
    final g = c, DW = host.DW;
    final retrato = W['retrato'];
    if (retrato is Sprite) {
      final x = _round((DW - 136) / 2), y = 6;
      g.fillStyle = OUT;
      g.fillRect(x - 1, y - 1, 138, 90);
      g.fillStyle = RP.wood[2];
      g.fillRect(x, y, 136, 88);
      g.fillStyle = RP.wood[4];
      g.fillRect(x, y, 136, 1);
      g.fillStyle = OUT;
      g.fillRect(x + 3, y + 3, 130, 82);
      g.smoothing = false;
      g.drawImage(retrato, x + 4, y + 4);
    }
    if (W['plato'] != null) {
      tarjeta(g, 3, 3, 78, 29);
      g.drawImage(host.lib.spr('cq.7_0', () => mkCoqui(.7, 0, false)), 5, 7);
      g.fillStyle = OUT;
      g.fillRect(29, 25, 48, 3);
      g.fillStyle = _white;
      g.fillRect(30, 25, 46, 2);
      // three slices: whole, or with a bite out
      final n = _arith(W['plato']);
      for (var i = 0; i < n; i++) {
        trozo(g, 32 + i * 15, 11, 1.3, i >= n - _n(W['lost']));
      }
    }
    if (jsTruthy(W['cafe'])) {
      tarjeta(g, 3, 3, 44 + _n(W['aciertos']) * 13, 36);
      taza(g, 8, 9, math.max(0, 3 - _n(W['lost'])).toInt(), 3);
      for (var i = 0; i < _n(W['aciertos']); i++) {
        host.heart(g, 49 + i * 13, 15, 1);
      }
    }
    final visor = W['visor'] as Map<String, dynamic>?;
    if (visor != null) {
      final quien = visor['quien'] as String;
      final im = host.lib.spr(
        'pf$quien',
        () => mkPersona(FAM[quien]!, 'idle', false, false),
      );
      tarjeta(g, 3, 3, 50, 50);
      g.fillStyle = _photo;
      g.fillRect(5, 5, 46, 46);
      if (jsTruthy(visor['nitido'])) {
        g.smoothing = false;
        g.drawImageRect(im, PX - 11, 0, 22, 23, 6, 5, 44, 46);
      } else {
        // what the camera sees out of focus (sheet: smoothing.places, sala.js:137): the person's sprite down to 5 x 5 and
        // back up to 46 x 46, smoothing on for both, then off
        final t = _vis ??= Sprite(5, 5, Uint32List(25)), x = Ctx(t.px, 5, 5);
        x.fillStyle = _photo;
        x.fillRect(0, 0, 5, 5);
        x.smoothing = true;
        x.drawImageRect(im, PX - 11, 0, 22, 23, 0, 0, 5, 5);
        g.smoothing = true;
        g.drawImageRect(t, 0, 0, 5, 5, 5, 5, 46, 46);
        g.smoothing = false;
      }
      // what the camera sees
      g.fillStyle = OUT;
      g.fillRect(27, 5, 1, 6);
      g.fillRect(27, 45, 1, 6);
      g.fillRect(5, 27, 6, 1);
      g.fillRect(45, 27, 6, 1);
    }
  }

  /* ---------- what can happen here ---------- */

  // DECISION(order 31b): the scene's random draws come from the game's one Rng, as Math.random was one: the one the
  // registry's factory is given (`createSala`, from the story runner's `rng`), as El balcón's (order 30b)
  Rng get _rng =>
      _rngGiven ??
      (throw StateError(
        'La sala was made without a random source (Rng) but draws a random number',
      ));

  // sala.js: azar
  bool azar() => _rng.next() < .5;

  // sala.js: mueve
  Future<void> mueve(String id, num x, num y, [num? n0]) async {
    final p = G(id);
    if (p == null) return;
    final x0 = p['x'] as num, y0 = p['y'] as num;
    final b0 = G('bebe');
    final bb = id == 'mama' && b0 != null && jsTruthy(b0['z']) ? b0 : null;
    if (bb != null) {
      // setTimeout(function sigue(){...}, TICK): the baby on her lap goes with her
      void sigue() {
        bb['x'] = (p['x'] as num) + (jsTruthy(p['sent']) ? 0 : 9);
        bb['y'] = (p['y'] as num) - (jsTruthy(p['sent']) ? 15 : 26);
        bb['z'] = (p['y'] as num) + 1;
        if (((p['x'] as num) - x).abs() + ((p['y'] as num) - y).abs() > 1) {
          unawaited(host.sleep(host.TICK).then((_) => sigue()));
        }
      }

      unawaited(host.sleep(host.TICK).then((_) => sigue()));
    }
    final dx = x - x0, dy = y - y0;
    final n = n0 != null && n0 != 0
        ? n0
        : math.max(3, _round(math.sqrt(dx * dx + dy * dy) / 6));
    p['sent'] = 0;
    for (var i = 1; i <= n; i++) {
      p['x'] = x0 + (x - x0) * i / n;
      p['y'] = y0 + (y - y0) * i / n - (i % 2);
      await wait(host.TICK);
    }
    p['x'] = x;
    p['y'] = y;
  }

  // sala.js: vuelaA
  Future<void> vuelaA(
    num x0,
    num y0,
    num x1,
    num y1, [
    Object? mord,
    num? k,
  ]) async {
    final v = <String, dynamic>{
      'x': x0,
      'y': y0,
      'mord': mord,
      'k': k == null || k == 0 ? 1 : k,
    };
    W['vuela'] = v;
    for (var i = 1; i <= 7; i++) {
      v['x'] = x0 + (x1 - x0) * i / 7;
      v['y'] = y0 + (y1 - y0) * i / 7 - math.sin(math.pi * i / 7) * 10;
      await wait(host.TICK);
    }
    W['vuela'] = null;
  }

  // sala.js: flashazo
  void flashazo() {
    W['flash'] = F;
    host.tone(1800, 0, .05, 'square', .06);
    host.tone(2400, .04, .12, 'sine', .05);
  }

  // sala.js: nFotos
  int nFotos() => ((W['fotos'] as List?) ?? const []).where(jsTruthy).length;

  // W.fotos[i] = f: past the end, the list grows (JavaScript)
  void _setFoto(int i, Map<String, dynamic> f) {
    final l = W['fotos'] as List;
    while (l.length <= i) {
      l.add(null);
    }
    l[i] = f;
  }

  // sala.js: glu
  void glu() => host.tone(300, 0, .09, 'sine', .09, 170);

  // sala.js: acts.ir (the kit's), as the old acts call it
  Future<void> ir(Object? a) => acts['ir']!({'a': a});

  List<num> _sitio(Object? who) =>
      SITIO[who] ?? (throw StateError('sala: no SITIO for $who'));

  // the stars of a happy ending (sala.js:184, :245: a screen effect, unchanged: sheet code lines 184, 245)
  static const List<List<int>> _final = [
    [60, 30],
    [180, 34],
    [120, 22],
    [96, 44],
    [150, 40],
  ];

  // sala.js: acts
  @override
  late final Map<String, Act> ownActs = {
    'anda': (o) async {
      final L = SITIO[o['a']] ?? [_plus(o['x']), _plus(o['y'])];
      await mueve('${o['quien']}', L[0], L[1]);
    },
    'entra': (o) async {
      final q = W['cq'] as Map<String, dynamic>, L = LUGAR['centro']!;
      q['x'] = LUGAR['puerta']![0];
      q['y'] = LUGAR['puerta']![1];
      q['s'] = LUGAR['puerta']![2];
      q['vis'] = 1;
      await wait(200);
      await host.hopTo(L[0], L[1], 3, L[2]);
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
      final p = G(jsTruthy(o['quien']) ? '${o['quien']}' : 'abuela');
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
      final ms = _plus(o['ms']);
      await wait(ms.isNaN || ms == 0 ? 700 : ms);
      if (o['quien'] == 'bebe') {
        p['est'] = 'idle';
      } else {
        p['pose'] = 'idle';
      }
    },
    /* ---- story 6: a slice for everyone ---- */
    // the frog goes straight to the covered cake and sniffs; abuela wags a finger
    'huele': (o) async {
      final q = W['cq'] as Map<String, dynamic>, L = LUGAR['puerta']!;
      q['x'] = L[0];
      q['y'] = L[1];
      q['s'] = L[2];
      q['vis'] = 1;
      await wait(200);
      await ir('huele');
      q['bub'] = 'bizcocho';
      SFX.coqui();
      host.bounce(5);
      await wait(600);
      G('abuela')!['pose'] = 'dedo';
    },
    'atras': (o) async {
      G('abuela')!['pose'] = 'idle';
      (W['cq'] as Map<String, dynamic>)['bub'] = null;
      await ir('centro');
    },
    'beso': (o) async {
      final p = G('mama')!;
      p['pose'] = 'wave';
      p['bub'] = 'amor';
      await wait(900);
      p['bub'] = null;
      p['pose'] = 'idle';
    },
    'despierta': (o) async {
      final p = G('abuelo')!;
      p['dormido'] = 0;
      p['rie'] = 1;
      SFX.blip();
      host.bounce(4);
      await wait(500);
      p['rie'] = 0;
      p['pose'] = 'wave';
      await wait(600);
      p['pose'] = 'idle';
    },
    // the cover comes off: seven slices. Three fly to his plate in the corner.
    'duerme': (o) async {
      G('abuelo')!['dormido'] = 1;
    },
    'destapa': (o) async {
      SFX.luz();
      W['pastel'] = 7;
      // the stars over the cake (sheet: points destapa.estrellas, code line 162)
      host.fx({
        't': 'star',
        'n': 10,
        'pts': [
          for (final p in _estrellas) [p[0], p[1]],
        ],
      });
      await wait(600);
    },
    'tres': (o) async {
      W['plato'] = 0;
      for (var i = 0; i < 3; i++) {
        W['pastel'] = _arith(W['pastel']) - 1;
        SFX.blip();
        // the slices fly from the cake to the plate card (sheet: points tres.desde, hud.plato; code line 163)
        await vuelaA(_tresDesde[0], _tresDesde[1], _hudPlato[0], _hudPlato[1]);
        W['plato'] = _arith(W['plato']) + 1;
      }
      await wait(300);
    },
    // abuela puts a slice from the dish in the frog's hands
    'dale': (o) async {
      final ab = G('abuela')!;
      await ir('abuela');
      ab['pose'] = 'offer';
      W['pastel'] = math.max(0, _arith(W['pastel']) - 1);
      ab['lleva'] = 1;
      SFX.blip();
      await wait(350);
      ab['lleva'] = 0;
      W['lleva'] = 1;
      ab['pose'] = 'idle';
      await wait(250);
      await ir('centro');
    },
    // the frog carries it to someone
    'da': (o) async {
      await ir(o['en']);
      await wait(150);
      W['lleva'] = 0;
      final p = G('${o['en']}')!;
      p['trozo'] = 1;
      SFX.blip();
      await wait(350);
    },
    // one happy bite; the slice stays on that person's plate until everyone eats together at the end
    'come': (o) async {
      final p = G('${o['quien']}');
      if (p == null) return;
      SFX.munch();
      p['trozo'] = 'mordido';
      if (o['quien'] == 'bebe') {
        p['est'] = 'clap';
        SFX.pio();
      } else {
        p['rie'] = 1;
      }
      await wait(600);
      p['rie'] = 0;
      if (o['quien'] == 'bebe') p['est'] = 'idle';
      await ir('centro');
    },
    'comen': (o) async {
      for (var k = 0; k < 3; k++) {
        SFX.munch();
        await wait(260);
      }
      for (final id in (W['gente'] as Map<String, dynamic>).keys) {
        final p = G(id)!;
        if (jsTruthy(p['trozo'])) {
          p['trozo'] = 0;
          if (id == 'bebe') {
            p['est'] = 'come';
          } else {
            p['servido'] = 1;
          }
        }
      }
      await wait(800);
    },
    // the wrong person takes one bite. The bitten slice goes onto the frog's plate.
    'muerde': (o) async {
      final p = G('${o['quien']}');
      if (p == null) return;
      SFX.munch();
      p['trozo'] = 'mordido';
      if (o['quien'] == 'bebe') p['est'] = 'come';
      await wait(700);
      if (o['quien'] == 'bebe') p['est'] = 'idle';
    },
    // abuela swaps: the bitten slice to his plate, a whole one from his plate to the one who was named
    'abda': (o) async {
      final ab = G('abuela')!,
          x = G('${o['de']}'),
          p = G('${o['a']}')!,
          h = _sitio(o['a']);
      if (x != null) {
        x['trozo'] = 0;
        // to the plate card (sheet: points hud.plato, code line 174)
        await vuelaA(
          x['x'] as num,
          (x['y'] as num) - 30,
          _hudPlato[0],
          _hudPlato[1],
          1,
        );
      }
      ab['lleva'] = 1;
      ab['pose'] = 'offer';
      // relative to SITIO; the row 150 is a floor row (sheet: code line 175, unchanged by the floor rule)
      await mueve(
        'abuela',
        h[0] + (o['a'] == 'bebe' ? 22 : -2),
        o['a'] == 'bebe' ? h[1] - 4 : 150,
      );
      await wait(150);
      ab['lleva'] = 0;
      p['trozo'] = 1;
      SFX.blip();
      await wait(300);
    },
    'vuelve': (o) async {
      final ab = G('abuela')!;
      ab['pose'] = 'idle';
      await mueve('abuela', SITIO['abuela']![0], SITIO['abuela']![1]);
      await ir('centro');
    },
    // the last slice on the dish goes to the one who has had none
    'ultimo': (o) async {
      final ab = G('abuela')!, h = _sitio(o['a']);
      W['pastel'] = 0;
      ab['lleva'] = 1;
      ab['pose'] = 'offer';
      // as abda (sheet: code line 175)
      await mueve(
        'abuela',
        h[0] + (o['a'] == 'bebe' ? 22 : -2),
        o['a'] == 'bebe' ? h[1] - 4 : 150,
      );
      await wait(150);
      ab['lleva'] = 0;
      G('${o['a']}')!['trozo'] = 1;
      SFX.blip();
      await wait(300);
    },
    // she brings the frog his own plate
    'suplato': (o) async {
      final ab = G('abuela')!;
      ab['lleva'] = 'plato';
      ab['pose'] = 'offer';
      final at = _p.floor(180, 158, 200);
      await mueve('abuela', at[0], at[1]);
      ab['dir'] = 1;
      await wait(300);
    },
    'final6': (o) async {
      final ab = G('abuela')!,
          q = W['cq'] as Map<String, dynamic>,
          enteros = 3 - _n(W['lost']);
      ab['lleva'] = 0;
      ab['pose'] = 'idle';
      W['plato'] = 3;
      SFX.munch();
      host.bounce(3);
      await wait(400);
      if (enteros <= 0) {
        final b = G('bebe')!;
        await mueve('bebe', (q['x'] as num) - 2, (q['y'] as num) + 26, 8);
        b['est'] = 'clap';
        b['trozo'] = 0;
        W['vuela'] = null;
        await vuelaA(
          b['x'] as num,
          (b['y'] as num) - 14,
          (q['x'] as num) + 16,
          (q['y'] as num) + 8,
          1,
          .8,
        );
        SFX.munch();
        q['bub'] = 'amor';
        await wait(900);
        q['bub'] = null;
      } else if (enteros >= 3) {
        W['heart'] = 1;
        SFX.win();
        host.fx({'t': 'star', 'n': 36, 'pts': _final});
        await wait(900);
      } else {
        q['bub'] = 'amor';
        SFX.coqui();
        await wait(800);
        q['bub'] = null;
      }
    },
    /* ---- Escuchar ---- */
    // abuelo puts the camera down on the low table
    'ponecamara': (o) async {
      final ab = G('abuelo')!, at = _p.floor(188, 150, 172);
      await mueve('abuelo', at[0], at[1]);
      ab['pose'] = 'idle';
      ab['dir'] = -1;
      W['camMesa'] = 1;
      SFX.blip();
      await wait(400);
    },
    // the camera on the table goes off by itself: the photo of everyone, big, over the room
    'retrato': (o) async {
      flashazo();
      while (F - _n(W['flash']) < 5) {
        await wait(host.TICK);
      }
      // a nearest-neighbour shrink of the picture, smoothing off (sheet: smoothing.notSmoothing; its region is
      // points.retrato), from the last frame drawn (sala.js `sc`)
      final k = Sprite(128, 80, Uint32List(128 * 80)), x = Ctx(k.px, 128, 80);
      x.smoothing = false;
      final sc = _sc;
      if (sc != null) {
        final r = _retrato;
        x.drawImageRect(
          sc.snapshot(0, 0, SW, SH),
          r[0],
          r[1],
          r[2],
          r[3],
          0,
          0,
          128,
          80,
        );
      }
      W['retrato'] = k;
      SFX.luz();
      await wait(900);
    },
    // the frog gets his plate from abuela and eats
    'cqcome': (o) async {
      final ab = G('abuela')!;
      ab['lleva'] = 0;
      ab['pose'] = 'idle';
      W['lleva'] = 1;
      SFX.blip();
      await wait(500);
      for (var k = 0; k < 2; k++) {
        SFX.munch();
        host.bounce(4);
        await wait(380);
      }
      W['lleva'] = 0;
      (W['cq'] as Map<String, dynamic>)['bub'] = 'amor';
      await wait(700);
      (W['cq'] as Map<String, dynamic>)['bub'] = null;
    },
    'ninos': (o) async {
      final a = G('hermano')!, b = G('hermana')!;
      a['vis'] = 1;
      b['vis'] = 1;
      final pa = _p.floor(193, 150, 200), pb = _p.floor(193, 182, 200);
      a['x'] = pa[0];
      a['y'] = pa[1];
      b['x'] = pb[0];
      b['y'] = pb[1];
    },
    'llora': (o) async {
      final b = G('bebe')!;
      b['est'] = jsTruthy(o['no']) ? 'idle' : 'llora';
      if (!jsTruthy(o['no'])) SFX.pio();
      await wait(600);
    },
    'todos': (o) async {
      for (final id in const ['mama', 'papa']) {
        G(id)!['pose'] = 'wave';
      }
      await wait(700);
      for (final id in const ['mama', 'papa']) {
        G(id)!['pose'] = 'idle';
      }
    },
    /* ---- story 7: three photos ---- */
    // the boy and the girl run in and hug the baby
    'corren': (o) async {
      final a = G('hermano')!, b = G('hermana')!;
      a['vis'] = 1;
      b['vis'] = 1;
      // in the new doorway, on its threshold (sheet: spots puerta.hermano, puerta.hermana; code line 198)
      a['x'] = _puertaHermano[0];
      a['y'] = _puertaHermano[1];
      b['x'] = _puertaHermana[0];
      b['y'] = _puertaHermana[1];
      // sheet moves, line 198: mueve("hermano",94,198,10),mueve("hermana",66,203,10) ->
      // mueve("hermano",80,200,10),mueve("hermana",60,204,10) (code line 198)
      final ta = _p.floor(198, 94, 198), tb = _p.floor(198, 66, 203);
      await Future.wait([
        mueve('hermano', ta[0], ta[1], 10),
        mueve('hermana', tb[0], tb[1], 10),
      ]);
      G('bebe')!['est'] = 'clap';
      SFX.pio();
      await wait(800);
      G('bebe')!['est'] = 'idle';
      // then the baby goes up onto mamá's lap, from SITIO.bebe (sheet: code line 199, relative to mamá: unchanged)
      final bb = G('bebe')!, m = G('mama')!, s0 = SITIO['bebe']!;
      for (var i = 1; i <= 6; i++) {
        bb['x'] = s0[0] + ((m['x'] as num) - s0[0]) * i / 6;
        bb['y'] =
            s0[1] +
            ((m['y'] as num) - 15 - s0[1]) * i / 6 -
            math.sin(math.pi * i / 6) * 8;
        await wait(host.TICK);
      }
      bb['x'] = m['x'];
      bb['y'] = (m['y'] as num) - 15;
      bb['z'] = (m['y'] as num) + 1;
      await wait(200);
    },
    // two people take their places, left and right; which side each is on is drawn fresh
    'lados': (o) async {
      final s = azar() ? 0 : 1,
          P = o['donde'] == 'juntos'
              ? JUNTOS
              : o['donde'] == 'parados'
              ? PARADOS
              : APARTE;
      if (o['donde'] == 'parados') {
        G('${o['a']}')!['servido'] = 0;
        G('${o['b']}')!['servido'] = 0;
      }
      await Future.wait([
        mueve('${o['a']}', P[s][0], P[s][1]),
        mueve('${o['b']}', P[1 - s][0], P[1 - s][1]),
      ]);
    },
    'sientan': (o) async {
      await Future.wait([
        mueve('mama', SITIO['mama']![0], SITIO['mama']![1]),
        mueve('papa', SITIO['papa']![0], SITIO['papa']![1]),
      ]);
      G('mama')!['sent'] = 1;
      G('papa')!['sent'] = 1;
      final bb = G('bebe'), m = G('mama')!;
      // the baby settles back on her lap
      if (bb != null && jsTruthy(bb['z'])) {
        bb['x'] = m['x'];
        bb['y'] = (m['y'] as num) - 15;
        bb['z'] = (m['y'] as num) + 1;
      }
    },
    'camara': (o) async {
      final ab = G('abuelo')!;
      await mueve('abuelo', CAMARA[0], CAMARA[1]);
      ab['dir'] = -1;
      ab['pose'] = 'foto';
      await wait(250);
    },
    // the frog hops beside someone (the 120 is the room's middle and 150 a floor row: sheet code line 205, unchanged)
    'junto': (o) async {
      final p = G('${o['en']}')!,
          px = p['x'] as num,
          py = p['y'] as num,
          cx = px + (px < 120 ? -24 : 24),
          s = py < 150 ? .9 : 1;
      await host.hopTo(_round(cx - 16), _round(py + 5 - 27), 2, s);
    },
    // a photo under the sign: a flash, and it pops up for a moment
    'prueba': (o) async {
      flashazo();
      await wait(300);
      final p = G('${o['con']}')!;
      host.fx({
        't': 'star',
        'n': 8,
        'pts': [
          [_round(p['x'] as num), _round(p['y'] as num) - 50],
        ],
      });
      await wait(500);
    },
    // a photo for the wall. ok: the frog and that person, straight. Not ok: that person alone, the frog's foot at the
    // edge, crooked.
    'dispara': (o) async {
      final ok = o['ok'] == '1' || o['ok'] == 1,
          i = nFotos(),
          p = G('${o['con']}')!;
      if (!ok) {
        p['pose'] = 'wave';
        await wait(300);
      }
      flashazo();
      await wait(350);
      _setFoto(
        i,
        ok
            ? <String, dynamic>{
                'q': jsTruthy(o['solo']) ? [o['con']] : ['coqui', o['con']],
                'ok': 1,
              }
            : <String, dynamic>{
                'q': [o['con']],
                'ok': 0,
                'pata': 1,
              },
      );
      SFX.blip();
      // over the middle of frame i (sheet: code line 209)
      host.fx({
        't': 'star',
        'n': ok ? 10 : 4,
        'pts': [if (i < _fotoStar.length) _fotoStar[i]],
      });
      await wait(700);
      p['pose'] = 'idle';
    },
    // the camera goes off at abuelo's feet: a photo of his slippers
    'pies': (o) async {
      final ab = G('abuelo')!, i = nFotos();
      ab['pose'] = 'idle';
      ab['bub'] = 'q';
      await wait(500);
      flashazo();
      await wait(350);
      _setFoto(i, <String, dynamic>{'ok': 0, 'pies': 1});
      SFX.bonk();
      ab['bub'] = null;
      await wait(700);
      ab['pose'] = 'foto';
    },
    // one child alone in the middle; the camera's little window shows a blur
    'solo': (o) async {
      final quien = '${o['quien']}',
          otro = quien == 'hermano' ? 'hermana' : 'hermano';
      // sheet moves, line 214: mueve(o.quien,120,146),mueve(otro,72,206) -> mueve(o.quien,120,136),mueve(otro,56,206)
      // (code line 214)
      final a = _p.floor(214, 120, 146), b = _p.floor(214, 72, 206);
      await Future.wait([
        mueve(quien, a[0], a[1]),
        mueve(otro, b[0], b[1]),
        ir('centro'),
      ]);
      W['visor'] = <String, dynamic>{'quien': quien, 'nitido': 0};
      // while abuelo asks who it is, a poke on the child gets a hello, not a name (the old scene's own lines)
      W['apodo'] = <String, dynamic>{
        quien: quien == 'hermano' ? 'el_dice_hola' : 'ella_dice_hola',
      };
      await wait(400);
    },
    'nitido': (o) async {
      final v = W['visor'] as Map<String, dynamic>?;
      if (v != null) v['nitido'] = 1;
      SFX.luz();
      await wait(450);
    },
    'quitavisor': (o) async {
      W['visor'] = null;
      W['apodo'] = null;
    },
    // the wall, then everyone together for one last photo
    'final7': (o) async {
      final fotos = (W['fotos'] as List?) ?? const [];
      final ok = fotos.where((f) => f is Map && jsTruthy(f['ok'])).length;
      W['visor'] = null;
      // the wall as he left it, for the next story
      V['fotos'] = [
        for (final f in fotos)
          f is! Map
              ? ''
              : jsTruthy(f['pies'])
              ? 'pies'
              : '${(f['q'] as List).firstWhere((k) => k != 'coqui', orElse: () => 'undefined')}'
                    '.${jsTruthy(f['ok']) ? 1 : 0}${jsTruthy(f['pata']) ? 'p' : ''}'
                    '${(f['q'] as List).contains('coqui') ? 'c' : ''}',
      ].join('-');
      // over the middle of each straight frame (sheet: code line 221)
      host.fx({
        't': 'star',
        'n': 14,
        'pts': [
          for (var i = 0; i < fotos.length; i++)
            if (fotos[i] is Map &&
                jsTruthy((fotos[i] as Map)['ok']) &&
                i < _fotoStar7.length)
              _fotoStar7[i],
        ],
      });
      await wait(900);
      if (ok >= 3) {
        W['heart'] = 1;
        SFX.win();
      } else {
        SFX.coqui();
      }
      await wait(500);
      final ab = G('abuelo')!;
      ab['pose'] = 'idle';
      ab['dir'] = 1;
      G('mama')!['servido'] = 0;
      G('papa')!['servido'] = 0;
      // sheet moves, line 224: mueve("abuelo",172,160) -> mueve("abuelo",186,164); the others keep their places (code
      // line 224)
      final pm = _p.floor(224, 98, 146),
          pp = _p.floor(224, 142, 146),
          pao = _p.floor(224, 172, 160),
          pab = _p.floor(224, 66, 160),
          pho = _p.floor(224, 140, 190),
          pha = _p.floor(224, 100, 190),
          pbb = _p.floor(224, 106, 124);
      await Future.wait([
        mueve('mama', pm[0], pm[1]),
        mueve('papa', pp[0], pp[1]),
        mueve('abuelo', pao[0], pao[1]),
        mueve('abuela', pab[0], pab[1]),
        mueve('hermano', pho[0], pho[1]),
        mueve('hermana', pha[0], pha[1]),
        ir('centro'),
      ]);
      // the baby on mamá's lap; z is the row it is sorted at (not a place on the screen)
      G('bebe')!['x'] = pbb[0];
      G('bebe')!['y'] = pbb[1];
      G('bebe')!['z'] = 147;
      await wait(300);
    },
    'flash': (o) async {
      flashazo();
      await wait(500);
    },
    /* ---- story 8: abuelo cannot find his glasses ---- */
    // the start of story 8: the children by the frog, abuelo wandering with his coffee, his glasses up on his head; the
    // photos from La foto on the wall
    'inicio8': (o) async {
      final a = G('hermano')!, b = G('hermana')!, ab = G('abuelo')!;
      a['vis'] = 1;
      b['vis'] = 1;
      // sheet moves, line 228: a.x=156;a.y=200;a.dir=-1;b.x=84;b.y=200; -> a.x=184;a.y=200;a.dir=-1;b.x=56;b.y=200;
      // (code line 228)
      final pa = _p.floor(228, 156, 200), pb = _p.floor(228, 84, 200);
      a['x'] = pa[0];
      a['y'] = pa[1];
      a['dir'] = -1;
      b['x'] = pb[0];
      b['y'] = pb[1];
      ab['sent'] = 0;
      final pab = _p.floor(228, 190, 150);
      ab['x'] = pab[0];
      ab['y'] = pab[1];
      ab['pose'] = 'taza';
      ab['gafas'] = 'arriba';
      ab['dir'] = -1;
      // the baby is on mamá's lap (z: the row it is sorted at)
      final bb = G('bebe')!, pbb = _p.floor(228, 97, 112);
      bb['x'] = pbb[0];
      bb['y'] = pbb[1];
      bb['z'] = 128;
      final mem = V['mem_fotos'];
      final ts = (jsTruthy(mem) ? '$mem' : '').split('-');
      for (var i = 0; i < ts.length; i++) {
        final t = ts[i];
        if (t.isEmpty || i > 2) continue;
        if (t == 'pies') {
          _setFoto(i, <String, dynamic>{'ok': 0, 'pies': 1});
          continue;
        }
        final m = t.split('.'), f = m.length > 1 ? m[1] : '';
        _setFoto(i, <String, dynamic>{
          'q': [if (f.contains('c')) 'coqui', m[0]],
          'ok': f.isNotEmpty && f[0] == '1' ? 1 : 0,
          'pata': f.contains('p') ? 1 : 0,
        });
      }
    },
    'tropieza': (o) async {
      final ab = G('abuelo')!, at = _p.floor(230, 162, 176);
      await mueve('abuelo', at[0], at[1]);
      W['golpe'] = F;
      SFX.bonk();
      ab['rie'] = 1;
      await wait(600);
      ab['rie'] = 0;
      W['borroso'] = 1;
      await wait(1100);
      W['borroso'] = 0;
      await wait(200);
    },
    'acerca': (o) async {
      await ir('centro');
      final at = _p.floor(231, 192, 180);
      await mueve('abuelo', at[0], at[1]);
      G('abuelo')!['dir'] = -1;
      await wait(200);
    },
    'palmada': (o) async {
      final q = W['cq'] as Map<String, dynamic>;
      q['bub'] = 'amor';
      SFX.coqui();
      host.bounce(5);
      await wait(700);
      q['bub'] = null;
    },
    'rie': (o) async {
      final p = G(jsTruthy(o['quien']) ? '${o['quien']}' : 'abuelo')!;
      p['rie'] = 1;
      await wait(700);
      p['rie'] = 0;
    },
    // a child creeps up behind the frog and covers his eyes
    'tapa': (o) async {
      final q = W['cq'] as Map<String, dynamic>, ab = G('abuelo')!;
      await ir('centro');
      // the room's middle (sheet: code line 235, unchanged); relative to the frog
      if (((ab['x'] as num) - 120).abs() < 60) {
        final at = _p.floor(235, 192, 180);
        await mueve('abuelo', at[0], at[1]);
      }
      await mueve('${o['quien']}', (q['x'] as num) + 16, (q['y'] as num) + 22);
      G('${o['quien']}')!['pose'] = 'ojos';
      W['tapaojos'] = o['quien'];
      SFX.blip();
      await wait(400);
    },
    'suelta': (o) async {
      W['tapaojos'] = null;
      G('${o['quien']}')!['pose'] = 'idle';
      // sheet moves, line 236: mueve(o.quien,o.quien==="hermano"?152:86,200) ->
      // mueve(o.quien,o.quien==="hermano"?184:56,200) (code line 236)
      final at = o['quien'] == 'hermano'
          ? _p.floor(236, 152, 200)
          : _p.floor(236, 86, 200);
      await mueve('${o['quien']}', at[0], at[1]);
    },
    'gira': (o) async {
      final ab = G('abuelo')!;
      ab['dir'] = -(jsTruthy(ab['dir']) ? ab['dir'] as num : 1);
      await wait(200);
    },
    // abuelo walks over to mamá or papá (relative: sheet code line 239)
    'abva': (o) async {
      final p = G('${o['a']}')!, ab = G('abuelo')!, px = p['x'] as num;
      await mueve('abuelo', px + (px < 120 ? -22 : 22), (p['y'] as num) + 10);
      ab['dir'] = (p['x'] as num) < (ab['x'] as num) ? -1 : 1;
      await wait(200);
    },
    // the baby, on mamá's arm, pulls the glasses down onto his nose
    'espejuelos': (o) async {
      final m = G('mama')!, b = G('bebe')!, ab = G('abuelo')!;
      m['servido'] = 0;
      if (jsTruthy(m['sent'])) {
        await mueve('mama', PARADOS[0][0], PARADOS[0][1]);
      }
      b['x'] = (m['x'] as num) + 9;
      b['y'] = (m['y'] as num) - 26;
      b['z'] = (m['y'] as num) + 1;
      await mueve('abuelo', (m['x'] as num) + 28, (m['y'] as num) + 6);
      ab['dir'] = -1;
      await wait(300);
      b['est'] = 'clap';
      SFX.pio();
      await wait(400);
      ab['gafas'] = 1;
      SFX.luz();
      host.fx({
        't': 'star',
        'n': 10,
        'pts': [
          [_round(ab['x'] as num), _round(ab['y'] as num) - 58],
        ],
      });
      await wait(700);
      b['est'] = 'idle';
    },
    'fin8': (o) async {
      await wait(900);
    },
    // right the first time: a heart that stays by abuelo's cup
    'corazon': (o) async {
      W['aciertos'] = _n(W['aciertos']) + 1;
      SFX.luz();
      await wait(300);
    },
    'final8': (o) async {
      final ab = G('abuela')!, ao = G('abuelo')!, n = 3 - _n(W['lost']);
      ao['pose'] = 'taza';
      if (n >= 3) {
        for (var k = 0; k < 3; k++) {
          glu();
          await wait(300);
        }
        W['heart'] = 1;
        SFX.win();
        host.fx({'t': 'star', 'n': 36, 'pts': _final});
        await wait(900);
      } else if (n > 0) {
        for (var k = 0; k < n; k++) {
          glu();
          await wait(300);
        }
        SFX.coqui();
        await wait(600);
      } else {
        ao['bub'] = 'q';
        SFX.drop();
        await wait(700);
        ao['bub'] = null;
        // sheet moves, line 247: mueve("abuelo",150,170) -> mueve("abuelo",172,178) (code line 247)
        final pao = _p.floor(247, 150, 170);
        await mueve('abuelo', pao[0], pao[1]);
        ao['dir'] = 1;
        ao['pose'] = 'taza';
        // sheet moves, line 247: mueve("abuela",182,172) -> mueve("abuela",200,176) (code line 247)
        final pab = _p.floor(247, 182, 172);
        await mueve('abuela', pab[0], pab[1]);
        ab['pose'] = 'offer';
        ab['dir'] = -1;
        SFX.luz();
        W['relleno'] = 1;
        await wait(900);
        ab['pose'] = 'idle';
      }
    },
  };

  // sala.js: stake
  // the thing at stake takes a step
  @override
  Future<void> stake(int lost, int max, String en) async {
    final t = (S['stake'] as Map<String, dynamic>)['thing'];
    if (t == 'cafe') {
      final ab = G('abuelo')!;
      W['gotas'] = <String, dynamic>{
        'x': (ab['x'] as num) + (_dir(ab) < 0 ? -13 : 13),
        'y': (ab['y'] as num) - 28,
        'f': F,
      };
      SFX.drop();
      await wait(250);
      SFX.drop();
      await wait(500);
      return;
    }
    if (t == 'fotos') {
      SFX.bonk();
      await wait(300);
      return;
    }
    SFX.bonk();
    await wait(300);
  }

  // sala.js: poke
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

  // sala.js: estado
  @override
  String estado(Map<String, dynamic> W) {
    final g = (W['gente'] as Map<String, dynamic>?) ?? const {};
    final gente = [
      for (final k in g.keys)
        if (g[k] != null && (g[k] as Map)['vis'] != 0)
          () {
            final p = g[k] as Map<String, dynamic>;
            return '$k@${jsNum(_round(p['x'] as num))},${jsNum(_round(p['y'] as num))}'
                '${jsTruthy(p['sent']) ? 's' : ''}${jsTruthy(p['bub']) ? '[${p['bub']}]' : ''}';
          }(),
    ].join(' ');
    final visor = W['visor'] as Map<String, dynamic>?;
    return 'gente=$gente plato=${_js(W['plato'])} pastel=${_js(W['pastel'])}'
        ' lleva=${_js(jsTruthy(W['lleva']) ? W['lleva'] : 0)} fotos=${jsonEncode(W['fotos'] ?? const [])}'
        ' visor=${visor != null ? '${visor['quien']}${_js(visor['nitido'])}' : '-'}'
        ' tapa=${jsTruthy(W['tapaojos']) ? W['tapaojos'] : '-'}'
        ' cafe=${_js(jsTruthy(W['cafe']) ? W['cafe'] : 0)}';
  }

  // remap is not in the old file. Page 12, section 5: every position a story, pair or level file holds goes through the
  // sheet's remap table. A floor point (a person's feet, the frog's) keeps its screen place (the sheet's `new`); a pair
  // rectangle gives the crop of the pictures it was; a level picture's rectangle or x gives itself back (the level
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
        if (r.now != null) return r.now!;
        final to = r.to;
        if (to.spot != null) return _p.spot(to.spot!);
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

/// One entry of sala.js's drawing list (`lista`): the row it is sorted by, how it is drawn, who it is (a person's id,
/// `coqui`), and whether it is the low table.
class SalaItem {
  SalaItem(this.y, this.d, {this.id, this.mesa = false});

  final num y;
  final void Function() d;
  final String? id;
  final bool mesa;
}
