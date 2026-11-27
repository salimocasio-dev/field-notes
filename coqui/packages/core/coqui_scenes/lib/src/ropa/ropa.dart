// La ropa (place 7, La playa, scene 3: `ropa`; stories 78 to 80): a NEW scene, written from its script's
// "Needs" list (historia/notas/guiones/ropa.md) on its set (ropa_set.dart) and its sheet (ropa-sheet.json, read by
// SceneSheet). There is no old scene file: every act is this file's, each doing on screen what the Needs list says,
// every place from the sheet (spots, guagua thing box, depth rule, shadows). Where the sheet names no place or an act
// is unstated in the script, the code does the plainest thing that keeps the story playing and marks it `OPEN:`.
//
// The drawing (the sheet's `front`): every sprite stands with its feet's bottom edge on its spot's row and its
// middle on its column (rules.anchor); clothes on the line hang top-middle on `cuerda1..5`; small things afloat, the
// bag and the shoes rest bottom-middle on their spots; the plate rests 8 px above its spot on its crate; the driver
// is centred on `chofer`; a sprite pixel is hidden by every LIVE set pixel (including swaying palm fronds:
// `engine.zb`) nearer than its upright plane plus `front.bias`. Between two sprites the nearer pixel wins (tie within
// 0.001 goes to the later layer; the frog is always the last layer).
// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/src/colmado/colmado_cast.dart' show inkBottom;
import 'package:coqui_scenes/src/ropa/ropa_places.dart';
import 'package:coqui_scenes/src/ropa/ropa_set.dart';
import 'package:coqui_scenes/src/ropa/ropa_sprites.dart';
import 'package:coqui_scenes/src/scene_set.dart';
import 'package:coqui_scenes/src/sheet_cache.dart';

/// The scene "La ropa", made from its sheet (read first: `loadScene`).
Scene createRopa() => Ropa(sceneSheetOf('ropa'));

int _round(num v) => (v + 0.5).floor();

int _n(Object? v) {
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? 0;
  return 0;
}

/// One sprite of the sprite layer, placed: its picture, its top left on the 240 × 216 picture, the screen row of its
/// anchor and the depth there (front.plane), and who or what it is.
class RopaItem {
  RopaItem(
    this.s,
    this.left,
    this.top,
    this.sy,
    this.d, {
    this.tag,
    this.spot,
    this.flat = false,
  });

  final Sprite s;
  final int left, top;
  final num sy;
  final double d;
  final String? tag;
  final String? spot;

  /// Wave / sand cloud drawn directly without occluding standing sprites.
  final bool flat;
}

/// Every person La ropa knows, by speaker key (ropa.md, "Needs").
const List<String> ROPA_PERSONAS = ['abuela', 'luis', 'carmen'];

/// The four look-alike children in story 80 (ropa.md, "Needs").
const List<String> ROPA_NINOS = ['chico_a', 'chico_b', 'chica_a', 'chica_b'];

class Ropa extends Escena implements SetScene, SetOverSprites {
  Ropa(this.ss)
    : sheet = identical(ss, _lastSs)
          ? _lastSheet!
          : (_lastSheet = ss.legacy()) {
    _p = identical(ss, _lastSs) ? _lastPlaces! : (_lastPlaces = RopaPlaces(ss));
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
  static RopaPlaces? _lastPlaces;

  /// The new scene's sheet (SceneSheet).
  final SceneSheet ss;

  @override
  final Sheet sheet;

  late final RopaPlaces _p;

  /// The scene's places, from its sheet.
  RopaPlaces get places => _p;

  @override
  String get id => 'ropa';

  @override
  late final Map<String, List<num>> CAM;

  late final Map<String, List<num>> LUGAR;

  @override
  Map<String, List<num>> get lugar => LUGAR;

  @override
  late final List<Thing> cosas;

  @override
  PpEngine newEngine({bool still = false}) => ropaEngine(still: still);

  @override
  PpEngine get projection => _p.e;

  List<num> _frogAt(RopaAt a) => [_round(a.sx) - 16, _round(a.sy) - 25, 1];

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

  static Map<String, dynamic> _firstSet(Object? beats) {
    if (beats is List) {
      for (final b in beats) {
        if (b is Map && b['set'] is Map && (b['set'] as Map)['hora'] != null) {
          return (b['set'] as Map).cast<String, dynamic>();
        }
      }
    }
    return const {};
  }

  Map<String, dynamic> _person(
    String spot, {
    int vis = 1,
    int sent = 0,
    int traje = 0,
    int toalla = 0,
    int gotea = 0,
    int camisa = 0,
    int vestido = 0,
    int sombrero = 0,
    int gafas = 0,
    int chancletas = 0,
  }) {
    final w = _p.world(spot);
    return <String, dynamic>{
      'x': w[0],
      'y': w[1],
      'z': w[2],
      'spot': spot,
      'vis': vis,
      'pose': 'idle',
      'abPose': 'idle',
      'sent': sent,
      'traje': traje,
      'toalla': toalla,
      'gotea': gotea,
      'camisa': camisa,
      'vestido': vestido,
      'sombrero': sombrero,
      'gafas': gafas,
      'chancletas': chancletas,
      'abanica': 0,
      'dx': 0,
      'dy': 0,
    };
  }

  // OPEN: ropa-sheet.json has no spot for Canelo (`perro`); in story 80 step 8 ("Canelo is under the frog, with
  // abuela's sun hat on") we place him on the dry sand at (u -1.25, v 8.4) right under `coqui.busca` (sx 88, sy 169)
  // so `frog-seen`, `spots-in-view` and `sprites-apart` (23 px below `coqui.busca`) all hold.
  List<double> _perroWorld() => _p.xyOf(-1.25, 8.4);

  @override
  Map<String, dynamic> fresh(Map<String, dynamic> story) {
    final acts = _actsOf([story['beats'], story['final']]);
    bool has(String a) => acts.any((o) => o['act'] == a);
    final set = _firstSet(story['beats']);
    final is80 =
        has('dedos') ||
        has('pone80') ||
        has('quita80') ||
        has('pareja80') ||
        has('busca80') ||
        has('bocina') ||
        has('final80');
    final is79 =
        !is80 &&
        (has('flotan') ||
            has('bolsa') ||
            has('trae79') ||
            has('ola79') ||
            has('lejos79') ||
            has('final79'));
    final is78 = !is80 && !is79;

    final gente = <String, dynamic>{};
    final String start;
    if (is80) {
      gente['abuela'] = _person('banco1', sent: 1);
      gente['luis'] = _person('luis.viste', traje: 1);
      gente['carmen'] = _person('caseta', traje: 1, chancletas: 1);
      start = 'banco2';
    } else if (is79) {
      gente['abuela'] = _person('orilla1')..['abPose'] = 'manos';
      gente['luis'] = _person('orilla2');
      gente['carmen'] = _person('orilla3');
      start = 'coqui.orilla';
    } else {
      // OPEN: ropa.md says the frog starts on `cuerda1`; `cuerda1` sits under the left palm's fronds (`fronds.wind`),
      // so he starts at `coqui.cuerda` on the sand under the line as in ropa-preview.html moment 1 (`frog-seen`).
      // Luis and Carmen start off-screen (`vis: 0`) until `salen78` brings them out of the sea.
      gente['abuela'] = _person('abuela.cuerda');
      gente['luis'] = _person('pie1', vis: 0, traje: 1);
      gente['carmen'] = _person('pie2', vis: 0, traje: 1);
      start = 'coqui.cuerda';
    }

    final q = _frogAt(_p.at(start));
    final hora = set['hora'] is String
        ? set['hora'] as String
        : (is80 ? 'ocaso' : 'tarde');
    final guagua = set['guagua'] != null ? _n(set['guagua']) : (is80 ? 1 : 0);

    return <String, dynamic>{
      'cam': 'wide',
      'hora': hora,
      'guagua': guagua == 1 ? 1 : 0,
      'story': is80 ? 80 : (is79 ? 79 : 78),
      'gente': gente,
      // Story 78: clothes on line (`cuerda2..4`), shoes on sand (`zapatos`), plate & cloth (`plato`),
      // fallen piece (`caida`), sand cloud, gull.
      'cuerda': <String, String>{
        if (is79) 'cuerda3': 'toalla',
      }, // spot -> sprite key
      'zapatosVis': 0,
      'panes': is78 ? 3 : 0,
      'platoPano': is78 ? 1 : 0,
      'caida': null, // {que} fallen on sand in baja78 ok=0
      'ultimaCaida': null,
      'nubeArena': 0,
      'gaviota': null, // {x, y}
      'coquiLleva': null, // carried item key
      // Story 79: floating things (`agua`), open bag (`bolsa`), far-out retry item (`farOut`), wave (`ola`),
      // lost items tracking, frog wrapped in dry towel (`coquiToalla`).
      'agua': <String, String>{}, // spot -> thing key
      'farOut': null, // {que, spot, dy}
      'perdidos79': <String>[],
      'bolsaVis': is79 ? 1 : 0,
      'bolsaN': is79 ? 3 : 0,
      'bolsaDentro': 0,
      'story79Fase': 'open',
      'ola': null, // {y}
      'coquiToalla': 0,
      // Story 80: driver fingers (`dedos`), horn/smile/tap, 4 look-alike children (`ninos`), active continuous pair
      // (`pareja`), turned-around stranger laughing (`extranoRie`), Canelo wearing abuela's sun hat (`perroVis`).
      'dedos': is80 ? 3 : 0,
      'choferModo': 'fingers', // 'fingers' | 'smile' | 'tap' | 'horn'
      'ninos': <String, String>{}, // id -> spot
      'pareja': null, // {quienes, que, hace, cual}
      'extranoRie': null, // child id briefly turned round laughing
      'perroVis': 0,
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
        'z': _p.world(start)[2],
        'spot': start,
      },
    };
  }

