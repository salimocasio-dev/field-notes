// Las frutas (place 4, El colmado, scene 3; stories 42 to 44): a NEW scene, written from its script's "Needs" list
// (historia/notas/guiones/frutas.md) on its set (frutas_set.dart) and its sheet (frutas-sheet.json, read by SceneSheet),
// as El mostrador is (lib/src/mostrador/). There is no old scene file: every act is this file's, each doing on screen
// what the Needs list says, every place from the sheet (a spot's world point, a thing's box, the depth rule). Where the
// sheet names no place, or the script does not settle what an act shows, the act does the plainest thing that keeps the
// story playing and says so in a comment starting `OPEN:` (page 13 lists them for the content lane).
//
// The drawing (the sheet's `front`): every sprite stands with its feet's bottom edge on its spot's row and its middle on
// its column (rules.anchor); a sprite pixel is hidden by every set pixel nearer the camera than the upright plane
// through its feet plus `front.bias` (front.plane); between two sprites the nearer pixel wins; a thing on the scale's
// pan or its dial takes the spot's `drawn_depth` (rules.depth). People and things are kept in W by their world point; a
// thing in a hand is drawn at the hand; a thing in the air between two places is kept by its screen point.
// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/src/colmado/colmado_cast.dart';
import 'package:coqui_scenes/src/frutas/frutas_places.dart';
import 'package:coqui_scenes/src/frutas/frutas_set.dart';
import 'package:coqui_scenes/src/frutas/frutas_sprites.dart';
import 'package:coqui_scenes/src/mostrador/mostrador_sprites.dart' as ms;
import 'package:coqui_scenes/src/scene_set.dart';
import 'package:coqui_scenes/src/sheet_cache.dart';

/// The scene "Las frutas", made from its sheet (read first: `loadScene`).
Scene createFrutas() => Frutas(sceneSheetOf('frutas'));

int _round(num v) => (v + 0.5).floor();

int _n(Object? v) => v is num ? v.toInt() : 0;

double _d(Object? v) => v is num ? v.toDouble() : 0;

/// One sprite of the sprite layer, placed: its picture, its top left on the 240 x 216 picture, the screen row of its
/// feet and the depth there (front.plane), and who or what it is.
class FrutasItem {
  FrutasItem(this.s, this.left, this.top, this.sy, this.d, {this.tag});

  final Sprite s;
  final int left, top;
  final num sy;
  final double d;

  /// Who or what it is (the rules' tests read it: `persona:<id>`, `cabra`, `coqui`, `cosa:<id>`, `aguja`, `dedo`).
  final String? tag;
}

/// The singular of a bin (the thing a bin holds, frutas_sprites.dart FRUTAS).
const Map<String, String> UNO = {
  'tomates': 'tomate',
  'cebollas': 'cebolla',
  'papas': 'papa',
  'platanos': 'platano',
  'aguacates': 'aguacate',
  'pinas': 'pina',
  'limones': 'limon',
};

/// The grown-ups of the scene (the rule "the frog is never behind a grown-up").
const List<String> ADULTOS = ['pepe', 'abuela', 'senora'];

class Frutas extends Escena implements SetScene, SetOverSprites {
  Frutas(this.ss) : sheet = ss.legacy() {
    _p = FrutasPlaces(ss);
    // the runner starts on `wide` (juego.js `cam = CAM.wide`): the sheet's one view
    CAM = {'wide': _p.view('wide')};
    LUGAR = {
      for (final s in const ['repisa.izq', 'repisa.der']) s: _frogAt(_p.at(s)),
      // the Needs' `repisa` (the ledge): the frog of stories 42, 43 and 44 stands at repisa.izq (the sheet's frog-places)
      'repisa': _frogAt(_p.at('repisa.izq')),
    };
    cosas = _things();
  }

  /// The new scene's sheet (SceneSheet).
  final SceneSheet ss;

  /// The old Sheet the shared code reads (`SceneSheet.legacy`: the scene, scale, origin; the start frog the runner's).
  @override
  final Sheet sheet;

  late final FrutasPlaces _p;

  /// The scene's places, from its sheet.
  FrutasPlaces get places => _p;

  @override
  String get id => 'frutas';

  @override
  late final Map<String, List<num>> CAM;

  late final Map<String, List<num>> LUGAR;

  @override
  Map<String, List<num>> get lugar => LUGAR;

  @override
  late final List<Thing> cosas;

  @override
  PpEngine newEngine({bool still = false}) => frutasEngine(still: still);

  @override
  PpEngine get projection => _p.e;

  // the frog's top left for a spot (rules.anchor: mkCoqui's column 16 on sx, its row 25 on sy)
  List<num> _frogAt(FrutasAt a) => [_round(a.sx) - 16, _round(a.sy) - 25, 1];

  Map<String, dynamic> get W => host.W;
  int get F => host.F;
  int get TICK => host.TICK;
  Future<void> wait(num ms) => host.wait(ms);

  /* ---------- the state at the start ---------- */

  // what the story does, read once from its file at the start (the scene's state at the start follows the script's
  // "Start" lines): the acts it calls and with what
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

  // the values the story's own first `set` steps give the world (story 44: `camion`)
  static Map<String, dynamic> _firstSets(Object? beats) {
    final out = <String, dynamic>{};
    if (beats is! List) return out;
    for (final st in beats) {
      if (st is Map && st['set'] is Map) {
        out.addAll((st['set'] as Map).cast<String, dynamic>());
        continue;
      }
      if (st is Map && st.containsKey('dots')) continue;
      break;
    }
    return out;
  }

  Map<String, dynamic> _person(String spot, {int vis = 1, int dir = 1}) {
    final w = _p.world(spot);
    return <String, dynamic>{
      'x': w[0],
      'y': w[1],
      'z': w[2],
      'spot': spot,
      'vis': vis,
      'dir': dir,
      'pose': 'idle',
      'dy': 0,
    };
  }

