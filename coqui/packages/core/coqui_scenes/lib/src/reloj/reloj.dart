// El reloj (place 6, La plaza, scene 2: `reloj`; stories 63 to 65): a NEW scene, written from its script's "Needs"
// list (historia/notas/guiones/reloj.md) on its set (reloj_set.dart) and its sheet (reloj-sheet.json, read by
// SceneSheet). There is no old scene file: every act is this file's, each doing on screen what the Needs list says,
// every place from the sheet (a spot's world point, a thing's box, the clock hands' pivot, the time cards' offsets,
// abuela's bingo card squares, the depth rule). Where the sheet names no place, or the script does not settle what an
// act shows, the act does the plainest thing that keeps the story playing and says so in a comment starting `OPEN:`.
//
// The drawing (the sheet's `front`): every sprite stands with its feet's bottom edge on its spot's row and its middle
// on its column (rules.anchor); sitting people hang by the lap; a sprite pixel is hidden by every set pixel nearer
// than the upright plane through its feet plus `front.bias` (front.plane); between two sprites the nearer pixel wins;
// the time cards, abuela's big bingo card and its beans are signs drawn last, over everything.
// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/src/colmado/colmado_cast.dart' show inkBottom;
import 'package:coqui_scenes/src/plaza/plaza_cast.dart';
import 'package:coqui_scenes/src/reloj/reloj_places.dart';
import 'package:coqui_scenes/src/reloj/reloj_set.dart';
import 'package:coqui_scenes/src/reloj/reloj_sprites.dart';
import 'package:coqui_scenes/src/scene_set.dart';
import 'package:coqui_scenes/src/sheet_cache.dart';

/// The scene "El reloj", made from its sheet (read first: `loadScene`).
Scene createReloj() => Reloj(sceneSheetOf('reloj'));

int _round(num v) => (v + 0.5).floor();

int _n(Object? v) {
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? 0;
  return 0;
}

double _num(Object? v, [double def = 0]) {
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? def;
  return def;
}

/// One sprite of the sprite layer, placed: its picture, its top left on the 240 × 216 picture, the screen row of its
/// feet and the depth there (front.plane), and who or what it is.
class RelojItem {
  RelojItem(this.s, this.left, this.top, this.sy, this.d, {this.tag});

  final Sprite s;
  final int left, top;
  final num sy;
  final double d;
  final String? tag;
}

/// The people El reloj knows, by speaker key (reloj.md, "Needs").
const List<String> RELOJ_PERSONAS = [
  'tito',
  'vendedor',
  'luis',
  'carmen',
  'abuela',
  'senor',
  'senora',
];

const List<int> _CARTON_NUMS = [40, 60, 80, 90, 100];

class Reloj extends Escena implements SetScene, SetOverSprites {
  Reloj(this.ss)
    : sheet = identical(ss, _lastSs)
          ? _lastSheet!
          : (_lastSheet = ss.legacy()) {
    _p = identical(ss, _lastSs)
        ? _lastPlaces!
        : (_lastPlaces = RelojPlaces(ss));
    _lastSs = ss;
    CAM = {'wide': _p.view('wide')};
    // the frog can be sent to any world spot the sheet names (`ir` {a}), plus the script's aliases
    // `manecilla` and `mesa_abuela` (resolved to `mano_*` and `mesa_abuela.coqui` in `_resolveSpot`)
    LUGAR = {
      for (final en in ss.spots.entries)
        if (en.value.world != null) en.key: _frogAt(_p.at(en.key)),
      'manecilla': _frogAt(_p.at('mano_abajo')),
      'mesa_abuela': _frogAt(_p.at('mesa_abuela.coqui')),
    };
    cosas = _things();
  }

  static SceneSheet? _lastSs;
  static Sheet? _lastSheet;
  static RelojPlaces? _lastPlaces;

  /// The new scene's sheet (SceneSheet).
  final SceneSheet ss;

  @override
  final Sheet sheet;

  late final RelojPlaces _p;

  /// The scene's places, from its sheet.
  RelojPlaces get places => _p;

  @override
  String get id => 'reloj';

  @override
  late final Map<String, List<num>> CAM;

  late final Map<String, List<num>> LUGAR;

  @override
  Map<String, List<num>> get lugar => LUGAR;

  @override
  late final List<Thing> cosas;

  @override
  PpEngine newEngine({bool still = false}) => relojEngine(still: still);

  @override
  PpEngine get projection => _p.e;

  List<num> _frogAt(RelojAt a) => [_round(a.sx) - 16, _round(a.sy) - 25, 1];

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

  Map<String, dynamic> _person(String spot, {int vis = 1, int sent = 0}) {
    final w = _p.world(spot);
    return <String, dynamic>{
      'x': w[0],
      'y': w[1],
      'z': w[2],
      'spot': spot,
      'vis': vis,
      'dir': 1,
      'pose': 'idle',
      'sent': sent,
      'dy': 0,
    };
  }

