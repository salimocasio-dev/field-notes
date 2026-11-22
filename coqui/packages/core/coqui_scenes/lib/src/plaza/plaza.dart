// El banco de la plaza (place 6, La plaza, scene 1: `plaza`; stories 60 to 62): a NEW scene, written from its script's
// "Needs" list (historia/notas/guiones/plaza.md) on its set (plaza_set.dart) and its sheet (plaza-sheet.json, read by
// SceneSheet). There is no old scene file: every act is this file's, each doing on screen what the Needs list says,
// every place from the sheet (a spot's world point, a thing's box, the board's hooks, the bubbles' offsets, the depth
// rule). Where the sheet names no place, or the script does not settle what an act shows, the act does the plainest
// thing that keeps the story playing and says so in a comment starting `OPEN:` (page 13 lists them for the content lane).
//
// The drawing (the sheet's `front`): every sprite stands with its feet's bottom edge on its spot's row and its middle on
// its column (rules.anchor); a sprite pixel is hidden by every set pixel nearer the camera than the upright plane through
// its feet plus `front.bias` (front.plane); between two sprites the nearer pixel wins; the two answer bubbles are drawn
// last, over everything. People and things are kept in W by their world point.
// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/src/colmado/colmado_cast.dart'
    show inkBottom, mkMoneda;
import 'package:coqui_scenes/src/plaza/plaza_cast.dart';
import 'package:coqui_scenes/src/plaza/plaza_places.dart';
import 'package:coqui_scenes/src/plaza/plaza_set.dart';
import 'package:coqui_scenes/src/plaza/plaza_sprites.dart';
import 'package:coqui_scenes/src/scene_set.dart';
import 'package:coqui_scenes/src/sheet_cache.dart';

/// The scene "El banco de la plaza", made from its sheet (read first: `loadScene`).
Scene createPlaza() => Plaza(sceneSheetOf('plaza'));

int _round(num v) => (v + 0.5).floor();

int _n(Object? v) => v is num ? v.toInt() : 0;

/// One sprite of the sprite layer, placed: its picture, its top left on the 240 x 216 picture, the screen row of its
/// feet and the depth there (front.plane), and who or what it is (the rules' tests read it: `persona:<id>`, `coqui`,
/// `perro`, `paloma:<i>`, `cola:<i>`, `foto:<fila><i>`, `cosa:<id>`).
class PlazaItem {
  PlazaItem(this.s, this.left, this.top, this.sy, this.d, {this.tag});

  final Sprite s;
  final int left, top;
  final num sy;
  final double d;
  final String? tag;
}

/// The people the scene knows, by speaker key (plaza.md, "Needs": things he can touch, speaker keys).
const List<String> PLAZA_PERSONAS = [
  'ana',
  'mama_ana',
  'beto',
  'abuela_ana',
  'luis',
  'carmen',
  'senor',
  'senora',
  'hombre',
  'mujer',
  'joven',
  'piraguero',
  'turista',
];

class Plaza extends Escena implements SetScene, SetOverSprites {
  Plaza(this.ss) : sheet = ss.legacy() {
    _p = PlazaPlaces(ss);
    CAM = {'wide': _p.view('wide')};
    // the frog can be sent to any spot the sheet names (`ir` {a}): his top left for it (rules.anchor: mkCoqui's column
    // 16 on sx, its row 25 on sy)
    LUGAR = {for (final s in ss.spots.keys) s: _frogAt(_p.at(s))};
    cosas = _things();
  }

  /// The new scene's sheet (SceneSheet).
  final SceneSheet ss;

  @override
  final Sheet sheet;

  late final PlazaPlaces _p;

  /// The scene's places, from its sheet.
  PlazaPlaces get places => _p;

  @override
  String get id => 'plaza';

  @override
  late final Map<String, List<num>> CAM;

  late final Map<String, List<num>> LUGAR;

  @override
  Map<String, List<num>> get lugar => LUGAR;

  @override
  late final List<Thing> cosas;

  @override
  PpEngine newEngine({bool still = false}) => plazaEngine(still: still);

  @override
  PpEngine get projection => _p.e;

  List<num> _frogAt(PlazaAt a) => [_round(a.sx) - 16, _round(a.sy) - 25, 1];

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

  // the story's first set step (its state: hora, tablero, carrito)
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
    final gente = <String, dynamic>{};
    // the frog: where the story's first `ir` sends him (no hop from nowhere)
    String? firstIr;
    for (final o in acts) {
      if (o['act'] == 'ir' && o['a'] is String && LUGAR.containsKey(o['a'])) {
        firstIr = o['a'] as String;
        break;
      }
    }
    final start = firstIr ?? 'asiento4';
    // every story: Luis and Carmen in front of the seat (plaza-preview.html moments 1, 3, 5: suelo3, suelo4). OPEN: the
    // preview has the frog at asiento4; story 60 starts him at asiento2, in front of which suelo4 stands: each takes the
    // nearest spot of the row whose column is clear of the frog's (his 32 columns and a child's half: 26 px)
    final fsx = _p.at(start).sx, fsy = _p.at(start).sy;
    String clear(String want, Set<String> used) {
      final wx = _p.at(want).sx;
      final row = List.of(_p.group('suelo'))
        ..sort(
          (a, b) =>
              (_p.at(a).sx - wx).abs().compareTo((_p.at(b).sx - wx).abs()),
        );
      for (final c in row) {
        if (used.contains(c)) continue;
        if (_p.at(c).sy <= fsy || (_p.at(c).sx - fsx).abs() >= 26) return c;
      }
      return want;
    }

