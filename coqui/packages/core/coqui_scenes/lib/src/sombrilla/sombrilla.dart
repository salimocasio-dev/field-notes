// La sombrilla (place 7, La playa, scene 2: `sombrilla`; stories 75 to 77): a NEW scene, written from its script's
// "Needs" list (historia/notas/guiones/sombrilla.md) on its set (sombrilla_set.dart) and its sheet
// (sombrilla-sheet.json, read by SceneSheet). There is no old scene file: every act is this file's, each doing on
// screen what the Needs list says, every place from the sheet (spots, set thing boxes, depth rule, shadows). Where the
// sheet names no place or an act is unstated in the script, the code does the plainest thing that keeps the story
// playing and marks it `OPEN:`.
//
// The drawing (the sheet's `front`): every sprite stands with its feet's bottom edge on its spot's row and its
// middle on its column (rules.anchor); shells on the face are centred on their places; small things in the row rest
// bottom-middle on their spots; a sprite pixel is hidden by every baked set pixel nearer than its upright plane plus
// `front.bias`. Nothing in this set sways. Between two sprites the nearer pixel wins (tie within 0.001 goes to the
// later layer; the frog is always the last layer).
// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/src/colmado/colmado_cast.dart' show inkBottom;
import 'package:coqui_scenes/src/scene_set.dart';
import 'package:coqui_scenes/src/sheet_cache.dart';
import 'package:coqui_scenes/src/sombrilla/sombrilla_places.dart';
import 'package:coqui_scenes/src/sombrilla/sombrilla_set.dart';
import 'package:coqui_scenes/src/sombrilla/sombrilla_sprites.dart';

/// The scene "La sombrilla", made from its sheet (read first: `loadScene`).
Scene createSombrilla() => Sombrilla(sceneSheetOf('sombrilla'));

int _round(num v) => (v + 0.5).floor();

int _n(Object? v) {
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? 0;
  return 0;
}

