// El baño (place 9, La casa, un día entero, scene 2: `bano`; stories 99 to 101): a NEW scene, written from its
// script's "Needs" list (historia/notas/guiones/bano.md) on its set (bano_set.dart) and its sheet (bano-sheet.json,
// read by SceneSheet). There is no old scene file: every act is this file's (and bano_acts.dart's), each doing on
// screen what the Needs list says, every place from the sheet (spots, set thing boxes, gauge bars, view `wide`, depth
// rule, shadows). Where the sheet names no place or an act is unstated in the script, the code does the plainest
// thing that keeps the story playing and marks it `OPEN:`.
//
// The drawing (the sheet's `front`): every person stands with their feet's bottom edge (`inkBottom`) on their spot's
// row and their middle on its column (rules.anchor); small things stand with their bottom edge on their spot's row;
// Carmen's step stool (`banquito`) hangs down from her feet (top row on `sy`); towels over heads (`toallaCab`) align
// with the top of the child's ink; gauge bars sit centred on `calentador.bars`. Every sprite pixel is hidden by any
// baked set pixel nearer than its upright plane plus `front.bias` (0.3), which hides whoever stands inside the shower
// behind its low front wall. Between two sprites the nearer pixel wins (tie within 0.001 goes to the later layer; the
// frog is drawn last among world sprites).
// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/src/bano/bano_places.dart';
import 'package:coqui_scenes/src/bano/bano_set.dart';
import 'package:coqui_scenes/src/bano/bano_sprites.dart';
import 'package:coqui_scenes/src/colmado/colmado_cast.dart' show inkBottom;
import 'package:coqui_scenes/src/scene_set.dart';
import 'package:coqui_scenes/src/sheet_cache.dart';

part 'bano_acts.dart';

/// The scene "El baño", made from its sheet (read first: `loadScene`).
Scene createBano() => Bano(sceneSheetOf('bano'));

int _round(num v) => (v + 0.5).floor();

int _n(Object? v) {
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? 0;
  return 0;
}

/// Every person El baño knows (plus `perro` and `coqui`).
const List<String> BANO_PERSONAS = ['abuela', 'abuelo', 'luis', 'carmen'];

/// Top drawn row of [s] (`inkTop` from bano-preview.html).
int _inkTop(Sprite s) {
  for (var y = 0; y < s.h; y++) {
    for (var x = 0; x < s.w; x++) {
      if (s.px[y * s.w + x] >>> 24 != 0) return y;
    }
  }
  return 0;
}

/// One sprite of the sprite layer, placed: its picture, its top left on the 240 × 216 picture, the screen row of its
/// anchor and the depth there (front.plane), and who or what it is.
class BanoItem {
  BanoItem(
    this.s,
    this.left,
    this.top,
    this.sy,
    this.d, {
    this.tag,
    this.overlay = false,
  });

  final Sprite s;
  final int left, top;
  final num sy;
  final double d;
  final String? tag;

  /// Screen-space overlay drawn over the set and world sprites (celebration cues / mirror reflection).
  final bool overlay;
}

class Bano extends Escena implements SetScene, SetOverSprites {
  Bano(this.ss)
    : sheet = identical(ss, _lastSs)
          ? _lastSheet!
          : (_lastSheet = ss.legacy()) {
    _p = identical(ss, _lastSs) ? _lastPlaces! : (_lastPlaces = BanoPlaces(ss));
    _lastSs = ss;
    CAM = {'wide': _p.view('wide')};
    LUGAR = {
      for (final en in ss.spots.entries)
        if (en.value.world != null) en.key: _frogAt(_p.at(en.key)),
    };
    cosas = _things();
  }

  static SceneSheet? _lastSs;
  static Sheet? _lastSheet;
  static BanoPlaces? _lastPlaces;

  /// The new scene's sheet (SceneSheet).
  final SceneSheet ss;

  @override
  final Sheet sheet;

  late final BanoPlaces _p;

  /// The scene's places, from its sheet.
  BanoPlaces get places => _p;

  @override
  String get id => 'bano';

  @override
  late final Map<String, List<num>> CAM;

  late final Map<String, List<num>> LUGAR;

  @override
  Map<String, List<num>> get lugar => LUGAR;

  @override
  late final List<Thing> cosas;

  @override
  PpEngine newEngine({bool still = false}) => banoEngine(still: still);

  @override
  PpEngine get projection => _p.e;

  List<num> _frogAt(BanoAt a) => [_round(a.sx) - 16, _round(a.sy) - 25, 1];

  Map<String, dynamic> get W => host.W;
  int get F => host.F;
  int get TICK => host.TICK;
  Future<void> wait(num ms) => host.wait(ms);

