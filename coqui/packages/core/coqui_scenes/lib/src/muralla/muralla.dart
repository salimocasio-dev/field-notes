// La muralla (place 10, El fuerte, scene 4: `muralla`; stories 117 to 119): a NEW scene, written from its
// script's "Needs" list (historia/notas/guiones/muralla.md) on its set (muralla_set.dart) and its sheet
// (muralla-sheet.json, read by SceneSheet). Every act is in muralla_acts.dart; where the sheet leaves a detail
// open or two characters would collide, the code keeps the story playing clearly and marks it `OPEN:`.
//
// Drawing rules (the sheet's `front` & `rules`):
// - `decor.cuerda` (1 px cord) is drawn behind every sprite and every baked set pixel (`setZ <= -1e8`, `lz = -50`).
// - Hanging lanterns (`farol1..3`) anchor top-middle (`(5, 0)`) at their cord spots.
// - Far-road sprites (`guagua`, `guagua_se_va`, `musico_lejos1..2`) use `farD(sy)` so the set parapet hides them.
// - Whoever stands inside a sentry box with its door open (`dentro_roja`/`dentro_azul`) is drawn from `topInk` 2 px
//   below the door box top (`dy`), clipped to `things.puerta_*.box`, over `mkDoorOpen`.
// - All other characters anchor `(PX, inkBottom)` (standing) or `(PX, 16 + 2 * t + 3)` (sitting); `abuela` anchors
//   `(30, inkBottom)`.
// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/src/muralla/muralla_places.dart';
import 'package:coqui_scenes/src/muralla/muralla_set.dart';
import 'package:coqui_scenes/src/muralla/muralla_sprites.dart';
import 'package:coqui_scenes/src/scene_set.dart';
import 'package:coqui_scenes/src/sheet_cache.dart';

part 'muralla_acts.dart';

/// The scene "La muralla", made from its sheet (read first: `loadScene`).
Scene createMuralla() => Muralla(sceneSheetOf('muralla'));

int _round(num v) => (v + 0.5).floor();

int _n(Object? v) {
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? 0;
  return 0;
}

/// One sprite placed on the 240 × 216 picture, with optional door [clipBox] and head-down offset [dy].
class MurallaItem {
  MurallaItem(
    this.s,
    this.left,
    this.top,
    this.sy,
    this.d, {
    this.tag,
    this.overlay = false,
    this.clipBox,
    this.dy = 0,
  });

  final Sprite s;
  final int left, top;
  final num sy;
  final double d;
  final String? tag;
  final bool overlay;
  final List<int>? clipBox;
  final int dy;
}

/// Every cast key in La muralla.
const List<String> MURALLA_PERSONAS = [
  'abuela',
  'abuelo',
  'luis',
  'carmen',
  'musico1',
  'musico2',
  'pepe',
  'maestra',
  'piraguero',
  'senor',
  'senora',
];

const Set<String> _childKeys = {'luis', 'carmen'};

/// Needs things in `muralla.md` (`coqui` is handled directly in [hit]).
const List<String> MURALLA_COSAS = [
  'puerta_roja',
  'puerta_azul',
  'camara',
  'silla',
  'jugo',
  'plato',
  'vela',
  'guitarra',
  'sombrero',
  'bolsa',
  'caja',
  'libro',
  'banco',
  'escalera',
  'farol1',
  'farol2',
  'farol3',
  'guagua',
  ...MURALLA_PERSONAS,
];

/// La muralla scene (place 10, El fuerte, scene 4, order 77).
class Muralla extends Escena implements SetScene, SetOverSprites {
  Muralla(this.ss) : sheet = ss.legacy() {
    places = MurallaPlaces(ss);
    _p = places;
    CAM = {'wide': _p.view('wide')};
    LUGAR = {
      for (final en in ss.spots.entries)
        if (en.value.world != null) en.key: _frogAt(_p.at(en.key)),
      'centro8': _frogAt(_p.at('centro8')),
    };
    cosas = _things();
  }

  /// The new scene's sheet (SceneSheet).
  final SceneSheet ss;

  @override
  final Sheet sheet;

  /// The scene's typed places.
  late final MurallaPlaces places;
  late final MurallaPlaces _p;

  @override
  String get id => 'muralla';

  String get setId => 'muralla';

  @override
  late final Map<String, List<num>> CAM;

  @override
  Map<String, List<num>> get lugar => LUGAR;
  late final Map<String, List<num>> LUGAR;

  @override
  late final List<Thing> cosas;

  bool get hasOverSprites => true;

  @override
  PpEngine newEngine({bool still = false}) => murallaEngine(still: still);

  @override
  PpEngine get projection => _p.e;

  PpEngine setEngine() => murallaEngine();

  @override
  bool get frogShadow => false;

  Map<String, dynamic> get W => host.W;
  int get F => host.F;
  int get TICK => host.TICK;
  Future<void> wait(num ms) => host.wait(ms);

  @override
  String setKey(Map<String, dynamic> W) =>
      W['hora'] == 'tarde_noche' ? 'tarde_noche' : 'noche';