  @override
  Map<String, dynamic> fresh(Map<String, dynamic> story) {
    final acts = _actsOf([story['beats'], story['final']]);
    bool has(String a) => acts.any((o) => o['act'] == a);
    final set = _firstSet(story['beats']);
    final isBingo = _n(set['mesas']) == 1 || has('bola65');
    final isMedia = !isBingo && has('larga');
    final gente = <String, dynamic>{};
    final String start;
    if (isBingo) {
      gente['vendedor'] = _person('quiosco');
      gente['abuela'] = _person('mesa_abuela.abuela', sent: 1);
      gente['luis'] = _person('mesa_abuela.luis');
      gente['senor'] = _person('mesa_senor', sent: 1);
      gente['tito'] = _person('mesa_tito', sent: 1);
      gente['senora'] = _person('senora');
      start = 'mesa_abuela.coqui';
    } else if (isMedia) {
      gente['tito'] = _person('balcon1');
      gente['luis'] = _person('pie1');
      gente['carmen'] = _person('pie3');
      start = 'pie2';
    } else {
      gente['tito'] = _person('balcon1');
      gente['vendedor'] = _person('quiosco');
      gente['luis'] = _person('pie1');
      gente['carmen'] = _person('pie3');
      start = 'pie2';
    }
    final q = _frogAt(_p.at(start));
    final hora = set['hora'] is String
        ? set['hora'] as String
        : (isBingo ? 'ocaso' : (isMedia ? 'tarde' : 'mediodia'));
    return <String, dynamic>{
      'cam': 'wide',
      'hora': hora,
      'mesas': isBingo ? 1 : 0,
      'gente': gente,
      // clock hands (stories 63 and 64; none drawn in story 65 bingo moment 6)
      'manecillas': isBingo ? 0 : 1,
      'manoLarga': 180.0,
      'manoCorta': isMedia ? 45.0 : 180.0,
      'manoPos': 'media',
      'camina': 0,
      'usaArribaAbajo': isMedia ? 1 : 0,
      // story 63: time cards, pastelillos, fryer, bell, oil can/key
      'cartas': null,
      'cartasPrev': null,
      'pastelillos': (!isBingo && !isMedia) ? 3 : null,
      'dorados': 0,
      'negros': 0,
      'final63': null,
      'fuego': 0,
      'sarten': null,
      'humoHasta': 0,
      'campanaHasta': 0,
      'aceitera': (!isBingo && !isMedia) ? 1 : 0,
      'llave': 0,
      // story 64: flap, spring, stuck shutters, figures
      'tapaAbierta': 0,
      'resorteHasta': 0,
      'atascados': 0,
      'figuras': 0,
      // story 65: bingo cage, held ball, prizes, abuela's card & beans, rivals
      'jaula': isBingo ? 1 : 0,
      'jaulaHasta': 0,
      'bola': null,
      'premios': isBingo ? 3 : 0,
      'carton': isBingo ? 1 : 0,
      'frijoles': <int>[],
      'ultimoFrijol': null,
      'cartones': <String, int>{'luis': 0, 'senor': 3, 'tito': 3},
      'abuelaOjos': 0,
      'rivalPremio': <String, int>{},
      'abuelaPremio': null,
      'tarjeta': null,
      'marcas': null,
      'cq': <String, dynamic>{
        'x': q[0],
        'y': q[1],
        's': 1,
        'dy': 0,
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
    final hora = h is String && const ['mediodia', 'tarde', 'ocaso'].contains(h)
        ? h
        : 'mediodia';
    return '$hora-${_n(W['mesas']) == 1 ? 1 : 0}';
  }

  @override
  void buildSet(PpEngine e, PpBuild b, Map<String, dynamic> W) =>
      buildSetFor(e, b, setKey(W));

  final Map<PpEngine, RelojSet> _sets = {};

  @override
  void buildSetFor(PpEngine e, PpBuild b, String key) =>
      (_sets[e] ??= RelojSet(e, b)).buildSet(RelojState.fromKey(key));

  @override
  bool get frogShadow => false;

  /* ---------- where everybody is ---------- */

  Map<String, dynamic> get _gente => W['gente'] as Map<String, dynamic>;

  RelojAt _atOf(Map<String, dynamic> o) =>
      _p.atWorld(o['x'] as num, o['y'] as num, o['z'] as num);

  RelojAt _frogPoint(Map<String, dynamic> q) {
    final spot = q['spot'];
    if (spot is String && _p.has(spot)) {
      final at = _p.at(spot);
      final L = _frogAt(at);
      if (q['x'] == L[0] && q['y'] == L[1]) return at;
    }
    if (q['wx'] is num && q['wy'] is num && q['z'] is num) {
      final at = _p.atWorld(q['wx'] as num, q['wy'] as num, q['z'] as num);
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

  // OPEN: `gen_reloj.py` names `pie1` for the frog (script has no owner per pie spot), `manecilla` (sheet splits it
  // into `mano_arriba`, `mano_abajo`, `mano_lado`), and `mesa_abuela` (sheet splits it into `.abuela`, `.luis`,
  // `.coqui`). Map them to the sheet's frog spots so Luis/Carmen stay clear and cards sit over `pie2`.
  String _resolveSpot(String key) {
    if (key == 'pie1') {
      final luis = _gente['luis'] as Map<String, dynamic>?;
      if (luis != null && luis['vis'] != 0 && luis['spot'] == 'pie1') {
        return 'pie2';
      }
      return 'pie1';
    }
    if (key == 'manecilla') {
      return switch (W['manoPos']) {
        'punto' => 'mano_arriba',
        'lado' => 'mano_lado',
        _ => 'mano_abajo',
      };
    }
    if (key == 'mesa_abuela') return 'mesa_abuela.coqui';
    return key;
  }

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

  static final Map<String, ({Sprite s, int ax, int ay})> _hands = {};
  static ({Sprite s, int ax, int ay}) _handSpr(
    int len,
    double deg, {
    required bool largo,
  }) {
    final d = (((deg % 360) + 360) % 360 * 2).round() / 2;
    final k = '${largo ? 'L' : 'S'}_${len}_$d';
    return _hands[k] ??= mkManecilla(len, d, largo: largo);
  }

  ({Sprite s, int ax, int ay, String key}) _personSprite(
    String id,
    Map<String, dynamic> p,
    bool open,
  ) {
    final sent = _n(p['sent']) == 1;
    var pose = (p['pose'] as String?) ?? 'idle';
    if (id == 'abuela') {
      // rules.anchor: abuela sitting mkAbuelaS (52 × 50): column 17 and row 36 (her lap) on (sx, sy)
      final abPose = _n(W['abuelaOjos']) == 1 && pose == 'idle'
          ? 'ojos'
          : (pose == 'sienta' ? 'idle' : pose);
      final k = 'abS$abPose$open';
      final s = _spr(k, () => mkAbuelaS(abPose, open, false));
      return (s: s, ax: 17, ay: 36, key: k);
    }
    if (sent && (pose == 'idle' || pose == 'arrodilla')) pose = 'sienta';
    final key = 'p$id$pose$open';
    final s = _spr(key, () => mkPlazaPersona(id, pose, open: open));
    final seated = pose == 'sienta';
    // rules.anchor: sitting mkPersona (sent = 1) hangs by lap row (8 rows above sprite bottom for adult)
    return (s: s, ax: PX, ay: seated ? s.h - 8 : inkBottom(s), key: key);
  }

  String? _talker() {
    try {
      return host.TALK;
    } catch (_) {
      return null;
    }
  }

  /// Every sprite of the frame [w] as it is placed (the people, the clock hands, the counter plate, the bingo cage,
  /// the prizes, the open flap/spring/shutters/figures, the props), except the frog. The rules' tests read it; [draw]
  /// draws it.
  List<RelojItem> items(Map<String, dynamic> w, int a) {
    final out = <RelojItem>[];
    final talk = _talker();

    // 1. the clock's two hands on the tower's front (reloj-preview.html: HANDS)
    if (_n(w['manecillas']) == 1) {
      final pv = _p.handPivot;
      final sx = _round(pv.sx), sy = _round(pv.sy);
      final shortDeg = _num(w['manoCorta'], 180);
      final longBase = _num(w['manoLarga'], 180);
      final longDeg = _n(w['camina']) == 1
          ? (longBase + F * 1.5) % 360
          : longBase;
      final sh = _handSpr(_p.shortHand, shortDeg, largo: false);
      final lg = _handSpr(_p.longHand, longDeg, largo: true);
      out.add(
        RelojItem(sh.s, sx - sh.ax, sy - sh.ay, sy, pv.d, tag: 'mano_corta'),
      );
      out.add(
        RelojItem(
          lg.s,
          sx - lg.ax,
          sy - lg.ay,
          sy,
          pv.d + .0005,
          tag: 'mano_larga',
        ),
      );
    }

    // 2. story 64: open iron flap, bouncing spring, stuck shutters, and the three wooden figures
    final wallD = _p.handPivot.d + .005;
    if (_n(w['tapaAbierta']) == 1) {
      final b = _p.box('tapa');
      final s = _spr('tapaAbierta', mkTapaAbierta);
      out.add(
        RelojItem(s, b[0], b[1], b[1] + b[3], wallD, tag: 'cosa:tapa_abierta'),
      );
    }
    if (F < _n(w['resorteHasta'])) {
      final b = _p.box('tapa');
      final f = (F >> 1) % 2;
      final s = _spr('resorte$f', () => mkResorte(f));
      out.add(
        RelojItem(
          s,
          b[0] + 4 + (f == 0 ? 0 : 2),
          b[1] + 5 - f,
          b[1] + b[3],
          wallD + .02,
          tag: 'cosa:resorte',
        ),
      );
    }
    // OPEN: `puertita` shutter thirds match reloj-set.html DOOR (top = rooster, middle = guitarist, bottom = small frog).
    final stuck = _n(w['atascados']);
    final figs = _n(w['figuras']);
    if (stuck > 0 || figs > 0) {
      final pb = _p.box('puertita');
      final slotH = pb[3] ~/ 3;
      // slot 0 = top (rooster), slot 1 = middle (guitarist), slot 2 = bottom (small frog)
      if (stuck >= 1) {
        final s = _spr('postigo', mkPostigoAtascado);
        out.add(
          RelojItem(
            s,
            pb[0] + 2,
            pb[1] + slotH + 1,
            pb[1] + pb[3],
            wallD + .008,
            tag: 'cosa:postigo1',
          ),
        );
      }
      if (stuck >= 2) {
        final s = _spr('postigo', mkPostigoAtascado);
        out.add(
          RelojItem(
            s,
            pb[0] + 2,
            pb[1] + 1,
            pb[1] + pb[3],
            wallD + .008,
            tag: 'cosa:postigo2',
          ),
        );
      }
      if (figs > 0) {
        final bob = (F >> 2) % 2;
        // figs == 3: all three; figs == 2: rooster + small frog (guitarist stuck); figs == 1: small frog alone
        final shown = <(String, int)>[
          if (figs >= 2) ('gallo', 0),
          if (figs >= 3) ('guitarra', 1),
          ('coqui', 2),
        ];
        for (final (who, slot) in shown) {
          final s = _spr('fig_$who', () => mkFiguraReloj(who));
          out.add(
            RelojItem(
              s,
              pb[0] + 3,
              pb[1] + slot * slotH + (slotH - s.h) ~/ 2 - bob,
              pb[1] + pb[3],
              wallD + .015,
              tag: 'cosa:figura_$who',
            ),
          );
        }
      }
    }

    // 3. the people
    final gente = (w['gente'] as Map<String, dynamic>?) ?? const {};
    for (final en in gente.entries) {
      final p = en.value as Map<String, dynamic>;
      if (p['vis'] == 0) continue;
      final open = talk == en.key && a % 2 == 1;
      final sp = _personSprite(en.key, p, open);
      final at = _atOf(p);
      final dir = _n(p['dir']) < 0 ? -1 : 1;
      final s = dir < 0 ? _mirror(sp.key, sp.s) : sp.s;
      final ax = dir < 0 ? sp.s.w - 1 - sp.ax : sp.ax;
      final sx = _round(at.sx), sy = _round(at.sy) + _n(p['dy']);
      out.add(
        RelojItem(s, sx - ax, sy - sp.ay, sy, at.d, tag: 'persona:${en.key}'),
      );
      // don Tito's oil can or big winding key in hand on the balcony
      if (en.key == 'tito' && (_n(w['llave']) == 1 || _n(w['aceitera']) == 1)) {
        final prop = _n(w['llave']) == 1
            ? _spr('llave', mkLlaveReloj)
            : _spr('aceitera', mkAceitera);
        out.add(
          RelojItem(
            prop,
            sx + (dir > 0 ? 6 : -6 - prop.w),
            sy - (_n(p['sent']) == 1 ? 14 : 26),
            sy,
            at.d + .02,
            tag: _n(w['llave']) == 1 ? 'cosa:llave' : 'cosa:aceitera',
          ),
        );
      }
    }

    // 4. story 63: the plate of pastelillos on the counter (`plato`), fryer fire, frying/smoke, ending plate
    final raw = w['pastelillos'];
    if (raw is num) {
      final at = _p.at('plato');
      final sx = _round(at.sx), sy = _round(at.sy);
      final fin = w['final63'];
      final Sprite plate;
      if (fin is num) {
        final g = fin.toInt().clamp(0, 3);
        plate = _spr(
          'plato_fin_$g',
          () => mkPlatoPastelillos(raw: 0, golden: g, black: 3 - g),
        );
      } else {
        final r = raw.toInt().clamp(0, 3);
        plate = _spr('plato_raw_$r', () => mkPlatoPastelillos(raw: r));
      }
      out.add(
        RelojItem(
          plate,
          sx - plate.w ~/ 2,
          sy - inkBottom(plate),
          sy,
          at.d,
          tag: 'cosa:plato',
        ),
      );
      // fryer flame & smoke just left of the plate (at KIOSK.u - 0.34, KIOSK.v - 0.05, z 1.26)
      final fryerPos = _p.xyOf(RelojE.KIOSK.u - .34, RelojE.KIOSK.v - .05);
      final fryerAt = _p.atWorld(fryerPos[0], fryerPos[1], 1.26);
      final fx = _round(fryerAt.sx), fy = _round(fryerAt.sy);
      if (_n(w['fuego']) == 1) {
        final f = (F >> 1) % 2;
        final fl = _spr('llama$f', () => mkLlama(f));
        out.add(
          RelojItem(
            fl,
            fx - fl.w ~/ 2,
            fy + 2,
            fy + 8,
            fryerAt.d + .01,
            tag: 'cosa:llama',
          ),
        );
      }
      if (w['sarten'] is String) {
        final kind = w['sarten'] as String;
        final ps = _spr('past_$kind', () => mkPastelillo(kind));
        out.add(
          RelojItem(
            ps,
            fx - ps.w ~/ 2,
            fy - ps.h + 1,
            fy,
            fryerAt.d + .02,
            tag: 'cosa:sarten',
          ),
        );
      }
      if (F < _n(w['humoHasta'])) {
        final f = (F >> 1) % 2;
        final hm = _spr('humo$f', () => mkHumo(f));
        out.add(
          RelojItem(
            hm,
            fx - hm.w ~/ 2,
            fy - hm.h - 2 - (f * 2),
            fy,
            fryerAt.d + .03,
            tag: 'cosa:humo',
          ),
        );
      }
    }

    // 5. bell ring mark beside the clock face when the bell chimes
    if (F < _n(w['campanaHasta'])) {
      final f = (F >> 1) % 2;
      final wave = _spr('campana$f', () => mkCampanaOnda(f));
      final fb = _p.box('reloj');
      out.add(
        RelojItem(
          wave,
          fb[0] + fb[2] + 1,
          fb[1] + 6,
          fb[1] + fb[3],
          wallD + .05,
          tag: 'cosa:campana',
        ),
      );
    }

    // 6. story 65: bingo cage, the three prizes on the shelf, small player cards, won prizes
    if (_n(w['jaula']) == 1) {
      final at = _p.at('jaula');
      final spin = F < _n(w['jaulaHasta']) ? (F >> 1) % 2 : 0;
      final s = _spr('jaula$spin', () => mkJaula(spin: spin));
      final sx = _round(at.sx), sy = _round(at.sy);
      out.add(
        RelojItem(
          s,
          sx - s.w ~/ 2,
          sy - inkBottom(s),
          sy,
          at.d,
          tag: 'cosa:jaula',
        ),
      );
    }
    final premios = _n(w['premios']);
    if (premios > 0) {
      // best prize is premio1 (left), taken first when rivals win: premios=3 -> 1,2,3; premios=2 -> 2,3; premios=1 -> 3
      final firstLeft = 4 - premios;
      for (var k = firstLeft; k <= 3; k++) {
        final spot = 'premio$k';
        final at = _p.at(spot);
        final s = _spr('premio$k', () => mkPremio(k));
        final sx = _round(at.sx), sy = _round(at.sy);
        out.add(
          RelojItem(
            s,
            sx - s.w ~/ 2,
            sy - inkBottom(s),
            sy,
            at.d,
            tag: 'cosa:$spot',
          ),
        );
      }
    }
    // small bingo cards on the tables (Luis at table 0, el señor at table 1, don Tito at table 2)
    if (_n(w['mesas']) == 1 && w['cartones'] is Map) {
      final cartones = w['cartones'] as Map;
      // OPEN: the sheet names no separate spot for each rival's small card; place each flat on its
      // table top (RelojE.TABLES, z = 0.72) clear of the frog (`frog-seen`).
      const placements = [
        ('luis', 0, 0.20, 0.40),
        ('senor', 1, 0.0, 0.05),
        ('tito', 2, 0.0, 0.05),
      ];
      for (final (who, idx, du, dv) in placements) {
        final p = gente[who] as Map<String, dynamic>?;
        if (p == null || p['vis'] == 0) continue;
        final beans = _n(cartones[who]).clamp(0, 5);
        final s = _spr('carton_chico_$beans', () => mkCartonChico(beans));
        final t = RelojE.TABLES[idx];
        final xy = _p.xyOf(t[0] + du, t[1] + dv);
        final at = _p.atWorld(xy[0], xy[1], 0.72);
        final sx = _round(at.sx), sy = _round(at.sy);
        final top = sy - s.h ~/ 2;
        out.add(
          RelojItem(
            s,
            sx - s.w ~/ 2,
            top,
            top + s.h,
            at.d + .05,
            tag: 'cosa:carton_$who',
          ),
        );
      }
    }
    // prizes taken by a rival or won by abuela (drawn on their table)
    final rPrem = (w['rivalPremio'] as Map?) ?? const {};
    for (final e in rPrem.entries) {
      final p = gente[e.key] as Map<String, dynamic>?;
      if (p == null || p['vis'] == 0) continue;
      final k = _n(e.value);
      if (k < 1 || k > 3) continue;
      final at = _atOf(p);
      final s = _spr('premio$k', () => mkPremio(k));
      final sx = _round(at.sx) + (e.key == 'tito' ? -14 : 14);
      final sy = _round(at.sy) - 2;
      out.add(
        RelojItem(
          s,
          sx - s.w ~/ 2,
          sy - inkBottom(s),
          sy,
          at.d + .06,
          tag: 'cosa:premio_${e.key}',
        ),
      );
    }
    final abPrem = w['abuelaPremio'];
    if (abPrem is num) {
      final k = abPrem.toInt().clamp(1, 3);
      final at = _p.at('mesa_abuela.coqui');
      final s = _spr('premio$k', () => mkPremio(k));
      final sx = _round(at.sx) + 18;
      final sy = _round(at.sy) + 1;
      out.add(
        RelojItem(
          s,
          sx - s.w ~/ 2,
          sy - inkBottom(s),
          sy,
          at.d - .04,
          tag: 'cosa:premio_abuela',
        ),
      );
    }
    // held-up numbered ball beside the señora (only when bola65 muestra=1)
    final bola = w['bola'];
    if (bola is num && gente['senora'] is Map) {
      final at = _atOf(gente['senora'] as Map<String, dynamic>);
      final s = _spr('bola_${bola.toInt()}', () => mkBolaBingo(bola.toInt()));
      // placed to the right of the señora's head so it clears the carton, cage and prizes
      final sx = _round(at.sx) + 18;
      final sy = _round(at.sy) - 34;
      out.add(
        RelojItem(
          s,
          sx - s.w ~/ 2,
          sy - s.h ~/ 2,
          _round(at.sy),
          at.d + .08,
          tag: 'cosa:bola',
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
    _setZ = baked.zb;
  }

  static final double _t30 = math.tan(math.pi / 6);

  void _put(
    RelojItem it,
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

  /// [items] and the frog (as the game draws him, juego.js frog, at the depth of his feet): every sprite of the frame,
  /// placed. [draw] composes it; the rules' tests read it.
  List<RelojItem> placed(Map<String, dynamic> W, int a) {
    final all = items(W, a);
    final q = W['cq'] as Map<String, dynamic>;
    if (jsTruthy(q['vis'])) {
      final b = host.frogBox(q), at = _frogPoint(q);
      final ox = b.x.toInt() - 16, oy = b.y.toInt() - 24;
      final rawDy = ((q['dy'] as num) + 0.5).floor();
      // Clamp upward bounce (`dy < 0`) so a celebratory hop near the top of the
      // clock face (`mano_arriba`, `45°`) never clips the frog's head above row 0.
      final maxUp = -math.max(0, b.y.toInt());
      final dy = rawDy < maxUp ? maxUp : rawDy;
      final qDraw = dy == rawDy ? q : <String, dynamic>{...q, 'dy': dy};
      final fk =
          '${q['s']}_${b.x - ox}_${b.y - oy}_${(q['y'] as num) - oy}_${dy}_${host.F % 47 < 2 ? 1 : 0}_${((q['bub'] == 'hola' || _talker() == 'coqui') && a % 2 != 0) ? 1 : 0}';
      final spr = _frogSprites.putIfAbsent(fk, () {
        final px = Uint32List(64 * 64);
        final g = Ctx(px, 64, 64)..translate(-ox.toDouble(), -oy.toDouble());
        host.frog(g, qDraw, a);
        return Sprite(64, 64, px);
      });
      all.add(RelojItem(spr, ox, oy, _round(at.sy), at.d, tag: 'coqui'));
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
    _over(c, W);
  }

  /// The two time cards' boxes now (rules.cards: the offsets of things.carta_a and carta_b from the frog's spot), or
  /// null when they are not shown.
  ({List<num> a, List<num> b})? cardBoxes(Map<String, dynamic> w) {
    final ca = w['cartas'];
    final q = w['cq'] as Map<String, dynamic>;
    if (ca is! Map || !jsTruthy(q['vis'])) return null;
    final sx = (q['x'] as num) + 16, sy = (q['y'] as num) + 25;
    final A = _p.cardA, B = _p.cardB;
    return (
      a: [sx + A[0], sy + A[1], A[2], A[3]],
      b: [sx + B[0], sy + B[1], B[2], B[3]],
    );
  }

  void _over(Ctx c, Map<String, dynamic> W) {
    // story 63: the two time cards over the frog
    final cb = cardBoxes(W);
    if (cb != null) {
      final ca = W['cartas'] as Map;
      final aH = _n(ca['a']), bH = _n(ca['b']);
      final sa = _spr('carta_$aH', () => mkCartaHora(aH));
      final sb = _spr('carta_$bH', () => mkCartaHora(bH));
      c.drawImage(sa, cb.a[0], cb.a[1]);
      c.drawImage(sb, cb.b[0], cb.b[1]);
    }
    // story 65: abuela's big bingo card (n40..n100) and any beans laid on it
    if (_n(W['carton']) == 1) {
      final beans = (W['frijoles'] as List? ?? const []).cast<num>().toSet();
      final beanSpr = _spr('frijol', mkFrijol);
      for (final n in _CARTON_NUMS) {
        final b = _p.box('n$n');
        final sq = _spr('cuadro_$n', () => mkCuadroBingo(n));
        c.drawImage(sq, b[0], b[1]);
        if (beans.contains(n)) {
          c.drawImage(beanSpr, b[0] + 4, b[1] + 9);
        }
      }
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
    void cast(RelojAt at, double? r) {
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
            _p.sheet.shadows.radius[plazaNino(en.key) ? 'ninos' : 'adultos'],
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

  static List<num>? _inkBox(RelojItem it) {
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
  static List<num>? inkBox(RelojItem it) => _inkBox(it);

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

  List<Thing> _things() {
    Thing sprite(String id, String tag, {num m = 0, bool z = false}) => Thing(
      id: id,
      m: m,
      z: z,
      si: (w) => _boxOfTag(w, tag) != null,
      box: (Map<String, dynamic> w) => _boxOfTag(w, tag),
    );
    Thing setThing(
      String id, {
      bool Function(Map<String, dynamic>)? si,
      bool z = false,
      num m = 0,
    }) {
      final b = _p.box(id);
      return Thing(
        id: id,
        m: m,
        z: z,
        world: _p.worldBox(id),
        si: si,
        box: [b[0], b[1], b[2], b[3]],
      );
    }

    Thing carta(String id, bool isA) => Thing(
      id: id,
      m: 0,
      z: true,
      si: (w) => cardBoxes(w) != null,
      box: (Map<String, dynamic> w) {
        final cb = cardBoxes(w);
        return cb == null ? null : (isA ? cb.a : cb.b);
      },
    );

    Thing cuadro(int n) {
      final id = 'n$n';
      final b = _p.box(id);
      return Thing(
        id: id,
        m: 0,
        z: true,
        si: (w) => _n(w['carton']) == 1,
        box: [b[0], b[1], b[2], b[3]],
      );
    }

    return [
      // overlay signs: time cards (story 63) and abuela's bingo card squares (story 65)
      carta('carta_a', true),
      carta('carta_b', false),
      for (final n in _CARTON_NUMS) cuadro(n),
      // story 64: top and bottom thirds of the clock face win over the frog riding the hand and over `reloj`
      setThing('arriba', z: true, si: (w) => _n(w['usaArribaAbajo']) == 1),
      setThing('abajo', z: true, si: (w) => _n(w['usaArribaAbajo']) == 1),
      // sprite things
      sprite('pastelillos', 'cosa:plato', m: 1, z: true),
      sprite('jaula', 'cosa:jaula', m: 1),
      sprite('premio1', 'cosa:premio1', m: 1),
      sprite('premio2', 'cosa:premio2', m: 1),
      sprite('premio3', 'cosa:premio3', m: 1),
      // the people
      for (final id in RELOJ_PERSONAS) sprite(id, 'persona:$id', m: 1),
      // set things
      setThing('reloj'),
      setThing('puertita'),
      setThing('tapa'),
      setThing('balcon'),
      setThing('escalera'),
      setThing('quiosco'),
    ];
  }

  /* ---------- talking ---------- */

  @override
  List<num>? talkAt(String who, Map<String, dynamic> W) {
    final b = _boxOfTag(W, 'persona:$who');
    if (b == null) return null;
    return [_round(b[0] + b[2] / 2), b[1] - 1];
  }

  @override
  Future<void> stake(int lost, int max, String en) async {
    host.SFX.bonk();
    await wait(300);
  }

  @override
  List<num> remap(List<num> xy) => xy;

  @override
  dynamic poke(String what) {
    if (what == 'reloj' && _n(W['manecillas']) == 1) {
      // story 63 step 1: "He touches it: the long hand swings and hangs again."
      // In story 64 (`usaArribaAbajo == 1`) the frog rides the long hand on the
      // 3-o'clock half, so a free tap only ticks without drifting the hand onto
      // the 9-o'clock side behind don Tito.
      if (_n(W['usaArribaAbajo']) == 0) {
        W['manoLarga'] = (_num(W['manoLarga'], 180) + 12) % 360;
      }
      host.SFX.toc();
    }
    return null;
  }

  @override
  String estado(Map<String, dynamic> W) {
    final g = (W['gente'] as Map<String, dynamic>?) ?? const {};
    final gente = [
      for (final e in g.entries)
        if ((e.value as Map)['vis'] != 0)
          '${e.key}@${(e.value as Map)['spot']}${(e.value as Map)['sent'] == 1 ? '(sentado)' : ''}',
    ].join(' ');
    return 'hora=${W['hora']} mesas=${W['mesas']} gente=$gente manoL=${W['manoLarga']} manoC=${W['manoCorta']} cartas=${W['cartas']} pastelillos=${W['pastelillos']} premios=${W['premios']} frijoles=${W['frijoles']} marcas=${W['marcas']}';
  }

  /* ---------- moving ---------- */

  Future<void> _salta(String rawSpot) async {
    final spot = _resolveSpot(rawSpot);
    if (!_p.has(spot)) return;
    final q = W['cq'] as Map<String, dynamic>;
    final at = _p.at(spot), L = _frogAt(at);
    if (!jsTruthy(q['vis'])) {
      q['x'] = L[0];
      q['y'] = L[1];
      q['z'] = at.z;
      q['vis'] = 1;
      q['spot'] = spot;
      q.remove('wx');
      q.remove('wy');
      return;
    }
    final dx = (q['x'] as num) - L[0], dy = (q['y'] as num) - L[1];
    final dd = math.sqrt(dx * dx + dy * dy);
    if (at.z > ((q['z'] as num?) ?? 0)) q['z'] = at.z;
    if (dd >= 3) {
      await host.hopTo(
        L[0],
        L[1],
        math.max(1, math.min(4, _round(dd / 30))),
        1,
      );
    }
    q['z'] = at.z;
    q['spot'] = spot;
    q.remove('wx');
    q.remove('wy');
  }

  num? _sxOf(String a) {
    if (a == 'coqui') return ((W['cq'] as Map)['x'] as num) + 16;
    final p = _gente[a] as Map<String, dynamic>?;
    if (p != null && p['vis'] != 0) return _atOf(p).sx;
    if (a == 'pastelillos') return _p.at('plato').sx;
    if (_p.sheet.things[a]?.box != null) {
      final b = _p.box(a);
      return b[0] + b[2] / 2;
    }
    if (_p.has(a)) return _p.at(a).sx;
    return null;
  }

  void _face(Map<String, dynamic> p, String? a) {
    if (a == null || _n(p['sent']) == 1) return;
    final tx = _sxOf(a);
    if (tx == null) return;
    final at = _atOf(p);
    if ((tx - at.sx).abs() <= 2) return;
    p['dir'] = tx > at.sx ? 1 : -1;
  }

  /* ---------- the acts (reloj.md, "Needs") ---------- */

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
    // `ya`: waits for any acts started with `suelto: 1`
    'ya': (o) async {
      final all = List<Future<void>>.of(_sueltos);
      _sueltos.clear();
      await Future.wait(all);
    },
    // `marca` {que}: the star or the cross on the rounds card
    'marca': (o) async {
      final m = W['marcas'];
      if (m is List) {
        final i = m.indexOf(null);
        if (i >= 0) m[i] = o['que'];
      }
      host.SFX.blip();
      await wait(250);
      // OPEN: after a wrong card in story 63 (`marca(x)`), the runner retries the same `decide` without re-running
      // `lead`; bring the frog back from `balcon2` to `pie2` and re-show the two time cards so both cards and the
      // hint hand stand cleanly.
      if (o['que'] == 'x' && W['cartasPrev'] is Map) {
        final q = W['cq'] as Map<String, dynamic>;
        if (q['spot'] != 'pie2') {
          if (q['spot'] == 'balcon2') await _salta('escalera');
          await _salta('pie2');
        }
        W['cartas'] = W['cartasPrev'];
        W['cartasPrev'] = null;
      }
    },
    // `ir` {a}: the frog hops to a spot the sheet names (with aliases resolved in `_resolveSpot`)
    'ir': (o) async {
      final a = o['a'], key = jsTruthy(a) ? a : o['en'];
      if (key is! String) return;
      await _salta(key);
    },
    // `cartas` {a, b}: two time cards appear over the frog (story 63)
    'cartas': (o) async {
      final a = _n(o['a']), b = _n(o['b']);
      // OPEN: in story 63 step 4 and rounds A/B no `ir` precedes `cartas` after `pone63`; hop the frog back down
      // from `balcon2`/`escalera` to `pie2` so the two cards stand at the sheet's `carta_a`/`carta_b` boxes.
      final q = W['cq'] as Map<String, dynamic>;
      if (q['spot'] != 'pie2') {
        if (q['spot'] == 'balcon2') await _salta('escalera');
        await _salta('pie2');
      }
      W['cartas'] = {'a': a, 'b': b};
      W['cartasPrev'] = null;
      host.SFX.blip();
      await wait(TICK * 2);
    },
    // `pone63` {h}: the frog hops up the ladder to balcon2 and sets the short hand to hour h (story 63)
    'pone63': (o) async {
      final h = _n(o['h']);
      if (W['cartas'] is Map) W['cartasPrev'] = W['cartas'];
      W['cartas'] = null;
      final q = W['cq'] as Map<String, dynamic>;
      if (q['spot'] != 'balcon2') {
        await _salta('escalera');
        await _salta('balcon2');
      }
      W['manoCorta'] = (h % 12) * 30.0;
      W['manoLarga'] = 180.0;
      host.SFX.toc();
      await wait(TICK * 3);
    },
    // `campana` {n}: the tower's bell rings n times (stories 63, 64)
    'campana': (o) async {
      final n = _n(o['n']).clamp(1, 12);
      for (var i = 0; i < n; i++) {
        W['campanaHasta'] = F + 5;
        host.SFX.blip();
        await wait(TICK * 2);
      }
    },
    // `echa63`: the vendedor lights the fryer and drops a raw pastelillo into the oil (story 63)
    'echa63': (o) async {
      W['fuego'] = 1;
      W['sarten'] = 'raw';
      final v = _gente['vendedor'] as Map<String, dynamic>?;
      if (v != null) v['pose'] = 'mano';
      host.SFX.drop();
      await wait(TICK * 3);
      if (v != null) v['pose'] = 'idle';
    },
    // `pastelillos` {n}: the raw pastelillos left on the plate (3, 2, 1) (story 63)
    'pastelillos': (o) async {
      W['pastelillos'] = _n(o['n']).clamp(0, 3);
      await wait(TICK);
    },
    // `frie63` {ok}: ok=1 golden pastelillo lifted out; ok=0 vendedor shakes head, smoke rises, black pastelillo (63)
    'frie63': (o) async {
      final ok = _n(o['ok']) == 1;
      final v = _gente['vendedor'] as Map<String, dynamic>?;
      if (ok) {
        W['cartasPrev'] = null;
        if (v != null) v['pose'] = 'mano';
        W['sarten'] = 'golden';
        W['dorados'] = _n(W['dorados']) + 1;
        host.SFX.win();
        await wait(TICK * 5);
        W['sarten'] = null;
        if (v != null) v['pose'] = 'idle';
      } else {
        if (v != null) v['pose'] = 'hombros';
        W['sarten'] = 'black';
        W['humoHasta'] = F + 14;
        W['negros'] = _n(W['negros']) + 1;
        host.SFX.bonk();
        await wait(TICK * 6);
        W['sarten'] = null;
        if (v != null) v['pose'] = 'idle';
      }
    },
    // `final63` {n}: the ending plate with n golden pastelillos (3, 2 or 1) and 3-n burnt ones (story 63)
    'final63': (o) async {
      final n = _n(o['n']).clamp(1, 3);
      // OPEN: the sheet names only `plato` on the counter for pastelillos (no second serving spot at the children's
      // feet); return the frog to `pie2` and show the final plate (n golden, 3-n black) at `plato`.
      final q = W['cq'] as Map<String, dynamic>;
      if (q['spot'] != 'pie2') {
        if (q['spot'] == 'balcon2') await _salta('escalera');
        await _salta('pie2');
      }
      W['final63'] = n;
      W['sarten'] = null;
      final v = _gente['vendedor'] as Map<String, dynamic>?;
      if (v != null) v['pose'] = 'mano';
      host.SFX.win();
      await wait(TICK * 6);
      if (v != null) v['pose'] = 'idle';
    },
    // `larga` {a}: the long hand swings to `punto` (12 / 0°), `media` (6 / 180°), or `lado` (3 / 90°), carrying the
    // frog to `mano_arriba`, `mano_abajo`, or `mano_lado` (story 64)
    'larga': (o) async {
      final a = (o['a'] as String?) ?? 'punto';
      final (deg, spot) = switch (a) {
        'punto' => (0.0, 'mano_arriba'),
        'lado' => (90.0, 'mano_lado'),
        _ => (180.0, 'mano_abajo'),
      };
      W['manoPos'] = a;
      final q = W['cq'] as Map<String, dynamic>;
      final cur = q['spot'] as String?;
      final riding =
          cur == 'mano_arriba' || cur == 'mano_abajo' || cur == 'mano_lado';
      var startDeg = (_num(W['manoLarga'], 180) % 360 + 360) % 360;
      if (riding && startDeg > 180) {
        startDeg = switch (cur) {
          'mano_arriba' => 0.0,
          'mano_lado' => 90.0,
          _ => 180.0,
        };
      }
      // Sweep through the open 3-o'clock side (0°..180°), never through the
      // 9-o'clock side where don Tito stands on balcon1 (`frog-seen`).
      final double diff = (startDeg >= 0 && startDeg <= 180)
          ? deg - startDeg
          : ((deg - startDeg + 540) % 360) - 180;
      const steps = 4;
      for (var i = 1; i <= steps; i++) {
        final curDeg = i == steps
            ? deg
            : (startDeg + diff * i / steps + 360) % 360;
        W['manoLarga'] = curDeg;
        if (riding) {
          if (i == steps) {
            final at = _p.at(spot), L = _frogAt(at);
            q['x'] = L[0];
            q['y'] = L[1];
            q['z'] = at.z;
            q['spot'] = spot;
            q.remove('wx');
            q.remove('wy');
          } else {
            final at = _p.handFrogAt(curDeg), L = _frogAt(at);
            q['x'] = L[0];
            q['y'] = L[1];
            q['z'] = at.z;
            q['wx'] = at.x;
            q['wy'] = at.y;
            q['spot'] = 'manecilla';
          }
        }
        await wait(TICK);
      }
      W['manoLarga'] = deg;
      host.SFX.swoop();
      await wait(TICK * 2);
    },
    // `corta` {h, media}: sets the short hand to hour h (plus half an hour when media=1) (story 64)
    'corta': (o) async {
      final h = _n(o['h']);
      final media = _n(o['media']) != 0;
      W['manoCorta'] = (h % 12) * 30.0 + (media ? 15.0 : 0.0);
      host.SFX.toc();
      await wait(TICK * 2);
    },
    // `resorte64`: the works grind, the flap opens, a spring jumps out, and a shutter sticks crooked (story 64)
    'resorte64': (o) async {
      W['tapaAbierta'] = 1;
      W['resorteHasta'] = F + 12;
      W['atascados'] = math.min(2, _n(W['atascados']) + 1);
      host.SFX.bonk();
      await wait(TICK * 6);
    },
    // `figuras64` {n}: the flap shuts and n of the 3 wooden figures come out of `puertita` (story 64 ending)
    'figuras64': (o) async {
      final n = _n(o['n']).clamp(1, 3);
      W['tapaAbierta'] = 0;
      W['figuras'] = n;
      host.SFX.win();
      await wait(TICK * 8);
    },
    // `bola65` {n, muestra}: cage spins; when muestra=1 the señora holds up ball n (story 65)
    'bola65': (o) async {
      final n = _n(o['n']);
      final muestra = _n(o['muestra']) == 1;
      W['jaulaHasta'] = F + 8;
      W['bola'] = muestra ? n : null;
      final sra = _gente['senora'] as Map<String, dynamic>?;
      if (sra != null) sra['pose'] = muestra ? 'mano' : 'idle';
      host.SFX.blip();
      await wait(TICK * 3);
      if (!muestra && sra != null) sra['pose'] = 'idle';
    },
    // `frijol` {carton, n}: lays a bean on abuela's big card (or marks Luis's/señor's/don Tito's card) (story 65)
    'frijol': (o) async {
      final carton = (o['carton'] as String?) ?? 'abuela';
      if (carton == 'abuela') {
        final n = _n(o['n']);
        final list = (W['frijoles'] as List).cast<int>();
        if (!list.contains(n)) list.add(n);
        W['ultimoFrijol'] = n;
      } else {
        final cs = (W['cartones'] as Map).cast<String, int>();
        cs[carton] = (cs[carton] ?? 0) + 1;
        final p = _gente[carton] as Map<String, dynamic>?;
        if (p != null) {
          p['dy'] = -1;
          await wait(TICK * 2);
          p['dy'] = 0;
        }
      }
      host.SFX.drop();
      await wait(TICK * 2);
    },
    // `quita65`: abuela removes the wrong bean from her card (story 65)
    'quita65': (o) async {
      final last = W['ultimoFrijol'];
      if (last is int) {
        (W['frijoles'] as List).remove(last);
        W['ultimoFrijol'] = null;
      }
      host.SFX.toc();
      await wait(TICK * 4);
    },
    // `rival65` {quien}: another player shouts Bingo and takes the best prize left (story 65)
    'rival65': (o) async {
      final quien = (o['quien'] as String?) ?? 'senor';
      // OPEN: the sheet has no walking spot between `mesa_senor`/`mesa_tito` and the prize table (`premio1..3`);
      // the rival jumps up at his table and the best prize left moves beside him.
      final p = _gente[quien] as Map<String, dynamic>?;
      final cs = W['cartones'];
      if (cs is Map) {
        cs[quien] = math.max(5, _n(cs[quien]) + 1);
      }
      final rem = _n(W['premios']);
      if (rem > 0) {
        final bestPrize = 4 - rem;
        (W['rivalPremio'] as Map<String, int>)[quien] = bestPrize;
      }
      if (p != null) {
        p['pose'] = 'rie';
        for (var i = 0; i < 4; i++) {
          p['dy'] = i % 2 == 0 ? -2 : 0;
          await wait(TICK);
        }
        p['dy'] = 0;
        p['pose'] = 'idle';
      } else {
        await wait(TICK * 4);
      }
    },
    // `premios` {n}: n prizes remain on the shelf (3, 2, 1) (story 65)
    'premios': (o) async {
      W['premios'] = _n(o['n']).clamp(0, 3);
      await wait(TICK);
    },
    // `final65` {n}: abuela wins and takes the best prize left (3=basket, 2=pineapple, 1=guineos) (story 65)
    'final65': (o) async {
      final n = _n(o['n']).clamp(1, 3);
      // OPEN: the sheet has no walking spot for abuela at the prize table; she celebrates at `mesa_abuela.abuela`,
      // the won prize leaves the shelf (`premios` decrements by 1) and appears on her table beside the frog.
      final won = 4 - n;
      W['abuelaOjos'] = 0;
      W['abuelaPremio'] = won;
      W['premios'] = math.max(0, n - 1);
      final ab = _gente['abuela'] as Map<String, dynamic>?;
      if (ab != null) ab['pose'] = 'rie';
      host.SFX.win();
      await wait(TICK * 6);
      if (ab != null) ab['pose'] = 'idle';
    },
    // `gesto` {quien, que, a}: character gestures (reloj.md, "Needs")
    'gesto': (o) async {
      final quien = o['quien'] as String;
      final que = o['que'] as String;
      final a = o['a'] as String?;
      final p = _gente[quien] as Map<String, dynamic>?;
      if (p == null || p['vis'] == 0) {
        await wait(TICK * 2);
        return;
      }
      Future<void> hold(String pose, int ticks) async {
        p['pose'] = pose;
        await wait(TICK * ticks);
        p['pose'] = 'idle';
      }

      switch (que) {
        case 'saluda':
          for (var i = 0; i < 6; i++) {
            p['pose'] = i % 2 == 0 ? 'saluda0' : 'saluda1';
            await wait(TICK);
          }
          p['pose'] = 'idle';
        case 'no':
          if (_n(p['sent']) == 1) {
            for (var i = 0; i < 4; i++) {
              p['dy'] = i % 2 == 0 ? 1 : 0;
              await wait(TICK);
            }
            p['dy'] = 0;
          } else {
            final d = _n(p['dir']) < 0 ? -1 : 1;
            for (var i = 0; i < 4; i++) {
              p['dir'] = i % 2 == 0 ? -d : d;
              await wait(TICK);
            }
            p['dir'] = d;
          }
        case 'si':
          for (var i = 0; i < 2; i++) {
            p['dy'] = 2;
            await wait(TICK);
            p['dy'] = 0;
            await wait(TICK);
          }
        case 'rie':
          p['pose'] = 'rie';
          for (var i = 0; i < 4; i++) {
            p['dy'] = i % 2 == 0 ? -1 : 0;
            await wait(TICK);
          }
          p['dy'] = 0;
          p['pose'] = 'idle';
        case 'mira':
          _face(p, a);
          await wait(TICK * 4);
        case 'senala':
          _face(p, a);
          await hold('senala', 6);
        case 'cabeza':
          await hold('cabeza', 6);
        case 'dedos':
          await hold('mano', 6);
        case 'uno':
          await hold('senala', 6);
        case 'manos':
          await hold('mano', 5);
        case 'ojos':
          if (quien == 'abuela') {
            W['abuelaOjos'] = _n(W['abuelaOjos']) == 1 ? 0 : 1;
          }
          await wait(TICK * 4);
        case 'sienta':
          p['sent'] = 1;
          p['dir'] = 1;
          W['aceitera'] = 0;
          await wait(TICK * 3);
        case 'llave':
          // OPEN: story 63 step 8 says don Tito comes down the ladder to wind the clock, but the sheet has no
          // winding spot at the foot; he stands on `balcon1` with the big key and starts the hands ticking (works
          // identically for story 64 step 7 too).
          p['sent'] = 0;
          W['aceitera'] = 0;
          W['llave'] = 1;
          W['tapaAbierta'] = 0;
          W['camina'] = 1;
          host.SFX.toc();
          await hold('mano', 6);
        default:
          await wait(TICK * 3);
      }
    },
  };
}