  /* ---------- the state ---------- */

  static List<Map<String, dynamic>> _actsOf(Object? x) {
    final out = <Map<String, dynamic>>[];
    void walk(Object? v) {
      if (v is Map) {
        if (v['act'] is String) out.add(v.cast<String, dynamic>());
        v.values.forEach(walk);
      } else if (v is List) {
        v.forEach(walk);
      }
    }

    walk(x);
    return out;
  }

  Map<String, dynamic> _person(
    String spot, {
    int vis = 1,
    int mudHands = 0,
    int mudFace = 0,
    int robe = 0,
  }) {
    final w = _p.world(spot);
    return <String, dynamic>{
      'x': w[0],
      'y': w[1],
      'z': w[2],
      'spot': spot,
      'vis': vis,
      'pose': 'idle',
      'dx': 0,
      'dy': 0,
      'mudHands': mudHands,
      'mudFace': mudFace,
      'shine': 0,
      'teeth': 0,
      'flatHair': 0,
      'pasteHair': 0,
      'combMouth': 0,
      'raincoat': 0,
      'towelHead': 0,
      'robe': robe,
      'holdingTowel': 0,
      'smellFace': 0,
    };
  }

  @override
  Map<String, dynamic> fresh(Map<String, dynamic> story) {
    final acts = _actsOf([story['beats'], story['final']]);
    bool has(String a) => acts.any((o) => o['act'] == a);
    final is101 =
        has('tubo') ||
        has('cepilla101') ||
        has('peina101') ||
        has('repisa101') ||
        has('final101');
    final is100 =
        !is101 &&
        (has('barras') || has('ducha100') || has('capa100') || has('final100'));
    final storyNum = is101 ? 101 : (is100 ? 100 : 99);
    final startSpot = storyNum == 99 ? 'piso_coqui' : 'repisa_coqui';
    final q = _frogAt(_p.at(startSpot));

    final gente = <String, dynamic>{
      // OPEN: in Story 100, `abuela_bano` (84,100) overlaps Coquí's feet at `repisa_coqui` (90,52);
      // start abuela at `piso_perro` (151,118) — clear of Coquí, fixtures, puertas, and sink — until `junto_puerta`.
      'abuela': _person(
        storyNum == 100 ? 'piso_perro' : 'abuela_bano',
        vis: is101 ? 0 : 1,
      ),
      'abuelo': _person('puerta1', vis: 0, robe: is100 ? 1 : 0),
      'luis': _person('puerta1', vis: 0, mudHands: storyNum == 99 ? 1 : 0),
      'carmen': _person(
        is101 ? 'banquito' : 'puerta2',
        vis: 0,
        mudFace: storyNum == 99 ? 1 : 0,
      ),
    };

    return <String, dynamic>{
      'story': storyNum,
      'hora': 'dia',
      'gente': gente,
      // Story 99 props
      'perroVis': storyNum == 99 ? 1 : 0,
      'perroSpot': 'piso_perro',
      'perroMuddy': storyNum == 99 ? 1 : 0,
      'jabonVis': storyNum == 99 ? 1 : 0,
      'jabon': storyNum == 99 ? 3 : 0,
      'toallasVis': 0,
      'toallaA': 'verde',
      'toallaB': 'amarillo',
      'bubblesAt': null, // null | 'luis' | 'carmen' | 'ducha'
      'coquiMuddy': storyNum == 99 ? 1 : 0,
      'coquiFoam': 0, // 0..3
      'agua99': null, // null | 'caliente'
      // Story 100 props
      'barrasVis': is100 ? 1 : 0,
      'barras': is100 ? 3 : 0,
      'duchaOn': 0,
      'llaveOn': 0,
      'espejoCoqui': 0,
      'vaporDucha': 0,
      'notasDucha': 0,
      // Story 101 props
      'tuboVis': is101 ? 1 : 0,
      'tubo': is101 ? 4 : 0,
      'cepillitoVis': is101 ? 1 : 0,
      'cepillitoPaste': 0, // 0..3
      'cosasVis': is101 ? 1 : 0,
      'cosaA': 'cepillo',
      'cosaB': 'peinilla',
      'cepilloPaste': 0,
      'espejoSparkle': 0,
      // Celebration cues
      'corazonFx': 0,
      'estrellaFx': 0,
      // HUD card
      'tarjeta': null,
      'marcas': null,
      'cq': <String, dynamic>{
        'x': q[0],
        'y': q[1],
        's': 1,
        'dy': 0,
        'dx': 0,
        'al': 1,
        'vis': 1,
        'bub': null,
        'spot': startSpot,
        'z': _p.world(startSpot)[2],
      },
    };
  }

  /* ---------- sprites and placement ---------- */

