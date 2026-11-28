// La noche (place 9, La casa, un día entero, scene 4: `noche`; stories 105 to 107): a NEW scene, written from its
// script's "Needs" list (historia/notas/guiones/noche.md) on its set (noche_set.dart) and its sheet (noche-sheet.json,
// read by SceneSheet). There is no old scene file: every act is this file's, each doing on screen what the Needs list
// says, every place from the sheet (spots, set thing boxes, cama metadata, held-item offsets, depth rule, shadows).
// Where the sheet names no place or an act is unstated in the script, the code does the plainest thing that keeps the
// story playing and marks it `OPEN:`.
//
// The drawing (the sheet's `front`): every sprite stands with its feet's bottom edge on its spot's row and its middle
// on its column (rules.anchor); whoever sits on a chair/armchair/sofa hangs by the lap (abuelaS: 17, 36; adult: 24, 41;
// child: 24, 33); children on the rug in 105 sit on the floor (sent drawing with feet on the spot); whoever lies in
// the bed hangs from his head's place with a blanket from chest to foot (rules.lying horizontal depth plane). Every
// sprite pixel is hidden by every set pixel (`baked.zb`) nearer than its plane plus `front.bias` (0.3). Between two
// sprites the nearer pixel wins (tie within 0.001 goes to the later layer).
// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/src/noche/noche_places.dart';
import 'package:coqui_scenes/src/noche/noche_set.dart';
import 'package:coqui_scenes/src/noche/noche_sprites.dart';
import 'package:coqui_scenes/src/scene_set.dart';
import 'package:coqui_scenes/src/sheet_cache.dart';

/// The scene "La noche", made from its sheet (read first: `loadScene`).
Scene createNoche() => Noche(sceneSheetOf('noche'));

int _round(num v) => (v + 0.5).floor();

int _n(Object? v) {
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? 0;
  return 0;
}

/// One sprite of the sprite layer, placed: its picture, its top left on the 240 × 216 picture, the screen row of its
/// anchor and the depth there (front.plane), and who or what it is.
class NocheItem {
  NocheItem(
    this.s,
    this.left,
    this.top,
    this.sy,
    this.d, {
    this.tag,
    this.overlay = false,
    this.lying = false,
    this.lyingZ = 0.0,
  });

  final Sprite s;
  final int left, top;
  final num sy;
  final double d;
  final String? tag;

  /// Screen-space overlay drawn over the set and world sprites (e.g. celebration cues).
  final bool overlay;

  /// Horizontal lying-in-bed depth plane (noche-sheet.json `rules.lying`).
  final bool lying;
  final double lyingZ;
}

/// Every person La noche knows, by speaker key (noche.md, "Needs").
const List<String> NOCHE_PERSONAS = [
  'abuela',
  'abuelo',
  'luis',
  'carmen',
  'perro',
];

const Set<String> _SEAT_SPOTS = {
  'sofa1',
  'sofa2',
  'sofa3',
  'butaca',
  'silla1',
  'silla2',
  'silla3',
  'silla4',
};

/// Table top destinations for `lleva106` when placed on `mesa` (clear of `vela`, `mesa_coqui`, and `silla1..4` heads).
// OPEN: noche-sheet.json gives no spots on the dinner table for carried sideboard items; placed in a tidy row on
// TABLE (z 0.74, v 5.9, u 2.25..3.45) clear of vela, mesa_coqui, and silla1..4 heads.
const Map<String, List<double>> _MESA_ITEM_UV = {
  'flan': [2.25, 5.9, 0.74],
  'jugo': [2.65, 5.9, 0.74],
  'queso': [3.05, 5.9, 0.74],
  'frutas': [3.45, 5.9, 0.74],
};

