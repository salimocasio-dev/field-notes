// El quiosco (place 6, La plaza, scene 3: `quiosco`; stories 66 to 68): a NEW scene, written from its script's "Needs"
// list (historia/notas/guiones/quiosco.md) on its set (quiosco_set.dart) and its sheet (quiosco-sheet.json, read by
// SceneSheet). There is no old scene file: every act is this file's, each doing on screen what the Needs list says,
// every place from the sheet (spots, set thing boxes, cup sign disc, facing, depth rule, shadows). Where the sheet
// names no place, or the script and sheet disagree on a detail, the act does the plainest thing that keeps the story
// playing and says so in a comment starting `OPEN:`.
//
// The drawing (the sheet's `front`): every sprite stands with its feet's bottom edge on its spot's row and its middle
// on its column (rules.anchor); sitting people hang by the lap; a sprite pixel is hidden by every set pixel nearer
// than the upright plane through its feet plus `front.bias` (front.plane); between two sprites the nearer pixel wins.
// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/src/colmado/colmado_cast.dart' show inkBottom;
import 'package:coqui_scenes/src/plaza/plaza_cast.dart' show plazaNino;
import 'package:coqui_scenes/src/quiosco/quiosco_places.dart';
import 'package:coqui_scenes/src/quiosco/quiosco_set.dart';
import 'package:coqui_scenes/src/quiosco/quiosco_sprites.dart';
import 'package:coqui_scenes/src/scene_set.dart';
import 'package:coqui_scenes/src/sheet_cache.dart';

/// The scene "El quiosco", made from its sheet (read first: `loadScene`).
Scene createQuiosco() => Quiosco(sceneSheetOf('quiosco'));

int _round(num v) => (v + 0.5).floor();

int _n(Object? v) {
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? 0;
  return 0;
}

/// One sprite of the sprite layer, placed: its picture, its top left on the 240 × 216 picture, the screen row of its
/// feet and the depth there (front.plane), and who or what it is.
class QuioscoItem {
  QuioscoItem(this.s, this.left, this.top, this.sy, this.d, {this.tag});

  final Sprite s;
  final int left, top;
  final num sy;
  final double d;
  final String? tag;
}

/// Every person El quiosco knows, by speaker key (quiosco.md, "Needs").
const List<String> QUIOSCO_PERSONAS = [
  'vendedor',
  'maestra',
  'doctor',
  'cocinero',
  'policia',
  'senor',
  'senora',
  'hombre',
  'mujer',
  'joven',
  'la_joven',
  'nino',
  'nina',
  'beto',
  'ana',
  'carmen',
  'luis',
  'abuela',
  'mama_ana',
];

const List<String> _LIMBER_COLORS = ['rojo', 'amarillo', 'blanco'];

bool _isSeatedSpot(String spot) =>
    spot.startsWith('taburete') || spot == 'mesa_a' || spot == 'mesa_b';

bool _isChild(String id) => id == 'nino' || id == 'nina' || plazaNino(id);