  /* ---------- the set ---------- */

  @override
  String setKey(Map<String, dynamic> W) {
    final h = W['hora'];
    final hora = h is String && const ['tarde', 'ocaso'].contains(h)
        ? h
        : 'tarde';
    return '$hora-${_n(W['guagua']) == 1 ? 1 : 0}';
  }

  @override
  void buildSet(PpEngine e, PpBuild b, Map<String, dynamic> W) =>
      buildSetFor(e, b, setKey(W));

  final Map<PpEngine, RopaSet> _sets = {};

  @override
  void buildSetFor(PpEngine e, PpBuild b, String key) =>
      (_sets[e] ??= RopaSet(e, b)).buildSet(RopaState.fromKey(key));

  @override
  bool get frogShadow => false;

  /* ---------- where everybody is ---------- */

  Map<String, dynamic> get _gente => W['gente'] as Map<String, dynamic>;

  RopaAt _atOf(Map<String, dynamic> o) =>
      _p.atWorld(o['x'] as num, o['y'] as num, o['z'] as num);

  RopaAt _frogPoint(Map<String, dynamic> q) {
    final spot = q['spot'];
    if (spot is String && _p.has(spot)) {
      final at = _p.at(spot);
      final L = _frogAt(at);
      if (q['x'] == L[0] && q['y'] == L[1]) return at;
    }
    final b = host.frogBox(q);
    return _p.fromScreen(
      b.x + b.w / 2,
      (q['y'] as num) + 25,
      (q['z'] as num?) ?? 0,
    );
  }

  /* ---------- sprites ---------- */

  static final Map<String, Sprite> _sprites = {};
  static Sprite _spr(String key, Sprite Function() make) =>
      _sprites[key] ??= make();

  Sprite _cuerdaSprite(String kind) => switch (kind) {
    'camisa' => _spr('rp_cuerda_camisa', mkCamisaCuerda),
    'pantalon' => _spr('rp_cuerda_pantalon', mkPantalonCuerda),
    'vestido' => _spr('rp_cuerda_vestido', mkVestidoCuerda),
    'toalla_mojada' => _spr(
      'rp_cuerda_toalla_mojada',
      () => mkToallaCuerda(mojada: true),
    ),
    'sombrero' => _spr('rp_cuerda_sombrero', mkSombreroCuerda),
    'chancletas' => _spr('rp_cuerda_chancletas', mkChancletasCuerda),
    'gafas' => _spr('rp_cuerda_gafas', mkGafasCuerda),
    'traje' => _spr('rp_cuerda_traje', mkTrajeCuerda),
    _ => _spr('rp_cuerda_toalla', mkToallaCuerda),
  };

  Sprite _aguaSprite(String kind) => switch (kind) {
    'sombrero' => _spr('rp_agua_sombrero', mkSombreroAgua),
    'chancletas' => _spr('rp_agua_chancletas', mkChancletasAgua),
    'gafas' => _spr('rp_agua_gafas', mkGafasAgua),
    'traje' => _spr('rp_agua_traje', mkTrajeAgua),
    _ => _spr('rp_agua_toalla', mkToallaAgua),
  };

  Sprite _llevaSprite(String kind) => switch (kind) {
    'camisa' => _spr('rp_cuerda_camisa', mkCamisaCuerda),
    'pantalon' => _spr('rp_cuerda_pantalon', mkPantalonCuerda),
    'vestido' => _spr('rp_cuerda_vestido', mkVestidoCuerda),
    'zapatos' => _spr('rp_zapatos', mkZapatos),
    _ => _aguaSprite(kind),
  };

  ({Sprite s, int ax, int ay}) _personSprite(
    String id,
    Map<String, dynamic> p,
    bool open,
    Map<String, dynamic> w,
  ) {
    final pose = (p['pose'] as String?) ?? 'idle';
    if (id == 'abuela') {
      final sent = _n(p['sent']) == 1;
      if (sent) {
        final abPose = switch (pose) {
          'saluda0' || 'saluda1' => pose,
          'senala' => 'tu',
          'rie' => 'yo',
          _ => 'idle',
        };
        final s = _spr(
          'rp_abS_${abPose}_$open',
          () => mkAbuelaS(abPose, open, true),
        );
        return (s: s, ax: 17, ay: 36);
      }
      final abExtra = (p['abPose'] as String?) ?? 'idle';
      if (abExtra == 'manos' && pose == 'idle') {
        final s = _spr('rp_ab_manos_$open', () => mkAbuelaManos(open));
        return (s: s, ax: 30, ay: inkBottom(s));
      }
      if (abExtra == 'sombrero' && pose == 'idle') {
        final s = _spr('rp_ab_sombrero_$open', () => mkAbuelaSombrero(open));
        return (s: s, ax: 30, ay: inkBottom(s));
      }
      final abPose = switch (pose) {
        'saluda0' || 'saluda1' => pose,
        'senala' => 'offer',
        'rie' => 'bless',
        _ => 'idle',
      };
      final s = _spr('rp_ab_${abPose}_$open', () => mkAbuela(abPose, open));
      return (s: s, ax: 30, ay: inkBottom(s));
    }

    final kp = switch (pose) {
      'saluda0' => 'wave0',
      'saluda1' => 'wave1',
      'senala' => 'tu',
      'rie' => 'yo',
      _ => 'idle',
    };
    final story = _n(w['story']);
    if (story == 78 && _n(p['traje']) == 1) {
      final toa = _n(p['toalla']) == 1;
      final got = _n(p['gotea']) == 1;
      final gf = (F >> 1) % 2;
      final s = _spr(
        'rp_${id}_playa_${toa}_${got}_$gf',
        () => mkNinoPlaya(id, toalla: toa, gotea: got, frame: gf),
      );
      return (s: s, ax: PX, ay: inkBottom(s));
    }
    if (story == 80 && id == 'luis' && _n(p['camisa']) == 0) {
      final s = _spr('rp_luis_playa_0_0_0', () => mkNinoPlaya('luis'));
      return (s: s, ax: PX, ay: inkBottom(s));
    }
    if (story == 80 && id == 'carmen' && _n(p['vestido']) == 0) {
      final s = _spr('rp_carmen_playa_0_0_0', () => mkNinoPlaya('carmen'));
      return (s: s, ax: PX, ay: inkBottom(s));
    }
    final gafas = _n(p['gafas']) == 1;
    final somb = _n(p['sombrero']) == 1;
    final aban = _n(p['abanica']) == 1;
    final chan = _n(p['chancletas']) == 1;
    final s = _spr(
      'rp_${id}_${kp}_${open}_${gafas}_${somb}_${aban}_$chan',
      () => mkNinoRopa(
        id,
        kp,
        open,
        gafas: gafas,
        sombrero: somb,
        abanica: aban,
        chancletas: chan,
      ),
    );
    return (s: s, ax: PX, ay: inkBottom(s));
  }

