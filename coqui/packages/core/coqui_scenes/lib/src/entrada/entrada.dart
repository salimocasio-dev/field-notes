// La entrada (place 8, La fonda, scene 1: `entrada`; stories 84 to 86): a NEW scene, written from its script's
// "Needs" list (historia/notas/guiones/entrada.md) on its set (entrada_set.dart) and its sheet (entrada-sheet.json,
// read by SceneSheet). There is no old scene file: every act is this scene's (entrada_acts.dart), each doing on
// screen what the Needs list says, every place read directly from the sheet (spots, set thing boxes, table cloths,
// depth rule, shadows). Where the sheet names no place or an act is unstated in the script, the code does the
// plainest thing that keeps the story playing and marks it `OPEN:`.
//
// The drawing (the sheet's `front`): every sprite stands with its feet's bottom edge on its spot's row and its
// middle on its column (rules.anchor); a seated person hangs by the lap (abuelaS: 17, 36; adult: 24, 41; child: 24,
// 33); every sprite pixel is hidden by every set pixel (`engine.zb` / `baked.zb`) nearer than its upright plane plus
// `front.bias`. Between two sprites the nearer pixel wins (tie within 0.001 goes to the later layer; the frog is
// drawn last among world sprites).
// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/src/colmado/colmado_cast.dart' show inkBottom;
import 'package:coqui_scenes/src/entrada/entrada_places.dart';
import 'package:coqui_scenes/src/entrada/entrada_set.dart';
import 'package:coqui_scenes/src/entrada/entrada_sprites.dart';
import 'package:coqui_scenes/src/scene_set.dart';
import 'package:coqui_scenes/src/sheet_cache.dart';

part 'entrada_acts.dart';
part 'entrada_layers.dart';

/// The scene "La entrada", made from its sheet (read first: `loadScene`).
Scene createEntrada() => Entrada(sceneSheetOf('entrada'));

int _round(num v) => (v + 0.5).floor();

int _n(Object? v) {
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? 0;
  return 0;
}

/// One sprite of the sprite layer, placed: its picture, its top left on the 240 × 216 picture, the screen row of its
/// anchor and the depth there (front.plane), who or what it is, and optional owner (`held`) or overlay flag.
class EntradaItem {
  EntradaItem(
    this.s,
    this.left,
    this.top,
    this.sy,
    this.d, {
    this.tag,
    this.held,
    this.overlay = false,
  });

  final Sprite s;
  final int left, top;
  final num sy;
  final double d;
  final String? tag;
  final String? held;

  /// Screen-space overlay drawn over the set and world sprites (e.g. celebration heart, music notes).
  final bool overlay;
}

/// Every touchable person in La entrada (entrada.md "Needs").
const List<String> ENTRADA_TOUCH_PEOPLE = [
  'mesera',
  'mesero',
  'abuela',
  'abuelo',
  'luis',
  'carmen',
  'senor',
  'senora',
  'hombre',
  'mujer',
  'joven',
];

/// Every speaker key in La entrada (entrada.md "Needs").
const List<String> ENTRADA_SPEAKERS = [...ENTRADA_TOUCH_PEOPLE, 'coqui'];

