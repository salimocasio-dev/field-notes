// La caja (place 4, El colmado, scene 4; stories 45 to 47): a NEW scene, written from its script's "Needs" list
// (historia/notas/guiones/caja.md) on its set (caja_set.dart) and its sheet (caja-sheet.json, read by SceneSheet), in
// El mostrador's way (lib/src/mostrador/mostrador.dart: the same names, the same parts, in the same order). There is no
// old scene file: every act is this file's, each doing on screen what the Needs list says, every place from the sheet (a
// spot's world point, a thing's box, a key card's box, the amount plate, the `etiqueta` offset, the depth rule). Where
// the sheet names no place, or the script does not settle what an act shows, the act does the plainest thing that keeps
// the story playing and says so in a comment starting `OPEN:` (page 13 lists them for the content lane).
//
// The drawing (the sheet's `front`): every sprite stands with its feet's bottom edge on its spot's row and its middle on
// its column (rules.anchor); a sprite pixel is hidden by every set pixel nearer the camera than the upright plane
// through its feet plus `front.bias` (front.plane); between two sprites the nearer pixel wins. The amount plate
// (things.importe) is drawn at its spot's depth, hidden only by a nearer sprite; the two key cards are drawn over
// everything (rules.cards).
// ignore_for_file: non_constant_identifier_names

import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/src/caja/caja_places.dart';
import 'package:coqui_scenes/src/caja/caja_set.dart';
import 'package:coqui_scenes/src/caja/caja_sprites.dart';
import 'package:coqui_scenes/src/colmado/colmado_cast.dart';
import 'package:coqui_scenes/src/colmado/colmado_dentro.dart';
import 'package:coqui_scenes/src/mostrador/mostrador_sprites.dart'
    show mkCliente;
import 'package:coqui_scenes/src/scene_set.dart';
import 'package:coqui_scenes/src/sheet_cache.dart';

/// The scene "La caja", made from its sheet (read first: `loadScene`).
Scene createCaja() => Caja(sceneSheetOf('caja'));

int _round(num v) => (v + 0.5).floor();

int _n(Object? v) => v is num
    ? v.toInt()
    : v is String
    ? (int.tryParse(v) ?? 0)
    : 0;

/// One sprite of the sprite layer, placed: its picture, its top left on the 240 x 216 picture, the screen row of its
/// feet and the depth there (front.plane); [bySet]: whether the set may hide it (the depth rule; the amount plate: not);
/// [flat]: one depth for every row (the amount plate's: its spot's).
class CajaItem {
  CajaItem(
    this.s,
    this.left,
    this.top,
    this.sy,
    this.d, {
    this.tag,
    this.bySet = true,
    this.flat = false,
    this.world,
  });

  final Sprite s;
  final int left, top;
  final num sy;
  final double d;
  final bool bySet, flat;

  /// Who or what it is (the rules' tests read it: `persona:<id>`, `coqui`, `cosa:<id>`, `etiqueta:<id>`, `importe`).
  final String? tag;

  /// The world point it stands on (a thing on the counter, a tag), when it stands on one.
  final List<double>? world;
}

/// The frog's places (the kit's `lugar`: his top left and scale): the sheet has one, coqui.frente.
const List<String> _frogSpots = ['coqui.frente', 'puerta'];

class Caja extends Escena implements SetScene, SetOverSprites {
  Caja(this.ss) : sheet = ss.legacy() {
    _p = CajaPlaces(ss);
    // the runner starts on `wide` (juego.js `cam = CAM.wide`): the sheet's one view
    CAM = {'wide': _p.view('wide')};
    LUGAR = {
      for (final s in _frogSpots)
        s.replaceFirst('coqui.', ''): _frogAt(_p.at(s)),
      // OPEN: story 45 sends the frog to `repisa` (`ir`; caja.md: "the frog hops onto its side shelf"), a spot the sheet
      // does not name: its v3 puts the frog on the floor in front of the counter (spots.coqui.frente: "not on the
      // register's shelf and not on the counter"); he goes there
      'repisa': _frogAt(_p.at('coqui.frente')),
    };
    cosas = _things();
  }

  /// The new scene's sheet (SceneSheet).
  final SceneSheet ss;

  /// The old Sheet the shared code reads (`SceneSheet.legacy`: the scene, scale, origin; the start frog the runner's).
  @override
  final Sheet sheet;

  late final CajaPlaces _p;

  /// The scene's places, from its sheet.
  CajaPlaces get places => _p;

  @override
  String get id => 'caja';

  @override
  late final Map<String, List<num>> CAM;

  late final Map<String, List<num>> LUGAR;

  @override
  Map<String, List<num>> get lugar => LUGAR;

  @override
  late final List<Thing> cosas;

  @override
  PpEngine newEngine({bool still = false}) => cajaEngine(still: still);

  @override
  PpEngine get projection => _p.e;