class Noche extends Escena implements SetScene, SetOverSprites {
  Noche(this.ss)
    : sheet = identical(ss, _lastSs)
          ? _lastSheet!
          : (_lastSheet = ss.legacy()) {
    _p = identical(ss, _lastSs)
        ? _lastPlaces!
        : (_lastPlaces = NochePlaces(ss));
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
  static NochePlaces? _lastPlaces;

  /// The new scene's sheet (SceneSheet).
  final SceneSheet ss;

  @override
  final Sheet sheet;

  late final NochePlaces _p;

  /// The scene's places, from its sheet.
  NochePlaces get places => _p;

  @override
  String get id => 'noche';

  @override
  late final Map<String, List<num>> CAM;

  late final Map<String, List<num>> LUGAR;

  @override
  Map<String, List<num>> get lugar => LUGAR;

  @override
  late final List<Thing> cosas;

  @override
  PpEngine newEngine({bool still = false}) => nocheEngine(still: still);

  @override
  PpEngine get projection => _p.e;

  List<num> _frogAt(NocheAt a) => [_round(a.sx) - 16, _round(a.sy) - 25, 1];

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
    int sent = 0,
    int lying = 0,
    String pose = 'idle',
  }) {
    final w = _p.world(spot);
    return <String, dynamic>{
      'x': w[0],
      'y': w[1],
      'z': w[2],
      'spot': spot,
      'vis': vis,
      'pose': pose,
      'sent': sent,
      'lying': lying,
      'dx': 0,
      'dy': 0,
    };
  }

  String _resolveSpot(String spot) {
    // OPEN: gen_noche.py uses `plato_perro`, `sofa_abuelo`, `sofa_pies`, `sofa_pies2`; mapped to noche-sheet.json
    // spots `perro`, `sofa1`, `sofa2`, `sofa3`.
    return switch (spot) {
      'plato_perro' => 'perro',
      'sofa_abuelo' => 'sofa1',
      'sofa_pies' => 'sofa2',
      'sofa_pies2' => 'sofa3',
      _ => spot,
    };
  }

  void _placePerson(
    String id,
    String rawSpot, {
    int vis = 1,
    int? sentOverride,
    int lying = 0,
    String pose = 'idle',
  }) {
    final spot = _resolveSpot(rawSpot);
    final w = _p.world(spot);
    final storyNum = _n(W['story']);
    final isRug105 =
        storyNum == 105 && (spot == 'alfombra1' || spot == 'alfombra2');
    final sent =
        sentOverride ?? (_SEAT_SPOTS.contains(spot) || isRug105 ? 1 : 0);
    _gente[id] = <String, dynamic>{
      'x': w[0],
      'y': w[1],
      'z': w[2],
      'spot': spot,
      'vis': vis,
      'pose': pose,
      'sent': sent,
      'lying': lying,
      'dx': 0,
      'dy': 0,
    };
  }

  @override
  Map<String, dynamic> fresh(Map<String, dynamic> story) {
    final acts = _actsOf([story['beats'], story['final']]);
    bool has(String a) => acts.any((o) => o['act'] == a);
    final is107 =
        has('reloj107') ||
        has('acuesta107') ||
        has('descansa107') ||
        has('levantados107') ||
        has('final107') ||
        has('canta107');
    final is106 =
        !is107 &&
        (has('tapa106') ||
            has('manos106') ||
            has('perro106') ||
            has('vela106') ||
            has('lleva106') ||
            has('final106') ||
            has('nariz106'));
    final storyNum = is107 ? 107 : (is106 ? 106 : 105);
    final startSpot = storyNum == 106 ? 'aparador_coqui' : 'brazo_coqui';
    final q = _frogAt(_p.at(startSpot));

    final gente = <String, dynamic>{};
    if (storyNum == 105) {
      gente['abuelo'] = _person('sofa1', sent: 1);
      gente['abuela'] = _person('butaca', sent: 1);
    } else if (storyNum == 106) {
      gente['abuela'] = _person('junto_mesa');
      gente['abuelo'] = _person('silla4', sent: 1);
      gente['perro'] = _person('perro');
      gente['luis'] = _person('silla1', sent: 1);
      gente['carmen'] = _person('silla2', sent: 1);
    } else {
      gente['abuela'] = _person('butaca', sent: 1);
      gente['abuelo'] = _person('ventana_abuelo');
      gente['luis'] = _person('alfombra1');
      gente['carmen'] = _person('alfombra2');
    }

    return <String, dynamic>{
      'story': storyNum,
      'hora': 'noche',
      'luz1': storyNum == 106 ? 1 : 0,
      'luz2': 1,
      'luz3': storyNum == 106 ? 1 : 0,
      'tele': 0,
      'mesa': storyNum == 106 ? 1 : 0,
      'oscuro': 0,
      'gente': gente,
      // Story 105 state
      'bufanda': 3,
      'bufandaVis': storyNum == 105 ? 1 : 0,
      'cqBufanda': 0,
      'lanaFx': null, // {x, y}
      'notaFx': null, // {x, y}
      'final105': 0,
      // Story 106 state
      'vela': 3,
      'velaVis': storyNum == 106 ? 1 : 0,
      'velaLit': 0,
      'manosLimpias': 0,
      'manosFx': null, // {clean: bool, x, y}
      'tapaFx': 0,
      'narizFx': 0,
      'mesaLampara': 0,
      'final106': 0,
      'items106': <String, String>{
        'jugo': 'aparador',
        'flan': 'aparador',
        'queso': 'aparador',
        'frutas': 'aparador',
      },
      // Story 107 state
      'relojHora': storyNum == 107 ? 8 : 0,
      'paginas': 3,
      'libroVis': storyNum == 107 ? 1 : 0,
      'libroPics': 0,
      'final107': 0,
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
        'z': _p.world(startSpot)[2],
        'spot': startSpot,
      },
    };
  }

  /* ---------- the set ---------- */

  @override
  String setKey(Map<String, dynamic> W) {
    final oscuro = _n(W['oscuro']) == 1 ? 1 : 0;
    final luz1 = oscuro == 1 ? 0 : (_n(W['luz1']) == 1 ? 1 : 0);
    final luz2 = oscuro == 1 ? 0 : (_n(W['luz2']) == 1 ? 1 : 0);
    final luz3 = oscuro == 1 ? 0 : (_n(W['luz3']) == 1 ? 1 : 0);
    final tele = _n(W['tele']) == 1 ? 1 : 0;
    final mesa = _n(W['mesa']) == 1 ? 1 : 0;
    return '$luz1-$luz2-$luz3-$tele-$mesa-$oscuro';
  }

  @override
  void buildSet(PpEngine e, PpBuild b, Map<String, dynamic> W) =>
      buildSetFor(e, b, setKey(W));

  final Map<PpEngine, NocheSet> _sets = {};

  @override
  void buildSetFor(PpEngine e, PpBuild b, String key) =>
      (_sets[e] ??= NocheSet(e, b)).buildSet(NocheState.fromKey(key));

  @override
  bool get frogShadow => false;

  /* ---------- where everybody is ---------- */

  Map<String, dynamic> get _gente => W['gente'] as Map<String, dynamic>;

  NocheAt _atOf(Map<String, dynamic> o) =>
      _p.atWorld(o['x'] as num, o['y'] as num, o['z'] as num);

  NocheAt _frogPoint(Map<String, dynamic> q) {
    final spot = q['spot'];
    if (spot is String && _p.hasWorld(spot)) {
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

  ({Sprite s, int ax, int ay, bool lying, double lyingZ}) _personSprite(
    String id,
    Map<String, dynamic> p,
    bool open,
    int storyNum,
    int a,
    int sx,
    int sy,
  ) {
    if (id == 'perro') {
      final pose = (p['pose'] as String?) ?? 'eat';
      final mp = switch (pose) {
        'bark' => 'bark',
        'sit' => 'sit',
        _ => 'eat',
      };
      final s = _spr('no_perro_${mp}_${a % 2}', () => mkPerro(mp, a % 2 == 1));
      // noche-sheet.json rules.anchor: Canelo mkPerro column 15 and bottom edge.
      return (s: s, ax: 15, ay: nocheInkBottom(s), lying: false, lyingZ: 0.0);
    }

    final pose = (p['pose'] as String?) ?? 'idle';
    final sent = _n(p['sent']) == 1;
    final lying = _n(p['lying']) == 1;
    final spot = (p['spot'] as String?) ?? '';

    if (id == 'abuela') {
      final abPose = switch (pose) {
        'saluda0' || 'saluda1' => 'saluda0',
        'senala' => 'tu',
        'rie' || 'palmas' => 'yo',
        _ => 'idle',
      };
      if (sent) {
        final s = _spr(
          'no_abS_${abPose}_$open',
          () => mkAbuelaS(abPose, open, false),
        );
        return (s: s, ax: 17, ay: 36, lying: false, lyingZ: 0.0);
      }
      final s = _spr('no_ab_${abPose}_$open', () => mkAbuela(abPose, open));
      return (s: s, ax: 30, ay: nocheInkBottom(s), lying: false, lyingZ: 0.0);
    }

    final whoKey = (storyNum == 105 || storyNum == 107)
        ? (id == 'luis'
              ? 'luis_pijama'
              : (id == 'carmen' ? 'carmen_pijama' : id))
        : id;
    final who = NOCHE_WHO[whoKey] ?? NOCHE_WHO['abuelo']!;

    if (lying) {
      final meta = _p.camaMeta;
      final s = _spr(
        'no_lying_${whoKey}_${sx}_${sy}_$open',
        () => mkLyingChild(
          who: who,
          sx: sx,
          sy: sy,
          footY: meta.footY,
          blanketW: meta.width,
          blanketCenterX: meta.centerX,
          blanketColour: meta.colour,
          open: open,
        ),
      );
      return (
        s: s,
        ax: 50,
        ay: 0,
        lying: true,
        lyingZ: (p['z'] as num).toDouble(),
      );
    }

    final kp = switch (pose) {
      'saluda0' => 'wave0',
      'saluda1' => 'wave1',
      'senala' => 'tu',
      'rie' || 'manos' || 'bosteza' => 'yo',
      'mano' => 'offer',
      _ => 'idle',
    };
    final s = _spr(
      'no_${whoKey}_${kp}_${open}_$sent',
      () => mkPersona(who, kp, open, sent),
    );
    // Floor-sitting on the rug in 105 uses inkBottom (noche-sheet.json rules.anchor); seats hang by the lap.
    final isRug = spot == 'alfombra1' || spot == 'alfombra2';
    final ay = sent && !isRug
        ? (16 + 2 * (who.nino ? 7 : 11) + 3)
        : nocheInkBottom(s);
    return (s: s, ax: PX, ay: ay, lying: false, lyingZ: 0.0);
  }

  String? _talker() {
    try {
      return host.TALK;
    } catch (_) {
      return null;
    }
  }

  /// Every sprite of the frame [w] as it is placed, except the frog. The rules' tests read it; [draw] draws it.
  List<NocheItem> items(Map<String, dynamic> w, int a) {
    final out = <NocheItem>[];
    final talk = _talker();
    final gente = (w['gente'] as Map<String, dynamic>?) ?? const {};
    final storyNum = _n(w['story']);

    // 1. Wall clock hands (story 107)
    final hora = _n(w['relojHora']);
    if (hora > 0) {
      final rb = _p.box('reloj');
      final rw = _p.sheet.thing('reloj').world!;
      final rat = _p.atWorld(
        (rw[0] + rw[3]) / 2,
        (rw[1] + rw[4]) / 2,
        (rw[2] + rw[5]) / 2,
      );
      final hs = _spr('no_reloj_$hora', () => mkRelojHands(hora: hora));
      out.add(
        NocheItem(
          hs,
          rb[0] + 1,
          rb[1] + 1,
          _round(rat.sy),
          rat.d + 0.2,
          tag: 'fx:reloj_hands',
        ),
      );
    }

    // 2. People
    for (final en in gente.entries) {
      final p = en.value as Map<String, dynamic>;
      if (p['vis'] == 0) continue;
      final open = talk == en.key && a % 2 == 1;
      final at = _atOf(p);
      final sx = _round(at.sx) + _n(p['dx']);
      final sy = _round(at.sy) + _n(p['dy']);
      final sp = _personSprite(en.key, p, open, storyNum, a, sx, sy);
      out.add(
        NocheItem(
          sp.s,
          sx - sp.ax,
          sy - sp.ay,
          sy,
          at.d,
          tag: 'persona:${en.key}',
          lying: sp.lying,
          lyingZ: sp.lyingZ,
        ),
      );
      if (en.key == 'abuelo' && (p['pose'] == 'zzz' || p['pose'] == 'dobla')) {
        final np = _spr('no_periodico', mkPeriodico);
        out.add(
          NocheItem(
            np,
            sx - 7,
            sy - (p['pose'] == 'zzz' ? 34 : 18),
            sy,
            at.d + .05,
            tag: 'fx:periodico',
          ),
        );
      }
    }

    // 3. Held items at `butaca` (`bufanda` in 105, `libro` in 107)
    if (_n(w['bufandaVis']) == 1) {
      final meta = _p.heldOffset('bufanda');
      final at = _p.at(meta.on);
      final stripes = _n(w['bufanda']).clamp(1, 3);
      final spr = _spr(
        'no_bufanda_$stripes',
        () => mkBufanda(stripes: stripes),
      );
      final sx = _round(at.sx) + meta.dx;
      final sy = _round(at.sy) + meta.dy;
      out.add(
        NocheItem(spr, sx - 6, sy - spr.h, sy, at.d + .05, tag: 'cosa:bufanda'),
      );
    }
    if (_n(w['libroVis']) == 1) {
      final meta = _p.heldOffset('libro');
      final at = _p.at(meta.on);
      final pages = _n(w['paginas']).clamp(1, 3);
      final spr = _spr('no_libro_$pages', () => mkLibroNoche(pages: pages));
      final sx = _round(at.sx) + meta.dx;
      final sy = _round(at.sy) + meta.dy;
      out.add(
        NocheItem(spr, sx - 6, sy - spr.h, sy, at.d + .05, tag: 'cosa:libro'),
      );
    }

    // 4. Story 106 sideboard & dinner table items + tall candle
    if (storyNum == 106) {
      final itemsMap = (w['items106'] as Map?) ?? const {};
      for (final kind in const ['jugo', 'flan', 'queso', 'frutas']) {
        final where = itemsMap[kind] as String? ?? 'aparador';
        final NocheAt at;
        if (where == 'mesa') {
          final uv = _MESA_ITEM_UV[kind]!;
          at = _p.atWorld(
            (uv[0] + uv[1]) / _p.e.R2,
            (uv[1] - uv[0]) / _p.e.R2,
            uv[2],
          );
        } else {
          at = _p.at(kind);
        }
        final spr = switch (kind) {
          'jugo' => _spr('no_jugo', mkJugo),
          'flan' => _spr('no_flan', mkFlan),
          'queso' => _spr('no_queso', mkQueso),
          _ => _spr('no_frutas', mkFrutas),
        };
        final sx = _round(at.sx), sy = _round(at.sy);
        out.add(
          NocheItem(spr, sx - 5, sy - spr.h, sy, at.d, tag: 'cosa:$kind'),
        );
      }

      if (_n(w['velaVis']) == 1) {
        final at = _p.at('vela');
        final len = _n(w['vela']).clamp(1, 3);
        final lit = _n(w['velaLit']) == 1;
        final spr = _spr(
          'no_vela_${len}_$lit',
          () => mkVelaNoche(len: len, lit: lit),
        );
        final sx = _round(at.sx), sy = _round(at.sy);
        out.add(NocheItem(spr, sx - 3, sy - spr.h, sy, at.d, tag: 'cosa:vela'));
      }

      if (_n(w['mesaLampara']) == 1) {
        // OPEN: small table lamp brought by abuelo when final106 has n == 1 (stub candle), placed on TABLE left of vela.
        const u = 0.25, v = 5.9, z = 0.74;
        final at = _p.atWorld((u + v) / _p.e.R2, (v - u) / _p.e.R2, z);
        final spr = _spr('no_mesa_lampara', mkMesaLampara);
        final sx = _round(at.sx), sy = _round(at.sy);
        out.add(
          NocheItem(spr, sx - 4, sy - spr.h, sy, at.d, tag: 'fx:mesa_lampara'),
        );
      }
    }

    // 5. Transient story FX (cleared before act completion)
    final lfx = w['lanaFx'];
    if (lfx is Map) {
      final spr = _spr('no_lana_roll', () => mkLana(rolling: true));
      final fx = _n(lfx['x']), fy = _n(lfx['y']);
      out.add(NocheItem(spr, fx - 4, fy - spr.h, fy, 3.2, tag: 'fx:lana'));
    }

    final nfx = w['notaFx'];
    if (nfx is Map) {
      final spr = _spr('no_nota', mkNotaMusical);
      final fx = _n(nfx['x']), fy = _n(nfx['y']);
      out.add(
        NocheItem(
          spr,
          fx - 3,
          fy - spr.h,
          fy,
          6.0,
          tag: 'fx:nota',
          overlay: true,
        ),
      );
    }

    if (_n(w['tapaFx']) == 1) {
      final at = _p.at('vela');
      final spr = _spr('no_tapa_vapor', mkTapaVapor);
      out.add(
        NocheItem(
          spr,
          _round(at.sx) - 18,
          _round(at.sy) - 14,
          _round(at.sy),
          at.d + .05,
          tag: 'fx:tapa_vapor',
        ),
      );
    }

    final mfx = w['manosFx'];
    if (mfx is Map) {
      final clean = mfx['clean'] == true;
      final spr = _spr('no_manos_$clean', () => mkManosCue(clean: clean));
      out.add(
        NocheItem(
          spr,
          _n(mfx['x']) - 6,
          _n(mfx['y']) - 4,
          _n(mfx['y']),
          6.0,
          tag: 'fx:manos',
          overlay: true,
        ),
      );
    }

    if (_n(w['narizFx']) == 1) {
      const u = 1.5, v = 6.35, z = 0.74;
      final at = _p.atWorld((u + v) / _p.e.R2, (v - u) / _p.e.R2, z);
      final spr = _spr('no_perro_nariz', mkPerroNariz);
      out.add(
        NocheItem(
          spr,
          _round(at.sx) - 5,
          _round(at.sy) - spr.h,
          _round(at.sy),
          at.d + .05,
          tag: 'fx:nariz',
        ),
      );
    }

    final lp = _n(w['libroPics']);
    if (lp > 0) {
      const kinds = ['bote', 'estrella', 'rana'];
      for (var i = 0; i < lp.clamp(0, 3); i++) {
        final spr = _spr('no_pic_${kinds[i]}', () => mkLibroPic(kinds[i]));
        out.add(
          NocheItem(
            spr,
            34 + i * 14,
            56 - (i % 2) * 4,
            68,
            6.0,
            tag: 'fx:libro_pic_$i',
            overlay: true,
          ),
        );
      }
    }

    // 6. Celebrations for 3-of-3 endings (clear of heads, frog, and interactive things)
    if (_n(w['final105']) == 3) {
      final est = _spr('no_estrellas', mkEstrellasNoche);
      final cor = _spr('no_corazon', mkCorazonNoche);
      out.add(
        NocheItem(est, 174, 56, 64, 9.0, tag: 'fx:estrellas', overlay: true),
      );
      out.add(
        NocheItem(cor, 192, 56, 65, 9.0, tag: 'fx:corazon', overlay: true),
      );
    }
    if (_n(w['final106']) == 3) {
      final est = _spr('no_estrellas', mkEstrellasNoche);
      final cor = _spr('no_corazon', mkCorazonNoche);
      out.add(
        NocheItem(est, 162, 58, 66, 9.0, tag: 'fx:estrellas', overlay: true),
      );
      out.add(
        NocheItem(cor, 180, 58, 67, 9.0, tag: 'fx:corazon', overlay: true),
      );
    }
    if (_n(w['final107']) == 3) {
      final est = _spr('no_estrellas', mkEstrellasNoche);
      final cor = _spr('no_corazon', mkCorazonNoche);
      out.add(
        NocheItem(est, 174, 56, 64, 9.0, tag: 'fx:estrellas', overlay: true),
      );
      out.add(
        NocheItem(cor, 192, 56, 65, 9.0, tag: 'fx:corazon', overlay: true),
      );
    }

    return out;
  }

  static final Map<String, Sprite> _frogSprites = {};

  /// [items] plus the frog (as the host draws him), for `draw` and for `NocheRules`.
  List<NocheItem> placed(Map<String, dynamic> w, int a) {
    final out = items(w, a);
    final q = w['cq'] as Map<String, dynamic>?;
    if (q != null && jsTruthy(q['vis'])) {
      final b = host.frogBox(q);
      final at = _frogPoint(q);
      final dx = _n(q['dx']);
      final fsy = _round(at.sy);
      final ox = b.x.toInt() - 16 + dx;
      final oy = b.y.toInt() - 24;
      final fk =
          '${q['s']}_${b.x - (b.x.toInt() - 16)}_${b.y - oy}_${(q['y'] as num) - oy}_${((q['dy'] as num) + 0.5).floor()}_${host.F % 47 < 2 ? 1 : 0}_${((q['bub'] == 'hola' || _talker() == 'coqui') && a % 2 != 0) ? 1 : 0}';
      final spr = _frogSprites.putIfAbsent(fk, () {
        final px = Uint32List(64 * 64);
        final g = Ctx(px, 64, 64)
          ..translate(-(b.x.toInt() - 16).toDouble(), -oy.toDouble());
        host.frog(g, q, a);
        return Sprite(64, 64, px);
      });
      out.add(NocheItem(spr, ox, oy, fsy, at.d, tag: 'coqui'));
      final cqBuf = _n(w['cqBufanda']);
      if (cqBuf > 0) {
        final bs = _spr(
          'no_buf_cuello_$cqBuf',
          () => mkBufandaCuello(stripes: cqBuf),
        );
        out.add(
          NocheItem(
            bs,
            _round(b.x + b.w / 2) - 9,
            _round(b.y + b.h) - 10,
            fsy,
            at.d + .02,
            tag: 'fx:bufanda_cuello',
          ),
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
    // La noche has no swaying foliage: baked depth matches noche-preview.html `window.DEPTH.z`.
    _setZ = baked.zb;
  }

  static final double _t30 = math.tan(math.pi / 6);

  void _put(
    NocheItem it,
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
      final plane = it.overlay
          ? it.d
          : (it.lying
                ? (((Y + .5) - _p.e.OY + it.lyingZ * 22.5) / (_p.e.S / 2)) *
                          _p.e.COS +
                      it.lyingZ * .5
                : it.d + (it.sy - (Y + .5)) * _t30 / S);
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
    if (p != null && p['vis'] != 0) {
      final at = _atOf(p);
      if (_n(p['lying']) == 1) {
        return [_round(at.sx), math.max(12, _round(at.sy) + 14)];
      }
      final sent = _n(p['sent']) == 1;
      final isKid = who == 'luis' || who == 'carmen';
      final dy = sent ? (isKid ? 34 : 42) : (isKid ? 42 : 52);
      return [_round(at.sx), _round(at.sy) - dy];
    }
    return null;
  }

  /* ---------- touch things & hit testing ---------- */

  static List<int>? _itemBox(
    List<NocheItem> list,
    bool Function(NocheItem) test,
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
      _itemBox(placed(w, 0), (it) => it.tag == tag);

  List<int> _heldBox(String name, int bw, int bh) {
    final meta = _p.heldOffset(name);
    final at = _p.at(meta.on);
    final sx = _round(at.sx) + meta.dx;
    final sy = _round(at.sy) + meta.dy;
    return [sx - bw ~/ 2, sy - bh, bw, bh];
  }

  List<Thing> _things() => [
    // Small interactive props & set fixtures
    Thing(
      id: 'bufanda',
      si: (w) => _n(w['story']) == 105 && _n(w['bufandaVis']) == 1,
      box: (w) => _spriteBox(w, 'cosa:bufanda') ?? _heldBox('bufanda', 12, 8),
    ),
    Thing(
      id: 'lana',
      si: (w) => _n(w['story']) == 105,
      box: (w) => _heldBox('lana', 8, 8),
    ),
    Thing(
      id: 'libro',
      si: (w) => _n(w['story']) == 107,
      box: (w) => _spriteBox(w, 'cosa:libro') ?? _heldBox('libro', 12, 8),
    ),
    for (final kind in const ['jugo', 'flan', 'queso', 'frutas'])
      Thing(
        id: kind,
        si: (w) => _n(w['story']) == 106,
        box: (w) => _spriteBox(w, 'cosa:$kind') ?? _p.spotBox(kind),
      ),
    Thing(
      id: 'vela',
      si: (w) => _n(w['story']) == 106 && _n(w['velaVis']) == 1,
      box: (w) => _spriteBox(w, 'cosa:vela') ?? _p.spotBox('vela'),
    ),
    Thing(id: 'television', box: (w) => _p.box('television')),
    Thing(id: 'luz1', box: (w) => _p.box('luz1')),
    Thing(id: 'luz2', box: (w) => _p.box('luz2')),
    Thing(id: 'luz3', box: (w) => _p.box('luz3')),
    Thing(id: 'reloj', box: (w) => _p.box('reloj')),
    // OPEN: noche-sheet.json has no box for `manos_luis`; derived around Luis's hands when visible.
    Thing(
      id: 'manos_luis',
      si: (w) {
        final p = (w['gente'] as Map?)?['luis'];
        return p is Map && p['vis'] != 0;
      },
      box: (w) {
        final b = _spriteBox(w, 'persona:luis');
        if (b == null) return null;
        return [b[0].toInt() + 14, b[1].toInt() + 18, 20, 12];
      },
    ),
    // Furniture targets for 106 & 107 (`mesa`, `aparador`, `cama`, `sofa`)
    Thing(
      id: 'mesa',
      si: (w) => _n(w['mesa']) == 1,
      box: (w) => _p.box('mesa'),
    ),
    Thing(id: 'aparador', box: (w) => _p.box('aparador')),
    // OPEN: noche-sheet.json has no box for `bandeja`; placed on the sideboard beside aparador_coqui in 106.
    Thing(
      id: 'bandeja',
      si: (w) => _n(w['story']) == 106,
      box: (w) => const [174, 41, 38, 12],
    ),
    Thing(id: 'cama', box: (w) => _p.box('cama')),
    Thing(id: 'sofa', box: (w) => _p.box('sofa')),
    // People
    for (final who in NOCHE_PERSONAS)
      Thing(
        id: who,
        si: (w) {
          final p = (w['gente'] as Map?)?[who];
          return p is Map && p['vis'] != 0;
        },
        box: (w) => _spriteBox(w, 'persona:$who'),
      ),
  ];

  @override
  String? hit(num x, num y, Map<String, dynamic> w) {
    // Check frog first when visible so nothing steals a frog tap.
    final q = w['cq'] as Map<String, dynamic>?;
    if (q != null && jsTruthy(q['vis'])) {
      final fb = host.frogBox(q);
      if (x >= fb.x && x < fb.x + fb.w && y >= fb.y && y < fb.y + fb.h) {
        return 'coqui';
      }
    }
    for (final t in cosas) {
      if (t.si != null && !t.si!(w)) continue;
      final b = box(t.id, w);
      if (b == null) continue;
      if (x >= b[0] && x < b[0] + b[2] && y >= b[1] && y < b[1] + b[3]) {
        return t.id;
      }
    }
    return null;
  }

  /* ---------- loose acts (`suelto: 1` / `ya`) ---------- */

  final List<Future<void>> _loose = [];

  Future<void> _run(Map<String, dynamic> o, Future<void> Function() body) {
    if (jsTruthy(o['suelto'])) {
      final f = body();
      _loose.add(f);
      return Future<void>.value();
    }
    return body();
  }

  @override
  List<num> remap(List<num> xy) => xy;

  @override
  Future<void> stake(int lost, int max, String en) async {}

  Future<void> _moveFrogTo(String rawSpot) async {
    final spot = _resolveSpot(rawSpot);
    if (!_p.hasWorld(spot)) return;
    final at = _p.at(spot);
    final q = W['cq'] as Map<String, dynamic>;
    final dest = _frogAt(at);
    final sx = (q['x'] as num).toDouble(), sy = (q['y'] as num).toDouble();
    final dx = dest[0].toDouble() - sx, dy = dest[1].toDouble() - sy;
    final dist = math.sqrt(dx * dx + dy * dy);
    if (dist >= 2) {
      final steps = (dist / 18).ceil().clamp(1, 5);
      for (var i = 1; i <= steps; i++) {
        final t = i / steps;
        q['x'] = _round(sx + dx * t);
        q['y'] = _round(sy + dy * t);
        q['dy'] = i < steps ? -4 : 0;
        await wait(70);
      }
    }
    q['x'] = dest[0];
    q['y'] = dest[1];
    q['dy'] = 0;
    q['z'] = at.z;
    q['spot'] = spot;
  }

  /* ---------- acts (noche.md "Needs" + gen_noche.py) ---------- */

  @override
  Map<String, Act> get ownActs => {
    'ya': (o) async {
      while (_loose.isNotEmpty) {
        final batch = List<Future<void>>.from(_loose);
        _loose.clear();
        await Future.wait(batch);
      }
    },
    'brilla': (o) async {
      W['twinkle'] = o['a'] ?? o['que'] ?? o['en'];
      await wait(120);
    },
    'ir': (o) => _run(o, () async {
      final spot = (o['a'] as String?) ?? 'brazo_coqui';
      await _moveFrogTo(spot);
    }),
    'llega': (o) => _run(o, () async {
      final quien = (o['quien'] as String?) ?? 'luis';
      final rawSpot = (o['a'] as String?) ?? 'alfombra1';
      final spot = _resolveSpot(rawSpot);
      if (!_p.hasWorld(spot)) return;
      _placePerson(quien, spot);
      await wait(160);
    }),
    'sale': (o) => _run(o, () async {
      final quien = (o['quien'] as String?) ?? 'luis';
      final p = _gente[quien];
      if (p is Map<String, dynamic>) {
        p['vis'] = 0;
      }
      await wait(120);
    }),

    /* ----- Story 105 acts ----- */
    'luces105': (o) => _run(o, () async {
      W['luz1'] = _n(o['a']) == 1 ? 1 : 0;
      W['luz2'] = _n(o['b']) == 1 ? 1 : 0;
      W['luz3'] = _n(o['c']) == 1 ? 1 : 0;
      await wait(120);
    }),
    'tele105': (o) => _run(o, () async {
      final on = _n(o['on']) == 1 ? 1 : 0;
      W['tele'] = on;
      if (on == 1) {
        final tb = _p.box('television');
        W['notaFx'] = {'x': tb[0] + tb[2] ~/ 2, 'y': tb[1] - 4};
        await wait(240);
        W['notaFx'] = null;
      } else {
        await wait(140);
      }
    }),
    'luz105': (o) => _run(o, () async {
      final cual = (o['cual'] as String?) ?? 'luz1';
      final ok = _n(o['ok']) == 1;
      if (const ['luz1', 'luz2', 'luz3'].contains(cual)) {
        W[cual] = _n(W[cual]) == 1 ? 0 : 1;
      }
      await wait(160);
      if (!ok) {
        if (_n(W[cual]) == 0) {
          // Lamp put out wrongly: abuela drops stitches in the dark.
          final ab = _gente['abuela'] as Map<String, dynamic>?;
          if (ab != null) {
            for (final dx in const [-1, 1, -1, 0]) {
              ab['dx'] = dx;
              await wait(60);
            }
            ab['dx'] = 0;
          }
        } else {
          // Lamp lit wrongly: abuelo starts and knocks the wool off abuela's lap.
          final abo = _gente['abuelo'] as Map<String, dynamic>?;
          if (abo != null) {
            abo['dy'] = -2;
            await wait(70);
            abo['dy'] = 0;
          }
          final ba = _p.at('butaca');
          W['lanaFx'] = {'x': _round(ba.sx) - 10, 'y': _round(ba.sy) + 12};
          await wait(180);
          W['lanaFx'] = null;
        }
      }
    }),
    'vuelve105': (o) => _run(o, () async {
      final cual = (o['cual'] as String?) ?? 'luz1';
      if (const ['luz1', 'luz2', 'luz3'].contains(cual)) {
        W[cual] = _n(W[cual]) == 1 ? 0 : 1;
      }
      await wait(160);
    }),
    'bufanda': (o) => _run(o, () async {
      W['bufanda'] = _n(o['n']).clamp(1, 3);
      await wait(140);
    }),
    'final105': (o) => _run(o, () async {
      final n = _n(o['n']).clamp(1, 3);
      W['bufanda'] = n;
      W['bufandaVis'] = 0;
      W['cqBufanda'] = n;
      W['final105'] = n;
      await wait(320);
    }),

    /* ----- Story 106 acts ----- */
    'tapa106': (o) => _run(o, () async {
      W['tapaFx'] = 1;
      await wait(240);
      W['tapaFx'] = 0;
    }),
    'manos106': (o) => _run(o, () async {
      final luis = _gente['luis'] as Map<String, dynamic>?;
      if (luis != null) {
        final la = _atOf(luis);
        W['manosFx'] = {
          'clean': false,
          'x': _round(la.sx),
          'y': _round(la.sy) - 24,
        };
        await wait(140);
        W['manosFx'] = null;
        luis['vis'] = 0;
        await wait(140);
        luis['vis'] = 1;
        W['manosLimpias'] = 1;
        W['manosFx'] = {
          'clean': true,
          'x': _round(la.sx),
          'y': _round(la.sy) - 24,
        };
        await wait(160);
        W['manosFx'] = null;
      } else {
        await wait(160);
      }
    }),
    'perro106': (o) => _run(o, () async {
      // OPEN: noche-sheet.json has no table-edge spot for Canelo; place at floor (u 3.10, v 6.45, z 0)
      // beside the table's right corner, >= 12 px below silla4 and >= 24 px from junto_mesa, inside [22, 218).
      final p = _gente['perro'] as Map<String, dynamic>?;
      if (p != null) {
        const u = 3.10, v = 6.45;
        final at = _p.atWorld((u + v) / _p.e.R2, (v - u) / _p.e.R2, 0);
        p['x'] = at.x;
        p['y'] = at.y;
        p['z'] = 0.0;
        p['spot'] = 'perro';
        p['pose'] = 'bark';
        p['vis'] = 1;
      }
      await wait(220);
    }),
    'vela106': (o) => _run(o, () async {
      W['velaVis'] = 1;
      W['velaLit'] = 1;
      await wait(180);
    }),
    'vela': (o) => _run(o, () async {
      W['velaVis'] = 1;
      W['vela'] = _n(o['n']).clamp(1, 3);
      await wait(140);
    }),
    'lleva106': (o) => _run(o, () async {
      final que = (o['que'] as String?) ?? 'queso';
      final a = (o['a'] as String?) == 'mesa' ? 'mesa' : 'aparador';
      final ok = _n(o['ok']) == 1;
      final itemsMap = (W['items106'] as Map<String, String>?) ?? {};
      itemsMap[que] = a;
      W['items106'] = itemsMap;
      await wait(180);
      if (!ok) {
        // Abuela turns to look while candle burns down.
        final ab = _gente['abuela'] as Map<String, dynamic>?;
        if (ab != null) {
          ab['pose'] = 'senala';
          await wait(180);
          ab['pose'] = 'idle';
        }
      }
    }),
    'final106': (o) => _run(o, () async {
      final n = _n(o['n']).clamp(1, 3);
      W['vela'] = n;
      W['velaLit'] = 1;
      W['final106'] = n;
      W['mesaLampara'] = n == 1 ? 1 : 0;
      _placePerson('abuela', 'silla1');
      _placePerson('luis', 'silla2');
      _placePerson('carmen', 'silla3');
      _placePerson('abuelo', 'silla4');
      await _moveFrogTo('mesa_coqui');
      await wait(280);
    }),
    'nariz106': (o) => _run(o, () async {
      W['narizFx'] = 1;
      await wait(240);
      W['narizFx'] = 0;
    }),

    /* ----- Story 107 acts ----- */
    'reloj107': (o) => _run(o, () async {
      W['relojHora'] = _n(o['hora']) > 0 ? _n(o['hora']) : 8;
      await wait(140);
    }),
    'acuesta107': (o) => _run(o, () async {
      final quien = (o['quien'] as String?) ?? 'carmen';
      final ok = _n(o['ok']) == 1;
      final spot = quien == 'luis' ? 'cama1' : 'cama2';
      _placePerson(quien, spot, sentOverride: 0, lying: 1);
      await wait(200);
      if (!ok) {
        final ab = _gente['abuela'] as Map<String, dynamic>?;
        if (ab != null) {
          ab['pose'] = 'senala';
          await wait(140);
          ab['pose'] = 'idle';
        }
      }
    }),
    'descansa107': (o) => _run(o, () async {
      final quien = (o['quien'] as String?) ?? 'abuelo';
      final ok = _n(o['ok']) == 1;
      if (quien == 'abuelo') {
        _placePerson('abuelo', 'sofa1', sentOverride: 1, lying: 0);
      } else {
        final a = (o['a'] as String?) ?? 'sofa_pies';
        final resolved = _resolveSpot(a);
        // OPEN: noche-sheet.json places brazo_coqui (153,85) 17 px from sofa3 (136,91); hop frog to
        // aparador_coqui before seating a second child on sofa3 so frog-seen and sprites-apart hold.
        if (resolved == 'sofa3' &&
            (W['cq'] as Map?)?['spot'] == 'brazo_coqui') {
          await _moveFrogTo('aparador_coqui');
        }
        _placePerson(quien, a, sentOverride: 1, lying: 0);
      }
      await wait(200);
      if (!ok) {
        final ab = _gente['abuela'] as Map<String, dynamic>?;
        if (ab != null) {
          ab['pose'] = 'senala';
          await wait(140);
          ab['pose'] = 'idle';
        }
      }
    }),
    'levantados107': (o) => _run(o, () async {
      _placePerson('luis', 'alfombra1', sentOverride: 0, lying: 0);
      _placePerson('carmen', 'alfombra2', sentOverride: 0, lying: 0);
      _placePerson('abuelo', 'sofa1', sentOverride: 1, lying: 0, pose: 'zzz');
      await wait(200);
    }),
    'paginas': (o) => _run(o, () async {
      W['paginas'] = _n(o['n']).clamp(1, 3);
      await wait(140);
    }),
    'final107': (o) => _run(o, () async {
      final n = _n(o['n']).clamp(1, 3);
      W['paginas'] = n;
      W['final107'] = n;
      _placePerson('luis', 'cama1', sentOverride: 0, lying: 1);
      _placePerson('carmen', 'cama2', sentOverride: 0, lying: 1);
      W['libroPics'] = n;
      await wait(320);
      W['libroPics'] = 0;
    }),
    'canta107': (o) => _run(o, () async {
      final q = W['cq'] as Map<String, dynamic>;
      final b = host.frogBox(q);
      W['notaFx'] = {'x': _round(b.x + b.w / 2), 'y': _round(b.y) - 6};
      await wait(260);
      W['notaFx'] = null;
    }),

    /* ----- Shared gestures & engine acts ----- */
    'gesto': (o) => _run(o, () async {
      final quien = (o['quien'] as String?) ?? 'abuela';
      final que = (o['que'] as String?) ?? 'saluda';
      if (quien == 'coqui') {
        final q = W['cq'] as Map<String, dynamic>;
        for (final dy in const [-3, 0, -3, 0]) {
          q['dy'] = dy;
          await wait(65);
        }
        q['dy'] = 0;
        return;
      }
      final p = _gente[quien] as Map<String, dynamic>?;
      if (p == null || p['vis'] == 0) return;
      if (que == 'saluda') {
        for (var i = 0; i < 4; i++) {
          p['pose'] = i % 2 == 0 ? 'saluda0' : 'saluda1';
          await wait(80);
        }
        p['pose'] = 'idle';
      } else if (que == 'no') {
        for (final dx in const [-1, 1, -1, 0]) {
          p['dx'] = dx;
          await wait(65);
        }
        p['dx'] = 0;
      } else if (que == 'si') {
        for (final dy in const [1, 0, 1, 0]) {
          p['dy'] = dy;
          await wait(65);
        }
        p['dy'] = 0;
      } else if (que == 'teje' || que == 'dobla' || que == 'palmas') {
        p['pose'] = que;
        for (final dy in const [1, 0, 1, 0]) {
          p['dy'] = dy;
          await wait(65);
        }
        p['dy'] = 0;
        p['pose'] = 'idle';
      } else if (que == 'entorna') {
        for (final dx in const [1, 0, 1, 0]) {
          p['dx'] = dx;
          await wait(60);
        }
        p['dx'] = 0;
      } else {
        // rie, mira, senala, bosteza, manos
        p['pose'] = que;
        await wait(220);
        p['pose'] = 'idle';
      }
    }),
    'marca': (o) async {
      final m = W['marcas'];
      if (m is List) {
        final i = m.indexOf(null);
        if (i >= 0) m[i] = o['que'];
      }
      await wait(120);
    },
    'fin': (o) async {
      final q = W['cq'] as Map<String, dynamic>;
      for (final dy in const [-4, -6, -3, 0]) {
        q['dy'] = dy;
        await wait(50);
      }
      await wait(200);
    },
  };
}
