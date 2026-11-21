// El mostrador (place 4, El colmado, scene 1; stories 36 to 38): a NEW scene, written from its script's "Needs" list
// (historia/notas/guiones/mostrador.md) on its set (mostrador_set.dart) and its sheet (mostrador-sheet.json, read by
// SceneSheet). There is no old scene file: every act is this file's, each doing on screen what the Needs list says,
// every place from the sheet (a spot's world point, a thing's box, the depth rule). Where the sheet names no place, or
// the script does not settle what an act shows, the act does the plainest thing that keeps the story playing and says
// so in a comment starting `OPEN:` (page 13 lists them for the content lane).
//
// The drawing (the sheet's `front`): every sprite stands with its feet's bottom edge on its spot's row and its middle on
// its column (rules.anchor); a sprite pixel is hidden by every set pixel nearer the camera than the upright plane
// through its feet plus `front.bias` (front.plane); between two sprites the nearer pixel wins. The people and the
// things are kept in W by their world point and the picture they are in (`dentro`, or `calle` with its own origin).
// ignore_for_file: non_constant_identifier_names

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/src/balcon/balcon.dart' show abanico;
import 'package:coqui_scenes/src/colmado/colmado_cast.dart';
import 'package:coqui_scenes/src/colmado/colmado_dentro.dart';
import 'package:coqui_scenes/src/mostrador/mostrador_places.dart';
import 'package:coqui_scenes/src/mostrador/mostrador_set.dart';
import 'package:coqui_scenes/src/mostrador/mostrador_sprites.dart';
import 'package:coqui_scenes/src/scene_set.dart';
import 'package:coqui_scenes/src/sheet_cache.dart';

/// The scene "El mostrador", made from its sheet (read first: `loadScene`).
Scene createMostrador() => Mostrador(sceneSheetOf('mostrador'));

int _round(num v) => (v + 0.5).floor();

int _n(Object? v) => v is num ? v.toInt() : 0;

/// One sprite of the sprite layer, placed: its picture, its top left on the 240 x 216 picture, the screen row of its
/// feet and the depth there (front.plane), and whether the set may hide it (the depth rule).
class MostradorItem {
  MostradorItem(this.s, this.left, this.top, this.sy, this.d, {this.tag});

  final Sprite s;
  final int left, top;
  final num sy;
  final double d;

  /// Who or what it is (the rules' tests read it: `persona:<id>`, `coqui`, `cosa:<id>`).
  final String? tag;
}

/// The places of a few things the frog's `ir` names (the kit's `lugar`: his top left and scale).
const List<String> _frogSpots = [
  'coqui.mostrador',
  'coqui.frente',
  'coqui.frente2',
  'puerta',
  'fuera',
];

class Mostrador extends Escena implements SetScene, SetOverSprites {
  Mostrador(this.ss) : sheet = ss.legacy() {
    _p = MostradorPlaces(ss);
    // the runner starts on `wide` (juego.js `cam = CAM.wide`): the inside view (the sheet has no view of that name)
    CAM = {
      'dentro': _p.view('dentro'),
      'calle': _p.view('calle'),
      'wide': _p.view('dentro'),
    };
    LUGAR = {
      for (final s in _frogSpots)
        s.replaceFirst('coqui.', ''): _frogAt(_p.at(s)),
      // OPEN: story 36 step 7 sends the frog to `mostrador_izq` (`ir`), a spot the sheet does not name; he goes to the
      // sheet's one place for him on the counter, coqui.mostrador (spots.coqui.mostrador: "the frog's one place on the
      // counter top").
      'mostrador_izq': _frogAt(_p.at('coqui.mostrador')),
    };
    cosas = _things();
  }

  /// The new scene's sheet (SceneSheet).
  final SceneSheet ss;

  /// The old Sheet the shared code reads (`SceneSheet.legacy`: the scene, scale, origin; the start frog the runner's).
  @override
  final Sheet sheet;

  late final MostradorPlaces _p;

  /// The scene's places, from its sheet.
  MostradorPlaces get places => _p;

  @override
  String get id => 'mostrador';

  @override
  late final Map<String, List<num>> CAM;

  late final Map<String, List<num>> LUGAR;

  @override
  Map<String, List<num>> get lugar => LUGAR;

  @override
  late final List<Thing> cosas;

  @override
  PpEngine newEngine({bool still = false}) => mostradorEngine(still: still);

  @override
  PpEngine get projection => _p.e;

  // the frog's top left for a spot (rules.anchor: mkCoqui's column 16 on sx, its row 25 on sy)
  List<num> _frogAt(MostradorAt a) => [_round(a.sx) - 16, _round(a.sy) - 25, 1];

  Map<String, dynamic> get W => host.W;
  int get F => host.F;
  int get TICK => host.TICK;
  Future<void> wait(num ms) => host.wait(ms);

  /* ---------- the state ---------- */

  // which picture: W.donde (fresh sets it from the story's first `cam`, `entra` moves it inside); with none, the
  // camera's (the views' x0 are the sheet's, 21 inside and 22 in the street); with no host (a picture), inside
  String donde(Map<String, dynamic> w) {
    final d = w['donde'];
    if (d is String) return d;
    try {
      final c = host.cam;
      final cv = CAM['calle']!;
      if (c[0] == cv[0] && c[2] == cv[2]) return 'calle';
    } catch (_) {
      // no host yet
    }
    return 'dentro';
  }

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

  static String? _firstCam(Object? beats) {
    String? found;
    void walk(Object? v) {
      if (found != null) return;
      if (v is Map) {
        if (v['cam'] is String) {
          found = v['cam'] as String;
          return;
        }
        v.values.forEach(walk);
      } else if (v is List) {
        v.forEach(walk);
      }
    }

    walk(beats);
    return found;
  }

  Map<String, dynamic> _person(String spot, String en, {int vis = 1}) {
    final w = _p.world(spot, en);
    return <String, dynamic>{
      'en': en,
      'x': w[0],
      'y': w[1],
      'z': w[2],
      'spot': spot,
      'vis': vis,
      'dir': 1,
      'pose': 'idle',
      'sent': 0,
      'dy': 0,
      'lleva': <dynamic>[],
    };
  }

  Map<String, dynamic> _cosa(
    String id,
    String k,
    String spot, {
    double dx = 0,
    Object? v,
    String en = 'dentro',
  }) {
    final w = _p.world(spot, en);
    return <String, dynamic>{
      'id': id,
      'k': k,
      'x': w[0] + dx,
      'y': w[1],
      'z': w[2],
      'en': en,
      'spot': spot,
      'vis': 1,
      'v': v,
      'con': null,
    };
  }

