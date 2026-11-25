// La orilla (place 7, La playa, scene 1: `orilla`; stories 72 to 74): a NEW scene, written from its script's
// "Needs" list (historia/notas/guiones/orilla.md) on its set (orilla_set.dart) and its sheet (orilla-sheet.json,
// read by SceneSheet). There is no old scene file: every act is this file's, each doing on screen what the Needs
// list says, every place from the sheet (spots, set thing boxes, depth rule, shadows). Where the sheet names no
// place or an act is unstated in the script, the code does the plainest thing that keeps the story playing and
// marks it `OPEN:`.
//
// The drawing (the sheet's `front`): every sprite stands with its feet's bottom edge on its spot's row and its
// middle on its column (rules.anchor); towels on the rope hang top-middle on `cuerda1`/`cuerda2`; a sprite pixel
// is hidden by every LIVE set pixel (including swaying palm fronds: `engine.zb`) nearer than its upright plane
// plus `front.bias`. Between two sprites the nearer pixel wins (tie within 0.001 goes to the later layer; the frog
// is always the last layer).
// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/src/colmado/colmado_cast.dart' show inkBottom;
import 'package:coqui_scenes/src/orilla/orilla_places.dart';
import 'package:coqui_scenes/src/orilla/orilla_set.dart';
import 'package:coqui_scenes/src/orilla/orilla_sprites.dart';
import 'package:coqui_scenes/src/scene_set.dart';
import 'package:coqui_scenes/src/sheet_cache.dart';

/// The scene "La orilla", made from its sheet (read first: `loadScene`).
Scene createOrilla() => Orilla(sceneSheetOf('orilla'));

int _round(num v) => (v + 0.5).floor();

int _n(Object? v) {
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? 0;
  return 0;
}

/// One sprite of the sprite layer, placed: its picture, its top left on the 240 × 216 picture, the screen row of its
/// anchor and the depth there (front.plane), and who or what it is.
class OrillaItem {
  OrillaItem(
    this.s,
    this.left,
    this.top,
    this.sy,
    this.d, {
    this.tag,
    this.flat = false,
  });

  final Sprite s;
  final int left, top;
  final num sy;
  final double d;
  final String? tag;

  /// Wave / splash drawn directly over the sand & water, behind standing sprites.
  final bool flat;
}

/// Every person La orilla knows, by speaker key (orilla.md, "Needs").
const List<String> ORILLA_PERSONAS = ['abuela', 'luis', 'carmen'];