  String? _talker() {
    try {
      return host.TALK;
    } catch (_) {
      return null;
    }
  }

  /// Every sprite of the frame [w] as it is placed, except the frog. The rules' tests read it; [draw] draws it.
  List<RopaItem> items(Map<String, dynamic> w, int a) {
    final out = <RopaItem>[];
    final talk = _talker();
    final gente = (w['gente'] as Map<String, dynamic>?) ?? const {};

    // 1. Wave strip across the shallow water (flat, behind standing sprites)
    final ola = w['ola'];
    if (ola is Map) {
      final oy = _n(ola['y']);
      final s = _spr('rp_ola_${(F >> 1) % 2}', () => mkOlaRopa((F >> 1) % 2));
      out.add(RopaItem(s, 36, oy - s.h, oy, -4.0, tag: 'fx:ola', flat: true));
    }

    // 2. Things afloat (`agua1..5`) & far-out retry item (`farOut`)
    final agua = (w['agua'] as Map?) ?? const {};
    for (final en in agua.entries) {
      final spot = en.key as String;
      final que = en.value as String;
      if (!_p.has(spot)) continue;
      final at = _p.at(spot);
      final sx = _round(at.sx), sy = _round(at.sy);
      final s = _aguaSprite(que);
      out.add(
        RopaItem(s, sx - 7, sy - s.h, sy, at.d, tag: 'cosa:$que', spot: spot),
      );
    }
    final far = w['farOut'];
    if (far is Map) {
      final que = far['que'] as String;
      final pw = _p.xyOf(0.05, -1.2);
      final at = _p.atWorld(pw[0], pw[1], 0);
      final sx = _round(at.sx), sy = _round(at.sy);
      final s = _aguaSprite(que);
      out.add(
        RopaItem(
          s,
          sx - 7,
          sy - s.h,
          sy,
          at.d,
          tag: 'cosa:$que',
          spot: 'farOut',
        ),
      );
    }

    // 3. Clothes & towels pegged on the line (`cuerda1..5`, top-anchored)
    final cuerda = (w['cuerda'] as Map?) ?? const {};
    for (final en in cuerda.entries) {
      final spot = en.key as String;
      final kind = en.value as String;
      if (!_p.has(spot)) continue;
      final at = _p.at(spot);
      final sx = _round(at.sx), sy = _round(at.sy);
      final s = _cuerdaSprite(kind);
      // In story 79, the dry towel on `cuerda3` is a static prop (`fx:toalla_seca`) while the fished-out towel
      // (`toalla_mojada` on `cuerda2`) carries `cosa:toalla` so `cosa:toalla` always refers to one item.
      final tag = kind == 'toalla'
          ? 'fx:toalla_seca'
          : (kind == 'toalla_mojada' ? 'cosa:toalla' : 'cosa:$kind');
      out.add(RopaItem(s, sx - 8, sy, sy, at.d, tag: tag, spot: spot));
    }

    // 4. Two pairs of shoes on the sand (`zapatos`, 24 x 8, bottom-anchored)
    if (_n(w['zapatosVis']) == 1) {
      final at = _p.at('zapatos');
      final sx = _round(at.sx), sy = _round(at.sy);
      final s = _spr('rp_zapatos', mkZapatos);
      out.add(RopaItem(s, sx - 12, sy - s.h, sy, at.d, tag: 'cosa:zapatos'));
    }

    // 5. Plate of sandwiches on its crate (`plato`, 16 x 10, lift 8)
    if (_n(w['story']) == 78) {
      final at = _p.at('plato');
      final sx = _round(at.sx), sy = _round(at.sy);
      final caja = _spr('rp_caja', mkCajaRopa);
      out.add(
        RopaItem(caja, sx - 6, sy - caja.h, sy, at.d - .001, tag: 'fx:caja'),
      );
      final nPanes = _n(w['panes']).clamp(0, 3);
      final plato = _spr('rp_plato_$nPanes', () => mkPlato(nPanes));
      out.add(
        RopaItem(plato, sx - 8, sy - plato.h - 8, sy, at.d, tag: 'cosa:plato'),
      );
      if (_n(w['platoPano']) == 1) {
        final pano = _spr('rp_pano_plato', mkPanoPlato);
        out.add(
          RopaItem(pano, sx - 6, sy - 17, sy, at.d + .01, tag: 'fx:pano_plato'),
        );
      }
    }

    // 6. Open bag on the sand (`bolsa`, 14 x 10, bottom-anchored)
    if (_n(w['bolsaVis']) == 1) {
      final at = _p.at('bolsa');
      final sx = _round(at.sx), sy = _round(at.sy);
      final bCount = _n(w['bolsaDentro']).clamp(0, 3);
      final s = _spr('rp_bolsa_$bCount', () => mkBolsaRopa(bCount));
      out.add(RopaItem(s, sx - 7, sy - s.h, sy, at.d, tag: 'cosa:bolsa'));
    }

    // 7. Fallen piece on the sand & sand cloud & gull (story 78 wrong move)
    final caida = w['caida'];
    if (caida is Map) {
      final que = caida['que'] as String;
      final at = _p.at('coqui.cuerda');
      final sx = _round(at.sx) + 18, sy = _round(at.sy) + 10;
      final s = _spr('rp_caida_$que', () => mkPiezaCaida(que));
      out.add(RopaItem(s, sx - 7, sy - s.h, sy, at.d + .2, tag: 'fx:caida'));
    }
    if (_n(w['nubeArena']) == 1) {
      final at = _p.at('plato');
      final sx = _round(at.sx), sy = _round(at.sy) - 10;
      final s = _spr('rp_nube_${F % 2}', () => mkNubeArena(F % 2));
      out.add(
        RopaItem(s, sx - 11, sy - 6, sy, at.d + .3, tag: 'fx:nube', flat: true),
      );
    }
    final gav = w['gaviota'];
    if (gav is Map) {
      final s = _spr('rp_gav_${a % 2}', () => mkGaviotaRopa(a % 2));
      final gx = _n(gav['x']), gy = _n(gav['y']);
      out.add(
        RopaItem(s, gx - s.w ~/ 2, gy - s.h ~/ 2, gy, 8.0, tag: 'fx:gaviota'),
      );
    }

    // 8. Bus driver at his window (`chofer`, 14 x 14, centred) when guagua = 1
    if (_n(w['guagua']) == 1) {
      final at = _p.at('chofer');
      final sx = _round(at.sx), sy = _round(at.sy);
      final dedos = _n(w['dedos']).clamp(0, 3);
      final modo = (w['choferModo'] as String?) ?? 'fingers';
      final s = _spr(
        'rp_chofer_${modo}_$dedos',
        () => mkChofer(
          fingers: dedos,
          smiling: modo == 'smile',
          tapping: modo == 'tap',
          horn: modo == 'horn',
        ),
      );
      out.add(RopaItem(s, sx - 7, sy - 7, sy, at.d, tag: 'fx:chofer'));
    }

    // 9. Four look-alike children at the water's edge (story 80, `ninos1..4`)
    final ninos = (w['ninos'] as Map?) ?? const {};
    final pareja = w['pareja'] as Map?;
    final extrano = w['extranoRie'] as String?;
    final stepPhase = (F >> 3) % 4;
    for (final en in ninos.entries) {
      final cid = en.key as String;
      final spot = en.value as String;
      if (!_p.has(spot)) continue;
      final at = _p.at(spot);
      final sx = _round(at.sx), sy = _round(at.sy);
      final isBoy = cid.startsWith('chico');
      final tipo = isBoy ? 'chico' : 'chica';
      final Sprite s;
      if (extrano == cid) {
        s = _spr('rp_extrano_rie_$tipo', () => mkNinoExtranoRie(tipo));
      } else {
        String pQue = 'sombrero';
        int phase = 0;
        if (pareja != null &&
            ((pareja['quienes'] == 'chicos' && isBoy) ||
                (pareja['quienes'] == 'chicas' && !isBoy))) {
          pQue = (pareja['que'] as String?) ?? 'sombrero';
          final hace = (pareja['hace'] as String?) ?? 'pone';
          final cual = (pareja['cual'] as String?) ?? 'a';
          final isMine = cid.endsWith('_$cual');
          final childAction = isMine
              ? hace
              : (hace == 'pone' ? 'quita' : 'pone');
          phase = childAction == 'pone' ? stepPhase : (3 - stepPhase);
        }
        s = _spr(
          'rp_atras_${tipo}_${pQue}_$phase',
          () => mkNinoAtras(tipo, pQue, phase),
        );
      }
      out.add(
        RopaItem(s, sx - PX, sy - inkBottom(s), sy, at.d, tag: 'persona:$cid'),
      );
    }

    // 10. Canelo (`perro`) wearing abuela's sun hat (story 80 ending)
    if (_n(w['perroVis']) == 1) {
      final pw = _perroWorld();
      final at = _p.atWorld(pw[0], pw[1], 0);
      final sx = _round(at.sx), sy = _round(at.sy);
      final s = _spr('rp_perro_sombrero', mkPerroSombrero);
      out.add(
        RopaItem(s, sx - 15, sy - inkBottom(s), sy, at.d, tag: 'persona:perro'),
      );
    }

    // 11. People (`abuela`, `luis`, `carmen`)
    for (final en in gente.entries) {
      final p = en.value as Map<String, dynamic>;
      if (p['vis'] == 0) continue;
      final open = talk == en.key && a % 2 == 1;
      final sp = _personSprite(en.key, p, open, w);
      final at = _atOf(p);
      final sx = _round(at.sx) + _n(p['dx']);
      final sy = _round(at.sy) + _n(p['dy']);
      out.add(
        RopaItem(
          sp.s,
          sx - sp.ax,
          sy - sp.ay,
          sy,
          at.d,
          tag: 'persona:${en.key}',
        ),
      );
    }

    return out;
  }

