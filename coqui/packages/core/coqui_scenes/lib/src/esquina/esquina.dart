// La esquina (place 5, La calle, scene 1; stories 48 to 50): a NEW scene, written from its script's "Needs" list
// (historia/notas/guiones/esquina.md) on its set (esquina_set.dart) and its sheet (esquina-sheet.json, read by
// SceneSheet). There is no old scene file: every act is this file's, each doing on screen what the Needs list says,
// every place from the sheet (a spot's world point, a thing's box, the lanes of `routes.trafico`, the depth rule). Where
// the sheet names no place, or the script does not settle what an act shows, the act does the plainest thing that keeps
// the story playing and says so in a comment starting `OPEN:` (page 13 lists them for the content lane).
//
// The drawing (the sheet's `front`): every person and small thing stands with its feet's bottom edge on its spot's row
// and its middle on its column (rules.anchor); its pixel is hidden by every set pixel nearer the camera than the upright
// plane through its feet plus `front.bias` (front.plane). The things that drive are La calle's vehicle sprites
// (calle_vehicles.dart: baked once from calle-base.js `vehicle`), placed by the middle of their floor, each pixel with
// its own depth: a set pixel nearer than it hides it, and a person is hidden by it as by the set (the sheet: "a car or a
// guagua baked into the set hides whoever stands behind it"); between two people the nearer pixel wins.
// ignore_for_file: non_constant_identifier_names

import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/src/calle/calle_cast.dart';
import 'package:coqui_scenes/src/calle/calle_vehicles.dart';
import 'package:coqui_scenes/src/colmado/colmado_cast.dart';
import 'package:coqui_scenes/src/esquina/esquina_places.dart';
import 'package:coqui_scenes/src/esquina/esquina_set.dart';
import 'package:coqui_scenes/src/esquina/esquina_sprites.dart';
import 'package:coqui_scenes/src/mostrador/mostrador_sprites.dart'
    show bancoWho;
import 'package:coqui_scenes/src/scene_set.dart';
import 'package:coqui_scenes/src/sheet_cache.dart';

/// The scene "La esquina", made from its sheet (read first: `loadScene`).
Scene createEsquina() => Esquina(sceneSheetOf('esquina'));

int _round(num v) => (v + 0.5).floor();

int _n(Object? v) => v is num ? v.toInt() : 0;

/// One sprite of the sprite layer, placed: its picture, its top left on the 240 x 216 picture, the screen row of its
/// feet and the depth there (front.plane).
class EsquinaItem {
  EsquinaItem(
    this.s,
    this.left,
    this.top,
    this.sy,
    this.d, {
    this.tag,
    this.grown = false,
  });

  /// A grown-up (whose pixels never hide the frog).
  final bool grown;

  final Sprite s;
  final int left, top;
  final num sy;
  final double d;

  /// Who or what it is (the rules' tests read it: `persona:<id>`, `coqui`, `cosa:<id>`, `auto:<k>`).
  final String? tag;
}

/// A vehicle of the sprite layer, placed: its sprite, top left, the depth of its floor's middle, its key.
class EsquinaAuto {
  EsquinaAuto(this.v, this.left, this.top, this.d, this.tag, this.kind);

  final VehicleSprite v;
  final int left, top;
  final double d;
  final String tag;

  /// `carro`, `azul` or `guagua`.
  final String kind;
}

/// The people of the place (the speaker keys and `quien` of the three stories).
const List<String> _people = [
  'abuela',
  'mama',
  'papa',
  'luis',
  'carmen',
  'senora',
  'senor',
  'pepe',
  'obrero',
];

class Esquina extends Escena implements SetScene, SetOverSprites {
  Esquina(this.ss) : sheet = ss.legacy() {
    _p = EsquinaPlaces(ss);
    CAM = {'wide': _p.view('wide')};
    LUGAR = {
      for (final e in _frogPlaces.entries) e.key: _frogAt(_p.at(e.value)),
    };
    cosas = _things();
  }

  /// The new scene's sheet (SceneSheet).
  final SceneSheet ss;

  @override
  final Sheet sheet;

  late final EsquinaPlaces _p;

  /// The scene's places, from its sheet.
  EsquinaPlaces get places => _p;

  @override
  String get id => 'esquina';

  @override
  late final Map<String, List<num>> CAM;

  late final Map<String, List<num>> LUGAR;

  @override
  Map<String, List<num>> get lugar => LUGAR;

  @override
  late final List<Thing> cosas;

  @override
  PpEngine newEngine({bool still = false}) => esquinaEngine(still: still);

  @override
  PpEngine get projection => _p.e;

  // where the frog's `ir` goes, by the stories' names: the sheet's spots of kind frog
  static const Map<String, String> _frogPlaces = {
    // the near pavement: the start of story 48, the ending of story 49 (acera5: "front row 5: the frog")
    'acera': 'acera5',
    'enfrente': 'acera5',
    'esquina': 'esquina',
    'boton': 'boton_coqui',
    'carro': 'toca_carro',
    'guagua': 'toca_guagua',
    'cerca': 'coqui.cerca',
    'cemento': 'coqui.cemento',
  };

  // the frog's top left for a spot (rules.anchor: mkCoqui's column 16 on sx, its row 25 on sy)
  List<num> _frogAt(EsquinaAt a) => [_round(a.sx) - 16, _round(a.sy) - 25, 1];

  Map<String, dynamic> get W => host.W;
  int get F => host.F;
  int get TICK => host.TICK;
  Future<void> wait(num ms) => host.wait(ms);
  Future<void> _tick() => wait(TICK);

  /* ---------- the state ---------- */

  // what the story does, read once from its file at the start: the acts it calls and with what
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

  // a `llega` with no place (`a`): does it stop for a touch, or drive through? It stops when the next act the story
  // writes for the same thing (`k`) is its `sigue` (it drives on from where it stopped: story 48 steps 2 to 4, story 49
  // step 3's bicycle); else it goes by (story 48 step 3's blue car, story 49 step 3's car and guagua). Read once from the
  // story's acts in the file's order, by the act's own words.
  final Map<String, bool> _stops = {};

  static String _llegaKey(Map<String, dynamic> o) =>
      '${o['k']}|${o['color']}|${o['de']}|${o['quien']}';

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

  Map<String, dynamic> _cosa(String id, String k, String spot, {Object? v}) {
    final w = _p.world(spot);
    return <String, dynamic>{
      'id': id,
      'k': k,
      'x': w[0],
      'y': w[1],
      'z': 0.0,
      'spot': spot,
      'vis': 1,
      'v': v,
    };
  }

