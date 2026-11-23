// El cruce (place 5, La calle, scene 4; stories 57 to 59): a NEW scene, written from its script's "Needs" list
// (historia/notas/guiones/cruce.md) on its set (cruce_set.dart) and its sheet (cruce-sheet.json, read by SceneSheet).
// There is no old scene file: every act is this file's, each doing on screen what the Needs list says, every place from
// the sheet (a spot's world point, a thing's box, the two views, the depth rule). Where the sheet names no place, or the
// script does not settle what an act shows, the act does the plainest thing that keeps the story playing and says so in
// a comment starting `OPEN:` (page 13 lists them for the content lane).
//
// The drawing (the sheet's `front`): every person and small thing stands with its feet's bottom edge on its spot's row
// and its middle on its column (rules.anchor); its pixel is hidden by every set pixel nearer the camera than the upright
// plane through its feet plus `front.bias` (front.plane); between two sprites the nearer pixel wins (front.sprites); the
// frog's pixels are never hidden by a grown-up's (the sheet's rule). There are no cars in this scene; a bicycle is a
// sprite standing in front of its rider (cruce-preview.html: its depth .15 nearer).
//
// The streets are turned 45 degrees (rules.uv): a walk out along a street goes from where one stands to the crossing,
// along the street to the sheet's exit (salida_*), and on along the same line until the sprite has left the picture, as
// the sheet's check salida-whole walks it; coming up from the bottom is the same walk up the street the frog comes up,
// ending at the sheet's abajo.* spots.
// ignore_for_file: non_constant_identifier_names

import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/src/calle/calle_cast.dart';
import 'package:coqui_scenes/src/colmado/colmado_cast.dart';
import 'package:coqui_scenes/src/cruce/cruce_places.dart';
import 'package:coqui_scenes/src/cruce/cruce_set.dart';
import 'package:coqui_scenes/src/cruce/cruce_sprites.dart';
import 'package:coqui_scenes/src/esquina/esquina_sprites.dart'
    show mkPepeEscoba;
import 'package:coqui_scenes/src/scene_set.dart';
import 'package:coqui_scenes/src/sheet_cache.dart';

/// The scene "El cruce", made from its sheet (read first: `loadScene`).
Scene createCruce() => Cruce(sceneSheetOf('cruce'));

int _round(num v) => (v + 0.5).floor();

int _n(Object? v) => v is num ? v.toInt() : 0;

/// One sprite of the sprite layer, placed: its picture, its top left on the 240 x 216 picture, the screen row of its
/// feet and the depth there (front.plane).
class CruceItem {
  CruceItem(
    this.s,
    this.left,
    this.top,
    this.sy,
    this.d, {
    this.tag,
    this.grown = false,
    this.flat = false,
  });

  /// Lying on the ground (a puddle): under every sprite, over the set.
  final bool flat;

  /// A grown-up (whose pixels never hide the frog).
  final bool grown;

  final Sprite s;
  final int left, top;
  final num sy;
  final double d;

  /// Who or what it is (the rules' tests read it: `persona:<id>`, `coqui`, `cosa:<id>`, `bici:<id>`).
  final String? tag;
}

/// The people of the place (the speaker keys and `quien` of the three stories), Canelo and the bebé.
const List<String> _people = [
  'bebe',
  'abuela',
  'abuelo',
  'mama',
  'papa',
  'luis',
  'carmen',
  'senora',
  'senor',
  'pepe',
  'obrero',
  'piraguero',
  'perro',
];

const Set<String> _notGrown = {'luis', 'carmen', 'bebe', 'perro'};

class Cruce extends Escena implements SetScene, SetOverSprites {
  Cruce(this.ss) : sheet = ss.legacy() {
    _p = CrucePlaces(ss);
    CAM = {'wide': _p.view('wide'), 'plaza': _p.view('plaza')};
    LUGAR = {
      for (final e in _frogPlaces.entries) e.key: _frogAt(_p.at(e.value)),
    };
    cosas = _things();
  }

  /// The new scene's sheet (SceneSheet).
  final SceneSheet ss;

  @override
  final Sheet sheet;

  late final CrucePlaces _p;

  /// The scene's places, from its sheet.
  CrucePlaces get places => _p;

  @override
  String get id => 'cruce';

  @override
  late final Map<String, List<num>> CAM;

  late final Map<String, List<num>> LUGAR;

  @override
  Map<String, List<num>> get lugar => LUGAR;

  @override
  late final List<Thing> cosas;

  @override
  PpEngine newEngine({bool still = false}) => cruceEngine(still: still);

  @override
  PpEngine get projection => _p.e;

  // where the frog's `ir` goes, by the stories' names: the sheet's spots of the frog
  static const Map<String, String> _frogPlaces = {
    'abajo': 'abajo.coqui',
    'cruce': 'coqui.cruce',
    'bici': 'coqui.bici',
    'asiento_plaza': 'asiento.coqui',
    'plaza': 'coqui.plaza',
    'tras_papa': 'tras_papa',
    'delante_canelo': 'delante_canelo',
    'detras_canelo': 'detras_canelo',
    'lado_abuela': 'lado_abuela',
    'delante_abuela': 'delante_abuela',
    'hueco': 'hueco',
  };

  /// The sheet's spot of the frog's place [key] (`lugar`'s key), or null.
  String? frogSpotOf(String key) => _frogPlaces[key];

  // the frog's top left for a spot (rules.anchor: mkCoqui's column 16 on sx, its row 25 on sy)
  List<num> _frogAt(CruceAt a) => [_round(a.sx) - 16, _round(a.sy) - 25, 1];

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

  Map<String, dynamic> _person(
    String spot, {
    int vis = 1,
    String pose = 'idle',
  }) {
    final w = _p.world(spot);
    return <String, dynamic>{
      'x': w[0],
      'y': w[1],
      'z': w[2],
      'spot': spot,
      'vis': vis,
      'dir': 1,
      'pose': pose,
      'dy': 0,
    };
  }