  /* ---------- drawing ---------- */

  Float32List? _setZ;
  bool _framed = false;
  Uint32List? _layer;
  Float32List? _layerZ;

  @override
  void setFramed(PpEngine engine, BakedSet baked, Map<String, dynamic> W) {
    _framed = true;
    // Live depth (after engine.drawLeaves) so swaying palm fronds hide sprites behind them (ropa-sheet.json front.plane).
    _setZ = engine.zb;
  }

  static final double _t30 = math.tan(math.pi / 6);

  void _put(
    RopaItem it,
    int W0,
    int H0,
    Float32List? setZ,
    double bias,
    double S,
  ) {
    final layer = _layer!, lz = _layerZ!, s = it.s;
    for (var y = 0; y < s.h; y++) {
      final Y = it.top + y;
      if (Y < 0 || Y >= H0) continue;
      final plane = it.d + (it.sy - (Y + .5)) * _t30 / S;
      for (var x = 0; x < s.w; x++) {
        final c = s.px[y * s.w + x];
        if (c >>> 24 == 0) continue;
        final X = it.left + x;
        if (X < 0 || X >= W0) continue;
        final i = Y * W0 + X;
        if (!it.flat && setZ != null && setZ[i] > plane + bias) continue;
        if (lz[i] > plane + .001) continue;
        lz[i] = plane;
        layer[i] = c;
      }
    }
  }

  static final Map<String, Sprite> _frogSprites = {};

  /// [items] and the frog (always last so a tie goes to the frog), plus carried item overlay.
  List<RopaItem> placed(Map<String, dynamic> W, int a) {
    final all = items(W, a);
    final q = W['cq'] as Map<String, dynamic>;
    if (jsTruthy(q['vis'])) {
      final b = host.frogBox(q), at = _frogPoint(q);
      final dx = _n(q['dx']);
      final fsy = _round(at.sy);
      final fsx = _round(at.sx) + dx;
      if (_n(W['coquiToalla']) == 1) {
        final tr = _spr('rp_coqui_toalla', mkCoquiToallaRopa);
        all.add(
          RopaItem(tr, fsx - tr.w ~/ 2, fsy - tr.h, fsy, at.d, tag: 'coqui'),
        );
      } else {
        final ox = b.x.toInt() - 16 + dx, oy = b.y.toInt() - 24;
        final fk =
            '${q['s']}_${b.x - (b.x.toInt() - 16)}_${b.y - oy}_${(q['y'] as num) - oy}_${((q['dy'] as num) + 0.5).floor()}_${host.F % 47 < 2 ? 1 : 0}_${((q['bub'] == 'hola' || _talker() == 'coqui') && a % 2 != 0) ? 1 : 0}';
        final spr = _frogSprites.putIfAbsent(fk, () {
          final px = Uint32List(64 * 64);
          final g = Ctx(px, 64, 64)
            ..translate(-(b.x.toInt() - 16).toDouble(), -oy.toDouble());
          host.frog(g, q, a);
          return Sprite(64, 64, px);
        });
        all.add(RopaItem(spr, ox, oy, fsy, at.d, tag: 'coqui'));
      }

      if (W['coquiLleva'] is String) {
        final cs = _llevaSprite(W['coquiLleva'] as String);
        all.add(
          RopaItem(
            cs,
            fsx - cs.w ~/ 2,
            fsy - 26 + _n(q['dy']),
            fsy,
            at.d + .04,
            tag: 'held:coqui_lleva',
          ),
        );
      }
    }
    return all;
  }

  @override
  void draw(Ctx c, Map<String, dynamic> W, int a) {
    if (!_framed) return;
    const w0 = 240, h0 = 216;
    final layer = _layer ??= Uint32List(w0 * h0);
    final lz = _layerZ ??= Float32List(w0 * h0);
    final setZ = _setZ, bias = _p.bias, S = _p.e.S;
    final all = placed(W, a);
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
          // #4A6C8C muted slate-blue (ABGR; no red anywhere per Noche rules).
          fr(c, x + 1 + k, y + 2 + k, 2, 1, 0xFF8C6C4A);
          fr(c, x + 11 - k, y + 2 + k, 2, 1, 0xFF8C6C4A);
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
      final z = (p['z'] as num).toDouble();
      final spot = p['spot'] as String?;
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
    final ninos = (W['ninos'] as Map?) ?? const {};
    final nr = _p.radius('ninos');
    if (nr != null) {
      for (final spot in ninos.values) {
        if (spot is String && _p.has(spot) && !_p.noShadow(spot)) {
          final at = _p.at(spot);
          if (at.z == 0) out.add((x: at.x, y: at.y, z: 0.0, r: nr));
        }
      }
    }
    if (_n(W['perroVis']) == 1) {
      final r = _p.radius('perro');
      if (r != null) {
        final pw = _perroWorld();
        out.add((x: pw[0], y: pw[1], z: 0.0, r: r));
      }
    }
    final q = W['cq'] as Map<String, dynamic>;
    if (jsTruthy(q['vis'])) {
      final at = _frogPoint(q);
      final spot = q['spot'] as String?;
      final r = _p.radius('coqui');
      if (r != null && at.z == 0 && (spot == null || !_p.noShadow(spot))) {
        out.add((x: at.x, y: at.y, z: 0.0, r: r));
      }
    }
    return out;
  }

