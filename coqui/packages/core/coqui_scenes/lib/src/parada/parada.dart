// La parada (place 5, La calle, scene 2; stories 51 to 53): a NEW scene, written from its script's "Needs" list
// (historia/notas/guiones/parada.md) on its set (parada_set.dart) and its sheet (parada-sheet.json, read by SceneSheet).
// There is no old scene file: every act is this file's, each doing on screen what the Needs list says, every place from
// the sheet (a spot's world point, a thing's box, the guagua's numbers in constants.guagua, the depth rule). Where the
// sheet names no place, or the script does not settle what an act shows, the act does the plainest thing that keeps the
// story playing and says so in a comment starting `OPEN:` (page 13 lists them for the content lane).
//
// The drawing (the sheet's `front`): every person and small thing stands with its feet's bottom edge on its spot's row
// and its middle on its column (rules.anchor); its pixel is hidden by every set pixel nearer the camera than the upright
// plane through its feet plus `front.bias` (front.plane). The guaguas are La calle's vehicle sprites (calle_vehicles.dart:
// baked once from calle-base.js `vehicle`), placed by the middle of their floor, each pixel with its own depth: a set
// pixel nearer than it hides it, and a person is hidden by it as by the set; the frog is never hidden by a grown-up or a
// guagua (the sheet's rule). What belongs to a guagua is drawn into its pixels: a head at its glass only through a pane
// of its windows (rules.anchor, parada-preview.html inPane), the basket of rolls on the sill the same way, the chofer
// leaning out at its front end; so it moves with the guagua and whoever stands in front of the guagua is drawn over it.
// ignore_for_file: non_constant_identifier_names

import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/src/calle/calle_cast.dart';
import 'package:coqui_scenes/src/calle/calle_vehicles.dart';
import 'package:coqui_scenes/src/colmado/colmado_cast.dart';
import 'package:coqui_scenes/src/parada/parada_places.dart';
import 'package:coqui_scenes/src/parada/parada_set.dart';
import 'package:coqui_scenes/src/parada/parada_sprites.dart';
import 'package:coqui_scenes/src/scene_set.dart';
import 'package:coqui_scenes/src/sheet_cache.dart';

/// The scene "La parada", made from its sheet (read first: `loadScene`).
Scene createParada() => Parada(sceneSheetOf('parada'));

int _round(num v) => (v + 0.5).floor();

int _n(Object? v) => v is num ? v.toInt() : (int.tryParse('$v') ?? 0);

/// One sprite of the sprite layer, placed: its picture, its top left on the 240 x 216 picture, the screen row of its
/// feet and the depth there (front.plane).
class ParadaItem {
  ParadaItem(
    this.s,
    this.left,
    this.top,
    this.sy,
    this.d, {
    this.tag,
    this.grown = false,
    this.held = false,
  });

  /// A grown-up (whose pixels never hide the frog).
  final bool grown;

  /// A thing in the frog's hand (in front of him: it hides what of him it covers; marked 3 in the layer).
  final bool held;

  final Sprite s;
  final int left, top;
  final num sy;
  final double d;

  /// Who or what it is (the rules' tests read it: `persona:<id>`, `coqui`, `perro`, `cosa:<id>`).
  final String? tag;
}

/// A guagua of the sprite layer, placed: its sprite, top left, the depth of its floor's middle, its key (its board), the
/// x of its middle.
class ParadaAuto {
  ParadaAuto(this.v, this.left, this.top, this.d, this.tag, this.x);

  final VehicleSprite v;
  final int left, top;
  final double d;
  final String tag;
  final double x;
}

/// What is drawn into a guagua's pixels: a head at its glass (only through a pane), the basket on the sill (the same),
/// the chofer leaning out (not cut by the panes).
class ParadaOnBus {
  ParadaOnBus(
    this.s,
    this.left,
    this.top,
    this.bus,
    this.tag, {
    this.pane = true,
  });

  final Sprite s;
  final int left, top;
  final String bus, tag;
  final bool pane;
}

/// The people of the place who speak or can be touched (the speaker keys and `quien` of the three stories).
const List<String> _people = [
  'abuela',
  'luis',
  'carmen',
  'senora',
  'senor',
  'chofer',
];

/// Who is a child (their pixels may hide the frog a little: the sheet's check frog-seen allows 40).
const Set<String> _children = {'luis', 'carmen', 'nino3'};

/// Story 52's group at the kerb (parada-preview.html moment 4: a señora, a señor, a child at fila3 to fila5), and the two
/// passengers inside who get off (no stand-in gives them).
const Map<String, String> _grupo52 = {
  'senora': 'fila3',
  'senor': 'fila4',
  'nino3': 'fila5',
};
const List<String> _pasajeros = ['pasajera', 'pasajero'];

class Parada extends Escena implements SetScene, SetOverSprites {
  Parada(this.ss) : sheet = ss.legacy() {
    _p = ParadaPlaces(ss);
    CAM = {'wide': _p.view('wide')};
    LUGAR = {
      for (final e in _frogPlaces.entries) e.key: _frogAt(_p.at(e.value)),
      for (final s in ss.spots.entries)
        if (s.key.startsWith('coqui.') || s.key.startsWith('fila'))
          s.key: _frogAt(_p.at(s.key)),
    };
    cosas = _things();
  }

  /// The new scene's sheet (SceneSheet).
  final SceneSheet ss;

  @override
  final Sheet sheet;

  late final ParadaPlaces _p;

  /// The scene's places, from its sheet.
  ParadaPlaces get places => _p;

  @override
  String get id => 'parada';

  @override
  late final Map<String, List<num>> CAM;

  late final Map<String, List<num>> LUGAR;

  @override
  Map<String, List<num>> get lugar => LUGAR;

  @override
  late final List<Thing> cosas;

  @override
  PpEngine newEngine({bool still = false}) => paradaEngine(still: still);

  @override
  PpEngine get projection => _p.e;

  // where the frog's `ir` goes, by the stories' names
  static const Map<String, String> _frogPlaces = {
    // OPEN: the stories send the frog to `bordillo` (the Needs' "the kerb: abuela, the frog"), a spot the sheet does not
    // name: its people wait in the row (fila1 to fila5: "people wait here, not at the kerb"). He goes to fila2, where
    // parada-preview.html's moments 1 and 2 put him (abuela at fila3 beside him)
    'bordillo': 'fila2',
  };

  /// The sheet's spot of the frog's place [key], or null.
  String? frogSpotOf(String key) =>
      _frogPlaces[key] ?? (_p.has(key) ? key : null);

  // the frog's top left for a spot (rules.anchor: mkCoqui's column 16 on sx, its row 25 on sy)
  List<num> _frogAt(ParadaAt a) => [_round(a.sx) - 16, _round(a.sy) - 25, 1];

  Map<String, dynamic> get W => host.W;
  int get F => host.F;
  int get TICK => host.TICK;
  Future<void> wait(num ms) => host.wait(ms);
  Future<void> _tick() => wait(TICK);

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

  Map<String, dynamic> _person(String spot, {int vis = 1, String? lleva}) {
    final w = _p.world(spot);
    return <String, dynamic>{
      'x': w[0],
      'y': w[1],
      'z': w[2],
      'spot': spot,
      'vis': vis,
      'dir': 1,
      'pose': 'idle',
      'dy': 0,
      'sit': false,
      'lleva': lleva,
    };
  }