  static final Map<String, Sprite> _cache = {};
  Sprite _spr(String key, Sprite Function() make) =>
      _cache.putIfAbsent(key, make);

  String? _talker() {
    try {
      return host.TALK;
    } catch (_) {
      return null;
    }
  }

  BanoAt _atOf(Map<String, dynamic> p) => _p.atWorld(
    (p['x'] as num).toDouble(),
    (p['y'] as num).toDouble(),
    (p['z'] as num).toDouble(),
  );

  BanoAt _frogPoint(Map<String, dynamic> q) {
    final spot = q['spot'] as String?;
    final z = (q['z'] as num?)?.toDouble() ?? 0.0;
    final qx = (q['x'] as num).toDouble();
    final qy = (q['y'] as num).toDouble();
    if (spot != null && _p.hasWorld(spot)) {
      final at = _p.at(spot);
      final target = _frogAt(at);
      if ((qx - target[0]).abs() < 1 && (qy - target[1]).abs() < 1) {
        return at;
      }
    }
    return _p.fromScreen(qx + 16, qy + 25, z);
  }

  bool _personAt(Map<String, dynamic> w, String who, String spot) {
    final p = (w['gente'] as Map?)?[who] as Map?;
    return p != null && p['vis'] != 0 && p['spot'] == spot;
  }

  bool _anyoneAt(Map<String, dynamic> w, String spot) {
    final gente = (w['gente'] as Map?) ?? const {};
    for (final v in gente.values) {
      if (v is Map && v['vis'] != 0 && v['spot'] == spot) return true;
    }
    return false;
  }