  @override
  Map<String, dynamic> fresh(Map<String, dynamic> story) {
    final acts = _actsOf([story['beats'], story['final']]);
    bool has(String a) => acts.any((o) => o['act'] == a);
    _stops.clear();
    for (var i = 0; i < acts.length; i++) {
      final o = acts[i];
      if (o['act'] != 'llega' || o['a'] != null) continue;
      var stop = false;
      for (var j = i + 1; j < acts.length; j++) {
        final n = acts[j];
        if (n['k'] != o['k']) continue;
        if (n['act'] == 'sigue') {
          stop = true;
          break;
        }
        if (n['act'] == 'llega') break;
      }
      _stops[_llegaKey(o)] = stop;
    }
    final gente = <String, dynamic>{};
    final cosas = <dynamic>[];
    String frog;
    Map<String, dynamic>? bebe;
    if (has('flores')) {
      // story 48: abuela with the bebé on her arm and the frog on the near pavement (esquina-preview.html moment 1)
      gente['abuela'] = _person('acera2');
      bebe = {'con': 'abuela', 'est': 'idle', 'dy': 0};
      frog = 'acera5';
    } else if (has('globos')) {
      // story 49: the frog at the corner; mamá with the bebé small on the far pavement (enfrente)
      gente['mama'] = _person('enfrente');
      bebe = {'con': 'mama', 'est': 'idle', 'dy': 0};
      frog = 'esquina';
    } else if (has('cemento')) {
      // story 50: the obrero at the lane with his paddle, Luis on the near pavement, the frog by the wet square, the
      // three cones round it (esquina-preview.html moment 7)
      gente['obrero'] = _person('obrero.paleta')
        ..['pose'] = 'paleta_roja'
        ..['dir'] = -1;
      gente['luis'] = _person('acera6');
      for (final c in _p.group('conos')) {
        cosas.add(_cosa(c, 'cono', c, v: 0));
      }
      frog = 'coqui.cerca';
    } else {
      frog = 'esquina';
    }
    final q = _frogAt(_p.at(frog));
    return {
      'hora': 'manana',
      'obra': 0,
      'puerta': 'shut',
      'luz': 'verde',
      'gente': gente,
      'autos': <String, dynamic>{},
      'cosas': cosas,
      'bebe': bebe,
      'flores': null,
      'dadas': <dynamic>[],
      'globos': null,
      'vuela': null,
      'cemento': null,
      'huellas': null,
      'banderas': 0,
      'bandera': null,
      'grupo': 0,
      'carriles': <String, dynamic>{},
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

  // the sheet's setKey: "hora + obra + puerta", e.g. "manana-0-shut"
  @override
  String setKey(Map<String, dynamic> W) {
    final hora = W['hora'] == 'tarde' ? 'tarde' : 'manana';
    final obra = jsTruthy(W['obra']) && W['obra'] != '0' ? 1 : 0;
    return '$hora-$obra-${W['puerta'] == 'open' ? 'open' : 'shut'}';
  }

  @override
  void buildSet(PpEngine e, PpBuild b, Map<String, dynamic> W) =>
      buildSetFor(e, b, setKey(W));

  final Map<PpEngine, EsquinaSet> _sets = {};

  @override
  void buildSetFor(PpEngine e, PpBuild b, String key) =>
      (_sets[e] ??= EsquinaSet(e, b)).buildSet(EsquinaState.fromKey(key));

  // the frog casts his shadow in the engine (shadows.byCharacter.coqui); never the old one
  @override
  bool get frogShadow => false;

  bool get _tarde => W['hora'] == 'tarde';

  /* ---------- where everybody is ---------- */

  Map<String, dynamic> get _gente => W['gente'] as Map<String, dynamic>;
  Map<String, dynamic> get _autos => W['autos'] as Map<String, dynamic>;
  List<Map<String, dynamic>> get _items =>
      (W['cosas'] as List).cast<Map<String, dynamic>>();

  Map<String, dynamic> _g(String id) =>
      (_gente[id] ??= _person('vuelta', vis: 0)) as Map<String, dynamic>;

  bool _seen(String id) {
    final p = _gente[id] as Map<String, dynamic>?;
    return p != null && p['vis'] != 0;
  }

  Map<String, dynamic>? _item(String id) {
    for (final o in _items) {
      if (o['id'] == id) return o;
    }
    return null;
  }

  EsquinaAt _atOf(Map<String, dynamic> o) =>
      _p.atWorld(o['x'] as num, o['y'] as num, o['z'] as num);

  // the frog's world point under his feet
  EsquinaAt _frogPoint(Map<String, dynamic> q) {
    final b = host.frogBox(q);
    return _p.fromScreen(b.x + b.w / 2, (q['y'] as num) + 25, 0);
  }

  /* ---------- sprites ---------- */

  static final Map<String, Sprite> _sprites = {};
  static Sprite _spr(String key, Sprite Function() make) =>
      _sprites[key] ??= make();

  // a person's sprite and the point of it that stands on the spot (rules.anchor)
  ({Sprite s, int ax, int ay, String key}) _personSprite(
    String id,
    Map<String, dynamic> p,
    bool open,
  ) {
    final pose = (p['pose'] as String?) ?? 'idle';
    final bebe = W['bebe'] as Map<String, dynamic>?;
    final carries = bebe != null && bebe['con'] == id;
    final escoba = id == 'pepe' && jsTruthy(p['escoba']);
    final bici = jsTruthy(p['bici']);
    final flores = carries ? _n(W['flores']) : 0;
    final globos = carries && (W['globos'] as Map?)?['con'] == 'bebe'
        ? _n((W['globos'] as Map)['n'])
        : 0;
    final est = carries ? (bebe['est'] as String? ?? 'idle') : '';
    final ff = carries && (F >> 2) % 2 == 1;
    final key =
        'p$id$pose$open$carries$escoba$bici$flores$globos$est${est == 'clap' ? ff : ''}';
    if (id == 'luis' && pose == 'rodillas') {
      final s = _spr(key, () => mkLuisRodillas(open: open));
      return (s: s, ax: PX, ay: inkBottom(s), key: key);
    }
    final a = callePerson(id, pose, open: open);
    var s = a.s;
    if (escoba || carries || bici) {
      s = _spr(key, () {
        var x = a.s;
        if (escoba) x = mkPepeEscoba(pose, open: open);
        if (bici) {
          x = mkBiciEmpujada(null, person: a.s);
        }
        if (carries) {
          x = conBebe(
            x,
            id == 'abuela',
            flores: flores,
            globos: globos,
            est: est,
            f: ff,
          );
        }
        return x;
      });
    }
    // a sprite grown upward (the balloons over the bebé) keeps its feet: the anchor row is its bottom; the obrero
    // sitting on his bucket: his hips' row, 38, on the spot (rules.anchor)
    final ax = id == 'abuela' ? 30 : PX;
    final sits =
        id == 'obrero' &&
        (pose == 'sentado' || pose == 'bebe' || pose == 'banderas_sentado');
    return (s: s, ax: ax, ay: sits ? 38 : inkBottom(s), key: key);
  }

  // the sprite of a small thing
  Sprite _thingSprite(Map<String, dynamic> o) {
    final k = o['k'] as String, v = o['v'];
    switch (k) {
      case 'cono':
        return _spr('cono$v', () => mkCono(_n(v) == 1));
      case 'cubo':
        return _spr('cubo', mkCubo);
      case 'rastro':
        return _spr('rastro', mkRastro);
      case 'huella':
        return _spr('huella', mkHuella);
      case 'mano':
        return _spr('manoc', mkManoCemento);
      case 'corazon':
        return _spr('corazon', mkCorazonCemento);
    }
    return _spr('flor0', () => mkFlor(0));
  }

  // the vehicle sprite of a thing that drives (`carro` red or blue, `guagua`), in its look and the hour's light
  VehicleSprite _autoSprite(Map<String, dynamic> v) {
    final kind = v['kind'] as String, heading = v['heading'] as String;
    final look = (v['look'] as String?) ?? '';
    final cara = v['cara'] as String?;
    VehicleSprite s;
    if (cara != null) {
      final f = _faceOf(cara);
      s = vehicleWithFace(kind, heading, cara, f.s, f.ax, f.bottom);
    } else {
      s = vehicleSprite(kind, heading, look: look);
    }
    return _tarde ? litVehicle(s, TARDE_M, TARDE_A) : s;
  }

  // a stranger's face at a window: the head and shoulders of the person's sprite (its top 24 rows), its middle column
  static ({Sprite s, int ax, int bottom}) _faceOf(String who) {
    final a = callePerson(who, 'idle');
    return (s: a.s, ax: a.ax, bottom: 24);
  }

  // the bicycle with its rider, as a sprite that stands on its place (facing right; mirrored heading `i`)
  Sprite _biciSprite(Map<String, dynamic> v, bool open) {
    final quien = (v['quien'] as String?) ?? 'senor';
    final i = v['heading'] == 'i';
    return _spr('bici$quien$i$open', () {
      final Sprite s;
      if (quien == 'senor' || quien == 'senora') {
        s = mkCiclista(
          null,
          person: mkPersona(bancoWho(quien), 'idle', open, true),
        );
      } else if (quien == 'pepe') {
        s = mkCiclista(PEPE, open: open);
      } else {
        s = mkCiclista(calleWho(quien), open: open);
      }
      return i ? mirrorSprite(s) : s;
    });
  }

  // where a held thing is drawn: beside the frog (his balloons), at a hand
  ({num x, num y, double d, num sy})? _frogHand() {
    final q = W['cq'] as Map<String, dynamic>;
    if (!jsTruthy(q['vis'])) return null;
    final b = host.frogBox(q), at = _frogPoint(q);
    return (x: b.x - 2, y: (q['y'] as num) + 20, d: at.d + .05, sy: at.sy);
  }

  /// Every sprite of the frame [w] but the frog and the vehicles, placed: the people, the bicycles, the small things.
  /// The rules' tests read it; [draw] draws it.
  List<EsquinaItem> items(Map<String, dynamic> w, int a) {
    final out = <EsquinaItem>[];
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
        EsquinaItem(
          s,
          sx - ax,
          sy - sp.ay,
          sy,
          at.d,
          tag: 'persona:${en.key}',
          grown: en.key != 'luis' && en.key != 'carmen',
        ),
      );
    }
    final autos = (w['autos'] as Map<String, dynamic>?) ?? const {};
    for (final en in autos.entries) {
      final v = en.value as Map<String, dynamic>;
      if (v['vis'] == 0 || v['kind'] != 'bici') continue;
      final s = _biciSprite(v, talk == v['quien'] && a % 2 == 1);
      final at = _p.atWorld(v['x'] as num, v['y'] as num, 0);
      final sx = _round(at.sx) + _n(v['dx']), sy = _round(at.sy);
      out.add(
        EsquinaItem(
          s,
          sx - s.w ~/ 2,
          sy - inkBottom(s),
          sy,
          at.d,
          tag: 'auto:${en.key}',
        ),
      );
    }
    for (final o
        in (w['cosas'] as List? ?? const []).cast<Map<String, dynamic>>()) {
      if (o['vis'] == 0) continue;
      final s = _thingSprite(o);
      final at = _atOf(o);
      final sx = _round(at.sx), sy = _round(at.sy);
      final flat = o['k'] != 'cono' && o['k'] != 'cubo';
      out.add(
        EsquinaItem(
          s,
          sx - s.w ~/ 2,
          flat ? sy - s.h ~/ 2 : sy - inkBottom(s),
          flat ? sy + s.h ~/ 2 : sy,
          at.d,
          tag: 'cosa:${o['id']}',
        ),
      );
    }
    // the frog's balloons, at his hand
    final gl = w['globos'] as Map<String, dynamic>?;
    if (gl != null && gl['con'] == 'coqui' && _n(gl['n']) > 0) {
      final h = _frogHand();
      if (h != null) {
        final s = _spr('globos${gl['n']}', () => mkGlobos(_n(gl['n'])));
        out.add(
          EsquinaItem(
            s,
            _round(h.x) - s.w ~/ 2,
            _round(h.y) - s.h,
            h.sy,
            h.d,
            tag: 'globos',
          ),
        );
      }
    }
    return out;
  }