  @override
  Map<String, dynamic> fresh(Map<String, dynamic> story) {
    final acts = _actsOf([story['beats'], story['final']]);
    bool has(String a) => acts.any((o) => o['act'] == a);
    final calle = _firstCam(story['beats']) == 'calle';
    final entraCoqui = acts.any(
      (o) => o['act'] == 'entra' && o['quien'] == 'coqui',
    );
    final gente = <String, dynamic>{
      'pepe': _person('pepe.mostrador', 'dentro'),
    };
    // story 36 starts in the street: abuela and the frog on the pavement (calle spots)
    if (calle) gente['abuela'] = _person('abuela.acera', 'calle');
    // story 38: the three children wait just inside the street door from the start (the script's "Start")
    if (has('ninos')) {
      final g = _p.group('ninos_puerta');
      for (var i = 0; i < g.length; i++) {
        gente['nino${i + 1}'] = _person(g[i], 'dentro')..['nino'] = i;
      }
    }
    // the goods on their shelf, but those the story says are not there (`nohay`: story 36's butter)
    final nohay = {
      for (final o in acts)
        if (o['act'] == 'nohay') o['k'],
    };
    final cosas = <dynamic>[
      for (final k in GENEROS)
        if (!nohay.contains(k)) _cosa(k, k, 'estante.$k'),
    ];
    // story 36: the tray of three warm quesitos, and the coin dish (the script's goal and "Start")
    if (has('bandeja')) {
      cosas.add(_cosa('quesitos', 'bandeja', 'bandeja', v: 3));
    }
    final nevera = has('limber');
    if (!nevera) cosas.add(_cosa('platillo', 'platillo', 'platillo', v: 0));
    // story 37: the row of malts beside the dish (mostrador-preview.html moment 4: three, .15 apart in x)
    if (has('malta')) {
      for (var i = 0; i < 3; i++) {
        cosas.add(_cosa('malta.$i', 'malta', 'maltas', dx: (i - 1) * .15));
      }
    }
    // story 36: the rooster on the awning's front edge, in the street (calle spot `gallo`)
    if (has('gallo')) {
      cosas.add(_cosa('gallo', 'gallo', 'gallo', en: 'calle', v: 0));
    }
    // OPEN: story 37's piragua cart ("outside the door, the piragua cart") has no place in the sheet: it stands at spot
    // `fuera`, the pavement seen through the street door
    if (has('piraguas')) cosas.add(_cosa('carrito', 'carrito', 'fuera'));
    // the list on the corner card: the things its `lista` acts name, in order
    final lista = <String>[];
    for (final o in acts) {
      final k = o['k'];
      if (o['act'] == 'lista' && k is String && !lista.contains(k)) {
        lista.add(k);
      }
    }
    // the frog: in the street (36), on the counter (38: the script's "Start"), or outside until he comes in (37)
    final q = calle
        ? _frogAt(_p.at('coqui.acera', 'calle'))
        : entraCoqui
        ? LUGAR['fuera']!
        : LUGAR['mostrador']!;
    return {
      // the picture the story starts in (its first `cam`): the runner's first frames are on `wide` (the inside view's
      // window) before that step moves the camera
      'donde': calle ? 'calle' : 'dentro',
      'hora': 'manana',
      'atras': 'shut',
      'puerta': 'shut',
      'nevera': nevera ? 1 : 0,
      'enNevera': nevera ? 5 : 0,
      'gente': gente,
      'cosas': cosas,
      'lista': <String, dynamic>{
        'vis': 0,
        'items': lista,
        'lit': null,
        'hechos': <dynamic>[],
      },
      'tarjeta': null,
      'marcas': null,
      'piensa': null,
      'piraguas': null,
      'cq': <String, dynamic>{
        'x': q[0],
        'y': q[1],
        's': 1,
        'dy': 0,
        'al': 1,
        'vis': entraCoqui && !calle ? 0 : 1,
        'bub': null,
        'z': calle || entraCoqui ? 0 : 1,
        'en': calle ? 'calle' : 'dentro',
        'lleva': null,
      },
    };
  }

  /* ---------- the set ---------- */

  // the sheet's setKey: inside "hora-atras-nevera" (e.g. "manana-shut-0"), in the street "hora-puerta" ("manana-shut")
  @override
  String setKey(Map<String, dynamic> W) {
    final hora = W['hora'] == 'tarde' ? 'tarde' : 'manana';
    if (donde(W) == 'calle') {
      return '$hora-${W['puerta'] == 'open' ? 'open' : 'shut'}';
    }
    return '$hora-${W['atras'] == 'open' ? 'open' : 'shut'}-${_n(W['nevera']) == 1 ? 1 : 0}';
  }

  @override
  void buildSet(PpEngine e, PpBuild b, Map<String, dynamic> W) =>
      buildSetFor(e, b, setKey(W));

  final Map<PpEngine, MostradorSet> _sets = {};

  @override
  void buildSetFor(PpEngine e, PpBuild b, String key) =>
      (_sets[e] ??= MostradorSet(e, b)).buildSet(MostradorState.fromKey(key));

  // the frog casts his shadow in the engine (shadows.byCharacter.coqui) when he stands on the floor; never the old one
  @override
  bool get frogShadow => false;

  /* ---------- where everybody is ---------- */

  Map<String, dynamic> _g(String id) =>
      ((W['gente'] as Map<String, dynamic>)[id] ??= _person(
            'fuera',
            'dentro',
            vis: 0,
          ))
          as Map<String, dynamic>;

  List<Map<String, dynamic>> get _items =>
      (W['cosas'] as List).cast<Map<String, dynamic>>();

  Map<String, dynamic>? _item(String id) {
    for (final o in _items) {
      if (o['id'] == id) return o;
    }
    return null;
  }

  // a person's or a thing's place on its picture
  MostradorAt _atOf(Map<String, dynamic> o) => _p.atWorld(
    o['x'] as num,
    o['y'] as num,
    o['z'] as num,
    (o['en'] as String?) ?? 'dentro',
  );

