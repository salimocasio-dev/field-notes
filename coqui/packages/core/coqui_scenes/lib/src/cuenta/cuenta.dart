// La cuenta (place 8, La fonda, scene 4: `cuenta`; stories 93 to 95): a NEW scene, written from its script's
// "Needs" list (historia/notas/guiones/cuenta.md) on its set (cuenta_set.dart) and its sheet (cuenta-sheet.json,
// read by SceneSheet). There is no old scene file: every act is this file's, each doing on screen what the Needs
// list says, every place from the sheet (spots, set thing boxes, counter parts, depth rule, shadows).
// Where the sheet names no place or an act is unstated in the script, the code does the plainest thing that keeps
// the story playing and marks it `OPEN:`.
//
// The drawing (the sheet's `front`): every sprite stands with its feet's bottom edge on its spot's row and its
// middle on its column (rules.anchor); whoever sits hangs by the lap (abuelaS: 17, 36; adult: 24, 41; child: 24, 33);
// the hanging cover `tapa` hangs by its top middle; every sprite pixel is hidden by every set pixel (`baked.zb`)
// nearer than its upright plane plus `front.bias` (0.3). Between two sprites the nearer pixel wins (tie within 0.001
// goes to the later layer: the dessert cart is drawn before the cup, flans, tub, cover, and frog on it).
// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/src/colmado/colmado_cast.dart' show inkBottom;
import 'package:coqui_scenes/src/cuenta/cuenta_places.dart';
import 'package:coqui_scenes/src/cuenta/cuenta_set.dart';
import 'package:coqui_scenes/src/cuenta/cuenta_sprites.dart';
import 'package:coqui_scenes/src/scene_set.dart';
import 'package:coqui_scenes/src/sheet_cache.dart';

/// The scene "La cuenta", made from its sheet (read first: `loadScene`).
Scene createCuenta() => Cuenta(sceneSheetOf('cuenta'));

int _round(num v) => (v + 0.5).floor();

int _n(Object? v) {
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? 0;
  return 0;
}

/// One sprite of the sprite layer, placed: its picture, its top left on the 240 × 216 picture, the screen row of its
/// anchor and the depth there (front.plane), and who or what it is.
class CuentaItem {
  CuentaItem(
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

  /// Screen-space overlay drawn over the set and world sprites (e.g. celebration cues).
  final bool overlay;
}

/// Every person La cuenta knows, by speaker key (cuenta.md, "Needs").
const List<String> CUENTA_PERSONAS = [
  'mesera',
  'mesero',
  'cocinero',
  'abuela',
  'abuelo',
  'luis',
  'carmen',
  'senor',
  'senora',
  'joven',
  'mujer',
];

const Set<String> _GUESTS = {'senor', 'senora', 'joven', 'mujer'};

const Set<String> _SEAT_SPOTS = {
  'silla1',
  'silla2',
  'silla3',
  'silla4',
  'otra_mesa1',
  'otra_mesa2',
};

class Cuenta extends Escena implements SetScene, SetOverSprites {
  Cuenta(this.ss)
    : sheet = identical(ss, _lastSs)
          ? _lastSheet!
          : (_lastSheet = ss.legacy()) {
    _p = identical(ss, _lastSs)
        ? _lastPlaces!
        : (_lastPlaces = CuentaPlaces(ss));
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
  static CuentaPlaces? _lastPlaces;

  /// The new scene's sheet (SceneSheet).
  final SceneSheet ss;

  @override
  final Sheet sheet;

  late final CuentaPlaces _p;

  /// The scene's places, from its sheet.
  CuentaPlaces get places => _p;

  @override
  String get id => 'cuenta';

  @override
  late final Map<String, List<num>> CAM;

  late final Map<String, List<num>> LUGAR;

  @override
  Map<String, List<num>> get lugar => LUGAR;

  @override
  late final List<Thing> cosas;

  @override
  PpEngine newEngine({bool still = false}) => cuentaEngine(still: still);

  @override
  PpEngine get projection => _p.e;

  List<num> _frogAt(CuentaAt a) => [_round(a.sx) - 16, _round(a.sy) - 25, 1];

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
      'dx': 0,
      'dy': 0,
    };
  }

