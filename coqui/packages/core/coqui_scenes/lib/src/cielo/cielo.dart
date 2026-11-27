// El cielo (place 7, La playa, scene 4: `cielo`; stories 81 to 83): a NEW scene, written from its script's
// "Needs" list (historia/notas/guiones/cielo.md) on its set (cielo_set.dart) and its sheet (cielo-sheet.json,
// read by SceneSheet). There is no old scene file: every act is this file's, each doing on screen what the Needs
// list says, every place from the sheet (spots, set thing boxes, sky boxes, overlay visor, depth rule, shadows).
// Where the sheet names no place or an act is unstated in the script, the code does the plainest thing that keeps
// the story playing and marks it `OPEN:`.
//
// The drawing (the sheet's `front`): every sprite stands with its feet's bottom edge on its spot's row and its
// middle on its column (rules.anchor); abuela in her rocking chair hangs by her lap (17, 36); the round eyepiece
// picture `visor` is drawn in screen space over everything (`d: 99`); every other sprite pixel is hidden by every
// LIVE set pixel (including swaying palm fronds: `engine.zb`) nearer than its upright plane plus `front.bias`.
// Between two sprites the nearer pixel wins (tie within 0.001 goes to the later layer; the frog is drawn last among
// world sprites, below screen overlays).
// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/src/cielo/cielo_places.dart';
import 'package:coqui_scenes/src/cielo/cielo_set.dart';
import 'package:coqui_scenes/src/cielo/cielo_sprites.dart';
import 'package:coqui_scenes/src/colmado/colmado_cast.dart' show inkBottom;
import 'package:coqui_scenes/src/scene_set.dart';
import 'package:coqui_scenes/src/sheet_cache.dart';

/// The scene "El cielo", made from its sheet (read first: `loadScene`).
Scene createCielo() => Cielo(sceneSheetOf('cielo'));

int _round(num v) => (v + 0.5).floor();

int _n(Object? v) {
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? 0;
  return 0;
}