  // the frog's world point under his feet (his z: 0 the floor, 1 the counter)
  MostradorAt _frogPoint(Map<String, dynamic> q) {
    final b = host.frogBox(q);
    return _p.fromScreen(
      b.x + b.w / 2,
      (q['y'] as num) + 25,
      (q['z'] as num?) ?? 0,
      (q['en'] as String?) ?? 'dentro',
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

  // a person's sprite and the point of it that stands on the spot (rules.anchor)
  ({Sprite s, int ax, int ay, String key}) _personSprite(
    String id,
    Map<String, dynamic> p,
    bool open,
  ) {
    final pose = (p['pose'] as String?) ?? 'idle', sent = _n(p['sent']) == 1;
    if (id == 'abuela') {
      if (sent) {
        final f = pose.startsWith('abanico')
            ? (pose == 'abanico1' ? 'fan1' : 'fan0')
            : 'idle';
        final key = 'abS$f$open';
        final s = _spr(key, () {
          final base = mkAbuelaS(f, open, false);
          if (f == 'idle') return base;
          final fan = canvasSprite(20, 12, (g) => abanicoDe(g, 10, 10));
          return overSprite(base, [(fan, 31 - 10, 16 - 10)]);
        });
        // abuela sitting: her middle (column 17) and her lap (row 36) on the seat's point (rules.anchor)
        return (s: s, ax: 17, ay: 36, key: key);
      }
      final ap = pose == 'saluda0'
          ? 'wave0'
          : pose == 'saluda1'
          ? 'wave1'
          : pose == 'mano'
          ? 'offer'
          : 'idle';
      final key = 'ab$ap$open';
      final s = _spr(key, () => mkAbuela(ap, open));
      return (s: s, ax: 30, ay: inkBottom(s), key: key);
    }
    if (id == 'pepe') {
      final pp = sent ? (pose.startsWith('abanico') ? pose : 'sentado') : pose;
      final key = 'pepe$pp$open';
      final s = _spr(key, () => mkPepe(pp, open: open));
      return (s: s, ax: PX, ay: inkBottom(s), key: key);
    }
    if (id.startsWith('nino')) {
      final i = _n(p['nino']);
      final key = 'nino$i$pose$open';
      final s = _spr(key, () => mkNino(i, pose, open: open));
      return (s: s, ax: PX, ay: inkBottom(s), key: key);
    }
    if (id == 'senora' || id == 'senor') {
      final lleva = p['cesta'] as String?;
      final mp = pose == 'manos' ? 'ojos' : 'idle';
      final key = 'cl$id$mp$lleva$open';
      final s = _spr(key, () => mkCliente(id, mp, open: open, lleva: lleva));
      return (s: s, ax: PX, ay: inkBottom(s), key: key);
    }
    // the family's children (FAM)
    final who = FAM[id == 'luis' ? 'hermano' : 'hermana']!;
    final kp = pose == 'saluda0' || pose == 'arriba'
        ? 'wave0'
        : pose == 'saluda1'
        ? 'wave1'
        : pose == 'mano'
        ? 'taza'
        : 'idle';
    final key = 'fam$id$kp$open';
    final s = _spr(key, () => mkPersona(who, kp, open, false));
    return (s: s, ax: PX, ay: inkBottom(s), key: key);
  }

  // the sprite of a thing
  Sprite _thingSprite(Map<String, dynamic> o) {
    final k = o['k'] as String, v = o['v'];
    switch (k) {
      case 'bandeja':
        return _spr('bandeja$v', () => mkBandeja(_n(v)));
      case 'platillo':
        return _spr('platillo$v', () => mkPlatillo(_n(v)));
      case 'moneda':
        return _spr('moneda', mkMoneda);
      case 'malta':
        return _spr('malta$v', () => mkMalta(v == 'abierta'));
      case 'limber':
        final st = (o['estado'] as String?) ?? 'vaso';
        return _spr('limber$v$st', () => mkLimber(v as String, st));
      case 'bolsa':
        return _spr('bolsatela$v', () => mkBolsaTela(v == 'abierta'));
      case 'bolsapapel':
        return _spr('bolsapapel', mkBolsaPapel);
      case 'quesito':
        return _spr('quesito$v', () => mkQuesito(v == 'medio'));
      case 'piragua':
        return _spr('piragua', mkPiragua);
      case 'carrito':
        return _spr('carrito', mkCarritoPiragua);
      case 'gallo':
        return _spr('gallo$v', () => mkGallo(v == 1));
      case 'lista':
        return _spr('lista', mkListaMano);
      case 'bolsaabuela':
        return _spr('bolsaabuela', mkBolsaAbuela);
    }
    return _spr('genero$k', () => mkGenero(k));
  }

  // where a held thing is drawn: at the holder's hand (the person's held-out hand, kit.js mkPersona 'taza': X + rx + 4.5,
  // row 27; abuela's at her right side; the frog's beside him), as a point of the picture with the holder's depth
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
    final p =
        (W['gente'] as Map<String, dynamic>)[holder] as Map<String, dynamic>?;
    if (p == null || p['vis'] == 0) return null;
    final at = _atOf(p), dir = _n(p['dir']) < 0 ? -1 : 1;
    final nino =
        holder == 'luis' || holder == 'carmen' || holder.startsWith('nino');
    if (holder == 'abuela') {
      return (
        x: at.sx + dir * 9,
        y: at.sy - (jsTruthy(p['sent']) ? 6 : 14),
        d: at.d + .05,
        sy: at.sy,
      );
    }
    return (
      x: at.sx + dir * (nino ? 11 : 13),
      y: at.sy - (nino ? 15 : (jsTruthy(p['sent']) ? 18 : 26)),
      d: at.d + .05,
      sy: at.sy,
    );
  }

  /// Every sprite of the frame [w] as it is placed (the people, the things, the frog), in the picture it shows. The
  /// rules' tests read it; [draw] draws it.
  List<MostradorItem> items(
    Map<String, dynamic> w,
    int a, {
    bool withFrog = true,
  }) {
    final out = <MostradorItem>[];
    final dn = donde(w), talk = _talker();
    final gente = (w['gente'] as Map<String, dynamic>?) ?? const {};
    for (final en in gente.entries) {
      final p = en.value as Map<String, dynamic>;
      if (p['vis'] == 0 || p['en'] != dn) continue;
      final open = talk == en.key && a % 2 == 1;
      final sp = _personSprite(en.key, p, open);
      final at = _atOf(p);
      final dir = _n(p['dir']) < 0 ? -1 : 1;
      final s = dir < 0 ? _mirror(sp.key, sp.s) : sp.s;
      final ax = dir < 0 ? sp.s.w - 1 - sp.ax : sp.ax;
      final sx = _round(at.sx), sy = _round(at.sy) + _n(p['dy']);
      out.add(
        MostradorItem(
          s,
          sx - ax,
          sy - sp.ay,
          sy,
          at.d,
          tag: 'persona:${en.key}',
        ),
      );
    }
    for (final o
        in (w['cosas'] as List? ?? const []).cast<Map<String, dynamic>>()) {
      if (o['vis'] == 0 || ((o['en'] as String?) ?? 'dentro') != dn) continue;
      final s = _thingSprite(o);
      final con = o['con'] as String?;
      if (con != null) {
        final h = _handOf(con);
        if (h == null) continue;
        out.add(
          MostradorItem(
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
        MostradorItem(
          s,
          sx - s.w ~/ 2,
          sy - inkBottom(s),
          sy,
          at.d,
          tag: 'cosa:${o['id']}',
        ),
      );
    }
    // the límbers left in the freezer, seen through its glass lid: a row on the lid inside the freezer's world box (the
    // colmado kit's NEVERA, the sheet's things.nevera.world), one for each that is left
    if (dn == 'dentro' && _n(w['nevera']) == 1) {
      final nv = ColmadoDentro.NEVERA, n = math.min(5, _n(w['enNevera']));
      for (var i = 0; i < n; i++) {
        final x = nv[0] + .14 + i * (nv[3] - nv[0] - .28) / 4,
            y = (nv[1] + nv[4]) / 2,
            at = _p.atWorld(x, y, nv[5] + .02);
        final s = _spr(
          'tapa$i',
          () => mkLimberTapa(i % 2 == 0 ? 'white' : 'orange'),
        );
        out.add(
          MostradorItem(
            s,
            _round(at.sx) - s.w ~/ 2,
            _round(at.sy) - s.h + 1,
            _round(at.sy),
            at.d,
            tag: 'nevera:$i',
          ),
        );
      }
    }
    return out;
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
    MostradorItem it,
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
        if (setZ != null && setZ[i] > plane + bias) {
          continue; // a set pixel nearer than the feet hides it
        }
        if (lz[i] > plane) continue; // a nearer sprite pixel is already there
        lz[i] = plane;
        layer[i] = c;
      }
    }
  }

  /// [items] and the frog (as the game draws him, juego.js frog, at the depth of his feet): every sprite of the frame,
  /// placed. [draw] composes it; the rules' tests read it.
  List<MostradorItem> placed(Map<String, dynamic> W, int a) {
    final all = items(W, a), dn = donde(W);
    final q = W['cq'] as Map<String, dynamic>;
    if (jsTruthy(q['vis']) && ((q['en'] as String?) ?? 'dentro') == dn) {
      final b = host.frogBox(q), at = _frogPoint(q);
      final ox = b.x.toInt() - 16, oy = b.y.toInt() - 24;
      final px = Uint32List(64 * 64);
      final g = Ctx(px, 64, 64)..translate(-ox.toDouble(), -oy.toDouble());
      host.frog(g, q, a);
      all.add(
        MostradorItem(
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
    final setZ = _frameEngine != null ? _setZ : null,
        bias = _p.bias,
        S = _p.e.S;
    final dn = donde(W);
    final all = placed(W, a);
    if (all.isEmpty) {
      _over(c, W, a, dn);
      return;
    }
    // only the box the sprites cover is cleared, composed and drawn
    var x0 = w0, y0 = h0, x1 = 0, y1 = 0;
    for (final it in all) {
      x0 = math.min(x0, math.max(0, it.left));
      y0 = math.min(y0, math.max(0, it.top));
      x1 = math.max(x1, math.min(w0, it.left + it.s.w));
      y1 = math.max(y1, math.min(h0, it.top + it.s.h));
    }
    if (x1 <= x0 || y1 <= y0) {
      _over(c, W, a, dn);
      return;
    }
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
    _over(c, W, a, dn);
  }

  // what is drawn over everything: the quesitos' steam, a thought, the list in a hand
  void _over(Ctx c, Map<String, dynamic> W, int a, String dn) {
    if (dn == 'dentro') {
      final t = _item('quesitos');
      if (t != null && t['vis'] != 0 && _n(t['v']) > 0 && t['con'] == null) {
        final at = _atOf(t), x = _round(at.sx), y = _round(at.sy) - 12;
        final f = (F >> 2) % 2;
        for (var i = 0; i < 3; i++) {
          fr(c, x - 4 + i * 4 + f, y - 2 - (i % 2) * 2, 1, 2, 0xD0F4F4F4);
          fr(c, x - 4 + i * 4 + 1 - f, y - 5 - (i % 2) * 2, 1, 2, 0xA0F4F4F4);
        }
      }
    }
    final pi = W['piensa'] as Map<String, dynamic>?;
    if (pi != null && F < _n(pi['hasta'])) {
      final h = _headOf(pi['quien'] as String);
      if (h != null) {
        nube(c, h[0] + 6, h[1] - 34, pi['k'] as String, [h[0], h[1]]);
      }
    }
  }

  /// A thought (mostrador.md: "a thought over the frog: a quesito"; "a piragua"): an outlined cloud of round lobes with
  /// two small circles that lead to the one who thinks, and the thing in it (comer.js `nube`, drawn the same way).
  void nube(Ctx g, num x, num y, String k, List<num> aim) {
    final im = k == 'piragua' ? mkPiragua() : _spr('quesito', mkQuesito);
    const w = 28, h = 22;
    final lobes = [
      [w * .27, h * .6, h * .36],
      [w * .5, h * .4, h * .41],
      [w * .73, h * .6, h * .36],
      [w * .5, h * .66, h * .36],
    ];
    void oval(num cx, num cy, num r, int col) {
      g.fillStyle = col;
      g.beginPath();
      g.ellipse(cx, cy, r, r, 0, 0, 2 * math.pi);
      g.fill();
    }

    for (final l in lobes) {
      oval(
        _round(x + l[0]),
        _round(y + l[1]),
        math.max(3, _round(l[2])) + 1,
        OUT,
      );
    }
    for (final l in lobes) {
      oval(
        _round(x + l[0]),
        _round(y + l[1]),
        math.max(3, _round(l[2])),
        0xFFFFFFFF,
      );
    }
    final cx = x + w / 2, cy = y + h / 2, vx = aim[0] - cx, vy = aim[1] - cy;
    final dd = math.max(1.0, math.sqrt(vx * vx + vy * vy)),
        ux = vx / dd,
        uy = vy / dd;
    for (final q in const [
      [15, 3],
      [21, 2],
    ]) {
      final px = _round(cx + ux * q[0]), py = _round(cy + uy * q[0]);
      oval(px, py, q[1] + 1, OUT);
      oval(px, py, q[1], 0xFFFFFFFF);
    }
    g.drawImage(im, _round(cx - im.w / 2), _round(cy - im.h / 2));
  }

  // the top of a head (talkAt's point), of a person or of the frog
  List<num>? _headOf(String who) {
    if (who == 'coqui' || who == 'cq') {
      final q = W['cq'] as Map<String, dynamic>;
      final b = host.frogBox(q);
      return [b.x + b.w / 2, b.y];
    }
    return talkAt(who, W);
  }

  /* ---------- the boards: abuela's or Carmen's list, the two rounds ---------- */

  @override
  void hud(Ctx c, Map<String, dynamic> W, int a) {
    final lista = W['lista'] as Map<String, dynamic>?;
    var x0 = 3;
    if (lista != null && jsTruthy(lista['vis'])) {
      final items = (lista['items'] as List).cast<String>();
      final w = 6 + 18 * items.length;
      tarjeta(c, 3, 3, w, 24);
      for (var i = 0; i < items.length; i++) {
        final k = items[i], s = _spr('genero$k', () => mkGenero(k));
        final x = 6 + i * 18, cx = x + 8;
        if (lista['lit'] == k && (F >> 2) % 2 == 0) {
          fr(c, x - 1, 4, 18, 22, 0xFF40E0FF);
        }
        c.drawImage(s, _round(cx - s.w / 2), 5 + (16 - s.h) ~/ 2 + 2);
        if ((lista['hechos'] as List).contains(k)) {
          c.drawImage(_spr('visto', mkVisto), x + 9, 18);
        }
      }
      x0 = 3 + w + 4;
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

  // castShadow(x, y, 0, radius) at the world x, y of whoever stands on the floor (z 0) of the picture shown (shadows.at);
  // none on the counter (onCounter), none sitting, none outside the door (none: fuera, pepe.fuera), none for the rooster.
  // In the street the world point is the one of the scene's engine under the same screen point (the street's picture is
  // baked on its own origin and handed to the scene's engine: mostrador_set.dart)
  @override
  List<ShadowCast> shadows(Map<String, dynamic> W) {
    final out = <ShadowCast>[];
    final dn = donde(W);
    void cast(MostradorAt at, double? r) {
      if (r == null || at.z != 0) return;
      if (dn == 'dentro') {
        out.add((x: at.x, y: at.y, z: 0, r: r));
      } else {
        final g = _p.e.unproject(at.sx, at.sy);
        out.add((x: g.x, y: g.y, z: 0, r: r));
      }
    }

    final gente = (W['gente'] as Map<String, dynamic>?) ?? const {};
    for (final en in gente.entries) {
      final p = en.value as Map<String, dynamic>;
      if (p['vis'] == 0 || p['en'] != dn || jsTruthy(p['sent'])) continue;
      if (_p.noShadow((p['spot'] as String?) ?? '', dn)) continue;
      final who = en.key.startsWith('nino') ? 'ninos' : en.key;
      cast(_atOf(p), _p.radius(who, dn));
    }
    final q = W['cq'] as Map<String, dynamic>?;
    if (q != null &&
        jsTruthy(q['vis']) &&
        ((q['en'] as String?) ?? 'dentro') == dn &&
        _n(q['z']) == 0) {
      final at = _frogPoint(q);
      // none outside the street door (the pavement seen through it)
      if (!(dn == 'dentro' && at.x < 0)) cast(at, _p.radius('coqui', dn));
    }
    return out;
  }

  /* ---------- the things he can touch ---------- */

  // the screen box of a sprite item: its drawn pixels' bounds
  static final Expando<List<int>> _inkOf = Expando<List<int>>();

  static List<num>? _inkBox(MostradorItem it) {
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

  // the boxes of the frame now (one list of placed sprites a frame: the signs ask for boxes many times a frame)
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
    if (f == null) {
      for (final it in items(w, 0)) {
        if (it.tag == tag) return _inkBox(it);
      }
      return null;
    }
    if (f != _boxesF || !identical(w, _boxesW)) {
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
      String id,
      String pic, {
      bool Function(Map<String, dynamic>)? si,
    }) {
      final b = _p.box(id, pic);
      return Thing(
        id: id,
        m: 0,
        world: pic == 'dentro' ? _p.worldBox(id) : null,
        si: (w) => donde(w) == pic && (si == null || si(w)),
        box: [b[0], b[1], b[2], b[3]],
      );
    }

    return [
      // small things first: they are in front of the counter and the shelves, and over the people
      for (final k in GENEROS) sprite(k, 'cosa:$k', z: true),
      sprite('limber_a', 'cosa:limber_a', z: true),
      sprite('limber_b', 'cosa:limber_b', z: true),
      sprite('bolsa', 'cosa:bolsa', z: true),
      sprite('quesitos', 'cosa:quesitos', z: true),
      // the people (names: the free poke)
      for (final id in const [
        'pepe',
        'abuela',
        'carmen',
        'luis',
        'senora',
        'senor',
      ])
        sprite(id, 'persona:$id', m: 1),
      Thing(
        id: 'ninos',
        m: 1,
        si: (w) => _ninosBox(w) != null,
        box: (Map<String, dynamic> w) => _ninosBox(w),
      ),
      // OPEN: the piragua cart (37: "the piragua cart twinkles", key `carrito`) has no place in the sheet: it stands at
      // spot `fuera` (the pavement seen through the street door); its box is its sprite's there
      sprite('carrito', 'cosa:carrito'),
      // the set's things (sheet: things.<id>.box)
      setThing('nevera', 'dentro', si: (w) => _n(w['nevera']) == 1),
      setThing('silla', 'dentro'),
      setThing('puerta', 'dentro'),
      setThing('mostrador', 'dentro'),
      setThing('colmado', 'calle'),
    ];
  }

  List<num>? _ninosBox(Map<String, dynamic> w) {
    List<num>? u;
    for (var i = 1; i <= 3; i++) {
      final b = _boxOfTag(w, 'persona:nino$i');
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

  /* ---------- talking ---------- */

  // the point over a speaker's head (the speaker keys pepe, ninos, and the people of the stories): its sprite's top
  @override
  List<num>? talkAt(String who, Map<String, dynamic> W) {
    final id = who == 'ninos' ? 'nino2' : who;
    for (final it in items(W, 0)) {
      if (it.tag != 'persona:$id') continue;
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
          '${e.key}@${(e.value as Map)['spot']}${(e.value as Map)['sent'] == 1 ? '(sentado)' : ''}',
    ].join(' ');
    final cosas = [
      for (final o in _itemsOf(W))
        if (o['vis'] != 0)
          '${o['id']}@${o['con'] ?? o['spot']}${o['v'] != null ? ':${o['v']}' : ''}${o['estado'] != null ? ':${o['estado']}' : ''}',
    ].join(',');
    final l = W['lista'] as Map?;
    return 'donde=${donde(W)} gente=$gente cosas=$cosas enNevera=${W['enNevera']} lista=${l?['hechos']} marcas=${W['marcas']}';
  }

  static List<Map<String, dynamic>> _itemsOf(Map<String, dynamic> W) =>
      (W['cosas'] as List? ?? const []).cast<Map<String, dynamic>>();

  /* ---------- moving ---------- */

  // a walk: a straight line at a steady pace, about 5 px of the picture a tick (comer.js mueve)
  Future<void> _anda(String id, String spot, {String? en}) async {
    final p = _g(id), pic = en ?? (p['en'] as String);
    final w = _p.world(spot, pic);
    if (p['vis'] == 0 || p['en'] != pic) {
      p['en'] = pic;
      p['x'] = w[0];
      p['y'] = w[1];
      p['z'] = w[2];
      p['vis'] = 1;
      p['spot'] = spot;
      return;
    }
    final a = _atOf(p), b = _p.atWorld(w[0], w[1], w[2], pic);
    final dist = math.sqrt(
      (b.sx - a.sx) * (b.sx - a.sx) + (b.sy - a.sy) * (b.sy - a.sy),
    );
    final x0 = p['x'] as num, y0 = p['y'] as num, z0 = p['z'] as num;
    p['sent'] = 0;
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
  }

  // the frog hops to a spot (the kit's hopTo: a hop about every 30 px), on the floor or onto the counter
  Future<void> _salta(String spot, {String en = 'dentro'}) async {
    final q = W['cq'] as Map<String, dynamic>;
    final at = _p.at(spot, en), L = _frogAt(at);
    if (q['en'] != en || !jsTruthy(q['vis'])) {
      q['en'] = en;
      q['x'] = L[0];
      q['y'] = L[1];
      q['z'] = at.z;
      q['vis'] = 1;
      return;
    }
    final dx = (q['x'] as num) - L[0], dy = (q['y'] as num) - L[1];
    final dd = math.sqrt(dx * dx + dy * dy);
    // going up onto the counter he is in front of it the whole hop; coming down, the same
    if (at.z > _n(q['z'])) q['z'] = at.z;
    if (dd >= 3) {
      await host.hopTo(
        L[0],
        L[1],
        math.max(1, math.min(4, _round(dd / 30))),
        1,
      );
    }
    q['z'] = at.z;
  }

  // a thing goes from where it is to a world point of the counter (or into a hand), in a few ticks
  Future<void> _lleva(
    Map<String, dynamic> o,
    String spot, {
    int n = 4,
    double dx = 0,
  }) async {
    final w = _p.world(spot);
    o['con'] = null;
    final x0 = o['x'] as num, y0 = o['y'] as num, z0 = o['z'] as num;
    for (var i = 1; i <= n; i++) {
      o['x'] = x0 + (w[0] + dx - x0) * i / n;
      o['y'] = y0 + (w[1] - y0) * i / n;
      o['z'] = z0 + (w[2] - z0) * i / n;
      await wait(TICK);
    }
    o['spot'] = spot;
    o['en'] = 'dentro';
  }

  // where a thing set down on the counter goes: the first of these the sheet names that holds nothing
  // OPEN: the sheet names one place for a thing taken down (`compra`); story 37 sets down three before they are packed,
  // so the second and the third take the counter's other named places (cosa_b, cosa_a)
  String _libre() {
    for (final s in const ['compra', 'cosa_b', 'cosa_a']) {
      if (!_items.any(
        (o) => o['vis'] != 0 && o['con'] == null && o['spot'] == s,
      )) {
        return s;
      }
    }
    return 'compra';
  }

  Map<String, dynamic> _genero(String k) {
    final o = _item(k);
    if (o != null) return o;
    final n = _cosa(k, k, 'estante.$k')..['vis'] = 0;
    _items.add(n);
    return n;
  }

  // the bell over the street door
  void _campana() {
    host.tone(1568, 0, .25, 'sine', .08);
    host.tone(2093, .08, .3, 'sine', .06);
  }

  // where somebody stands once in (mostrador.md, "Needs": the customer at `cliente`, the next one waiting at `cola1`;
  // abuela at `abuela.frente`; a child at `nino.frente`; don Pepe behind the counter)
  String _destino(String quien) {
    switch (quien) {
      case 'abuela':
        return 'abuela.frente';
      case 'luis':
      case 'carmen':
        return 'nino.frente';
      case 'pepe':
        return 'pepe.mostrador';
      case 'senora':
      case 'senor':
        final g = W['gente'] as Map<String, dynamic>;
        final busy = g.values.any(
          (p) => (p as Map)['vis'] != 0 && p['spot'] == 'cliente',
        );
        // OPEN: the sheet says coqui.frente2 and cliente are never taken together ("the frog of story 37 has no
        // customer"), but in story 37 step 6 the señora comes in while the frog stands at coqui.frente2 (4 px from
        // cliente): she waits at cola1, the nearest named place clear of him
        final q = W['cq'] as Map<String, dynamic>, f2 = LUGAR['frente2']!;
        final frogThere =
            jsTruthy(q['vis']) && q['x'] == f2[0] && q['y'] == f2[1];
        return busy || frogThere ? 'cola1' : 'cliente';
    }
    return 'puerta';
  }

  // the story goes inside: who was in the street is left outside (the frog until he comes in himself)
  void _adentro() {
    final q = W['cq'] as Map<String, dynamic>;
    if (q['en'] == 'calle') {
      final L = LUGAR['fuera']!;
      q['en'] = 'dentro';
      q['x'] = L[0];
      q['y'] = L[1];
      q['z'] = 0;
      q['vis'] = 0;
    }
    final g = W['gente'] as Map<String, dynamic>;
    for (final p in g.values) {
      final m = p as Map<String, dynamic>;
      if (m['en'] == 'calle') {
        m['vis'] = 0;
        m['en'] = 'dentro';
      }
    }
    W['donde'] = 'dentro';
  }

  /* ---------- the acts (mostrador.md, "Needs") ---------- */

  @override
  Map<String, Act> get ownActs => {
    // `entra` {quien}: comes in at the street door, bell (36: 2, 7; 37: 6; 38: 1, 5, 8)
    'entra': (o) async {
      final quien = o['quien'] as String;
      // coming in at the street door: the story is inside from now (story 36: who was in the street is left outside)
      _adentro();
      _campana();
      if (quien == 'coqui') {
        final q = W['cq'] as Map<String, dynamic>;
        final L = LUGAR['fuera']!;
        q['en'] = 'dentro';
        q['x'] = L[0];
        q['y'] = L[1];
        q['z'] = 0;
        q['vis'] = 1;
        await _salta('puerta');
        final kid = (W['gente'] as Map<String, dynamic>).entries.any(
          (e) =>
              (e.value as Map)['vis'] != 0 &&
              (e.value as Map)['spot'] == 'nino.frente',
        );
        await _salta(kid ? 'coqui.frente2' : 'coqui.frente');
        return;
      }
      final p = _g(quien);
      final w = _p.world('fuera');
      p
        ..['en'] = 'dentro'
        ..['x'] = w[0]
        ..['y'] = w[1]
        ..['z'] = w[2]
        ..['vis'] = 1
        ..['sent'] = 0
        ..['spot'] = 'fuera';
      await _anda(quien, 'puerta');
      await _anda(quien, _destino(quien));
      p['dir'] = 1;
    },
    // `sale` {quien, por}: goes out by the street or the back door (36: 7, 8, 9, 11; 37; 38)
    'sale': (o) async {
      final quien = o['quien'] as String,
          por = (o['por'] as String?) ?? 'puerta';
      if (quien == 'coqui') {
        await _salta('coqui.frente');
        await _salta('puerta');
        await _salta('fuera');
        (W['cq'] as Map<String, dynamic>)['vis'] = 0;
        return;
      }
      final p = _g(quien);
      if (p['vis'] == 0) return;
      final era = p['spot'];
      p['sent'] = 0;
      p['pose'] = 'idle';
      if (por == 'atras') {
        await _anda(quien, 'pepe.atras');
        p['vis'] = 0;
        p['spot'] = 'pepe.fuera';
      } else {
        await _anda(quien, 'puerta');
        await _anda(quien, 'fuera');
        p['vis'] = 0;
        _campana();
      }
      // the next customer steps up to the counter
      if (era == 'cliente') {
        for (final e in (W['gente'] as Map<String, dynamic>).entries) {
          final m = e.value as Map<String, dynamic>;
          if (m['vis'] != 0 && m['spot'] == 'cola1') {
            await _anda(e.key, 'cliente');
          }
        }
      }
    },
    // `lista` {k, hecho}: a picture on the list card lights, or gets its tick; with no k the list is shown (36: 4 to 6, 10;
    // 37: 2 to 4)
    'lista': (o) async {
      final l = W['lista'] as Map<String, dynamic>;
      final k = o['k'];
      l['vis'] = 1;
      if (k is! String) return;
      if (_n(o['hecho']) == 1) {
        (l['hechos'] as List).add(k);
        l['lit'] = null;
        host.SFX.blip();
        await wait(250);
      } else {
        l['lit'] = k;
        host.SFX.blip();
        await wait(150);
      }
    },
    // `baja` {k}: don Pepe takes a thing off the shelf and sets it on the counter (36: 4, 5; 37: 2 to 4)
    'baja': (o) async {
      final k = o['k'] as String, p = _g('pepe'), t = _genero(k);
      await _anda('pepe', 'pepe.estante.$k');
      p['pose'] = 'alcanza';
      await wait(TICK * 3);
      t
        ..['vis'] = 1
        ..['con'] = 'pepe';
      host.SFX.blip();
      p['pose'] = 'mano';
      await _anda('pepe', 'pepe.mostrador');
      final at = _p.world('pepe.mostrador');
      t
        ..['x'] = at[0]
        ..['y'] = at[1]
        ..['z'] = 1;
      await _lleva(t, _libre(), n: 3);
      host.SFX.blip();
      p['pose'] = 'idle';
      p['dir'] = 1;
    },
    // `nohay` {k}: he looks at an empty place on the shelf and shrugs (36: 6)
    'nohay': (o) async {
      final k = o['k'] as String, p = _g('pepe');
      await _anda('pepe', 'pepe.estante.$k');
      p['pose'] = 'alcanza';
      await wait(TICK * 4);
      p['pose'] = 'mano';
      p['dir'] = -_n(p['dir']);
      await wait(TICK * 3);
      p['dir'] = -_n(p['dir']);
      p['pose'] = 'idle';
      await _anda('pepe', 'pepe.mostrador');
      p['dir'] = 1;
    },
    // `guarda` {quien, k}: the thing goes into abuela's bag, or into Carmen's cloth bag held open (36: 4, 5; 37: 5)
    'guarda': (o) async {
      final quien = o['quien'] as String, t = _genero(o['k'] as String);
      if (quien == 'carmen') {
        // her cloth bag, held open on the counter at `bolsa` (the sheet: "the bag being packed")
        var b = _item('bolsa');
        if (b == null || b['spot'] != 'bolsa') {
          b ??= _cosa('bolsa', 'bolsa', 'bolsa');
          b
            ..['vis'] = 1
            ..['con'] = null
            ..['v'] = 'abierta';
          final w = _p.world('bolsa');
          b
            ..['x'] = w[0]
            ..['y'] = w[1]
            ..['z'] = w[2]
            ..['spot'] = 'bolsa';
          if (!_items.contains(b)) _items.add(b);
          host.SFX.blip();
          await wait(TICK * 2);
        }
        _g('pepe')['pose'] = 'mano';
        await _lleva(t, 'bolsa', n: 3);
        t['vis'] = 0;
        t['spot'] = 'en_bolsa';
        host.SFX.blip();
        _g('pepe')['pose'] = 'idle';
        await wait(TICK);
        return;
      }
      t['con'] = quien;
      host.SFX.blip();
      await wait(TICK * 3);
      t
        ..['vis'] = 0
        ..['con'] = null
        ..['spot'] = 'en_bolsa';
    },
    // `bandeja` {que}: `da` don Pepe pushes the tray to abuela and the frog; `quita` abuela hands a quesito to a customer;
    // `comen` n: the ending for three, two or one left (36: 7, 8, 9, 10)
    'bandeja': (o) async {
      final t = _item('quesitos');
      if (t == null) return;
      final que = o['que'];
      if (que == 'da') {
        // OPEN: the sheet names one place for the tray (`bandeja`); "pushes the tray over to abuela and the frog" has no
        // second place: it stays there, don Pepe's hand on it, then open towards them
        final p = _g('pepe');
        p['pose'] = 'mano';
        await wait(TICK * 4);
        p['pose'] = 'saluda0';
        await wait(TICK * 3);
        p['pose'] = 'idle';
      } else if (que == 'quita') {
        // to the customer at the counter
        String? quien;
        for (final e in (W['gente'] as Map<String, dynamic>).entries) {
          if ((e.value as Map)['vis'] != 0 &&
              (e.value as Map)['spot'] == 'cliente') {
            quien = e.key;
          }
        }
        t['v'] = math.max(0, _n(t['v']) - 1);
        final qs = _cosa('quesito.$F', 'quesito', 'bandeja');
        _items.add(qs);
        if (quien != null) {
          await _lleva(qs, 'cosa_a', n: 3);
          qs['con'] = quien;
          await wait(TICK * 4);
        }
        qs['vis'] = 0;
        host.SFX.blip();
      } else if (que == 'comen') {
        final n = _n(o['n']);
        // three: one each, the third into the bag; two: one each; one: abuela breaks it in two, half each
        final medio = n == 1;
        final a = _cosa(
          'quesito.ab',
          'quesito',
          'bandeja',
          v: medio ? 'medio' : null,
        )..['con'] = 'abuela';
        final c = _cosa(
          'quesito.cq',
          'quesito',
          'bandeja',
          v: medio ? 'medio' : null,
        )..['con'] = 'coqui';
        _items
          ..add(a)
          ..add(c);
        t['v'] = math.max(0, _n(t['v']) - (medio ? 1 : 2));
        host.SFX.blip();
        await wait(TICK * 4);
        host.SFX.munch();
        host.bounce(5);
        await wait(TICK * 6);
        a['vis'] = 0;
        c['vis'] = 0;
        if (n == 3) {
          t['v'] = 0;
          host.SFX.blip();
        }
        await wait(TICK * 2);
      }
    },
    // `piensa` {quien, k}: a thought bubble: quesito, piragua (36: 4; 37: 2)
    'piensa': (o) async {
      W['piensa'] = <String, dynamic>{
        'quien': o['quien'],
        'k': o['k'],
        'hasta': F + 40,
      };
      host.SFX.blip();
      await wait(300);
    },
    // `pon2` {a, b}: two things stand on the counter in front of the frog (36: 8, 9); what stood there goes back
    'pon2': (o) async {
      for (final x in _items) {
        if (x['con'] == null &&
            (x['spot'] == 'cosa_a' || x['spot'] == 'cosa_b')) {
          final k = x['id'] as String;
          if (GENEROS.contains(k)) {
            final w = _p.world('estante.$k');
            x
              ..['x'] = w[0]
              ..['y'] = w[1]
              ..['z'] = w[2]
              ..['spot'] = 'estante.$k'
              ..['vis'] = 0;
          }
        }
      }
      for (final (k, spot) in [
        (o['a'] as String, 'cosa_a'),
        (o['b'] as String, 'cosa_b'),
      ]) {
        final t = _genero(k), w = _p.world(spot);
        t
          ..['x'] = w[0]
          ..['y'] = w[1]
          ..['z'] = w[2]
          ..['spot'] = spot
          ..['en'] = 'dentro'
          ..['con'] = null
          ..['vis'] = 1;
        host.SFX.blip();
        await wait(TICK * 2);
      }
    },
    // `sirve` {k, a}: the frog pushes a thing across to a customer (36: 8, 9; 38: 6, 7)
    'sirve': (o) async {
      final k = o['k'] as String, a = o['a'] as String;
      final t = k.startsWith('limber') ? _item(k) : _genero(k);
      if (t == null) return;
      host.bounce(5);
      t['desde'] = t['spot'];
      await _lleva(t, 'cosa_a', n: 3);
      t['con'] = a;
      host.SFX.blip();
      await wait(TICK * 2);
    },
    // `cesta` {quien, k}: a customer opens the basket or bag: the thing in it shows (36: 8, 9). What she was handed goes
    // back to where it stood
    'cesta': (o) async {
      final quien = o['quien'] as String, k = o['k'] as String;
      final p = _g(quien);
      final t = _item(k);
      if (t != null && t['con'] == quien) {
        final back = (t['desde'] as String?) ?? 'cosa_b';
        t['con'] = null;
        final w = _p.world(back);
        t
          ..['x'] = w[0]
          ..['y'] = w[1]
          ..['z'] = w[2]
          ..['spot'] = back;
      }
      p['cesta'] = 'cesta_abierta';
      final dentro = _cosa('cesta.$quien', k, 'cliente')..['con'] = quien;
      _items.add(dentro);
      host.SFX.blip();
      await wait(TICK * 8);
      dentro['vis'] = 0;
      p['cesta'] = 'cesta';
    },
    // `paga` {quien, n}: coins go from a hand, or from the row on the counter, into the dish (36; 37: 2 to 4, 6 to 8; 38)
    'paga': (o) async {
      final quien = o['quien'] as String, n = math.max(1, _n(o['n']));
      final dish = _item('platillo');
      for (var i = 0; i < n; i++) {
        Map<String, dynamic> c;
        final fila = [
          for (final x in _items)
            if (x['k'] == 'moneda' && x['vis'] != 0 && x['spot'] == 'monedas')
              x,
        ];
        if (quien == 'carmen' && fila.isNotEmpty) {
          c = fila.last;
        } else {
          c = _cosa('moneda.$quien.$F.$i', 'moneda', 'compra')..['con'] = quien;
          _items.add(c);
          await wait(TICK * 2);
        }
        if (dish != null) {
          await _lleva(c, 'platillo', n: 3);
          c['vis'] = 0;
          dish['v'] = _n(dish['v']) + 1;
        } else {
          // OPEN: with the freezer on the counter (story 38) the dish's place lies under it (the sheet's notes): there
          // is no place for the coin; it goes to don Pepe's hand
          c['con'] = 'pepe';
          await wait(TICK * 3);
          c['vis'] = 0;
        }
        host.SFX.drop();
        await wait(TICK);
      }
    },
    // `monedas` {n}: Carmen's row of coins on the counter (37: 2 on): from `monedas`, towards +x, `step` apart
    'monedas': (o) async {
      final n = _n(o['n']);
      final s = _p.sheet.spot('monedas'),
          step = (s.raw['step'] as num).toDouble();
      for (var i = 0; i < n; i++) {
        _items.add(_cosa('moneda.fila.$i', 'moneda', 'monedas', dx: i * step));
        host.SFX.drop();
        await wait(TICK);
      }
    },
    // `malta`: don Pepe opens one, sets it down; Carmen drinks it (37: 7, 8)
    'malta': (o) async {
      Map<String, dynamic>? m;
      for (final x in _items) {
        if (x['k'] == 'malta' && x['vis'] != 0 && x['spot'] == 'maltas') m = x;
      }
      if (m == null) return;
      _g('pepe')['pose'] = 'mano';
      await _lleva(m, _libre(), n: 3);
      m['v'] = 'abierta';
      host.tone(2400, 0, .25, 'sawtooth', .02, 900); // the hiss
      _g('pepe')['pose'] = 'idle';
      await wait(TICK * 4);
      m['con'] = 'carmen';
      await wait(TICK * 3);
      host.SFX.munch();
      await wait(TICK * 3);
      m['vis'] = 0;
    },
    // `bolsapapel` {a}: he hands a paper bag over (37: 6, 7, 8)
    'bolsapapel': (o) async {
      // OPEN: the pile of paper bags (with a coin painted on it) has no place in the sheet: the bag appears where a
      // thing is set down (`compra`), then goes into the hand
      final a = o['a'] as String;
      final b = _cosa('bolsapapel.$a.$F', 'bolsapapel', _libre());
      _items.add(b);
      host.SFX.blip();
      await wait(TICK * 3);
      b['con'] = a;
      // the bread just bought goes in it
      for (final x in _items) {
        if (x['vis'] != 0 &&
            x['con'] == null &&
            GENEROS.contains(x['id']) &&
            x['spot'] == 'compra') {
          x['vis'] = 0;
          x['spot'] = 'en_bolsa';
        }
      }
      await wait(TICK * 2);
    },
    // `piraguas` {n}: the ending at the cart: two, one or none (37: 9)
    'piraguas': (o) async {
      // OPEN: the cart stands at `fuera` (no place of its own in the sheet) and nobody has a place beside it: Carmen is
      // shown back just inside the door (`puerta`), with n piraguas in her hand; the piragua man is not drawn
      final n = _n(o['n']);
      final c = _g('carmen');
      await _anda('carmen', 'puerta', en: 'dentro');
      c['vis'] = 1;
      for (var i = 0; i < n; i++) {
        final pg = _cosa('piragua.$i', 'piragua', 'puerta')..['con'] = 'carmen';
        _items.add(pg);
        host.SFX.blip();
        await wait(TICK * 3);
      }
      if (n == 0) {
        c['pose'] = 'mano';
        await wait(TICK * 6);
        c['pose'] = 'idle';
      }
      await wait(TICK * 4);
    },
    // `limber` {que}: bandeja, pon {col_a, col_b, cerca}, vuelve, derrite, cuenta (38)
    'limber': (o) async {
      final que = o['que'];
      void place(String id, String col, String spot) {
        var t = _item(id);
        if (t == null) {
          t = _cosa(id, 'limber', spot);
          _items.add(t);
        }
        final w = _p.world(spot);
        t
          ..['x'] = w[0]
          ..['y'] = w[1]
          ..['z'] = w[2]
          ..['spot'] = spot
          ..['v'] = col
          ..['estado'] = 'vaso'
          ..['con'] = null
          ..['vis'] = 1;
      }

      if (que == 'bandeja') {
        // the two of the opening: the white one at don Pepe's hand (limber_pepe), the orange one by the frog
        // (limber_lejos). OPEN: "on a small tray": the sheet names no place for the tray; it is not drawn
        W['nevera'] = 1;
        place('limber_a', 'white', 'limber_pepe');
        place('limber_b', 'orange', 'limber_lejos');
        host.SFX.blip();
        await wait(TICK * 2);
      } else if (que == 'pon') {
        // OPEN: "one beside the customer, one beside the frog" (`cerca`): the sheet names the two places limber_pepe
        // (limber_a) and limber_lejos (limber_b) and no place beside the customer; `cerca` changes no place
        W['enNevera'] = math.max(0, _n(W['enNevera']) - 2);
        place('limber_a', (o['col_a'] as String?) ?? 'white', 'limber_pepe');
        place('limber_b', (o['col_b'] as String?) ?? 'orange', 'limber_lejos');
        _g('pepe')['pose'] = jsTruthy(_g('pepe')['sent']) ? 'idle' : 'mano';
        host.SFX.blip();
        await wait(TICK * 3);
      } else if (que == 'vuelve') {
        // the one nobody took goes back into the freezer
        for (final id in const ['limber_a', 'limber_b']) {
          final t = _item(id);
          if (t != null &&
              t['vis'] != 0 &&
              t['con'] == null &&
              t['estado'] == 'vaso') {
            t['vis'] = 0;
            W['enNevera'] = _n(W['enNevera']) + 1;
          }
        }
        host.SFX.blip();
        await wait(TICK * 2);
      } else if (que == 'derrite') {
        // the one she was handed, set down on the counter, melts into a puddle
        for (final id in const ['limber_a', 'limber_b']) {
          final t = _item(id);
          if (t == null ||
              t['con'] == null ||
              t['con'] == 'coqui' ||
              t['con'] == 'luis') {
            continue;
          }
          final back = (t['desde'] as String?) ?? 'limber_lejos',
              w = _p.world(back);
          t
            ..['con'] = null
            ..['x'] = w[0]
            ..['y'] = w[1]
            ..['z'] = w[2]
            ..['spot'] = back;
          await wait(TICK * 3);
          t['estado'] = 'lamido';
          await wait(TICK * 3);
          t['estado'] = 'charco';
          host.SFX.drop();
          await wait(TICK * 3);
        }
      } else if (que == 'cuenta') {
        // the freezer opens: what is left can be counted (seen through its glass lid)
        W['neveraAbierta'] = 1;
        host.SFX.blip();
        await wait(TICK * 6);
      }
    },
    // `abanico` {quien}: don Pepe, or abuela, sits down and fans himself (36: 7; 38: 4)
    'abanico': (o) async {
      final quien = o['quien'] as String, p = _g(quien);
      await _anda(quien, quien == 'pepe' ? 'pepe.silla' : 'abuela.silla');
      p['sent'] = 1;
      for (var i = 0; i < 6; i++) {
        p['pose'] = i % 2 == 0 ? 'abanico0' : 'abanico1';
        await wait(TICK * 2);
      }
    },
    // `ninos` {n}: the children come in; n of them get a limber and pay, the others look into the freezer (38: 8)
    'ninos': (o) async {
      // OPEN: the sheet names no place at the counter for three children (only `nino.frente`, one child): they stay at
      // `ninos_puerta`; each who gets a límber holds it up, the others look towards the freezer
      final n = _n(o['n']);
      for (var i = 1; i <= 3; i++) {
        final p = _g('nino$i');
        p['vis'] = 1;
        if (i <= n) {
          p['pose'] = 'moneda';
          await wait(TICK * 2);
          host.SFX.drop();
          p['pose'] = i % 2 == 1 ? 'limber_a' : 'limber_b';
          W['enNevera'] = math.max(0, _n(W['enNevera']) - 1);
          host.SFX.blip();
          await wait(TICK * 3);
        } else {
          p['pose'] = 'idle';
          p['dir'] = 1;
          p['triste'] = 1;
          await wait(TICK * 3);
        }
      }
    },
    // `gallo`: the rooster on the awning crows (36: 1)
    'gallo': (o) async {
      final g = _item('gallo');
      g?['v'] = 1;
      host.tone(700, 0, .18, 'sawtooth', .04, 980);
      host.tone(980, .2, .35, 'sawtooth', .04, 620);
      await wait(TICK * 8);
      g?['v'] = 0;
    },
    // `gesto` {quien, que, a}: a small move of one person (36: 3, 4, 8, 10; 37: 4 to 9; 38: 1, 3, 8, 9)
    'gesto': (o) async {
      final quien = o['quien'] as String, que = o['que'] as String?;
      if (quien == 'coqui') {
        host.bounce(6);
        await wait(TICK * 3);
        return;
      }
      final p = _g(quien);
      if (p['vis'] == 0) return;
      switch (que) {
        case 'saluda':
          for (var i = 0; i < 6; i++) {
            p['pose'] = i % 2 == 0 ? 'saluda0' : 'saluda1';
            await wait(TICK);
          }
          p['pose'] = jsTruthy(p['sent']) ? 'abanico0' : 'idle';
        case 'agacha':
          p['dy'] = 3;
          await wait(TICK * 6);
          p['dy'] = 0;
        case 'lista':
          final l = _cosa('lista.$quien', 'lista', 'compra')..['con'] = quien;
          _items.add(l);
          (W['lista'] as Map<String, dynamic>)['vis'] = 1;
          await wait(TICK * 6);
          l['vis'] = 0;
        case 'mira':
          final a = o['a'] as String?, at = _atOf(p);
          num? tx;
          if (a != null) {
            final t = _item(a == 'plato' ? 'platillo' : a);
            if (t != null) tx = _atOf(t).sx;
            if (a == 'mostrador' || a == 'nevera') {
              tx = _p.at('coqui.mostrador').sx;
            }
          }
          if (tx != null && (tx - at.sx).abs() > 2) {
            p['dir'] = tx > at.sx ? 1 : -1;
          }
          await wait(TICK * 4);
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
        case 'manos':
          p['pose'] = 'manos';
          await wait(TICK * 6);
          p['pose'] = 'idle';
        case 'bolsa':
          // she lifts her cloth bag: from the counter onto her arm
          final b = _item('bolsa');
          if (b != null) {
            b
              ..['con'] = quien
              ..['v'] = null;
          }
          p['pose'] = 'saluda0';
          host.SFX.blip();
          await wait(TICK * 5);
          p['pose'] = 'idle';
        case 'bolsas':
          p['pose'] = 'saluda0';
          await wait(TICK * 6);
          p['pose'] = 'idle';
        case 'monedas':
          for (final x in _items) {
            if (x['k'] == 'moneda' && x['vis'] != 0 && x['spot'] == 'monedas') {
              x['con'] = quien;
            }
          }
          host.SFX.blip();
          await wait(TICK * 3);
          for (final x in _items) {
            if (x['k'] == 'moneda' && x['con'] == quien) x['vis'] = 0;
          }
        case 'levanta':
          p['sent'] = 0;
          p['pose'] = 'idle';
          await _anda(quien, 'pepe.mostrador');
        case 'mano':
          final t = _item((o['a'] as String?) ?? '');
          if (t != null) {
            final at = _atOf(p), tx = _atOf(t).sx;
            if ((tx - at.sx).abs() > 2) p['dir'] = tx > at.sx ? 1 : -1;
          }
          p['pose'] = 'mano';
          await wait(TICK * 5);
          p['pose'] = 'idle';
        default:
          await wait(TICK * 3);
      }
    },
    // `trae` {k}: don Pepe comes in at the back door with a thing and sets it on the counter (36: 10)
    'trae': (o) async {
      final k = o['k'] as String, p = _g('pepe'), t = _genero(k);
      final w = _p.world('pepe.atras');
      p
        ..['en'] = 'dentro'
        ..['x'] = w[0]
        ..['y'] = w[1]
        ..['z'] = w[2]
        ..['vis'] = 1
        ..['spot'] = 'pepe.atras'
        ..['pose'] = 'mano';
      t
        ..['vis'] = 1
        ..['con'] = 'pepe';
      await _anda('pepe', 'pepe.mostrador');
      final m = _p.world('pepe.mostrador');
      t
        ..['x'] = m[0]
        ..['y'] = m[1]
        ..['z'] = 1;
      await _lleva(t, _libre(), n: 3);
      host.SFX.blip();
      p['pose'] = 'idle';
    },
    // `lame` {quien}: the frog, or Luis, picks up his límber and licks it (38: 2, 3)
    'lame': (o) async {
      final quien = o['quien'] as String;
      final t = _item(quien == 'coqui' ? 'limber_b' : 'limber_a');
      if (t == null) return;
      t['con'] = quien;
      t['estado'] = 'lamido';
      if (quien == 'coqui') host.bounce(5);
      host.SFX.munch();
      await wait(TICK * 6);
    },
    // `ir` {a}: the shared act (kit.js comunes.ir: hops of about 30 px, 1 to 4), on the sheet's spots, with the frog's
    // height kept (on the counter he stands on its top, z 1: in front of what is behind it)
    'ir': (o) async {
      final a = o['a'], key = jsTruthy(a) ? a : o['en'];
      if (key is! String || !LUGAR.containsKey(key)) return;
      await _salta(
        key.startsWith('mostrador')
            ? 'coqui.mostrador'
            : (_p.has('coqui.$key') ? 'coqui.$key' : key),
      );
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
    // `ya`: waits for an act that was started with `suelto: 1` (no act of this scene runs loose: nothing to wait for)
    'ya': (o) async {},
  };

  /// A paper fan (El balcón's), for abuela sitting.
  static void abanicoDe(Ctx g, num x, num y) => abanico(g, x, y, 8, -60, 60);
}