class Entrada extends Escena implements SetScene, SetOverSprites {
  Entrada(this.ss)
    : sheet = identical(ss, _lastSs)
          ? _lastSheet!
          : (_lastSheet = ss.legacy()) {
    _p = identical(ss, _lastSs)
        ? _lastPlaces!
        : (_lastPlaces = EntradaPlaces(ss));
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
  static EntradaPlaces? _lastPlaces;

  /// The new scene's sheet (SceneSheet).
  final SceneSheet ss;

  @override
  final Sheet sheet;

  late final EntradaPlaces _p;

  /// The scene's places, from its sheet.
  EntradaPlaces get places => _p;

  @override
  String get id => 'entrada';

  @override
  late final Map<String, List<num>> CAM;

  late final Map<String, List<num>> LUGAR;

  @override
  Map<String, List<num>> get lugar => LUGAR;

  @override
  late final List<Thing> cosas;

  @override
  PpEngine newEngine({bool still = false}) => entradaEngine(still: still);

  @override
  PpEngine get projection => _p.e;

  List<num> _frogAt(EntradaAt a) => [_round(a.sx) - 16, _round(a.sy) - 25, 1];

  Map<String, dynamic> get W => host.W;
  int get F => host.F;
  int get TICK => host.TICK;
  Future<void> wait(num ms) => host.wait(ms);

  /* ---------- state ---------- */

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
      'pose': 'idle',
      'sent': sent,
      'dx': 0,
      'dy': 0,
    };
  }

  void _placePerson(
    Map<String, dynamic> p,
    String spot, {
    int vis = 1,
    int sent = 0,
  }) {
    final w = _p.world(spot);
    p['x'] = w[0];
    p['y'] = w[1];
    p['z'] = w[2];
    p['spot'] = spot;
    p['vis'] = vis;
    p['sent'] = sent;
    p['dx'] = 0;
    p['dy'] = 0;
  }

  static String _companionOf(String who) => switch (who) {
    'senor' => 'senora',
    'senora' => 'senor',
    'hombre' => 'mujer',
    'mujer' => 'hombre',
    'joven' => 'amigo',
    _ => 'senora',
  };

  @override
  Map<String, dynamic> fresh(Map<String, dynamic> story) {
    final acts = _actsOf([story['beats'], story['final']]);
    bool has(String a) => acts.any((o) => o['act'] == a);
    final set = _firstSet(story['beats']);
    final is86 =
        has('velas') ||
        has('menu86') ||
        has('bandeja86') ||
        has('da86') ||
        has('final86');
    final is85 =
        !is86 &&
        (has('dulces') ||
            has('manteles') ||
            has('corbata85') ||
            has('sienta85') ||
            has('final85'));
    final storyNum = is86 ? 86 : (is85 ? 85 : 84);
    final hora =
        (set['hora'] as String?) ?? (is84(storyNum) ? 'ocaso' : 'noche');
    final cuerda = (set['cuerda'] as String?) ?? 'puesta';
    final startSpot = is86
        ? 'mesa2_coqui'
        : (is85 ? 'taburete_coqui' : 'felpudo');
    final startAt = _p.at(startSpot);
    final q = _frogAt(startAt);

    final gente = <String, dynamic>{};
    if (storyNum == 84) {
      gente['abuela'] = _person('puerta1');
      gente['abuelo'] = _person('puerta2');
      gente['luis'] = _person('puerta3');
      gente['carmen'] = _person('puerta4');
      gente['senor'] = _person('cola1');
      gente['senora'] = _person('cola2');
      gente['hombre'] = _person('cola1', vis: 0);
      gente['mujer'] = _person('cola2', vis: 0);
      gente['mesera'] = _person('atril');
      gente['mesero'] = _person('paso1', vis: 0);
    } else if (storyNum == 85) {
      gente['mesero'] = _person('taburete', sent: 1);
      gente['senora'] = _person('ante_cuerda1');
      gente['senor'] = _person('ante_cuerda2');
      gente['vecino'] = _person('vellonera1');
      gente['vecina'] = _person('vellonera2');
      gente['hombre'] = _person('banco1', vis: 0, sent: 1);
      gente['mujer'] = _person('banco2', vis: 0, sent: 1);
      gente['joven'] = _person('ante_cuerda1', vis: 0);
      gente['amigo'] = _person('ante_cuerda2', vis: 0);
    } else {
      gente['abuela'] = _person('mesa2_a', sent: 1);
      gente['abuelo'] = _person('mesa2_b', sent: 1);
      gente['luis'] = _person('mesa2_c', sent: 1);
      gente['carmen'] = _person('mesa2_d', sent: 1);
      gente['mesera'] = _person('junto_mesa');
      gente['mesero'] = _person('bandeja');
    }

    return <String, dynamic>{
      'story': storyNum,
      'hora': hora,
      'cuerda': cuerda,
      'gente': gente,
      // Story 84 state
      'mesas84': storyNum == 84 ? 3 : 0,
      'floresVis': storyNum == 84 ? 1 : 0,
      'meseroCarry': null, // 'platos' | 'bandeja' | null
      'abueloSombrero': 0,
      'final84': 0,
      // Story 85 state
      'tabureteVis': storyNum == 85 ? 1 : 0,
      'dulces': storyNum == 85 ? 3 : -1,
      'mantel2': storyNum == 85 ? 'rojo' : null,
      'mantel3': storyNum == 85 ? 'azul' : null,
      'meseroCorbata': 1,
      'coquiCorbata': 0,
      'musicaFx': 0,
      'final85': 0,
      // Story 86 state
      'velas': storyNum == 86 ? 3 : 0,
      'menuVis': storyNum == 86 ? 1 : 0,
      'menuOpen': 0,
      'menuCloseToFlame': 0,
      'trayVis': 0,
      'trayQue': 'agua', // 'agua' | 'pan'
      'trayIzq': 'con', // 'con' | 'sin'
      'cosaAVis': 0,
      'cosaBVis': 0,
      'cafesVis': 0,
      'vasitoVis': 0,
      'paneraVis': 0,
      'splashFx': 0,
      'velaSmoke': 0,
      'final86': 0,
      // HUD card
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
        'z': startAt.z,
        'spot': startSpot,
      },
    };
  }

  static bool is84(int n) => n == 84;

  /* ---------- the set ---------- */

  @override
  String setKey(Map<String, dynamic> W) {
    final h = W['hora'];
    final hora =
        h is String && const ['ocaso', 'noche', 'tarde_noche'].contains(h)
        ? h
        : 'ocaso';
    final c = W['cuerda'];
    final cuerda = c is String && const ['puesta', 'abierta'].contains(c)
        ? c
        : 'puesta';
    return '$hora-$cuerda';
  }

  @override
  void buildSet(PpEngine e, PpBuild b, Map<String, dynamic> W) =>
      buildSetFor(e, b, setKey(W));

  final Map<PpEngine, EntradaSet> _sets = {};

  @override
  void buildSetFor(PpEngine e, PpBuild b, String key) =>
      (_sets[e] ??= EntradaSet(e, b)).buildSet(EntradaState.fromKey(key));

  @override
  bool get frogShadow => false;

  /* ---------- where everybody is ---------- */

  Map<String, dynamic> get _gente => W['gente'] as Map<String, dynamic>;

  EntradaAt _atOf(Map<String, dynamic> o) =>
      _p.atWorld(o['x'] as num, o['y'] as num, o['z'] as num);

  EntradaAt _frogPoint(Map<String, dynamic> q) {
    final spot = q['spot'];
    if (spot is String && _p.hasWorld(spot)) {
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

  /* ---------- sprite caches & layer entry points ---------- */

  static final Map<String, Sprite> _sprites = {};
  static Sprite _spr(String key, Sprite Function() make) =>
      _sprites[key] ??= make();

  static final Map<String, Sprite> _frogSprites = {};

  String? _talker() {
    try {
      return host.TALK;
    } catch (_) {
      return null;
    }
  }

  /// Every sprite of the frame [w] as it is placed, except the frog. The rules' tests read it; [draw] draws it.
  List<EntradaItem> items(Map<String, dynamic> w, int a) => _entradaItems(w, a);

  /// [items] plus the frog (and frog's bow tie in story 85), for `draw` and for `EntradaRules`.
  List<EntradaItem> placed(Map<String, dynamic> w, int a) =>
      _entradaPlaced(w, a);

  /* ---------- SetOverSprites & draw ---------- */

  Float32List? _setZ;
  bool _framed = false;
  Uint32List? _layer;
  Float32List? _layerZ;

  @override
  void setFramed(PpEngine engine, BakedSet baked, Map<String, dynamic> W) {
    _framed = true;
    _setZ = engine.zb;
  }

  static final double _t30 = math.tan(math.pi / 6);

  void _put(
    EntradaItem it,
    int w0,
    int h0,
    Float32List? setZ,
    double bias,
    double S,
  ) {
    final layer = _layer!, lz = _layerZ!, sp = it.s;
    final sw = sp.w, sh = sp.h;
    final spx = sp.px;
    for (var py = 0; py < sh; py++) {
      final Y = it.top + py;
      if (Y < 0 || Y >= h0) continue;
      final plane = it.overlay ? it.d : it.d + (it.sy - (Y + .5)) * _t30 / S;
      final row = Y * w0;
      final srow = py * sw;
      for (var px = 0; px < sw; px++) {
        final c = spx[srow + px];
        if (c >>> 24 == 0) continue;
        final X = it.left + px;
        if (X < 0 || X >= w0) continue;
        final i = row + X;
        if (!it.overlay && setZ != null && setZ[i] > plane + bias) continue;
        if (lz[i] > plane + .001) continue;
        lz[i] = plane;
        layer[i] = c;
      }
    }
  }

  @override
  void draw(Ctx c, Map<String, dynamic> w, int a) {
    if (!_framed) return;
    const w0 = 240, h0 = 216;
    final layer = _layer ??= Uint32List(w0 * h0);
    final lz = _layerZ ??= Float32List(w0 * h0);
    final setZ = _setZ, bias = _p.bias, S = _p.e.S;
    final all = placed(w, a);
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

  /* ---------- shadows (sheet: shadows) ---------- */

  @override
  List<ShadowCast> shadows(Map<String, dynamic> W) {
    final out = <ShadowCast>[];
    final gente = (W['gente'] as Map<String, dynamic>?) ?? const {};
    for (final en in gente.entries) {
      final p = en.value as Map<String, dynamic>;
      if (p['vis'] == 0) continue;
      final spot = p['spot'] as String?;
      final z = (p['z'] as num?)?.toDouble() ?? 0.0;
      if (z != 0 || (spot != null && _p.noShadow(spot))) continue;
      final r = _p.radius(en.key) ?? _p.radius('senor');
      if (r == null) continue;
      out.add((
        x: (p['x'] as num).toDouble(),
        y: (p['y'] as num).toDouble(),
        z: 0.0,
        r: r,
      ));
    }
    final q = W['cq'] as Map<String, dynamic>?;
    if (q != null && jsTruthy(q['vis'])) {
      final spot = q['spot'] as String?;
      final z = (q['z'] as num?)?.toDouble() ?? 0.0;
      if (z == 0 && (spot == null || !_p.noShadow(spot))) {
        final fp = _frogPoint(q);
        final r = _p.radius('coqui');
        if (r != null) out.add((x: fp.x, y: fp.y, z: 0.0, r: r));
      }
    }
    return out;
  }

  /* ---------- talk bubbles ---------- */

  @override
  List<num>? talkAt(String who, Map<String, dynamic> W) {
    if (who == 'coqui') {
      final q = W['cq'] as Map<String, dynamic>?;
      if (q == null) return null;
      final b = host.frogBox(q);
      return [b.x + b.w / 2, b.y - 4];
    }
    final gente = (W['gente'] as Map<String, dynamic>?) ?? const {};
    final p = gente[who] as Map<String, dynamic>?;
    if (p == null || p['vis'] == 0) return null;
    final at = _atOf(p);
    final sent = _n(p['sent']) == 1;
    final isChild = who == 'luis' || who == 'carmen';
    final dy = sent ? (isChild ? 34 : 42) : (isChild ? 42 : 52);
    return [_round(at.sx), _round(at.sy) - dy];
  }

  /* ---------- touch things & hit testing ---------- */

  static List<int>? _itemBox(
    List<EntradaItem> list,
    bool Function(EntradaItem) test,
  ) {
    var x0 = 240, y0 = 216, x1 = -1, y1 = -1;
    for (final it in list) {
      if (!test(it)) continue;
      final sp = it.s;
      for (var py = 0; py < sp.h; py++) {
        for (var px = 0; px < sp.w; px++) {
          if (sp.px[py * sp.w + px] >>> 24 == 0) continue;
          final X = it.left + px, Y = it.top + py;
          if (X < 0 || X >= 240 || Y < 0 || Y >= 216) continue;
          if (X < x0) x0 = X;
          if (X > x1) x1 = X;
          if (Y < y0) y0 = Y;
          if (Y > y1) y1 = Y;
        }
      }
    }
    if (x1 < 0) return null;
    return [x0, y0, x1 - x0 + 1, y1 - y0 + 1];
  }

  List<num>? _spriteBox(Map<String, dynamic> w, String tag) =>
      _itemBox(items(w, 0), (it) => it.tag == tag);

  List<num>? _velasBox(Map<String, dynamic> w) => _itemBox(
    items(w, 0),
    (it) => it.tag != null && it.tag!.startsWith('cosa:vela'),
  );

  List<Thing> _things() => [
    // Foreground interactive props first
    Thing(
      id: 'cosa_a',
      si: (w) => _n(w['trayVis']) == 1 && _n(w['cosaAVis']) == 1,
      box: (w) => _spriteBox(w, 'cosa:cosa_a') ?? _p.spotBox('cosa_a'),
    ),
    Thing(
      id: 'cosa_b',
      si: (w) => _n(w['trayVis']) == 1 && _n(w['cosaBVis']) == 1,
      box: (w) => _spriteBox(w, 'cosa:cosa_b') ?? _p.spotBox('cosa_b'),
    ),
    Thing(
      id: 'menu',
      si: (w) => _n(w['menuVis']) == 1,
      box: (w) => _spriteBox(w, 'cosa:menu') ?? _p.spotBox('menu'),
    ),
    Thing(
      id: 'velas',
      si: (w) => _n(w['story']) == 86,
      box: (w) => _velasBox(w) ?? _p.spotBox('velas'),
    ),
    Thing(
      id: 'dulces',
      si: (w) => _n(w['story']) == 85 && _n(w['dulces']) >= 0,
      box: (w) => _spriteBox(w, 'cosa:dulces') ?? _p.spotBox('dulces'),
    ),
    // People
    for (final who in ENTRADA_TOUCH_PEOPLE)
      Thing(
        id: who,
        si: (w) => ((w['gente'] as Map?)?[who] as Map?)?['vis'] == 1,
        box: (w) => _spriteBox(w, 'persona:$who'),
      ),
    // Set things
    Thing(id: 'banco', box: (w) => _p.box('banco')),
    Thing(id: 'mesa1', box: (w) => _p.box('mesa1')),
    Thing(id: 'mesa2', box: (w) => _p.box('mesa2')),
    Thing(id: 'mesa3', box: (w) => _p.box('mesa3')),
    Thing(id: 'puerta', box: (w) => _p.box('puerta')),
    Thing(id: 'vellonera', box: (w) => _p.box('vellonera')),
  ];

  @override
  String? hit(num x, num y, Map<String, dynamic> w) {
    // Check frog first when visible so nothing with a wider box steals a frog tap.
    final q = w['cq'] as Map<String, dynamic>?;
    if (q != null && jsTruthy(q['vis'])) {
      final fb = host.frogBox(q);
      if (x >= fb.x && x < fb.x + fb.w && y >= fb.y && y < fb.y + fb.h) {
        return 'coqui';
      }
    }
    for (final t in cosas) {
      if (t.si != null && !t.si!(w)) continue;
      final b = box(t.id, w);
      if (b == null) continue;
      if (x >= b[0] && x < b[0] + b[2] && y >= b[1] && y < b[1] + b[3]) {
        return t.id;
      }
    }
    return null;
  }

  final List<Future<void>> _loose = [];

  @override
  List<num> remap(List<num> xy) => xy;

  @override
  Future<void> stake(int lost, int max, String en) async {}

  @override
  Map<String, Act> get ownActs => _entradaOwnActs();
}