  @override
  void buildSet(PpEngine e, PpBuild b, Map<String, dynamic> W) =>
      buildSetFor(e, b, setKey(W));

  final Map<PpEngine, MurallaSet> _sets = {};

  @override
  void buildSetFor(PpEngine e, PpBuild b, String key) =>
      _setFor(e, b).buildSet(MurallaState.fromKey(key));

  MurallaSet _setFor(PpEngine e, PpBuild b) =>
      _sets.putIfAbsent(e, () => MurallaSet(e, b));

  List<num> view(Map<String, dynamic> W) => _p.view('wide');

  @override
  List<num> remap(List<num> xy) => xy;

  @override
  Future<void> stake(int lost, int max, String en) async {}

  @override
  Map<String, Act> get ownActs => _buildOwnActs();

  void prewarm(Map<String, dynamic> W) {
    final sNum = _storyNum(W);
    for (final who in const ['abuela', 'abuelo', 'luis', 'carmen']) {
      _personSprite(who, const {'pose': 'idle'}, false, sNum, 0);
    }
  }

  @override
  List<ShadowCast> shadows(Map<String, dynamic> W) {
    final out = <ShadowCast>[];
    final gente = (W['gente'] as Map<String, dynamic>?) ?? const {};
    for (final en in gente.entries) {
      final p = en.value as Map<String, dynamic>;
      if (!jsTruthy(p['vis']) || jsTruthy(p['sent'])) continue;
      final spot = p['spot'] as String?;
      if (spot != null && (_p.noShadow(spot) || _p.isPxSpot(spot))) continue;
      if (((p['z'] as num?) ?? 0) > 0.001) continue;
      final r = _p.radius(en.key, isChild: _childKeys.contains(en.key));
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
      final qs = q['s'];
      final qspot = q['spot'] as String?;
      final onFloor =
          qspot != null &&
          !_p.noShadow(qspot) &&
          ((q['z'] as num?) ?? 0) <= 0.001;
      if (qs is num && !onFloor == false) {
        final at = _frogPoint(q);
        final r = _p.radius('coqui');
        if (r != null) out.add((x: at.x, y: at.y, z: 0.0, r: r));
      }
    }
    return out;
  }

  @override
  Map<String, dynamic> fresh([Map<String, dynamic>? story]) {
    final gente = <String, dynamic>{
      for (final who in MURALLA_PERSONAS)
        who: {
          'vis': 0,
          'x': 0.0,
          'y': 0.0,
          'z': 0.0,
          'spot': null,
          'pose': 'idle',
          'sent': 0,
          'dx': 0,
          'dy': 0,
        },
    };
    final storyId = story?['id'] as String? ?? '';
    final storyNum = switch (storyId) {
      'todos-en-la-foto' => 117,
      'por-que-no-bailas' => 118,
      'nos-vemos' => 119,
      _ => _storyNumFromBeats(story),
    };
    final hora = storyNum == 119 ? 'tarde_noche' : 'noche';
    final startSpot = switch (storyNum) {
      118 => 'mesa_coqui',
      119 => 'junto_mesa_coqui',
      _ => 'junto_camara',
    };
    final sat = _p.at(startSpot);
    final sq = _frogAt(sat);
    return {
      'story': storyNum,
      'hora': hora,
      'gente': gente,
      'cq': <String, dynamic>{
        'vis': 1,
        's': 1,
        'dx': 0,
        'dy': 0,
        'al': 1,
        'x': sq[0],
        'y': sq[1],
        'z': sat.z,
        'spot': startSpot,
        'bub': null,
      },
      'faroles': 3,
      'farolPresent': [1, 1, 1],
      'farolLit': [1, 1, 1],
      'farolSwing': 0,
      'redDoorOpen': 0,
      'blueDoorOpen': 0,
      'palomaLedge': 0,
      'pigeonBurst': 0,
      'vientoDark': 0,
      'fotoFx': 0,
      'flashFx': 0,
      'final117': 0,
      'aros': 3,
      'jugoAt': storyNum == 118 ? 'mesa' : null,
      'platoAt': storyNum == 118 ? 'mesa' : null,
      'sillaAt': storyNum == 118 ? 'mesa' : null,
      'mu1Guitar': storyNum == 118 ? 1 : 0,
      'mu1GuitarLift': 0,
      'mu2Drum': storyNum == 118 || storyNum == 119 ? 1 : 0,
      'notaFx': null,
      'final118': 0,
      'caras': 0,
      'guaguaVis': storyNum == 119 ? 1 : 0,
      'guaguaGone': 0,
      'guaguaDoorOpen': 1,
      'guaguaBlink': 0,
      'muLejosVis': 0,
      'guitarraMesa': storyNum == 119 ? 1 : 0,
      'items119': storyNum == 119
          ? <String, String>{
              'sombrero': 'mesa',
              'bolsa': 'mesa',
              'caja': 'mesa',
              'libro': 'mesa',
            }
          : <String, String>{},
      'hugItem': <String, String>{},
      'fanWho': <String, int>{},
      'plateWho': <String, int>{},
      'legUpWho': 0,
      'missedGuests': <String>[],
      'final119': 0,
      'tarjeta': null,
      'marcas': null,
      'talkAt': <String, dynamic>{},
    };
  }

