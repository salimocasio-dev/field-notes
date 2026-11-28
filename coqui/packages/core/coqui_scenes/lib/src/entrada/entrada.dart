// La entrada (place 8, La fonda, scene 1: `entrada`; stories 84 to 86): a NEW scene, written from its script's
// "Needs" list (historia/notas/guiones/entrada.md) on its set (entrada_set.dart) and its sheet (entrada-sheet.json,
// read by SceneSheet). There is no old scene file: every act is this file's, each doing on screen what the Needs
// list says, every place from the sheet (spots, set thing boxes, table cloths, depth rule, shadows).
// Where the sheet names no place or an act is unstated in the script, the code does the plainest thing that keeps
// the story playing and marks it `OPEN:`.
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
        if (en.value.world != null) en.key: _frogAt(_spotAt(en.key)),
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

  /// Resolves a spot's projection; nudges `mesa1_coqui` on table 1's top so it satisfies `sprites-apart` with
  /// `mesa1_a..c` (just as `entrada-sheet.json` nudged `mesa2_coqui` and `mesa3_coqui`).
  EntradaAt _spotAt(String spot) {
    if (spot == 'mesa1_coqui') {
      // OPEN: entrada-sheet.json puts mesa1_coqui at (1.3, 3.35, 0.74) -> (154, 93), only 10 px below mesa1_a/b (83)
      // and 27 px right of mesa1_c (127); nudge to (1.33, 3.50, 0.74) -> (155, 95) (still on table 1 top v 2.3..3.5)
      // matching how entrada-sheet.json moved mesa3_coqui for sprites-apart (12 px down, 28 px across).
      return _p.atUv(1.33, 3.50, 0.74);
    }
    return _p.at(spot);
  }

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
    final startAt = _spotAt(startSpot);
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
      final at = _spotAt(spot);
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
    Map<String, dynamic> w,
    bool open,
  ) {
    final pose = (p['pose'] as String?) ?? 'idle';
    final sent = _n(p['sent']) == 1;
    final story = _n(w['story']);
    if (id == 'abuela') {
      if (sent) {
        final abPose = switch (pose) {
          'saluda0' || 'saluda1' || 'mano' => 'saluda0',
          'senala' => 'tu',
          'rie' => 'yo',
          _ => 'idle',
        };
        final s = _spr(
          'en_abS_${abPose}_$open',
          () => mkAbuelaS(abPose, open, false),
        );
        return (s: s, ax: 17, ay: 36);
      }
      final abPose = switch (pose) {
        'saluda0' || 'saluda1' || 'pasa' => 'saluda0',
        'senala' => 'tu',
        'rie' => 'yo',
        _ => 'idle',
      };
      final s = _spr('en_ab_${abPose}_$open', () => mkAbuela(abPose, open));
      return (s: s, ax: 30, ay: inkBottom(s));
    }

    final Who who;
    final String variant;
    if (id == 'mesera') {
      final pad = story == 86;
      who = mkMeseraWho(pad: pad);
      variant = pad ? 'pad' : 'std';
    } else if (id == 'mesero') {
      final is85 = story == 85;
      final bowtie = _n(w['meseroCorbata']) != 0;
      final bandage = is85;
      final cane = is85;
      who = mkMeseroWho(bowtie: bowtie, bandage: bandage, cane: cane);
      variant = '${bowtie ? 1 : 0}_${bandage ? 1 : 0}_${cane ? 1 : 0}';
    } else {
      who = ENTRADA_PEOPLE[id] ?? ENTRADA_PEOPLE['vecino']!;
      variant = 'std';
    }

    final kp = switch (pose) {
      'saluda0' || 'pasa' => 'wave0',
      'saluda1' => 'wave1',
      'senala' || 'baston' => 'tu',
      'rie' || 'reverencia' => 'yo',
      'mano' || 'lista' => 'offer',
      _ => 'idle',
    };
    final s = _spr(
      'en_${id}_${variant}_${kp}_${open}_$sent',
      () => mkPersona(who, kp, open, sent),
    );
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

  /// Every sprite of the frame [w] as it is placed, except the frog. The rules' tests read it; [draw] draws it.
  List<EntradaItem> items(Map<String, dynamic> w, int a) {
    final out = <EntradaItem>[];
    final talk = _talker();
    final gente = (w['gente'] as Map<String, dynamic>?) ?? const {};
    final anim = (F >> 2) + a;
    final story = _n(w['story']);

    // 1. Table cloths (story 85: mesa2 and mesa3)
    for (final (tableId, key) in const [
      ('mesa2', 'mantel2'),
      ('mesa3', 'mantel3'),
    ]) {
      final col = w[key] as String?;
      if (col == null) continue;
      final c = _p.cloth(tableId);
      final wBox = c.box[2], hBox = c.box[3];
      final s = _spr(
        'en_mantel_${tableId}_$col',
        () => mkMantel(wBox, hBox, c.topRows, col),
      );
      final at = _p.atUv(c.uv[0], c.uv[1], c.uv[2]);
      out.add(
        EntradaItem(s, c.box[0], c.box[1], c.screen[1], at.d, tag: 'cosa:$key'),
      );
    }

    // 2. Mesero's stool under taburete (story 85)
    if (_n(w['tabureteVis']) == 1) {
      final uv = _p.uv('taburete');
      final at = _p.atUv(uv[0], uv[1], uv[2] - 0.6);
      final s = _spr('en_taburete', mkTaburete);
      final sx = _round(at.sx), sy = _round(at.sy);
      out.add(EntradaItem(s, sx - 7, sy - s.h, sy, at.d, tag: 'cosa:taburete'));
    }

    // 3. People (and items held directly by a person)
    for (final en in gente.entries) {
      final p = en.value as Map<String, dynamic>;
      if (p['vis'] == 0) continue;
      final open = talk == en.key && a % 2 == 1;
      final sp = _personSprite(en.key, p, w, open);
      final at = _atOf(p);
      final sx = _round(at.sx) + _n(p['dx']);
      final sy = _round(at.sy) + _n(p['dy']);
      out.add(
        EntradaItem(
          sp.s,
          sx - sp.ax,
          sy - sp.ay,
          sy,
          at.d,
          tag: 'persona:${en.key}',
        ),
      );

      // Mesero carrying plates or full tray during story 84 crossing (`pasa84`)
      if (en.key == 'mesero' && w['meseroCarry'] != null) {
        final carry = w['meseroCarry'] as String;
        final atCarry = _p.atWorld(
          p['x'] as num,
          p['y'] as num,
          (p['z'] as num) + 0.8,
        );
        final cx = _round(atCarry.sx) + _n(p['dx']);
        final cy = _round(atCarry.sy) + _n(p['dy']);
        if (carry == 'platos') {
          final pl = _spr('en_platos', mkPlatos);
          out.add(
            EntradaItem(
              pl,
              cx - 8,
              cy - pl.h,
              cy,
              atCarry.d + .02,
              tag: 'fx:platos',
              held: 'mesero',
            ),
          );
        } else {
          // OPEN: full tray held by mesero during pasa84(que=bandeja), placed at z + 0.8 like platos.
          final bd = _spr('en_bandeja_llena', mkBandejaLlena);
          out.add(
            EntradaItem(
              bd,
              cx - 10,
              cy - bd.h,
              cy,
              atCarry.d + .02,
              tag: 'fx:bandeja_llena',
              held: 'mesero',
            ),
          );
        }
      }

      // Abuelo holding his hat in final84(n=1) when the kitchen swing door flaps
      if (en.key == 'abuelo' && _n(w['abueloSombrero']) == 1) {
        // OPEN: abuelo's hat held at chest/lap level (below his top 14 head rows so heads-clear holds).
        final hat = _spr('en_sombrero', mkSombrero);
        out.add(
          EntradaItem(
            hat,
            sx - 7,
            sy - 18,
            sy,
            at.d + .03,
            tag: 'fx:sombrero',
            held: 'abuelo',
          ),
        );
      }
    }

    // 4. Story 84 table 3 props: flowers & star card
    if (_n(w['floresVis']) == 1) {
      final atF = _p.at('flores');
      final sf = _spr('en_flores', mkFlores);
      final fx = _round(atF.sx), fy = _round(atF.sy);
      out.add(
        EntradaItem(sf, fx - 5, fy - sf.h, fy, atF.d, tag: 'cosa:flores'),
      );

      final atT = _p.at('tarjeta');
      final st = _spr('en_estrella', mkEstrella);
      final tx = _round(atT.sx), ty = _round(atT.sy);
      out.add(
        EntradaItem(st, tx - 4, ty - st.h, ty, atT.d, tag: 'cosa:tarjeta'),
      );
    }

    // 5. Story 85 saucer of sweets (`dulces`) on mesero's knee
    final dulcesN = _n(w['dulces']);
    if (story == 85 && dulcesN >= 0) {
      final at = _p.at('dulces');
      final s = _spr('en_dulces_$dulcesN', () => mkDulces(dulcesN));
      final sx = _round(at.sx), sy = _round(at.sy);
      out.add(
        EntradaItem(
          s,
          sx - 6,
          sy - s.h,
          sy,
          at.d + .05,
          tag: 'cosa:dulces',
          held: 'mesero',
        ),
      );
    }

    // 6. Story 86 props: menu, three candles, mesero's tray & cosa_a / cosa_b, coffees, vasito, panera
    if (_n(w['menuVis']) == 1) {
      final open = _n(w['menuOpen']) == 1;
      final nearFlame = _n(w['menuCloseToFlame']) == 1;
      final at = _p.at('menu');
      final s = _spr('en_menu_$open', () => mkMenu(open: open));
      // OPEN: in final86(n=1), abuelo holds the menu closer to the remaining candle flame (still below heads & behind frog).
      final sx = _round(at.sx) + (nearFlame ? 16 : 0);
      final sy = _round(at.sy);
      out.add(
        EntradaItem(
          s,
          sx - 7,
          sy - s.h,
          sy,
          at.d + .05,
          tag: 'cosa:menu',
          held: nearFlame ? 'abuelo' : 'abuela',
        ),
      );
    }

    if (story == 86) {
      final velasN = _n(w['velas']);
      final smoke = _n(w['velaSmoke']) == 1;
      final at = _p.at('velas');
      final sx = _round(at.sx), sy = _round(at.sy);
      const offs = [-7, 0, 7];
      for (var i = 0; i < 3; i++) {
        final lit = i < velasN;
        final s = _spr(
          'en_vela_${lit}_${!lit && smoke}',
          () => mkVela(lit: lit, smoke: !lit && smoke),
        );
        out.add(
          EntradaItem(
            s,
            sx + offs[i] - 3,
            sy - s.h,
            sy,
            at.d,
            tag: 'cosa:vela${i + 1}',
            held: 'velas',
          ),
        );
      }

      if (_n(w['cafesVis']) == 1) {
        // OPEN: coffees from cafes86 placed on table 2's far half (v=5.65, z=0.74, d=5.26 < coqui/velas) clear of heads & menu.
        final atAb = _p.atUv(0.95, 5.65, 0.74);
        final cBlack = _spr('en_cafe_negro', () => mkCafe(conLeche: false));
        final ax = _round(atAb.sx), ay = _round(atAb.sy);
        out.add(
          EntradaItem(
            cBlack,
            ax - 4,
            ay - cBlack.h,
            ay,
            atAb.d,
            tag: 'fx:cafe_abuela',
          ),
        );
        final atAbo = _p.atUv(2.05, 5.65, 0.74);
        final cMilk = _spr('en_cafe_leche', () => mkCafe(conLeche: true));
        final bx = _round(atAbo.sx), by = _round(atAbo.sy);
        out.add(
          EntradaItem(
            cMilk,
            bx - 4,
            by - cMilk.h,
            by,
            atAbo.d,
            tag: 'fx:cafe_abuelo',
          ),
        );
      }

      if (_n(w['vasitoVis']) == 1) {
        // OPEN: Coquí's small glass with lemon (vasito86) placed on table 2 between coqui (x<=166) and velas (x>=175).
        final atV = _p.atUv(1.96, 6.45, 0.74);
        final s = _spr('en_vasito', mkVasito);
        final vx = _round(atV.sx), vy = _round(atV.sy);
        out.add(EntradaItem(s, vx - 3, vy - s.h, vy, atV.d, tag: 'fx:vasito'));
      }

      if (_n(w['paneraVis']) == 1) {
        // OPEN: bread basket (final86) placed on table 2's far middle (u=1.75, v=5.55, z=0.74), clear of heads, coqui, velas.
        final atP = _p.atUv(1.75, 5.55, 0.74);
        final s = _spr('en_panera', mkPanera);
        final px = _round(atP.sx), py = _round(atP.sy);
        out.add(EntradaItem(s, px - 7, py - s.h, py, atP.d, tag: 'fx:panera'));
      }

      if (_n(w['trayVis']) == 1) {
        final buv = _p.uv('bandeja');
        final cuv = _p.uv('cosa_a');
        final atT = _p.atUv(buv[0], buv[1], cuv[2]);
        final st = _spr('en_bandejaT', mkBandejaT);
        final tx = _round(atT.sx), ty = _round(atT.sy);
        out.add(
          EntradaItem(
            st,
            tx - 15,
            ty,
            ty,
            atT.d + .02,
            tag: 'cosa:bandeja_t',
            held: 'mesero',
          ),
        );

        final que = (w['trayQue'] as String?) ?? 'agua';
        final izqCon = w['trayIzq'] != 'sin';
        if (_n(w['cosaAVis']) == 1) {
          final atA = _p.at('cosa_a');
          final sa = que == 'pan'
              ? _spr('en_pan_$izqCon', () => mkCosaPan(con: izqCon))
              : _spr('en_agua_$izqCon', () => mkCosaAgua(con: izqCon));
          final ax = _round(atA.sx), ay = _round(atA.sy);
          out.add(
            EntradaItem(
              sa,
              ax - 5,
              ay - sa.h,
              ay,
              atA.d + .02,
              tag: 'cosa:cosa_a',
              held: 'mesero',
            ),
          );
        }
        if (_n(w['cosaBVis']) == 1) {
          final atB = _p.at('cosa_b');
          final bCon = !izqCon;
          final sb = que == 'pan'
              ? _spr('en_pan_$bCon', () => mkCosaPan(con: bCon))
              : _spr('en_agua_$bCon', () => mkCosaAgua(con: bCon));
          final bx = _round(atB.sx), by = _round(atB.sy);
          out.add(
            EntradaItem(
              sb,
              bx - 5,
              by - sb.h,
              by,
              atB.d + .02,
              tag: 'cosa:cosa_b',
              held: 'mesero',
            ),
          );
        }
      }

      if (_n(w['splashFx']) == 1) {
        final at = _p.at('velas');
        final sp = _spr('en_splash_${anim % 2}', () => mkSalpicadura(anim % 2));
        out.add(
          EntradaItem(
            sp,
            _round(at.sx) - 6,
            _round(at.sy) - 18,
            _round(at.sy),
            at.d + .04,
            tag: 'fx:splash',
          ),
        );
      }
    }

    // 7. Music notes from vellonera (final85) & celebration heart (3-of-3 endings)
    if (_n(w['musicaFx']) == 1) {
      // OPEN: music notes floating above vellonera [123,33,20,40] in final85, clear of all heads.
      final nt = _spr('en_notas_${anim % 2}', () => mkNotasMusica(anim % 2));
      out.add(
        EntradaItem(nt, 126, 20, 20, 5.0, tag: 'fx:musica', overlay: true),
      );
    }

    if (_n(w['final84']) == 3 ||
        _n(w['final85']) == 3 ||
        _n(w['final86']) == 3) {
      // OPEN: 3-of-3 celebration heart placed high above the room at (161, 22), clear of every character head.
      final cor = _spr('en_corazon', mkCorazon);
      out.add(
        EntradaItem(cor, 161, 22, 22, 5.0, tag: 'fx:corazon', overlay: true),
      );
    }

    return out;
  }

  static final Map<String, Sprite> _frogSprites = {};

  /// [items] plus the frog (and frog's bow tie in story 85), for `draw` and for `EntradaRules`.
  List<EntradaItem> placed(Map<String, dynamic> w, int a) {
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
      out.add(EntradaItem(spr, ox, oy, fsy, at.d, tag: 'coqui'));
      if (_n(w['coquiCorbata']) == 1) {
        final bt = _spr('en_corbata', mkCorbata);
        final cx = _round(at.sx) + dx;
        final cy = fsy + _n(q['dy']);
        out.add(
          EntradaItem(
            bt,
            cx - 4,
            cy - 11,
            fsy,
            at.d + .01,
            tag: 'fx:corbata',
            held: 'coqui',
          ),
        );
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

  /* ---------- helpers for movement & loose acts ---------- */

  final List<Future<void>> _loose = [];

  Future<void> _run(Map<String, dynamic> o, Future<void> Function() body) {
    if (jsTruthy(o['suelto'])) {
      final f = body();
      _loose.add(f);
      return Future<void>.value();
    }
    return body();
  }

  Future<void> _hopFrogTo(String spot) async {
    if (!_p.hasWorld(spot)) return;
    final at = _spotAt(spot);
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
        await wait(65);
      }
    }
    q['x'] = dest[0];
    q['y'] = dest[1];
    q['dy'] = 0;
    q['z'] = at.z;
    q['spot'] = spot;
  }

  Future<void> _walkPersonTo(
    String who,
    String spot, {
    int sent = 0,
    int steps = 4,
  }) async {
    if (!_p.hasWorld(spot)) return;
    final p = _gente[who] as Map<String, dynamic>?;
    if (p == null) return;
    final dest = _p.world(spot);
    if (p['vis'] == 0) {
      _placePerson(p, spot, vis: 1, sent: sent);
      await wait(60);
      return;
    }
    final x0 = (p['x'] as num).toDouble();
    final y0 = (p['y'] as num).toDouble();
    final z0 = (p['z'] as num).toDouble();
    p['sent'] = 0;
    for (var i = 1; i <= steps; i++) {
      final t = i / steps;
      p['x'] = x0 + (dest[0] - x0) * t;
      p['y'] = y0 + (dest[1] - y0) * t;
      p['z'] = z0 + (dest[2] - z0) * t;
      await wait(55);
    }
    _placePerson(p, spot, vis: 1, sent: sent);
  }

  Future<void> _crossMesero(String que) async {
    final mesero = _gente['mesero'] as Map<String, dynamic>?;
    if (mesero == null) return;
    W['meseroCarry'] = que;
    _placePerson(mesero, 'paso1', vis: 1);
    await wait(60);
    await _walkPersonTo('mesero', 'choque', steps: 3);
    await _walkPersonTo('mesero', 'paso2', steps: 3);
    mesero['vis'] = 0;
    W['meseroCarry'] = null;
  }

  Future<void> _seatWaitingPair84() async {
    // Seat whoever is currently waiting at cola1/cola2 at the best free table.
    // We use end chairs (mesa3_c/d or mesa2_c/d) so they never occlude mesa2_coqui or mesa1_coqui later.
    final senor = _gente['senor'] as Map<String, dynamic>?;
    final senora = _gente['senora'] as Map<String, dynamic>?;
    final hombre = _gente['hombre'] as Map<String, dynamic>?;
    final mujer = _gente['mujer'] as Map<String, dynamic>?;
    final senorWaiting =
        senor != null && senor['vis'] == 1 && senor['spot'] == 'cola1';
    if (senorWaiting && senora != null) {
      await Future.wait([
        _walkPersonTo('senor', 'mesa3_c', sent: 1, steps: 4),
        _walkPersonTo('senora', 'mesa3_d', sent: 1, steps: 4),
      ]);
      return;
    }
    if (hombre != null && mujer != null) {
      final targetA = senor != null && senor['spot'] == 'mesa3_c'
          ? 'mesa2_a'
          : 'mesa3_c';
      final targetB = targetA == 'mesa2_a' ? 'mesa2_b' : 'mesa3_d';
      await Future.wait([
        _walkPersonTo('hombre', targetA, sent: 1, steps: 4),
        _walkPersonTo('mujer', targetB, sent: 1, steps: 4),
      ]);
    }
  }

  @override
  List<num> remap(List<num> xy) => xy;

  @override
  Future<void> stake(int lost, int max, String en) async {}

  /* ---------- acts (entrada.md "Needs" + gen_entrada.py) ---------- */

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
      final spot = (o['a'] as String?) ?? 'felpudo';
      // OPEN: gen_entrada.py step 4 calls `ir(a=felpudo)` immediately before `juntos(llega(familia, puerta1..4))`.
      // Because felpudo (46, 128) shares row 128 with atril3 (34, 128) and atril4 (58, 128), walk the family back
      // to puerta1..4 alongside the frog so sprites-apart holds after `ir` as well as after `ya`.
      if (_n(W['story']) == 84 &&
          spot == 'felpudo' &&
          (_gente['luis'] as Map?)?['spot'] == 'atril3') {
        await Future.wait([
          _hopFrogTo(spot),
          _walkPersonTo('abuela', 'puerta1', steps: 3),
          _walkPersonTo('abuelo', 'puerta2', steps: 3),
          _walkPersonTo('luis', 'puerta3', steps: 3),
          _walkPersonTo('carmen', 'puerta4', steps: 3),
        ]);
        return;
      }
      await _hopFrogTo(spot);
    }),
    'llega': (o) => _run(o, () async {
      final quien = o['quien'] as String?;
      final a = o['a'] as String?;
      if (quien == null || a == null || !_p.hasWorld(a)) return;
      final p = _gente[quien] as Map<String, dynamic>?;
      if (p == null) return;
      final sent =
          a.startsWith('banco') || a.contains('_') && a.startsWith('mesa')
          ? 1
          : 0;
      if (_n(W['story']) == 85 && a == 'ante_cuerda1') {
        final comp = _companionOf(quien);
        final cp = _gente[comp] as Map<String, dynamic>?;
        // Clear any previous couple waiting at ante_cuerda1/2 so spots never collide
        for (final en in _gente.entries) {
          if (en.key == quien || en.key == comp) continue;
          final other = en.value as Map<String, dynamic>;
          if (other['vis'] == 1 &&
              (other['spot'] == 'ante_cuerda1' ||
                  other['spot'] == 'ante_cuerda2')) {
            other['vis'] = 0;
          }
        }
        await Future.wait([
          _walkPersonTo(quien, 'ante_cuerda1', steps: 3),
          if (cp != null) _walkPersonTo(comp, 'ante_cuerda2', steps: 3),
        ]);
        return;
      }
      await _walkPersonTo(quien, a, sent: sent, steps: 3);
    }),
    'sale': (o) => _run(o, () async {
      final quien = o['quien'] as String?;
      if (quien == null) return;
      final p = _gente[quien] as Map<String, dynamic>?;
      if (p != null) p['vis'] = 0;
      await wait(60);
    }),
    'gesto': (o) => _run(o, () async {
      final quien = (o['quien'] as String?) ?? 'mesera';
      final que = (o['que'] as String?) ?? 'saluda';
      final p = _gente[quien] as Map<String, dynamic>?;
      if (p == null) return;
      if (que == 'saluda' || que == 'pasa') {
        for (var i = 0; i < 4; i++) {
          p['pose'] = i % 2 == 0 ? 'saluda0' : 'saluda1';
          await wait(70);
        }
        p['pose'] = 'idle';
      } else if (que == 'no') {
        for (final dx in const [-1, 1, -1, 0]) {
          p['dx'] = dx;
          await wait(60);
        }
        p['dx'] = 0;
      } else if (que == 'si' || que == 'reverencia') {
        p['pose'] = que == 'reverencia' ? 'reverencia' : 'idle';
        for (final dy in const [1, 2, 1, 0]) {
          p['dy'] = dy;
          await wait(60);
        }
        p['dy'] = 0;
        p['pose'] = 'idle';
      } else {
        // rie, mira, senala, mano, lista, baston
        p['pose'] = que;
        await wait(180);
        p['pose'] = 'idle';
      }
    }),

    /* ---------- Story 84 acts ---------- */
    'mesas84': (o) => _run(o, () async {
      W['mesas84'] = _n(o['n']).clamp(1, 3);
      W['floresVis'] = 1;
      await wait(100);
    }),
    'pasa84': (o) => _run(o, () async {
      final que = (o['que'] as String?) ?? 'platos';
      await _crossMesero(que);
    }),
    'avanza84': (o) => _run(o, () async {
      final tramo = (o['tramo'] as String?) ?? 'a';
      final ok = _n(o['ok']) == 1;
      if (ok) {
        if (tramo == 'a') {
          await Future.wait([
            _hopFrogTo('ante_atril'),
            _walkPersonTo('abuela', 'atril1', steps: 3),
            _walkPersonTo('abuelo', 'atril2', steps: 3),
            _walkPersonTo('luis', 'atril3', steps: 3),
            _walkPersonTo('carmen', 'atril4', steps: 3),
          ]);
        } else {
          final mesera = _gente['mesera'] as Map<String, dynamic>?;
          if (mesera != null) mesera['pose'] = 'pasa';
          W['cuerda'] = 'abierta';
          await _hopFrogTo('ante_atril');
          await wait(120);
          if (mesera != null) mesera['pose'] = 'idle';
        }
      } else {
        // Frog hopped forward when told to wait: bumps into mesero's tray, pair behind gets best free table
        await _hopFrogTo('ante_atril');
        await _crossMesero('bandeja');
        await _seatWaitingPair84();
        await _hopFrogTo(tramo == 'a' ? 'felpudo' : 'ante_atril');
      }
    }),
    'espera84': (o) => _run(o, () async {
      final tramo = (o['tramo'] as String?) ?? 'a';
      final ok = _n(o['ok']) == 1;
      await _hopFrogTo('banco_coqui');
      if (ok) {
        await _crossMesero('bandeja');
        final mesera = _gente['mesera'] as Map<String, dynamic>?;
        if (mesera != null) mesera['pose'] = 'pasa';
        await wait(100);
        if (mesera != null) mesera['pose'] = 'idle';
        if (tramo == 'a') {
          await Future.wait([
            _hopFrogTo('ante_atril'),
            _walkPersonTo('abuela', 'atril1', steps: 3),
            _walkPersonTo('abuelo', 'atril2', steps: 3),
            _walkPersonTo('luis', 'atril3', steps: 3),
            _walkPersonTo('carmen', 'atril4', steps: 3),
          ]);
        } else {
          W['cuerda'] = 'abierta';
          await _hopFrogTo('ante_atril');
        }
      } else {
        // Frog sat on bench when called forward: pair behind walks past to best free table
        await _seatWaitingPair84();
      }
    }),
    'final84': (o) => _run(o, () async {
      final n = _n(o['n']).clamp(1, 3);
      W['cuerda'] = 'abierta';
      W['mesas84'] = n;
      W['final84'] = n;
      W['meseroCarry'] = null;
      (_gente['mesero'] as Map<String, dynamic>?)?['vis'] = 0;
      if (n == 3) {
        // Matches preview moment 4: family at mesa3, senor/senora at mesa2_a/b, mesera at mesera_fin
        _placePerson(
          _gente['senor'] as Map<String, dynamic>,
          'mesa2_a',
          sent: 1,
        );
        _placePerson(
          _gente['senora'] as Map<String, dynamic>,
          'mesa2_b',
          sent: 1,
        );
        (_gente['hombre'] as Map<String, dynamic>)['vis'] = 0;
        (_gente['mujer'] as Map<String, dynamic>)['vis'] = 0;
        _placePerson(
          _gente['abuela'] as Map<String, dynamic>,
          'mesa3_a',
          sent: 1,
        );
        _placePerson(
          _gente['abuelo'] as Map<String, dynamic>,
          'mesa3_b',
          sent: 1,
        );
        _placePerson(
          _gente['luis'] as Map<String, dynamic>,
          'mesa3_c',
          sent: 1,
        );
        _placePerson(
          _gente['carmen'] as Map<String, dynamic>,
          'mesa3_d',
          sent: 1,
        );
        _placePerson(_gente['mesera'] as Map<String, dynamic>, 'mesera_fin');
        W['abueloSombrero'] = 0;
        await _hopFrogTo('mesa3_coqui');
      } else if (n == 2) {
        // Family at mesa2; senor/senora at mesa3_c/d (keeps mesa2_coqui 100% clear); mesera at junto_mesa
        _placePerson(
          _gente['senor'] as Map<String, dynamic>,
          'mesa3_c',
          sent: 1,
        );
        _placePerson(
          _gente['senora'] as Map<String, dynamic>,
          'mesa3_d',
          sent: 1,
        );
        (_gente['hombre'] as Map<String, dynamic>)['vis'] = 0;
        (_gente['mujer'] as Map<String, dynamic>)['vis'] = 0;
        _placePerson(
          _gente['abuela'] as Map<String, dynamic>,
          'mesa2_a',
          sent: 1,
        );
        _placePerson(
          _gente['abuelo'] as Map<String, dynamic>,
          'mesa2_b',
          sent: 1,
        );
        _placePerson(
          _gente['luis'] as Map<String, dynamic>,
          'mesa2_c',
          sent: 1,
        );
        _placePerson(
          _gente['carmen'] as Map<String, dynamic>,
          'mesa2_d',
          sent: 1,
        );
        _placePerson(_gente['mesera'] as Map<String, dynamic>, 'junto_mesa');
        W['abueloSombrero'] = 0;
        await _hopFrogTo('mesa2_coqui');
      } else {
        // Family at mesa1 (by kitchen door); hombre/mujer at mesa2_c/d (keeps mesa1_coqui clear); senor/senora at mesa3_c/d
        _placePerson(
          _gente['senor'] as Map<String, dynamic>,
          'mesa3_c',
          sent: 1,
        );
        _placePerson(
          _gente['senora'] as Map<String, dynamic>,
          'mesa3_d',
          sent: 1,
        );
        _placePerson(
          _gente['hombre'] as Map<String, dynamic>,
          'mesa2_c',
          sent: 1,
        );
        _placePerson(
          _gente['mujer'] as Map<String, dynamic>,
          'mesa2_d',
          sent: 1,
        );
        _placePerson(
          _gente['abuela'] as Map<String, dynamic>,
          'mesa1_a',
          sent: 1,
        );
        _placePerson(
          _gente['abuelo'] as Map<String, dynamic>,
          'mesa1_b',
          sent: 1,
        );
        _placePerson(
          _gente['luis'] as Map<String, dynamic>,
          'mesa1_c',
          sent: 1,
        );
        _placePerson(
          _gente['carmen'] as Map<String, dynamic>,
          'mesa1_d',
          sent: 1,
        );
        _placePerson(_gente['mesera'] as Map<String, dynamic>, 'junto_mesa');
        W['abueloSombrero'] = 1;
        await _hopFrogTo('mesa1_coqui');
      }
      await wait(160);
    }),

    /* ---------- Story 85 acts ---------- */
    'dulces': (o) => _run(o, () async {
      W['dulces'] = _n(o['n']).clamp(0, 3);
      await wait(100);
    }),
    'manteles': (o) => _run(o, () async {
      final a = o['a'] as String?;
      final b = o['b'] as String?;
      if (a != null) W['mantel2'] = a;
      if (b != null) W['mantel3'] = b;
      await wait(120);
    }),
    'corbata85': (o) => _run(o, () async {
      W['meseroCorbata'] = 0;
      await wait(120);
      W['coquiCorbata'] = 1;
      await wait(140);
    }),
    'sienta85': (o) => _run(o, () async {
      final quienes = (o['quienes'] as String?) ?? 'senora';
      final comp = _companionOf(quienes);
      final mesa = (o['mesa'] as String?) ?? 'mesa2';
      final otherMesa = mesa == 'mesa2' ? 'mesa3' : 'mesa2';
      final ok = _n(o['ok']) == 1;
      final qP = _gente[quienes] as Map<String, dynamic>?;
      final cP = _gente[comp] as Map<String, dynamic>?;
      if (ok) {
        await Future.wait([
          if (qP != null)
            _walkPersonTo(quienes, '${mesa}_a', sent: 1, steps: 3),
          if (cP != null) _walkPersonTo(comp, '${mesa}_b', sent: 1, steps: 3),
        ]);
        final mesero = _gente['mesero'] as Map<String, dynamic>?;
        if (mesero != null) {
          mesero['dy'] = 1;
          await wait(70);
          mesero['dy'] = 0;
        }
        await _hopFrogTo('taburete_coqui');
      } else {
        // Couple sits at taken table; vellonera pair returns; couple gets up, takes sweet, sits at other table.
        await Future.wait([
          if (qP != null)
            _walkPersonTo(quienes, '${mesa}_a', sent: 1, steps: 2),
          if (cP != null) _walkPersonTo(comp, '${mesa}_b', sent: 1, steps: 2),
        ]);
        await wait(120);
        await Future.wait([
          if (qP != null)
            _walkPersonTo(quienes, '${otherMesa}_a', sent: 1, steps: 3),
          if (cP != null)
            _walkPersonTo(comp, '${otherMesa}_b', sent: 1, steps: 3),
          _walkPersonTo('vecino', '${mesa}_a', sent: 1, steps: 3),
          _walkPersonTo('vecina', '${mesa}_b', sent: 1, steps: 3),
        ]);
        await _hopFrogTo('taburete_coqui');
      }
    }),
    'vuelven85': (o) => _run(o, () async {
      final mesa = (o['mesa'] as String?) ?? 'mesa3';
      await Future.wait([
        _walkPersonTo('vecino', '${mesa}_a', sent: 1, steps: 3),
        _walkPersonTo('vecina', '${mesa}_b', sent: 1, steps: 3),
      ]);
      // In story 85 step 3, joven speaks right after vuelven85 before banco85; place joven + amigo at the rope.
      _placePerson(_gente['joven'] as Map<String, dynamic>, 'ante_cuerda1');
      _placePerson(_gente['amigo'] as Map<String, dynamic>, 'ante_cuerda2');
      await wait(80);
    }),
    'banco85': (o) => _run(o, () async {
      final quien = (o['quien'] as String?) ?? 'joven';
      final comp = _companionOf(quien);
      await Future.wait([
        _walkPersonTo(quien, 'banco1', sent: 1, steps: 3),
        _walkPersonTo(comp, 'banco2', sent: 1, steps: 3),
      ]);
    }),
    'tarde85': (o) => _run(o, () async {
      // Clear mesa2, mesa3, ante_cuerda1/2, and bench; restore vecino + vecina to vellonera1/2.
      for (final en in _gente.entries) {
        if (en.key == 'mesero' || en.key == 'vecino' || en.key == 'vecina') {
          continue;
        }
        (en.value as Map<String, dynamic>)['vis'] = 0;
      }
      _placePerson(_gente['vecino'] as Map<String, dynamic>, 'vellonera1');
      _placePerson(_gente['vecina'] as Map<String, dynamic>, 'vellonera2');
      await _hopFrogTo('taburete_coqui');
      await wait(120);
    }),
    'final85': (o) => _run(o, () async {
      final n = _n(o['n']).clamp(1, 3);
      W['dulces'] = n;
      W['final85'] = n;
      W['musicaFx'] = 1;
      // Every table is taken (distinct characters, nobody at vellonera1/2 so mesa1_a/b stay clear)
      _placePerson(
        _gente['vecino'] as Map<String, dynamic>,
        'mesa1_a',
        sent: 1,
      );
      _placePerson(
        _gente['vecina'] as Map<String, dynamic>,
        'mesa1_b',
        sent: 1,
      );
      _placePerson(
        _gente['hombre'] as Map<String, dynamic>,
        'mesa2_a',
        sent: 1,
      );
      _placePerson(_gente['mujer'] as Map<String, dynamic>, 'mesa2_b', sent: 1);
      _placePerson(_gente['senor'] as Map<String, dynamic>, 'mesa3_a', sent: 1);
      _placePerson(
        _gente['senora'] as Map<String, dynamic>,
        'mesa3_b',
        sent: 1,
      );
      _placePerson(_gente['joven'] as Map<String, dynamic>, 'banco1', sent: 1);
      _placePerson(_gente['amigo'] as Map<String, dynamic>, 'banco2', sent: 1);
      final mesero = _gente['mesero'] as Map<String, dynamic>;
      _placePerson(mesero, 'taburete', sent: 1);
      mesero['pose'] = 'mano';
      await _hopFrogTo('taburete_coqui');
      await wait(160);
      mesero['pose'] = 'idle';
    }),

    /* ---------- Story 86 acts ---------- */
    'velas': (o) => _run(o, () async {
      final prev = _n(W['velas']);
      final next = _n(o['n']).clamp(0, 3);
      W['velas'] = next;
      if (next < prev) {
        W['velaSmoke'] = 1;
        await wait(140);
        W['velaSmoke'] = 0;
      } else {
        await wait(100);
      }
    }),
    'menu86': (o) => _run(o, () async {
      final mesera = _gente['mesera'] as Map<String, dynamic>?;
      if (mesera != null) mesera['pose'] = 'mano';
      W['menuVis'] = 1;
      await wait(100);
      W['menuOpen'] = 1;
      if (mesera != null) mesera['pose'] = 'idle';
      await wait(120);
    }),
    'bandeja86': (o) => _run(o, () async {
      W['trayVis'] = 1;
      W['trayQue'] = (o['que'] as String?) ?? 'agua';
      W['trayIzq'] = (o['izq'] as String?) ?? 'con';
      W['cosaAVis'] = 1;
      W['cosaBVis'] = 1;
      await wait(120);
    }),
    'da86': (o) => _run(o, () async {
      final cual = (o['cual'] as String?) ?? 'cosa_a';
      final a = (o['a'] as String?) ?? 'luis';
      final ok = _n(o['ok']) == 1;
      final q = W['cq'] as Map<String, dynamic>;
      final target = _gente[a] as Map<String, dynamic>?;
      q['dy'] = -3;
      await wait(70);
      q['dy'] = 0;
      if (ok) {
        if (cual == 'cosa_a') {
          W['cosaAVis'] = 0;
        } else {
          W['cosaBVis'] = 0;
        }
        if (target != null) {
          target['dy'] = 1;
          await wait(80);
          target['dy'] = 0;
        }
        if (_n(W['cosaAVis']) == 0 && _n(W['cosaBVis']) == 0) {
          W['trayVis'] = 0;
        }
      } else {
        // Recipient shakes head; mesero snatches back with transient splash; both items remain on tray for retry.
        if (target != null) {
          for (final dx in const [-1, 1, -1, 0]) {
            target['dx'] = dx;
            await wait(60);
          }
          target['dx'] = 0;
        }
        W['splashFx'] = 1;
        await wait(160);
        W['splashFx'] = 0;
      }
    }),
    'cafes86': (o) => _run(o, () async {
      W['cafesVis'] = 1;
      await wait(160);
    }),
    'vasito86': (o) => _run(o, () async {
      W['vasitoVis'] = 1;
      await wait(160);
    }),
    'final86': (o) => _run(o, () async {
      final n = _n(o['n']).clamp(1, 3);
      W['velas'] = n;
      W['final86'] = n;
      W['trayVis'] = 0;
      W['cosaAVis'] = 0;
      W['cosaBVis'] = 0;
      W['splashFx'] = 0;
      W['velaSmoke'] = 0;
      W['paneraVis'] = 1;
      W['menuCloseToFlame'] = n == 1 ? 1 : 0;
      await _hopFrogTo('mesa2_coqui');
      await wait(180);
    }),

    /* ---------- Shared card & ending ---------- */
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