  /// Every sprite to draw over the set, except the frog (who is added in [placed]).
  List<BanoItem> items(Map<String, dynamic> w, int a) {
    final out = <BanoItem>[];
    final talk = _talker();
    final anim = (a / 3).floor();
    final gente = (w['gente'] as Map<String, dynamic>?) ?? const {};

    // 1. People (abuela, abuelo, luis, carmen)
    for (final id in BANO_PERSONAS) {
      final p = gente[id] as Map<String, dynamic>?;
      if (p == null || p['vis'] == 0) continue;
      final at = _atOf(p);
      final sx = _round(at.sx) + _n(p['dx']);
      final sy = _round(at.sy) + _n(p['dy']);
      final spot = p['spot'] as String?;
      final pose = (p['pose'] as String?) ?? 'idle';
      final open = talk == id && a % 2 != 0;
      final effectiveId = id == 'abuelo' && _n(p['robe']) == 1
          ? 'abuelo_bata'
          : (_n(p['raincoat']) == 1 ? 'lluvia' : id);
      final mudHands = _n(p['mudHands']) == 1;
      final mudFace = _n(p['mudFace']) == 1;
      final shine = _n(p['shine']) == 1;
      final teeth = _n(p['teeth']) == 1;
      final flatHair = _n(p['flatHair']) == 1;
      final pasteHair = _n(p['pasteHair']) == 1;
      final combMouth = _n(p['combMouth']) == 1;
      final holdingTowel = _n(p['holdingTowel']) == 1;
      final smellFace = _n(p['smellFace']) == 1;
      final key =
          'bn_p_${effectiveId}_${pose}_${open}_${mudHands}_${mudFace}_${shine}_${teeth}_${flatHair}_${pasteHair}_${combMouth}_${holdingTowel}_$smellFace';
      final s = _spr(
        key,
        () => mkBanoPersona(
          effectiveId,
          pose,
          open: open,
          mudHands: mudHands,
          mudFace: mudFace,
          shine: shine,
          teeth: teeth,
          flatHair: flatHair,
          pasteHair: pasteHair,
          combMouth: combMouth,
          holdingTowel: holdingTowel,
          smellFace: smellFace,
        ),
      );
      final ax = effectiveId == 'abuela' ? 30 : PX;
      final ay = inkBottom(s);

      // Stand-in stool under Carmen at `banquito` (12 x 7, top row on her feet's row sy)
      if (spot == 'banquito') {
        final st = _spr('bn_taburete', mkTabureteBano);
        out.add(BanoItem(st, sx - 6, sy, sy, at.d - .01, tag: 'fx:taburete'));
      }

      out.add(BanoItem(s, sx - ax, sy - ay, sy, at.d, tag: 'persona:$id'));

      // Towel over child's head (`toallaCab`, top row on top row of child's ink)
      if (_n(p['towelHead']) == 1) {
        final tc = _spr('bn_toalla_cab', mkToallaCab);
        final childTop = sy - ay + _inkTop(s);
        out.add(
          BanoItem(
            tc,
            sx - 8,
            childTop,
            sy,
            at.d + .02,
            tag: 'fx:toalla_cab_$id',
          ),
        );
      }
    }

    // 2. Canelo
    if (_n(w['perroVis']) == 1) {
      final spot = (w['perroSpot'] as String?) ?? 'piso_perro';
      final at = _p.at(spot);
      final sx = _round(at.sx), sy = _round(at.sy);
      final muddy = _n(w['perroMuddy']) == 1;
      final s = _spr(
        'bn_perro_${muddy}_${anim % 2}',
        () => mkBanoPerro(anim % 2, muddy: muddy),
      );
      out.add(
        BanoItem(s, sx - 15, sy - inkBottom(s), sy, at.d, tag: 'persona:perro'),
      );
    }

    // 3. Story 99 soap and folded towels
    // OPEN: when Coquí sits inside the sink (`lavamanos_coqui`), he takes the soap with him (moment 3);
    // hiding the lip bar prevents its box [124,52,8,5] from overlapping 3 px of his foot.
    if (_n(w['jabonVis']) == 1 &&
        (w['cq'] as Map?)?['spot'] != 'lavamanos_coqui') {
      final n = _n(w['jabon']).clamp(1, 3);
      final at = _p.at('jabon');
      final sx = _round(at.sx), sy = _round(at.sy);
      final s = _spr('bn_jabon_$n', () => mkJabon(n));
      out.add(BanoItem(s, sx - 4, sy - s.h, sy, at.d, tag: 'cosa:jabon'));
    }

    if (_n(w['toallasVis']) == 1) {
      final colA = (w['toallaA'] as String?) ?? 'verde';
      final colB = (w['toallaB'] as String?) ?? 'amarillo';
      for (final (spot, col) in [('toalla_a', colA), ('toalla_b', colB)]) {
        final at = _p.at(spot);
        final sx = _round(at.sx), sy = _round(at.sy);
        final s = _spr('bn_toalla_$col', () => mkToalla(col));
        out.add(BanoItem(s, sx - 6, sy - s.h, sy, at.d, tag: 'cosa:$spot'));
      }
    }

    // 4. Story 100 gauge bars (centred on `calentador.bars`)
    if (_n(w['barrasVis']) == 1) {
      final count = _n(w['barras']).clamp(0, 3);
      final gUv = _p.gaugeUv;
      final gaugeAt = _p.atWorld(
        (gUv[0] + 0) / _p.e.R2,
        (0 - gUv[0]) / _p.e.R2,
        gUv[1],
      );
      final bars = _p.gaugeBars;
      final barSpr = _spr('bn_barra', mkBarraGauge);
      for (var i = 0; i < count && i < bars.length; i++) {
        final bx = bars[i];
        out.add(
          BanoItem(
            barSpr,
            bx[0],
            bx[1],
            _round(gaugeAt.sy) + (i - 1) * 3,
            gaugeAt.d + .02,
            tag: 'fx:barra_${i + 1}',
          ),
        );
      }
    }

    // 5. Story 101 tube, tiny brush, shelf toothbrush & comb
    if (_n(w['tuboVis']) == 1) {
      final n = _n(w['tubo']).clamp(0, 4);
      final at = _p.at('tubo');
      final sx = _round(at.sx), sy = _round(at.sy);
      final s = _spr('bn_tubo_$n', () => mkTubo(n));
      out.add(BanoItem(s, sx - 2, sy - s.h, sy, at.d, tag: 'cosa:tubo'));
    }

    // OPEN: hide `cepillito` while Carmen stands on `banquito` (her body covers [125,53,6,4] in moment 7).
    if (_n(w['cepillitoVis']) == 1 && !_anyoneAt(w, 'banquito')) {
      final paste = _n(w['cepillitoPaste']).clamp(0, 3);
      final at = _p.at('cepillito');
      final sx = _round(at.sx), sy = _round(at.sy);
      final s = _spr('bn_cepillito_$paste', () => mkCepillito(paste: paste));
      out.add(BanoItem(s, sx - 3, sy - s.h, sy, at.d, tag: 'cosa:cepillito'));
    }

    if (_n(w['cosasVis']) == 1) {
      final paste = _n(w['cepilloPaste']) == 1;
      for (final (spot, kind) in [
        ('cosa_a', (w['cosaA'] as String?) ?? 'cepillo'),
        ('cosa_b', (w['cosaB'] as String?) ?? 'peinilla'),
      ]) {
        final at = _p.at(spot);
        final sx = _round(at.sx), sy = _round(at.sy);
        final s = kind == 'cepillo'
            ? _spr('bn_cepillo_$paste', () => mkCepillo(paste: paste))
            : _spr('bn_peinilla', mkPeinilla);
        out.add(BanoItem(s, sx - 6, sy - s.h, sy, at.d, tag: 'cosa:$spot'));
      }
    }

    // 6. Water, steam, bubbles, mirror reflection, singing notes
    if (_n(w['duchaOn']) == 1) {
      final at = _p.at('ducha_dentro');
      final sx = _round(at.sx);
      final ag = _spr('bn_agua_ducha_${anim % 3}', () => mkAguaDucha(anim));
      out.add(BanoItem(ag, sx - 7, 14, 34, at.d - .02, tag: 'fx:agua_ducha'));
    }
    if (_n(w['llaveOn']) == 1) {
      final lb = _p.box('llave_lavamanos');
      final at = _p.at('lavamanos_coqui');
      final ag = _spr('bn_agua_llave_${anim % 2}', () => mkAguaLlave(anim));
      out.add(
        BanoItem(
          ag,
          lb[0] + 3,
          lb[1] + 2,
          lb[1] + 12,
          at.d + .01,
          tag: 'fx:agua_llave',
        ),
      );
    }
    if (_n(w['vaporDucha']) == 1) {
      final vp = _spr('bn_vapor_${anim % 2}', () => mkVaporBano(anim));
      out.add(
        BanoItem(vp, 35, 16, 28, 3.0, tag: 'fx:vapor_ducha', overlay: true),
      );
    }
    if (_n(w['notasDucha']) == 1) {
      final nt = _spr('bn_notas_${anim % 2}', () => mkNotasBano(anim));
      out.add(
        BanoItem(nt, 48, 12, 20, 3.0, tag: 'fx:notas_ducha', overlay: true),
      );
    }
    if (w['agua99'] == 'caliente') {
      final at = _p.at('lavamanos_coqui');
      final vp = _spr('bn_vapor_${anim % 2}', () => mkVaporBano(anim));
      out.add(
        BanoItem(
          vp,
          _round(at.sx) - 7,
          _round(at.sy) - 34,
          at.sy,
          at.d + .02,
          tag: 'fx:vapor_sink',
        ),
      );
    }

    final bubWho = w['bubblesAt'] as String?;
    if (bubWho != null) {
      final p = gente[bubWho] as Map<String, dynamic>?;
      if (p != null && p['vis'] != 0) {
        final at = _atOf(p);
        final bb = _spr('bn_burbujas_${anim % 2}', () => mkBurbujas(anim));
        out.add(
          BanoItem(
            bb,
            _round(at.sx) - 6,
            _round(at.sy) - 32,
            _round(at.sy),
            at.d + .02,
            tag: 'fx:burbujas',
          ),
        );
      }
    }

    if (_n(w['espejoCoqui']) == 1 || _n(w['espejoSparkle']) == 1) {
      final m = _p.box('espejo');
      final sp = _n(w['espejoSparkle']) == 1;
      final ef = _spr('bn_espejo_$sp', () => mkEspejoCoqui(sparkle: sp));
      out.add(
        BanoItem(
          ef,
          m[0] + (m[2] - ef.w) ~/ 2,
          m[1] + (m[3] - ef.h) ~/ 2,
          m[1] + m[3],
          3.0,
          tag: 'fx:espejo_coqui',
          overlay: true,
        ),
      );
    }

    // 7. Celebration cues
    if (_n(w['corazonFx']) == 1) {
      final q = w['cq'] as Map<String, dynamic>?;
      final fp = q != null ? _frogPoint(q) : _p.at('repisa_coqui');
      final cor = _spr('bn_corazon', mkCorazonBano);
      out.add(
        BanoItem(
          cor,
          (_round(fp.sx) + 12).clamp(22, 206),
          (_round(fp.sy) - 24).clamp(4, 200),
          fp.sy,
          6.0,
          tag: 'fx:corazon',
          overlay: true,
        ),
      );
    }
    if (_n(w['estrellaFx']) == 1) {
      final q = w['cq'] as Map<String, dynamic>?;
      final fp = q != null ? _frogPoint(q) : _p.at('repisa_coqui');
      final st = _spr('bn_estrella', mkEstrellaBano);
      out.add(
        BanoItem(
          st,
          (_round(fp.sx) - 18).clamp(22, 208),
          (_round(fp.sy) - 24).clamp(4, 200),
          fp.sy,
          6.0,
          tag: 'fx:estrella',
          overlay: true,
        ),
      );
    }

    return out;
  }