  // the frog's top left for a spot (rules.anchor: mkCoqui's column 16 on sx, its row 25 on sy)
  List<num> _frogAt(CajaAt a) => [_round(a.sx) - 16, _round(a.sy) - 25, 1];

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
    String? con,
    Map<String, dynamic>? tag,
  }) {
    final w = _p.world(spot);
    return <String, dynamic>{
      'id': id,
      'k': k,
      'x': w[0],
      'y': w[1],
      'z': w[2],
      'spot': spot,
      'vis': 1,
      'v': v,
      'con': con,
      'tag': tag,
    };
  }

  @override
  Map<String, dynamic> fresh(Map<String, dynamic> story) {
    final acts = _actsOf([story['beats'], story['final']]);
    bool has(String a) => acts.any((o) => o['act'] == a);
    final gente = <String, dynamic>{
      // story 46: don Pepe wraps beside the register, where the two things stand (spots.pepe.empaca: "don Pepe packing
      // bags beside the register"); 45 and 47: behind the register (pepe.caja)
      'pepe': _person(has('envuelve') ? 'pepe.empaca' : 'pepe.caja'),
    };
    // the first customer is in front of the counter from the start (45 and 47: "Luis in front of the counter")
    final first = acts.firstWhere(
      (o) => o['act'] == 'cliente',
      orElse: () => const {},
    );
    if (first['precio'] != null && first['quien'] is String) {
      gente[first['quien'] as String] = _person('cliente');
    }
    // story 47: the three children outside, at the shop window and in the street doorway (group ninos_fuera)
    if (has('ninos47')) {
      final g = _p.group('ninos_fuera');
      for (var i = 0; i < g.length; i++) {
        gente['nino${i + 1}'] = _person(g[i])..['nino'] = i;
      }
    }
    final cosas = <dynamic>[];
    // 45: the clip on the register's face (spots.clip), empty until don Pepe counts the bills under it
    if (has('clip')) cosas.add(_cosa('clip', 'clip', 'clip', v: 0));
    // 46: the gift paper on its holder (spots.papel); the frog's own jar, from story 45 (caja.md 46: "Start")
    if (has('papel')) {
      cosas.add(_cosa('papel', 'papel', 'papel', v: 5));
      cosas.add(_cosa('jarra', 'jarra', 'frasco', v: 3, con: 'coqui'));
    }
    // 47: the children's jar (spots.frasco), the ball on the sill (spots.bola, shown while W.vitrina is 1)
    if (has('frasco')) {
      cosas.add(_cosa('frasco', 'frasco', 'frasco', v: 0));
      cosas.add(_cosa('bola', 'bola', 'bola'));
    }
    final q = LUGAR['frente']!;
    return {
      'hora': 'tarde',
      'vitrina': has('frasco') ? 1 : 0,
      'gaveta': 0,
      'importe': null,
      'teclas': null,
      'pulsada': null,
      'gorro': 0,
      'gente': gente,
      'cosas': cosas,
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
        'z': 0,
      },
    };
  }

  /* ---------- the set ---------- */

  // the sheet's setKey: hora ("manana", "tarde")
  @override
  String setKey(Map<String, dynamic> W) =>
      W['hora'] == 'manana' ? 'manana' : 'tarde';

  @override
  void buildSet(PpEngine e, PpBuild b, Map<String, dynamic> W) =>
      buildSetFor(e, b, setKey(W));

  final Map<PpEngine, CajaSet> _sets = {};

  @override
  void buildSetFor(PpEngine e, PpBuild b, String key) =>
      (_sets[e] ??= CajaSet(e, b)).buildSet(CajaState.fromKey(key));

  // the frog casts his shadow in the engine (shadows.byCharacter.coqui); never the old one
  @override
  bool get frogShadow => false;

  /* ---------- where everybody is ---------- */

  Map<String, dynamic> _g(String id) =>
      ((W['gente'] as Map<String, dynamic>)[id] ??= _person('puerta', vis: 0))
          as Map<String, dynamic>;

  List<Map<String, dynamic>> get _items =>
      (W['cosas'] as List).cast<Map<String, dynamic>>();

  Map<String, dynamic>? _item(String id) {
    for (final o in _items) {
      if (o['id'] == id && o['vis'] != 0) return o;
    }
    return null;
  }

  void _quita(String id) => _items.removeWhere((o) => o['id'] == id);

  CajaAt _atOf(Map<String, dynamic> o) =>
      _p.atWorld(o['x'] as num, o['y'] as num, o['z'] as num);

  // the frog's world point under his feet
  CajaAt _frogPoint(Map<String, dynamic> q) {
    final b = host.frogBox(q);
    return _p.fromScreen(b.x + b.w / 2, (q['y'] as num) + 25, 0);
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
    final pose = (p['pose'] as String?) ?? 'idle';
    if (id == 'pepe') {
      final key = 'pepe$pose$open';
      final s = _spr(key, () => mkPepe(pose, open: open));
      return (s: s, ax: PX, ay: inkBottom(s), key: key);
    }
    if (id.startsWith('nino')) {
      final i = _n(p['nino']);
      final key = 'nino$i$pose$open';
      final s = _spr(key, () => mkNino(i, pose, open: open));
      return (s: s, ax: PX, ay: inkBottom(s), key: key);
    }
    if (id == 'senora' || id == 'senor') {
      final mp = pose == 'ojos' ? 'ojos' : 'idle';
      final key = 'cl$id$mp$open';
      final s = _spr(key, () => mkCliente(id, mp, open: open));
      return (s: s, ax: PX, ay: inkBottom(s), key: key);
    }
    // the family's children (FAM)
    final who = FAM[id == 'luis' ? 'hermano' : 'hermana']!;
    final kp = pose == 'saluda0'
        ? 'wave0'
        : pose == 'saluda1'
        ? 'wave1'
        : pose == 'mano'
        ? 'taza'
        : pose == 'ojos'
        ? 'ojos'
        : 'idle';
    final key = 'fam$id$kp$open';
    final s = _spr(key, () => mkPersona(who, kp, open, false));
    return (s: s, ax: PX, ay: inkBottom(s), key: key);
  }

  // the sprite of a thing
  Sprite _thingSprite(Map<String, dynamic> o) {
    final k = o['k'] as String, v = o['v'];
    switch (k) {
      case 'clip':
        return _spr('clip${_n(v)}', () => mkClip(_n(v)));
      case 'papel':
        return _spr('papel${_n(v)}', () => mkPapel(_n(v)));
      case 'frasco':
        final l = (v as num?) ?? 0;
        return _spr('frasco$l', () => mkFrasco(l));
      case 'bola':
        return _spr('bola', mkBola);
      case 'jarra':
        return _spr('jarra${_n(v)}', () => mkJarra(_n(v)));
      case 'billete':
        return _spr('billete', mkBillete);
      case 'billete20':
        return _spr('billete20', mkBillete20);
      case 'gaveta':
        return _spr('gaveta', mkGaveta);
      case 'regalo':
        return _spr('regalo$v', () => mkRegalo(_n(v)));
      case 'regalo_grande':
        return _spr('regalog$v', () => mkRegalo(_n(v), grande: true));
      case 'roto':
        return _spr('roto$v', () => mkPapelRoto(_n(v)));
      case 'globo':
        return _spr('globo$v', () => mkGlobo(_n(v)));
      case 'bolsapapel':
        return _spr('bolsapapel$v', () => mkBolsaPapel(v == 1));
      case 'compra':
        return _spr('compra$v', () => mkCompra(v as String?));
      case 'tagback':
        return _spr('tagback', mkEtiquetaAtras);
    }
    // a thing of story 46: `<kind>` with v true (the dear make) or false
    return _spr('cosa$k$v', () => mkCosa(k, v == true));
  }

  // where a held thing is drawn: at the holder's hand (the person's held-out hand, kit.js mkPersona 'taza': X + rx + 4.5,
  // row 27; the frog's beside him), as a point of the picture with the holder's depth
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
    return (
      x: at.sx + dir * (nino ? 11 : 13),
      y: at.sy - (nino ? 15 : 26),
      d: at.d + .05,
      sy: at.sy,
    );
  }

  /// Every sprite of the frame [w] as it is placed (the people, the things, the price tags, the amount plate), in the
  /// picture. The rules' tests read it; [draw] draws it.
  List<CajaItem> items(Map<String, dynamic> w, int a) {
    final out = <CajaItem>[];
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
        CajaItem(s, sx - ax, sy - sp.ay, sy, at.d, tag: 'persona:${en.key}'),
      );
    }
    for (final o
        in (w['cosas'] as List? ?? const []).cast<Map<String, dynamic>>()) {
      if (o['vis'] == 0) continue;
      if (o['id'] == 'bola' && _n(w['vitrina']) != 1 && o['con'] == null) {
        continue;
      }
      final s = _thingSprite(o);
      final con = o['con'] as String?;
      if (con != null) {
        var h = _handOf(con);
        if (h == null) continue;
        // a balloon is held up in the hand on the left, away from the frog
        if (o['k'] == 'globo' && con != 'coqui') {
          final at = _atOf(_g(con));
          h = (x: at.sx - 13, y: h.y, d: h.d, sy: h.sy);
        }
        out.add(
          CajaItem(
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
      // a thing hangs from its point (the clip: its top edge on it, caja-preview.html `hanging`), or stands on it
      final top = o['k'] == 'clip' ? sy - 1 : sy - inkBottom(s);
      out.add(
        CajaItem(
          s,
          sx - s.w ~/ 2,
          top,
          sy,
          at.d,
          tag: 'cosa:${o['id']}',
          world: [at.x, at.y, at.z],
        ),
      );
      // its price tag, in front of it (spots.<spot>.etiqueta.dw: a world offset from the thing)
      final tg = o['tag'] as Map<String, dynamic>?;
      final dw = tg == null ? null : _p.etiqueta(o['spot'] as String);
      if (tg != null && dw != null) {
        final t = _p.atWorld(at.x + dw[0], at.y + dw[1], at.z + dw[2]);
        final ts = _n(tg['ver']) == 1
            ? _spr('tag${tg['n']}', () => mkEtiqueta('${tg['n']}'))
            : _spr('tagback', mkEtiquetaAtras);
        final tx = _round(t.sx), ty = _round(t.sy);
        out.add(
          CajaItem(
            ts,
            tx - ts.w ~/ 2,
            ty - inkBottom(ts),
            ty,
            t.d,
            tag: 'etiqueta:${o['id']}',
            world: [t.x, t.y, t.z],
          ),
        );
      }
    }
    // the register's drawer pulled open (W.gaveta)
    if (_n(w['gaveta']) == 1) {
      // OPEN: the sheet has no state `gaveta` (its setKey is hora only) and names no place for the open drawer: it is
      // drawn as a sprite at the colmado kit's CAJA_GAVETA (the drawer's front, the sheet's spots.clip is measured from
      // it), pulled .3 towards the customer
      final g = ColmadoDentro.CAJA_GAVETA,
          at = _p.atWorld(g[0], g[1] + .3, g[2] - .1),
          s = _spr('gaveta', mkGaveta);
      final sx = _round(at.sx), sy = _round(at.sy);
      out.add(CajaItem(s, sx - s.w ~/ 2, sy - s.h, sy, at.d, tag: 'gaveta'));
    }
    // the amount the register shows (things.importe: the plate's box, the depth of its spot ventana_caja)
    final imp = w['importe'];
    if (imp != null) {
      final pl = _p.importe;
      final s = _spr(
        'importe$imp',
        () => mkImporte('$imp', w: pl.box[2], h: pl.box[3]),
      );
      out.add(
        CajaItem(
          s,
          pl.box[0],
          pl.box[1],
          pl.box[1] + pl.box[3],
          pl.d,
          tag: 'importe',
          bySet: false,
          flat: true,
        ),
      );
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
    CajaItem it,
    int W0,
    int H0,
    Float32List? setZ,
    double bias,
    double S,
    List<String?>? tags,
  ) {
    final layer = _layer!, lz = _layerZ!, s = it.s;
    for (var y = 0; y < s.h; y++) {
      final Y = it.top + y;
      if (Y < 0 || Y >= H0) continue;
      final plane = it.flat ? it.d : it.d + (it.sy - (Y + .5)) * _t30 / S;
      for (var x = 0; x < s.w; x++) {
        final c = s.px[y * s.w + x];
        if (c >>> 24 == 0) continue;
        final X = it.left + x;
        if (X < 0 || X >= W0) continue;
        final i = Y * W0 + X;
        if (it.bySet && setZ != null && setZ[i] > plane + bias) {
          continue; // a set pixel nearer than the feet hides it
        }
        if (lz[i] > plane) continue; // a nearer sprite pixel is already there
        lz[i] = plane;
        layer[i] = c;
        if (tags != null) tags[i] = it.tag;
      }
    }
  }

  /// [items] and the frog (as the game draws him, juego.js frog, at the depth of his feet; with the paper hat of story
  /// 46's ending on his head): every sprite of the frame, placed. [draw] composes it; the rules' tests read it.
  List<CajaItem> placed(Map<String, dynamic> W, int a) {
    final all = items(W, a);
    final q = W['cq'] as Map<String, dynamic>;
    if (jsTruthy(q['vis'])) {
      final b = host.frogBox(q), at = _frogPoint(q);
      final ox = b.x.toInt() - 16, oy = b.y.toInt() - 24;
      final px = Uint32List(64 * 64);
      final g = Ctx(px, 64, 64)..translate(-ox.toDouble(), -oy.toDouble());
      host.frog(g, q, a);
      if (_n(W['gorro']) == 1) {
        final h = _spr('gorro', () => mkGorro(3));
        g.drawImage(h, _round(b.x + b.w / 2 - h.w / 2), b.y.toInt() - h.h + 3);
      }
      all.add(
        CajaItem(Sprite(64, 64, px), ox, oy, _round(at.sy), at.d, tag: 'coqui'),
      );
    }
    return all;
  }

  /// The sprite layer of frame [W] as [draw] composes it, over a blank picture: each picture pixel's colour (0: no
  /// sprite there) and the tag of the sprite that shows there. [setZ]: the set's depth (the baked state's), or none.
  ({Uint32List px, List<String?> tags}) layerOf(
    Map<String, dynamic> W,
    Float32List? setZ,
  ) {
    const w0 = 240, h0 = 216;
    _layer = Uint32List(w0 * h0);
    _layerZ = Float32List(w0 * h0)..fillRange(0, w0 * h0, -1e9);
    final tags = List<String?>.filled(w0 * h0, null);
    for (final it in placed(W, 0)) {
      _put(it, w0, h0, setZ, _p.bias, _p.e.S, tags);
    }
    final out = (px: _layer!, tags: tags);
    _layer = null;
    _layerZ = null;
    return out;
  }

  @override
  void draw(Ctx c, Map<String, dynamic> W, int a) {
    const w0 = 240, h0 = 216;
    final layer = _layer ??= Uint32List(w0 * h0);
    final lz = _layerZ ??= Float32List(w0 * h0);
    final setZ = _frameEngine != null ? _setZ : null,
        bias = _p.bias,
        S = _p.e.S;
    final all = placed(W, a);
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
          _put(it, w0, h0, setZ, bias, S, null);
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
    _over(c, W);
  }

  // what is drawn over everything: the two answer keys (rules.cards: "the game draws them over the picture")
  void _over(Ctx c, Map<String, dynamic> W) {
    final t = W['teclas'];
    if (t is! List || t.length != 2) return;
    for (var i = 0; i < 2; i++) {
      final k = i == 0 ? 'tecla_a' : 'tecla_b', b = _p.card(k), n = '${t[i]}';
      final lit = W['pulsada'] == k;
      final s = _spr(
        'tecla$n$lit${b[2]}x${b[3]}',
        () => mkTecla(n, w: b[2], h: b[3], lit: lit),
      );
      c.drawImage(s, b[0], b[1]);
    }
  }

  /* ---------- the boards: the two rounds ---------- */

  @override
  void hud(Ctx c, Map<String, dynamic> W, int a) {
    if (!jsTruthy(W['tarjeta'])) return;
    const x0 = 3;
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

  // castShadow(x, y, 0, radius) at the world x, y of whoever stands on the floor (shadows.at); none for the children
  // outside (shadows.none: ninos_fuera.1 to .3) nor for anyone outside the wall (x < 0: the street)
  @override
  List<ShadowCast> shadows(Map<String, dynamic> W) {
    final out = <ShadowCast>[];
    void cast(CajaAt at, double? r) {
      if (r == null || at.z != 0 || at.x < 0) return;
      out.add((x: at.x, y: at.y, z: 0, r: r));
    }

    final gente = (W['gente'] as Map<String, dynamic>?) ?? const {};
    for (final en in gente.entries) {
      final p = en.value as Map<String, dynamic>;
      if (p['vis'] == 0) continue;
      if (_p.noShadow((p['spot'] as String?) ?? '')) continue;
      final who = en.key.startsWith('nino') ? 'ninos' : en.key;
      cast(_atOf(p), _p.radius(who));
    }
    final q = W['cq'] as Map<String, dynamic>?;
    if (q != null && jsTruthy(q['vis'])) {
      cast(_frogPoint(q), _p.radius('coqui'));
    }
    return out;
  }

  /* ---------- the things he can touch ---------- */

  // the screen box of a sprite item: its drawn pixels' bounds
  static final Expando<List<int>> _inkOf = Expando<List<int>>();

  static List<num>? _inkBox(CajaItem it) {
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
      had = x1 < 0 ? const [] : [x0, y0, x1 - x0 + 1, y1 - y0 + 1];
      _inkOf[s] = had;
    }
    return had.isEmpty
        ? null
        : [it.left + had[0], it.top + had[1], had[2], had[3]];
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

  /// Forget the boxes of this frame (a test that changes W within one frame calls it).
  void forgetBoxes() => _boxesF = null;

  List<Thing> _things() {
    Thing sprite(String id, String tag, {num m = 0, bool z = false}) => Thing(
      id: id,
      m: m,
      z: z,
      si: (w) => _boxOfTag(w, tag) != null,
      box: (Map<String, dynamic> w) => _boxOfTag(w, tag),
    );
    Thing card(String id) {
      final b = _p.card(id);
      return Thing(
        id: id,
        m: 0,
        z: true,
        si: (w) => w['teclas'] is List,
        box: [b[0], b[1], b[2], b[3]],
      );
    }

    final caja = _p.box('caja');
    return [
      // the two answer keys: cards over the picture (spots.tecla_a, tecla_b: their boxes)
      card('tecla_a'),
      card('tecla_b'),
      // small things first: they are in front of the counter and over the people
      sprite('cosa_a', 'cosa:cosa_a', z: true),
      sprite('cosa_b', 'cosa:cosa_b', z: true),
      sprite('frasco', 'cosa:frasco', z: true),
      sprite('papel', 'cosa:papel', z: true),
      sprite('bola', 'cosa:bola', z: true),
      // the people (names: the free poke)
      for (final id in const ['pepe', 'luis', 'carmen', 'senora', 'senor'])
        sprite(id, 'persona:$id', m: 1),
      Thing(
        id: 'ninos',
        m: 1,
        si: (w) => _ninosBox(w) != null,
        box: (Map<String, dynamic> w) => _ninosBox(w),
      ),
      // the set's register (sheet: things.caja.box)
      Thing(
        id: 'caja',
        m: 0,
        world: _p.worldBox('caja'),
        box: [caja[0], caja[1], caja[2], caja[3]],
      ),
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

  // the point over a speaker's head (the speaker keys pepe, luis, carmen, senora, senor, nino): its sprite's top; `nino`
  // (and `ninos`) the middle child
  @override
  List<num>? talkAt(String who, Map<String, dynamic> W) {
    final id = who == 'ninos' || who == 'nino' ? 'nino2' : who;
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
    final cosas = [
      for (final o
          in (W['cosas'] as List? ?? const []).cast<Map<String, dynamic>>())
        if (o['vis'] != 0)
          '${o['id']}@${o['con'] ?? o['spot']}${o['v'] != null ? ':${o['v']}' : ''}',
    ].join(',');
    return 'gente=$gente cosas=$cosas importe=${W['importe']} teclas=${W['teclas']} marcas=${W['marcas']}';
  }

  /* ---------- moving ---------- */

  // a walk: a straight line at a steady pace, about 5 px of the picture a tick (comer.js mueve)
  Future<void> _anda(String id, String spot) async {
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
    final a = _atOf(p), b = _p.atWorld(w[0], w[1], w[2]);
    final dist = math.sqrt(
      (b.sx - a.sx) * (b.sx - a.sx) + (b.sy - a.sy) * (b.sy - a.sy),
    );
    final x0 = p['x'] as num, y0 = p['y'] as num, z0 = p['z'] as num;
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
    p
      ..['x'] = w[0]
      ..['y'] = w[1]
      ..['z'] = w[2]
      ..['dy'] = 0
      ..['spot'] = spot;
  }

  // the frog hops to a spot of his (the kit's hopTo: a hop about every 30 px)
  Future<void> _salta(String spot) async {
    final q = W['cq'] as Map<String, dynamic>;
    final L = _frogAt(_p.at(spot));
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
  }

  // a thing goes from where it is (or from a hand) to a world point, in a few ticks
  Future<void> _lleva(
    Map<String, dynamic> o,
    List<double> to, {
    int n = 4,
    String? spot,
  }) async {
    final con = o['con'] as String?;
    if (con != null) {
      // from the hand: start at the world point under the hand on the counter's height
      final h = _handOf(con);
      if (h != null) {
        final g = _p.fromScreen(h.x, h.y, to[2]);
        o['x'] = g.x;
        o['y'] = g.y;
        o['z'] = to[2];
      }
      o['con'] = null;
    }
    final x0 = o['x'] as num, y0 = o['y'] as num, z0 = o['z'] as num;
    for (var i = 1; i <= n; i++) {
      o['x'] = x0 + (to[0] - x0) * i / n;
      o['y'] = y0 + (to[1] - y0) * i / n;
      o['z'] = z0 + (to[2] - z0) * i / n;
      await wait(TICK);
    }
    if (spot != null) o['spot'] = spot;
  }

  // bills go one by one from one hand to another (a bill drawn in the hand it is in)
  Future<void> _billetes(
    String de,
    String a,
    int n, {
    String k = 'billete',
  }) async {
    for (var i = 0; i < n; i++) {
      final b = _cosa('$k.$de.$a.$F.$i', k, 'cosa_cliente', con: de);
      _items.add(b);
      await wait(TICK * 2);
      b['con'] = a;
      host.SFX.blip();
      await wait(TICK * 2);
      _items.remove(b);
    }
  }

  // the bell over the street door
  void _campana() {
    host.tone(1568, 0, .25, 'sine', .08);
    host.tone(2093, .08, .3, 'sine', .06);
  }

  // the register's ring (`suena`: "the bell rings and the window shows n")
  void _timbre() {
    host.tone(2637, 0, .35, 'triangle', .07);
    host.tone(3136, .05, .4, 'sine', .05);
  }

  // who stands where: the person at `cliente`, the ones in the line
  String? _en(String spot) {
    for (final e in (W['gente'] as Map<String, dynamic>).entries) {
      final m = e.value as Map;
      if (m['vis'] != 0 && m['spot'] == spot) return e.key;
    }
    return null;
  }

  // what a customer sets down when the story names nothing (the rounds of 45 and 47): what each set down in the opening
  // (caja.md: Luis a box of cans, the señor a pot, the señora a bag of rice, Carmen a frying pan)
  static String _suCompra(String quien) => switch (quien) {
    'senor' => 'olla',
    'senora' => 'arroz',
    'carmen' => 'sarten',
    _ => 'latas',
  };

  // the one item standing at a spot of the counter (cosa_cliente, cosa_a, cosa_b), not held
  Map<String, dynamic>? _sobre(String spot) {
    for (final o in _items) {
      if (o['vis'] != 0 && o['con'] == null && o['spot'] == spot) return o;
    }
    return null;
  }

  /* ---------- the acts (caja.md, "Needs") ---------- */

  // the acts started with `suelto: 1` (they run while their line is said), waited for by `ya` (as Los estantes')
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
    // `gaveta` {abre}: the drawer opens with a ring, or shuts (45: 1)
    'gaveta': (o) async {
      W['gaveta'] = _n(o['abre']) == 1 ? 1 : 0;
      _timbre();
      await wait(TICK * 4);
    },
    // `clip` {n}: n bills under the frog's clip, counted one by one; `clip` {quita: 1, a}: don Pepe takes one off: back
    // to the customer (`cliente`), or into the drawer (`gaveta`) (45: 1, 7)
    'clip': (o) async {
      final c = _item('clip');
      if (c == null) return;
      final p = _g('pepe');
      if (_n(o['quita']) == 1) {
        if (_n(c['v']) <= 0) return;
        p['pose'] = 'mano';
        c['v'] = _n(c['v']) - 1;
        host.SFX.blip();
        final b = _cosa('billete.clip.$F', 'billete', 'clip');
        _items.add(b);
        await wait(TICK * 2);
        if (o['a'] == 'cliente') {
          final q = _en('cliente');
          if (q != null) {
            b['con'] = q;
            await wait(TICK * 4);
          }
        } else {
          // into the drawer: it opens, the bill goes in, it shuts
          W['gaveta'] = 1;
          final g = ColmadoDentro.CAJA_GAVETA;
          await _lleva(b, [g[0], g[1] + .3, g[2]], n: 3);
          await wait(TICK * 2);
          W['gaveta'] = 0;
        }
        _items.remove(b);
        host.SFX.drop();
        p['pose'] = 'idle';
        return;
      }
      final n = _n(o['n']);
      p['pose'] = 'mano';
      for (var i = _n(c['v']); i < n; i++) {
        c['v'] = i + 1;
        host.SFX.blip();
        await wait(TICK * 3);
      }
      p['pose'] = 'idle';
    },
    // `aviso`: don Pepe taps the clip, then the register, and lifts a finger: take care (45: 5)
    'aviso': (o) async {
      final p = _g('pepe');
      if (p['spot'] != 'pepe.caja') await _anda('pepe', 'pepe.caja');
      p['pose'] = 'mano';
      host.SFX.blip();
      await wait(TICK * 3);
      _timbre();
      await wait(TICK * 3);
      p['pose'] = 'saluda0';
      await wait(TICK * 5);
      p['pose'] = 'idle';
    },
    // `paga45` {n}: he hands what is left under the clip to the frog, who drops it into his jar (45: 8)
    'paga45': (o) async {
      final n = _n(o['n']), c = _item('clip');
      final j =
          _item('jarra') ??
          (_cosa('jarra', 'jarra', 'frasco', v: 0, con: 'coqui'));
      if (!_items.contains(j)) _items.add(j);
      _g('pepe')['pose'] = 'mano';
      for (var i = 0; i < n; i++) {
        if (c != null) c['v'] = math.max(0, _n(c['v']) - 1);
        final b = _cosa('billete.rana.$i', 'billete', 'clip', con: 'pepe');
        _items.add(b);
        await wait(TICK * 2);
        b['con'] = 'coqui';
        await wait(TICK * 2);
        _items.remove(b);
        j['v'] = _n(j['v']) + 1;
        host.SFX.drop();
        host.bounce(4);
      }
      if (c != null) c['v'] = 0;
      _g('pepe')['pose'] = 'idle';
      await wait(TICK * 2);
    },
    // `cliente` {quien, cosa, precio, ver}: a customer comes up to the register and sets a thing down at cosa_cliente
    // with its price tag in front (ver 1: its numeral faces us; 0: it faces don Pepe, we see its blank back) (45: 2 to 7;
    // 46: 3, 4, 6, 7, no thing: `par` sets them out; 47: 2, 3, 5, 6)
    'cliente': (o) async {
      final quien = o['quien'] as String;
      W['importe'] = null;
      W['teclas'] = null;
      W['pulsada'] = null;
      final p = _g(quien);
      final aqui = _en('cliente');
      if (aqui != null && aqui != quien) {
        await acts['sale']!({'quien': aqui});
      }
      if (p['vis'] == 0) {
        // in at the street door, with the bell
        _campana();
        final w = _p.world('puerta');
        p
          ..['x'] = w[0]
          ..['y'] = w[1]
          ..['z'] = w[2]
          ..['vis'] = 1
          ..['pose'] = 'idle'
          ..['spot'] = 'puerta';
        await wait(TICK);
      }
      final era = p['spot'];
      if (era != 'cliente') await _anda(quien, 'cliente');
      p['dir'] = 1;
      // the line moves up behind him
      if (era == 'cola1') {
        final c2 = _en('cola2');
        if (c2 != null) await _anda(c2, 'cola1');
      }
      if (o['precio'] != null || o['cosa'] != null) {
        _quita('compra');
        final k = (o['cosa'] as String?) ?? _suCompra(quien);
        p['pose'] = 'mano';
        await wait(TICK * 2);
        _items.add(
          _cosa(
            'compra',
            'compra',
            'cosa_cliente',
            v: k,
            tag: {'n': '${o['precio'] ?? ''}', 'ver': _n(o['ver'])},
          ),
        );
        host.SFX.blip();
        await wait(TICK * 2);
        p['pose'] = 'idle';
      }
    },
    // `sale` {quien}: a served customer goes out by the street door, with what was bought (after each sale, 45 to 47)
    'sale': (o) async {
      final quien = o['quien'] as String;
      final p = _g(quien);
      if (p['vis'] == 0) return;
      // what was bought goes with him: the thing at cosa_cliente, a wrapped parcel
      for (final x in List.of(_items)) {
        if (x['con'] == null &&
            (x['id'] == 'compra' || (x['k'] as String).startsWith('regalo')) &&
            x['spot'] != 'taza_abuela') {
          x['con'] = quien;
        }
      }
      W['teclas'] = null;
      W['pulsada'] = null;
      p['pose'] = 'idle';
      await _anda(quien, 'puerta');
      p['vis'] = 0;
      _items.removeWhere((x) => x['con'] == quien);
      _campana();
      // the cup left beside the one bought (46): nothing to clear; the next in line waits
    },
    // `teclas` {a, b}: the numerals on the two keys (45, 47)
    'teclas': (o) async {
      W['teclas'] = ['${o['a']}', '${o['b']}'];
      W['pulsada'] = null;
      host.SFX.blip();
      await wait(TICK * 2);
    },
    // `suena` {n}: the bell rings and the register's window shows n; the key with n on it goes down (45, 47)
    'suena': (o) async {
      final n = '${o['n']}';
      final t = W['teclas'];
      if (t is List) {
        W['pulsada'] = t[0] == n
            ? 'tecla_a'
            : t[1] == n
            ? 'tecla_b'
            : null;
      }
      _timbre();
      W['importe'] = n;
      W['gaveta'] = 1;
      await wait(TICK * 4);
      W['gaveta'] = 0;
      W['pulsada'] = null;
      await wait(TICK * 2);
    },
    // `etiqueta` {ver}: don Pepe turns the tag round (45: 6, 7; 47: 5, 6)
    'etiqueta': (o) async {
      final c = _sobre('cosa_cliente');
      final p = _g('pepe');
      p['pose'] = 'mano';
      await wait(TICK * 2);
      final tg = c?['tag'] as Map<String, dynamic>?;
      if (tg != null) tg['ver'] = _n(o['ver']);
      host.SFX.blip();
      await wait(TICK * 3);
      p['pose'] = 'idle';
    },
    // `paga` {quien, n, con}: bills counted into don Pepe's hand (a few of them drawn); con 20: one twenty-dollar bill,
    // held out (45; 46; 47)
    'paga': (o) async {
      final quien = o['quien'] as String, n = _n(o['n']);
      final p = _g('pepe');
      p['pose'] = 'mano';
      if (_n(o['con']) == 20) {
        _g(quien)['pose'] = 'mano';
        final b = _cosa(
          'billete20.$quien',
          'billete20',
          'cosa_cliente',
          con: quien,
        );
        _items.add(b);
        host.SFX.blip();
        await wait(TICK * 5);
        b['con'] = 'pepe';
        _g(quien)['pose'] = 'idle';
        await wait(TICK * 3);
        _items.remove(b);
      } else {
        if (quien != 'coqui') _g(quien)['pose'] = 'mano';
        if (quien == 'coqui') {
          final j = _item('jarra');
          if (j != null) j['v'] = math.max(0, _n(j['v']) - 2);
        }
        await _billetes(quien, 'pepe', math.min(4, math.max(1, n ~/ 4)));
        if (quien != 'coqui') _g(quien)['pose'] = 'idle';
      }
      host.SFX.drop();
      p['pose'] = 'idle';
    },
    // `cola` {n}: a line forms: the next n customers come in at the street door and wait at cola1, cola2 (45: 5;
    // 46: 5, with a balloon each: "a line of people, each with a birthday hat or a balloon"; 47: 4)
    'cola': (o) async {
      final n = _n(o['n']);
      // who: the customers the story brings to the register after its line forms (its `cliente` acts after `cola`)
      final quien = <String>[];
      final story = host.S;
      var seen = false;
      for (final a in _actsOf([story['beats'], story['final']])) {
        if (a['act'] == 'cola') {
          seen = true;
          continue;
        }
        if (!seen || a['act'] != 'cliente') continue;
        final q = a['quien'];
        if (q is String && !quien.contains(q) && q != _en('cliente')) {
          quien.add(q);
        }
      }
      final fiesta = _actsOf([story['beats']])
          .any((a) => a['act'] == 'envuelve');
      final spots = _p.group('cola');
      for (var i = 0; i < n && i < quien.length && i < spots.length; i++) {
        final q = quien[i], p = _g(q);
        if (p['vis'] != 0) {
          await _anda(q, 'puerta');
          p['vis'] = 0;
        }
        _campana();
        final w = _p.world('puerta');
        p
          ..['x'] = w[0]
          ..['y'] = w[1]
          ..['z'] = w[2]
          ..['vis'] = 1
          ..['pose'] = 'idle'
          ..['spot'] = 'puerta';
        if (fiesta) {
          _items.add(_cosa('globo.$q', 'globo', 'puerta', v: i, con: q));
        }
        await _anda(q, spots[i]);
        // in the line each stands with what sticks out of the figure on the side away from the frog (the señor's cane is
        // in front of him: he faces the register; the señora's ponytail is behind her: she faces the counter's length)
        p['dir'] = q == 'senora' ? 1 : -1;
      }
    },
    // `par` {k, a, b}: two things of one kind on the counter in front of the frog, at cosa_a and cosa_b, each with its
    // tag towards us (a, b: the numerals); the dear one (the higher price) is the larger or finer make (46: 1, 3, 4, 6, 7)
    'par': (o) async {
      final k = o['k'] as String, a = _n(o['a']), b = _n(o['b']);
      _quita('cosa_a');
      _quita('cosa_b');
      _quita('roto');
      for (final (id, n, otro) in [('cosa_a', a, b), ('cosa_b', b, a)]) {
        _items.add(_cosa(id, k, id, v: n > otro, tag: {'n': '$n', 'ver': 1}));
        host.SFX.blip();
        await wait(TICK * 2);
      }
    },
    // `empuja` {cual}: the frog pushes one along to don Pepe (46: 3, 6, 7)
    'empuja': (o) async {
      final cual = o['cual'] as String;
      W['empujado'] = cual;
      host.bounce(6);
      host.SFX.blip();
      // OPEN: "the frog pushes it along to don Pepe": the sheet names no place where don Pepe wraps (nor one along the
      // counter between cosa_a or cosa_b and him); the thing stays at its spot, in front of him at pepe.empaca, and the
      // frog bounces
      final t = _item(cual);
      if (t != null) {
        final w = _p.world(cual);
        t['x'] = w[0] - .08;
        await wait(TICK * 2);
        t['x'] = w[0];
      }
      await wait(TICK * 2);
    },
    // `envuelve` {ok}: don Pepe wraps what was pushed at once (paper, string, a bow: one sheet off the holder); not ok:
    // he unwraps it and the sheet tears (46: 3, 6, 7)
    'envuelve': (o) async {
      final cual = (W['empujado'] as String?) ?? 'cosa_a';
      final t = _item(cual), papel = _item('papel'), p = _g('pepe');
      if (t == null) return;
      p['pose'] = 'mano';
      if (_n(o['ok']) == 1) {
        final n = papel == null ? 0 : _n(papel['v']);
        if (papel != null) papel['v'] = math.max(0, n - 1);
        host.SFX.blip();
        await wait(TICK * 2);
        t['envuelto'] = {'k': t['k'], 'v': t['v']};
        t['k'] = 'regalo';
        t['v'] = math.max(0, n - 1);
        host.tone(880, 0, .12, 'square', .03);
        await wait(TICK * 3);
      } else {
        final e = t['envuelto'] as Map?;
        if (e != null) {
          t['k'] = e['k'];
          t['v'] = e['v'];
          t.remove('envuelto');
        }
        final w = _p.world(cual);
        final r = _cosa('roto', 'roto', cual, v: 2);
        r['x'] = w[0] + .25;
        _items.add(r);
        host.tone(300, 0, .2, 'sawtooth', .03, 120); // the tear
        await wait(TICK * 6);
        _quita('roto');
      }
      p['pose'] = 'idle';
    },
    // `papel` {n}: the sheets on the holder (46)
    'papel': (o) async {
      final p = _item('papel');
      if (p == null) {
        _items.add(_cosa('papel', 'papel', 'papel', v: _n(o['n'])));
      } else {
        p['v'] = _n(o['n']);
      }
      await wait(TICK);
    },
    // `regalo46` {n}: the ending: abuela's cup wrapped with a bow and a paper hat for the frog (2), wrapped (1), or put
    // into a plain paper bag (0) (46: 8)
    'regalo46': (o) async {
      final n = _n(o['n']), papel = _item('papel'), t = _item('taza_abuela');
      final p = _g('pepe');
      p['pose'] = 'mano';
      await wait(TICK * 3);
      if (t != null) {
        if (n > 0) {
          t['k'] = 'regalo_grande';
          t['v'] = 0;
        } else {
          t['k'] = 'bolsapapel';
          t['v'] = 1;
        }
      }
      if (papel != null) papel['v'] = 0;
      host.SFX.blip();
      await wait(TICK * 4);
      if (n >= 2) {
        W['gorro'] = 1;
        host.bounce(6);
        host.SFX.blip();
        await wait(TICK * 4);
      }
      p['pose'] = 'idle';
    },
    // `cambio` {n, ok}: don Pepe counts n bills up into the customer's hand, one for each number of the line; ok: they
    // go into the jar and its level rises; not ok: into her purse (47: 2, 3, 5, 6; started with `suelto: 1`, then `ya`)
    'cambio': (o) async {
      final n = _n(o['n']), ok = _n(o['ok']) == 1;
      final quien = _en('cliente');
      if (quien == null) return;
      final p = _g('pepe');
      p['pose'] = 'mano';
      _g(quien)['pose'] = 'mano';
      final bills = <Map<String, dynamic>>[];
      for (var i = 0; i < n; i++) {
        final b = _cosa('cambio.$i', 'billete', 'cosa_cliente', con: 'pepe');
        _items.add(b);
        await wait(TICK * 3);
        b['con'] = quien;
        bills.add(b);
        host.SFX.blip();
        await wait(TICK * 4);
      }
      p['pose'] = 'idle';
      final f = _item('frasco');
      if (ok && f != null) {
        // into the jar: one line higher in a round of the game (the card is shown), half a line in the opening
        final w = _p.world('frasco');
        for (final b in bills) {
          await _lleva(b, w, n: 3);
          _items.remove(b);
          host.SFX.drop();
        }
        final l = (f['v'] as num?) ?? 0;
        f['v'] = jsTruthy(W['tarjeta']) ? l.floor() + 1 : l + .5;
      } else {
        await wait(TICK * 3);
        _items.removeWhere(bills.contains);
        host.SFX.drop();
      }
      _g(quien)['pose'] = 'idle';
    },
    // `cuenta47` {ok}: in a miss, don Pepe counts the wrong change into her hand, she counts it herself and shakes her
    // head; it goes back to him (47: 5, 6)
    'cuenta47': (o) async {
      final quien = _en('cliente');
      if (quien == null) return;
      final q = _g(quien), p = _g('pepe');
      p['pose'] = 'mano';
      q['pose'] = 'mano';
      final bills = <Map<String, dynamic>>[];
      for (var i = 0; i < 2; i++) {
        final b = _cosa('cuenta.$i', 'billete', 'cosa_cliente', con: quien);
        _items.add(b);
        bills.add(b);
        host.SFX.blip();
        await wait(TICK * 3);
      }
      p['pose'] = 'idle';
      q['pose'] = 'ojos';
      await wait(TICK * 5);
      q['pose'] = 'idle';
      final d = _n(q['dir']) < 0 ? -1 : 1;
      for (var i = 0; i < 4; i++) {
        q['dir'] = i % 2 == 0 ? -d : d;
        await wait(TICK);
      }
      q['dir'] = d;
      for (final b in bills) {
        b['con'] = 'pepe';
      }
      await wait(TICK * 2);
      _items.removeWhere(bills.contains);
    },
    // `frasco` {n}: the jar's level (0 at the start, 1 just under the first line, 2 at it, 3 at the second line) (47)
    'frasco': (o) async {
      final f = _item('frasco');
      if (f == null) return;
      final n = _n(o['n']);
      if (((f['v'] as num?) ?? 0) != n) host.SFX.drop();
      f['v'] = n;
      await wait(TICK);
    },
    // `muestra47`: don Pepe lifts the jar to show its level against the lines, then sets it down (47: 7)
    'muestra47': (o) async {
      final f = _item('frasco');
      final p = _g('pepe');
      if (f == null) return;
      if (p['spot'] != 'pepe.caja') await _anda('pepe', 'pepe.caja');
      f['con'] = 'pepe';
      p['pose'] = 'mano';
      host.SFX.blip();
      await wait(TICK * 8);
      f['con'] = null;
      final w = _p.world('frasco');
      f
        ..['x'] = w[0]
        ..['y'] = w[1]
        ..['z'] = w[2];
      p['pose'] = 'idle';
    },
    // `ninos47` {que}: the children at the window (ventana: they wave), two fingers held up at the jar's two lines
    // (dos), in (entran: at the street door, then group ninos_dentro), out with the ball (salen) (47: 1, 4, 7)
    'ninos47': (o) async {
      final que = o['que'] as String?;
      final fuera = _p.group('ninos_fuera'), dentro = _p.group('ninos_dentro');
      switch (que) {
        case 'ventana':
          for (var k = 0; k < 6; k++) {
            for (var i = 1; i <= 3; i++) {
              _g('nino$i')['pose'] = (k + i) % 2 == 0 ? 'saluda0' : 'saluda1';
            }
            await wait(TICK);
          }
          for (var i = 1; i <= 3; i++) {
            _g('nino$i')['pose'] = 'idle';
          }
        case 'dos':
          // OPEN: "one holds up two fingers and points at the two lines on the jar": no pose of two fingers is drawn
          // (the cast's children wave); the child in the doorway lifts a hand twice
          final c = _g('nino2');
          for (var k = 0; k < 2; k++) {
            c['pose'] = 'saluda0';
            await wait(TICK * 3);
            c['pose'] = 'idle';
            await wait(TICK * 2);
          }
        case 'entran':
          // the one in the doorway first, then the two at the window, each by the doorway
          _campana();
          for (final (k, i) in const [(0, 2), (1, 1), (2, 3)]) {
            final id = 'nino$i';
            final p = _g(id);
            p['pose'] = 'idle';
            if (p['spot'] != fuera[1]) await _anda(id, fuera[1]);
            await _anda(id, 'puerta');
            await _anda(id, dentro[k]);
            p['dir'] = 1;
          }
        case 'salen':
          final b = _item('bola');
          if (b != null) b['con'] = 'nino2';
          for (var i = 1; i <= 3; i++) {
            final id = 'nino$i';
            await _anda(id, 'puerta');
          }
          for (var i = 1; i <= 3; i++) {
            final id = 'nino$i';
            await _anda(id, fuera[1]);
            _g(id)['vis'] = 0;
          }
          b?['vis'] = 0;
          host.SFX.blip();
        default:
          await wait(TICK * 3);
      }
    },
    // `gesto` {quien, que, a}: a small move of one person (45 to 47)
    'gesto': (o) async {
      final quien = o['quien'] as String, que = o['que'] as String?;
      final a = o['a'] as String?;
      if (quien == 'coqui') {
        if (que == 'sale_taza') {
          // the frog carries abuela's cup out: it goes to his hand, he hops to the street door
          final t = _item('taza_abuela');
          if (t != null) t['con'] = 'coqui';
          host.SFX.blip();
          await _salta('puerta');
          return;
        }
        host.bounce(6);
        await wait(TICK * 3);
        return;
      }
      final p = _g(quien);
      if (p['vis'] == 0) return;
      void face(num tx) {
        final at = _atOf(p);
        if ((tx - at.sx).abs() > 2) p['dir'] = tx > at.sx ? 1 : -1;
      }

      num? xOf(String? k) {
        if (k == null) return null;
        if (k == 'ninos') {
          final b = _ninosBox(W);
          return b == null ? null : b[0] + b[2] / 2;
        }
        final t = _item(k);
        return t == null ? null : _atOf(t).sx;
      }

      switch (que) {
        case 'saluda':
          for (var i = 0; i < 6; i++) {
            p['pose'] = i % 2 == 0 ? 'saluda0' : 'saluda1';
            await wait(TICK);
          }
          p['pose'] = 'idle';
        case 'no':
          // shakes the head, looking from the register's window to the tag
          final d = _n(p['dir']) < 0 ? -1 : 1;
          for (var i = 0; i < 4; i++) {
            p['dir'] = i % 2 == 0 ? -d : d;
            await wait(TICK);
          }
          p['dir'] = d;
        case 'mano':
          final tx = xOf(a);
          if (tx != null) face(tx);
          p['pose'] = 'mano';
          await wait(TICK * 5);
          p['pose'] = 'idle';
        case 'mira':
          final tx = xOf(a == 'taza' ? 'taza_abuela' : a);
          if (tx != null) face(tx);
          await wait(TICK * 4);
        case 'senala':
          final tx = xOf(a);
          if (tx != null) face(tx);
          p['pose'] = quien == 'pepe' ? 'mano' : 'saluda0';
          // 46: 2, "Don Pepe points at the gift paper and stands the cup beside it, for later" (spots.taza_abuela)
          if (quien == 'pepe' && a == 'papel') {
            final t = _item('cosa_b') ?? _item('cosa_a');
            if (t != null) {
              t['id'] = 'taza_abuela';
              t['tag'] = null;
              await _lleva(
                t,
                _p.world('taza_abuela'),
                n: 3,
                spot: 'taza_abuela',
              );
              host.SFX.blip();
            }
          }
          await wait(TICK * 5);
          p['pose'] = 'idle';
        case 'nudillos':
          // he pulls the holder close and cracks his knuckles
          p['pose'] = 'mano';
          await wait(TICK * 3);
          p['pose'] = 'saluda0';
          host.tone(180, 0, .05, 'square', .04);
          host.tone(200, .12, .05, 'square', .04);
          await wait(TICK * 3);
          p['pose'] = 'idle';
        case 'empaca':
          // he packs a bag beside the register and holds a tag up to his glasses, its blank back to us
          await _anda('pepe', 'pepe.empaca');
          p['pose'] = 'alcanza';
          final tg = _cosa(
            'etiqueta.pepe',
            'tagback',
            'pepe.empaca',
            con: 'pepe',
          );
          _items.add(tg);
          host.SFX.blip();
          await wait(TICK * 6);
          _items.remove(tg);
          p['pose'] = 'idle';
          await _anda('pepe', 'pepe.caja');
          p['dir'] = 1;
        case 'bolsa':
          // Luis slips the plate into his own bag (a paper bag in his hand)
          final t = _item('cosa_b');
          if (t != null) {
            t['con'] = quien;
            await wait(TICK * 2);
            t['vis'] = 0;
            _quita('cosa_b');
          }
          _items.add(
            _cosa('bolsa.$quien', 'bolsapapel', 'cliente', v: 1, con: quien),
          );
          p['pose'] = 'mano';
          host.SFX.blip();
          await wait(TICK * 4);
          p['pose'] = 'idle';
        default:
          await wait(TICK * 3);
      }
    },
    // `ir` {a}: the shared act (kit.js comunes.ir: hops of about 30 px, 1 to 4), on the frog's places
    'ir': (o) async {
      final a = o['a'], key = jsTruthy(a) ? a : o['en'];
      if (key is! String || !LUGAR.containsKey(key)) return;
      final L = LUGAR[key]!, q = W['cq'] as Map<String, dynamic>;
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
  };
}
