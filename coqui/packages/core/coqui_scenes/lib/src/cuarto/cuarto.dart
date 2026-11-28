// El cuarto (place 9, La casa, un día entero, scene 1: `cuarto`; stories 96 to 98): a NEW scene, written from
// its script's "Needs" list (historia/notas/guiones/cuarto.md) on its set (cuarto_set.dart) and its sheet
// (cuarto-sheet.json, read by SceneSheet). Every act is in cuarto_acts.dart; every place, box, hang metadata, view,
// depth bias, and shadow comes from the sheet. Unstated placements or behaviors are marked `OPEN:`.
//
// The drawing (the sheet's `front`):
// - Upright sprites stand with their feet resting on sy (`d + (sy - (Y + 0.5)) * tan(30 deg) / S`).
// - Hung-in-bed sprites (`cama_luis`, `cama_carmen`, `sentado_luis`, `sentado_carmen`) hang down from their head on
//   the pillow (`ay = 0`, cut at `hang.rows = 40`, blanket from `lying: 24` or `sitting: 30`), using the mattress
//   plane (`front.hung`: `(2 * COS / S) * (Y + 0.5 - OY) + 2 * hang.z + dd`).
// - Small things anchor at bottom-middle (`almohada`, `plato`, `campana`, `bebe`, `zetas`, `nariz`, `ropa_*`), or at
//   knees (`manta_abuelo`, `at: [8, 6]`, `dd: 0.02`).
// - Every sprite pixel is hidden by any baked set pixel nearer than its plane + `front.bias` (0.3); between sprites,
//   the nearer pixel wins (tie within 0.001 goes to the later layer).
// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/src/colmado/colmado_cast.dart' show inkBottom;
import 'package:coqui_scenes/src/cuarto/cuarto_places.dart';
import 'package:coqui_scenes/src/cuarto/cuarto_set.dart';
import 'package:coqui_scenes/src/cuarto/cuarto_sprites.dart';
import 'package:coqui_scenes/src/scene_set.dart';
import 'package:coqui_scenes/src/sheet_cache.dart';

part 'cuarto_acts.dart';

/// The scene "El cuarto", made from its sheet (read first: `loadScene`).
Scene createCuarto() => Cuarto(sceneSheetOf('cuarto'));

int _round(num v) => (v + 0.5).floor();

int _n(Object? v) {
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? 0;
  return 0;
}

/// One sprite of the sprite layer, placed: its picture, top-left on 240 x 216, anchor row [sy], depth [d],
/// optional [hungZ] for `front.hung` mattress-plane sprites, and [dd] depth offset.
class CuartoItem {
  CuartoItem(
    this.s,
    this.left,
    this.top,
    this.sy,
    this.d, {
    this.tag,
    this.overlay = false,
    this.hungZ,
    this.dd = 0.0,
  });

  final Sprite s;
  final int left, top;
  final num sy;
  final double d;
  final String? tag;
  final bool overlay;
  final double? hungZ;
  final double dd;
}

/// People in El cuarto (excluding `bebe`, `perro`, `coqui`).
const List<String> CUARTO_PERSONAS = ['abuela', 'abuelo', 'luis', 'carmen'];

/// Every speaker key supported by [Cuarto.talkAt] (all 7 speakers in cuarto.md Needs & gen_cuarto.py).
const List<String> CUARTO_SPEAKERS = [
  'abuela',
  'abuelo',
  'luis',
  'carmen',
  'bebe',
  'perro',
  'coqui',
];