  void _placePerson(String id, String spot, {int vis = 1}) {
    final w = _p.world(spot);
    final sent = _SEAT_SPOTS.contains(spot) ? 1 : 0;
    _gente[id] = <String, dynamic>{
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

  @override
  Map<String, dynamic> fresh(Map<String, dynamic> story) {
    final acts = _actsOf([story['beats'], story['final']]);
    bool has(String a) => acts.any((o) => o['act'] == a);
    final is95 =
        has('paga95') ||
        has('guarda95') ||
        has('sillas95') ||
        has('guagua') ||
        has('final95');
    final is94 =
        !is95 &&
        (has('lleva94') ||
            has('cuenta94') ||
            has('cobra94') ||
            has('moneda94') ||
            has('menta94') ||
            has('cierra94') ||
            has('final94'));
    final storyNum = is95 ? 95 : (is94 ? 94 : 93);
    final startSpot = storyNum == 93 ? 'carrito_coqui' : 'mostrador_coqui';
    final q = _frogAt(_p.at(startSpot));

    final gente = <String, dynamic>{};
    if (storyNum == 93) {
      gente['abuela'] = _person('silla1', sent: 1);
      gente['abuelo'] = _person('silla2', sent: 1);
      gente['luis'] = _person('silla3', sent: 1);
      gente['carmen'] = _person('silla4', sent: 1);
      gente['mesera'] = _person('mesera93');
    } else if (storyNum == 94) {
      gente['mesera'] = _person('caja');
      gente['abuelo'] = _person('paga');
      gente['abuela'] = _person('familia1');
      gente['luis'] = _person('familia3');
      gente['carmen'] = _person('familia4');
    } else {
      gente['abuela'] = _person('silla1', sent: 1);
      gente['abuelo'] = _person('silla2', sent: 1);
      gente['luis'] = _person('silla3', sent: 1);
      gente['carmen'] = _person('silla4', sent: 1);
      gente['mesero'] = _person('junto_mesa');
      gente['cocinero'] = _person('cocina');
      gente['mesera'] = _person('sillas_mesera');
    }

    return <String, dynamic>{
      'story': storyNum,
      'hora': 'noche',
      'guagua': 'no',
      'sillas': 'abajo',
      'gente': gente,
      // Story 93 dessert cart state
      'carritoVis': storyNum == 93 ? 1 : 0,
      'carritoEn': 'carrito', // 'carrito' | 'otra_mesa'
      'copa': 0,
      'copaPool': 0, // 0 none, 1 little pool, 2 big pool
      'flanWobble': 0,
      'mantScooped': 0,
      'tapaDown': 0,
      'sirveFx': null, // {kind: 'flan'|'mantecado', x, y}
      'otraLast': null, // guest served in round A at otra_mesa
      'final93': 0,
      // Story 94 & 95 counter props & state
      'maquinaVis': storyNum == 94 ? 1 : 0,
      'maquinaBeep': 0,
      'frascoVis': storyNum == 93 ? 0 : 1,
      'frasco': 0,
      'frascoBills': 0,
      'frascoTipped': 0,
      'cuentaVis': storyNum == 94 ? 1 : 0,
      'cuentaEn': 'mesera', // 'mesera' | 'abuelo' | 'grande'
      'cuentaNum': 40,
      'gavetaAbierta': 0,
      'gavetaBills': 0,
      'payFx': null, // {kind: 'tarjeta'|'billetes'|'moneda'|'menta', x, y}
      'sillaManoFx': 0,
      'final94': 0,
      'final95': 0,
      'guaguaDoor': null, // 'open' | 'shut' | null
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
  String setKey(Map<String, dynamic> W) {
    final g = W['guagua'];
    final guagua =
        g is String && const ['no', 'lejos', 'medio', 'cerca'].contains(g)
        ? g
        : 'no';
    final s = W['sillas'];
    final sillas = s is String && const ['abajo', 'arriba'].contains(s)
        ? s
        : 'abajo';
    return '$guagua-$sillas';
  }

  @override
  void buildSet(PpEngine e, PpBuild b, Map<String, dynamic> W) =>
      buildSetFor(e, b, setKey(W));

  final Map<PpEngine, CuentaSet> _sets = {};

  @override
  void buildSetFor(PpEngine e, PpBuild b, String key) =>
      (_sets[e] ??= CuentaSet(e, b)).buildSet(CuentaState.fromKey(key));

  @override
  bool get frogShadow => false;

  /* ---------- where everybody is ---------- */

  Map<String, dynamic> get _gente => W['gente'] as Map<String, dynamic>;

  CuentaAt _atOf(Map<String, dynamic> o) =>
      _p.atWorld(o['x'] as num, o['y'] as num, o['z'] as num);

  CuentaAt _frogPoint(Map<String, dynamic> q) {
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

  /* ---------- sprites ---------- */

  static final Map<String, Sprite> _sprites = {};
  static Sprite _spr(String key, Sprite Function() make) =>
      _sprites[key] ??= make();

  ({Sprite s, int ax, int ay}) _personSprite(
    String id,
    Map<String, dynamic> p,
    bool open,
    int storyNum,
  ) {
    final pose = (p['pose'] as String?) ?? 'idle';
    final sent = _n(p['sent']) == 1;
    if (id == 'abuela') {
      final abPose = switch (pose) {
        'saluda0' || 'saluda1' => 'saluda0',
        'senala' => 'tu',
        'rie' || 'barriga' => 'yo',
        _ => 'idle',
      };
      if (sent) {
        final s = _spr(
          'cu_abS_${abPose}_$open',
          () => mkAbuelaS(abPose, open, false),
        );
        // cuenta-sheet.json rules.anchor: abuelaS hangs by her lap (17, 36).
        return (s: s, ax: 17, ay: 36);
      }
      final s = _spr('cu_ab_${abPose}_$open', () => mkAbuela(abPose, open));
      // cuenta-sheet.json rules.anchor: mkAbuela standing column 30.
      return (s: s, ax: 30, ay: inkBottom(s));
    }

    final whoKey = (id == 'abuelo' && storyNum == 94) ? 'abuelo_sin_gafas' : id;
    final who = CUENTA_WHO[whoKey] ?? CUENTA_WHO['senor']!;
    final kp = switch (pose) {
      'saluda0' => 'wave0',
      'saluda1' => 'wave1',
      'senala' => 'tu',
      'rie' || 'barriga' || 'reverencia' || 'agita' => 'yo',
      'mano' => 'offer',
      _ => 'idle',
    };
    final s = _spr(
      'cu_${whoKey}_${kp}_${open}_$sent',
      () => mkPersona(who, kp, open, sent),
    );
    // cuenta-sheet.json rules.anchor: sitting hung by lap 16 + 2*t + 3 (adult 41, child 33).
    final ay = sent ? (16 + 2 * (who.nino ? 7 : 11) + 3) : inkBottom(s);
    return (s: s, ax: PX, ay: ay);
  }

  String? _talker() {
    try {
      return host.TALK;
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic>? _vars() {
    try {
      return host.V;
    } catch (_) {
      return null;
    }
  }

  void _seatGuestIn(Map<String, dynamic> gente, String guest, String spot) {
    for (final g in _GUESTS) {
      if (g == guest) continue;
      final gm = gente[g];
      if (gm is Map<String, dynamic> && gm['vis'] != 0 && gm['spot'] == spot) {
        gm['vis'] = 0;
      }
    }
    final cur = gente[guest];
    if (cur is Map<String, dynamic> &&
        cur['vis'] != 0 &&
        cur['spot'] == spot &&
        _n(cur['sent']) == 1) {
      return;
    }
    gente[guest] = _person(spot, sent: 1);
  }

  void _ensureOtraMesaGuestIn(Map<String, dynamic> w, String guest) {
    if (!_GUESTS.contains(guest) ||
        _n(w['story']) != 93 ||
        w['carritoEn'] != 'otra_mesa') {
      return;
    }
    final gente = w['gente'];
    if (gente is! Map<String, dynamic>) return;
    final cur = gente[guest];
    if (cur is Map &&
        cur['vis'] != 0 &&
        (cur['spot'] == 'otra_mesa1' || cur['spot'] == 'otra_mesa2')) {
      w['otraLast'] ??= guest;
      return;
    }
    final last = w['otraLast'] as String?;
    var targetSpot = 'otra_mesa1';
    if (last != null) {
      final lp = gente[last];
      if (lp is Map && lp['vis'] != 0 && lp['spot'] == 'otra_mesa1') {
        targetSpot = 'otra_mesa2';
      }
    }
    _seatGuestIn(gente, guest, targetSpot);
    w['otraLast'] ??= guest;
  }

  /// Syncs story 93's next-table guests with `host.V` (`ga`, `gb` dealt by `reparte`) and `host.TALK`
  /// so the drawn guests are visibly seated before their dessert request line plays.
  void _syncOtraMesaGuests(Map<String, dynamic> w) {
    if (_n(w['story']) != 93 || w['carritoEn'] != 'otra_mesa') return;
    final gente = w['gente'];
    if (gente is! Map<String, dynamic>) return;
    final v = _vars();
    final ga = v?['ga'];
    final gb = v?['gb'];
    if (ga is String && _GUESTS.contains(ga)) {
      _seatGuestIn(gente, ga, 'otra_mesa1');
      if (gb is String && _GUESTS.contains(gb) && gb != ga) {
        _seatGuestIn(gente, gb, 'otra_mesa2');
      } else {
        final hasSecond = _GUESTS.any((g) {
          final m = gente[g];
          return g != ga &&
              m is Map &&
              m['vis'] != 0 &&
              m['spot'] == 'otra_mesa2';
        });
        if (!hasSecond) {
          final fallback = _GUESTS.firstWhere((g) => g != ga);
          _seatGuestIn(gente, fallback, 'otra_mesa2');
        }
      }
      return;
    }
    final talk = _talker();
    if (talk is String && _GUESTS.contains(talk)) {
      _ensureOtraMesaGuestIn(w, talk);
    }
  }

  /// Every sprite of the frame [w] as it is placed, except the frog. The rules' tests read it; [draw] draws it.
  List<CuentaItem> items(Map<String, dynamic> w, int a) {
    _syncOtraMesaGuests(w);
    final out = <CuentaItem>[];
    final talk = _talker();
    final gente = (w['gente'] as Map<String, dynamic>?) ?? const {};
    final storyNum = _n(w['story']);

    // 1. Night guagua glimpsed in doorway in final95 (open door while boarding, shut after boarding)
    if (_n(w['final95']) > 0) {
      final shut = w['guaguaDoor'] == 'shut';
      final bus = _spr(
        'cu_guagua_puerta_$shut',
        () => mkGuaguaPuerta(doorShut: shut),
      );
      // Doorway hole is [181, 16, 34, 50]; d=0.15 places bus behind umbral (d=0.433) and in front of outside wall (d=-1.04).
      out.add(CuentaItem(bus, 186, 34, 66, 0.15, tag: 'fx:guagua_puerta'));
    }

    // 2. People
    for (final en in gente.entries) {
      final p = en.value as Map<String, dynamic>;
      if (p['vis'] == 0) continue;
      final open = talk == en.key && a % 2 == 1;
      final sp = _personSprite(en.key, p, open, storyNum);
      final at = _atOf(p);
      final sx = _round(at.sx) + _n(p['dx']);
      final sy = _round(at.sy) + _n(p['dy']);
      out.add(
        CuentaItem(
          sp.s,
          sx - sp.ax,
          sy - sp.ay,
          sy,
          at.d,
          tag: 'persona:${en.key}',
        ),
      );
      if (en.key == 'mesera' && _n(w['sillaManoFx']) == 1) {
        final ch = _spr('cu_silla_mano', mkSillaMano);
        out.add(
          CuentaItem(ch, sx - 14, sy - 34, sy, at.d + .02, tag: 'fx:silla_l'),
        );
        out.add(
          CuentaItem(ch, sx + 5, sy - 34, sy, at.d + .02, tag: 'fx:silla_r'),
        );
      }
    }

    // 3. Story 93 dessert cart and the four things on it (cart drawn FIRST so tie goes to items & frog)
    if (_n(w['carritoVis']) == 1) {
      final suf = w['carritoEn'] == 'otra_mesa' ? '2' : '';
      final cAt = _p.at('carrito$suf');
      final cart = _spr('cu_carrito', mkCarrito);
      final csx = _round(cAt.sx), csy = _round(cAt.sy);
      out.add(
        CuentaItem(cart, csx - 38, csy - cart.h, csy, cAt.d, tag: 'fx:carrito'),
      );

      // Frog's small cup (`copa`)
      final copaAt = _p.at('copa$suf');
      final scoops = _n(w['copa']).clamp(0, 3);
      final pool = _n(w['copaPool']);
      final copaSpr = _spr(
        'cu_copa_${scoops}_$pool',
        () => mkCopa(scoops: scoops, pool: pool == 1, bigPool: pool == 2),
      );
      final cosx = _round(copaAt.sx), cosy = _round(copaAt.sy);
      out.add(
        CuentaItem(
          copaSpr,
          cosx - (copaSpr.w ~/ 2),
          cosy - copaSpr.h,
          cosy,
          copaAt.d,
          tag: 'cosa:copa',
        ),
      );

      // Caramel flans (`flanes`)
      final flAt = _p.at('flanes$suf');
      final wob = _n(w['flanWobble']) == 1;
      final flSpr = _spr('cu_flanes_$wob', () => mkFlanes(wobble: wob));
      final flsx = _round(flAt.sx), flsy = _round(flAt.sy);
      out.add(
        CuentaItem(
          flSpr,
          flsx - (flSpr.w ~/ 2),
          flsy - flSpr.h,
          flsy,
          flAt.d,
          tag: 'cosa:flanes',
        ),
      );

      // Tub of ice cream (`mantecado`)
      final mAt = _p.at('mantecado$suf');
      final sc = _n(w['mantScooped']) == 1;
      final mSpr = _spr('cu_mant_$sc', () => mkMantecado(scooped: sc));
      final msx = _round(mAt.sx), msy = _round(mAt.sy);
      out.add(
        CuentaItem(
          mSpr,
          msx - (mSpr.w ~/ 2),
          msy - mSpr.h,
          msy,
          mAt.d,
          tag: 'cosa:mantecado',
        ),
      );

      // Domed cover (`tapa`): hangs with top middle on spot (cuenta-sheet.json rules.spot)
      final tAt = _p.at('tapa$suf');
      final tSpr = _spr('cu_tapa', mkTapa);
      final tsx = _round(tAt.sx), tsy = _round(tAt.sy);
      out.add(
        CuentaItem(
          tSpr,
          tsx - (tSpr.w ~/ 2),
          tsy,
          tsy,
          tAt.d,
          tag: 'cosa:tapa',
        ),
      );

      // Wide cover swung down briefly over desserts during `sirve93(nada)`
      if (_n(w['tapaDown']) == 1) {
        final tg = _spr('cu_tapa_grande', mkTapaGrande);
        out.add(
          CuentaItem(
            tg,
            flsx - 7,
            flsy - tg.h,
            flsy,
            flAt.d + .02,
            tag: 'fx:tapa_down',
          ),
        );
      }

      // Transient served dish animation (`sirve93`)
      final sfx = w['sirveFx'];
      if (sfx is Map) {
        final kind = sfx['kind'] as String?;
        final spr = kind == 'mantecado'
            ? _spr('cu_vaso_mant', mkVasoMantecado)
            : _spr('cu_plato_flan', mkPlatoFlan);
        final fx = _n(sfx['x']), fy = _n(sfx['y']);
        out.add(
          CuentaItem(
            spr,
            fx - (spr.w ~/ 2),
            fy - (spr.h ~/ 2),
            fy,
            flAt.d + .03,
            tag: 'fx:sirve',
          ),
        );
      }

      // 3-of-3 celebration in final93 (clear of all heads, cart items, frog, and window)
      if (_n(w['final93']) == 3) {
        final est = _spr('cu_estrellas', mkEstrellasCuenta);
        final cor = _spr('cu_corazon', mkCorazonCuenta);
        out.add(
          CuentaItem(
            est,
            128,
            144,
            152,
            9.0,
            tag: 'fx:estrellas',
            overlay: true,
          ),
        );
        out.add(
          CuentaItem(cor, 146, 144, 153, 9.0, tag: 'fx:corazon', overlay: true),
        );
      }
    }

    // 4. Card machine on counter (`maquina`, story 94)
    if (_n(w['maquinaVis']) == 1) {
      final at = _p.at('maquina');
      final beep = _n(w['maquinaBeep']) == 1;
      final spr = _spr('cu_maquina_$beep', () => mkMaquina(beep: beep));
      final sx = _round(at.sx), sy = _round(at.sy);
      out.add(
        CuentaItem(
          spr,
          sx - (spr.w ~/ 2),
          sy - spr.h,
          sy,
          at.d,
          tag: 'cosa:maquina',
        ),
      );
      if (beep) {
        final bp = _spr('cu_beep', mkBeep);
        out.add(
          CuentaItem(bp, sx - 4, sy - 18, sy, at.d + .02, tag: 'fx:beep'),
        );
      }
    }

    // 5. Glass jar on counter (`frasco`, stories 94 & 95)
    if (_n(w['frascoVis']) == 1) {
      final at = _p.at('frasco');
      final coins = _n(w['frasco']).clamp(0, 3);
      final bills = _n(w['frascoBills']).clamp(0, 2);
      final tipped = _n(w['frascoTipped']) == 1;
      final spr = _spr(
        'cu_frasco_${coins}_${bills}_$tipped',
        () => mkFrasco(coins: coins, bills: bills, tipped: tipped),
      );
      final sx = _round(at.sx), sy = _round(at.sy);
      out.add(
        CuentaItem(
          spr,
          sx - (spr.w ~/ 2),
          sy - spr.h,
          sy,
          at.d,
          tag: 'cosa:frasco',
        ),
      );
    }

    // 6. Open register drawer extension (extends below gaveta [103, 59, 18, 3] without covering it)
    if (_n(w['gavetaAbierta']) == 1) {
      final bills = _n(w['gavetaBills']) == 1;
      final spr = _spr('cu_gaveta_$bills', () => mkGavetaAbierta(bills: bills));
      final gb = _p.box('gaveta');
      final gy = gb[1] + gb[3];
      out.add(
        CuentaItem(spr, gb[0], gy, gy + spr.h, 1.7, tag: 'fx:gaveta_abierta'),
      );
    }

    // 7. Bill slip (`cuenta`, story 94)
    // OPEN: cuenta-sheet.json has no spot for `cuenta` ("a slip, 8 x 10, in a hand"): placed at
    // (126, 38) by mesera, (148, 68) by abuelo, and (128, 74) when enlarged — all clear of people,
    // counter things, and the window.
    if (_n(w['cuentaVis']) == 1) {
      final en = (w['cuentaEn'] as String?) ?? 'mesera';
      if (en == 'grande') {
        final numVal = _n(w['cuentaNum']);
        final shine = w['twinkle'] == 'cuenta';
        final spr = _spr(
          'cu_cuenta_g_${numVal}_$shine',
          () => mkCuentaGrande(numVal, shine: shine),
        );
        out.add(CuentaItem(spr, 128, 74, 102, 2.3, tag: 'cosa:cuenta'));
      } else {
        final spr = _spr('cu_cuenta_slip', mkCuentaSlip);
        final pos = en == 'abuelo' ? const (148, 68) : const (126, 38);
        out.add(
          CuentaItem(
            spr,
            pos.$1,
            pos.$2,
            pos.$2 + spr.h,
            en == 'abuelo' ? 2.2 : 2.0,
            tag: 'cosa:cuenta',
          ),
        );
      }
    }

    // 8. Transient payment / mint animation FX (cleared before act completes)
    final pfx = w['payFx'];
    if (pfx is Map) {
      final kind = pfx['kind'] as String?;
      final spr = switch (kind) {
        'tarjeta' => _spr('cu_tarjeta', mkTarjeta),
        'moneda' => _spr('cu_moneda', mkMoneda),
        'menta' => _spr('cu_menta', mkMenta),
        _ => _spr('cu_billetes', mkBilletes),
      };
      final fx = _n(pfx['x']), fy = _n(pfx['y']);
      out.add(
        CuentaItem(
          spr,
          fx - (spr.w ~/ 2),
          fy - (spr.h ~/ 2),
          fy,
          2.4,
          tag: 'fx:pay',
        ),
      );
    }

    // 9. Celebrations for 3-of-3 endings in stories 94 & 95 (clear of window, heads, and counter props)
    if (_n(w['final94']) == 3) {
      final est = _spr('cu_estrellas', mkEstrellasCuenta);
      final cor = _spr('cu_corazon', mkCorazonCuenta);
      out.add(
        CuentaItem(est, 132, 36, 44, 5.0, tag: 'fx:estrellas', overlay: true),
      );
      out.add(
        CuentaItem(cor, 150, 36, 45, 5.0, tag: 'fx:corazon', overlay: true),
      );
    }
    if (_n(w['final95']) == 3) {
      final est = _spr('cu_estrellas', mkEstrellasCuenta);
      final cor = _spr('cu_corazon', mkCorazonCuenta);
      out.add(
        CuentaItem(est, 184, 6, 14, 5.0, tag: 'fx:estrellas', overlay: true),
      );
      out.add(
        CuentaItem(cor, 202, 5, 14, 5.0, tag: 'fx:corazon', overlay: true),
      );
    }

    return out;
  }

  static final Map<String, Sprite> _frogSprites = {};

  /// [items] plus the frog (as the host draws him), for `draw` and for `CuentaRules`.
  List<CuentaItem> placed(Map<String, dynamic> w, int a) {
    final out = items(w, a);
    final q = w['cq'] as Map<String, dynamic>?;
    if (q != null && jsTruthy(q['vis'])) {
      final b = host.frogBox(q);
      final at = _frogPoint(q);
      final dx = _n(q['dx']);
      final fsy = _round(at.sy);
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
      out.add(CuentaItem(spr, ox, oy, fsy, at.d, tag: 'coqui'));
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
    // La cuenta has no swaying foliage: baked depth matches cuenta-preview.html `window.DEPTH.z`.
    _setZ = baked.zb;
  }

  static final double _t30 = math.tan(math.pi / 6);

  void _put(
    CuentaItem it,
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
    _syncOtraMesaGuests(W);
    final out = <ShadowCast>[];
    final gente = (W['gente'] as Map<String, dynamic>?) ?? const {};
    for (final en in gente.entries) {
      final p = en.value as Map<String, dynamic>;
      if (p['vis'] == 0) continue;
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
    _syncOtraMesaGuests(W);
    if (_GUESTS.contains(who) &&
        _n(W['story']) == 93 &&
        W['carritoEn'] == 'otra_mesa') {
      _ensureOtraMesaGuestIn(W, who);
    }
    final gente = (W['gente'] as Map<String, dynamic>?) ?? const {};
    final p = gente[who] as Map<String, dynamic>?;
    if (p != null && p['vis'] != 0) {
      final at = _atOf(p);
      final sent = _n(p['sent']) == 1;
      final isKid = who == 'luis' || who == 'carmen';
      final dy = sent ? (isKid ? 34 : 42) : (isKid ? 42 : 52);
      return [_round(at.sx), _round(at.sy) - dy];
    }
    return null;
  }

  /* ---------- touch things & hit testing ---------- */

  static List<int>? _itemBox(
    List<CuentaItem> list,
    bool Function(CuentaItem) test,
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
    // Foreground interactive props
    Thing(
      id: 'copa',
      si: (w) => _n(w['carritoVis']) == 1,
      box: (w) =>
          _spriteBox(w, 'cosa:copa') ??
          _p.spotBox(w['carritoEn'] == 'otra_mesa' ? 'copa2' : 'copa'),
    ),
    Thing(
      id: 'flanes',
      si: (w) => _n(w['carritoVis']) == 1,
      box: (w) =>
          _spriteBox(w, 'cosa:flanes') ??
          _p.spotBox(w['carritoEn'] == 'otra_mesa' ? 'flanes2' : 'flanes'),
    ),
    Thing(
      id: 'mantecado',
      si: (w) => _n(w['carritoVis']) == 1,
      box: (w) =>
          _spriteBox(w, 'cosa:mantecado') ??
          _p.spotBox(
            w['carritoEn'] == 'otra_mesa' ? 'mantecado2' : 'mantecado',
          ),
    ),
    Thing(
      id: 'tapa',
      si: (w) => _n(w['carritoVis']) == 1,
      box: (w) =>
          _spriteBox(w, 'cosa:tapa') ??
          _p.spotBox(w['carritoEn'] == 'otra_mesa' ? 'tapa2' : 'tapa'),
    ),
    Thing(
      id: 'cuenta',
      si: (w) => _n(w['cuentaVis']) == 1,
      box: (w) => _spriteBox(w, 'cosa:cuenta'),
    ),
    Thing(
      id: 'maquina',
      si: (w) => _n(w['maquinaVis']) == 1,
      box: (w) => _spriteBox(w, 'cosa:maquina') ?? _p.spotBox('maquina'),
    ),
    Thing(
      id: 'frasco',
      si: (w) => _n(w['frascoVis']) == 1,
      box: (w) => _spriteBox(w, 'cosa:frasco') ?? _p.spotBox('frasco'),
    ),
    // Counter set things (before people so mesera behind register does not shadow the drawer or mints)
    Thing(id: 'gaveta', box: (w) => _p.box('gaveta')),
    Thing(id: 'mentas', box: (w) => _p.box('mentas')),
    // People
    for (final who in CUENTA_PERSONAS)
      Thing(
        id: who,
        si: (w) {
          final p = (w['gente'] as Map?)?[who];
          return p is Map && p['vis'] != 0;
        },
        box: (w) => _spriteBox(w, 'persona:$who'),
      ),
    // Back wall openings (after people so umbral family takes priority over the open door behind them)
    Thing(id: 'ventana', box: (w) => _p.box('ventana')),
    Thing(id: 'puerta', box: (w) => _p.box('puerta')),
  ];

  @override
  String? hit(num x, num y, Map<String, dynamic> w) {
    _syncOtraMesaGuests(w);
    // Check frog first when visible so nothing steals a frog tap.
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

  /* ---------- loose acts (`suelto: 1` / `ya`) ---------- */

  final List<Future<void>> _loose = [];

  Future<void> _run(Map<String, dynamic> o, Future<void> Function() body) {
    if (jsTruthy(o['suelto'])) {
      final f = body();
      _loose.add(f);
      return Future<void>.value();
    }
    return body();
  }

  @override
  List<num> remap(List<num> xy) => xy;

  @override
  Future<void> stake(int lost, int max, String en) async {}

  /* ---------- helpers for story 93 guests & story 94/95 arrivals ---------- */

  // OPEN: gen_cuenta.py issues no `llega` in story 93 for the two drawn guests at otra_mesa;
  // `_syncOtraMesaGuests` seats `host.V['ga']`/`host.V['gb']` (or the active speaker) ahead of
  // the request line, and `_ensureOtraMesaGuest` ensures any guest named by `sirve93`/`gesto`.
  void _ensureOtraMesaGuest(String guest) => _ensureOtraMesaGuestIn(W, guest);

  Future<void> _moveFrogTo(String spot) async {
    if (!_p.hasWorld(spot)) return;
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

  /* ---------- acts (cuenta.md "Needs" + gen_cuenta.py) ---------- */

  @override
  Map<String, Act> get ownActs => {
    'ya': (o) async {
      while (_loose.isNotEmpty) {
        final batch = List<Future<void>>.from(_loose);
        _loose.clear();
        await Future.wait(batch);
      }
    },
    'brilla': (o) async {
      W['twinkle'] = o['a'] ?? o['que'] ?? o['en'];
      await wait(120);
    },
    'ir': (o) => _run(o, () async {
      final spot = (o['a'] as String?) ?? 'mostrador_coqui';
      await _moveFrogTo(spot);
      if (spot == 'puerta_coqui' && _n(W['story']) == 95) {
        // OPEN: gen_cuenta.py issues no `llega` for mesera before beat 8 waves; move her to `caja`
        // matching cuenta-preview.html moment 7.
        _placePerson('mesera', 'caja');
      }
    }),
    'llega': (o) => _run(o, () async {
      final quien = (o['quien'] as String?) ?? 'senor';
      final spot = (o['a'] as String?) ?? 'paga';
      if (!_p.hasWorld(spot)) return;
      if (spot == 'paga') {
        // Clear any previous occupant at `paga` so two characters never stack at the register.
        for (final en in _gente.entries) {
          if (en.key == quien) continue;
          final m = en.value as Map<String, dynamic>;
          if (m['vis'] != 0 && m['spot'] == 'paga') {
            m['vis'] = 0;
          }
        }
        // OPEN: in story 94 beat 4 when senor steps up to paga, clear the family who already paid
        // and the opening bill slip (matching cuenta-preview.html moment 4 with zero sprites-apart breaches).
        if (_n(W['story']) == 94 && _GUESTS.contains(quien)) {
          for (final fam in const ['abuela', 'abuelo', 'luis', 'carmen']) {
            final fm = _gente[fam];
            if (fm is Map<String, dynamic>) fm['vis'] = 0;
          }
          W['cuentaVis'] = 0;
        }
      }
      _placePerson(quien, spot);
      await wait(160);
    }),
    'sale': (o) => _run(o, () async {
      final quien = (o['quien'] as String?) ?? 'senor';
      final p = _gente[quien];
      if (p is Map<String, dynamic> && p['vis'] != 0) {
        final w = _p.world('sale');
        p['x'] = w[0];
        p['y'] = w[1];
        p['z'] = w[2];
        p['spot'] = 'sale';
        p['sent'] = 0;
        await wait(140);
        p['vis'] = 0;
      } else {
        await wait(80);
      }
    }),

    /* ----- Story 93 acts ----- */
    'carrito93': (o) => _run(o, () async {
      final a = (o['a'] as String?) == 'otra_mesa' ? 'otra_mesa' : 'carrito';
      W['carritoVis'] = 1;
      W['carritoEn'] = a;
      W['tapaDown'] = 0;
      W['sirveFx'] = null;
      if (a == 'otra_mesa') {
        _placePerson('mesera', 'mesera93b');
        // OPEN: gen_cuenta.py issues no `llega` in story 93; seat senor and mujer by default
        // matching cuenta-preview.html moment 2 (swapped dynamically when a drawn guest is served).
        _placePerson('senor', 'otra_mesa1');
        _placePerson('mujer', 'otra_mesa2');
        W['otraLast'] = null;
        await _moveFrogTo('carrito_coqui2');
      } else {
        _placePerson('mesera', 'mesera93');
        for (final g in _GUESTS) {
          final gm = _gente[g];
          if (gm is Map<String, dynamic>) gm['vis'] = 0;
        }
        await _moveFrogTo('carrito_coqui');
      }
      await wait(160);
    }),
    'sirve93': (o) => _run(o, () async {
      final que = (o['que'] as String?) ?? 'flan';
      final a = (o['a'] as String?) ?? 'luis';
      final ok = _n(o['ok']) == 1;
      if (_GUESTS.contains(a)) _ensureOtraMesaGuest(a);
      final target = _gente[a] as Map<String, dynamic>?;
      final suf = W['carritoEn'] == 'otra_mesa' ? '2' : '';

      if (que == 'nada') {
        W['tapaDown'] = 1;
        await wait(240);
      } else if (que == 'mantecado') {
        W['mantScooped'] = 1;
        final src = _p.at('mantecado$suf');
        final dst = target != null ? _atOf(target) : src;
        W['sirveFx'] = {
          'kind': 'mantecado',
          'x': _round((src.sx + dst.sx) / 2),
          'y': _round((src.sy + dst.sy) / 2) - 10,
        };
        await wait(240);
        W['sirveFx'] = null;
        W['mantScooped'] = 0;
      } else {
        // flan
        W['flanWobble'] = 1;
        final src = _p.at('flanes$suf');
        final dst = target != null ? _atOf(target) : src;
        W['sirveFx'] = {
          'kind': 'flan',
          'x': _round((src.sx + dst.sx) / 2),
          'y': _round((src.sy + dst.sy) / 2) - 10,
        };
        await wait(240);
        W['sirveFx'] = null;
        W['flanWobble'] = 0;
      }

      if (target != null) {
        if (ok) {
          for (final dy in const [1, 0, 1, 0]) {
            target['dy'] = dy;
            await wait(55);
          }
          target['dy'] = 0;
        } else {
          target['pose'] = 'mano';
          await wait(220);
          target['pose'] = 'idle';
        }
      }
      // Swing cover back up at act's end so flanes/mantecado/tapa stay unobstructed and touchable.
      W['tapaDown'] = 0;
    }),
    'copa': (o) => _run(o, () async {
      W['copa'] = _n(o['n']).clamp(0, 3);
      await wait(120);
    }),
    'final93': (o) => _run(o, () async {
      final n = _n(o['n']).clamp(1, 3);
      W['copa'] = n;
      W['final93'] = n;
      W['copaPool'] = n == 3 ? 0 : (n == 2 ? 1 : 2);
      W['tapaDown'] = 0;
      W['sirveFx'] = null;
      await wait(360);
    }),

    /* ----- Story 94 acts ----- */
    'lleva94': (o) => _run(o, () async {
      W['cuentaVis'] = 1;
      W['cuentaEn'] = 'abuelo';
      await wait(240);
    }),
    'cuenta94': (o) => _run(o, () async {
      W['cuentaVis'] = 1;
      W['cuentaNum'] = _n(o['n']) > 0 ? _n(o['n']) : 40;
      W['cuentaEn'] = 'grande';
      await wait(260);
    }),
    'menta94': (o) => _run(o, () async {
      final mb = _p.box('mentas');
      W['payFx'] = {'kind': 'menta', 'x': mb[0] + 4, 'y': mb[1] - 4};
      await wait(150);
      final q = W['cq'] as Map<String, dynamic>;
      final fp = _frogPoint(q);
      W['payFx'] = {
        'kind': 'menta',
        'x': _round(fp.sx),
        'y': _round(fp.sy) - 18,
      };
      await wait(150);
      W['payFx'] = null;
    }),
    'cobra94': (o) => _run(o, () async {
      final como = (o['como'] as String?) ?? 'tarjeta';
      final ok = _n(o['ok']) == 1;
      if (como == 'tarjeta') {
        final ma = _p.at('maquina');
        W['maquinaBeep'] = 1;
        W['payFx'] = {
          'kind': 'tarjeta',
          'x': _round(ma.sx),
          'y': _round(ma.sy) - 14,
        };
        await wait(240);
        W['payFx'] = null;
        W['maquinaBeep'] = 0;
      } else {
        // efectivo
        W['gavetaAbierta'] = 1;
        final gb = _p.box('gaveta');
        W['payFx'] = {
          'kind': 'billetes',
          'x': gb[0] + gb[2] ~/ 2,
          'y': gb[1] + gb[3] + 3,
        };
        await wait(240);
        W['payFx'] = null;
        if (ok) W['gavetaBills'] = 1;
      }
      if (!ok) {
        // Brief frown / head shake from whoever stands at paga
        for (final en in _gente.entries) {
          final m = en.value as Map<String, dynamic>;
          if (m['vis'] != 0 && m['spot'] == 'paga') {
            for (final dx in const [-1, 1, -1, 0]) {
              m['dx'] = dx;
              await wait(55);
            }
            m['dx'] = 0;
          }
        }
      }
    }),
    'moneda94': (o) => _run(o, () async {
      final quien = (o['quien'] as String?) ?? 'abuelo';
      final mete = _n(o['mete']) == 1;
      final fa = _p.at('frasco');
      final p = _gente[quien] as Map<String, dynamic>?;
      final pa = p != null && p['vis'] != 0 ? _atOf(p) : _p.at('paga');
      if (mete) {
        W['payFx'] = {
          'kind': 'moneda',
          'x': _round(pa.sx) - 10,
          'y': _round(pa.sy) - 24,
        };
        await wait(110);
        W['payFx'] = {
          'kind': 'moneda',
          'x': _round(fa.sx),
          'y': _round(fa.sy) - 16,
        };
        await wait(130);
        W['payFx'] = null;
      } else {
        W['payFx'] = {
          'kind': 'moneda',
          'x': _round(pa.sx) - 8,
          'y': _round(pa.sy) - 20,
        };
        await wait(160);
        W['payFx'] = null;
      }
    }),
    'frasco': (o) => _run(o, () async {
      W['frascoVis'] = 1;
      W['frasco'] = _n(o['n']).clamp(0, 3);
      W['frascoTipped'] = 0;
      await wait(120);
    }),
    'final94': (o) => _run(o, () async {
      final n = _n(o['n']).clamp(1, 3);
      W['frascoVis'] = 1;
      W['frasco'] = n;
      W['frascoTipped'] = 1;
      W['final94'] = n;
      await wait(360);
    }),
    'cierra94': (o) => _run(o, () async {
      W['gavetaAbierta'] = 0;
      W['gavetaBills'] = 0;
      await wait(200);
    }),

    /* ----- Story 95 acts ----- */
    'paga95': (o) => _run(o, () async {
      final quien = (o['quien'] as String?) ?? 'abuelo';
      final que = (o['que'] as String?) ?? 'cuenta';
      final gb = _p.box('gaveta');
      final fa = _p.at('frasco');
      W['payFx'] = {
        'kind': 'billetes',
        'x': que == 'propina' ? _round(fa.sx) : gb[0] + gb[2] ~/ 2,
        'y': que == 'propina' ? _round(fa.sy) - 16 : gb[1] + gb[3] + 4,
      };
      await wait(220);
      W['payFx'] = null;
      if (quien == 'abuela' && que == 'propina') {
        // Story 95 beat 2: abuela's bills go into the jar too (no separate guarda95 issued).
        W['frascoBills'] = (_n(W['frascoBills']) + 1).clamp(0, 2);
      }
    }),
    'guarda95': (o) => _run(o, () async {
      final donde = (o['donde'] as String?) ?? 'gaveta';
      final ok = _n(o['ok']) == 1;
      final gb = _p.box('gaveta');
      final fa = _p.at('frasco');
      if (ok) {
        if (donde == 'gaveta') {
          W['gavetaAbierta'] = 1;
          W['payFx'] = {
            'kind': 'billetes',
            'x': gb[0] + gb[2] ~/ 2,
            'y': gb[1] + gb[3] + 3,
          };
          await wait(180);
          W['gavetaBills'] = 1;
          W['payFx'] = null;
        } else {
          W['payFx'] = {
            'kind': 'billetes',
            'x': _round(fa.sx),
            'y': _round(fa.sy) - 16,
          };
          await wait(180);
          W['frascoBills'] = (_n(W['frascoBills']) + 1).clamp(0, 2);
          W['payFx'] = null;
        }
      } else {
        // Wrong place briefly, then fishes them out and puts them in the right place.
        if (donde == 'gaveta') {
          W['gavetaAbierta'] = 1;
          W['payFx'] = {
            'kind': 'billetes',
            'x': gb[0] + gb[2] ~/ 2,
            'y': gb[1] + gb[3] + 3,
          };
          await wait(160);
          W['payFx'] = {
            'kind': 'billetes',
            'x': _round(fa.sx),
            'y': _round(fa.sy) - 16,
          };
          await wait(160);
          W['frascoBills'] = (_n(W['frascoBills']) + 1).clamp(0, 2);
          W['payFx'] = null;
        } else {
          W['payFx'] = {
            'kind': 'billetes',
            'x': _round(fa.sx),
            'y': _round(fa.sy) - 16,
          };
          await wait(160);
          W['gavetaAbierta'] = 1;
          W['payFx'] = {
            'kind': 'billetes',
            'x': gb[0] + gb[2] ~/ 2,
            'y': gb[1] + gb[3] + 3,
          };
          await wait(160);
          W['gavetaBills'] = 1;
          W['payFx'] = null;
        }
      }
    }),
    'sillas95': (o) => _run(o, () async {
      W['sillaManoFx'] = 1;
      await wait(200);
      W['sillas'] = 'arriba';
      await wait(160);
      W['sillaManoFx'] = 0;
    }),
    'guagua': (o) => _run(o, () async {
      final n = o['n'];
      if (n is String && const ['no', 'lejos', 'medio', 'cerca'].contains(n)) {
        W['guagua'] = n;
      }
      await wait(180);
    }),
    'final95': (o) => _run(o, () async {
      final n = _n(o['n']).clamp(1, 3);
      W['final95'] = n;
      W['gavetaAbierta'] = 0;
      // Outcome-dependent pace (cuenta.md story 95 step 9):
      // n=3: guagua still far -> family walks calmly, bus arrives, seats for everyone + stars/heart;
      // n=2: middle lamp -> family walks fast and boards;
      // n=1: already at the stop -> family runs, abuelo holds his hat, jumps on, door shuts behind frog.
      final stepMs = n == 3 ? 130 : (n == 2 ? 80 : 45);
      final strideDy = n == 3 ? -1 : (n == 2 ? -2 : -4);
      final exitPt = _p.at('sale');
      // Slightly outside the open doorway (v = -0.35 -> depth toward the street bus)
      final outPt = _p.fromScreen(_round(exitPt.sx), _round(exitPt.sy) - 10, 0);

      if (n == 1) {
        // Bus is already waiting at the stop with its door open; abuelo holds his hat as they run.
        W['guagua'] = 'cerca';
        W['guaguaDoor'] = 'open';
        final abo = _gente['abuelo'];
        if (abo is Map<String, dynamic> && abo['vis'] != 0) {
          abo['pose'] = 'yo';
        }
      } else if (n == 2) {
        W['guagua'] = 'medio';
        W['guaguaDoor'] = 'open';
      } else {
        W['guaguaDoor'] = 'open';
      }

      // Family heads out through the doorway toward the stop in order (abuela, abuelo, luis, carmen)
      for (final who in const ['abuela', 'abuelo', 'luis', 'carmen']) {
        final p = _gente[who];
        if (p is! Map<String, dynamic> || p['vis'] == 0) continue;
        final sx = (p['x'] as num).toDouble();
        final sy = (p['y'] as num).toDouble();
        final steps = n == 3 ? 3 : 2;
        for (var i = 1; i <= steps; i++) {
          final t = i / steps;
          p['x'] = sx + (outPt.x - sx) * t;
          p['y'] = sy + (outPt.y - sy) * t;
          p['z'] = 0.0;
          p['dy'] = i.isOdd ? strideDy : 0;
          await wait(stepMs);
        }
        p['dy'] = 0;
        p['pose'] = 'idle';
        p['vis'] = 0;
      }

      // For n=3 and n=2 the guagua pulls right up to the stop as they reach it.
      W['guagua'] = 'cerca';

      // Coquí hops out through the doorway and jumps aboard right behind the family.
      final q = W['cq'] as Map<String, dynamic>?;
      if (q != null && jsTruthy(q['vis'])) {
        final qsx = (q['x'] as num).toDouble();
        final qsy = (q['y'] as num).toDouble();
        final dest = _frogAt(outPt);
        final hops = n == 3 ? 3 : 2;
        for (var i = 1; i <= hops; i++) {
          final t = i / hops;
          q['x'] = _round(qsx + (dest[0] - qsx) * t);
          q['y'] = _round(qsy + (dest[1] - qsy) * t);
          q['dy'] = n == 1 ? -6 : -4;
          await wait(stepMs);
        }
        q['dy'] = 0;
        q['vis'] = 0;
      }

      // The guagua door shuts behind the frog as the staff wave from inside.
      W['guaguaDoor'] = 'shut';
      await wait(n == 3 ? 200 : 120);
    }),

    /* ----- Shared gestures & engine acts ----- */
    'gesto': (o) => _run(o, () async {
      final quien = (o['quien'] as String?) ?? 'mesera';
      final que = (o['que'] as String?) ?? 'saluda';
      if (_GUESTS.contains(quien)) _ensureOtraMesaGuest(quien);
      final p = _gente[quien] as Map<String, dynamic>?;
      if (p == null || p['vis'] == 0) return;
      if (que == 'saluda') {
        for (var i = 0; i < 4; i++) {
          p['pose'] = i % 2 == 0 ? 'saluda0' : 'saluda1';
          await wait(80);
        }
        p['pose'] = 'idle';
      } else if (que == 'no') {
        for (final dx in const [-1, 1, -1, 0]) {
          p['dx'] = dx;
          await wait(65);
        }
        p['dx'] = 0;
      } else if (que == 'si') {
        for (final dy in const [1, 0, 1, 0]) {
          p['dy'] = dy;
          await wait(65);
        }
        p['dy'] = 0;
      } else if (que == 'agita') {
        p['pose'] = 'agita';
        for (final dx in const [-1, 1, -1, 0]) {
          p['dx'] = dx;
          await wait(65);
        }
        p['dx'] = 0;
        p['pose'] = 'idle';
      } else if (que == 'reverencia') {
        p['pose'] = 'reverencia';
        for (final dy in const [1, 2, 1, 0]) {
          p['dy'] = dy;
          await wait(70);
        }
        p['dy'] = 0;
        p['pose'] = 'idle';
      } else {
        // rie, mira, senala, barriga, mano
        p['pose'] = que;
        await wait(240);
        p['pose'] = 'idle';
      }
    }),
    'marca': (o) async {
      final m = W['marcas'];
      if (m is List) {
        final i = m.indexOf(null);
        if (i >= 0) m[i] = o['que'];
      }
      await wait(120);
    },
    'fin': (o) async {
      final q = W['cq'] as Map<String, dynamic>;
      for (final dy in const [-4, -6, -3, 0]) {
        q['dy'] = dy;
        await wait(50);
      }
      await wait(200);
    },
  };
}