  static final Map<String, Sprite> _frogSprites = {};

  /// [items] plus the frog (as the host draws him) and frog sink foam, for `draw` and for `BanoRules`.
  List<BanoItem> placed(Map<String, dynamic> w, int a) {
    final out = items(w, a);
    final q = w['cq'] as Map<String, dynamic>?;
    if (q != null && jsTruthy(q['vis'])) {
      final b = host.frogBox(q);
      final at = _frogPoint(q);
      final dx = _n(q['dx']);
      final fsy = _round(at.sy);
      final fsx = _round(at.sx) + dx;
      final ox = b.x.toInt() - 16 + dx;
      final oy = b.y.toInt() - 24;
      final muddy = _n(w['coquiMuddy']) == 1;
      final foam = _n(w['coquiFoam']).clamp(0, 3);
      final blink = host.F % 47 < 2 ? 1 : 0;
      final mouth = ((q['bub'] == 'hola' || _talker() == 'coqui') && a % 2 != 0)
          ? 1
          : 0;
      final fk =
          '${q['s']}_${b.x - (b.x.toInt() - 16)}_${b.y - oy}_${(q['y'] as num) - oy}_${((q['dy'] as num) + 0.5).floor()}_${blink}_${mouth}_${muddy}_$foam';
      final spr = _frogSprites.putIfAbsent(fk, () {
        if (!muddy && foam == 0) {
          final px = Uint32List(64 * 64);
          final g = Ctx(px, 64, 64)
            ..translate(-(b.x.toInt() - 16).toDouble(), -oy.toDouble());
          host.frog(g, q, a);
          return Sprite(64, 64, px);
        }
        final custom = mkBanoCoqui(
          mouth,
          f: blink,
          muddyFeet: muddy,
          foam: foam,
        );
        final px = Uint32List(64 * 64);
        final g = Ctx(px, 64, 64);
        final cx = ((q['x'] as num) - ox).round();
        final cy = ((q['y'] as num) + (q['dy'] as num? ?? 0) - oy).round();
        g.drawImage(custom, cx, cy);
        return Sprite(64, 64, px);
      });
      out.add(BanoItem(spr, ox, oy, fsy, at.d, tag: 'coqui'));

      if (foam > 0) {
        final fm = _spr('bn_espuma_$foam', () => mkEspumaSink(foam));
        out.add(
          BanoItem(fm, fsx - 12, fsy - 10, fsy, at.d + .02, tag: 'fx:espuma'),
        );
      }
    }
    return out;
  }

