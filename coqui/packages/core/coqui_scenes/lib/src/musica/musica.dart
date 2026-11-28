// La música (place 10, El fuerte, scene 2: `musica`; stories 111 to 113): a NEW scene, written from its script's
// "Needs" list (historia/notas/guiones/musica.md) on its set (musica_set.dart) and its sheet (musica-sheet.json,
// read by SceneSheet). There is no old scene file: every act is this file's (and musica_acts.dart's), each doing on
// screen what the Needs list says, every place from the sheet (spots, set thing boxes, held offsets, view `wide`,
// depth rule, shadows). Where the sheet names no place or an act is unstated in the script, the code does the plainest
// thing that keeps the story playing and marks it `OPEN:`.
//
// The drawing (the sheet's `front`): standing people stand with their feet (`inkBottom`) on their spot's row and their
// middle on its column; seated people (on musician stools `taburete1..2`, on `banco1..4`, or `banqueta_abuela`) hang by
// the lap (`abuelaS` at row 36 / column 17; `mkPersona` at row `16 + 2 * t + 3`, i.e. 41 for adults and 33 for children,
// / column 24). Hanging things (`guitarra`, `tambor`, `nota1..3`) place their top middle on their spot; the microphone
// places its bottom middle on `microfono`; held things (`guitarra_rodillas`, `tambor_rodillas`, `camara`) offset from
// their holder by `things.<id>.px` with `dd = .05 - py * tan30 / S` so they draw in front of the holder at the same
// row. Every sprite pixel is hidden by any baked set pixel nearer than its upright plane plus `front.bias` (0.3).
// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/src/colmado/colmado_cast.dart' show inkBottom;
import 'package:coqui_scenes/src/musica/musica_places.dart';
import 'package:coqui_scenes/src/musica/musica_set.dart';
import 'package:coqui_scenes/src/musica/musica_sprites.dart';
import 'package:coqui_scenes/src/scene_set.dart';
import 'package:coqui_scenes/src/sheet_cache.dart';

part 'musica_acts.dart';

/// The scene "La música", made from its sheet (read first: `loadScene`).
Scene createMusica() => Musica(sceneSheetOf('musica'));

int _round(num v) => (v + 0.5).floor();

int _n(Object? v) {
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? 0;
  return 0;
}

/// Every named person key La música knows (family, musicians, and Pool 113 / dancers).
const List<String> MUSICA_NAMED_PEOPLE = [
  'musico1',
  'musico2',
  'abuela',
  'abuelo',
  'luis',
  'carmen',
  'mama',
  'papa',
  'senor',
  'senora',
  'joven',
  'mujer',
  'hombre',
];

const List<String> _DANCER_KEYS = [
  'mama',
  'papa',
  'mujer',
  'hombre',
  'senora',
  'senor',
];

const Set<String> _SEAT_SPOTS = {
  'taburete1',
  'taburete2',
  'banco1',
  'banco2',
  'banco3',
  'banco4',
  'banqueta_abuela',
};