  /* ---------- speech bubbles ---------- */

  @override
  List<num>? talkAt(String who, Map<String, dynamic> W) {
    if (who == 'coqui') {
      final q = W['cq'] as Map<String, dynamic>;
      final b = host.frogBox(q);
      return [b.x + b.w / 2, b.y];
    }
    if (who == 'perro' && _n(W['perroVis']) == 1) {
      final pw = _perroWorld();
      final at = _p.atWorld(pw[0], pw[1], 0);
      return [_round(at.sx), _round(at.sy) - 24];
    }
    final gente = (W['gente'] as Map<String, dynamic>?) ?? const {};
    final p = gente[who];
    if (p is Map<String, dynamic> && p['vis'] != 0) {
      final at = _atOf(p);
      final h = who == 'abuela' ? (_n(p['sent']) == 1 ? 44 : 50) : 41;
      return [_round(at.sx) + _n(p['dx']), _round(at.sy) + _n(p['dy']) - h];
    }
    return null;
  }

  /* ---------- things he can touch (ropa.md Needs + ropa-sheet.json) ---------- */

  List<num>? _itemBox(Map<String, dynamic> w, String tag) {
    for (final it in items(w, 0)) {
      if (it.tag != tag) continue;
      final s = it.s;
      var x0 = s.w, y0 = s.h, x1 = -1, y1 = -1;
      for (var y = 0; y < s.h; y++) {
        for (var x = 0; x < s.w; x++) {
          if (s.px[y * s.w + x] >>> 24 == 0) continue;
          if (x < x0) x0 = x;
          if (x > x1) x1 = x;
          if (y < y0) y0 = y;
          if (y > y1) y1 = y;
        }
      }
      if (x1 < 0) return [it.left, it.top, s.w, s.h];
      return [it.left + x0, it.top + y0, x1 - x0 + 1, y1 - y0 + 1];
    }
    return null;
  }

  bool _vis(Map<String, dynamic> w, String who) {
    final g = w['gente'];
    return g is Map && g[who] is Map && (g[who] as Map)['vis'] != 0;
  }

  List<Thing> _things() {
    Thing spriteThing(
      String id,
      String tag,
      bool Function(Map<String, dynamic> w) si,
    ) => Thing(id: id, si: si, box: (w) => _itemBox(w, tag));

    // Order matters for Escena.hit: small clothes/afloat/plate/bag sprites first, then look-alike children,
    // then people & Canelo, then background `guagua` set thing last.
    return [
      for (final k in const [
        'camisa',
        'pantalon',
        'vestido',
        'zapatos',
        'sombrero',
        'toalla',
        'chancletas',
        'gafas',
        'traje',
        'plato',
        'bolsa',
      ])
        spriteThing(k, 'cosa:$k', (w) => _itemBox(w, 'cosa:$k') != null),
      for (final cid in ROPA_NINOS)
        spriteThing(
          cid,
          'persona:$cid',
          (w) => ((w['ninos'] as Map?) ?? const {}).containsKey(cid),
        ),
      for (final who in ROPA_PERSONAS)
        spriteThing(who, 'persona:$who', (w) => _vis(w, who)),
      spriteThing('perro', 'persona:perro', (w) => _n(w['perroVis']) == 1),
      Thing(
        id: 'guagua',
        si: (w) => _n(w['guagua']) == 1,
        box: (_) => _p.box('guagua'),
        world: _p.worldBox('guagua'),
      ),
    ];
  }

  bool _opaqueAt(RopaItem it, int ix, int iy) =>
      ix >= it.left &&
      ix < it.left + it.s.w &&
      iy >= it.top &&
      iy < it.top + it.s.h &&
      (it.s.px[(iy - it.top) * it.s.w + (ix - it.left)] >>> 24) != 0;

  @override
  String? hit(num x, num y, Map<String, dynamic> w) {
    bool inBox(List<num> b, num m) =>
        x >= b[0] - m &&
        x < b[0] + b[2] + m &&
        y >= b[1] - m &&
        y < b[1] + b[3] + m;

    if (aveHit(x, y)) return 'pajaro';
    final ix = x.floor(), iy = y.floor();
    final byTag = <String, RopaItem>{};
    for (final it in placed(w, host.F)) {
      if (it.tag != null) byTag[it.tag!] = it;
    }

    var inFrogBox = false;
    final q = w['cq'] as Map<String, dynamic>;
    if (jsTruthy(q['vis'])) {
      final fb = host.frogBox(q);
      if (x >= fb.x && x < fb.x + fb.w && y >= fb.y && y < fb.y + fb.h) {
        final coquiItem = byTag['coqui'];
        if (coquiItem != null && _opaqueAt(coquiItem, ix, iy)) {
          return 'coqui';
        }
        // Transparent corner inside frogBox: let exact `cosas` hits (e.g. adjacent child shoes) win first.
        inFrogBox = true;
      }
    }

    // Two-pass hit resolution: exact boxes first (margin 0) so adjacent clothes on the line,
    // afloat items, and look-alike children never steal pixels across close boundaries, then margin slack.
    final visible = <(Thing, List<num>, RopaItem?)>[];
    final exactMatches = <(Thing, RopaItem?)>[];
    for (final t in cosas) {
      if (t.si != null && !t.si!(w)) continue;
      final b = box(t.id, w);
      if (b == null) continue;
      final it = t.id == 'guagua'
          ? null
          : (ROPA_PERSONAS.contains(t.id) ||
                    ROPA_NINOS.contains(t.id) ||
                    t.id == 'perro'
                ? byTag['persona:${t.id}']
                : byTag['cosa:${t.id}']);
      if (inBox(b, 0)) exactMatches.add((t, it));
      visible.add((t, b, it));
    }
    if (exactMatches.isNotEmpty) {
      Thing? opaqueBest;
      var bestDepth = double.negativeInfinity;
      for (final (t, it) in exactMatches) {
        if (it != null && _opaqueAt(it, ix, iy) && it.d > bestDepth) {
          bestDepth = it.d;
          opaqueBest = t;
        }
      }
      return (opaqueBest ?? exactMatches.first.$1).id;
    }
    if (inFrogBox) return 'coqui';
    for (final (t, b, _) in visible) {
      final m = t.m ?? 3;
      if (inBox(b, m)) return t.id;
    }
    return null;
  }

  /* ---------- movement helpers ---------- */

  Future<void> _hopTo(String spot, {int steps = 6}) async {
    if (!_p.has(spot)) return;
    final q = W['cq'] as Map<String, dynamic>;
    final at = _p.at(spot);
    final L = _frogAt(at);
    final sx = (q['x'] as num).toDouble();
    final sy = (q['y'] as num).toDouble();
    final ex = L[0].toDouble();
    final ey = L[1].toDouble();
    final n = math.max(1, steps);
    for (var i = 1; i <= n; i++) {
      final t = i / n;
      q['x'] = _round(sx + (ex - sx) * t);
      q['y'] = _round(sy + (ey - sy) * t);
      q['dy'] = -_round(math.sin(t * math.pi) * 8);
      await wait(45);
    }
    q['x'] = L[0];
    q['y'] = L[1];
    q['dy'] = 0;
    q['z'] = at.z;
    q['spot'] = spot;
  }