/// One sprite of the sprite layer, placed: its picture, its top left on the 240 × 216 picture, the screen row of its
/// anchor and the depth there (front.plane), and who or what it is.
class CieloItem {
  CieloItem(
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

  /// Screen-space overlay drawn over the set and world sprites (e.g. `visor`, weather FX, celebration cues).
  final bool overlay;
}

/// Every person El cielo knows, by speaker key (cielo.md, "Needs").
const List<String> CIELO_PERSONAS = ['abuela', 'luis', 'carmen'];

class Cielo extends Escena implements SetScene, SetOverSprites {
  Cielo(this.ss)
    : sheet = identical(ss, _lastSs)
          ? _lastSheet!
          : (_lastSheet = ss.legacy()) {
    _p = identical(ss, _lastSs)
        ? _lastPlaces!
        : (_lastPlaces = CieloPlaces(ss));
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
  static CieloPlaces? _lastPlaces;

  /// The new scene's sheet (SceneSheet).
  final SceneSheet ss;

  @override
  final Sheet sheet;

  late final CieloPlaces _p;

  /// The scene's places, from its sheet.
  CieloPlaces get places => _p;

  @override
  String get id => 'cielo';

  @override
  late final Map<String, List<num>> CAM;

  late final Map<String, List<num>> LUGAR;

  @override
  Map<String, List<num>> get lugar => LUGAR;

  @override
  late final List<Thing> cosas;

  @override
  PpEngine newEngine({bool still = false}) => cieloEngine(still: still);

  @override
  PpEngine get projection => _p.e;

  List<num> _frogAt(CieloAt a) => [_round(a.sx) - 16, _round(a.sy) - 25, 1];

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
        if (b is Map && b['set'] is Map && (b['set'] as Map)['cielo'] != null) {
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

  @override
  Map<String, dynamic> fresh(Map<String, dynamic> story) {
    final acts = _actsOf([story['beats'], story['final']]);
    bool has(String a) => acts.any((o) => o['act'] == a);
    final set = _firstSet(story['beats']);
    final is83 =
        has('mira83') ||
        has('luz83') ||
        has('deseos') ||
        has('canta83') ||
        has('final83');
    final is82 =
        !is83 &&
        (has('velas') ||
            has('toldo') ||
            has('tapa82') ||
            has('tiempo82') ||
            has('final82'));
    final storyNum = is83 ? 83 : (is82 ? 82 : 81);
    final cielo =
        (set['cielo'] as String?) ??
        (is83 ? 'noche' : (is82 ? 'gris' : 'azul'));
    final startSpot = is83 ? 'coqui.telescopio' : (is82 ? 'piso' : 'manta');
    final q = _frogAt(_p.at(startSpot));

    final gente = <String, dynamic>{
      'abuela': _person('mecedora', sent: 1),
      'luis': _person(is83 ? 'luis.tel' : (is82 ? 'mesa1' : 'chiringa_pie')),
      'carmen': _person(is83 ? 'carmen.tel' : (is82 ? 'mesa2' : 'bola1')),
    };

    return <String, dynamic>{
      'story': storyNum,
      'cielo': cielo,
      'toldo': 'arriba',
      'gente': gente,
      'perroVis': 0,
      // Radio (stories 81 & 82)
      'radioVis': is83 ? 0 : 1,
      'radioNotas': 0,
      'radioSol': 0,
      // Story 81 props & state
      'jugos': is83 || is82 ? 0 : 3,
      'sombrillaVis': is83 || is82 ? 0 : 1,
      'sombrillaAbierta': 0,
      'chiringaVis': is83 || is82 ? 0 : 1,
      'chiringaVuela': 0,
      'chiringaPos': null, // {x, y} while flying
      'bolaVis': is83 || is82 ? 0 : 1,
      'bolaEn': 'carmen', // 'carmen' (bola1 + [15,0]), 'bola', or 'vuelo'
      'bolaPos': null, // {x, y} during kick animation
      'tropiezo': null, // 'sombrilla' | 'chiringa' | 'bola' | null
      'gaviota': null, // {x, y}
      'nubeGrande': null, // {x, y}
      'vientoFx': 0,
      'final81': 0,
      // Story 82 props & state
      'velas': is82 ? 3 : 0,
      'velaLean': 0,
      'velaHiss': 0,
      'chalVis': is82 ? 1 : 0,
      'chalPuesto': is83 ? 1 : 0,
      'tapaVis': is82 ? 1 : 0,
      'tapaPuesta': 0,
      'lluviaFx': 0,
      'gotaFx': 0,
      'abuelaVela': 0,
      'cenaVis': 0,
      'final82': 0,
      // Story 83 props & state
      'telVis': is83 ? 1 : 0,
      'telDir': 'up', // 'up' | 'luna' | 'estrella'
      'visor': null, // 'luna' | 'estrella' | null
      'visorCae': 0,
      'visorFrame': 0,
      'luzFugaz': null, // {x, y}
      'deseos': is83 ? 3 : 0,
      'dedosFx': 0,
      'ojosFx': 0,
      'cantaFx': 0,
      'ecos': 0,
      'final83': 0,
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
    final c = W['cielo'];
    final cielo =
        c is String &&
            const ['azul', 'nublado', 'gris', 'rosa', 'noche'].contains(c)
        ? c
        : 'azul';
    final t = W['toldo'];
    final toldo = t is String && const ['arriba', 'abajo'].contains(t)
        ? t
        : 'arriba';
    return '$cielo-$toldo';
  }

  @override
  void buildSet(PpEngine e, PpBuild b, Map<String, dynamic> W) =>
      buildSetFor(e, b, setKey(W));

  final Map<PpEngine, CieloSet> _sets = {};

  @override
  void buildSetFor(PpEngine e, PpBuild b, String key) =>
      (_sets[e] ??= CieloSet(e, b)).buildSet(CieloState.fromKey(key));

  @override
  bool get frogShadow => false;

  /* ---------- where everybody is ---------- */

  Map<String, dynamic> get _gente => W['gente'] as Map<String, dynamic>;

  CieloAt _atOf(Map<String, dynamic> o) =>
      _p.atWorld(o['x'] as num, o['y'] as num, o['z'] as num);

  CieloAt _frogPoint(Map<String, dynamic> q) {
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
  ) {
    final pose = (p['pose'] as String?) ?? 'idle';
    if (id == 'abuela') {
      final abPose = switch (pose) {
        'saluda0' || 'saluda1' || 'mano' => 'saluda0',
        'senala' => 'tu',
        'rie' => 'yo',
        'brazos' => 'yo',
        _ => 'idle',
      };
      final s = _spr(
        'cl_abS_${abPose}_$open',
        () => mkAbuelaS(abPose, open, false),
      );
      // cielo-sheet.json rules.anchor: abuelaS hangs by her lap (17, 36).
      return (s: s, ax: 17, ay: 36);
    }
    final who = id == 'luis' ? FAM['hermano']! : FAM['hermana']!;
    final kp = switch (pose) {
      'saluda0' => 'wave0',
      'saluda1' => 'wave1',
      'senala' => 'tu',
      'rie' => 'yo',
      'mano' => 'offer',
      'mira' => 'idle',
      'dedos' => 'offer',
      'ojos' => 'yo',
      _ => 'idle',
    };
    final s = _spr(
      'cl_${id}_${kp}_$open',
      () => mkPersona(who, kp, open, false),
    );
    return (s: s, ax: PX, ay: inkBottom(s));
  }

  String? _talker() {
    try {
      return host.TALK;
    } catch (_) {
      return null;
    }
  }

  /// Every sprite of the frame [w] as it is placed, except the frog. The rules' tests read it; [draw] draws it.
  List<CieloItem> items(Map<String, dynamic> w, int a) {
    final out = <CieloItem>[];
    final talk = _talker();
    final gente = (w['gente'] as Map<String, dynamic>?) ?? const {};
    final anim = (F >> 2) + a;

    // 1. People (abuela at mecedora, luis, carmen)
    for (final en in gente.entries) {
      final p = en.value as Map<String, dynamic>;
      if (p['vis'] == 0) continue;
      final open = talk == en.key && a % 2 == 1;
      final sp = _personSprite(en.key, p, open);
      final at = _atOf(p);
      final sx = _round(at.sx) + _n(p['dx']);
      final sy = _round(at.sy) + _n(p['dy']);
      out.add(
        CieloItem(
          sp.s,
          sx - sp.ax,
          sy - sp.ay,
          sy,
          at.d,
          tag: 'persona:${en.key}',
        ),
      );
      // Draped shawl on abuela's shoulders (below head rows 123..136: starts at sy - 20 = 139)
      if (en.key == 'abuela' && _n(w['chalPuesto']) == 1) {
        final sh = _spr('cl_chal_puesto', mkChalPuesto);
        out.add(
          CieloItem(sh, sx - 9, sy - 20, sy, at.d + .01, tag: 'cosa:chal'),
        );
      }
      // Candle carried by abuela when shivering in story 82 cold wrong branch
      if (en.key == 'abuela' && _n(w['abuelaVela']) == 1) {
        final vl = _spr('cl_vela_lit', () => mkVela(lit: true));
        out.add(
          CieloItem(
            vl,
            sx + 10,
            sy - 16,
            sy,
            at.d + .02,
            tag: 'fx:abuela_vela',
          ),
        );
      }
      // Carmen's raised fingers indicator (`gesto dedos`) or wishing sparkles (`gesto ojos`)
      if (en.key == 'carmen') {
        final dedos = _n(w['dedosFx']);
        if (dedos > 0) {
          final dd = _spr('cl_dedos_$dedos', () => mkDedos(dedos));
          out.add(
            CieloItem(dd, sx + 8, sy - 36, sy, at.d + .02, tag: 'fx:dedos'),
          );
        }
        if (_n(w['ojosFx']) == 1) {
          final oj = _spr('cl_ojos_${anim % 2}', () => mkOjosDeseo(anim % 2));
          out.add(
            CieloItem(oj, sx + 8, sy - 40, sy, at.d + .02, tag: 'fx:ojos'),
          );
        }
      }
    }

    // Optional Canelo (`perro`: listed in Needs things; off in stories 81-83 unless toggled)
    if (_n(w['perroVis']) == 1) {
      final at = _p.at('bola2');
      final s = _spr('cl_perro_lie', () => mkPerro('lie', false));
      final sx = _round(at.sx), sy = _round(at.sy);
      out.add(
        CieloItem(
          s,
          sx - 15,
          sy - inkBottom(s),
          sy,
          at.d,
          tag: 'persona:perro',
        ),
      );
    }

    // 2. Radio on the table (stories 81 & 82)
    if (_n(w['radioVis']) == 1) {
      final at = _p.at('radio');
      final s = _spr('cl_radio', mkRadio);
      final sx = _round(at.sx), sy = _round(at.sy);
      out.add(CieloItem(s, sx - 6, sy - s.h, sy, at.d, tag: 'cosa:radio'));
      // Radio music notes or speaker bubble (placed at cols 70..86, rows 120..134, clear of abuela/luis heads & candles)
      if (_n(w['radioNotas']) == 1) {
        final nt = _spr('cl_rnotas_${anim % 2}', () => mkRadioNotas(anim % 2));
        out.add(CieloItem(nt, 70, 124, sy, at.d + .03, tag: 'fx:radio_notas'));
      }
      if (_n(w['radioSol']) == 1 || talk == 'radio') {
        final sol = _n(w['radioSol']) == 1;
        final bb = _spr('cl_rbub_$sol', () => mkRadioBurbuja(sol: sol));
        out.add(CieloItem(bb, 70, 120, sy, at.d + .03, tag: 'fx:radio_bub'));
      }
    }

    // 3. Story 81 props: tray of glasses (`bandeja`/`jugos`), umbrella (`sombrilla`), kite (`chiringa`), ball (`bola`)
    final jugosN = _n(w['jugos']);
    if (jugosN > 0) {
      final at = _p.at('bandeja');
      final fin = _n(w['final81']) > 0;
      final s = _spr(
        'cl_bandeja_${jugosN}_$fin',
        () => mkBandeja(jugosN, finalMode: fin),
      );
      final sx = _round(at.sx), sy = _round(at.sy);
      out.add(CieloItem(s, sx - 10, sy - s.h, sy, at.d, tag: 'cosa:jugos'));
      if (_n(w['final81']) == 3) {
        final cor = _spr('cl_corazon', mkCorazonCielo);
        out.add(
          CieloItem(cor, sx - 5, sy - 24, sy, at.d + .03, tag: 'fx:corazon'),
        );
      }
    }

    final trop = w['tropiezo'] as String?;

    if (_n(w['sombrillaVis']) == 1) {
      if (trop == 'sombrilla') {
        final at = _p.at('bandeja');
        final s = _spr('cl_somb_caida', mkSombrillaCaida);
        final sx = _round(at.sx), sy = _round(at.sy);
        out.add(
          CieloItem(
            s,
            sx - 12,
            sy - s.h - 2,
            sy,
            at.d + .02,
            tag: 'cosa:sombrilla',
          ),
        );
      } else {
        final at = _p.at('sombrilla');
        final open = _n(w['sombrillaAbierta']) == 1;
        final s = open
            ? _spr('cl_somb_open', mkSombrillaOpen)
            : _spr('cl_somb_shut', mkSombrillaShut);
        final sx = _round(at.sx), sy = _round(at.sy);
        out.add(
          CieloItem(
            s,
            sx - (open ? 32 : 4),
            sy - s.h,
            sy,
            at.d,
            tag: 'cosa:sombrilla',
          ),
        );
      }
    }

    if (_n(w['chiringaVis']) == 1) {
      if (trop == 'chiringa') {
        final at = _p.at('bandeja');
        final s = _spr('cl_chiringa', mkChiringa);
        final sx = _round(at.sx), sy = _round(at.sy);
        out.add(
          CieloItem(
            s,
            sx - 10,
            sy - s.h - 3,
            sy,
            at.d + .02,
            tag: 'cosa:chiringa',
          ),
        );
      } else if (_n(w['chiringaVuela']) == 1) {
        final pos = w['chiringaPos'] as Map?;
        final kx = pos != null ? _n(pos['x']) : 104;
        final ky = pos != null ? _n(pos['y']) : 72;
        final s = _spr(
          'cl_chir_vuela_${anim % 2}',
          () => mkChiringaVuela(anim % 2),
        );
        out.add(CieloItem(s, kx - 10, ky - 10, ky, 5.0, tag: 'cosa:chiringa'));
      } else {
        final at = _p.at('chiringa');
        final s = _spr('cl_chiringa', mkChiringa);
        final sx = _round(at.sx), sy = _round(at.sy);
        out.add(
          CieloItem(s, sx - 10, sy - s.h, sy, at.d, tag: 'cosa:chiringa'),
        );
      }
    }

    if (_n(w['bolaVis']) == 1) {
      final s = _spr('cl_bola', mkBolaCielo);
      if (trop == 'bola') {
        final at = _p.at('bandeja');
        final sx = _round(at.sx), sy = _round(at.sy);
        out.add(
          CieloItem(s, sx - 4, sy - s.h - 4, sy, at.d + .02, tag: 'cosa:bola'),
        );
      } else if (w['bolaPos'] is Map) {
        final pos = w['bolaPos'] as Map;
        final bx = _n(pos['x']), by = _n(pos['y']);
        final at = _p.at('bola');
        out.add(
          CieloItem(s, bx - 4, by - s.h, by, at.d + .01, tag: 'cosa:bola'),
        );
      } else if (w['bolaEn'] == 'carmen') {
        // OPEN: cielo-preview.html moment 1 draws the ball at Carmen's feet 15 px to her right (no separate spot).
        final at = _p.at('bola1');
        final sx = _round(at.sx) + 15, sy = _round(at.sy);
        out.add(
          CieloItem(s, sx - 4, sy - s.h, sy, at.d + .01, tag: 'cosa:bola'),
        );
      } else {
        final at = _p.at('bola');
        final sx = _round(at.sx), sy = _round(at.sy);
        out.add(CieloItem(s, sx - 4, sy - s.h, sy, at.d, tag: 'cosa:bola'));
      }
    }

    // 4. Story 82 props: three candles in jars (`velas`), folded shawl (`chal`), glass cover (`tapa`), supper
    final velasN = _n(w['velas']);
    if (_n(w['story']) == 82) {
      final at = _p.at('velas');
      final sx = _round(at.sx), sy = _round(at.sy);
      final lean = _n(w['velaLean']) == 1 && _n(w['tapaPuesta']) == 0;
      final hiss = _n(w['velaHiss']) == 1;
      const offs = [-7, 0, 7];
      for (var i = 0; i < 3; i++) {
        final lit = i < velasN;
        final s = _spr(
          'cl_vela_${lit}_${lean}_${!lit && hiss}',
          () => mkVela(lit: lit, lean: lit && lean, hiss: !lit && hiss),
        );
        out.add(
          CieloItem(
            s,
            sx + offs[i] - 3,
            sy - s.h,
            sy,
            at.d,
            tag: 'cosa:vela${i + 1}',
          ),
        );
      }
      if (_n(w['cenaVis']) == 1) {
        final cn = _spr('cl_cena', mkCena);
        // Placed at table's left edge clear of candles and radio
        out.add(
          CieloItem(cn, sx - 20, sy - cn.h + 2, sy, at.d + .01, tag: 'fx:cena'),
        );
      }
      if (_n(w['final82']) == 3) {
        final cor = _spr('cl_corazon', mkCorazonCielo);
        out.add(
          CieloItem(cor, sx - 5, sy - 26, sy, at.d + .06, tag: 'fx:corazon'),
        );
      }
    }

    if (_n(w['chalVis']) == 1 && _n(w['chalPuesto']) == 0) {
      final at = _p.at('chal');
      final s = _spr('cl_chal', mkChal);
      final sx = _round(at.sx), sy = _round(at.sy);
      out.add(CieloItem(s, sx - 5, sy - s.h, sy, at.d, tag: 'cosa:chal'));
    }

    if (_n(w['tapaVis']) == 1) {
      final puesta = _n(w['tapaPuesta']) == 1;
      final at = _p.at(puesta ? 'tapa_puesta' : 'tapa');
      final s = puesta
          ? _spr('cl_tapa_puesta', mkTapaPuesta)
          : _spr('cl_tapa_suelo', mkTapaSuelo);
      final sx = _round(at.sx), sy = _round(at.sy);
      out.add(
        CieloItem(
          s,
          sx - (puesta ? 13 : 9),
          sy - s.h,
          sy,
          at.d + (puesta ? .05 : 0.0),
          tag: 'cosa:tapa',
        ),
      );
    }

    // 5. Story 83 props: telescope (`telescopio`) and round eyepiece picture (`visor`)
    if (_n(w['telVis']) == 1) {
      final at = _p.at('telescopio');
      final dir = (w['telDir'] as String?) ?? 'up';
      final s = _spr('cl_tel_$dir', () => mkTelescopio(dir: dir));
      final sx = _round(at.sx), sy = _round(at.sy);
      out.add(CieloItem(s, sx - 7, sy - s.h, sy, at.d, tag: 'cosa:telescopio'));
    }

    final visor = w['visor'] as String?;
    if (visor != null && (visor == 'luna' || visor == 'estrella')) {
      final sc = _p.screen('visor');
      final cae = _n(w['visorCae']) == 1;
      final vf = _n(w['visorFrame']);
      final s = _spr(
        'cl_visor_${visor}_${cae}_${cae ? vf % 3 : 0}',
        () => mkVisor(visor, cae: cae, frame: vf),
      );
      out.add(
        CieloItem(
          s,
          sc[0] - 14,
          sc[1] - 14,
          sc[1],
          99.0,
          tag: 'cosa:visor',
          overlay: true,
        ),
      );
    }

    // 6. Transient weather & night FX (cleared before act completes)
    final gav = w['gaviota'];
    if (gav is Map) {
      final s = _spr('cl_gav_${anim % 2}', () => mkGaviotaCielo(anim % 2));
      final gx = _n(gav['x']), gy = _n(gav['y']);
      out.add(
        CieloItem(s, gx - 7, gy - 4, gy, 5.0, tag: 'fx:gaviota', overlay: true),
      );
    }
    final ng = w['nubeGrande'];
    if (ng is Map) {
      final s = _spr('cl_nube_grande', mkNubeGrande);
      final nx = _n(ng['x']), ny = _n(ng['y']);
      out.add(
        CieloItem(
          s,
          nx - 18,
          ny - 9,
          ny,
          5.0,
          tag: 'fx:nube_grande',
          overlay: true,
        ),
      );
    }
    if (_n(w['vientoFx']) == 1) {
      final s = _spr('cl_viento_${anim % 3}', () => mkVientoRacha(anim % 3));
      out.add(CieloItem(s, 96, 76, 82, 5.0, tag: 'fx:viento', overlay: true));
    }
    if (_n(w['lluviaFx']) == 1) {
      final s = _spr('cl_lluvia_${anim % 4}', () => mkLluvia(anim % 4));
      out.add(CieloItem(s, 22, 48, 190, 8.0, tag: 'fx:lluvia', overlay: true));
    }
    if (_n(w['gotaFx']) == 1) {
      final at = _p.at('velas');
      final s = _spr('cl_gota_${anim % 2}', () => mkGotaTabla(anim % 2));
      out.add(
        CieloItem(
          s,
          _round(at.sx) - 5,
          _round(at.sy) - 14,
          _round(at.sy),
          at.d + .06,
          tag: 'fx:gota',
        ),
      );
    }
    final lf = w['luzFugaz'];
    if (lf is Map) {
      final s = _spr('cl_luz_${anim % 2}', () => mkLuzFugaz(anim % 2));
      final lx = _n(lf['x']), ly = _n(lf['y']);
      out.add(
        CieloItem(s, lx - 9, ly - 4, ly, 5.0, tag: 'fx:luz', overlay: true),
      );
    }
    if (_n(w['cantaFx']) == 1) {
      final q = w['cq'] as Map<String, dynamic>;
      final fp = _frogPoint(q);
      final s = _spr('cl_nota_${anim % 2}', () => mkNotaCoqui(anim % 2));
      out.add(
        CieloItem(
          s,
          _round(fp.sx) + 12,
          _round(fp.sy) - 34,
          _round(fp.sy),
          fp.d + .02,
          tag: 'fx:nota',
        ),
      );
    }
    final ecos = _n(w['ecos']);
    if (ecos > 0) {
      final s = _spr('cl_eco_${anim % 2}', () => mkEcoCoqui(anim % 2));
      // Answering voices from the palm (right) and deck beam (left), clear of sky boxes & heads
      const pts = [(194, 86), (62, 74), (132, 82)];
      for (var i = 0; i < ecos && i < pts.length; i++) {
        out.add(
          CieloItem(
            s,
            pts[i].$1,
            pts[i].$2,
            pts[i].$2,
            5.0,
            tag: 'fx:eco_${i + 1}',
            overlay: true,
          ),
        );
      }
      if (_n(w['final83']) == 3) {
        final cor = _spr('cl_corazon', mkCorazonCielo);
        out.add(
          CieloItem(cor, 114, 72, 72, 5.0, tag: 'fx:corazon', overlay: true),
        );
      }
    }

    return out;
  }

  static final Map<String, Sprite> _frogSprites = {};

  /// [items] plus the frog (as the host draws him), for `draw` and for `CieloRules`.
  List<CieloItem> placed(Map<String, dynamic> w, int a) {
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
      out.add(CieloItem(spr, ox, oy, fsy, at.d, tag: 'coqui'));
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
    // Live depth (after engine.drawLeaves) so swaying palm fronds hide sprites behind them (cielo-sheet.json front.plane).
    _setZ = engine.zb;
  }

  static final double _t30 = math.tan(math.pi / 6);

  void _put(
    CieloItem it,
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
    if (_n(W['perroVis']) == 1) {
      final at = _p.at('bola2');
      final r = _p.radius('perro');
      if (r != null) out.add((x: at.x, y: at.y, z: 0.0, r: r));
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
    if (who == 'radio') {
      final at = _p.at('radio');
      return [_round(at.sx), _round(at.sy) - 14];
    }
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
    final dy = who == 'abuela' ? 38 : 42;
    return [_round(at.sx), _round(at.sy) - dy];
  }

  /* ---------- touch things & hit testing ---------- */

  static List<int>? _itemBox(
    List<CieloItem> list,
    bool Function(CieloItem) test,
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

  bool _hitsOpenUmbrella(num x, num y, Map<String, dynamic> w) {
    // Canopy [119,124,64,16] or pole pixels, without stealing touches from frog or tray.
    for (final it in items(w, 0)) {
      if (it.tag != 'cosa:sombrilla') continue;
      final px = x.floor() - it.left;
      final py = y.floor() - it.top;
      if (px < 0 || px >= it.s.w || py < 0 || py >= it.s.h) return false;
      if (it.s.px[py * it.s.w + px] >>> 24 != 0) return true;
      // Canopy bounding rectangle for forgiving taps on the open umbrella
      return py < 16;
    }
    return false;
  }

  List<Thing> _things() => [
    // Foreground sprite things (people & interactive props)
    Thing(
      id: 'radio',
      si: (w) => _n(w['radioVis']) == 1,
      box: (w) => _spriteBox(w, 'cosa:radio') ?? _p.spotBox('radio'),
    ),
    Thing(
      id: 'velas',
      si: (w) => _n(w['story']) == 82,
      box: (w) => _velasBox(w) ?? _p.spotBox('velas'),
    ),
    Thing(
      id: 'tapa',
      si: (w) => _n(w['tapaVis']) == 1,
      box: (w) => _spriteBox(w, 'cosa:tapa') ?? _p.spotBox('tapa'),
    ),
    Thing(
      id: 'chal',
      si: (w) => _n(w['chalVis']) == 1 || _n(w['chalPuesto']) == 1,
      box: (w) => _spriteBox(w, 'cosa:chal') ?? _p.spotBox('chal'),
    ),
    Thing(
      id: 'jugos',
      si: (w) => _n(w['jugos']) > 0,
      box: (w) => _spriteBox(w, 'cosa:jugos') ?? _p.spotBox('bandeja'),
    ),
    Thing(
      id: 'chiringa',
      si: (w) => _n(w['chiringaVis']) == 1,
      box: (w) => _spriteBox(w, 'cosa:chiringa') ?? _p.spotBox('chiringa'),
    ),
    Thing(
      id: 'bola',
      si: (w) => _n(w['bolaVis']) == 1,
      box: (w) => _spriteBox(w, 'cosa:bola') ?? _p.spotBox('bola'),
    ),
    Thing(
      id: 'telescopio',
      si: (w) => _n(w['telVis']) == 1,
      box: (w) => _spriteBox(w, 'cosa:telescopio') ?? _p.spotBox('telescopio'),
    ),
    // People
    for (final who in CIELO_PERSONAS)
      Thing(
        id: who,
        si: (w) => ((w['gente'] as Map?)?[who] as Map?)?['vis'] != 0,
        box: (w) => _spriteBox(w, 'persona:$who'),
      ),
    Thing(
      id: 'perro',
      si: (w) => _n(w['perroVis']) == 1,
      box: (w) => _spriteBox(w, 'persona:perro'),
    ),
    // Open umbrella checked after frog/tray/people so its bounding box does not shadow them
    Thing(
      id: 'sombrilla',
      si: (w) => _n(w['sombrillaVis']) == 1,
      box: (w) => _spriteBox(w, 'cosa:sombrilla') ?? _p.spotBox('sombrilla'),
      hand: (w) {
        final b = _spriteBox(w, 'cosa:sombrilla') ?? _p.spotBox('sombrilla');
        return [b[0] + b[2] / 2, b[1] + 8];
      },
    ),
    // Set things: blind's cord, sky objects (before whole sky)
    Thing(
      id: 'cuerda',
      si: (w) => _n(w['story']) == 82,
      box: (w) => _p.box('cuerda'),
    ),
    Thing(
      id: 'luna',
      si: (w) => w['cielo'] == 'noche',
      box: (w) => _p.box('luna'),
    ),
    Thing(
      id: 'estrella',
      si: (w) => w['cielo'] == 'noche',
      box: (w) => _p.box('estrella'),
    ),
    Thing(
      id: 'nube',
      si: (w) => w['cielo'] == 'azul' || w['cielo'] == 'nublado',
      box: (w) => _p.box('nube'),
    ),
    Thing(
      id: 'cielo',
      box: (w) => _p.box('cielo'),
      // Hint hand centred inside the visible window's sky, clear of the sun and cloud
      hand: (w) => const [110, 56],
    ),
  ];

  @override
  String? hit(num x, num y, Map<String, dynamic> w) {
    // Check frog first when visible so nothing with a wider bounding box (like open umbrella) steals a frog tap.
    final q = w['cq'] as Map<String, dynamic>?;
    if (q != null && jsTruthy(q['vis'])) {
      final fb = host.frogBox(q);
      if (x >= fb.x && x < fb.x + fb.w && y >= fb.y && y < fb.y + fb.h) {
        return 'coqui';
      }
    }
    for (final t in cosas) {
      if (t.si != null && !t.si!(w)) continue;
      if (t.id == 'sombrilla' &&
          _n(w['sombrillaAbierta']) == 1 &&
          w['tropiezo'] != 'sombrilla') {
        if (_hitsOpenUmbrella(x, y, w)) return 'sombrilla';
        continue;
      }
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

  /* ---------- acts (cielo.md "Needs" + gen_cielo.py) ---------- */

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
      final raw = (o['a'] as String?) ?? 'manta';
      // OPEN: gen_cielo.py story 83 calls `ir a=telescopio`, while cielo-sheet.json separates `telescopio` (stand, z 0)
      // and `coqui.telescopio` (frog on top of the stand, z 0.9); resolve `telescopio` to `coqui.telescopio` for the frog.
      final spot = raw == 'telescopio' ? 'coqui.telescopio' : raw;
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
    }),
    'radio': (o) => _run(o, () async {
      W['radioVis'] = 1;
      if (_n(o['sol']) == 1) {
        W['radioSol'] = 1;
        await wait(450);
        W['radioSol'] = 0;
        return;
      }
      if (_n(o['on']) == 1) {
        W['radioNotas'] = 1;
        await wait(350);
        W['radioNotas'] = 0;
      }
    }),
    'jugos': (o) => _run(o, () async {
      W['jugos'] = _n(o['n']).clamp(1, 3);
      await wait(120);
    }),
    'sombrilla81': (o) => _run(o, () async {
      final open = _n(o['abierta']) == 1;
      W['sombrillaVis'] = 1;
      W['tropiezo'] = null;
      if (!open) {
        // Before round B: also return kite to sand and ball to its game spot so all three things are ready.
        W['chiringaVuela'] = 0;
        W['chiringaPos'] = null;
        if (W['bolaEn'] == 'vuelo') W['bolaEn'] = 'bola';
      }
      W['sombrillaAbierta'] = open ? 1 : 0;
      await wait(240);
    }),
    'vuela81': (o) => _run(o, () async {
      final ok = _n(o['ok']) == 1;
      W['tropiezo'] = null;
      final luis = _gente['luis'] as Map<String, dynamic>;
      luis['pose'] = 'mano';
      if (ok) {
        W['chiringaVuela'] = 1;
        for (final pt in const [(180, 150), (156, 118), (126, 92), (104, 72)]) {
          W['chiringaPos'] = {'x': pt.$1, 'y': pt.$2};
          await wait(90);
        }
        luis['pose'] = 'idle';
      } else {
        W['chiringaVuela'] = 0;
        W['chiringaPos'] = null;
        W['tropiezo'] = 'chiringa';
        await wait(250);
        luis['pose'] = 'idle';
      }
    }),
    'bola81': (o) => _run(o, () async {
      final ok = _n(o['ok']) == 1;
      W['tropiezo'] = null;
      final carmen = _gente['carmen'] as Map<String, dynamic>;
      final luis = _gente['luis'] as Map<String, dynamic>;
      carmen['pose'] = 'saluda0';
      if (ok) {
        final b1 = _p.at('bola1'),
            bm = _p.at('bola'),
            b2 = _p.at('chiringa_pie');
        for (final pt in [
          (_round(b1.sx) + 18, _round(b1.sy) - 2),
          (_round(bm.sx), _round(bm.sy) - 8),
          (_round(b2.sx) - 14, _round(b2.sy) - 2),
          (_round(bm.sx), _round(bm.sy) - 6),
          (_round(bm.sx), _round(bm.sy)),
        ]) {
          W['bolaPos'] = {'x': pt.$1, 'y': pt.$2};
          await wait(90);
        }
        W['bolaPos'] = null;
        W['bolaEn'] = 'bola';
        carmen['pose'] = 'idle';
        luis['pose'] = 'idle';
      } else {
        W['bolaPos'] = null;
        W['tropiezo'] = 'bola';
        await wait(250);
        carmen['pose'] = 'idle';
      }
    }),
    'tiempo81': (o) => _run(o, () async {
      final que = (o['que'] as String?) ?? 'sol';
      if (que == 'viento') {
        W['vientoFx'] = 1;
        await wait(360);
        W['vientoFx'] = 0;
      } else if (que == 'nubes') {
        // Wind drops; kite comes down; big cloud slides over the sun
        W['chiringaVuela'] = 0;
        W['chiringaPos'] = null;
        final sun = _p.skyScreen('sun');
        for (final dx in const [-52, -32, -14, 0]) {
          W['nubeGrande'] = {'x': sun[0] + dx, 'y': sun[1]};
          await wait(90);
        }
        W['cielo'] = 'nublado';
        W['nubeGrande'] = null;
      } else {
        // sol: sun comes out bright in blue sky
        W['chiringaVuela'] = 0;
        W['chiringaPos'] = null;
        W['cielo'] = 'azul';
        await wait(240);
      }
    }),
    'tropiezo81': (o) => _run(o, () async {
      final que = (o['que'] as String?) ?? 'bola';
      final carmen = _gente['carmen'] as Map<String, dynamic>;
      final luis = _gente['luis'] as Map<String, dynamic>;
      carmen['pose'] = 'mano';
      luis['pose'] = 'mano';
      W['chiringaVuela'] = 0;
      W['chiringaPos'] = null;
      W['tropiezo'] = que;
      await wait(320);
      carmen['pose'] = 'idle';
      luis['pose'] = 'idle';
    }),
    'final81': (o) => _run(o, () async {
      // OPEN: cielo.md 81 step 8 says abuela comes down from the porch to the tray, but cielo-sheet.json has no sand
      // spot for abuela; she stays at mecedora and celebrates while the tray shows the glasses and straws.
      W['jugos'] = _n(o['n']).clamp(1, 3);
      W['final81'] = W['jugos'];
      W['tropiezo'] = null;
      W['chiringaVuela'] = 0;
      W['chiringaPos'] = null;
      (_gente['abuela'] as Map<String, dynamic>)['pose'] = 'rie';
      (_gente['luis'] as Map<String, dynamic>)['pose'] = 'rie';
      (_gente['carmen'] as Map<String, dynamic>)['pose'] = 'rie';
      await wait(450);
    }),
    'velas': (o) => _run(o, () async {
      W['velas'] = _n(o['n']).clamp(1, 3);
      await wait(120);
    }),
    'toldo': (o) => _run(o, () async {
      W['toldo'] = _n(o['abajo']) == 1 ? 'abajo' : 'arriba';
      await wait(360);
    }),
    'chal': (o) => _run(o, () async {
      W['chalPuesto'] = _n(o['puesto']) == 1 ? 1 : 0;
      await wait(360);
    }),
    'tapa82': (o) => _run(o, () async {
      W['tapaVis'] = 1;
      W['tapaPuesta'] = _n(o['puesta']) == 1 ? 1 : 0;
      if (W['tapaPuesta'] == 1) W['velaLean'] = 0;
      await wait(360);
    }),
    'tiempo82': (o) => _run(o, () async {
      final que = (o['que'] as String?) ?? 'lluvia';
      if (que == 'lluvia') {
        W['lluviaFx'] = 1;
        if (W['toldo'] != 'abajo') {
          W['gotaFx'] = 1;
          W['velaHiss'] = 1;
        }
        await wait(380);
        W['lluviaFx'] = 0;
        W['gotaFx'] = 0;
        W['velaHiss'] = 0;
      } else if (que == 'viento') {
        W['vientoFx'] = 1;
        if (_n(W['tapaPuesta']) == 0) {
          W['velaLean'] = 1;
        }
        await wait(360);
        W['vientoFx'] = 0;
        W['velaLean'] = 0;
      } else {
        // frio: cold gust; if abuela has no shawl, she shivers and briefly takes a candle towards salida
        // OPEN: cielo.md names `puerta`, while cielo-sheet.json names `salida` (outside view at -5,172); abuela
        // shivers at mecedora with a candle and stays in view so abuela-head and spots-in-view hold at act's end.
        final ab = _gente['abuela'] as Map<String, dynamic>;
        W['vientoFx'] = 1;
        if (_n(W['chalPuesto']) == 0) {
          ab['pose'] = 'brazos';
          W['abuelaVela'] = 1;
          await wait(360);
          W['abuelaVela'] = 0;
          ab['pose'] = 'idle';
        } else {
          await wait(260);
        }
        W['vientoFx'] = 0;
      }
    }),
    'final82': (o) => _run(o, () async {
      W['velas'] = _n(o['n']).clamp(1, 3);
      W['final82'] = W['velas'];
      W['toldo'] = 'arriba';
      W['tapaPuesta'] = 0;
      W['chalPuesto'] = 0;
      W['cenaVis'] = 1;
      (_gente['abuela'] as Map<String, dynamic>)['pose'] = 'rie';
      (_gente['luis'] as Map<String, dynamic>)['pose'] = 'rie';
      (_gente['carmen'] as Map<String, dynamic>)['pose'] = 'rie';
      await wait(450);
    }),
    'deseos': (o) => _run(o, () async {
      W['deseos'] = _n(o['n']).clamp(1, 3);
      W['dedosFx'] = W['deseos'];
      await wait(220);
      W['dedosFx'] = 0;
    }),
    'mira83': (o) => _run(o, () async {
      final a = (o['a'] as String?) == 'estrella' ? 'estrella' : 'luna';
      final cae = _n(o['cae']) == 1;
      W['telDir'] = a;
      W['visor'] = a;
      W['visorCae'] = cae ? 1 : 0;
      if (cae) {
        for (var f = 0; f < 3; f++) {
          W['visorFrame'] = f;
          await wait(110);
        }
        W['visorCae'] = 0;
        W['visorFrame'] = 0;
      } else {
        W['visorFrame'] = 0;
        await wait(260);
      }
    }),
    'luz83': (o) => _run(o, () async {
      final en = (o['en'] as String?) == 'estrella' ? 'star' : 'moon';
      final sc = _p.skyScreen(en);
      // Streak beside the moon or star without covering their boxes
      final baseX = en == 'moon' ? sc[0] + 28 : sc[0] - 28;
      final baseY = sc[1] + 6;
      for (var i = 0; i < 4; i++) {
        W['luzFugaz'] = {'x': baseX - i * 4, 'y': baseY + i * 2};
        await wait(80);
      }
      W['luzFugaz'] = null;
    }),
    'canta83': (o) => _run(o, () async {
      final n = _n(o['n']).clamp(0, 3);
      W['cantaFx'] = 1;
      await wait(220);
      if (n > 0) {
        W['ecos'] = n;
        await wait(260);
        W['ecos'] = 0;
      }
      W['cantaFx'] = 0;
    }),
    'final83': (o) => _run(o, () async {
      final n = _n(o['n']).clamp(1, 3);
      W['deseos'] = n;
      W['final83'] = n;
      W['ecos'] = n;
      (_gente['abuela'] as Map<String, dynamic>)['pose'] = 'rie';
      (_gente['luis'] as Map<String, dynamic>)['pose'] = 'rie';
      (_gente['carmen'] as Map<String, dynamic>)['pose'] = 'rie';
      await wait(450);
    }),
    'gesto': (o) => _run(o, () async {
      final quien = (o['quien'] as String?) ?? 'abuela';
      final que = (o['que'] as String?) ?? 'saluda';
      final p = _gente[quien] as Map<String, dynamic>?;
      if (p == null) return;
      if (que == 'saluda') {
        for (var i = 0; i < 4; i++) {
          p['pose'] = i % 2 == 0 ? 'saluda0' : 'saluda1';
          await wait(90);
        }
        p['pose'] = 'idle';
      } else if (que == 'dedos') {
        p['pose'] = 'dedos';
        W['dedosFx'] = _n(o['n']).clamp(1, 3);
        await wait(280);
        W['dedosFx'] = 0;
        p['pose'] = 'idle';
      } else if (que == 'ojos') {
        p['pose'] = 'ojos';
        W['ojosFx'] = 1;
        await wait(280);
        W['ojosFx'] = 0;
        p['pose'] = 'idle';
      } else if (que == 'mece') {
        for (final dx in const [-1, 0, 1, 0]) {
          p['dx'] = dx;
          await wait(80);
        }
        p['dx'] = 0;
      } else if (que == 'no') {
        for (final dx in const [-1, 1, -1, 0]) {
          p['dx'] = dx;
          await wait(70);
        }
        p['dx'] = 0;
      } else if (que == 'si') {
        for (final dy in const [1, 0, 1, 0]) {
          p['dy'] = dy;
          await wait(70);
        }
        p['dy'] = 0;
      } else {
        // mira, senala, brazos, mano, rie
        p['pose'] = que;
        await wait(260);
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