  @override
  Map<String, dynamic> fresh(Map<String, dynamic> story) {
    final acts = _actsOf([story['beats'], story['final']]);
    bool has(String a) => acts.any((o) => o['act'] == a);
    final gente = <String, dynamic>{};
    var hora = 'manana', historia = 0;
    Map<String, dynamic>? boletos;
    Object? bola;
    var cajas = 0;
    if (has('final51')) {
      // story 51 (parada-preview.html moment 1): Luis with his ball at fila1, the frog at fila2, abuela with her strip
      // of four tickets at fila3, Carmen with her basket at fila4; the señora comes to the seat (`gesto sienta`)
      historia = 51;
      gente['luis'] = _person('fila1', lleva: 'pelota');
      gente['abuela'] = _person('fila3', lleva: 'boletos');
      gente['carmen'] = _person('fila4', lleva: 'cesta');
      boletos = {'n': 4, 'quien': 'abuela'};
    } else if (has('final52')) {
      // story 52: the frog, Luis and abuela at the stop (Luis at fila4, abuela with her basket of rolls at fila5: at
      // fila3, moment 3's place for Luis, a child hides the frog at the back door's button, coqui.boton_baja, by 44 px,
      // more than the sheet's 40), Canelo lying under the seat (bajo_banco); fila1 and fila2 are free while the frog works
      // the buttons
      historia = 52;
      gente['luis'] = _person('fila4');
      gente['abuela'] = _person('fila5', lleva: 'panes');
      gente['perro'] = _person('bajo_banco')..['pose'] = 'lie';
    } else if (has('final53')) {
      // story 53: early; abuela with the two boxes at fila3 beside the frog; the ball on the seat (banco_medio)
      historia = 53;
      hora = 'temprano';
      gente['abuela'] = _person('fila3', lleva: 'cajas');
      bola = 'banco_medio';
      cajas = 2;
    }
    final q = _frogAt(_p.at('fila2'));
    return {
      'historia': historia,
      'hora': hora,
      'gente': gente,
      'autos': <String, dynamic>{},
      'viajan': <String, dynamic>{},
      'fuera': <dynamic>[],
      'boletos': boletos,
      'panes': null,
      'tapado': 0,
      'cajas': cajas,
      'cajaCoqui': 0,
      'bola': bola,
      'vuela': null,
      'sol': historia == 53 ? 0 : null,
      'chofer': null,
      'signo': null,
      'sombra': 1.0,
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
      },
    };
  }

  /* ---------- the set ---------- */

  // the sheet's setKey: the hora
  @override
  String setKey(Map<String, dynamic> W) {
    final h = W['hora'];
    return h is String && PARADA_HORAS.contains(h) ? h : 'manana';
  }

  @override
  void buildSet(PpEngine e, PpBuild b, Map<String, dynamic> W) =>
      buildSetFor(e, b, setKey(W));

  final Map<PpEngine, ParadaSet> _sets = {};

  @override
  void buildSetFor(PpEngine e, PpBuild b, String key) =>
      (_sets[e] ??= ParadaSet(e, b)).buildSet(ParadaState.fromKey(key));

  // the frog casts his shadow in the engine (shadows.byCharacter.coqui); never the old one
  @override
  bool get frogShadow => false;

  /* ---------- where everybody is ---------- */

  Map<String, dynamic> get _gente => W['gente'] as Map<String, dynamic>;
  Map<String, dynamic> get _autos => W['autos'] as Map<String, dynamic>;
  Map<String, dynamic> get _cq => W['cq'] as Map<String, dynamic>;

  Map<String, dynamic> _g(String id) =>
      (_gente[id] ??= _person('camino', vis: 0)) as Map<String, dynamic>;

  bool _seen(String id) {
    final p = _gente[id] as Map<String, dynamic>?;
    return p != null && p['vis'] != 0;
  }

  ParadaAt _atOf(Map<String, dynamic> o) =>
      _p.atWorld(o['x'] as num, o['y'] as num, o['z'] as num);

  // the frog's world point under his feet
  ParadaAt _frogPoint(Map<String, dynamic> q) {
    final b = host.frogBox(q);
    return _p.fromScreen(b.x + b.w / 2, (q['y'] as num) + 25, 0);
  }

  // the guagua that stands (or is on its way) at [spot] (`parada1`, `parada2`), or null
  Map<String, dynamic>? _busAt(String spot) {
    for (final v in _autos.values) {
      final m = v as Map<String, dynamic>;
      if (m['vis'] != 0 && m['spot'] == spot) return m;
    }
    return null;
  }

  Map<String, dynamic>? _bus(String? board) {
    final v = board == null ? null : _autos[board] as Map<String, dynamic>?;
    return v != null && v['vis'] != 0 ? v : null;
  }

  // a spot of the guagua at [stop]: the sheet's spots of the second guagua are the first's with ".2"
  String _of(String spot, String? stop) => stop == 'parada2' ? '$spot.2' : spot;

  /* ---------- sprites ---------- */

  static final Map<String, Sprite> _sprites = {};
  static Sprite _spr(String key, Sprite Function() make) =>
      _sprites[key] ??= make();

  static final Map<String, Sprite> _mirrored = {};
  static Sprite _mirrorOf(String key, Sprite s) =>
      _mirrored[key] ??= mirrorSprite(s);

  // what a person holds, drawn over the sprite at (x, y) of it (parada-preview.html `holding`: abuela's strip at (17, 31),
  // Luis's ball at (12, 27), Carmen's basket at (6, 24), abuela's boxes on her lap at (22, 33) of her sitting sprite;
  // the rest beside those: this file's choice)
  ({Sprite s, int x, int y})? _held(String id, Map<String, dynamic> p) {
    final lleva = p['lleva'] as String?;
    if (lleva == null) return null;
    final sit = jsTruthy(p['sit']);
    switch (lleva) {
      case 'boletos':
        final b = W['boletos'] as Map<String, dynamic>?;
        final n = b == null ? 0 : _n(b['n']);
        if (n <= 0) return null;
        return (s: _spr('boletos$n', () => mkBoletos(n)), x: 17, y: 31);
      case 'pelota':
        return (
          s: _spr('pelota', mkPelota),
          x: id == 'abuela' ? 17 : 12,
          y: 27,
        );
      case 'cesta':
        return (s: _spr('cesta', mkCestaCarmen), x: 6, y: 24);
      case 'cajas':
        final n = _n(W['cajas']);
        if (n <= 0) return null;
        return (
          s: _spr('cajas$n', () => mkCajas(n)),
          x: sit ? 22 : 17,
          y: sit ? 33 : 31,
        );
      case 'panes':
        final n = W['panes'] == null ? 3 : _n(W['panes']);
        return (s: _spr('panes${n}h', () => mkPanes(n)), x: 17, y: 30);
    }
    return null;
  }

  // a person's sprite and the point of it that stands on the spot (rules.anchor)
  ({Sprite s, int ax, int ay, String key}) _personSprite(
    String id,
    Map<String, dynamic> p,
    bool open,
  ) {
    final pose = (p['pose'] as String?) ?? 'idle';
    final f = (F >> 2) % 2 == 1;
    if (id == 'perro') {
      final pan = jsTruthy(p['pan']);
      final key = 'perro$pose$pan${pose == 'run' || pose == 'eat' ? f : ''}';
      final s = _spr(key, () => pan ? mkPerroPan(pose, f) : mkPerro(pose, f));
      return (s: s, ax: 13, ay: inkBottom(s), key: key);
    }
    final sit = jsTruthy(p['sit']);
    final held = _held(id, p);
    final key =
        'p$id$pose$open$sit${p['lleva']}${held == null ? '' : '${held.s.w}x${held.s.h}${W['panes']}${W['cajas']}'}';
    final Anchored a;
    if (sit) {
      a = paradaSitting(id, open: open);
    } else {
      final who = paradaWho(id);
      if (who != null) {
        final persona = switch (pose) {
          'saluda0' => 'wave0',
          'saluda1' => 'wave1',
          'mano' => 'offer',
          _ => 'idle',
        };
        final s = mkPersona(who, persona, open, false);
        a = (s: s, ax: PX, ay: inkBottom(s));
      } else {
        a = callePerson(id, pose, open: open);
      }
    }
    if (held == null) return (s: a.s, ax: a.ax, ay: a.ay, key: key);
    final s = _spr(key, () => overSprite(a.s, [(held.s, held.x, held.y)]));
    return (s: s, ax: a.ax, ay: a.ay, key: key);
  }

  // the guagua's sprite: its board, its doors, the hour's light (the set's lightPass)
  VehicleSprite _busSprite(Map<String, dynamic> v) {
    final front = jsTruthy(v['delante']), back = jsTruthy(v['atras']);
    final look = front && back
        ? 'puertas'
        : front
        ? 'puerta'
        : back
        ? 'atras'
        : '';
    final s = vehicleSprite(
      'guagua',
      'i',
      board: v['board'] as String,
      look: look,
    );
    final L = PARADA_LIGHT[setKey(W)];
    return L == null ? s : litVehicle(s, L.$1, L.$2);
  }

  // where a held thing is drawn at the frog: at his right hand (this file's choice)
  ({int x, int y, double d, num sy})? _frogHand() {
    final q = _cq;
    if (!jsTruthy(q['vis'])) return null;
    final b = host.frogBox(q), at = _frogPoint(q);
    return (
      x: _round(b.x + b.w - 7),
      y: _round((q['y'] as num) + 23),
      d: at.d + .05,
      sy: at.sy,
    );
  }

  /// Every sprite of the frame [w] but the frog and the guaguas, placed: the people, Canelo, the small things.
  List<ParadaItem> items(Map<String, dynamic> w, int a) {
    final out = <ParadaItem>[];
    final talk = _talker();
    final gente = (w['gente'] as Map<String, dynamic>?) ?? const {};
    for (final en in gente.entries) {
      final p = en.value as Map<String, dynamic>;
      if (p['vis'] == 0) continue;
      final open = talk == en.key && a % 2 == 1;
      final sp = _personSprite(en.key, p, open);
      final at = _atOf(p);
      final dir = _n(p['dir']) < 0 ? -1 : 1;
      final s = dir < 0 ? _mirrorOf(sp.key, sp.s) : sp.s;
      final ax = dir < 0 ? sp.s.w - 1 - sp.ax : sp.ax;
      final sx = _round(at.sx), sy = _round(at.sy) + _n(p['dy']);
      out.add(
        ParadaItem(
          s,
          sx - ax,
          sy - sp.ay,
          sy,
          at.d,
          tag: en.key == 'perro' ? 'perro' : 'persona:${en.key}',
          grown: en.key != 'perro' && !_children.contains(en.key),
        ),
      );
    }
    // the ball on the seat (banco_medio: "a small thing: its bottom middle on the point")
    if (w['bola'] == 'banco_medio') {
      final s = _spr('pelota', mkPelota);
      final at = _p.at('banco_medio');
      final sx = _round(at.sx), sy = _round(at.sy);
      out.add(
        ParadaItem(
          s,
          sx - s.w ~/ 2,
          sy - inkBottom(s),
          sy,
          at.d,
          tag: 'cosa:bola',
        ),
      );
    }
    // what the frog holds: his strip of tickets, a box, the ball
    final h = _frogHand();
    if (h != null) {
      Sprite? s;
      final b = w['boletos'] as Map<String, dynamic>?;
      if (b != null && b['quien'] == 'coqui' && _n(b['n']) > 0) {
        final n = _n(b['n']);
        s = _spr('boletos$n', () => mkBoletos(n));
      } else if (_n(w['cajaCoqui']) == 1) {
        s = _spr('cajas1', () => mkCajas(1));
      } else if (w['bola'] == 'coqui') {
        s = _spr('pelota', mkPelota);
      }
      if (s != null) {
        out.add(
          ParadaItem(
            s,
            h.x - s.w ~/ 2,
            h.y - s.h,
            h.sy,
            h.d,
            tag: 'cosa:mano_coqui',
            held: true,
          ),
        );
      }
    }
    return out;
  }

  /// Every guagua of the frame [w], placed.
  List<ParadaAuto> autos(Map<String, dynamic> w) {
    final out = <ParadaAuto>[];
    final autos = (w['autos'] as Map<String, dynamic>?) ?? const {};
    for (final en in autos.entries) {
      final v = en.value as Map<String, dynamic>;
      if (v['vis'] == 0) continue;
      final s = _busSprite(v);
      final at = placeVehicle(_p.e, s, v['x'] as num, v['y'] as num);
      out.add(
        ParadaAuto(
          s,
          at.left,
          at.top,
          at.d,
          'auto:${en.key}',
          (v['x'] as num).toDouble(),
        ),
      );
    }
    return out;
  }

  /// What is drawn into each guagua of [w]: the heads at the glass of the one at parada1 (ventana1, ventana2), the basket
  /// on its sill, its chofer leaning out (while he speaks or does something).
  List<ParadaOnBus> onBus(Map<String, dynamic> w, int a) {
    final out = <ParadaOnBus>[];
    final autos = (w['autos'] as Map<String, dynamic>?) ?? const {};
    final talk = _talker();
    for (final en in autos.entries) {
      final v = en.value as Map<String, dynamic>;
      if (v['vis'] == 0 || v['ventanas'] != 1) continue;
      final dx = (v['x'] as num) - _p.p1;
      final riders = (v['riders'] as Map?)?.cast<String, dynamic>() ?? const {};
      for (final r in riders.entries) {
        final id = r.value as String;
        final w0 = _p.world(r.key);
        final at = _p.atWorld(w0[0] + dx, w0[1], w0[2]);
        final open = talk == (id == 'coqui' ? 'tu' : id) && a % 2 == 1;
        final hd = mkCabezaCached(id, open);
        final flip = (v['flip'] as Map?)?[id] == 1;
        final s = flip ? _mirrorOf('cab$id$open', hd.s) : hd.s;
        final ax = flip ? hd.s.w - 1 - hd.ax : hd.ax;
        out.add(
          ParadaOnBus(
            s,
            _round(at.sx) - ax,
            _round(at.sy) - hd.ay + _n((v['wave'] as Map?)?[id]),
            en.key,
            'cabeza:$id',
          ),
        );
      }
      // the basket of rolls on the sill of ventana1 (parada-preview.html moment 3: ventana1 with z less .3, its bottom
      // middle on the point), while abuela sits there
      if (w['panes'] != null && riders['ventana1'] == 'abuela') {
        final n = _n(w['panes']), tap = _n(w['tapado']) == 1;
        final s = _spr('panes$n$tap', () => mkPanes(n, tapado: tap));
        final w0 = _p.world('ventana1');
        final at = _p.atWorld(w0[0] + dx, w0[1], w0[2] - .3);
        out.add(
          ParadaOnBus(
            s,
            _round(at.sx) - s.w ~/ 2,
            _round(at.sy) - inkBottom(s),
            en.key,
            'cosa:panes',
          ),
        );
      }
      // the chofer leans out while he speaks or does something (the rest of the time he is not seen: leaning out at the
      // sheet's spot `chofer` he covers the front door, its arrow and its button, which the frog must touch)
      final ch = w['chofer'] as String?;
      if (ch != null || talk == 'chofer') {
        final pose = ch ?? 'idle';
        final open = talk == 'chofer' && a % 2 == 1;
        final s = _spr('chofer$pose$open', () => mkChofer(pose, open: open));
        final w0 = _p.world('chofer');
        final at = _p.atWorld(w0[0] + dx, w0[1], w0[2]);
        out.add(
          ParadaOnBus(
            s,
            _round(at.sx) - PX,
            _round(at.sy) - 11,
            en.key,
            'persona:chofer',
            pane: false,
          ),
        );
      }
    }
    return out;
  }

  static final Map<String, ({Sprite s, int ax, int ay})> _heads = {};
  static ({Sprite s, int ax, int ay}) mkCabezaCached(String id, bool open) =>
      _heads['$id$open'] ??= mkCabeza(id, open: open);

  // who is talking now (the runner's TALK), or null
  String? _talker() {
    try {
      return host.TALK;
    } catch (_) {
      return null;
    }
  }

  /* ---------- drawing ---------- */

  PpEngine? _frameEngine;
  Float32List? _setZ;
  final Uint32List _layer = Uint32List(240 * 216);
  final Float32List _lz = Float32List(240 * 216);
  final Uint8List _isV = Uint8List(240 * 216);
  final Int8List _busPx = Int8List(240 * 216);

  @override
  void setFramed(PpEngine engine, BakedSet baked, Map<String, dynamic> W) {
    _frameEngine = engine;
    _setZ = baked.zb;
  }

  static final double _t30 = math.tan(math.pi / 6);

  /// Composes [it] into a layer ([layer], depths [lz], vehicles' marks [isV]: 1 a guagua's pixel, 2 a grown-up's) by the
  /// sheet's rule: hidden where [setZ] is nearer than its plane plus [bias], or a guagua's pixel is (the same rule), or
  /// another sprite's pixel is nearer than its plane. The frog is hidden by neither a guagua nor a grown-up. Returns how
  /// many of its pixels it drew. A pixel hidden is told to [hidden] with why: `set`, `auto` (a guagua), `held` (what
  /// the frog holds), `sprite` (another sprite).
  static int put(
    ParadaItem it,
    Uint32List layer,
    Float32List lz,
    Uint8List isV,
    Float32List? setZ,
    double bias,
    double S, {
    void Function(int i, String why)? hidden,
  }) {
    const w0 = 240, h0 = 216;
    final s = it.s;
    var n = 0;
    for (var y = 0; y < s.h; y++) {
      final Y = it.top + y;
      if (Y < 0 || Y >= h0) continue;
      final plane = it.d + (it.sy - (Y + .5)) * _t30 / S;
      for (var x = 0; x < s.w; x++) {
        final c = s.px[y * s.w + x];
        if (c >>> 24 == 0) continue;
        final X = it.left + x;
        if (X < 0 || X >= w0) continue;
        final i = Y * w0 + X;
        if (setZ != null && setZ[i] > plane + bias) {
          hidden?.call(i, 'set');
          continue;
        }
        if (!(it.tag == 'coqui' && (isV[i] == 1 || isV[i] == 2)) &&
            !personOver(i, plane, bias, lz, isV)) {
          hidden?.call(
            i,
            isV[i] == 1
                ? 'auto'
                : isV[i] == 3
                ? 'held'
                : 'sprite',
          );
          continue;
        }
        lz[i] = plane;
        layer[i] = c;
        isV[i] = it.grown
            ? 2
            : it.held
            ? 3
            : 0;
        n++;
      }
    }
    return n;
  }

  /// The frog as the game draws him (juego.js frog, at the depth of his feet), placed; null when he is not seen.
  ParadaItem? frogItem(Map<String, dynamic> W, int a) {
    final q = W['cq'] as Map<String, dynamic>;
    if (!jsTruthy(q['vis'])) return null;
    final b = host.frogBox(q), at = _frogPoint(q);
    final ox = b.x.toInt() - 16, oy = b.y.toInt() - 24;
    final px = Uint32List(64 * 64);
    final g = Ctx(px, 64, 64)..translate(-ox.toDouble(), -oy.toDouble());
    host.frog(g, q, a);
    return ParadaItem(
      Sprite(64, 64, px),
      ox,
      oy,
      _round(at.sy),
      at.d,
      tag: 'coqui',
    );
  }

  /// [items] and the frog: every sprite that stands, placed.
  List<ParadaItem> placed(Map<String, dynamic> W, int a) {
    final all = items(W, a);
    final f = frogItem(W, a);
    if (f != null) all.add(f);
    return all;
  }

  /// Composes the whole sprite layer of [W] into [layer] ([lz], [isV]): the guaguas and what is drawn into them, then
  /// every sprite that stands, the frog last. The rules' tests call it with a [hidden] that counts what hides what.
  void compose(
    Map<String, dynamic> W,
    int a,
    Uint32List layer,
    Float32List lz,
    Uint8List isV,
    Float32List? setZ, {
    void Function(ParadaItem it, int i, String why)? hidden,
  }) {
    layer.fillRange(0, layer.length, 0);
    lz.fillRange(0, lz.length, -1e9);
    isV.fillRange(0, isV.length, 0);
    _busPx.fillRange(0, _busPx.length, -1);
    final buses = autos(W);
    for (var k = 0; k < buses.length; k++) {
      final v = buses[k], s = v.v.s;
      // which pixels this guagua drew (putVehicle writes a pixel's depth where it draws it): kept in [_bus]
      final x0 = math.max(0, v.left), x1 = math.min(240, v.left + s.w);
      final y0 = math.max(0, v.top), y1 = math.min(216, v.top + s.h);
      final was = <double>[
        for (var y = y0; y < y1; y++)
          for (var x = x0; x < x1; x++) lz[y * 240 + x],
      ];
      putVehicle(v.v, v.left, v.top, v.d, layer, lz, isV, setZ);
      var j = 0;
      for (var y = y0; y < y1; y++) {
        for (var x = x0; x < x1; x++) {
          final i = y * 240 + x;
          if (lz[i] != was[j++]) _busPx[i] = k;
        }
      }
    }
    final bias = _p.bias, S = _p.e.S;
    for (final o in onBus(W, a)) {
      final k = buses.indexWhere((v) => v.tag == 'auto:${o.bus}');
      if (k < 0) continue;
      final mid = buses[k].x;
      final s = o.s;
      for (var y = 0; y < s.h; y++) {
        final Y = o.top + y;
        if (Y < 0 || Y >= 216) continue;
        for (var x = 0; x < s.w; x++) {
          final c = s.px[y * s.w + x];
          if (c >>> 24 == 0) continue;
          final X = o.left + x;
          if (X < 0 || X >= 240) continue;
          final i = Y * 240 + X;
          if (o.pane) {
            if (_busPx[i] != k || !_p.inPane(mid, X, Y)) continue;
          } else {
            // the chofer leaning out: in front of his guagua's side, hidden by the set as a person is
            final w0 = _p.world('chofer');
            final at = _p.atWorld(w0[0] + mid - _p.p1, w0[1], w0[2]);
            final plane = at.d + (at.sy - (Y + .5)) * _t30 / S;
            if (setZ != null && setZ[i] > plane + bias) continue;
            if (_busPx[i] != k && lz[i] > plane) continue;
            if (_busPx[i] != k) lz[i] = plane;
          }
          layer[i] = c;
          isV[i] = 1;
          _busPx[i] = k;
        }
      }
    }
    for (final it in placed(W, a)) {
      put(
        it,
        layer,
        lz,
        isV,
        setZ,
        bias,
        S,
        hidden: hidden == null ? null : (i, why) => hidden(it, i, why),
      );
    }
  }

  @override
  void draw(Ctx c, Map<String, dynamic> W, int a) {
    final setZ = _frameEngine != null ? _setZ : null;
    compose(W, a, _layer, _lz, _isV, setZ);
    c.drawImage(Sprite(240, 216, _layer), 0, 0);
    _over(c, W, a);
  }

  // what is drawn over everything: a ticket, a roll or the ball on its way; the frog's sign over his head
  void _over(Ctx c, Map<String, dynamic> W, int a) {
    final v = W['vuela'] as Map<String, dynamic>?;
    if (v != null) {
      final k = v['k'] as String;
      final s = switch (k) {
        'boleto' => _spr('boleto', mkBoleto),
        'pan' => _spr('pan', mkPan),
        _ => _spr('pelota', mkPelota),
      };
      c.drawImage(
        s,
        _round((v['x'] as num) - s.w / 2),
        _round((v['y'] as num) - s.h / 2),
      );
    }
    final sg = W['signo'] as String?;
    final q = W['cq'] as Map<String, dynamic>;
    if (sg != null && jsTruthy(q['vis'])) {
      final b = host.frogBox(q);
      final s = _spr('signo$sg', () => mkSignoCoqui(sg));
      c.drawImage(s, _round(b.x + b.w - 6), _round((q['y'] as num) - 4));
    }
  }

  /* ---------- the card: the goal and the two rounds ---------- */

  @override
  void hud(Ctx c, Map<String, dynamic> W, int a) {
    var x0 = 3;
    // the goal on the card (parada.md: the strip of tickets, story 51; the basket of rolls, 52; the sun, 53)
    Sprite? goal;
    final historia = _n(W['historia']);
    if (historia == 51) {
      final b = W['boletos'] as Map<String, dynamic>?;
      final n = b == null ? 0 : _n(b['n']);
      goal = n > 0
          ? _spr('boletos$n', () => mkBoletos(n))
          : _spr('boletos0', () => Sprite(8, 9, Uint32List(72)));
    } else if (historia == 52) {
      final n = W['panes'] == null ? 3 : _n(W['panes']);
      goal = _spr('panes${n}h', () => mkPanes(n));
    } else if (historia == 53) {
      final n = _n(W['sol']);
      goal = _spr('sol$n', () => mkSolCarta(n));
    }
    if (goal != null) {
      final w = goal.w + 8;
      tarjeta(c, x0, 3, w, 24);
      c.drawImage(goal, x0 + 4, 3 + (24 - goal.h) ~/ 2);
      x0 += w + 4;
    }
    if (!jsTruthy(W['tarjeta'])) return;
    final marcas = W['marcas'] is List ? W['marcas'] as List : const [];
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

  // castShadow(x, y, z, radius) at the world x, y, z of whoever stands, sits or lies (shadows.at; the radius by character,
  // a stranger by its kind: shadows.radius), the frog's (grown while he waits in the sun: espera53), and the casts of
  // each guagua (calle-base.js vehicle)
  @override
  List<ShadowCast> shadows(Map<String, dynamic> W) {
    final out = <ShadowCast>[];
    final rad = _p.sheet.shadows.radius;
    final gente = (W['gente'] as Map<String, dynamic>?) ?? const {};
    for (final en in gente.entries) {
      final p = en.value as Map<String, dynamic>;
      if (p['vis'] == 0) continue;
      final r =
          _p.radius(en.key) ??
          (_children.contains(en.key) ? rad['ninos'] : rad['adultos']);
      if (r == null) continue;
      final at = _atOf(p);
      out.add((x: at.x, y: at.y, z: at.z, r: r));
    }
    final q = W['cq'] as Map<String, dynamic>?;
    final rc = _p.radius('coqui');
    if (q != null && jsTruthy(q['vis']) && rc != null) {
      final at = _frogPoint(q);
      final k = (W['sombra'] as num?)?.toDouble() ?? 1;
      out.add((x: at.x, y: at.y, z: 0, r: rc * k));
    }
    final autos = (W['autos'] as Map<String, dynamic>?) ?? const {};
    for (final v in autos.values) {
      final m = v as Map<String, dynamic>;
      if (m['vis'] == 0) continue;
      out.addAll(vehicleShadows('guagua', m['x'] as num, m['y'] as num));
    }
    return out;
  }

  /* ---------- the things he can touch ---------- */

  static final Expando<List<int>> _inkOf = Expando<List<int>>();

  static List<int>? _ink(Sprite s) {
    final had = _inkOf[s];
    if (had != null) return had.isEmpty ? null : had;
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
    final r = x1 < 0 ? const <int>[] : [x0, y0, x1 - x0 + 1, y1 - y0 + 1];
    _inkOf[s] = r;
    return r.isEmpty ? null : r;
  }

  static List<num>? inkBox(Sprite s, int left, int top) {
    final b = _ink(s);
    return b == null ? null : [left + b[0], top + b[1], b[2], b[3]];
  }

  int? _boxesF;
  Map<String, dynamic>? _boxesW;
  String? _boxesTalk;
  Map<String, List<num>?> _boxes = {};

  Map<String, List<num>?> _allBoxes(Map<String, dynamic> w) {
    final out = <String, List<num>?>{
      for (final it in items(w, 0))
        if (it.tag != null) it.tag!: inkBox(it.s, it.left, it.top),
      for (final v in autos(w)) v.tag: inkBox(v.v.s, v.left, v.top),
    };
    for (final o in onBus(w, 0)) {
      // a head at the glass: what of it shows through the pane (its box, cut to the panes' rows and its guagua's box)
      out[o.tag] ??= inkBox(o.s, o.left, o.top);
    }
    return out;
  }

  List<num>? _boxOfTag(Map<String, dynamic> w, String tag) {
    int? f;
    try {
      f = host.F;
    } catch (_) {
      f = null;
    }
    if (f == null) return _allBoxes(w)[tag];
    final talk = _talker();
    if (f != _boxesF || !identical(w, _boxesW) || talk != _boxesTalk) {
      _boxes = _allBoxes(w);
      _boxesF = f;
      _boxesW = w;
      _boxesTalk = talk;
    }
    return _boxes[tag];
  }

  List<num>? _busBox(Map<String, dynamic> w, String stop) {
    for (final en
        in ((w['autos'] as Map<String, dynamic>?) ?? const {}).entries) {
      final v = en.value as Map<String, dynamic>;
      if (v['vis'] != 0 && v['spot'] == stop) {
        return _boxOfTag(w, 'auto:${en.key}');
      }
    }
    return null;
  }

  /// The door [id] (`puerta_sube`, `puerta_baja`) of the guagua at parada1: the sheet's box (`things.<id>.world`: its
  /// door, arrow and button) moved with the guagua ("add P - -1.9 to x"); null when no guagua stands there.
  List<num>? doorBox(Map<String, dynamic> w, String id) {
    for (final v
        in ((w['autos'] as Map<String, dynamic>?) ?? const {}).values) {
      final m = v as Map<String, dynamic>;
      if (m['vis'] == 0 || m['spot'] != 'parada1') continue;
      return _p.boxOf(_p.worldBox(id), (m['x'] as num) - _p.p1);
    }
    return null;
  }

  List<num>? _personBox(Map<String, dynamic> w, String id) =>
      _boxOfTag(w, 'persona:$id') ?? _boxOfTag(w, 'cabeza:$id');

  List<Thing> _things() {
    Thing sprite(
      String id,
      List<num>? Function(Map<String, dynamic>) f, {
      num m = 0,
      bool z = false,
    }) => Thing(
      id: id,
      m: m,
      z: z,
      si: (w) => f(w) != null,
      box: (Map<String, dynamic> w) => f(w),
    );
    Thing setThing(String id, List<int> b, List<double> w) =>
        Thing(id: id, m: 0, world: w, box: [b[0], b[1], b[2], b[3]]);

    return [
      // the ball (a small thing on the seat or in a hand: in front of whoever it lies by), the people (names: the free
      // poke), Canelo
      sprite(
        'bola',
        (w) =>
            _boxOfTag(w, 'cosa:bola') ??
            (w['bola'] == 'coqui' ? _boxOfTag(w, 'cosa:mano_coqui') : null),
        z: true,
      ),
      for (final id in _people) sprite(id, (w) => _personBox(w, id), m: 1),
      sprite('perro', (w) => _boxOfTag(w, 'perro'), m: 1),
      // the two doors of the guagua at parada1, with their arrows and buttons: they move with it
      sprite('puerta_sube', (w) => doorBox(w, 'puerta_sube')),
      sprite('puerta_baja', (w) => doorBox(w, 'puerta_baja')),
      // the guagua in front (parada1) and the one behind (parada2)
      sprite('guagua_a', (w) => _busBox(w, 'parada1')),
      sprite('guagua_b', (w) => _busBox(w, 'parada2')),
      // the set's things: the walking post, the stop (its sign; a touch on its seat is a touch on it too: [hit])
      setThing('poste', _p.box('poste'), _p.worldBox('poste')),
      setThing('parada', _p.stopBoxes['sign']!, _p.stopWorlds['sign']!),
      // OPEN: the sun (parada.md: "sol", twinkled in story 53 step 1) has no place: the sheet's sky has no sun in any
      // hora (E.SUN null) and names no thing `sol`. It is on the card only; it takes no touch, and its twinkle falls on
      // the frog (the runner's way with a thing that has no box)
      Thing(
        id: 'sol',
        m: 0,
        si: (_) => false,
        box: (Map<String, dynamic> _) => null,
      ),
    ];
  }

  // a touch on the stop's seat is a touch on the stop (things.parada: "TWO boxes, a touch on either is a touch on parada")
  @override
  String? hit(num x, num y, Map<String, dynamic> w) {
    final h = super.hit(x, y, w);
    if (h != null) return h;
    final b = _p.stopBoxes['seat'];
    if (b != null &&
        x >= b[0] &&
        x < b[0] + b[2] &&
        y >= b[1] &&
        y < b[1] + b[3]) {
      return 'parada';
    }
    return null;
  }

  /* ---------- talking ---------- */

  // the point over a speaker's head: its sprite's top; a head at the glass: its top; the chofer leaning out: his
  // sprite's top; who rides with no window: the top of his guagua over its front door
  @override
  List<num>? talkAt(String who, Map<String, dynamic> W) {
    if (who == 'chofer') {
      final v = _busAt('parada1');
      if (v == null) return null;
      final w0 = _p.world('chofer');
      final at = _p.atWorld(w0[0] + (v['x'] as num) - _p.p1, w0[1], w0[2]);
      final sp = ss.spot('chofer').raw['sprite'] as List?;
      final top = sp == null ? -9 : (sp[1] as num).toInt();
      return [_round(at.sx), _round(at.sy) + top - 1];
    }
    final b = _boxOfTag(W, 'persona:$who') ?? _boxOfTag(W, 'cabeza:$who');
    if (b != null) return [_round(b[0] + b[2] / 2), b[1] - 1];
    final viajan = (W['viajan'] as Map?)?.cast<String, dynamic>() ?? const {};
    final board = viajan[who] as String?;
    final v = _bus(board);
    if (v != null) {
      final vb = _boxOfTag(W, 'auto:$board');
      if (vb != null) return [_round(vb[0] + vb[2] * .2), vb[1] - 1];
    }
    return null;
  }

  @override
  Future<void> stake(int lost, int max, String en) async {
    host.SFX.bonk();
    await wait(300);
  }

  // the stories write no place on the picture: nothing to move
  @override
  List<num> remap(List<num> xy) => xy;

  @override
  String estado(Map<String, dynamic> W) {
    final g = (W['gente'] as Map<String, dynamic>?) ?? const {};
    final gente = [
      for (final e in g.entries)
        if ((e.value as Map)['vis'] != 0)
          '${e.key}@${(e.value as Map)['spot']}',
    ].join(' ');
    final a = (W['autos'] as Map<String, dynamic>?) ?? const {};
    final autos = [
      for (final e in a.entries)
        if ((e.value as Map)['vis'] != 0)
          '${e.key}@${(e.value as Map)['spot']}',
    ].join(' ');
    return 'hora=${W['hora']} gente=$gente autos=$autos boletos=${(W['boletos'] as Map?)?['n']} panes=${W['panes']} sol=${W['sol']}';
  }

  /* ---------- moving ---------- */

  // a walk: a straight line at a steady pace, about 5 px of the picture a tick
  Future<void> _anda(String id, String spot) async {
    final w = _p.world(spot);
    await _andaA(id, w[0], w[1], w[2]);
    _g(id)['spot'] = spot;
  }

  Future<void> _andaA(String id, num x, num y, num z, {int px = 5}) async {
    final p = _g(id);
    p['spot'] = null;
    if (p['vis'] == 0) {
      p
        ..['x'] = x
        ..['y'] = y
        ..['z'] = z
        ..['vis'] = 1;
      return;
    }
    final a = _atOf(p), b = _p.atWorld(x, y, z);
    final dist = math.sqrt(
      (b.sx - a.sx) * (b.sx - a.sx) + (b.sy - a.sy) * (b.sy - a.sy),
    );
    final x0 = p['x'] as num, y0 = p['y'] as num, z0 = p['z'] as num;
    if ((b.sx - a.sx).abs() > 3) p['dir'] = b.sx > a.sx ? 1 : -1;
    if (dist >= .5) {
      final n = math.max(1, (dist / px).ceil());
      for (var i = 1; i <= n; i++) {
        p['x'] = x0 + (x - x0) * i / n;
        p['y'] = y0 + (y - y0) * i / n;
        p['z'] = z0 + (z - z0) * i / n;
        p['dy'] = i % 2 == 1 && i < n ? -1 : 0;
        await _tick();
      }
    }
    p
      ..['x'] = x
      ..['y'] = y
      ..['z'] = z
      ..['dy'] = 0;
  }

  // a person who is not seen appears at a spot
  Map<String, dynamic> _aparece(String id, String spot) {
    final p = _g(id);
    final w = _p.world(spot);
    p
      ..['x'] = w[0]
      ..['y'] = w[1]
      ..['z'] = w[2]
      ..['vis'] = 1
      ..['spot'] = spot
      ..['sit'] = false
      ..['dy'] = 0;
    (W['viajan'] as Map).remove(id);
    return p;
  }

  // a person who sits stands up first (the seat's spots are at z .46: down to the pavement in front of it)
  Future<void> _levanta(String id) async {
    final p = _g(id);
    if (!jsTruthy(p['sit'])) return;
    p['sit'] = false;
    p['z'] = 0.0;
    await _tick();
  }

  // the frog hops to a spot (the kit's hopTo: a hop about every 30 px)
  Future<void> _salta(String spot) async {
    final q = _cq;
    final L = _frogAt(_p.at(spot));
    if (!jsTruthy(q['vis'])) {
      q
        ..['x'] = L[0]
        ..['y'] = L[1]
        ..['vis'] = 1;
      return;
    }
    final dx = (q['x'] as num) - L[0], dy = (q['y'] as num) - L[1];
    final dd = math.sqrt(dx * dx + dy * dy);
    if (dd >= 3) {
      await host.hopTo(
        L[0],
        L[1],
        math.max(1, math.min(4, _round(dd / 30))),
        1,
      );
    }
    q
      ..['x'] = L[0]
      ..['y'] = L[1];
  }

  // a thing on its way between two screen points, over everything (a ticket, a roll, the ball)
  Future<void> _vuela(
    String k,
    List<num> from,
    List<num> to, {
    int n = 6,
  }) async {
    for (var i = 1; i <= n; i++) {
      final t = i / n;
      W['vuela'] = {
        'k': k,
        'x': from[0] + (to[0] - from[0]) * t,
        'y': from[1] + (to[1] - from[1]) * t - math.sin(t * math.pi) * 10,
      };
      await _tick();
    }
    W['vuela'] = null;
  }

  // the screen point of a person's hand (the middle of the box, a little low), or of the frog's
  List<num>? _handOf(String id) {
    if (id == 'coqui') {
      final h = _frogHand();
      return h == null ? null : [h.x, h.y - 4];
    }
    final b = _boxOfTag(W, 'persona:$id');
    if (b == null) return null;
    return [b[0] + b[2] / 2, b[1] + b[3] * .55];
  }

  /* ---------- the guaguas ---------- */

  // OPEN: the sheet names no route for the guaguas (only where they stand: parada1, parada2, in the stop's lane y 4.6).
  // A guagua comes along the stop's lane from just past the picture's right edge and drives on to just past its left
  // edge (computed from its sprite: wholly outside the 240 columns), heading `i` as the sheet says; one that leaves from
  // parada2 while parada1 is taken pulls out to the far lane (constants.E.LANE1) and passes behind it.
  double _entryX(String board) {
    final s = vehicleSprite('guagua', 'i', board: board);
    return _p.lane + (240 + s.ax + 2 - _p.e.OX) * _p.e.R2 / _p.e.S;
  }

  double _exitX(String board, double y) {
    final s = vehicleSprite('guagua', 'i', board: board);
    return y + (s.ax - s.s.w - 2 - _p.e.OX) * _p.e.R2 / _p.e.S;
  }

  void _hiss() => host.tone(900, 0, .3, 'sawtooth', .015, 300);

  void _brake() => host.tone(220, 0, .25, 'sawtooth', .02, 160);

  // `guagua llega`: a guagua with picture [board] comes and stops at [stop] (parada1 or parada2). Who stands there goes
  // first (and, for parada1, the one at parada2 too: the newcomer would drive through it)
  Future<void> _llega(String board, String stop) async {
    final had = _bus(board);
    if (had != null && had['spot'] == stop) return;
    if (had != null) await _sale(board);
    final there = _busAt(stop);
    if (there != null) await _sale(there['board'] as String);
    if (stop == 'parada1') {
      final behind = _busAt('parada2');
      if (behind != null) await _sale(behind['board'] as String);
    }
    final to = _p.world(stop);
    final v = _nuevo(board, stop);
    _autos[board] = v;
    await drive(v, to[0], _tick);
    v['para'] = 1;
    _brake();
    await wait(TICK * 2);
  }

  Map<String, dynamic> _nuevo(String board, String stop) {
    final viajan = (W['viajan'] as Map).cast<String, dynamic>();
    final riders = <String, dynamic>{};
    final inside = <dynamic>[];
    for (final e in viajan.entries) {
      if (e.value != board) continue;
      inside.add(e.key);
      if (stop == 'parada1') {
        final win = _windowOf(e.key);
        if (win != null && !riders.containsKey(win)) riders[win] = e.key;
      }
    }
    return <String, dynamic>{
      'board': board,
      'x': _entryX(board),
      'y': _p.lane,
      'vis': 1,
      'spot': stop,
      'ventanas': stop == 'parada1' ? 1 : 0,
      'riders': riders,
      'inside': inside,
      'delante': 0,
      'atras': 0,
      'para': 0,
      'flip': <String, dynamic>{},
      'wave': <String, dynamic>{},
    };
  }

  // the window a rider is seen at (ventana1 abuela: "abuela's head at the glass"; ventana2 "Luis and the frog")
  static String? _windowOf(String id) => switch (id) {
    'abuela' => 'ventana1',
    'luis' || 'coqui' => 'ventana2',
    _ => null,
  };

  // `guagua sale`: it drives away to the left and out, with whoever rides it
  Future<void> _sale(String board) async {
    final v = _bus(board);
    if (v == null) return;
    v['delante'] = 0;
    v['atras'] = 0;
    v['para'] = 0;
    final pull = v['spot'] == 'parada2' && _busAt('parada1') != null;
    v['spot'] = null;
    final x0 = (v['x'] as num).toDouble();
    final lane = (v['y'] as num).toDouble();
    final to = _exitX(board, pull ? _p.farLane : lane);
    _hiss();
    if (pull) {
      // out of the stop's lane to the far one over the first 1.6 of the way, then on
      var x = x0;
      const step = .34;
      while (x > to) {
        x = math.max(to, x - step * (x0 - x < .6 ? .5 : 1));
        final t = math.min(1.0, (x0 - x) / 1.6);
        v['x'] = x;
        v['y'] = lane - (lane - _p.farLane) * t;
        await _tick();
      }
    } else {
      await drive(v, to, _tick, stop: false);
    }
    v['vis'] = 0;
    _autos.remove(board);
    (W['fuera'] as List).add(board);
    // who rode it has gone where it goes; only abuela and the frog come back (51's `vuelve51`, 53's `monta53`)
    (W['viajan'] as Map).removeWhere(
      (id, b) => b == board && id != 'abuela' && id != 'coqui',
    );
  }

  // `guagua pasa`: it drives by in the far lane without stopping
  Future<void> _pasa(String board) async {
    final v = _nuevo(board, 'pasa')
      ..['spot'] = null
      ..['ventanas'] = 0
      ..['y'] = _p.farLane;
    v['x'] = _p.farLane + (_entryX(board) - _p.lane);
    _autos['pasa:$board'] = v;
    await drive(v, _exitX(board, _p.farLane), _tick, stop: false);
    _autos.remove('pasa:$board');
  }

  // the board of a `k` (arbol, toldo, casa); a `$`-less value is the board itself
  static String _board(Object? k) => '$k';

  // a door of guagua [v] opens or shuts (`delante` the front door, `atras` the back door)
  Future<void> _door(Map<String, dynamic> v, String which, bool open) async {
    if (jsTruthy(v[which]) == open) return;
    _hiss();
    v[which] = open ? 1 : 0;
    await wait(TICK * 2);
  }

  // the guagua [quien] would get on: the one he is on, else the nearest along x
  Map<String, dynamic>? _busFor(String quien) {
    final viajan = (W['viajan'] as Map).cast<String, dynamic>();
    final on = _bus(viajan[quien] as String?);
    if (on != null) return on;
    num? x;
    if (quien == 'coqui') {
      x = _frogPoint(_cq).x;
    } else if (_seen(quien)) {
      x = _g(quien)['x'] as num;
    }
    Map<String, dynamic>? best;
    for (final v in _autos.values) {
      final m = v as Map<String, dynamic>;
      if (m['vis'] == 0 || m['spot'] == null) continue;
      if (best == null ||
          (x != null &&
              ((m['x'] as num) - x).abs() < ((best['x'] as num) - x).abs())) {
        best = m;
      }
    }
    return best;
  }

  // `sube` {quien, k}: [quien] gets on at the front door of the guagua with picture [board]
  Future<void> _sube(String quien, String board) async {
    var v = _bus(board);
    if (v == null) {
      // the stories always bring the guagua first; if one is not there, it comes to a free stop
      await _llega(board, _busAt('parada1') == null ? 'parada1' : 'parada2');
      v = _bus(board)!;
    }
    final stop = v['spot'] as String?;
    final viajan = (W['viajan'] as Map).cast<String, dynamic>();
    if (quien == 'coqui') {
      // aboard another one: he gets off it at its back door first ("he hops across")
      final other = _bus(viajan['coqui'] as String?);
      if (other != null && !identical(other, v)) {
        await _bajaCoqui(other, then: null);
      }
      await _salta(_of('coqui.boton_sube', stop));
      host.bounce(4);
      host.SFX.blip();
      await _door(v, 'delante', true);
      await host.hopTo(_cq['x'] as num, (_cq['y'] as num) - 6, 1, 1);
      _cq['vis'] = 0;
    } else {
      await _levanta(quien);
      if (!_seen(quien)) return;
      await _door(v, 'delante', true);
      await _anda(quien, _of('puerta_sube', stop));
      await _tick();
      _g(quien)['vis'] = 0;
    }
    viajan[quien] = board;
    (v['inside'] as List).add(quien);
    final win = _windowOf(quien);
    if (v['ventanas'] == 1 && win != null) {
      final riders = (v['riders'] as Map).cast<String, dynamic>();
      // OPEN: the sheet has two windows for heads (ventana1 abuela; ventana2 "Luis and the frog"), no ventana3: the frog
      // takes ventana2 in front of Luis (52's ending; 51's ending with one ticket, "on her lap at the window")
      if (!riders.containsKey(win) || quien == 'coqui') riders[win] = quien;
    }
    await _door(v, 'delante', false);
  }

  // the frog gets off guagua [v] at its back door (coqui.boton_baja of its stop), then hops to [then]
  Future<void> _bajaCoqui(Map<String, dynamic> v, {String? then}) async {
    final stop = v['spot'] as String?;
    await _door(v, 'atras', true);
    _quitaRider(v, 'coqui');
    final L = _frogAt(_p.at(_of('coqui.boton_baja', stop)));
    _cq
      ..['x'] = L[0]
      ..['y'] = L[1]
      ..['vis'] = 1;
    host.SFX.hop();
    await _tick();
    await _door(v, 'atras', false);
    if (then != null) await _salta(then);
  }

  void _quitaRider(Map<String, dynamic> v, String id) {
    final riders = (v['riders'] as Map).cast<String, dynamic>();
    riders.removeWhere((_, r) => r == id);
    (v['inside'] as List).remove(id);
    (W['viajan'] as Map).remove(id);
  }

  // a free place of the row for one who gets off (fila1 and fila2 stay free: the frog works the buttons from there,
  // the sheet's check row-free; fila3 too: who stands there covers the frog at the back door's button); null: none
  String? _filaLibre() {
    for (final f in const ['fila5', 'fila4']) {
      final taken = _gente.values.any(
        (p) => (p as Map)['vis'] != 0 && p['spot'] == f,
      );
      if (!taken) return f;
    }
    return null;
  }

  // `baja` {quien, k}: [quien] gets off at the back door of the guagua with picture [board] and walks to [to] (a free
  // place of the row, or, with none, out by the footpath)
  Future<void> _baja(String quien, String board, {String? to}) async {
    final v = _bus(board);
    if (v == null) return;
    final stop = v['spot'] as String?;
    if (quien == 'coqui') {
      await _bajaCoqui(v, then: to ?? 'fila2');
      return;
    }
    await _door(v, 'atras', true);
    _quitaRider(v, quien);
    _aparece(quien, _of('puerta_baja', stop))['pose'] = 'idle';
    host.SFX.hop();
    await _tick();
    final dest = to ?? _filaLibre();
    if (dest == null) {
      await _anda(quien, 'camino');
      _g(quien)['vis'] = 0;
    } else {
      await _anda(quien, dest);
    }
    _g(quien)['dir'] = 1;
    await _door(v, 'atras', false);
  }

  /* ---------- the acts (parada.md, "Needs") ---------- */

  // the acts started with `suelto: 1` (they run while their line is said), waited for by `ya`
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

  // the frog's place to come back to: fila2 (`bordillo`), or, in story 53 once the señor sits at banco1 (in front of
  // fila2), the walking post (coqui.poste: moment 5)
  String _home() {
    final se = _gente['senor'] as Map<String, dynamic>?;
    return _n(W['historia']) == 53 &&
            se != null &&
            se['vis'] != 0 &&
            jsTruthy(se['sit'])
        ? 'coqui.poste'
        : 'fila2';
  }

  // the frog takes the next box from abuela (53's game: "holds the first box out to the frog"; the second for round B)
  Future<void> _cajaParaCoqui() async {
    if (_n(W['historia']) != 53 || !jsTruthy(W['tarjeta'])) return;
    if (_n(W['cajaCoqui']) == 1 || _n(W['cajas']) <= 0) return;
    final ab = _gente['abuela'] as Map<String, dynamic>?;
    if (ab != null && ab['vis'] != 0) {
      ab['pose'] = 'mano';
      await wait(TICK * 3);
      ab['pose'] = 'idle';
    }
    W['cajas'] = _n(W['cajas']) - 1;
    W['cajaCoqui'] = 1;
    host.SFX.blip();
    await _tick();
  }

  // the sun's step: n 0 early (temprano), 1 going down (tarde), 2 evening (noche: the lamp lit): parada.md 53, "3 steps
  // of the sun: morning, late afternoon, evening"
  void _sol(int n) {
    W['sol'] = n;
    W['hora'] = const ['temprano', 'tarde', 'noche'][n.clamp(0, 2)];
  }

  // the direction a person turns to look at or point at [a] (a thing's box, a person, the frog)
  num? _xOf(String a) {
    if (a == 'coqui') {
      final q = _cq;
      return jsTruthy(q['vis']) ? host.frogBox(q).x + 16 : null;
    }
    final t = cosa(a);
    if (t != null) {
      final b = box(a, W);
      if (b != null) return b[0] + b[2] / 2;
    }
    return null;
  }

  Map<String, Act> _acts() => {
    // `ya`: waits for the acts that were started with `suelto: 1`
    'ya': (o) async {
      final all = List<Future<void>>.of(_sueltos);
      _sueltos.clear();
      await Future.wait(all);
    },
    // `ir` {a}: the frog hops to one of his places (the kit's hops of about 30 px, 1 to 4)
    'ir': (o) async {
      final a = o['a'], key = jsTruthy(a) ? a : o['en'];
      if (key is! String) return;
      final spot = frogSpotOf(key);
      if (spot == null) return;
      await _salta(spot);
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
    // `guagua` {k, que, a}: a guagua with picture k comes and stops at parada1 or parada2 (`llega`), drives away
    // (`sale`), or drives by (`pasa`) (51 to 53)
    'guagua': (o) async {
      final board = _board(o['k']);
      switch (o['que']) {
        case 'llega':
          await _llega(board, o['a'] == 'parada2' ? 'parada2' : 'parada1');
        // story 52's ending: Canelo runs after the guagua as it leaves (handled at `sale`)
        case 'sale':
          final chase =
              _n(W['historia']) == 52 &&
              _seen('perro') &&
              !jsTruthy(_cq['vis']);
          if (chase) {
            final p = _g('perro')..['pose'] = 'run';
            await Future.wait([
              _sale(board),
              () async {
                await wait(TICK * 2);
                await _anda('perro', 'fila1');
                await _anda('perro', 'camino');
                p['vis'] = 0;
              }(),
            ]);
          } else {
            await _sale(board);
          }
        case 'pasa':
          await _pasa(board);
        default:
          await wait(TICK);
      }
    },
    // `boleto` {quien}: the chofer tears a ticket off somebody's strip (51)
    'boleto': (o) async {
      final quien = (o['quien'] as String?) ?? 'coqui';
      final v = _busFor(quien);
      final b = W['boletos'] as Map<String, dynamic>?;
      // the ticket goes from the strip's hand (the frog's own strip; a child's ticket from his hand: the script's "Luis's
      // strip" is not drawn, abuela's strip of four stays whole until step 5) to the chofer at parada1, or to the front
      // door of the guagua at parada2
      final from = quien == 'coqui'
          ? (_handOf('coqui') ??
                (v == null ? null : _boxOfTag(W, 'auto:${v['board']}')))
          : _handOf(quien);
      if (quien == 'coqui' && b != null && b['quien'] == 'coqui') {
        b['n'] = math.max(0, _n(b['n']) - 1);
      }
      List<num>? to;
      if (v != null && v['spot'] == 'parada1') {
        W['chofer'] = 'idle';
        to = talkAt('chofer', W);
        if (to != null) to = [to[0], to[1] + 12];
      } else if (v != null) {
        // OPEN: the guagua at parada2 has no chofer's spot: its chofer is not drawn; the ticket goes to its front door
        final w0 = _p.world(_of('boton_sube', v['spot'] as String?));
        final at = _p.atWorld(w0[0] + (v['x'] as num) - _p.p2, w0[1], w0[2]);
        to = [at.sx, at.sy];
      }
      host.SFX.toc();
      if (from != null && to != null) {
        await _vuela('boleto', [from[0], from[1]], to);
      } else {
        await wait(TICK * 3);
      }
      host.SFX.blip();
      await wait(TICK * 2);
      W['chofer'] = null;
    },
    // `boletos` {n, quien}: the strip, in abuela's hand or the frog's (51)
    'boletos': (o) async {
      final quien = (o['quien'] as String?) ?? 'abuela';
      final n = _n(o['n']);
      final b = W['boletos'] as Map<String, dynamic>?;
      if (b != null && b['quien'] == 'abuela' && quien == 'coqui') {
        // abuela puts the strip in the frog's hand (51 step 5)
        final ab = _g('abuela');
        ab['pose'] = 'mano';
        await wait(TICK * 3);
        ab['lleva'] = null;
        W['boletos'] = {'n': n, 'quien': 'coqui'};
        host.SFX.blip();
        host.bounce(4);
        await wait(TICK * 2);
        ab['pose'] = 'idle';
        return;
      }
      W['boletos'] = {'n': n, 'quien': quien};
      if (quien != 'coqui' && _seen(quien)) _g(quien)['lleva'] = 'boletos';
      await wait(TICK);
    },
    // `sube` {quien, k}: somebody gets on at the front door of a guagua (51, 52)
    'sube': (o) => _sube(o['quien'] as String, _board(o['k'])),
    // `baja` {quien, k}: somebody gets off at the back door of a guagua (51, 52)
    'baja': (o) => _baja(o['quien'] as String, _board(o['k'])),
    // `vuelve51`: the two guaguas come back; abuela and the frog get off (51: 6, 7)
    'vuelve51': (o) async {
      final viajan = (W['viajan'] as Map).cast<String, dynamic>();
      final fuera = (W['fuera'] as List).cast<String>();
      // the two that left last, back to where they stood: the first of them to parada1, the second behind it
      final boards = <String>[];
      for (final b in fuera.reversed) {
        if (!boards.contains(b)) boards.insert(0, b);
        if (boards.length == 2) break;
      }
      final a = viajan['abuela'] as String?, c = viajan['coqui'] as String?;
      for (final b in [a, c]) {
        if (b != null && !boards.contains(b)) boards.add(b);
      }
      final arrivals = <Future<void>>[];
      for (var i = 0; i < boards.length && i < 2; i++) {
        final stop = i == 0 ? 'parada1' : 'parada2';
        if (_bus(boards[i]) != null) continue;
        final v = _nuevo(boards[i], stop);
        _autos[boards[i]] = v;
        final to = _p.world(stop)[0];
        arrivals.add(() async {
          if (i == 1) {
            // the second waits off the picture until the first has gone far enough ahead not to be caught up
            while (_bus(boards[0]) != null &&
                ((_bus(boards[0])!['x'] as num) > _entryX(boards[0]) - 5.2)) {
              await _tick();
            }
          }
          await drive(v, to, _tick);
          v['para'] = 1;
        }());
      }
      await Future.wait(arrivals);
      _brake();
      await wait(TICK * 2);
      final ga = _bus(a), gc = _bus(c);
      await Future.wait([
        if (ga != null) _baja('abuela', a!, to: 'fila3'),
        if (gc != null) _baja('coqui', c!, to: 'fila2'),
      ]);
      _g('abuela')['dir'] = 1;
    },
    // `final51` {n}: the ending for two, one or no tickets left (51: 8)
    'final51': (o) async {
      final n = _n(o['n']);
      final v = _busAt('parada1');
      final board = v?['board'] as String? ?? 'casa';
      if (n == 0) {
        // no ticket left: the guagua drives off without them; abuela takes the frog's hand and they set off along the
        // pavement, the frog hopping
        // OPEN: the pavement has no way out of the picture in the sheet (camino is the footpath's): abuela walks to the
        // row's left end (fila1) and turns that way; the frog stays at fila2 beside her, hopping
        await _sale(board);
        await _levanta('abuela');
        await _anda('abuela', 'fila1');
        _g('abuela')['dir'] = -1;
        for (var i = 0; i < 3; i++) {
          host.bounce(5);
          await wait(TICK * 2);
        }
        return;
      }
      // the frog gives the chofer one ticket for each of them he has left (two: abuela's and his; one: his)
      await _salta('coqui.boton_sube');
      for (var i = 0; i < n; i++) {
        await acts['boleto']!({'act': 'boleto', 'quien': 'coqui'});
      }
      await _sube('abuela', board);
      await _sube('coqui', board);
      // they sit at the front windows and wave
      final wv = (_bus(board)?['wave'] as Map?)?.cast<String, dynamic>();
      for (var i = 0; i < 6; i++) {
        wv?['abuela'] = i % 2 == 0 ? -1 : 0;
        wv?['coqui'] = i % 2 == 0 ? 0 : -1;
        await _tick();
      }
      wv?.clear();
      if (n == 2) host.SFX.right();
    },
    // `puerta` {cual, abre}: the frog presses a door's button; the door opens or shuts (52)
    'puerta': (o) async {
      final cual = '${o['cual']}';
      final v = _busAt('parada1');
      if (v == null) return;
      final back = cual == 'puerta_baja';
      await _salta(back ? 'coqui.boton_baja' : 'coqui.boton_sube');
      host.bounce(4);
      host.SFX.blip();
      await wait(TICK * 2);
      await _door(v, back ? 'atras' : 'delante', _n(o['abre'] ?? 1) == 1);
    },
    // `llama52` {quien}: somebody knocks on the back door's glass from inside (52: 1, 3)
    'llama52': (o) async {
      final quien = o['quien'] as String;
      final v = _busAt('parada1');
      // OPEN: the sheet has no place for a head at the back door's glass (only ventana1 and ventana2): who knocks is not
      // drawn there; the knocks are heard and he is inside, to get off at `baja`
      if (v != null && !(v['inside'] as List).contains(quien)) {
        (v['inside'] as List).add(quien);
        (W['viajan'] as Map)[quien] = v['board'];
      }
      for (var i = 0; i < 3; i++) {
        host.SFX.toc();
        await wait(TICK * 2);
      }
    },
    // `gente52` {que}: `viene` (people walk up to the kerb, others come to the back door's glass), `sube` (the people at
    // the kerb get on), `baja` (the people inside get off) (52: 5 to 7)
    'gente52': (o) async {
      final v = _busAt('parada1');
      switch (o['que']) {
        case 'viene':
          // whoever stands in the row and is not of the group goes off by the footpath
          // OPEN: the sheet names no place the people come from or go to but the footpath (camino); they come and go
          // that way. And the people "at the back door's glass" have no place: they are inside, not drawn
          final walks = <Future<void>>[];
          for (final e in _gente.entries.toList()) {
            final p = e.value as Map<String, dynamic>;
            final spot = p['spot'] as String?;
            if (p['vis'] == 0 || spot == null || !spot.startsWith('fila')) {
              continue;
            }
            if (_grupo52[e.key] == spot) continue;
            walks.add(() async {
              await _anda(e.key, 'camino');
              p['vis'] = 0;
            }());
          }
          await Future.wait(walks);
          var i = 0;
          final come = <Future<void>>[];
          for (final e in _grupo52.entries) {
            final p = _gente[e.key] as Map<String, dynamic>?;
            if (p != null && p['vis'] != 0 && p['spot'] == e.value) continue;
            final d = i++;
            come.add(() async {
              await wait(TICK * 3 * d);
              if (p == null || p['vis'] == 0) _aparece(e.key, 'camino');
              await _levanta(e.key);
              await _anda(e.key, e.value);
              _g(e.key)['dir'] = 1;
            }());
          }
          await Future.wait([...come, _salta('coqui.botones')]);
          if (v != null) {
            final inside = v['inside'] as List;
            for (final id in _pasajeros) {
              if (!inside.contains(id)) inside.add(id);
              (W['viajan'] as Map)[id] = v['board'];
            }
          }
        case 'sube':
          if (v == null) return;
          await _door(v, 'delante', true);
          for (final e in _grupo52.entries) {
            final p = _gente[e.key] as Map<String, dynamic>?;
            if (p == null || p['vis'] == 0 || p['spot'] != e.value) continue;
            await _anda(e.key, 'puerta_sube');
            await _tick();
            p['vis'] = 0;
            // they ride on (to the park): not among who gets off
          }
          host.SFX.right();
          await _door(v, 'delante', false);
        case 'baja':
          if (v == null) return;
          await _door(v, 'atras', true);
          for (final id in _pasajeros) {
            final inside = v['inside'] as List;
            if (!inside.contains(id)) continue;
            _quitaRider(v, id);
            _aparece(id, 'puerta_baja');
            await _tick();
            unawaited(() async {
              await _anda(id, 'camino');
              _g(id)['vis'] = 0;
            }());
            await wait(TICK * 3);
          }
          // the last one off the pavement before the door shuts
          while (_pasajeros.any(_seen)) {
            await _tick();
          }
          await _door(v, 'atras', false);
        default:
          await wait(TICK);
      }
    },
    // `perro52`: Canelo runs in at the open door, along the aisle and out with a roll, and eats it under the bench (52: 6,
    // 7)
    'perro52': (o) async {
      final v = _busAt('parada1');
      if (!_seen('perro') || v == null) return;
      final door = jsTruthy(v['atras']) ? 'puerta_baja' : 'puerta_sube';
      final p = _g('perro')..['pose'] = 'run';
      host.tone(500, 0, .12, 'square', .04, 700);
      await _anda('perro', door);
      // OPEN: the aisle inside has no places: Canelo is gone in at the door and comes out at it with a roll
      p['vis'] = 0;
      await wait(TICK * 4);
      W['panes'] = math.max(0, (W['panes'] == null ? 3 : _n(W['panes'])) - 1);
      host.SFX.munch();
      await wait(TICK * 3);
      p
        ..['vis'] = 1
        ..['pan'] = 1;
      await _anda('perro', 'bajo_banco');
      p
        ..['pan'] = 0
        ..['pose'] = 'eat'
        ..['dir'] = 1;
      for (var i = 0; i < 3; i++) {
        host.SFX.munch();
        await wait(TICK * 2);
      }
      p['pose'] = 'lie';
      await _door(v, 'atras', false);
      await _door(v, 'delante', false);
    },
    // `panes` {n}: the rolls on the sill (52)
    'panes': (o) async {
      W['panes'] = _n(o['n']);
      final ab = _gente['abuela'] as Map<String, dynamic>?;
      if (ab != null) ab['lleva'] = null;
      host.SFX.blip();
      await wait(TICK * 2);
    },
    // `final52` {n}: three, two or one roll left (52: 8): abuela lifts the cloth; one each for abuela, Luis and the frog;
    // Luis and the frog; one broken in two for them
    'final52': (o) async {
      final n = _n(o['n']);
      W['tapado'] = 1;
      await wait(TICK * 3);
      W['tapado'] = 0;
      host.SFX.blip();
      await wait(TICK * 2);
      final v = _busAt('parada1');
      final wv = (v?['wave'] as Map?)?.cast<String, dynamic>();
      for (var i = 0; i < n; i++) {
        W['panes'] = n - i - 1;
        host.SFX.munch();
        wv?['abuela'] = -1;
        await wait(TICK * 3);
        wv?.clear();
      }
      W['panes'] = 0;
      if (n == 3) host.SFX.right();
      await wait(TICK * 2);
    },
    // `camina53` {ok}: the frog walks off along the path and comes back: soon and without the box, or late and with it
    // (53: 2, 6, 7)
    'camina53': (o) async {
      final ok = _n(o['ok'] ?? 1) == 1;
      await _cajaParaCoqui();
      await _salta('coqui.poste');
      await _salta('camino');
      _cq['vis'] = 0;
      await wait(TICK * (ok ? 6 : 14));
      if (ok) W['cajaCoqui'] = 0;
      _cq['vis'] = 1;
      await _salta('coqui.poste');
      await _salta(_home());
      if (ok) host.SFX.blip();
    },
    // `monta53` {ok}: the frog rides off waving from a window and comes back (53: 3, 6, 7)
    'monta53': (o) async {
      final ok = _n(o['ok'] ?? 1) == 1;
      await _cajaParaCoqui();
      // OPEN: "the frog hops to the sign": the sheet has no spot for the frog at the stop's sign: he waits where he gets
      // on, at the front door's button of the guagua at parada1 (coqui.boton_sube)
      await _salta('coqui.boton_sube');
      final board = (_busAt('parada1')?['board'] as String?) ?? 'arbol';
      if (_busAt('parada1') == null) await _llega(board, 'parada1');
      await _sube('coqui', board);
      final wv = (_bus(board)?['wave'] as Map?)?.cast<String, dynamic>();
      for (var i = 0; i < 4; i++) {
        wv?['coqui'] = i % 2 == 0 ? -1 : 0;
        await _tick();
      }
      wv?.clear();
      await _sale(board);
      await wait(TICK * (ok ? 4 : 10));
      if (ok) W['cajaCoqui'] = 0;
      // another brings him back
      await _llega(board, 'parada1');
      await _baja('coqui', board, to: _home());
      await _sale(board);
      if (ok) host.SFX.blip();
    },
    // `espera53`: he waits at the kerb, no guagua comes, his shadow grows (53: 6, 7)
    'espera53': (o) async {
      await _cajaParaCoqui();
      // at the kerb, where a guagua would take him (coqui.boton_sube: "on the pavement, at the button's x", the kerb)
      await _salta('coqui.boton_sube');
      W['signo'] = 'gota';
      for (var i = 0; i <= 10; i++) {
        W['sombra'] = 1 + i * .08;
        if (i % 3 == 0) host.bounce(1);
        await _tick();
      }
      await wait(TICK * 4);
      W['sombra'] = 1.0;
      W['signo'] = null;
      await _salta(_home());
    },
    // `sol` {n}: the sun's step (53)
    'sol': (o) async {
      _sol(_n(o['n']));
      host.SFX.suave();
      await wait(TICK * 3);
    },
    // `final53` {n}: the ending for no step, one or two lost (53: 8)
    'final53': (o) async {
      final n = _n(o['n']);
      _sol(n);
      // Luis and Carmen run up; abuela gets up from the seat (parada-preview.html moment 6: abuela at fila2, the frog at
      // fila3, Luis with the ball at fila4, Carmen at fila5)
      // the señor who sat down at banco1 in step 4 goes his way by the footpath (the sheet's moment 6 has nobody on the
      // seat; the script does not say)
      await _salta('fila3');
      await Future.wait([
        if (_seen('senor'))
          () async {
            await _levanta('senor');
            await _anda('senor', 'camino');
            _g('senor')['vis'] = 0;
          }(),
        () async {
          await _levanta('abuela');
          await _anda('abuela', 'fila2');
        }(),
        () async {
          _aparece('luis', 'camino');
          await _anda('luis', 'fila4');
        }(),
        () async {
          await wait(TICK * 3);
          _aparece('carmen', 'camino');
          await _anda('carmen', 'fila5');
        }(),
      ]);
      // Luis takes the ball from the seat
      W['bola'] = null;
      _g('luis')['lleva'] = 'pelota';
      host.SFX.blip();
      await wait(TICK * 2);
      final ab = _g('abuela');
      if (n == 0) {
        // they play with the ball on the pavement; abuela claps
        for (final (a, b) in const [
          ('luis', 'coqui'),
          ('coqui', 'carmen'),
          ('carmen', 'luis'),
        ]) {
          if (a == 'luis') _g('luis')['lleva'] = null;
          if (a == 'coqui') W['bola'] = null;
          if (a == 'carmen') _g('carmen')['lleva'] = null;
          final f = _handOf(a), t = _handOf(b);
          if (f != null && t != null) await _vuela('pelota', f, t);
          if (b == 'coqui') W['bola'] = 'coqui';
          if (b == 'carmen' || b == 'luis') _g(b)['lleva'] = 'pelota';
          ab['pose'] = 'saluda0';
          host.SFX.hop();
          await _tick();
          ab['pose'] = 'idle';
        }
        host.SFX.right();
      } else if (n == 1) {
        // one throw to the frog, who catches it
        _g('luis')['lleva'] = null;
        final f = _handOf('luis'), t = _handOf('coqui');
        if (f != null && t != null) await _vuela('pelota', f, t);
        W['bola'] = 'coqui';
        host.bounce(5);
        await wait(TICK * 2);
      } else {
        // Luis carries the ball under his arm
        await wait(TICK * 3);
      }
    },
    // `gesto` {quien, que, a}: saluda, no, senala and mira (with a), sienta (sits down on the bench), pulgar (the chofer's
    // thumb up), silba, bosteza (the frog yawns), lengua (the frog, tongue out, tired), salta (the frog bounces)
    'gesto': (o) async {
      final quien = o['quien'] as String, que = o['que'] as String?;
      final a = o['a'] as String?;
      if (quien == 'coqui') {
        switch (que) {
          case 'bosteza':
          case 'lengua':
            W['signo'] = que;
            host.bounce(que == 'bosteza' ? 2 : 3);
            await wait(TICK * 8);
            W['signo'] = null;
          case 'mira':
            host.bounce(3);
            await wait(TICK * 3);
          default:
            host.bounce(6);
            await wait(TICK * 3);
        }
        return;
      }
      if (quien == 'chofer') {
        if (_busAt('parada1') == null) {
          await wait(TICK * 3);
          return;
        }
        W['chofer'] = que == 'pulgar' || que == 'silba' ? que : 'idle';
        if (que == 'silba') {
          host.tone(2200, 0, .25, 'sine', .06, 2700);
          host.tone(2700, .3, .3, 'sine', .06, 2200);
        } else {
          host.SFX.blip();
        }
        await wait(TICK * 6);
        W['chofer'] = null;
        return;
      }
      if (que == 'sienta') {
        // banco1 the señor (53), banco2 abuela (53): the sheet's words. The señora (51): banco2, where
        // parada-preview.html's moment 1 seats her (the sheet's banco1 says "the señora (51)", but there she sits in
        // front of the frog at fila2 and he would be drawn over her)
        final spot = quien == 'abuela' || quien == 'senora'
            ? 'banco2'
            : 'banco1';
        final p = _g(quien);
        if (p['vis'] == 0) _aparece(quien, 'camino');
        final w = _p.world(spot);
        await _andaA(quien, w[0], w[1] + .5, 0);
        p
          ..['x'] = w[0]
          ..['y'] = w[1]
          ..['z'] = w[2]
          ..['spot'] = spot
          ..['sit'] = true
          ..['dir'] = 1
          ..['pose'] = 'idle';
        host.SFX.suave();
        // story 53: the señor on the seat sits in front of fila2: the frog goes to the walking post (coqui.poste), where
        // parada-preview.html's moment 5 has him beside the señor and abuela on the seat
        if (quien == 'senor' && _n(W['historia']) == 53) await _salta(_home());
        await wait(TICK * 2);
        return;
      }
      // who rides at a window: the head shakes or turns there
      final viajan = (W['viajan'] as Map).cast<String, dynamic>();
      final on = _bus(viajan[quien] as String?);
      if (!_seen(quien)) {
        // OPEN: abuela inside the guagua (51 wrong: "shakes her head and points at the other guagua"): no picture
        // inside; at ventana1 her head shakes, else nothing shows
        if (on != null && que == 'no') {
          final flip = (on['flip'] as Map).cast<String, dynamic>();
          for (var i = 0; i < 4; i++) {
            flip[quien] = i % 2 == 0 ? 1 : 0;
            await _tick();
          }
          flip.remove(quien);
        } else {
          await wait(TICK * 3);
        }
        return;
      }
      final p = _g(quien);
      switch (que) {
        case 'saluda':
          for (var i = 0; i < 6; i++) {
            p['pose'] = i % 2 == 0 ? 'saluda0' : 'saluda1';
            await _tick();
          }
          p['pose'] = 'idle';
        case 'no':
          final d = _n(p['dir']) < 0 ? -1 : 1;
          for (var i = 0; i < 4; i++) {
            p['dir'] = i % 2 == 0 ? -d : d;
            await _tick();
          }
          p['dir'] = d;
        case 'senala':
        case 'mira':
          final tx = a == null ? null : _xOf(a);
          final at = _atOf(p);
          if (tx != null && (tx - at.sx).abs() > 2) {
            p['dir'] = tx > at.sx ? 1 : -1;
          }
          if (que == 'senala' && !jsTruthy(p['sit'])) p['pose'] = 'mano';
          await wait(TICK * 5);
          p['pose'] = 'idle';
        default:
          await wait(TICK * 3);
      }
    },
  };
}