  Future<void> _hopToScreen(
    int ex,
    int ey,
    double ez,
    String spot, {
    int steps = 5,
  }) async {
    final q = W['cq'] as Map<String, dynamic>;
    final sx = (q['x'] as num).toDouble();
    final sy = (q['y'] as num).toDouble();
    final n = math.max(1, steps);
    for (var i = 1; i <= n; i++) {
      final t = i / n;
      q['x'] = _round(sx + (ex - sx) * t);
      q['y'] = _round(sy + (ey - sy) * t);
      q['dy'] = -_round(math.sin(t * math.pi) * 7);
      await wait(45);
    }
    q['x'] = ex;
    q['y'] = ey;
    q['dy'] = 0;
    q['z'] = ez;
    q['spot'] = spot;
  }

  Future<void> _brinco() async {
    final q = W['cq'] as Map<String, dynamic>;
    for (final dy in const [-4, -7, -4, 0]) {
      q['dy'] = dy;
      await wait(60);
    }
  }

  Future<void> _movePerson(
    Map<String, dynamic> p,
    String spot, {
    int steps = 6,
    int? sent,
  }) async {
    if (!_p.has(spot)) return;
    final target = _p.world(spot);
    final sx = (p['x'] as num).toDouble();
    final sy = (p['y'] as num).toDouble();
    final sz = (p['z'] as num).toDouble();
    final n = math.max(1, steps);
    p['sent'] = 0;
    for (var i = 1; i <= n; i++) {
      final t = i / n;
      p['x'] = sx + (target[0] - sx) * t;
      p['y'] = sy + (target[1] - sy) * t;
      p['z'] = sz + (target[2] - sz) * t;
      await wait(45);
    }
    p['x'] = target[0];
    p['y'] = target[1];
    p['z'] = target[2];
    p['spot'] = spot;
    if (sent != null) p['sent'] = sent;
  }

  @override
  List<num> remap(List<num> xy) => xy;

  @override
  Future<void> stake(int lost, int max, String en) async {}

  /* ---------- acts ---------- */

  final List<Future<void>> _sueltos = [];

  @override
  Map<String, Act> get ownActs => {
    for (final e in _acts.entries)
      e.key: e.key == 'ya'
          ? e.value
          : (o) {
              if (!jsTruthy(o['suelto'])) return e.value(o);
              final f = e.value(o);
              _sueltos.add(f);
              unawaited(f.then((_) {}, onError: (Object _) {}));
              return Future<void>.value();
            },
  };

  static String _pegOf(String que) => switch (que) {
    'camisa' => 'cuerda2',
    'pantalon' => 'cuerda3',
    'vestido' => 'cuerda4',
    _ => 'cuerda1',
  };

  static String _ninoSpotOf(String id) => switch (id) {
    'chico_a' => 'ninos1',
    'chico_b' => 'ninos2',
    'chica_a' => 'ninos3',
    _ => 'ninos4',
  };

