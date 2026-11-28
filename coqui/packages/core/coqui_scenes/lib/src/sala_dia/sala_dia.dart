// La sala, de día (place 9, La casa, un día entero, scene 3: `sala_dia`; stories 102 to 104): a NEW scene, written
// from its script's "Needs" list (historia/notas/guiones/sala_dia.md) on its set (sala_dia_set.dart) and its sheet
// (sala_dia-sheet.json, read by SceneSheet). There is no old scene file: every act is in sala_dia_acts.dart, each
// doing on screen what the Needs list says, every place from the sheet (spots, set thing boxes, depth rule, shadows).
// Where the sheet names no place or an act is unstated in the script, the code does the plainest thing that keeps the
// story playing and marks it `OPEN:`.
//
// The drawing (the sheet's `front`): every sprite stands with its feet's bottom edge on its spot's row and its
// middle on its column (rules.anchor); seated people hang by their lap (abuelo: 24, 41; Luis and Carmen: 24, 33);
// standing abuela anchors at (30, inkBottom); the photo in Carmen's hands has `dd: 0.02`; every sprite pixel is hidden
// by every baked set pixel (`baked.zb`) nearer than its upright plane plus `front.bias` (0.3). Between two sprites the
// nearer pixel wins (tie within 0.001 goes to the later layer).
// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/src/colmado/colmado_cast.dart' show inkBottom;
import 'package:coqui_scenes/src/sala_dia/sala_dia_places.dart';
import 'package:coqui_scenes/src/sala_dia/sala_dia_set.dart';
import 'package:coqui_scenes/src/sala_dia/sala_dia_sprites.dart';
import 'package:coqui_scenes/src/scene_set.dart';
import 'package:coqui_scenes/src/sheet_cache.dart';

part 'sala_dia_acts.dart';

/// The scene "La sala, de día", made from its sheet (read first: `loadScene`).
Scene createSalaDia() => SalaDia(sceneSheetOf('sala_dia'));

int _round(num v) => (v + 0.5).floor();

int _n(Object? v) {
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? 0;
  return 0;
}