class Orilla extends Escena implements SetScene, SetOverSprites {
  Orilla(this.ss)
    : sheet = identical(ss, _lastSs)
          ? _lastSheet!
          : (_lastSheet = ss.legacy()) {
    _p = identical(ss, _lastSs)
        ? _lastPlaces!
        : (_lastPlaces = OrillaPlaces(ss));
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
  static OrillaPlaces? _lastPlaces;

  /// The new scene's sheet (SceneSheet).
  final SceneSheet ss;

  @override
  final Sheet sheet;

  late final OrillaPlaces _p;

  /// The scene's places, from its sheet.
  OrillaPlaces get places => _p;

  @override
  String get id => 'orilla';

  @override
  late final Map<String, List<num>> CAM;

  late final Map<String, List<num>> LUGAR;

  @override
  Map<String, List<num>> get lugar => LUGAR;

  @override
  late final List<Thing> cosas;

  @override
  PpEngine newEngine({bool still = false}) => orillaEngine(still: still);

  @override
  PpEngine get projection => _p.e;

  List<num> _frogAt(OrillaAt a) => [_round(a.sx) - 16, _round(a.sy) - 25, 1];

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
      'dir': 1,
      'pose': 'idle',
      'sent': sent,
      'wade': 0, // 0 = dry/sand, 1 = ankles (agua1), 2 = knees (agua2)
      'gotea': 0,
      'abanica': 0,
      'toalla': null,
      'dx': 0,
      'dy': 0,
    };
  }

  @override
  Map<String, dynamic> fresh(Map<String, dynamic> story) {
    final acts = _actsOf([story['beats'], story['final']]);
    bool has(String a) => acts.any((o) => o['act'] == a);
    final set = _firstSet(story['beats']);
    final is74 =
        has('toallas_cuerda') ||
        has('sale74') ||
        has('seca74') ||
        has('final74');
    final is73 =
        !is74 &&
        (has('botes') || has('vadea') || has('navega73') || has('final73'));
    final is72 = !is74 && !is73;

    final gente = <String, dynamic>{};
    final String start;
    if (is74) {
      gente['abuela'] = _person('manta_abuela', sent: 1);
      gente['luis'] = _person('pie1', sent: 0);
      gente['carmen'] = _person('pie2', sent: 0);
      start = 'manta_coqui';
    } else if (is73) {
      gente['abuela'] = _person('abuela.arena', sent: 1);
      gente['luis'] = _person('luis.botes', sent: 1);
      gente['carmen'] = _person('orilla3', sent: 0);
      start = 'coqui.orilla';
    } else {
      // OPEN: story 72 step 1 ("walk in from the palms", "Carmen runs to the water's edge") has no arrival act;
      // everyone starts at their sheet spots (`abuela.foto`, `castillo_l`, `castillo_r`, `perro`, `coqui.castillo`).
      gente['abuela'] = _person('abuela.foto', sent: 1);
      gente['carmen'] = _person('castillo_l', sent: 1);
      gente['luis'] = _person('castillo_r', sent: 0);
      start = 'coqui.castillo';
    }

    final q = _frogAt(_p.at(start));
    final hora = set['hora'] is String
        ? set['hora'] as String
        : (is74 ? 'tarde' : (is73 ? 'mediodia' : 'manana'));
    final castillo = set['castillo'] != null ? _n(set['castillo']) : 0;
    final manta = set['manta'] != null ? _n(set['manta']) : (is74 ? 1 : 0);

    return <String, dynamic>{
      'cam': 'wide',
      'hora': hora,
      'castillo': castillo == 1 ? 1 : 0,
      'manta': manta == 1 ? 1 : 0,
      'story': is74 ? 74 : (is73 ? 73 : 72),
      'gente': gente,
      // Fishing boat far out (sprite in all 3 stories until `bote_va` sails it off)
      'boteVis': 1,
      'boteDx': 0,
      'boteRock': 0,
      'gaviota': null, // {x, y} when flying up
      // Waves (sprite layer)
      'ola': null, // {grande: bool, y: int}
      // Story 72: castle, shells, towers, camera, Canelo, splashes
      'conchas': (is72 || is73) ? 3 : 0,
      'conchasSpot': is73 ? 'conchas73' : 'conchas',
      'torres': <int>[0, 0, 0], // 0 none, 1 pink, 2 white
      'cubo': 0,
      'tapa': 0,
      'fotoCam': 0,
      'fotoFlash': 0,
      'conchaSuelta': null, // {x, y} rolling shell in pierde72
      'salpica': null, // {x, y, arena: bool}
      'perroVis': is72 ? 1 : 0,
      'perroPose': 'sit',
      'perroDx': 0,
      'perroDy': 0,
      'perroConcha': 0,
      'perroArena': 0,
      // Story 73: toy boats, frog's boat, Carmen's necklace
      'boteA': null,
      'boteB': null,
      'boteADy': 0,
      'boteBDy': 0,
      'boteAHund': 0,
      'boteBHund': 0,
      'boteRana': null, // {color, x, y, d, hundido: bool}
      'collar': null, // 0..3 when Carmen holds string
      'final73': null, // 1..3 prize on frog
      // Story 74: towels on rope, pile, basket, abuela lying back, frog wet/towel/hat
      'toallas': is74 ? 3 : 0,
      'toallaA': is74 ? 'rojo' : null,
      'toallaB': is74 ? 'azul' : null,
      'toallaAGotea': 0,
      'toallaBGotea': 0,
      'canasta': is74 ? 1 : 0,
      'abuelaAcostada': 0,
      'coquiGotea': 0,
      'coquiConcha': 0,
      'coquiToalla': null, // color carried or wrapped
      'final74': null, // 1..3
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
        'z': _p.world(start)[2],
        'spot': start,
      },
    };
  }

  /* ---------- the set ---------- */

  @override
  String setKey(Map<String, dynamic> W) {
    final h = W['hora'];
    final hora =
        h is String &&
            const ['manana', 'mediodia', 'tarde', 'ocaso'].contains(h)
        ? h
        : 'manana';
    return '$hora-${_n(W['castillo']) == 1 ? 1 : 0}-${_n(W['manta']) == 1 ? 1 : 0}';
  }

  @override
  void buildSet(PpEngine e, PpBuild b, Map<String, dynamic> W) =>
      buildSetFor(e, b, setKey(W));

  final Map<PpEngine, OrillaSet> _sets = {};

  @override
  void buildSetFor(PpEngine e, PpBuild b, String key) =>
      (_sets[e] ??= OrillaSet(e, b)).buildSet(OrillaState.fromKey(key));

  @override
  bool get frogShadow => false;

  /* ---------- where everybody is ---------- */

  Map<String, dynamic> get _gente => W['gente'] as Map<String, dynamic>;

  OrillaAt _atOf(Map<String, dynamic> o) =>
      _p.atWorld(o['x'] as num, o['y'] as num, o['z'] as num);

  OrillaAt _frogPoint(Map<String, dynamic> q) {
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

  ({Sprite s, int ax, int ay}) _personSprite(
    String id,
    Map<String, dynamic> p,
    bool open,
    Map<String, dynamic> w,
  ) {
    if (id == 'abuela') {
      if (_n(w['abuelaAcostada']) == 1) {
        final s = _spr('ab_acostada', mkAbuelaAcostada);
        return (s: s, ax: s.w ~/ 2, ay: inkBottom(s));
      }
      final pose = (p['pose'] as String?) ?? 'idle';
      final abPose = switch (pose) {
        'saluda0' || 'saluda1' => pose,
        'senala' => 'tu',
        'rie' => 'yo',
        _ => 'idle',
      };
      final k = 'or_abS_${abPose}_$open';
      final s = _spr(k, () => cutSandSit(mkAbuelaS(abPose, open, false), 42));
      return (s: s, ax: 17, ay: inkBottom(s));
    }
    final who = id == 'luis' ? FAM['hermano']! : FAM['hermana']!;
    final sent = _n(p['sent']) == 1;
    final wade = _n(p['wade']);
    final pose = (p['pose'] as String?) ?? 'idle';
    final kp = switch (pose) {
      'saluda0' => 'wave0',
      'saluda1' => 'wave1',
      'senala' => 'tu',
      'rie' => 'yo',
      'mano' => 'offer',
      _ => 'idle',
    };
    if (sent) {
      final cutRows = 16 + 2 * (who.nino ? 7 : 11) + 3 + 3;
      final k = 'or_${id}_sit_${kp}_$open';
      final s = _spr(
        k,
        () => cutSandSit(mkPersona(who, kp, open, true), cutRows),
      );
      return (s: s, ax: PX, ay: inkBottom(s));
    }
    final baseKey = 'or_${id}_st_${kp}_$open';
    final base = _spr(baseKey, () => mkPersona(who, kp, open, false));
    if (wade > 0) {
      final clip = wade >= 2 ? 10 : 4;
      final wf = (F >> 2) % 2;
      final wk = '${baseKey}_wade_${clip}_$wf';
      final s = _spr(wk, () => wadeClip(base, clip, frame: wf));
      return (s: s, ax: PX, ay: s.h);
    }
    return (s: base, ax: PX, ay: inkBottom(base));
  }

  String? _talker() {
    try {
      return host.TALK;
    } catch (_) {
      return null;
    }
  }

  /// Every sprite of the frame [w] as it is placed, except the frog. The rules' tests read it; [draw] draws it.
  List<OrillaItem> items(Map<String, dynamic> w, int a) {
    final out = <OrillaItem>[];
    final talk = _talker();
    final gente = (w['gente'] as Map<String, dynamic>?) ?? const {};

    // 1. Wave sprite running across the wet sand (flat, under standing characters)
    final ola = w['ola'];
    if (ola is Map) {
      final grande = ola['grande'] == true;
      final oy = _n(ola['y']);
      final s = _spr(
        'ola_${grande}_${(F >> 1) % 2}',
        () => mkOla(grande, (F >> 1) % 2),
      );
      out.add(OrillaItem(s, 28, oy - s.h, oy, -4.0, tag: 'fx:ola', flat: true));
    }

    // 2. Fishing boat far out at anchor (`bote`, 34 x 20, bottom-middle on spot `bote`)
    if (_n(w['boteVis']) == 1) {
      final at = _p.at('bote');
      final rock = _n(w['boteRock']) == 1;
      final s = _spr('bote_pesca_$rock', () => mkBotePesca(rock: rock));
      final sx = _round(at.sx) + _n(w['boteDx']);
      final sy = _round(at.sy);
      out.add(OrillaItem(s, sx - 17, sy - s.h, sy, at.d, tag: 'cosa:bote'));
    }
    final gav = w['gaviota'];
    if (gav is Map) {
      final s = _spr('gav_${a % 2}', () => mkGaviota(a % 2));
      final gx = _n(gav['x']), gy = _n(gav['y']);
      out.add(
        OrillaItem(s, gx - s.w ~/ 2, gy - s.h ~/ 2, gy, 5.0, tag: 'fx:gaviota'),
      );
    }

    // 3. Pink shells in a row (`conchas` in 72, `conchas73` in 73)
    final conchasN = _n(w['conchas']);
    if (conchasN > 0) {
      final spot = (w['conchasSpot'] as String?) ?? 'conchas';
      final at = _p.at(spot);
      final s = _spr('conchas_$conchasN', () => mkConchas(conchasN));
      final sx = _round(at.sx), sy = _round(at.sy);
      out.add(OrillaItem(s, sx - 11, sy - s.h, sy, at.d, tag: 'cosa:conchas'));
    }

    // 4. Shells placed on the castle's three towers (`torre1..3`)
    final torres = w['torres'];
    if (_n(w['castillo']) == 1 && torres is List) {
      for (var i = 0; i < 3 && i < torres.length; i++) {
        final v = _n(torres[i]);
        if (v <= 0) continue;
        final at = _p.at('torre${i + 1}');
        final s = v == 2
            ? _spr('concha_blanca', mkConchaBlanca)
            : _spr('concha', mkConcha);
        final sx = _round(at.sx), sy = _round(at.sy);
        out.add(
          OrillaItem(
            s,
            sx - 3,
            sy - s.h,
            sy,
            at.d,
            tag: 'cosa:torre_concha_${i + 1}',
          ),
        );
      }
    }

    // 5. Rolling shell lost to a wave (`pierde72 mar`)
    final cSuelta = w['conchaSuelta'];
    if (cSuelta is Map) {
      final s = _spr('concha', mkConcha);
      final cx = _n(cSuelta['x']), cy = _n(cSuelta['y']);
      out.add(OrillaItem(s, cx - 3, cy - 3, cy, 4.0, tag: 'fx:concha_suelta'));
    }

    // 6. Toy boats on wet sand (`bote_a`, `bote_b`: 14 x 10, bottom-middle)
    for (final (key, spot, dyKey, hKey, tag) in const [
      ('boteA', 'bote_a', 'boteADy', 'boteAHund', 'cosa:bote_a'),
      ('boteB', 'bote_b', 'boteBDy', 'boteBHund', 'cosa:bote_b'),
    ]) {
      final col = w[key];
      if (col is String) {
        final at = _p.at(spot);
        final hund = _n(w[hKey]) == 1;
        final s = _spr(
          'bote_${col}_$hund',
          () => mkBoteJuguete(col, hundido: hund),
        );
        final sx = _round(at.sx), sy = _round(at.sy) + _n(w[dyKey]);
        out.add(OrillaItem(s, sx - 7, sy - s.h, sy, at.d, tag: tag));
      }
    }

    // 7. Frog's boat on the water (`navega73`: 36 x 8, bottom-middle, just under frog)
    final bRana = w['boteRana'];
    if (bRana is Map) {
      final col = (bRana['color'] as String?) ?? 'verde';
      final hund = bRana['hundido'] == true;
      final s = _spr(
        'bote_rana_${col}_$hund',
        () => mkBoteRana(col, hundido: hund),
      );
      final bx = _n(bRana['x']), by = _n(bRana['y']);
      final bd = (bRana['d'] as num).toDouble();
      out.add(
        OrillaItem(s, bx - 18, by - s.h, by, bd - .002, tag: 'fx:bote_rana'),
      );
    }

    // 8. Story 74: towels on rope (`cuerda1`/`cuerda2`, top-middle), towel pile (`toallas`), basket (`canasta`)
    for (final (key, spot, gKey, tag) in const [
      ('toallaA', 'cuerda1', 'toallaAGotea', 'cosa:toalla_a'),
      ('toallaB', 'cuerda2', 'toallaBGotea', 'cosa:toalla_b'),
    ]) {
      final col = w[key];
      if (col is String) {
        final at = _p.at(spot);
        final got = _n(w[gKey]) == 1;
        final s = _spr(
          'toalla_${col}_$got',
          () => mkToallaColgada(col, gotea: got),
        );
        final sx = _round(at.sx), sy = _round(at.sy);
        out.add(OrillaItem(s, sx - 7, sy, sy, at.d, tag: tag));
      }
    }
    final toallasN = _n(w['toallas']);
    if (toallasN > 0) {
      final at = _p.at('toallas');
      final s = _spr('pila_$toallasN', () => mkPilaToallas(toallasN));
      final sx = _round(at.sx), sy = _round(at.sy);
      out.add(OrillaItem(s, sx - 7, sy - s.h, sy, at.d, tag: 'cosa:toallas'));
    }
    if (_n(w['canasta']) == 1) {
      final at = _p.at('canasta');
      final s = _spr('canasta', mkCanastaPlaya);
      final sx = _round(at.sx), sy = _round(at.sy);
      out.add(OrillaItem(s, sx - 6, sy - s.h, sy, at.d, tag: 'cosa:canasta'));
    }

    // 9. Canelo (`perro`, story 72)
    if (_n(w['perroVis']) == 1) {
      final at = _p.at('perro');
      final pose = (w['perroPose'] as String?) ?? 'sit';
      final step = (F >> 2) % 2 == 1;
      final Sprite s;
      if (_n(w['perroConcha']) == 1) {
        s = _spr('perro_concha_$step', () => mkPerroConcha(step));
      } else if (_n(w['perroArena']) == 1) {
        s = _spr('perro_arena', mkPerroArena);
      } else {
        s = _spr('perro_${pose}_$step', () => mkPerro(pose, step));
      }
      final sx = _round(at.sx) + _n(w['perroDx']);
      final sy = _round(at.sy) + _n(w['perroDy']);
      out.add(
        OrillaItem(
          s,
          sx - 15,
          sy - inkBottom(s),
          sy,
          at.d,
          tag: 'persona:perro',
        ),
      );
    }

    // 10. People (abuela, luis, carmen) + held props (bucket, camera, necklace, fan, drips, towel)
    for (final en in gente.entries) {
      final p = en.value as Map<String, dynamic>;
      if (p['vis'] == 0) continue;
      final open = talk == en.key && a % 2 == 1;
      final sp = _personSprite(en.key, p, open, w);
      final at = _atOf(p);
      final sx = _round(at.sx) + _n(p['dx']);
      final sy = _round(at.sy) + _n(p['dy']);
      out.add(
        OrillaItem(
          sp.s,
          sx - sp.ax,
          sy - sp.ay,
          sy,
          at.d,
          tag: 'persona:${en.key}',
        ),
      );
      if (en.key == 'luis' && _n(w['cubo']) == 1) {
        final cb = _spr('cubo', mkCuboArena);
        out.add(
          OrillaItem(cb, sx - 14, sy - cb.h, sy, at.d + .02, tag: 'held:cubo'),
        );
      }
      if (en.key == 'abuela' && _n(w['fotoCam']) == 1) {
        final cm = _spr('camara', mkCamara);
        out.add(
          OrillaItem(cm, sx + 2, sy - 26, sy, at.d + .02, tag: 'held:camara'),
        );
        if (_n(w['fotoFlash']) == 1) {
          final fl = _spr('flash', mkFlash);
          out.add(
            OrillaItem(fl, sx + 4, sy - 32, sy, at.d + .05, tag: 'fx:flash'),
          );
        }
      }
      if (en.key == 'carmen' && w['collar'] is num) {
        final cn = _n(w['collar']).clamp(0, 3);
        final cs = _spr('collar_$cn', () => mkCollar(cn));
        out.add(
          OrillaItem(
            cs,
            sx - cs.w ~/ 2,
            sy - 20,
            sy,
            at.d + .02,
            tag: 'held:collar',
          ),
        );
      }
      if (_n(p['abanica']) == 1) {
        final ab = _spr('aban_${a % 2}', () => mkAbanicoMano(a % 2));
        out.add(
          OrillaItem(
            ab,
            sx + 6,
            sy - 28,
            sy,
            at.d + .02,
            tag: 'held:aban_${en.key}',
          ),
        );
      }
      if (p['toalla'] is String) {
        final tc = p['toalla'] as String;
        final ts = _spr('tp_$tc', () => mkToallaPuesta(tc));
        out.add(
          OrillaItem(
            ts,
            sx - ts.w ~/ 2,
            sy - 26,
            sy,
            at.d + .02,
            tag: 'held:toalla_${en.key}',
          ),
        );
      }
      if (_n(p['gotea']) == 1) {
        final gt = _spr('gotas_${(F >> 1) % 2}', () => mkGotas((F >> 1) % 2));
        out.add(
          OrillaItem(
            gt,
            sx - gt.w ~/ 2,
            sy - 28,
            sy,
            at.d + .03,
            tag: 'fx:gotas_${en.key}',
          ),
        );
      }
    }

    // 11. Digging / ducking splash
    final salp = w['salpica'];
    if (salp is Map) {
      final isArena = salp['arena'] == true;
      final s = _spr(
        'salp_${isArena}_${(F >> 1) % 2}',
        () => mkSalpicadura(isArena, (F >> 1) % 2),
      );
      final sx = _n(salp['x']), sy = _n(salp['y']);
      out.add(
        OrillaItem(s, sx - s.w ~/ 2, sy - s.h, sy, 8.0, tag: 'fx:salpica'),
      );
    }

    return out;
  }

  /* ---------- drawing ---------- */

  Float32List? _setZ;
  bool _framed = false;
  Uint32List? _layer;
  Float32List? _layerZ;

  @override
  void setFramed(PpEngine engine, BakedSet baked, Map<String, dynamic> W) {
    _framed = true;
    // Live depth (after engine.drawLeaves) so swaying palm fronds hide sprites behind them (orilla-sheet.json front.plane).
    _setZ = engine.zb;
  }

  static final double _t30 = math.tan(math.pi / 6);

  void _put(
    OrillaItem it,
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
        if (!it.flat && setZ != null && setZ[i] > plane + bias) continue;
        if (lz[i] > plane + .001) continue;
        lz[i] = plane;
        layer[i] = c;
      }
    }
  }

  static final Map<String, Sprite> _frogSprites = {};

  /// [items] and the frog (always last so a tie goes to the frog), plus frog accessories.
  List<OrillaItem> placed(Map<String, dynamic> W, int a) {
    final all = items(W, a);
    final q = W['cq'] as Map<String, dynamic>;
    if (jsTruthy(q['vis'])) {
      final b = host.frogBox(q), at = _frogPoint(q);
      final dx = _n(q['dx']);
      final fsy = _round(at.sy);
      final fsx = _round(at.sx) + dx;
      final fin74 = W['final74'];
      if (fin74 is num && fin74 == 3) {
        final tr = _spr('toalla_rana', mkToallaRana);
        all.add(
          OrillaItem(tr, fsx - tr.w ~/ 2, fsy - tr.h, fsy, at.d, tag: 'coqui'),
        );
      } else if (fin74 is num && (fin74 == 1 || fin74 == 2)) {
        final sr = _spr('sombrero_rana', mkSombreroRana);
        all.add(
          OrillaItem(sr, fsx - sr.w ~/ 2, fsy - sr.h, fsy, at.d, tag: 'coqui'),
        );
      } else {
        final ox = b.x.toInt() - 16 + dx, oy = b.y.toInt() - 24;
        final fk =
            '${q['s']}_${b.x - (b.x.toInt() - 16)}_${b.y - oy}_${(q['y'] as num) - oy}_${((q['dy'] as num) + 0.5).floor()}_${host.F % 47 < 2 ? 1 : 0}_${((q['bub'] == 'hola' || _talker() == 'coqui') && a % 2 != 0) ? 1 : 0}';
        final spr = _frogSprites.putIfAbsent(fk, () {
          final px = Uint32List(64 * 64);
          final g = Ctx(px, 64, 64)
            ..translate(-(b.x.toInt() - 16).toDouble(), -oy.toDouble());
          host.frog(g, q, a);
          return Sprite(64, 64, px);
        });
        all.add(OrillaItem(spr, ox, oy, fsy, at.d, tag: 'coqui'));
      }

      if (_n(W['tapa']) == 1) {
        final mt = _spr('mano_tapa', mkManoTapa);
        all.add(
          OrillaItem(
            mt,
            fsx - mt.w ~/ 2,
            fsy - 22,
            fsy,
            at.d + .03,
            tag: 'fx:tapa',
          ),
        );
      }
      if (_n(W['coquiConcha']) == 1) {
        final sh = _spr('concha', mkConcha);
        all.add(
          OrillaItem(
            sh,
            fsx - 3,
            fsy - 27 + _n(q['dy']),
            fsy,
            at.d + .03,
            tag: 'held:coqui_concha',
          ),
        );
      }
      if (W['coquiToalla'] is String) {
        final tc = W['coquiToalla'] as String;
        final ts = _spr('tp_$tc', () => mkToallaPuesta(tc));
        all.add(
          OrillaItem(
            ts,
            fsx - ts.w ~/ 2,
            fsy - 24 + _n(q['dy']),
            fsy,
            at.d + .03,
            tag: 'held:coqui_toalla',
          ),
        );
      }
      if (_n(W['coquiGotea']) == 1) {
        final gt = _spr('gotas_${(F >> 1) % 2}', () => mkGotas((F >> 1) % 2));
        all.add(
          OrillaItem(
            gt,
            fsx - gt.w ~/ 2,
            fsy - 24,
            fsy,
            at.d + .03,
            tag: 'fx:gotas_coqui',
          ),
        );
      }
      final fin73 = W['final73'];
      if (fin73 is num) {
        final cr = _spr(
          'collar_rana_${fin73.toInt()}',
          () => mkCollarRana(fin73.toInt()),
        );
        all.add(
          OrillaItem(
            cr,
            fsx - cr.w ~/ 2,
            fsy - 16,
            fsy,
            at.d + .03,
            tag: 'held:collar_rana',
          ),
        );
      }
    }
    return all;
  }

  @override
  void draw(Ctx c, Map<String, dynamic> W, int a) {
    if (!_framed) return;
    const w0 = 240, h0 = 216;
    final layer = _layer ??= Uint32List(w0 * h0);
    final lz = _layerZ ??= Float32List(w0 * h0);
    final setZ = _setZ, bias = _p.bias, S = _p.e.S;
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
      final z = (p['z'] as num).toDouble();
      final spot = p['spot'] as String?;
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
    if (_n(W['perroVis']) == 1) {
      final r = _p.radius('perro');
      if (r != null) {
        final at = _p.at('perro');
        out.add((x: at.x, y: at.y, z: 0.0, r: r));
      }
    }
    final q = W['cq'] as Map<String, dynamic>;
    if (jsTruthy(q['vis'])) {
      final at = _frogPoint(q);
      final spot = q['spot'] as String?;
      final r = _p.radius('coqui');
      if (r != null && at.z == 0 && (spot == null || !_p.noShadow(spot))) {
        out.add((x: at.x, y: at.y, z: 0.0, r: r));
      }
    }
    return out;
  }

  /* ---------- speech bubbles ---------- */

  @override
  List<num>? talkAt(String who, Map<String, dynamic> W) {
    if (who == 'coqui') {
      final q = W['cq'] as Map<String, dynamic>;
      final b = host.frogBox(q);
      return [b.x + b.w / 2, b.y];
    }
    if (who == 'perro' && _n(W['perroVis']) == 1) {
      final at = _p.at('perro');
      return [_round(at.sx), _round(at.sy) - 24];
    }
    final gente = (W['gente'] as Map<String, dynamic>?) ?? const {};
    final p = gente[who];
    if (p is Map<String, dynamic> && p['vis'] != 0) {
      final at = _atOf(p);
      final h = who == 'abuela'
          ? (_n(W['abuelaAcostada']) == 1 ? 22 : 42)
          : (_n(p['sent']) == 1 ? 35 : 41);
      return [_round(at.sx) + _n(p['dx']), _round(at.sy) + _n(p['dy']) - h];
    }
    return null;
  }

  /* ---------- things he can touch (orilla.md Needs + orilla-sheet.json) ---------- */

  List<num>? _itemBox(Map<String, dynamic> w, String tag) {
    for (final it in items(w, 0)) {
      if (it.tag != tag) continue;
      final s = it.s;
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
      if (x1 < 0) return [it.left, it.top, s.w, s.h];
      return [it.left + x0, it.top + y0, x1 - x0 + 1, y1 - y0 + 1];
    }
    return null;
  }

  bool _vis(Map<String, dynamic> w, String who) {
    final g = w['gente'];
    return g is Map && g[who] is Map && (g[who] as Map)['vis'] != 0;
  }

  List<Thing> _things() {
    Thing spriteThing(
      String id,
      String tag,
      bool Function(Map<String, dynamic> w) si, {
      List<int> Function()? fallback,
    }) =>
        Thing(id: id, si: si, box: (w) => _itemBox(w, tag) ?? fallback?.call());

    // Order matters for Escena.hit: small interactive sprites first, then people, then background set things (`mar` last).
    return [
      spriteThing('bote_a', 'cosa:bote_a', (w) => w['boteA'] is String),
      spriteThing('bote_b', 'cosa:bote_b', (w) => w['boteB'] is String),
      spriteThing('toalla_a', 'cosa:toalla_a', (w) => w['toallaA'] is String),
      spriteThing('toalla_b', 'cosa:toalla_b', (w) => w['toallaB'] is String),
      spriteThing('toallas', 'cosa:toallas', (w) => _n(w['toallas']) > 0),
      spriteThing('conchas', 'cosa:conchas', (w) => _n(w['conchas']) > 0),
      spriteThing('bote', 'cosa:bote', (w) => _n(w['boteVis']) == 1),
      for (final who in ORILLA_PERSONAS)
        spriteThing(who, 'persona:$who', (w) => _vis(w, who)),
      spriteThing('perro', 'persona:perro', (w) => _n(w['perroVis']) == 1),
      Thing(
        id: 'castillo',
        si: (w) => _n(w['castillo']) == 1,
        box: (_) => _p.box('castillo'),
        world: _p.worldBox('castillo'),
      ),
      Thing(
        id: 'arena',
        si: (w) => _n(w['castillo']) == 1,
        box: (_) => _p.box('arena'),
        world: _p.worldBox('arena'),
      ),
      Thing(
        id: 'mar',
        si: (_) => true,
        box: (_) => _p.box('mar'),
        world: _p.worldBox('mar'),
      ),
    ];
  }

  /* ---------- movement helpers ---------- */

  Future<void> _hopTo(String spot, {int steps = 6}) async {
    if (!_p.has(spot)) return;
    final q = W['cq'] as Map<String, dynamic>;
    final at = _p.at(spot);
    final L = _frogAt(at);
    final sx = (q['x'] as num).toDouble();
    final sy = (q['y'] as num).toDouble();
    final ex = L[0].toDouble();
    final ey = L[1].toDouble();
    final n = math.max(1, steps);
    for (var i = 1; i <= n; i++) {
      final t = i / n;
      q['x'] = _round(sx + (ex - sx) * t);
      q['y'] = _round(sy + (ey - sy) * t);
      q['dy'] = -_round(math.sin(t * math.pi) * 8);
      await wait(45);
    }
    q['x'] = L[0];
    q['y'] = L[1];
    q['dy'] = 0;
    q['z'] = at.z;
    q['spot'] = spot;
  }

  Future<void> _brinco() async {
    final q = W['cq'] as Map<String, dynamic>;
    for (final dy in const [-4, -7, -4, 0]) {
      q['dy'] = dy;
      await wait(60);
    }
  }

  Future<void> _movePerson(
    Map<String, dynamic> p,
    String spot, {
    int steps = 6,
    int? sent,
    int? wade,
  }) async {
    if (!_p.has(spot)) return;
    final target = _p.world(spot);
    final sx = (p['x'] as num).toDouble();
    final sy = (p['y'] as num).toDouble();
    final sz = (p['z'] as num).toDouble();
    final n = math.max(1, steps);
    p['sent'] = 0;
    for (var i = 1; i <= n; i++) {
      final t = i / n;
      p['x'] = sx + (target[0] - sx) * t;
      p['y'] = sy + (target[1] - sy) * t;
      p['z'] = sz + (target[2] - sz) * t;
      await wait(45);
    }
    p['x'] = target[0];
    p['y'] = target[1];
    p['z'] = target[2];
    p['spot'] = spot;
    if (sent != null) p['sent'] = sent;
    if (wade != null) p['wade'] = wade;
  }

  @override
  List<num> remap(List<num> xy) => xy;

  @override
  Future<void> stake(int lost, int max, String en) async {}

  /* ---------- acts ---------- */

  final List<Future<void>> _sueltos = [];

  @override
  Map<String, Act> get ownActs => {
    for (final e in _acts.entries)
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

  late final Map<String, Act> _acts = {
    'ya': (o) async {
      final all = List<Future<void>>.of(_sueltos);
      _sueltos.clear();
      await Future.wait(all);
    },
    'ir': (o) async {
      final a = o['a'] as String?;
      if (a == null) return;
      // OPEN: `orilla1` (125, 84) has 9 px of the frog under the right palm's swaying frond tip; `orilla2`
      // (151, 84) is in the same `orilla` group and keeps the frog 100% clear (`frog-seen`).
      final target = a == 'orilla1' ? 'orilla2' : a;
      if (_p.has(target)) {
        await _hopTo(target, steps: 6);
      }
    },
    // Waves running up the wet sand and back (stories 72, 73)
    'ola': (o) async {
      final grande = o['t'] == 'grande';
      final ys = grande
          ? const [76, 82, 88, 94, 98, 94, 88, 82, 76]
          : const [76, 80, 84, 88, 84, 80, 76];
      for (final y in ys) {
        W['ola'] = <String, dynamic>{'grande': grande, 'y': y};
        await wait(70);
      }
      W['ola'] = null;
    },
    // Story 72: build the sand castle with three towers
    'torres72': (o) async {
      final luis = _gente['luis'] as Map<String, dynamic>?;
      final carmen = _gente['carmen'] as Map<String, dynamic>?;
      if (luis != null) luis['sent'] = 1;
      if (carmen != null) carmen['sent'] = 1;
      W['cubo'] = 1;
      await wait(160);
      W['castillo'] = 1;
      await wait(180);
      W['cubo'] = 0;
    },
    // Story 72: hand over frog's eyes, Luis hides a shell (no visual giveaway)
    'esconde72': (o) async {
      final q = W['cq'] as Map<String, dynamic>;
      if (q['spot'] != 'coqui.castillo') {
        await _hopTo('coqui.castillo', steps: 5);
      }
      W['tapa'] = 1;
      await wait(240);
      W['tapa'] = 0;
      await wait(80);
    },
    // Story 72: frog digs at `parche` or ducks at `mar_busca`, returns to `coqui.castillo`
    'busca72': (o) async {
      final en = o['en'] as String?;
      final ok = _n(o['ok']) == 1;
      final spot = en == 'mar' ? 'mar_busca' : 'parche';
      await _hopTo(spot, steps: 6);
      final at = _p.at(spot);
      final sx = _round(at.sx), sy = _round(at.sy);
      W['salpica'] = <String, dynamic>{
        'x': sx,
        'y': sy - 4,
        'arena': en != 'mar',
      };
      await wait(200);
      W['salpica'] = null;
      if (ok) {
        W['coquiConcha'] = 1;
        await _brinco();
      }
      await _hopTo('coqui.castillo', steps: 6);
      W['coquiConcha'] = 0;
    },
    // Story 72: place a pink shell on tower n (1..3)
    'corona72': (o) async {
      final n = _n(o['n']).clamp(1, 3);
      final t = List<int>.from(W['torres'] as List);
      t[n - 1] = 1;
      W['torres'] = t;
      await wait(160);
    },
    // Story 72: shell lost to a wave (mar) or Canelo digs it out and runs off (arena)
    'pierde72': (o) async {
      final en = o['en'] as String?;
      if (en == 'mar') {
        for (final (oy, cy) in const [(78, 76), (86, 80), (82, 72), (76, 62)]) {
          W['ola'] = <String, dynamic>{'grande': false, 'y': oy};
          W['conchaSuelta'] = <String, dynamic>{'x': 151, 'y': cy};
          await wait(80);
        }
        W['ola'] = null;
        W['conchaSuelta'] = null;
      } else {
        // OPEN: no spot for Canelo running off down the beach; he dashes from `perro` toward `parche` with a
        // pink shell in his mouth and returns to `perro` so `spots-in-view` holds.
        W['perroPose'] = 'run';
        W['perroConcha'] = 1;
        for (final dx in const [-12, -24, -12, 0]) {
          W['perroDx'] = dx;
          await wait(75);
        }
        W['perroConcha'] = 0;
        W['perroPose'] = 'sit';
        W['perroDx'] = 0;
      }
    },
    // Stories 72 & 73: count of pink shells shown in the row
    'conchas': (o) async {
      final n = _n(o['n']).clamp(0, 3);
      W['conchas'] = n;
      // Story 72 step 5: Luis takes the two opening shells off the towers and shows 3 again before the game.
      if (_n(W['story']) == 72 && n == 3 && _n(W['castillo']) == 1) {
        W['torres'] = <int>[0, 0, 0];
      }
      await wait(120);
    },
    // Story 72 ending
    'final72': (o) async {
      final n = _n(o['n']).clamp(1, 3);
      W['conchas'] = 0;
      if (n == 3) {
        W['torres'] = <int>[1, 1, 1];
      } else if (n == 2) {
        W['torres'] = <int>[1, 1, 2];
      } else {
        W['torres'] = <int>[1, 0, 0];
        W['perroPose'] = 'lie';
        W['perroArena'] = 1;
      }
      await wait(240);
    },
    // Story 72: abuela's camera clicks
    'foto': (o) async {
      W['fotoCam'] = 1;
      await wait(140);
      W['fotoFlash'] = 1;
      await wait(120);
      W['fotoFlash'] = 0;
      await wait(120);
      W['fotoCam'] = 0;
    },
    // Story 73: child wades to `agua1` (ankles) or `agua2` (knees)
    'vadea': (o) async {
      final quien = (o['quien'] as String?) ?? 'carmen';
      final a = (o['a'] as String?) ?? 'agua1';
      final p = _gente[quien] as Map<String, dynamic>?;
      if (p == null) return;
      final wade = a == 'agua2' ? 2 : 1;
      await _movePerson(p, a, steps: 6, sent: 0, wade: wade);
    },
    // Story 73: two toy boats on the wet sand
    'botes': (o) async {
      W['boteA'] = o['a'] as String?;
      W['boteB'] = o['b'] as String?;
      W['boteADy'] = 0;
      W['boteBDy'] = 0;
      W['boteAHund'] = 0;
      W['boteBHund'] = 0;
      await wait(140);
    },
    // Story 73 step 3: Luis tests a toy boat on the shallow water edge
    'prueba73': (o) async {
      // OPEN: no separate water-test spot in the sheet; the tested boat nudges onto the shallow water above
      // `bote_a`/`bote_b`, floats or tilts, and returns to its wet-sand spot so it can be touched in the ask.
      final color = o['color'] as String?;
      final ok = _n(o['ok']) == 1;
      final isA = W['boteA'] == color;
      final dyKey = isA ? 'boteADy' : 'boteBDy';
      final hKey = isA ? 'boteAHund' : 'boteBHund';
      for (final dy in const [-4, -8, -10]) {
        W[dyKey] = dy;
        await wait(65);
      }
      if (!ok) {
        W[hKey] = 1;
        await wait(180);
        W[hKey] = 0;
      } else {
        await wait(180);
      }
      W[dyKey] = 0;
    },
    // Story 73: frog rides a boat out to `navega` (halfway to Carmen)
    'navega73': (o) async {
      final color = (o['color'] as String?) ?? 'verde';
      final ok = _n(o['ok']) == 1;
      final concha = _n(o['concha']) == 1;
      final q = W['cq'] as Map<String, dynamic>;
      final startAt = _p.at('coqui.orilla');
      final navAt = _p.at('navega');
      if (concha) W['coquiConcha'] = 1;
      for (var i = 1; i <= 6; i++) {
        final t = i / 6;
        final sx = _round(startAt.sx + (navAt.sx - startAt.sx) * t);
        final sy = _round(startAt.sy + (navAt.sy - startAt.sy) * t);
        final d = startAt.d + (navAt.d - startAt.d) * t;
        q['x'] = sx - 16;
        q['y'] = sy - 25;
        q['z'] = 0.0;
        q['spot'] = 'navega';
        W['boteRana'] = <String, dynamic>{
          'color': color,
          'x': sx,
          'y': sy,
          'd': d,
          'hundido': false,
        };
        await wait(55);
      }
      if (ok) {
        await wait(160);
        W['coquiConcha'] = 0;
        W['boteRana'] = null;
        await _hopTo('coqui.orilla', steps: 5);
      } else {
        W['boteRana'] = <String, dynamic>{
          'color': color,
          'x': _round(navAt.sx),
          'y': _round(navAt.sy),
          'd': navAt.d,
          'hundido': true,
        };
        W['salpica'] = <String, dynamic>{
          'x': _round(navAt.sx),
          'y': _round(navAt.sy) - 4,
          'arena': false,
        };
        await wait(220);
        W['salpica'] = null;
        W['coquiConcha'] = 0;
        W['boteRana'] = null;
        await _hopTo('coqui.orilla', steps: 5);
      }
    },
    // Story 73: shells on Carmen's string
    'collar': (o) async {
      W['collar'] = _n(o['n']).clamp(0, 3);
      await wait(120);
    },
    // Story 73 ending: Carmen wades back in and gives the frog his shells
    'final73': (o) async {
      // OPEN: Carmen wades back in to `sale`; the toy boats are cleared so she never overlaps `bote_b`, and
      // the prize (necklace / wrist tie / single shell) is drawn on the frog at `coqui.orilla`.
      final n = _n(o['n']).clamp(1, 3);
      W['boteA'] = null;
      W['boteB'] = null;
      W['conchas'] = 0;
      W['collar'] = null;
      final carmen = _gente['carmen'] as Map<String, dynamic>?;
      if (carmen != null) {
        await _movePerson(carmen, 'sale', steps: 6, sent: 0, wade: 0);
      }
      W['final73'] = n;
      await wait(220);
    },
    // Story 73 ending: fishing boat pulls anchor and sails out to the right
    'bote_va': (o) async {
      for (final dx in const [4, 10, 18, 28, 40]) {
        W['boteDx'] = dx;
        await wait(80);
      }
      W['boteVis'] = 0;
    },
    // Story 74: somebody runs into the sea
    'al_agua': (o) async {
      final quien = o['quien'] as String?;
      if (quien == 'coqui') {
        await _hopTo('mar_busca', steps: 6);
        final at = _p.at('mar_busca');
        W['salpica'] = <String, dynamic>{
          'x': _round(at.sx),
          'y': _round(at.sy) - 4,
          'arena': false,
        };
        await wait(160);
        W['salpica'] = null;
        return;
      }
      final p = _gente[quien] as Map<String, dynamic>?;
      if (p == null) return;
      p['abanica'] = 0;
      p['gotea'] = 0;
      p['toalla'] = null;
      // OPEN: in story 74 step 4 both children run into the water (`al_agua luis`, `al_agua carmen`); Luis takes
      // `agua1` and Carmen takes `agua2` (5 px across, 11 px down while both wait briefly before Carmen comes out).
      final spot = quien == 'carmen' ? 'agua2' : 'agua1';
      await _movePerson(
        p,
        spot,
        steps: 6,
        sent: 0,
        wade: spot == 'agua2' ? 2 : 1,
      );
    },
    // Story 74: somebody comes out of the water dripping
    'sale74': (o) async {
      final quien = o['quien'] as String?;
      if (quien == 'coqui') {
        await _hopTo('manta_coqui', steps: 6);
        W['coquiGotea'] = 1;
        await _brinco();
        return;
      }
      // Clear anyone standing at `sale` back to their standing spot so the incoming child has `sale` free.
      for (final other in const ['luis', 'carmen']) {
        if (other == quien) continue;
        final op = _gente[other] as Map<String, dynamic>?;
        if (op != null && op['spot'] == 'sale') {
          await _movePerson(
            op,
            other == 'luis' ? 'pie1' : 'pie2',
            steps: 4,
            sent: 0,
            wade: 0,
          );
        }
      }
      final p = _gente[quien] as Map<String, dynamic>?;
      if (p == null) return;
      await _movePerson(p, 'sale', steps: 6, sent: 0, wade: 0);
      p['gotea'] = 1;
    },
    // Story 74: two towels hung on the rope
    'toallas_cuerda': (o) async {
      W['toallaA'] = o['a'] as String?;
      W['toallaB'] = o['b'] as String?;
      W['toallaAGotea'] = 0;
      W['toallaBGotea'] = 0;
      await wait(120);
    },
    // Story 74: pile of dry towels on the blanket
    'toallas': (o) async {
      W['toallas'] = _n(o['n']).clamp(0, 3);
      await wait(120);
    },
    // Story 74: frog brings a towel from the rope (or abuela dries the frog)
    'seca74': (o) async {
      // OPEN: no spot beside the rope or the child for carrying; frog carries the towel sprite in hand, bounces
      // to `sale` (or stays on `manta_coqui` when dried by abuela), then returns to `manta_coqui`.
      final quien = o['quien'] as String?;
      final color = (o['color'] as String?) ?? 'azul';
      final ok = _n(o['ok']) == 1;
      if (quien == 'coqui') {
        W['coquiToalla'] = color;
        await _brinco();
        W['coquiGotea'] = 0;
        await wait(140);
        W['coquiToalla'] = null;
        return;
      }
      final p = _gente[quien] as Map<String, dynamic>?;
      if (p == null) return;
      W['coquiToalla'] = color;
      await _brinco();
      W['coquiToalla'] = null;
      p['toalla'] = color;
      if (ok) {
        await wait(200);
        p['gotea'] = 0;
        p['toalla'] = null;
        if (W['toallaA'] == color) W['toallaAGotea'] = 1;
        if (W['toallaB'] == color) W['toallaBGotea'] = 1;
      } else {
        // Wet towel: child jumps in shock; abuela lifts hat briefly and hands a dry towel from the pile.
        for (final dy in const [-5, 0, -4, 0]) {
          p['dy'] = dy;
          await wait(70);
        }
        p['toalla'] = null;
        W['abuelaAcostada'] = 0;
        await wait(140);
        p['gotea'] = 0;
        W['abuelaAcostada'] = 1;
      }
    },
    // Story 74 ending: sunset, abuela packs basket, towels by what is left
    'final74': (o) async {
      // OPEN: abuela packs basket (`canasta = 0`) at `manta_abuela`; Luis & Carmen stand at `pie1`/`pie2` wrapped
      // in towels; frog at `manta_coqui` is wrapped in a towel (3) or under abuela's hat (1 or 2).
      final n = _n(o['n']).clamp(1, 3);
      W['abuelaAcostada'] = 0;
      W['canasta'] = 0;
      W['toallas'] = n;
      W['coquiGotea'] = 0;
      final luis = _gente['luis'] as Map<String, dynamic>?;
      final carmen = _gente['carmen'] as Map<String, dynamic>?;
      if (luis != null) {
        luis['gotea'] = 0;
        luis['abanica'] = 0;
        await _movePerson(luis, 'pie1', steps: 4, sent: 0, wade: 0);
        luis['toalla'] = 'azul';
      }
      if (carmen != null) {
        carmen['gotea'] = 0;
        carmen['abanica'] = 0;
        await _movePerson(carmen, 'pie2', steps: 4, sent: 0, wade: 0);
        carmen['toalla'] = n >= 2 ? 'amarillo' : 'azul';
      }
      W['final74'] = n;
      await wait(240);
    },
    // Gestures & shared acts
    'gesto': (o) async {
      final quien = o['quien'] as String?, que = o['que'] as String?;
      if (quien == null || que == null) return;
      if (quien == 'coqui') {
        await _brinco();
        return;
      }
      final p = _gente[quien] as Map<String, dynamic>?;
      if (p == null || p['vis'] == 0) return;
      switch (que) {
        case 'saluda':
          for (var i = 0; i < 4; i++) {
            p['pose'] = i.isEven ? 'saluda0' : 'saluda1';
            p['dy'] = i.isEven ? -2 : 0;
            await wait(100);
          }
          p['pose'] = 'idle';
          p['dy'] = 0;
        case 'no':
          for (final d in const [-2, 2, -2, 0]) {
            p['dx'] = d;
            await wait(80);
          }
        case 'si':
          for (var i = 0; i < 2; i++) {
            p['dy'] = -3;
            await wait(100);
            p['dy'] = 0;
            await wait(80);
          }
        case 'rie':
          p['pose'] = 'rie';
          await wait(220);
          p['pose'] = 'idle';
        case 'mira':
          p['dy'] = -1;
          await wait(180);
          p['dy'] = 0;
        case 'senala':
          p['pose'] = 'senala';
          if (o['a'] == 'bote') {
            W['boteRock'] = 1;
            W['gaviota'] = <String, dynamic>{'x': 190, 'y': 14};
          }
          await wait(220);
          p['pose'] = 'idle';
          W['boteRock'] = 0;
          W['gaviota'] = null;
        case 'arrodilla':
          p['sent'] = 1;
          await wait(160);
        case 'sienta':
          // OPEN: Carmen sits at `pie2` when asking to eat bread (no bread-giving act named).
          p['abanica'] = 0;
          p['sent'] = 1;
          await wait(160);
        case 'abanica':
          p['abanica'] = 1;
          await wait(160);
        case 'gotea':
          p['gotea'] = 1;
          await wait(160);
        case 'acuesta':
          if (quien == 'abuela') {
            W['abuelaAcostada'] = 1;
          }
          await wait(200);
        case 'tapa':
          W['tapa'] = 1;
          await wait(200);
          W['tapa'] = 0;
        case 'toca':
          // OPEN: abuela sits on `manta_abuela`, no spot beside the rope; she reaches toward the rope towels.
          // In story 74 step 2 (no drying act named), when Luis is dripping at `sale`, he dries off with the red
          // towel (leaving it dripping on the rope) and steps back to `pie1`.
          p['pose'] = 'saluda0';
          await wait(200);
          p['pose'] = 'idle';
          final luis = _gente['luis'] as Map<String, dynamic>?;
          if (luis != null &&
              luis['spot'] == 'sale' &&
              _n(luis['gotea']) == 1) {
            luis['gotea'] = 0;
            W['toallaAGotea'] = 1;
            await _movePerson(luis, 'pie1', steps: 4, sent: 0, wade: 0);
          }
      }
    },
    'marca': (o) async {
      final m = W['marcas'];
      if (m is List) {
        final i = m.indexOf(null);
        if (i >= 0) m[i] = o['que'];
      }
      await wait(120);
    },
    'fin': (o) async {
      await _brinco();
      await wait(200);
    },
  };
}
