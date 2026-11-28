// El pedido (place 8, La fonda, scene 2: `pedido`; stories 87 to 89): a NEW scene, written from its script's
// "Needs" list (historia/notas/guiones/pedido.md) on its set (pedido_set.dart) and its sheet (pedido-sheet.json,
// read by SceneSheet). There is no old scene file: every act is in pedido_acts.dart, each doing on screen what the
// Needs list says, every place from the sheet (spots, set thing boxes, depth rule, shadows). Where the sheet names
// no place or an act is unstated in the script, the code does the plainest thing that keeps the story playing and
// marks it `OPEN:`.
//
// The drawing (the sheet's `front`): every sprite stands with its feet's bottom edge on its spot's row and its
// middle on its column (rules.anchor); seated people hang by their lap (`abuela`: 17, 36; adults: 24, 41; children:
// 24, 33); board pictures are centred on their panels with `dd: 0.05`; hanging plantains anchor at top-middle (7, 0);
// every sprite pixel is hidden by every baked set pixel (`baked.zb`) nearer than its upright plane plus `front.bias`
// (0.3). Between two sprites the nearer pixel wins (tie within 0.001 goes to the later layer).
// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/src/colmado/colmado_cast.dart' show inkBottom;
import 'package:coqui_scenes/src/pedido/pedido_places.dart';
import 'package:coqui_scenes/src/pedido/pedido_set.dart';
import 'package:coqui_scenes/src/pedido/pedido_sprites.dart';
import 'package:coqui_scenes/src/scene_set.dart';
import 'package:coqui_scenes/src/sheet_cache.dart';

part 'pedido_acts.dart';

/// The scene "El pedido", made from its sheet (read first: `loadScene`).
Scene createPedido() => Pedido(sceneSheetOf('pedido'));

int _round(num v) => (v + 0.5).floor();

int _n(Object? v) {
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? 0;
  return 0;
}

/// One sprite of the sprite layer, placed: its picture, its top left on the 240 × 216 picture, the screen row of its
/// anchor and the depth there (front.plane), and who or what it is.
class PedidoItem {
  PedidoItem(
    this.s,
    this.left,
    this.top,
    this.sy,
    this.d, {
    this.tag,
    this.overlay = false,
  });

  final Sprite s;
  final int left, top;
  final num sy;
  final double d;
  final String? tag;
  final bool overlay;
}

/// Every person El pedido knows, by speaker key (pedido.md, "Needs").
const List<String> PEDIDO_PERSONAS = [
  'abuela',
  'abuelo',
  'luis',
  'carmen',
  'cocinero',
  'mesera',
  'mesero',
  'senor',
  'senora',
  'joven',
  'mujer',
];

/// Every speaker key supported by [Pedido.talkAt] (12 speakers).
const List<String> PEDIDO_SPEAKERS = [...PEDIDO_PERSONAS, 'coqui'];