  int _storyNumFromBeats(Map<String, dynamic>? story) {
    final beats = story?['beats'];
    if (beats is List && beats.isNotEmpty && beats.first is Map) {
      final s = (beats.first as Map)['set'];
      if (s is Map && s['hora'] == 'tarde_noche') return 119;
    }
    return 117;
  }

  int _storyNum(Map<String, dynamic> w) => _n(w['story']);

  /* ---------- Host / frog helpers ---------- */

  Map<String, dynamic> get _gente =>
      (W['gente'] ??= <String, dynamic>{}) as Map<String, dynamic>;

  Map<String, dynamic> _person(String who) =>
      (_gente[who] ??= <String, dynamic>{}) as Map<String, dynamic>;

  List<double> _frogAt(MurallaAt at) => [
    _round(at.sx) - 16.0,
    _round(at.sy) - 25.0,
    1.0,
  ];

  void _setFrogSpot(String spot) {
    final at = _p.at(spot);
    final L = _frogAt(at);
    final q = W['cq'] as Map<String, dynamic>;
    q['vis'] = 1;
    q['x'] = L[0];
    q['y'] = L[1];
    q['z'] = at.z;
    q['spot'] = spot;
    q['s'] = 1;
    q['dx'] = 0;
    q['dy'] = 0;
  }