/// One sprite of the sprite layer, placed: its picture, its top left on the 240 × 216 picture, the screen row of its
/// anchor and the depth there (front.plane), and who or what it is.
class MusicaItem {
  MusicaItem(
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

  /// Screen-space overlay drawn over the set and world sprites (flash / photo / celebration cues).
  final bool overlay;
}

class Musica extends Escena implements SetScene, SetOverSprites {
  Musica(this.ss)
    : sheet = identical(ss, _lastSs)
          ? _lastSheet!
          : (_lastSheet = ss.legacy()) {
    _p = identical(ss, _lastSs)
        ? _lastPlaces!
        : (_lastPlaces = MusicaPlaces(ss));
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
  static MusicaPlaces? _lastPlaces;

  /// The new scene's sheet (SceneSheet).
  final SceneSheet ss;

  @override
  final Sheet sheet;

  late final MusicaPlaces _p;

  /// The scene's places, from its sheet.
  MusicaPlaces get places => _p;

  @override
  String get id => 'musica';

  @override
  late final Map<String, List<num>> CAM;

  late final Map<String, List<num>> LUGAR;

  @override
  Map<String, List<num>> get lugar => LUGAR;

  @override
  late final List<Thing> cosas;

  @override
  PpEngine newEngine({bool still = false}) => musicaEngine(still: still);

  @override
  PpEngine get projection => _p.e;

  List<num> _frogAt(MusicaAt a) => [_round(a.sx) - 16, _round(a.sy) - 25, 1];

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

  Map<String, dynamic> _person(String spot, {int vis = 0}) {
    final w = _p.world(spot);
    return <String, dynamic>{
      'x': w[0],
      'y': w[1],
      'z': w[2],
      'spot': spot,
      'vis': vis,
      'pose': 'idle',
      'dx': 0,
      'dy': 0,
      'eyesShut': 0,
      'laugh': 0,
      'yawn': 0,
      'eat': 0,
      'sing': 0,
      'coverEars': 0,
      'fan': 0,
      'dance': 0,
      'rondaRole': null,
    };
  }

  @override
  Map<String, dynamic> fresh(Map<String, dynamic> story) {
    final acts = _actsOf([story['beats'], story['final']]);
    bool has(String a) => acts.any((o) => o['act'] == a);
    final is113 =
        has('ronda113') || has('foto113') || has('hojas') || has('final113');
    final is112 =
        !is113 &&
        (has('baila112') ||
            has('canta112') ||
            has('notas') ||
            has('fuera112') ||
            has('final112'));
    final storyNum = is113 ? 113 : (is112 ? 112 : 111);
    final startSpot = storyNum == 111 ? 'borde_coqui' : 'centro_coqui';
    final q = _frogAt(_p.at(startSpot));

    final gente = <String, dynamic>{
      'musico1': _person('taburete1', vis: is113 ? 1 : 0),
      'musico2': _person('taburete2', vis: is113 ? 1 : 0),
      'abuela': _person('junto_escenario', vis: 0),
      'abuelo': _person('espera2', vis: 0),
      'luis': _person('espera3', vis: 0),
      'carmen': _person('ronda4', vis: 0),
      'mama': _person('pista1', vis: 0),
      'papa': _person('pista2', vis: 0),
      'senor': _person('pista6', vis: 0),
      'senora': _person('pista5', vis: 0),
      'joven': _person('ronda5', vis: 0),
      'mujer': _person('pista3', vis: 0),
      'hombre': _person('pista4', vis: 0),
    };

    return <String, dynamic>{
      'story': storyNum,
      'hora': 'noche',
      'gente': gente,
      // Instruments (111..113): rack vs knees
      'guitarraHeldBy': is112 || is113 ? 'musico1' : null,
      'tamborHeldBy': is112 || is113 ? 'musico2' : null,
      // Microphone & paper notes (112, 113)
      'micVis': is112 || is113 ? 1 : 0,
      'micMode': 'up', // 'up' | 'low' | 'high'
      'notasVis': is112 ? 1 : 0,
      'notas': 0, // 0..3 lit
      'waitSpotOf': <String, String>{},
      // Floating notes / Sour noise
      'notasFloat': 0, // 0 = none, 1 = small, 2 = big, 3 = sour jagged
      // Story 113 props (camera, sheets, flash, photo)
      'camaraCoqui': 0,
      'hojasVis': is113 ? 1 : 0,
      'hojas': is113 ? 3 : 0,
      'flashFx': 0,
      'fotoFx': 0, // 0 = none, 1 = ok, 2 = bad
      'badFoto':
          0, // persistent rejected photo under abuela's stool until corrected
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

  MusicaAt _atOf(Map<String, dynamic> p) => _p.atWorld(
    (p['x'] as num).toDouble(),
    (p['y'] as num).toDouble(),
    (p['z'] as num).toDouble(),
  );

  MusicaAt _frogPoint(Map<String, dynamic> q) {
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

  static bool _isSeat(String? spot) =>
      spot != null && _SEAT_SPOTS.contains(spot);

  /// Every sprite to draw over the set, except the frog (who is added in [placed]).
  List<MusicaItem> items(Map<String, dynamic> w, int a) {
    final out = <MusicaItem>[];
    final talk = _talker();
    final anim = (a / 3).floor();
    final storyNum = _n(w['story']);
    final gente = (w['gente'] as Map<String, dynamic>?) ?? const {};

    // 1. People
    for (final id in MUSICA_NAMED_PEOPLE) {
      final p = gente[id] as Map<String, dynamic>?;
      if (p == null || !jsTruthy(p['vis'])) continue;
      final spot = p['spot'] as String?;
      final sent = _isSeat(spot);
      final at = _atOf(p);
      final sx = _round(at.sx) + _n(p['dx']);
      final sy = _round(at.sy) + _n(p['dy']);
      final pose = (p['pose'] as String?) ?? 'idle';
      final sing = _n(p['sing']) == 1 || p['rondaRole'] == 'canta';
      final open = sing || (talk == id && a % 2 != 0);
      final eyesShut = _n(p['eyesShut']) == 1;
      final laugh = _n(p['laugh']) == 1;
      final yawn = _n(p['yawn']) == 1;
      final eat = _n(p['eat']) == 1;
      final coverEars = _n(p['coverEars']) == 1;
      final fan = _n(p['fan']) == 1;
      final dance = _n(p['dance']) == 1 || p['rondaRole'] == 'baila';
      final danceStep = dance ? (anim % 2) : 0;
      final effectivePose = dance ? (danceStep == 0 ? 'wave0' : 'wave1') : pose;
      final danceDy = dance ? (danceStep == 0 ? 0 : -2) : 0;
      final drawSy = sy + danceDy;

      final key =
          'ms_p_${id}_${effectivePose}_${open}_${sent}_${eyesShut}_${laugh}_${yawn}_${eat}_${coverEars}_${fan}_${dance}_$danceStep';
      final s = _spr(
        key,
        () => mkMusicaPersona(
          id,
          effectivePose,
          open: open,
          sent: sent,
          eyesShut: eyesShut,
          laugh: laugh,
          yawn: yawn,
          eat: eat,
          coverEars: coverEars,
          fan: fan,
          dance: dance,
          danceStep: danceStep,
        ),
      );
      final whoDef = MUSICA_PEOPLE[id];
      final ax = id == 'abuela' ? (sent ? 17 : 30) : PX;
      final ay = sent
          ? (id == 'abuela' ? 36 : (whoDef?.nino == true ? 33 : 41))
          : inkBottom(s);
      out.add(
        MusicaItem(s, sx - ax, drawSy - ay, drawSy, at.d, tag: 'persona:$id'),
      );

      // Story 113: Abuela seated on `banqueta_abuela` holds her album & shows spare sheets in her pocket.
      if (id == 'abuela' && sent && storyNum == 113) {
        final al = _spr('ms_album', mkAlbumMusica);
        out.add(
          MusicaItem(al, sx - 7, sy - 8, sy + 3, at.d + .04, tag: 'fx:album'),
        );
        final hCount = _n(w['hojas']);
        if (hCount > 0) {
          final hs = _spr('ms_hojas_$hCount', () => mkHojasMusica(hCount));
          out.add(
            MusicaItem(hs, sx + 4, sy - 12, sy, at.d + .03, tag: 'fx:hojas'),
          );
        }
      }
    }

    // 2. Guitar & Drum (on rack vs held across knees)
    // In stories 112/113 the musicians hold the instruments subtly in gameplay (`is112`/`is113`),
    // while in story 111 they hang on the rack unless explicitly held via `toca111` / `cambian111`.
    final gHolder = w['guitarraHeldBy'] as String?;
    final tHolder = w['tamborHeldBy'] as String?;
    if (storyNum == 111 && gHolder == null) {
      final at = _p.at('guitarra_atril');
      final sx = _round(at.sx), sy = _round(at.sy);
      final g = _spr('ms_guitarra', mkGuitarra);
      out.add(MusicaItem(g, sx - 6, sy, sy, at.d, tag: 'cosa:guitarra'));
    } else if (gHolder != null && gente[gHolder] is Map) {
      final hp = gente[gHolder] as Map<String, dynamic>;
      if (hp['vis'] != 0) {
        final at = _atOf(hp);
        final pxOff = _p.thingPx('guitarra_rodillas');
        final sx = _round(at.sx) + pxOff[0];
        final sy = _round(at.sy) + pxOff[1];
        final dd = .05 - pxOff[1] * _t30 / _p.e.S;
        final gh = _spr('ms_guitarra_h', mkGuitarraH);
        out.add(
          MusicaItem(
            gh,
            sx - 11,
            sy - gh.h,
            sy,
            at.d + dd,
            tag: 'held:guitarra',
          ),
        );
      }
    }

    if (storyNum == 111 && tHolder == null) {
      final at = _p.at('tambor_atril');
      final sx = _round(at.sx), sy = _round(at.sy);
      final t = _spr('ms_tambor', mkTambor);
      out.add(MusicaItem(t, sx - 6, sy, sy, at.d, tag: 'cosa:tambor'));
    } else if (tHolder != null && gente[tHolder] is Map) {
      final hp = gente[tHolder] as Map<String, dynamic>;
      if (hp['vis'] != 0) {
        final at = _atOf(hp);
        final pxOff = _p.thingPx('guitarra_rodillas');
        final sx = _round(at.sx) + pxOff[0];
        final sy = _round(at.sy) + pxOff[1] + 2;
        final dd = .05 - (pxOff[1] + 2) * _t30 / _p.e.S;
        final th = _spr('ms_tambor_h', mkTamborH);
        out.add(
          MusicaItem(th, sx - 6, sy - th.h, sy, at.d + dd, tag: 'held:tambor'),
        );
      }
    }

    // 3. Microphone (stories 112 & 113)
    if (_n(w['micVis']) == 1) {
      final mode = (w['micMode'] as String?) ?? 'up';
      final at = _p.at('microfono');
      final sx = _round(at.sx), sy = _round(at.sy);
      final mc = _spr('ms_mic_$mode', () => mkMicrofono(mode));
      out.add(
        MusicaItem(mc, sx - 3, sy - mc.h, sy, at.d, tag: 'cosa:microfono'),
      );
    }

    // 4. Hanging paper notes over stage (story 112)
    if (_n(w['notasVis']) == 1) {
      final litCount = _n(w['notas']).clamp(0, 3);
      for (var i = 1; i <= 3; i++) {
        final lit = i <= litCount;
        final spot = 'nota$i';
        final at = _p.at(spot);
        final sx = _round(at.sx), sy = _round(at.sy);
        final ns = _spr('ms_nota_$lit', () => mkNotaPapel(lit: lit));
        out.add(MusicaItem(ns, sx - 7, sy, sy, at.d, tag: 'nota:$spot'));
      }
    }

    // 5. Floating music notes / sour noise
    final nf = _n(w['notasFloat']);
    if (nf > 0) {
      final at = _p.at('guitarra_atril');
      final spr = _spr(
        'ms_nfloat_${nf}_${anim % 2}',
        () => mkNotasFloat(kind: nf - 1, anim: anim),
      );
      out.add(
        MusicaItem(
          spr,
          _round(at.sx) - 24,
          _round(at.sy) - 22,
          at.sy,
          4.0,
          tag: 'fx:notas',
          overlay: true,
        ),
      );
    }

    // 6. Camera flash / photo (overlay)
    if (_n(w['flashFx']) == 1) {
      final q = w['cq'] as Map<String, dynamic>?;
      final fp = q != null ? _frogPoint(q) : _p.at('centro_coqui');
      final fl = _spr('ms_flash', mkFlashMusica);
      out.add(
        MusicaItem(
          fl,
          _round(fp.sx) - 8,
          _round(fp.sy) - 22,
          fp.sy,
          6.0,
          tag: 'fx:flash',
          overlay: true,
        ),
      );
    }
    final pf = _n(w['fotoFx']);
    if (pf > 0) {
      final ab = gente['abuela'] as Map<String, dynamic>?;
      final at = ab != null && ab['vis'] != 0
          ? _atOf(ab)
          : _p.at('banqueta_abuela');
      final ph = _spr('ms_foto_$pf', () => mkFotoPapel(bad: pf == 2));
      out.add(
        MusicaItem(
          ph,
          (_round(at.sx) - 12).clamp(24, 206),
          (_round(at.sy) - 14).clamp(4, 200),
          at.sy,
          6.0,
          tag: 'fx:foto',
          overlay: true,
        ),
      );
    } else if (_n(w['badFoto']) == 1) {
      final ab = gente['abuela'] as Map<String, dynamic>?;
      final at = ab != null && ab['vis'] != 0
          ? _atOf(ab)
          : _p.at('banqueta_abuela');
      final ph = _spr('ms_foto_2', () => mkFotoPapel(bad: true));
      out.add(
        MusicaItem(
          ph,
          (_round(at.sx) - 5).clamp(24, 206),
          (_round(at.sy) + 2).clamp(4, 200),
          at.sy + 4,
          6.0,
          tag: 'fx:bad_foto',
          overlay: true,
        ),
      );
    }

    // 7. Celebration cues
    if (_n(w['corazonFx']) == 1) {
      final q = w['cq'] as Map<String, dynamic>?;
      final fp = q != null ? _frogPoint(q) : _p.at('centro_coqui');
      final cor = _spr('ms_corazon', mkCorazonMusica);
      out.add(
        MusicaItem(
          cor,
          (_round(fp.sx) + 12).clamp(24, 206),
          (_round(fp.sy) - 24).clamp(4, 200),
          fp.sy,
          6.0,
          tag: 'fx:corazon',
          overlay: true,
        ),
      );
    }
    if (_n(w['estrellaFx']) == 1) {
      final q = w['cq'] as Map<String, dynamic>?;
      final fp = q != null ? _frogPoint(q) : _p.at('centro_coqui');
      final st = _spr('ms_estrella', mkEstrellaMusica);
      out.add(
        MusicaItem(
          st,
          (_round(fp.sx) - 18).clamp(24, 208),
          (_round(fp.sy) - 24).clamp(4, 200),
          fp.sy,
          6.0,
          tag: 'fx:estrella',
          overlay: true,
        ),
      );
    }

    return out;
  }

  static final Map<String, Sprite> _frogSprites = {};

  /// [items] plus the frog (as the host draws him) and held camera, for `draw` and for `MusicaRules`.
  List<MusicaItem> placed(Map<String, dynamic> w, int a) {
    final out = items(w, a);
    final q = w['cq'] as Map<String, dynamic>?;
    if (q != null && jsTruthy(q['vis'])) {
      final b = host.frogBox(q);
      final at = _frogPoint(q);
      final dx = _n(q['dx']);
      final fsy = _round(at.sy);
      final fsx = _round(at.sx) + dx;
      final ox = b.x.toInt() - 16 + dx;
      final oy = b.y.toInt() - 24;
      final blink = host.F % 47 < 2 ? 1 : 0;
      final mouth = ((q['bub'] == 'hola' || _talker() == 'coqui') && a % 2 != 0)
          ? 1
          : 0;
      final fk =
          '${q['s']}_${b.x - (b.x.toInt() - 16)}_${b.y - oy}_${(q['y'] as num) - oy}_${((q['dy'] as num) + 0.5).floor()}_${blink}_$mouth';
      final spr = _frogSprites.putIfAbsent(fk, () {
        final px = Uint32List(64 * 64);
        final g = Ctx(px, 64, 64)
          ..translate(-(b.x.toInt() - 16).toDouble(), -oy.toDouble());
        host.frog(g, q, a);
        return Sprite(64, 64, px);
      });
      out.add(MusicaItem(spr, ox, oy, fsy, at.d, tag: 'coqui'));

      if (_n(w['camaraCoqui']) == 1) {
        final pxOff = _p.thingPx('camara');
        final cx = fsx + pxOff[0];
        final cy = fsy + _round(q['dy'] as num? ?? 0) + pxOff[1];
        final dd = .05 - pxOff[1] * _t30 / _p.e.S;
        final camSpr = _spr('ms_camara', mkCamara);
        out.add(
          MusicaItem(
            camSpr,
            cx - 5,
            cy - camSpr.h,
            cy,
            at.d + dd,
            tag: 'cosa:camara',
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
    _setZ = baked.zb;
  }

  static final double _t30 = math.tan(math.pi / 6);

  void _put(
    MusicaItem it,
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
      final r = _p.radius(en.key) ?? 0.35;
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
    if (p == null) return null;
    if (p['vis'] == 0) {
      final at = _p.at('espera2');
      return [_round(at.sx), _round(at.sy) - 52];
    }
    final at = _atOf(p);
    return [
      _round(at.sx),
      _round(at.sy) - (_isSeat(p['spot'] as String?) ? 42 : 52),
    ];
  }

  /* ---------- touch things & hit testing ---------- */

  static List<int>? _itemBox(
    List<MusicaItem> list,
    bool Function(MusicaItem) test,
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

  List<num>? _placedBox(Map<String, dynamic> w, String tag) =>
      _itemBox(placed(w, 0), (it) => it.tag == tag);

  List<Thing> _things() => [
    // 1. Instruments, mic & camera (foreground props take hit priority over stage / floor / holder)
    Thing(
      id: 'guitarra',
      m: 1,
      si: (w) => _n(w['story']) == 111 && w['guitarraHeldBy'] == null,
      box: (w) => _spriteBox(w, 'cosa:guitarra') ?? _p.box('guitarra'),
    ),
    Thing(
      id: 'tambor',
      m: 1,
      si: (w) => _n(w['story']) == 111 && w['tamborHeldBy'] == null,
      box: (w) => _spriteBox(w, 'cosa:tambor') ?? _p.box('tambor'),
    ),
    Thing(
      id: 'microfono',
      m: 1,
      si: (w) => _n(w['micVis']) == 1,
      box: (w) => _spriteBox(w, 'cosa:microfono') ?? _p.box('microfono'),
    ),
    Thing(
      id: 'camara',
      m: 1,
      si: (w) => _n(w['camaraCoqui']) == 1,
      box: (w) => _placedBox(w, 'cosa:camara') ?? _p.box('camara'),
    ),
    // 2. Coquí
    Thing(
      id: 'coqui',
      si: (w) => jsTruthy((w['cq'] as Map?)?['vis']),
      box: (Map<String, dynamic> w) {
        final b = host.frogBox(w['cq'] as Map<String, dynamic>);
        return [b.x, b.y, b.w, b.h];
      },
    ),
    // 3. People (named family, musicians, and Pool 113 guests)
    for (final who in MUSICA_NAMED_PEOPLE)
      Thing(
        id: who,
        si: (w) => ((w['gente'] as Map?)?[who] as Map?)?['vis'] != 0,
        box: (w) => _spriteBox(w, 'persona:$who'),
      ),
    // 4. Set areas (`escenario`, `banco`, `pista`)
    Thing(id: 'escenario', box: (w) => _p.box('escenario')),
    Thing(id: 'banco', box: (w) => _p.box('banco')),
    Thing(id: 'pista', box: (w) => _p.box('pista')),
  ];

  @override
  String setKey(Map<String, dynamic> W) =>
      MusicaState(hora: (W['hora'] as String?) ?? 'noche').key;

  @override
  void buildSet(PpEngine e, PpBuild b, Map<String, dynamic> W) =>
      buildSetFor(e, b, setKey(W));

  final Map<PpEngine, MusicaSet> _sets = {};

  @override
  void buildSetFor(PpEngine e, PpBuild b, String key) =>
      (_sets[e] ??= MusicaSet(e, b)).buildSet(MusicaState.fromKey(key));

  @override
  bool get frogShadow => false;

  @override
  List<num> remap(List<num> xy) => xy;

  @override
  Future<void> stake(int lost, int max, String en) async {}

  final List<Future<void>> _loose = [];

  @override
  Map<String, Act> get ownActs => _buildOwnActs();
}