class Pedido extends Escena implements SetScene, SetOverSprites {
  Pedido(this.ss)
    : sheet = identical(ss, _lastSs)
          ? _lastSheet!
          : (_lastSheet = ss.legacy()) {
    _p = identical(ss, _lastSs)
        ? _lastPlaces!
        : (_lastPlaces = PedidoPlaces(ss));
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
  static PedidoPlaces? _lastPlaces;

  /// The new scene's sheet (SceneSheet).
  final SceneSheet ss;

  @override
  final Sheet sheet;

  late final PedidoPlaces _p;

  /// The scene's places, from its sheet.
  PedidoPlaces get places => _p;

  @override
  String get id => 'pedido';

  @override
  late final Map<String, List<num>> CAM;

  late final Map<String, List<num>> LUGAR;

  @override
  Map<String, List<num>> get lugar => LUGAR;

  @override
  late final List<Thing> cosas;

  @override
  PpEngine newEngine({bool still = false}) => pedidoEngine(still: still);

  @override
  PpEngine get projection => _p.e;

  List<num> _frogAt(PedidoAt a) => [_round(a.sx) - 16, _round(a.sy) - 25, 1];

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
      'al': 1.0,
      'dx': 0,
      'dy': 0,
    };
  }

  void _placePerson(Map<String, dynamic> p, String spot, {int? sent}) {
    final w = _p.world(spot);
    p['x'] = w[0];
    p['y'] = w[1];
    p['z'] = w[2];
    p['spot'] = spot;
    p['vis'] = 1;
    p['dx'] = 0;
    p['dy'] = 0;
    if (sent != null) p['sent'] = sent;
  }

  @override
  Map<String, dynamic> fresh(Map<String, dynamic> story) {
    final acts = _actsOf([story['beats'], story['final']]);
    bool has(String a) => acts.any((o) => o['act'] == a);
    final is89 =
        has('bandeja89') ||
        has('alza89') ||
        has('da89') ||
        has('sorbo89') ||
        has('final89');
    final is88 =
        !is89 &&
        (has('frie88') ||
            has('tablero88') ||
            has('pide88') ||
            has('platanos') ||
            has('final88'));
    final storyNum = is89 ? 89 : (is88 ? 88 : 87);
    final startSpot = is88 ? 'repisa_coqui' : 'mesa_coqui';
    final q = _frogAt(_p.at(startSpot));

    final gente = <String, dynamic>{
      'abuela': _person(is89 ? 'silla2' : 'silla1', sent: 1),
      'abuelo': _person(is89 ? 'silla1' : 'silla2', sent: 1),
      'luis': _person('silla3', sent: 1),
      'carmen': _person('silla4', sent: 1),
      'cocinero': _person('hueco'),
      'mesera': _person('junto_mesa', vis: 0),
      'mesero': _person('junto_mesa', vis: 0),
      'senor': _person('otra_mesa1', vis: 0, sent: 1),
      'senora': _person('otra_mesa2', vis: 0, sent: 1),
      'joven': _person('otra_mesa1', vis: 0, sent: 1),
      'mujer': _person('otra_mesa2', vis: 0, sent: 1),
    };

    return <String, dynamic>{
      'story': storyNum,
      'hora': 'noche',
      'tablero': is88 ? 'platos' : 'comida',
      'gente': gente,
      // Board pictures: food board (stories 87 & 88) and drinks board (story 89)
      'cuadros': is88
          ? <String>[
              'carne_tostones',
              'carne_mofongo',
              'pescado_tostones',
              'pescado_mofongo',
            ]
          : is89
          ? <String>[]
          : <String>['sopa', 'carne', 'pescado', 'ensalada'],
      'bcuadros': is89
          ? <String>['refresco', 'limonada', 'jugo', 'cafe']
          : <String>[],
      'litCuadros': <int>{},
      // Cat at banquito
      'gatoVis': 1,
      'gatoPose': 'sit',
      // Shelf plates repisa1..repisa3 (plato1..plato3)
      'repisa': <String?>[null, null, null],
      // Story 87 state
      'platito': storyNum == 87 ? 3 : 0,
      'platitoEn': 'repisa_fin',
      'ordenes': <String, String>{},
      'servidos': <String, String>{},
      'llevaPlato': null,
      'meseraPad': 0,
      'meseraPlato': null,
      // Story 88 state
      'platanosVis': is88 ? 1 : 0,
      'platanos': is88 ? 3 : 0,
      'platoRanaVis': is88 ? 1 : 0,
      'platoRana': 0,
      'platoRanaEn': 'repisa_fin',
      'cocineroProp': null,
      'cocineroGuina': 0,
      // Story 89 state
      'bandeja': <String?>[null, null, null],
      'alzaBebida': null,
      'jugoVis': 0,
      'jugo': 3,
      'vasitoEn': 'vasito',
      'meseroPad': 0,
      'meseroAbanico': 0,
      'meseroSorbo': 0,
      // Transient FX & active directional gesture target cue
      'campanaFx': 0,
      'llamaFx': 0,
      'vaporFx': 0,
      'finalCelebrar': 0,
      'gestoCue': null,
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
        'z': _p.world(startSpot)[2],
        'spot': startSpot,
      },
    };
  }

  /* ---------- the set ---------- */

  @override
  String setKey(Map<String, dynamic> W) => 'noche';

  @override
  void buildSet(PpEngine e, PpBuild b, Map<String, dynamic> W) =>
      buildSetFor(e, b, setKey(W));

  final Map<PpEngine, PedidoSet> _sets = {};

  @override
  void buildSetFor(PpEngine e, PpBuild b, String key) =>
      (_sets[e] ??= PedidoSet(e, b)).buildSet(PedidoState.fromKey(key));

  @override
  bool get frogShadow => false;

  /* ---------- where everybody is ---------- */

  Map<String, dynamic> get _gente => W['gente'] as Map<String, dynamic>;

  PedidoAt _atOf(Map<String, dynamic> o) =>
      _p.atWorld(o['x'] as num, o['y'] as num, o['z'] as num);

  PedidoAt _frogPoint(Map<String, dynamic> q) {
    final spot = q['spot'];
    if (spot is String && _p.has(spot)) {
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

  /* ---------- sprites ---------- */

  static final Map<String, Sprite> _sprites = {};
  static Sprite _spr(String key, Sprite Function() make) =>
      _sprites[key] ??= make();

  static String _kitPoseOf(String pose) => switch (pose) {
    'saluda0' => 'wave0',
    'saluda1' => 'wave1',
    'senala_izq' => 'offer',
    'senala_der' || 'senala' => 'tu',
    'yo' || 'rie' => 'yo',
    'bebe' || 'come' => 'taza',
    _ => 'idle',
  };

  ({Sprite s, int ax, int ay}) _personSprite(
    String id,
    Map<String, dynamic> p,
    Map<String, dynamic> w,
    bool open,
    int anim,
  ) {
    final pose = (p['pose'] as String?) ?? 'idle';
    final sent = _n(p['sent']) == 1;
    if (id == 'abuela') {
      final s = _spr('pd_abS_${pose}_$open', () => mkAbuelaPedido(pose, open));
      // pedido-sheet.json rules.anchor: abuelaS hangs by her lap (17, 36).
      return (s: s, ax: 17, ay: 36);
    }
    final kp = _kitPoseOf(pose);
    if (id == 'cocinero') {
      final guina = _n(w['cocineroGuina']) == 1;
      final prop = w['cocineroProp'] as String?;
      final s = _spr(
        'pd_coc_${kp}_${open}_${guina}_$prop',
        () => mkCocinero(pose: kp, open: open, guina: guina, prop: prop),
      );
      return (s: s, ax: PX, ay: inkBottom(s));
    }
    if (id == 'mesera') {
      final pad = _n(w['meseraPad']) == 1;
      final plato = w['meseraPlato'] as String?;
      final s = _spr(
        'pd_msr_${kp}_${open}_${pad}_$plato',
        () => mkMesera(pose: kp, open: open, pad: pad, plato: plato),
      );
      return (s: s, ax: PX, ay: inkBottom(s));
    }
    if (id == 'mesero') {
      final pad = _n(w['meseroPad']) == 1;
      final abanico = _n(w['meseroAbanico']) == 1;
      final sorbo = _n(w['meseroSorbo']) == 1;
      final ff = abanico ? anim % 2 : 0;
      final s = _spr(
        'pd_mso_${kp}_${open}_${pad}_${abanico}_${sorbo}_$ff',
        () => mkMesero(
          pose: kp,
          open: open,
          pad: pad,
          abanico: abanico,
          sorbo: sorbo,
          fanFrame: ff,
        ),
      );
      return (s: s, ax: PX, ay: inkBottom(s));
    }

    final Who who = switch (id) {
      'abuelo' => FAM['abuelo']!,
      'luis' => FAM['hermano']!,
      'carmen' => FAM['hermana']!,
      _ => PEDIDO_PEOPLE[id]!,
    };
    final s = _spr(
      'pd_${id}_${kp}_${open}_$sent',
      () => mkPersona(who, kp, open, sent),
    );
    return (s: s, ax: PX, ay: sent ? pedidoSeatedLap(who) : inkBottom(s));
  }

  String? _talker() {
    try {
      return host.TALK;
    } catch (_) {
      return null;
    }
  }

  /// Every sprite of the frame [w] as it is placed, except the frog. The rules' tests read it; [draw] draws it.
  List<PedidoItem> items(Map<String, dynamic> w, int a) {
    final out = <PedidoItem>[];
    final talk = _talker();
    final gente = (w['gente'] as Map<String, dynamic>?) ?? const {};
    final anim = (F >> 2) + a;
    final story = _n(w['story']);
    final lit = (w['litCuadros'] as Set?) ?? const <int>{};

    // 1. People (cocinero, seated family, seated guests, standing staff)
    for (final id in PEDIDO_PERSONAS) {
      final p = gente[id] as Map<String, dynamic>?;
      if (p == null || p['vis'] == 0) continue;
      final open = talk == id && a % 2 == 1;
      final sp = _personSprite(id, p, w, open, anim);
      final at = _atOf(p);
      final sx = _round(at.sx) + _n(p['dx']);
      final sy = _round(at.sy) + _n(p['dy']);
      out.add(
        PedidoItem(sp.s, sx - sp.ax, sy - sp.ay, sy, at.d, tag: 'persona:$id'),
      );
    }

    // 2. Board pictures on food board (`cuadro1..4`) and drinks board (`bcuadro1..4`): dd +0.05 (pedido-preview.html)
    final cuadros = (w['cuadros'] as List?) ?? const [];
    for (var i = 0; i < cuadros.length && i < 4; i++) {
      final kind = cuadros[i] as String;
      final spot = 'cuadro${i + 1}';
      final at = _p.at(spot);
      final isLit = story != 89 && lit.contains(i + 1);
      final s = _spr(
        'pd_pic_${kind}_$isLit',
        () => mkCuadroPic(kind, lit: isLit),
      );
      final sx = _round(at.sx), sy = _round(at.sy);
      out.add(
        PedidoItem(s, sx - 7, sy - 6, sy, at.d + .05, tag: 'cuadro:$spot'),
      );
    }
    final bcuadros = (w['bcuadros'] as List?) ?? const [];
    for (var i = 0; i < bcuadros.length && i < 4; i++) {
      final kind = bcuadros[i] as String;
      final spot = 'bcuadro${i + 1}';
      final at = _p.at(spot);
      final isLit = story == 89 && lit.contains(i + 1);
      final s = _spr(
        'pd_pic_${kind}_$isLit',
        () => mkCuadroPic(kind, lit: isLit),
      );
      final sx = _round(at.sx), sy = _round(at.sy);
      out.add(
        PedidoItem(s, sx - 7, sy - 6, sy, at.d + .05, tag: 'bcuadro:$spot'),
      );
    }

    // 3. Hanging plantains on hook (story 88)
    if (_n(w['platanosVis']) == 1) {
      final n = _n(w['platanos']).clamp(0, 3);
      final at = _p.at('platanos');
      final s = _spr('pd_plat_$n', () => mkPlatanos(n));
      final sx = _round(at.sx), sy = _round(at.sy);
      out.add(PedidoItem(s, sx - 7, sy, sy, at.d, tag: 'cosa:platanos'));
    }

    // 4. Shelf plates (`plato1..plato3` at `repisa1..repisa3`)
    final repisa = (w['repisa'] as List?) ?? const [];
    for (var i = 0; i < repisa.length && i < 3; i++) {
      final kind = repisa[i] as String?;
      if (kind == null) continue;
      final spot = 'repisa${i + 1}';
      final at = _p.at(spot);
      final s = _spr('pd_plato_$kind', () => mkPlato(kind));
      final sx = _round(at.sx), sy = _round(at.sy);
      out.add(
        PedidoItem(s, sx - 7, sy - s.h, sy, at.d, tag: 'cosa:plato${i + 1}'),
      );
    }

    // 5. Small plate (`platito` in story 87) or frog's own plate (`platoRana` in story 88)
    if (story == 87) {
      final n = _n(w['platito']).clamp(0, 3);
      final en = (w['platitoEn'] as String?) ?? 'repisa_fin';
      final at = _p.at(en);
      final s = _spr('pd_platito_$n', () => mkPlatito(n));
      final sx = _round(at.sx), sy = _round(at.sy);
      out.add(PedidoItem(s, sx - 6, sy - s.h, sy, at.d, tag: 'cosa:platito'));
    } else if (story == 88 && _n(w['platoRanaVis']) == 1) {
      final lv = _n(w['platoRana']).clamp(0, 3);
      final en = (w['platoRanaEn'] as String?) ?? 'repisa_fin';
      final at = _p.at(en);
      final s = _spr('pd_platorana_$lv', () => mkPlatoRana(lv));
      final sx = _round(at.sx), sy = _round(at.sy);
      out.add(PedidoItem(s, sx - 6, sy - s.h, sy, at.d, tag: 'cosa:platito'));
    }

    // 6. Cat on floor by stool (`banquito`)
    if (_n(w['gatoVis']) == 1) {
      final pose = (w['gatoPose'] as String?) ?? 'sit';
      final gf = pose == 'lame' ? anim % 2 : 0;
      final at = _p.at('banquito');
      final s = _spr(
        'pd_gato_${pose}_$gf',
        () => mkGatoPedido(pose, frame: gf),
      );
      final sx = _round(at.sx), sy = _round(at.sy);
      out.add(PedidoItem(s, sx - 12, sy - s.h, sy, at.d, tag: 'cosa:gato'));
    }

    // 7. Story 87: order dish bubbles above seated family (`pide87`)
    // OPEN: pedido-sheet.json has no dish-bubble spot; place each 14x12 bubble above the speaker's head so 0 px
    // overlap top 14 head rows (abuela top 74 -> 60, abuelo 73 -> 59, luis/carmen 79 -> 65), clear of shelf & panels.
    final ordenes = (w['ordenes'] as Map?) ?? const {};
    const bubbleTops = <String, int>{
      'abuela': 60,
      'abuelo': 59,
      'luis': 65,
      'carmen': 65,
    };
    for (final en in ordenes.entries) {
      final who = en.key as String;
      final dish = en.value as String;
      final p = gente[who] as Map<String, dynamic>?;
      if (p == null || p['vis'] == 0) continue;
      final at = _atOf(p);
      final sx = _round(at.sx);
      final top = bubbleTops[who] ?? 60;
      final s = _spr('pd_ord_$dish', () => mkOrdenBurbuja(dish));
      out.add(
        PedidoItem(s, sx - 7, top, top + 12, at.d + .05, tag: 'fx:orden_$who'),
      );
    }

    // 8. Story 87: served plates on the family table (`lleva87`, `sirve87`)
    // OPEN: pedido-sheet.json has no served-plate spots on the family table; place them cleanly on the table top
    // (cols 121..175, rows 105..112, depth bebida1.d) clear of frog (76..106), platito at bebida1 (109..120), & heads.
    final servidos = (w['servidos'] as Map?) ?? const {};
    if (servidos.isNotEmpty) {
      final tblD = _p.at('bebida1').d;
      const plateXs = <String, int>{
        'abuela': 128,
        'abuelo': 142,
        'luis': 156,
        'carmen': 170,
      };
      for (final en in servidos.entries) {
        final who = en.key as String;
        final dish = en.value as String;
        final px = plateXs[who];
        if (px == null) continue;
        final s = _spr('pd_plato_$dish', () => mkPlato(dish));
        out.add(
          PedidoItem(s, px - 7, 113 - s.h, 113, tblD, tag: 'fx:servido_$who'),
        );
      }
    }

    // 9. Story 89: drinks on tray (`bebida1..bebida3`) and tall glass of orange juice (`vasito`)
    final bandeja = (w['bandeja'] as List?) ?? const [];
    final lifted = w['alzaBebida'] as String?;
    for (var i = 0; i < bandeja.length && i < 3; i++) {
      final kind = bandeja[i] as String?;
      if (kind == null) continue;
      final spot = 'bebida${i + 1}';
      final at = _p.at(spot);
      final s = _spr('pd_beb_$kind', () => mkBebida(kind));
      final lift = lifted == kind ? -6 : 0;
      final sx = _round(at.sx), sy = _round(at.sy);
      out.add(
        PedidoItem(
          s,
          sx - 5,
          sy - s.h + lift,
          sy,
          at.d + (lift != 0 ? .02 : 0),
          tag: 'cosa:$spot',
        ),
      );
    }

    if (_n(w['jugoVis']) == 1) {
      final thirds = _n(w['jugo']).clamp(0, 3);
      final en = (w['vasitoEn'] as String?) ?? 'vasito';
      final at = _p.at(en);
      final s = _spr('pd_vasito_$thirds', () => mkVasito(thirds));
      final sx = _round(at.sx), sy = _round(at.sy);
      out.add(PedidoItem(s, sx - 4, sy - s.h, sy, at.d, tag: 'cosa:vasito'));
    }

    // 10. Transient FX (bell sparkle, hatch flames, steam, gesture target cue, 3-of-3 ending celebration)
    if (_n(w['campanaFx']) == 1) {
      final cb = _p.box('campana');
      final s = _spr('pd_camp_${anim % 2}', () => mkCampanaBrillo(anim % 2));
      out.add(
        PedidoItem(s, cb[0] - 4, cb[1] - 8, cb[1], 1.2, tag: 'fx:campana'),
      );
    }
    if (_n(w['llamaFx']) == 1) {
      final s = _spr('pd_llama_${anim % 2}', () => mkLlama(anim % 2));
      // Inside hatch hole right of cocinero, below head and above shelf
      out.add(PedidoItem(s, 162, 26, 36, -0.1, tag: 'fx:llama'));
    }
    if (_n(w['vaporFx']) == 1) {
      final s = _spr('pd_vapor_${anim % 2}', () => mkVapor(anim % 2));
      final tblD = _p.at('bebida1').d;
      out.add(PedidoItem(s, 151, 96, 104, tblD + .02, tag: 'fx:vapor'));
    }
    final gc = w['gestoCue'];
    if (gc is Map) {
      final isSelf = gc['self'] == true;
      final isUp = gc['up'] == true;
      final s = _spr(
        'pd_gcue_${isSelf}_$isUp',
        () => mkGestoFlecha(self: isSelf, up: isUp),
      );
      final cx = _n(gc['cueX']);
      final cy = _n(gc['cueY']);
      final cd = (gc['d'] as num?)?.toDouble() ?? 6.0;
      out.add(PedidoItem(s, cx - 4, cy, cy + 7, cd, tag: 'fx:gesto_cue'));
    }
    if (_n(w['finalCelebrar']) == 1) {
      final st = _spr('pd_star', mkEstrellaPedido);
      final hr = _spr('pd_heart', mkCorazonPedido);
      // Positioned in open room area between shelf and heads (y 52..62), clear of heads, panels, plates, frog
      out.add(PedidoItem(st, 66, 52, 61, 6.0, tag: 'fx:estrella1'));
      out.add(PedidoItem(hr, 100, 50, 60, 6.0, tag: 'fx:corazon'));
      out.add(PedidoItem(st, 128, 52, 61, 6.0, tag: 'fx:estrella2'));
    }

    return out;
  }

  static final Map<String, Sprite> _frogSprites = {};

  /// [items] plus the frog (as the host draws him), for `draw` and for `PedidoRules`.
  List<PedidoItem> placed(Map<String, dynamic> w, int a) {
    final out = items(w, a);
    final q = w['cq'] as Map<String, dynamic>?;
    if (q != null && jsTruthy(q['vis'])) {
      final lleva = w['llevaPlato'] as String?;
      final at = _frogPoint(q);
      final dx = _n(q['dx']);
      final fsy = _round(at.sy);
      if (lleva != null) {
        final blink = host.F % 47 < 2;
        final open = (q['bub'] == 'hola' || _talker() == 'coqui') && a % 2 != 0;
        final s = _spr(
          'pd_cqpl_${lleva}_${open}_$blink',
          () => mkCoquiPlato(lleva, open: open, blink: blink),
        );
        final sx = _round(at.sx) + dx;
        final ay = coquiPlatoBottom(s);
        out.add(
          PedidoItem(
            s,
            sx - 16,
            fsy - ay + _n(q['dy']),
            fsy,
            at.d,
            tag: 'coqui',
          ),
        );
      } else {
        final b = host.frogBox(q);
        final ox = b.x.toInt() - 16 + dx;
        final oy = b.y.toInt() - 24;
        final fk =
            '${q['s']}_${b.x - (b.x.toInt() - 16)}_${b.y - oy}_${(q['y'] as num) - oy}_${((q['dy'] as num) + 0.5).floor()}_${host.F % 47 < 2 ? 1 : 0}_${((q['bub'] == 'hola' || _talker() == 'coqui') && a % 2 != 0) ? 1 : 0}';
        final spr = _frogSprites.putIfAbsent(fk, () {
          final px = Uint32List(64 * 64);
          final g = Ctx(px, 64, 64)
            ..translate(-(b.x.toInt() - 16).toDouble(), -oy.toDouble());
          host.frog(g, q, a);
          return Sprite(64, 64, px);
        });
        out.add(PedidoItem(spr, ox, oy, fsy, at.d, tag: 'coqui'));
      }
    }
    return out;
  }

  /* ---------- SetOverSprites & draw ---------- */

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
    PedidoItem it,
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

  /* ---------- the shadows (sheet: shadows) ---------- */

  @override
  List<ShadowCast> shadows(Map<String, dynamic> W) {
    final out = <ShadowCast>[];
    final gente = (W['gente'] as Map<String, dynamic>?) ?? const {};
    for (final en in gente.entries) {
      final p = en.value as Map<String, dynamic>;
      if (p['vis'] == 0) continue;
      final al = (p['al'] as num?)?.toDouble() ?? 1.0;
      if (al <= 0.5) continue;
      final spot = p['spot'] as String?;
      final z = (p['z'] as num?)?.toDouble() ?? 0.0;
      if (z != 0 || (spot != null && _p.noShadow(spot))) continue;
      final r = _p.radius(en.key);
      if (r == null) continue;
      out.add((
        x: (p['x'] as num).toDouble(),
        y: (p['y'] as num).toDouble(),
        z: 0.0,
        r: r,
      ));
    }
    if (_n(W['gatoVis']) == 1 && !_p.noShadow('banquito')) {
      final at = _p.at('banquito');
      final r = _p.radius('gato');
      if (r != null) out.add((x: at.x, y: at.y, z: 0.0, r: r));
    }
    return out;
  }

  /* ---------- talk bubbles (all 12 speakers) ---------- */

  @override
  List<num>? talkAt(String who, Map<String, dynamic> W) {
    if (who == 'coqui') {
      final q = W['cq'] as Map<String, dynamic>?;
      if (q == null || !jsTruthy(q['vis'])) return null;
      final b = host.frogBox(q);
      return [b.x + b.w / 2, b.y - 4];
    }
    final gente = (W['gente'] as Map<String, dynamic>?) ?? const {};
    final p = gente[who] as Map<String, dynamic>?;
    if (p == null || p['vis'] == 0) return null;
    final at = _atOf(p);
    final dy = switch (who) {
      'cocinero' => 53,
      'mesera' || 'mesero' => 53,
      'abuela' => 38,
      'luis' || 'carmen' => 34,
      _ => 40,
    };
    return [_round(at.sx) + _n(p['dx']), _round(at.sy) + _n(p['dy']) - dy];
  }

  /* ---------- touch things & hit testing (all 23 Needs things) ---------- */

  static List<int>? _itemBox(
    List<PedidoItem> list,
    bool Function(PedidoItem) test,
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

  List<Thing> _things() => [
    for (var i = 1; i <= 3; i++)
      Thing(
        id: 'plato$i',
        si: (w) =>
            w['repisa'] is List &&
            (w['repisa'] as List).length >= i &&
            (w['repisa'] as List)[i - 1] != null,
        box: (w) => _spriteBox(w, 'cosa:plato$i') ?? _p.spotBox('repisa$i'),
      ),
    Thing(
      id: 'platito',
      si: (w) =>
          _n(w['story']) == 87 ||
          (_n(w['story']) == 88 && _n(w['platoRanaVis']) == 1),
      box: (w) => _spriteBox(w, 'cosa:platito') ?? _p.spotBox('repisa_fin'),
    ),
    for (var i = 1; i <= 3; i++)
      Thing(
        id: 'bebida$i',
        si: (w) =>
            w['bandeja'] is List &&
            (w['bandeja'] as List).length >= i &&
            (w['bandeja'] as List)[i - 1] != null,
        box: (w) => _spriteBox(w, 'cosa:bebida$i') ?? _p.spotBox('bebida$i'),
      ),
    Thing(
      id: 'vasito',
      si: (w) => _n(w['jugoVis']) == 1,
      box: (w) => _spriteBox(w, 'cosa:vasito') ?? _p.spotBox('vasito'),
    ),
    Thing(
      id: 'platanos',
      si: (w) => _n(w['platanosVis']) == 1,
      box: (w) => _spriteBox(w, 'cosa:platanos') ?? _p.spotBox('platanos'),
    ),
    Thing(
      id: 'gato',
      si: (w) => _n(w['gatoVis']) == 1,
      box: (w) => _spriteBox(w, 'cosa:gato'),
    ),
    for (final who in const [
      'mesera',
      'mesero',
      'abuela',
      'abuelo',
      'luis',
      'carmen',
      'cocinero',
    ])
      Thing(
        id: who,
        si: (w) => ((w['gente'] as Map?)?[who] as Map?)?['vis'] != 0,
        box: (w) => _spriteBox(w, 'persona:$who'),
      ),
    for (var i = 1; i <= 4; i++)
      Thing(
        id: 'cuadro$i',
        box: (w) => _spriteBox(w, 'cuadro:cuadro$i') ?? _p.box('cuadro$i'),
      ),
    Thing(id: 'bebidas', box: (w) => _p.box('bebidas')),
  ];

  @override
  String? hit(num x, num y, Map<String, dynamic> w) {
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

  /* ---------- sheet-backed gesture target resolver & frog hop ---------- */

  _TargetPos? _targetScreen(String? target, Map<String, dynamic> w) {
    if (target == null || target.isEmpty) return null;
    final gente = (w['gente'] as Map<String, dynamic>?) ?? const {};
    if (gente[target] is Map) {
      final p = gente[target] as Map<String, dynamic>;
      if (p['vis'] == 0) return null;
      final at = _atOf(p);
      final sx = _round(at.sx) + _n(p['dx']);
      final sy = _round(at.sy) + _n(p['dy']);
      if (target == 'cocinero') {
        return (sx: sx, sy: sy, cueX: sx + 14, cueY: 24, up: false, d: 0.0);
      }
      final headTopOffset = switch (target) {
        'abuela' => 36,
        'luis' || 'carmen' => 31,
        'mesera' || 'mesero' => 53,
        _ => 39,
      };
      final headTop = sy - headTopOffset;
      return (
        sx: sx,
        sy: sy,
        cueX: sx,
        cueY: (headTop - 10).clamp(42, 180),
        up: false,
        d: at.d + .06,
      );
    }
    if (target == 'coqui') {
      final q = w['cq'] as Map<String, dynamic>?;
      if (q == null || !jsTruthy(q['vis'])) return null;
      final at = _frogPoint(q);
      final sx = _round(at.sx), sy = _round(at.sy);
      return (
        sx: sx,
        sy: sy,
        cueX: sx,
        cueY: sy - 34,
        up: false,
        d: at.d + .06,
      );
    }
    if (const [
      'cuadro1',
      'cuadro2',
      'cuadro3',
      'cuadro4',
      'bcuadro1',
      'bcuadro2',
      'bcuadro3',
      'bcuadro4',
      'bebidas',
    ].contains(target)) {
      final b = _p.box(target);
      final cx = b[0] + b[2] ~/ 2;
      final cy = b[1] + b[3] ~/ 2;
      return (sx: cx, sy: cy, cueX: cx, cueY: 42, up: true, d: 1.2);
    }
    if (target == 'campana') {
      final b = _p.box('campana');
      final cx = b[0] + b[2] ~/ 2;
      return (sx: cx, sy: b[1], cueX: cx, cueY: b[1] - 9, up: false, d: 1.2);
    }
    final spot = switch (target) {
      'platito' =>
        _n(w['story']) == 88
            ? ((w['platoRanaEn'] as String?) ?? 'repisa_fin')
            : ((w['platitoEn'] as String?) ?? 'repisa_fin'),
      'vasito' => (w['vasitoEn'] as String?) ?? 'vasito',
      'platanos' => 'platanos',
      'gato' => 'banquito',
      'plato1' => 'repisa1',
      'plato2' => 'repisa2',
      'plato3' => 'repisa3',
      'bebida1' || 'bebida2' || 'bebida3' => target,
      _ => _p.has(target) ? target : null,
    };
    if (spot == null || !_p.has(spot)) return null;
    final at = _p.at(spot);
    final sx = _round(at.sx), sy = _round(at.sy);
    if (spot == 'platanos') {
      return (sx: sx, sy: sy, cueX: sx, cueY: sy + 20, up: true, d: at.d + .06);
    }
    final dy = switch (target) {
      'vasito' => 26,
      'bebida1' || 'bebida2' || 'bebida3' => 24,
      'gato' => 29,
      _ => 17,
    };
    return (sx: sx, sy: sy, cueX: sx, cueY: sy - dy, up: false, d: at.d + .06);
  }

  Future<void> _hopToSpot(String spot) async {
    if (!_p.has(spot)) return;
    final at = _p.at(spot);
    final q = W['cq'] as Map<String, dynamic>;
    final dest = _frogAt(at);
    final sx = (q['x'] as num).toDouble(), sy = (q['y'] as num).toDouble();
    final dx = dest[0].toDouble() - sx, dy = dest[1].toDouble() - sy;
    final dist = math.sqrt(dx * dx + dy * dy);
    if (dist >= 2) {
      final steps = (dist / 18).ceil().clamp(1, 5);
      for (var i = 1; i <= steps; i++) {
        final t = i / steps;
        q['x'] = _round(sx + dx * t);
        q['y'] = _round(sy + dy * t);
        q['dy'] = i < steps ? -4 : 0;
        await wait(70);
      }
    }
    q['x'] = dest[0];
    q['y'] = dest[1];
    q['dy'] = 0;
    q['z'] = at.z;
    q['spot'] = spot;
  }

  /* ---------- loose acts & delegated acts (pedido_acts.dart) ---------- */

  final List<Future<void>> _loose = [];

  @override
  List<num> remap(List<num> xy) => xy;

  @override
  Future<void> stake(int lost, int max, String en) async {}

  @override
  Map<String, Act> get ownActs => _buildOwnActs();
}
