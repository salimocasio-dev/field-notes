// Los regalos (place 10, El fuerte, scene 3: `regalos`; stories 114 to 116): a NEW scene, written from its script's
// "Needs" list (historia/notas/guiones/regalos.md) on its set (regalos_set.dart) and its sheet (regalos-sheet.json,
// read by SceneSheet). There is no old scene file: every act is in regalos_acts.dart, each doing on screen what the
// Needs list says, every place from the sheet (spots, curtain/stool boxes, depth rule, shadows). Where the sheet names
// no place or an act is unstated in the script, the code does the plainest thing that keeps the story playing and
// marks it `OPEN:`.
//
// The drawing (the sheet's `front`): every sprite stands with its feet's bottom edge on its spot's row and its
// middle on its column (rules.anchor); standing abuela anchors at (30, inkBottom); mkPersona standing anchors at
// (24, inkBottom); hanging photos anchor at top-middle (6, 0) on cuerda1..4; the curtain's left column aligns with
// things.cortina.box[0] (19) and bottom on the spot's row; every sprite pixel is hidden by every baked set pixel
// (`baked.zb`) nearer than its upright plane plus `front.bias` (0.3). Between two sprites the nearer pixel wins
// (tie within 0.001 goes to the later layer).
// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/src/colmado/colmado_cast.dart' show inkBottom;
import 'package:coqui_scenes/src/regalos/regalos_places.dart';
import 'package:coqui_scenes/src/regalos/regalos_set.dart';
import 'package:coqui_scenes/src/regalos/regalos_sprites.dart';
import 'package:coqui_scenes/src/scene_set.dart';
import 'package:coqui_scenes/src/sheet_cache.dart';

part 'regalos_acts.dart';

/// The scene "Los regalos", made from its sheet (read first: `loadScene`).
Scene createRegalos() => Regalos(sceneSheetOf('regalos'));

int _round(num v) => (v + 0.5).floor();

int _n(Object? v) {
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? 0;
  return 0;
}

