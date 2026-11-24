// El calendario (place 6, La plaza, scene 4: `calendario`; stories 69 to 71): a NEW scene, written from its script's
// "Needs" list (historia/notas/guiones/calendario.md) on its set (calendario_set.dart) and its sheet
// (calendario-sheet.json, read by SceneSheet). There is no old scene file: every act is this file's, each doing on
// screen what the Needs list says, every place from the sheet (steps, hooks, suns, seats, balloons, kite, bows, box,
// held card, board/column/arch boxes, depth rule, shadows). Where the sheet names no place or an act is unstated in the
// script, the code does the plainest thing that keeps the story playing and marks it `OPEN:`.
//
// The drawing (the sheet's `front`): every sprite stands with its feet's bottom edge on its spot's row and its middle
// on its column (rules.anchor); sitting people hang by the lap; a card hangs top-middle on its hook (`dd = +0.05`); the
// sun peg centres on `sol1..7` (`dd = +0.03`); a held card hangs left-middle on `muestra` (`dd = +0.05`); a sprite pixel
// is hidden by every set pixel nearer than its upright plane plus `front.bias`.
// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/src/calendario/calendario_places.dart';
import 'package:coqui_scenes/src/calendario/calendario_set.dart';
import 'package:coqui_scenes/src/calendario/calendario_sprites.dart';
import 'package:coqui_scenes/src/colmado/colmado_cast.dart' show inkBottom;
import 'package:coqui_scenes/src/plaza/plaza_cast.dart'
    show cropTop, mkPlazaPersona, plazaNino, plazaWho;
import 'package:coqui_scenes/src/scene_set.dart';
import 'package:coqui_scenes/src/sheet_cache.dart';

/// The scene "El calendario", made from its sheet (read first: `loadScene`).
Scene createCalendario() => Calendario(sceneSheetOf('calendario'));

int _round(num v) => (v + 0.5).floor();

int _n(Object? v) {
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? 0;
  return 0;
}

/// One sprite of the sprite layer, placed: its picture, its top left on the 240 × 216 picture, the screen row of its
/// feet and the depth there (front.plane), and who or what it is.
class CalendarioItem {
  CalendarioItem(this.s, this.left, this.top, this.sy, this.d, {this.tag});

  final Sprite s;
  final int left, top;
  final num sy;
  final double d;
  final String? tag;
}

/// Every person El calendario knows, by speaker key (calendario.md, "Needs").
const List<String> CALENDARIO_PERSONAS = [
  'senora',
  'luis',
  'carmen',
  'beto',
  'abuela',
  'tito',
  'senor',
];