  /// Every vehicle of the frame [w] (the cars and the guaguas), placed.
  List<EsquinaAuto> autos(Map<String, dynamic> w) {
    final out = <EsquinaAuto>[];
    final autos = (w['autos'] as Map<String, dynamic>?) ?? const {};
    for (final en in autos.entries) {
      final v = en.value as Map<String, dynamic>;
      if (v['vis'] == 0 || v['kind'] == 'bici') continue;
      final s = _autoSprite(v);
      final at = placeVehicle(_p.e, s, v['x'] as num, v['y'] as num);
      out.add(
        EsquinaAuto(
          s,
          at.left + _n(v['dx']),
          at.top,
          at.d,
          'auto:${en.key}',
          v['kind'] as String,
        ),
      );
    }
    return out;
  }

  static final Map<String, Sprite> _mirrored = {};
  static Sprite _mirrorOf(String key, Sprite s) =>
      _mirrored[key] ??= mirrorSprite(s);

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

  @override
  void setFramed(PpEngine engine, BakedSet baked, Map<String, dynamic> W) {
    _frameEngine = engine;
    _setZ = baked.zb;
  }

  static final double _t30 = math.tan(math.pi / 6);

  /// Composes [it] into a layer ([layer], depths [lz], vehicles' marks [isV]) by the sheet's rule: hidden where [setZ]
  /// is nearer than its plane plus [bias], or a vehicle's pixel is (the same rule), or another sprite's pixel is
  /// nearer than its plane. Returns how many of its pixels it drew.
  static int put(
    EsquinaItem it,
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
        // the frog is never behind a grown-up, a car or a guagua (the sheet's rule): their pixels do not hide his
        if (!(it.tag == 'coqui' && isV[i] != 0) &&
            !personOver(i, plane, bias, lz, isV)) {
          hidden?.call(i, isV[i] == 1 ? 'auto' : 'sprite');
          continue;
        }
        lz[i] = plane;
        layer[i] = c;
        isV[i] = it.grown ? 2 : 0;
        n++;
      }
    }
    return n;
  }

  /// The frog as the game draws him (juego.js frog, at the depth of his feet), placed; null when he is not seen.
  EsquinaItem? frogItem(Map<String, dynamic> W, int a) {
    final q = W['cq'] as Map<String, dynamic>;
    if (!jsTruthy(q['vis'])) return null;
    final b = host.frogBox(q), at = _frogPoint(q);
    final ox = b.x.toInt() - 16, oy = b.y.toInt() - 24;
    final px = Uint32List(64 * 64);
    final g = Ctx(px, 64, 64)..translate(-ox.toDouble(), -oy.toDouble());
    host.frog(g, q, a);
    return EsquinaItem(
      Sprite(64, 64, px),
      ox,
      oy,
      _round(at.sy),
      at.d,
      tag: 'coqui',
    );
  }

  /// [items] and the frog: every sprite that stands, placed.
  List<EsquinaItem> placed(Map<String, dynamic> W, int a) {
    final all = items(W, a);
    final f = frogItem(W, a);
    if (f != null) all.add(f);
    return all;
  }

  // the lit lamp of the traffic light (the sheet's lamps: lamps.1 red, lamps.3 green): its pixels with the lamp's depth
  void _lamp(Map<String, dynamic> W) {
    final luz = W['luz'] as String?;
    if (luz == null) return;
    final at = _p.at(luz == 'roja' ? 'lamps.1' : 'lamps.3');
    final s = _spr('lampara$luz', () => mkLampara(luz));
    final x0 = _round(at.sx) - s.w ~/ 2, y0 = _round(at.sy) - s.h ~/ 2;
    for (var y = 0; y < s.h; y++) {
      for (var x = 0; x < s.w; x++) {
        final c = s.px[y * s.w + x];
        if (c >>> 24 == 0) continue;
        final X = x0 + x, Y = y0 + y;
        if (X < 0 || Y < 0 || X >= 240 || Y >= 216) continue;
        final i = Y * 240 + X;
        if (_lz[i] > at.d + .2) continue;
        _layer[i] = c;
        _lz[i] = at.d + .2;
        _isV[i] = 0;
      }
    }
  }

  /// Composes the whole sprite layer of [W] into [layer] ([lz], [isV]): the vehicles, the lit lamp, then every sprite
  /// that stands, the frog with them. The rules' tests call it with a [hidden] that counts what hides what.
  void compose(
    Map<String, dynamic> W,
    int a,
    Uint32List layer,
    Float32List lz,
    Uint8List isV,
    Float32List? setZ, {
    void Function(EsquinaItem it, int i, String why)? hidden,
  }) {
    layer.fillRange(0, layer.length, 0);
    lz.fillRange(0, lz.length, -1e9);
    isV.fillRange(0, isV.length, 0);
    for (final v in autos(W)) {
      putVehicle(v.v, v.left, v.top, v.d, layer, lz, isV, setZ);
    }
    if (identical(layer, _layer)) _lamp(W);
    final bias = _p.bias, S = _p.e.S;
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

  // what is drawn over everything: a balloon flying off, the frog's flags, a flower on its way
  void _over(Ctx c, Map<String, dynamic> W, int a) {
    final v = W['vuela'] as Map<String, dynamic>?;
    if (v != null) {
      final s = _spr('globos1', () => mkGlobos(1));
      c.drawImage(s, _round((v['x'] as num) - s.w / 2), _round(v['y'] as num));
    }
    final fl = W['florVa'] as Map<String, dynamic>?;
    if (fl != null) {
      final s = _spr('flor0', () => mkFlor(0));
      c.drawImage(
        s,
        _round((fl['x'] as num) - s.w / 2),
        _round(fl['y'] as num),
      );
    }
    final q = W['cq'] as Map<String, dynamic>;
    if (_n(W['banderas']) == 1 && jsTruthy(q['vis'])) {
      final b = host.frogBox(q);
      final bd = W['bandera'] as Map<String, dynamic>?;
      // the green flag on the side of the one that goes, the red on the other (or both held down at his sides)
      var verdeDer = true;
      if (bd != null) {
        final t = _autoBox(W, bd['verde'] as String?);
        if (t != null) verdeDer = t[0] + t[2] / 2 > b.x + b.w / 2;
      }
      final up = bd != null ? 6 : 0;
      final gv = _spr('bandera_verde', () => mkBandera('verde')),
          rj = _spr('bandera_roja', () => mkBandera('roja'));
      final xl = b.x - 6, xr = b.x + b.w - 3, y = (q['y'] as num) + 8;
      c.drawImage(verdeDer ? rj : gv, _round(xl), _round(y - up));
      c.drawImage(verdeDer ? gv : rj, _round(xr), _round(y - up));
    }
  }

  /* ---------- the cards: the flowers of story 48, the two rounds ---------- */

  @override
  void hud(Ctx c, Map<String, dynamic> W, int a) {
    var x0 = 3;
    if (W['flores'] != null) {
      // three flowers, each under a small face: mamá, papá, Luis (esquina.md 48: "the card shows the three flowers,
      // each under a small face"); a flower given away is gone from the last face first
      final n = _n(W['flores']);
      const w = 6 + 3 * 18;
      tarjeta(c, x0, 3, w, 30);
      for (var i = 0; i < 3; i++) {
        final id = const ['mama', 'papa', 'luis'][i];
        final head = _spr('cara$id', () => _cara(id));
        final x = x0 + 4 + i * 18;
        c.drawImage(head, x, 4);
        if (i < n) {
          final f = _spr('flor$i', () => mkFlor(i));
          c.drawImage(f, x + 5, 18);
        }
      }
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

  // a small face for the card: the top 14 rows of the person's sprite, its middle 16 columns
  static Sprite _cara(String id) {
    final s = callePerson(id, 'idle').s;
    const w = 16, h = 14;
    final px = Uint32List(w * h);
    final top = id == 'luis' ? 0 : 2;
    for (var y = 0; y < h; y++) {
      for (var x = 0; x < w; x++) {
        final sx = PX - 8 + x, sy = top + y;
        if (sy < s.h) px[y * w + x] = s.px[sy * s.w + sx];
      }
    }
    return Sprite(w, h, px);
  }

  /* ---------- the shadows (sheet: shadows) ---------- */

  // castShadow(x, y, 0, radius) at the world x, y of whoever stands on the ground (shadows.at; none sitting on the bucket
  // or kneeling: shadows.none, onBucket), the cones' (.16), and the casts of each vehicle (calle-base.js vehicle)
  @override
  List<ShadowCast> shadows(Map<String, dynamic> W) {
    final out = <ShadowCast>[];
    void cast(EsquinaAt at, double? r) {
      if (r == null || at.z != 0) return;
      out.add((x: at.x, y: at.y, z: 0, r: r));
    }

    final gente = (W['gente'] as Map<String, dynamic>?) ?? const {};
    for (final en in gente.entries) {
      final p = en.value as Map<String, dynamic>;
      if (p['vis'] == 0) continue;
      final pose = p['pose'] as String? ?? '';
      if (pose == 'sentado' ||
          pose == 'bebe' ||
          pose == 'banderas_sentado' ||
          pose == 'rodillas') {
        continue;
      }
      if (_p.noShadow((p['spot'] as String?) ?? '')) continue;
      cast(_atOf(p), _p.radius(en.key));
    }
    for (final o
        in (W['cosas'] as List? ?? const []).cast<Map<String, dynamic>>()) {
      if (o['vis'] == 0 || o['k'] != 'cono') continue;
      cast(_atOf(o), _p.radius('cono'));
    }
    final q = W['cq'] as Map<String, dynamic>?;
    if (q != null && jsTruthy(q['vis'])) {
      cast(_frogPoint(q), _p.radius('coqui'));
    }
    final autos = (W['autos'] as Map<String, dynamic>?) ?? const {};
    for (final v in autos.values) {
      final m = v as Map<String, dynamic>;
      if (m['vis'] == 0 || m['kind'] == 'bici') continue;
      out.addAll(
        vehicleShadows(m['kind'] as String, m['x'] as num, m['y'] as num),
      );
    }
    return out;
  }

  /* ---------- the things he can touch ---------- */

  // the screen box of a sprite: its drawn pixels' bounds
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

  // the boxes of the frame now (one list of placed sprites a frame: the signs ask for boxes many times a frame)
  int? _boxesF;
  Map<String, dynamic>? _boxesW;
  Map<String, List<num>?> _boxes = {};

  Map<String, List<num>?> _allBoxes(Map<String, dynamic> w) {
    final its = items(w, 0);
    final out = <String, List<num>?>{
      for (final it in its)
        if (it.tag != null) it.tag!: inkBox(it.s, it.left, it.top),
      for (final v in autos(w)) v.tag: inkBox(v.v.s, v.left, v.top),
    };
    out['bebe'] = _bebeOf(w, its);
    out['gente'] = _genteOf(w, out);
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
    if (f != _boxesF || !identical(w, _boxesW)) {
      _boxes = _allBoxes(w);
      _boxesF = f;
      _boxesW = w;
    }
    return _boxes[tag];
  }

  List<num>? _autoBox(Map<String, dynamic> w, String? k) =>
      k == null ? null : _boxOfTag(w, 'auto:$k');

  // the bebé's box: where his sprite sits over his carrier's (conBebe: abuela's at (14, 14), a persona's at (10, 14), the
  // sprite grown upward by what he holds up)
  List<num>? _bebeOf(Map<String, dynamic> w, List<EsquinaItem> its) {
    final bebe = w['bebe'] as Map<String, dynamic>?;
    if (bebe == null) return null;
    final con = bebe['con'] as String;
    for (final it in its) {
      if (it.tag != 'persona:$con') continue;
      final p =
          (w['gente'] as Map<String, dynamic>)[con] as Map<String, dynamic>;
      final base = callePerson(con, (p['pose'] as String?) ?? 'idle').s;
      final grown = it.s.h - base.h;
      final bx = con == 'abuela' ? 14 : 10;
      final x = _n(p['dir']) < 0 ? it.s.w - bx - 26 : bx;
      return [it.left + x + 2, it.top + grown + 14, 22, 26];
    }
    return null;
  }

  List<num>? _bebeBox(Map<String, dynamic> w) => _boxOfTag(w, 'bebe');

  // the group at the kerb (the sheet's things.gente: the people at the grupo's and bordillo's spots), while it is there
  List<num>? _genteOf(Map<String, dynamic> w, Map<String, List<num>?> boxes) {
    if (_n(w['grupo']) != 1) return null;
    List<num>? u;
    final g = (w['gente'] as Map<String, dynamic>?) ?? const {};
    final grupo = _p.group('grupo');
    for (final e in g.entries) {
      final p = e.value as Map<String, dynamic>;
      if (p['vis'] == 0 || !grupo.contains(p['spot'])) continue;
      final b = boxes['persona:${e.key}'];
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

  List<num>? _genteBox(Map<String, dynamic> w) => _boxOfTag(w, 'gente');

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
      // the bicycle, small, over the street
      sprite('bicicleta', (w) => _boxOfTag(w, 'auto:bicicleta'), z: true),
      // the group at the kerb, while it stands there (49 step 2): over its own people
      sprite('gente', _genteBox, m: 1, z: true),
      // the bebé, over his carrier
      sprite('bebe', _bebeBox, m: 1, z: true),
      // the people (names: the free poke)
      for (final id in _people)
        sprite(id, (w) => _boxOfTag(w, 'persona:$id'), m: 1),
      // the things that drive: a car (red or blue) and the guagua
      sprite('carro', (w) => _boxOfTag(w, 'auto:carro')),
      sprite('guagua', (w) => _boxOfTag(w, 'auto:guagua')),
      sprite(
        'azul',
        (w) => ((w['autos'] as Map?)?['carro'] as Map?)?['kind'] == 'azul'
            ? _boxOfTag(w, 'auto:carro')
            : null,
      ),
      // the set's things (sheet: things.<id>.box), the small ones first
      setThing('boton'),
      setThing('puerta'),
      setThing('cemento', si: (w) => jsTruthy(w['obra']) && w['obra'] != '0'),
      setThing('esquina'),
      setThing('colmado'),
      setThing('calle'),
    ];
  }

  /* ---------- talking ---------- */

  // the point over a speaker's head: its sprite's top; a stranger at a vehicle's window: the window's top
  @override
  List<num>? talkAt(String who, Map<String, dynamic> W) {
    final autos = (W['autos'] as Map<String, dynamic>?) ?? const {};
    for (final en in autos.entries) {
      final v = en.value as Map<String, dynamic>;
      if (v['vis'] == 0) continue;
      if (v['cara'] == who) {
        final b = _boxOfTag(W, 'auto:${en.key}');
        if (b != null) return [_round(b[0] + b[2] / 2), b[1] - 1];
      }
      if (v['kind'] == 'bici' && v['quien'] == who) {
        final b = _boxOfTag(W, 'auto:${en.key}');
        if (b != null) return [_round(b[0] + b[2] / 2), b[1] - 1];
      }
    }
    for (final it in items(W, 0)) {
      if (it.tag != 'persona:$who') continue;
      final b = inkBox(it.s, it.left, it.top);
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
          '${e.key}:${(e.value as Map)['kind']}@${(e.value as Map)['spot']}',
    ].join(' ');
    return 'luz=${W['luz']} gente=$gente autos=$autos flores=${W['flores']} globos=${(W['globos'] as Map?)?['n']} cemento=${W['cemento']}';
  }

  /* ---------- moving ---------- */

  // a walk: a straight line at a steady pace, about 5 px of the picture a tick
  Future<void> _anda(String id, String spot) async {
    final w = _p.world(spot);
    await _andaA(id, w[0], w[1], w[2]);
    _g(id)['spot'] = spot;
  }

  Future<void> _andaA(String id, num x, num y, num z) async {
    final p = _g(id);
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
      final n = math.max(1, (dist / 5).ceil());
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
      ..['dy'] = 0;
    return p;
  }

  // the frog hops to a spot (the kit's hopTo: a hop about every 30 px)
  Future<void> _salta(String spot) async {
    final q = W['cq'] as Map<String, dynamic>;
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

  /* ---------- the things that drive ---------- */

  // the key a story's `k` names: `carro`, `guagua`, `bicicleta`
  static String _key(Object? k) => k == 'guagua'
      ? 'guagua'
      : k == 'bicicleta'
      ? 'bicicleta'
      : 'carro';

  // the spot's own word for a kind: carro, guagua, bici
  static String _spotKind(String key) => key == 'bicicleta' ? 'bici' : key;

  // the lane nearest a world y (`routes.trafico.lanes`)
  ({List<double> entra, List<double> sale}) _laneAt(num y) {
    final c = _p.lanes['cerca']!, l = _p.lanes['lejos']!;
    return (y - c.entra[1]).abs() <= (y - l.entra[1]).abs() ? c : l;
  }

  // where a `llega` stops: the sheet's spot for that thing there, or null (it drives through)
  String? _stopFor(String key, Map<String, dynamic> o) {
    final a = o['a'] as String?;
    final sk = _spotKind(key);
    if (a == null) {
      if (_stops[_llegaKey(o)] != true) return null;
      if (key == 'bicicleta') {
        // OPEN: a bicycle that comes along and stops to be touched (48 step 4, 49 step 3) has no spot in the sheet but
        // story 50's two ends of the lane; it stops at carril_b.bici ("a bicycle's middle, heading to -x"), the one
        // bicycle spot in the near lane heading the way the traffic goes
        return 'carril_b.bici';
      }
      // story 48 steps 2 and 3: where the car and the guagua stop in story 48 (para48_carro, para48_guagua)
      return 'para48_$sk';
    }
    if (a == 'parada1' || a == 'parada2') {
      // OPEN: story 48's game draws which of the two stands in front (`parada1`) and which behind (`parada2`); the
      // sheet names one place for each thing (para48_carro in front, para48_guagua behind it). Each stops at its own:
      // the car is always in front
      return 'para48_$sk';
    }
    if (a == 'carril_a' || a == 'carril_b') {
      final ends = W['carriles'] as Map<String, dynamic>;
      var end = a;
      // OPEN: the guagua never waits at carril_a (the sheet: "the guagua never waits here"), but story 50's game deals
      // it to either end; the guagua waits at carril_b and the other thing takes carril_a (the touch is by the thing,
      // so the story plays the same)
      if (key == 'guagua' && end == 'carril_a') end = 'carril_b';
      final taken = ends[end];
      if (taken != null && taken != key && _seenAuto(taken as String)) {
        end = end == 'carril_a' ? 'carril_b' : 'carril_a';
      }
      ends[end] = key;
      return '$end.$sk';
    }
    if (a == 'acera') {
      // story 48's ending: Luis with his bicycle on the near pavement (acera4: "Luis with his bicycle")
      return 'acera4';
    }
    return _p.has(a) ? a : null;
  }

  bool _seenAuto(String key) {
    final v = _autos[key] as Map<String, dynamic>?;
    return v != null && v['vis'] != 0;
  }

  // `llega` {k, color, de, a, quien}: a thing that drives comes along the street and stops at a spot, or drives through
  Future<void> _llega(Map<String, dynamic> o) async {
    final key = _key(o['k']);
    final stop = _stopFor(key, o);
    final kind = key == 'bicicleta'
        ? 'bici'
        : key == 'guagua'
        ? 'guagua'
        : (o['color'] == 'azul' ? 'azul' : 'carro');
    // OPEN: story 48 step 3 has the guagua come "from the left" (`de: izq`) while the blue car goes by the other way;
    // the sheet's routes (routes.trafico) have every thing enter at the right and leave at the left: both come from the
    // right, the blue car by the far lane
    final List<double> to;
    String heading;
    double startX;
    ({List<double> entra, List<double> sale}) lane;
    if (stop != null) {
      to = _p.world(stop);
      lane = _laneAt(to[1]);
      // a thing that waits at the lane's left end (carril_a) has come from the left, heading +x
      heading = stop.startsWith('carril_a') ? 'd' : 'i';
      startX = heading == 'd' ? lane.sale[0] : lane.entra[0];
    } else {
      lane = _p.lanes['lejos']!;
      to = lane.sale;
      heading = 'i';
      startX = lane.entra[0];
    }
    final quien = key == 'bicicleta'
        ? ((o['quien'] as String?) ??
              // OPEN: story 49 step 3's bicycle has no rider named (the señor and Luis are in the group at the
              // kerb): papá rides it, the one grown-up of the family not in that story
              'papa')
        : null;
    final v = <String, dynamic>{
      'k': key,
      'kind': kind,
      'heading': heading,
      'look': '',
      'x': startX,
      'y': (stop == 'acera4' ? lane.entra[1] : to[1]),
      'vis': 1,
      'spot': stop,
      'quien': quien,
      'cara': null,
      'dx': 0,
    };
    _autos[key] = v;
    // story 50: the obrero lifts his paddle, its red side, for a thing that comes up to the lane
    final ob = _gente['obrero'] as Map<String, dynamic>?;
    if (ob != null && ob['vis'] != 0 && ob['spot'] != 'obrero.cubo') {
      final pose = ob['pose'] as String;
      if (pose.startsWith('paleta') || pose == 'idle') {
        ob['pose'] = 'paleta_roja';
      }
    }
    if (stop == 'acera4') {
      // story 48's ending: Luis rides along the near lane to beside the pavement, gets off and pushes his bicycle up
      await drive(v, to[0], _tick);
      v['vis'] = 0;
      final l = _aparece('luis', 'acera4')..['bici'] = 1;
      l['dir'] = -1;
      host.SFX.blip();
      await _tick();
      return;
    }
    await drive(v, to[0], _tick, stop: stop != null);
    if (stop == null) {
      v['vis'] = 0;
      return;
    }
    if (key == 'bicicleta') {
      _bell();
    }
  }

  // `sigue` {k}: it drives on and out of the picture, the way it heads, in its lane
  Future<void> _sigue(Map<String, dynamic> o) async {
    final key = _key(o['k']);
    final v = _autos[key] as Map<String, dynamic>?;
    if (v == null || v['vis'] == 0) return;
    final lane = _laneAt(v['y'] as num);
    v['look'] = '';
    v['dx'] = 0;
    final to = v['heading'] == 'd' ? lane.entra[0] : lane.sale[0];
    await drive(v, to, _tick, stop: false);
    v
      ..['vis'] = 0
      ..['cara'] = null;
    final ends = W['carriles'] as Map<String, dynamic>;
    ends.removeWhere((_, k) => k == key);
  }

  void _honk() {
    host.tone(392, 0, .16, 'square', .05);
  }

  void _bell() {
    host.tone(2093, 0, .12, 'sine', .07);
    host.tone(2637, .12, .2, 'sine', .06);
  }

  void _hiss() {
    host.tone(900, 0, .3, 'sawtooth', .015, 300);
  }

  // `luz` {roja}: the frog presses the button on the pole; the light turns red and whatever drives stops at the stripes
  // (the sheet: "in story 49 it stops at the stop line at alto_carro and alto_guagua": the blue car and a guagua, in the
  // near lane); or back to green, and the traffic drives on
  Future<void> _luz(Map<String, dynamic> o) async {
    if (_n(o['roja']) == 1) {
      if (W['luz'] == 'roja') return;
      final q = W['cq'] as Map<String, dynamic>;
      final was = [q['x'], q['y']];
      final atCorner =
          was[0] == LUGAR['esquina']![0] && was[1] == LUGAR['esquina']![1];
      await _salta('boton_coqui');
      host.bounce(4);
      host.SFX.blip();
      await wait(TICK * 3);
      W['luz'] = 'roja';
      host.tone(660, 0, .12, 'square', .04);
      if (atCorner) await _salta('esquina');
      final cerca = _p.lanes['cerca']!;
      final stops = <Future<void>>[];
      for (final (key, kind, spot) in const [
        ('carro', 'azul', 'alto_carro'),
        ('guagua', 'guagua', 'alto_guagua'),
      ]) {
        if (_seenAuto(key)) continue;
        final to = _p.world(spot);
        final v = <String, dynamic>{
          'k': key,
          'kind': kind,
          'heading': 'i',
          'look': '',
          'x': cerca.entra[0],
          'y': to[1],
          'vis': 1,
          'spot': spot,
          'quien': null,
          'cara': null,
          'dx': 0,
        };
        _autos[key] = v;
        stops.add(drive(v, to[0], _tick));
        await wait(TICK * 4);
      }
      await Future.wait(stops);
      return;
    }
    if (W['luz'] == 'verde') return;
    W['luz'] = 'verde';
    host.tone(880, 0, .12, 'square', .04);
    await wait(TICK * 2);
    final goes = <Future<void>>[];
    for (final key in const ['carro', 'guagua']) {
      final v = _autos[key] as Map<String, dynamic>?;
      if (v == null || v['vis'] == 0) continue;
      if (!(v['spot'] as String? ?? '').startsWith('alto_')) continue;
      goes.add(_sigue({'k': key}));
      await wait(TICK * 3);
    }
    await Future.wait(goes);
  }

  /* ---------- story 49: the people at the corner ---------- */

  // who crossed and stands on the near pavement leaves it (vanishes) when the place is needed again
  void _despeja(String spot, {String? keep}) {
    for (final e in _gente.entries) {
      final p = e.value as Map<String, dynamic>;
      if (p['vis'] == 0 || e.key == keep || e.key == 'mama') continue;
      if (p['spot'] == spot) p['vis'] = 0;
    }
  }

  // `cruza` {quien}: one crosses the street and waves from the far side (cruce_fin)
  Future<void> _cruza(String quien) async {
    W['grupo'] = 0;
    final p = _g(quien);
    if (quien == 'abuela' && p['vis'] == 0) {
      // the ending of 49: abuela comes out of the colmado with her bag
      // OPEN: abuela comes out at `puerta` while don Pepe stands at `pepe.puerta`, the same place ("never in the same
      // picture"): he goes in
      final pepe = _gente['pepe'] as Map<String, dynamic>?;
      if (pepe != null) pepe['vis'] = 0;
      W['puerta'] = 'open';
      _campana();
      _aparece('abuela', 'puerta');
      await wait(TICK * 3);
      W['puerta'] = 'shut';
    }
    if (p['vis'] == 0) _aparece(quien, 'bordillo1');
    // where the one who crossed ends: cruce_fin; a second one at the same time (49 step 4: the señora and Carmen)
    var to = 'cruce_fin';
    final otro = _gente.entries.any(
      (e) =>
          e.key != quien &&
          (e.value as Map)['vis'] != 0 &&
          ((e.value as Map)['spot'] == 'cruce_fin' ||
              (e.value as Map)['spot'] == 'acera2' ||
              (e.value as Map)['va'] == 'cruce_fin'),
    );
    if (otro) {
      if (quien == 'abuela') {
        _despeja('cruce_fin', keep: quien);
        _despeja('acera2', keep: quien);
        _despeja('acera3', keep: quien);
      } else {
        // OPEN: the sheet names one place for whoever crossed (cruce_fin); a second one crossing with her stops at the
        // next place of the near pavement's back row, acera3
        to = 'acera3';
      }
    }
    p['va'] = to;
    p['pose'] = 'idle';
    // OPEN: the way over the stripes has no named points: the walk is a straight line from the kerb to the far place
    await _anda(quien, to);
    p['va'] = null;
    p['dir'] = 1;
    for (var i = 0; i < 4; i++) {
      p['pose'] = i % 2 == 0 ? 'saluda0' : 'saluda1';
      await _tick();
    }
    p['pose'] = 'idle';
  }

  // `pasa` {quien}: one walks on round the corner, past the colmado (to `vuelta`, by the corner: boton_coqui, the pole's
  // foot on the colmado's pavement, then up the side wall), and is gone
  Future<void> _pasa(String quien) async {
    W['grupo'] = 0;
    final p = _g(quien);
    if (p['vis'] == 0) return;
    p['pose'] = 'idle';
    final b = _p.world('boton_coqui');
    await _andaA(quien, b[0], b[1], b[2]);
    await _anda(quien, 'vuelta');
    p['vis'] = 0;
  }

  void _campana() {
    host.tone(1568, 0, .25, 'sine', .08);
    host.tone(2093, .08, .3, 'sine', .06);
  }

  // `globos` {n}: the balloons in the frog's hand. The first time (49 step 1) abuela comes out of the colmado at its
  // door and puts the strings in his hand; she stays at the door until the people come (`gente viene`)
  Future<void> _globos(int n) async {
    final gl = W['globos'] as Map<String, dynamic>?;
    if (gl == null) {
      W['puerta'] = 'open';
      _campana();
      final ab = _aparece('abuela', 'puerta')..['pose'] = 'mano';
      await wait(TICK * 4);
      W['globos'] = <String, dynamic>{'n': n, 'con': 'coqui'};
      host.SFX.blip();
      await wait(TICK * 2);
      ab['pose'] = 'idle';
      return;
    }
    gl['n'] = n;
    await wait(TICK);
  }

  // the people at the kerb: the group of four in the opening of 49 (the sheet's group grupo: bordillo1, bordillo2,
  // fondo1, fondo2; esquina-preview.html moment 4: the señora, Luis, Carmen, the señor), walking in from the corner
  static const Map<String, String> _grupo = {
    'senora': 'bordillo1',
    'luis': 'bordillo2',
    'carmen': 'fondo1',
    'senor': 'fondo2',
  };

  Future<void> _vienen(Map<String, String> who) async {
    final b = _p.world('boton_coqui');
    final walks = <Future<void>>[];
    var i = 0;
    for (final e in who.entries) {
      final p = _aparece(e.key, 'vuelta')..['pose'] = 'idle';
      p['dir'] = -1;
      walks.add(() async {
        await wait(TICK * 3 * i);
        await _andaA(e.key, b[0], b[1], b[2]);
        await _anda(e.key, e.value);
        _g(e.key)['dir'] = 1;
      }());
      i++;
    }
    await Future.wait(walks);
  }

  /* ---------- story 50: the lane, the obrero, the cement ---------- */

  // the wet square's three parts along x (the sheet's things.cemento world box): part i's middle
  List<double> _parte(int i, {double du = .5, double dv = .5}) {
    final b = _p.worldBox('cemento');
    final w = (b[3] - b[0]) / 3;
    return [b[0] + w * (i + du), b[1] + (b[4] - b[1]) * dv];
  }

  // the order the parts are lost in: the right one, then the left one (one smooth part is left in the middle, "one small
  // frog print between the wheel tracks")
  static const List<int> _perdidas = [2, 0];

  void _marca(String id, String k, List<double> w) {
    _items.removeWhere((o) => o['id'] == id);
    _items.add(<String, dynamic>{
      'id': id,
      'k': k,
      'x': w[0],
      'y': w[1],
      'z': 0.0,
      'spot': 'cemento',
      'vis': 1,
      'v': null,
    });
  }

  void _cementoN(int n) {
    W['cemento'] = n;
    _items.removeWhere((o) => o['k'] == 'rastro');
    for (var i = 0; i < 3 - n && i < _perdidas.length; i++) {
      _marca('rastro$i', 'rastro', _parte(_perdidas[i]));
    }
  }

  /* ---------- the acts (esquina.md, "Needs") ---------- */

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
    // `ya`: waits for the acts that were started with `suelto: 1`
    'ya': (o) async {
      final all = List<Future<void>>.of(_sueltos);
      _sueltos.clear();
      await Future.wait(all);
    },
    // `ir` {a}: the frog hops to one of his places (the kit's hops of about 30 px, 1 to 4), the sheet's frog spots
    'ir': (o) async {
      final a = o['a'], key = jsTruthy(a) ? a : o['en'];
      if (key is! String) return;
      final spot = _frogPlaces[key] ?? (_p.has(key) ? key : null);
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
    // `llega` {k, de, a}: a thing that drives comes along the street and stops at a spot, or drives through (48: 1 to 4,
    // 6, 7; 49: 3; 50: 2, 3, 5, 6)
    'llega': _llega,
    // `sigue` {k}: it drives on and out (the same steps)
    'sigue': _sigue,
    // `bocina` {k}: it honks; the guagua's door hisses open and shut; the bicycle's bell rings (48: 2 to 4; 49: 6, 7)
    'bocina': (o) async {
      final key = _key(o['k']);
      final v = _autos[key] as Map<String, dynamic>?;
      if (key == 'bicicleta') {
        _bell();
        await wait(TICK * 4);
        return;
      }
      if (key == 'guagua' &&
          v != null &&
          v['vis'] != 0 &&
          v['kind'] == 'guagua') {
        _hiss();
        v['look'] = 'puerta';
        await wait(TICK * 5);
        _hiss();
        v['look'] = '';
        await wait(TICK * 2);
        return;
      }
      _honk();
      await wait(TICK * 3);
    },
    // `baja48` {quien, de}: the door opens and mamá or papá gets out (48: 6, 7), on the kerb stone beside it (sale_carro,
    // sale_guagua), and walks to the near pavement (acera3 mamá, acera1 papá: the sheet's words); the frog hops back to
    // his place there (acera5)
    'baja48': (o) async {
      final quien = o['quien'] as String, key = _key(o['de']);
      final v = _autos[key] as Map<String, dynamic>?;
      if (v != null && v['vis'] != 0) {
        v['look'] = 'puerta';
        _hiss();
      }
      await wait(TICK * 3);
      _aparece(quien, 'sale_${_spotKind(key)}')['pose'] = 'idle';
      host.SFX.right();
      await wait(TICK * 2);
      if (v != null) v['look'] = '';
      await Future.wait([
        _anda(quien, quien == 'papa' ? 'acera1' : 'acera3'),
        _salta('acera5'),
      ]);
      _g(quien)['dir'] = 1;
    },
    // `ventanilla` {k, quien}: the window comes down with a stranger's face (48: 6, 7)
    'ventanilla': (o) async {
      final key = _key(o['k']);
      final v = _autos[key] as Map<String, dynamic>?;
      host.SFX.toc();
      await wait(TICK * 3);
      if (v == null || v['vis'] == 0) return;
      v['cara'] = o['quien'];
      host.tone(300, 0, .3, 'sine', .03, 200);
      await wait(TICK * 3);
    },
    // `flor` {a}: the bebé holds a flower out and it is taken (48: 6, 7): it goes from his hand to the stranger's face
    'flor': (o) async {
      final from = _bebeBox(W), to = talkAt(o['a'] as String, W);
      W['flores'] = math.max(0, _n(W['flores']) - 1);
      if (from != null && to != null) {
        final x0 = from[0] + from[2] / 2, y0 = from[1] - 8;
        for (var i = 1; i <= 6; i++) {
          W['florVa'] = {
            'x': x0 + (to[0] - x0) * i / 6,
            'y': y0 + (to[1] + 6 - y0) * i / 6,
          };
          await _tick();
        }
      }
      W['florVa'] = null;
      host.SFX.blip();
      await wait(TICK * 2);
    },
    // `flores` {n}: the flowers in the bebé's hand (and on the card)
    'flores': (o) async {
      W['flores'] = _n(o['n']);
      await wait(TICK);
    },
    // `da48` {n}: the ending for three, two or one left (48: 8)
    'da48': (o) async {
      final n = _n(o['n']);
      final bebe = W['bebe'] as Map<String, dynamic>?;
      if (bebe != null) bebe['est'] = 'clap';
      // three: one to mamá, one to papá, one to Luis (behind his ear); two: mamá and papá, Luis holds out his hand and
      // gets the bebé's; one: mamá, papá gets the bebé's hand on his nose and laughs, Luis shrugs and grins
      final to = const ['mama', 'papa', 'luis'];
      for (var i = 0; i < 3; i++) {
        final p = _gente[to[i]] as Map<String, dynamic>?;
        if (p == null || p['vis'] == 0) continue;
        if (i < n) {
          W['flores'] = n - i - 1;
          p['pose'] = 'mano';
          host.SFX.blip();
          await wait(TICK * 4);
          p['pose'] = 'idle';
        } else {
          p['pose'] = i == 1 ? 'saluda0' : 'mano';
          await wait(TICK * 4);
          p['pose'] = 'idle';
        }
      }
      if (n == 3) host.SFX.right();
      if (bebe != null) bebe['est'] = 'idle';
      await wait(TICK * 2);
    },
    // `gente` {que}: `viene` (the group walks up to the kerb), `saluda`, `cruza` (they cross and walk away) (49: 1, 2, 4)
    'gente': (o) async {
      final que = o['que'];
      if (que == 'viene') {
        // abuela goes back into the colmado; the door shuts behind her (49 step 1)
        if (_seen('abuela')) {
          _g('abuela')['vis'] = 0;
          W['puerta'] = 'shut';
        }
        await _vienen(_grupo);
        W['grupo'] = 1;
      } else if (que == 'saluda') {
        for (var i = 0; i < 6; i++) {
          for (final id in _grupo.keys) {
            if (_seen(id)) _g(id)['pose'] = i % 2 == 0 ? 'saluda0' : 'saluda1';
          }
          await _tick();
        }
        for (final id in _grupo.keys) {
          if (_seen(id)) _g(id)['pose'] = 'idle';
        }
      } else if (que == 'cruza') {
        await Future.wait([
          for (final id in _grupo.keys)
            if (_seen(id)) _cruza(id),
        ]);
      }
    },
    // `luz` {roja}: the light turns red and the traffic stops at the stripes; or back to green (49: 4, 6 to 8)
    'luz': _luz,
    // `par49` {a, b, lado}: two people walk up and stop side by side at the kerb, which on which side as drawn (49: 6, 7)
    'par49': (o) async {
      final a = o['a'] as String, b = o['b'] as String;
      for (final id in const ['senora', 'senor', 'luis', 'carmen']) {
        if (_seen(id)) _g(id)['vis'] = 0;
      }
      final uno = o['lado'] == '2';
      await _vienen({
        a: uno ? 'bordillo2' : 'bordillo1',
        b: uno ? 'bordillo1' : 'bordillo2',
      });
    },
    // `cruza` {quien}: one crosses and waves from the far side (49: 6, 7, 8)
    'cruza': (o) => _cruza(o['quien'] as String),
    // `pasa` {quien}: one walks on round the corner (49: 4, 6, 7)
    'pasa': (o) => _pasa(o['quien'] as String),
    // `globos` {n}: the balloons in the frog's hand (49: 1 to 8)
    'globos': (o) => _globos(_n(o['n'])),
    // `globo_va`: one gets away and floats up out of the picture (49: 6, 7)
    'globo_va': (o) async {
      final gl = W['globos'] as Map<String, dynamic>?;
      final h = _frogHand();
      host.bounce(8);
      if (gl != null) gl['n'] = math.max(0, _n(gl['n']) - 1);
      if (h == null) return;
      var y = h.y - 36;
      final x = h.x;
      host.tone(700, 0, .4, 'sine', .04, 1200);
      while (y > -40) {
        W['vuela'] = {'x': x + math.sin(y / 9) * 3, 'y': y};
        y -= 7;
        await _tick();
      }
      W['vuela'] = null;
    },
    // `da49` {n}: the ending for three, two or one left: the bebé takes the strings (49: 8)
    'da49': (o) async {
      final n = _n(o['n']);
      W['globos'] = <String, dynamic>{'n': n, 'con': 'bebe'};
      final bebe = W['bebe'] as Map<String, dynamic>?;
      host.SFX.blip();
      if (bebe != null) bebe['est'] = 'clap';
      final m = _gente['mama'] as Map<String, dynamic>?;
      // three: he is lifted onto his toes and mamá holds him down, laughing; two: one in each hand; one: he hugs it
      for (var i = 0; i < (n == 3 ? 6 : 3); i++) {
        if (m != null && n == 3) m['dy'] = i % 2 == 0 ? -2 : 0;
        await _tick();
      }
      if (m != null) m['dy'] = 0;
      if (n == 3) host.SFX.right();
      if (bebe != null) bebe['est'] = 'idle';
    },
    // `paleta` {a}: the obrero turns the green side to one end of the lane (50: 2, 3)
    'paleta': (o) async {
      final ob = _g('obrero');
      final end = W['carriles'] as Map<String, dynamic>;
      final key = end[o['a']] as String?;
      final b = key == null ? null : _autoBox(W, key);
      final at = _atOf(ob);
      if (b != null) ob['dir'] = b[0] + b[2] / 2 > at.sx ? 1 : -1;
      ob['pose'] = 'paleta_verde';
      host.SFX.blip();
      await wait(TICK * 4);
    },
    // `banderas`: he hands the frog the two flags; the frog by the cement (coqui.cerca) (50: 4)
    'banderas': (o) async {
      final ob = _g('obrero');
      final was = ob['pose'];
      ob['pose'] = was == 'sentado' || was == 'bebe'
          ? 'banderas_sentado'
          : 'banderas';
      await wait(TICK * 4);
      W['banderas'] = 1;
      host.SFX.blip();
      ob['pose'] = was == 'bebe' ? 'sentado' : was;
      await _salta('coqui.cerca');
    },
    // `bandera` {a}: the frog points the green flag at one thing and the red at the other (50: 5, 6)
    'bandera': (o) async {
      final key = _key(o['a']);
      String? otra;
      for (final k in const ['carro', 'guagua', 'bicicleta']) {
        if (k != key && _seenAuto(k)) otra = k;
      }
      W['bandera'] = {'verde': key, 'roja': otra};
      host.bounce(4);
      host.SFX.blip();
      await wait(TICK * 5);
    },
    // `atras50` {k}: the wrong one starts, backs up, knocks a cone over and leaves a wheel track in the cement (50: 5, 6)
    'atras50': (o) async {
      final key = _key(o['k']);
      final v = _autos[key] as Map<String, dynamic>?;
      // OPEN: the way it backs from the lane over the pavement to the wet square has no place in the sheet: it lurches
      // where it stands (two pixels on and back), the cone at cono2 (the sheet: "the one that is knocked over") falls,
      // and the track is drawn by `cemento`
      if (v != null && v['vis'] != 0) {
        final d = v['heading'] == 'd' ? 2 : -2;
        for (final dx in [d, d * 2, d, 0, -d, 0]) {
          v['dx'] = dx;
          await _tick();
        }
        _honk();
      }
      final c = _item('cono2');
      if (c != null) c['v'] = 1;
      host.SFX.bonk();
      W['bandera'] = null;
      await wait(TICK * 3);
    },
    // `cemento` {n}: the smooth parts left (a wheel track across each part lost)
    'cemento': (o) async {
      _cementoN(_n(o['n']));
      await wait(TICK);
    },
    // `huellas` {n}: the ending for three, two or one part smooth (50: 7): the obrero gets up (obrero.fin); two frog
    // prints side by side (one with one part left); with three Luis kneels (luis.cemento) and presses his hand in, and a
    // heart is drawn round it all; with two Luis's hand beside the prints
    'huellas': (o) async {
      final n = _n(o['n']);
      final ob = _g('obrero');
      ob['pose'] = 'idle';
      await _anda('obrero', 'obrero.fin');
      final smooth = [
        for (var i = 0; i < 3; i++)
          if (!_perdidas.take(3 - n).contains(i)) i,
      ];
      host.bounce(5);
      if (n == 1) {
        _marca('huella0', 'huella', _parte(smooth[0]));
      } else {
        _marca('huella0', 'huella', _parte(smooth[0], dv: .3));
        _marca('huella1', 'huella', _parte(smooth[0], dv: .7));
      }
      host.SFX.blip();
      await _salta('coqui.cerca');
      if (n >= 2) {
        final l = _g('luis');
        await _anda('luis', 'luis.cemento');
        l['pose'] = 'rodillas';
        await wait(TICK * 3);
        _marca('mano0', 'mano', _parte(smooth.length > 1 ? smooth[1] : 0));
        host.SFX.blip();
        await wait(TICK * 2);
      }
      if (n == 3) {
        _marca('corazon', 'corazon', _parte(1));
        host.SFX.right();
        await wait(TICK * 3);
      }
    },
    // `gesto` {quien, que, a}: `saluda`, `mira` with `a`, `no`, `rie`, `silba` (the obrero), `bebe` (he drinks from his
    // bottle, sitting on his bucket), `pie` (the frog pulls his foot back from the cement)
    'gesto': (o) async {
      final quien = o['quien'] as String, que = o['que'] as String?;
      if (quien == 'coqui') {
        host.bounce(que == 'pie' ? 3 : 6);
        await wait(TICK * 3);
        return;
      }
      if (quien == 'bebe') {
        final bebe = W['bebe'] as Map<String, dynamic>?;
        if (bebe == null) return;
        if (que == 'rie' && _seen('papa')) {
          // papá takes the bebé from abuela and swings him up high (48 step 7)
          bebe['con'] = 'papa';
          final p = _g('papa');
          for (var i = 0; i < 6; i++) {
            p['dy'] = i % 2 == 0 ? -3 : 0;
            bebe['est'] = 'clap';
            await _tick();
          }
          p['dy'] = 0;
          bebe['est'] = 'idle';
          return;
        }
        bebe['est'] = 'clap';
        await wait(TICK * 6);
        bebe['est'] = 'idle';
        return;
      }
      if (quien == 'pepe' && !_seen('pepe')) {
        // don Pepe comes to his door with a broom (49 step 5)
        _aparece('pepe', 'pepe.puerta')['escoba'] = 1;
        _campana();
      }
      final p = _g(quien);
      if (p['vis'] == 0) return;
      switch (que) {
        case 'saluda':
          for (var i = 0; i < 6; i++) {
            p['pose'] = i % 2 == 0 ? 'saluda0' : 'saluda1';
            await _tick();
          }
          p['pose'] = 'idle';
        case 'mira':
          final a = o['a'] as String?, at = _atOf(p);
          num? tx;
          if (a == 'coqui') {
            final q = W['cq'] as Map<String, dynamic>;
            tx = host.frogBox(q).x + 16;
          } else if (a != null && _p.sheet.things.containsKey(a)) {
            final b = _p.sheet.things[a]!.box;
            if (b != null) tx = b[0] + b[2] / 2;
          }
          if (tx != null && (tx - at.sx).abs() > 2) {
            p['dir'] = tx > at.sx ? 1 : -1;
          }
          if (quien == 'obrero' && a == 'cemento') p['pose'] = 'senala';
          await wait(TICK * 5);
          if (quien == 'obrero' && a == 'cemento') p['pose'] = 'paleta_roja';
        case 'no':
          final d = _n(p['dir']) < 0 ? -1 : 1;
          for (var i = 0; i < 4; i++) {
            p['dir'] = i % 2 == 0 ? -d : d;
            await _tick();
          }
          p['dir'] = d;
        case 'rie':
          for (var i = 0; i < 4; i++) {
            p['dy'] = i % 2 == 0 ? -2 : 0;
            await _tick();
          }
          p['dy'] = 0;
        case 'silba':
          final was = p['pose'];
          p['pose'] = 'silba';
          host.tone(2200, 0, .25, 'sine', .06, 2700);
          host.tone(2700, .3, .3, 'sine', .06, 2200);
          await wait(TICK * 6);
          p['pose'] = was;
        case 'bebe':
          // the obrero sits down on his upturned bucket (obrero.cubo) with his water bottle and drinks
          if (quien == 'obrero') {
            final cubo = _p.world('obrero.cubo');
            p['pose'] = 'idle';
            await _andaA(quien, cubo[0], cubo[1], 0);
            _items.removeWhere((x) => x['k'] == 'cubo');
            _items.add(<String, dynamic>{
              'id': 'cubo',
              'k': 'cubo',
              'x': cubo[0],
              'y': cubo[1],
              'z': 0.0,
              'spot': 'obrero.cubo',
              'vis': 1,
              'v': null,
            });
            final w = _p.world('obrero.cubo');
            p
              ..['x'] = w[0]
              ..['y'] = w[1]
              ..['z'] = w[2]
              ..['spot'] = 'obrero.cubo'
              ..['dir'] = -1
              ..['pose'] = 'bebe';
            host.tone(500, 0, .2, 'sine', .04, 380);
            await wait(TICK * 8);
            p['pose'] = 'sentado';
          } else {
            await wait(TICK * 3);
          }
        default:
          await wait(TICK * 3);
      }
    },
  };
}