  late final Map<String, Act> _acts = {
    'ya': (o) async {
      final all = List<Future<void>>.of(_sueltos);
      _sueltos.clear();
      await Future.wait(all);
    },
    'ir': (o) async {
      final a = o['a'] as String?;
      if (a != null && _p.has(a)) {
        await _hopTo(a, steps: 6);
      }
    },

    /* ---- Story 78: La ropa seca ---- */
    'panes': (o) async {
      W['panes'] = _n(o['n']).clamp(0, 3);
      await wait(120);
    },
    'tiende78': (o) async {
      final que = (o['que'] as String?) ?? 'camisa';
      if (que == 'zapatos') {
        W['zapatosVis'] = 1;
      } else {
        final c = Map<String, String>.from(W['cuerda'] as Map);
        c[_pegOf(que)] = que;
        W['cuerda'] = c;
      }
      await wait(150);
    },
    'salen78': (o) async {
      // OPEN: Luis and Carmen walk out from the water edge (`orilla2`/`orilla3`) to `pie1`/`pie2` wrapped in
      // towels and dripping, abuela lifts the plate cloth (`platoPano = 0`) and walks to sit on `banco1`.
      final luis = _gente['luis'] as Map<String, dynamic>?;
      final carmen = _gente['carmen'] as Map<String, dynamic>?;
      final abuela = _gente['abuela'] as Map<String, dynamic>?;
      if (luis != null) {
        final w0 = _p.world('orilla2');
        luis['x'] = w0[0];
        luis['y'] = w0[1];
        luis['z'] = w0[2];
        luis['vis'] = 1;
        luis['traje'] = 1;
        luis['toalla'] = 1;
        luis['gotea'] = 1;
      }
      if (carmen != null) {
        final w0 = _p.world('orilla3');
        carmen['x'] = w0[0];
        carmen['y'] = w0[1];
        carmen['z'] = w0[2];
        carmen['vis'] = 1;
        carmen['traje'] = 1;
        carmen['toalla'] = 1;
        carmen['gotea'] = 1;
      }
      await Future.wait([
        if (luis != null) _movePerson(luis, 'pie1', steps: 5, sent: 0),
        if (carmen != null) _movePerson(carmen, 'pie2', steps: 5, sent: 0),
      ]);
      W['platoPano'] = 0;
      if (abuela != null) {
        await _movePerson(abuela, 'banco1', steps: 6, sent: 1);
      }
    },
    'baja78': (o) async {
      // OPEN: interpolated hop between the piece's spot and abuela on `banco1` before returning to `coqui.cuerda`.
      final que = (o['que'] as String?) ?? 'camisa';
      final ok = _n(o['ok']) == 1;
      if (que == 'zapatos') {
        W['zapatosVis'] = 0;
      } else {
        final c = Map<String, String>.from(W['cuerda'] as Map);
        c.remove(_pegOf(que));
        W['cuerda'] = c;
      }
      W['coquiLleva'] = que;
      await _brinco();
      // Hop toward bench keeping clear of abuela at `banco1` (174, 98).
      final bAt = _p.at('banco1');
      await _hopToScreen(
        _round(bAt.sx) - 34,
        _round(bAt.sy) - 5,
        0.0,
        'coqui.cuerda',
        steps: 4,
      );
      W['coquiLleva'] = null;
      if (!ok) {
        W['caida'] = <String, dynamic>{'que': que};
        W['ultimaCaida'] = que;
      }
      await _hopTo('coqui.cuerda', steps: 4);
    },
    'sacude78': (o) async {
      final ultima = W['ultimaCaida'] as String?;
      W['nubeArena'] = 1;
      for (final (gx, gy) in const [(162, 84), (174, 68), (190, 50)]) {
        W['gaviota'] = <String, dynamic>{'x': gx, 'y': gy};
        await wait(75);
      }
      W['gaviota'] = null;
      W['nubeArena'] = 0;
      W['caida'] = null;
      W['ultimaCaida'] = null;
      if (ultima != null) {
        if (ultima == 'zapatos') {
          W['zapatosVis'] = 1;
        } else {
          final c = Map<String, String>.from(W['cuerda'] as Map);
          c[_pegOf(ultima)] = ultima;
          W['cuerda'] = c;
        }
      }
      await wait(80);
    },
    'final78': (o) async {
      final n = _n(o['n']).clamp(1, 3);
      W['cuerda'] = <String, String>{};
      W['zapatosVis'] = 0;
      W['panes'] = n;
      final luis = _gente['luis'] as Map<String, dynamic>?;
      final carmen = _gente['carmen'] as Map<String, dynamic>?;
      final abuela = _gente['abuela'] as Map<String, dynamic>?;
      if (luis != null) {
        luis['traje'] = 0;
        luis['toalla'] = 0;
        luis['gotea'] = 0;
        luis['pose'] = 'rie';
      }
      if (carmen != null) {
        carmen['traje'] = 0;
        carmen['toalla'] = 0;
        carmen['gotea'] = 0;
        carmen['pose'] = 'rie';
      }
      if (abuela != null) abuela['pose'] = 'rie';
      await _brinco();
      if (luis != null) luis['pose'] = 'idle';
      if (carmen != null) carmen['pose'] = 'idle';
      if (abuela != null) abuela['pose'] = 'idle';
    },

    /* ---- Story 79: ¡Mi sombrero! ---- */
    'flotan': (o) async {
      // OPEN: 5-item opening order comes from gen_ropa.py (`sombrero,gafas,chancletas,traje,toalla`) on `agua1..5`;
      // 4-item game order uses `agua1, agua2, agua4, agua5` matching ropa-sheet.json `moment4`.
      final raw = (o['orden'] as String?) ?? '';
      final list = [
        for (final s in raw.split(','))
          if (s.trim().isNotEmpty) s.trim(),
      ];
      final spots = list.length >= 5
          ? const ['agua1', 'agua2', 'agua3', 'agua4', 'agua5']
          : const ['agua1', 'agua2', 'agua4', 'agua5'];
      final m = <String, String>{};
      for (var i = 0; i < list.length && i < spots.length; i++) {
        m[spots[i]] = list[i];
      }
      W['agua'] = m;
      W['farOut'] = null;
      if (list.length <= 4) {
        W['story79Fase'] = 'game';
        W['perdidos79'] = <String>[];
      }
      await wait(120);
    },
    'bolsa': (o) async {
      W['bolsaVis'] = 1;
      W['bolsaN'] = _n(o['n']).clamp(0, 3);
      await wait(120);
    },
    'trae79': (o) async {
      // OPEN: frog hops over to the floating item's `agua` spot (or `farOut`), pushes it back to `coqui.orilla`.
      final que = (o['que'] as String?) ?? 'sombrero';
      String? foundSpot;
      final agua = Map<String, String>.from(W['agua'] as Map);
      for (final en in agua.entries) {
        if (en.value == que) {
          foundSpot = en.key;
          break;
        }
      }
      final far = W['farOut'];
      if (foundSpot != null) {
        await _hopTo(foundSpot, steps: 5);
        agua.remove(foundSpot);
        W['agua'] = agua;
      } else if (far is Map && far['que'] == que) {
        final pw = _p.xyOf(0.05, -1.2);
        final at = _p.atWorld(pw[0], pw[1], 0);
        await _hopToScreen(
          _round(at.sx) - 16,
          _round(at.sy) - 25,
          at.d,
          'coqui.orilla',
          steps: 5,
        );
        W['farOut'] = null;
      }
      W['coquiLleva'] = que;
      await _hopTo('coqui.orilla', steps: 5);
      W['coquiLleva'] = null;
      final abuela = _gente['abuela'] as Map<String, dynamic>?;
      if (W['story79Fase'] == 'open' && que == 'sombrero') {
        if (abuela != null) abuela['abPose'] = 'sombrero';
        await wait(180);
        if (abuela != null) abuela['abPose'] = 'manos';
        // Small wave takes the hat back into the water for step 3.
        if (foundSpot != null) {
          final restored = Map<String, String>.from(W['agua'] as Map);
          restored[foundSpot] = 'sombrero';
          W['agua'] = restored;
        }
      } else if (que == 'toalla') {
        final c = Map<String, String>.from(W['cuerda'] as Map);
        c['cuerda2'] = 'toalla_mojada';
        W['cuerda'] = c;
      } else {
        W['bolsaDentro'] = _n(W['bolsaDentro']) + 1;
      }
      await wait(80);
    },
    'ola79': (o) async {
      // OPEN: wave rolls across and carries the asked item (`lleva`) out to open shallow water (u 0.05, v -1.2)
      // between the two palm crowns so it stays visible, clear of fronds, and touchable for the retry ask.
      final lleva = (o['lleva'] as String?) ?? 'sombrero';
      for (final y in const [56, 52, 48, 52, 56]) {
        W['ola'] = <String, dynamic>{'y': y};
        await wait(65);
      }
      W['ola'] = null;
      final agua = Map<String, String>.from(W['agua'] as Map);
      String? spot;
      for (final en in agua.entries) {
        if (en.value == lleva) {
          spot = en.key;
          break;
        }
      }
      if (spot != null) {
        agua.remove(spot);
        W['agua'] = agua;
        W['farOut'] = <String, dynamic>{'que': lleva};
      }
    },
    'lejos79': (o) async {
      final que = (o['que'] as String?) ?? 'sombrero';
      final far = W['farOut'];
      if (far is Map) {
        final pw = _p.xyOf(0.05, -1.2);
        final at = _p.atWorld(pw[0], pw[1], 0);
        await _hopToScreen(
          _round(at.sx) - 16,
          _round(at.sy) - 25,
          at.d,
          'coqui.orilla',
          steps: 4,
        );
      }
      for (final y in const [54, 48, 44]) {
        W['ola'] = <String, dynamic>{'y': y};
        await wait(65);
      }
      W['farOut'] = null;
      W['ola'] = null;
      final lost = List<String>.from(W['perdidos79'] as List);
      if (!lost.contains(que)) lost.add(que);
      W['perdidos79'] = lost;
      await _hopTo('coqui.orilla', steps: 5);
    },
    'final79': (o) async {
      // OPEN: remaining un-lost items hang dripping on `cuerda1, 2, 4, 5` while abuela takes the dry towel off
      // `cuerda3` to wrap Coquí (`coquiToalla = 1`).
      final n = _n(o['n']).clamp(1, 3);
      W['agua'] = <String, String>{};
      W['farOut'] = null;
      final lost = (W['perdidos79'] as List).cast<String>().toSet();
      final kept = [
        for (final k in const ['sombrero', 'chancletas', 'gafas', 'traje'])
          if (!lost.contains(k)) k,
      ];
      const pegs = ['cuerda1', 'cuerda2', 'cuerda4', 'cuerda5'];
      final c = <String, String>{};
      for (var i = 0; i < kept.length && i < pegs.length; i++) {
        c[pegs[i]] = kept[i];
      }
      W['cuerda'] = c;
      // OPEN: move frog to `banco2` (202, 98, on the bench) when wrapped in the dry towel so
      // `cuerda4`/`cuerda5` above `coqui.orilla` and `abuela` at `orilla1` never overlap him (`frog-seen`).
      await _hopTo('banco2', steps: 4);
      W['coquiToalla'] = 1;
      final abuela = _gente['abuela'] as Map<String, dynamic>?;
      final luis = _gente['luis'] as Map<String, dynamic>?;
      final carmen = _gente['carmen'] as Map<String, dynamic>?;
      if (abuela != null) abuela['abPose'] = 'idle';
      if (n == 2) {
        if (abuela != null) {
          abuela['dy'] = -2;
          await wait(180);
          abuela['dy'] = 0;
        }
      } else if (n == 1) {
        if (luis != null) luis['pose'] = 'rie';
        if (carmen != null) carmen['pose'] = 'rie';
        if (abuela != null) {
          for (var i = 0; i < 4; i++) {
            abuela['pose'] = i.isEven ? 'saluda0' : 'saluda1';
            await wait(90);
          }
          abuela['pose'] = 'idle';
        }
        if (luis != null) luis['pose'] = 'idle';
        if (carmen != null) carmen['pose'] = 'idle';
      } else {
        await wait(200);
      }
    },

    /* ---- Story 80: Se pone y se quita ---- */
    'dedos': (o) async {
      W['dedos'] = _n(o['n']).clamp(0, 3);
      W['choferModo'] = 'fingers';
      await wait(120);
    },
    'pone80': (o) async {
      final quien = o['quien'] as String?;
      final que = o['que'] as String?;
      final p = _gente[quien] as Map<String, dynamic>?;
      if (p == null || que == null) return;
      if (que == 'camisa') p['camisa'] = 1;
      if (que == 'vestido') p['vestido'] = 1;
      if (que == 'sombrero') p['sombrero'] = 1;
      if (que == 'gafas') p['gafas'] = 1;
      await wait(160);
    },
    'quita80': (o) async {
      final quien = o['quien'] as String?;
      final que = o['que'] as String?;
      final p = _gente[quien] as Map<String, dynamic>?;
      if (p == null || que == null) return;
      if (que == 'sombrero') p['sombrero'] = 0;
      if (que == 'gafas') p['gafas'] = 0;
      if (que == 'chancletas') p['chancletas'] = 0;
      await wait(160);
    },
    'pareja80': (o) async {
      // Started `suelto: 1` with NO `ya`: records active pair in `W` so `draw()` animates continuously from `host.F`.
      final quienes = (o['quienes'] as String?) ?? 'chicos';
      final que = (o['que'] as String?) ?? 'sombrero';
      final hace = (o['hace'] as String?) ?? 'pone';
      final cual = (o['cual'] as String?) ?? 'a';
      W['pareja'] = <String, String>{
        'quienes': quienes,
        'que': que,
        'hace': hace,
        'cual': cual,
      };
      final ninos = Map<String, String>.from(W['ninos'] as Map);
      if (quienes == 'chicos') {
        ninos['chico_a'] = 'ninos1';
        ninos['chico_b'] = 'ninos2';
      } else {
        ninos['chica_a'] = 'ninos3';
        ninos['chica_b'] = 'ninos4';
      }
      W['ninos'] = ninos;
    },
    'busca80': (o) async {
      final quien = (o['quien'] as String?) ?? 'chico_a';
      final ok = _n(o['ok']) == 1;
      final spot = _ninoSpotOf(quien);
      await _hopTo(spot, steps: 5);
      if (ok) {
        W['pareja'] = null;
        final ninos = Map<String, String>.from(W['ninos'] as Map);
        if (quien.startsWith('chico')) {
          ninos.remove('chico_a');
          ninos.remove('chico_b');
          final luis = _gente['luis'] as Map<String, dynamic>?;
          if (luis != null) {
            luis['vis'] = 1;
            luis['camisa'] = 1;
            luis['sombrero'] = 1;
          }
        } else {
          ninos.remove('chica_a');
          ninos.remove('chica_b');
          final carmen = _gente['carmen'] as Map<String, dynamic>?;
          if (carmen != null) {
            carmen['vis'] = 1;
            carmen['vestido'] = 1;
          }
        }
        W['ninos'] = ninos;
        await _hopTo('coqui.busca', steps: 5);
      } else {
        W['extranoRie'] = quien;
        await wait(220);
        W['extranoRie'] = null;
        await _hopTo('coqui.busca', steps: 5);
      }
    },
    'bocina': (o) async {
      W['choferModo'] = 'horn';
      await wait(180);
      W['choferModo'] = 'fingers';
    },
    'final80': (o) async {
      // OPEN: no boarding spot at `parada` and no spot for `perro` in ropa-sheet.json; Luis & Carmen run to
      // `parada` and board (`vis = 0`), abuela stands at `parada` counting heads, and Canelo appears right under
      // `coqui.busca` wearing abuela's sun hat.
      final n = _n(o['n']).clamp(1, 3);
      W['pareja'] = null;
      W['ninos'] = <String, String>{};
      W['dedos'] = n;
      W['choferModo'] = n >= 3 ? 'smile' : (n == 2 ? 'tap' : 'fingers');
      final luis = _gente['luis'] as Map<String, dynamic>?;
      final carmen = _gente['carmen'] as Map<String, dynamic>?;
      final abuela = _gente['abuela'] as Map<String, dynamic>?;
      if (luis != null && luis['vis'] != 0) {
        await _movePerson(luis, 'parada', steps: 4, sent: 0);
        luis['vis'] = 0;
      }
      if (carmen != null && carmen['vis'] != 0) {
        await _movePerson(carmen, 'parada', steps: 4, sent: 0);
        carmen['vis'] = 0;
      }
      if (abuela != null) {
        if (n == 1) {
          for (var i = 0; i < 4; i++) {
            abuela['pose'] = i.isEven ? 'saluda0' : 'saluda1';
            await wait(70);
          }
          abuela['pose'] = 'idle';
        }
        await _movePerson(abuela, 'parada', steps: 5, sent: 0);
      }
      W['perroVis'] = 1;
      await wait(160);
    },

    /* ---- Shared gestures (ropa.md Needs) ---- */
    'gesto': (o) async {
      final quien = o['quien'] as String?, que = o['que'] as String?;
      if (quien == null || que == null) return;
      if (quien == 'coqui') {
        await _brinco();
        return;
      }
      final p = _gente[quien] as Map<String, dynamic>?;
      if (p == null || p['vis'] == 0) return;
      switch (que) {
        case 'saluda':
          for (var i = 0; i < 4; i++) {
            p['pose'] = i.isEven ? 'saluda0' : 'saluda1';
            p['dy'] = i.isEven ? -2 : 0;
            await wait(90);
          }
          p['pose'] = 'idle';
          p['dy'] = 0;
        case 'no':
          for (final d in const [-2, 2, -2, 0]) {
            p['dx'] = d;
            await wait(75);
          }
        case 'si':
          for (var i = 0; i < 2; i++) {
            p['dy'] = -3;
            await wait(90);
            p['dy'] = 0;
            await wait(70);
          }
        case 'rie':
          p['pose'] = 'rie';
          for (final dy in const [-2, 0, -2, 0]) {
            p['dy'] = dy;
            await wait(65);
          }
          p['pose'] = 'idle';
        case 'mira':
          p['dy'] = -1;
          await wait(160);
          p['dy'] = 0;
        case 'senala':
          p['pose'] = 'senala';
          await wait(200);
          p['pose'] = 'idle';
        case 'gira':
          for (final dx in const [-2, 2, 0]) {
            p['dx'] = dx;
            await wait(75);
          }
        case 'manos':
          p['abPose'] = 'manos';
          await wait(180);
        case 'ojos':
          p['dy'] = -1;
          await wait(140);
          p['dy'] = 0;
          // OPEN: story 80 step 4 (`gesto abuela ojos`) transitions Luis & Carmen off to the water's edge as the
          // four look-alike children (`ninos1..4`) and frog (`coqui.busca`) take their moment-6 game spots.
          if (_n(W['story']) == 80 && quien == 'abuela') {
            final luis = _gente['luis'] as Map<String, dynamic>?;
            final carmen = _gente['carmen'] as Map<String, dynamic>?;
            if (luis != null) luis['vis'] = 0;
            if (carmen != null) carmen['vis'] = 0;
            W['ninos'] = <String, String>{
              'chico_a': 'ninos1',
              'chico_b': 'ninos2',
              'chica_a': 'ninos3',
              'chica_b': 'ninos4',
            };
            await _hopTo('coqui.busca', steps: 6);
          }
        case 'hombros':
          p['dy'] = -2;
          await wait(160);
          p['dy'] = 0;
        case 'abanica':
          p['abanica'] = 1;
          for (final dx in const [-1, 1, -1, 0]) {
            p['dx'] = dx;
            await wait(65);
          }
          p['abanica'] = 0;
      }
    },
    'marca': (o) async {
      final m = W['marcas'];
      if (m is List) {
        final i = m.indexOf(null);
        if (i >= 0) m[i] = o['que'];
      }
      await wait(160);
    },
    'fin': (o) async {
      await wait(240);
    },
  };
}
