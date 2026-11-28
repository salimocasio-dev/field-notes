// La comida (place 8, La fonda, scene 3: `comida`; stories 90 to 92): a NEW scene, written from its script's
// "Needs" list (historia/notas/guiones/comida.md) on its set (comida_set.dart) and its sheet (comida-sheet.json,
// read by SceneSheet). There is no old scene file: every act is this file's, each doing on screen what the Needs
// list says, every place from the sheet (spots, set thing box `olla`, view `wide`, depth rule, shadows).
// Where the sheet names no place or an act is unstated in the script, the code does the plainest thing that keeps
// the story playing and marks it `OPEN:`.
//
// The drawing (the sheet's `front`): every standing sprite stands with its feet's bottom edge on its spot's row and
// its middle on its column (rules.anchor); whoever sits at the long table hangs by the lap row (abuela 17,36;
// grown-ups 24,41; children 24,33) on the seat's top (z 0.44); every small thing has its bottom middle on its spot;
// every sprite pixel is hidden by every baked set pixel nearer than its upright plane plus `front.bias` (0.3).
// Between two sprites the nearer pixel wins (tie within 0.001 goes to the later layer; the frog is drawn last among
// world sprites).
// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/src/colmado/colmado_cast.dart' show inkBottom;
import 'package:coqui_scenes/src/comida/comida_places.dart';
import 'package:coqui_scenes/src/comida/comida_set.dart';
import 'package:coqui_scenes/src/comida/comida_sprites.dart';
import 'package:coqui_scenes/src/scene_set.dart';
import 'package:coqui_scenes/src/sheet_cache.dart';

/// The scene "La comida", made from its sheet (read first: `loadScene`).
Scene createComida() => Comida(sceneSheetOf('comida'));

int _round(num v) => (v + 0.5).floor();

int _n(Object? v) {
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? 0;
  return 0;
}

/// One sprite of the sprite layer, placed: its picture, its top left on the 240 × 216 picture, the screen row of its
/// anchor and the depth there (front.plane), and who or what it is.
class ComidaItem {
  ComidaItem(
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

  /// Screen-space overlay drawn over the set and world sprites (celebration cues).
  final bool overlay;
}

/// Every person La comida knows, by speaker key (comida.md, "Needs").
const List<String> COMIDA_PERSONAS = [
  'abuela',
  'abuelo',
  'luis',
  'carmen',
  'mesera',
  'cocinero',
  'senor',
  'senora',
  'joven',
  'mujer',
];

const List<String> _SHELF_ITEMS = ['sal', 'azucar', 'hielo', 'servilletas'];

class Comida extends Escena implements SetScene, SetOverSprites {
  Comida(this.ss)
    : sheet = identical(ss, _lastSs)
          ? _lastSheet!
          : (_lastSheet = ss.legacy()) {
    _p = identical(ss, _lastSs)
        ? _lastPlaces!
        : (_lastPlaces = ComidaPlaces(ss));
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
  static ComidaPlaces? _lastPlaces;

  /// The new scene's sheet (SceneSheet).
  final SceneSheet ss;

  @override
  final Sheet sheet;

  late final ComidaPlaces _p;

  /// The scene's places, from its sheet.
  ComidaPlaces get places => _p;

  @override
  String get id => 'comida';

  @override
  late final Map<String, List<num>> CAM;

  late final Map<String, List<num>> LUGAR;

  @override
  Map<String, List<num>> get lugar => LUGAR;

  @override
  late final List<Thing> cosas;

  @override
  PpEngine newEngine({bool still = false}) => comidaEngine(still: still);

  @override
  PpEngine get projection => _p.e;

  List<num> _frogAt(ComidaAt a) => [_round(a.sx) - 16, _round(a.sy) - 25, 1];

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
      'ojos': 0,
      'cara': 0,
      'rojo': 0,
      'cuchara': 0,
      'tapa': 0,
      'come': 0,
    };
  }