    final lu = clear('suelo3', const {}), ca = clear('suelo4', {lu});
    gente['luis'] = _person(lu);
    gente['carmen'] = _person(ca);
    // story 61: Ana at the board (tablero1), her abuela on the seat (asiento1, sitting: the script's "Start")
    if (has('tarjetas')) {
      gente['ana'] = _person('tablero1');
      gente['abuela_ana'] = _person('asiento1', sent: 1);
    }
    // story 62: the piragüero behind his cart (carro_pie)
    if (has('pide62')) gente['piraguero'] = _person('carro_pie');
    final q = LUGAR[start]!;
    return {
      'hora': set['hora'] ?? 'manana',
      'tablero': _n(set['tablero']),
      'carrito': _n(set['carrito']),
      'gente': gente,
      // story 60: Canelo lying in front of the seat (`bajo`)
      'perro': has('palomas')
          ? <String, dynamic>{'spot': 'bajo', 'pose': 'lie', 'hasta': 0}
          : null,
      'palomas': <dynamic>[],
      'cosas': <dynamic>[],
      'burbujas': null,
      'tarjetas': has('tarjetas') ? 0 : null,
      'piedra': 0,
      'fotos': <dynamic>[],
      'pide': null,
      'traduce': null,
      'jarra': has('pide62') ? 0 : null,
      'cola': 0,
      'fila1': 0,
      'visita': 0,
      'nuevo': 0,
      'fila1Look': 0,
      'colaLook': 0,
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

  // the sheet's setKey: "hora-tablero-carrito", e.g. "manana-0-0"
  @override
  String setKey(Map<String, dynamic> W) {
    final h = W['hora'];
    final hora =
        h is String && const ['manana', 'mediodia', 'tarde'].contains(h)
        ? h
        : 'manana';
    return '$hora-${_n(W['tablero']) == 1 ? 1 : 0}-${_n(W['carrito']) == 1 ? 1 : 0}';
  }

  @override
  void buildSet(PpEngine e, PpBuild b, Map<String, dynamic> W) =>
      buildSetFor(e, b, setKey(W));

  final Map<PpEngine, PlazaSet> _sets = {};

  @override
  void buildSetFor(PpEngine e, PpBuild b, String key) =>
      (_sets[e] ??= PlazaSet(e, b)).buildSet(PlazaState.fromKey(key));

  // the frog casts his shadow in the engine (shadows.byCharacter.coqui) when he stands on the ground; never the old one
  @override
  bool get frogShadow => false;

  /* ---------- where everybody is ---------- */

  Map<String, dynamic> get _gente => W['gente'] as Map<String, dynamic>;

  Map<String, dynamic> _g(String id) =>
      (_gente[id] ??= _person('entrada', vis: 0)) as Map<String, dynamic>;

  List<Map<String, dynamic>> get _items =>
      (W['cosas'] as List).cast<Map<String, dynamic>>();

  PlazaAt _atOf(Map<String, dynamic> o) =>
      _p.atWorld(o['x'] as num, o['y'] as num, o['z'] as num);

  // the frog's world point under his feet (his z: 0 the ground, .46 the seat, 1 the ledge, 1.02 the cart's top)
  PlazaAt _frogPoint(Map<String, dynamic> q) {
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

  // the look of a visitor: the one at the cart is TURISTAS[visita]; the line behind her the next ones
  static String _look(int i) =>
      TURISTAS[i.clamp(0, TURISTAS.length - 1) % TURISTAS.length];

  // a person's sprite and the point of it that stands on the spot (rules.anchor: the middle column PX; standing, the
  // feet's bottom edge; sitting, the lap row: mkPersona's row 16 + 2t + 3, which is 8 rows above the sprite's bottom)
  ({Sprite s, int ax, int ay, String key}) _personSprite(
    String id,
    Map<String, dynamic> p,
    bool open,
  ) {
    final sent = _n(p['sent']) == 1;
    var pose = (p['pose'] as String?) ?? 'idle';
    if (sent && (pose == 'idle' || pose == 'arrodilla')) pose = 'sienta';
    final look = id == 'turista'
        ? _look(_n(W['visita']))
        : (p['look'] as String? ?? id);
    final key = 'p$look$pose$open';
    final s = _spr(key, () => mkPlazaPersona(look, pose, open: open));
    final seated = pose == 'sienta';
    return (s: s, ax: PX, ay: seated ? s.h - 8 : inkBottom(s), key: key);
  }

  // where a held thing is drawn: at the holder's hand (a person's held-out hand, kit.js mkPersona 'taza': X + rx + 4.5,
  // row 27; the frog's beside him), a point of the picture with the holder's depth
  ({num x, num y, double d, num sy})? _handOf(String holder) {
    if (holder == 'coqui') {
      final q = W['cq'] as Map<String, dynamic>;
      if (!jsTruthy(q['vis'])) return null;
      final b = host.frogBox(q), at = _frogPoint(q);
      return (
        x: b.x + b.w + 2,
        y: (q['y'] as num) + 24,
        d: at.d + .05,
        sy: at.sy,
      );
    }
    final p = _gente[holder] as Map<String, dynamic>?;
    if (p == null || p['vis'] == 0) return null;
    final at = _atOf(p), dir = _n(p['dir']) < 0 ? -1 : 1;
    final nino = plazaNino(
      holder == 'turista' ? _look(_n(W['visita'])) : holder,
    );
    return (
      x: at.sx + dir * (nino ? 11 : 13),
      y: at.sy - (nino ? 15 : (jsTruthy(p['sent']) ? 6 : 26)),
      d: at.d + .05,
      sy: at.sy,
    );
  }

  // the top middle of a person's head on the picture (from its sprite's drawn pixels), or of the frog's
  List<num>? _cabeza(Map<String, dynamic> w, String who) {
    if (who == 'coqui') {
      final q = w['cq'] as Map<String, dynamic>;
      if (!jsTruthy(q['vis'])) return null;
      final b = host.frogBox(q);
      return [b.x + b.w / 2, b.y];
    }
    final b = _boxOfTag(w, 'persona:$who');
    return b == null ? null : [b[0] + b[2] / 2, b[1]];
  }

  Sprite _thingSprite(Map<String, dynamic> o) {
    final k = o['k'] as String, v = o['v'];
    switch (k) {
      case 'foto':
        return _spr('foto$v', () => mkFoto(v as String));
      case 'dibujo':
        return _spr('dibujo$v', () => mkDibujo(v as String));
      case 'tarjeta_vuela':
        return _spr('tv${F % 2}', () => mkTarjetaVuela(F % 2));
      case 'piragua':
        return _spr('piragua$v', () => mkPiraguaPz(_n(v) == 0 ? 1 : _n(v)));
      case 'piragua_grande':
        return _spr('piraguag$v', () => mkPiraguaPz(_n(v), grande: true));
      case 'moneda':
        return _spr('moneda', mkMoneda);
      case 'bolsa_pan':
        return _spr('bolsapan', mkBolsaPan);
      case 'migaja':
        return _spr('migaja', mkMigaja);
      case 'lapiz':
        return _spr('lapiz', mkLapiz);
    }
    throw StateError('no sprite for $k');
  }

  /// Every sprite of the frame [w] as it is placed (the people, Canelo, the pigeons, the line of visitors, the photos,
  /// the things), but the frog. The rules' tests read it; [draw] draws it.
  List<PlazaItem> items(Map<String, dynamic> w, int a) {
    final out = <PlazaItem>[];
    final talk = _talker();
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
        PlazaItem(s, sx - ax, sy - sp.ay, sy, at.d, tag: 'persona:${en.key}'),
      );
    }
    // Canelo (story 60): lying at `bajo` (rules.anchor: mkPerro('lie') column 15 and its bottom edge); wagging when touched
    final pr = w['perro'] as Map<String, dynamic>?;
    if (pr != null) {
      final at = _p.at(pr['spot'] as String);
      final wag = F < _n(pr['hasta']);
      final pose = wag ? 'sit' : 'lie';
      final f = wag && (F >> 2) % 2 == 1;
      final s = _spr('perro$pose$f', () => mkPerro(pose, f));
      final sx = _round(at.sx), sy = _round(at.sy);
      out.add(PlazaItem(s, sx - 15, sy - inkBottom(s), sy, at.d, tag: 'perro'));
    }
    // the pigeons: on the seat's back (respaldo1 to 3: their bottom middle on the spot), flying, or on a hand, a cap, a head
    final pal = (w['palomas'] as List? ?? const [])
        .cast<Map<String, dynamic>>();
    for (var i = 0; i < pal.length; i++) {
      final o = pal[i];
      if (o['vis'] == 0) continue;
      final pose = (o['pose'] as String?) ?? 'posada';
      final f = pose == 'vuela' || pose == 'come' ? (F >> 1) % 2 : 0;
      final dir = _n(o['dir']) < 0 ? -1 : 1;
      final base = _spr('pal$pose$f', () => mkPalomaPz(pose, f));
      final s = dir < 0 ? _mirror('pal$pose$f', base) : base;
      final en = o['en'] as String?;
      if (en != null) {
        // held: on a hand, on Beto's cap, on the frog's head
        final who = en.split(':')[1];
        List<num>? pt;
        if (en == 'cabeza:coqui' || en.startsWith('gorra:')) {
          if (who == 'coqui') {
            pt = _cabeza(w, 'coqui');
          } else {
            // the top of his head: his sprite, placed above
            for (final it in out) {
              if (it.tag != 'persona:$who') continue;
              final b = _inkBox(it);
              if (b != null) pt = [b[0] + b[2] / 2, b[1]];
            }
          }
        } else {
          final h = _handOf(who);
          if (h != null) pt = [h.x, h.y];
        }
        if (pt == null) continue;
        final holderD = en.endsWith('coqui')
            ? _frogPoint(w['cq'] as Map<String, dynamic>).d
            : _atOf(_gente[en.split(':')[1]] as Map<String, dynamic>).d;
        out.add(
          PlazaItem(
            s,
            _round(pt[0]) - s.w ~/ 2,
            _round(pt[1]) - inkBottom(s) + 1,
            _round(pt[1]) + 30,
            holderD + .1,
            tag: 'paloma:$i',
          ),
        );
        continue;
      }
      final at = _atOf(o);
      final sx = _round(at.sx), sy = _round(at.sy);
      out.add(
        PlazaItem(
          s,
          sx - s.w ~/ 2,
          sy - inkBottom(s),
          sy,
          at.d,
          tag: 'paloma:$i',
        ),
      );
    }
    // the visitors in the line (story 62): the next one at fila1, the ones at the back at fila2 on (`cola`)
    final line = <(String, int)>[
      if (_n(w['fila1']) == 1) ('fila1', _n(w['fila1Look'])),
      for (var k = 0; k < _n(w['cola']); k++)
        ('fila${k + 2}', _n(w['colaLook']) + k),
    ];
    for (final (spot, look) in line) {
      if (!_p.has(spot)) continue;
      final at = _p.at(spot);
      final lk = _look(look);
      final pose = w['reloj'] == spot ? 'reloj' : 'idle';
      final s = _spr('p$lk${pose}false', () => mkPlazaPersona(lk, pose));
      final sx = _round(at.sx), sy = _round(at.sy);
      out.add(
        PlazaItem(s, sx - PX, sy - inkBottom(s), sy, at.d, tag: 'cola:$spot'),
      );
    }
    // the photos and the frog's drawings on the board's hooks (sheet: ganchos): hung by their top middle
    for (final f
        in (w['fotos'] as List? ?? const []).cast<Map<String, dynamic>>()) {
      final g = _p.ganchos(f['fila'] as String)[_n(f['i'])];
      final at = _p.atWorld(g[0], g[1], g[2]);
      final s = f['dibujo'] != null
          ? _spr('dibujo${f['dibujo']}', () => mkDibujo(f['dibujo'] as String))
          : _spr('foto${f['quien']}', () => mkFoto(f['quien'] as String));
      final sx = _round(at.sx), top = _round(at.sy);
      out.add(
        PlazaItem(
          s,
          sx - s.w ~/ 2,
          top,
          top,
          at.d,
          tag: 'foto:${f['fila']}${f['i']}',
        ),
      );
    }
    // the blank cards under their stone on the ledge (repisa: their bottom middle on it); the stone rocks when knocked
    final nt = w['tarjetas'];
    if (nt is num && _n(w['tablero']) == 1) {
      final at = _p.at('repisa');
      final s = _spr('tarjetas$nt', () => mkTarjetas(nt.toInt()));
      final sx =
              _round(at.sx) +
              (F < _n(w['piedra']) ? ((F >> 1) % 2 == 0 ? -1 : 1) : 0),
          sy = _round(at.sy);
      out.add(
        PlazaItem(
          s,
          sx - s.w ~/ 2,
          sy - inkBottom(s),
          sy,
          at.d,
          tag: 'cosa:tarjetas',
        ),
      );
    }
    // the coin jar (story 62). OPEN: the sheet names no place for the jar ("the frog on the cart's edge beside the jar"):
    // it stands at carro_borde, the nearest named spot, just behind the frog
    final jarra = w['jarra'];
    if (jarra is num && _n(w['carrito']) == 1) {
      final at = _p.at('carro_borde');
      final s = _spr('jarra$jarra', () => mkJarra(jarra.toInt()));
      final sx = _round(at.sx), sy = _round(at.sy);
      out.add(
        PlazaItem(
          s,
          sx - s.w ~/ 2,
          sy - inkBottom(s),
          sy,
          at.d - .02,
          tag: 'cosa:jarra',
        ),
      );
    }
    // things: in a hand, or at a world point
    for (final o
        in (w['cosas'] as List? ?? const []).cast<Map<String, dynamic>>()) {
      if (o['vis'] == 0) continue;
      final s = _thingSprite(o);
      final con = o['con'] as String?;
      if (con == 'coqui') {
        // what the frog holds stands beside him, at his left, clear of him (the frog is whole)
        final q = w['cq'] as Map<String, dynamic>;
        if (!jsTruthy(q['vis'])) continue;
        final b = host.frogBox(q), at = _frogPoint(q);
        final sy = _round(at.sy);
        out.add(
          PlazaItem(
            s,
            _round(b.x) - 3 - s.w,
            sy - inkBottom(s),
            sy,
            at.d,
            tag: 'cosa:${o['id']}',
          ),
        );
        continue;
      }
      if (con != null) {
        final h = _handOf(con);
        if (h == null) continue;
        out.add(
          PlazaItem(
            s,
            _round(h.x) - s.w ~/ 2,
            _round(h.y) - s.h + 4,
            h.sy,
            h.d,
            tag: 'cosa:${o['id']}',
          ),
        );
        continue;
      }
      final at = _atOf(o);
      final sx = _round(at.sx), sy = _round(at.sy);
      out.add(
        PlazaItem(
          s,
          sx - s.w ~/ 2,
          sy - inkBottom(s),
          sy,
          at.d,
          tag: 'cosa:${o['id']}',
        ),
      );
    }
    return out;
  }