  @override
  Map<String, dynamic> fresh(Map<String, dynamic> story) {
    final acts = _actsOf([story['beats'], story['final']]);
    bool has(String a) => acts.any((o) => o['act'] == a);
    final gente = <String, dynamic>{};
    var hist = 0;
    String frog;
    if (has('botella')) {
      // story 57: abuela and the frog come up to the crossing; she has a letter in her hand and her bag with the bottle
      hist = 57;
      gente['abuela'] = _person('abajo.abuela');
      frog = 'abajo.coqui';
    } else if (has('hielo')) {
      // story 58: Luis on his bicycle with the frog on the rack; the obrero behind the cones (cruce-preview.html m3)
      hist = 58;
      gente['luis'] = _person('abajo.bici')..['bici'] = 1;
      gente['obrero'] = _person('conos.obrero');
      frog = 'coqui.bici';
    } else {
      // story 59: papá at his camera with his back to us, the frog behind him (the script's "Start")
      hist = 59;
      gente['papa'] = _person('papa_camara');
      frog = 'tras_papa';
    }
    final at = _p.at(frog);
    final q = _frogAt(at);
    return {
      'hist': hist,
      'hora': hist == 58 ? 'tarde' : (hist == 59 ? 'ocaso' : 'mediodia'),
      'cerrada': hist == 58 ? 1 : 0,
      'gente': gente,
      'cosas': <dynamic>[],
      'carta': hist == 57 ? 1 : 0,
      'bolsa': hist == 57 ? 'abuela' : null,
      'bolsita': 0,
      'botella': null,
      'tumbada': 0,
      'lleva': <dynamic>[],
      'enAsiento': <dynamic>[],
      'hielo': null,
      'hieloEn': 'bici',
      'gotas': null,
      'mapa': null,
      'piraguas': null,
      'hojas': null,
      'camara': hist == 59 ? 'papa' : null,
      'foto': null,
      'flash': null,
      'fotos': <dynamic>[],
      'fotosVer': 0,
      'tarjeta': null,
      'marcas': null,
      'cqz': at.z,
      'cqw': [at.x, at.y, at.z],
      'cqxy': [q[0], q[1]],
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

  // the sheet's setKey: "hora + cerrada", e.g. "mediodia-0". Story 59 takes `ocaso` (the sheet's setKey note: "57
  // mediodia, 58 tarde, 59 ocaso"; its story file sets hora tarde, which is the sheet's reading of "late afternoon")
  @override
  String setKey(Map<String, dynamic> W) {
    final h = W['hist'] == 59
        ? 'ocaso'
        : (const ['mediodia', 'tarde', 'ocaso'].contains(W['hora'])
              ? W['hora'] as String
              : 'mediodia');
    final c = jsTruthy(W['cerrada']) && W['cerrada'] != '0' ? 1 : 0;
    return '$h-$c';
  }

  bool get _cerrada => setKey(W).endsWith('-1');

  @override
  void buildSet(PpEngine e, PpBuild b, Map<String, dynamic> W) =>
      buildSetFor(e, b, setKey(W));

  final Map<PpEngine, CruceSet> _sets = {};

  @override
  void buildSetFor(PpEngine e, PpBuild b, String key) =>
      (_sets[e] ??= CruceSet(e, b)).buildSet(CruceState.fromKey(key));

  // the frog casts his shadow in the engine (shadows.byCharacter.coqui); never the old one
  @override
  bool get frogShadow => false;

  /* ---------- where everybody is ---------- */

  Map<String, dynamic> get _gente => W['gente'] as Map<String, dynamic>;
  List<Map<String, dynamic>> get _items =>
      (W['cosas'] as List).cast<Map<String, dynamic>>();

  Map<String, dynamic> _g(String id) =>
      (_gente[id] ??= _person('centro', vis: 0)) as Map<String, dynamic>;

  bool _seen(String id) {
    final p = _gente[id] as Map<String, dynamic>?;
    return p != null && p['vis'] != 0;
  }

  CruceAt _atOf(Map<String, dynamic> o) =>
      _p.atWorld(o['x'] as num, o['y'] as num, o['z'] as num);

  // the frog's world point under his feet (at the height of his place: the rack, the seat)
  CruceAt _frogPoint(Map<String, dynamic> q) {
    // where the scene put him last (a spot, a step of a walk): that point, while the runner has not moved him since
    final w = W['cqw'], xy = W['cqxy'];
    if (w is List && xy is List && xy[0] == q['x'] && xy[1] == q['y']) {
      return _p.atWorld(w[0] as num, w[1] as num, w[2] as num);
    }
    final b = host.frogBox(q);
    final z = (W['cqz'] as num?) ?? 0;
    return _p.fromScreen(b.x + b.w / 2, (q['y'] as num) + 25, z);
  }

  /* ---------- sprites ---------- */

  static final Map<String, Sprite> _sprites = {};
  static Sprite _spr(String key, Sprite Function() make) =>
      _sprites[key] ??= make();

  // the persona pose of a pose word (callePerson's): idle, saluda0, saluda1, mano, ojos, taza
  static String _persona(String pose) => switch (pose) {
    'saluda0' => 'wave0',
    'saluda1' => 'wave1',
    'mano' => 'offer',
    'ojos' => 'ojos',
    'taza' => 'taza',
    'foto' => 'foto',
    _ => 'idle',
  };

  // a person's sprite and the point of it that stands on the spot (rules.anchor)
  ({Sprite s, int ax, int ay, String key, bool turns}) _personSprite(
    String id,
    Map<String, dynamic> p,
    bool open,
  ) {
    final pose = (p['pose'] as String?) ?? 'idle';
    final escoba = jsTruthy(p['escoba']);
    final cuerda = jsTruthy(p['cuerda']);
    final key = 'p$id$pose$open$escoba$cuerda${(F >> 2) % 2}';
    switch (id) {
      case 'abuela':
        if (pose == 'sentada' || pose == 'fan0' || pose == 'fan1') {
          // abuela sitting (mkAbuelaS): column 17 and her lap's row 36 on the seat's spot
          final s = _spr(
            key,
            () => mkAbuelaS(pose == 'sentada' ? 'idle' : pose, open, false),
          );
          return (s: s, ax: 17, ay: 36, key: key, turns: false);
        }
      case 'luis':
        if (pose == 'sentado') {
          // a child sitting: column 24 and the lap row 16 + 2 t + 3 = 33 (rules.anchor)
          final s = _spr(
            key,
            () => mkPersona(calleWho('luis'), 'idle', open, true),
          );
          return (s: s, ax: PX, ay: 33, key: key, turns: false);
        }
      case 'papa':
        if (pose == 'rodillas') {
          // kneeling: the sitting drawing with its feet on the spot (rules.anchor's stand-in)
          final s = _spr(
            key,
            () => mkPersona(calleWho('papa'), 'idle', open, true),
          );
          return (s: s, ax: PX, ay: inkBottom(s), key: key, turns: false);
        }
        if (pose == 'foto') {
          final s = _spr(
            key,
            () => mkPersona(calleWho('papa'), 'foto', open, false),
          );
          return (s: s, ax: PX, ay: inkBottom(s), key: key, turns: true);
        }
      case 'abuelo':
        final s = _spr(key, () => mkAbuelo(_persona(pose), open: open));
        return (s: s, ax: PX, ay: inkBottom(s), key: key, turns: true);
      case 'piraguero':
        final s = _spr(key, () => mkPiraguero(_persona(pose), open: open));
        return (s: s, ax: PX, ay: inkBottom(s), key: key, turns: true);
      case 'bebe':
        // the bebé (kit.js mkBebe, a sitting baby: the sheet's stand-in), column 13 and its bottom edge
        final f = pose == 'clap' && (F >> 2) % 2 == 1;
        final s = _spr(
          'bebe$pose$f',
          () => mkBebe(pose == 'clap' ? 'clap' : 'idle', f),
        );
        return (
          s: s,
          ax: 13,
          ay: inkBottom(s),
          key: 'bebe$pose$f',
          turns: false,
        );
      case 'perro':
        // Canelo lying (mkPerro('lie')), column 15 and its bottom edge; trotting in: running
        final run = pose == 'run', f = run && (F >> 1) % 2 == 1;
        final s = _spr('perro$pose$f', () => mkPerro(run ? 'run' : 'lie', f));
        return (
          s: s,
          ax: 15,
          ay: inkBottom(s),
          key: 'perro$pose$f',
          turns: true,
        );
      case 'pepe':
        if (escoba) {
          final s = _spr(key, () => mkPepeEscoba(pose, open: open));
          return (s: s, ax: PX, ay: inkBottom(s), key: key, turns: true);
        }
    }
    final a = callePerson(id, pose, open: open);
    var s = a.s;
    if (cuerda) {
      // Carmen with her skipping rope: the rope's arc over her head, its ends at her hands
      s = _spr(key, () => overSprite(a.s, [(mkCuerda(30, 26), PX - 15, 0)]));
    }
    return (s: s, ax: a.ax, ay: a.ay, key: key, turns: true);
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

  // the sprite of a small thing
  Sprite _thingSprite(Map<String, dynamic> o) {
    final k = o['k'] as String, v = o['v'];
    switch (k) {
      case 'charco':
        return _spr('charco${_n(v)}', () => mkCharco(_n(v) == 0 ? 14 : _n(v)));
      case 'carrito':
        final hielo = W['hieloEn'] == 'carro' && _n(W['hielo']) > 0;
        return _spr('carrito$hielo', () => mkCarrito(hielo: hielo));
      case 'bici':
        return _spr('bicisola', () => mkBiciFrente(cesta: true, hielo: 0));
      case 'camara':
        return _spr('camara', mkCamara);
      case 'cometa':
        return _spr('cometa', mkCometa);
      case 'pan':
        return _spr('pan', mkPan);
      case 'hoja':
        return _spr('hoja$v', () => mkHoja(hecha: true, mala: v == 'mala'));
    }
    return _spr('bolsa', mkBolsa);
  }

  // what someone holds at the hand: the place beside the sprite (its right edge, at the height of a hand), its depth a
  // little nearer than the holder's (the sheet gives no hand: a guess)
  ({int x, int y, double d, num sy})? _handOf(
    CruceItem it, {
    bool left = false,
  }) {
    final b = inkBox(it.s, it.left, it.top);
    if (b == null) return null;
    final x = left ? b[0] - 2 : b[0] + b[2] - 3;
    final y = b[1] + (b[3] * .55).round();
    return (x: x.toInt(), y: y.toInt(), d: it.d + .05, sy: it.sy);
  }

  /// Every sprite of the frame [w] but the frog, placed: the people, the bicycles, the small things and what is held.
  /// The rules' tests read it; [draw] draws it.
  List<CruceItem> items(Map<String, dynamic> w, int a) {
    final out = <CruceItem>[];
    final talk = _talker();
    final gente = (w['gente'] as Map<String, dynamic>?) ?? const {};
    final byId = <String, CruceItem>{};
    for (final en in gente.entries) {
      final p = en.value as Map<String, dynamic>;
      if (p['vis'] == 0) continue;
      final open = talk == en.key && a % 2 == 1;
      final sp = _personSprite(en.key, p, open);
      final at = _atOf(p);
      final dir = sp.turns && _n(p['dir']) < 0 ? -1 : 1;
      final s = dir < 0 ? _mirrorOf(sp.key, sp.s) : sp.s;
      final ax = dir < 0 ? sp.s.w - 1 - sp.ax : sp.ax;
      final sx = _round(at.sx), sy = _round(at.sy) + _n(p['dy']);
      final it = CruceItem(
        s,
        sx - ax,
        sy - sp.ay,
        sy,
        at.d,
        tag: 'persona:${en.key}',
        grown: !_notGrown.contains(en.key),
      );
      out.add(it);
      byId[en.key] = it;
      // a bicycle seen end-on stands in front of its rider (cruce-preview.html: the bici at the rider's spot, .15
      // nearer): don Pepe's in 57, Luis's with the basket and the ice in 58
      if (jsTruthy(p['bici'])) {
        final luis = en.key == 'luis';
        final hielo = luis && w['hieloEn'] == 'bici' ? _n(w['hielo']) : 0;
        final bs = _spr(
          'bici$luis$hielo',
          () => mkBiciFrente(cesta: luis, hielo: hielo),
        );
        out.add(
          CruceItem(
            bs,
            sx - 10,
            sy - inkBottom(bs),
            sy,
            at.d + .15,
            tag: 'bici:${en.key}',
          ),
        );
      }
    }
    for (final o
        in (w['cosas'] as List? ?? const []).cast<Map<String, dynamic>>()) {
      if (o['vis'] == 0) continue;
      final s = _thingSprite(o);
      final at = _atOf(o);
      final sx = _round(at.sx) + _n(o['dx']), sy = _round(at.sy) + _n(o['dy']);
      final flat = o['k'] == 'charco';
      out.add(
        CruceItem(
          s,
          sx - s.w ~/ 2,
          flat ? sy - s.h ~/ 2 : sy - inkBottom(s),
          flat ? sy + s.h ~/ 2 : sy,
          at.d + ((o['dd'] as num?) ?? 0).toDouble(),
          tag: 'cosa:${o['id']}',
          flat: flat,
        ),
      );
    }
    void held(
      String tag,
      Sprite s,
      CruceItem? by, {
      bool left = false,
      int up = 0,
    }) {
      if (by == null) return;
      final h = _handOf(by, left: left);
      if (h == null) return;
      out.add(
        CruceItem(
          s,
          h.x - s.w ~/ 2,
          h.y - s.h - up,
          h.sy,
          h.d,
          tag: 'cosa:$tag',
        ),
      );
    }

    // abuela's: the letter, the small bag, her bag with the bottle standing on it
    final ab = byId['abuela'];
    if (jsTruthy(w['carta'])) held('carta', _spr('carta', mkCarta), ab, up: 4);
    if (jsTruthy(w['bolsita'])) {
      held(
        'bolsita',
        _spr('bolsita', mkBolsita),
        ab,
        up: (gente['abuela'] as Map?)?['pose'] == 'mano' ? 10 : 0,
      );
    }
    final n = w['botella'];
    if (w['bolsa'] == 'abuela' && ab != null) {
      held('bolsa', _spr('bolsa', mkBolsa), ab, up: -14);
      if (n != null) {
        held('botella', _botella(w), ab, up: -14 + 11);
      }
    }
    if (w['bolsa'] == 'asiento') {
      final at = _p.at('asiento.bolsa');
      final bs = _spr('bolsa', mkBolsa);
      final sx = _round(at.sx), sy = _round(at.sy);
      out.add(
        CruceItem(
          bs,
          sx - bs.w ~/ 2,
          sy - inkBottom(bs),
          sy,
          at.d,
          tag: 'cosa:bolsa',
        ),
      );
      // the bottle standing on the bag (cruce-preview.html: 11 px up, .01 nearer); tipping, on its side beside it
      if (n != null && w['botellaCon'] == null) {
        final bt = _botella(w);
        final up = jsTruthy(w['tumbada']) ? 4 : 11;
        out.add(
          CruceItem(
            bt,
            sx - bt.w ~/ 2 + (jsTruthy(w['tumbada']) ? 8 : 0),
            sy - up - inkBottom(bt),
            sy,
            at.d + .01,
            tag: 'cosa:botella',
          ),
        );
      }
    }
    final con = w['botellaCon'] as String?;
    if (con != null && n != null) {
      final by = con == 'coqui' ? null : byId[con];
      if (by != null) held('botella', _botella(w), by, up: 4);
    }
    // the things on the seat (the frog puts them there: hueco, the gap, the sheet's seat point)
    final en = (w['enAsiento'] as List? ?? const []).cast<String>();
    if (en.isNotEmpty) {
      final at = _p.at('hueco');
      var x = _round(at.sx) - 8 * (en.length - 1);
      for (final k in en) {
        final s = _thingSprite({'k': k, 'v': null});
        final sy = _round(at.sy);
        out.add(
          CruceItem(
            s,
            x - s.w ~/ 2,
            sy - inkBottom(s),
            sy,
            at.d,
            tag: 'cosa:$k',
          ),
        );
        x += 16;
      }
    }
    // the ice in Luis's hands (58's ending, before it is on the cart)
    if (w['hieloEn'] == 'luis' && _n(w['hielo']) > 0) {
      final s = _spr('hielo${w['hielo']}', () => _hielo(_n(w['hielo'])));
      held('hielo', s, byId['luis']);
    }
    // the piraguas
    final pi = (w['piraguas'] as Map?)?.cast<String, dynamic>();
    if (pi != null) {
      for (final e in pi.entries) {
        if (e.key == 'coqui') continue;
        final s = _spr(
          'piragua${e.value}',
          () => mkPiraguaCruce(dos: e.value == 2),
        );
        held('piragua_${e.key}', s, byId[e.key], up: 2);
      }
    }
    // what the frog holds: the kite, the loaf, the bottle, a piragua
    final f = _frogHeld(w);
    if (f.isNotEmpty) {
      final q = w['cq'] as Map<String, dynamic>;
      if (jsTruthy(q['vis'])) {
        final b = host.frogBox(q), at = _frogPoint(q);
        var x = b.x - 2;
        for (final s in f) {
          out.add(
            CruceItem(
              s,
              _round(x - s.w / 2),
              _round((q['y'] as num) + 22 - s.h),
              at.sy,
              at.d + .05,
              tag: 'cosa:lleva',
            ),
          );
          x += b.w + 4;
        }
      }
    }
    return out;
  }

  List<Sprite> _frogHeld(Map<String, dynamic> w) {
    final out = <Sprite>[];
    for (final k in (w['lleva'] as List? ?? const []).cast<String>()) {
      out.add(_thingSprite({'k': k, 'v': null}));
    }
    if (w['botellaCon'] == 'coqui' && w['botella'] != null) {
      out.add(_botella(w));
    }
    final pi = (w['piraguas'] as Map?)?['coqui'];
    if (pi != null) {
      out.add(_spr('piragua$pi', () => mkPiraguaCruce(dos: pi == 2)));
    }
    return out;
  }

  Sprite _botella(Map<String, dynamic> w) {
    final n = _n(w['botella']), t = jsTruthy(w['tumbada']);
    return _spr('botella$n$t', () => mkBotellaAgua(n, tumbada: t));
  }

  // the block of ice held (in three sizes), 12 x 8 at most
  static Sprite _hielo(int n) {
    final w = [0, 5, 8, 12][n.clamp(0, 3)], h = [0, 3, 5, 7][n.clamp(0, 3)];
    final b = Buf(w + 2, h + 2);
    b.rect(1, 1, w, h, hexColour('#BCE4F4'));
    b.rect(1, 1, w, 1, hexColour('#F0FAFF'));
    return b.outline().done();
  }

  /* ---------- drawing ---------- */

  PpEngine? _frameEngine;
  Float32List? _setZ;
  final Uint32List _layer = Uint32List(240 * 216);
  final Float32List _lz = Float32List(240 * 216);
  final Uint8List _isG = Uint8List(240 * 216);

  @override
  void setFramed(PpEngine engine, BakedSet baked, Map<String, dynamic> W) {
    _frameEngine = engine;
    _setZ = baked.zb;
  }

  static final double _t30 = math.tan(math.pi / 6);

  /// Composes [it] into a layer ([layer], depths [lz], grown-ups' marks [isG]) by the sheet's rule: hidden where
  /// [setZ] is nearer than its plane plus [bias], or another sprite's pixel is nearer than its plane (front.sprites: a
  /// tie within .001 goes to the later); the frog's pixels are never hidden by a grown-up's. Returns how many of its
  /// pixels it drew.
  static int put(
    CruceItem it,
    Uint32List layer,
    Float32List lz,
    Uint8List isG,
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
      final plane = it.flat ? -1e8 : it.d + (it.sy - (Y + .5)) * _t30 / S;
      for (var x = 0; x < s.w; x++) {
        final c = s.px[y * s.w + x];
        if (c >>> 24 == 0) continue;
        final X = it.left + x;
        if (X < 0 || X >= w0) continue;
        final i = Y * w0 + X;
        if (!it.flat && setZ != null && setZ[i] > plane + bias) {
          hidden?.call(i, 'set');
          continue;
        }
        if (lz[i] > plane + .001 && !(it.tag == 'coqui' && isG[i] == 2)) {
          hidden?.call(i, 'sprite');
          continue;
        }
        lz[i] = plane;
        layer[i] = c;
        isG[i] = it.grown ? 2 : 0;
        n++;
      }
    }
    return n;
  }

  /// The frog as the game draws him (juego.js frog, at the depth of his feet), placed; null when he is not seen.
  CruceItem? frogItem(Map<String, dynamic> W, int a) {
    final q = W['cq'] as Map<String, dynamic>;
    if (!jsTruthy(q['vis'])) return null;
    final b = host.frogBox(q), at = _frogPoint(q);
    final ox = b.x.toInt() - 16, oy = b.y.toInt() - 24;
    final px = Uint32List(64 * 64);
    final g = Ctx(px, 64, 64)..translate(-ox.toDouble(), -oy.toDouble());
    host.frog(g, q, a);
    return CruceItem(
      Sprite(64, 64, px),
      ox,
      oy,
      _round(at.sy),
      at.d,
      tag: 'coqui',
    );
  }

  /// [items] and the frog: every sprite that stands, placed (the puddles first: they lie on the ground).
  List<CruceItem> placed(Map<String, dynamic> W, int a) {
    final all = items(W, a);
    final f = frogItem(W, a);
    if (f != null) all.add(f);
    all.sort((x, y) => (y.flat ? 1 : 0) - (x.flat ? 1 : 0));
    return all;
  }

  /// Composes the whole sprite layer of [W] into [layer] ([lz], [isG]). The rules' tests call it with a [hidden] that
  /// counts what hides what.
  void compose(
    Map<String, dynamic> W,
    int a,
    Uint32List layer,
    Float32List lz,
    Uint8List isG,
    Float32List? setZ, {
    void Function(CruceItem it, int i, String why)? hidden,
  }) {
    layer.fillRange(0, layer.length, 0);
    lz.fillRange(0, lz.length, -1e9);
    isG.fillRange(0, isG.length, 0);
    final bias = _p.bias, S = _p.e.S;
    for (final it in placed(W, a)) {
      put(
        it,
        layer,
        lz,
        isG,
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
    compose(W, a, _layer, _lz, _isG, setZ);
    c.drawImage(Sprite(240, 216, _layer), 0, 0);
    // drops falling from the basket
    final gt = W['gotas'] as Map<String, dynamic>?;
    if (gt != null) {
      final s = _spr('gota', mkGota);
      for (var i = 0; i < 3; i++) {
        final y = (gt['y'] as num) + ((F + i * 3) % 9) * 2;
        c.drawImage(s, _round((gt['x'] as num) - 4 + i * 4), _round(y));
      }
    }
  }

  /* ---------- the cards: the road of 58, the sheets of 59, the two rounds; the photo shown big ---------- */

  @override
  void hud(Ctx c, Map<String, dynamic> W, int a) {
    var x0 = 3;
    if (W['mapa'] != null) {
      // the card's road: two steps, the cart at its end, the bicycle at its start, a step nearer after each right ride
      const w = 64;
      tarjeta(c, x0, 3, w, 24);
      fr(c, x0 + 6, 18, w - 12, 3, 0xFF8A9098);
      for (final k in const [0, 1, 2]) {
        fr(c, x0 + 7 + k * 22, 17, 2, 5, 0xFF505860);
      }
      final cart = _spr('carritoMini', () => _mini(mkCarrito(), 2));
      c.drawImage(cart, x0 + w - cart.w - 3, 5);
      final bici = _spr('biciMini', () => _mini(mkBici(cesta: true), 2));
      c.drawImage(bici, x0 + 2 + _n(W['mapa']).clamp(0, 2) * 18, 8);
      x0 += w + 4;
    }
    if (W['hojas'] != null) {
      // the sheets left in the camera
      const w = 6 + 3 * 11;
      tarjeta(c, x0, 3, w, 18);
      final n = _n(W['hojas']);
      for (var i = 0; i < 3; i++) {
        final s = _spr('hojaVacia', mkHoja);
        if (i < n) c.drawImage(s, x0 + 4 + i * 11, 7);
      }
      x0 += w + 4;
    }
    if (jsTruthy(W['tarjeta'])) _rounds(c, W, x0);
    // the flash
    final fl = W['flash'];
    if (fl is num && F - fl < 3) fr(c, 0, 0, 196, 216, 0xFFFFFFFF);
    // a photo sheet shown big: the picture as it is now (the set and the sprites), spoiled when the frog was not
    // where papá said
    final ft = W['foto'] as Map<String, dynamic>?;
    if (ft != null) _fotoGrande(c, W, ft);
    // the photos of the ending, laid out
    if (jsTruthy(W['fotosVer'])) {
      final fs = (W['fotos'] as List).cast<String>();
      final y = 60, s0 = 196 ~/ 2 - (fs.length * 30) ~/ 2;
      for (var i = 0; i < fs.length; i++) {
        final s = _spr(
          'hojaG${fs[i]}',
          () => _mini2(mkHoja(hecha: true, mala: fs[i] != 'ok')),
        );
        c.drawImage(s, s0 + i * 30, y);
      }
    }
  }

  // a sprite at half size (every other pixel)
  static Sprite _mini(Sprite s, int k) {
    final w = (s.w / k).ceil(), h = (s.h / k).ceil();
    final px = Uint32List(w * h);
    for (var y = 0; y < h; y++) {
      for (var x = 0; x < w; x++) {
        px[y * w + x] = s.px[(y * k) * s.w + x * k];
      }
    }
    return Sprite(w, h, px);
  }

  // a sprite at three times its size
  static Sprite _mini2(Sprite s) {
    const k = 3;
    final w = s.w * k, h = s.h * k;
    final px = Uint32List(w * h);
    for (var y = 0; y < h; y++) {
      for (var x = 0; x < w; x++) {
        px[y * w + x] = s.px[(y ~/ k) * s.w + x ~/ k];
      }
    }
    return Sprite(w, h, px);
  }

  void _fotoGrande(Ctx c, Map<String, dynamic> W, Map<String, dynamic> ft) {
    final e = _frameEngine;
    // the window of the photo over the picture: the seat and the family, in the plaza view (a guess)
    const px0 = 124, py0 = 96, w = 112, h = 104;
    final dx = 196 ~/ 2 - w ~/ 2 - 4, dy = 40;
    fr(c, dx, dy, w + 8, h + 14, 0xFFFCFCF8);
    fr(c, dx, dy, w + 8, 1, 0xFF404040);
    final pic = Uint32List(w * h);
    for (var y = 0; y < h; y++) {
      for (var x = 0; x < w; x++) {
        final i = (py0 + y) * 240 + px0 + x;
        final l = _layer[i];
        pic[y * w + x] = l >>> 24 != 0
            ? l
            : (e != null ? e.pix[i] | 0xFF000000 : 0xFF8AB0D8);
      }
    }
    c.drawImage(Sprite(w, h, pic), dx + 4, dy + 4);
    if (ft['ok'] == 0 || ft['ok'] == false) {
      final f = frogItem(W, 0);
      if (f != null) {
        if (ft['como'] == 'espalda') {
          // his back over a face: the frog big, near the camera
          final big = _mini2(_crop(f.s));
          c.drawImage(big, dx + 4 + w ~/ 2 - big.w ~/ 2, dy + 4);
        } else {
          // only his eyes at the edge
          final eyes = _mini2(_crop(f.s, rows: 7));
          c.drawImage(eyes, dx + w - eyes.w ~/ 2, dy + h - eyes.h + 4);
        }
      }
    }
  }

  // a sprite cut to its drawn pixels ([rows]: only its top rows)
  static Sprite _crop(Sprite s, {int? rows}) {
    final b = _ink(s);
    if (b == null) return s;
    final h = rows == null ? b[3] : math.min(rows, b[3]);
    final px = Uint32List(b[2] * h);
    for (var y = 0; y < h; y++) {
      for (var x = 0; x < b[2]; x++) {
        px[y * b[2] + x] = s.px[(b[1] + y) * s.w + b[0] + x];
      }
    }
    return Sprite(b[2], h, px);
  }

  void _rounds(Ctx c, Map<String, dynamic> W, int x0) {
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

  // castShadow(x, y, 0, radius) at the world x, y of whoever stands on the ground (shadows.at; none sitting, kneeling, on
  // the seat, the rack or the wall: shadows.none, onSeat)
  @override
  List<ShadowCast> shadows(Map<String, dynamic> W) {
    final out = <ShadowCast>[];
    void cast(CruceAt at, double? r) {
      if (r == null || at.z != 0) return;
      out.add((x: at.x, y: at.y, z: 0, r: r));
    }

    final gente = (W['gente'] as Map<String, dynamic>?) ?? const {};
    for (final en in gente.entries) {
      final p = en.value as Map<String, dynamic>;
      if (p['vis'] == 0) continue;
      final pose = p['pose'] as String? ?? '';
      if (const {
        'sentada',
        'fan0',
        'fan1',
        'sentado',
        'rodillas',
      }.contains(pose)) {
        continue;
      }
      if (_p.noShadow((p['spot'] as String?) ?? '')) continue;
      cast(_atOf(p), _p.radius(en.key));
    }
    final q = W['cq'] as Map<String, dynamic>?;
    if (q != null && jsTruthy(q['vis'])) {
      cast(_frogPoint(q), _p.radius('coqui'));
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
  Map<String, List<num>?> _boxes = {};

  Map<String, List<num>?> _allBoxes(Map<String, dynamic> w) => {
    for (final it in items(w, 0))
      if (it.tag != null && it.tag!.startsWith('persona:'))
        it.tag!: inkBox(it.s, it.left, it.top),
  };

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

  // the frog's places of story 59 can be touched in its game (from the rounds card to the end)
  static bool _juego59(Map<String, dynamic> w) =>
      w['hist'] == 59 && jsTruthy(w['tarjeta']);

  List<Thing> _things() {
    Thing sprite(String id, List<num>? Function(Map<String, dynamic>) f) =>
        Thing(id: id, m: 1, si: (w) => f(w) != null, box: f);
    Thing setThing(String id) {
      final b = _p.box(id);
      return Thing(
        id: id,
        m: 0,
        world: _p.worldBox(id),
        box: [b[0], b[1], b[2], b[3]],
      );
    }

    return [
      // the frog's four places of story 59 (the sheet's boxes): before the frog and the family, in its game only
      for (final id in const [
        'delante_canelo',
        'detras_canelo',
        'lado_abuela',
        'delante_abuela',
      ])
        Thing(id: id, m: 0, z: true, si: _juego59, box: [..._p.box(id)]),
      // the people, Canelo and the bebé
      for (final id in _people) sprite(id, (w) => _boxOfTag(w, 'persona:$id')),
      // the big tree at the end of the street straight on, which story 58 makes twinkle (step 2), never touched
      // OPEN: the sheet has no thing for the big tree: its twinkle is drawn round the street straight on (calle_recta's
      // box), at whose end it stands
      Thing(
        id: 'arbol',
        m: 0,
        box: const <num>[0, 0, 0, 0],
        hintBox: [..._p.box('calle_recta')],
      ),
      // the three streets (the sheet's boxes)
      setThing('calle_izq'),
      setThing('calle_der'),
      setThing('calle_recta'),
    ];
  }

  /// A touch that is not an answer: the closed street gets a shake of the obrero's head (58: "touching it does nothing
  /// but a shake of the obrero's head").
  @override
  dynamic poke(String what) {
    if (what == 'calle_der' && _cerrada && _seen('obrero')) {
      final p = _g('obrero');
      final my = host.runId;
      unawaited(() async {
        final d = _n(p['dir']) < 0 ? -1 : 1;
        for (var i = 0; i < 4 && my == host.runId; i++) {
          p['dir'] = i % 2 == 0 ? -d : d;
          await host.sleep(TICK / host.FAST);
        }
        p['dir'] = d;
      }());
    }
    return null;
  }

  /* ---------- talking ---------- */

  // the point over a speaker's head: its sprite's top
  @override
  List<num>? talkAt(String who, Map<String, dynamic> W) {
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
    return 'gente=$gente botella=${W['botella']} hielo=${W['hielo']} mapa=${W['mapa']} hojas=${W['hojas']} fotos=${W['fotos']}';
  }

  /* ---------- moving ---------- */

  // the world point of (u, v) on the ground, and back (the set's turn: rules.uv)
  static List<double> _xy(num u, num v) => E.xy(u, v);
  static List<double> _uv(num x, num y) => E.uv(x, y);

  // a walker: a person (id) or the frog ('coqui'), along a polyline of world points, at [pace] px a tick
  Future<void> _walk(
    Map<String, List<List<double>>> paths, {
    double pace = 5,
    String? frogWith,
  }) async {
    final pos = <String, List<double>>{};
    final legs = <String, int>{};
    for (final e in paths.entries) {
      if (e.key == 'coqui') {
        final q = W['cq'] as Map<String, dynamic>;
        final at = _frogPoint(q);
        pos['coqui'] = [at.x, at.y, at.z];
      } else {
        final p = _g(e.key);
        pos[e.key] = [
          (p['x'] as num).toDouble(),
          (p['y'] as num).toDouble(),
          (p['z'] as num).toDouble(),
        ];
      }
      legs[e.key] = 0;
    }
    var guard = 0;
    while (legs.entries.any((e) => e.value < paths[e.key]!.length) &&
        guard++ < 400) {
      for (final e in paths.entries) {
        var leg = legs[e.key]!;
        if (leg >= e.value.length) continue;
        final a = pos[e.key]!;
        var left = pace;
        while (leg < e.value.length && left > 0) {
          final b = e.value[leg];
          final pa = _p.atWorld(a[0], a[1], a[2]),
              pb = _p.atWorld(b[0], b[1], b[2]);
          final d = math.sqrt(
            (pb.sx - pa.sx) * (pb.sx - pa.sx) +
                (pb.sy - pa.sy) * (pb.sy - pa.sy),
          );
          if (e.key != 'coqui' && (pb.sx - pa.sx).abs() > 1) {
            _g(e.key)['dir'] = pb.sx > pa.sx ? 1 : -1;
          }
          if (d <= left) {
            a.setAll(0, b);
            left -= d;
            leg++;
          } else {
            final t = left / d;
            for (var k = 0; k < 3; k++) {
              a[k] = a[k] + (b[k] - a[k]) * t;
            }
            left = 0;
          }
        }
        legs[e.key] = leg;
        if (e.key == 'coqui') {
          _setFrog(a, bob: guard % 2 == 1 && leg < e.value.length);
        } else {
          final p = _g(e.key);
          p
            ..['x'] = a[0]
            ..['y'] = a[1]
            ..['z'] = a[2]
            ..['dy'] = guard % 2 == 1 && leg < e.value.length ? -1 : 0;
        }
      }
      if (frogWith != null) {
        final p = _g(frogWith);
        final off = W['rack'] as List<double>;
        _setFrog([
          (p['x'] as num) + off[0],
          (p['y'] as num) + off[1],
          (p['z'] as num) + off[2],
        ]);
      }
      await _tick();
    }
    for (final id in paths.keys) {
      if (id != 'coqui') _g(id)['dy'] = 0;
    }
  }

  // the frog at a world point (feet), by his screen box (rules.anchor)
  void _setFrog(List<double> w, {bool bob = false}) {
    final q = W['cq'] as Map<String, dynamic>;
    final at = _p.atWorld(w[0], w[1], w[2]);
    q
      ..['x'] = _round(at.sx) - 16
      ..['y'] = _round(at.sy) - 25 - (bob ? 2 : 0);
    W['cqz'] = w[2];
    W['cqw'] = bob ? null : [w[0], w[1], w[2]];
    W['cqxy'] = [q['x'], q['y']];
  }

  // where one stands, in (u, v)
  List<double> _uvOf(String id) {
    if (id == 'coqui') {
      final at = _frogPoint(W['cq'] as Map<String, dynamic>);
      return _uv(at.x, at.y);
    }
    final p = _g(id);
    return _uv(p['x'] as num, p['y'] as num);
  }

  // the walk out along street [por] from where [id] stands: to the crossing (on the street's line), to the sheet's exit,
  // then on along the same line until the sprite has left the picture (the sheet's check salida-whole)
  List<List<double>> _out(
    String id,
    String por, {
    double z = 0,
    List<double>? off,
  }) {
    final u0 = _uvOf(id);
    final ex = _p.world('salida_$por'), eu = _uv(ex[0], ex[1]);
    final o = off ?? const [0.0, 0.0];
    final turn = por == 'recta' ? [eu[0] + o[0], u0[1]] : [u0[0], eu[1] + o[1]];
    final far = switch (por) {
      'izq' => [eu[0] - 2.2, eu[1] + o[1]],
      'der' => [eu[0] + 3.0, eu[1] + o[1]],
      _ => [eu[0] + o[0], eu[1] - 4.4],
    };
    List<double> w(List<num> uv) => [..._xy(uv[0], uv[1]), z];
    return [
      w(turn),
      w([
        eu[0] + (por == 'recta' ? o[0] : 0),
        eu[1] + (por == 'recta' ? 0 : o[1]),
      ]),
      w(far),
    ];
  }

  // the walk up from below the picture to spot [spot], up the street the frog comes up
  List<List<double>> _up(String spot) {
    final w = _p.world(spot);
    final uv = _uv(w[0], w[1]);
    return [
      [..._xy(uv[0], uv[1] + 7), w[2]],
      w,
    ];
  }

  // puts [id] (or the frog) at the start of a path without a walk
  void _at(String id, List<double> w) {
    if (id == 'coqui') {
      _setFrog(w);
      (W['cq'] as Map<String, dynamic>)['vis'] = 1;
      return;
    }
    _g(id)
      ..['x'] = w[0]
      ..['y'] = w[1]
      ..['z'] = w[2]
      ..['vis'] = 1;
  }

  void _hide(String id) {
    if (id == 'coqui') {
      (W['cq'] as Map<String, dynamic>)['vis'] = 0;
    } else {
      _g(id)['vis'] = 0;
    }
  }

  // who goes out along a street together: abuela with the frog (57: 2, 3), Luis with the frog on his rack (58)
  List<String> _goers(String quien) => switch (quien) {
    'abuela' => ['abuela', 'coqui'],
    'luis' => ['luis'],
    _ => [quien],
  };

  // the sheet's spot each one comes up at, and where the frog ends in the game of 57 (coqui.cruce, preview moment 2)
  String _home(String id) => switch (id) {
    'abuela' => 'abajo.abuela',
    'luis' => 'abajo.bici',
    _ => 'abajo.coqui',
  };

  // out along a street and gone
  Future<void> _sale(String quien, String por, {bool arbol = false}) async {
    final goers = _goers(quien);
    final paths = <String, List<List<double>>>{};
    for (final id in goers) {
      final z = id == 'coqui' ? 0.0 : (_g(id)['z'] as num).toDouble();
      var path = _out(id, por, z: z);
      if (arbol) {
        // 58 step 2: Luis stops under the big tree on the way (bajo_arbol), then rides on and out
        final t = _p.world('bajo_arbol');
        final tu = _uv(t[0], t[1]);
        path = [
          [..._xy(tu[0], _uvOf(id)[1]), 0.0],
          t,
        ];
        paths[id] = path;
      } else {
        paths[id] = path;
      }
    }
    final rack = quien == 'luis' && _riding();
    await _walk(paths, frogWith: rack ? 'luis' : null);
    if (arbol) {
      await wait(TICK * 5);
      await _walk({
        'luis': _out('luis', 'recta'),
      }, frogWith: rack ? 'luis' : null);
    }
    for (final id in goers) {
      _hide(id);
    }
    if (rack) _hide('coqui');
  }

  bool _riding() {
    final l = _gente['luis'] as Map<String, dynamic>?;
    return l != null && jsTruthy(l['bici']) && W['rack'] != null;
  }

  // up from the bottom again, to the sheet's abajo spots (OPEN: the sheet names no place below the picture: the walk
  // starts on the line of the street they come up, below the picture's edge)
  Future<void> _vuelven(String quien) async {
    final goers = _goers(quien);
    final rack = quien == 'luis' && W['rack'] != null;
    final paths = <String, List<List<double>>>{};
    for (final id in goers) {
      final p = _up(_home(id));
      _at(id, p.first);
      paths[id] = p;
      if (id != 'coqui') _g(id)['dir'] = 1;
    }
    if (rack) (W['cq'] as Map<String, dynamic>)['vis'] = 1;
    await _walk(paths, frogWith: rack ? 'luis' : null);
    for (final id in goers) {
      if (id == 'coqui') {
        _frogSpot(_home(id));
      } else {
        _g(id)['spot'] = _home(id);
      }
    }
    if (rack) {
      final q = _frogAt(_p.at('coqui.bici'));
      (W['cq'] as Map<String, dynamic>)
        ..['x'] = q[0]
        ..['y'] = q[1];
      _frogSpot('coqui.bici');
    }
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
      _frogSpot(spot);
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
    } else {
      host.bounce(6);
      await wait(TICK * 2);
    }
    q
      ..['x'] = L[0]
      ..['y'] = L[1];
    _frogSpot(spot);
  }

  // the frog stands at spot [spot]: his point is the spot's
  void _frogSpot(String spot) {
    final q = W['cq'] as Map<String, dynamic>, w = _p.world(spot);
    W['cqz'] = w[2];
    W['cqw'] = [w[0], w[1], w[2]];
    W['cqxy'] = [q['x'], q['y']];
  }

  // one walks from where he is to spot [spot] (a straight line)
  Future<void> _anda(String id, String spot, {double pace = 5}) async {
    final w = _p.world(spot);
    final p = _g(id);
    if (p['vis'] == 0) {
      _at(id, w);
    } else {
      await _walk({
        id: [w],
      }, pace: pace);
    }
    p['spot'] = spot;
  }

  // a person who is not seen appears at a spot
  Map<String, dynamic> _aparece(
    String id,
    String spot, {
    String pose = 'idle',
  }) {
    final p = _g(id);
    final w = _p.world(spot);
    p
      ..['x'] = w[0]
      ..['y'] = w[1]
      ..['z'] = w[2]
      ..['vis'] = 1
      ..['spot'] = spot
      ..['pose'] = pose
      ..['dir'] = 1
      ..['dy'] = 0;
    return p;
  }

  /* ---------- the acts (cruce.md, "Needs") ---------- */

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

  // the things the frog brings back: `trae` names a place (tienda, colmado, farmacia); what it gives
  static String? _cosaDe(Object? trae) => switch (trae) {
    'tienda' => 'cometa',
    'colmado' => 'pan',
    _ => null,
  };

  // the one standing at centro leaves along the left street (never shut)
  Future<void> _despejaCentro(String keep) async {
    final fut = <Future<void>>[];
    for (final e in _gente.entries) {
      final p = e.value as Map<String, dynamic>;
      if (p['vis'] == 0 || e.key == keep || p['spot'] != 'centro') continue;
      p['spot'] = null;
      p['pose'] = 'idle';
      fut.add(() async {
        await _walk({e.key: _out(e.key, 'izq')});
        p['vis'] = 0;
      }());
    }
    await Future.wait(fut);
  }

  Map<String, Act> _acts() => {
    // `ya`: waits for the acts that were started with `suelto: 1`
    'ya': (o) async {
      final all = List<Future<void>>.of(_sueltos);
      _sueltos.clear();
      await Future.wait(all);
    },
    // `ir` {a}: the frog hops to one of his places, the sheet's spots
    'ir': (o) async {
      final a = o['a'], key = jsTruthy(a) ? a : o['en'];
      if (key is! String) return;
      final spot = _frogPlaces[key] ?? (_p.has(key) ? key : null);
      if (spot == null) return;
      if (W['hist'] == 59) await host.camGo('plaza', 1);
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
    // `toma` {quien, por, trae, arbol}: somebody walks or rides out along a street (izq, der, recta), and comes up from
    // the bottom again, with a thing or without (57: 2, 3, 5, 6; 58: 2, 3, 5, 6); the story says "Y después..." while it
    // runs. With `arbol` Luis stops under the big tree on the way (58: 2). Carmen, who skips out ahead of the frog (57:
    // 6), does not come back.
    'toma': (o) async {
      final quien = o['quien'] as String, por = o['por'] as String;
      if (quien == 'carmen') {
        _g('carmen')['spot'] = null;
        await _walk({'carmen': _out('carmen', por)});
        _hide('carmen');
        return;
      }
      if (quien == 'luis') _rack();
      await _sale(quien, por, arbol: jsTruthy(o['arbol']));
      await wait(TICK * 4);
      final trae = o['trae'];
      if (quien == 'abuela') {
        // the letter is posted; from the farmacia she brings a small paper bag
        W['carta'] = 0;
        if (trae == 'farmacia') W['bolsita'] = 1;
      }
      final cosa = _cosaDe(trae);
      if (quien == 'coqui' && cosa != null) {
        (W['lleva'] as List).add(cosa);
      }
      await _vuelven(quien);
      if (quien == 'coqui') await _salta('coqui.cruce');
    },
    // `vuelve` {quien, por}: out along the street, then back along it, slowly, with nothing (57, 58: the wrong branch)
    'vuelve': (o) async {
      final quien = o['quien'] as String, por = o['por'] as String;
      if (quien == 'luis') _rack();
      final goers = _goers(quien);
      final rack = quien == 'luis' && _riding();
      final paths = <String, List<List<double>>>{
        for (final id in goers) id: _out(id, por),
      };
      await _walk(paths, frogWith: rack ? 'luis' : null);
      await wait(TICK * 4);
      // back the same way: from beyond the edge to the crossing, then to his place, slowly
      final back = <String, List<List<double>>>{};
      for (final id in goers) {
        final p = paths[id]!;
        final home = _p.world(id == 'coqui' ? 'coqui.cruce' : _home(id));
        back[id] = [p[1], p[0], home];
      }
      await _walk(back, pace: 3, frogWith: rack ? 'luis' : null);
      for (final id in goers) {
        if (id != 'coqui') {
          _g(id)
            ..['spot'] = _home(id)
            ..['dir'] = 1;
        }
      }
      if (rack) {
        final q = _frogAt(_p.at('coqui.bici'));
        (W['cq'] as Map<String, dynamic>)
          ..['x'] = q[0]
          ..['y'] = q[1];
        _frogSpot('coqui.bici');
      } else if (goers.contains('coqui')) {
        _frogSpot('coqui.cruce');
      }
    },
    // `senala` {quien, a}: somebody points along a street (the openings only): a hand held out to the side (izq, der),
    // a hand lifted (recta: no pose points straight on; a guess)
    'senala': (o) async {
      final p = _g(o['quien'] as String);
      if (p['vis'] == 0) return;
      final a = o['a'];
      p['dir'] = a == 'izq' ? -1 : 1;
      p['pose'] = a == 'recta' ? 'saluda1' : 'mano';
      host.SFX.blip();
      await wait(TICK * 6);
      p['pose'] = 'idle';
      p['dir'] = 1;
    },
    // `pasa` {quien}: somebody walks, rides or skips into the crossing and stops at centro, facing us (57, 58); whoever
    // stood there walks on out along the street to the left
    // OPEN: where a passer-by comes from is not named: from the exit of the street straight on (salida_recta, never shut)
    'pasa': (o) async {
      final quien = o['quien'] as String;
      final p = _g(quien);
      await _despejaCentro(quien);
      if (p['vis'] == 0) {
        _aparece(quien, 'salida_recta');
        if (quien == 'pepe') {
          if (W['hist'] == 57) {
            p['bici'] = 1; // don Pepe rides up on his bicycle (57: 1)
          } else {
            p['escoba'] = 1; // don Pepe at the corner with his broom (58: 3)
          }
        }
        if (quien == 'carmen' && W['hist'] == 57) p['cuerda'] = 1;
        p['spot'] = null;
      }
      if (jsTruthy(p['bici'])) _bell();
      await _anda(quien, 'centro');
      p['dir'] = 1;
    },
    // `botella` {n}: the water left in abuela's bottle (57)
    'botella': (o) async {
      W['botella'] = _n(o['n']);
      await wait(TICK);
    },
    // `derrama57`: the frog stumbles on abuela's bag (asiento.coqui, where he arrives at the seat), the bottle tips and
    // water runs out over the pavement before abuela catches it (57: 5, 6)
    'derrama57': (o) async {
      await _salta('asiento.coqui');
      host.bounce(4);
      W['tumbada'] = 1;
      host.SFX.bonk();
      // the puddle on the pavement under the bag (the bag's spot on the ground)
      final w = _p.world('asiento.bolsa');
      _items.removeWhere((x) => x['id'] == 'charco57');
      _items.add(<String, dynamic>{
        'id': 'charco57',
        'k': 'charco',
        'x': w[0],
        'y': w[1],
        'z': 0.0,
        'spot': 'asiento.bolsa',
        'vis': 1,
        'v': 0,
      });
      host.SFX.drop();
      await wait(TICK * 5);
      final ab = _gente['abuela'] as Map<String, dynamic>?;
      if (ab != null) ab['pose'] = 'sentada';
      W['tumbada'] = 0;
      await wait(TICK * 2);
    },
    // `final57` {n}: the frog puts the two things on the seat; three parts: the frog drinks, abuela drinks, she pours the
    // last over his head; two: the frog drinks, abuela drinks; one: she gives it all to the frog and fans herself (57: 7)
    'final57': (o) async {
      final n = _n(o['n']);
      final ll = W['lleva'] as List;
      (W['enAsiento'] as List).addAll(ll);
      ll.clear();
      host.SFX.blip();
      await wait(TICK * 3);
      final ab = _gente['abuela'] as Map<String, dynamic>?;
      Future<void> bebe(String who) async {
        W['botellaCon'] = who;
        host.tone(500, 0, .2, 'sine', .04, 380);
        await wait(TICK * 4);
        W['botella'] = math.max(0, _n(W['botella']) - 1);
      }

      if (n == 1) {
        await bebe('coqui');
        if (ab != null) {
          for (var i = 0; i < 6; i++) {
            ab['pose'] = i % 2 == 0 ? 'fan0' : 'fan1';
            await _tick();
          }
          ab['pose'] = 'sentada';
        }
      } else {
        await bebe('coqui');
        await bebe('abuela');
        if (n == 3) {
          // the last part over the frog's head: he shuts his eyes and smiles
          W['botellaCon'] = 'coqui';
          host.SFX.drop();
          host.bounce(5);
          await wait(TICK * 4);
          W['botella'] = 0;
          host.SFX.right();
        }
      }
      W['botellaCon'] = null;
      await wait(TICK * 2);
    },
    // `hielo` {n}: the block's size in Luis's basket (58)
    'hielo': (o) async {
      W['hielo'] = _n(o['n']);
      await wait(TICK);
    },
    // `gotea`: drops fall from the basket and a puddle is left under the bicycle (58: 4, 5, 6)
    'gotea': (o) async {
      final l = _gente['luis'] as Map<String, dynamic>?;
      if (l == null || l['vis'] == 0) {
        await wait(TICK * 2);
        return;
      }
      final at = _atOf(l);
      W['gotas'] = {'x': _round(at.sx), 'y': _round(at.sy) - 18};
      for (var i = 0; i < 6; i++) {
        if (i % 3 == 0) host.SFX.drop();
        await _tick();
      }
      W['gotas'] = null;
      _items.removeWhere((x) => x['id'] == 'charco58');
      _items.add(<String, dynamic>{
        'id': 'charco58',
        'k': 'charco',
        'x': l['x'],
        'y': l['y'],
        'z': 0.0,
        'spot': l['spot'],
        'vis': 1,
        'v': 10,
      });
      await wait(TICK);
    },
    // `mapa58` {n}: the bicycle's place on the card's road
    'mapa58': (o) async {
      W['mapa'] = _n(o['n']);
      if (_n(o['n']) > 0) host.SFX.blip();
      await wait(TICK);
    },
    // `piraguero58`: the first time, he stands in the square with his cart when they come up (plaza view: plaza_carrito,
    // luis.plaza, coqui.plaza); the second, he takes the block onto his cart and scrapes it (58: 6, 7)
    'piraguero58': (o) async {
      if (!_seen('piraguero')) {
        await host.camGo('plaza');
        _campana();
        _aparece('piraguero', 'plaza_carrito');
        final w = _p.world('plaza_carrito');
        _items.add(<String, dynamic>{
          'id': 'carrito',
          'k': 'carrito',
          'x': w[0],
          'y': w[1],
          'z': 0.0,
          'spot': 'plaza_carrito',
          'vis': 1,
          'v': null,
          // cruce-preview.html m4: the cart 3 px lower than his feet, .1 nearer
          'dy': 3,
          'dd': .1,
        });
        // OPEN: the square has no place for the bicycle: it stays where Luis got off (abajo.bici), and he carries the
        // block to luis.plaza
        final l = _g('luis');
        if (l['vis'] != 0 && jsTruthy(l['bici'])) {
          l['bici'] = 0;
          final b = <String, dynamic>{
            'id': 'bici',
            'k': 'bici',
            'x': l['x'],
            'y': l['y'],
            'z': 0.0,
            'spot': l['spot'],
            'vis': 1,
            'v': null,
            'dd': .15,
          };
          _items.add(b);
        }
        W['rack'] = null;
        W['hieloEn'] = 'luis';
        W['cqz'] = 0.0;
        await Future.wait([_anda('luis', 'luis.plaza'), _salta('coqui.plaza')]);
        _g('luis')['dir'] = 1;
        return;
      }
      final pi = _g('piraguero');
      pi['pose'] = 'mano';
      await wait(TICK * 3);
      W['hieloEn'] = 'carro';
      host.SFX.blip();
      pi['pose'] = 'idle';
      for (var i = 0; i < 4; i++) {
        host.tone(1800, 0, .08, 'square', .02, 1200);
        pi['dy'] = i % 2 == 0 ? -1 : 0;
        await _tick();
      }
      pi['dy'] = 0;
    },
    // `final58` {n}: a big block: three piraguas (Luis, the frog, the piragüero); smaller: two; small: one with two spoons
    'final58': (o) async {
      final n = _n(o['n']);
      final pi = <String, dynamic>{};
      W['piraguas'] = pi;
      if (n == 1) {
        pi['luis'] = 2;
      } else {
        pi['luis'] = 1;
        pi['coqui'] = 1;
        if (n == 3) pi['piraguero'] = 1;
      }
      host.SFX.blip();
      await wait(TICK * 4);
      if (n == 3) host.SFX.right();
    },
    // `pone59` {quien, donde}: somebody takes a place in the group (59: 1 to 5); papá at papa_rodillas: he stands the
    // camera on the short wall (muro), runs to the seat and kneels (59: 9)
    // OPEN: where the family walks in from is not named: each one appears at his place
    'pone59': (o) async {
      final quien = o['quien'] as String, donde = o['donde'] as String;
      await host.camGo('plaza', 1);
      final pose = switch ((quien, donde)) {
        ('abuela', 'asiento1') => 'sentada',
        ('luis', 'asiento2') => 'sentado',
        ('papa', 'papa_rodillas') => 'rodillas',
        _ => 'idle',
      };
      if (quien == 'papa' && _seen('papa')) {
        W['camara'] = 'muro';
        final w = _p.world('muro');
        _items.add(<String, dynamic>{
          'id': 'camara',
          'k': 'camara',
          'x': w[0],
          'y': w[1],
          'z': w[2],
          'spot': 'muro',
          'vis': 1,
          'v': null,
        });
        host.SFX.toc();
        _g('papa')['pose'] = 'idle';
        await _anda('papa', donde, pace: 7);
        _g('papa')['pose'] = pose;
        return;
      }
      if (quien == 'perro') {
        // Canelo trots in and lies down
        final p = _aparece('perro', donde, pose: 'run');
        for (var i = 0; i < 4; i++) {
          await _tick();
        }
        p['pose'] = 'lie';
        host.SFX.blip();
        return;
      }
      _aparece(quien, donde, pose: pose);
      if (quien == 'bebe') host.SFX.blip();
      await wait(TICK * 3);
    },
    // `va59` {donde}: the frog hops to one of his places (59: 7 to 9); if he is there already, he bounces
    'va59': (o) async {
      final d = o['donde'] as String;
      await _salta(_frogPlaces[d] ?? d);
    },
    // `foto59` {ok, como}: "¡Uno, dos, tres!" said, the flash; the sheet slides out and is shown big for a moment: good,
    // or spoiled (espalda: his back over a face; ojos: only his eyes at an edge)
    'foto59': (o) async {
      final ok = jsTruthy(o['ok']) && o['ok'] != '0';
      final p = _gente['papa'] as Map<String, dynamic>?;
      if (p != null && p['spot'] == 'papa_camara') p['pose'] = 'foto';
      await wait(TICK * 2);
      W['flash'] = F;
      host.tone(2400, 0, .08, 'square', .03, 900);
      await wait(TICK * 2);
      W['foto'] = <String, dynamic>{'ok': ok ? 1 : 0, 'como': o['como']};
      (W['fotos'] as List).add(ok ? 'ok' : 'mala');
      host.SFX.swoop();
      await wait(TICK * 10);
      W['foto'] = null;
      W['flash'] = null;
      if (p != null && p['spot'] == 'papa_camara') p['pose'] = 'idle';
    },
    // `hojas` {n}: the sheets left in the camera (on the card)
    'hojas': (o) async {
      W['hojas'] = _n(o['n']);
      if (W['hist'] == 59) await host.camGo('plaza', 1);
      await wait(TICK);
    },
    // `final59` {n}: the photos laid out (59: 9); three good: abuela holds one to her heart; two: they laugh at the
    // spoiled one, Luis holds it up; one: the bebé chews a spoiled one, mamá takes it away laughing
    // OPEN: the photos are "laid out on the seat", where abuela and Luis sit and the frog is in the gap: no place on the
    // seat is free; they are shown in a row over the picture
    'final59': (o) async {
      final n = _n(o['n']);
      W['fotosVer'] = 1;
      host.SFX.blip();
      await wait(TICK * 4);
      final who = n == 3 ? 'abuela' : (n == 2 ? 'luis' : 'bebe');
      final p = _gente[who] as Map<String, dynamic>?;
      for (var i = 0; i < 6; i++) {
        if (p != null) p['dy'] = i % 2 == 0 ? -2 : 0;
        if (who == 'bebe' && p != null) {
          p['pose'] = i % 2 == 0 ? 'clap' : 'idle';
        }
        await _tick();
      }
      if (p != null) {
        p['dy'] = 0;
        if (who == 'bebe') p['pose'] = 'idle';
      }
      if (n == 3) host.SFX.right();
      W['fotosVer'] = 0;
    },
    // `gesto` {quien, que, a}: saluda, no, rie, mira (with a), sienta, abanica, lengua, pulgar, manos, hombros
    'gesto': (o) async {
      final quien = o['quien'] as String, que = o['que'] as String?;
      if (quien == 'coqui') {
        // lengua: the frog comes back tired (OPEN: the frog is the runner's drawing: his tongue is not drawn; a slow,
        // low bounce)
        host.bounce(que == 'lengua' ? 2 : 6);
        await wait(TICK * (que == 'lengua' ? 5 : 3));
        return;
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
          await wait(TICK * 5);
          p['dir'] = 1;
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
        case 'sienta':
          // abuela sits down on the seat (asiento.abuela) and stands her bag with the bottle beside her (asiento.bolsa);
          // the frog goes to the crossing's stripes, where the game is played (coqui.cruce: preview moment 2)
          await _anda(quien, 'asiento.abuela');
          p['pose'] = 'sentada';
          p['dir'] = 1;
          W['bolsa'] = 'asiento';
          host.SFX.toc();
          await _salta('coqui.cruce');
        case 'abanica':
          final sits = p['pose'] == 'sentada';
          for (var i = 0; i < 8; i++) {
            if (sits) p['pose'] = i % 2 == 0 ? 'fan0' : 'fan1';
            await _tick();
          }
          if (sits) p['pose'] = 'sentada';
        case 'pulgar':
          // a thumb up (no pose for it: a hand lifted, a guess)
          p['pose'] = 'saluda1';
          host.SFX.blip();
          await wait(TICK * 5);
          p['pose'] = 'idle';
        case 'manos':
          // abuela shows her empty hands, or holds up the small paper bag: her hand held out
          final was = p['pose'];
          p['pose'] = 'mano';
          await wait(TICK * 6);
          p['pose'] = was;
        case 'hombros':
          // Carmen's hands on Luis's shoulders: her arms out in front (mkPersona's `ojos`, a guess)
          p['pose'] = 'ojos';
          await wait(TICK * 8);
          p['pose'] = 'idle';
        default:
          await wait(TICK * 3);
      }
    },
  };

  // Luis's bicycle: the frog on its rack (coqui.bici: the offset of his spot from Luis's)
  void _rack() {
    final l = _gente['luis'] as Map<String, dynamic>?;
    if (l == null || !jsTruthy(l['bici'])) return;
    final a = _p.world('abajo.bici'), b = _p.world('coqui.bici');
    W['rack'] = [b[0] - a[0], b[1] - a[1], b[2] - a[2]];
  }

  void _bell() {
    host.tone(2093, 0, .15, 'sine', .06);
    host.tone(2093, .2, .15, 'sine', .06);
  }

  void _campana() {
    host.tone(1568, 0, .25, 'sine', .08);
    host.tone(2093, .08, .3, 'sine', .06);
  }
}