/// One sprite of the sprite layer, placed: its picture, its top left on the 240 × 216 picture, the screen row of its
/// anchor and the depth there (front.plane), and who or what it is.
class RegalosItem {
  RegalosItem(
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
  final bool overlay;
}

/// Every drawn person Los regalos knows, by speaker/script key (`pepe` matches gen_regalos.py & Needs; sheet calls him
/// `don_pepe`).
const List<String> REGALOS_PERSONAS = [
  'abuela',
  'abuelo',
  'luis',
  'carmen',
  'pepe',
  'maestra',
  'piraguero',
];

/// Every speaker key supported by [Regalos.talkAt] (8 speakers).
const List<String> REGALOS_SPEAKERS = [...REGALOS_PERSONAS, 'coqui'];

/// The four photo keys of story 115, in canonical peg order (`cuerda1..cuerda4`).
const List<String> REGALOS_FOTOS = ['foto_3m', 'foto_7m', 'foto_3a', 'foto_7a'];

class Regalos extends Escena implements SetScene, SetOverSprites {
  Regalos(this.ss)
    : sheet = identical(ss, _lastSs)
          ? _lastSheet!
          : (_lastSheet = ss.legacy()) {
    _p = identical(ss, _lastSs)
        ? _lastPlaces!
        : (_lastPlaces = RegalosPlaces(ss));
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
  static RegalosPlaces? _lastPlaces;

  /// The new scene's sheet (SceneSheet).
  final SceneSheet ss;

  @override
  final Sheet sheet;

  late final RegalosPlaces _p;

  /// The scene's places, from its sheet.
  RegalosPlaces get places => _p;

  @override
  String get id => 'regalos';

  @override
  late final Map<String, List<num>> CAM;

  late final Map<String, List<num>> LUGAR;

  @override
  Map<String, List<num>> get lugar => LUGAR;

  @override
  late final List<Thing> cosas;

  @override
  PpEngine newEngine({bool still = false}) => regalosEngine(still: still);

  @override
  PpEngine get projection => _p.e;

  List<num> _frogAt(RegalosAt a) => [_round(a.sx) - 16, _round(a.sy) - 25, 1];

  Map<String, dynamic> get W => host.W;
  int get F => host.F;
  int get TICK => host.TICK;
  Future<void> wait(num ms) => host.wait(ms);

  /* ---------- state ---------- */

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

  Map<String, dynamic> _person(String spot, {int vis = 1}) {
    final w = _p.world(spot);
    return <String, dynamic>{
      'x': w[0],
      'y': w[1],
      'z': w[2],
      'spot': spot,
      'vis': vis,
      'pose': 'idle',
      'al': 1.0,
      'dx': 0,
      'dy': 0,
    };
  }

  void _placePerson(Map<String, dynamic> p, String spot) {
    final w = _p.world(spot);
    p['x'] = w[0];
    p['y'] = w[1];
    p['z'] = w[2];
    p['spot'] = spot;
    p['vis'] = 1;
    p['dx'] = 0;
    p['dy'] = 0;
  }

  @override
  Map<String, dynamic> fresh(Map<String, dynamic> story) {
    final acts = _actsOf([story['beats'], story['final']]);
    bool has(String a) => acts.any((o) => o['act'] == a);
    final is116 =
        has('empuja116') ||
        has('abre116') ||
        has('etiquetas116') ||
        has('pareja116') ||
        has('sorpresas') ||
        has('final116');
    final is115 =
        !is116 &&
        (has('velas115') ||
            has('foto115') ||
            has('viento115') ||
            has('prende115') ||
            has('velas') ||
            has('final115'));
    final storyNum = is116 ? 116 : (is115 ? 115 : 114);
    // OPEN: gen_regalos.py calls `ir(mesa_coqui)` at Story 115 start, but mesa_coqui covers fotos1..fotos2 on the
    // table; regalos-preview.html moments 4 & 5 place the frog at `banqueta_coqui` throughout Story 115.
    final startSpot = is115 ? 'banqueta_coqui' : 'mesa_coqui';
    final q = _frogAt(_p.at(startSpot));

    final gente = <String, dynamic>{
      'abuela': _person('tras_mesa', vis: 1),
      'abuelo': _person(is116 ? 'banqueta_der' : 'junto_banco', vis: 1),
      'luis': _person('arco', vis: 1),
      // Story 114 starts with Carmen dancing beyond the arch at fondo2 (half-open curtain).
      'carmen': _person(
        is116 ? 'banqueta_izq' : (is115 ? 'tras_mesa2' : 'fondo2'),
        vis: 1,
      ),
      'pepe': _person('espera1', vis: (is115 || is116) ? 1 : 0),
      'maestra': _person('espera2', vis: (is115 || is116) ? 1 : 0),
      'piraguero': _person('espera3', vis: is116 ? 1 : 0),
    };

    return <String, dynamic>{
      'story': storyNum,
      'hora': 'noche',
      'gente': gente,
      // Story 114 state (La sorpresa)
      'cortinaState': storyNum == 114 ? 'half' : 'open', // 'open'|'half'|'shut'
      'pinzas': 3,
      'sombraFx': 0,
      'pinzaVolandoFx': 0,
      'mantelFx': 0,
      'bizcochoAt': storyNum == 114
          ? 'banco1'
          : (is115 ? 'mesa2' : null), // 'banco1' | 'mesa2' | null
      'bizcochoRed': storyNum == 114 ? 1 : 0,
      'regaloAt': storyNum == 114 ? 'banco2' : null, // 'banco2'|'mesa1'|null
      'regaloShaken': 0,
      'floresAt': storyNum == 114 ? 'banco3' : null, // 'banco3'|'mesa3'|null
      'carmenOjos': 0,
      // Story 115 state (Las velas)
      'cajaVelasVis': is115 ? 1 : 0,
      'cajaVelasEmpty': 0,
      'velasOnCake': 0, // 0 before velas115, 1 after
      'velasLit': 0, // 0..7
      'velasSmoked': 0,
      'abuelaFosforo': 0,
      // Each photo's location: 'fotos1'..'fotos4' or 'cuerda1'..'cuerda4' (or null outside 115)
      'fotoPos': is115
          ? <String, String>{
              'foto_3m': 'fotos1',
              'foto_7m': 'fotos2',
              'foto_3a': 'fotos3',
              'foto_7a': 'fotos4',
            }
          : <String, String>{},
      'vientoFx': 0,
      // Story 116 state (Para ti)
      'paquetesMesa': is116 ? 3 : 0, // 3, 2, 1, 0 packets on table
      'paquetesTagged': is116 ? 1 : 0,
      'paqueteStoolVis': is116 ? 1 : 0,
      'paqueteStoolTorn': 0,
      'paqueteStoolOpen': 0,
      'paqueteA':
          null, // null | 'carmen' | guest key ('pepe'|'maestra'|'piraguero')
      'sorpresas': 3,
      'papelesRotos': 0, // 0, 1, 2 torn papers by stool at ending
      'abuelaLista': is116 ? 1 : 0,
      'carmenSombrero': 0,
      'abueloAbanico': 0,
      'coquiSombrerito': 0,
      // Per-person gesture flags
      'luisSilencio': 0,
      'luisDedos': 0,
      'manosWho': <String>{},
      'aplaudeWho': <String>{},
      // Shared FX & HUD
      'celebrar': 0,
      'gestoCue': null,
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
  String setKey(Map<String, dynamic> W) => RegalosState.KEY;

  @override
  void buildSet(PpEngine e, PpBuild b, Map<String, dynamic> W) =>
      buildSetFor(e, b, setKey(W));

  final Map<PpEngine, RegalosSet> _sets = {};

  @override
  void buildSetFor(PpEngine e, PpBuild b, String key) =>
      (_sets[e] ??= RegalosSet(e, b)).buildSet(RegalosState.fromKey(key));

  @override
  bool get frogShadow => false;

  /* ---------- where everybody is ---------- */

  Map<String, dynamic> get _gente => W['gente'] as Map<String, dynamic>;

  RegalosAt _atOf(Map<String, dynamic> o) =>
      _p.atWorld(o['x'] as num, o['y'] as num, o['z'] as num);

  RegalosAt _frogPoint(Map<String, dynamic> q) {
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

  static String _kitPoseOf(String pose) => switch (pose) {
    'saluda0' => 'wave0',
    'saluda1' => 'wave1',
    'senala_izq' => 'offer',
    'senala_der' || 'senala' => 'tu',
    'yo' || 'rie' => 'yo',
    _ => 'idle',
  };

  ({Sprite s, int ax, int ay}) _personSprite(
    String id,
    Map<String, dynamic> p,
    Map<String, dynamic> w,
    bool open,
  ) {
    final pose = (p['pose'] as String?) ?? 'idle';
    final kp = _kitPoseOf(pose);
    if (id == 'abuela') {
      final lista = _n(w['abuelaLista']) == 1;
      final fosforo = _n(w['abuelaFosforo']) == 1;
      final s = _spr(
        'rg_ab_${kp}_${open}_${lista}_$fosforo',
        () => mkAbuelaRegalos(kp, open, lista: lista, fosforo: fosforo),
      );
      return (s: s, ax: 30, ay: inkBottom(s));
    }
    final Who who = switch (id) {
      'abuelo' => FAM['abuelo']!,
      'luis' => FAM['hermano']!,
      'carmen' => FAM['hermana']!,
      _ => REGALOS_PEOPLE[id]!,
    };
    final manos = (w['manosWho'] as Set?)?.contains(id) ?? false;
    final aplaude = (w['aplaudeWho'] as Set?)?.contains(id) ?? false;
    final sombrero = id == 'carmen' && _n(w['carmenSombrero']) == 1;
    final abanico = id == 'abuelo' && _n(w['abueloAbanico']) == 1;
    final silencio = id == 'luis' && _n(w['luisSilencio']) == 1;
    final dedos = id == 'luis' && _n(w['luisDedos']) == 1;
    final ojos = id == 'carmen' && _n(w['carmenOjos']) == 1;
    final s = _spr(
      'rg_${id}_${kp}_${open}_${sombrero}_${abanico}_${silencio}_${dedos}_${manos}_${aplaude}_$ojos',
      () => mkPersonaRegalos(
        who,
        kp,
        open,
        sombrero: sombrero,
        abanico: abanico,
        silencio: silencio,
        dedos: dedos,
        manos: manos,
        aplaude: aplaude,
        ojos: ojos,
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
  List<RegalosItem> items(Map<String, dynamic> w, int a) {
    final out = <RegalosItem>[];
    final talk = _talker();
    final gente = (w['gente'] as Map<String, dynamic>?) ?? const {};
    final anim = (F >> 2) + a;

    // 1. Curtain across the arch (`cortina`, story 114: half or shut on 3/2/1 pegs).
    final cort = (w['cortinaState'] as String?) ?? 'open';
    if (cort == 'half' || cort == 'shut') {
      final half = cort == 'half';
      final pegs = _n(w['pinzas']).clamp(1, 3);
      final shadow = !half && _n(w['sombraFx']) == 1;
      final at = _p.at('cortina');
      final box = half ? _p.curtainHalfBox : _p.box('cortina');
      final s = _spr(
        'rg_cort_${half}_${pegs}_$shadow',
        () => mkCortina(half: half, pegs: pegs, shadow: shadow),
      );
      final sy = _round(at.sy);
      out.add(
        RegalosItem(s, box[0], sy - box[3], sy, at.d, tag: 'cosa:cortina'),
      );
    }

    // 2. People
    for (final id in REGALOS_PERSONAS) {
      final p = gente[id] as Map<String, dynamic>?;
      if (p == null || p['vis'] == 0) continue;
      final open = talk == id && a % 2 == 1;
      final sp = _personSprite(id, p, w, open);
      final at = _atOf(p);
      // OPEN: mkPersona(maestra, peinado: 'largo') is 1 px taller than piraguero tested at banqueta_der in preview m6,
      // grazing mesa2's bottom row (y=90) by 1 px; nudge 1 px down so mesa2 stays 100% clear.
      final spotNudgeY = (id == 'maestra' && p['spot'] == 'banqueta_der')
          ? 1
          : 0;
      final sx = _round(at.sx) + _n(p['dx']);
      final sy = _round(at.sy) + _n(p['dy']) + spotNudgeY;
      out.add(
        RegalosItem(sp.s, sx - sp.ax, sy - sp.ay, sy, at.d, tag: 'persona:$id'),
      );
    }

    // 3. Story 114 & 115 props: bizcocho, regalo, flores, caja_velas
    final bizAt = w['bizcochoAt'] as String?;
    if (bizAt != null && _p.has(bizAt)) {
      final at = _p.at(bizAt);
      final sx = _round(at.sx), sy = _round(at.sy);
      final story = _n(w['story']);
      late final Sprite s;
      if (story == 115) {
        final hasC = _n(w['velasOnCake']) == 1;
        final lit = _n(w['velasLit']).clamp(0, 7);
        final smk = _n(w['velasSmoked']) == 1;
        s = _spr(
          'rg_biz115_${hasC}_${lit}_$smk',
          () => mkBizcocho(18, 18, candles: hasC, litCandles: lit, smoked: smk),
        );
      } else if (bizAt == 'banco1') {
        final net = _n(w['bizcochoRed']) == 1;
        s = _spr('rg_bizB_$net', () => mkBizcocho(16, 12, net: net));
      } else {
        s = _spr('rg_bizT', () => mkBizcocho(14, 14));
      }
      out.add(
        RegalosItem(s, sx - s.w ~/ 2, sy - s.h, sy, at.d, tag: 'cosa:bizcocho'),
      );
    }

    final regAt = w['regaloAt'] as String?;
    if (regAt != null && _p.has(regAt)) {
      final at = _p.at(regAt);
      final sx = _round(at.sx), sy = _round(at.sy);
      final shaken = _n(w['regaloShaken']) == 1;
      final s = _spr('rg_reg_$shaken', () => mkRegaloBox(shaken: shaken));
      out.add(
        RegalosItem(s, sx - s.w ~/ 2, sy - s.h, sy, at.d, tag: 'cosa:regalo'),
      );
    }

    final flAt = w['floresAt'] as String?;
    if (flAt != null && _p.has(flAt)) {
      final at = _p.at(flAt);
      final sx = _round(at.sx), sy = _round(at.sy);
      final onBench = flAt == 'banco3';
      final s = _spr(
        'rg_fl_$onBench',
        () => onBench ? mkFlores(12, 16) : mkFlores(14, 14),
      );
      out.add(
        RegalosItem(s, sx - s.w ~/ 2, sy - s.h, sy, at.d, tag: 'cosa:flores'),
      );
    }

    if (_n(w['cajaVelasVis']) == 1) {
      final at = _p.at('banco2');
      final sx = _round(at.sx), sy = _round(at.sy);
      final empty = _n(w['cajaVelasEmpty']) == 1;
      final s = _spr('rg_velas_$empty', () => mkCajaVelas(empty: empty));
      out.add(
        RegalosItem(
          s,
          sx - s.w ~/ 2,
          sy - s.h,
          sy,
          at.d,
          tag: 'cosa:caja_velas',
        ),
      );
    }

    // 4. Story 115 photos (`foto_3m`, `foto_7m`, `foto_3a`, `foto_7a`) on cord (`cuerda1..4`) or table (`fotos1..4`).
    final fotoPos = (w['fotoPos'] as Map?) ?? const {};
    for (final key in REGALOS_FOTOS) {
      final spot = fotoPos[key] as String?;
      if (spot == null || !_p.has(spot)) continue;
      final hung = spot.startsWith('cuerda');
      final kind = key.substring('foto_'.length); // '3m'|'7m'|'3a'|'7a'
      final at = _p.at(spot);
      final sx = _round(at.sx), sy = _round(at.sy);
      final s = _spr(
        'rg_ft_${kind}_$hung',
        () => mkFotoRegalos(kind, hung: hung),
      );
      final top = hung ? sy : sy - s.h;
      out.add(RegalosItem(s, sx - s.w ~/ 2, top, sy, at.d, tag: 'cosa:$key'));
    }

    // 5. Story 116 packets on table (`mesa2`, `mesa3`, and `mesa1` when 3 on table) and on low stool (`paquete`).
    final pm = _n(w['paquetesMesa']).clamp(0, 3);
    final tagged = _n(w['paquetesTagged']) == 1;
    final tableSpots = switch (pm) {
      3 => const ['mesa1', 'mesa2', 'mesa3'],
      2 => const ['mesa2', 'mesa3'],
      1 => const ['mesa3'],
      _ => const <String>[],
    };
    for (final spot in tableSpots) {
      final at = _p.at(spot);
      final sx = _round(at.sx), sy = _round(at.sy);
      final s = _spr(
        'rg_pktT_$tagged',
        () => mkPaquete(14, 14, tagged: tagged),
      );
      out.add(
        RegalosItem(
          s,
          sx - s.w ~/ 2,
          sy - s.h,
          sy,
          at.d,
          tag: 'cosa:paquete_$spot',
        ),
      );
    }
    if (_n(w['paqueteStoolVis']) == 1) {
      final at = _p.at('paquete');
      final a = w['paqueteA'] as String?;
      // Shift packet cleanly toward Carmen (banqueta_izq) or guest (banqueta_der) while staying clear of both.
      final shiftX = a == null ? 0 : (a == 'carmen' ? -6 : 6);
      final sx = _round(at.sx) + shiftX, sy = _round(at.sy);
      final torn = _n(w['paqueteStoolTorn']) == 1;
      final open = !torn && _n(w['paqueteStoolOpen']) == 1;
      final s = _spr(
        'rg_pktS_${torn}_$open',
        () => mkPaquete(14, 12, torn: torn, open: open),
      );
      out.add(
        RegalosItem(s, sx - s.w ~/ 2, sy - s.h, sy, at.d, tag: 'cosa:paquete'),
      );
    }
    final rotos = _n(w['papelesRotos']).clamp(0, 2);
    if (rotos >= 1) {
      final s = _spr('rg_roto', mkPapelRoto);
      out.add(RegalosItem(s, 152, 134, 140, 4.1, tag: 'fx:roto1'));
      if (rotos >= 2) {
        out.add(RegalosItem(s, 172, 134, 140, 4.1, tag: 'fx:roto2'));
      }
    }

    // 6. Transient FX (strictly clear of heads, frog, bench/table/cord/stool items)
    if (_n(w['mantelFx']) == 1) {
      final s = _spr('rg_mantel', mkMantelBrillo);
      out.add(RegalosItem(s, 162, 92, 97, 2.7, tag: 'fx:mantel'));
    }
    if (_n(w['pinzaVolandoFx']) == 1) {
      final s = _spr('rg_pinza_fx', mkPinzaVolando);
      out.add(RegalosItem(s, 68, 22, 28, 5.0, tag: 'fx:pinza'));
    }
    if (_n(w['vientoFx']) == 1) {
      final s = _spr('rg_viento_${anim % 2}', () => mkVientoFx(anim % 2));
      out.add(RegalosItem(s, 108, 20, 28, 5.0, tag: 'fx:viento'));
    }
    final gc = w['gestoCue'];
    if (gc is Map) {
      final isUp = gc['up'] == true;
      final s = _spr('rg_gc_$isUp', () => mkGestoFlechaRegalos(up: isUp));
      final cx = _n(gc['cueX']), cy = _n(gc['cueY']);
      final cd = (gc['d'] as num?)?.toDouble() ?? 5.0;
      out.add(RegalosItem(s, cx - 4, cy, cy + 7, cd, tag: 'fx:gesto_cue'));
    }
    if (_n(w['celebrar']) >= 1) {
      final st = _spr('rg_star', mkEstrellaRegalos);
      final hr = _spr('rg_heart', mkCorazonRegalos);
      // Open sky/wall space (cols 76..116, rows 12..22): clear of curtain, bench, cord, people, frog.
      out.add(RegalosItem(st, 76, 14, 23, 5.5, tag: 'fx:estrella1'));
      out.add(RegalosItem(hr, 92, 12, 21, 5.5, tag: 'fx:corazon'));
      out.add(RegalosItem(st, 108, 14, 23, 5.5, tag: 'fx:estrella2'));
    }

    return out;
  }

  static final Map<String, Sprite> _frogSprites = {};

  /// [items] plus the frog (as the host draws him), for `draw` and for `RegalosRules`.
  List<RegalosItem> placed(Map<String, dynamic> w, int a) {
    final out = items(w, a);
    final q = w['cq'] as Map<String, dynamic>?;
    if (q != null && jsTruthy(q['vis'])) {
      final at = _frogPoint(q);
      final dx = _n(q['dx']);
      final fsy = _round(at.sy);
      final b = host.frogBox(q);
      final ox = b.x.toInt() - 16 + dx;
      final oy = b.y.toInt() - 24;
      final hat = _n(w['coquiSombrerito']) == 1;
      final fk =
          '${q['s']}_${b.x - (b.x.toInt() - 16)}_${b.y - oy}_${(q['y'] as num) - oy}_${((q['dy'] as num) + 0.5).floor()}_${host.F % 47 < 2 ? 1 : 0}_${((q['bub'] == 'hola' || _talker() == 'coqui') && a % 2 != 0) ? 1 : 0}_$hat';
      final spr = _frogSprites.putIfAbsent(fk, () {
        final px = Uint32List(64 * 64);
        final g = Ctx(px, 64, 64)
          ..translate(-(b.x.toInt() - 16).toDouble(), -oy.toDouble());
        host.frog(g, q, a);
        final base = Sprite(64, 64, px);
        if (!hat) return base;
        // Overlay tiny straw hat (`sombrerito`) neatly on top of Coquí's head inside his 64x64 canvas.
        final hx = ((b.x + b.w / 2) - (b.x.toInt() - 16)).round() - 6;
        final hy = (b.y - oy).round() - 2;
        return overlaySombreritoOnFrog(base, hx, hy);
      });
      out.add(RegalosItem(spr, ox, oy, fsy, at.d, tag: 'coqui'));
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
    RegalosItem it,
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
      final al = (p['al'] as num?)?.toDouble() ?? 1.0;
      if (al <= 0.5) continue;
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
    return out;
  }

  /* ---------- talk bubbles (all 8 speakers) ---------- */

  @override
  List<num>? talkAt(String who, Map<String, dynamic> W) {
    if (who == 'coqui') {
      final q = W['cq'] as Map<String, dynamic>?;
      if (q == null || !jsTruthy(q['vis'])) return null;
      final b = host.frogBox(q);
      return [b.x + b.w / 2, b.y - 4];
    }
    final gente = (W['gente'] as Map<String, dynamic>?) ?? const {};
    final p = gente[who] as Map<String, dynamic>?;
    if (p == null || p['vis'] == 0) return null;
    final at = _atOf(p);
    final dy = switch (who) {
      'luis' || 'carmen' => 42,
      _ => 52,
    };
    return [_round(at.sx) + _n(p['dx']), _round(at.sy) + _n(p['dy']) - dy];
  }

  /* ---------- touch things & hit testing (all 19 Needs things) ---------- */

  static List<int>? _itemBox(
    List<RegalosItem> list,
    bool Function(RegalosItem) test,
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

  // Small interactive items come before people/curtain/stool so every overlapping thing answers touches cleanly.
  List<Thing> _things() => [
    for (final fk in REGALOS_FOTOS)
      Thing(
        id: fk,
        si: (w) => (w['fotoPos'] as Map?)?[fk] is String,
        box: (w) => _spriteBox(w, 'cosa:$fk'),
      ),
    Thing(
      id: 'bizcocho',
      si: (w) => w['bizcochoAt'] is String,
      box: (w) => _spriteBox(w, 'cosa:bizcocho'),
    ),
    Thing(
      id: 'regalo',
      si: (w) => w['regaloAt'] is String,
      box: (w) => _spriteBox(w, 'cosa:regalo'),
    ),
    Thing(
      id: 'flores',
      si: (w) => w['floresAt'] is String,
      box: (w) => _spriteBox(w, 'cosa:flores'),
    ),
    Thing(
      id: 'caja_velas',
      si: (w) => _n(w['cajaVelasVis']) == 1,
      box: (w) => _spriteBox(w, 'cosa:caja_velas') ?? _p.spotBox('caja_velas'),
    ),
    Thing(
      id: 'paquete',
      si: (w) => _n(w['paqueteStoolVis']) == 1,
      box: (w) => _spriteBox(w, 'cosa:paquete') ?? _p.spotBox('paquete'),
    ),
    for (final who in REGALOS_PERSONAS)
      Thing(
        id: who,
        si: (w) => ((w['gente'] as Map?)?[who] as Map?)?['vis'] != 0,
        box: (w) => _spriteBox(w, 'persona:$who'),
      ),
    Thing(
      id: 'cortina',
      si: (w) {
        final c = w['cortinaState'];
        return c == 'half' || c == 'shut';
      },
      box: (w) =>
          _spriteBox(w, 'cosa:cortina') ??
          (w['cortinaState'] == 'half' ? _p.curtainHalfBox : _p.box('cortina')),
    ),
    Thing(id: 'banqueta', box: (w) => _p.box('banqueta')),
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

  /* ---------- frog hop & loose acts ---------- */

  Future<void> _hopToSpot(String spot) async {
    if (!_p.has(spot)) return;
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

  final List<Future<void>> _loose = [];

  @override
  List<num> remap(List<num> xy) => xy;

  @override
  Future<void> stake(int lost, int max, String en) async {}

  @override
  Map<String, Act> get ownActs => _buildOwnActs();
}