class Calendario extends Escena implements SetScene, SetOverSprites {
  Calendario(this.ss)
    : sheet = identical(ss, _lastSs)
          ? _lastSheet!
          : (_lastSheet = ss.legacy()) {
    _p = identical(ss, _lastSs)
        ? _lastPlaces!
        : (_lastPlaces = CalendarioPlaces(ss));
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
  static CalendarioPlaces? _lastPlaces;

  /// The new scene's sheet (SceneSheet).
  final SceneSheet ss;

  @override
  final Sheet sheet;

  late final CalendarioPlaces _p;

  /// The scene's places, from its sheet.
  CalendarioPlaces get places => _p;

  @override
  String get id => 'calendario';

  @override
  late final Map<String, List<num>> CAM;

  late final Map<String, List<num>> LUGAR;

  @override
  Map<String, List<num>> get lugar => LUGAR;

  @override
  late final List<Thing> cosas;

  @override
  PpEngine newEngine({bool still = false}) => calendarioEngine(still: still);

  @override
  PpEngine get projection => _p.e;

  List<num> _frogAt(CalendarioAt a) => [
    _round(a.sx) - 16,
    _round(a.sy) - 25,
    1,
  ];

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
      'dx': 0,
      'dy': 0,
    };
  }

  @override
  Map<String, dynamic> fresh(Map<String, dynamic> story) {
    final acts = _actsOf([story['beats'], story['final']]);
    bool has(String a) => acts.any((o) => o['act'] == a);
    final set = _firstSet(story['beats']);
    final is71 = has('sol71') || has('noche71') || has('gente');
    final is70 = !is71 && (has('lazos') || has('canelo70'));
    final is69 = !is71 && !is70;

    final gente = <String, dynamic>{};
    final String start;
    if (is71) {
      gente['senora'] = _person('izq');
      gente['abuela'] = _person('asiento1', sent: 1);
      gente['tito'] = _person('asiento2', sent: 1);
      gente['senor'] = _person('asiento3', sent: 1);
      start = 'escalon1';
    } else if (is70) {
      gente['senora'] = _person('izq');
      gente['luis'] = _person('suelo1');
      gente['carmen'] = _person('suelo2');
      start = 'escalon5';
    } else {
      gente['senora'] = _person('izq');
      gente['beto'] = _person('poste');
      // OPEN: in story 69 step 3, `gen_calendario.py` has abuela and Luis speak (and lists both in `names`) with
      // no arrival act ("abuela walks by (no act named)", "Luis rides up (no act named)"). Seating them on the
      // right-hand bench (`asiento1`, `asiento3`) keeps them visible, talk-animated, pokeable, and clear of the board.
      gente['abuela'] = _person('asiento1', sent: 1);
      gente['luis'] = _person('asiento3', sent: 1);
      start = 'escalon1';
    }

    final q = _frogAt(_p.at(start));
    final hora = set['hora'] is String
        ? set['hora'] as String
        : (is70 ? 'tarde' : 'manana');
    final tela = set['tela'] != null ? _n(set['tela']) : (is69 ? 1 : 0);

    return <String, dynamic>{
      'cam': 'wide',
      'hora': hora,
      'tela': tela == 1 ? 1 : 0,
      'gente': gente,
      // Board cards: column '1'..'7' -> List<String> (up to 3 hooks), plus 'arco' -> String?
      'tablero': <String, List<String>>{},
      'arcoCarta': null,
      'ultimaCarta': null,
      'muestra': null,
      'caja': 1,
      'luz': null,
      // Story 69: balloons
      'globos': is69 ? 3 : 0,
      'revientaHasta': 0,
      'final69': null,
      // Story 70: kite, bows, Canelo
      'chiringa': is70 ? 1 : 0,
      'chiringaVuela': 0,
      'lazos': is70 ? 3 : 0,
      'perroVis': is70 ? 1 : 0,
      'perroPose': 'lie',
      'bultoQuien': null,
      // Story 71: sun peg, passing night, baskets, seated count
      'sol': null,
      'nochePaso': 0,
      'cestas': is71
          ? <String, int>{'abuela': 0, 'tito': 0, 'senor': 0}
          : <String, int>{},
      'final71': null,
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
    final hora = h is String && const ['manana', 'tarde', 'noche'].contains(h)
        ? h
        : 'manana';
    return '$hora-${_n(W['tela']) == 1 ? 1 : 0}';
  }

  @override
  void buildSet(PpEngine e, PpBuild b, Map<String, dynamic> W) =>
      buildSetFor(e, b, setKey(W));

  final Map<PpEngine, CalendarioSet> _sets = {};

  @override
  void buildSetFor(PpEngine e, PpBuild b, String key) =>
      (_sets[e] ??= CalendarioSet(e, b)).buildSet(CalendarioState.fromKey(key));

  @override
  bool get frogShadow => false;

  /* ---------- where everybody is ---------- */

  Map<String, dynamic> get _gente => W['gente'] as Map<String, dynamic>;

  CalendarioAt _atOf(Map<String, dynamic> o) =>
      _p.atWorld(o['x'] as num, o['y'] as num, o['z'] as num);

  CalendarioAt _frogPoint(Map<String, dynamic> q) {
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

  ({Sprite s, int ax, int ay, String key}) _personSprite(
    String id,
    Map<String, dynamic> p,
    bool open,
  ) {
    final sent = _n(p['sent']) == 1;
    var pose = (p['pose'] as String?) ?? 'idle';
    if (id == 'abuela') {
      // rules.anchor: abuela sitting mkAbuelaS (52 × 50): column 17 and row 36 (her lap) on (sx, sy).
      // Seated on the right-hand bench (`asiento1`), she faces left toward the board so her knees stay inside [22, 218).
      final abPose = pose == 'sienta' ? 'idle' : pose;
      final k = 'abS$abPose$open';
      final raw = _spr(k, () => mkAbuelaS(abPose, open, false));
      final s = _mirror(k, raw);
      return (s: s, ax: s.w - 1 - 17, ay: 36, key: '${k}_L');
    }
    if (sent && (pose == 'idle' || pose == 'arrodilla')) pose = 'sienta';
    // OPEN: `plaza_cast.dart` gives `senor` El banco's tall `sombrero`, which extends 4 rows into `tito`'s head at
    // `asiento2`. Draw `senor` bareheaded on the bench (as in `calendario-preview.html` `SENOR`) so `seat-heads` holds.
    if (id == 'senor') {
      final kp = switch (pose) {
        'saluda0' => 'wave0',
        'saluda1' => 'wave1',
        'mano' => 'offer',
        'senala' => 'tu',
        'rie' => 'yo',
        _ => 'idle',
      };
      final key = 'cal_senor_${pose}_${open}_$sent';
      final s = _spr(
        key,
        () => cropTop(mkPersona(plazaWho('senor')!, kp, open, sent)),
      );
      final seated = pose == 'sienta';
      return (s: s, ax: PX, ay: seated ? s.h - 8 : inkBottom(s), key: key);
    }
    final key = 'cal_${id}_${pose}_$open';
    final raw = _spr(key, () => mkPlazaPersona(id, pose, open: open));
    // Face Beto left at `poste` so his red cap's bill points away from Coquí at `escalon1` (anchored at PX keeps x <= 49).
    final s = id == 'beto' ? _mirror(key, raw) : raw;
    final seated = pose == 'sienta';
    return (s: s, ax: PX, ay: seated ? s.h - 8 : inkBottom(s), key: key);
  }

  String? _talker() {
    try {
      return host.TALK;
    } catch (_) {
      return null;
    }
  }

  /// Every sprite of the frame [w] as it is placed, except the frog. The rules' tests read it; [draw] draws it.
  List<CalendarioItem> items(Map<String, dynamic> w, int a) {
    final out = <CalendarioItem>[];
    final talk = _talker();
    final gente = (w['gente'] as Map<String, dynamic>?) ?? const {};
    final cestas = (w['cestas'] as Map?) ?? const {};

    // 1. Picture cards hung on the board hooks (`gancho.k.j`, top-middle anchored, dd = +0.05)
    final tablero = (w['tablero'] as Map?) ?? const {};
    for (var col = 1; col <= 7; col++) {
      final list = tablero['$col'];
      if (list is! List) continue;
      final count = math.min(list.length, 3);
      for (var j = 0; j < count; j++) {
        final kind = list[j] as String;
        final at = _p.at('gancho.$col.${j + 1}');
        final s = _spr('carta_$kind', () => mkCartaCalendario(kind));
        final sx = _round(at.sx), sy = _round(at.sy);
        out.add(
          CalendarioItem(
            s,
            sx - 7,
            sy,
            sy,
            at.d + .05,
            tag: 'cosa:carta_${col}_${j + 1}',
          ),
        );
      }
    }
    final arcoCarta = w['arcoCarta'];
    if (arcoCarta is String) {
      final at = _p.at('arco_gancho');
      final s = _spr('carta_$arcoCarta', () => mkCartaCalendario(arcoCarta));
      final sx = _round(at.sx), sy = _round(at.sy);
      out.add(
        CalendarioItem(s, sx - 7, sy, sy, at.d + .05, tag: 'cosa:arco_carta'),
      );
    }

    // 2. Sun peg (`sol1..sol7`, centred (4, 4), dd = +0.03)
    final sol = w['sol'];
    if (sol is num && sol >= 1 && sol <= 7) {
      final at = _p.at('sol${sol.toInt()}');
      final s = _spr('sol', mkSolPeg);
      final sx = _round(at.sx), sy = _round(at.sy);
      out.add(
        CalendarioItem(s, sx - 4, sy - 4, sy, at.d + .03, tag: 'cosa:sol'),
      );
    }

    // 3. Balloons tied to the left post (`globos`, bottom-middle (12, 20)) & burst flash
    final globos = _n(w['globos']);
    if (globos > 0) {
      final at = _p.at('globos');
      final s = _spr('globos_$globos', () => mkGlobos(globos));
      final sx = _round(at.sx), sy = _round(at.sy);
      out.add(
        CalendarioItem(s, sx - 12, sy - s.h, sy, at.d, tag: 'cosa:globos'),
      );
    }
    if (F < _n(w['revientaHasta'])) {
      final at = _p.at('globos');
      final s = _spr('estallido', mkEstallido);
      final sx = _round(at.sx), sy = _round(at.sy) - 10;
      out.add(
        CalendarioItem(
          s,
          sx - s.w ~/ 2,
          sy - s.h ~/ 2,
          _round(at.sy),
          at.d + .04,
          tag: 'cosa:estallido',
        ),
      );
    }

    // 4. Señora's box of cards (`caja`, bottom-middle (7, 10)) and held card (`muestra`, left-middle (0, 6))
    if (_n(w['caja']) == 1) {
      final at = _p.at('caja');
      final s = _spr('caja', mkCajaCalendario);
      final sx = _round(at.sx), sy = _round(at.sy);
      out.add(CalendarioItem(s, sx - 7, sy - s.h, sy, at.d, tag: 'cosa:caja'));
    }
    final muestra = w['muestra'];
    if (muestra is String) {
      final at = _p.at('muestra');
      final s = _spr('carta_$muestra', () => mkCartaCalendario(muestra));
      final sx = _round(at.sx), sy = _round(at.sy);
      out.add(
        CalendarioItem(s, sx, sy - 6, sy, at.d + .05, tag: 'cosa:muestra'),
      );
    }

    // 5. Story 70: kite on paving (or flying at ending) + bows + Canelo
    final vuela = _n(w['chiringaVuela']);
    if (_n(w['chiringa']) == 1 && vuela == 0) {
      final at = _p.at('chiringa');
      final s = _spr('chiringa', mkChiringa);
      final sx = _round(at.sx), sy = _round(at.sy);
      out.add(
        CalendarioItem(s, sx - 14, sy - s.h, sy, at.d, tag: 'cosa:chiringa'),
      );
      final lazos = _n(w['lazos']).clamp(0, 3);
      final lz = _spr('lazo', mkLazo);
      for (var i = 1; i <= lazos; i++) {
        final la = _p.at('lazo$i');
        final lsx = _round(la.sx), lsy = _round(la.sy);
        out.add(
          CalendarioItem(
            lz,
            lsx - 3,
            lsy - lz.h,
            lsy,
            la.d,
            tag: 'cosa:lazo$i',
          ),
        );
      }
    } else if (vuela > 0) {
      final f = (F >> 2) % 2;
      final s = _spr('chiringa_v_${vuela}_$f', () => mkChiringaVuela(vuela, f));
      // OPEN: story 70 ending kite flying heights (high for 3 bows, mid-leaning for 2, low-spinning for 1; clear of frog).
      final ky = vuela == 3 ? 14 : (vuela == 2 ? 26 : 58);
      final kx = vuela == 1 ? 148 : 112;
      out.add(
        CalendarioItem(
          s,
          kx - s.w ~/ 2,
          ky,
          ky + s.h,
          2.6,
          tag: 'cosa:chiringa',
        ),
      );
    }
    if (_n(w['perroVis']) == 1) {
      final at = _p.at('perro');
      final pose = (w['perroPose'] as String?) ?? 'lie';
      final f = (F >> 2) % 2 == 1;
      final s = _spr('perro_${pose}_$f', () => mkPerro(pose, f));
      final sx = _round(at.sx), sy = _round(at.sy);
      out.add(
        CalendarioItem(
          s,
          sx - 15,
          sy - inkBottom(s),
          sy,
          at.d,
          tag: 'persona:perro',
        ),
      );
    }

    // 6. People (plus story 71 baskets on seated laps, story 70 school bag, story 69 ending balloons)
    for (final en in gente.entries) {
      final p = en.value as Map<String, dynamic>;
      if (p['vis'] == 0) continue;
      final open = talk == en.key && a % 2 == 1;
      final sp = _personSprite(en.key, p, open);
      final at = _atOf(p);
      final sx = _round(at.sx) + _n(p['dx']);
      final sy = _round(at.sy) + _n(p['dy']);
      out.add(
        CalendarioItem(
          sp.s,
          sx - sp.ax,
          sy - sp.ay,
          sy,
          at.d,
          tag: 'persona:${en.key}',
        ),
      );
      if (cestas.containsKey(en.key) && _n(p['sent']) == 1) {
        final full = _n(cestas[en.key]) == 1;
        final bs = _spr('cesta_$full', () => mkCestaCalendario(llena: full));
        // Positioned at lap level (below head rows) so seat-heads stays 0 px covered
        out.add(
          CalendarioItem(
            bs,
            sx - 10,
            sy - 8,
            sy,
            at.d + .02,
            tag: 'held:cesta_${en.key}',
          ),
        );
      }
      if (w['bultoQuien'] == en.key) {
        final bg = _spr('bulto', mkBultoEscolar);
        out.add(
          CalendarioItem(
            bg,
            sx - bg.w ~/ 2,
            sy - 46,
            sy,
            at.d + .04,
            tag: 'held:bulto_${en.key}',
          ),
        );
      }
    }

    // Story 69 ending balloons distributed to Beto (and Luis if n == 3)
    final fin69 = w['final69'];
    if (fin69 is num) {
      final n = fin69.toInt().clamp(1, 3);
      if (gente['beto'] is Map && (gente['beto'] as Map)['vis'] != 0) {
        final at = _atOf(gente['beto'] as Map<String, dynamic>);
        final g0 = _spr('globo_0', () => mkGloboSolo(0));
        final sx = _round(at.sx) - 8, sy = _round(at.sy) - 24;
        out.add(
          CalendarioItem(
            g0,
            sx - g0.w ~/ 2,
            sy - g0.h,
            _round(at.sy),
            at.d + .03,
            tag: 'held:globo_beto',
          ),
        );
      }
      if (n == 3 &&
          gente['luis'] is Map &&
          (gente['luis'] as Map)['vis'] != 0) {
        final at = _atOf(gente['luis'] as Map<String, dynamic>);
        final g2 = _spr('globo_2', () => mkGloboSolo(2));
        final sx = _round(at.sx) - 10, sy = _round(at.sy) - 18;
        out.add(
          CalendarioItem(
            g2,
            sx - g2.w ~/ 2,
            sy - g2.h,
            _round(at.sy),
            at.d + .03,
            tag: 'held:globo_luis',
          ),
        );
      }
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
    _setZ = baked.zb;
  }

  static final double _t30 = math.tan(math.pi / 6);

  void _put(
    CalendarioItem it,
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
        if (setZ != null && setZ[i] > plane + bias) continue;
        if (lz[i] > plane + .001) continue;
        lz[i] = plane;
        layer[i] = c;
      }
    }
  }

  static final Map<String, Sprite> _frogSprites = {};

  /// [items] and the frog (with his balloon in story 69 ending if n >= 2).
  List<CalendarioItem> placed(Map<String, dynamic> W, int a) {
    final all = items(W, a);
    final q = W['cq'] as Map<String, dynamic>;
    if (jsTruthy(q['vis'])) {
      final b = host.frogBox(q), at = _frogPoint(q);
      final dx = _n(q['dx']);
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
      final fsy = _round(at.sy);
      final fsx = _round(at.sx) + dx;
      all.add(CalendarioItem(spr, ox, oy, fsy, at.d, tag: 'coqui'));

      final fin69 = W['final69'];
      if (fin69 is num && fin69 >= 2) {
        final g1 = _spr('globo_1', () => mkGloboSolo(1));
        final ty = fsy - 24 + _n(q['dy']);
        all.add(
          CalendarioItem(
            g1,
            fsx - g1.w ~/ 2 + 6,
            ty - g1.h,
            ty,
            at.d + .02,
            tag: 'held:globo_coqui',
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
    _over(c, W);
  }

  void _glowBox(Ctx c, List<int> b) {
    const gold = 0xFFFFE060;
    fr(c, b[0], b[1], b[2], 2, gold);
    fr(c, b[0], b[1] + b[3] - 2, b[2], 2, gold);
    fr(c, b[0], b[1], 2, b[3], gold);
    fr(c, b[0] + b[2] - 2, b[1], 2, b[3], gold);
  }

  void _over(Ctx c, Map<String, dynamic> W) {
    final luz = W['luz'];
    if (luz is String) {
      if (luz == 'todos') {
        for (var i = 1; i <= 7; i++) {
          _glowBox(c, _p.box('dia$i'));
        }
      } else if (luz == 'arco') {
        _glowBox(c, _p.box('arco'));
      } else {
        final d = int.tryParse(luz);
        if (d != null && d >= 1 && d <= 7) {
          _glowBox(c, _p.box('dia$d'));
        }
      }
    }
    if (_n(W['nochePaso']) == 1) {
      // Passing night overlay (story 71 `noche71`)
      c.fillStyle = 0x99121834;
      c.fillRect(0, 0, 240, 216);
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
    void cast(CalendarioAt at, double? r) {
      if (r == null || at.z != 0) return;
      out.add((x: at.x, y: at.y, z: 0, r: r));
    }

    final gente = (W['gente'] as Map<String, dynamic>?) ?? const {};
    for (final en in gente.entries) {
      final p = en.value as Map<String, dynamic>;
      if (p['vis'] == 0 || jsTruthy(p['sent'])) continue;
      if (_p.noShadow((p['spot'] as String?) ?? '')) continue;
      cast(
        _atOf(p),
        _p.radius(en.key) ??
            _p.sheet.shadows.radius[plazaNino(en.key) ? 'ninos' : 'adultos'],
      );
    }
    if (_n(W['perroVis']) == 1) {
      cast(_p.at('perro'), _p.radius('perro'));
    }
    final q = W['cq'] as Map<String, dynamic>?;
    if (q != null && jsTruthy(q['vis']) && (q['z'] as num? ?? 0) == 0) {
      final at = _frogPoint(q);
      if (at.sx >= 0) cast(at, _p.radius('coqui'));
    }
    return out;
  }

  /* ---------- the things he can touch ---------- */

  static final Expando<List<int>> _inkOf = Expando<List<int>>();

  static List<num>? _inkBox(CalendarioItem it) {
    final s = it.s;
    final had = _inkOf[s];
    if (had != null) {
      return had.isEmpty
          ? null
          : [it.left + had[0], it.top + had[1], had[2], had[3]];
    }
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
    if (x1 < 0) {
      _inkOf[s] = const [];
      return null;
    }
    _inkOf[s] = [x0, y0, x1 - x0 + 1, y1 - y0 + 1];
    return [it.left + x0, it.top + y0, x1 - x0 + 1, y1 - y0 + 1];
  }

  /// The screen box of a placed sprite (its drawn pixels' bounds).
  static List<num>? inkBox(CalendarioItem it) => _inkBox(it);

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
    if (f == null || f != _boxesF || !identical(w, _boxesW)) {
      _boxes = {
        for (final it in items(w, 0))
          if (it.tag != null) it.tag!: _inkBox(it),
      };
      _boxesF = f;
      _boxesW = w;
    }
    return _boxes[tag];
  }

  List<Thing> _things() {
    Thing sprite(String id, String tag, {num m = 0, bool z = false}) => Thing(
      id: id,
      m: m,
      z: z,
      si: (w) => _boxOfTag(w, tag) != null,
      box: (Map<String, dynamic> w) => _boxOfTag(w, tag),
    );
    Thing setThing(String id, {num m = 0, bool z = false}) {
      final b = _p.box(id);
      return Thing(
        id: id,
        m: m,
        z: z,
        world: _p.worldBox(id),
        box: [b[0], b[1], b[2], b[3]],
      );
    }

    return [
      // Sprite things first so `sol` (on a column's square) and the flying `chiringa` answer touches over columns
      sprite('sol', 'cosa:sol', m: 2, z: true),
      sprite('globos', 'cosa:globos', m: 2, z: true),
      sprite('chiringa', 'cosa:chiringa', m: 2, z: true),
      sprite('caja', 'cosa:caja', m: 2, z: true),
      sprite('perro', 'persona:perro', m: 2, z: true),
      for (final id in CALENDARIO_PERSONAS) sprite(id, 'persona:$id', z: true),
      // Coquí
      Thing(
        id: 'coqui',
        m: 2,
        z: true,
        si: (w) => jsTruthy((w['cq'] as Map)['vis']),
        box: (Map<String, dynamic> w) {
          final b = host.frogBox(w['cq'] as Map<String, dynamic>);
          return [b.x, b.y, b.w, b.h];
        },
      ),
      // Set things: individual columns & arch (`z: true`) beat `tabla` (`z: false`), while `tabla`'s border hits `tabla`
      for (var i = 1; i <= 7; i++) setThing('dia$i', z: true),
      setThing('arco', z: true),
      setThing('tabla'),
      setThing('escalon'),
      setThing('banco'),
    ];
  }

  Future<void> _brinco() async {
    final q = W['cq'] as Map<String, dynamic>;
    for (final d in const [-5, -7, -4, 0]) {
      q['dy'] = d;
      await wait(TICK);
    }
  }

  @override
  Future<void> stake(int lost, int max, String en) async {
    host.SFX.bonk();
    await wait(300);
  }

  @override
  List<num> remap(List<num> xy) => xy;

  @override
  List<num>? talkAt(String who, Map<String, dynamic> W) {
    final b = _boxOfTag(W, 'persona:$who');
    if (b == null) return null;
    return [_round(b[0] + b[2] / 2), b[1] - 1];
  }

  @override
  dynamic poke(String what) {
    host.SFX.toc();
    return null;
  }

  /* ---------- the acts ---------- */

  bool _sueloFrontBusy() {
    for (final v in _gente.values) {
      if (v is Map &&
          v['vis'] != 0 &&
          (v['spot'] == 'suelo1' || v['spot'] == 'suelo2')) {
        return true;
      }
    }
    return false;
  }

  Future<void> _hopTo(String spot, {int steps = 10}) async {
    if (!_p.has(spot)) return;
    final at = _p.at(spot);
    final to = _frogAt(at);
    final q = W['cq'] as Map<String, dynamic>;
    final x0 = (q['x'] as num).toDouble(), y0 = (q['y'] as num).toDouble();
    final z0 = (q['z'] as num? ?? 0).toDouble();
    for (var i = 1; i <= steps; i++) {
      final t = i / steps;
      q['x'] = x0 + (to[0] - x0) * t;
      q['y'] = y0 + (to[1] - y0) * t;
      q['z'] = z0 + (at.z - z0) * t;
      q['dy'] = (-math.sin(t * math.pi) * 10).round();
      await wait(TICK);
    }
    q['x'] = to[0];
    q['y'] = to[1];
    q['z'] = at.z;
    q['dy'] = 0;
    q['spot'] = spot;
  }

  Future<void> _walkTo(
    Map<String, dynamic> p,
    String spot, {
    int steps = 12,
    bool sitAtEnd = false,
  }) async {
    final w = _p.world(spot);
    final x0 = (p['x'] as num).toDouble(),
        y0 = (p['y'] as num).toDouble(),
        z0 = (p['z'] as num).toDouble();
    p['sent'] = 0;
    p['pose'] = 'idle';
    for (var i = 1; i <= steps; i++) {
      final t = i / steps;
      p['x'] = x0 + (w[0] - x0) * t;
      p['y'] = y0 + (w[1] - y0) * t;
      p['z'] = z0 + (w[2] - z0) * t;
      p['dy'] = i.isOdd ? -1 : 0;
      await wait(TICK);
    }
    p['x'] = w[0];
    p['y'] = w[1];
    p['z'] = w[2];
    p['dy'] = 0;
    p['spot'] = spot;
    p['sent'] = sitAtEnd ? 1 : 0;
  }

  void _removeCardFrom(String dia) {
    if (dia == 'arco') {
      W['arcoCarta'] = null;
      return;
    }
    final tablero = W['tablero'] as Map<String, List<String>>;
    final list = tablero[dia];
    if (list != null && list.isNotEmpty) {
      list.removeLast();
    }
  }

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
    'ya': (o) async {
      final all = List<Future<void>>.of(_sueltos);
      _sueltos.clear();
      await Future.wait(all);
    },
    'ir': (o) async {
      final a = o['a'] as String?;
      if (a == null) return;
      await _hopTo(a);
    },
    'luce': (o) async {
      final dia = o['dia']?.toString();
      if (dia == null) return;
      W['luz'] = dia;
      await wait(260);
      // Keep column 6 glowing on story 70's Saturday morning ending
      if (W['hora'] == 'manana' && _n(W['chiringa']) == 1 && dia == '6') return;
      W['luz'] = null;
    },
    'cuenta': (o) async {
      final de = _n(o['de']).clamp(1, 7);
      final a = _n(o['a']).clamp(1, 7);
      for (var d = de; d <= a; d++) {
        W['luz'] = '$d';
        await wait(160);
      }
      W['luz'] = null;
    },
    'muestra': (o) async {
      final carta = o['carta'] as String?;
      W['muestra'] = carta;
      final s = _gente['senora'] as Map<String, dynamic>?;
      if (s != null) s['pose'] = 'mano';
      await wait(180);
      if (s != null) s['pose'] = 'idle';
    },
    'cuelga': (o) async {
      final carta = o['carta'] as String?;
      final dia = o['dia']?.toString();
      final quien = (o['quien'] as String?) ?? 'coqui';
      if (carta == null || dia == null) return;
      W['muestra'] = null;

      final tablero = W['tablero'] as Map<String, List<String>>;
      if (quien == 'coqui') {
        final colNum = dia == 'arco' ? 6 : _n(dia).clamp(1, 7);
        final stepSpot = 'escalon$colNum';
        // OPEN: in story 70, Luis (`suelo1`) and Carmen (`suelo2`) stand directly in front of `escalon1..4` (their
        // heads reach row 109 while the step ends at row 117). If a wrong touch hangs a card on columns 1..4 while
        // they stand there, the frog hops back to `escalon5` after hanging so `frog-seen` stays 0 px covered.
        await _hopTo(stepSpot, steps: 8);
        if (dia == 'arco') {
          // Story 70 `vale` slide-up: if the same card was just placed on day 6 or 7, slide it up to the arch
          for (final d in const ['6', '7']) {
            final col = tablero[d];
            if (col != null && col.isNotEmpty && col.last == carta) {
              col.removeLast();
              break;
            }
          }
          W['arcoCarta'] = carta;
        } else {
          final col = tablero.putIfAbsent(dia, () => <String>[]);
          if (col.length < 3) {
            col.add(carta);
          } else {
            col[2] = carta;
          }
        }
        W['ultimaCarta'] = <String, String>{'dia': dia, 'carta': carta};
        await wait(120);
        if (colNum <= 4 && _sueloFrontBusy()) {
          await _hopTo('escalon5', steps: 6);
        }
      } else {
        if (dia == 'arco') {
          W['arcoCarta'] = carta;
        } else {
          final col = tablero.putIfAbsent(dia, () => <String>[]);
          if (col.length < 3) {
            col.add(carta);
          } else {
            col[2] = carta;
          }
        }
        W['ultimaCarta'] = <String, String>{'dia': dia, 'carta': carta};
        await wait(80);
      }
    },
    'quita': (o) async {
      final dia = o['dia']?.toString();
      if (dia != null) _removeCardFrom(dia);
      await wait(140);
    },
    'vacia': (o) async {
      (W['tablero'] as Map<String, List<String>>).clear();
      W['arcoCarta'] = null;
      W['ultimaCarta'] = null;
      W['muestra'] = null;
      await wait(200);
    },
    // Story 69
    'globos': (o) async {
      W['globos'] = _n(o['n']).clamp(0, 3);
      await wait(120);
    },
    'revienta69': (o) async {
      final last = W['ultimaCarta'];
      if (last is Map && last['dia'] is String) {
        _removeCardFrom(last['dia'] as String);
        W['ultimaCarta'] = null;
      }
      W['revientaHasta'] = F + 10;
      final beto = _gente['beto'] as Map<String, dynamic>?;
      if (beto != null) beto['dy'] = -6;
      await wait(240);
      if (beto != null) beto['dy'] = 0;
    },
    'final69': (o) async {
      final n = _n(o['n']).clamp(1, 3);
      W['globos'] = 0;
      W['final69'] = n;
      await wait(300);
    },
    // Story 70
    'lazos': (o) async {
      W['lazos'] = _n(o['n']).clamp(0, 3);
      await wait(120);
    },
    'canelo70': (o) async {
      final last = W['ultimaCarta'];
      if (last is Map && last['dia'] is String) {
        _removeCardFrom(last['dia'] as String);
        W['ultimaCarta'] = null;
      }
      W['perroPose'] = 'run';
      await wait(280);
      W['perroPose'] = 'lie';
    },
    'final70': (o) async {
      final n = _n(o['n']).clamp(1, 3);
      W['lazos'] = n;
      W['chiringaVuela'] = n;
      if (n == 1) W['perroPose'] = 'run';
      await wait(320);
      W['luz'] = null;
    },
    // Story 71
    'sol71': (o) async {
      W['sol'] = _n(o['dia']).clamp(1, 7);
      await wait(160);
    },
    'noche71': (o) async {
      W['nochePaso'] = 1;
      await wait(280);
      W['nochePaso'] = 0;
      await wait(120);
    },
    'gente': (o) async {
      final n = _n(o['n']).clamp(1, 3);
      final senor = _gente['senor'] as Map<String, dynamic>?;
      final tito = _gente['tito'] as Map<String, dynamic>?;
      if (senor != null) senor['vis'] = n >= 3 ? 1 : 0;
      if (tito != null) tito['vis'] = n >= 2 ? 1 : 0;
      await wait(100);
    },
    'lee71': (o) async {
      final ok = _n(o['ok']) == 1;
      if (ok) {
        for (final k in const ['abuela', 'tito', 'senor']) {
          final p = _gente[k] as Map<String, dynamic>?;
          if (p != null && p['vis'] != 0) p['dy'] = -2;
        }
        await wait(200);
        for (final k in const ['abuela', 'tito', 'senor']) {
          final p = _gente[k] as Map<String, dynamic>?;
          if (p != null) p['dy'] = 0;
        }
      } else {
        final who =
            (_gente['senor'] is Map && (_gente['senor'] as Map)['vis'] != 0)
            ? 'senor'
            : 'tito';
        final p = _gente[who] as Map<String, dynamic>?;
        if (p != null && p['vis'] != 0) {
          await _walkTo(p, 'ronda', steps: 10, sitAtEnd: false);
          for (final d in const [-2, 2, 0]) {
            p['dx'] = d;
            await wait(80);
          }
        }
      }
    },
    'se_va71': (o) async {
      final quien = o['quien'] as String?;
      if (quien == null) return;
      final p = _gente[quien] as Map<String, dynamic>?;
      if (p == null || p['vis'] == 0) return;
      await _walkTo(p, 'entrada', steps: 10, sitAtEnd: false);
      p['vis'] = 0;
    },
    'cesta71': (o) async {
      final quien = (o['quien'] as String?) ?? 'abuela';
      final cestas = W['cestas'] as Map<String, int>;
      cestas[quien] = 1;
      final p = _gente[quien] as Map<String, dynamic>?;
      if (p != null && p['vis'] != 0) {
        p['dy'] = -3;
        await wait(200);
        p['dy'] = 0;
      }
    },
    'final71': (o) async {
      final n = _n(o['n']).clamp(1, 3);
      W['sol'] = null;
      W['final71'] = n;
      final cestas = W['cestas'] as Map<String, int>;
      for (final k in const ['abuela', 'tito', 'senor']) {
        final p = _gente[k] as Map<String, dynamic>?;
        if (p != null && p['vis'] != 0) {
          cestas[k] = 1;
          p['pose'] = 'saluda0';
        }
      }
      await wait(280);
      for (final k in const ['abuela', 'tito', 'senor']) {
        final p = _gente[k] as Map<String, dynamic>?;
        if (p != null) p['pose'] = 'idle';
      }
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
        case 'aplaude':
          for (var i = 0; i < 4; i++) {
            p['pose'] = i.isEven ? 'saluda0' : 'saluda1';
            p['dy'] = i.isEven ? -2 : 0;
            await wait(110);
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
          await wait(240);
          p['pose'] = 'idle';
        case 'mira':
          p['dy'] = -1;
          await wait(200);
          p['dy'] = 0;
        case 'senala':
          p['pose'] = 'senala';
          await wait(260);
          p['pose'] = 'idle';
        case 'bulto':
          p['pose'] = 'saluda0';
          W['bultoQuien'] = quien;
          await wait(280);
          W['bultoQuien'] = null;
          p['pose'] = 'idle';
        case 'levanta':
          p['dy'] = -5;
          await wait(260);
          p['dy'] = 0;
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