  /* ---------- SetOverSprites & draw ---------- */

  Float32List? _setZ;
  bool _framed = false;
  Uint32List? _layer;
  Float32List? _layerZ;

  @override
  void setFramed(PpEngine engine, BakedSet baked, Map<String, dynamic> W) {
    _framed = true;
    _setZ = baked.zb;
  }

  static final double _t30 = math.tan(math.pi / 6);

  void _put(
    BanoItem it,
    int w0,
    int h0,
    Float32List? setZ,
    double bias,
    double S,
  ) {
    final layer = _layer!, lz = _layerZ!, sp = it.s;
    final sw = sp.w, sh = sp.h;
    final spx = sp.px;
    for (var py = 0; py < sh; py++) {
      final Y = it.top + py;
      if (Y < 0 || Y >= h0) continue;
      final plane = it.overlay ? it.d : it.d + (it.sy - (Y + .5)) * _t30 / S;
      final row = Y * w0;
      final srow = py * sw;
      for (var px = 0; px < sw; px++) {
        final c = spx[srow + px];
        if (c >>> 24 == 0) continue;
        final X = it.left + px;
        if (X < 0 || X >= w0) continue;
        final i = row + X;
        if (!it.overlay && setZ != null && setZ[i] > plane + bias) continue;
        if (lz[i] > plane + .001) continue;
        lz[i] = plane;
        layer[i] = c;
      }
    }
  }

  @override
  void draw(Ctx c, Map<String, dynamic> w, int a) {
    if (!_framed) return;
    const w0 = 240, h0 = 216;
    final layer = _layer ??= Uint32List(w0 * h0);
    final lz = _layerZ ??= Float32List(w0 * h0);
    final setZ = _setZ, bias = _p.bias, S = _p.e.S;
    final all = placed(w, a);
    var x0 = w0, y0 = h0, x1 = 0, y1 = 0;
    for (final it in all) {
      x0 = math.min(x0, math.max(0, it.left));
      y0 = math.min(y0, math.max(0, it.top));
      x1 = math.max(x1, math.min(w0, it.left + it.s.w));
      y1 = math.max(y1, math.min(h0, it.top + it.s.h));
    }
    if (x1 > x0 && y1 > y0) {
      for (var y = y0; y < y1; y++) {
        layer.fillRange(y * w0 + x0, y * w0 + x1, 0);
        lz.fillRange(y * w0 + x0, y * w0 + x1, -1e9);
      }
      for (final it in all) {
        _put(it, w0, h0, setZ, bias, S);
      }
      c.drawImageRect(
        Sprite(w0, h0, layer),
        x0,
        y0,
        x1 - x0,
        y1 - y0,
        x0,
        y0,
        x1 - x0,
        y1 - y0,
      );
    }
  }