  MurallaAt _frogPoint(Map<String, dynamic> q) {
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

  MurallaAt _atOf(Map<String, dynamic> p) {
    final spot = p['spot'];
    if (spot is String && _p.isPxSpot(spot)) {
      return _p.at(spot);
    }
    return _p.atWorld(p['x'] as num, p['y'] as num, p['z'] as num);
  }

  /* ---------- sprites ---------- */

  static final Map<String, Sprite> _sprites = {};
  static Sprite _spr(String key, Sprite Function() make) =>
      _sprites[key] ??= make();

  static int _inkTop(Sprite s) {
    for (var y = 0; y < s.h; y++) {
      for (var x = 0; x < s.w; x++) {
        if (s.px[y * s.w + x] >>> 24 != 0) return y;
      }
    }
    return 0;
  }

  ({Sprite s, int ax, int ay}) _personSprite(
    String id,
    Map<String, dynamic> p,
    bool open,
    int storyNum,
    int a, {
    Map<String, dynamic>? w,
  }) {
    final stateW = w ?? W;
    final pose = (p['pose'] as String?) ?? 'idle';
    final sent = _n(p['sent']) == 1;
    if (id == 'abuela') {
      final abPose = switch (pose) {
        'saluda0' || 'saluda1' => 'saluda0',
        'senala' => 'tu',
        'rie' || 'palmas' => 'yo',
        'mano' => 'offer',
        'beso' => 'idle',
        _ => 'idle',
      };
      var s = _spr('mu_ab_${abPose}_$open', () => mkAbuela(abPose, open));
      final hugMap = (stateW['hugItem'] as Map?) ?? const {};
      final hug = hugMap[id] as String?;
      final legUp =
          _n(stateW['legUpWho']) == 1 &&
          (p['spot'] as String? ?? '').startsWith('baile');
      if (pose == 'beso' || legUp || hug != null) {
        s = _spr(
          'mu_ab_ex_${abPose}_${open}_${pose == 'beso'}_${legUp}_$hug',
          () => mkPersonaMurallaExtra(
            s,
            kiss: pose == 'beso',
            legUp: legUp,
            hugItem: hug,
          ),
        );
      }
      return (s: s, ax: 30, ay: murallaInkBottom(s));
    }

    final who = MURALLA_WHO[id] ?? MURALLA_WHO['abuelo']!;
    final kp = switch (pose) {
      'saluda0' => 'wave0',
      'saluda1' => 'wave1',
      'senala' => 'tu',
      'rie' || 'boca' || 'cuenta' || 'hombro' => 'yo',
      'mano' => 'offer',
      _ => 'idle',
    };
    final hat = id == 'musico1';
    final drum = id == 'musico2' && _n(stateW['mu2Drum']) == 1;
    final guitarLift = id == 'musico1' && _n(stateW['mu1GuitarLift']) == 1;
    final guitarCarry =
        id == 'musico1' && _n(stateW['mu1Guitar']) == 1 && !guitarLift;
    final tongue = pose == 'lengua';
    final belly = pose == 'barriga';
    final fanMap = (stateW['fanWho'] as Map?) ?? const {};
    final fan = _n(fanMap[id]) == 1 || pose == 'abanico';
    final hugMap = (stateW['hugItem'] as Map?) ?? const {};
    final hug = hugMap[id] as String?;
    final plateMap = (stateW['plateWho'] as Map?) ?? const {};
    final plate = _n(plateMap[id]) == 1;
    final legUp =
        _n(stateW['legUpWho']) == 1 &&
        (p['spot'] as String? ?? '').startsWith('baile');
    final s = _spr(
      'mu_${id}_${kp}_${open}_${sent}_${hat}_${drum}_${guitarLift}_${guitarCarry}_${tongue}_${belly}_${fan ? a % 2 : -1}_${hug}_${plate}_$legUp',
      () => mkPersonaMurallaExtra(
        mkPersona(who, kp, open, sent),
        hat: hat,
        drum: drum,
        guitar: guitarCarry,
        guitarLift: guitarLift,
        plateInHand: plate,
        tongue: tongue,
        belly: belly,
        legUp: legUp,
        fan: fan,
        fanPhase: a % 2,
        hugItem: hug,
      ),
    );
    final ay = sent ? (16 + 2 * (who.nino ? 7 : 11) + 3) : murallaInkBottom(s);
    return (s: s, ax: PX, ay: ay);
  }

  String? _talker() {
    try {
      return host.TALK;
    } catch (_) {
      return null;
    }
  }

  /// Every sprite of frame [w] as placed on screen. `MurallaRules` inspects this list; [draw] renders it.
  List<MurallaItem> items(Map<String, dynamic> w, int a) {
    final out = <MurallaItem>[];
    final talk = _talker();
    final storyNum = _n(w['story']);
    final gente = (w['gente'] as Map<String, dynamic>?) ?? const {};

    // 1. Open sentry-box doors drawn behind anyone inside
    if (_n(w['redDoorOpen']) == 1) {
      final box = _p.box('puerta_roja');
      final at = _p.at('dentro_roja');
      final sx = _round(at.sx), sy = _round(at.sy);
      final spr = _spr(
        'mu_door_roja',
        () => mkDoorOpen(box[2], box[3], _p.doorColour('puerta_roja')),
      );
      out.add(
        MurallaItem(
          spr,
          sx - box[2] ~/ 2,
          sy - box[3],
          sy,
          at.d,
          tag: 'fx:puerta_roja_open',
        ),
      );
    }
    if (_n(w['blueDoorOpen']) == 1) {
      final box = _p.box('puerta_azul');
      final at = _p.at('dentro_azul');
      final sx = _round(at.sx), sy = _round(at.sy);
      final spr = _spr(
        'mu_door_azul',
        () => mkDoorOpen(box[2], box[3], _p.doorColour('puerta_azul')),
      );
      out.add(
        MurallaItem(
          spr,
          sx - box[2] ~/ 2,
          sy - box[3],
          sy,
          at.d,
          tag: 'fx:puerta_azul_open',
        ),
      );
    }

    // 2. Far road (guagua & two walking músicos in story 119)
    if (_n(w['guaguaVis']) == 1) {
      final gone = _n(w['guaguaGone']) == 1;
      final at = _p.at(gone ? 'guagua_se_va' : 'guagua');
      final openDoor = _n(w['guaguaDoorOpen']) != 0;
      final blink = _n(w['guaguaBlink']) == 1 && (a % 2 == 0);
      final faces = _n(w['caras']).clamp(0, 4);
      final spr = _spr(
        'mu_guagua_${openDoor}_${blink}_$faces',
        () => mkGuagua(openDoor: openDoor, blink: blink, faces: faces),
      );
      final sx = _round(at.sx), sy = _round(at.sy);
      out.add(
        MurallaItem(spr, sx - 11, sy - spr.h, sy, at.d, tag: 'cosa:guagua'),
      );
    }
    if (_n(w['muLejosVis']) == 1) {
      final at1 = _p.at('musico_lejos1');
      final spr1 = _spr('mu_lejos1', mkLejos1);
      final sx1 = _round(at1.sx), sy1 = _round(at1.sy);
      out.add(
        MurallaItem(spr1, sx1 - 2, sy1 - spr1.h, sy1, at1.d, tag: 'fx:lejos1'),
      );
      final at2 = _p.at('musico_lejos2');
      final spr2 = _spr('mu_lejos2', mkLejos2);
      final sx2 = _round(at2.sx), sy2 = _round(at2.sy);
      out.add(
        MurallaItem(spr2, sx2 - 2, sy2 - spr2.h, sy2, at2.d, tag: 'fx:lejos2'),
      );
    }

    // 3. Hanging paper lanterns (`farol1..3`, top-anchored on cord)
    final present = w['farolPresent'] is List
        ? w['farolPresent'] as List
        : const [1, 1, 1];
    final litList = w['farolLit'] is List
        ? w['farolLit'] as List
        : const [1, 1, 1];
    final swingIdx = _n(w['farolSwing']);
    for (var i = 0; i < 3; i++) {
      if (i >= present.length || _n(present[i]) == 0) continue;
      final spot = 'farol${i + 1}';
      final at = _p.at(spot);
      final lit = i < litList.length ? _n(litList[i]) == 1 : true;
      final spr = _spr('mu_farol_$lit', () => mkFarol(lit: lit));
      final swingDx = swingIdx == i + 1 ? (a % 2 == 0 ? 1 : -1) : 0;
      final sx = _round(at.sx) + swingDx, sy = _round(at.sy);
      out.add(MurallaItem(spr, sx - 5, sy, sy, at.d, tag: 'cosa:$spot'));
    }

    // 4. Camera in story 117
    if (storyNum == 117) {
      final at = _p.at('camara');
      final spr = _spr('mu_camara', mkCamara);
      final sx = _round(at.sx), sy = _round(at.sy);
      out.add(
        MurallaItem(spr, sx - 6, sy - spr.h, sy, at.d, tag: 'cosa:camara'),
      );
    }

    // 5. Story 118 candle on parapet, juice, plate, and wooden chair
    if (storyNum == 118) {
      final vat = _p.at('vela');
      final rings = _n(w['aros']).clamp(0, 3);
      final lit = rings > 0;
      final gut = _n(w['final118']) == 1 && lit;
      final vspr = _spr(
        'mu_vela_${rings}_${lit}_$gut',
        () => mkVelaMuralla(rings: rings, lit: lit, guttering: gut),
      );
      final vsx = _round(vat.sx), vsy = _round(vat.sy);
      out.add(
        MurallaItem(vspr, vsx - 4, vsy - vspr.h, vsy, vat.d, tag: 'cosa:vela'),
      );

      if (w['jugoAt'] != 'used') {
        final jAt = _p.at('jugo');
        final jSpr = _spr('mu_jugo', mkJugoMuralla);
        final jsx = _round(jAt.sx), jsy = _round(jAt.sy);
        out.add(
          MurallaItem(
            jSpr,
            jsx - 3,
            jsy - jSpr.h,
            jsy,
            jAt.d,
            tag: 'cosa:jugo',
          ),
        );
      }

      if (w['platoAt'] != 'used') {
        final pAt = _p.at('plato');
        final pSpr = _spr('mu_plato', mkPlatoMuralla);
        final psx = _round(pAt.sx), psy = _round(pAt.sy);
        out.add(
          MurallaItem(
            pSpr,
            psx - 6,
            psy - pSpr.h,
            psy,
            pAt.d,
            tag: 'cosa:plato',
          ),
        );
      }

      final sillaAt = w['sillaAt'] as String?;
      if (sillaAt != 'hidden') {
        final onAbuelo = sillaAt == 'abuelo';
        final sAt = onAbuelo ? _p.atUv(-2.45, 2.2, 0.0) : _p.at('junto_mesa');
        final sSpr = _spr('mu_silla', mkSillaMuralla);
        final ssx = _round(sAt.sx), ssy = _round(sAt.sy);
        out.add(
          MurallaItem(
            sSpr,
            ssx - 7,
            ssy - sSpr.h,
            ssy,
            sAt.d,
            tag: onAbuelo ? 'fx:silla_abuelo' : 'cosa:silla',
          ),
        );
      }
    }

    // 6. Story 119 table things (`mesa1..mesa5`)
    if (storyNum == 119) {
      if (_n(w['guitarraMesa']) == 1) {
        final gat = _p.at('mesa1');
        final gspr = _spr('mu_guitarra', mkGuitarra);
        final gsx = _round(gat.sx), gsy = _round(gat.sy);
        out.add(
          MurallaItem(
            gspr,
            gsx - 5,
            gsy - gspr.h,
            gsy,
            gat.d,
            tag: 'cosa:guitarra',
          ),
        );
      }
      final itemsMap = (w['items119'] as Map?) ?? const {};
      const tableMap = [
        ('sombrero', 'mesa2', 6),
        ('bolsa', 'mesa3', 5),
        ('caja', 'mesa4', 6),
        ('libro', 'mesa5', 5),
      ];
      for (final (kind, spot, ax) in tableMap) {
        if (itemsMap[kind] != 'mesa') continue;
        final at = _p.at(spot);
        final spr = switch (kind) {
          'sombrero' => _spr('mu_sombrero', mkSombrero),
          'bolsa' => _spr('mu_bolsa', mkBolsa),
          'caja' => _spr('mu_caja', mkCaja),
          _ => _spr('mu_libro', mkLibroMuralla),
        };
        final sx = _round(at.sx), sy = _round(at.sy);
        out.add(
          MurallaItem(spr, sx - ax, sy - spr.h, sy, at.d, tag: 'cosa:$kind'),
        );
      }
    }

    // 7. People (those behind a closed sentry-box door remain hidden behind it until opened)
    for (final en in gente.entries) {
      final p = en.value as Map<String, dynamic>;
      if (p['vis'] == 0) continue;
      final spot = p['spot'] as String?;
      final inRed = spot == 'dentro_roja';
      final inBlue = spot == 'dentro_azul';
      if (inRed && _n(w['redDoorOpen']) != 1) continue;
      if (inBlue && _n(w['blueDoorOpen']) != 1) continue;

      final open = talk == en.key && a % 2 == 1;
      final at = _atOf(p);
      final sx = _round(at.sx) + _n(p['dx']);
      final sy = _round(at.sy) + _n(p['dy']);
      final sp = _personSprite(en.key, p, open, storyNum, a, w: w);

      if (inRed || inBlue) {
        final doorId = inRed ? 'puerta_roja' : 'puerta_azul';
        final cbox = _p.box(doorId);
        final dyClip = cbox[1] + 2 - (sy - sp.ay + _inkTop(sp.s));
        out.add(
          MurallaItem(
            sp.s,
            sx - sp.ax,
            sy - sp.ay + dyClip,
            sy,
            at.d,
            tag: 'persona:${en.key}',
            clipBox: cbox,
            dy: dyClip,
          ),
        );
      } else {
        out.add(
          MurallaItem(
            sp.s,
            sx - sp.ax,
            sy - sp.ay,
            sy,
            at.d,
            tag: 'persona:${en.key}',
          ),
        );
      }
    }

    // 8. Transient story FX & celebrations
    if (_n(w['palomaLedge']) == 1) {
      final box = _p.box('puerta_azul');
      final pspr = _spr(
        'mu_paloma_ledge',
        () => mkPaloma(flying: false, openEye: true),
      );
      out.add(
        MurallaItem(
          pspr,
          box[0] + 12,
          box[1] - pspr.h,
          box[1],
          1.35,
          tag: 'fx:paloma',
        ),
      );
    }
    if (_n(w['pigeonBurst']) == 1) {
      final box = _p.box(
        _n(w['redDoorOpen']) == 1 ? 'puerta_roja' : 'puerta_azul',
      );
      final pspr = _spr('mu_paloma_fly', () => mkPaloma(flying: true));
      out.add(
        MurallaItem(
          pspr,
          box[0] + 3,
          box[1] - 12 - (a % 2) * 3,
          box[1],
          6.0,
          tag: 'fx:paloma_burst1',
          overlay: true,
        ),
      );
      out.add(
        MurallaItem(
          pspr,
          box[0] + 14,
          box[1] - 18 + (a % 2) * 2,
          box[1],
          6.0,
          tag: 'fx:paloma_burst2',
          overlay: true,
        ),
      );
    }

    if (_n(w['flashFx']) == 1) {
      final cat = _p.at('camara');
      final fspr = _spr('mu_flash', mkFlashMuralla);
      out.add(
        MurallaItem(
          fspr,
          _round(cat.sx) - 10,
          _round(cat.sy) - 24,
          _round(cat.sy),
          8.0,
          tag: 'fx:flash',
          overlay: true,
        ),
      );
    }

    final fotoLevel = _n(w['fotoFx']);
    if (fotoLevel > 0) {
      final fspr = _spr('mu_foto_$fotoLevel', () => mkFotoSlide(fotoLevel));
      out.add(
        MurallaItem(fspr, 176, 144, 160, 8.0, tag: 'fx:foto', overlay: true),
      );
    }

    final nfx = w['notaFx'];
    if (nfx is Map) {
      final spr = _spr('mu_nota', mkNotaMuralla);
      final fx = _n(nfx['x']), fy = _n(nfx['y']);
      out.add(
        MurallaItem(
          spr,
          fx - 3,
          fy - spr.h,
          fy,
          7.0,
          tag: 'fx:nota',
          overlay: true,
        ),
      );
    }

    if (_n(w['final117']) == 3 ||
        _n(w['final118']) == 3 ||
        _n(w['final119']) == 4) {
      final est = _spr('mu_estrellas', mkEstrellasMuralla);
      final cor = _spr('mu_corazon', mkCorazonMuralla);
      out.add(
        MurallaItem(est, 168, 12, 22, 9.0, tag: 'fx:estrellas', overlay: true),
      );
      out.add(
        MurallaItem(cor, 188, 12, 23, 9.0, tag: 'fx:corazon', overlay: true),
      );
    }

    return out;
  }

  /// [items] plus the frog (placed per muralla-preview.html `placeAll` & `host.frog`), for [draw] & `MurallaRules`.
  List<MurallaItem> placed(Map<String, dynamic> w, int a) {
    final out = items(w, a);
    final q = w['cq'] as Map<String, dynamic>?;
    if (q != null && jsTruthy(q['vis'])) {
      final b = host.frogBox(q);
      final at = _frogPoint(q);
      final fsy = _round(at.sy);
      final ox = b.x.toInt() - 16;
      final oy = b.y.toInt() - 24;
      final talk = _talker();
      final blink = _tryTickBlink() ? 1 : 0;
      final open = (q['bub'] == 'hola' || talk == 'coqui') && a % 2 != 0;
      final fk =
          '${q['s']}_${b.x - ox}_${b.y - oy}_${(q['y'] as num) - oy}_${((q['dy'] as num) + .5).floor()}_${blink}_${open ? 1 : 0}';
      final spr = _spr('mu_frog_$fk', () {
        final px = Uint32List(64 * 64);
        final g = Ctx(px, 64, 64)..translate(-ox.toDouble(), -oy.toDouble());
        host.frog(g, q, a);
        return Sprite(64, 64, px);
      });
      out.add(MurallaItem(spr, ox, oy, fsy, at.d, tag: 'coqui'));
    }
    return out;
  }

  bool _tryTickBlink() {
    try {
      return host.F % 47 < 2;
    } catch (_) {
      return false;
    }
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
    MurallaItem it,
    int w0,
    int h0,
    Float32List? setZ,
    double bias,
    double S,
  ) {
    final layer = _layer!, lz = _layerZ!, sp = it.s;
    final sw = sp.w, sh = sp.h;
    final spx = sp.px;
    final cb = it.clipBox;
    for (var py = 0; py < sh; py++) {
      final Y = it.top + py;
      if (Y < 0 || Y >= h0) continue;
      if (cb != null && (Y < cb[1] || Y >= cb[1] + cb[3])) continue;
      final plane = it.overlay
          ? it.d
          : it.d + (it.sy - ((Y - it.dy) + .5)) * _t30 / S;
      final row = Y * w0;
      final srow = py * sw;
      for (var px = 0; px < sw; px++) {
        final c = spx[srow + px];
        if (c >>> 24 == 0) continue;
        final X = it.left + px;
        if (X < 0 || X >= w0) continue;
        if (cb != null && (X < cb[0] || X >= cb[0] + cb[2])) continue;
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

    // Lantern cord pixels (decor.cuerda) drawn into unbaked sky/sea at lz = -50.
    final cord = _p.cordMeta;
    final cordN = ((cord.u1 - cord.u0) * _p.e.S).ceil();
    final cordCol =
        0xFF000000 |
        ((cord.colour[2] & 0xFF) << 16) |
        ((cord.colour[1] & 0xFF) << 8) |
        (cord.colour[0] & 0xFF);
    final cordPts = <(int, int)>[];
    var x0 = w0, y0 = h0, x1 = 0, y1 = 0;
    for (var k = 0; k <= cordN; k++) {
      final frac = k / cordN;
      final u = cord.u0 + (cord.u1 - cord.u0) * frac;
      final z = cord.z - math.sin(frac * math.pi) * cord.sag;
      final q = _p.atUv(u, cord.v, z);
      final ix = q.sx.truncate(), iy = q.sy.truncate();
      if (ix < 0 || iy < 0 || ix >= w0 || iy >= h0) continue;
      if (setZ != null && setZ[iy * w0 + ix] > -1e8) continue;
      cordPts.add((ix, iy));
      x0 = math.min(x0, ix);
      y0 = math.min(y0, iy);
      x1 = math.max(x1, ix + 1);
      y1 = math.max(y1, iy + 1);
    }

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
      for (final (ix, iy) in cordPts) {
        final i = iy * w0 + ix;
        layer[i] = cordCol;
        lz[i] = -50.0;
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

    if (_n(w['vientoDark']) == 1) {
      c
        ..save()
        ..globalAlpha = .58
        ..fillStyle = 0xFF1C0E0A
        ..fillRect(0, 0, w0, h0)
        ..restore();
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
          '..####.####..',
          '.###.....###.',
          '.#.........#.',
        ];
        final col = hexColour('#F8C838');
        for (var r = 0; r < st.length; r++) {
          for (var colI = 0; colI < st[r].length; colI++) {
            if (st[r][colI] == '#') fr(c, x + colI, y + 3 + r, 1, 1, col);
          }
        }
      } else if (m == 'x') {
        const cr = [
          '###.......###',
          '####.....####',
          '.####...####.',
          '..####.####..',
          '...#######...',
          '....#####....',
          '...#######...',
          '..####.####..',
          '.####...####.',
          '####.....####',
          '###.......###',
        ];
        final col = hexColour('#E05040');
        for (var r = 0; r < cr.length; r++) {
          for (var colI = 0; colI < cr[r].length; colI++) {
            if (cr[r][colI] == '#') fr(c, x + colI, y + 3 + r, 1, 1, col);
          }
        }
      } else {
        final col = hexColour('#C8B8A0');
        fr(c, x + 2, y + 12, 9, 2, col);
      }
    }
  }

  /* ---------- touches & talking mouths ---------- */

  @override
  List<num>? talkAt(String who, Map<String, dynamic> W) {
    if (who == 'coqui') {
      final q = W['cq'] as Map<String, dynamic>?;
      if (q == null) return null;
      final b = host.frogBox(q);
      return [_round(b.x + b.w / 2), _round(b.y) - 6];
    }
    // OPEN: story 119 `gente` speaker voices come from the guagua on the road.
    if (who == 'gente') {
      final gb = _spriteBox(W, 'cosa:guagua');
      if (gb != null) {
        return [gb[0].toInt() + gb[2] ~/ 2, gb[1].toInt() - 4];
      }
      final gAt = _p.at(_n(W['guaguaGone']) == 1 ? 'guagua_se_va' : 'guagua');
      return [_round(gAt.sx), _round(gAt.sy) - 14];
    }
    final p = (W['gente'] as Map<String, dynamic>?)?[who];
    if (p is Map<String, dynamic>) {
      final spot = p['spot'] as String?;
      if (spot == 'dentro_roja' || spot == 'dentro_azul') {
        final b = _p.box(spot == 'dentro_roja' ? 'puerta_roja' : 'puerta_azul');
        return [b[0] + b[2] ~/ 2, b[1]];
      }
      final at = _atOf(p);
      final sx = _round(at.sx) + _n(p['dx']);
      final sy = _round(at.sy) + _n(p['dy']);
      return [sx, sy - 48];
    }
    return null;
  }

  List<num>? _itemBox(
    List<MurallaItem> list,
    bool Function(MurallaItem it) test,
  ) {
    var x0 = 240, y0 = 216, x1 = -1, y1 = -1;
    for (final it in list) {
      if (!test(it)) continue;
      final sp = it.s;
      final cb = it.clipBox;
      for (var py = 0; py < sp.h; py++) {
        for (var px = 0; px < sp.w; px++) {
          if (sp.px[py * sp.w + px] >>> 24 == 0) continue;
          final X = it.left + px, Y = it.top + py;
          if (X < 0 || X >= 240 || Y < 0 || Y >= 216) continue;
          if (cb != null &&
              (X < cb[0] ||
                  X >= cb[0] + cb[2] ||
                  Y < cb[1] ||
                  Y >= cb[1] + cb[3])) {
            continue;
          }
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

  List<Thing> _things() => [
    // OPEN: touch priority checks foreground table/small items first, then people, then large set surfaces.
    for (final kind in const ['sombrero', 'bolsa', 'caja', 'libro'])
      Thing(
        id: kind,
        si: (w) =>
            _n(w['story']) == 119 && ((w['items119'] as Map?)?[kind] == 'mesa'),
        box: (w) => _spriteBox(w, 'cosa:$kind'),
      ),
    Thing(
      id: 'guitarra',
      si: (w) => _n(w['story']) == 119 && _n(w['guitarraMesa']) == 1,
      box: (w) => _spriteBox(w, 'cosa:guitarra') ?? _p.spotBox('mesa1'),
    ),
    Thing(
      id: 'jugo',
      si: (w) => _n(w['story']) == 118 && w['jugoAt'] != 'used',
      box: (w) => _spriteBox(w, 'cosa:jugo') ?? _p.spotBox('jugo'),
    ),
    Thing(
      id: 'plato',
      si: (w) => _n(w['story']) == 118 && w['platoAt'] != 'used',
      box: (w) => _spriteBox(w, 'cosa:plato') ?? _p.spotBox('plato'),
    ),
    Thing(
      id: 'vela',
      si: (w) => _n(w['story']) == 118,
      box: (w) => _spriteBox(w, 'cosa:vela') ?? _p.spotBox('vela'),
    ),
    Thing(
      id: 'silla',
      si: (w) => _n(w['story']) == 118 && w['sillaAt'] != 'hidden',
      box: (w) =>
          _spriteBox(w, 'cosa:silla') ??
          _spriteBox(w, 'fx:silla_abuelo') ??
          _p.spotBox('junto_mesa'),
    ),
    Thing(
      id: 'camara',
      si: (w) => _n(w['story']) == 117,
      box: (w) => _spriteBox(w, 'cosa:camara') ?? _p.spotBox('camara'),
    ),
    for (var i = 1; i <= 3; i++)
      Thing(
        id: 'farol$i',
        si: (w) {
          final pr = w['farolPresent'];
          return pr is! List || (i - 1 < pr.length && _n(pr[i - 1]) == 1);
        },
        box: (w) => _spriteBox(w, 'cosa:farol$i') ?? _p.spotBox('farol$i'),
      ),
    Thing(
      id: 'guagua',
      si: (w) => _n(w['story']) == 119 && _n(w['guaguaVis']) == 1,
      box: (w) => _spriteBox(w, 'cosa:guagua') ?? _p.spotBox('guagua'),
    ),
    // People
    for (final who in MURALLA_PERSONAS)
      Thing(
        id: who,
        si: (w) {
          final p = (w['gente'] as Map?)?[who];
          if (p is! Map || p['vis'] == 0) return false;
          final sp = p['spot'];
          if (sp == 'dentro_roja' && _n(w['redDoorOpen']) != 1) return false;
          if (sp == 'dentro_azul' && _n(w['blueDoorOpen']) != 1) return false;
          return true;
        },
        box: (w) => _spriteBox(w, 'persona:$who'),
      ),
    // Set surfaces
    Thing(id: 'puerta_roja', box: (w) => _p.box('puerta_roja')),
    Thing(id: 'puerta_azul', box: (w) => _p.box('puerta_azul')),
    Thing(id: 'banco', box: (w) => _p.box('banco')),
    Thing(id: 'escalera', box: (w) => _p.box('escalera')),
  ];

  @override
  String? hit(num x, num y, Map<String, dynamic> w) {
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
}