  Map<String, dynamic> _cosa(
    String id,
    String k,
    String spot, {
    double dx = 0,
    Object? v,
  }) {
    final w = _p.world(spot);
    return <String, dynamic>{
      'id': id,
      'k': k,
      'x': w[0] + dx,
      'y': w[1],
      'z': w[2],
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
    final sets = _firstSets(story['beats']);
    // story 43 sells fruit: the stand holds the frutas (its acts cut and smell aguacates, limones, piñas); 42 and 44 the
    // verduras
    final frutas = has('huele') || has('corta');
    final s44 = has('cajones'), s42 = has('tira');
    final gente = <String, dynamic>{
      // story 44's "Start": don Pepe at the hand cart, lifting the last fresh crate off it
      'pepe': _person(s44 ? 'pepe.carro' : 'pepe.detras'),
      'abuela': _person('abuela.delante'),
      'senora': _person('senora.puerta', vis: 0),
    };
    final cosas = <dynamic>[
      // story 43: abuela's basket on the ledge, its three hollows empty; 42 and 44: abuela with her basket in her hands
      // ("with her basket and her list")
      if (frutas)
        _cosa('canasta', 'canasta', 'canasta')
      else
        _cosa('canasta', 'cesta', 'abuela.delante')
          ..['con'] = 'abuela'
          ..['mano'] = 'cesta',
    ];
    // the list on the corner card: 42 "a paper with four pictures" (the four bins of verduras); 44 "tomatoes and onions,
    // each with the dial at its full mark"
    final lista = s42
        ? _p.surtido('verduras')
        : s44
        ? const ['tomates', 'cebollas']
        : const <String>[];
    final q = LUGAR['repisa.izq']!;
    return {
      'hora': 'manana',
      // the shop door: open (the set's default; story 43's señora leans out of it)
      'puerta': 'open',
      'surtido': frutas ? 'frutas' : 'verduras',
      'camion': _n(sets['camion'] ?? sets['carro']),
      'gente': gente,
      'cabra': <String, dynamic>{'pose': 'de_pie', 'hasta': 0, 'boca': null},
      'cosas': cosas,
      'lista': <String, dynamic>{
        'vis': lista.isEmpty ? 0 : 1,
        'items': lista,
        'pesa': s44 ? 1 : 0,
        'lit': null,
        'hechos': <dynamic>[],
      },
      'tarjeta': null,
      'marcas': null,
      'piensa': null,
      'aguja': 0,
      'dedo': null,
      'hueco': 0,
      'moscas': <dynamic>[],
      'bolsas': <dynamic>[],
      'cuchillo': frutas ? 1 : 0,
      'cq': <String, dynamic>{
        'x': q[0],
        'y': q[1],
        's': 1,
        'dy': 0,
        'al': 1,
        'vis': 1,
        'bub': null,
        'z': _p.world('repisa.izq')[2],
        'lleva': null,
      },
    };
  }

  /* ---------- the set ---------- */

  // the cart: W.carro, or W.camion as story 44's file names it (OPEN: the generator writes `camion` where the Needs and
  // the sheet say `carro`; both are read)
  static bool _carro(Map<String, dynamic> W) =>
      _n(W['carro']) == 1 || _n(W['camion']) == 1;

  // the sheet's setKey: "hora + puerta + carro + surtido", e.g. "manana-open-0-verduras"
  @override
  String setKey(Map<String, dynamic> W) {
    final hora = W['hora'] == 'tarde' ? 'tarde' : 'manana';
    final puerta = W['puerta'] == 'shut' ? 'shut' : 'open';
    final surtido = W['surtido'] == 'frutas' ? 'frutas' : 'verduras';
    return '$hora-$puerta-${_carro(W) ? 1 : 0}-$surtido';
  }

  @override
  void buildSet(PpEngine e, PpBuild b, Map<String, dynamic> W) =>
      buildSetFor(e, b, setKey(W));

  final Map<PpEngine, FrutasSet> _sets = {};

  @override
  void buildSetFor(PpEngine e, PpBuild b, String key) =>
      (_sets[e] ??= FrutasSet(e, b)).buildSet(FrutasState.fromKey(key));

  /// The part each pixel of state [key] belongs to (set-kit.js PART_TAGS: `tomates`, `puesto`, `carro`, ...), baked once
  /// on an engine of its own with the tags on (the rules' tests read it: abuela clear of the bins, the cart clear of her).
  List<String?> partTagsOf(String key) => _tags[key] ??= () {
    final e = frutasEngine(still: true);
    return (FrutasSet(e, PpBuild(e))
          ..tags = true
          ..buildSet(FrutasState.fromKey(key)))
        .partTags!;
  }();
  final Map<String, List<String?>> _tags = {};

  // the frog stands on the ledge: he casts no shadow (shadows.none: repisa.izq, repisa.der; onLedge); never the old one
  @override
  bool get frogShadow => false;

  /* ---------- where everybody is ---------- */

  Map<String, dynamic> _g(String id) =>
      ((W['gente'] as Map<String, dynamic>)[id] ??= _person(
            'pepe.puerta',
            vis: 0,
          ))
          as Map<String, dynamic>;

  List<Map<String, dynamic>> get _items =>
      (W['cosas'] as List).cast<Map<String, dynamic>>();

  Map<String, dynamic>? _item(String id) {
    for (final o in _items) {
      if (o['id'] == id && o['vis'] != 0) return o;
    }
    return null;
  }

  Map<String, dynamic> _add(Map<String, dynamic> o) {
    _items.removeWhere((x) => x['id'] == o['id']);
    _items.add(o);
    return o;
  }

  // a person's or a thing's place on the picture
  FrutasAt _atOf(Map<String, dynamic> o) =>
      _p.atWorld(o['x'] as num, o['y'] as num, o['z'] as num);

  // the frog's world point under his feet (his z: the ledge's top)
  FrutasAt _frogPoint(Map<String, dynamic> q) {
    final b = host.frogBox(q);
    return _p.fromScreen(b.x + b.w / 2, (q['y'] as num) + 25, _d(q['z']));
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
    if (id == 'abuela') {
      final ap = switch (pose) {
        'mano' => 'offer',
        'saluda0' => 'wave0',
        'saluda1' => 'wave1',
        _ => 'idle',
      };
      final key = 'ab$ap$open';
      final s = _spr(key, () => mkAbuela(ap, open));
      return (s: s, ax: 30, ay: inkBottom(s), key: key);
    }
    if (id == 'senora') {
      final sp = pose.startsWith('saluda') ? 'wave${pose.substring(6)}' : pose;
      final key = 'senora$sp$open';
      final s = _spr(key, () => ms.mkCliente('senora', sp, open: open));
      return (s: s, ax: PX, ay: inkBottom(s), key: key);
    }
    final key = 'pepe$pose$open';
    final s = _spr(key, () => mkPepe(pose, open: open));
    return (s: s, ax: PX, ay: inkBottom(s), key: key);
  }

  // the goat's sprite (colmado_cast.dart mkCabra: faces right; standing and chewing it looks at the stand, so it is
  // drawn mirrored; with its head in the low crate it is frutas_sprites.dart mkCabraCajon, its muzzle on cabra.cajon)
  ({Sprite s, int ax, int ay}) _cabraSprite(Map<String, dynamic> w) {
    final c = w['cabra'] as Map<String, dynamic>;
    var pose = (c['pose'] as String?) ?? 'de_pie';
    if (pose == 'mastica' && F >= _n(c['hasta'])) pose = 'de_pie';
    final f = (F >> 2) % 2;
    if (pose == 'cajon') {
      final s = _spr('cabraCajon$f', () => mkCabraCajon(f));
      return (s: s, ax: s.w ~/ 2, ay: inkBottom(s));
    }
    final k = pose == 'mastica' ? 'mastica' : pose;
    final key = 'cabra$k${k == 'mastica' ? f : 0}';
    final s = _mirror(key, _spr(key, () => mkCabra(k, k == 'mastica' ? f : 0)));
    return (s: s, ax: s.w - 1 - s.w ~/ 2, ay: inkBottom(s));
  }

  // the sprite of a thing
  Sprite _thingSprite(Map<String, dynamic> o) {
    final k = o['k'] as String, v = o['v'];
    switch (k) {
      case 'moneda':
        return _spr('moneda', mkMoneda);
      case 'canasta':
        if (o['con'] != null) {
          final en = [
            for (final x in (W['canasta'] as List? ?? const [])) x as String?,
          ];
          return _spr(
            'canastaArriba${en.join(',')}',
            () => mkCanastaArriba(en),
          );
        }
        return _spr('canasta', mkCanasta);
      case 'cesta':
        return _spr('cesta', mkCestaAbuela);
      case 'lista':
        return _spr('lista', mkLista);
      case 'monedero':
        return _spr('monedero', mkMonedero);
      case 'cuchillo':
        return _spr('cuchillo', mkCuchillo);
      case 'cortado':
        return _spr('cortado$v', () => mkAguacateCortado(v == 1));
      case 'tajada_aguacate':
        return _spr('tajadaA', mkTajadaAguacate);
      case 'tajada_limon':
        return _spr('tajadaL', mkTajadaLimon);
      case 'guineo':
        return _spr('guineo', () => mkPlatano(true));
      case 'bolsa':
        return _spr('bolsa', () => mkBolsaPapel(true));
      case 'plato':
        final m = v as Map;
        return _spr(
          'plato${m['k']}${m['n']}',
          () => mkEnPlato(m['k'] as String, _d(m['n'])),
        );
      case 'cajon':
        final m = v as Map;
        final fresco = m['fresco'] == 1,
            lleno = _d(m['lleno']),
            volcado = m['volcado'] == 1,
            pequeno = m['pequeno'] == 1,
            ck = m['k'] as String;
        return _spr(
          'cajon$ck$fresco$lleno$volcado$pequeno',
          () => mkCajon(
            ck,
            fresco: fresco,
            lleno: lleno,
            volcado: volcado,
            pequeno: pequeno,
          ),
        );
      case 'fruta':
        final m = v as Map;
        final f = m['k'] as String, grande = m['grande'] == 1;
        return _spr('fruta$f$grande', () => mkFruta(f, grande: grande));
    }
    throw StateError('Las frutas: no sprite for $k');
  }

  // a held thing with the holder's hand over it (frutas-preview.html's `hands`: a small round of skin at its lower middle)
  Sprite _enMano(Sprite s, String key) => _spr('mano$key', () {
    final h = Buf(6, 6)..ell(3, 3, 2.3, 2.3, [RP.skin[2], RP.skin[3]]);
    final hand = h.outline().done();
    return overSprite(s, [(hand, s.w ~/ 2 - 3, s.h - 5)], top: 0);
  });

  // where a held thing is drawn: its bottom middle at the holder's hand (abuela: `der` her right, `izq` her left, both
  // round her basket `cesta`, lifted to her nose `cara`, held up `arriba`; frutas-preview.html moments 1 to 3: her
  // basket at her middle, the big fruit at her right, the small one at her left), as a point of the picture with the
  // holder's depth
  ({num x, num y, double d, num sy})? _handOf(String holder, String? side) {
    if (holder == 'coqui') {
      final q = W['cq'] as Map<String, dynamic>;
      if (!jsTruthy(q['vis'])) return null;
      final b = host.frogBox(q), at = _frogPoint(q);
      return (
        x: b.x + b.w + 3,
        y: (q['y'] as num) + 24,
        d: at.d + .05,
        sy: at.sy,
      );
    }
    final p =
        (W['gente'] as Map<String, dynamic>)[holder] as Map<String, dynamic>?;
    if (p == null || p['vis'] == 0) return null;
    final at = _atOf(p), sx = _round(at.sx), sy = _round(at.sy);
    if (holder == 'abuela') {
      final (dx, dy) = switch (side) {
        'der' => (12, -10),
        'izq' => (-12, -8),
        'cara' => (5, -31),
        'arriba' => (0, -8),
        'alto' => (13, -26),
        _ => (0, -7),
      };
      return (x: sx + dx, y: sy + dy, d: at.d + .05, sy: at.sy);
    }
    // don Pepe's hand held out (mkPersona 'offer': kit.js X - rx - 9.5 = 17.5 px from his middle, row 25 of his 54)
    final dir = _n(p['dir']) < 0 ? -1 : 1;
    return (x: sx - dir * 17, y: sy - 25, d: at.d + .05, sy: at.sy);
  }

  /// Every sprite of the frame [w] as it is placed (the people, the goat, the things), the frog not among them. The
  /// rules' tests read it; [draw] draws it.
  List<FrutasItem> items(Map<String, dynamic> w, int a) {
    final out = <FrutasItem>[];
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
        FrutasItem(s, sx - ax, sy - sp.ay, sy, at.d, tag: 'persona:${en.key}'),
      );
    }
    // the goat at its post
    if (w['cabra'] is Map) {
      final at = _p.at('cabra.poste'), g = _cabraSprite(w);
      final sx = _round(at.sx), sy = _round(at.sy);
      out.add(FrutasItem(g.s, sx - g.ax, sy - g.ay, sy, at.d, tag: 'cabra'));
      // what it holds in its mouth (a plátano it took: story 42 step 5)
      final boca = (w['cabra'] as Map)['boca'];
      if (boca is String && (w['cabra'] as Map)['pose'] == 'cuello') {
        final s = _spr('fruta$boca', () => mkFruta(boca));
        // the head of mkCabra 'cuello', mirrored: its muzzle at column 36 - 1 - (15 + 17 + 3) of the sprite
        final mx = sx - g.ax + (g.s.w - 1 - 35), my = sy - g.ay + 13;
        out.add(
          FrutasItem(
            s,
            mx - s.w ~/ 2,
            my - s.h ~/ 2,
            sy,
            at.d + .05,
            tag: 'boca',
          ),
        );
      }
    }
    // don Pepe's knife in his other hand (43: "behind it with his knife"), down while he cuts
    final pepe = gente['pepe'] as Map<String, dynamic>?;
    if (_n(w['cuchillo']) > 0 && pepe != null && pepe['vis'] != 0) {
      final at = _atOf(pepe), dir = _n(pepe['dir']) < 0 ? -1 : 1;
      final s = _spr('cuchillo', mkCuchillo);
      final x = _round(at.sx) + dir * 9,
          y = _round(at.sy) - 20 + (_n(w['cuchillo']) == 2 ? 4 : 0);
      out.add(
        FrutasItem(
          s,
          x - s.w ~/ 2,
          y - s.h,
          at.sy,
          at.d + .05,
          tag: 'cuchillo',
        ),
      );
    }
    for (final o
        in (w['cosas'] as List? ?? const []).cast<Map<String, dynamic>>()) {
      if (o['vis'] == 0) continue;
      var s = _thingSprite(o);
      final con = o['con'] as String?;
      if (con != null) {
        final h = _handOf(con, o['mano'] as String?);
        if (h == null) continue;
        if (con == 'abuela' && o['k'] == 'fruta') {
          s = _enMano(
            s,
            '${o['k']}${(o['v'] as Map)['k']}${(o['v'] as Map)['grande']}',
          );
        }
        out.add(
          FrutasItem(
            s,
            _round(h.x) - s.w ~/ 2,
            _round(h.y) - inkBottom(s),
            h.sy,
            h.d,
            tag: 'cosa:${o['id']}',
          ),
        );
        continue;
      }
      if (o['sx'] is num) {
        // in the air between two places: its screen point, in front of everything
        final x = _round(o['sx'] as num), y = _round(o['sy'] as num);
        out.add(
          FrutasItem(
            s,
            x - s.w ~/ 2,
            y - inkBottom(s),
            y,
            99,
            tag: 'cosa:${o['id']}',
          ),
        );
        continue;
      }
      final at = _atOf(o);
      final sx = _round(at.sx) + _n(o['px']), sy = _round(at.sy) + _n(o['py']);
      final spot = o['spot'] as String?;
      final d = spot == 'plato'
          ? _p.drawnDepth('plato') + .01
          : at.d + _d(o['dd']);
      out.add(
        FrutasItem(
          s,
          sx - s.w ~/ 2,
          sy - inkBottom(s),
          sy,
          d,
          tag: 'cosa:${o['id']}',
        ),
      );
    }
    // the scale's needle over its dial, at its middle (colmado-fuera.js dial: floor of the projection), at the dial's
    // drawn depth (rules.depth); a world with no `aguja` (a picture of the set alone, as La mesa's cocina.no) has none
    final ag = _p.at('aguja'), cx = ag.sx.floor(), cy = ag.sy.floor();
    final nd = _p.drawnDepth('aguja') + .01;
    if (w['aguja'] is num) {
      final n = _d(w['aguja']);
      out.add(
        FrutasItem(
          _spr('aguja$n', () => mkAguja(n)),
          cx - 5,
          cy - 5,
          cy,
          nd,
          tag: 'aguja',
        ),
      );
    }
    // his finger on a mark of the dial (the kit's marks: 3 to 5 px from its middle, at 3 and 6 o'clock)
    final dedo = w['dedo'];
    if (dedo is String) {
      final s = _spr('dedo', mkDedo);
      final (mx, my) = dedo == 'medio'
          ? (cx + 4, cy)
          : dedo == 'libra'
          ? (cx, cy + 4)
          : (cx, cy - 4);
      out.add(FrutasItem(s, mx - 1, my - 4, cy, nd + .01, tag: 'dedo'));
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
    FrutasItem it,
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
  List<FrutasItem> placed(Map<String, dynamic> W, int a) {
    final all = items(W, a);
    final q = W['cq'] as Map<String, dynamic>;
    if (jsTruthy(q['vis'])) {
      final b = host.frogBox(q), at = _frogPoint(q);
      final ox = b.x.toInt() - 16, oy = b.y.toInt() - 24;
      final px = Uint32List(64 * 64);
      final g = Ctx(px, 64, 64)..translate(-ox.toDouble(), -oy.toDouble());
      host.frog(g, q, a);
      all.add(
        FrutasItem(
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
    _over(c, W, a);
  }

  // what is drawn over everything: the flies, a thought
  void _over(Ctx c, Map<String, dynamic> W, int a) {
    for (final m in (W['moscas'] as List? ?? const [])) {
      final b = _moscaBox(W, m as String);
      if (b == null) continue;
      final t = F / 3 + m.length;
      final x = b[0] + b[2] / 2 + math.cos(t) * (b[2] / 2 + 2),
          y = b[1] - 3 + math.sin(t * 1.3) * 3;
      c.drawImage(
        _spr('mosca${(F >> 1) % 2}', () => mkMosca((F >> 1) % 2)),
        _round(x) - 2,
        _round(y) - 2,
      );
    }
    final pi = W['piensa'] as Map<String, dynamic>?;
    if (pi != null && F < _n(pi['hasta'])) {
      final h = _headOf(pi['quien'] as String);
      if (h != null) {
        nube(c, h[0] + 4, h[1] - 32, pi['k'] as String, [h[0], h[1]]);
      }
    }
  }

  // where a fly circles: over a thing's drawn box (`cosa:<id>`), over a hollow of the basket (`hueco:<i>`)
  List<num>? _moscaBox(Map<String, dynamic> w, String m) {
    if (m.startsWith('hueco:')) {
      return _boxOfTag(w, 'cosa:hueco.${m.substring(6)}');
    }
    return _boxOfTag(w, 'cosa:$m');
  }

  /// A thought (frutas.md: "a thought over abuela: a pot of soup", "a guineo over the frog"): an outlined cloud of round
  /// lobes with two small circles that lead to the one who thinks, and the thing in it (El mostrador's `nube`).
  void nube(Ctx g, num x, num y, String k, List<num> aim) {
    final im = k == 'sopa'
        ? _spr('olla', mkOlla)
        : k == 'guineo'
        ? _spr('guineo', () => mkPlatano(true))
        : _spr('fruta$k', () => mkFruta(UNO[k] ?? k));
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

  /* ---------- the boards: abuela's list, the two rounds ---------- */

  @override
  void hud(Ctx c, Map<String, dynamic> W, int a) {
    final lista = W['lista'] as Map<String, dynamic>?;
    var x0 = 3;
    if (lista != null && jsTruthy(lista['vis'])) {
      final items = (lista['items'] as List).cast<String>();
      final dial = _n(lista['pesa']) == 1, step = dial ? 26 : 18;
      final w = 6 + step * items.length;
      tarjeta(c, 3, 3, w, 24);
      for (var i = 0; i < items.length; i++) {
        final k = items[i], s = _spr('fruta${UNO[k]}', () => mkFruta(UNO[k]!));
        final x = 6 + i * step, cx = x + 8;
        if (lista['lit'] == k && (F >> 2) % 2 == 0) {
          fr(c, x - 1, 4, 18, 22, 0xFF40E0FF);
        }
        c.drawImage(s, _round(cx - s.w / 2), 5 + (16 - s.h) ~/ 2 + 2);
        if (dial) {
          // the dial at its full mark (story 44's list: a pound of each)
          c.drawImage(_spr('dialLista', _dialLista), x + 16, 9);
        }
        if ((lista['hechos'] as List).contains(k)) {
          c.drawImage(_spr('visto', ms.mkVisto), x + 9, 18);
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

  // a small dial with its needle at the full mark, for the list card (7 x 7)
  static Sprite _dialLista() {
    final b = Buf(9, 9);
    b.ell(4.5, 4.5, 3.6, 3.6, [0xFF3A3A46]);
    b.ell(4.5, 4.5, 2.8, 2.8, [0xFFF4FAFC]);
    b.rect(4, 4, 1, 3, 0xFF2828E0);
    return b.done();
  }

  /* ---------- the shadows (sheet: shadows) ---------- */

  // castShadow(x, y, 0, radius) at the world x, y of whoever stands on the pavement (shadows.at): don Pepe, abuela, the
  // señora, the goat; none for the frog on the ledge (shadows.none, onLedge), none for a thing
  @override
  List<ShadowCast> shadows(Map<String, dynamic> W) {
    final out = <ShadowCast>[];
    final gente = (W['gente'] as Map<String, dynamic>?) ?? const {};
    for (final en in gente.entries) {
      final p = en.value as Map<String, dynamic>;
      if (p['vis'] == 0 || _d(p['z']) != 0) continue;
      if (_p.noShadow((p['spot'] as String?) ?? '')) continue;
      final r = _p.radius(en.key);
      if (r == null) continue;
      out.add((x: _d(p['x']), y: _d(p['y']), z: 0, r: r));
    }
    if (W['cabra'] is Map) {
      final w = _p.world('cabra.poste'), r = _p.radius('cabra');
      if (r != null) out.add((x: w[0], y: w[1], z: 0, r: r));
    }
    return out;
  }

  /* ---------- the things he can touch ---------- */

  static final Expando<List<int>> _inkOf = Expando<List<int>>();

  static List<num>? _inkBox(FrutasItem it) {
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

  // the boxes of the frame now (one list of placed sprites a frame: the signs ask for boxes many times a frame)
  int? _boxesF;
  Map<String, dynamic>? _boxesW;
  Map<String, FrutasItem> _byTag = {};

  Map<String, FrutasItem> _itemsByTag(Map<String, dynamic> w) {
    int? f;
    try {
      f = host.F;
    } catch (_) {
      f = null;
    }
    if (f == null || f != _boxesF || !identical(w, _boxesW)) {
      _byTag = {
        for (final it in items(w, 0))
          if (it.tag != null) it.tag!: it,
      };
      _boxesF = f;
      _boxesW = w;
    }
    return _byTag;
  }

  List<num>? _boxOfTag(Map<String, dynamic> w, String tag) {
    final it = _itemsByTag(w)[tag];
    return it == null ? null : _inkBox(it);
  }

  // whether a sprite item draws a pixel at (x, y) or within [m] of it
  static bool _inkAt(FrutasItem it, num x, num y, int m) {
    final s = it.s;
    for (var dy = -m; dy <= m; dy++) {
      for (var dx = -m; dx <= m; dx++) {
        final X = x.floor() + dx - it.left, Y = y.floor() + dy - it.top;
        if (X < 0 || Y < 0 || X >= s.w || Y >= s.h) continue;
        if (s.px[Y * s.w + X] >>> 24 != 0) return true;
      }
    }
    return false;
  }

  // the person, goat and thing sprites he can touch, by thing id and the tag of its item
  static const Map<String, String> _spriteTags = {
    'fruta_a': 'cosa:fruta_a',
    'fruta_b': 'cosa:fruta_b',
    'cajon_a': 'cosa:cajon_a',
    'cajon_b': 'cosa:cajon_b',
    'canasta': 'cosa:canasta',
    'pepe': 'persona:pepe',
    'abuela': 'persona:abuela',
    'senora': 'persona:senora',
    'cabra': 'cabra',
  };

  static const List<String> _bins = [
    'tomates',
    'cebollas',
    'papas',
    'platanos',
    'aguacates',
    'pinas',
    'limones',
  ];

  List<Thing> _things() {
    Thing sprite(String id, {num m = 0, bool z = false}) => Thing(
      id: id,
      m: m,
      z: z,
      si: (w) => _boxOfTag(w, _spriteTags[id]!) != null,
      box: (Map<String, dynamic> w) => _boxOfTag(w, _spriteTags[id]!),
    );
    Thing setThing(String id, {bool Function(Map<String, dynamic>)? si}) {
      final b = _p.box(id);
      final t = _p.sheet.thing(id);
      return Thing(
        id: id,
        m: 0,
        world: t.world,
        si: si,
        box: [b[0], b[1], b[2], b[3]],
        hand: (Map<String, dynamic> w) => _handPoint(id, w),
      );
    }

    return [
      // small things first: they are in front of the stand and the people
      for (final id in const [
        'fruta_a',
        'fruta_b',
        'cajon_a',
        'cajon_b',
        'canasta',
      ])
        sprite(id, z: true),
      // the bins of the assortment in the set (sheet: things.<bin>.box, surtido)
      for (final k in _bins)
        setThing(k, si: (w) => (w['surtido'] ?? 'verduras') == _p.surtidoOf(k)),
      // the people and the goat (the free poke)
      for (final id in const ['pepe', 'abuela', 'senora', 'cabra'])
        sprite(id, m: 1),
      // the set's other things (sheet: things.<id>.box)
      setThing('pesa'),
      setThing('guineos'),
      setThing('cajon'),
      setThing('puerta'),
    ];
  }

  // Where the big hand points at a set thing: its box's middle, unless something answers a touch before it there (the
  // frog on the ledge in front of the bin of tomatoes, a small thing, another bin whose middle is nearer): then the point
  // of its box nearest its middle where a touch gives this thing.
  List<num> _handPoint(String id, Map<String, dynamic> w) {
    final b = _p.box(id);
    final mx = b[0] + b[2] / 2, my = b[1] + b[3] / 2;
    // the runner's touch is at the hand's point and 3 down (Story.tapOn)
    if (hit(mx, my + 3, w) == id) return [_round(mx), _round(my)];
    List<num>? best;
    var bd = 1e9;
    for (var y = b[1]; y < b[1] + b[3] - 3; y++) {
      for (var x = b[0]; x < b[0] + b[2]; x++) {
        final dd = (x - mx) * (x - mx) + (y - my) * (y - my);
        if (dd >= bd) continue;
        if (hit(x, y + 3, w) != id) continue;
        bd = dd.toDouble();
        best = [x, y];
      }
    }
    return best ?? [_round(mx), _round(my)];
  }

  // A touch at (x, y) (kit.js escena.hit, in its order: the small things, the frog, the rest), each sprite by its drawn
  // pixels (1 px round them) inside its box, the set's bins by the bin whose box's middle is nearest among those whose
  // box holds the point (the bins' boxes overlap: the stand is slanted), the set's other things by their boxes.
  @override
  String? hit(num x, num y, Map<String, dynamic> w) {
    bool inb(List<num>? b, num m) =>
        b != null &&
        x >= b[0] - m &&
        x < b[0] + b[2] + m &&
        y >= b[1] - m &&
        y < b[1] + b[3] + m;
    final tags = _itemsByTag(w);
    bool spriteHit(Thing t) {
      final it = tags[_spriteTags[t.id]];
      if (it == null) return false;
      return inb(_inkBox(it), t.m ?? 3) && _inkAt(it, x, y, 1 + _n(t.m));
    }

    for (final t in cosas) {
      if (t.z && (t.si == null || t.si!(w)) && spriteHit(t)) return t.id;
    }
    final q = w['cq'] as Map<String, dynamic>, fb = host.frogBox(q);
    if (jsTruthy(q['vis']) &&
        x >= fb.x &&
        x < fb.x + fb.w &&
        y >= fb.y &&
        y < fb.y + fb.h) {
      return 'coqui';
    }
    String? bin;
    var bd = 1e9;
    for (final t in cosas) {
      if (!_bins.contains(t.id) || !(t.si == null || t.si!(w))) continue;
      final b = t.box as List<num>;
      if (!inb(b, 0)) continue;
      final cx = b[0] + b[2] / 2, cy = b[1] + b[3] / 2;
      final dd = (x - cx) * (x - cx) + (y - cy) * (y - cy);
      if (dd < bd) {
        bd = dd.toDouble();
        bin = t.id;
      }
    }
    // a person or the goat drawn over a bin takes the touch on its own pixels
    for (final t in cosas) {
      if (t.z || !_spriteTags.containsKey(t.id)) continue;
      if (spriteHit(t)) return t.id;
    }
    if (bin != null) return bin;
    for (final t in cosas) {
      if (t.z || _bins.contains(t.id) || _spriteTags.containsKey(t.id)) {
        continue;
      }
      if ((t.si == null || t.si!(w)) && inb(t.box as List<num>, t.m ?? 3)) {
        return t.id;
      }
    }
    return null;
  }

  /* ---------- talking ---------- */

  // the point over a speaker's head (the speaker keys pepe, abuela, senora): its sprite's top
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
        if (o['vis'] != 0) '${o['id']}@${o['con'] ?? o['spot']}',
    ].join(',');
    return 'carro=${_carro(W) ? 1 : 0} surtido=${W['surtido']} gente=$gente cabra=${(W['cabra'] as Map?)?['pose']} '
        'cosas=$cosas canasta=${W['canasta']} aguja=${W['aguja']} bolsas=${W['bolsas']} marcas=${W['marcas']}';
  }

  /* ---------- moving ---------- */

  // a walk: a straight line at a steady pace, about 5 px of the picture a tick (El mostrador's `_anda`)
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

  // don Pepe holds his hand out towards a screen column: mkPepe 'mano' is mkPersona's 'offer', its hand out on the
  // sprite's left (kit.js: X - rx - 9.5, row 25), so he is drawn mirrored when the column is right of him
  void _tiende(num x) {
    final p = _g('pepe'), at = _atOf(p);
    if ((x - at.sx).abs() > 2) p['dir'] = x < at.sx ? 1 : -1;
  }

  // a person turns to face a screen column
  void _mira(String id, num x) {
    final p = _g(id), at = _atOf(p);
    if ((x - at.sx).abs() > 2) p['dir'] = x > at.sx ? 1 : -1;
  }

  // the screen point a thing is drawn at now (its bottom middle): in a hand, in the air, or at its world point
  List<num> _screenOf(Map<String, dynamic> o) {
    final con = o['con'] as String?;
    if (con != null) {
      final h = _handOf(con, o['mano'] as String?);
      if (h != null) return [h.x, h.y];
    }
    if (o['sx'] is num) return [o['sx'] as num, o['sy'] as num];
    final at = _atOf(o);
    return [_round(at.sx) + _n(o['px']), _round(at.sy) + _n(o['py'])];
  }

  // a thing flies from where it is drawn to [to] (a screen point) in [n] ticks, along an arc [lift] px high (a toss, a
  // drop); it is then kept by its screen point until it is put somewhere
  Future<void> _vuela(
    Map<String, dynamic> o,
    List<num> to, {
    int n = 5,
    num lift = 12,
    List<num>? via,
  }) async {
    final from = _screenOf(o);
    o['con'] = null;
    final mid = via ?? [(from[0] + to[0]) / 2, math.min(from[1], to[1]) - lift];
    for (var i = 1; i <= n; i++) {
      final t = i / n, u = 1 - t;
      o['sx'] = u * u * from[0] + 2 * u * t * mid[0] + t * t * to[0];
      o['sy'] = u * u * from[1] + 2 * u * t * mid[1] + t * t * to[1];
      await wait(TICK);
    }
  }

  // a thing is set at a spot of the sheet (its world point), with a nudge in screen pixels and of depth
  void _pon(
    Map<String, dynamic> o,
    String spot, {
    double dx = 0,
    int px = 0,
    int py = 0,
    double dd = 0,
  }) {
    final w = _p.world(spot);
    o
      ..['x'] = w[0] + dx
      ..['y'] = w[1]
      ..['z'] = w[2]
      ..['spot'] = spot
      ..['px'] = px
      ..['py'] = py
      ..['dd'] = dd
      ..['con'] = null
      ..remove('sx')
      ..remove('sy');
  }

  List<num> _spotScreen(String spot) {
    final at = _p.at(spot);
    return [_round(at.sx), _round(at.sy)];
  }

  // the top middle of a bin's space (its world box: x and y in the middle, z at its top), as a screen point
  List<num> _binTop(String k) {
    final b = _p.worldBox(k);
    final at = _p.atWorld((b[0] + b[3]) / 2, (b[1] + b[4]) / 2, b[5] - .2);
    return [_round(at.sx), _round(at.sy)];
  }

  // a coin from abuela's row on the ledge to don Pepe's hand: the last coin of the row [row] (`monedas4`: the four for
  // the four things; `monedas2`: the two under the guineos)
  Future<bool> _pagaUna(String row) async {
    Map<String, dynamic>? c;
    for (final x in _items) {
      if (x['k'] == 'moneda' &&
          x['vis'] != 0 &&
          x['spot'] == row &&
          x['sx'] == null) {
        c = x;
      }
    }
    if (c == null) return false;
    final pepe = _g('pepe');
    final h = _handOf('pepe', null);
    if (h != null && pepe['vis'] != 0) {
      pepe['pose'] = 'mano';
      _tiende(_screenOf(c)[0]);
      await _vuela(c, [h.x, h.y], n: 4, lift: 8);
    }
    c['vis'] = 0;
    host.SFX.drop();
    pepe['pose'] = 'idle';
    await wait(TICK);
    return true;
  }

  // the goat eats what lies on the low crate (spot `bajo`): its head down into it (cabra.cajon), munching, each thing
  // gone in turn; then it chews
  Future<void> _come() async {
    final c = W['cabra'] as Map<String, dynamic>;
    c['pose'] = 'cajon';
    await wait(TICK * 2);
    for (final x in _items.toList()) {
      if (x['vis'] == 0 || x['spot'] != 'bajo' || x['k'] == 'cajon') continue;
      host.SFX.munch();
      await wait(TICK * 3);
      x['vis'] = 0;
    }
    await wait(TICK * 2);
    c['pose'] = 'mastica';
    c['hasta'] = F + 30;
  }

  // what lies on the scale's pan goes into a paper bag and into abuela's basket; the needle back to rest (44: "then into
  // a bag in abuela's basket"). Called by every act but `marca44` and `marca` before it runs: the pan is shown while the
  // story says what it weighs
  Future<void> _embolsa() async {
    W['dedo'] = null;
    final pl = _item('plato');
    if (pl == null) return;
    final m = pl['v'] as Map;
    pl['vis'] = 0;
    W['aguja'] = 0;
    final b = _add(
      _cosa('bolsa.${(W['bolsas'] as List).length}', 'bolsa', 'plato'),
    );
    _pon(b, 'plato');
    host.SFX.blip();
    await wait(TICK * 2);
    final ab = _g('abuela');
    if (ab['vis'] != 0) {
      final h = _handOf('abuela', 'cesta')!;
      await _vuela(b, [h.x, h.y], n: 5, lift: 10);
    }
    b['vis'] = 0;
    (W['bolsas'] as List).add(<String, dynamic>{'k': m['k'], 'n': m['n']});
    host.SFX.drop();
    await wait(TICK);
  }

  // the crate of the ledge at [lado] (`a`, `b`), or null
  Map<String, dynamic>? _cajon(String lado) => _item('cajon_$lado');

  // the crate of [k] on the ledge that is fresh (or yesterday's when [fresco] is false)
  Map<String, dynamic>? _cajonDe(String k, {bool fresco = true}) {
    for (final l in const ['a', 'b']) {
      final c = _cajon(l);
      if (c == null) continue;
      final m = c['v'] as Map;
      if (m['k'] == k && (m['fresco'] == 1) == fresco) return c;
    }
    return null;
  }

  // the hollow of each fruit in abuela's basket (43)
  static const Map<String, int> _HUECO = {'limon': 0, 'aguacate': 1, 'pina': 2};

  // the fruit in hollow [i] of the basket (its item id)
  String _hueco(int i) => 'hueco.$i';

  // a person walks a way of named spots
  Future<void> _camino(String id, List<String> spots) async {
    for (final s in spots) {
      await _anda(id, s);
    }
  }

  /* ---------- the acts (frutas.md, "Needs") ---------- */

  @override
  Map<String, Act> get ownActs {
    final acts = _acts();
    // what lies on the pan is bagged before every act but his finger on the dial and the rounds' star (see _embolsa)
    return {
      for (final e in acts.entries)
        e.key: e.key == 'marca44' || e.key == 'marca' || e.key == 'ya'
            ? e.value
            : (o) async {
                await _embolsa();
                await e.value(o);
              },
    };
  }

  Map<String, Act> _acts() => {
    // `lista` {k, hecho}: a picture on the list lights (hecho 0), or gets its tick (hecho 1) (42: 3, 4)
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
    // `piensa` {quien, k}: a thought over somebody: a pot of soup over abuela, a guineo over the frog (42: 1)
    'piensa': (o) async {
      W['piensa'] = <String, dynamic>{
        'quien': o['quien'],
        'k': o['k'],
        'hasta': F + 40,
      };
      host.SFX.blip();
      await wait(300);
    },
    // `monedas` {n}: abuela lays her coins on the ledge: four together (monedas4), the others under the guineos
    // (monedas2), each row .2 apart along x (the sheet's `dir`, `row.step`) (42: 1)
    'monedas': (o) async {
      final n = _n(o['n']), r4 = _p.row('monedas4'), r2 = _p.row('monedas2');
      final ab = _g('abuela');
      ab['pose'] = 'mano';
      for (var i = 0; i < n; i++) {
        final four = i < r4.n;
        final row = four ? 'monedas4' : 'monedas2', j = four ? i : i - r4.n;
        if (!four && j >= r2.n) break;
        final step = four ? r4.step : r2.step;
        _add(_cosa('moneda.$row.$j', 'moneda', row, dx: j * step));
        host.SFX.drop();
        await wait(TICK);
      }
      ab['pose'] = 'idle';
    },
    // `mano` {k}: don Pepe lays a hand on a bin (42: 2, 4), or takes one thing out of it and holds it up (43: 1)
    'mano': (o) async {
      final k = o['k'] as String, p = _g('pepe');
      if (p['vis'] == 0) return;
      // OPEN: the sheet names one place behind the stand (pepe.detras) and none behind each bin: he reaches towards the
      // bin from there (he turns to its middle; his hand is out)
      _tiende(_binTop(k)[0]);
      p['pose'] = 'mano';
      host.SFX.blip();
      if (W['surtido'] == 'frutas') {
        // 43: he takes one out of the bin and holds it up
        final f = _add(
          _cosa(
            'pepe.fruta',
            'fruta',
            'pepe.detras',
            v: {'k': UNO[k], 'grande': 1},
          ),
        );
        f['con'] = 'pepe';
        await wait(TICK * 4);
        return;
      }
      await wait(TICK * 5);
      p['pose'] = 'idle';
    },
    // `corta` {k, bueno}: don Pepe cuts an aguacate in two: green inside, or black inside with a fly (43: 1, 2)
    'corta': (o) async {
      final p = _g('pepe'), bueno = _n(o['bueno']);
      p['pose'] = 'mano';
      final k = o['k'] as String;
      // another one from the bin when his hand is empty or holds the one cut before
      var f = _item('pepe.fruta');
      if (f == null || f['k'] != 'fruta') {
        _tiende(_binTop(k)[0]);
        f = _add(
          _cosa(
            'pepe.fruta',
            'fruta',
            'pepe.detras',
            v: {'k': UNO[k], 'grande': 1},
          ),
        );
        f['con'] = 'pepe';
        await wait(TICK * 3);
      }
      // the knife comes down
      W['cuchillo'] = 2;
      host.tone(900, 0, .08, 'square', .03);
      await wait(TICK * 3);
      W['cuchillo'] = 1;
      f
        ..['k'] = 'cortado'
        ..['v'] = bueno;
      final moscas = W['moscas'] as List;
      if (bueno == 0) {
        moscas.add('pepe.fruta');
      } else {
        moscas.remove('pepe.fruta');
      }
      host.SFX.blip();
      await wait(TICK * 4);
    },
    // `prueba43`: he holds a slice out to the frog; the frog eats it (43: 1)
    'prueba43': (o) async {
      final p = _g('pepe');
      p['pose'] = 'mano';
      final s = _add(_cosa('tajada', 'tajada_aguacate', 'pepe.detras'))
        ..['con'] = 'pepe';
      await wait(TICK * 3);
      final h = _handOf('coqui', null);
      if (h != null) await _vuela(s, [h.x - 4, h.y - 6], n: 5, lift: 10);
      host.SFX.munch();
      host.bounce(5);
      s['vis'] = 0;
      await wait(TICK * 4);
      p['pose'] = 'idle';
    },
    // `suelta` {quien, que}: somebody drops what he holds onto the low crate (`bajo`): don Pepe the bad aguacate; abuela
    // the small limón, the other fruit of a round, or both the bad one in the basket and the one beside it (43: 2, 3, 5,
    // 6). The goat's `come` follows
    'suelta': (o) async {
      final quien = o['quien'] as String, que = o['que'] as String?;
      final drop = <Map<String, dynamic>>[];
      if (quien == 'pepe') {
        final f = _item('pepe.fruta');
        if (f != null) drop.add(f);
      } else if (que == 'ambas') {
        // the last one laid in the basket (the bad one) and the one in the hollow before it
        final i = _n(W['ultimo']);
        for (final j in [i, i - 1]) {
          final f = j >= 0 ? _item(_hueco(j)) : null;
          if (f != null) drop.add(f);
        }
        final en = W['canasta'] as List? ?? [];
        for (final j in [i, i - 1]) {
          if (j >= 0 && j < en.length) en[j] = null;
        }
      } else {
        // the one abuela still holds (`limon`: the small limón, fruta_b; `otra`: the other of the round)
        for (final id in const ['fruta_a', 'fruta_b']) {
          final f = _item(id);
          if (f != null && f['con'] == 'abuela') drop.add(f);
        }
      }
      if (quien == 'abuela') _g('abuela')['pose'] = 'mano';
      final to = _spotScreen('bajo');
      for (final f in drop) {
        final key = f['id'] as String;
        f['id'] = 'bajo.$key.$F';
        (W['moscas'] as List).remove(key);
        await _vuela(f, to, n: 5, lift: 14);
        _pon(f, 'bajo');
        host.SFX.drop();
      }
      (W['moscas'] as List).removeWhere(
        (m) => (m as String).startsWith('hueco:'),
      );
      _g('abuela')['pose'] = 'idle';
      await wait(TICK * 2);
    },
    // `cabra` {que}: roba (takes a plátano from the bin's end), come (what is on the low crate), mastica, caja (its head in
    // the crate on the low crate) (42: 5; 43; 44: 6, 7)
    'cabra': (o) async {
      final c = W['cabra'] as Map<String, dynamic>, que = o['que'];
      switch (que) {
        case 'roba':
          // OPEN: the sheet names no place for the goat's head at the plantain bin's end (only cabra.cajon, the low
          // crate): it stretches its neck out at its post (mkCabra 'cuello') and a plátano is in its mouth
          c['pose'] = 'cuello';
          await wait(TICK * 3);
          c['boca'] = 'platano';
          host.SFX.blip();
          await wait(TICK * 4);
          c['boca'] = null;
          c['pose'] = 'mastica';
          c['hasta'] = F + 30;
          host.SFX.munch();
          await wait(TICK * 3);
        case 'come':
          await _come();
        case 'caja':
          // its head in the crate pushed onto the low crate: yesterday's is eaten whole, a fresh one half before abuela
          // pulls it back to the ledge
          c['pose'] = 'cajon';
          Map<String, dynamic>? cr;
          for (final x in _items) {
            if (x['vis'] != 0 && x['spot'] == 'bajo' && x['k'] == 'cajon') {
              cr = x;
            }
          }
          await wait(TICK * 2);
          if (cr != null) {
            final m = Map<String, dynamic>.of(
              (cr['v'] as Map).cast<String, dynamic>(),
            );
            host.SFX.munch();
            await wait(TICK * 3);
            if (m['fresco'] == 1) {
              m['lleno'] = .5;
              cr['v'] = m;
              host.SFX.munch();
              await wait(TICK * 2);
              final ab = _g('abuela');
              ab['pose'] = 'mano';
              _pon(cr, cr['desde'] as String? ?? 'cajon_a');
              host.SFX.blip();
              await wait(TICK * 2);
              ab['pose'] = 'idle';
            } else {
              m['lleno'] = 0;
              cr['v'] = m;
              host.SFX.munch();
              await wait(TICK * 3);
              cr['vis'] = 0;
              (W['moscas'] as List).remove(cr['id']);
            }
          }
          c['pose'] = 'mastica';
          c['hasta'] = F + 30;
        default:
          c['pose'] = 'mastica';
          c['hasta'] = F + 24;
          host.SFX.munch();
          await wait(TICK * 6);
      }
    },
    // `tira` {k, ok}: the frog tosses one from a bin: caught in abuela's basket and a coin to don Pepe; or off the rim
    // onto the low crate, where the goat eats it, and a coin all the same (42: 2, 3, 6, 7)
    'tira': (o) async {
      final k = o['k'] as String, ok = _n(o['ok']) == 1;
      final t = _add(
        _cosa('vuela.$F', 'fruta', 'vuelo', v: {'k': UNO[k], 'grande': 0}),
      );
      final from = _binTop(k);
      t
        ..['sx'] = from[0]
        ..['sy'] = from[1];
      host.bounce(5);
      host.SFX.hop();
      final h = _handOf('abuela', 'cesta');
      final to = h == null ? _spotScreen('bajo') : [h.x, h.y - 4];
      // the top of its arc: the sheet's `vuelo`, between the ledge and the basket
      await _vuela(t, to, n: 6, via: _spotScreen('vuelo'));
      if (ok) {
        t['vis'] = 0;
        host.SFX.blip();
        await wait(TICK);
        await _pagaUna('monedas4');
        return;
      }
      // off the rim onto the low crate; the goat eats it; don Pepe holds his hand out and abuela gives him a coin
      host.SFX.bonk();
      await _vuela(t, _spotScreen('bajo'), n: 4, lift: 8);
      _pon(t, 'bajo');
      await _come();
      _tiende(_spotScreen('monedas2')[0]);
      _g('pepe')['pose'] = 'mano';
      await wait(TICK * 3);
      await _pagaUna('monedas2');
    },
    // `guineos` {n}: the ending: abuela buys two guineos, one or none (the coins under the guineos to don Pepe; a guineo
    // for the frog, one for her; they eat); none: she shows her empty hand, the goat chews, the frog looks at the guineos
    // (42: 8)
    'guineos': (o) async {
      final n = _n(o['n']);
      final gp = _p.screen('guineos');
      if (n == 0) {
        final ab = _g('abuela');
        ab['pose'] = 'mano';
        final c = W['cabra'] as Map<String, dynamic>;
        c['pose'] = 'mastica';
        c['hasta'] = F + 30;
        await wait(TICK * 6);
        host.bounce(4);
        await wait(TICK * 4);
        ab['pose'] = 'idle';
        return;
      }
      for (var i = 0; i < n; i++) {
        await _pagaUna('monedas2');
      }
      final quien = n >= 2 ? ['coqui', 'abuela'] : ['coqui'];
      final gs = <Map<String, dynamic>>[];
      for (final q in quien) {
        final gu = _add(_cosa('guineo.$q', 'guineo', 'vuelo'))
          ..['sx'] = gp[0]
          ..['sy'] = gp[1] + 6;
        host.SFX.blip();
        final h = _handOf(q, q == 'abuela' ? 'der' : null);
        if (h != null) await _vuela(gu, [h.x, h.y], n: 4, lift: 4);
        gu
          ..['con'] = q
          ..['mano'] = q == 'abuela' ? 'der' : null
          ..remove('sx')
          ..remove('sy');
        gs.add(gu);
      }
      await wait(TICK * 3);
      host.SFX.munch();
      host.bounce(5);
      await wait(TICK * 5);
      for (final gu in gs) {
        gu['vis'] = 0;
      }
      await wait(TICK * 2);
    },
    // `huele` {k, grande}: abuela takes two of a kind, a big one (fruta_a, `grande`) and a small one (fruta_b), presses
    // and smells each in the same way (43: 3, 5, 6)
    'huele': (o) async {
      final k = o['k'] as String, big = (o['grande'] as String?) ?? 'fruta_a';
      final small = big == 'fruta_a' ? 'fruta_b' : 'fruta_a';
      final ab = _g('abuela');
      for (final (id, side, g) in [(big, 'der', 1), (small, 'izq', 0)]) {
        final f = _add(
          _cosa(id, 'fruta', 'abuela.delante', v: {'k': UNO[k], 'grande': g}),
        );
        f
          ..['con'] = 'abuela'
          ..['mano'] = side;
        host.SFX.blip();
        await wait(TICK * 2);
      }
      // each to her nose, the same way
      for (final id in [big, small]) {
        final f = _item(id)!, side = f['mano'];
        ab['pose'] = 'idle';
        f['mano'] = 'cara';
        await wait(TICK * 3);
        ab['dy'] = 1;
        await wait(TICK * 2);
        ab['dy'] = 0;
        f['mano'] = side;
        await wait(TICK * 2);
      }
    },
    // `pone43` {cual, ok}: the frog lays one in the basket's next hollow; not ok: flies come over it and the one beside it
    // (43: 3, 5, 6)
    'pone43': (o) async {
      final id = o['cual'] as String, ok = _n(o['ok']) == 1;
      final f = _item(id);
      if (f == null) return;
      // each fruit to its own hollow: the limón's, the aguacate's, the piña's (43: "three hollows: for a limón, an
      // aguacate and a piña")
      final i = _HUECO[(f['v'] as Map)['k']] ?? math.min(2, _n(W['hueco']));
      final cs = _item('canasta');
      host.bounce(5);
      host.SFX.hop();
      final dx = CANASTA_HUECOS[i] - 12;
      if (cs != null) {
        final at = _screenOf(cs);
        await _vuela(f, [at[0] + dx, at[1] - 8], n: 5, lift: 10);
      }
      f['id'] = _hueco(i);
      _pon(f, 'canasta', px: dx, py: -8, dd: .05);
      W['hueco'] = i + 1;
      W['ultimo'] = i;
      final en =
          (W['canasta'] as List?) ??
          (W['canasta'] = <dynamic>[null, null, null]);
      while (en.length < 3) {
        en.add(null);
      }
      en[i] = (f['v'] as Map)['k'];
      host.SFX.drop();
      if (!ok) {
        final m = W['moscas'] as List;
        m.add('hueco:$i');
        if (i > 0 && _item(_hueco(i - 1)) != null) m.add('hueco:${i - 1}');
        host.tone(220, 0, .3, 'sawtooth', .02, 260); // the buzz
      }
      await wait(TICK * 3);
    },
    // `canasta43`: the basket from the ledge into abuela's hands, held up, seen from above (43: 7)
    'canasta43': (o) async {
      final cs = _item('canasta');
      if (cs == null) return;
      // what is in its hollows goes with it (drawn in the basket seen from above)
      for (var i = 0; i < 3; i++) {
        _item(_hueco(i))?['vis'] = 0;
      }
      W['canasta'] ??= <dynamic>[null, null, null];
      final h = _handOf('abuela', 'arriba');
      if (h != null) await _vuela(cs, [h.x, h.y], n: 4, lift: 6);
      cs
        ..['con'] = 'abuela'
        ..['mano'] = 'arriba'
        ..remove('sx')
        ..remove('sy');
      host.SFX.blip();
      await wait(TICK * 6);
    },
    // `llama43`: the señora leans out of the shop door and calls (43: 4)
    'llama43': (o) async {
      final s = _g('senora');
      final w = _p.world('senora.puerta');
      s
        ..['x'] = w[0]
        ..['y'] = w[1]
        ..['z'] = w[2]
        ..['spot'] = 'senora.puerta'
        ..['vis'] = 1
        ..['dir'] = 1;
      for (var i = 0; i < 6; i++) {
        s['pose'] = i % 2 == 0 ? 'saluda0' : 'saluda1';
        await wait(TICK);
      }
      s['pose'] = 'idle';
    },
    // `sale` {quien, a}: don Pepe into the shop (`tienda`: he waits in its doorway, pepe.puerta, while the señora is
    // served inside), or to his cart (`camion`, `carro`) (43: 4; 44: 5)
    'sale': (o) async {
      final quien = o['quien'] as String, a = o['a'];
      final p = _g(quien);
      p['pose'] = 'idle';
      W['dedo'] = null;
      if (a == 'tienda') {
        // the señora goes back in first (she and he cannot stand in one doorway)
        _g('senora')['vis'] = 0;
        // OPEN: "Don Pepe goes in": he stops in the doorway (pepe.puerta) and says his line there; the sheet names no
        // place inside the shop, and a speaker out of the picture loses his bubble
        await _camino(quien, const ['pepe.puerta']);
        p['dir'] = 1;
        return;
      }
      // OPEN: "he wheels it off round the corner": the cart is the set's (state carro), it cannot move, and the sheet
      // names no place round the corner: he goes to its handles (pepe.carro) and stands there; the cart is gone when he
      // comes back (`vuelve`)
      W['fuera'] = 1;
      await _camino(quien, const ['pepe.pesa', 'pepe.carro']);
      p['dir'] = -1;
      p['pose'] = 'mano';
    },
    // `vuelve` {quien, a}: back from the shop to the stand, or back without the cart (43: 7; 44: 8)
    'vuelve': (o) async {
      final quien = o['quien'] as String, a = o['a'];
      final p = _g(quien);
      p['pose'] = 'idle';
      if (a == 'tienda') {
        await _camino(quien, const ['pepe.detras']);
        p['dir'] = 1;
        return;
      }
      W['camion'] = 0;
      W['carro'] = 0;
      W['fuera'] = 0;
      await wait(TICK * 2);
      await _camino(quien, const ['pepe.pesa']);
      p['dir'] = 1;
    },
    // `limon44`: he lifts a small fresh crate of limones off the cart, cuts one and gives the frog a slice; the frog's
    // face puckers (44: 2)
    'limon44': (o) async {
      final p = _g('pepe');
      // OPEN: the small crate of limones has no place on the ledge in the sheet: he takes it from the cart (pepe.carro)
      // and holds it at his hand by the scale (pepe.pesa)
      if (_carro(W)) await _camino('pepe', const ['pepe.carro']);
      p['pose'] = 'mano';
      _add(
        _cosa(
          'cajita',
          'cajon',
          'pepe.carro',
          v: {'k': 'limones', 'fresco': 1, 'lleno': 1, 'pequeno': 1},
        ),
      )['con'] = 'pepe';
      host.SFX.blip();
      await _camino('pepe', const ['pepe.pesa']);
      // his hand out towards the frog, the small crate in it
      final q = W['cq'] as Map<String, dynamic>, fb = host.frogBox(q);
      _tiende(fb.x + fb.w / 2);
      p['pose'] = 'mano';
      host.tone(900, 0, .08, 'square', .03);
      await wait(TICK * 3);
      final s = _add(_cosa('tajada', 'tajada_limon', 'pepe.pesa'))
        ..['con'] = 'pepe';
      await wait(TICK * 2);
      final h = _handOf('coqui', null);
      if (h != null) await _vuela(s, [h.x - 4, h.y - 6], n: 6, lift: 12);
      s['vis'] = 0;
      host.SFX.munch();
      // OPEN: the frog is the game's own sprite (no puckered face): he shudders, two quick bounces
      host.bounce(4);
      await wait(TICK * 2);
      host.bounce(4);
      await wait(TICK * 3);
    },
    // `pesa` {k, n}: things onto the scale's pan (`plato`, its drawn depth); the needle to half or full; they are bagged
    // into abuela's basket before the next act (44: 3, 6, 7)
    'pesa': (o) async {
      final k = o['k'] as String, n = _d(o['n']);
      // from don Pepe's small crate (the limones), or from the fresh crate of the ledge
      final src = _item('cajita') ?? _cajonDe(k);
      final heap = _add(_cosa('plato', 'plato', 'plato', v: {'k': k, 'n': n}));
      if (src != null) {
        final a = _screenOf(src);
        heap
          ..['sx'] = a[0]
          ..['sy'] = a[1] - 4;
        if (src['id'] != 'cajita') {
          final m = Map<String, dynamic>.of(
            (src['v'] as Map).cast<String, dynamic>(),
          )..['lleno'] = 0;
          src['v'] = m;
        }
        await _vuela(heap, _spotScreen('plato'), n: 5, lift: 10);
        src['vis'] = 0;
      }
      _pon(heap, 'plato');
      host.SFX.drop();
      // the needle swings to its mark
      for (final v in [n * .5, n]) {
        W['aguja'] = v >= 1
            ? 1.0
            : v > 0
            ? .5
            : 0.0;
        await wait(TICK * 2);
      }
      W['aguja'] = n >= 1 ? 1.0 : .5;
      host.SFX.blip();
      await wait(TICK * 3);
    },
    // `marca44` {que}: his finger on the needle at the half mark (`medio`), on the full mark (`libra`) (44: 3)
    'marca44': (o) async {
      final p = _g('pepe');
      final ag = _p.at('aguja');
      _tiende(ag.sx);
      p['pose'] = 'mano';
      // OPEN: the finger is a small hand laid on the mark (the kit's marks on the dial); don Pepe at pepe.pesa does not
      // reach the dial (the sheet: "his shown pixels lie over none of the dial")
      W['dedo'] = o['que'];
      host.SFX.blip();
      await wait(TICK * 8);
    },
    // `cajones` {k, lado}: the fresh crate and yesterday's of one thing side by side on the ledge, the fresh one at
    // cajon_<lado> (44: 1, 6, 7)
    'cajones': (o) async {
      final k = o['k'] as String, lado = (o['lado'] as String?) ?? 'a';
      final otro = lado == 'a' ? 'b' : 'a';
      final m = W['moscas'] as List;
      for (final l in const ['a', 'b']) {
        _cajon(l)?['vis'] = 0;
        m.remove('cajon_$l');
      }
      final p = _g('pepe');
      p['pose'] = 'mano';
      _tiende(_spotScreen('cajon_a')[0]);
      _add(
        _cosa(
          'cajon_$lado',
          'cajon',
          'cajon_$lado',
          v: {'k': k, 'fresco': 1, 'lleno': 1},
        ),
      )['desde'] = 'cajon_$lado';
      host.SFX.drop();
      await wait(TICK * 2);
      _add(
        _cosa(
          'cajon_$otro',
          'cajon',
          'cajon_$otro',
          v: {'k': k, 'fresco': 0, 'lleno': 1},
        ),
      )['desde'] = 'cajon_$otro';
      m.add('cajon_$otro');
      host.SFX.drop();
      await wait(TICK * 2);
      p['pose'] = 'idle';
      // story 44's start: from the cart to his place by the scale
      if (p['spot'] == 'pepe.carro' && W['fuera'] != 1) {
        await _camino('pepe', const ['pepe.pesa']);
        p['dir'] = 1;
      }
    },
    // `ayer44` {k}: yesterday's crate of a thing twinkles; its fly circles (44: 1)
    'ayer44': (o) async {
      final c = _cajonDe(o['k'] as String, fresco: false);
      if (c == null) return;
      W['twinkle'] = c['id'];
      final m = W['moscas'] as List;
      if (!m.contains(c['id'])) m.add(c['id']);
      host.tone(220, 0, .3, 'sawtooth', .02, 260);
      await wait(TICK * 8);
      W['twinkle'] = null;
    },
    // `empuja44` {cual}: the frog pushes a crate off the ledge onto the low crate (44: 6, 7; the goat's `caja` follows)
    'empuja44': (o) async {
      final c = _item(o['cual'] as String);
      if (c == null) return;
      host.bounce(6);
      host.SFX.hop();
      await _vuela(c, _spotScreen('bajo'), n: 6, lift: 6);
      _pon(c, 'bajo');
      host.SFX.drop();
      await wait(TICK);
    },
    // `vuelca44` {k}: yesterday's crate, dragged towards the scale, knocks the fresh one over: half of it onto the low
    // crate (44: 6, 7; the goat's `come` follows)
    'vuelca44': (o) async {
      final k = o['k'] as String;
      final ayer = _cajonDe(k, fresco: false), fresco = _cajonDe(k);
      if (ayer == null || fresco == null) return;
      host.bounce(6);
      // dragged towards the fresh one, a few pixels at a tick
      final dir = _screenOf(fresco)[0] > _screenOf(ayer)[0] ? 1 : -1;
      for (var i = 1; i <= 3; i++) {
        ayer['px'] = dir * i * 2;
        await wait(TICK);
      }
      final m = Map<String, dynamic>.of(
        (fresco['v'] as Map).cast<String, dynamic>(),
      )..['volcado'] = 1;
      fresco['v'] = m;
      host.SFX.bonk();
      // half of it rolls onto the low crate
      final h = _add(
        _cosa('derrame.$F', 'plato', 'bajo', v: {'k': k, 'n': .5}),
      );
      final a = _screenOf(fresco);
      h
        ..['sx'] = a[0]
        ..['sy'] = a[1];
      await _vuela(h, _spotScreen('bajo'), n: 6, lift: 6);
      _pon(h, 'bajo');
      host.SFX.drop();
      ayer['px'] = 0;
      fresco['v'] = Map<String, dynamic>.of(m)
        ..['volcado'] = 0
        ..['lleno'] = .5;
      await wait(TICK * 2);
    },
    // `bolsas44`: the scale shows each bag in turn (the tomatoes', the onions') (44: 8)
    'bolsas44': (o) async {
      final p = _g('pepe');
      _tiende(_p.at('plato').sx);
      p['pose'] = 'mano';
      for (final b in (W['bolsas'] as List).cast<Map>()) {
        if (b['k'] == 'limones') continue;
        final bag = _add(_cosa('bolsa.pesa', 'bolsa', 'plato'));
        _pon(bag, 'plato');
        host.SFX.drop();
        W['aguja'] = _d(b['n']) >= 1 ? 1.0 : .5;
        await wait(TICK * 8);
        bag['vis'] = 0;
        W['aguja'] = 0.0;
        await wait(TICK * 2);
      }
      p['pose'] = 'idle';
    },
    // `abuela` {a, que}: abuela goes to a spot (`delante`, `junto_cabra`); que: `lista` she holds her list up, `guarda`
    // the list into her pocket, `monedero` she looks into her purse, `monedas` she looks at the coins left, then at the
    // frog (42: 5, 8; 44: 4, 5)
    'abuela': (o) async {
      final ab = _g('abuela');
      final a = o['a'];
      if (a is String) {
        await _anda('abuela', 'abuela.$a');
        ab['dir'] = 1;
      }
      switch (o['que']) {
        case 'lista':
          final l = _add(_cosa('lista.mano', 'lista', 'abuela.delante'))
            ..['con'] = 'abuela'
            ..['mano'] = 'alto';
          (W['lista'] as Map<String, dynamic>)['vis'] = 1;
          host.SFX.blip();
          await wait(TICK * 8);
          l['vis'] = 0;
        case 'guarda':
          final l = _add(_cosa('lista.mano', 'lista', 'abuela.delante'))
            ..['con'] = 'abuela'
            ..['mano'] = 'izq';
          await wait(TICK * 4);
          l['vis'] = 0;
          (W['lista'] as Map<String, dynamic>)['vis'] = 0;
          host.SFX.blip();
          await wait(TICK * 2);
        case 'monedero':
          final m = _add(_cosa('monedero', 'monedero', 'abuela.delante'))
            ..['con'] = 'abuela'
            ..['mano'] = 'izq';
          ab['dy'] = 1;
          await wait(TICK * 8);
          ab['dy'] = 0;
          m['vis'] = 0;
        case 'monedas':
          _mira('abuela', _spotScreen('monedas2')[0]);
          await wait(TICK * 5);
          final q = W['cq'] as Map<String, dynamic>, fb = host.frogBox(q);
          _mira('abuela', fb.x + fb.w / 2);
          await wait(TICK * 5);
      }
    },
    // `aparta42`: don Pepe pulls the bins of potatoes and plantains back from the goat (42: 5)
    'aparta42': (o) async {
      // OPEN: the bins are the set's (baked) and cannot move: he lays his hand over the plantain bin, towards the goat,
      // and the goat stands back from it
      final p = _g('pepe');
      _tiende(_binTop('platanos')[0] + 20);
      p['pose'] = 'mano';
      host.SFX.blip();
      await wait(TICK * 4);
      final c = W['cabra'] as Map<String, dynamic>;
      c['pose'] = 'de_pie';
      c['hasta'] = 0;
      await wait(TICK * 3);
      p['pose'] = 'idle';
      p['dir'] = 1;
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
}
