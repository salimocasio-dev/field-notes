// Los estantes (place 4, El colmado, scene 2; stories 39 to 41): a NEW scene, written from its script's "Needs" list
// (historia/notas/guiones/estantes.md) on its set (estantes_set.dart) and its sheet (estantes-sheet.json, read by
// SceneSheet), as El mostrador is (lib/src/mostrador/). There is no old scene file: every act is this file's, each doing
// on screen what the Needs list says, every place from the sheet (a spot's world point, a thing's box, the depth rule).
// Where the sheet names no place, or the script does not settle what an act shows, the act does the plainest thing that
// keeps the story playing and says so in a comment starting `OPEN:` (page 13 lists them for the content lane).
//
// The drawing (the sheet's `front`): every sprite stands with its feet's bottom edge on its spot's row and its middle on
// its column (rules.anchor); a sprite pixel is hidden by every set pixel nearer the camera than the upright plane
// through its feet plus `front.bias` (front.plane); between two sprites the nearer pixel wins; don Pepe on the ladder
// is not hidden by the ladder's own pixels (front.after: the set's part `escalera`); a box lying flat carries the depth
// of each of its pixels. The people and the things are kept in W by their world point.
// ignore_for_file: non_constant_identifier_names

import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/src/colmado/colmado_cast.dart';
import 'package:coqui_scenes/src/estantes/estantes_places.dart';
import 'package:coqui_scenes/src/estantes/estantes_set.dart';
import 'package:coqui_scenes/src/estantes/estantes_sprites.dart';
import 'package:coqui_scenes/src/mostrador/mostrador_sprites.dart'
    show mkCliente, mkMalta;
import 'package:coqui_scenes/src/scene_set.dart';
import 'package:coqui_scenes/src/sheet_cache.dart';

/// The scene "Los estantes", made from its sheet (read first: `loadScene`).
Scene createEstantes() => Estantes(sceneSheetOf('estantes'));

int _round(num v) => (v + 0.5).floor();

int _n(Object? v) =>
    v is num ? v.toInt() : (v is String ? int.tryParse(v) ?? 0 : 0);

/// One sprite of the sprite layer, placed: its picture, its top left on the 240 x 216 picture, the screen row of its
/// feet and the depth there (front.plane), the depth of each pixel for a thing lying flat ([z]), whether the ladder's
/// pixels hide it ([ladder] false: don Pepe on the ladder, front.after), and who or what it is.
class EstantesItem {
  EstantesItem(
    this.s,
    this.left,
    this.top,
    this.sy,
    this.d, {
    this.tag,
    this.z,
    this.ladder = true,
  });

  final Sprite s;
  final int left, top;
  final num sy;
  final double d;
  final Float32List? z;
  final bool ladder;

  /// Who or what it is (the rules' tests read it: `persona:<id>`, `coqui`, `cosa:<id>`).
  final String? tag;
}

class Estantes extends Escena implements SetScene, SetOverSprites {
  Estantes(this.ss) : sheet = ss.legacy() {
    _p = EstantesPlaces(ss);
    // the runner starts on `wide` (juego.js `cam = CAM.wide`): the sheet's one view
    CAM = {'wide': _p.view('wide')};
    LUGAR = {
      'cajon': _frogAt(_p.at('coqui.cajon')),
      'piso': _frogAt(_p.at('coqui.piso')),
    };
    cosas = _things();
  }

  /// The new scene's sheet (SceneSheet).
  final SceneSheet ss;

  /// The old Sheet the shared code reads (`SceneSheet.legacy`: the scene, scale, origin; the start frog the runner's).
  @override
  final Sheet sheet;

  late final EstantesPlaces _p;

  /// The scene's places, from its sheet.
  EstantesPlaces get places => _p;

  @override
  String get id => 'estantes';

  @override
  late final Map<String, List<num>> CAM;

  late final Map<String, List<num>> LUGAR;

  @override
  Map<String, List<num>> get lugar => LUGAR;

  @override
  late final List<Thing> cosas;

  @override
  PpEngine newEngine({bool still = false}) => estantesEngine(still: still);

  @override
  PpEngine get projection => _p.e;

  // the frog's top left for a spot (rules.anchor: mkCoqui's column 16 on sx, its row 25 on sy)
  List<num> _frogAt(EstantesAt a) => [_round(a.sx) - 16, _round(a.sy) - 25, 1];

  Map<String, dynamic> get W => host.W;
  int get F => host.F;
  int get TICK => host.TICK;
  Future<void> wait(num ms) => host.wait(ms);

  /* ---------- the state ---------- */