/// One sprite of the sprite layer, placed: its picture, its top left on the 240 × 216 picture, the screen row of its
/// anchor and the depth there (front.plane), and who or what it is.
class SombrillaItem {
  SombrillaItem(
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

  /// Ground mark / wind streak drawn over the sand without occluding standing sprites.
  final bool flat;
}

/// Every person La sombrilla knows, by speaker key (sombrilla.md, "Needs").
const List<String> SOMBRILLA_PERSONAS = ['abuela', 'luis', 'carmen'];

class Sombrilla extends Escena implements SetScene, SetOverSprites {
  Sombrilla(this.ss)
    : sheet = identical(ss, _lastSs)
          ? _lastSheet!
          : (_lastSheet = ss.legacy()) {
    _p = identical(ss, _lastSs)
        ? _lastPlaces!
        : (_lastPlaces = SombrillaPlaces(ss));
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
  static SombrillaPlaces? _lastPlaces;

  /// The new scene's sheet (SceneSheet).
  final SceneSheet ss;

  @override
  final Sheet sheet;

  late final SombrillaPlaces _p;

  /// The scene's places, from its sheet.
  SombrillaPlaces get places => _p;

  @override
  String get id => 'sombrilla';

  @override
  late final Map<String, List<num>> CAM;

  late final Map<String, List<num>> LUGAR;

  @override
  Map<String, List<num>> get lugar => LUGAR;

  @override
  late final List<Thing> cosas;

  @override
  PpEngine newEngine({bool still = false}) => sombrillaEngine(still: still);

  @override
  PpEngine get projection => _p.e;

  List<num> _frogAt(SombrillaAt a) => [_round(a.sx) - 16, _round(a.sy) - 25, 1];

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

  Map<String, dynamic> _person(
    String spot, {
    int vis = 1,
    int sent = 0,
    int lying = 0,
    String abPose = 'sleep',
  }) {
    final w = _p.world(spot);
    return <String, dynamic>{
      'x': w[0],
      'y': w[1],
      'z': w[2],
      'spot': spot,
      'vis': vis,
      'pose': 'idle',
      'sent': sent,
      'lying': lying,
      'abPose': abPose,
      'sombrero': 0,
      'gafas': 0,
      'chancletas': 0,
      'sostiene': null, // refused item held briefly on wrong trae77
      'aplaude': 0,
      'dx': 0,
      'dy': 0,
    };
  }

  @override
  Map<String, dynamic> fresh(Map<String, dynamic> story) {
    final acts = _actsOf([story['beats'], story['final']]);
    bool has(String a) => acts.any((o) => o['act'] == a);
    final set = _firstSet(story['beats']);
    final is77 =
        has('jugadores') ||
        has('duele77') ||
        has('trae77') ||
        has('fuera77') ||
        has('viento77') ||
        has('final77');
    final is76 =
        !is77 &&
        (has('caracoles') ||
            has('pone76') ||
            has('boton76') ||
            has('canelo76') ||
            has('final76'));
    final is75 = !is77 && !is76;

    final gente = <String, dynamic>{};
    final String start;
    if (is77) {
      gente['abuela'] = _person('sol1', sent: 0, lying: 0);
      gente['luis'] = _person('sol2', sent: 0, lying: 0);
      gente['carmen'] = _person('sol3', sent: 0, lying: 0);
      start = 'coqui.bolsa';
    } else if (is76) {
      gente['abuela'] = _person('manta', sent: 1, lying: 0);
      gente['luis'] = _person('luis.figura', sent: 0, lying: 0);
      gente['carmen'] = _person('carmen.figura', sent: 0, lying: 0);
      start = 'coqui.figura';
    } else {
      gente['abuela'] = _person('manta', sent: 0, lying: 1, abPose: 'sleep');
      gente['luis'] = _person('luis.cara', sent: 0, lying: 0);
      gente['carmen'] = _person('carmen.cara', sent: 0, lying: 0);
      start = 'coqui.cara';
    }

    final q = _frogAt(_p.at(start));
    final hora = set['hora'] is String
        ? set['hora'] as String
        : (is77 ? 'sol' : (is76 ? 'tarde' : 'mediodia'));
    final dibujo = set['dibujo'] is String
        ? set['dibujo'] as String
        : (is75 ? 'circulo' : 'figura');

    return <String, dynamic>{
      'cam': 'wide',
      'hora': hora,
      'dibujo': dibujo,
      'story': is77 ? 77 : (is76 ? 76 : 75),
      'gente': gente,
      // Story 75: bucket of shells, Z's, face shells, mouth line, sand hat
      'cubo75': is75 ? 1 : 0,
      'zetas': is75 ? 3 : 0,
      'caraConchas': <String, int>{
        'ojo_izq': 0,
        'ojo_der': 0,
        'nariz': 0,
        'boca': 0,
      },
      'conchaCae': null, // {x, y} shell briefly dropped on wrong place
      'bocaLinea': null, // 'grande' | 'pequena' | null
      'sombreroArena': 0,
      // Story 76: spiral shells, Canelo, figure additions, buttons
      'caracoles': is76 ? 3 : 0,
      'perroVis': is76 ? 1 : 0,
      'perroSpot': 'perro',
      'perroPose': 'husmea',
      'perroDx': 0,
      'perroDy': 0,
      'perroCaracol': 0,
      'perroCava': 0,
      'perroArena': 0,
      'perroPalo': 0,
      'pelo': 0,
      'orejas': 0,
      'estrella': 0,
      'piedras': <Map<String, dynamic>>[], // {en, kind}
      'piedraTemp': null, // {en, kind} briefly placed on wrong spot
      'carmenCaracol': 0,
      'botonPreview': 0,
      'botones': 0,
      'paloBoton': 0,
      // Story 77: row of three things, beach ball, players, wind, frog carrying
      'filaVis': is77 ? 1 : 0,
      'bolaVis': is77 ? 1 : 0,
      'bolaPos': null, // {x, y} during passes, else at Luis's side
      'jugadores': is77 ? 3 : 0,
      'piesConchas': is77 ? 1 : 0,
      'viento': 0,
      'coquiLleva': null, // 'sombreros' | 'gafas' | 'chancletas' | null
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
    final hora = h is String && const ['mediodia', 'tarde', 'sol'].contains(h)
        ? h
        : 'mediodia';
    final d = W['dibujo'];
    final dibujo = d is String && const ['circulo', 'figura'].contains(d)
        ? d
        : 'circulo';
    return '$hora-$dibujo';
  }

  @override
  void buildSet(PpEngine e, PpBuild b, Map<String, dynamic> W) =>
      buildSetFor(e, b, setKey(W));

  final Map<PpEngine, SombrillaSet> _sets = {};

  @override
  void buildSetFor(PpEngine e, PpBuild b, String key) =>
      (_sets[e] ??= SombrillaSet(e, b)).buildSet(SombrillaState.fromKey(key));

  @override
  bool get frogShadow => false;

  /* ---------- where everybody is ---------- */

  Map<String, dynamic> get _gente => W['gente'] as Map<String, dynamic>;

  SombrillaAt _atOf(Map<String, dynamic> o) =>
      _p.atWorld(o['x'] as num, o['y'] as num, o['z'] as num);

  SombrillaAt _frogPoint(Map<String, dynamic> q) {
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
  ) {
    final lying = _n(p['lying']) == 1;
    final sent = _n(p['sent']) == 1;
    final pose = (p['pose'] as String?) ?? 'idle';

    if (id == 'abuela') {
      if (lying) {
        final abPose = (p['abPose'] as String?) ?? 'sleep';
        final s = _spr(
          'sm_ab_lie_$abPose',
          () => mkAbuelaAcostadaSombrilla(pose: abPose),
        );
        return (s: s, ax: 26, ay: inkBottom(s));
      }
      if (sent) {
        final abPose = switch (pose) {
          'saluda0' || 'saluda1' => pose,
          'senala' => 'tu',
          'rie' => 'yo',
          'mano' => 'saluda0',
          _ => 'idle',
        };
        final s = _spr(
          'sm_abP_${abPose}_$open',
          () => mkAbuelaS(abPose, open, true),
        );
        return (s: s, ax: 17, ay: inkBottom(s));
      }
      final abPose = switch (pose) {
        'saluda0' || 'saluda1' || 'mano' => 'wave',
        'senala' => 'wave',
        'rie' => 'happy',
        _ => 'idle',
      };
      final s = _spr('sm_ab_${abPose}_$open', () => mkAbuela(abPose, open));
      return (s: s, ax: 30, ay: inkBottom(s));
    }

    if (id == 'carmen' && lying) {
      final s = _spr('sm_carmen_lie', mkCarmenAcostada);
      return (s: s, ax: s.w ~/ 2, ay: inkBottom(s));
    }

    final who = id == 'luis' ? FAM['hermano']! : FAM['hermana']!;
    final kp = switch (pose) {
      'saluda0' => 'wave0',
      'saluda1' => 'wave1',
      'senala' => 'tu',
      'rie' => 'yo',
      'mano' => 'offer',
      'calla' => 'yo',
      _ => 'idle',
    };
    final s = _spr(
      'sm_${id}_${kp}_${open}_$sent',
      () => mkPersona(who, kp, open, sent),
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

  /// Screen point of a figure landmark from `SombrillaE.FIG` (for props laid on the sand figure).
  SombrillaAt _uvAt(double u, double v) {
    final xy = _p.xyOf(u, v);
    return _p.atWorld(xy[0], xy[1], 0);
  }

  Sprite _thingIcon(String que) => switch (que) {
    'sombreros' => _spr('sm_sombreros', mkSombreros),
    'gafas' => _spr('sm_gafas', mkGafas),
    _ => _spr('sm_chancletas', mkChancletas),
  };

  /// Every sprite of the frame [w] as it is placed, except the frog. The rules' tests read it; [draw] draws it.
  List<SombrillaItem> items(Map<String, dynamic> w, int a) {
    final out = <SombrillaItem>[];
    final talk = _talker();
    final gente = (w['gente'] as Map<String, dynamic>?) ?? const {};
    final dibujo = (w['dibujo'] as String?) ?? 'circulo';

    // 1. Story 75: mouth line, sand sun hat, face shells, dropped shell, bucket of shells
    if (dibujo == 'circulo') {
      final bocaL = w['bocaLinea'];
      if (bocaL is String) {
        final at = _p.at('boca');
        final s = _spr('sm_boca_$bocaL', () => mkBocaLinea(bocaL));
        final sx = _round(at.sx), sy = _round(at.sy);
        out.add(
          SombrillaItem(
            s,
            sx - s.w ~/ 2,
            sy - s.h ~/ 2 + 1,
            sy,
            at.d + .02,
            tag: 'fx:boca_linea',
            flat: true,
          ),
        );
      }
      if (_n(w['sombreroArena']) == 1) {
        final topAt = _uvAt(SombrillaE.FACE.u, SombrillaE.FACE.v - 1.55);
        final s = _spr('sm_sombrero_arena', mkSombreroArena);
        final sx = _round(topAt.sx), sy = _round(topAt.sy);
        out.add(
          SombrillaItem(
            s,
            sx - s.w ~/ 2,
            sy - s.h + 4,
            sy,
            topAt.d + .06,
            tag: 'fx:sombrero_arena',
            flat: true,
          ),
        );
      }
      final cara = w['caraConchas'];
      if (cara is Map) {
        const offsets = [(0, 0), (-4, 0), (4, 0)];
        final sh = _spr('sm_concha5', mkConcha5);
        for (final k in const ['ojo_izq', 'ojo_der', 'nariz', 'boca']) {
          final cnt = _n(cara[k]).clamp(0, 3);
          if (cnt <= 0) continue;
          final at = _p.at(k);
          final sx = _round(at.sx), sy = _round(at.sy);
          for (var i = 0; i < cnt; i++) {
            final (dx, dy) = offsets[i];
            out.add(
              SombrillaItem(
                sh,
                sx + dx - 2,
                sy + dy - 2,
                sy,
                at.d + .05,
                tag: 'fx:concha_${k}_$i',
                flat: true,
              ),
            );
          }
        }
      }
      final cae = w['conchaCae'];
      if (cae is Map) {
        final sh = _spr('sm_concha5', mkConcha5);
        final cx = _n(cae['x']), cy = _n(cae['y']);
        out.add(
          SombrillaItem(
            sh,
            cx - 2,
            cy - 2,
            cy,
            6.0,
            tag: 'fx:concha_cae',
            flat: true,
          ),
        );
      }
    }

    if (_n(w['cubo75']) == 1) {
      final at = _p.at('cubo75');
      final s = _spr('sm_cubo', mkCuboConchas);
      final sx = _round(at.sx), sy = _round(at.sy);
      out.add(SombrillaItem(s, sx - 6, sy - s.h, sy, at.d, tag: 'cosa:cubo75'));
    }

    // 2. Story 76 & 77: additions on the sand figure (seaweed hair, shell ears, starfish, flat stones, buttons, feet shells)
    if (dibujo == 'figura') {
      if (_n(w['pelo']) == 1) {
        final at = _uvAt(SombrillaE.FIG.u, SombrillaE.FIG.head[0] - .75);
        final s = _spr('sm_pelo', mkPeloAlgas);
        final sx = _round(at.sx), sy = _round(at.sy);
        out.add(
          SombrillaItem(
            s,
            sx - s.w ~/ 2,
            sy - s.h ~/ 2,
            sy,
            at.d + .04,
            tag: 'fx:pelo',
            flat: true,
          ),
        );
      }
      if (_n(w['orejas']) == 1) {
        final leftAt = _uvAt(
          SombrillaE.FIG.u - SombrillaE.FIG.head[1] - .12,
          SombrillaE.FIG.head[0],
        );
        final rightAt = _uvAt(
          SombrillaE.FIG.u + SombrillaE.FIG.head[1] + .12,
          SombrillaE.FIG.head[0],
        );
        final sl = _spr('sm_oreja_l', () => mkOrejaConcha(right: false));
        final sr = _spr('sm_oreja_r', () => mkOrejaConcha(right: true));
        out.add(
          SombrillaItem(
            sl,
            _round(leftAt.sx) - sl.w ~/ 2,
            _round(leftAt.sy) - sl.h ~/ 2,
            _round(leftAt.sy),
            leftAt.d + .04,
            tag: 'fx:oreja_l',
            flat: true,
          ),
        );
        out.add(
          SombrillaItem(
            sr,
            _round(rightAt.sx) - sr.w ~/ 2,
            _round(rightAt.sy) - sr.h ~/ 2,
            _round(rightAt.sy),
            rightAt.d + .04,
            tag: 'fx:oreja_r',
            flat: true,
          ),
        );
      }
      if (_n(w['estrella']) == 1) {
        final mb = _p.box('mano_izq');
        final sx = mb[0] + mb[2] ~/ 2;
        final sy = mb[1] + mb[3] ~/ 2;
        final s = _spr('sm_estrella', mkEstrellaMar);
        final at = _p.fromScreen(sx, sy, 0);
        out.add(
          SombrillaItem(
            s,
            sx - s.w ~/ 2,
            sy - s.h ~/ 2,
            sy,
            at.d + .05,
            tag: 'fx:estrella',
            flat: true,
          ),
        );
      }
      // Flat stones placed by pone76 (permanent + temp on wrong)
      final piedras = <Map<String, dynamic>>[
        if (w['piedras'] is List)
          for (final item in w['piedras'] as List)
            if (item is Map) item.cast<String, dynamic>(),
        if (w['piedraTemp'] is Map)
          (w['piedraTemp'] as Map).cast<String, dynamic>(),
      ];
      final seenPerPlace = <String, int>{};
      for (var idx = 0; idx < piedras.length; idx++) {
        final pd = piedras[idx];
        final en = (pd['en'] as String?) ?? 'cabeza';
        final slot = seenPerPlace[en] ?? 0;
        seenPerPlace[en] = slot + 1;
        final b = _p.box(en);
        final kind = en == 'cabeza'
            ? 'cabeza'
            : (en.startsWith('brazo') ? 'brazo' : 'mano');
        final s = _spr('sm_piedra_$kind', () => mkPiedra(kind));
        final dx = slot == 0 ? 0 : (slot == 1 ? 6 : -6);
        final sx = b[0] + b[2] ~/ 2 + dx;
        final sy = b[1] + b[3] ~/ 2;
        final at = _p.fromScreen(sx, sy, 0);
        out.add(
          SombrillaItem(
            s,
            sx - s.w ~/ 2,
            sy - s.h ~/ 2,
            sy,
            at.d + .05,
            tag: 'fx:piedra_$idx',
            flat: true,
          ),
        );
      }
      // Button preview (boton76) and final buttons down the figure's body (final76)
      final btnN = _n(w['botones']).clamp(0, 3);
      if (_n(w['botonPreview']) == 1 && btnN == 0) {
        final at = _uvAt(SombrillaE.FIG.u, 4.72);
        final s = _spr('sm_caracol', mkCaracol);
        out.add(
          SombrillaItem(
            s,
            _round(at.sx) - s.w ~/ 2,
            _round(at.sy) - s.h ~/ 2,
            _round(at.sy),
            at.d + .05,
            tag: 'fx:boton_prev',
            flat: true,
          ),
        );
      }
      if (btnN > 0) {
        final s = _spr('sm_caracol', mkCaracol);
        const vs = [4.25, 4.78, 5.3];
        for (var i = 0; i < btnN; i++) {
          final at = _uvAt(SombrillaE.FIG.u, vs[i]);
          out.add(
            SombrillaItem(
              s,
              _round(at.sx) - s.w ~/ 2,
              _round(at.sy) - s.h ~/ 2,
              _round(at.sy),
              at.d + .05,
              tag: 'fx:boton_$i',
              flat: true,
            ),
          );
        }
      }
      if (_n(w['paloBoton']) == 1) {
        final at = _uvAt(SombrillaE.FIG.u, 4.95);
        final s = _spr('sm_palo_boton', mkPaloBoton);
        out.add(
          SombrillaItem(
            s,
            _round(at.sx) - s.w ~/ 2,
            _round(at.sy) - s.h ~/ 2,
            _round(at.sy),
            at.d + .05,
            tag: 'fx:palo_boton',
            flat: true,
          ),
        );
      }
      if (_n(w['piesConchas']) == 1) {
        final sh = _spr('sm_concha5', mkConcha5);
        for (final fb in _p.boxesOf('pies')) {
          final sx = fb[0] + fb[2] ~/ 2;
          final sy = fb[1] + fb[3] ~/ 2;
          final at = _p.fromScreen(sx, sy, 0);
          out.add(
            SombrillaItem(
              sh,
              sx - 2,
              sy - 2,
              sy,
              at.d + .04,
              tag: 'fx:pie_concha_$sx',
              flat: true,
            ),
          );
        }
      }
    }

    // 3. Story 76: spiral shells in a row (`caracoles`, 28 x 8, bottom-middle)
    final carN = _n(w['caracoles']);
    if (carN > 0) {
      final at = _p.at('caracoles');
      final s = _spr('sm_caracoles_$carN', () => mkCaracoles(carN));
      final sx = _round(at.sx), sy = _round(at.sy);
      out.add(
        SombrillaItem(s, sx - 14, sy - s.h, sy, at.d, tag: 'cosa:caracoles'),
      );
    }

    // 4. Story 77: row of three things in front of abuela's bag (`sombreros`, `gafas`, `chancletas`)
    if (_n(w['filaVis']) == 1) {
      for (final (spot, key, make) in [
        ('sombreros', 'sm_sombreros', mkSombreros),
        ('gafas', 'sm_gafas', mkGafas),
        ('chancletas', 'sm_chancletas', mkChancletas),
      ]) {
        final at = _p.at(spot);
        final s = _spr(key, make);
        final sx = _round(at.sx), sy = _round(at.sy);
        out.add(
          SombrillaItem(s, sx - 8, sy - s.h, sy, at.d, tag: 'cosa:$spot'),
        );
      }
    }

    // 5. Canelo (story 76: `perro` sniffing or `hoyo` digging)
    if (_n(w['perroVis']) == 1) {
      final pSpot = (w['perroSpot'] as String?) ?? 'perro';
      final at = _p.at(pSpot);
      final pose = (w['perroPose'] as String?) ?? 'husmea';
      final step = (F >> 2) % 2 == 1;
      final Sprite s;
      if (_n(w['perroCaracol']) == 1) {
        s = _spr('sm_perro_caracol_$step', () => mkPerroCaracol(step));
      } else if (_n(w['perroCava']) == 1) {
        final cf = (F >> 1) % 2;
        s = _spr('sm_perro_cava_$cf', () => mkPerroCava(cf));
      } else if (_n(w['perroArena']) == 1) {
        s = _spr('sm_perro_arena', mkPerroArenaSombrilla);
      } else if (_n(w['perroPalo']) == 1) {
        s = _spr('sm_perro_palo', mkPerroPalo);
      } else {
        s = _spr('sm_perro_${pose}_$step', () => mkPerro(pose, step));
      }
      final sx = _round(at.sx) + _n(w['perroDx']);
      final sy = _round(at.sy) + _n(w['perroDy']);
      out.add(
        SombrillaItem(
          s,
          sx - 15,
          sy - inkBottom(s),
          sy,
          at.d,
          tag: 'persona:perro',
        ),
      );
    }

    // 6. People (abuela, luis, carmen) + Z's + worn/held items + claps
    for (final en in gente.entries) {
      final p = en.value as Map<String, dynamic>;
      if (p['vis'] == 0) continue;
      final open = talk == en.key && a % 2 == 1;
      final sp = _personSprite(en.key, p, open);
      final at = _atOf(p);
      final sx = _round(at.sx) + _n(p['dx']);
      final sy = _round(at.sy) + _n(p['dy']);
      final lying = _n(p['lying']) == 1;
      out.add(
        SombrillaItem(
          sp.s,
          sx - sp.ax,
          sy - sp.ay,
          sy,
          at.d,
          tag: 'persona:${en.key}',
        ),
      );

      // Story 75: Z's over sleeping abuela
      if (en.key == 'abuela' && lying && _n(w['zetas']) > 0) {
        final zn = _n(w['zetas']).clamp(1, 3);
        final zf = (F >> 2) % 2;
        final zs = _spr('sm_zetas_${zn}_$zf', () => mkZetas(zn, zf));
        out.add(
          SombrillaItem(
            zs,
            sx - 20,
            sy - sp.ay - zs.h + 2,
            sy,
            at.d + .05,
            tag: 'fx:zetas',
          ),
        );
      }

      // Story 76: Carmen briefly holding a spiral shell (`boton76`)
      if (en.key == 'carmen' && _n(w['carmenCaracol']) == 1) {
        final cs = _spr('sm_caracol', mkCaracol);
        out.add(
          SombrillaItem(
            cs,
            sx - 14,
            sy - 24,
            sy,
            at.d + .03,
            tag: 'held:carmen_caracol',
          ),
        );
      }

      // Story 77: worn hat / dark glasses / sandals / held refused item / clapping
      if (_n(p['sombrero']) == 1) {
        final hs = _spr('sm_sombrero_puesto', mkSombreroPuesto);
        final hx = lying
            ? (en.key == 'abuela' ? sx - 17 : sx + 8)
            : (en.key == 'abuela' ? sx + 2 : sx);
        final hy = lying ? sy - 16 : (en.key == 'abuela' ? sy - 50 : sy - 43);
        out.add(
          SombrillaItem(
            hs,
            hx - hs.w ~/ 2,
            hy,
            sy,
            at.d + .03,
            tag: 'worn:sombrero_${en.key}',
          ),
        );
      }
      if (_n(p['gafas']) == 1) {
        final gs = _spr('sm_gafas_puestas', mkGafasPuestas);
        final gx = lying
            ? (en.key == 'abuela' ? sx - 16 : sx + 8)
            : (en.key == 'abuela' ? sx - 1 : sx);
        final gy = lying ? sy - 10 : (en.key == 'abuela' ? sy - 38 : sy - 31);
        out.add(
          SombrillaItem(
            gs,
            gx - gs.w ~/ 2,
            gy,
            sy,
            at.d + .03,
            tag: 'worn:gafas_${en.key}',
          ),
        );
      }
      if (_n(p['chancletas']) == 1) {
        final cs = _spr('sm_chancletas_puestas', mkChancletasPuestas);
        final cx = lying ? (en.key == 'abuela' ? sx + 18 : sx - 10) : sx;
        final cy = lying ? sy - 6 : sy - cs.h;
        out.add(
          SombrillaItem(
            cs,
            cx - cs.w ~/ 2,
            cy,
            sy,
            at.d + .03,
            tag: 'worn:chancletas_${en.key}',
          ),
        );
      }
      if (p['sostiene'] is String) {
        final hs = _thingIcon(p['sostiene'] as String);
        out.add(
          SombrillaItem(
            hs,
            sx - hs.w ~/ 2,
            sy - 24,
            sy,
            at.d + .04,
            tag: 'held:sostiene_${en.key}',
          ),
        );
      }
      if (_n(p['aplaude']) == 1) {
        final ap = _spr(
          'sm_aplauso_${(F >> 1) % 2}',
          () => mkAplauso((F >> 1) % 2),
        );
        out.add(
          SombrillaItem(
            ap,
            sx - ap.w ~/ 2,
            sy - 20,
            sy,
            at.d + .05,
            tag: 'fx:aplauso_${en.key}',
          ),
        );
      }
    }

    // 7. Story 77: beach ball (`bola`, 9 x 9, at Luis's side `sol2 + (-10, -11)` dd +.3 as sombrilla-preview.html,
    //    or at `bolaPos` during passes)
    if (_n(w['bolaVis']) == 1) {
      final bs = _spr('sm_bola', mkBolaPlaya);
      final pos = w['bolaPos'];
      if (pos is Map) {
        final bx = _n(pos['x']), by = _n(pos['y']);
        out.add(
          SombrillaItem(bs, bx - 4, by - bs.h, by, 10.0, tag: 'cosa:bola'),
        );
      } else {
        final luis = gente['luis'] as Map<String, dynamic>?;
        final at = luis != null ? _atOf(luis) : _p.at('sol2');
        final sx = _round(at.sx) - 10 + (luis != null ? _n(luis['dx']) : 0);
        final sy = _round(at.sy) - 11 + (luis != null ? _n(luis['dy']) : 0);
        out.add(
          SombrillaItem(bs, sx - 4, sy - bs.h, sy, at.d + .3, tag: 'cosa:bola'),
        );
      }
    }

    // 8. Story 77: wind gust overlay (`viento77`)
    if (_n(w['viento']) == 1) {
      final vs = _spr('sm_viento_${F % 4}', () => mkViento(F % 4));
      out.add(
        SombrillaItem(vs, 84, 134, 152, 10.0, tag: 'fx:viento', flat: true),
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
    // Nothing in this set sways, so bakedZ is the whole depth (sombrilla-sheet.json front.how).
    _setZ = baked.zb;
  }

  static final double _t30 = math.tan(math.pi / 6);

  void _put(
    SombrillaItem it,
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

  /// [items] and the frog (always last so a tie goes to the frog), plus carried item overlay.
  List<SombrillaItem> placed(Map<String, dynamic> W, int a) {
    final all = items(W, a);
    final q = W['cq'] as Map<String, dynamic>;
    if (jsTruthy(q['vis'])) {
      final b = host.frogBox(q), at = _frogPoint(q);
      final dx = _n(q['dx']);
      final fsy = _round(at.sy);
      final fsx = _round(at.sx) + dx;
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
      all.add(SombrillaItem(spr, ox, oy, fsy, at.d, tag: 'coqui'));

      if (W['coquiLleva'] is String) {
        final cs = _thingIcon(W['coquiLleva'] as String);
        all.add(
          SombrillaItem(
            cs,
            fsx - cs.w ~/ 2,
            fsy - 28 + _n(q['dy']),
            fsy,
            at.d + .04,
            tag: 'held:coqui_lleva',
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
      if (_n(p['lying']) == 1) continue; // sheet: lying casts no shadow
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
        final pSpot = (W['perroSpot'] as String?) ?? 'perro';
        final at = _p.at(pSpot);
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
      final pSpot = (W['perroSpot'] as String?) ?? 'perro';
      final at = _p.at(pSpot);
      return [_round(at.sx), _round(at.sy) - 24];
    }
    final gente = (W['gente'] as Map<String, dynamic>?) ?? const {};
    final p = gente[who];
    if (p is Map<String, dynamic> && p['vis'] != 0) {
      final at = _atOf(p);
      final lying = _n(p['lying']) == 1;
      final h = lying
          ? 20
          : (who == 'abuela' ? (_n(p['sent']) == 1 ? 44 : 50) : 41);
      return [_round(at.sx) + _n(p['dx']), _round(at.sy) + _n(p['dy']) - h];
    }
    return null;
  }

  /* ---------- things he can touch (sombrilla.md Needs + sombrilla-sheet.json) ---------- */

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
      bool Function(Map<String, dynamic> w) si,
    ) => Thing(id: id, si: si, box: (w) => _itemBox(w, tag));

    Thing setThing(String id, bool Function(Map<String, dynamic> w) si) =>
        Thing(id: id, si: si, box: (_) => _p.box(id), world: _p.worldBox(id));

    bool isCirculo(Map<String, dynamic> w) => w['dibujo'] == 'circulo';
    bool isFigura(Map<String, dynamic> w) => w['dibujo'] == 'figura';

    // Order matters for Escena.hit: small interactive sprites first (`bola` before `luis`), then people & dog,
    // then the four face places BEFORE `cara`, then the figure parts.
    return [
      spriteThing('bola', 'cosa:bola', (w) => _n(w['bolaVis']) == 1),
      spriteThing('sombreros', 'cosa:sombreros', (w) => _n(w['filaVis']) == 1),
      spriteThing('gafas', 'cosa:gafas', (w) => _n(w['filaVis']) == 1),
      spriteThing(
        'chancletas',
        'cosa:chancletas',
        (w) => _n(w['filaVis']) == 1,
      ),
      spriteThing('caracoles', 'cosa:caracoles', (w) => _n(w['caracoles']) > 0),
      for (final who in SOMBRILLA_PERSONAS)
        spriteThing(who, 'persona:$who', (w) => _vis(w, who)),
      spriteThing('perro', 'persona:perro', (w) => _n(w['perroVis']) == 1),
      setThing('ojo_izq', isCirculo),
      setThing('ojo_der', isCirculo),
      setThing('nariz', isCirculo),
      setThing('boca', isCirculo),
      setThing('cara', isCirculo),
      setThing('cabeza', isFigura),
      setThing('brazo_izq', isFigura),
      setThing('brazo_der', isFigura),
      setThing('mano_izq', isFigura),
      setThing('mano_der', isFigura),
      setThing('pies', isFigura),
    ];
  }

  @override
  List<num>? handAt(String k) {
    // Point directly at the left foot box for `pies` (the union box centre is between the feet, over Luis at `sol2`).
    if (k == 'pies') {
      final fb = _p.boxesOf('pies').first;
      return [fb[0] + fb[2] / 2, fb[1]];
    }
    return super.handAt(k);
  }

  @override
  String? hit(num x, num y, Map<String, dynamic> w) {
    final res = super.hit(x, y, w);
    if (res == 'pies') {
      // Only the two individual foot boxes answer for `pies` (sombrilla-sheet.json: `things.pies.boxes`).
      final ok = _p
          .boxesOf('pies')
          .any(
            (b) => x >= b[0] && x < b[0] + b[2] && y >= b[1] && y < b[1] + b[3],
          );
      return ok ? 'pies' : null;
    }
    return res;
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
    int? lying,
  }) async {
    if (!_p.has(spot)) return;
    final target = _p.world(spot);
    final sx = (p['x'] as num).toDouble();
    final sy = (p['y'] as num).toDouble();
    final sz = (p['z'] as num).toDouble();
    final n = math.max(1, steps);
    p['lying'] = 0;
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
    if (lying != null) p['lying'] = lying;
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
      final story = _n(W['story']);
      if (a == 'cubo') {
        // OPEN: gen_sombrilla.py calls `ir a=cubo`, while sombrilla-sheet.json names the frog's spots
        // `coqui.cara` (story 75, beside `cubo75`) and `coqui.figura` (story 76).
        await _hopTo(story == 76 ? 'coqui.figura' : 'coqui.cara', steps: 4);
        return;
      }
      if (a == 'bolsa') {
        // OPEN: gen_sombrilla.py calls `ir a=bolsa`, while sombrilla-sheet.json names the frog's spot `coqui.bolsa`.
        await _hopTo('coqui.bolsa', steps: 4);
        return;
      }
      if (a == 'manta' && story == 76) {
        // OPEN: story 76 step 3 calls `ir a=manta` + `gesto coqui mano` without a separate frog spot beside abuela
        // (standing on `manta` overlaps abuela and violates `sprites-apart`/`frog-seen`) and with no `ir` back
        // before step 4; the frog hops up toward abuela to greet her and returns to `coqui.figura`.
        final q = W['cq'] as Map<String, dynamic>;
        final home = _p.at('coqui.figura');
        final mAt = _p.at('manta');
        final startL = _frogAt(home);
        final midX = _round((home.sx + mAt.sx) / 2) - 16;
        final midY = _round((home.sy + mAt.sy) / 2) - 25;
        for (final (px, py, dy) in [
          (midX, midY + 12, -6),
          (midX, midY, -4),
          (midX, midY, 0),
          (midX, midY + 12, -5),
        ]) {
          q['x'] = px;
          q['y'] = py;
          q['dy'] = dy;
          await wait(65);
        }
        q['x'] = startL[0];
        q['y'] = startL[1];
        q['dy'] = 0;
        q['spot'] = 'coqui.figura';
        return;
      }
      if (_p.has(a)) {
        await _hopTo(a, steps: 6);
      }
    },

    /* ---- Story 75: La cara ---- */

    // Floating Z's count over abuela (3..0)
    'zetas': (o) async {
      W['zetas'] = _n(o['n']).clamp(0, 3);
      await wait(120);
    },
    // Clack, abuela stirs on the blanket
    'despierta75': (o) async {
      final ab = _gente['abuela'] as Map<String, dynamic>?;
      if (ab != null && _n(ab['lying']) == 1) {
        ab['abPose'] = 'stir';
        for (final dx in const [-2, 2, -1, 0]) {
          ab['dx'] = dx;
          await wait(80);
        }
        ab['abPose'] = 'sleep';
      } else {
        await wait(160);
      }
    },
    // Press a shell into a face place (`ok=1`), or drop it with a clack and remove it (`ok=0`)
    'concha75': (o) async {
      final en = (o['en'] as String?) ?? 'ojo_izq';
      final ok = _n(o['ok']) == 1;
      if (!_p.has(en)) return;
      final at = _p.at(en);
      final sx = _round(at.sx), sy = _round(at.sy);
      await _brinco();
      if (ok) {
        final cara = Map<String, int>.from(W['caraConchas'] as Map);
        cara[en] = ((cara[en] ?? 0) + 1).clamp(1, 3);
        W['caraConchas'] = cara;
        await wait(140);
      } else {
        // Drop onto shell with a bounce, then Carmen removes it
        for (final dy in const [-10, -4, 0, -3, 0]) {
          W['conchaCae'] = <String, dynamic>{'x': sx + 2, 'y': sy + dy};
          await wait(60);
        }
        await wait(100);
        W['conchaCae'] = null;
      }
    },
    // Mouth line drawn with stick: grande, borrada, pequena
    'boca75': (o) async {
      final t = o['t'] as String?;
      if (t == 'borrada') {
        W['bocaLinea'] = null;
      } else if (t == 'grande' || t == 'pequena') {
        W['bocaLinea'] = t;
      }
      await wait(160);
    },
    // Story 75 ending: last shells + sun hat over the face; abuela by Z's left (3, 2, or 1)
    'final75': (o) async {
      // OPEN: story 75 step 8 (n=3: children lie down beside the face and frog curls up on its nose) has no lying
      // spots for Luis/Carmen or sleeping/curled sprites in the sheet, and curling on the nose would violate
      // `face-clear`; everyone stays at their moment 2 spots (`luis.cara`, `carmen.cara`, `coqui.cara`) while the
      // completed face and sun hat appear and abuela wakes/sits up at `manta`.
      final n = _n(o['n']).clamp(1, 3);
      W['caraConchas'] = <String, int>{
        'ojo_izq': 3,
        'ojo_der': 3,
        'nariz': 3,
        'boca': 3,
      };
      W['bocaLinea'] = 'pequena';
      W['sombreroArena'] = 1;
      final ab = _gente['abuela'] as Map<String, dynamic>?;
      if (n == 3) {
        await wait(180);
        W['zetas'] = 0;
        if (ab != null) {
          ab['lying'] = 0;
          ab['sent'] = 1;
          ab['pose'] = 'rie';
        }
        await _brinco();
        if (ab != null) ab['pose'] = 'idle';
      } else if (n == 2) {
        if (ab != null) ab['abPose'] = 'ojo';
        await wait(220);
        W['zetas'] = 0;
        if (ab != null) {
          ab['lying'] = 0;
          ab['sent'] = 1;
        }
        await wait(140);
      } else {
        W['zetas'] = 0;
        if (ab != null) {
          ab['lying'] = 0;
          ab['sent'] = 1;
          ab['pose'] = 'saluda0';
        }
        await wait(220);
        if (ab != null) ab['pose'] = 'idle';
      }
    },

    /* ---- Story 76: La cabeza y los brazos ---- */

    // Count of spiral shells in the row (3..0)
    'caracoles': (o) async {
      W['caracoles'] = _n(o['n']).clamp(0, 3);
      await wait(120);
    },
    // Carmen holds a spiral shell to the figure's middle and puts it back
    'boton76': (o) async {
      // OPEN: no spot in the sheet for Carmen walking to the figure's middle or `caracoles`; she holds a spiral
      // shell up from `carmen.figura`, a button preview flashes on the figure's body, and returns to the row.
      W['carmenCaracol'] = 1;
      await wait(140);
      W['botonPreview'] = 1;
      await wait(180);
      W['botonPreview'] = 0;
      W['carmenCaracol'] = 0;
    },
    // Lay a piece on the sand figure: pelo, orejas, estrella, piedra (`ok=1` stays; `ok=0` placed then taken off)
    'pone76': (o) async {
      final que = (o['que'] as String?) ?? 'piedra';
      final en = (o['en'] as String?) ?? 'cabeza';
      final ok = _n(o['ok']) == 1;
      if (que == 'pelo') {
        W['pelo'] = 1;
        await wait(180);
        return;
      }
      if (que == 'orejas') {
        W['orejas'] = 1;
        await wait(180);
        return;
      }
      if (que == 'estrella') {
        W['estrella'] = 1;
        await wait(180);
        return;
      }
      await _brinco();
      if (ok) {
        final list = List<Map<String, dynamic>>.from(W['piedras'] as List);
        list.add(<String, dynamic>{'en': en, 'kind': que});
        W['piedras'] = list;
        await wait(150);
      } else {
        W['piedraTemp'] = <String, dynamic>{'en': en, 'kind': que};
        await wait(200);
        W['piedraTemp'] = null;
      }
    },
    // Canelo takes a spiral shell in his mouth, trots to `hoyo`, and digs (matches moment 4)
    'canelo76': (o) async {
      W['perroSpot'] = 'perro';
      W['perroCaracol'] = 1;
      W['perroCava'] = 0;
      for (final (dx, dy) in const [(-6, 3), (-14, 7), (-20, 10)]) {
        W['perroDx'] = dx;
        W['perroDy'] = dy;
        await wait(70);
      }
      W['perroDx'] = 0;
      W['perroDy'] = 0;
      W['perroCaracol'] = 0;
      W['perroSpot'] = 'hoyo';
      W['perroPose'] = 'husmea';
      W['perroCava'] = 1;
      await wait(200);
    },
    // Story 76 ending: remaining spiral shells placed as buttons down the figure's middle
    'final76': (o) async {
      // OPEN: story 76 step 8 (n=3: "abuela gets up to lie down beside herself, arms out") has no lying spot beside
      // the sand figure in the sheet; abuela stays at `manta` celebrating while the 3 buttons appear on the figure.
      final n = _n(o['n']).clamp(1, 3);
      W['caracoles'] = 0;
      W['botones'] = n;
      W['perroCava'] = 0;
      if (n == 3) {
        final ab = _gente['abuela'] as Map<String, dynamic>?;
        if (ab != null) {
          ab['pose'] = 'saluda0';
          await wait(200);
          ab['pose'] = 'idle';
        }
      } else if (n == 2) {
        W['perroSpot'] = 'perro';
        W['perroPose'] = 'sit';
        W['perroArena'] = 1;
        await wait(200);
      } else {
        W['perroSpot'] = 'perro';
        W['perroPose'] = 'sit';
        W['perroPalo'] = 1;
        W['paloBoton'] = 1;
        await wait(200);
      }
    },

    /* ---- Story 77: Me duele ---- */

    // Player count still in the ball game (3..1)
    'jugadores': (o) async {
      W['jugadores'] = _n(o['n']).clamp(1, 3);
      await wait(100);
    },
    // Opening only: somebody shows what hurts (`pies` hops, `cabeza` hand on head, `ojos` squints)
    'duele77': (o) async {
      final quien = o['quien'] as String?;
      final donde = o['donde'] as String?;
      final p = _gente[quien] as Map<String, dynamic>?;
      if (p == null) return;
      if (donde == 'pies') {
        for (final dy in const [-5, 0, -5, 0]) {
          p['dy'] = dy;
          await wait(75);
        }
      } else if (donde == 'cabeza') {
        p['pose'] = 'mano';
        for (final dx in const [-2, 2, 0]) {
          p['dx'] = dx;
          await wait(80);
        }
        p['pose'] = 'idle';
      } else {
        p['pose'] = 'calla';
        for (final dx in const [-1, 1, 0]) {
          p['dx'] = dx;
          await wait(80);
        }
        p['pose'] = 'idle';
      }
    },
    // Frog brings sun hat / dark glasses / sandals to `a` (`ok=1` puts it on; `ok=0` holds & shakes head)
    'trae77': (o) async {
      // OPEN: no delivery spot beside each player or blanket for the frog; the frog bounces at `coqui.bolsa`
      // carrying the item sprite, then the recipient puts it on (whether standing in the sun or resting on the
      // blanket after a miss) or refuses it with a head shake.
      final que = (o['que'] as String?) ?? 'sombreros';
      final a = o['a'] as String?;
      final ok = _n(o['ok']) == 1;
      final p = _gente[a] as Map<String, dynamic>?;
      W['coquiLleva'] = que;
      await _brinco();
      W['coquiLleva'] = null;
      if (p == null) return;
      if (ok) {
        if (que == 'sombreros') p['sombrero'] = 1;
        if (que == 'gafas') p['gafas'] = 1;
        if (que == 'chancletas') p['chancletas'] = 1;
        await wait(160);
      } else {
        p['sostiene'] = que;
        for (final dx in const [-2, 2, -2, 0]) {
          p['dx'] = dx;
          await wait(75);
        }
        p['sostiene'] = null;
      }
    },
    // Gust of wind blows worn things off (the row beside the bag remains ready)
    'viento77': (o) async {
      W['viento'] = 1;
      for (var i = 0; i < 4; i++) {
        await wait(65);
      }
      for (final en in _gente.entries) {
        final p = en.value as Map<String, dynamic>;
        p['sombrero'] = 0;
        p['gafas'] = 0;
        p['chancletas'] = 0;
      }
      W['viento'] = 0;
    },
    // Player gives up and lies down on the blanket in the shade (`abuela` -> `manta2`, `carmen` -> `manta3`)
    'fuera77': (o) async {
      final quien = o['quien'] as String?;
      final p = _gente[quien] as Map<String, dynamic>?;
      if (p == null) return;
      // OPEN: sombrilla-sheet.json lists `manta2` (75, 98) for abuela out of the game and `manta3` (99, 97, 24 px
      // across from `manta2`) as a third blanket spot; Carmen takes `manta3` so both players fit when both miss.
      final target = quien == 'abuela' ? 'manta2' : 'manta3';
      p['sombrero'] = 0;
      p['gafas'] = 0;
      p['chancletas'] = 0;
      p['pose'] = 'idle';
      await _movePerson(p, target, steps: 6, sent: 0, lying: 1);
      if (quien == 'abuela') p['abPose'] = 'sleep';
    },
    // Story 77 ending: the ball goes round the remaining players and bounces off the frog's head
    'final77': (o) async {
      final n = _n(o['n']).clamp(1, 3);
      final ab = _gente['abuela'] as Map<String, dynamic>?;
      final car = _gente['carmen'] as Map<String, dynamic>?;
      final luis = _gente['luis'] as Map<String, dynamic>?;
      final lAt = luis != null ? _atOf(luis) : _p.at('sol2');
      final fAt = _p.at('coqui.bolsa');
      final points = <(int, int)>[(_round(lAt.sx) - 10, _round(lAt.sy) - 24)];
      if (ab != null && _n(ab['lying']) == 0) {
        final aAt = _atOf(ab);
        points.add((_round(aAt.sx), _round(aAt.sy) - 36));
      } else if (ab != null) {
        ab['aplaude'] = 1;
      }
      if (car != null && _n(car['lying']) == 0) {
        final cAt = _atOf(car);
        points.add((_round(cAt.sx), _round(cAt.sy) - 34));
      } else if (car != null) {
        car['aplaude'] = 1;
      }
      // High arc onto the frog's head and back to Luis
      points.add((_round(fAt.sx), _round(fAt.sy) - 26));
      points.add((_round(lAt.sx) - 10, _round(lAt.sy) - 11));
      for (final (bx, by) in points) {
        W['bolaPos'] = <String, dynamic>{'x': bx, 'y': by};
        await wait(90);
      }
      await _brinco();
      W['bolaPos'] = null;
      if (n == 3) {
        if (ab != null) ab['aplaude'] = 0;
        if (car != null) car['aplaude'] = 0;
      }
    },

    /* ---- Shared gestures (sombrilla.md Needs) ---- */
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
            await wait(90);
          }
          p['pose'] = 'idle';
          p['dy'] = 0;
        case 'no':
          for (final d in const [-2, 2, -2, 0]) {
            p['dx'] = d;
            await wait(75);
          }
        case 'si':
          for (var i = 0; i < 2; i++) {
            p['dy'] = -3;
            await wait(90);
            p['dy'] = 0;
            await wait(70);
          }
        case 'rie':
          p['pose'] = 'rie';
          for (final dy in const [-2, 0, -2, 0]) {
            p['dy'] = dy;
            await wait(65);
          }
          p['pose'] = 'idle';
        case 'mira':
          p['dy'] = -1;
          await wait(160);
          p['dy'] = 0;
        case 'senala':
          p['pose'] = 'senala';
          await wait(200);
          p['pose'] = 'idle';
        case 'calla':
          p['pose'] = 'calla';
          p['dy'] = -1;
          await wait(180);
          p['pose'] = 'idle';
          p['dy'] = 0;
        case 'arrodilla':
        case 'sienta':
          p['lying'] = 0;
          p['sent'] = 1;
          await wait(140);
        case 'acuesta':
          p['sent'] = 0;
          p['lying'] = 1;
          await wait(140);
        case 'mano':
          p['pose'] = 'mano';
          await wait(200);
          p['pose'] = 'idle';
      }
    },
    'marca': (o) async {
      final m = W['marcas'];
      if (m is List) {
        final i = m.indexOf(null);
        if (i >= 0) m[i] = o['que'];
      }
      await wait(160);
    },
    'fin': (o) async {
      await wait(240);
    },
  };
}