  /* ---------- the corner card: the two rounds ---------- */

  @override
  void hud(Ctx c, Map<String, dynamic> W, int a) {
    if (!_framed || !jsTruthy(W['tarjeta'])) return;
    final marcas = W['marcas'] is List ? W['marcas'] as List : const [];
    const x0 = 3;
    tarjeta(c, x0, 3, 6 + 20 * marcas.length, 24);
    for (var i = 0; i < marcas.length; i++) {
      final m = marcas[i], x = x0 + 7 + i * 20, y = 6;
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
        for (var j = 0; j < st.length; j++) {
          for (var k = 0; k < st[j].length; k++) {
            if (st[j][k] == '#') fr(c, x + k - 1, y + j + 1, 3, 3, OUT);
          }
        }
        for (var j = 0; j < st.length; j++) {
          for (var k = 0; k < st[j].length; k++) {
            if (st[j][k] == '#') fr(c, x + k, y + j + 2, 1, 1, 0xFF20C0F0);
          }
        }
      } else if (m != null) {
        for (var k = 0; k < 11; k++) {
          fr(c, x + k, y + 1 + k, 4, 3, OUT);
          fr(c, x + 10 - k, y + 1 + k, 4, 3, OUT);
        }
        for (var k = 0; k < 11; k++) {
          fr(c, x + 1 + k, y + 2 + k, 2, 1, 0xFF1E40C8);
          fr(c, x + 11 - k, y + 2 + k, 2, 1, 0xFF1E40C8);
        }
      } else {
        fr(c, x + 1, y + 13, 12, 1, 0xFFD4C8C8);
        fr(c, x + 1, y + 1, 1, 12, 0xFFD4C8C8);
        fr(c, x + 12, y + 1, 1, 12, 0xFFD4C8C8);
        fr(c, x + 1, y + 1, 12, 1, 0xFFD4C8C8);
      }
    }
  }

  /* ---------- the shadows (sheet: shadows) ---------- */

  @override
  List<ShadowCast> shadows(Map<String, dynamic> W) {
    final out = <ShadowCast>[];
    final gente = (W['gente'] as Map<String, dynamic>?) ?? const {};
    for (final en in gente.entries) {
      final p = en.value as Map<String, dynamic>;
      if (p['vis'] == 0) continue;
      final spot = p['spot'] as String?;
      final z = (p['z'] as num?)?.toDouble() ?? 0.0;
      if (z != 0 || (spot != null && _p.noShadow(spot))) continue;
      final r = _p.radius(en.key);
      if (r == null) continue;
      out.add((
        x: (p['x'] as num).toDouble(),
        y: (p['y'] as num).toDouble(),
        z: 0.0,
        r: r,
      ));
    }
    if (_n(W['perroVis']) == 1) {
      final spot = (W['perroSpot'] as String?) ?? 'piso_perro';
      if (!_p.noShadow(spot)) {
        final at = _p.at(spot);
        final r = _p.radius('perro');
        if (r != null) out.add((x: at.x, y: at.y, z: 0.0, r: r));
      }
    }
    final q = W['cq'] as Map<String, dynamic>?;
    if (q != null && jsTruthy(q['vis'])) {
      final spot = q['spot'] as String?;
      final z = (q['z'] as num?)?.toDouble() ?? 0.0;
      if (z == 0 && (spot == null || !_p.noShadow(spot))) {
        final fp = _frogPoint(q);
        final r = _p.radius('coqui');
        if (r != null) out.add((x: fp.x, y: fp.y, z: 0.0, r: r));
      }
    }
    return out;
  }

  /* ---------- talk bubbles ---------- */

  @override
  List<num>? talkAt(String who, Map<String, dynamic> W) {
    if (who == 'coqui') {
      final q = W['cq'] as Map<String, dynamic>?;
      if (q == null) return null;
      final b = host.frogBox(q);
      return [b.x + b.w / 2, b.y - 4];
    }
    final gente = (W['gente'] as Map<String, dynamic>?) ?? const {};
    final p = gente[who] as Map<String, dynamic>?;
    if (p == null) return null;
    if (p['vis'] == 0) {
      // Abuelo waiting outside the door in story 100 (`fuera`) still has a door-side anchor
      final at = _p.at('puerta1');
      return [_round(at.sx), _round(at.sy) - 52];
    }
    final at = _atOf(p);
    return [_round(at.sx), _round(at.sy) - 52];
  }

  /* ---------- touch things & hit testing ---------- */

  static List<int>? _itemBox(
    List<BanoItem> list,
    bool Function(BanoItem) test,
  ) {
    var x0 = 240, y0 = 216, x1 = -1, y1 = -1;
    for (final it in list) {
      if (!test(it)) continue;
      final sp = it.s;
      for (var py = 0; py < sp.h; py++) {
        for (var px = 0; px < sp.w; px++) {
          if (sp.px[py * sp.w + px] >>> 24 == 0) continue;
          final X = it.left + px, Y = it.top + py;
          if (X < 0 || X >= 240 || Y < 0 || Y >= 216) continue;
          if (X < x0) x0 = X;
          if (X > x1) x1 = X;
          if (Y < y0) y0 = Y;
          if (Y > y1) y1 = Y;
        }
      }
    }
    if (x1 < 0) return null;
    return [x0, y0, x1 - x0 + 1, y1 - y0 + 1];
  }

  List<num>? _spriteBox(Map<String, dynamic> w, String tag) =>
      _itemBox(items(w, 0), (it) => it.tag == tag);

  List<Thing> _things() => [
    // 1. Specific small things & hand target (`manos_luis`) take priority over people/set boxes
    Thing(
      id: 'manos_luis',
      m: 2,
      si: (w) =>
          _personAt(w, 'luis', 'lavamanos1') &&
          ((w['gente'] as Map)['luis'] as Map)['pose'] == 'yo',
      box: (w) => _p.box('manos_luis'),
    ),
    Thing(
      id: 'jabon',
      si: (w) => _n(w['jabonVis']) == 1,
      box: (w) => _spriteBox(w, 'cosa:jabon') ?? _p.spotBox('jabon'),
    ),
    for (final id in const ['toalla_a', 'toalla_b'])
      Thing(
        id: id,
        si: (w) => _n(w['toallasVis']) == 1,
        box: (w) => _spriteBox(w, 'cosa:$id') ?? _p.spotBox(id),
      ),
    for (final id in const ['cosa_a', 'cosa_b'])
      Thing(
        id: id,
        si: (w) => _n(w['cosasVis']) == 1,
        box: (w) => _spriteBox(w, 'cosa:$id') ?? _p.spotBox(id),
      ),
    Thing(
      id: 'tubo',
      m: 0,
      si: (w) => _n(w['tuboVis']) == 1,
      box: (w) => _spriteBox(w, 'cosa:tubo') ?? _p.spotBox('tubo'),
    ),
    Thing(
      id: 'cepillito',
      m: 1,
      si: (w) => _n(w['cepillitoVis']) == 1 && !_anyoneAt(w, 'banquito'),
      box: (w) => _spriteBox(w, 'cosa:cepillito') ?? _p.spotBox('cepillito'),
    ),
    // 2. Coquí
    Thing(
      id: 'coqui',
      si: (w) => jsTruthy((w['cq'] as Map?)?['vis']),
      box: (Map<String, dynamic> w) {
        final b = host.frogBox(w['cq'] as Map<String, dynamic>);
        return [b.x, b.y, b.w, b.h];
      },
    ),
    // 3. People & Canelo (in front of wall/set boxes)
    Thing(
      id: 'perro',
      si: (w) => _n(w['perroVis']) == 1,
      box: (w) => _spriteBox(w, 'persona:perro'),
    ),
    for (final who in BANO_PERSONAS)
      Thing(
        id: who,
        si: (w) => ((w['gente'] as Map?)?[who] as Map?)?['vis'] != 0,
        box: (w) => _spriteBox(w, 'persona:$who'),
      ),
    // 4. Set things (taps, mirror, heater gauge, basket, shower)
    for (final id in const [
      'llave_ducha',
      'llave_lavamanos',
      'espejo',
      'calentador',
      'canasta',
      'ducha',
    ])
      Thing(id: id, box: (w) => _p.box(id)),
  ];

  @override
  String setKey(Map<String, dynamic> W) =>
      BanoState(hora: (W['hora'] as String?) ?? 'dia').key;

  @override
  void buildSet(PpEngine e, PpBuild b, Map<String, dynamic> W) =>
      buildSetFor(e, b, setKey(W));

  final Map<PpEngine, BanoSet> _sets = {};

  @override
  void buildSetFor(PpEngine e, PpBuild b, String key) =>
      (_sets[e] ??= BanoSet(e, b)).buildSet(BanoState.fromKey(key));

  @override
  bool get frogShadow => false;

  @override
  List<num> remap(List<num> xy) => xy;

  @override
  Future<void> stake(int lost, int max, String en) async {}

  final List<Future<void>> _loose = [];

  @override
  Map<String, Act> get ownActs => _buildOwnActs();
}