  // what the story does, read once from its file at the start (the scene's own state at the start follows it, as the
  // script's "Start" lines say): the acts it calls and with what
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
      'dir': 1,
      'pose': 'idle',
      'dy': 0,
    };
  }

  Map<String, dynamic> _cosa(
    String id,
    String k,
    String spot, {
    Object? v,
    num dx = 0,
    num dy = 0,
    int vis = 1,
  }) {
    final w = _p.world(spot);
    return <String, dynamic>{
      'id': id,
      'k': k,
      'x': w[0],
      'y': w[1],
      'z': w[2],
      'spot': spot,
      'vis': vis,
      'v': v,
      'dx': dx,
      'dy': dy,
      'con': null,
      'ci': 0,
      'caja': null,
      'vuela': null,
    };
  }

  @override
  Map<String, dynamic> fresh(Map<String, dynamic> story) {
    final acts = _actsOf([story['beats'], story['final']]);
    bool has(String a) => acts.any((o) => o['act'] == a);
    final gente = <String, dynamic>{};
    final cosas = <dynamic>[];
    var anillos = 0, mesa = 0, gafas = 0;
    var frog = 'coqui.piso';
    if (has('abre39')) {
      // story 39 (estantes.md "Start"): morning; don Pepe drags the big cardboard box in at the door; Luis and the frog
      // beside it; the señora and the señor at the left edge. The middle shelf bare, its six rings of dust.
      // OPEN: the box has no place while it is dragged in (the sheet names only where it ends, `caja_grande`), and the
      // place for don Pepe coming in with it (`pepe.entra`, 38,138) is behind the señora waiting at cola1 (38,145): he
      // would not be seen. The box stands at caja_grande from the start and don Pepe beside it, at pepe.pie.
      anillos = 1;
      gafas = 1;
      gente['pepe'] = _person('pepe.pie');
      gente['luis'] = _person('luis.piso');
      cosas.add(_cosa('caja', 'caja', 'caja_grande', v: 'cerrada'));
      for (var i = 0; i < 3; i++) {
        cosas.add(
          _cosa('lata.c$i', 'lata', 'caja_grande', vis: 0)..['caja'] = i,
        );
        cosas.add(
          _cosa('botella.c$i', 'botella', 'caja_grande', vis: 0)..['caja'] = i,
        );
      }
      // the frog's crate: a sprite .3 high under him (spots.coqui.cajon.ground)
      final g = _p.groundOf('coqui.cajon');
      cosas.add(
        _cosa('cajon', 'cajon', 'coqui.cajon')
          ..['x'] = g.x
          ..['y'] = g.y
          ..['z'] = g.z,
      );
      frog = 'coqui.cajon';
    } else if (has('fila')) {
      // story 40: don Pepe at the low table; Luis and the frog at the crate of cans; the drawing pinned over the table
      mesa = 1;
      gente['pepe'] = _person('pepe.mesa');
      gente['luis'] = _person('luis.cajas');
      gente['perro'] = _person('perro.entra', vis: 0);
      cosas.add(_cosa('cajon_latas', 'cajon_latas', 'cajon_latas'));
      cosas.add(_cosa('papel', 'papel', 'dibujo'));
    } else {
      // story 41: don Pepe at the foot of the ladder; Luis with abuela's note; the frog beside abuela's box; his last
      // maltas in a row on the top shelf (estantes-preview.html moment 4: one at each of the seven places)
      gente['pepe'] = _person('pepe.pie');
      gente['luis'] = _person('luis.cajas');
      final g = _p.group('estante.alto');
      for (var i = 0; i < g.length; i++) {
        cosas.add(_cosa('malta.$i', 'malta', g[i]));
      }
    }
    // the customers of story 39 wait at the left edge from the start (`cliente` with a can or a bottle)
    for (final o in acts) {
      if (o['act'] != 'cliente' || o['lleva'] == 'caja') continue;
      final q = o['quien'] as String;
      gente[q] ??= _person(q == 'senora' ? 'cola1' : 'cola2');
    }
    final q = _frogAt(_p.at(frog));
    return {
      'anillos': anillos,
      'mesa': mesa,
      'gafas': gafas,
      'gente': gente,
      'cosas': cosas,
      'tarjeta': null,
      'marcas': null,
      'dedo': null,
      'tiembla': 0,
      'cq': <String, dynamic>{
        'x': q[0],
        'y': q[1],
        's': 1,
        'dy': 0,
        'al': 1,
        'vis': 1,
        'bub': null,
        'z': _p.world(frog)[2],
      },
    };
  }

  /* ---------- the set ---------- */

  // the sheet's setKey: "anillos + mesa", e.g. "1-0"
  @override
  String setKey(Map<String, dynamic> W) =>
      '${_n(W['anillos']) == 1 ? 1 : 0}-${_n(W['mesa']) == 1 ? 1 : 0}';

  @override
  void buildSet(PpEngine e, PpBuild b, Map<String, dynamic> W) =>
      buildSetFor(e, b, setKey(W));

  final Map<PpEngine, EstantesSet> _sets = {};

  // the set's own pixels of its part `escalera` (the ladder), by key: recorded at each state's bake (set-kit.js
  // PART_TAGS), for front.after
  static final Map<String, Uint8List> _ladderOf = {};

  @override
  void buildSetFor(PpEngine e, PpBuild b, String key) {
    final set = _sets[e] ??= EstantesSet(e, b);
    set.tags = true;
    set.buildSet(EstantesState.fromKey(key));
    final t = set.partTags!;
    _ladderOf[key] = Uint8List.fromList([
      for (final x in t) x == 'escalera' ? 1 : 0,
    ]);
    set.k.PART_TAGS = null;
  }

  // the ladder's pixels in state [key] (a bake of its own when the state has not been baked by this scene yet)
  Uint8List _ladder(String key) => _ladderOf[key] ??= () {
    final e = estantesEngine(), set = EstantesSet(e, PpBuild(e))..tags = true;
    set.buildSet(EstantesState.fromKey(key));
    return Uint8List.fromList([
      for (final x in set.partTags!) x == 'escalera' ? 1 : 0,
    ]);
  }();

  // the frog casts his shadow in the engine (shadows.byCharacter.coqui) when he stands on the floor; never the old one
  @override
  bool get frogShadow => false;

  /* ---------- where everybody is ---------- */

  Map<String, dynamic> _g(String id) =>
      ((W['gente'] as Map<String, dynamic>)[id] ??= _person('entra', vis: 0))
          as Map<String, dynamic>;

  List<Map<String, dynamic>> get _items =>
      (W['cosas'] as List).cast<Map<String, dynamic>>();

  Map<String, dynamic>? _item(String id) {
    for (final o in _items) {
      if (o['id'] == id) return o;
    }
    return null;
  }

  // a person's or a thing's place
  EstantesAt _atOf(Map<String, dynamic> o) =>
      _p.atWorld(o['x'] as num, o['y'] as num, o['z'] as num);

  // the frog's world point under his feet (his z: 0 the floor, .3 his crate)
  EstantesAt _frogPoint(Map<String, dynamic> q) {
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

  static final Map<String, FlatSprite> _flats = {};
  FlatSprite _flat(String spot, int n) => _flats['$spot.$n'] ??= mkBotellero(
    _p.e,
    _p.world(spot),
    _p.footprint(spot),
    n,
  );

  // a person's sprite and the point of it that stands on the spot (rules.anchor)
  ({Sprite s, int ax, int ay, String key}) _personSprite(
    String id,
    Map<String, dynamic> p,
    bool open,
  ) {
    final pose = (p['pose'] as String?) ?? 'idle';
    if (id == 'pepe') {
      final g = _n(W['gafas']) == 1;
      final key = 'pepe$pose$open$g';
      final s = _spr(key, () => mkPepeGafas(pose, open: open, gafas: g));
      return (s: s, ax: PX, ay: inkBottom(s), key: key);
    }
    if (id == 'senora' || id == 'senor') {
      final mp = switch (pose) {
        'saluda0' => 'wave0',
        'saluda1' => 'wave1',
        'mano' => 'taza',
        _ => 'idle',
      };
      final key = 'cl$id$mp$open';
      final s = _spr(key, () => mkCliente(id, mp, open: open));
      return (s: s, ax: PX, ay: inkBottom(s), key: key);
    }
    if (id == 'perro') {
      final f = (F >> 1) % 2 == 1;
      final key = 'perro$pose$f';
      final s = _spr(
        key,
        () => pose == 'papel'
            ? mkPerroPapel(f)
            : mkPerro(pose == 'idle' ? 'sit' : pose, f),
      );
      // Canelo: his middle column 13 (the scenes draw it at -13), his lowest drawn row on sy - 1 (rules.anchor)
      return (s: s, ax: 13, ay: inkBottom(s), key: key);
    }
    // Luis (kit.js FAM.hermano)
    final kp = switch (pose) {
      'saluda0' || 'arriba' => 'wave0',
      'saluda1' => 'wave1',
      'mano' => 'taza',
      'cuenta' => 'tu',
      _ => 'idle',
    };
    final key = 'luis$kp$open';
    final s = _spr(key, () => mkPersona(FAM['hermano']!, kp, open, false));
    return (s: s, ax: PX, ay: inkBottom(s), key: key);
  }

  // the sprite of a thing
  Sprite _thingSprite(Map<String, dynamic> o) {
    final k = o['k'] as String, v = o['v'];
    switch (k) {
      case 'lata':
        final lab = _n(o['lab']);
        return _spr('lata$lab', () => mkLata(lab));
      case 'botella':
        return _spr('botella', mkBotella);
      case 'rota':
        return _spr('rota', mkBotellaRota);
      case 'malta':
        return _spr('malta$v', () => mkMalta(v == 'abierta'));
      case 'caja':
        return _spr('caja$v', () => mkCajaGrande(v == 'abierta'));
      case 'cajon':
        return _spr('cajon', mkCajon);
      case 'cajon_latas':
        final lleno = _cajonLleno();
        return _spr('cajon_latas$lleno', () => mkCajonLatas(lleno));
      case 'red':
        final n = _n(v);
        return _spr('red$n', () => mkRed(n));
      case 'bandera':
        return _spr('bandera', mkBandera);
      case 'papel':
        return _spr('papel', mkPapel);
      case 'nota':
        return _spr('nota', mkNota);
      case 'gafas':
        return _spr('gafas', mkGafas);
      case 'botellero':
        return _flat(o['spot'] as String, _n(v)).s;
    }
    throw StateError('no sprite for $k');
  }

  // the crate of cans looks full but while the nets stand on it (estantes-preview.html moment 3: `cajon_vacio` under
  // the nets) and once it is tipped to show what is left (`resto`)
  bool _cajonLleno() =>
      _n(W['cajonVacio']) != 1 &&
      !_items.any((o) => o['k'] == 'red' && o['vis'] != 0);

  // where a held thing is drawn: at the holder's hand (the person's held-out hand, kit.js mkPersona 'taza': X + rx + 4.5,
  // row 27; the frog's beside him), as the bottom middle of the thing on the picture, with the holder's depth
  ({num x, num y, double d, num sy})? _handOf(String holder) {
    if (holder == 'coqui') {
      final q = W['cq'] as Map<String, dynamic>;
      if (!jsTruthy(q['vis'])) return null;
      final b = host.frogBox(q), at = _frogPoint(q);
      return (
        x: b.x + b.w + 2,
        y: (q['y'] as num) + 24 + 4,
        d: at.d + .05,
        sy: at.sy,
      );
    }
    final p =
        (W['gente'] as Map<String, dynamic>)[holder] as Map<String, dynamic>?;
    if (p == null || p['vis'] == 0) return null;
    final at = _atOf(p), dir = _n(p['dir']) < 0 ? -1 : 1;
    final nino = holder == 'luis';
    return (
      x: at.sx + dir * (nino ? 11 : 13),
      y: at.sy - (nino ? 15 : 26) + 4,
      d: at.d + .05,
      sy: at.sy,
    );
  }

  /// Every sprite of the frame [w] as it is placed (the people, the things), but the frog. The rules' tests read it;
  /// [draw] draws it.
  List<EstantesItem> items(Map<String, dynamic> w, int a) {
    final out = <EstantesItem>[];
    final talk = _talker();
    final shake = _n(w['tiembla']) > _safeF()
        ? ((_safeF() >> 1) % 2 == 0 ? -1 : 1)
        : 0;
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
      final onLadder = en.key == 'pepe' && (p['z'] as num) > 0;
      final sx = _round(at.sx) + (onLadder ? shake : 0),
          sy = _round(at.sy) + _n(p['dy']);
      out.add(
        EstantesItem(
          s,
          sx - ax,
          sy - sp.ay,
          sy,
          at.d,
          tag: 'persona:${en.key}',
          ladder: !onLadder,
        ),
      );
    }
    final held = <String, int>{};
    for (final o
        in (w['cosas'] as List? ?? const []).cast<Map<String, dynamic>>()) {
      if (o['vis'] == 0) continue;
      if (o['k'] == 'gafas' && _n(w['gafas']) == 1) continue;
      final s = _thingSprite(o);
      final tag = 'cosa:${o['id']}';
      final con = o['con'] as String?;
      final vu = o['vuela'] as Map<String, dynamic>?;
      if (vu != null) {
        final x = _round(vu['x'] as num), y = _round(vu['y'] as num);
        out.add(
          EstantesItem(
            s,
            x - s.w ~/ 2,
            y - inkBottom(s),
            y,
            (vu['d'] as num).toDouble(),
            tag: tag,
          ),
        );
        continue;
      }
      if (con != null) {
        final h = _handOf(con);
        if (h == null) continue;
        final i = held[con] = (held[con] ?? -1) + 1;
        final x = _round(h.x) + i * 5, y = _round(h.y);
        out.add(
          EstantesItem(
            s,
            x - s.w ~/ 2,
            y - inkBottom(s),
            h.sy,
            h.d + i * .001,
            tag: tag,
          ),
        );
        continue;
      }
      final box = o['caja'];
      if (box != null) {
        // a can or a bottle in the big box: at its place in the box's sprite, behind the box's front
        final c = _item('caja');
        if (c == null || c['vis'] == 0) continue;
        final at = _atOf(c), cs = _thingSprite(c);
        final left = _round(at.sx) - cs.w ~/ 2,
            top = _round(at.sy) - inkBottom(cs);
        final slot = o['k'] == 'lata'
            ? cajaLata(_n(box))
            : cajaBotella(_n(box));
        out.add(
          EstantesItem(
            s,
            left + slot.x,
            top + slot.y,
            _round(at.sy),
            at.d - .01,
            tag: tag,
          ),
        );
        continue;
      }
      final at = _atOf(o);
      if (o['k'] == 'botellero') {
        final f = _flat(o['spot'] as String, _n(o['v']));
        final sx = _round(at.sx), sy = _round(at.sy);
        out.add(
          EstantesItem(f.s, sx - f.ax, sy - f.ay, sy, at.d, tag: tag, z: f.z),
        );
        continue;
      }
      final onTop = (o['spot'] as String?)?.startsWith('estante.alto') ?? false;
      final sx = _round(at.sx) + _n(o['dx']) + (onTop ? shake : 0),
          sy = _round(at.sy) + _n(o['dy']);
      // the drawing on the wall: its middle on the point (rules.anchor)
      final mid = o['k'] == 'papel';
      out.add(
        EstantesItem(
          s,
          sx - s.w ~/ 2,
          mid ? sy - s.h ~/ 2 : sy - inkBottom(s),
          sy,
          at.d,
          tag: tag,
        ),
      );
    }
    return out;
  }

  int _safeF() {
    try {
      return host.F;
    } catch (_) {
      return 0;
    }
  }

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
  Uint32List? _layer;
  Float32List? _layerZ;

  @override
  void setFramed(PpEngine engine, BakedSet baked, Map<String, dynamic> W) {
    _frameEngine = engine;
    _setZ = baked.zb;
  }

  static final double _t30 = math.tan(math.pi / 6);

  void _put(
    EstantesItem it,
    int W0,
    int H0,
    Float32List? setZ,
    Uint8List? ladder,
    double bias,
    double S,
  ) {
    final layer = _layer!, lz = _layerZ!, s = it.s, fz = it.z;
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
        final mine = fz != null ? fz[y * s.w + x] : plane;
        if (setZ != null &&
            setZ[i] > mine + bias &&
            (it.ladder || ladder == null || ladder[i] == 0)) {
          continue; // a set pixel nearer than the feet hides it (not the ladder, for don Pepe on it)
        }
        if (lz[i] > mine) continue; // a nearer sprite pixel is already there
        lz[i] = mine;
        layer[i] = c;
      }
    }
  }

  /// [items] and the frog (as the game draws him, juego.js frog, at the depth of his feet): every sprite of the frame,
  /// placed. [draw] composes it; the rules' tests read it.
  List<EstantesItem> placed(Map<String, dynamic> W, int a) {
    final all = items(W, a);
    final q = W['cq'] as Map<String, dynamic>;
    if (jsTruthy(q['vis'])) {
      final b = host.frogBox(q), at = _frogPoint(q);
      final ox = b.x.toInt() - 16, oy = b.y.toInt() - 24;
      final px = Uint32List(64 * 64);
      final g = Ctx(px, 64, 64)..translate(-ox.toDouble(), -oy.toDouble());
      host.frog(g, q, a);
      all.add(
        EstantesItem(
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

  /// Whether the set's pixel [i] (of the picture) in [W]'s state is the ladder's (front.after).
  bool ladderAt(Map<String, dynamic> W, int i) => _ladder(setKey(W))[i] == 1;

  @override
  void draw(Ctx c, Map<String, dynamic> W, int a) {
    const w0 = 240, h0 = 216;
    final layer = _layer ??= Uint32List(w0 * h0);
    final lz = _layerZ ??= Float32List(w0 * h0);
    final setZ = _frameEngine != null ? _setZ : null,
        bias = _p.bias,
        S = _p.e.S;
    final all = placed(W, a);
    final ladder = setZ != null && all.any((it) => !it.ladder)
        ? _ladder(setKey(W))
        : null;
    if (all.isNotEmpty) {
      // only the box the sprites cover is cleared, composed and drawn
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
          _put(it, w0, h0, setZ, ladder, bias, S);
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
    // the counting finger, over everything (a sign)
    final dd = W['dedo'];
    if (dd is List) {
      final f = _spr('dedo', mkDedo);
      c.drawImage(
        f,
        _round(dd[0] as num) - f.w ~/ 2,
        _round(dd[1] as num) - f.h,
      );
    }
  }

  /* ---------- the board: the two rounds ---------- */

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

  // castShadow(x, y, 0, radius) at the world x, y of whoever stands on the floor (z 0) (shadows.at); none off the floor:
  // don Pepe on the ladder, the frog on his crate (shadows.none, off_floor)
  @override
  List<ShadowCast> shadows(Map<String, dynamic> W) {
    final out = <ShadowCast>[];
    void cast(EstantesAt at, double? r) {
      if (r == null || at.z != 0) return;
      out.add((x: at.x, y: at.y, z: 0, r: r));
    }

    final gente = (W['gente'] as Map<String, dynamic>?) ?? const {};
    for (final en in gente.entries) {
      final p = en.value as Map<String, dynamic>;
      if (p['vis'] == 0) continue;
      if (_p.noShadow((p['spot'] as String?) ?? '')) continue;
      cast(_atOf(p), _p.radius(en.key));
    }
    final q = W['cq'] as Map<String, dynamic>?;
    if (q != null && jsTruthy(q['vis']) && (q['z'] as num? ?? 0) == 0) {
      cast(_frogPoint(q), _p.radius('coqui'));
    }
    return out;
  }

  /* ---------- the things he can touch ---------- */

  // the screen box of a sprite item: its drawn pixels' bounds
  static final Expando<List<int>> _inkOf = Expando<List<int>>();

  static List<num>? _inkBox(EstantesItem it) {
    final s = it.s;
    var had = _inkOf[s];
    if (had == null) {
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
      had = _inkOf[s] = x1 < 0 ? const [] : [x0, y0, x1 - x0 + 1, y1 - y0 + 1];
    }
    if (had.isEmpty) return null;
    return [it.left + had[0], it.top + had[1], had[2], had[3]];
  }

  static List<num>? _union(List<num>? u, List<num>? b) {
    if (b == null) return u;
    if (u == null) return b;
    final x0 = math.min(u[0], b[0]), y0 = math.min(u[1], b[1]);
    final x1 = math.max(u[0] + u[2], b[0] + b[2]),
        y1 = math.max(u[1] + u[3], b[1] + b[3]);
    return [x0, y0, x1 - x0, y1 - y0];
  }

  // the boxes of the frame now (one list of placed sprites a frame: the signs ask for boxes many times a frame)
  int? _boxesF;
  Map<String, dynamic>? _boxesW;
  List<EstantesItem> _boxItems = const [];

  List<EstantesItem> _itemsNow(Map<String, dynamic> w) {
    int? f;
    try {
      f = host.F;
    } catch (_) {
      f = null;
    }
    if (f == null) return items(w, 0);
    if (f != _boxesF || !identical(w, _boxesW)) {
      _boxItems = items(w, 0);
      _boxesF = f;
      _boxesW = w;
    }
    return _boxItems;
  }

  List<num>? _boxOfTag(Map<String, dynamic> w, String tag) {
    for (final it in _itemsNow(w)) {
      if (it.tag == tag) return _inkBox(it);
    }
    return null;
  }

  // a kind in the big box (the Needs: "lata, botella (the ones on the floor; any of a kind counts)"): the box round all
  // that are in it (the cans stand on its left, the bottles on its right, so the two never overlap)
  List<num>? _kindBox(Map<String, dynamic> w, String k) {
    List<num>? u;
    final cosas = (w['cosas'] as List? ?? const [])
        .cast<Map<String, dynamic>>();
    for (final it in _itemsNow(w)) {
      final t = it.tag;
      if (t == null || !t.startsWith('cosa:$k.c')) continue;
      final o = cosas.where((c) => 'cosa:${c['id']}' == t).firstOrNull;
      if (o == null || o['caja'] == null) continue;
      u = _union(u, _inkBox(it));
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
    Thing kind(String k) => Thing(
      id: k,
      m: 0,
      z: true,
      si: (w) => _kindBox(w, k) != null,
      box: (Map<String, dynamic> w) => _kindBox(w, k),
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

    return [
      // small things first: they are in front of the shelves and the floor, and over the people
      kind('lata'),
      kind('botella'),
      sprite('red_a', 'cosa:red_a', z: true),
      sprite('red_b', 'cosa:red_b', z: true),
      sprite('caja_senora', 'cosa:caja_senora', z: true),
      sprite('caja_senor', 'cosa:caja_senor', z: true),
      sprite('caja', 'cosa:caja', z: true),
      // the people and Canelo (names: the free poke)
      for (final id in const ['pepe', 'luis', 'senora', 'senor', 'perro'])
        sprite(id, 'persona:$id', m: 1),
      // the set's things (sheet: things.<id>.box): the table only where it is
      setThing('mesa', si: (w) => _n(w['mesa']) == 1),
      setThing('estante'),
    ];
  }

  /* ---------- talking ---------- */

  // the point over a speaker's head (the speaker keys pepe, luis, senora, senor): its sprite's top
  @override
  List<num>? talkAt(String who, Map<String, dynamic> W) {
    for (final it in items(W, 0)) {
      if (it.tag != 'persona:$who') continue;
      final b = _inkBox(it);
      if (b == null) return null;
      return [_round(b[0] + b[2] / 2), b[1] - 1];
    }
    return null;
  }

  @override
  Future<void> stake(int lost, int max, String en) async {
    host.SFX.bonk();
    await wait(300);
  }

  // the stories write no place on the picture (no `x`, `y` in a set step, no answer cards' place): nothing to move
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
    final cosas = [
      for (final o
          in (W['cosas'] as List? ?? const []).cast<Map<String, dynamic>>())
        if (o['vis'] != 0)
          '${o['id']}@${o['con'] ?? o['spot']}${o['v'] != null ? ':${o['v']}' : ''}',
    ].join(',');
    return 'gente=$gente cosas=$cosas gafas=${W['gafas']} marcas=${W['marcas']}';
  }

  /* ---------- moving ---------- */

  // a walk: a straight line at a steady pace, about [pace] px of the picture a tick (El mostrador's)
  Future<void> _anda(String id, String spot, {num pace = 5}) async {
    final p = _g(id);
    final w = _p.world(spot);
    if (p['vis'] == 0) {
      p
        ..['x'] = w[0]
        ..['y'] = w[1]
        ..['z'] = w[2]
        ..['vis'] = 1
        ..['spot'] = spot;
      return;
    }
    await _mueve(p, w, pace: pace);
    p['spot'] = spot;
  }

  // a person goes in a straight line to world point [w], [pace] px of the picture a tick
  Future<void> _mueve(
    Map<String, dynamic> p,
    List<double> w, {
    num pace = 5,
    int? ticks,
  }) async {
    final a = _atOf(p), b = _p.atWorld(w[0], w[1], w[2]);
    final dist = math.sqrt(
      (b.sx - a.sx) * (b.sx - a.sx) + (b.sy - a.sy) * (b.sy - a.sy),
    );
    final x0 = p['x'] as num, y0 = p['y'] as num, z0 = p['z'] as num;
    if ((b.sx - a.sx).abs() > 3) p['dir'] = b.sx > a.sx ? 1 : -1;
    if (dist >= .5) {
      final n = ticks ?? math.max(1, (dist / pace).ceil());
      for (var i = 1; i <= n; i++) {
        p['x'] = x0 + (w[0] - x0) * i / n;
        p['y'] = y0 + (w[1] - y0) * i / n;
        p['z'] = z0 + (w[2] - z0) * i / n;
        p['dy'] = ticks == null && i % 2 == 1 && i < n ? -1 : 0;
        await wait(TICK);
      }
    }
    p['x'] = w[0];
    p['y'] = w[1];
    p['z'] = w[2];
    p['dy'] = 0;
  }

  // a thing flies on the picture from screen point [a] to [b] (its bottom middle), in [n] ticks, [arc] px up at the
  // middle, its depth from [da] to [db]
  Future<void> _vuela(
    Map<String, dynamic> o,
    ({num x, num y}) a,
    ({num x, num y}) b,
    double da,
    double db, {
    int n = 5,
    num arc = 0,
  }) async {
    o['con'] = null;
    o['caja'] = null;
    for (var i = 1; i <= n; i++) {
      final t = i / n;
      o['vuela'] = <String, dynamic>{
        'x': a.x + (b.x - a.x) * t,
        'y': a.y + (b.y - a.y) * t - math.sin(math.pi * t) * arc,
        'd': da + (db - da) * t,
      };
      await wait(TICK);
    }
  }

  static ({num x, num y}) _xy(({num x, num y, double d}) p) => (x: p.x, y: p.y);

  // where a thing is now, as the bottom middle of its sprite on the picture, and its depth
  ({num x, num y, double d}) _whereNow(Map<String, dynamic> o) {
    final vu = o['vuela'] as Map<String, dynamic>?;
    if (vu != null) {
      return (
        x: vu['x'] as num,
        y: vu['y'] as num,
        d: (vu['d'] as num).toDouble(),
      );
    }
    final con = o['con'] as String?;
    if (con != null) {
      final h = _handOf(con);
      if (h != null) return (x: h.x, y: h.y, d: h.d);
    }
    for (final it in items(W, 0)) {
      if (it.tag == 'cosa:${o['id']}') {
        return (x: it.left + it.s.w ~/ 2, y: it.top + inkBottom(it.s), d: it.d);
      }
    }
    final at = _atOf(o);
    return (x: at.sx, y: at.sy, d: at.d);
  }

  // a thing lands at spot [spot] (with [dx] screen px along the row)
  void _pon(Map<String, dynamic> o, String spot, {num dx = 0, num dy = 0}) {
    final w = _p.world(spot);
    o
      ..['x'] = w[0]
      ..['y'] = w[1]
      ..['z'] = w[2]
      ..['spot'] = spot
      ..['dx'] = dx
      ..['dy'] = dy
      ..['con'] = null
      ..['caja'] = null
      ..['vuela'] = null
      ..['vis'] = 1;
  }

  // a thing goes to a spot from where it is now, flying on the picture
  Future<void> _vuelaA(
    Map<String, dynamic> o,
    String spot, {
    num dx = 0,
    int n = 4,
    num arc = 0,
  }) async {
    final a = _whereNow(o), b = _p.at(spot);
    await _vuela(o, _xy(a), (x: b.sx + dx, y: b.sy), a.d, b.d, n: n, arc: arc);
    _pon(o, spot, dx: dx);
  }

  // a thing goes into a hand, flying on the picture
  Future<void> _vuelaMano(
    Map<String, dynamic> o,
    String quien, {
    int n = 4,
    num arc = 0,
  }) async {
    final a = _whereNow(o), h = _handOf(quien);
    if (h != null) {
      await _vuela(o, _xy(a), (x: h.x, y: h.y), a.d, h.d, n: n, arc: arc);
    }
    o['vuela'] = null;
    o['con'] = quien;
  }

  // a thing rolls along the floor to spot [spot] (a can out of the door: `puerta_lata`, the picture's left edge)
  Future<void> _rueda(Map<String, dynamic> o, String spot, {int n = 8}) async {
    final a = _whereNow(o);
    final g = _p.fromScreen(a.x, a.y, 0);
    o
      ..['vuela'] = null
      ..['con'] = null
      ..['caja'] = null
      ..['x'] = g.x
      ..['y'] = g.y
      ..['z'] = 0
      ..['dx'] = 0
      ..['dy'] = 0;
    final w = _p.world(spot), x0 = g.x, y0 = g.y;
    for (var i = 1; i <= n; i++) {
      o['x'] = x0 + (w[0] - x0) * i / n;
      o['y'] = y0 + (w[1] - y0) * i / n;
      await wait(TICK);
    }
    o['vis'] = 0;
    o['spot'] = spot;
  }

  // the bell over the street door
  void _campana() {
    host.tone(1568, 0, .25, 'sine', .08);
    host.tone(2093, .08, .3, 'sine', .06);
  }

  // a bottle breaks on the floor
  void _rompe() {
    host.tone(2600, 0, .08, 'square', .03, 1800);
    host.tone(3400, .05, .12, 'triangle', .03, 2200);
    host.tone(2900, .12, .1, 'triangle', .02, 1500);
  }

  /* ---------- don Pepe and the ladder ---------- */

  bool _enEscalera() => _g('pepe')['spot'] == 'pepe.escalera';

  // don Pepe up the ladder: to its foot (pepe.pie), then rung by rung to pepe.escalera (the sheet's rungs: the line
  // between the two places, one step a rung)
  Future<void> _sube() async {
    final p = _g('pepe');
    if (_enEscalera()) return;
    if (p['spot'] != 'pepe.pie') await _anda('pepe', 'pepe.pie');
    p['pose'] = 'escalera';
    p['dir'] = 1;
    await _mueve(p, _p.world('pepe.escalera'), ticks: 4);
    p['spot'] = 'pepe.escalera';
    host.SFX.creak();
  }

  // don Pepe down the ladder to its foot
  Future<void> _baja() async {
    final p = _g('pepe');
    if (!_enEscalera()) return;
    p['pose'] = 'escalera';
    await _mueve(p, _p.world('pepe.pie'), ticks: 4);
    p['spot'] = 'pepe.pie';
    p['pose'] = 'idle';
  }

  /* ---------- the shelves ---------- */

  // the things standing on the shelf group [g] (estante.medio, estante.alto), in their places' order
  List<Map<String, dynamic>> _enEstante(String g, [String? k]) {
    final spots = _p.group(g);
    final out = <Map<String, dynamic>>[];
    for (final s in spots) {
      for (final o in _items) {
        if (o['vis'] != 0 &&
            o['con'] == null &&
            o['vuela'] == null &&
            o['spot'] == s &&
            (k == null || o['k'] == k)) {
          out.add(o);
        }
      }
    }
    return out;
  }

  // story 39's rings: a can stands on a small ring (the first three places), a bottle on a large one (the last three);
  // the first free one of its kind
  String? _anillo(String k) {
    final g = _p.group('estante.medio');
    final mine = k == 'lata' ? g.sublist(0, 3) : g.sublist(3);
    for (final s in mine) {
      if (!_items.any(
        (o) => o['vis'] != 0 && o['spot'] == s && o['con'] == null,
      )) {
        return s;
      }
    }
    return null;
  }

  // the last bottle on the top shelf (the one furthest along: don Pepe takes from that end)
  Map<String, dynamic>? _ultimaAlto() {
    final l = _enEstante('estante.alto');
    return l.isEmpty ? null : l.last;
  }

  // a bottle falls off the top shelf and breaks on the floor
  // OPEN: the sheet names no place where a falling thing lands: it breaks at the nearest floor spot that holds nothing
  // (story 39: pepe.pie, he is on the ladder; story 41: caja_grande, the big box's place, empty in that story)
  Future<void> _cae(Map<String, dynamic> o) async {
    final suelo = _g('pepe')['spot'] == 'pepe.pie' || _item('caja') == null
        ? 'caja_grande'
        : 'pepe.pie';
    final b = _p.at(suelo), a = _whereNow(o);
    await _vuela(o, _xy(a), (x: b.sx, y: b.sy), a.d, b.d, n: 4);
    _pon(o, suelo);
    o['k'] = 'rota';
    _rompe();
    await wait(TICK * 3);
  }

  /* ---------- counting ---------- */

  // the points a finger goes along to count [n] things of kind [k] (the Needs' `cuenta`: Luis's finger on the cans and
  // bottles in the big box, on the cans of a net, on the bottles of a box seen from above; don Pepe's along the shelf;
  // the frog along abuela's box): each thing's top middle on the picture
  List<({num x, num y})> _puntos(String k, int n, String quien) {
    final out = <({num x, num y})>[];
    final its = items(W, 0);
    EstantesItem? itemOf(String id) =>
        its.where((it) => it.tag == 'cosa:$id').firstOrNull;
    // a net with n cans (story 40: Luis counts the right net)
    if (k == 'lata') {
      for (final o in _items) {
        if (o['k'] != 'red' || o['vis'] == 0 || _n(o['v']) != n) continue;
        final it = itemOf(o['id'] as String);
        if (it == null) continue;
        for (final c in redLayout(n)) {
          out.add((x: it.left + c.x + 3, y: it.top + c.y));
        }
        return out;
      }
    }
    // the big box's own (story 39)
    final enCaja = [
      for (final o in _items)
        if (o['caja'] != null && o['vis'] != 0 && o['k'] == k) o,
    ];
    if (enCaja.isNotEmpty) {
      for (final o in enCaja) {
        final it = itemOf(o['id'] as String);
        if (it != null) out.add((x: it.left + it.s.w ~/ 2, y: it.top));
      }
      return out.take(n).toList();
    }
    // a box seen from above (story 41): abuela's for the frog, the one asked about for Luis
    if (k == 'botella') {
      final caja = quien == 'coqui' ? _item('caja_abuela') : _cajaPedida();
      if (caja != null && quien != 'pepe') {
        final c = _p.world(caja['spot'] as String),
            f = _p.footprint(caja['spot'] as String);
        for (var i = 0; i < math.min(n, _n(caja['v'])); i++) {
          final h = holeAt(c, f, i), s = _p.atWorld(h[0], h[1], h[2]);
          out.add((x: s.sx, y: s.sy - 1));
        }
        return out;
      }
    }
    // the shelf (story 39's end: don Pepe counts the bottles on their rings)
    for (final o in _enEstante('estante.medio', k)) {
      final it = itemOf(o['id'] as String);
      if (it != null) out.add((x: it.left + it.s.w ~/ 2, y: it.top));
    }
    return out.take(n).toList();
  }

  // the box being asked about in story 41: the first customer's box that is not full
  Map<String, dynamic>? _cajaPedida() {
    for (final id in const ['caja_senora', 'caja_senor']) {
      final c = _item(id);
      if (c != null && c['vis'] != 0 && _n(c['v']) < 10) return c;
    }
    return _item('caja_senor') ?? _item('caja_senora');
  }

  /* ---------- the pyramid (story 40) ---------- */

  // how many rows of the pyramid are laid
  int _filas() {
    final g = _p.group('mesa.fila');
    var n = 0;
    for (var r = 0; r < g.length; r++) {
      if (_items.any(
        (o) => o['vis'] != 0 && o['spot'] == g[r] && o['k'] == 'lata',
      )) {
        n = r + 1;
      }
    }
    return n;
  }

  // the pitch of the cans in a row: a can's own width (estantes-preview.html cansRow: 6 px)
  static final int _paso = mkLata().w - 2;

  // a row of [n] cans laid on row [r], can by can (estantes-preview.html cansRow: centred on the row's point)
  Future<void> _fila(int r, int n, {int every = 3}) async {
    final g = _p.group('mesa.fila');
    final spot = g[math.min(r, g.length - 1)];
    final p = _g('pepe');
    for (var i = 0; i < n; i++) {
      final dx = _round((i - (n - 1) / 2) * _paso);
      final c = _cosa('fila.$r.$i', 'lata', spot, dx: dx)
        ..['lab'] = (r + i) % 3;
      _items.add(c);
      p['pose'] = i % 2 == 0 ? 'mano' : 'idle';
      host.SFX.blip();
      await wait(TICK * every);
    }
    p['pose'] = 'idle';
  }

  // the flag on top of the highest row (estantes-preview.html: on mesa.fila.3, a can's height up)
  void _bandera() {
    final r = _filas();
    if (r == 0) return;
    _items.removeWhere((o) => o['k'] == 'bandera');
    final g = _p.group('mesa.fila');
    _items.add(_cosa('bandera', 'bandera', g[r - 1], dy: -(mkLata().h - 2)));
  }

  /* ---------- the acts (estantes.md, "Needs") ---------- */

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

  Map<String, Act> _acts() => {
    // `ya`: waits for the acts that were started with `suelto: 1` (as in every scene)
    'ya': (o) async {
      final all = List<Future<void>>.of(_sueltos);
      _sueltos.clear();
      await Future.wait(all);
    },
    // `marca` {que}: the star or the cross on the rounds card (comer.js marca)
    'marca': (o) async {
      final m = W['marcas'];
      if (m is List) {
        final i = m.indexOf(null);
        if (i >= 0) m[i] = o['que'];
      }
      host.SFX.blip();
      await wait(250);
    },
    // `final`: stars and a heart when nothing was lost (the kit's `fin`)
    'final': (o) => acts['fin']!(o),
    // `sube`: don Pepe up the ladder (39: 2; 41: 2, 5, 6, 7)
    'sube': (o) => _sube(),
    // `baja` {tiembla}: down the ladder; with `tiembla` the ladder wobbles and a bottle shakes off the top shelf and
    // breaks (41: 6, 7)
    'baja': (o) async {
      if (jsTruthy(o['tiembla'])) {
        W['tiembla'] = F + 14;
        host.SFX.creak();
        await _baja();
        final b = _ultimaAlto();
        if (b != null) await _cae(b);
        W['tiembla'] = 0;
      } else {
        await _baja();
      }
    },
    // `tiembla`: the ladder wobbles and the bottles on the top shelf rattle (41: 2)
    // OPEN: the ladder is the set's (baked): it does not move; don Pepe on it and the bottles on the top shelf shake
    'tiembla': (o) async {
      W['tiembla'] = F + 12;
      host.SFX.creak();
      for (var i = 0; i < 4; i++) {
        host.tone(1900 + i * 140, i * .09, .05, 'square', .02);
      }
      await wait(TICK * 7);
      W['tiembla'] = 0;
    },
    // `abre39`: don Pepe opens the big box: the cans and the bottles show (39: 1)
    'abre39': (o) async {
      final p = _g('pepe');
      if (p['spot'] != 'pepe.pie') await _anda('pepe', 'pepe.pie');
      p['pose'] = 'mano';
      await wait(TICK * 3);
      _item('caja')?['v'] = 'abierta';
      for (final x in _items) {
        if (x['caja'] != null) x['vis'] = 1;
      }
      host.SFX.creak();
      await wait(TICK * 3);
      p['pose'] = 'idle';
    },
    // `saca` {k}: he lifts a can or a bottle out of the box to be seen, then puts it back (39: 1)
    'saca': (o) async {
      final k = o['k'] as String, p = _g('pepe');
      final t = _items.lastWhere(
        (x) => x['caja'] != null && x['vis'] != 0 && x['k'] == k,
        orElse: () => <String, dynamic>{},
      );
      if (t.isEmpty) return;
      final slot = t['caja'];
      p['pose'] = 'mano';
      t['caja'] = null;
      t['con'] = 'pepe';
      host.SFX.blip();
      await wait(TICK * 10);
      t['con'] = null;
      t['caja'] = slot;
      p['pose'] = 'idle';
      await wait(TICK * 2);
    },
    // `lanza` {k, ok}: the frog tosses a can or a bottle up; ok: don Pepe catches it and stands it on its ring; not ok:
    // it slips through his hands: a bottle breaks on the floor, a can rolls out of the door (39: 2, 3, 6, 7, 8)
    'lanza': (o) async {
      final k = o['k'] as String, ok = jsTruthy(o['ok']) && o['ok'] != 0;
      var t = _items.lastWhere(
        (x) => x['caja'] != null && x['vis'] != 0 && x['k'] == k,
        orElse: () => <String, dynamic>{},
      );
      if (t.isEmpty) {
        // nothing of that kind left in the box (a story never asks it): one comes from the box all the same
        t = _cosa('$k.x$F', k, 'caja_grande');
        _items.add(t);
      }
      // into the frog's hands, then up
      await _vuelaMano(t, 'coqui', n: 2);
      host.bounce(6);
      host.SFX.swoop();
      final p = _g('pepe');
      p['pose'] = 'escalera_alto';
      await _vuelaMano(t, 'pepe', n: 6, arc: 18);
      if (ok) {
        host.SFX.blip();
        await wait(TICK * 2);
        final ring = _anillo(k);
        if (ring != null) {
          p['pose'] = 'alcanza';
          await _vuelaA(t, ring, n: 3);
          host.SFX.drop();
        } else {
          t['vis'] = 0;
        }
        p['pose'] = 'escalera';
        await wait(TICK * 2);
        return;
      }
      // he fumbles
      p['pose'] = 'escalera';
      await wait(TICK * 2);
      if (k == 'botella') {
        await _cae(t);
      } else {
        final suelo = _p.at(
          _g('pepe')['spot'] == 'pepe.pie' ? 'caja_grande' : 'pepe.pie',
        );
        final a = _whereNow(t);
        await _vuela(t, _xy(a), (x: suelo.sx, y: suelo.sy), a.d, suelo.d, n: 4);
        host.SFX.drop();
        await _rueda(t, 'puerta_lata');
      }
    },
    // `cuenta` {k, n, quien}: a finger, or the frog, goes along n things, in time with the counting line (39: 4, 8;
    // 40: 6; 41: 1, 6, 7)
    // OPEN: 41:1 "the frog hops along the box, bottle by bottle": the sheet names no places along the box for him; he
    // bounces where he is while the finger goes along the bottles
    'cuenta': (o) async {
      final k = o['k'] as String, n = _n(o['n']), quien = o['quien'] as String;
      for (final x in _items) {
        if (x['k'] == 'nota') x['vis'] = 0;
      }
      final pts = _puntos(k, n, quien);
      final p = quien == 'coqui' ? null : _g(quien);
      final era = p?['pose'];
      if (p != null) {
        p['pose'] = quien == 'luis'
            ? 'cuenta'
            : (_enEscalera() ? 'escalera_alto' : 'mano');
      }
      await wait(TICK * 2);
      for (var i = 0; i < pts.length; i++) {
        W['dedo'] = [pts[i].x, pts[i].y];
        host.tone(660 + i * 60, 0, .06, 'sine', .05);
        if (quien == 'coqui') host.bounce(4);
        await wait(TICK * 6);
      }
      W['dedo'] = null;
      if (p != null) p['pose'] = era ?? 'idle';
      await wait(TICK);
    },
    // `gafas` {que}: `caen` they slip off his nose and fall into the big box; `halla` Luis finds them (39: 5, 8)
    'gafas': (o) async {
      if (o['que'] == 'caen') {
        final p = _g('pepe'), at = _atOf(p);
        W['gafas'] = 0;
        final g = _cosa('gafas', 'gafas', 'caja_grande');
        _items.add(g);
        final c = _p.at('caja_grande');
        // from his face (mkPersona's eyes, row 11 of the figure: the sprite's top on its feet's row less its height)
        final sp = _personSprite('pepe', p, false).s;
        final face = (x: at.sx, y: at.sy - inkBottom(sp) + 14);
        await _vuela(g, face, (x: c.sx, y: c.sy - 12), at.d + .1, c.d, n: 6);
        g['vis'] = 0;
        g['vuela'] = null;
        host.SFX.drop();
        await wait(TICK * 2);
      } else {
        final g = _item('gafas');
        final l = _g('luis');
        l['pose'] = 'mano';
        if (g != null) {
          g
            ..['vis'] = 1
            ..['con'] = 'luis';
        }
        host.SFX.blip();
        await wait(TICK * 4);
      }
    },
    // `busca39`: he feels for his glasses and does not find them (39: 5)
    'busca39': (o) async {
      final p = _g('pepe');
      p['pose'] = 'escalera';
      for (var i = 0; i < 6; i++) {
        p['dir'] = i % 2 == 0 ? -1 : 1;
        await wait(TICK * 2);
      }
      p['dir'] = 1;
    },
    // `cliente` {quien, lleva, n}: waits at the window; comes in, takes n of a kind, goes (39: start, 9; 41: 5)
    'cliente': (o) async {
      final quien = o['quien'] as String, lleva = o['lleva'] as String?;
      final p = _g(quien);
      if (lleva == 'caja') {
        // 41:5: comes in with a box of her own, sets it on the floor and stands by it
        _campana();
        final w = _p.world('entra');
        p
          ..['x'] = w[0]
          ..['y'] = w[1]
          ..['z'] = w[2]
          ..['vis'] = 1
          ..['spot'] = 'entra';
        final box =
            _item('caja_$quien') ??
            (_cosa('caja_$quien', 'botellero', 'caja_$quien', v: _n(o['n']))
              ..['vis'] = 0);
        if (!_items.contains(box)) _items.add(box);
        box
          ..['v'] = _n(o['n'])
          ..['con'] = quien
          ..['vis'] = 1;
        p['pose'] = 'mano';
        await _anda(quien, '$quien.caja');
        _pon(box, 'caja_$quien');
        host.SFX.drop();
        p['pose'] = 'idle';
        p['dir'] = 1;
        await wait(TICK * 2);
        return;
      }
      p['llamada'] = _n(p['llamada']) + 1;
      if (p['vis'] == 0 || p['llamada'] == 1) {
        // the start: she waits at the left edge (fresh has put her there)
        await _anda(quien, quien == 'senora' ? 'cola1' : 'cola2');
        return;
      }
      // 39:9: what the shelf holds of her kind goes to her, one by one
      // OPEN: "comes in, takes n of a kind, goes": the sheet names no place at the shelf for a customer, and the story
      // looks at the señora's empty hand after she is served: each customer stays where she waits (cola1, cola2) and
      // the things go to her hand from the shelf
      _campana();
      final k = lleva ?? 'lata', n = _n(o['n']);
      p['pose'] = 'mano';
      final l = _enEstante('estante.medio', k);
      for (var i = 0; i < math.min(n, l.length); i++) {
        await _vuelaMano(l[i], quien, n: 5, arc: 8);
        host.SFX.blip();
      }
      await wait(TICK * 2);
    },
    // `mira` {quien, a}: somebody looks at something: don Pepe at his drawing, at the frog, along the top shelf; Luis
    // round the shop; a customer at an empty hand or an empty hole (39: 9; 40: 1, 5, 9; 41: 8)
    'mira': (o) async {
      final quien = o['quien'] as String, a = o['a'] as String?;
      final p = _g(quien);
      if (p['vis'] == 0) return;
      final at = _atOf(p);
      num? tx;
      switch (a) {
        case 'dibujo':
          tx = _p.at('dibujo').sx;
        case 'coqui':
          final b = host.frogBox(W['cq'] as Map<String, dynamic>);
          tx = b.x + b.w / 2;
        case 'estante':
          for (var i = 0; i < 4; i++) {
            p['dir'] = i % 2 == 0 ? 1 : -1;
            await wait(TICK * 3);
          }
          p['dir'] = 1;
          return;
        case 'tienda':
          for (var i = 0; i < 4; i++) {
            p['dir'] = i % 2 == 0 ? -1 : 1;
            await wait(TICK * 3);
          }
          return;
        case 'mano':
          p['pose'] = 'mano';
          await wait(TICK * 8);
          return;
        case 'hueco':
          final c = _item('caja_$quien');
          if (c != null) tx = _atOf(c).sx;
          p['dy'] = 1;
          if (tx != null && (tx - at.sx).abs() > 2) {
            p['dir'] = tx > at.sx ? 1 : -1;
          }
          await wait(TICK * 8);
          p['dy'] = 0;
          return;
      }
      if (tx != null && (tx - at.sx).abs() > 2) p['dir'] = tx > at.sx ? 1 : -1;
      await wait(TICK * 5);
    },
    // `fila` {n, una}: don Pepe lays a row of n cans can by can, in time with the counting line (40: 1, 2, 6)
    'fila': (o) => _fila(_filas(), _n(o['n'])),
    // `redes` {a, b}: two nets of cans stand on the crate (40: 3, 6, 7)
    'redes': (o) async {
      final l = _g('luis');
      l['pose'] = 'mano';
      for (final (id, v) in [('red_a', o['a']), ('red_b', o['b'])]) {
        var r = _item(id);
        if (r == null) {
          r = _cosa(id, 'red', id);
          _items.add(r);
        }
        _pon(r, id);
        r['v'] = _n(v);
        host.SFX.blip();
        await wait(TICK * 3);
      }
      l['pose'] = 'idle';
    },
    // `pone` {n, ok}: a net is carried over and its row laid; not ok: don Pepe counts it, shakes his head, and two cans
    // fall out on the way back and roll out of the door (40: 3, 4, 6, 7)
    // OPEN: "the frog and Luis carry it over": the sheet names no places for them between the crate and the table: the
    // net goes over by itself, the frog bounces and Luis holds out his hand
    'pone': (o) async {
      final n = _n(o['n']), ok = jsTruthy(o['ok']) && o['ok'] != 0;
      final net = _items.firstWhere(
        (x) => x['k'] == 'red' && x['vis'] != 0 && _n(x['v']) == n,
        orElse: () => <String, dynamic>{},
      );
      final r = _filas();
      final row = _p.group('mesa.fila')[math.min(r, 3)];
      host.bounce(5);
      _g('luis')['pose'] = 'mano';
      if (net.isNotEmpty) {
        final home = net['spot'] as String;
        final a = _whereNow(net), b = _p.at(row);
        await _vuela(net, _xy(a), (x: b.sx, y: b.sy), a.d, b.d, n: 5, arc: 6);
        if (ok) {
          net['vis'] = 0;
          net['vuela'] = null;
          _pon(net, home);
          net['vis'] = 0;
        } else {
          // don Pepe counts it with his finger and shakes his head
          final p = _g('pepe'),
              it = items(
                W,
                0,
              ).where((i) => i.tag == 'cosa:${net['id']}').firstOrNull;
          if (it != null) {
            for (final c in redLayout(n)) {
              W['dedo'] = [it.left + c.x + 3, it.top + c.y];
              host.tone(660, 0, .05, 'sine', .04);
              await wait(TICK * 3);
            }
          }
          W['dedo'] = null;
          final d = _n(p['dir']) < 0 ? -1 : 1;
          for (var i = 0; i < 4; i++) {
            p['dir'] = i % 2 == 0 ? -d : d;
            await wait(TICK);
          }
          p['dir'] = d;
          // on the way back, half way, two cans fall out of it and roll out of the door
          final back = _p.at(home), mid = _whereNow(net);
          final half = (x: (mid.x + back.sx) / 2, y: (mid.y + back.sy) / 2);
          await _vuela(
            net,
            (x: mid.x, y: mid.y),
            half,
            mid.d,
            (mid.d + back.d) / 2,
            n: 3,
          );
          net['v'] = math.max(0, n - 2);
          final fuera = <Future<void>>[];
          for (var i = 0; i < 2; i++) {
            final c = _cosa('suelta.$F.$i', 'lata', home)..['lab'] = i;
            _items.add(c);
            c['vuela'] = <String, dynamic>{
              'x': half.x + i * 6 - 3,
              'y': half.y,
              'd': mid.d,
            };
            fuera.add(_rueda(c, 'puerta_lata', n: 7 + i));
          }
          host.SFX.drop();
          await _vuela(
            net,
            half,
            (x: back.sx, y: back.sy),
            (mid.d + back.d) / 2,
            back.d,
            n: 3,
          );
          _pon(net, home);
          await Future.wait(fuera);
          _g('luis')['pose'] = 'idle';
          return;
        }
      }
      if (ok) await _fila(r, n, every: 2);
      _g('luis')['pose'] = 'idle';
    },
    // `bandera`: the flag goes in on top (40: 4, 8)
    'bandera': (o) async {
      _bandera();
      host.SFX.blip();
      await wait(TICK * 3);
    },
    // `tumba`: Canelo runs in at the door, bumps the table: the pyramid comes down, the cans roll back to the crate; he
    // runs out with the drawing in his mouth; Luis runs after him and brings him back by the collar, without the
    // drawing (40: 5). He sits beside the frog after (estantes-preview.html moment 3: perro.rana)
    'tumba': (o) async {
      final d = _g('perro'), l = _g('luis');
      _campana();
      _pon(d, 'perro.entra');
      d['pose'] = 'run';
      d['vis'] = 1;
      d['dir'] = 1;
      await _anda('perro', 'perro.mesa', pace: 8);
      host.SFX.bonk();
      // the pyramid comes down: the cans roll back to the crate
      final cans = [
        for (final x in _items)
          if (x['k'] == 'lata' &&
              (x['spot'] as String).startsWith('mesa.fila') &&
              x['vis'] != 0)
            x,
      ];
      _items.removeWhere((x) => x['k'] == 'bandera');
      final rolling = [
        for (var i = 0; i < cans.length; i++)
          () async {
            await wait(TICK * (i % 4));
            await _vuelaA(cans[i], 'cajon_latas', n: 5, arc: 4);
            cans[i]['vis'] = 0;
          }(),
      ];
      // the drawing into his mouth, and out he goes
      final papel = _item('papel');
      if (papel != null) papel['vis'] = 0;
      d['pose'] = 'papel';
      await wait(TICK * 2);
      await _anda('perro', 'perro.entra', pace: 8);
      await Future.wait(rolling);
      d['vis'] = 0;
      // Luis runs after him and brings him back by the collar
      await _anda('luis', 'entra', pace: 7);
      l['vis'] = 0;
      await wait(TICK * 4);
      l['vis'] = 1;
      _pon(d, 'perro.entra');
      d['pose'] = 'idle';
      d['vis'] = 1;
      await Future.wait([
        _anda('luis', 'luis.cajas'),
        () async {
          d['pose'] = 'stand';
          await _anda('perro', 'perro.rana');
          d['pose'] = 'sit';
          d['dir'] = -1;
        }(),
      ]);
      l['dir'] = -1;
    },
    // `resto` {n}: the crate tipped to show what is left; the top is made of it (40: 8)
    'resto': (o) async {
      final n = _n(o['n']), p = _g('pepe');
      W['cajonVacio'] = 1;
      for (final x in _items) {
        if (x['k'] == 'red') x['vis'] = 0;
      }
      p['pose'] = 'mano';
      host.SFX.creak();
      await wait(TICK * 5);
      if (n > 0) await _fila(_filas(), n);
      p['pose'] = 'idle';
    },
    // `cajade` {quien, n}: a box of ten holes with n bottles, seen from above (41: 1, 5)
    'cajade': (o) async {
      final quien = o['quien'] as String, id = 'caja_$quien';
      var c = _item(id);
      if (c == null) {
        c = _cosa(id, 'botellero', id, v: _n(o['n']));
        _items.add(c);
      }
      if (c['con'] == null) _pon(c, id);
      c['v'] = _n(o['n']);
      // OPEN: the script's shelf holds what abuela's box and the two customers' boxes need, and one over; how much the
      // customers' boxes need is drawn at this step (8 or 9 each). The shelf starts with seven (estantes-preview.html
      // moment 4: one at each place); once both boxes are in, what is left on it is made that number (one bottle
      // more or fewer at the end of the row, with no move)
      if (quien == 'senor') {
        final ra = _item('caja_senora'),
            want = (10 - _n(ra?['v'] ?? 10)) + (10 - _n(c['v'])) + 1;
        final g = _p.group('estante.alto');
        var on = _enEstante('estante.alto');
        while (on.length > want) {
          on.last['vis'] = 0;
          on = _enEstante('estante.alto');
        }
        for (var i = 0; i < g.length && on.length < want; i++) {
          if (on.any((x) => x['spot'] == g[i])) continue;
          _items.add(_cosa('malta.mas.$i', 'malta', g[i]));
          on = _enEstante('estante.alto');
        }
      }
      host.SFX.blip();
      await wait(TICK * 2);
    },
    // `nota41`: Luis shows abuela's note (41: 1); he holds it until he, or the frog, counts
    'nota41': (o) async {
      final l = _g('luis');
      _items.add(_cosa('nota', 'nota', 'luis.cajas')..['con'] = 'luis');
      l['pose'] = 'mano';
      host.SFX.blip();
      await wait(TICK * 6);
    },
    // `pasa` {a, n}: don Pepe hands n bottles down, one at a time, into a box (41: 2, 3, 4, 6, 7)
    // OPEN: 41:2 "hands it to Luis, who puts it in the box": Luis has no place by abuela's box: the bottle goes from
    // don Pepe's hand into the box
    'pasa': (o) async {
      final a = o['a'] as String, n = _n(o['n']);
      final caja = _item('caja_$a');
      final p = _g('pepe');
      for (var i = 0; i < n; i++) {
        final b = _ultimaAlto();
        if (b == null || caja == null) break;
        p['pose'] = 'alcanza';
        await _vuelaMano(b, 'pepe', n: 3);
        p['pose'] = 'escalera';
        final c = _p.world(caja['spot'] as String),
            f = _p.footprint(caja['spot'] as String);
        final h = holeAt(c, f, math.min(9, _n(caja['v']))),
            s = _p.atWorld(h[0], h[1], h[2]);
        final from = _whereNow(b);
        await _vuela(
          b,
          _xy(from),
          (x: s.sx, y: s.sy + 2),
          from.d,
          s.d,
          n: 5,
          arc: 6,
        );
        b['vis'] = 0;
        b['vuela'] = null;
        caja['v'] = math.min(10, _n(caja['v']) + 1);
        host.SFX.drop();
        await wait(TICK * 2);
      }
      p['pose'] = _enEscalera() ? 'escalera' : 'idle';
    },
    // `lleva` {quien}: a box is carried to the door, or out (41: 4, 8, 9)
    'lleva': (o) async {
      final quien = o['quien'] as String;
      final caja = _item('caja_$quien');
      if (quien == 'abuela') {
        final l = _g('luis');
        if (!jsTruthy(W['abuelaLista'])) {
          // OPEN: 41:4 "Luis carries the box to the door and sets it down there": the sheet names no place by the door
          // for a box: it stays at caja_abuela; Luis bends to it
          W['abuelaLista'] = 1;
          l['pose'] = 'mano';
          l['dy'] = 2;
          await wait(TICK * 6);
          l['dy'] = 0;
          l['pose'] = 'idle';
          return;
        }
        // 41:9: Luis lifts abuela's box and goes out with it
        // OPEN: "Luis y Coquí van para la casa": the frog has no place on the way out: he stays and bounces
        if (caja != null) caja['con'] = 'luis';
        l['pose'] = 'mano';
        host.bounce(6);
        await _anda('luis', 'entra');
        l['vis'] = 0;
        caja?['vis'] = 0;
        host.bounce(6);
        await wait(TICK * 2);
        return;
      }
      // 41:8: the señora and the señor lift their boxes
      // OPEN: a box is drawn from above, lying on the floor (the sheet's footprint): lifted, it would cross the person
      // like a plank, and the steps after look at what is in it (the señor's empty hole). Each bends to his box and it
      // stays where it is; the script's "the señora waves from the door" is waved where she stands (no place by the
      // door is named for her)
      final p = _g(quien);
      p['pose'] = 'mano';
      p['dy'] = 2;
      host.SFX.blip();
      await wait(TICK * 4);
      p['dy'] = 0;
      p['pose'] = 'idle';
    },
    // `niega41`: don Pepe starts to hand down the wrong number; Luis shakes his head and holds up the box (41: 6, 7)
    // OPEN: Luis has no place by the customer's box (luis.cajas is far from caja_senora and caja_senor): he lifts his
    // hand and shakes his head where he stands; the box stays on the floor
    'niega41': (o) async {
      final p = _g('pepe'), l = _g('luis');
      final b = _ultimaAlto();
      p['pose'] = 'alcanza';
      if (b != null) b['con'] = 'pepe';
      await wait(TICK * 4);
      l['pose'] = 'arriba';
      final d = _n(l['dir']) < 0 ? -1 : 1;
      for (var i = 0; i < 4; i++) {
        l['dir'] = i % 2 == 0 ? -d : d;
        await wait(TICK);
      }
      l['dir'] = d;
      if (b != null) b['con'] = null;
      p['pose'] = 'escalera';
      await wait(TICK * 3);
      l['pose'] = 'idle';
    },
    // `abre41`: he brings the last bottle down and opens it for the frog (41: 8)
    'abre41': (o) async {
      final b = _ultimaAlto();
      final p = _g('pepe');
      if (b == null) return;
      p['pose'] = 'alcanza';
      await _vuelaMano(b, 'pepe', n: 3);
      p['pose'] = 'mano';
      await _baja();
      p['pose'] = 'mano';
      b['v'] = 'abierta';
      host.tone(2400, 0, .25, 'sawtooth', .02, 900); // the hiss
      await wait(TICK * 4);
      await _vuelaMano(b, 'coqui', n: 5, arc: 4);
      host.bounce(5);
      p['pose'] = 'idle';
      await wait(TICK * 2);
    },
    // `saluda` {quien}: somebody waves (41: 9)
    'saluda': (o) async {
      final p = _g(o['quien'] as String);
      if (p['vis'] == 0) return;
      for (var i = 0; i < 6; i++) {
        p['pose'] = i % 2 == 0 ? 'saluda0' : 'saluda1';
        await wait(TICK);
      }
      p['pose'] = 'idle';
    },
    // `ir` {a}: the shared act (kit.js comunes.ir) on the frog's two places, his crate (`cajon`) and the floor (`piso`),
    // with his height kept (on the crate he stands on its top, z .3)
    'ir': (o) async {
      final a = o['a'], key = jsTruthy(a) ? a : o['en'];
      if (key is! String || !LUGAR.containsKey(key)) return;
      final q = W['cq'] as Map<String, dynamic>, L = LUGAR[key]!;
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
      q['z'] = _p.world('coqui.$key')[2];
    },
  };
}