/// One sprite of the sprite layer, placed: its picture, its top left on the 240 × 216 picture, the screen row of its
/// anchor and the depth there (front.plane), and who or what it is.
class SalaDiaItem {
  SalaDiaItem(
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

/// Every drawn person La sala, de día knows, by speaker key (sala_dia.md, "Needs").
const List<String> SALA_DIA_PERSONAS = ['abuelo', 'luis', 'carmen', 'abuela'];

/// Every speaker key supported by [SalaDia.talkAt] (6 speakers: four drawn people, mamá on the telephone, and coquí).
const List<String> SALA_DIA_SPEAKERS = [...SALA_DIA_PERSONAS, 'mama', 'coqui'];

class SalaDia extends Escena implements SetScene, SetOverSprites {
  SalaDia(this.ss)
    : sheet = identical(ss, _lastSs)
          ? _lastSheet!
          : (_lastSheet = ss.legacy()) {
    _p = identical(ss, _lastSs)
        ? _lastPlaces!
        : (_lastPlaces = SalaDiaPlaces(ss));
    _lastSs = ss;
    CAM = {'wide': _p.view('wide')};
    LUGAR = {
      for (final en in ss.spots.entries)
        if (en.value.world != null) en.key: _frogAt(_p.at(en.key)),
      // OPEN: gen_sala_dia.py & sala_dia.md Needs name the frog's spot `mesa_coqui`, while sala_dia-sheet.json names it
      // `junto_mesa_coqui`. Alias it so `ir` and LUGAR lookups resolve cleanly.
      'mesa_coqui': _frogAt(_p.at('junto_mesa_coqui')),
    };
    cosas = _things();
  }

  static SceneSheet? _lastSs;
  static Sheet? _lastSheet;
  static SalaDiaPlaces? _lastPlaces;

  /// The new scene's sheet (SceneSheet).
  final SceneSheet ss;

  @override
  final Sheet sheet;

  late final SalaDiaPlaces _p;

  /// The scene's places, from its sheet.
  SalaDiaPlaces get places => _p;

  @override
  String get id => 'sala_dia';

  @override
  late final Map<String, List<num>> CAM;

  late final Map<String, List<num>> LUGAR;

  @override
  Map<String, List<num>> get lugar => LUGAR;

  @override
  late final List<Thing> cosas;

  @override
  PpEngine newEngine({bool still = false}) => salaDiaEngine(still: still);

  @override
  PpEngine get projection => _p.e;

  List<num> _frogAt(SalaDiaAt a) => [_round(a.sx) - 16, _round(a.sy) - 25, 1];

  Map<String, dynamic> get W => host.W;
  int get F => host.F;
  int get TICK => host.TICK;
  Future<void> wait(num ms) => host.wait(ms);

  /* ---------- spot aliases & state ---------- */

  /// Resolves script spot names to sheet spot names (`mesa_coqui` -> `junto_mesa_coqui`).
  String _resolveSpot(String spot) {
    if (spot == 'mesa_coqui') return 'junto_mesa_coqui';
    return spot;
  }

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
    final resolved = _resolveSpot(spot);
    final w = _p.world(resolved);
    p['x'] = w[0];
    p['y'] = w[1];
    p['z'] = w[2];
    p['spot'] = resolved;
    p['vis'] = 1;
    p['dx'] = 0;
    p['dy'] = 0;
    if (sent != null) p['sent'] = sent;
  }

  @override
  Map<String, dynamic> fresh(Map<String, dynamic> story) {
    final acts = _actsOf([story['beats'], story['final']]);
    bool has(String a) => acts.any((o) => o['act'] == a);
    final is104 =
        has('pantalla104') ||
        has('pagina104') ||
        has('foto104') ||
        has('pega104') ||
        has('estrellas') ||
        has('final104');
    final is103 =
        !is104 &&
        (has('suena103') ||
            has('oido103') ||
            has('boca103') ||
            has('pone103') ||
            has('bateria') ||
            has('final103'));
    final storyNum = is104 ? 104 : (is103 ? 103 : 102);
    final startSpot = is103 ? 'brazo_coqui' : 'junto_mesa_coqui';
    final q = _frogAt(_p.at(startSpot));

    final gente = <String, dynamic>{
      'abuelo': _person('butaca', vis: is103 ? 1 : 0, sent: 1),
      'luis': _person(is104 ? 'escritorio' : 'cojin1', vis: 1, sent: 1),
      'carmen': _person('cojin2', vis: 1, sent: 1),
      'abuela': _person(
        is103 ? 'ventana_abuela' : 'estante',
        vis: is104 ? 0 : 1,
        sent: 0,
      ),
    };

    return <String, dynamic>{
      'story': storyNum,
      'hora': 'tarde',
      'pantalla': 0,
      'clockHour': 3,
      'gente': gente,
      // Story 102 state (Lee y escribe)
      'libroVis': storyNum == 102 ? 1 : 0,
      'libroOpen': 0,
      'libroScribbled': 0,
      'libroPatched': 0,
      'papelVis': storyNum == 102 ? 1 : 0,
      'hojas': 5,
      'miniFrog': 0,
      'abuelaHarina': 0,
      'libroCon': null, // null | 'luis' | 'carmen'
      'papelCon': null, // null | 'luis' | 'carmen'
      'leeFx': null, // {quien: 'luis'|'carmen', kind: 'barco'|'estrella'}
      'escribeFx': null, // {quien: 'luis'|'carmen', nombres: bool}
      'avionFx': null, // {x: int, y: int}
      'dibujoFinal': 0, // 0, 1, 2, 3
      // Story 103 state (El teléfono)
      'telefonoVis': is103 ? 1 : 0,
      'telefonoLit': 0,
      'telefonoRing': 0,
      'bateria': 3,
      'bateriaBlink': 0,
      'telefonoHolder': 'mesa', // 'mesa' | 'abuela' | 'coqui' | 'abuelo'
      'telefonoDonde': null, // null | 'oreja_abuelo' | 'boca_abuelo'
      'abuelaPhone': null, // null | 'ear' | 'mouth'
      'abuelaSilencio': 0,
      'abueloDoze': is103 ? 1 : 0,
      'abueloEar': 0,
      'abueloSmile': 0,
      'abueloNod': 0,
      'abueloHoldPhone': 0,
      'anillosFx': 0,
      'vozFx': null, // {kind: String, x: int, y: int}
      // Story 104 state (Por la tarde)
      'paginasVis': is104 ? 1 : 0,
      'paginaGlow': 0, // 0, 1, 2, 3
      'paginaPhotos':
          <int, List<String>>{}, // page (1..3) -> photo keys stuck on it
      'paginaTorn': <int>{}, // pages (1..3) with a torn corner + gold star
      'estrellasVis': is104 ? 1 : 0,
      'estrellas': 3,
      'foto': null, // null or photo key string in Carmen's hands
      'fotoTorn': 0,
      'luisNotebook': is104 ? 1 : 0,
      'luisBall': 0,
      'avecesFx': null, // null | 'compu' | 'libro'
      'portadaFinal': 0, // 0, 1, 2, 3
      // Shared FX & HUD
      'celebrar': 0, // 0 none, 1 heart only, 2 stars + heart
      'gestoCue': null,
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
  String setKey(Map<String, dynamic> W) => _n(W['pantalla']) != 0 ? '1' : '0';

  @override
  void buildSet(PpEngine e, PpBuild b, Map<String, dynamic> W) =>
      buildSetFor(e, b, setKey(W));

  final Map<PpEngine, SalaDiaSet> _sets = {};

  @override
  void buildSetFor(PpEngine e, PpBuild b, String key) =>
      (_sets[e] ??= SalaDiaSet(e, b)).buildSet(SalaDiaState.fromKey(key));

  @override
  bool get frogShadow => false;

  /* ---------- where everybody is ---------- */

  Map<String, dynamic> get _gente => W['gente'] as Map<String, dynamic>;

  SalaDiaAt _atOf(Map<String, dynamic> o) =>
      _p.atWorld(o['x'] as num, o['y'] as num, o['z'] as num);

  SalaDiaAt _frogPoint(Map<String, dynamic> q) {
    final spot = q['spot'];
    if (spot is String) {
      final resolved = _resolveSpot(spot);
      if (_p.has(resolved)) {
        final at = _p.at(resolved);
        final L = _frogAt(at);
        if (q['x'] == L[0] && q['y'] == L[1]) return at;
      }
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
    final kp = _kitPoseOf(pose);
    final phoneLit = _n(w['telefonoLit']) == 1;
    final phoneBars = _n(w['bateria']).clamp(0, 3);
    final phoneBlink = _n(w['bateriaBlink']) == 1 && anim % 2 == 1;
    if (id == 'abuela') {
      final harina = _n(w['abuelaHarina']) == 1;
      final silencio = _n(w['abuelaSilencio']) == 1;
      final phone = w['abuelaPhone'] as String?;
      final s = _spr(
        'sd_ab_${kp}_${open}_${harina}_${silencio}_${phone}_${phoneLit}_${phoneBars}_$phoneBlink',
        () => mkAbuelaSalaDia(
          kp,
          open,
          harina: harina,
          silencio: silencio,
          phone: phone,
          phoneLit: phoneLit,
          phoneBars: phoneBars,
          phoneBlink: phoneBlink,
        ),
      );
      // sala_dia-sheet.json rules.anchor: abuela standing (mkAbuela, 48 wide): col 30, lowest drawn row.
      return (s: s, ax: 30, ay: inkBottom(s));
    }
    if (id == 'abuelo') {
      final doze = _n(w['abueloDoze']) == 1;
      final cupEar = _n(w['abueloEar']) == 1;
      final smile = _n(w['abueloSmile']) == 1;
      final nod = _n(w['abueloNod']) == 1;
      final holdPhone = _n(w['abueloHoldPhone']) == 1;
      final donde = w['telefonoDonde'] as String?;
      final phone = switch (donde) {
        'oreja_abuelo' => 'ear',
        'boca_abuelo' => 'mouth',
        _ => null,
      };
      final s = _spr(
        'sd_abo_${kp}_${open}_${doze}_${cupEar}_${smile}_${nod}_${holdPhone}_${phone}_${phoneLit}_${phoneBars}_$phoneBlink',
        () => mkAbueloSalaDia(
          kp,
          open,
          doze: doze,
          cupEar: cupEar,
          smile: smile,
          nod: nod,
          holdPhone: holdPhone,
          phone: phone,
          phoneLit: phoneLit,
          phoneBars: phoneBars,
          phoneBlink: phoneBlink,
        ),
      );
      return (s: s, ax: PX, ay: salaDiaSeatedLap(FAM['abuelo']!));
    }
    if (id == 'luis') {
      final nb = _n(w['luisNotebook']) == 1;
      final ball = _n(w['luisBall']) == 1;
      final reads = w['libroCon'] == 'luis';
      final sheet = w['papelCon'] == 'luis';
      final writes =
          w['escribeFx'] is Map && (w['escribeFx'] as Map)['quien'] == 'luis';
      final s = _spr(
        'sd_luis_${kp}_${open}_${sent}_${nb}_${ball}_${writes}_${reads}_$sheet',
        () => sent
            ? mkNinoSalaDia(
                FAM['hermano']!,
                kp,
                open,
                notebook: nb,
                ball: ball,
                writes: writes,
                reads: reads,
                sheet: sheet,
              )
            : mkPersona(FAM['hermano']!, kp, open, false),
      );
      return (
        s: s,
        ax: PX,
        ay: sent ? salaDiaSeatedLap(FAM['hermano']!) : inkBottom(s),
      );
    }
    // carmen
    final reads = w['libroCon'] == 'carmen';
    final sheet = w['papelCon'] == 'carmen';
    final writes =
        w['escribeFx'] is Map && (w['escribeFx'] as Map)['quien'] == 'carmen';
    final s = _spr(
      'sd_car_${kp}_${open}_${sent}_${writes}_${reads}_$sheet',
      () => sent
          ? mkNinoSalaDia(
              FAM['hermana']!,
              kp,
              open,
              writes: writes,
              reads: reads,
              sheet: sheet,
            )
          : mkPersona(FAM['hermana']!, kp, open, false),
    );
    return (
      s: s,
      ax: PX,
      ay: sent ? salaDiaSeatedLap(FAM['hermana']!) : inkBottom(s),
    );
  }

  String? _talker() {
    try {
      return host.TALK;
    } catch (_) {
      return null;
    }
  }

  /// Every sprite of the frame [w] as it is placed, except the frog. The rules' tests read it; [draw] draws it.
  List<SalaDiaItem> items(Map<String, dynamic> w, int a) {
    final out = <SalaDiaItem>[];
    final talk = _talker();
    final gente = (w['gente'] as Map<String, dynamic>?) ?? const {};
    final anim = (F >> 2) + a;

    // 0. Wall clock hands (E.CLOCK on back wall v = 0, z = 2.3 -> screen ~(63, 14), dd +0.05 in front of wall face).
    final clkAt = _p.atUv(SalaDiaE.CLOCK[0], 0, SalaDiaE.CLOCK[1]);
    final clkSpr = _spr(
      'sd_clk_${_n(w['clockHour'])}',
      () => mkRelojManecillas(hour: _n(w['clockHour'])),
    );
    out.add(
      SalaDiaItem(
        clkSpr,
        _round(clkAt.sx) - 5,
        _round(clkAt.sy) - 5,
        _round(clkAt.sy),
        clkAt.d + .05,
        tag: 'fx:reloj',
      ),
    );

    // 1. People (abuelo, luis, carmen, abuela)
    for (final id in SALA_DIA_PERSONAS) {
      final p = gente[id] as Map<String, dynamic>?;
      if (p == null || p['vis'] == 0) continue;
      final open = talk == id && a % 2 == 1;
      final sp = _personSprite(id, p, w, open, anim);
      final at = _atOf(p);
      final sx = _round(at.sx) + _n(p['dx']);
      final sy = _round(at.sy) + _n(p['dy']);
      out.add(
        SalaDiaItem(sp.s, sx - sp.ax, sy - sp.ay, sy, at.d, tag: 'persona:$id'),
      );
    }

    // 2. Story 102 table props: libro & papel
    if (_n(w['libroVis']) == 1) {
      final at = _p.at('libro');
      final open = _n(w['libroOpen']) == 1;
      final scrib = _n(w['libroScribbled']) == 1;
      final patch = _n(w['libroPatched']) == 1;
      final s = _spr(
        'sd_libro_${open}_${scrib}_$patch',
        () => mkLibro(open: open, scribbled: scrib, patched: patch),
      );
      final sx = _round(at.sx), sy = _round(at.sy);
      out.add(
        SalaDiaItem(s, sx - s.w ~/ 2, sy - s.h, sy, at.d, tag: 'cosa:libro'),
      );
    }
    if (_n(w['papelVis']) == 1) {
      final at = _p.at('papel');
      final h = _n(w['hojas']).clamp(0, 5);
      final mf = _n(w['miniFrog']) == 1;
      final s = _spr('sd_papel_${h}_$mf', () => mkPapel(h, miniFrog: mf));
      final sx = _round(at.sx), sy = _round(at.sy);
      out.add(
        SalaDiaItem(s, sx - s.w ~/ 2, sy - s.h, sy, at.d, tag: 'cosa:papel'),
      );
    }

    // 3. Story 103 table prop: telefono (drawn on the low table until picked up by abuela, coquí, or abuelo)
    if (_n(w['telefonoVis']) == 1 &&
        (w['telefonoHolder'] ?? 'mesa') == 'mesa') {
      final at = _p.at('telefono');
      final lit = _n(w['telefonoLit']) == 1;
      final ring = _n(w['telefonoRing']) == 1;
      final bars = _n(w['bateria']).clamp(0, 3);
      final blink = _n(w['bateriaBlink']) == 1 && anim % 2 == 1;
      final s = _spr(
        'sd_tel_${lit}_${ring}_${bars}_$blink',
        () => mkTelefono(lit: lit, ringing: ring, bars: bars, blink: blink),
      );
      final sx = _round(at.sx), sy = _round(at.sy);
      out.add(
        SalaDiaItem(s, sx - s.w ~/ 2, sy - s.h, sy, at.d, tag: 'cosa:telefono'),
      );
      if (ring) {
        final rs = _spr('sd_ring_${anim % 2}', () => mkTelefonoRing(anim % 2));
        out.add(
          SalaDiaItem(rs, sx - 7, sy - 14, sy - 7, at.d + .02, tag: 'fx:ring'),
        );
      }
    }

    // 4. Story 104 table & hand props: pagina1..pagina3, estrellas, foto
    if (_n(w['paginasVis']) == 1) {
      final glowN = _n(w['paginaGlow']);
      final photosByPage = (w['paginaPhotos'] as Map?) ?? const {};
      final torns = (w['paginaTorn'] as Set?) ?? const <int>{};
      for (var i = 1; i <= 3; i++) {
        final spot = 'pagina$i';
        final at = _p.at(spot);
        final g = glowN == i;
        final pagePhotos =
            (photosByPage[i] as List?)?.cast<String>() ?? const <String>[];
        final tr = torns.contains(i);
        final pKey = pagePhotos.join(',');
        final s = _spr(
          'sd_pag_${i}_${g}_${pKey}_$tr',
          () => mkPagina(i, glow: g, photos: pagePhotos, torn: tr),
        );
        final sx = _round(at.sx), sy = _round(at.sy);
        out.add(
          SalaDiaItem(s, sx - s.w ~/ 2, sy - s.h, sy, at.d, tag: 'cosa:$spot'),
        );
      }
    }
    if (_n(w['estrellasVis']) == 1) {
      final at = _p.at('estrellas');
      final n = _n(w['estrellas']).clamp(0, 3);
      final s = _spr('sd_estr_$n', () => mkEstrellasBox(n));
      final sx = _round(at.sx), sy = _round(at.sy);
      out.add(
        SalaDiaItem(
          s,
          sx - s.w ~/ 2,
          sy - s.h,
          sy,
          at.d,
          tag: 'cosa:estrellas',
        ),
      );
    }
    final fotoQue = w['foto'] as String?;
    if (fotoQue != null && fotoQue.isNotEmpty) {
      final at = _p.at('foto');
      final torn = _n(w['fotoTorn']) == 1;
      final s = _spr(
        'sd_foto_${fotoQue}_$torn',
        () => mkFoto(fotoQue, torn: torn),
      );
      final sx = _round(at.sx), sy = _round(at.sy);
      // sala_dia-preview.html moment 5: foto has dd: +0.02 so it renders in front of Carmen's torso (below her head).
      out.add(
        SalaDiaItem(
          s,
          sx - s.w ~/ 2,
          sy - s.h,
          sy,
          at.d + .02,
          tag: 'cosa:foto',
        ),
      );
    }

    // 5. Story 102 transient & ending FX (all placed strictly clear of seated heads, frog, and table props)
    final lee = w['leeFx'];
    if (lee is Map) {
      final who = (lee['quien'] as String?) ?? 'luis';
      final kind = (lee['kind'] as String?) ?? 'barco';
      final p = gente[who] as Map<String, dynamic>?;
      if (p != null && p['vis'] != 0) {
        final at = _atOf(p);
        final sx = _round(at.sx);
        final s = _spr('sd_lee_$kind', () => mkLeePic(kind));
        // Head top is row 78 for children on cushions -> rows 66..73 are cleanly above their heads.
        out.add(SalaDiaItem(s, sx - 5, 66, 74, at.d + .05, tag: 'fx:lee'));
      }
    }
    final esc = w['escribeFx'];
    if (esc is Map) {
      final who = (esc['quien'] as String?) ?? 'carmen';
      final nombres = esc['nombres'] == true;
      final p = gente[who] as Map<String, dynamic>?;
      if (p != null && p['vis'] != 0) {
        final at = _atOf(p);
        final sx = _round(at.sx);
        final s = _spr(
          'sd_esc_$nombres',
          () => mkHojaEscrita(nombres: nombres),
        );
        out.add(SalaDiaItem(s, sx - 6, 66, 74, at.d + .05, tag: 'fx:escribe'));
      }
    }
    final avion = w['avionFx'];
    if (avion is Map) {
      final ax = _n(avion['x']), ay = _n(avion['y']);
      final s = _spr('sd_avion', mkAvionPapel);
      out.add(SalaDiaItem(s, ax - 5, ay - 3, ay + 4, 6.0, tag: 'fx:avion'));
    }
    final dibujo = _n(w['dibujoFinal']);
    if (dibujo > 0) {
      final s = _spr('sd_dib_$dibujo', () => mkDibujoRana(dibujo));
      // OPEN: sala_dia-sheet.json has no spot for Carmen's final frog drawing; place below low-table props
      // (rows 116..131, cols 110..142) so libro, papel, frog, and heads stay 100% uncovered.
      out.add(
        SalaDiaItem(
          s,
          126 - s.w ~/ 2,
          116,
          116 + s.h,
          4.5,
          tag: 'fx:dibujo_final',
        ),
      );
    }

    // 6. Story 103 transient FX (clear of frog at 148..179/63..86, abuelo head 185..198/54..67, ear/mouth boxes)
    if (_n(w['anillosFx']) == 1) {
      final s = _spr('sd_an_${anim % 2}', () => mkAnillos(anim % 2));
      out.add(SalaDiaItem(s, 166, 52, 60, 4.5, tag: 'fx:anillos'));
    }
    final voz = w['vozFx'];
    if (voz is Map) {
      final kind = (voz['kind'] as String?) ?? 'guagua';
      final vx = _n(voz['x']), vy = _n(voz['y']);
      final s = _spr('sd_voz_$kind', () => mkVozPic(kind));
      out.add(SalaDiaItem(s, vx, vy, vy + s.h, 4.5, tag: 'fx:voz'));
    }

    // 7. Story 104 transient & ending FX
    final av = w['avecesFx'] as String?;
    if (av != null) {
      // Over Luis at escritorio (head rows 37..50) and below clock (rows 7..21): rows 24..33, cols 54..65.
      final s = _spr('sd_av_$av', () => mkAvecesPic(av));
      out.add(SalaDiaItem(s, 54, 24, 34, 4.5, tag: 'fx:aveces'));
    }
    final port = _n(w['portadaFinal']);
    if (port > 0) {
      final s = _spr('sd_port_$port', () => mkPortadaAlbum(port));
      // OPEN: sala_dia-sheet.json has no spot for the shut album cover; place below pagina1..3 (rows 116..129).
      out.add(
        SalaDiaItem(
          s,
          127 - s.w ~/ 2,
          116,
          116 + s.h,
          4.5,
          tag: 'fx:portada_final',
        ),
      );
    }

    // 8. Directional gesture cue & ending celebration (open wall space rows 40..50, cols 114..150)
    final gc = w['gestoCue'];
    if (gc is Map) {
      final isUp = gc['up'] == true;
      final s = _spr('sd_gc_$isUp', () => mkGestoFlechaSalaDia(up: isUp));
      final cx = _n(gc['cueX']), cy = _n(gc['cueY']);
      final cd = (gc['d'] as num?)?.toDouble() ?? 5.0;
      out.add(SalaDiaItem(s, cx - 4, cy, cy + 7, cd, tag: 'fx:gesto_cue'));
    }
    final cel = _n(w['celebrar']);
    if (cel >= 1) {
      final hr = _spr('sd_heart', mkCorazonSalaDia);
      out.add(SalaDiaItem(hr, 128, 40, 49, 5.5, tag: 'fx:corazon'));
      if (cel >= 2) {
        final st = _spr('sd_star', mkEstrellaSalaDia);
        out.add(SalaDiaItem(st, 114, 42, 51, 5.5, tag: 'fx:estrella1'));
        out.add(SalaDiaItem(st, 142, 42, 51, 5.5, tag: 'fx:estrella2'));
      }
    }

    return out;
  }

  static final Map<String, Sprite> _frogSprites = {};

  /// [items] plus the frog (as the host draws him), for `draw` and for `SalaDiaRules`.
  List<SalaDiaItem> placed(Map<String, dynamic> w, int a) {
    final out = items(w, a);
    final q = w['cq'] as Map<String, dynamic>?;
    if (q != null && jsTruthy(q['vis'])) {
      final at = _frogPoint(q);
      final dx = _n(q['dx']);
      final fsy = _round(at.sy);
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
      out.add(SalaDiaItem(spr, ox, oy, fsy, at.d, tag: 'coqui'));
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
    SalaDiaItem it,
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
    // Frog shadow only when on the floor (`junto_mesa_coqui`, z == 0, not in shadows.none).
    final q = W['cq'] as Map<String, dynamic>?;
    if (q != null && jsTruthy(q['vis'])) {
      final at = _frogPoint(q);
      final spot = q['spot'] as String?;
      final resolved = spot != null ? _resolveSpot(spot) : null;
      if (at.z == 0 && (resolved == null || !_p.noShadow(resolved))) {
        final r = _p.radius('coqui');
        if (r != null) out.add((x: at.x, y: at.y, z: 0.0, r: r));
      }
    }
    return out;
  }

  /* ---------- talk bubbles (all 6 speakers) ---------- */

  @override
  List<num>? talkAt(String who, Map<String, dynamic> W) {
    if (who == 'coqui') {
      final q = W['cq'] as Map<String, dynamic>?;
      if (q == null || !jsTruthy(q['vis'])) return null;
      final b = host.frogBox(q);
      return [b.x + b.w / 2, b.y - 4];
    }
    if (who == 'mama') {
      // Mamá is heard on the telephone only (story 103): point bubble at whoever holds it, or the telephone on table.
      final holder = W['telefonoHolder'] as String?;
      final gente = (W['gente'] as Map<String, dynamic>?) ?? const {};
      if (holder == 'abuela') {
        final ab = gente['abuela'] as Map<String, dynamic>?;
        if (ab != null && ab['vis'] != 0) {
          final at = _atOf(ab);
          return [_round(at.sx) - 6, _round(at.sy) - 42];
        }
      } else if (holder == 'coqui' || holder == 'abuelo') {
        final donde = W['telefonoDonde'] as String?;
        if (donde == 'oreja_abuelo' || donde == 'boca_abuelo') {
          final b = _p.box(donde!);
          return [b[0] + b[2] ~/ 2, b[1] - 4];
        }
        final at = _p.at('brazo_coqui');
        return [_round(at.sx), _round(at.sy) - 28];
      }
      if (_n(W['telefonoVis']) == 1) {
        final at = _p.at('telefono');
        return [_round(at.sx), _round(at.sy) - 10];
      }
      return null;
    }
    final gente = (W['gente'] as Map<String, dynamic>?) ?? const {};
    final p = gente[who] as Map<String, dynamic>?;
    if (p == null || p['vis'] == 0) {
      // OPEN: in story 104, abuela speaks from off-screen (gen_sala_dia.py has no `llega` for her); anchor her
      // bubble at the kitchen doorway (`cocina`) so her lines always have a clean speaker point.
      if (who == 'abuela') {
        final at = _p.at('cocina');
        return [_round(at.sx), _round(at.sy) - 52];
      }
      return null;
    }
    final at = _atOf(p);
    final dy = switch (who) {
      'abuela' => 52,
      'abuelo' => 40,
      _ => 34, // luis, carmen seated
    };
    return [_round(at.sx) + _n(p['dx']), _round(at.sy) + _n(p['dy']) - dy];
  }

  /* ---------- touch things & hit testing (all 17 Needs things) ---------- */

  static List<int>? _itemBox(
    List<SalaDiaItem> list,
    bool Function(SalaDiaItem) test,
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

  // Order matters for hit testing: small interactive items & abuelo's ear/mouth boxes MUST precede people/set boxes.
  List<Thing> _things() => [
    Thing(
      id: 'oreja_abuelo',
      si: (w) => ((w['gente'] as Map?)?['abuelo'] as Map?)?['vis'] != 0,
      box: (w) => _p.box('oreja_abuelo'),
    ),
    Thing(
      id: 'boca_abuelo',
      si: (w) => ((w['gente'] as Map?)?['abuelo'] as Map?)?['vis'] != 0,
      box: (w) => _p.box('boca_abuelo'),
    ),
    Thing(
      id: 'foto',
      si: (w) => w['foto'] is String && (w['foto'] as String).isNotEmpty,
      box: (w) => _spriteBox(w, 'cosa:foto') ?? _p.spotBox('foto'),
    ),
    Thing(
      id: 'libro',
      si: (w) => _n(w['libroVis']) == 1,
      box: (w) => _spriteBox(w, 'cosa:libro') ?? _p.spotBox('libro'),
    ),
    Thing(
      id: 'papel',
      si: (w) => _n(w['papelVis']) == 1,
      box: (w) => _spriteBox(w, 'cosa:papel') ?? _p.spotBox('papel'),
    ),
    Thing(
      id: 'telefono',
      si: (w) =>
          _n(w['telefonoVis']) == 1 &&
          (w['telefonoHolder'] ?? 'mesa') == 'mesa',
      box: (w) => _spriteBox(w, 'cosa:telefono') ?? _p.spotBox('telefono'),
    ),
    for (var i = 1; i <= 3; i++)
      Thing(
        id: 'pagina$i',
        si: (w) => _n(w['paginasVis']) == 1,
        box: (w) => _spriteBox(w, 'cosa:pagina$i') ?? _p.spotBox('pagina$i'),
      ),
    Thing(
      id: 'estrellas',
      si: (w) => _n(w['estrellasVis']) == 1,
      box: (w) => _spriteBox(w, 'cosa:estrellas') ?? _p.spotBox('estrellas'),
    ),
    for (final who in SALA_DIA_PERSONAS)
      Thing(
        id: who,
        si: (w) => ((w['gente'] as Map?)?[who] as Map?)?['vis'] != 0,
        box: (w) => _spriteBox(w, 'persona:$who'),
      ),
    Thing(id: 'computadora', box: (w) => _p.box('computadora')),
    Thing(id: 'ventana', box: (w) => _p.box('ventana')),
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

  /* ---------- frog hop & loose acts ---------- */

  Future<void> _hopToSpot(String spot) async {
    final resolved = _resolveSpot(spot);
    if (!_p.has(resolved)) return;
    final at = _p.at(resolved);
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
    q['spot'] = resolved;
  }

  final List<Future<void>> _loose = [];

  @override
  List<num> remap(List<num> xy) => xy;

  @override
  Future<void> stake(int lost, int max, String en) async {}

  @override
  Map<String, Act> get ownActs => _buildOwnActs();
}