  String? _talker() {
    try {
      return host.TALK;
    } catch (_) {
      return null;
    }
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
    PlazaItem it,
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
        // a set pixel nearer than the feet hides it
        if (setZ != null && setZ[i] > plane + bias) continue;
        if (lz[i] > plane + .001) continue; // a nearer sprite pixel is already there (within .001: a tie, the later wins)
        lz[i] = plane;
        layer[i] = c;
      }
    }
  }

  /// [items] and the frog (as the game draws him, juego.js frog, at the depth of his feet): every sprite of the frame,
  /// placed. [draw] composes it; the rules' tests read it.
  List<PlazaItem> placed(Map<String, dynamic> W, int a) {
    final all = items(W, a);
    final q = W['cq'] as Map<String, dynamic>;
    if (jsTruthy(q['vis'])) {
      final b = host.frogBox(q), at = _frogPoint(q);
      final ox = b.x.toInt() - 16, oy = b.y.toInt() - 24;
      final px = Uint32List(64 * 64);
      final g = Ctx(px, 64, 64)..translate(-ox.toDouble(), -oy.toDouble());
      host.frog(g, q, a);
      all.add(
        PlazaItem(
          Sprite(64, 64, px),
          ox,
          oy,
          _round(at.sy),
          at.d,
          tag: 'coqui',
        ),
      );
    }
    return all;
  }

  @override
  void draw(Ctx c, Map<String, dynamic> W, int a) {
    const w0 = 240, h0 = 216;
    final layer = _layer ??= Uint32List(w0 * h0);
    final lz = _layerZ ??= Float32List(w0 * h0);
    final setZ = _framed ? _setZ : null, bias = _p.bias, S = _p.e.S;
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

  /// The two answer bubbles' boxes now (rules.bubbles: the offsets of things.burbuja_a and burbuja_b from the frog's
  /// spot), or null when they are not shown.
  ({List<num> a, List<num> b})? bubbleBoxes(Map<String, dynamic> w) {
    final bu = w['burbujas'];
    final q = w['cq'] as Map<String, dynamic>;
    if (bu is! Map || !jsTruthy(q['vis'])) return null;
    final sx = (q['x'] as num) + 16, sy = (q['y'] as num) + 25;
    final A = _p.bubbleA, B = _p.bubbleB;
    return (
      a: [sx + A[0], sy + A[1], A[2], A[3]],
      b: [sx + B[0], sy + B[1], B[2], B[3]],
    );
  }

  // a picture bubble over a person's head (a visitor's, a helper's): its tail on the top of the head
  List<num>? _bubbleOver(Map<String, dynamic> w, String who, Sprite s) {
    final h = _cabeza(w, who);
    if (h == null) return null;
    return [_round(h[0] - s.w / 2), _round(h[1] - s.h - 1), s.w, s.h];
  }

  /// The visitor's bubble (the flag and what she asks for) and the helper's (both flags), where they are drawn now.
  List<({Sprite s, List<num> box, String tag})> overBubbles(
    Map<String, dynamic> w,
  ) {
    final out = <({Sprite s, List<num> box, String tag})>[];
    final pi = w['pide'];
    if (pi is Map) {
      final s = _spr(
        'pide${pi['cosa']}',
        () => mkPideBurbuja(pi['cosa'] as String),
      );
      final b = _bubbleOver(w, pi['quien'] as String, s);
      if (b != null) out.add((s: s, box: b, tag: 'pide'));
    }
    final tr = w['traduce'];
    if (tr is String) {
      final s = _spr('traduce', mkTraduceBurbuja);
      final b = _bubbleOver(w, tr, s);
      if (b != null) out.add((s: s, box: b, tag: 'traduce'));
    }
    return out;
  }

  void _over(Ctx c, Map<String, dynamic> W) {
    for (final o in overBubbles(W)) {
      c.drawImage(o.s, o.box[0], o.box[1]);
    }
    final bb = bubbleBoxes(W);
    if (bb != null) {
      final bu = W['burbujas'] as Map;
      final izq = bu['izq'] as String,
          der = izq == 'insignia' ? 'manos' : 'insignia';
      for (final (k, b) in [(izq, bb.a), (der, bb.b)]) {
        final lit = bu['dice'] == k;
        final s = _spr('bur$k$lit', () => mkBurbuja(k, lit: lit));
        c.drawImage(s, b[0], b[1]);
      }
    }
  }

  /* ---------- the corner card: the two rounds ---------- */

  @override
  void hud(Ctx c, Map<String, dynamic> W, int a) {
    if (!jsTruthy(W['tarjeta'])) return;
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

  // castShadow(x, y, 0, radius) at the world x, y of whoever stands on the ground (z 0) (shadows.at); none for whoever
  // sits, stands on the ledge or on the cart (shadows.none, onSeat), none for the pigeons; the visitors in the line cast a
  // grown-up's
  @override
  List<ShadowCast> shadows(Map<String, dynamic> W) {
    final out = <ShadowCast>[];
    void cast(PlazaAt at, double? r) {
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
    final r = _p.radius('turista');
    if (_n(W['fila1']) == 1) cast(_p.at('fila1'), r);
    for (var k = 0; k < _n(W['cola']); k++) {
      if (_p.has('fila${k + 2}')) cast(_p.at('fila${k + 2}'), r);
    }
    final pr = W['perro'];
    if (pr is Map) cast(_p.at(pr['spot'] as String), _p.radius('perro'));
    final q = W['cq'] as Map<String, dynamic>?;
    if (q != null && jsTruthy(q['vis']) && (q['z'] as num? ?? 0) == 0) {
      final at = _frogPoint(q);
      if (at.sx >= 0) cast(at, _p.radius('coqui'));
    }
    return out;
  }

  /* ---------- the things he can touch ---------- */

  static final Expando<List<int>> _inkOf = Expando<List<int>>();

  static List<num>? _inkBox(PlazaItem it) {
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
  static List<num>? inkBox(PlazaItem it) => _inkBox(it);

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

  List<num>? _union(Map<String, dynamic> w, String prefix) {
    List<num>? u;
    final keys = [
      for (final it in items(w, 0))
        if (it.tag != null && it.tag!.startsWith(prefix)) it.tag!,
    ];
    for (final k in keys) {
      final b = _boxOfTag(w, k);
      if (b == null) continue;
      if (u == null) {
        u = b;
      } else {
        final x0 = math.min(u[0], b[0]), y0 = math.min(u[1], b[1]);
        final x1 = math.max(u[0] + u[2], b[0] + b[2]),
            y1 = math.max(u[1] + u[3], b[1] + b[3]);
        u = [x0, y0, x1 - x0, y1 - y0];
      }
    }
    return u;
  }

  List<Thing> _things() {
    Thing sprite(String id, String tag, {num m = 0, bool z = false}) => Thing(
      id: id,
      m: m,
      z: z,
      si: (w) => _boxOfTag(w, tag) != null,
      box: (Map<String, dynamic> w) => _boxOfTag(w, tag),
    );
    Thing setThing(String id, {bool Function(Map<String, dynamic>)? si}) {
      final b = _p.box(id);
      return Thing(
        id: id,
        m: 0,
        world: _p.worldBox(id),
        si: si,
        box: [b[0], b[1], b[2], b[3]],
      );
    }

    // the answer bubbles: touched places that are not in the world (screen boxes over the frog: things.burbuja_a, _b)
    Thing burbuja(String id, bool a) => Thing(
      id: id,
      m: 0,
      z: true,
      si: (w) => bubbleBoxes(w) != null,
      box: (Map<String, dynamic> w) {
        final bb = bubbleBoxes(w);
        return bb == null ? null : (a ? bb.a : bb.b);
      },
    );

    return [
      burbuja('burbuja_a', true),
      burbuja('burbuja_b', false),
      sprite('tarjetas', 'cosa:tarjetas', z: true),
      Thing(
        id: 'palomas',
        m: 1,
        z: true,
        si: (w) => _union(w, 'paloma:') != null,
        box: (Map<String, dynamic> w) => _union(w, 'paloma:'),
      ),
      // the board's two halves: each picture with its row of hooks (things.fila_isla, fila_ciudad)
      setThing('fila_isla', si: (w) => _n(w['tablero']) == 1),
      setThing('fila_ciudad', si: (w) => _n(w['tablero']) == 1),
      // the people (names: the free poke)
      for (final id in PLAZA_PERSONAS) sprite(id, 'persona:$id', m: 1),
      sprite('perro', 'perro', m: 1),
      // the set's things (sheet: things.<id>.box)
      setThing('carrito', si: (w) => _n(w['carrito']) == 1),
      setThing('tablero', si: (w) => _n(w['tablero']) == 1),
      setThing('banco'),
      setThing('arbol'),
    ];
  }

  /* ---------- talking ---------- */

  // the point over a speaker's head (the speaker keys of the scripts, and the people of El parque): its sprite's top
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

  // a touch that is not an answer: Canelo wags (story 60 step 2: "Canelo wags and licks Ana's hand")
  @override
  dynamic poke(String what) {
    if (what == 'perro' && W['perro'] is Map) {
      (W['perro'] as Map<String, dynamic>)['hasta'] = F + 24;
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
    final pal = [
      for (final o in (W['palomas'] as List? ?? const []))
        if ((o as Map)['vis'] != 0) o['en'] ?? o['spot'],
    ].join(',');
    final fotos = [
      for (final f in (W['fotos'] as List? ?? const []))
        '${(f as Map)['quien'] ?? f['dibujo']}@${f['fila']}${f['i']}',
    ].join(',');
    return 'gente=$gente palomas=$pal fotos=$fotos tarjetas=${W['tarjetas']} jarra=${W['jarra']} cola=${W['cola']} marcas=${W['marcas']}';
  }

  /* ---------- moving ---------- */

  // a walk: a straight line at a steady pace, about 5 px of the picture a tick (comer.js mueve)
  Future<void> _anda(String id, String spot) async {
    final p = _g(id);
    final w = _p.world(spot);
    if (p['vis'] == 0) {
      // in from where people come in (`entrada`, at the left, outside the window)
      final e = _p.world('entrada');
      p
        ..['x'] = e[0]
        ..['y'] = e[1]
        ..['z'] = e[2]
        ..['vis'] = 1
        ..['spot'] = 'entrada';
    }
    final a = _atOf(p), b = _p.atWorld(w[0], w[1], w[2]);
    final dist = math.sqrt(
      (b.sx - a.sx) * (b.sx - a.sx) + (b.sy - a.sy) * (b.sy - a.sy),
    );
    final x0 = p['x'] as num, y0 = p['y'] as num, z0 = p['z'] as num;
    p['sent'] = 0;
    if (p['pose'] == 'arrodilla') p['pose'] = 'idle';
    if ((b.sx - a.sx).abs() > 3) p['dir'] = b.sx > a.sx ? 1 : -1;
    if (dist >= .5) {
      final n = math.max(1, (dist / 5).ceil());
      for (var i = 1; i <= n; i++) {
        p['x'] = x0 + (w[0] - x0) * i / n;
        p['y'] = y0 + (w[1] - y0) * i / n;
        p['z'] = z0 + (w[2] - z0) * i / n;
        p['dy'] = i % 2 == 1 && i < n ? -1 : 0;
        await wait(TICK);
      }
    }
    p['x'] = w[0];
    p['y'] = w[1];
    p['z'] = w[2];
    p['dy'] = 0;
    p['spot'] = spot;
    // on the seat he sits (the spots asiento1 to 4 are on its top: whoever is there sits, facing us)
    if (_p.group('asientos').contains(spot)) {
      p['sent'] = 1;
      p['dir'] = 1;
    }
  }

  // the frog hops to a spot (the kit's hopTo: a hop about every 30 px)
  Future<void> _salta(String spot) async {
    final q = W['cq'] as Map<String, dynamic>;
    final at = _p.at(spot), L = _frogAt(at);
    if (!jsTruthy(q['vis'])) {
      q['x'] = L[0];
      q['y'] = L[1];
      q['z'] = at.z;
      q['vis'] = 1;
      q['spot'] = spot;
      return;
    }
    final dx = (q['x'] as num) - L[0], dy = (q['y'] as num) - L[1];
    final dd = math.sqrt(dx * dx + dy * dy);
    // going up onto the seat, the ledge or the cart he is in front of it the whole hop; coming down, the same
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
    await _abre();
  }

  // how many of the frog's drawn pixels person [id] covers now (front.sprites: between two sprites the nearer pixel wins)
  int _tapa(String id) {
    final all = placed(W, 0);
    PlazaItem? f, p;
    for (final it in all) {
      if (it.tag == 'coqui') f = it;
      if (it.tag == 'persona:$id') p = it;
    }
    if (f == null || p == null) return 0;
    final S = _p.e.S;
    var n = 0;
    for (var y = 0; y < f.s.h; y++) {
      final Y = f.top + y;
      final pf = f.d + (f.sy - (Y + .5)) * _t30 / S,
          pp = p.d + (p.sy - (Y + .5)) * _t30 / S;
      if (pp <= pf + .001) continue;
      for (var x = 0; x < f.s.w; x++) {
        if (f.s.px[y * f.s.w + x] >>> 24 == 0) continue;
        final X = f.left + x - p.left, YY = Y - p.top;
        if (X < 0 || YY < 0 || X >= p.s.w || YY >= p.s.h) continue;
        if (p.s.px[YY * p.s.w + X] >>> 24 != 0) n++;
      }
    }
    return n;
  }

  // OPEN: the frog is whole in every moment (the sheet's frog-seen), but the story's spots put somebody in front of him
  // (60: Carmen at suelo4 in front of the frog at asiento2, the abuela at frente2 in front of him at asiento1; 61: the
  // abuela at frente1 and the señora at frente2 in front of him at tablero2): who would cover him stands at the nearest
  // spot of the same row (the sheet's group: suelo, frente, cerca, ayuda) that is free and leaves him whole; with none,
  // at the story's spot. The content lane settles the places.
  String _sitio(String id, String spot) {
    final q = W['cq'] as Map<String, dynamic>;
    if (!jsTruthy(q['vis']) || _p.group('asientos').contains(spot)) return spot;
    String? group;
    for (final g in const ['suelo', 'frente', 'cerca', 'ayuda']) {
      if (_p.group(g).contains(spot)) group = g;
    }
    final p = _g(id);
    final keep = Map<String, dynamic>.of(p);
    int tapaEn(String s) {
      final w = _p.world(s);
      p
        ..['x'] = w[0]
        ..['y'] = w[1]
        ..['z'] = w[2]
        ..['vis'] = 1
        ..['sent'] = 0
        ..['spot'] = s;
      _boxesF = null;
      final n = _tapa(id);
      p
        ..clear()
        ..addAll(keep);
      _boxesF = null;
      return n;
    }

    bool taken(String c) => _gente.entries.any(
      (e) =>
          e.key != id &&
          (e.value as Map)['vis'] != 0 &&
          (e.value as Map)['spot'] == c,
    );
    if (group == null || (tapaEn(spot) == 0 && !taken(spot))) return spot;
    final sx = _p.at(spot).sx;
    final cands = List.of(_p.group(group))
      ..sort(
        (a, b) => (_p.at(a).sx - sx).abs().compareTo((_p.at(b).sx - sx).abs()),
      );
    for (final c in cands) {
      if (c == spot) continue;
      if (taken(c)) continue;
      if (tapaEn(c) == 0) return c;
    }
    // every place of the row is taken: he changes places with one who leaves the frog whole at the story's spot
    for (final c in cands) {
      if (c == spot || tapaEn(c) != 0) continue;
      for (final e in _gente.entries) {
        final o = e.value as Map<String, dynamic>;
        if (e.key == id || o['vis'] == 0 || o['spot'] != c) continue;
        final keepO = Map<String, dynamic>.of(o), w = _p.world(spot);
        o
          ..['x'] = w[0]
          ..['y'] = w[1]
          ..['z'] = w[2]
          ..['spot'] = spot;
        final ok = _tapa(e.key) == 0;
        o
          ..clear()
          ..addAll(keepO);
        if (ok) {
          _cambio = (e.key, spot);
          return c;
        }
      }
    }
    return spot;
  }

  // a change of places [_sitio] chose: who moves, and to where
  (String, String)? _cambio;

  // the frog has landed: whoever stands in front of him and covers him steps aside (see [_sitio])
  Future<void> _abre() async {
    for (final e in _gente.entries.toList()) {
      final p = e.value as Map<String, dynamic>;
      if (p['vis'] == 0 || jsTruthy(p['sent']) || p['spot'] is! String) {
        continue;
      }
      final spot = p['spot'] as String;
      if (spot == 'entrada' || _tapa(e.key) == 0) continue;
      final to = _sitio(e.key, spot);
      if (to != spot) {
        await _anda(e.key, to);
        _face(p, 'coqui');
      }
    }
  }

  // the sx of whatever a gesture's `a` names: a person, the frog, a thing of the set, a spot
  num? _sxOf(String a) {
    if (a == 'coqui') return ((W['cq'] as Map)['x'] as num) + 16;
    final p = _gente[a] as Map<String, dynamic>?;
    if (p != null && p['vis'] != 0) return _atOf(p).sx;
    if (_p.sheet.things[a]?.box != null) {
      final b = _p.box(a);
      return b[0] + b[2] / 2;
    }
    if (_p.has(a)) return _p.at(a).sx;
    return null;
  }

  void _face(Map<String, dynamic> p, String? a) {
    if (a == null) return;
    final tx = _sxOf(a);
    if (tx == null) return;
    final at = _atOf(p);
    if ((tx - at.sx).abs() > 2) p['dir'] = tx > at.sx ? 1 : -1;
  }

  // a thing that moves from one world point to another in [n] ticks (a photo up to its hook, a coin into the jar)
  Future<void> _vuela(
    Map<String, dynamic> o,
    List<double> to, {
    int n = 4,
  }) async {
    final x0 = o['x'] as num, y0 = o['y'] as num, z0 = o['z'] as num;
    for (var i = 1; i <= n; i++) {
      o['x'] = x0 + (to[0] - x0) * i / n;
      o['y'] = y0 + (to[1] - y0) * i / n;
      o['z'] = z0 + (to[2] - z0) * i / n;
      await wait(TICK);
    }
  }

  Map<String, dynamic> _cosa(
    String id,
    String k,
    List<double> w, {
    Object? v,
    String? con,
  }) {
    _items.removeWhere((o) => o['id'] == id);
    final o = <String, dynamic>{
      'id': id,
      'k': k,
      'x': w[0],
      'y': w[1],
      'z': w[2],
      'vis': 1,
      'v': v,
      'con': con,
    };
    _items.add(o);
    return o;
  }

  List<double> _frogWorld() {
    final q = W['cq'] as Map<String, dynamic>;
    final a = _frogPoint(q);
    return [a.x, a.y, a.z + .5];
  }

  /* ---------- the board (story 61) ---------- */

  List<Map<String, dynamic>> get _fotos =>
      (W['fotos'] as List).cast<Map<String, dynamic>>();

  // the first free hook of a row (sheet: ganchos, five a row), or null
  int? _libre(String fila) {
    for (var i = 0; i < 5; i++) {
      if (!_fotos.any((f) => f['fila'] == fila && f['i'] == i)) return i;
    }
    return null;
  }

  // a photo (or a drawing) goes up from the frog to the free hook of a row
  Future<Map<String, dynamic>?> _cuelga(
    String fila, {
    String? quien,
    String? dibujo,
  }) async {
    var i = _libre(fila);
    // OPEN: a row of five hooks full (no story of 61 fills one): the photo goes on the other row's first free hook
    i ??= _libre(fila == 'isla' ? 'ciudad' : 'isla');
    if (i == null) return null;
    final row = _libre(fila) == i ? fila : (fila == 'isla' ? 'ciudad' : 'isla');
    final g = _p.ganchos(row)[i];
    final o = _cosa(
      'vuelo',
      dibujo != null ? 'dibujo' : 'foto',
      _frogWorld(),
      v: dibujo ?? quien,
    );
    await _vuela(o, [g[0], g[1] + .02, g[2] - .2], n: 4);
    _items.remove(o);
    final f = <String, dynamic>{
      'fila': row,
      'i': i,
      'quien': quien,
      'dibujo': dibujo,
    };
    _fotos.add(f);
    host.SFX.blip();
    await wait(TICK * 2);
    return f;
  }

  /* ---------- the cart (story 62) ---------- */

  // the visitor at the cart gets a piragua from the piragüero, then a coin goes into the jar
  Future<void> _piragua([int colores = 1]) async {
    final pi = _g('piraguero');
    pi['pose'] = 'mano';
    _face(pi, 'turista');
    final o = _cosa(
      'piragua',
      'piragua',
      _frogWorld(),
      v: colores,
      con: 'piraguero',
    );
    host.SFX.blip();
    await wait(TICK * 5);
    final t = _gente['turista'] as Map<String, dynamic>?;
    if (t != null && t['vis'] != 0) o['con'] = 'turista';
    pi['pose'] = 'idle';
    await wait(TICK * 3);
  }

  Future<void> _moneda() async {
    final t = _gente['turista'] as Map<String, dynamic>?;
    final from = t != null && t['vis'] != 0
        ? <double>[(t['x'] as num).toDouble(), (t['y'] as num).toDouble(), 1.4]
        : _frogWorld();
    final o = _cosa('moneda', 'moneda', from);
    final to = _p.world('carro_borde');
    await _vuela(o, [to[0], to[1], to[2] + .4], n: 4);
    _items.remove(o);
    W['jarra'] = _n(W['jarra']) + 1;
    host.SFX.drop();
    await wait(TICK * 2);
  }

  // whoever leaves: walks out at the left (entrada) and is gone; what she held goes with her
  Future<void> _sale(String quien) async {
    if (quien == 'coqui') {
      await _salta('frente1');
      await _salta('entrada');
      (W['cq'] as Map<String, dynamic>)['vis'] = 0;
      return;
    }
    final p = _gente[quien] as Map<String, dynamic>?;
    if (p == null || p['vis'] == 0) return;
    p['pose'] = 'idle';
    if (W['traduce'] == quien) W['traduce'] = null;
    final pi = W['pide'];
    if (pi is Map && pi['quien'] == quien) W['pide'] = null;
    await _anda(quien, 'entrada');
    p['vis'] = 0;
    _items.removeWhere((o) => o['con'] == quien);
  }

  /* ---------- the acts (plaza.md, "Needs") ---------- */

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
    // `ya`: waits for the acts that were started with `suelto: 1`
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
    },
    // `ir` {a}: the frog hops to a spot the sheet names (kit.js comunes.ir: hops of about 30 px), with his height kept
    'ir': (o) async {
      final a = o['a'], key = jsTruthy(a) ? a : o['en'];
      if (key is! String || !LUGAR.containsKey(key)) return;
      await _salta(key);
    },
    // `llega` {quien, a}: somebody walks in to a spot (60 to 62); onto the seat he sits; the frog hops there
    'llega': (o) async {
      final quien = o['quien'] as String, a = o['a'] as String;
      if (quien == 'coqui') return _salta(a);
      if (!_p.has(a)) return;
      if (quien == 'turista') {
        final t = _gente['turista'] as Map<String, dynamic>?;
        if (t == null || t['vis'] == 0) {
          // the next visitor: the one waiting at fila1 steps up, or a new one walks in
          if (_n(W['fila1']) == 1) {
            W['fila1'] = 0;
            W['visita'] = _n(W['fila1Look']);
            _gente['turista'] = _person('fila1');
          } else {
            W['visita'] = _n(W['nuevo']);
            W['nuevo'] = _n(W['nuevo']) + 1;
          }
        }
      }
      _cambio = null;
      final to = _sitio(quien, a);
      final cambio = _cambio;
      if (cambio != null) {
        await _anda(cambio.$1, cambio.$2);
        _face(_g(cambio.$1), 'coqui');
      }
      await _anda(quien, to);
      // once there, he turns to the frog (on the seat he faces us); if turned so he would cover the frog (a cane, a
      // bag on the side), he faces the other way
      if (!_p.group('asientos').contains(a)) {
        final p = _g(quien);
        _face(p, 'coqui');
        _boxesF = null;
        if (_tapa(quien) > 0) {
          p['dir'] = -_n(p['dir']);
          _boxesF = null;
          if (_tapa(quien) > 0) p['dir'] = -_n(p['dir']);
        }
      }
    },
    // `sale` {quien}: walks out (60 to 62)
    'sale': (o) => _sale(o['quien'] as String),
    // `mano` {a, b}: two shake hands (60); with the frog, his whole arm goes up and down (he bounces)
    'mano': (o) async {
      final a = o['a'] as String, b = o['b'] as String;
      final pa = a == 'coqui' ? null : _g(a), pb = b == 'coqui' ? null : _g(b);
      if (pa != null) {
        _face(pa, b);
        pa['pose'] = 'mano';
      }
      if (pb != null) {
        _face(pb, a);
        pb['pose'] = 'mano';
      }
      for (var i = 0; i < 4; i++) {
        if (a == 'coqui' || b == 'coqui') host.bounce(4);
        for (final p in [pa, pb]) {
          if (p != null) p['dy'] = i % 2 == 0 ? 1 : 0;
        }
        await wait(TICK * 2);
      }
      for (final p in [pa, pb]) {
        if (p != null) {
          p['pose'] = 'idle';
          p['dy'] = 0;
        }
      }
    },
    // `burbujas` {izq}: the two answer bubbles over the frog, and which picture is at the left (insignia, manos) (60)
    'burbujas': (o) async {
      W['burbujas'] = <String, dynamic>{
        'izq': o['izq'] == 'manos' ? 'manos' : 'insignia',
        'dice': null,
      };
      host.SFX.blip();
      await wait(TICK * 2);
    },
    // `dice60` {cual}: the frog says a bubble's line: that bubble lights while he says it (60: 3, 5, 6)
    'dice60': (o) async {
      final bu = W['burbujas'];
      if (bu is Map) bu['dice'] = o['cual'];
      host.bounce(5);
      await wait(TICK * 8);
      final now = W['burbujas'];
      if (now is Map) now['dice'] = null;
    },
    // `rien60`: Luis, Carmen and Ana burst out laughing (60)
    'rien60': (o) async {
      final who = [
        for (final k in const ['luis', 'carmen', 'ana'])
          if ((_gente[k] as Map?)?['vis'] == 1) _g(k),
      ];
      for (final p in who) {
        p['pose'] = 'rie';
      }
      for (var i = 0; i < 6; i++) {
        for (final p in who) {
          p['dy'] = i % 2 == 0 ? -1 : 0;
        }
        await wait(TICK);
      }
      for (final p in who) {
        p['pose'] = 'idle';
        p['dy'] = 0;
      }
    },
    // `palomas` {n}: the pigeons on the seat's back (respaldo1 to 3), turned towards the frog (60)
    'palomas': (o) async {
      final g = _p.group('respaldos'), n = math.min(_n(o['n']), g.length);
      final fx = (W['cq'] as Map)['x'] as num;
      W['palomas'] = [
        for (var i = 0; i < n; i++)
          () {
            final w = _p.world(g[i]);
            return <String, dynamic>{
              'x': w[0],
              'y': w[1],
              'z': w[2],
              'spot': g[i],
              'vis': 1,
              'pose': 'posada',
              'dir': _p.at(g[i]).sx < fx + 16 ? 1 : -1,
            };
          }(),
      ];
    },
    // `paloma_va`: one pigeon flies off, up over the tree and away (60)
    'paloma_va': (o) async {
      final pal = (W['palomas'] as List).cast<Map<String, dynamic>>();
      Map<String, dynamic>? p;
      for (final x in pal.reversed) {
        if (x['vis'] != 0 && x['en'] == null && x['pose'] != 'vuela') {
          p = x;
          break;
        }
      }
      if (p == null) return;
      p['pose'] = 'vuela';
      host.SFX.swoop();
      final x0 = p['x'] as num, y0 = p['y'] as num, z0 = p['z'] as num;
      for (var i = 1; i <= 10; i++) {
        p['x'] = x0 - .25 * i;
        p['y'] = y0 - .45 * i;
        p['z'] = z0 + .45 * i;
        await wait(TICK);
      }
      p['vis'] = 0;
    },
    // `final60` {n}: the ending, by the pigeons left: three, on Ana's hand, Beto's cap and the frog's head (stars); two,
    // on Ana's hand and the frog's head, Beto claps; one, eating from the frog's hand, Ana and Beto very still (60: 7)
    'final60': (o) async {
      W['burbujas'] = null;
      final n = _n(o['n']);
      final pal = [
        for (final x in (W['palomas'] as List).cast<Map<String, dynamic>>())
          if (x['vis'] != 0) x,
      ];
      final where = n >= 3
          ? ['mano:ana', 'gorra:beto', 'cabeza:coqui']
          : n == 2
          ? ['mano:ana', 'cabeza:coqui']
          : ['mano:coqui'];
      for (var i = 0; i < pal.length; i++) {
        if (i < where.length) {
          pal[i]['pose'] = 'vuela';
          await wait(TICK * 2);
          pal[i]['en'] = where[i];
          pal[i]['pose'] = where[i] == 'mano:coqui' ? 'come' : 'posada';
          host.SFX.blip();
        } else {
          pal[i]['vis'] = 0;
        }
      }
      for (final k in const ['ana', 'beto']) {
        final p = _gente[k] as Map<String, dynamic>?;
        if (p != null) _face(p, 'coqui');
      }
      if (n == 2) {
        final b = _gente['beto'] as Map<String, dynamic>?;
        for (var i = 0; i < 6 && b != null; i++) {
          b['pose'] = i % 2 == 0 ? 'rie' : 'idle';
          await wait(TICK);
        }
        b?['pose'] = 'idle';
      }
      if (n >= 3) {
        final h = _cabeza(W, 'coqui');
        if (h != null) {
          host.fx({
            't': 'star',
            'n': 36,
            'pts': [
              [h[0] - 30, h[1] - 4],
              [h[0] + 26, h[1] - 6],
              [h[0] - 60, h[1] + 6],
              [h[0], h[1] - 16],
            ],
          });
        }
        host.SFX.win();
      }
      await wait(TICK * 10);
    },
    // `foto61` {quien, fila, ok}: a photo is hung under the island or the city; not ok: it is taken down again, the frog
    // reaching across the ledge knocks the stone (61)
    'foto61': (o) async {
      final quien = o['quien'] as String,
          fila = o['fila'] == 'ciudad' ? 'ciudad' : 'isla';
      final ok = _n(o['ok']) == 1;
      final a = _gente['ana'] as Map<String, dynamic>?;
      if (quien == 'ana' && a != null) _face(a, 'fila_$fila');
      final f = await _cuelga(fila, quien: quien);
      if (ok || f == null) return;
      await wait(TICK * 6);
      // the frog reaches across for it: a hop on the spot, the stone rocks
      host.bounce(6);
      W['piedra'] = F + 12;
      _fotos.remove(f);
      host.SFX.toc();
      await wait(TICK * 4);
    },
    // `tarjetas` {n}: the blank cards under the stone on the ledge (61)
    'tarjetas': (o) async {
      W['tarjetas'] = math.max(0, _n(o['n']));
    },
    // `vuela61`: the wind takes a card away over the wall (61: 6, 7)
    'vuela61': (o) async {
      host.SFX.swoop();
      final w = _p.world('repisa');
      final c = _cosa('tarjeta_vuela', 'tarjeta_vuela', [
        w[0],
        w[1],
        w[2] + .1,
      ]);
      W['tarjetas'] = math.max(0, _n(W['tarjetas']) - 1);
      final from = _p.uvOf(w[0], w[1]);
      for (var i = 1; i <= 12; i++) {
        final p = _p.xyOf(from[0] + .2 * i, from[1] - .35 * i);
        c['x'] = p[0];
        c['y'] = p[1];
        c['z'] = w[2] + .3 * i;
        await wait(TICK);
      }
      _items.remove(c);
    },
    // `dibuja61` {n}: the ending: the frog draws on the cards left (abuela's house, abuela, the whole family) and hangs
    // them on the free hooks, the city's first (61: 8)
    'dibuja61': (o) async {
      final n = _n(o['n']);
      W['tarjetas'] = 0;
      final lap = _cosa('lapiz', 'lapiz', _frogWorld(), con: 'coqui');
      for (final k in const ['casa', 'abuela', 'familia'].take(n)) {
        host.bounce(4);
        await wait(TICK * 4);
        await _cuelga(_libre('ciudad') != null ? 'ciudad' : 'isla', dibujo: k);
      }
      _items.remove(lap);
      if (n >= 3) {
        host.fx({
          't': 'star',
          'n': 36,
          'pts': [
            [40, 60],
            [80, 56],
            [60, 44],
            [30, 50],
          ],
        });
        host.SFX.win();
      }
      await wait(TICK * 6);
    },
    // `pide62` {quien, cosa}: a visitor's bubble: the flag of the United States and a small piragua or guagua (62)
    'pide62': (o) async {
      W['pide'] = <String, dynamic>{
        'quien': o['quien'],
        'cosa': o['cosa'] == 'guagua' ? 'guagua' : 'piragua',
      };
      W['traduce'] = null;
      final t = _gente[o['quien']] as Map<String, dynamic>?;
      if (t != null) _face(t, 'piraguero');
      host.SFX.blip();
      await wait(TICK * 4);
    },
    // `traduce62` {quien}: the two-flag bubble over a helper (62); it stays while she helps
    'traduce62': (o) async {
      W['traduce'] = o['quien'];
      host.SFX.blip();
      await wait(TICK * 6);
    },
    // `ayuda62` {quien, ok}: a helper listens to the visitor and helps (a nod, then he turns to the piragüero), or
    // shrugs (62: 5, 6)
    'ayuda62': (o) async {
      final p = _g(o['quien'] as String);
      _face(p, 'turista');
      await wait(TICK * 5);
      if (_n(o['ok']) == 1) {
        for (var i = 0; i < 2; i++) {
          p['dy'] = 2;
          await wait(TICK);
          p['dy'] = 0;
          await wait(TICK);
        }
        _face(p, 'piraguero');
        p['pose'] = 'senala';
        await wait(TICK * 4);
        p['pose'] = 'idle';
      } else {
        p['pose'] = 'hombros';
        await wait(TICK * 8);
        p['pose'] = 'idle';
      }
    },
    // `piragua62` {color}: the piragüero makes one and hands it to the visitor (rojo: a red one) (62)
    'piragua62': (o) => _piragua(1),
    // `moneda`: a coin into the jar (62)
    'moneda': (o) => _moneda(),
    // `cola` {n}: the visitors at the back of the line (fila2 on); the first `cola` also brings the next one to fila1 (62)
    'cola': (o) async {
      if (_n(W['cola']) == 0 &&
          _n(W['fila1']) == 0 &&
          (_gente['turista'] as Map?)?['vis'] == 1 &&
          _n(o['n']) >= 3) {
        // "two in front, and three behind them": the next one waits at fila1, the three at the back from fila2 on
        W['fila1'] = 1;
        W['fila1Look'] = _n(W['nuevo']);
        W['colaLook'] = _n(W['nuevo']) + 1;
        W['nuevo'] = _n(W['nuevo']) + 1 + _n(o['n']);
      }
      W['cola'] = math.max(0, _n(o['n']));
      await wait(TICK * 2);
    },
    // `se_va62`: the last one in the line looks at his watch and walks away (62: 5, 6)
    'se_va62': (o) async {
      final n = _n(W['cola']);
      if (n == 0) return;
      final spot = 'fila${n + 1}';
      W['reloj'] = spot;
      await wait(TICK * 8);
      W['reloj'] = null;
      // he walks off: a person of his own for the walk out, his place in the line empty
      final look = _look(_n(W['colaLook']) + n - 1);
      W['cola'] = n - 1;
      final p = _person(spot)..['look'] = look;
      _gente['visita_va'] = p;
      await _anda('visita_va', 'entrada');
      _gente.remove('visita_va');
    },
    // `atiende62` {n}: Ana helps the n visitors still in the line, one after another: piraguas, coins; the piragüero
    // counts his jar (62: 7)
    'atiende62': (o) async {
      final n = math.min(_n(o['n']), _n(W['cola']) + _n(W['fila1']));
      for (var k = 0; k < n; k++) {
        // the next one in the line steps up to the cart
        if (_n(W['fila1']) == 1) {
          W['fila1'] = 0;
          W['visita'] = _n(W['fila1Look']);
          _gente['turista'] = _person('fila1');
        } else {
          // the front one of the line (fila2) steps up; the others move up a place
          W['visita'] = _n(W['colaLook']);
          W['colaLook'] = _n(W['colaLook']) + 1;
          W['cola'] = math.max(0, _n(W['cola']) - 1);
          _gente['turista'] = _person('fila2');
        }
        await _anda('turista', 'turno');
        _g('turista')['dir'] = 1;
        W['pide'] = <String, dynamic>{'quien': 'turista', 'cosa': 'piragua'};
        await wait(TICK * 3);
        W['traduce'] = 'ana';
        await wait(TICK * 3);
        await _piragua(1);
        await _moneda();
        await _sale('turista');
      }
      // the piragüero counts the coins in his jar
      final pi = _g('piraguero');
      _face(pi, 'carro_borde');
      for (var i = 0; i < _n(W['jarra']); i++) {
        pi['dy'] = i % 2 == 0 ? 1 : 0;
        host.SFX.drop();
        await wait(TICK);
      }
      pi['dy'] = 0;
    },
    // `final62` {n}: the frog's piragua, of three, two or one colours (three: as big as he is, stars) (62: 7)
    'final62': (o) async {
      final n = math.max(1, math.min(3, _n(o['n'])));
      final pi = _g('piraguero');
      pi['pose'] = 'mano';
      _face(pi, 'coqui');
      await wait(TICK * 4);
      _cosa(
        'piragua_coqui',
        n == 3 ? 'piragua_grande' : 'piragua',
        _frogWorld(),
        v: n,
        con: 'coqui',
      );
      pi['pose'] = 'idle';
      host.SFX.blip();
      if (n == 3) {
        final h = _cabeza(W, 'coqui');
        if (h != null) {
          host.fx({
            't': 'star',
            'n': 36,
            'pts': [
              [h[0] - 26, h[1]],
              [h[0] + 22, h[1] - 6],
              [h[0], h[1] - 14],
              [h[0] - 40, h[1] + 10],
            ],
          });
        }
        host.SFX.win();
      }
      await wait(TICK * 8);
    },
    // `gesto` {quien, que, a}: a small move of one person
    'gesto': (o) async {
      final quien = o['quien'] as String,
          que = o['que'] as String?,
          a = o['a'] as String?;
      if (quien == 'coqui') {
        host.bounce(6);
        await wait(TICK * 3);
        return;
      }
      if (que == 'llama' && (_gente[quien] as Map?)?['vis'] != 1) {
        // OPEN: "calls from across the square": the sheet names no place across the square inside the view; she is at
        // `entrada` (where people come in, outside the window), so the call is heard, not seen
        _gente[quien] = _person('entrada');
      }
      final p = _g(quien);
      if (p['vis'] == 0) return;
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
        case 'llama':
          for (var i = 0; i < 6; i++) {
            p['pose'] = i % 2 == 0 ? 'llama0' : 'llama1';
            await wait(TICK);
          }
          p['pose'] = 'idle';
        case 'no':
          final d = _n(p['dir']) < 0 ? -1 : 1;
          for (var i = 0; i < 4; i++) {
            p['dir'] = i % 2 == 0 ? -d : d;
            await wait(TICK);
          }
          p['dir'] = d;
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
        case 'hombros':
          await hold('hombros', 6);
        case 'cabeza':
          await hold('cabeza', 6);
        case 'guino':
          await hold('guino', 5);
        case 'arrodilla':
          // she kneels down to Canelo: lower, turned to him; she stays down until she walks again
          _face(p, 'bajo');
          p['pose'] = 'arrodilla';
          await wait(TICK * 4);
        case 'sienta':
          p['sent'] = 1;
          p['dir'] = 1;
          await wait(TICK * 3);
        default:
          await wait(TICK * 3);
      }
    },
  };
}