  @override
  Map<String, dynamic> fresh(Map<String, dynamic> story) {
    final acts = _actsOf([story['beats'], story['final']]);
    bool has(String a) => acts.any((o) => o['act'] == a);
    final is92 =
        has('prueba92') ||
        has('tazon') ||
        has('monton92') ||
        has('sirve92') ||
        has('final92');
    final is91 =
        !is92 &&
        (has('trae91') || has('sopas') || has('final91') || has('sube91'));
    final storyNum = is92 ? 92 : (is91 ? 91 : 90);
    final startSpot = is92
        ? 'servir_coqui'
        : (is91 ? 'auxiliar_coqui' : 'mesa_coqui');
    final q = _frogAt(_p.at(startSpot));

    final gente = <String, dynamic>{
      'abuela': _person(
        is92 ? 'fila1' : 'silla1',
        vis: is92 ? 0 : 1,
        sent: is92 ? 0 : 1,
      ),
      'abuelo': _person(
        is92 ? 'fila1' : 'silla2',
        vis: is92 ? 0 : 1,
        sent: is92 ? 0 : 1,
      ),
      'luis': _person(
        is92 ? 'fila2' : 'silla3',
        vis: is92 ? 0 : 1,
        sent: is92 ? 0 : 1,
      ),
      'carmen': _person(
        is92 ? 'fila3' : 'silla4',
        vis: is92 ? 0 : 1,
        sent: is92 ? 0 : 1,
      ),
      'mesera': _person('junto_mesa', vis: is91 ? 1 : 0),
      'cocinero': _person('detras_olla', vis: is92 ? 1 : 0),
      'senor': _person('fila3', vis: 0),
      'senora': _person('fila1', vis: 0),
      'joven': _person('fila2', vis: 0),
      'mujer': _person('fila1', vis: 0),
    };

    return <String, dynamic>{
      'story': storyNum,
      'hora': 'noche',
      'gente': gente,
      // Story 90 props & state
      'platillosVis': storyNum == 90 ? 1 : 0,
      'platillos': <String>['salado', 'dulce', 'picante'],
      'jarra': storyNum == 90 ? 3 : 0,
      'vasos': storyNum == 90 ? 3 : 0,
      'final90': 0,
      'fuegoFx': 0,
      'vaporFx': 0,
      'rojoCoqui': 0,
      // Story 91 props & state
      'estacionVis': is91 ? 1 : 0,
      'ensaladaVis': is91 ? 1 : 0,
      'sopasVis': 0,
      'sopas': 0, // bowls still steaming (3..0)
      'delantal': is91 ? 1 : 0,
      'servilletaBrazo': 0,
      'lleva': null, // 'sal' | 'azucar' | 'hielo' | 'servilletas' | null during trae91
      'final91': 0,
      // Story 92 props & state
      'perroVis': is92 ? 1 : 0,
      'perroMood': 'sit', // 'sit' | 'up' | 'eat' | 'sleep'
      'platoPerroVis': is92 ? 1 : 0,
      'platoPerroLleno': 0,
      'tazonVis': is92 ? 1 : 0,
      'tazon': 0, // spoonfuls in frog's bowl (0..3)
      'cucharon': is92 ? 1 : 0,
      'platoArroz': null, // null | 'normal' | 'mas' | 'menos'
      'platoArrozQuien': null,
      'salsaFx': 0, // 1 = bottle + drop
      'salFx': 0, // 1 = salt grains over pot
      'final92': 0,
      // Celebration cues
      'corazonFx': 0,
      'estrellaFx': 0,
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
        'spot': startSpot,
        'z': _p.world(startSpot)[2],
      },
    };
  }

  /* ---------- sprites and placement ---------- */

  static final Map<String, Sprite> _cache = {};
  Sprite _spr(String key, Sprite Function() make) =>
      _cache.putIfAbsent(key, make);

  String? _talker() {
    try {
      return host.TALK;
    } catch (_) {
      return null;
    }
  }

  ComidaAt _atOf(Map<String, dynamic> p) => _p.atWorld(
    (p['x'] as num).toDouble(),
    (p['y'] as num).toDouble(),
    (p['z'] as num).toDouble(),
  );

  ComidaAt _frogPoint(Map<String, dynamic> q) {
    final spot = q['spot'] as String?;
    final z = (q['z'] as num?)?.toDouble() ?? 0.0;
    final qx = (q['x'] as num).toDouble();
    final qy = (q['y'] as num).toDouble();
    if (spot != null && _p.hasWorld(spot)) {
      final at = _p.at(spot);
      final target = _frogAt(at);
      if ((qx - target[0]).abs() < 1 && (qy - target[1]).abs() < 1) {
        return at;
      }
    }
    return _p.fromScreen(qx + 16, qy + 25, z);
  }

  /// Every sprite to draw over the set, except the frog (who is added in [placed]).
  List<ComidaItem> items(Map<String, dynamic> w, int a) {
    final out = <ComidaItem>[];
    final talk = _talker();
    final anim = (a / 3).floor();
    final gente = (w['gente'] as Map<String, dynamic>?) ?? const {};

    // 1. People (seated at long table, mesera, cocinero, or standing in line at fila1..3)
    for (final id in COMIDA_PERSONAS) {
      final p = gente[id] as Map<String, dynamic>?;
      if (p == null || p['vis'] == 0) continue;
      final at = _atOf(p);
      final sx = _round(at.sx) + _n(p['dx']);
      final sy = _round(at.sy) + _n(p['dy']);
      final sent = p['sent'] == 1;
      final pose = (p['pose'] as String?) ?? 'idle';
      final open =
          (talk == id && a % 2 != 0) || _n(p['come']) == 1 && a % 2 != 0;
      final ojos = _n(p['ojos']) == 1;
      final cara = _n(p['cara']) == 1;
      final rojo = _n(p['rojo']) == 1;
      final cuchara = _n(p['cuchara']) == 1;
      final tapa = _n(p['tapa']) == 1;
      final key =
          'cm_p_${id}_${pose}_${open}_${sent}_${ojos}_${cara}_${rojo}_${cuchara}_$tapa';
      final s = _spr(
        key,
        () => mkComidaPersona(
          id,
          pose,
          open: open,
          sent: sent,
          ojos: ojos,
          cara: cara,
          rojo: rojo,
          cuchara: cuchara,
          tapa: tapa,
        ),
      );
      final ax = comidaAnchorX(id, sent: sent);
      final ay = sent ? comidaLapRow(id) : inkBottom(s);
      out.add(ComidaItem(s, sx - ax, sy - ay, sy, at.d, tag: 'persona:$id'));
    }

    // 2. Story 90 table things: platillo1..3, jarra, vasos
    if (_n(w['platillosVis']) == 1) {
      final rawOrd = w['platillos'];
      final ord = rawOrd is List
          ? [for (final x in rawOrd) '$x']
          : const ['salado', 'dulce', 'picante'];
      final spots = _p.group('platillos');
      for (var i = 0; i < spots.length && i < ord.length; i++) {
        final spot = spots[i];
        final sabor = ord[i];
        final at = _p.at(spot);
        final sx = _round(at.sx), sy = _round(at.sy);
        final s = _spr('cm_platillo_$sabor', () => mkPlatillo(sabor));
        out.add(ComidaItem(s, sx - 7, sy - s.h, sy, at.d, tag: 'cosa:$spot'));
      }
    }

    final jarraN = _n(w['jarra']);
    if (_n(w['story']) == 90 || jarraN > 0) {
      final at = _p.at('jarra');
      final sx = _round(at.sx), sy = _round(at.sy);
      final s = _spr('cm_jarra_$jarraN', () => mkJarra(jarraN));
      out.add(ComidaItem(s, sx - 6, sy - s.h, sy, at.d, tag: 'cosa:jarra'));
    }

    final vasosN = _n(w['vasos']);
    if (_n(w['story']) == 90 || vasosN > 0) {
      final fin = _n(w['final90']) > 0;
      final at = _p.at('vasos');
      final sx = _round(at.sx), sy = _round(at.sy);
      final s = _spr(
        'cm_vasos_${vasosN}_$fin',
        () => mkVasos(vasosN, finalMode: fin),
      );
      out.add(ComidaItem(s, sx - 13, sy - s.h, sy, at.d, tag: 'cosa:vasos'));
    }

    // 3. Story 91 station shelf items (sal, azucar, hielo, servilletas), Carmen's salad, and soup bowls (sopa1..3)
    if (_n(w['estacionVis']) == 1) {
      for (final k in _SHELF_ITEMS) {
        final at = _p.at(k);
        final sx = _round(at.sx), sy = _round(at.sy);
        final s = switch (k) {
          'sal' => _spr('cm_sal', mkSal),
          'azucar' => _spr('cm_azucar', mkAzucar),
          'hielo' => _spr('cm_hielo', mkHielo),
          _ => _spr('cm_servilletas', mkServilletas),
        };
        out.add(ComidaItem(s, sx - 5, sy - s.h, sy, at.d, tag: 'cosa:$k'));
      }
    }

    if (_n(w['ensaladaVis']) == 1) {
      final at = _p.at('ensalada');
      final sx = _round(at.sx), sy = _round(at.sy);
      final s = _spr('cm_ensalada', mkEnsalada);
      out.add(ComidaItem(s, sx - 6, sy - s.h, sy, at.d, tag: 'cosa:ensalada'));
    }

    if (_n(w['sopasVis']) == 1) {
      final hot = _n(w['sopas']);
      final spots = _p.group('sopas');
      for (var i = 0; i < spots.length; i++) {
        final spot = spots[i];
        final isHot = i < hot;
        final at = _p.at(spot);
        final sx = _round(at.sx), sy = _round(at.sy);
        final s = _spr('cm_sopa_$isHot', () => mkSopa(caliente: isHot));
        out.add(ComidaItem(s, sx - 6, sy - s.h, sy, at.d, tag: 'cosa:$spot'));
        if (isHot) {
          // Steam wisps strictly between heads (bottom row 85) and bowl top (row 97): rows 90..95
          final st = _spr('cm_vapor_sopa_${anim % 2}', () => mkVaporSopa(anim));
          out.add(
            ComidaItem(
              st,
              sx - 3,
              sy - s.h - st.h - 1,
              sy,
              at.d + .01,
              tag: 'fx:vapor_$spot',
            ),
          );
        }
      }
    }

    // 4. Story 92 serving table things: tazon, dog, plato_perro, held-out rice plate, salt/sauce FX
    if (_n(w['tazonVis']) == 1) {
      final n = _n(w['tazon']).clamp(0, 3);
      final at = _p.at('tazon');
      final sx = _round(at.sx), sy = _round(at.sy);
      final s = _spr('cm_tazon_$n', () => mkTazon(n));
      out.add(ComidaItem(s, sx - 5, sy - s.h, sy, at.d, tag: 'cosa:tazon'));
    }

    if (_n(w['perroVis']) == 1) {
      final at = _p.at('bajo_mesa');
      final sx = _round(at.sx), sy = _round(at.sy);
      final mood = (w['perroMood'] as String?) ?? 'sit';
      final s = _spr(
        'cm_perro_${mood}_${anim % 2}',
        () => mkPerroComida(mood, anim),
      );
      out.add(
        ComidaItem(
          s,
          sx - 15,
          sy - inkBottom(s),
          sy,
          at.d,
          tag: 'persona:perro',
        ),
      );
    }

    if (_n(w['platoPerroVis']) == 1) {
      final lleno = _n(w['platoPerroLleno']) == 1;
      final at = _p.at('plato_perro');
      final sx = _round(at.sx), sy = _round(at.sy);
      final s = _spr('cm_plato_perro_$lleno', () => mkPlatoPerro(lleno: lleno));
      out.add(
        ComidaItem(s, sx - 6, sy - s.h, sy, at.d, tag: 'cosa:plato_perro'),
      );
    }

    // OPEN: comida-sheet.json notes no spot or size for the plate held out by fila1 (`monton92`).
    // Drawn on the pot side of fila1 at (81, 58) with depth just behind fila1 (`at.d - .01`) so it is clearly visible
    // between the frog (columns 49..80) and fila1's body (90..104) while covering 0 px of fila1, the frog, or the pot.
    final arroz = w['platoArroz'] as String?;
    if (arroz != null) {
      final at = _p.at('fila1');
      final sx = _round(at.sx), sy = _round(at.sy);
      final s = _spr('cm_arroz_$arroz', () => mkPlatoArroz(arroz));
      out.add(
        ComidaItem(s, sx - 16, sy - 27, sy, at.d - .01, tag: 'fx:plato_arroz'),
      );
    }

    // OPEN: no spot for the bottle of red hot sauce (`salsaRoja`) or falling salt grains during `prueba92`.
    // Drawn above the pot during `prueba92` and cleared before the act completes so the pot stays 100% clear.
    if (_n(w['salFx']) == 1) {
      final gs = _spr('cm_granos_sal', mkGranosSal);
      out.add(ComidaItem(gs, 38, 48, 54, 4.0, tag: 'fx:sal_granos'));
    }
    if (_n(w['salsaFx']) == 1) {
      final sb = _spr('cm_salsa_roja', mkSalsaRoja);
      final gd = _spr('cm_gota_salsa', mkGotaSalsa);
      out.add(ComidaItem(sb, 46, 40, 52, 4.0, tag: 'fx:salsa_botella'));
      out.add(ComidaItem(gd, 42, 50, 55, 4.0, tag: 'fx:salsa_gota'));
    }

    // 5. Celebration cues (heart/stars): placed in clear air near the frog/table (never covering heads/pot/shelf)
    if (_n(w['corazonFx']) == 1) {
      final q = w['cq'] as Map<String, dynamic>?;
      final fp = q != null ? _frogPoint(q) : _p.at('mesa_coqui');
      final cor = _spr('cm_corazon', mkCorazonComida);
      final cx = (_round(fp.sx) + 12).clamp(24, 206);
      final cy = (_round(fp.sy) - 24).clamp(4, 200);
      out.add(
        ComidaItem(cor, cx, cy, cy, 6.0, tag: 'fx:corazon', overlay: true),
      );
    }
    if (_n(w['estrellaFx']) == 1) {
      final q = w['cq'] as Map<String, dynamic>?;
      final fp = q != null ? _frogPoint(q) : _p.at('mesa_coqui');
      final st = _spr('cm_estrella', mkEstrellaComida);
      final sx = (_round(fp.sx) - 18).clamp(24, 208);
      final sy = (_round(fp.sy) - 24).clamp(4, 200);
      out.add(
        ComidaItem(st, sx, sy, sy, 6.0, tag: 'fx:estrella', overlay: true),
      );
    }

    return out;
  }

  static final Map<String, Sprite> _frogSprites = {};

  /// [items] plus the frog (as the host draws him) and frog worn accessories, for `draw` and for `ComidaRules`.
  List<ComidaItem> placed(Map<String, dynamic> w, int a) {
    final out = items(w, a);
    final anim = (a / 3).floor();
    final q = w['cq'] as Map<String, dynamic>?;
    if (q != null && jsTruthy(q['vis'])) {
      final b = host.frogBox(q);
      final at = _frogPoint(q);
      final dx = _n(q['dx']);
      final fsy = _round(at.sy);
      final fsx = _round(at.sx) + dx;
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
      out.add(ComidaItem(spr, ox, oy, fsy, at.d, tag: 'coqui'));

      // OPEN: frog accessories (`delantal`, `servilletaBrazo`, `cucharon`, `lleva`, `fuegoFx`, `vaporFx`) drawn
      // cleanly over/beside Coquí inside his bounds so they cover 0 px of the pot, shelf items, or any person's head.
      if (_n(w['delantal']) == 1) {
        final ap = _spr('cm_delantal', mkDelantalCoqui);
        out.add(
          ComidaItem(
            ap,
            fsx - 6,
            fsy - 10,
            fsy,
            at.d + .01,
            tag: 'fx:delantal',
          ),
        );
      }
      if (_n(w['servilletaBrazo']) == 1) {
        final nv = _spr('cm_servilleta_brazo', mkServilletaBrazo);
        out.add(
          ComidaItem(
            nv,
            fsx + 8,
            fsy - 12,
            fsy,
            at.d + .01,
            tag: 'fx:servilleta_brazo',
          ),
        );
      }
      if (_n(w['cucharon']) == 1) {
        // Right side of frog (cols 73..78 at servir_coqui), clear of the pot (30..50) and fila1 (85..108)
        final sp = _spr('cm_cucharon', mkCucharonCoqui);
        out.add(
          ComidaItem(
            sp,
            fsx + 9,
            fsy - 17,
            fsy,
            at.d + .01,
            tag: 'fx:cucharon',
          ),
        );
      }
      final lleva = w['lleva'] as String?;
      if (lleva != null) {
        final cs = switch (lleva) {
          'sal' => _spr('cm_sal', mkSal),
          'azucar' => _spr('cm_azucar', mkAzucar),
          'hielo' => _spr('cm_pinzas_hielo', mkPinzasHielo),
          'servilletas' => _spr('cm_servilletas', mkServilletas),
          _ => null,
        };
        if (cs != null) {
          out.add(
            ComidaItem(
              cs,
              fsx - cs.w ~/ 2,
              fsy - 26,
              fsy,
              at.d + .02,
              tag: 'fx:lleva',
            ),
          );
        }
      }
      if (_n(w['rojoCoqui']) == 1) {
        final cr = _spr('cm_carita_roja', mkCaritaRoja);
        out.add(
          ComidaItem(
            cr,
            fsx - 7,
            fsy - 18,
            fsy,
            at.d + .01,
            tag: 'fx:carita_roja',
          ),
        );
      }
      if (_n(w['fuegoFx']) == 1) {
        final fg = _spr('cm_fuego_${anim % 2}', () => mkFuegoCoqui(anim));
        out.add(
          ComidaItem(fg, fsx + 8, fsy - 17, fsy, at.d + .02, tag: 'fx:fuego'),
        );
      }
      if (_n(w['vaporFx']) == 1) {
        // Rows 83..90 at mesa_coqui (below abuela's head rows 67..80)
        final vp = _spr('cm_vapor_cq_${anim % 2}', () => mkVaporCoqui(anim));
        out.add(
          ComidaItem(vp, fsx - 6, fsy - 31, fsy, at.d + .02, tag: 'fx:vapor'),
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
    _setZ = baked.zb;
  }

  static final double _t30 = math.tan(math.pi / 6);

  void _put(
    ComidaItem it,
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
      final at = _p.at('bajo_mesa');
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
    final sent = p['sent'] == 1;
    final dy = sent ? (who == 'abuela' ? 38 : 42) : 52;
    return [_round(at.sx), _round(at.sy) - dy];
  }

  /* ---------- touch things & hit testing ---------- */

  static List<int>? _itemBox(
    List<ComidaItem> list,
    bool Function(ComidaItem) test,
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

  List<num>? _sopasBox(Map<String, dynamic> w) => _itemBox(
    items(w, 0),
    (it) => it.tag != null && it.tag!.startsWith('cosa:sopa'),
  );

  List<Thing> _things() => [
    // Small interactive table & shelf & serving props first (highest touch priority)
    for (final id in const ['platillo1', 'platillo2', 'platillo3'])
      Thing(
        id: id,
        si: (w) => _n(w['platillosVis']) == 1,
        box: (w) => _spriteBox(w, 'cosa:$id') ?? _p.spotBox(id),
      ),
    Thing(
      id: 'jarra',
      si: (w) => _n(w['story']) == 90 || _n(w['jarra']) > 0,
      box: (w) => _spriteBox(w, 'cosa:jarra') ?? _p.spotBox('jarra'),
    ),
    for (final id in _SHELF_ITEMS)
      Thing(
        id: id,
        si: (w) => _n(w['estacionVis']) == 1,
        box: (w) => _spriteBox(w, 'cosa:$id') ?? _p.spotBox(id),
      ),
    Thing(
      id: 'sopas',
      si: (w) => _n(w['sopasVis']) == 1,
      box: (w) => _sopasBox(w) ?? _p.spotBox('sopa2'),
    ),
    Thing(
      id: 'tazon',
      si: (w) => _n(w['tazonVis']) == 1,
      box: (w) => _spriteBox(w, 'cosa:tazon') ?? _p.spotBox('tazon'),
    ),
    Thing(
      id: 'plato_perro',
      si: (w) => _n(w['platoPerroVis']) == 1,
      box: (w) =>
          _spriteBox(w, 'cosa:plato_perro') ?? _p.spotBox('plato_perro'),
    ),
    // Set thing: big pot on the serving table
    Thing(id: 'olla', box: (w) => _p.box('olla')),
    // Coquí (foreground over table/seated family)
    Thing(
      id: 'coqui',
      si: (w) => jsTruthy((w['cq'] as Map?)?['vis']),
      box: (Map<String, dynamic> w) {
        final b = host.frogBox(w['cq'] as Map<String, dynamic>);
        return [b.x, b.y, b.w, b.h];
      },
    ),
    // Dog
    Thing(
      id: 'perro',
      si: (w) => _n(w['perroVis']) == 1,
      box: (w) => _spriteBox(w, 'persona:perro'),
    ),
    // People
    for (final who in COMIDA_PERSONAS)
      Thing(
        id: who,
        si: (w) => ((w['gente'] as Map?)?[who] as Map?)?['vis'] != 0,
        box: (w) => _spriteBox(w, 'persona:$who'),
      ),
  ];

  @override
  String setKey(Map<String, dynamic> W) =>
      ComidaState(hora: (W['hora'] as String?) ?? 'noche').key;

  @override
  void buildSet(PpEngine e, PpBuild b, Map<String, dynamic> W) =>
      buildSetFor(e, b, setKey(W));

  final Map<PpEngine, ComidaSet> _sets = {};

  @override
  void buildSetFor(PpEngine e, PpBuild b, String key) =>
      (_sets[e] ??= ComidaSet(e, b)).buildSet(ComidaState.fromKey(key));

  @override
  bool get frogShadow => false;

  /* ---------- acts ---------- */

  final List<Future<void>> _loose = [];

  Future<void> _run(Map<String, dynamic> o, Future<void> Function() body) {
    if (jsTruthy(o['suelto'])) {
      final f = body();
      _loose.add(f);
      return Future.value();
    }
    return body();
  }

  Future<void> _hopFrogTo(String spot) async {
    if (!_p.hasWorld(spot)) return;
    final at = _p.at(spot);
    final q = W['cq'] as Map<String, dynamic>;
    final dest = _frogAt(at);
    final sx = (q['x'] as num).toDouble(), sy = (q['y'] as num).toDouble();
    final dx = dest[0].toDouble() - sx, dy = dest[1].toDouble() - sy;
    final dist = math.sqrt(dx * dx + dy * dy);
    if (dist >= 2) {
      final steps = (dist / 22).ceil().clamp(1, 5);
      for (var i = 1; i <= steps; i++) {
        final t = i / steps;
        q['x'] = sx + dx * t;
        q['y'] = sy + dy * t;
        q['dy'] = -math.sin(t * math.pi) * 9;
        await wait(65);
      }
    }
    q
      ..['x'] = dest[0]
      ..['y'] = dest[1]
      ..['dy'] = 0
      ..['spot'] = spot
      ..['z'] = at.z;
  }

  Map<String, dynamic>? _personOf(String? id) {
    if (id == null) return null;
    final gente = W['gente'] as Map<String, dynamic>?;
    return gente?[id] as Map<String, dynamic>?;
  }

  void _clearPersonAtSpot(String spot, String exceptId) {
    final gente = (W['gente'] as Map<String, dynamic>?) ?? const {};
    for (final en in gente.entries) {
      if (en.key == exceptId) continue;
      final p = en.value as Map<String, dynamic>;
      if (p['vis'] != 0 && p['spot'] == spot) {
        p['vis'] = 0;
      }
    }
  }

  @override
  List<num> remap(List<num> xy) => xy;

  @override
  Future<void> stake(int lost, int max, String en) async {}

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
      final spot = (o['a'] as String?) ?? 'mesa_coqui';
      await _hopFrogTo(spot);
    }),
    'llega': (o) => _run(o, () async {
      final quien = (o['quien'] as String?) ?? 'mesera';
      final a = (o['a'] as String?) ?? 'junto_mesa';
      final p = _personOf(quien);
      if (p == null || !_p.hasWorld(a)) return;
      // OPEN: in story 92, gen_comida.py calls `llega` for each person at `fila1` without calling `sale` on the
      // previous one; dismiss whoever occupied that spot so two people never stack and `sprites-apart` holds.
      _clearPersonAtSpot(a, quien);
      final w = _p.world(a);
      p
        ..['x'] = w[0]
        ..['y'] = w[1]
        ..['z'] = w[2]
        ..['spot'] = a
        ..['sent'] = a.startsWith('silla') ? 1 : 0
        ..['vis'] = 1
        ..['pose'] = 'idle'
        ..['dx'] = 0
        ..['dy'] = 0;
      if (a == 'fila1') {
        W['platoArroz'] = null;
        W['platoArrozQuien'] = null;
      }
      for (final d in const [-6, -3, 0]) {
        p['dx'] = d;
        await wait(70);
      }
    }),
    'sale': (o) => _run(o, () async {
      final quien = (o['quien'] as String?) ?? 'mesera';
      final p = _personOf(quien);
      if (p == null) return;
      for (final d in const [-3, -6, -10]) {
        p['dx'] = d;
        await wait(70);
      }
      p
        ..['vis'] = 0
        ..['dx'] = 0
        ..['dy'] = 0;
      if (W['platoArrozQuien'] == quien) {
        W['platoArroz'] = null;
        W['platoArrozQuien'] = null;
      }
    }),
    'marca': (o) async {
      final m = W['marcas'];
      if (m is List) {
        final i = m.indexWhere((x) => x == null);
        if (i >= 0) m[i] = o['que'] == 'ok' ? 'ok' : 'x';
      }
      await wait(140);
    },

    /* ---------- Story 90: Prueba ---------- */
    'platillos90': (o) => _run(o, () async {
      final raw = (o['orden'] as String?) ?? 'salado,dulce,picante';
      final parts = raw
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      W['platillosVis'] = 1;
      W['platillos'] = parts.length == 3
          ? parts
          : <String>['salado', 'dulce', 'picante'];
      // Clear any previous round facial reactions when fresh pieces go onto the plates
      final gente = (W['gente'] as Map<String, dynamic>?) ?? const {};
      for (final id in const ['abuela', 'abuelo', 'luis', 'carmen']) {
        final p = gente[id] as Map<String, dynamic>?;
        if (p != null) {
          p
            ..['ojos'] = 0
            ..['cara'] = 0
            ..['rojo'] = 0
            ..['come'] = 0;
        }
      }
      final ab = _personOf('abuela');
      if (ab != null) {
        ab['pose'] = 'offer';
        await wait(180);
        ab['pose'] = 'idle';
      }
      await wait(120);
    }),
    'fuego90': (o) => _run(o, () async {
      // OPEN: no spot for abuela's small water jug in comida-sheet.json; show Coquí biting the pepper (red face + fire
      // from his mouth), then cooling off with steam rising off his head.
      final q = W['cq'] as Map<String, dynamic>;
      W['rojoCoqui'] = 1;
      W['fuegoFx'] = 1;
      for (var i = 0; i < 4; i++) {
        q['dy'] = i.isEven ? -4 : 0;
        await wait(110);
      }
      q['dy'] = 0;
      W['fuegoFx'] = 0;
      W['vaporFx'] = 1;
      await wait(280);
      W['vaporFx'] = 0;
      W['rojoCoqui'] = 0;
    }),
    'jarra': (o) => _run(o, () async {
      final n = _n(o['n']).clamp(0, 3);
      W['jarra'] = n;
      W['vasos'] = n;
      await wait(140);
    }),
    'da90': (o) => _run(o, () async {
      final cual = (o['cual'] as String?) ?? 'platillo1';
      final a = (o['a'] as String?) ?? 'carmen';
      final ok = _n(o['ok']) != 0;
      final q = W['cq'] as Map<String, dynamic>;
      final p = _personOf(a);
      // Determine which taste sits on plate `cual`
      final idx =
          const {'platillo1': 0, 'platillo2': 1, 'platillo3': 2}[cual] ?? 0;
      final ord = W['platillos'] is List
          ? [for (final x in W['platillos'] as List) '$x']
          : const ['salado', 'dulce', 'picante'];
      final taste = idx < ord.length ? ord[idx] : 'salado';

      // Frog hops a tiny beat to feed target
      for (final dy in const [-5, -2, 0]) {
        q['dy'] = dy;
        await wait(70);
      }
      if (p != null) {
        p['ojos'] = 0;
        p['come'] = 1;
        await wait(180);
        p['come'] = 0;
        if (ok) {
          p['pose'] = 'wave0';
          W['corazonFx'] = 1;
          await wait(240);
          p['pose'] = 'idle';
          W['corazonFx'] = 0;
        } else {
          p['cara'] = 1;
          if (taste == 'picante') p['rojo'] = 1;
          for (final dx in const [-2, 2, -2, 0]) {
            p['dx'] = dx;
            await wait(75);
          }
          // Gulps down a glass of lemonade from the jar
          p['pose'] = 'taza';
          await wait(220);
          p['pose'] = 'idle';
          p['cara'] = 0;
          p['rojo'] = 0;
        }
      }
    }),
    'final90': (o) => _run(o, () async {
      final n = _n(o['n']).clamp(1, 3);
      W['jarra'] = n;
      W['vasos'] = n;
      W['final90'] = n;
      W['corazonFx'] = n == 3 ? 1 : 0;
      W['estrellaFx'] = n == 3 ? 1 : 0;
      for (final id in const ['luis', 'carmen']) {
        final p = _personOf(id);
        if (p != null) p['pose'] = 'taza';
      }
      await wait(360);
      for (final id in const ['luis', 'carmen']) {
        final p = _personOf(id);
        if (p != null) p['pose'] = 'idle';
      }
    }),

    /* ---------- Story 91: Falta algo ---------- */
    'trae91': (o) => _run(o, () async {
      // OPEN: no table spots for metal cups or abuela's coffee cup; the frog carries the chosen shelf item over to the
      // table and returns to `auxiliar_coqui` so all four shelf items remain visible and touchable and `frog-station`
      // holds after every act.
      final que = (o['que'] as String?) ?? 'sal';
      final a = (o['a'] as String?) ?? 'abuela';
      final ok = _n(o['ok']) != 0;
      final q = W['cq'] as Map<String, dynamic>;
      final p = _personOf(a);
      W['lleva'] = que;
      await _hopFrogTo('mesa_coqui');
      if (p != null) {
        if (ok) {
          p['pose'] = 'offer';
          await wait(200);
          p['pose'] = 'idle';
        } else {
          for (final dx in const [-2, 2, -2, 0]) {
            p['dx'] = dx;
            await wait(70);
          }
        }
      }
      W['lleva'] = null;
      await _hopFrogTo('auxiliar_coqui');
      q['dy'] = 0;
    }),
    'sopas': (o) => _run(o, () async {
      final n = _n(o['n']).clamp(0, 3);
      W['sopasVis'] = 1;
      W['sopas'] = n;
      // Put down spoons for bowls that stopped steaming (index >= n among abuela, abuelo, luis)
      const who = ['abuela', 'abuelo', 'luis'];
      for (var i = 0; i < who.length; i++) {
        final p = _personOf(who[i]);
        if (p != null && i >= n) p['cuchara'] = 0;
      }
      await wait(160);
    }),
    'final91': (o) => _run(o, () async {
      final n = _n(o['n']).clamp(1, 3);
      W['sopasVis'] = 1;
      W['sopas'] = n;
      W['final91'] = n;
      W['corazonFx'] = n == 3 ? 1 : 0;
      W['estrellaFx'] = n == 3 ? 1 : 0;
      W['servilletaBrazo'] = 1;
      const who = ['abuela', 'abuelo', 'luis'];
      for (var i = 0; i < who.length; i++) {
        final p = _personOf(who[i]);
        if (p != null) p['cuchara'] = i < n ? 1 : 0;
      }
      await wait(320);
    }),
    'sube91': (o) => _run(o, () async {
      W['sopasVis'] = 0;
      W['servilletaBrazo'] = 1;
      await _hopFrogTo('mesa_coqui');
      W['corazonFx'] = 1;
      await wait(180);
    }),

    /* ---------- Story 92: Más y menos ---------- */
    'prueba92': (o) => _run(o, () async {
      final que = (o['que'] as String?) ?? 'prueba';
      final co = _personOf('cocinero');
      if (que == 'sal') {
        if (co != null) co['pose'] = 'offer';
        W['salFx'] = 1;
        await wait(240);
        W['salFx'] = 0;
        if (co != null) co['pose'] = 'idle';
      } else if (que == 'salsa') {
        if (co != null) co['pose'] = 'offer';
        W['salsaFx'] = 1;
        await wait(260);
        W['salsaFx'] = 0;
        if (co != null) co['pose'] = 'idle';
      } else {
        if (co != null) {
          co['come'] = 1;
          co['pose'] = 'yo';
          await wait(220);
          co['come'] = 0;
          co['pose'] = 'idle';
        }
      }
    }),
    'tazon': (o) => _run(o, () async {
      final n = _n(o['n']).clamp(0, 3);
      W['tazonVis'] = 1;
      W['tazon'] = n;
      await wait(140);
    }),
    'monton92': (o) => _run(o, () async {
      final a = (o['a'] as String?) ?? 'abuela';
      final co = _personOf('cocinero');
      if (co != null) co['pose'] = 'offer';
      W['platoArroz'] = 'normal';
      W['platoArrozQuien'] = a;
      await wait(180);
      if (co != null) co['pose'] = 'idle';
    }),
    'sirve92': (o) => _run(o, () async {
      final que = (o['que'] as String?) ?? 'bien';
      final ok = _n(o['ok']) != 0;
      final q = W['cq'] as Map<String, dynamic>;
      final quien = W['platoArrozQuien'] as String?;
      final p = _personOf(quien);
      // Frog acts on the plate
      for (final dy in const [-5, 0]) {
        q['dy'] = dy;
        await wait(80);
      }
      if (que == 'mas') {
        W['platoArroz'] = 'mas';
      } else if (que == 'menos') {
        W['platoArroz'] = 'menos';
        W['platoPerroLleno'] = 1;
        W['perroMood'] = 'eat';
        await wait(180);
        W['perroMood'] = 'sit';
      } else {
        W['platoArroz'] = 'normal';
      }
      if (ok) {
        if (p != null) {
          p['pose'] = 'wave0';
          await wait(200);
          p['pose'] = 'idle';
        }
        // Keep the guest visible until the next `llega` or `final92` so any immediate reaction line / `gesto come`
        // (story 92 steps 2..5) still has the speaker on screen; clear the held plate after serving.
        W['platoArroz'] = null;
      } else {
        // Wrong serving: guest shakes head, plate goes into dog's bowl, cocinero fills a new one
        if (p != null) {
          p['cara'] = 1;
          for (final dx in const [-2, 2, -2, 0]) {
            p['dx'] = dx;
            await wait(75);
          }
          p['cara'] = 0;
        }
        W['platoPerroLleno'] = 1;
        W['perroMood'] = 'eat';
        W['platoArroz'] = 'normal';
        await wait(220);
        W['perroMood'] = 'sit';
      }
    }),
    'final92': (o) => _run(o, () async {
      final n = _n(o['n']).clamp(1, 3);
      // Guests are gone; clear everyone in the line
      final gente = (W['gente'] as Map<String, dynamic>?) ?? const {};
      for (final id in const [
        'abuela',
        'abuelo',
        'luis',
        'carmen',
        'senor',
        'senora',
        'joven',
        'mujer',
      ]) {
        final p = gente[id] as Map<String, dynamic>?;
        if (p != null) p['vis'] = 0;
      }
      W['platoArroz'] = null;
      W['platoArrozQuien'] = null;
      W['tazonVis'] = 1;
      W['tazon'] = n;
      W['final92'] = n;
      W['corazonFx'] = n == 3 ? 1 : 0;
      W['estrellaFx'] = n == 3 ? 1 : 0;
      W['perroMood'] = n == 1 ? 'sleep' : 'sit';
      await wait(320);
    }),

    /* ---------- Shared gestures (`gesto`) & `fin` ---------- */
    'gesto': (o) => _run(o, () async {
      final quien = (o['quien'] as String?) ?? 'coqui';
      final que = (o['que'] as String?) ?? 'si';
      if (quien == 'coqui') {
        final q = W['cq'] as Map<String, dynamic>;
        if (que == 'no') {
          for (final dx in const [-3, 3, -2, 0]) {
            q['dx'] = dx;
            await wait(70);
          }
        } else if (que == 'come' || que == 'bebe') {
          for (final dy in const [-3, 0, -3, 0]) {
            q['dy'] = dy;
            await wait(80);
          }
        } else {
          for (final dy in const [-5, 0]) {
            q['dy'] = dy;
            await wait(85);
          }
        }
        return;
      }
      final p = _personOf(quien);
      if (p == null) return;
      switch (que) {
        case 'saluda':
          p['pose'] = 'wave0';
          await wait(140);
          p['pose'] = 'wave1';
          await wait(140);
          p['pose'] = 'idle';
        case 'no':
          for (final dx in const [-2, 2, -2, 0]) {
            p['dx'] = dx;
            await wait(75);
          }
        case 'si':
          for (final dy in const [2, 0, 2, 0]) {
            p['dy'] = dy;
            await wait(75);
          }
        case 'rie':
          for (var i = 0; i < 4; i++) {
            p['dy'] = i.isEven ? -2 : 0;
            await wait(80);
          }
          p['dy'] = 0;
        case 'mira':
          p['pose'] = 'idle';
          await wait(120);
        case 'senala':
          p['pose'] = 'tu';
          await wait(240);
          p['pose'] = 'idle';
        case 'ojos':
          p['ojos'] = 1;
          await wait(140);
        case 'come':
          p['come'] = 1;
          await wait(220);
          p['come'] = 0;
        case 'bebe':
          p['pose'] = 'taza';
          await wait(220);
          p['pose'] = 'idle';
        case 'cara':
          p['cara'] = 1;
          await wait(220);
          p['cara'] = 0;
        case 'tapa':
          p['tapa'] = 1;
          await wait(240);
          p['tapa'] = 0;
        case 'cuchara':
          p['cuchara'] = _n(p['cuchara']) == 0 ? 1 : 0;
          await wait(120);
        default:
          await wait(100);
      }
    }),
    'fin': (o) async {
      final q = W['cq'] as Map<String, dynamic>;
      for (var i = 0; i < 3; i++) {
        q['dy'] = -6;
        await wait(110);
        q['dy'] = 0;
        await wait(110);
      }
    },
  };
}