class Cuarto extends Escena implements SetScene, SetOverSprites {
  Cuarto(this.ss)
    : sheet = identical(ss, _lastSs)
          ? _lastSheet!
          : (_lastSheet = ss.legacy()) {
    _p = identical(ss, _lastSs)
        ? _lastPlaces!
        : (_lastPlaces = CuartoPlaces(ss));
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
  static CuartoPlaces? _lastPlaces;

  /// The new scene's sheet (SceneSheet).
  final SceneSheet ss;

  @override
  final Sheet sheet;

  late final CuartoPlaces _p;

  /// The scene's places, from its sheet.
  CuartoPlaces get places => _p;

  @override
  String get id => 'cuarto';

  @override
  late final Map<String, List<num>> CAM;

  late final Map<String, List<num>> LUGAR;

  @override
  Map<String, List<num>> get lugar => LUGAR;

  @override
  late final List<Thing> cosas;

  @override
  PpEngine newEngine({bool still = false}) => cuartoEngine(still: still);

  @override
  PpEngine get projection => _p.e;

  List<num> _frogAt(CuartoAt a) => [_round(a.sx) - 16, _round(a.sy) - 25, 1];

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
    bool dormido = false,
  }) {
    final w = _p.world(spot);
    return <String, dynamic>{
      'x': w[0],
      'y': w[1],
      'z': w[2],
      'spot': spot,
      'vis': vis,
      'pose': 'idle',
      'sent': sent,
      'dormido': dormido ? 1 : 0,
      'al': 1.0,
      'dx': 0,
      'dy': 0,
    };
  }

  void _placePerson(
    Map<String, dynamic> p,
    String spot, {
    int? sent,
    bool? dormido,
  }) {
    final w = _p.world(spot);
    p['x'] = w[0];
    p['y'] = w[1];
    p['z'] = w[2];
    p['spot'] = spot;
    p['vis'] = 1;
    p['dx'] = 0;
    p['dy'] = 0;
    if (sent != null) p['sent'] = sent;
    if (dormido != null) p['dormido'] = dormido ? 1 : 0;
  }

  @override
  Map<String, dynamic> fresh(Map<String, dynamic> story) {
    final acts = _actsOf([story['beats'], story['final']]);
    bool has(String a) => acts.any((o) => o['act'] == a);
    final is98 =
        has('silla98') ||
        has('zapatos98') ||
        has('corrige98') ||
        has('viste98') ||
        has('pelo98') ||
        has('final98');
    final is97 =
        !is98 &&
        (has('reloj97') ||
            has('zetas') ||
            has('campana97') ||
            has('manta97') ||
            has('corre97') ||
            has('final97'));
    final storyNum = is98 ? 98 : (is97 ? 97 : 96);
    final startSpot = is98 ? 'alfombra2' : (is97 ? 'mesita_coqui' : 'alfombra');
    final q = _frogAt(_p.at(startSpot));

    final gente = <String, dynamic>{
      'abuela': _person('puerta'),
      'abuelo': _person(
        'butaca_abuelo',
        vis: is97 ? 1 : 0,
        sent: 1,
        dormido: true,
      ),
      'luis': _person(is98 ? 'vestir' : 'cama_luis', dormido: !is98),
      'carmen': _person(
        is98 ? 'sentado_carmen' : 'cama_carmen',
        dormido: !is98,
      ),
    };

    return <String, dynamic>{
      'story': storyNum,
      'hora': storyNum == 96 ? 'alba' : 'manana',
      'luz': 0,
      'cuna': storyNum == 97 ? 1 : 0,
      'butaca': storyNum == 97 ? 1 : 0,
      'gente': gente,
      // Bed blanket flags (on while someone lies/sits under the blanket in 96 & 97)
      'mantaLuisVis': storyNum == 98 ? 0 : 1,
      'mantaCarmenVis': 1,
      'mantaAbueloVis': storyNum == 97 ? 1 : 0,
      // Story 96 state
      'platoVis': storyNum == 96 ? 1 : 0,
      'plato': storyNum == 96 ? 3 : 0,
      'almohadaVis': 0,
      'almohadaPos': 'almohada_suelo',
      'perroVis': storyNum == 96 ? 1 : 0,
      'perroSpot': 'bajo_cama',
      'perroPose': 'nariz',
      'luisCamisa96': storyNum == 96 ? 0 : 1,
      'found96': null,
      'coquiDuerme': 0,
      // Story 97 state
      'relojHora': storyNum == 97 ? 7.0 : null,
      'campanaVis': storyNum == 97 ? 1 : 0,
      'zetas': storyNum == 97 ? 3 : 0,
      'bebeState': 'sleep',
      'abuelaSilencio': 0,
      'carmenPies': 0,
      'tinkleFx': 0,
      'gritoFx': 0,
      // Story 98 state
      'sillaA': null,
      'sillaB': null,
      'luisTrousers': 0,
      'luisShoes': 0,
      'luisShirt': 0,
      'luisHat': 0,
      'luisWatch': 0,
      'luisTumbled': 0,
      'pelo98': 3,
      'abuelaFoto': storyNum == 98 ? 1 : 0,
      'abuelaFotoUp': 0,
      'flashFx': 0,
      'fotoCard': 0,
      // Shared FX & HUD
      'finalCelebrar': 0,
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
  String setKey(Map<String, dynamic> W) => CuartoState.fromWorld(W).key;

  @override
  void buildSet(PpEngine e, PpBuild b, Map<String, dynamic> W) =>
      buildSetFor(e, b, setKey(W));

  final Map<PpEngine, CuartoSet> _sets = {};

  @override
  void buildSetFor(PpEngine e, PpBuild b, String key) =>
      (_sets[e] ??= CuartoSet(e, b)).buildSet(CuartoState.fromKey(key));

  @override
  bool get frogShadow => false;

  /* ---------- where everybody is ---------- */

  Map<String, dynamic> get _gente => W['gente'] as Map<String, dynamic>;

  CuartoAt _atOf(Map<String, dynamic> o) =>
      _p.atWorld(o['x'] as num, o['y'] as num, o['z'] as num);

  CuartoAt _frogPoint(Map<String, dynamic> q) {
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
    'palpa' => 'ojos',
    _ => 'idle',
  };

  ({Sprite s, int ax, int ay, double? hungZ}) _personSprite(
    String id,
    Map<String, dynamic> p,
    Map<String, dynamic> w,
    bool open,
    int anim,
  ) {
    final pose = (p['pose'] as String?) ?? 'idle';
    final spot = (p['spot'] as String?) ?? '';
    final dormido = _n(p['dormido']) == 1;
    final sent = _n(p['sent']) == 1;
    final kp = _kitPoseOf(pose);

    if (id == 'abuela') {
      final sil = _n(w['abuelaSilencio']) == 1;
      final foto = _n(w['abuelaFoto']) == 1 || spot == 'foto';
      final fotoUp = _n(w['abuelaFotoUp']) == 1;
      final s = _spr(
        'ct_ab_${kp}_${open}_${sil}_${foto}_$fotoUp',
        () => mkAbuelaCuarto(
          pose: kp,
          open: open,
          silencio: sil,
          foto: foto,
          fotoUp: fotoUp,
        ),
      );
      return (s: s, ax: 30, ay: inkBottom(s), hungZ: null);
    }

    if (id == 'abuelo') {
      if (sent || spot == 'butaca_abuelo') {
        final s = _spr(
          'ct_aoS_${kp}_${open}_$dormido',
          () => mkAbueloArmchair(dormido: dormido, open: open, pose: kp),
        );
        return (s: s, ax: PX, ay: cuartoSeatedLap(FAM['abuelo']!), hungZ: null);
      }
      final s = _spr(
        'ct_ao_${kp}_$open',
        () => mkPersona(FAM['abuelo']!, kp, open, false),
      );
      return (s: s, ax: PX, ay: inkBottom(s), hungZ: null);
    }

    // Luis or Carmen
    final hang = _p.hang(spot);
    if (hang != null) {
      final isLuis = id == 'luis';
      final isLying = spot == 'cama_luis' || spot == 'cama_carmen';
      final baseWho = FAM[isLuis ? 'hermano' : 'hermana']!;
      final Who who;
      if (isLuis && _n(w['story']) == 96 && _n(w['luisCamisa96']) == 0) {
        // In story 96 before shirt is found, Luis sits/lies in pyjamas.
        who = Who(
          nino: true,
          piel: baseWho.piel,
          pelo: baseWho.pelo,
          peinado: baseWho.peinado,
          ropa: _ramp(const ['#5A82B8', '#7BA4D8', '#A6C8F0', '#CBE0FA']),
          abajo: _ramp(const ['#4A70A4', '#6B92C6', '#8FB4E2']),
          dormido: dormido,
        );
      } else {
        who = baseWho.copyWith(dormido: dormido);
      }
      final blanketOn = isLuis
          ? _n(w['mantaLuisVis']) == 1
          : _n(w['mantaCarmenVis']) == 1;
      final blanketFrom = blanketOn
          ? (isLying ? hang.lyingFrom : hang.sittingFrom)
          : null;
      final bedColor = _p.beds[hang.bed];
      final s = _spr(
        'ct_bed_${id}_${hang.bed}_${blanketFrom}_${dormido}_${kp}_${open}_${w['luisCamisa96']}',
        () => mkInBed(
          who,
          bedColor,
          hang,
          blanketFrom: blanketFrom,
          pose: kp,
          open: open,
        ),
      );
      return (s: s, ax: PX, ay: 0, hungZ: hang.z);
    }

    if (id == 'luis' && _n(w['story']) == 98) {
      final tr = _n(w['luisTrousers']) == 1;
      final sh = _n(w['luisShoes']) == 1;
      final sr = _n(w['luisShirt']) == 1;
      final ht = _n(w['luisHat']) == 1;
      final wt = _n(w['luisWatch']) == 1;
      final nt = _n(w['pelo98']).clamp(1, 3);
      final tb = _n(w['luisTumbled']) == 1;
      final s = _spr(
        'ct_lv_${tr}_${sh}_${sr}_${ht}_${wt}_${nt}_${tb}_${kp}_${open}_$dormido',
        () => mkLuisVestir(
          trousers: tr,
          shoes: sh,
          shirt: sr,
          hat: ht,
          watch: wt,
          neat: nt,
          pose: kp,
          open: open,
          dormido: dormido,
          tumbled: tb,
        ),
      );
      return (
        s: s,
        ax: PX,
        ay: tb ? cuartoSeatedLap(FAM['hermano']!) : inkBottom(s),
        hungZ: null,
      );
    }

    if (id == 'carmen') {
      final pies = _n(w['carmenPies']) == 1;
      final s = _spr(
        'ct_ca_${kp}_${open}_$pies',
        () => mkCarmenCuarto(pose: kp, open: open, pies: pies),
      );
      return (s: s, ax: PX, ay: inkBottom(s), hungZ: null);
    }

    final s = _spr(
      'ct_lu_${kp}_${open}_$dormido',
      () => mkPersona(
        FAM['hermano']!.copyWith(dormido: dormido),
        kp,
        open,
        false,
      ),
    );
    return (s: s, ax: PX, ay: inkBottom(s), hungZ: null);
  }

  static List<int> _ramp(List<String> hs) => [for (final s in hs) hexColour(s)];

  String? _talker() {
    try {
      return host.TALK;
    } catch (_) {
      return null;
    }
  }

  /// Every sprite of the frame [w] as it is placed, except the frog. The rules' tests read it; [draw] draws it.
  List<CuartoItem> items(Map<String, dynamic> w, int a) {
    final out = <CuartoItem>[];
    final talk = _talker();
    final gente = (w['gente'] as Map<String, dynamic>?) ?? const {};
    final anim = (F >> 2) + a;

    // 1. People (abuela, abuelo, luis, carmen)
    for (final id in CUARTO_PERSONAS) {
      final p = gente[id] as Map<String, dynamic>?;
      if (p == null || p['vis'] == 0) continue;
      final open = talk == id && a % 2 == 1;
      final sp = _personSprite(id, p, w, open, anim);
      final at = _atOf(p);
      final sx = _round(at.sx) + _n(p['dx']);
      final sy = _round(at.sy) + _n(p['dy']);
      out.add(
        CuartoItem(
          sp.s,
          sx - sp.ax,
          sy - sp.ay,
          sy,
          at.d,
          tag: 'persona:$id',
          hungZ: sp.hungZ,
        ),
      );
    }

    // 2. Blanket on abuelo's knees (`manta_abuelo`, anchor `at: [8, 6]`, `dd: 0.02`)
    if (_n(w['mantaAbueloVis']) == 1) {
      final at = _p.at('manta_abuelo');
      final offset = _p.spotAtOffset('manta_abuelo') ?? const [8, 6];
      final s = _spr('ct_manta_abuelo', mkMantaAbuelo);
      final sx = _round(at.sx), sy = _round(at.sy);
      out.add(
        CuartoItem(
          s,
          sx - offset[0],
          sy - offset[1],
          sy,
          at.d + .02,
          tag: 'cosa:manta_abuelo',
        ),
      );
    }

    // 3. Canelo (`bajo_cama` nose or `junto_mesita` sitting/licking)
    if (_n(w['perroVis']) == 1) {
      final pSpot = (w['perroSpot'] as String?) ?? 'bajo_cama';
      final pPose = (w['perroPose'] as String?) ?? 'nariz';
      final at = _p.at(pSpot);
      final sx = _round(at.sx), sy = _round(at.sy);
      if (pSpot == 'bajo_cama' || pPose == 'nariz') {
        final s = _spr('ct_nariz', mkNariz);
        out.add(
          CuartoItem(
            s,
            sx - s.w ~/ 2,
            sy - s.h,
            sy,
            at.d,
            tag: 'persona:perro',
          ),
        );
      } else {
        final pf = pPose == 'lick' ? anim % 2 : 0;
        final s = _spr(
          'ct_perro_${pPose}_$pf',
          () => mkPerroCuarto(pPose, frame: pf),
        );
        final ax = inkMid(s), ay = inkBottom(s);
        out.add(
          CuartoItem(s, sx - ax, sy - ay, sy, at.d, tag: 'persona:perro'),
        );
      }
    }

    // 4. Night table items (`plato`, `campana`)
    if (_n(w['platoVis']) == 1) {
      final n = _n(w['plato']).clamp(0, 3);
      final at = _p.at('plato');
      final s = _spr('ct_plato_$n', () => mkPlatoCuarto(n));
      final sx = _round(at.sx), sy = _round(at.sy);
      out.add(
        CuartoItem(s, sx - s.w ~/ 2, sy - s.h, sy, at.d, tag: 'cosa:plato'),
      );
    }
    if (_n(w['campanaVis']) == 1) {
      final at = _p.at('campana');
      final s = _spr('ct_campana', mkCampana);
      final sx = _round(at.sx), sy = _round(at.sy);
      out.add(
        CuartoItem(s, sx - s.w ~/ 2, sy - s.h, sy, at.d, tag: 'cosa:campana'),
      );
    }

    // 5. Big pillow on the floor (`almohada_suelo`)
    if (_n(w['almohadaVis']) == 1) {
      final pos = (w['almohadaPos'] as String?) ?? 'almohada_suelo';
      final at = _p.at(pos);
      final s = _spr('ct_almohada', mkAlmohada);
      final sx = _round(at.sx), sy = _round(at.sy);
      out.add(
        CuartoItem(s, sx - s.w ~/ 2, sy - s.h, sy, at.d, tag: 'cosa:almohada'),
      );
    }

    // 6. Baby and Z's in cradle (when `cuna == 1`)
    if (_n(w['cuna']) == 1) {
      final bs = (w['bebeState'] as String?) ?? 'sleep';
      final at = _p.at('bebe');
      final s = _spr('ct_bebe_$bs', () => mkBebeCuarto(bs));
      final sx = _round(at.sx), sy = _round(at.sy);
      out.add(
        CuartoItem(s, sx - s.w ~/ 2, sy - s.h, sy, at.d, tag: 'cosa:bebe'),
      );
      final zn = _n(w['zetas']).clamp(0, 3);
      if (zn > 0) {
        final zat = _p.at('zetas');
        final zs = _spr('ct_zetas_$zn', () => mkZetas(zn));
        final zsx = _round(zat.sx), zsy = _round(zat.sy);
        out.add(
          CuartoItem(
            zs,
            zsx - zs.w ~/ 2,
            zsy - zs.h,
            zsy,
            zat.d,
            tag: 'fx:zetas',
          ),
        );
      }
    }

    // 7. Clothes on chair (`ropa_a` on seat, `ropa_b` on back)
    final ropaA = w['sillaA'] as String?;
    if (ropaA != null && ropaA.isNotEmpty) {
      final at = _p.at('ropa_a');
      final s = _spr('ct_ropa_$ropaA', () => mkRopaCuarto(ropaA));
      final sx = _round(at.sx), sy = _round(at.sy);
      out.add(
        CuartoItem(s, sx - s.w ~/ 2, sy - s.h, sy, at.d, tag: 'cosa:ropa_a'),
      );
    }
    final ropaB = w['sillaB'] as String?;
    if (ropaB != null && ropaB.isNotEmpty) {
      final at = _p.at('ropa_b');
      final s = _spr('ct_ropa_$ropaB', () => mkRopaCuarto(ropaB));
      final sx = _round(at.sx), sy = _round(at.sy);
      out.add(
        CuartoItem(s, sx - s.w ~/ 2, sy - s.h, sy, at.d, tag: 'cosa:ropa_b'),
      );
    }

    // 8. Clock hands (`reloj97`, projected from `things.reloj.quad`)
    final rh = w['relojHora'];
    if (rh is num) {
      final hVal = rh.toDouble();
      final cc = _p.clockCenter;
      final s = _spr('ct_reloj_$hVal', () => mkManecillas(hVal));
      final cx = _round(cc.sx), cy = _round(cc.sy);
      out.add(
        CuartoItem(
          s,
          cx - s.w ~/ 2,
          cy - s.h ~/ 2,
          cy + s.h ~/ 2,
          cc.d + .05,
          tag: 'fx:reloj',
        ),
      );
    }

    // 9. Found item in story 96 (`busca96`)
    // OPEN: `busca96` found camisa/zapatos placed beside Luis's bed at (54, 116) so it stays clear of busca_cama,
    // cama, junto_mesita, and luz.
    final found = w['found96'] as String?;
    if (found != null && found.isNotEmpty) {
      final s = _spr('ct_ropa_$found', () => mkRopaCuarto(found));
      final d = _p.at('busca_cama').d;
      out.add(CuartoItem(s, 48, 106, 116, d, tag: 'fx:found96'));
    }

    // 10. Transient FX (tinkle, howl, camera flash, photo card, gesture cue, 3-of-3 celebration)
    if (_n(w['tinkleFx']) == 1) {
      final cb = _p.spotBox('campana');
      final s = _spr('ct_tinkle_${anim % 2}', () => mkTinkleFx(anim % 2));
      out.add(
        CuartoItem(s, cb[0] - 4, cb[1] - 8, cb[1], 1.2, tag: 'fx:tinkle'),
      );
    }
    if (_n(w['gritoFx']) == 1) {
      final s = _spr('ct_grito_${anim % 2}', () => mkGritoFx(anim % 2));
      final gr =
          gente['abuelo']?['vis'] != 0 &&
              (gente['abuelo']?['spot'] == 'pie_abuelo')
          ? _atOf(gente['abuelo'] as Map<String, dynamic>)
          : _atOf(gente['luis'] as Map<String, dynamic>);
      final gx = _round(gr.sx), gy = _round(gr.sy) - 52;
      out.add(
        CuartoItem(s, gx - s.w ~/ 2, gy, gy + s.h, gr.d + .05, tag: 'fx:grito'),
      );
    }
    if (_n(w['flashFx']) == 1) {
      final at = _p.at('foto');
      final s = _spr('ct_flash', mkFlashCuarto);
      final fx = _round(at.sx) - 6, fy = _round(at.sy) - 42;
      out.add(CuartoItem(s, fx, fy, fy + s.h, at.d + .08, tag: 'fx:flash'));
    }
    final fotoCard = _n(w['fotoCard']);
    if (fotoCard >= 1 && fotoCard <= 3) {
      // OPEN: final98 photo card shown above abuela at `foto` (x=169, y=20), clear of her head and all sprites.
      final at = _p.at('foto');
      final s = _spr('ct_fotocard_$fotoCard', () => mkFotoCard(fotoCard));
      out.add(CuartoItem(s, 169, 20, 44, at.d + .08, tag: 'fx:foto_card'));
    }
    final gc = w['gestoCue'];
    if (gc is Map) {
      final isSelf = gc['self'] == true;
      final isUp = gc['up'] == true;
      final s = _spr(
        'ct_gcue_${isSelf}_$isUp',
        () => mkGestoFlechaCuarto(self: isSelf, up: isUp),
      );
      final cx = _n(gc['cueX']);
      final cy = _n(gc['cueY']);
      final cd = (gc['d'] as num?)?.toDouble() ?? 6.0;
      out.add(CuartoItem(s, cx - 4, cy, cy + 7, cd, tag: 'fx:gesto_cue'));
    }
    if (_n(w['finalCelebrar']) == 1) {
      final st = _spr('ct_star', mkEstrellaCuarto);
      final hr = _spr('ct_heart', mkCorazonCuarto);
      out.add(CuartoItem(st, 82, 12, 21, 6.0, tag: 'fx:estrella1'));
      out.add(CuartoItem(hr, 97, 11, 21, 6.0, tag: 'fx:corazon'));
      out.add(CuartoItem(st, 114, 12, 21, 6.0, tag: 'fx:estrella2'));
    }

    return out;
  }

  static final Map<String, Sprite> _frogSprites = {};

  /// [items] plus the frog (as the host draws him), for `draw` and for `CuartoRules`.
  List<CuartoItem> placed(Map<String, dynamic> w, int a) {
    final out = items(w, a);
    final q = w['cq'] as Map<String, dynamic>?;
    if (q != null && jsTruthy(q['vis'])) {
      final at = _frogPoint(q);
      final dx = _n(q['dx']);
      final fsy = _round(at.sy);
      if (_n(w['coquiDuerme']) == 1) {
        final s = _spr('ct_cq_duerme', mkCoquiDuerme);
        final sx = _round(at.sx) + dx;
        out.add(
          CuartoItem(
            s,
            sx - 16,
            fsy - 19 + _n(q['dy']),
            fsy,
            at.d,
            tag: 'coqui',
          ),
        );
      } else {
        final b = host.frogBox(q);
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
        out.add(CuartoItem(spr, ox, oy, fsy, at.d, tag: 'coqui'));
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
    CuartoItem it,
    int w0,
    int h0,
    Float32List? setZ,
    double bias,
    double S,
    double COS,
    double OY,
  ) {
    final layer = _layer!, lz = _layerZ!, sp = it.s;
    final sw = sp.w, sh = sp.h;
    final spx = sp.px;
    for (var py = 0; py < sh; py++) {
      final Y = it.top + py;
      if (Y < 0 || Y >= h0) continue;
      final plane = it.overlay
          ? it.d
          : (it.hungZ != null
                ? (2 * COS / S) * (Y + .5 - OY) + 2 * it.hungZ! + it.dd
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
    final setZ = _setZ,
        bias = _p.bias,
        S = _p.e.S,
        COS = _p.e.COS,
        OY = _p.e.OY;
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
        _put(it, w0, h0, setZ, bias, S, COS, OY);
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
    if (_n(W['perroVis']) == 1) {
      final pSpot = (W['perroSpot'] as String?) ?? 'bajo_cama';
      if (!_p.noShadow(pSpot)) {
        final at = _p.at(pSpot);
        final r = _p.radius('perro');
        if (at.z == 0 && r != null) {
          out.add((x: at.x, y: at.y, z: 0.0, r: r));
        }
      }
    }
    final q = W['cq'] as Map<String, dynamic>?;
    if (q != null && jsTruthy(q['vis'])) {
      final al = (q['al'] as num?)?.toDouble() ?? 1.0;
      final qSpot = q['spot'] as String?;
      final qz = (q['z'] as num?)?.toDouble() ?? 0.0;
      if (al > 0.5 && qz == 0 && (qSpot == null || !_p.noShadow(qSpot))) {
        final at = _frogPoint(q);
        final r = _p.radius('coqui');
        if (r != null) {
          out.add((x: at.x, y: at.y, z: 0.0, r: r));
        }
      }
    }
    return out;
  }

  /* ---------- talk bubbles (all 7 speakers) ---------- */

  @override
  List<num>? talkAt(String who, Map<String, dynamic> W) {
    if (who == 'coqui') {
      final q = W['cq'] as Map<String, dynamic>?;
      if (q == null || !jsTruthy(q['vis'])) return null;
      final b = host.frogBox(q);
      return [b.x + b.w / 2, b.y - 4];
    }
    if (who == 'bebe') {
      if (_n(W['cuna']) != 1) return null;
      final at = _p.at('bebe');
      return [_round(at.sx), _round(at.sy) - 14];
    }
    if (who == 'perro') {
      if (_n(W['perroVis']) != 1) return null;
      final pSpot = (W['perroSpot'] as String?) ?? 'bajo_cama';
      final at = _p.at(pSpot);
      return [_round(at.sx), _round(at.sy) - (pSpot == 'bajo_cama' ? 12 : 24)];
    }
    final gente = (W['gente'] as Map<String, dynamic>?) ?? const {};
    final p = gente[who] as Map<String, dynamic>?;
    if (p == null) return null;
    if (p['vis'] == 0) {
      // When abuela calls from the kitchen in story 97 steps 6-7, talkAt('abuela') returns puerta head position.
      if (who == 'abuela') {
        final at = _p.at('puerta');
        return [_round(at.sx), _round(at.sy) - 50];
      }
      return null;
    }
    final at = _atOf(p);
    final spot = (p['spot'] as String?) ?? '';
    final int dy;
    if (who == 'abuela') {
      dy = 50;
    } else if (who == 'abuelo') {
      dy = spot == 'butaca_abuelo' ? 40 : 53;
    } else if (_p.hang(spot) != null) {
      // In bed: `at.sy` is top of head on pillow.
      dy = 4;
    } else {
      dy = 42;
    }
    return [_round(at.sx) + _n(p['dx']), _round(at.sy) + _n(p['dy']) - dy];
  }

  /* ---------- touch things & hit testing (all 20 Needs things) ---------- */

  static List<int>? _itemBox(
    List<CuartoItem> list,
    bool Function(CuartoItem) test,
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
    Thing(
      id: 'almohada',
      si: (w) => _n(w['almohadaVis']) == 1,
      box: (w) =>
          _spriteBox(w, 'cosa:almohada') ?? _p.spotBox('almohada_suelo'),
    ),
    Thing(
      id: 'campana',
      si: (w) => _n(w['campanaVis']) == 1,
      box: (w) => _spriteBox(w, 'cosa:campana') ?? _p.spotBox('campana'),
    ),
    Thing(
      id: 'plato',
      si: (w) => _n(w['platoVis']) == 1,
      box: (w) => _spriteBox(w, 'cosa:plato') ?? _p.spotBox('plato'),
    ),
    Thing(
      id: 'ropa_a',
      si: (w) => w['sillaA'] is String && (w['sillaA'] as String).isNotEmpty,
      box: (w) => _spriteBox(w, 'cosa:ropa_a') ?? _p.spotBox('ropa_a'),
    ),
    Thing(
      id: 'ropa_b',
      si: (w) => w['sillaB'] is String && (w['sillaB'] as String).isNotEmpty,
      box: (w) => _spriteBox(w, 'cosa:ropa_b') ?? _p.spotBox('ropa_b'),
    ),
    Thing(
      id: 'manta_abuelo',
      si: (w) => _n(w['mantaAbueloVis']) == 1,
      box: (w) =>
          _spriteBox(w, 'cosa:manta_abuelo') ?? _p.spotBox('manta_abuelo'),
    ),
    Thing(
      id: 'manta_carmen',
      si: (w) => _n(w['mantaCarmenVis']) == 1,
      box: (w) => _p.box('manta_carmen'),
    ),
    Thing(
      id: 'manta_luis',
      si: (w) => _n(w['mantaLuisVis']) == 1,
      box: (w) => _p.box('manta_luis'),
    ),
    for (final who in const ['luis', 'carmen', 'abuela', 'abuelo'])
      Thing(
        id: who,
        si: (w) => ((w['gente'] as Map?)?[who] as Map?)?['vis'] != 0,
        box: (w) => _spriteBox(w, 'persona:$who'),
      ),
    Thing(
      id: 'bebe',
      si: (w) => _n(w['cuna']) == 1,
      box: (w) => _spriteBox(w, 'cosa:bebe') ?? _p.spotBox('bebe'),
    ),
    Thing(
      id: 'perro',
      si: (w) => _n(w['perroVis']) == 1,
      box: (w) => _spriteBox(w, 'persona:perro'),
    ),
    Thing(
      id: 'cuna',
      si: (w) => _n(w['cuna']) == 1,
      box: (w) => _p.box('cuna'),
    ),
    Thing(id: 'reloj', box: (w) => _p.box('reloj')),
    Thing(id: 'luz', box: (w) => _p.box('luz')),
    Thing(id: 'silla', box: (w) => _p.box('silla')),
    Thing(id: 'cama', box: (w) => _p.box('cama')),
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
    // In story 96, `cama` is asked/decided (not `manta_luis`), so tapping Luis's bed hits `cama` first.
    final is96 = _n(w['story']) == 96;
    if (is96) {
      final cb = _p.box('cama');
      final luisBox = _spriteBox(w, 'persona:luis');
      // Let Luis's head hit `luis`, and the rest of his bed hit `cama`.
      if (luisBox != null &&
          x >= luisBox[0] &&
          x < luisBox[0] + luisBox[2] &&
          y >= luisBox[1] &&
          y < luisBox[1] + 14) {
        return 'luis';
      }
      final mb = _p.box('manta_luis');
      if (x >= mb[0] &&
          x < mb[0] + mb[2] &&
          y >= mb[1] &&
          y < mb[1] + mb[3] &&
          !(x >= cb[0] &&
              x < cb[0] + cb[2] &&
              y >= cb[1] &&
              y < cb[1] + cb[3])) {
        if (_n(w['mantaLuisVis']) == 1) return 'manta_luis';
      }
      if (x >= cb[0] && x < cb[0] + cb[2] && y >= cb[1] && y < cb[1] + cb[3]) {
        return 'cama';
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

  /* ---------- gesture cue targets & frog hop ---------- */

  ({int sx, int sy, int cueX, int cueY, bool up, double d})? _targetScreen(
    String? target,
    Map<String, dynamic> w,
  ) {
    if (target == null || target.isEmpty) return null;
    if (target == 'cuna') {
      final b = _p.box('cuna');
      final cx = b[0] + b[2] ~/ 2;
      return (sx: cx, sy: b[1], cueX: cx, cueY: b[1] - 9, up: false, d: 1.5);
    }
    final gente = (w['gente'] as Map<String, dynamic>?) ?? const {};
    if (gente[target] is Map) {
      final p = gente[target] as Map<String, dynamic>;
      if (p['vis'] == 0) return null;
      final at = _atOf(p);
      final sx = _round(at.sx) + _n(p['dx']);
      final sy = _round(at.sy) + _n(p['dy']);
      return (
        sx: sx,
        sy: sy,
        cueX: sx,
        cueY: (sy - 46).clamp(16, 180),
        up: false,
        d: at.d + .06,
      );
    }
    if (_p.has(target)) {
      final at = _p.at(target);
      final sx = _round(at.sx), sy = _round(at.sy);
      return (
        sx: sx,
        sy: sy,
        cueX: sx,
        cueY: sy - 20,
        up: false,
        d: at.d + .06,
      );
    }
    return null;
  }

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

  /* ---------- loose acts & delegated acts (cuarto_acts.dart) ---------- */

  final List<Future<void>> _loose = [];

  @override
  List<num> remap(List<num> xy) => xy;

  @override
  Future<void> stake(int lost, int max, String en) async {}

  @override
  Map<String, Act> get ownActs => _buildOwnActs();
}