class Quiosco extends Escena implements SetScene, SetOverSprites {
  Quiosco(this.ss)
    : sheet = identical(ss, _lastSs)
          ? _lastSheet!
          : (_lastSheet = ss.legacy()) {
    _p = identical(ss, _lastSs)
        ? _lastPlaces!
        : (_lastPlaces = QuioscoPlaces(ss));
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
  static QuioscoPlaces? _lastPlaces;

  /// The new scene's sheet (SceneSheet).
  final SceneSheet ss;

  @override
  final Sheet sheet;

  late final QuioscoPlaces _p;

  /// The scene's places, from its sheet.
  QuioscoPlaces get places => _p;

  @override
  String get id => 'quiosco';

  @override
  late final Map<String, List<num>> CAM;

  late final Map<String, List<num>> LUGAR;

  @override
  Map<String, List<num>> get lugar => LUGAR;

  @override
  late final List<Thing> cosas;

  @override
  PpEngine newEngine({bool still = false}) => quioscoEngine(still: still);

  @override
  PpEngine get projection => _p.e;

  List<num> _frogAt(QuioscoAt a) => [_round(a.sx) - 16, _round(a.sy) - 25, 1];

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

  Map<String, dynamic> _person(String spot, {int vis = 1, int? sent}) {
    final w = _p.world(spot);
    final s = sent ?? (_isSeatedSpot(spot) ? 1 : 0);
    return <String, dynamic>{
      'x': w[0],
      'y': w[1],
      'z': w[2],
      'spot': spot,
      'vis': vis,
      'dir': _p.faceOf(spot),
      'pose': 'idle',
      'sent': s,
      'dx': 0,
      'dy': 0,
    };
  }

  @override
  Map<String, dynamic> fresh(Map<String, dynamic> story) {
    final acts = _actsOf([story['beats'], story['final']]);
    bool has(String a) => acts.any((o) => o['act'] == a);
    final set = _firstSet(story['beats']);
    final is68 = _n(set['fiesta']) == 1 || has('torre68') || has('velas');
    final is67 = !is68 && (has('tapa67') || has('limbers') || has('saca67'));
    final is66 = !is68 && !is67;

    final gente = <String, dynamic>{};
    final String start;
    if (is68) {
      gente['vendedor'] = _person('detras');
      gente['ana'] = _person('taburete1', sent: 1);
      gente['beto'] = _person('taburete2', sent: 1);
      gente['carmen'] = _person('taburete3', sent: 1);
      gente['luis'] = _person('pie1', sent: 0);
      gente['abuela'] = _person('mesa_a', sent: 1);
      gente['mama_ana'] = _person('mesa_b', sent: 1);
      start = 'barra_e';
    } else if (is67) {
      gente['vendedor'] = _person('detras');
      gente['abuela'] = _person('mesa_a', sent: 1);
      gente['carmen'] = _person('mesa_b', sent: 1);
      gente['luis'] = _person('pie1', sent: 0);
      start = 'mesa';
    } else {
      gente['vendedor'] = _person('detras');
      gente['luis'] = _person('mesa_a', sent: 1);
      gente['carmen'] = _person('mesa_b', sent: 1);
      start = 'barra_c';
    }

    final q = _frogAt(_p.at(start));
    final hora = set['hora'] is String
        ? set['hora'] as String
        : (is66 ? 'mediodia' : 'tarde');
    return <String, dynamic>{
      'cam': 'wide',
      'hora': hora,
      'fiesta': is68 ? 1 : 0,
      'gente': gente,
      // Story 66: glass dome quesitos, frog's drink tray, saucer quesito, ending
      'quesitos': is66 ? 3 : null,
      'cupulaAbierta': 0,
      'bandeja': null,
      'platico': null,
      'final66': null,
      'pitoHasta': 0,
      // Story 67: box, forgotten item over frog's head, limbers, chef hat, paper hat
      'caja': is67 ? 1 : 0,
      'cajaEstado': 'cerrada',
      'cosaCabeza': null,
      'senorGorro': 0,
      'coquiGorro': 0,
      'limbers': is67 ? 3 : null,
      'derretidos': 0,
      'final67': null,
      'caneloLimber': 0,
      // Story 68: Beto's tower, candle 5, crown, tray candles, child bizcochos, broken bizcocho
      'torre': is68 ? 3 : null,
      'torreVela5': 0,
      'torreLit': 0,
      'torreHumo': 0,
      'betoCorona': is68 ? 1 : 0,
      'coronaVuelaHasta': 0,
      'velas': null,
      'bizcochos': <String, int>{},
      'bizcochoRoto': 0,
      'caneloRoto': 0,
      'final68': null,
      // Shared gestures
      'dedos': null,
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
    final hora = h is String && const ['mediodia', 'tarde'].contains(h)
        ? h
        : 'mediodia';
    return '$hora-${_n(W['fiesta']) == 1 ? 1 : 0}';
  }

  @override
  void buildSet(PpEngine e, PpBuild b, Map<String, dynamic> W) =>
      buildSetFor(e, b, setKey(W));

  final Map<PpEngine, QuioscoSet> _sets = {};

  @override
  void buildSetFor(PpEngine e, PpBuild b, String key) =>
      (_sets[e] ??= QuioscoSet(e, b)).buildSet(QuioscoState.fromKey(key));

  @override
  bool get frogShadow => false;

  /* ---------- where everybody is ---------- */

  Map<String, dynamic> get _gente => W['gente'] as Map<String, dynamic>;

  QuioscoAt _atOf(Map<String, dynamic> o) =>
      _p.atWorld(o['x'] as num, o['y'] as num, o['z'] as num);

  QuioscoAt _frogPoint(Map<String, dynamic> q) {
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

  bool _spotOccupied(String spot) {
    for (final v in _gente.values) {
      if (v is Map && v['vis'] != 0 && v['spot'] == spot) return true;
    }
    return false;
  }

  // OPEN: `gen_quiosco.py` sets `START_BARRA = "barra1"` at the start of stories 66 and 68 ("on the counter beside the
  // tray"). On quiosco-sheet.json, `barra1` [75,116] is 23 px sideways × 7 px down from `taburete2` [52,109] (occupied
  // by `doctor` in 66 and `beto` in 68), whereas the preview's moments place the frog at `barra_c` (story 66) and
  // `barra_e` (story 68). Map `barra1` to those counter spots so the frog stays clear of `taburete2`.
  String _resolveSpot(String key) {
    if (key == 'barra1') {
      if (W['torre'] != null || _n(W['fiesta']) == 1) return 'barra_e';
      if (W['quesitos'] != null) return 'barra_c';
    }
    return key;
  }

  // OPEN: In story 67 step 3, `gen_quiosco.py` seats `senor` at `taburete2` [52,109] (whereas quiosco-preview.html
  // moment 3 seats `joven`/`senor` at `taburete4`/`taburete3`). While `taburete2` is occupied, holding the box item at
  // `barra2` [80,100] (28 px clear of `taburete2`, verified by `frog-stool`) avoids overlapping `senor`'s 24 px box;
  // once `taburete2` is empty (rounds A and B), the frog stands at `barra_caja` [75,105] as in moment 4.
  String _boxFrogSpot() => _spotOccupied('taburete2') ? 'barra2' : 'barra_caja';

  /* ---------- sprites ---------- */

  static final Map<String, Sprite> _sprites = {};
  static Sprite _spr(String key, Sprite Function() make) =>
      _sprites[key] ??= make();

  static final Map<String, Sprite> _mirrored = {};
  static Sprite _mirror(String key, Sprite s) => _mirrored[key] ??= () {
    final px = Uint32List(s.w * s.h);
    for (var y = 0; y < s.h; y++) {
      for (var x = 0; x < s.w; x++) {
        px[y * s.w + (s.w - 1 - x)] = s.px[y * s.w + x];
      }
    }
    return Sprite(s.w, s.h, px);
  }();

  ({Sprite s, int ax, int ay, String key}) _personSprite(
    String id,
    Map<String, dynamic> p,
    bool open,
    Map<String, dynamic> w,
  ) {
    final sent = _n(p['sent']) == 1;
    var pose = (p['pose'] as String?) ?? 'idle';
    if (id == 'abuela') {
      // rules.anchor: abuela sitting mkAbuelaS (52 × 50): column 17 and row 36 (her lap) on (sx, sy)
      final abPose = pose == 'sienta' ? 'idle' : pose;
      final k = 'abS$abPose$open';
      final s = _spr(k, () => mkAbuelaS(abPose, open, false));
      return (s: s, ax: 17, ay: 36, key: k);
    }
    if (sent && (pose == 'idle' || pose == 'arrodilla')) pose = 'sienta';
    final corona = id == 'beto' && _n(w['betoCorona']) == 1;
    final gorro = id == 'senor' && _n(w['senorGorro']) == 1;
    final key = 'q_${id}_${pose}_${open}_${corona}_$gorro';
    final s = _spr(
      key,
      () => mkQuioscoPersona(
        id,
        pose,
        open: open,
        corona: corona,
        gorroCocinero: gorro,
      ),
    );
    final seated = pose == 'sienta';
    // rules.anchor: sitting mkPersona (sent = 1) hangs by lap row (s.h - 8 for both adults and children)
    return (s: s, ax: PX, ay: seated ? s.h - 8 : inkBottom(s), key: key);
  }

  String? _talker() {
    try {
      return host.TALK;
    } catch (_) {
      return null;
    }
  }

  /// Every sprite of the frame [w] as it is placed, except the frog. The rules' tests read it; [draw] draws it.
  List<QuioscoItem> items(Map<String, dynamic> w, int a) {
    final out = <QuioscoItem>[];
    final talk = _talker();
    final gente = (w['gente'] as Map<String, dynamic>?) ?? const {};

    // 1. People
    for (final en in gente.entries) {
      final p = en.value as Map<String, dynamic>;
      if (p['vis'] == 0) continue;
      final open = talk == en.key && a % 2 == 1;
      final sp = _personSprite(en.key, p, open, w);
      final at = _atOf(p);
      // Never mirror seated abuela (asymmetric mkAbuelaS keeps her inside x0 = 22)
      final dir = (en.key == 'abuela' && _n(p['sent']) == 1)
          ? 1
          : (_n(p['dir']) < 0 ? -1 : 1);
      final s = dir < 0 ? _mirror(sp.key, sp.s) : sp.s;
      final ax = dir < 0 ? sp.s.w - 1 - sp.ax : sp.ax;
      final sx = _round(at.sx) + _n(p['dx']);
      final sy = _round(at.sy) + _n(p['dy']);
      out.add(
        QuioscoItem(s, sx - ax, sy - sp.ay, sy, at.d, tag: 'persona:${en.key}'),
      );
      // Whistle puff beside policía when he blows his whistle
      if (en.key == 'policia' && F < _n(w['pitoHasta'])) {
        final f = (F >> 1) % 2;
        final wv = _spr('pito$f', () => mkPitoOnda(f));
        out.add(
          QuioscoItem(
            wv,
            sx + (dir < 0 ? -16 : 6),
            sy - 30,
            sy,
            at.d + .04,
            tag: 'cosa:pito',
          ),
        );
      }
      // Flying paper crown above Beto when he blows out his birthday candle
      if (en.key == 'beto' && F < _n(w['coronaVuelaHasta'])) {
        final cr = _spr('corona', mkCorona);
        final lift = ((F % 12) + 1) * 2;
        out.add(
          QuioscoItem(
            cr,
            sx - cr.w ~/ 2 + 6,
            sy - 38 - lift,
            sy,
            at.d + .05,
            tag: 'cosa:corona_vuela',
          ),
        );
      }
    }

    // 2. Story 66: glass dome at barra_izq, saucer quesito, and ending quesitos
    final qs = w['quesitos'];
    if (qs is num) {
      final at = _p.at('barra_izq');
      final sx = _round(at.sx), sy = _round(at.sy);
      final open = _n(w['cupulaAbierta']) == 1;
      final n = qs.toInt().clamp(0, 3);
      final s = _spr('cupula_${n}_$open', () => mkCupula(n, abierta: open));
      out.add(
        QuioscoItem(
          s,
          sx - s.w ~/ 2,
          sy - inkBottom(s),
          sy,
          at.d,
          tag: 'cosa:quesitos',
        ),
      );
    }
    if (w['platico'] is String) {
      final who = w['platico'] as String;
      final spot = switch (who) {
        'maestra' => 'barra1',
        'doctor' => 'barra2',
        'cocinero' => 'barra3',
        _ => 'barra4',
      };
      final at = _p.at(spot);
      final sx = _round(at.sx), sy = _round(at.sy);
      final s = _spr('quesito_plato', mkQuesitoPlato);
      out.add(
        QuioscoItem(
          s,
          sx - s.w ~/ 2,
          sy - inkBottom(s),
          sy,
          at.d + .02,
          tag: 'cosa:platico',
        ),
      );
    }
    if (w['final66'] is num) {
      // Ending quesitos on the table (`mesa`) for Luis, Carmen, and Coquí
      final n = (w['final66'] as num).toInt().clamp(1, 3);
      final at = _p.at('mesa');
      final sx = _round(at.sx), sy = _round(at.sy);
      final whole = _spr('quesito_plato', mkQuesitoPlato);
      final piece = _spr('quesito_trozo', () => mkQuesitoPlato(trozo: true));
      out.add(
        QuioscoItem(
          n >= 2 ? whole : piece,
          sx - 10,
          sy - inkBottom(whole),
          sy,
          at.d + .02,
          tag: 'cosa:final66_a',
        ),
      );
      out.add(
        QuioscoItem(
          n >= 2 ? whole : piece,
          sx + 1,
          sy - inkBottom(whole),
          sy,
          at.d + .02,
          tag: 'cosa:final66_b',
        ),
      );
      if (n >= 3) {
        out.add(
          QuioscoItem(
            whole,
            sx - 5,
            sy - inkBottom(whole) - 3,
            sy,
            at.d + .03,
            tag: 'cosa:final66_c',
          ),
        );
      }
    }

    // 3. Story 67: box at barra_fin, three limbers along right wing (`limbers`), Canelo at melted cups
    if (_n(w['caja']) == 1) {
      final at = _p.at('barra_fin');
      final sx = _round(at.sx), sy = _round(at.sy);
      final st = (w['cajaEstado'] as String?) ?? 'cerrada';
      final s = _spr('caja_$st', () => mkCajaQuiosco(st));
      out.add(
        QuioscoItem(
          s,
          sx - s.w ~/ 2,
          sy - inkBottom(s),
          sy,
          at.d,
          tag: 'cosa:caja',
        ),
      );
    }
    if (w['limbers'] is num) {
      final melted = _n(w['derretidos']).clamp(0, 3);
      // Row runs back along the right wing (.6, .3, 0 in -v): draw back-to-front
      for (var i = 2; i >= 0; i--) {
        final at = _p.atUvOffset('limbers', 0, -0.3 * i);
        final sx = _round(at.sx), sy = _round(at.sy);
        final isMelted = i >= (3 - melted);
        final col = _LIMBER_COLORS[i];
        final s = _spr(
          'limber_${col}_$isMelted',
          () => mkLimber(col, derretido: isMelted),
        );
        out.add(
          QuioscoItem(
            s,
            sx - s.w ~/ 2,
            sy - inkBottom(s),
            sy,
            at.d,
            tag: 'cosa:limber_$i',
          ),
        );
      }
    }
    if (_n(w['caneloLimber']) == 1) {
      // OPEN: story 67 ending (n = 1): Canelo laps below the right wing beside the melted cups (no spot on sheet).
      final xy = _p.xyOf(1.8, 2.3);
      final at = _p.atWorld(xy[0], xy[1], 0);
      final s = _spr('perro_eat_${a % 2}', () => mkPerro('eat', a % 2 == 1));
      final sx = _round(at.sx), sy = _round(at.sy);
      out.add(
        QuioscoItem(
          s,
          sx - 15,
          sy - inkBottom(s),
          sy,
          at.d,
          tag: 'cosa:canelo',
        ),
      );
    }

    // 4. Story 68: Beto's tower at barra_izq, candles tray + vela_a/b/c, child bizcochos, broken bizcocho + Canelo
    if (w['torre'] is num) {
      final at = _p.at('barra_izq');
      final sx = _round(at.sx), sy = _round(at.sy);
      final n = (w['torre'] as num).toInt().clamp(1, 3);
      final v5 = _n(w['torreVela5']) == 1;
      final lit = _n(w['torreLit']) == 1;
      final humo = _n(w['torreHumo']) == 1;
      final s = _spr(
        'torre_${n}_${v5}_${lit}_$humo',
        () => mkTorre68(n, vela5: v5, encendida: lit, humo: humo),
      );
      out.add(
        QuioscoItem(
          s,
          sx - s.w ~/ 2,
          sy - inkBottom(s),
          sy,
          at.d,
          tag: 'cosa:torre',
        ),
      );
    }
    final velas = w['velas'];
    if (velas is Map) {
      // Tray plate under vela_a..c (quiosco-preview.html moment 6: at vela_b, px [0, 1], dd -.06)
      final tb = _p.at('vela_b');
      final tr = _spr('bandeja_velas', mkBandejaVelas);
      final tsx = _round(tb.sx), tsy = _round(tb.sy) + 1;
      out.add(
        QuioscoItem(
          tr,
          tsx - tr.w ~/ 2,
          tsy - inkBottom(tr),
          tsy,
          tb.d - .06,
          tag: 'cosa:bandeja_velas',
        ),
      );
      for (final slot in const ['a', 'b', 'c']) {
        final v = _n(velas[slot]);
        if (v <= 0) continue;
        final at = _p.at('vela_$slot');
        final sx = _round(at.sx), sy = _round(at.sy);
        final s = _spr('vela_${slot}_$v', () => mkVelaNumero(v, slot));
        out.add(
          QuioscoItem(
            s,
            sx - s.w ~/ 2,
            sy - inkBottom(s),
            sy,
            at.d,
            tag: 'cosa:vela_$slot',
          ),
        );
      }
    }
    if (_n(w['bizcochoRoto']) == 1) {
      final at = _p.at('barra_c');
      final sx = _round(at.sx), sy = _round(at.sy);
      final s = _spr('bizcocho_roto', () => mkBizcocho(roto: true));
      out.add(
        QuioscoItem(
          s,
          sx - s.w ~/ 2,
          sy - inkBottom(s),
          sy,
          at.d + .02,
          tag: 'cosa:bizcocho_roto',
        ),
      );
    }
    if (_n(w['caneloRoto']) == 1) {
      // OPEN: story 68 wrong move: Canelo eats the broken bizcocho pieces below the counter (no spot on sheet).
      final xy = _p.xyOf(1.6, 2.8);
      final at = _p.atWorld(xy[0], xy[1], 0);
      final s = _spr('perro_eat_${a % 2}', () => mkPerro('eat', a % 2 == 1));
      final sx = _round(at.sx), sy = _round(at.sy);
      out.add(
        QuioscoItem(
          s,
          sx - 15,
          sy - inkBottom(s),
          sy,
          at.d,
          tag: 'cosa:canelo',
        ),
      );
    }
    // Small bizcochos received by children (drawn near the counter edge in front of them, clear of candles)
    final biz = (w['bizcochos'] as Map?) ?? const {};
    for (final en in biz.entries) {
      final who = en.key as String;
      if (who == 'ana' || who == 'carmen') {
        final p = gente[who] as Map<String, dynamic>?;
        if (p == null || p['vis'] == 0) continue;
        final at = _p.at(who == 'ana' ? 'barra1' : 'barra3');
        final s = _spr('bizcocho_vela', () => mkBizcocho(vela: true));
        final sx = _round(at.sx) + (who == 'carmen' ? 8 : 0);
        final sy = _round(at.sy);
        out.add(
          QuioscoItem(
            s,
            sx - s.w ~/ 2,
            sy - inkBottom(s),
            sy,
            at.d + .02,
            tag: 'cosa:biz_$who',
          ),
        );
      }
    }

    // 5. Held-up fingers badge (`gesto` `dedos`)
    final dedos = w['dedos'];
    if (dedos is Map) {
      final who = dedos['quien'] as String?;
      final n = _n(dedos['n']);
      if (who != null && n > 0) {
        final s = _spr('dedos_$n', () => mkDedos(n));
        if (who == 'coqui') {
          final q = w['cq'] as Map<String, dynamic>;
          final at = _frogPoint(q);
          final sx = _round(at.sx) + 14;
          final sy = _round(at.sy) - 18;
          out.add(
            QuioscoItem(
              s,
              sx - s.w ~/ 2,
              sy - s.h ~/ 2,
              _round(at.sy),
              at.d + .04,
              tag: 'cosa:dedos',
            ),
          );
        } else if (gente[who] is Map) {
          final p = gente[who] as Map<String, dynamic>;
          final at = _atOf(p);
          final sx = _round(at.sx) + 14;
          final sy = _round(at.sy) - 24;
          out.add(
            QuioscoItem(
              s,
              sx - s.w ~/ 2,
              sy - s.h ~/ 2,
              _round(at.sy),
              at.d + .04,
              tag: 'cosa:dedos',
            ),
          );
        }
      }
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
    _setZ = baked.zb;
  }

  static final double _t30 = math.tan(math.pi / 6);

  void _put(
    QuioscoItem it,
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
        if (setZ != null && setZ[i] > plane + bias) continue;
        if (lz[i] > plane + .001) continue;
        lz[i] = plane;
        layer[i] = c;
      }
    }
  }

  static final Map<String, Sprite> _frogSprites = {};

  /// [items] and the frog (with anything he carries on his head: story 66 tray, story 67 box item, story 67 paper hat).
  List<QuioscoItem> placed(Map<String, dynamic> W, int a) {
    final all = items(W, a);
    final q = W['cq'] as Map<String, dynamic>;
    if (jsTruthy(q['vis'])) {
      final b = host.frogBox(q), at = _frogPoint(q);
      final dx = _n(q['dx']);
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
      final fsy = _round(at.sy);
      final fsx = _round(at.sx) + dx;
      all.add(QuioscoItem(spr, ox, oy, fsy, at.d, tag: 'coqui'));

      // Things carried on the frog's head (quiosco-preview.html: px [0, -24], dd .02, held by coqui)
      final bandeja = W['bandeja'];
      if (bandeja is Map) {
        final que = bandeja['que'] as String?;
        final der = _n(bandeja['derramado']) == 1;
        final tr = _spr(
          'bandeja_${que}_$der',
          () => mkBandejaRana(que, derramado: der),
        );
        final ty = fsy - 24 + _n(q['dy']);
        all.add(
          QuioscoItem(
            tr,
            fsx - tr.w ~/ 2,
            ty - inkBottom(tr),
            ty,
            at.d + .02,
            tag: 'held:bandeja_rana',
          ),
        );
      }
      final cosa = W['cosaCabeza'];
      if (cosa is String) {
        final cs = _spr('cosa67_$cosa', () => mkCosa67(cosa));
        final ty = fsy - 24 + _n(q['dy']);
        all.add(
          QuioscoItem(
            cs,
            fsx - cs.w ~/ 2,
            ty - inkBottom(cs),
            ty,
            at.d + .02,
            tag: 'held:cosa_cabeza',
          ),
        );
      }
      if (_n(W['coquiGorro']) == 1) {
        final gp = _spr('gorro_coqui', mkGorroPapelCoqui);
        final ty = fsy - 24 + _n(q['dy']);
        all.add(
          QuioscoItem(
            gp,
            fsx - gp.w ~/ 2,
            ty - inkBottom(gp),
            ty,
            at.d + .02,
            tag: 'held:coqui_gorro',
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
    void cast(QuioscoAt at, double? r) {
      if (r == null || at.z != 0) return;
      out.add((x: at.x, y: at.y, z: 0, r: r));
    }

    final gente = (W['gente'] as Map<String, dynamic>?) ?? const {};
    for (final en in gente.entries) {
      final p = en.value as Map<String, dynamic>;
      if (p['vis'] == 0 || jsTruthy(p['sent'])) continue;
      if (_p.noShadow((p['spot'] as String?) ?? '')) continue;
      cast(
        _atOf(p),
        _p.radius(en.key) ??
            _p.sheet.shadows.radius[_isChild(en.key) ? 'ninos' : 'adultos'],
      );
    }
    final q = W['cq'] as Map<String, dynamic>?;
    if (q != null && jsTruthy(q['vis']) && (q['z'] as num? ?? 0) == 0) {
      final at = _frogPoint(q);
      if (at.sx >= 0) cast(at, _p.radius('coqui'));
    }
    return out;
  }

  /* ---------- the things he can touch ---------- */

  static final Expando<List<int>> _inkOf = Expando<List<int>>();

  static List<num>? _inkBox(QuioscoItem it) {
    final s = it.s;
    final had = _inkOf[s];
    if (had != null) {
      return had.isEmpty
          ? null
          : [it.left + had[0], it.top + had[1], had[2], had[3]];
    }
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
    if (x1 < 0) {
      _inkOf[s] = const [];
      return null;
    }
    _inkOf[s] = [x0, y0, x1 - x0 + 1, y1 - y0 + 1];
    return [it.left + x0, it.top + y0, x1 - x0 + 1, y1 - y0 + 1];
  }

  /// The screen box of a placed sprite (its drawn pixels' bounds).
  static List<num>? inkBox(QuioscoItem it) => _inkBox(it);

  int? _boxesF;
  Map<String, dynamic>? _boxesW;
  Map<String, List<num>?> _boxes = {};

  List<num>? _boxOfTag(Map<String, dynamic> w, String tag) {
    int? f;
    try {
      f = host.F;
    } catch (_) {
      f = null;
    }
    if (f == null || f != _boxesF || !identical(w, _boxesW)) {
      _boxes = {
        for (final it in items(w, 0))
          if (it.tag != null) it.tag!: _inkBox(it),
      };
      _boxesF = f;
      _boxesW = w;
    }
    return _boxes[tag];
  }

  List<num>? _limbersBox(Map<String, dynamic> w) {
    num? x0, y0, x1, y1;
    for (var i = 0; i < 3; i++) {
      final b = _boxOfTag(w, 'cosa:limber_$i');
      if (b == null) continue;
      x0 = x0 == null ? b[0] : math.min(x0, b[0]);
      y0 = y0 == null ? b[1] : math.min(y0, b[1]);
      x1 = x1 == null ? b[0] + b[2] : math.max(x1, b[0] + b[2]);
      y1 = y1 == null ? b[1] + b[3] : math.max(y1, b[1] + b[3]);
    }
    return x0 == null ? null : [x0, y0!, x1! - x0, y1! - y0];
  }

  List<Thing> _things() {
    Thing sprite(String id, String tag, {num m = 0, bool z = false}) => Thing(
      id: id,
      m: m,
      z: z,
      si: (w) => _boxOfTag(w, tag) != null,
      box: (Map<String, dynamic> w) => _boxOfTag(w, tag),
    );
    Thing setThing(String id, {num m = 0}) {
      final b = _p.box(id);
      return Thing(
        id: id,
        m: m,
        world: _p.worldBox(id),
        box: [b[0], b[1], b[2], b[3]],
      );
    }

    return [
      // Set things (pokes)
      setThing('quiosco'),
      setThing('letrero'),
      setThing('barra'),
      setThing('taburetes'),
      setThing('mesa'),
      // Small sprite things
      sprite('quesitos', 'cosa:quesitos', m: 2, z: true),
      sprite('torre', 'cosa:torre', m: 2, z: true),
      sprite('caja', 'cosa:caja', m: 2, z: true),
      Thing(
        id: 'limbers',
        m: 2,
        z: true,
        si: (w) => _limbersBox(w) != null,
        box: _limbersBox,
      ),
      sprite('vela_a', 'cosa:vela_a', m: 2, z: true),
      sprite('vela_b', 'cosa:vela_b', m: 2, z: true),
      sprite('vela_c', 'cosa:vela_c', m: 2, z: true),
      // People
      for (final id in QUIOSCO_PERSONAS) sprite(id, 'persona:$id', z: true),
      // Coquí
      Thing(
        id: 'coqui',
        m: 2,
        z: true,
        si: (w) => jsTruthy((w['cq'] as Map)['vis']),
        box: (Map<String, dynamic> w) {
          final b = host.frogBox(w['cq'] as Map<String, dynamic>);
          return [b.x, b.y, b.w, b.h];
        },
      ),
    ];
  }

  Future<void> _brinco() async {
    final q = W['cq'] as Map<String, dynamic>;
    for (final d in const [-5, -7, -4, 0]) {
      q['dy'] = d;
      await wait(TICK);
    }
  }

  @override
  Future<void> stake(int lost, int max, String en) async {
    host.SFX.bonk();
    await wait(300);
  }

  @override
  List<num> remap(List<num> xy) => xy;

  @override
  List<num>? talkAt(String who, Map<String, dynamic> W) {
    final b = _boxOfTag(W, 'persona:$who');
    if (b == null) return null;
    return [_round(b[0] + b[2] / 2), b[1] - 1];
  }

  @override
  dynamic poke(String what) {
    host.SFX.toc();
    return null;
  }

  /* ---------- the acts ---------- */

  Future<void> _hopTo(String spot, {int steps = 10}) async {
    final target = _resolveSpot(spot);
    if (!_p.has(target)) return;
    final at = _p.at(target);
    final to = _frogAt(at);
    final q = W['cq'] as Map<String, dynamic>;
    final x0 = (q['x'] as num).toDouble(), y0 = (q['y'] as num).toDouble();
    final z0 = (q['z'] as num? ?? 0).toDouble();
    for (var i = 1; i <= steps; i++) {
      final t = i / steps;
      q['x'] = x0 + (to[0] - x0) * t;
      q['y'] = y0 + (to[1] - y0) * t;
      q['z'] = z0 + (at.z - z0) * t;
      q['dy'] = (-math.sin(t * math.pi) * 10).round();
      await wait(TICK);
    }
    q['x'] = to[0];
    q['y'] = to[1];
    q['z'] = at.z;
    q['dy'] = 0;
    q['spot'] = target;
  }

  Future<void> _walkTo(
    Map<String, dynamic> p,
    String spot, {
    int steps = 12,
    bool sitAtEnd = false,
  }) async {
    final w = _p.world(spot);
    final x0 = (p['x'] as num).toDouble(),
        y0 = (p['y'] as num).toDouble(),
        z0 = (p['z'] as num).toDouble();
    p['sent'] = 0;
    p['pose'] = 'idle';
    for (var i = 1; i <= steps; i++) {
      final t = i / steps;
      p['x'] = x0 + (w[0] - x0) * t;
      p['y'] = y0 + (w[1] - y0) * t;
      p['z'] = z0 + (w[2] - z0) * t;
      p['dy'] = i.isOdd ? -1 : 0;
      await wait(TICK);
    }
    p['x'] = w[0];
    p['y'] = w[1];
    p['z'] = w[2];
    p['dy'] = 0;
    p['spot'] = spot;
    p['sent'] = sitAtEnd ? 1 : 0;
    p['dir'] = _p.faceOf(spot);
  }

  String _barSpotFor(String target) {
    final p = _gente[target] as Map<String, dynamic>?;
    final sp = p?['spot'] as String?;
    return switch (sp) {
      'taburete1' => 'barra1',
      'taburete2' => 'barra2',
      'taburete3' => 'barra3',
      'taburete4' => 'barra4',
      _ => 'barra_c',
    };
  }

  final List<Future<void>> _sueltos = [];

  @override
  Map<String, Act> get ownActs {
    final own = _acts();
    return {
      for (final e in own.entries)
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
  }

  Map<String, Act> _acts() => {
    'ya': (o) async {
      final all = List<Future<void>>.of(_sueltos);
      _sueltos.clear();
      await Future.wait(all);
    },
    'ir': (o) async {
      final a = o['a'] as String?;
      if (a == null) return;
      await _hopTo(a);
    },
    'llega': (o) async {
      final quien = o['quien'] as String?;
      var a = o['a'] as String?;
      if (quien == null || a == null || !_p.has(a)) return;
      // OPEN: in story 68 step 5, `gen_quiosco.py` sends `nina` to `cola2` [137,132] (directly in front of Coquí at
      // `barra_e` [146,96]), whereas `quiosco-preview.html` moment 6 places her at `cola3` [103,151] behind `nino`.
      // Keep her at `cola3` in story 68 so `frog-seen` holds (she steps up to `cola1` for round B).
      if (quien == 'nina' && a == 'cola2' && W['torre'] != null) {
        a = 'cola3';
      }
      var p = _gente[quien] as Map<String, dynamic>?;
      if (p == null || p['vis'] == 0) {
        p = _person('entrada', vis: 1, sent: 0);
        _gente[quien] = p;
      }
      await _walkTo(p, a, sitAtEnd: _isSeatedSpot(a));
    },
    'sale': (o) async {
      final quien = o['quien'] as String?;
      if (quien == null) return;
      final p = _gente[quien] as Map<String, dynamic>?;
      if (p == null || p['vis'] == 0) return;
      final oldSpot = p['spot'] as String?;
      await _walkTo(p, 'entrada', steps: 10, sitAtEnd: false);
      p['vis'] = 0;
      // Once `taburete2` frees in story 67, hop frog from `barra2` back to `barra_caja` (clear of `cola1`).
      final q = W['cq'] as Map<String, dynamic>;
      if (oldSpot == 'taburete2' && W['caja'] == 1 && q['spot'] == 'barra2') {
        await _hopTo('barra_caja', steps: 6);
      }
    },
    // Story 66
    'quesitos': (o) async {
      W['quesitos'] = _n(o['n']).clamp(0, 3);
      await wait(120);
    },
    'sirve66': (o) async {
      final que = (o['que'] as String?) ?? 'cafe';
      // OPEN: holding the 22 × 10 tray on the frog's head at `barra_c` [120,96] overlaps the vendedor's head rows
      // [55..68] behind the counter; hop to `barra_e` [146,96] while carrying the tray so `vendedor-head` stays clear.
      await _hopTo('barra_e', steps: 6);
      final v = _gente['vendedor'] as Map<String, dynamic>?;
      if (v != null) v['pose'] = 'mano';
      await wait(180);
      W['bandeja'] = <String, dynamic>{'que': que, 'derramado': 0};
      if (v != null) v['pose'] = 'idle';
      await wait(160);
    },
    'lleva66': (o) async {
      final a = o['a'] as String?;
      final ok = _n(o['ok']) == 1;
      if (a == null) return;
      final dest = _barSpotFor(a);
      await _hopTo(dest, steps: 8);
      final p = _gente[a] as Map<String, dynamic>?;
      if (ok) {
        if (p != null) {
          p['pose'] = 'mano';
          p['dy'] = -2;
        }
        await wait(240);
        W['bandeja'] = null;
        if (p != null) {
          p['pose'] = 'idle';
          p['dy'] = 0;
        }
        await _hopTo('barra_c', steps: 8);
      } else {
        if (p != null) p['pose'] = 'hombros';
        final cur = W['bandeja'];
        final que = cur is Map ? (cur['que'] as String? ?? 'cafe') : 'cafe';
        W['bandeja'] = <String, dynamic>{'que': que, 'derramado': 1};
        await wait(240);
        if (p != null) p['pose'] = 'idle';
        await _hopTo('barra_e', steps: 8);
      }
    },
    'quesito66': (o) async {
      final a = o['a'] as String?;
      final v = _gente['vendedor'] as Map<String, dynamic>?;
      if (v != null) v['pose'] = 'saluda0';
      await wait(160);
      W['bandeja'] = null;
      W['platico'] = a;
      if (v != null) v['pose'] = 'idle';
      await wait(200);
      W['platico'] = null;
    },
    'final66': (o) async {
      final n = _n(o['n']).clamp(1, 3);
      W['cupulaAbierta'] = 1;
      W['quesitos'] = 0;
      W['bandeja'] = null;
      W['platico'] = null;
      W['final66'] = n;
      await wait(320);
    },
    // Story 67
    'tapa67': (o) async {
      final v = _gente['vendedor'] as Map<String, dynamic>?;
      if (v != null) v['pose'] = 'mano';
      await wait(180);
      W['cajaEstado'] = 'abierta';
      if (v != null) v['pose'] = 'idle';
      await wait(160);
    },
    'saca67': (o) async {
      final cosa = (o['cosa'] as String?) ?? 'libro';
      W['cajaEstado'] = 'abierta';
      await _hopTo(_boxFrogSpot(), steps: 8);
      W['cosaCabeza'] = cosa;
      await wait(200);
    },
    'lleva67': (o) async {
      final cosa = (o['cosa'] as String?) ?? (W['cosaCabeza'] as String?);
      final a = o['a'] as String?;
      final ok = _n(o['ok']) == 1;
      if (a == null) return;
      final dest = _barSpotFor(a);
      await _hopTo(dest, steps: 8);
      final p = _gente[a] as Map<String, dynamic>?;
      if (ok) {
        if (p != null) {
          p['pose'] = 'mano';
          p['dy'] = -2;
        }
        if (cosa == 'gorro' && a == 'senor') {
          W['senorGorro'] = 1;
        }
        W['cosaCabeza'] = null;
        await wait(240);
        if (p != null) {
          p['pose'] = 'idle';
          p['dy'] = 0;
        }
        await _hopTo(_boxFrogSpot(), steps: 8);
      } else {
        if (p != null) p['pose'] = 'hombros';
        await wait(240);
        if (p != null) p['pose'] = 'idle';
        await _hopTo(_boxFrogSpot(), steps: 8);
        W['cosaCabeza'] = cosa;
      }
    },
    'limbers': (o) async {
      final n = _n(o['n']).clamp(0, 3);
      W['limbers'] = n;
      W['derretidos'] = (3 - n).clamp(0, 3);
      await wait(120);
    },
    'derrite67': (o) async {
      final cur = _n(W['limbers']);
      final next = (cur - 1).clamp(0, 3);
      W['limbers'] = next;
      W['derretidos'] = (3 - next).clamp(0, 3);
      await wait(240);
    },
    'final67': (o) async {
      final n = _n(o['n']).clamp(1, 3);
      W['cajaEstado'] = 'vacia';
      W['cosaCabeza'] = null;
      W['coquiGorro'] = 1;
      W['limbers'] = n;
      W['derretidos'] = (3 - n).clamp(0, 3);
      W['final67'] = n;
      W['caneloLimber'] = n == 1 ? 1 : 0;
      await wait(320);
    },
    // Story 68
    'torre68': (o) async {
      W['torre'] = _n(o['n']).clamp(1, 3);
      await wait(120);
    },
    'velas': (o) async {
      W['velas'] = <String, int>{
        'a': _n(o['a']),
        'b': _n(o['b']),
        'c': _n(o['c']),
      };
      await wait(160);
    },
    'vela68': (o) async {
      final n = _n(o['n']);
      final a = o['a'] as String?;
      final ok = _n(o['ok']) == 1;
      if (a == null) return;
      if (ok) {
        if (a == 'torre') {
          await _hopTo('barra_c', steps: 6);
          W['torreVela5'] = 1;
          await wait(200);
          await _hopTo('barra_e', steps: 6);
        } else {
          final biz = (W['bizcochos'] as Map<String, int>);
          biz[a] = n;
          final p = _gente[a] as Map<String, dynamic>?;
          if (p != null) {
            p['pose'] = 'saluda0';
            p['dy'] = -2;
          }
          await wait(220);
          if (p != null) {
            p['pose'] = 'idle';
            p['dy'] = 0;
          }
          if (a == 'nino' || a == 'nina') {
            W['velas'] = null;
          }
        }
      } else {
        W['bizcochoRoto'] = 1;
        W['caneloRoto'] = 1;
        await wait(280);
      }
    },
    'quita68': (o) async {
      final cur = _n(W['torre']);
      W['torre'] = (cur - 1).clamp(1, 3);
      W['bizcochoRoto'] = 0;
      W['caneloRoto'] = 0;
      await wait(240);
    },
    'final68': (o) async {
      final n = _n(o['n']).clamp(1, 3);
      W['torre'] = n;
      W['torreVela5'] = 1;
      W['torreLit'] = 0;
      W['torreHumo'] = 1;
      W['betoCorona'] = 0;
      W['bizcochoRoto'] = 0;
      W['caneloRoto'] = 0;
      W['final68'] = n;
      await wait(320);
    },
    // Gestures & shared acts
    'gesto': (o) async {
      final quien = o['quien'] as String?, que = o['que'] as String?;
      if (quien == null || que == null) return;
      if (quien == 'coqui') {
        final q = W['cq'] as Map<String, dynamic>;
        switch (que) {
          case 'no':
            for (final d in const [-2, 2, -2, 0]) {
              q['dx'] = d;
              await wait(80);
            }
          case 'dedos':
            W['dedos'] = <String, dynamic>{'quien': 'coqui', 'n': _n(o['n'])};
            await wait(320);
            W['dedos'] = null;
          case 'si':
          case 'rie':
            await _brinco();
          default:
            await wait(160);
        }
        return;
      }
      final p = _gente[quien] as Map<String, dynamic>?;
      if (p == null || p['vis'] == 0) return;
      switch (que) {
        case 'saluda':
        case 'aplaude':
          for (var i = 0; i < 4; i++) {
            p['pose'] = i.isEven ? 'saluda0' : 'saluda1';
            p['dy'] = i.isEven ? -2 : 0;
            await wait(110);
          }
          p['pose'] = 'idle';
          p['dy'] = 0;
        case 'no':
          for (final d in const [-2, 2, -2, 0]) {
            p['dx'] = d;
            await wait(80);
          }
        case 'si':
          p['dy'] = -2;
          await wait(120);
          p['dy'] = 0;
        case 'rie':
          p['pose'] = 'rie';
          for (var i = 0; i < 3; i++) {
            p['dy'] = i.isEven ? -2 : 0;
            await wait(110);
          }
          p['pose'] = 'idle';
          p['dy'] = 0;
        case 'senala':
          p['pose'] = 'senala';
          await wait(280);
          p['pose'] = 'idle';
        case 'mira':
          p['dy'] = -1;
          await wait(180);
          p['dy'] = 0;
        case 'manos':
          p['pose'] = 'hombros';
          await wait(260);
          p['pose'] = 'idle';
        case 'dedos':
          p['pose'] = 'mano';
          W['dedos'] = <String, dynamic>{'quien': quien, 'n': _n(o['n'])};
          await wait(320);
          W['dedos'] = null;
          p['pose'] = 'idle';
        case 'gorra':
          p['pose'] = 'cabeza';
          await wait(260);
          p['pose'] = 'idle';
        case 'pito':
          p['pose'] = 'mano';
          W['pitoHasta'] = F + 10;
          await wait(280);
          p['pose'] = 'idle';
        case 'guino':
          p['pose'] = 'guino';
          await wait(280);
          p['pose'] = 'idle';
        case 'abraza':
          p['pose'] = 'hombros';
          p['dy'] = -2;
          await wait(260);
          p['pose'] = 'idle';
          p['dy'] = 0;
        case 'sopla':
          W['torreVela5'] = 1;
          W['torreLit'] = 1;
          await wait(220);
          p['pose'] = 'rie';
          W['torreLit'] = 0;
          W['torreHumo'] = 1;
          W['betoCorona'] = 0;
          W['coronaVuelaHasta'] = F + 12;
          await wait(320);
          p['pose'] = 'idle';
      }
    },
    'marca': (o) async {
      final m = W['marcas'];
      if (m is List) {
        final i = m.indexOf(null);
        if (i >= 0) m[i] = o['que'];
      }
      await wait(120);
    },
    'fin': (o) async {
      await _brinco();
      await wait(200);
    },
  };
}
