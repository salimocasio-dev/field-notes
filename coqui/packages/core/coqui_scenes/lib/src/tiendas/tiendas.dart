// Las tiendas (place 5, La calle, scene 3; stories 54 to 56): a NEW scene, written from its script's "Needs" list
// (historia/notas/guiones/tiendas.md) on its set (tiendas_set.dart) and its sheet (tiendas-sheet.json, read by
// SceneSheet). There is no old scene file: every act is this file's, each doing on screen what the Needs list says, every
// place from the sheet (a spot's world point, a group, a thing's box, the view, the depth rule). Where the sheet names no
// place, or the script does not settle what an act shows, the act does the plainest thing that keeps the story playing
// and says so in a comment starting `OPEN:` (page 13 lists them for the content lane).
//
// Two pictures: the row of shops (`fila` tiendas, stories 54 and 56) and story 55's two buildings (`fila` altos, the
// sheet's part `altos`, with its own origin and view). A world point is projected by the engine of its picture.
//
// The drawing (the sheet's `front`): every person and small thing stands with its feet's bottom edge on its spot's row
// and its middle on its column (rules.anchor); its pixel is hidden by every set pixel nearer the camera than the upright
// plane through its feet plus `front.bias` (front.plane); between two sprites the nearer pixel wins, but the frog is
// never behind a grown-up (the sheet's rule: a grown-up's pixels never hide his). A door that opens and a door that
// rattles are drawn over the set's own door (the set's doors are all baked shut): the open one from La calle's kit
// (calle-base.js doorX, open), on a picture of its own, kept where it shows through the doorway or stands in front of
// the wall; the rattling one is the set's own door, its pixels moved one column to and fro.
// ignore_for_file: non_constant_identifier_names

import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/src/calle/calle_base.dart';
import 'package:coqui_scenes/src/calle/calle_cast.dart';
import 'package:coqui_scenes/src/colmado/colmado_cast.dart';
import 'package:coqui_scenes/src/scene_set.dart';
import 'package:coqui_scenes/src/set_kit.dart';
import 'package:coqui_scenes/src/sheet_cache.dart';
import 'package:coqui_scenes/src/tiendas/tiendas_places.dart';
import 'package:coqui_scenes/src/tiendas/tiendas_set.dart';
import 'package:coqui_scenes/src/tiendas/tiendas_sprites.dart';

/// The scene "Las tiendas", made from its sheet (read first: `loadScene`).
Scene createTiendas() => Tiendas(sceneSheetOf('tiendas'));

int _round(num v) => (v + 0.5).floor();

int _n(Object? v) =>
    v is num ? v.toInt() : (v is String ? int.tryParse(v) ?? 0 : 0);

/// One sprite of the sprite layer, placed: its picture, its top left on the 240 x 216 picture, the screen row of its
/// feet and the depth there (front.plane). A [flat] one (a door drawn over the set's own) has a depth per pixel ([pd]).
class TiendasItem {
  TiendasItem(
    this.s,
    this.left,
    this.top,
    this.sy,
    this.d, {
    this.tag,
    this.grown = false,
    this.pd,
  });

  /// A grown-up (whose pixels never hide the frog).
  final bool grown;

  final Sprite s;
  final int left, top;
  final num sy;
  final double d;

  /// The depth of each pixel (a piece of the set drawn again: a door), or null: the upright plane through the feet.
  final Float32List? pd;

  bool get flat => pd != null;

  /// Who or what it is (the rules' tests read it: `persona:<id>`, `coqui`, `cochecito`, `cosa:<id>`, `puerta:<k>`).
  final String? tag;
}

/// The people of the place (the speaker keys and `quien` of the three stories), and the painter.
const List<String> _people = [
  'abuela',
  'mama',
  'papa',
  'luis',
  'senora',
  'senor',
  'pintor',
];

/// The four fronts of the row (tiendas-set.html E.FRONTS).
const List<String> _fronts = ['tienda', 'banco', 'farmacia', 'correo'];

class Tiendas extends Escena implements SetScene, SetOverSprites {
  Tiendas(this.ss) : sheet = ss.legacy() {
    _p = TiendasPlaces(ss);
    for (final f in const ['tiendas', 'altos']) {
      for (final e in _p.of(f).spots.entries) {
        if (e.value.kind == 'frog') _frogFila[e.key] = f;
      }
    }
    LUGAR = {
      for (final e in _frogFila.entries) e.key: _frogAt(_p.at(e.key, e.value)),
    };
    cosas = _things();
  }

  /// The new scene's sheet (SceneSheet).
  final SceneSheet ss;

  /// The old Sheet the shared code reads (`SceneSheet.legacy`: the scene, scale, origin; the start frog the runner's).
  @override
  final Sheet sheet;

  late final TiendasPlaces _p;

  /// The scene's places, from its sheet.
  TiendasPlaces get places => _p;

  @override
  String get id => 'tiendas';

  // the story's picture, read from its first `set` (story 55: fila altos); no story yet: the row
  String _storyFila() {
    try {
      final S = host.S;
      for (final b in (S['beats'] as List? ?? const [])) {
        if (b is Map &&
            b['set'] is Map &&
            (b['set'] as Map)['fila'] is String) {
          return (b['set'] as Map)['fila'] == 'altos' ? 'altos' : 'tiendas';
        }
      }
    } catch (_) {
      // no host yet
    }
    return 'tiendas';
  }

  /// The views: `tiendas` (views.tiendas) and `altos` (altos.views.altos); `wide`, the runner's first, is the view of
  /// the story's own picture.
  @override
  Map<String, List<num>> get CAM => {
    'wide': _p.view(_storyFila()),
    'tiendas': _p.view('tiendas'),
    'altos': _p.view('altos'),
  };

  late final Map<String, List<num>> LUGAR;

  // the frog's spots (the sheet's spots of kind frog) and the picture each is in
  final Map<String, String> _frogFila = {};

  @override
  Map<String, List<num>> get lugar => LUGAR;

  @override
  late final List<Thing> cosas;

  @override
  PpEngine newEngine({bool still = false}) => tiendasEngine(still: still);

  @override
  PpEngine get projection => _p.e;

  // where the frog's `ir` goes, by the stories' names: the sheet's spots of kind frog
  static const Map<String, String> _frogPlaces = {
    // story 54's ending: the group at the horse, the frog on its back (groups.grupo_caballito)
    'caballito': 'caballito',
    // story 55's ending: the frog sitting on the kerb (groups.bordillo), then beside the bicycle (groups.bici)
    'bordillo': 'bordillo2',
    'bici': 'coqui.bici',
    // story 56's ending: "the frog comes back with the umbrella" to abuela on the seat: the frog's place of story 56
    // (spots.coqui.56: "story 56: the frog on the pavement (also in the ending, nube 2)")
    'banco_acera': 'coqui.56',
  };

  /// The sheet's spot of the frog's place [key] (`lugar`'s key), or null.
  String? frogSpotOf(String key) =>
      _frogPlaces[key] ?? (LUGAR.containsKey(key) ? key : null);

  // the frog's top left for a spot (rules.anchor: mkCoqui's column 16 on sx, its row 25 on sy)
  List<num> _frogAt(TiendasAt a) => [_round(a.sx) - 16, _round(a.sy) - 25, 1];

  Map<String, dynamic> get W => host.W;
  int get F => host.F;
  int get TICK => host.TICK;
  Future<void> wait(num ms) => host.wait(ms);
  Future<void> _tick() => wait(TICK);

  /* ---------- the state ---------- */

  /// The picture of [w]: `tiendas` or `altos`.
  static String filaOf(Map<String, dynamic> w) =>
      w['fila'] == 'altos' ? 'altos' : 'tiendas';

  String get _fila => filaOf(W);

  // what the story does, read once from its file at the start: the acts it calls
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

  Map<String, dynamic> _person(String spot, String fila, {int vis = 1}) {
    final w = _p.world(spot, fila);
    return <String, dynamic>{
      'x': w[0],
      'y': w[1],
      'z': w[2],
      'spot': spot,
      'vis': vis,
      'dir': 1,
      'pose': 'idle',
      'dy': 0,
      'lleva': null,
      'sent': 0,
    };
  }

  @override
  Map<String, dynamic> fresh(Map<String, dynamic> story) {
    final acts = _actsOf([story['beats'], story['final']]);
    bool has(String a) => acts.any((o) => o['act'] == a);
    final gente = <String, dynamic>{};
    Map<String, dynamic>? coche;
    Map<String, dynamic>? bici;
    String frog;
    String fila = 'tiendas';
    if (has('va54')) {
      // story 54: abuela with a letter in her hand, the stroller with the bebé and the frog on the near pavement
      // (groups.inicio; tiendas-preview.html moment 1)
      gente['abuela'] = _person('abuela.acera', fila)..['lleva'] = 'letter';
      final w = _p.world('cochecito');
      coche = <String, dynamic>{
        'x': w[0],
        'y': w[1],
        'z': w[2],
        'spot': 'cochecito',
        'vis': 1,
        'est': 'idle',
        'toma': null,
        'vacio': 0,
      };
      frog = 'coqui.acera';
    } else if (has('entra55')) {
      // story 55: Luis with his bicycle, the lunch tins in its basket, the frog beside him (groups.bici; moment 6)
      fila = 'altos';
      gente['luis'] = _person('bici', fila);
      final w = _p.world('bici', fila);
      bici = <String, dynamic>{
        'x': w[0],
        'y': w[1],
        'vis': 1,
        'monta': 0,
        'dir': 1,
      };
      frog = 'coqui.bici';
    } else {
      // story 56: abuela and the frog on the near pavement, her bread in its open bag (the sheet's places of story 56:
      // abuela standing at abuela.lluvia, the frog at coqui.56)
      gente['abuela'] = _person('abuela.lluvia', fila)..['lleva'] = 'bread';
      frog = 'coqui.56';
    }
    final q = _frogAt(_p.at(frog, fila));
    return {
      'fila': fila,
      'par': 'a',
      'lado': 'izq',
      'hora': 'manana',
      'nube': 0,
      // story 56: a front's thing is its door (tiendas.md Needs: "each front; its door in story 56")
      'portal': has('puerta56') ? 1 : 0,
      'gente': gente,
      'coche': coche,
      'bici': bici,
      'bebeH': null,
      'tins': 3,
      'vapor': 3,
      'cosas': <dynamic>[],
      'puertas': <String, dynamic>{},
      'mano': null,
      'ventana': null,
      'lluvia': 0,
      'nubeSpr': has('nube') ? 1 : 0,
      'lista': null,
      'monedas': null,
      'tarjeta': null,
      'marcas': null,
      'cq': <String, dynamic>{
        'x': q[0],
        'y': q[1],
        's': 1,
        'dy': 0,
        'al': 1,
        'vis': 1,
        'bub': null,
        'lleva': null,
      },
    };
  }

  /* ---------- the set ---------- */

  // story 55 writes `lado` left or right and `hora` mediodia: the sheet's lado izq (the tall one on the left) or der; an
  // hour the set does not draw takes the page's default (tiendas-set.html pick: manana)
  static String _lado(Object? v) => v == 'right' || v == 'der' ? 'der' : 'izq';

  // the sheet's setKey: tiendas "hora + nube", e.g. "manana-0"; altos "par + lado + hora", e.g. "a-izq-manana"
  @override
  String setKey(Map<String, dynamic> W) {
    final hora = W['hora'] == 'tarde' ? 'tarde' : 'manana';
    if (filaOf(W) == 'altos') {
      final par = W['par'] == 'b' ? 'b' : 'a';
      return '$par-${_lado(W['lado'])}-$hora';
    }
    final nube = _n(W['nube']).clamp(0, 2);
    return '$hora-$nube';
  }

  @override
  void buildSet(PpEngine e, PpBuild b, Map<String, dynamic> W) =>
      buildSetFor(e, b, setKey(W));

  final Map<PpEngine, TiendasSet> _sets = {};

  @override
  void buildSetFor(PpEngine e, PpBuild b, String key) =>
      (_sets[e] ??= TiendasSet(e, b)).buildSet(TiendasState.fromKey(key));

  // the frog casts his shadow in the engine (shadows.byCharacter.coqui); never the old one
  @override
  bool get frogShadow => false;

  /* ---------- where everybody is ---------- */

  Map<String, dynamic> get _gente => W['gente'] as Map<String, dynamic>;
  List<Map<String, dynamic>> get _items =>
      (W['cosas'] as List).cast<Map<String, dynamic>>();

  Map<String, dynamic> _g(String id) =>
      (_gente[id] ??= <String, dynamic>{
            'x': 0.0,
            'y': 0.0,
            'z': 0.0,
            'spot': null,
            'vis': 0,
            'dir': 1,
            'pose': 'idle',
            'dy': 0,
            'lleva': null,
            'sent': 0,
          })
          as Map<String, dynamic>;

  bool _seen(String id) {
    final p = _gente[id] as Map<String, dynamic>?;
    return p != null && p['vis'] != 0;
  }

  TiendasAt _atOf(Map<String, dynamic> o, String fila) =>
      _p.atWorld(o['x'] as num, o['y'] as num, (o['z'] as num?) ?? 0, fila);

  // the frog's world point under his feet
  TiendasAt _frogPoint(Map<String, dynamic> w, Map<String, dynamic> q) {
    final b = host.frogBox(q);
    final fila = filaOf(w);
    final spot = _frogSpotAt(q, w);
    if (spot != null) return _p.at(spot, fila);
    return _p.fromScreen(b.x + b.w / 2, (q['y'] as num) + 25, 0, fila);
  }

  // the frog's spot when he stands on one of his picture's (the horse's back is at z .72: its screen point is not the
  // ground's)
  String? _frogSpotAt(Map<String, dynamic> q, [Map<String, dynamic>? w]) {
    final fila = filaOf(w ?? W);
    for (final e in LUGAR.entries) {
      if (_frogFila[e.key] != fila) continue;
      if (e.value[0] == q['x'] && e.value[1] == q['y']) return e.key;
    }
    return null;
  }

  /// The sheet's spot the frog stands on in [w], or null (on his way).
  String? frogSpot(Map<String, dynamic> w) =>
      _frogSpotAt(w['cq'] as Map<String, dynamic>, w);

  /* ---------- sprites ---------- */

  static final Map<String, Sprite> _sprites = {};
  static Sprite _spr(String key, Sprite Function() make) =>
      _sprites[key] ??= make();

  static final Map<String, Sprite> _mirrored = {};
  static Sprite _mirrorOf(String key, Sprite s) =>
      _mirrored[key] ??= mirrorSprite(s);

  // a person's sprite and the point of it that stands on the spot (rules.anchor), and which hand pose holds a thing
  ({Sprite s, int ax, int ay, String key, String hand, bool abuela, bool nino})
  _personSprite(String id, Map<String, dynamic> p, bool open) {
    final pose = (p['pose'] as String?) ?? 'idle';
    final sent = _n(p['sent']) == 1;
    final key = 'p$id$pose$open$sent${id == 'mama' ? W['fila'] : ''}';
    if (sent) {
      if (id == 'abuela') {
        // abuela sitting (mkAbuelaS): her middle at column 17 and her lap at row 36 on the seat's spot (rules.anchor)
        final s = _spr(key, () => mkAbuelaS('idle', open, false));
        return (
          s: s,
          ax: 17,
          ay: 36,
          key: key,
          hand: 'sent',
          abuela: true,
          nino: false,
        );
      }
      // Luis sitting on the kerb (mkPersona, sent = 1: feet on sy)
      final s = _spr(
        key,
        () => mkPersona(
          FAM['hermano']!,
          pose == 'taza' ? 'taza' : 'idle',
          open,
          true,
        ),
      );
      return (
        s: s,
        ax: PX,
        ay: inkBottom(s),
        key: key,
        hand: pose,
        abuela: false,
        nino: true,
      );
    }
    final persona = switch (pose) {
      'saluda0' => 'wave0',
      'saluda1' => 'wave1',
      'mano' => 'offer',
      _ => pose,
    };
    Sprite s;
    if (id == 'mama' && W['fila'] == 'altos') {
      s = _spr(key, () => mkPersona(MAMA_ENFERMERA, persona, open, false));
    } else if (id == 'pintor') {
      s = _spr(key, () => mkPintor(pose, open: open));
    } else if (id == 'mama' || id == 'papa' || id == 'luis') {
      s = _spr(key, () => mkPersona(calleWho(id), persona, open, false));
    } else {
      s = callePerson(id, pose == 'taza' ? 'taza' : pose, open: open).s;
    }
    final ax = id == 'abuela' ? 30 : PX;
    return (
      s: s,
      ax: ax,
      ay: inkBottom(s),
      key: key,
      hand: persona,
      abuela: id == 'abuela',
      nino: id == 'luis',
    );
  }

  // what a person holds: its sprite, by the word kept in `lleva`
  static Sprite? _heldSprite(String? k) => k == null
      ? null
      : _spr('lleva$k', () => mkTrae(k) ?? Sprite(1, 1, Uint32List(1)));

  // the stroller's sprite
  static Sprite _cocheSprite(Map<String, dynamic> c, int f) {
    final est = (c['est'] as String?) ?? 'idle', toma = c['toma'] as String?;
    final vacio = _n(c['vacio']) == 1, ff = est == 'clap' && (f >> 2) % 2 == 1;
    return _spr(
      'coche$est$toma$vacio$ff',
      () => mkCochecito(est: est, toma: toma, vacio: vacio, f: ff),
    );
  }

  // where a held thing is drawn beside the frog: at his hand (in front of him)
  ({num x, num y, double d, num sy})? _frogHand(Map<String, dynamic> w) {
    final q = w['cq'] as Map<String, dynamic>;
    if (!jsTruthy(q['vis'])) return null;
    final b = host.frogBox(q), at = _frogPoint(w, q);
    return (
      x: b.x + b.w - 4,
      y: (q['y'] as num) + 14,
      d: at.d + .05,
      sy: at.sy,
    );
  }

  /// Every sprite of the frame [w] but the frog, placed: the doors drawn over the set's, the people, the stroller, the
  /// bicycle, the small things. The rules' tests read it; [draw] draws it.
  List<TiendasItem> items(Map<String, dynamic> w, int a) {
    final out = <TiendasItem>[];
    final fila = filaOf(w);
    final talk = _talker();
    out.addAll(_doorItems(w, a));
    // Luis's bicycle standing (story 55), behind him: its handlebar 8 px right of the spot `bici` (rules.anchor: "the
    // preview draws it 8 px right of bici, behind Luis"), its wheels on the spot's row
    final bici = w['bici'] as Map<String, dynamic>?;
    if (bici != null && bici['vis'] != 0) {
      final at = _p.atWorld(bici['x'] as num, bici['y'] as num, 0, fila);
      final monta = _n(bici['monta']) == 1;
      final op = talk == 'luis' && a % 2 == 1;
      final left = _n(bici['dir']) < 0;
      var s = monta
          ? _spr(
              'ciclista$op',
              () => mkCiclista(FAM['hermano']!, cesta: true, open: op),
            )
          : _spr('bici', () => mkBici(cesta: true));
      if (monta && left) s = _mirrorOf('ciclista$op', s);
      final sx = _round(at.sx) + (monta ? 0 : 8), sy = _round(at.sy);
      // mkBici: the handlebar at column 21; mkCiclista: the saddle under column PX
      final ax = monta ? PX : 21;
      out.add(
        TiendasItem(
          s,
          sx - ax,
          sy - inkBottom(s),
          sy,
          at.d - (monta ? 0 : .02),
          tag: monta ? 'bici:monta' : 'bici',
        ),
      );
      // the lunch tins in its basket (mkBici's basket: columns 24 to 30, its top at row 1)
      final n = _n(w['tins']);
      if (n > 0) {
        final t = _spr(
          'tins$n${w['vapor']}',
          () => mkFiambreras(n, _n(w['vapor'])),
        );
        final bx = monta ? sx - PX + (PX - 14) + 27 : sx - ax + 27;
        final by = monta
            ? sy - inkBottom(s) + (s.h - 19) + 2
            : sy - inkBottom(s) + 2;
        out.add(
          TiendasItem(
            t,
            bx - t.w ~/ 2,
            by - t.h,
            sy,
            at.d - .01,
            tag: 'comida',
          ),
        );
      }
    }
    final gente = (w['gente'] as Map<String, dynamic>?) ?? const {};
    for (final en in gente.entries) {
      final p = en.value as Map<String, dynamic>;
      if (p['vis'] == 0) continue;
      final open = talk == en.key && a % 2 == 1;
      final sp = _personSprite(en.key, p, open);
      final at = _atOf(p, fila);
      final dir = _n(p['dir']) < 0 ? -1 : 1;
      final s = dir < 0 ? _mirrorOf(sp.key, sp.s) : sp.s;
      final ax = dir < 0 ? sp.s.w - 1 - sp.ax : sp.ax;
      final sx = _round(at.sx), sy = _round(at.sy) + _n(p['dy']);
      final grown = en.key != 'luis';
      out.add(
        TiendasItem(
          s,
          sx - ax,
          sy - sp.ay,
          sy,
          at.d,
          tag: 'persona:${en.key}',
          grown: grown,
        ),
      );
      // what is in the person's hand
      final held = _heldSprite(p['lleva'] as String?);
      if (held != null) {
        final hand = sp.hand == 'sent' ? 'idle' : sp.hand;
        var (hx, hy) = handOf(
          held,
          hand,
          sp.abuela,
          nino: sp.nino,
          up: heldUp(p['lleva'] as String?),
        );
        if (sp.hand == 'sent') {
          // abuela sitting: on her lap, at its middle (mkAbuelaS: the lap round (X + 9, 36))
          hx = 17 + 9 - held.w ~/ 2;
          hy = 36 - held.h + 1;
        }
        if (dir < 0) hx = sp.s.w - hx - held.w;
        out.add(
          TiendasItem(
            held,
            sx - ax + hx,
            sy - sp.ay + hy,
            sy,
            at.d + .05,
            tag: 'lleva:${en.key}',
          ),
        );
      }
    }
    // the stroller with the bebé (story 54)
    final c = w['coche'] as Map<String, dynamic>?;
    if (c != null && c['vis'] != 0) {
      final s = _cocheSprite(c, a);
      final at = _atOf(c, fila);
      final est = (c['est'] as String?) ?? 'idle';
      final sx = _round(at.sx), sy = _round(at.sy);
      out.add(
        TiendasItem(
          s,
          sx - cochecitoX(est),
          sy - inkBottom(s),
          sy,
          at.d,
          tag: 'cochecito',
        ),
      );
    }
    // the bebé on the horse (story 54's ending): on the horse's back, in front of the frog (spots.caballito)
    final bh = w['bebeH'] as String?;
    if (bh != null && fila == 'tiendas') {
      final at = _p.at('caballito');
      final s = _spr(
        'bebeH${a ~/ 3 % 2}',
        () => mkBebe('clap', a ~/ 3 % 2 == 1),
      );
      // behind the frog (a child may hide 40 of his pixels at most: the sheet's frog-seen), towards the horse's head (the
      // right) on abuela's hands, nearer the frog in his arms
      final sx = _round(at.sx) + (bh == 'coqui' ? 7 : 13),
          sy = _round(at.sy) + _n(w['bebeDy']);
      out.add(
        TiendasItem(s, sx - 13, sy - 26, sy, at.d - .06, tag: 'bebe:caballo'),
      );
    }
    // the small things that lie or stand somewhere: the bread on the seat, the open tin
    for (final o
        in (w['cosas'] as List? ?? const []).cast<Map<String, dynamic>>()) {
      if (o['vis'] == 0) continue;
      final s =
          _heldSprite(o['k'] as String) ??
          _spr('nada', () => Sprite(1, 1, Uint32List(1)));
      final at = _atOf(o, fila);
      final sx = _round(at.sx), sy = _round(at.sy);
      out.add(
        TiendasItem(
          s,
          sx - s.w ~/ 2,
          sy - inkBottom(s),
          sy,
          at.d,
          tag: 'cosa:${o['id']}',
        ),
      );
    }
    // the shopkeeper's hand at a door (story 54): out of the doorway, at a hand's height over the door's spot
    final m = w['mano'] as Map<String, dynamic>?;
    if (m != null && fila == 'tiendas') {
      final at = _p.at('puerta_${m['k']}');
      final s = _spr('manoTendero', mkManoTendero);
      final sx = _round(at.sx), sy = _round(at.sy);
      out.add(TiendasItem(s, sx - 4, sy - 34, sy, at.d - .3, tag: 'mano'));
      if (_n(m['moneda']) == 1) {
        final mo = _spr('moneda', mkMoneda54);
        out.add(
          TiendasItem(mo, sx + 6, sy - 36, sy, at.d - .29, tag: 'moneda'),
        );
      }
    }
    // a hand or a head at a window of story 55's buildings, the sign mamá or papá shows at the door
    out.addAll(_altosItems(w, a));
    // the frog's held thing (story 56: the purse, the big bag, the umbrella)
    final cq = w['cq'] as Map<String, dynamic>;
    final fl = _heldSprite(cq['lleva'] as String?);
    if (fl != null) {
      final h = _frogHand(w);
      if (h != null) {
        out.add(
          TiendasItem(
            fl,
            _round(h.x) - fl.w ~/ 2,
            _round(h.y) - 2,
            h.sy,
            h.d,
            tag: 'lleva:coqui',
          ),
        );
      }
    }
    return out;
  }

  // the doors that open or rattle now (W.puertas: front -> `open` or a rattle's column, -1 or 1)
  List<TiendasItem> _doorItems(Map<String, dynamic> w, int a) {
    final out = <TiendasItem>[];
    if (filaOf(w) != 'tiendas') return out;
    final ps = (w['puertas'] as Map<String, dynamic>?) ?? const {};
    for (final e in ps.entries) {
      if (e.value == 'open') {
        final d = _openDoor(e.key, w);
        out.add(
          TiendasItem(
            d.s,
            d.left,
            d.top,
            0,
            0,
            pd: d.pd,
            tag: 'puerta:${e.key}',
          ),
        );
      } else if (e.value is num && _frameBaked != null) {
        final d = _shutDoor(e.key);
        if (d != null) {
          out.add(
            TiendasItem(
              d.s,
              d.left + (e.value as num).toInt(),
              d.top,
              0,
              0,
              pd: d.pd,
              tag: 'puerta:${e.key}',
            ),
          );
        }
      }
    }
    return out;
  }

  /* ---------- the doors drawn over the set's ---------- */

  // the door of front [k] (things.puerta_<k>.world: from its left edge to its right, the door's height)
  ({double d0, double d1, double dh}) _door(String k) {
    final w = _p.worldBox('puerta_$k');
    return (d0: w[0], d1: w[3], dh: w[5]);
  }

  // the wall's plane (y = 0) under picture pixel (X, Y) of picture [fila]: the world x and z there
  (double, double) _onWall(int X, int Y, [String fila = 'tiendas']) {
    final e = _p.engineOf(fila);
    final x = (X + .5 - e.OX) / e.S * e.R2;
    return (x, (x / e.R2 * .5 - (Y + .5 - e.OY) / e.S) / e.COS);
  }

  double _wallDepth(double x, double z) => x / _p.e.R2 * _p.e.COS + z * .5;

  static final Map<String, ({Sprite s, int left, int top, Float32List pd})>
  _opened = {};

  // the door of front [k] open (calle-base.js doorX with `open`: the dim inside, the floor, the panel turned inwards
  // ... and outwards over the pavement), drawn by La calle's kit on a picture of its own with the row's origin, in the
  // light of the state; kept where it shows through the doorway or stands in front of the wall
  ({Sprite s, int left, int top, Float32List pd}) _openDoor(
    String k,
    Map<String, dynamic> w,
  ) {
    final st = TiendasState.fromKey(setKey(w));
    final key = '$k${st.key}';
    final had = _opened[key];
    if (had != null) return had;
    final en = tiendasEngine(),
        b = PpBuild(en),
        kit = SetKit(en, b),
        cl = CalleBase(kit);
    en.zb.fillRange(0, en.zb.length, -1e9);
    en.pix.fillRange(0, en.pix.length, 0);
    final d = _door(k);
    // the door's wood, as tiendas-set.html gives it to each front
    final wood = k == 'banco'
        ? const [120, 130, 150]
        : k == 'farmacia'
        ? const [236, 240, 236]
        : k == 'correo'
        ? const [60, 90, 170]
        : CalleBase.WOOD;
    cl.doorX(0, d.d0, d.d1, d.dh, true, wood, true);
    final light = tiendasLight(st);
    if (light != null) kit.lightPass(light.m, light.a);
    var x0 = 240, y0 = 216, x1 = -1, y1 = -1;
    final keep = Uint8List(240 * 216);
    for (var Y = 0; Y < 216; Y++) {
      for (var X = 0; X < 240; X++) {
        final i = Y * 240 + X;
        if (en.zb[i] < -1e8) continue;
        final (x, z) = _onWall(X, Y);
        final inDoor = x > d.d0 && x < d.d1 && z > 0 && z < d.dh;
        if (!inDoor && en.zb[i] <= _wallDepth(x, z) + .01) continue;
        keep[i] = 1;
        x0 = math.min(x0, X);
        x1 = math.max(x1, X);
        y0 = math.min(y0, Y);
        y1 = math.max(y1, Y);
      }
    }
    final ww = x1 - x0 + 1, hh = y1 - y0 + 1;
    final px = Uint32List(ww * hh), pd = Float32List(ww * hh);
    for (var Y = y0; Y <= y1; Y++) {
      for (var X = x0; X <= x1; X++) {
        final i = Y * 240 + X;
        if (keep[i] == 0) continue;
        final (x, z) = _onWall(X, Y);
        px[(Y - y0) * ww + X - x0] = en.pix[i] | 0xFF000000;
        pd[(Y - y0) * ww + X - x0] = math.max(en.zb[i], _wallDepth(x, z));
      }
    }
    return _opened[key] = (s: Sprite(ww, hh, px), left: x0, top: y0, pd: pd);
  }

  // the set's own door of front [k], shut (its pixels in the doorway, from the baked set of the frame), to rattle
  ({Sprite s, int left, int top, Float32List pd})? _shutDoor(String k) {
    final baked = _frameBaked;
    if (baked == null) return null;
    final b = _p.box('puerta_$k'), d = _door(k);
    final ww = b[2], hh = b[3];
    final px = Uint32List(ww * hh), pd = Float32List(ww * hh);
    for (var y = 0; y < hh; y++) {
      for (var x = 0; x < ww; x++) {
        final X = b[0] + x, Y = b[1] + y;
        if (X < 0 || Y < 0 || X >= 240 || Y >= 216) continue;
        final (wx, wz) = _onWall(X, Y);
        if (!(wx > d.d0 && wx < d.d1 && wz > 0 && wz < d.dh)) continue;
        final i = Y * 240 + X;
        // the door's own pixels (the post box in front of the correo's is not the door's)
        if (baked.zb[i] > _wallDepth(wx, wz) + .05) continue;
        px[y * ww + x] = baked.pix[i] | 0xFF000000;
        pd[y * ww + x] = _wallDepth(wx, wz);
      }
    }
    return (s: Sprite(ww, hh, px), left: b[0], top: b[1], pd: pd);
  }

  /* ---------- story 55's windows and signs ---------- */

  List<TiendasItem> _altosItems(Map<String, dynamic> w, int a) {
    final out = <TiendasItem>[];
    if (filaOf(w) != 'altos') return out;
    final lado = _lado(w['lado']);
    final v = w['ventana'] as Map<String, dynamic>?;
    if (v != null) {
      // OPEN: the buildings' windows have no place in the sheet (altos.buildings gives the doors only): the hand that
      // waves and the head that shakes are drawn at the top middle of the building's thing box (altos.things.<id>.<lado>
      // .box), a little under its roof edge
      final b = _p.buildingBox(v['k'] as String, lado);
      final cx = b[0] + b[2] ~/ 2, ty = b[1] + (v['k'] == 'alto' ? 22 : 24);
      final s = v['que'] == 'cabeza'
          ? _spr('cabezaVentana', mkCabezaVentana)
          : _spr(
              'manoVentana${a ~/ 3 % 2}',
              () => mkManoVentana(a ~/ 3 % 2 == 1),
            );
      final dx = v['que'] == 'cabeza' && _n(v['no']) == 1
          ? (a ~/ 2 % 2 == 0 ? -1 : 1)
          : 0;
      final left = cx - s.w ~/ 2 + dx;
      // on the building's wall (y = 0): each pixel at the wall's depth there
      final pd = Float32List(s.w * s.h);
      for (var y = 0; y < s.h; y++) {
        for (var x = 0; x < s.w; x++) {
          final (wx, wz) = _onWall(left + x, ty + y, 'altos');
          pd[y * s.w + x] = _wallDepth(wx, wz) + .02;
        }
      }
      out.add(TiendasItem(s, left, ty, ty + s.h, 0, pd: pd, tag: 'ventana'));
    }
    return out;
  }

  // who is talking now (the runner's TALK), or null
  String? _talker() {
    try {
      return host.TALK;
    } catch (_) {
      return null;
    }
  }

  /* ---------- drawing ---------- */

  BakedSet? _frameBaked;
  Float32List? _setZ;
  final Uint32List _layer = Uint32List(240 * 216);
  final Float32List _lz = Float32List(240 * 216);
  final Uint8List _isV = Uint8List(240 * 216);

  @override
  void setFramed(PpEngine engine, BakedSet baked, Map<String, dynamic> W) {
    _frameBaked = baked;
    _setZ = baked.zb;
  }

  static final double _t30 = math.tan(math.pi / 6);

  /// Composes [it] into a layer ([layer], depths [lz], grown-ups' marks [isV]) by the sheet's rule: hidden where [setZ]
  /// is nearer than its plane plus [bias], or another sprite's pixel is nearer than its plane (the frog never behind a
  /// grown-up). Returns how many of its pixels it drew.
  static int put(
    TiendasItem it,
    Uint32List layer,
    Float32List lz,
    Uint8List isV,
    Float32List? setZ,
    double bias,
    double S, {
    void Function(int i, String why)? hidden,
  }) {
    const w0 = 240, h0 = 216;
    final s = it.s;
    var n = 0;
    for (var y = 0; y < s.h; y++) {
      final Y = it.top + y;
      if (Y < 0 || Y >= h0) continue;
      final plane = it.d + (it.sy - (Y + .5)) * _t30 / S;
      for (var x = 0; x < s.w; x++) {
        final c = s.px[y * s.w + x];
        if (c >>> 24 == 0) continue;
        final X = it.left + x;
        if (X < 0 || X >= w0) continue;
        final i = Y * w0 + X;
        final pz = it.pd != null ? it.pd![y * s.w + x] : plane;
        if (setZ != null && setZ[i] > pz + (it.pd != null ? .05 : bias)) {
          hidden?.call(i, 'set');
          continue;
        }
        if (lz[i] > pz && !(it.tag == 'coqui' && isV[i] == 2)) {
          hidden?.call(i, isV[i] == 2 ? 'grown' : 'sprite');
          continue;
        }
        lz[i] = pz;
        layer[i] = c;
        isV[i] = it.grown ? 2 : 0;
        n++;
      }
    }
    return n;
  }

  /// The frog as the game draws him (juego.js frog, at the depth of his feet), placed; null when he is not seen.
  TiendasItem? frogItem(Map<String, dynamic> W, int a) {
    final q = W['cq'] as Map<String, dynamic>;
    if (!jsTruthy(q['vis'])) return null;
    final b = host.frogBox(q), at = _frogPoint(W, q);
    final ox = b.x.toInt() - 16, oy = b.y.toInt() - 24;
    final px = Uint32List(64 * 64);
    final g = Ctx(px, 64, 64)..translate(-ox.toDouble(), -oy.toDouble());
    host.frog(g, q, a);
    return TiendasItem(
      Sprite(64, 64, px),
      ox,
      oy,
      _round(at.sy),
      at.d,
      tag: 'coqui',
    );
  }

  /// [items] and the frog: every sprite, placed.
  List<TiendasItem> placed(Map<String, dynamic> W, int a) {
    final all = items(W, a);
    final f = frogItem(W, a);
    if (f != null) all.add(f);
    return all;
  }

  /// Composes the whole sprite layer of [W] into [layer] ([lz], [isV]): the doors over the set's, then every sprite,
  /// the frog last. The rules' tests call it with a [hidden] that counts what hides what.
  void compose(
    Map<String, dynamic> W,
    int a,
    Uint32List layer,
    Float32List lz,
    Uint8List isV,
    Float32List? setZ, {
    void Function(TiendasItem it, int i, String why)? hidden,
  }) {
    layer.fillRange(0, layer.length, 0);
    lz.fillRange(0, lz.length, -1e9);
    isV.fillRange(0, isV.length, 0);
    final bias = _p.bias, S = _p.e.S;
    for (final it in placed(W, a)) {
      put(
        it,
        layer,
        lz,
        isV,
        setZ,
        bias,
        S,
        hidden: hidden == null ? null : (i, why) => hidden(it, i, why),
      );
    }
  }

  @override
  void draw(Ctx c, Map<String, dynamic> W, int a) {
    compose(W, a, _layer, _lz, _isV, _setZ);
    c.drawImage(Sprite(240, 216, _layer), 0, 0);
    _over(c, W, a);
  }

  // what is drawn over everything: the cloud of story 56 at the sky's edge, the drops and the rain
  void _over(Ctx c, Map<String, dynamic> W, int a) {
    if (filaOf(W) != 'tiendas') return;
    final cam = _p.view('tiendas');
    if (_n(W['nubeSpr']) == 1 && _n(W['nube']) == 0) {
      // OPEN: the cloud "at the left edge of the sky" (story 56, nube 0) has no place in the sheet, and the set draws no
      // cloud at nube 0 (its nube 1 draws one at the upper left, its nube 2 a bank over the sky): it is drawn at the
      // view's left edge (views.tiendas.x0), its top row on the picture's, half of it outside the window
      final s = _spr('nube', mkNube);
      c.drawImage(s, cam[0].toInt() - s.w ~/ 2, 0);
    }
    final ll = _n(W['lluvia']);
    if (ll > 0) {
      // the drops, over the whole window: a few (1) or rain (2), falling 6 rows a frame
      final n = ll == 2 ? 70 : 9;
      for (var k = 0; k < n; k++) {
        final x = cam[0] + ((k * 53 + (k * k) % 37) % cam[2]);
        final y = ((k * 29 + a * 6) % 230) - 10;
        fr(c, x, y, 1, ll == 2 ? 4 : 3, 0xFFF0D0B8);
      }
    }
  }

  /* ---------- the cards ---------- */

  // the pictures of a list card's places (story 54's errands, story 56's two things)
  static Sprite _listIcon(String k) => _spr('icono$k', () {
    switch (k) {
      case 'letter':
        return mkCarta();
      case 'purse':
        return mkMonedero(false);
      case 'bottle':
        // the small bottle of the card (tiendas.md 54: "a small bottle")
        final b = Buf(6, 10);
        b.rect(2, 0, 2, 2, hexColour('#F4F4F4'));
        b.rect(1, 2, 4, 8, hexColour('#5AA0E0'));
        b.rect(1, 5, 4, 2, hexColour('#FAFAF4'));
        return b.outline().done();
      case 'bag':
        return mkBolsaGrande();
      case 'umbrella':
        return mkSombrillaCerrada();
    }
    return Sprite(1, 1, Uint32List(1));
  });

  @override
  void hud(Ctx c, Map<String, dynamic> W, int a) {
    var x0 = 3;
    final l = W['lista'] as Map<String, dynamic>?;
    if (l != null) {
      // the list: the pictures of the errands (54: a letter, a coin purse, a small bottle; 56: a bag, an umbrella); the
      // one that is asked for now lit, a tick on each one done
      final ks = (l['ks'] as List).cast<String>();
      final hecho = (l['hecho'] as Map).cast<String, dynamic>();
      final w = 4 + ks.length * 18;
      tarjeta(c, x0, 3, w, 26);
      for (var i = 0; i < ks.length; i++) {
        final k = ks[i], x = x0 + 3 + i * 18;
        if (l['on'] == k) {
          fr(c, x - 1, 4, 18, 24, 0xFF40D8F8);
          fr(c, x, 5, 16, 22, 0xFFF4FDFF);
        }
        final s = _listIcon(k);
        final sc = s.h > 16 ? 1 : 1;
        c.drawImage(s, x + 8 - s.w * sc ~/ 2, 16 - s.h ~/ 2);
        if (_n(hecho[k]) == 1) {
          // a tick
          for (var j = 0; j < 4; j++) {
            fr(c, x + 3 + j, 21 + j, 2, 2, OUT);
          }
          for (var j = 0; j < 8; j++) {
            fr(c, x + 7 + j, 24 - j, 2, 2, OUT);
          }
          for (var j = 0; j < 4; j++) {
            fr(c, x + 4 + j, 21 + j, 1, 1, 0xFF30C040);
          }
          for (var j = 0; j < 8; j++) {
            fr(c, x + 8 + j, 23 - j, 1, 1, 0xFF30C040);
          }
        }
      }
      x0 += w + 4;
    }
    if (W['monedas'] != null) {
      // story 54: the coins abuela keeps (3 to 0) and the little horse they are for
      final n = _n(W['monedas']);
      const w = 4 + 3 * 7 + 16;
      tarjeta(c, x0, 3, w, 26);
      for (var i = 0; i < 3; i++) {
        final mo = _spr('moneda', mkMoneda54);
        if (i < n) {
          c.drawImage(mo, x0 + 4 + i * 7, 14);
        } else {
          fr(c, x0 + 5 + i * 7, 15, 3, 3, 0xFFD4C8C8);
        }
      }
      final hx = x0 + 4 + 21 + 1;
      // a little horse: a brown body, its neck and head, a white mane, a red base
      fr(c, hx, 22, 12, 2, 0xFF323CCE);
      fr(c, hx + 2, 15, 7, 5, 0xFF4678B0);
      fr(c, hx + 8, 10, 3, 7, 0xFF4678B0);
      fr(c, hx + 9, 10, 4, 3, 0xFF568CC4);
      fr(c, hx + 7, 9, 2, 4, 0xFFECF6FA);
      fr(c, hx + 3, 20, 1, 2, 0xFF3C6496);
      fr(c, hx + 7, 20, 1, 2, 0xFF3C6496);
      x0 += w + 4;
    }
    if (!jsTruthy(W['tarjeta'])) return;
    final marcas = W['marcas'] is List ? W['marcas'] as List : const [];
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

  // castShadow(x, y, 0, radius) at the world x, y of whoever stands on the ground (shadows.at; none sitting, none on the
  // horse or the seat: shadows.none, onSeat), the stroller's (.35). In the picture altos (its own origin) a shadow is
  // cast at the world point under the same screen point of the frame's engine (the row's origin), as El mostrador's
  // street
  @override
  List<ShadowCast> shadows(Map<String, dynamic> W) {
    final out = <ShadowCast>[];
    final fila = filaOf(W);
    void cast(TiendasAt at, double? r) {
      if (r == null || at.z != 0) return;
      if (fila == 'tiendas') {
        out.add((x: at.x, y: at.y, z: 0, r: r));
      } else {
        final g = _p.e.unproject(at.sx, at.sy);
        out.add((x: g.x, y: g.y, z: 0, r: r));
      }
    }

    final gente = (W['gente'] as Map<String, dynamic>?) ?? const {};
    for (final en in gente.entries) {
      final p = en.value as Map<String, dynamic>;
      if (p['vis'] == 0 || _n(p['sent']) == 1) continue;
      if (_p.noShadow((p['spot'] as String?) ?? '', fila)) continue;
      cast(_atOf(p, fila), _p.radius(en.key, fila) ?? _p.radius(en.key));
    }
    final c = W['coche'] as Map<String, dynamic>?;
    if (c != null && c['vis'] != 0) {
      cast(_atOf(c, fila), _p.radius('cochecito'));
    }
    final q = W['cq'] as Map<String, dynamic>?;
    if (q != null && jsTruthy(q['vis'])) {
      final spot = _frogSpotAt(q, W);
      if (spot == null || !_p.noShadow(spot, fila)) {
        cast(_frogPoint(W, q), _p.radius('coqui', fila));
      }
    }
    return out;
  }

  /* ---------- the things he can touch ---------- */

  static final Expando<List<int>> _inkOf = Expando<List<int>>();

  static List<int>? _ink(Sprite s) {
    final had = _inkOf[s];
    if (had != null) return had.isEmpty ? null : had;
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
    final r = x1 < 0 ? const <int>[] : [x0, y0, x1 - x0 + 1, y1 - y0 + 1];
    _inkOf[s] = r;
    return r.isEmpty ? null : r;
  }

  static List<num>? inkBox(Sprite s, int left, int top) {
    final b = _ink(s);
    return b == null ? null : [left + b[0], top + b[1], b[2], b[3]];
  }

  int? _boxesF;
  Map<String, dynamic>? _boxesW;
  Map<String, List<num>?> _boxes = {};

  Map<String, List<num>?> _allBoxes(Map<String, dynamic> w) => {
    for (final it in items(w, 0))
      if (it.tag != null && !it.flat) it.tag!: inkBox(it.s, it.left, it.top),
  };

  List<num>? _boxOfTag(Map<String, dynamic> w, String tag) {
    int? f;
    try {
      f = host.F;
    } catch (_) {
      f = null;
    }
    if (f == null) return _allBoxes(w)[tag];
    if (f != _boxesF || !identical(w, _boxesW)) {
      _boxes = _allBoxes(w);
      _boxesF = f;
      _boxesW = w;
    }
    return _boxes[tag];
  }

  // the bebé's box: over the stroller's basket and his head (mkCochecito: the bebé at (-1, 4) of the stroller), or on
  // the horse
  List<num>? _bebeBox(Map<String, dynamic> w) {
    final h = _boxOfTag(w, 'bebe:caballo');
    if (h != null) return h;
    final c = w['coche'] as Map<String, dynamic>?;
    if (c == null || c['vis'] == 0 || _n(c['vacio']) == 1) return null;
    return _boxOfTag(w, 'cochecito');
  }

  List<Thing> _things() {
    Thing sprite(
      String id,
      List<num>? Function(Map<String, dynamic>) f, {
      num m = 0,
      bool z = false,
    }) => Thing(
      id: id,
      m: m,
      z: z,
      si: (w) => f(w) != null,
      box: (Map<String, dynamic> w) => f(w),
    );
    bool tiendas(Map<String, dynamic> w) => filaOf(w) == 'tiendas';
    bool altos(Map<String, dynamic> w) => filaOf(w) == 'altos';
    Thing front(String k) {
      final b = _p.box(k), d = _p.box('puerta_$k');
      return Thing(
        id: k,
        m: 0,
        si: tiendas,
        // story 56: the front is its door (things.puerta_<k>.box); else its lit wall (things.<k>.box)
        box: (Map<String, dynamic> w) => _n(w['portal']) == 1
            ? [d[0], d[1], d[2], d[3]]
            : [b[0], b[1], b[2], b[3]],
      );
    }

    Thing building(String k) => Thing(
      id: k,
      m: 0,
      si: altos,
      box: (Map<String, dynamic> w) {
        final b = _p.buildingBox(k, _lado(w['lado']));
        return [b[0], b[1], b[2], b[3]];
      },
    );
    final cb = _p.box('caballito');
    return [
      // the lunch tins in the basket, small, over the bicycle and Luis (z: before the frog)
      sprite('comida', (w) => _boxOfTag(w, 'comida'), m: 1, z: true),
      // the bebé, over the stroller
      sprite('bebe', _bebeBox, m: 1, z: true),
      // the people (names: the free poke)
      for (final id in _people)
        sprite(id, (w) => _boxOfTag(w, 'persona:$id'), m: 1),
      // the set's things (sheet: things.<id>.box; altos.things.<id>.<lado>.box), the small ones first
      Thing(
        id: 'caballito',
        m: 0,
        si: tiendas,
        world: _p.worldBox('caballito'),
        box: [cb[0], cb[1], cb[2], cb[3]],
      ),
      for (final k in _fronts) front(k),
      building('alto'),
      building('nuevo'),
    ];
  }

  /* ---------- talking ---------- */

  // the point over a speaker's head: its sprite's top
  @override
  List<num>? talkAt(String who, Map<String, dynamic> W) {
    if (who == 'luis') {
      final bici = W['bici'] as Map<String, dynamic>?;
      if (bici != null && _n(bici['monta']) == 1 && bici['vis'] != 0) {
        final b = _boxOfTag(W, 'bici:monta');
        if (b != null) return [_round(b[0] + b[2] / 2), b[1] - 1];
      }
    }
    for (final it in items(W, 0)) {
      if (it.tag != 'persona:$who') continue;
      final b = inkBox(it.s, it.left, it.top);
      if (b == null) return null;
      return [_round(b[0] + b[2] / 2), b[1] - 1];
    }
    return null;
  }

  @override
  Future<void> stake(int lost, int max, String en) async {
    host.SFX.bonk();
    await wait(300);
  }

  // the stories write no place on the picture: nothing to move
  @override
  List<num> remap(List<num> xy) => xy;

  @override
  String estado(Map<String, dynamic> W) {
    final g = (W['gente'] as Map<String, dynamic>?) ?? const {};
    final gente = [
      for (final e in g.entries)
        if ((e.value as Map)['vis'] != 0)
          '${e.key}@${(e.value as Map)['spot']}',
    ].join(' ');
    return 'fila=${W['fila']} par=${W['par']} lado=${W['lado']} nube=${W['nube']} gente=$gente monedas=${W['monedas']} vapor=${W['vapor']} tins=${W['tins']}';
  }

  /* ---------- moving ---------- */

  // a walk: a straight line at a steady pace, about 5 px of the picture a tick
  Future<void> _anda(String id, String spot) async {
    final w = _p.world(spot, _fila);
    await _andaA(_g(id), w[0], w[1], w[2]);
    _g(id)['spot'] = spot;
  }

  Future<void> _andaA(Map<String, dynamic> p, num x, num y, num z) async {
    if (p['vis'] == 0) {
      p
        ..['x'] = x
        ..['y'] = y
        ..['z'] = z
        ..['vis'] = 1;
      return;
    }
    final a = _atOf(p, _fila), b = _p.atWorld(x, y, z, _fila);
    final dist = math.sqrt(
      (b.sx - a.sx) * (b.sx - a.sx) + (b.sy - a.sy) * (b.sy - a.sy),
    );
    final x0 = p['x'] as num, y0 = p['y'] as num, z0 = (p['z'] as num?) ?? 0;
    if ((b.sx - a.sx).abs() > 3 && p.containsKey('dir')) {
      p['dir'] = b.sx > a.sx ? 1 : -1;
    }
    if (dist >= .5) {
      final n = math.max(1, (dist / 5).ceil());
      for (var i = 1; i <= n; i++) {
        p['x'] = x0 + (x - x0) * i / n;
        p['y'] = y0 + (y - y0) * i / n;
        p['z'] = z0 + (z - z0) * i / n;
        p['dy'] = i % 2 == 1 && i < n ? -1 : 0;
        await _tick();
      }
    }
    p
      ..['x'] = x
      ..['y'] = y
      ..['z'] = z
      ..['dy'] = 0;
  }

  // the stroller is pushed to a spot
  Future<void> _empuja(String spot) async {
    final c = W['coche'] as Map<String, dynamic>?;
    if (c == null) return;
    final w = _p.world(spot);
    await _andaA(c, w[0], w[1], w[2]);
    c['spot'] = spot;
  }

  // a person who is not seen appears at a spot
  Map<String, dynamic> _aparece(String id, String spot) {
    final p = _g(id);
    final w = _p.world(spot, _fila);
    p
      ..['x'] = w[0]
      ..['y'] = w[1]
      ..['z'] = w[2]
      ..['vis'] = 1
      ..['spot'] = spot
      ..['dy'] = 0
      ..['sent'] = 0;
    return p;
  }

  // the frog hops to a spot (the kit's hopTo: a hop about every 30 px)
  Future<void> _salta(String spot) async {
    final q = W['cq'] as Map<String, dynamic>;
    final L = _frogAt(_p.at(spot, _fila));
    if (!jsTruthy(q['vis'])) {
      q
        ..['x'] = L[0]
        ..['y'] = L[1]
        ..['vis'] = 1;
      return;
    }
    final dx = (q['x'] as num) - L[0], dy = (q['y'] as num) - L[1];
    final dd = math.sqrt(dx * dx + dy * dy);
    if (dd >= 3) {
      await host.hopTo(
        L[0],
        L[1],
        math.max(1, math.min(4, _round(dd / 30))),
        1,
      );
    }
    q
      ..['x'] = L[0]
      ..['y'] = L[1];
  }

  Map<String, dynamic> get _puertas => W['puertas'] as Map<String, dynamic>;

  void _campanilla() {
    host.tone(1568, 0, .25, 'sine', .08);
    host.tone(2093, .08, .3, 'sine', .06);
  }

  // a door is pushed: it opens (a bell over it), or it rattles and stays shut (the set's door, moved to and fro)
  Future<void> _abre(String k) async {
    _puertas[k] = 'open';
    _campanilla();
    await wait(TICK * 3);
  }

  void _cierra(String k) {
    _puertas.remove(k);
    host.SFX.toc();
  }

  Future<void> _sacude(String k, {int veces = 6}) async {
    for (var i = 0; i < veces; i++) {
      _puertas[k] = i % 2 == 0 ? -1 : 1;
      host.tone(180 + (i % 2) * 40, 0, .05, 'square', .04);
      await _tick();
    }
    _puertas.remove(k);
  }

  /* ---------- story 54: the errands ---------- */

  // the bebé's thing in a wrong place, by the front: a lollipop (farmacia), a top (tienda), a pencil (banco, correo)
  // (the story's own `toma` is the same; this is for a call without it)
  static String _tomaDe(String k) =>
      k == 'farmacia' ? 'lollipop' : (k == 'tienda' ? 'top' : 'pencil');

  // `va54` {a, ok, trae}: abuela, the stroller and the frog cross to the front's group (groups.grupo_<a>); then:
  // - the letter (54 step 2): abuela drops it in the post box (no going in);
  // - the purse, the small bag (steps 3, 4): abuela goes in alone (spots.puerta_<a>) and comes out with it;
  // - the game (steps 6, 7): abuela and the stroller go in, and come out with the place's thing (ok), or with the bebé's
  //   fist round what he took and a coin paid into the shopkeeper's hand at the door (not ok)
  Future<void> _va54(Map<String, dynamic> o) async {
    final k = o['a'] as String;
    if (!_fronts.contains(k)) return;
    final ok = _n(o['ok']) == 1, trae = o['trae'] as String?;
    final g = _p.group('grupo_$k');
    final ab = _g('abuela'), c = W['coche'] as Map<String, dynamic>?;
    ab['pose'] = 'idle';
    await Future.wait([_anda('abuela', g[0]), _empuja(g[1]), _salta(g[2])]);
    ab['dir'] = 1;
    if (trae == 'letter') {
      // OPEN: the post box has no place in the sheet (things lists the fronts, the doors and the horse; the post box is
      // only a part of the set): abuela holds the letter out where she stands (abuela.puerta_correo) and it is gone
      ab['pose'] = 'mano';
      await wait(TICK * 4);
      ab['lleva'] = null;
      host.SFX.drop();
      await wait(TICK * 2);
      ab['pose'] = 'idle';
      return;
    }
    final juego =
        !ok || const ['plasters', 'envelope', 'parcel'].contains(trae);
    // in at the door
    await _anda('abuela', 'puerta_$k');
    await _abre(k);
    ab['vis'] = 0;
    if (juego && c != null) {
      await _empuja('puerta_$k');
      c['vis'] = 0;
    }
    _cierra(k);
    await wait(TICK * 8);
    // out again
    await _abre(k);
    ab
      ..['vis'] = 1
      ..['dir'] = -1;
    if (juego && c != null) {
      c['vis'] = 1;
      if (!ok) {
        c['toma'] = trae ?? _tomaDe(k);
        c['est'] = 'idle';
      }
    }
    ab['lleva'] = ok ? trae : null;
    host.SFX.blip();
    if (!ok) {
      // abuela, shaking her head, drops a coin into the shopkeeper's hand at the door (a hand and a sleeve; no face)
      W['mano'] = <String, dynamic>{'k': k, 'moneda': 0};
      ab['pose'] = 'mano';
      await wait(TICK * 3);
      W['monedas'] = math.max(0, _n(W['monedas']) - 1);
      (W['mano'] as Map)['moneda'] = 1;
      host.tone(1200, 0, .08, 'sine', .05);
      await wait(TICK * 4);
      W['mano'] = null;
      ab['pose'] = 'idle';
    }
    await wait(TICK * 2);
    _cierra(k);
    await Future.wait([_anda('abuela', g[0]), if (juego) _empuja(g[1])]);
    ab['dir'] = 1;
  }

  // `caballito54` {n}: the ending for three, two or one coin left (54 step 8); the group stands at the horse
  // (groups.grupo_caballito) and the frog is on its back (spots.caballito)
  Future<void> _caballito54(int n) async {
    final ab = _g('abuela');
    final c = W['coche'] as Map<String, dynamic>?;
    final q = W['cq'] as Map<String, dynamic>;
    Future<void> paga() async {
      ab['pose'] = 'mano';
      await wait(TICK * 2);
      final m = math.max(0, _n(W['monedas']) - 1);
      W['monedas'] = m;
      ab['lleva'] = m > 0 ? 'coins$m' : null;
      host.tone(1200, 0, .08, 'sine', .05);
      await wait(TICK * 2);
      ab['pose'] = 'idle';
    }

    Future<void> rock(void Function(int dy) set, int times) async {
      host.tone(523, 0, .2, 'triangle', .05);
      for (var i = 0; i < times; i++) {
        set(i % 2 == 0 ? -2 : 0);
        await _tick();
        await _tick();
      }
      set(0);
    }

    // OPEN: the sheet names no place for the frog off the horse (its group at the horse is abuela, the stroller and the
    // frog on the horse's back): while the bebé rides on abuela's hands, the frog stays sitting on the back, still
    if (c != null) c['toma'] = null;
    Future<void> bebe(String con, {bool frog = false}) async {
      if (c != null) c['vacio'] = 1;
      W['bebeH'] = con;
      ab['pose'] = 'mano';
      await rock((dy) {
        W['bebeDy'] = dy;
        if (frog) q['dy'] = dy;
      }, 8);
      W['bebeH'] = null;
      if (c != null) c['vacio'] = 0;
      ab['pose'] = 'idle';
    }

    await paga();
    if (n == 1) {
      // one coin: the frog and the bebé ride together, the frog holding him
      await bebe('coqui', frog: true);
    } else {
      // the frog rides, then the bebé on abuela's hands, then (three) the frog again, waving
      await rock((dy) => q['dy'] = dy, 8);
      await paga();
      await bebe('abuela');
      if (n == 3) {
        await paga();
        await rock((dy) => q['dy'] = dy, 6);
        host.bounce(6);
        host.SFX.right();
      }
    }
    W['bebeDy'] = 0;
    q['dy'] = 0;
    await wait(TICK * 2);
  }

  /* ---------- story 55: the buildings ---------- */

  // the building [k] (`alto`, `nuevo`)'s side now (the drawn `lado`)
  String _ladoDe(String k) => TiendasPlaces.sideOf(k, _lado(W['lado']));

  // `entra55` {a, ok, quien}: Luis and the frog run to the building's door with a tin (groups.puerta_<side>): mamá or
  // papá comes to the door (spots.puerta_<side>), shows the sign and takes the tin; or they run in, a head at a window
  // shakes and points across, and they come out puffing
  Future<void> _entra55(Map<String, dynamic> o) async {
    final k = o['a'] as String;
    if (k != 'alto' && k != 'nuevo') return;
    final side = _ladoDe(k), ok = _n(o['ok']) == 1;
    final g = _p.group('puerta_$side', 'altos');
    final luis = _g('luis');
    await _apartaPaso(side);
    // Luis takes a tin out of the basket
    W['tins'] = math.max(0, _n(W['tins']) - 1);
    luis
      ..['lleva'] = 'tin'
      ..['pose'] = 'taza';
    await Future.wait([_anda('luis', g[1]), _salta(g[2])]);
    luis['dir'] = 1;
    if (ok) {
      final quien = (o['quien'] as String?) ?? 'mama';
      // OPEN: "hangs a sign beside it": the sheet names no place on the wall beside the door (altos.buildings gives the
      // doors' edges only): mamá or papá shows the sign in her or his hand at the door
      // mamá in her nurse's coat, papá with a book
      final p = _aparece(quien, g[0])
        ..['pose'] = 'taza'
        ..['dir'] = -1
        ..['lleva'] = quien == 'papa' ? 'book' : null;
      host.SFX.toc();
      await wait(TICK * 4);
      p['lleva'] = quien == 'mama' ? 'cruz' : 'campana';
      host.SFX.blip();
      await wait(TICK * 5);
      // the tin goes from Luis's hand to the parent's
      luis
        ..['lleva'] = null
        ..['pose'] = 'idle';
      p['lleva'] = 'tin';
      W['tins'] = _n(W['tins']);
      host.SFX.blip();
      await wait(TICK * 3);
      return;
    }
    // the wrong door: in and up; a head at a window shakes and points across; out again, puffing
    luis['vis'] = 0;
    (W['cq'] as Map<String, dynamic>)['vis'] = 0;
    host.SFX.toc();
    await wait(TICK * 4);
    W['ventana'] = <String, dynamic>{'k': k, 'que': 'cabeza', 'no': 1};
    await wait(TICK * 8);
    W['ventana'] = null;
    final q = W['cq'] as Map<String, dynamic>;
    final L = _frogAt(_p.at(g[2], 'altos'));
    q
      ..['x'] = L[0]
      ..['y'] = L[1]
      ..['vis'] = 1;
    luis['vis'] = 1;
    for (var i = 0; i < 4; i++) {
      luis['dy'] = i % 2 == 0 ? -1 : 0;
      host.bounce(2);
      await _tick();
      await _tick();
    }
    luis['dy'] = 0;
    // the tin back in the basket (it is carried to the right door next)
    luis
      ..['lleva'] = null
      ..['pose'] = 'idle';
    W['tins'] = _n(W['tins']) + 1;
    host.SFX.bonk();
  }

  // the passer-by of story 55 (the señor, the señora) stands at senor.pasa, where the group at the right building's
  // door stands too (14 px across and 8 down from puerta_der, 8 and 11 from coqui.puerta_der): while they go there he
  // or she steps over to the left building's front
  Future<void> _apartaPaso(String side) async {
    for (final id in const ['senor', 'senora']) {
      final p = _gente[id] as Map<String, dynamic>?;
      if (p == null || p['vis'] == 0) continue;
      // OPEN: the picture altos has no second place for a passer-by: he or she waits at luis.puerta_izq (Luis's place
      // in front of the left building's door, free while Luis is at the right one)
      if (side == 'der' && p['spot'] == 'senor.pasa') {
        await _anda(id, 'luis.puerta_izq');
        p['dir'] = 1;
      } else if (side == 'izq' && p['spot'] == 'luis.puerta_izq') {
        // and back to the passer-by's place when they go to the left one
        await _anda(id, 'senor.pasa');
        p['dir'] = -1;
      }
    }
  }

  // `otra55`: Luis gets on his bicycle with the frog, they ride out of the picture to the left; the picture changes to the
  // second pair of buildings (par b) and they ride in to their place again (groups.bici); the señor is gone and the
  // señora stands there with her bag
  Future<void> _otra55() async {
    final luis = _g('luis'), bici = W['bici'] as Map<String, dynamic>;
    final q = W['cq'] as Map<String, dynamic>;
    for (final id in const ['mama', 'papa', 'senor', 'senora']) {
      if (_seen(id)) _g(id)['vis'] = 0;
    }
    // to the bicycle, on, and away (to the picture's left: x 6 columns before the view)
    final b = _p.world('bici', 'altos');
    await Future.wait([_anda('luis', 'bici'), _salta('coqui.bici')]);
    luis['vis'] = 0;
    q['vis'] = 0;
    bici
      ..['x'] = b[0]
      ..['y'] = b[1]
      ..['monta'] = 1;
    host.tone(2093, 0, .12, 'sine', .07);
    final cam = _p.view('altos');
    final away = _p.fromScreen(
      cam[0] - 30,
      _p.at('bici', 'altos').sy,
      0,
      'altos',
    );
    await _andaA(bici, away.x, b[1], 0);
    // the second street
    W['par'] = 'b';
    await wait(TICK * 2);
    bici['x'] = away.x;
    await _andaA(bici, b[0], b[1], 0);
    bici['monta'] = 0;
    final l = _aparece('luis', 'bici');
    l['dir'] = 1;
    final L = _frogAt(_p.at('coqui.bici', 'altos'));
    q
      ..['x'] = L[0]
      ..['y'] = L[1]
      ..['vis'] = 1;
    // OPEN: the picture altos has one place for a passer-by (senor.pasa, "the señor passing"): the señora stands there
    _aparece('senora', 'senor.pasa')
      ..['dir'] = -1
      ..['lleva'] = 'bigbag';
    await wait(TICK * 2);
  }

  /* ---------- story 56: the doors ---------- */

  // where a person stands to push a front's door: the door's spot (spots.puerta_<k>: "where somebody goes in")
  // `puerta56` {k, ok, trae, quien}: abuela or the frog pushes the front's door: it opens and she or he goes in and comes
  // out with a thing (the stamp, the bag, the umbrella), or it rattles and stays shut
  Future<void> _puerta56(Map<String, dynamic> o) async {
    final k = o['k'] as String;
    if (!_fronts.contains(k)) return;
    final ok = _n(o['ok']) == 1, trae = o['trae'] as String?;
    final quien = (o['quien'] as String?) ?? 'coqui';
    final at = 'puerta_$k';
    if (quien == 'abuela') {
      final ab = _g('abuela');
      await _anda('abuela', at);
      ab['dir'] = 1;
      if (ok) {
        await _abre(k);
        ab['vis'] = 0;
        _cierra(k);
        await wait(TICK * 6);
        await _abre(k);
        ab['vis'] = 1;
        // her bread in one hand; what she bought goes into her bag (it is not drawn after)
        host.SFX.blip();
        await wait(TICK * 2);
        _cierra(k);
      } else {
        // it does not move; she knocks; nothing
        await _sacude(k, veces: 4);
        for (var i = 0; i < 3; i++) {
          host.SFX.toc();
          await wait(TICK * 2);
        }
        await wait(TICK * 2);
      }
      await _anda('abuela', 'abuela.lluvia');
      ab['dir'] = 1;
      return;
    }
    // the frog: abuela, standing at abuela.lluvia (the opening), would hide his face at the banco's door (5 px across, 13
    // down): she steps back to abuela.acera while he pushes, and comes back after
    final q = W['cq'] as Map<String, dynamic>;
    final ab = _gente['abuela'] as Map<String, dynamic>?;
    final aparta =
        ab != null &&
        ab['vis'] != 0 &&
        _n(ab['sent']) == 0 &&
        ab['spot'] == 'abuela.lluvia';
    await Future.wait([
      _salta(at),
      if (aparta) _anda('abuela', 'abuela.acera'),
    ]);
    Future<void> vuelve() async {
      await Future.wait([
        _salta('coqui.56'),
        if (aparta) _anda('abuela', 'abuela.lluvia'),
      ]);
      if (aparta) ab['dir'] = 1;
    }

    if (ok) {
      host.bounce(4);
      await _abre(k);
      q['vis'] = 0;
      _cierra(k);
      await wait(TICK * 6);
      await _abre(k);
      q['vis'] = 1;
      q['lleva'] = trae == 'bag' ? 'bigbag' : trae;
      host.SFX.blip();
      await wait(TICK * 2);
      _cierra(k);
      await vuelve();
      if (trae == 'bag') {
        // abuela puts the bread in it
        q['lleva'] = null;
        final pan = _items.where((x) => x['id'] == 'pan').firstOrNull;
        if (pan != null) pan['k'] = 'breadbag';
        host.SFX.blip();
        await wait(TICK * 2);
      }
      return;
    }
    // the frog pushes with both hands: it rattles; he pushes again
    host.bounce(4);
    await _sacude(k);
    host.bounce(4);
    await _sacude(k, veces: 4);
    await vuelve();
    if (k == 'banco' && !_seen('senora') && _n(W['senoraFuera']) == 0) {
      // OPEN: no act brings the señora out of the tienda before her line (story 56 step 4: "The señora comes out of the
      // tienda with a kite in her hand", then her line): she comes out after the frog's push on the banco's door of the
      // opening (step 3), at senora.tienda
      W['senoraFuera'] = 1;
      await _abre('tienda');
      _aparece('senora', 'senora.tienda')
        ..['lleva'] = 'kite'
        ..['dir'] = 1;
      await wait(TICK * 3);
      _cierra('tienda');
    }
  }

  // `cierran56`: a bell rings twelve somewhere; along the row every door is pulled shut, a key turns in one of them;
  // the señora walks on to where she stops on her way past (senora.pasa)
  Future<void> _cierran56() async {
    for (var i = 0; i < 12; i++) {
      host.tone(784, 0, .25, 'sine', .05);
      await wait(TICK);
    }
    for (final k in _fronts) {
      _puertas[k] = 'open';
      await wait(TICK);
      _puertas.remove(k);
      host.SFX.toc();
      await wait(TICK);
    }
    host.tone(300, 0, .1, 'square', .04, 200);
    await wait(TICK * 2);
  }

  // abuela sits down on the seat with her bread (spots.banco_acera, her lap on the seat's top; her bread beside her at
  // spots.pan) and gives the frog her purse
  Future<void> _sienta56() async {
    final ab = _g('abuela');
    await _anda('abuela', 'banco_acera');
    ab
      ..['sent'] = 1
      ..['dir'] = 1
      ..['lleva'] = null;
    final w = _p.world('pan');
    _items.removeWhere((x) => x['id'] == 'pan');
    _items.add(<String, dynamic>{
      'id': 'pan',
      'k': 'bread',
      'x': w[0],
      'y': w[1],
      'z': w[2],
      'vis': 1,
    });
    final q = W['cq'] as Map<String, dynamic>;
    q['lleva'] = 'purse';
    host.SFX.blip();
    await wait(TICK * 3);
    q['lleva'] = null;
    // the señora walks on to where she stops on her way past (spots.senora.pasa: the sheet's moment 4), her kite put
    // away; she stands there once abuela sits (her place is abuela's standing one, abuela.lluvia)
    final s = _gente['senora'] as Map<String, dynamic>?;
    if (s != null && s['vis'] != 0) {
      s['lleva'] = null;
      await _anda('senora', 'senora.pasa');
    } else {
      _aparece('senora', 'senora.pasa');
    }
    _g('senora')['dir'] = -1;
  }

  // `final56` {n}: the ending, by the steps of the dry time lost (56 step 8): abuela stands up (abuela.lluvia) with the
  // umbrella and her bread in its bag
  Future<void> _final56(int n) async {
    final ab = _g('abuela');
    // the señora goes on her way first (back in at the tienda: abuela stands up at her place, abuela.lluvia)
    if (_seen('senora')) {
      await _anda('senora', 'senora.tienda');
      await _abre('tienda');
      _g('senora')['vis'] = 0;
      _cierra('tienda');
    }
    final pan = _items.where((x) => x['id'] == 'pan').firstOrNull;
    if (pan != null) pan['vis'] = 0;
    ab['sent'] = 0;
    final w = _p.world('abuela.lluvia');
    ab
      ..['x'] = w[0]
      ..['y'] = w[1]
      ..['z'] = 0.0
      ..['spot'] = 'abuela.lluvia'
      ..['lleva'] = 'umbrella';
    host.SFX.blip();
    await wait(TICK * 3);
    if (n == 0) {
      // OPEN: "they walk off along the pavement": the sheet names no place off the pavement for them: they stand at
      // their places of story 56 (abuela.lluvia, coqui.56) under the bright sky, the umbrella shut, and the first drop
      // falls behind them
      W['lluvia'] = 1;
      host.SFX.drop();
      await wait(TICK * 6);
      W['lluvia'] = 0;
      host.SFX.right();
      return;
    }
    // a few drops (one lost) or rain (two): abuela opens the umbrella
    W['lluvia'] = n == 1 ? 1 : 2;
    if (n == 2) host.SFX.lluvia();
    await wait(TICK * 3);
    ab['lleva'] = 'umbrellaOpen';
    host.SFX.blip();
    await wait(TICK * 3);
    if (n == 1) {
      // the frog hops ahead with his mouth open to the drops (where he is: no place ahead in the sheet)
      for (var i = 0; i < 3; i++) {
        host.bounce(6);
        await wait(TICK * 3);
      }
    }
  }

  /* ---------- the acts (tiendas.md, "Needs") ---------- */

  // the acts started with `suelto: 1` (they run while their line is said), waited for by `ya`
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
    // `ya`: waits for the acts that were started with `suelto: 1`
    'ya': (o) async {
      final all = List<Future<void>>.of(_sueltos);
      _sueltos.clear();
      await Future.wait(all);
    },
    // `ir` {a}: the frog hops to one of his places (the sheet's frog spots); `caballito` takes the group at the horse
    // with him (54 step 8), `bici` Luis back to his bicycle (55 step 9)
    'ir': (o) async {
      final a = o['a'], key = jsTruthy(a) ? a : o['en'];
      if (key is! String) return;
      final spot = frogSpotOf(key);
      if (spot == null) return;
      if (key == 'caballito' && _fila == 'tiendas') {
        final g = _p.group('grupo_caballito');
        _g('abuela')['pose'] = 'idle';
        await Future.wait([_anda('abuela', g[0]), _empuja(g[1]), _salta(g[2])]);
        _g('abuela')['dir'] = -1;
        return;
      }
      if (key == 'bici' && _fila == 'altos' && _seen('luis')) {
        final luis = _g('luis');
        final cosa = _items.where((x) => x['id'] == 'fiambrera').firstOrNull;
        if (cosa != null) _items.remove(cosa);
        luis
          ..['sent'] = 0
          ..['pose'] = 'idle'
          ..['lleva'] = null;
        await Future.wait([_anda('luis', 'bici'), _salta(spot)]);
        luis['dir'] = 1;
        return;
      }
      await _salta(spot);
    },
    // `marca` {que}: the star or the cross on the rounds card
    'marca': (o) async {
      final m = W['marcas'];
      if (m is List) {
        final i = m.indexOf(null);
        if (i >= 0) m[i] = o['que'];
      }
      host.SFX.blip();
      await wait(250);
    },
    // `lista` {k, hecho}: the card's pictures (54: the letter, the coin purse, the small bottle; 56: the bag, the
    // umbrella): with no `k` the card comes; `hecho` 0 lights the picture, 1 gives it its tick
    'lista': (o) async {
      final k = o['k'] as String?;
      var l = W['lista'] as Map<String, dynamic>?;
      if (l == null) {
        l = <String, dynamic>{
          'ks': _fila == 'tiendas' && W['coche'] != null
              ? <String>['letter', 'purse', 'bottle']
              : <String>['bag', 'umbrella'],
          'on': null,
          'hecho': <String, dynamic>{},
        };
        W['lista'] = l;
        // story 54: beside it, the coins and the horse (tiendas.md 54: "The card shows the three coins and the horse")
        if (W['coche'] != null) W['monedas'] ??= 3;
      }
      if (k != null) {
        if (_n(o['hecho']) == 1) {
          (l['hecho'] as Map)[k] = 1;
          if (l['on'] == k) l['on'] = null;
          host.SFX.right();
        } else {
          l['on'] = k;
          host.SFX.blip();
        }
      }
      await wait(TICK * 2);
    },
    // `monedas` {n}: abuela shows her coins in her hand (54 steps 1, 8); at the start she puts them away again
    'monedas': (o) async {
      final n = _n(o['n']);
      final ab = _g('abuela');
      W['monedas'] = n;
      final was = ab['lleva'];
      ab
        ..['pose'] = 'mano'
        ..['lleva'] = n > 0 ? 'coins$n' : null;
      host.SFX.blip();
      await wait(TICK * 6);
      ab['pose'] = 'idle';
      // the opening (no rounds card yet): into her pocket, after the errands; the ending: she keeps them in her hand
      if (!jsTruthy(W['tarjeta'])) ab['lleva'] = was;
    },
    // `telefono`: abuela's telephone rings; she listens and nods (54 step 5)
    'telefono': (o) async {
      final ab = _g('abuela');
      final was = ab['lleva'];
      for (var i = 0; i < 3; i++) {
        host.tone(1320, 0, .12, 'square', .04);
        host.tone(1320, .16, .12, 'square', .04);
        await wait(TICK * 3);
      }
      ab
        ..['pose'] = 'saluda0'
        ..['lleva'] = 'telefono';
      await wait(TICK * 6);
      for (var i = 0; i < 2; i++) {
        ab['dy'] = 1;
        await _tick();
        ab['dy'] = 0;
        await _tick();
      }
      ab
        ..['pose'] = 'idle'
        ..['lleva'] = was;
    },
    // `cuenta54`: abuela counts on her fingers, looking along the row (54 step 4)
    'cuenta54': (o) async {
      final ab = _g('abuela');
      for (var i = 0; i < 3; i++) {
        ab['dir'] = i % 2 == 0 ? -1 : 1;
        ab['pose'] = 'saluda0';
        host.tone(660 + i * 110, 0, .08, 'sine', .04);
        await wait(TICK * 3);
        ab['pose'] = 'idle';
        await _tick();
      }
      ab['dir'] = 1;
    },
    // `va54` {a, ok, trae}: the errands and the game's visits (54 steps 2 to 4, 6, 7)
    'va54': _va54,
    // `caballito54` {n}: the ending (54 step 8)
    'caballito54': (o) => _caballito54(_n(o['n'])),
    // `vapor` {n}: the wisps of steam over the tins (55: 1, 6, 7)
    'vapor': (o) async {
      W['vapor'] = _n(o['n']);
      if (_n(o['n']) < 3) host.tone(500, 0, .3, 'sine', .03, 300);
      await wait(TICK * 2);
    },
    // `ventana55`: a window opens at the top of the tall building and a hand waves (55 step 2)
    'ventana55': (o) async {
      W['ventana'] = <String, dynamic>{'k': 'alto', 'que': 'mano'};
      host.SFX.toc();
      await wait(TICK * 9);
      W['ventana'] = null;
    },
    // `pintor55`: the painter of the new building lifts his brush (55 step 3)
    'pintor55': (o) async {
      // OPEN: the painter on the ladder has no place in the sheet (the ladder is the set's; no spot stands by it): he
      // comes to the new building's doorway (spots.puerta_<side>) and lifts his brush there, then goes in
      final side = _ladoDe('nuevo');
      final p = _aparece('pintor', 'puerta_$side')..['dir'] = 1;
      await wait(TICK * 2);
      p['pose'] = 'brocha';
      host.SFX.blip();
      await wait(TICK * 6);
      p['pose'] = 'idle';
      await wait(TICK * 2);
      p['vis'] = 0;
    },
    // `cuenta55` {a}: Luis counts the tall one's floors with a finger, to the top; or touches the new one's wet paint and
    // looks at his finger (55 steps 2, 3)
    'cuenta55': (o) async {
      final luis = _g('luis');
      if (o['a'] == 'alto') {
        for (var i = 0; i < 3; i++) {
          luis['pose'] = i % 2 == 0 ? 'saluda0' : 'saluda1';
          luis['dy'] = -i;
          host.tone(523 + i * 131, 0, .1, 'sine', .04);
          await wait(TICK * 3);
        }
        luis
          ..['pose'] = 'idle'
          ..['dy'] = 0;
        return;
      }
      // to the new building's front (luis.puerta_<side>), a hand on the wall, a look at his finger, and back
      final side = _ladoDe('nuevo');
      final g = _p.group('puerta_$side', 'altos');
      await Future.wait([_anda('luis', g[1]), _salta(g[2])]);
      luis
        ..['dir'] = 1
        ..['pose'] = 'taza';
      await wait(TICK * 4);
      luis['pose'] = 'ojos';
      host.tone(400, 0, .15, 'sine', .04, 600);
      await wait(TICK * 4);
      luis['pose'] = 'idle';
      await Future.wait([_anda('luis', 'bici'), _salta('coqui.bici')]);
      luis['dir'] = 1;
    },
    // `entra55` {a, ok, quien}: the tin to the right door, or the wrong door (55 steps 6, 7)
    'entra55': _entra55,
    // `otra55`: they ride on; the picture changes to the second pair (55 step 7)
    'otra55': (o) => _otra55(),
    // `come55` {n}: the ending (55 step 8): the last tin opened on Luis's lap, the rice steaming (3), a little (2), none
    // (1: Luis blows on his fingers); they eat
    'come55': (o) async {
      final n = _n(o['n']);
      final luis = _g('luis');
      W['tins'] = 0;
      luis
        ..['lleva'] = 'tinOpen$n'
        ..['pose'] = 'idle';
      host.SFX.blip();
      await wait(TICK * 4);
      if (n == 1) {
        // a joke: he blows on his fingers
        luis['lleva'] = null;
        luis['pose'] = 'ojos';
        host.tone(300, 0, .4, 'sawtooth', .01, 200);
        await wait(TICK * 4);
        luis
          ..['pose'] = 'idle'
          ..['lleva'] = 'tinOpen$n';
      }
      for (var i = 0; i < 4; i++) {
        host.SFX.munch();
        host.bounce(3);
        luis['dy'] = i % 2 == 0 ? -1 : 0;
        await wait(TICK * 2);
      }
      luis['dy'] = 0;
      if (n == 3) host.SFX.right();
    },
    // `puerta56` {k, ok, trae, quien}: somebody pushes a door (56 steps 2, 3, 6, 7)
    'puerta56': _puerta56,
    // `cierran56`: the bell; every door is pulled shut (56 step 5)
    'cierran56': (o) => _cierran56(),
    // `nube` {n}: the cloud's step (56 steps 6, 7): over the street (1), raining (2)
    'nube': (o) async {
      final n = _n(o['n']).clamp(0, 2);
      W['nube'] = n;
      host.SFX.trueno(.5);
      if (n == 2) {
        W['lluvia'] = 2;
        host.SFX.lluvia();
      }
      await wait(TICK * 4);
    },
    // `final56` {n}: the ending (56 step 8)
    'final56': (o) => _final56(_n(o['n'])),
    // `gesto` {quien, que, a}: `saluda`, `no`, `senala` with `a`, `mira` with `a`, `sienta`, `papel` (Luis turns his
    // paper round), `cometa` (the señora holds her kite up), `baila` (the frog in the rain)
    'gesto': (o) async {
      final quien = o['quien'] as String, que = o['que'] as String?;
      if (quien == 'coqui') {
        // `baila`: the frog dances in the rain in front of abuela; she laughs
        final n = que == 'baila' ? 6 : 2;
        for (var i = 0; i < n; i++) {
          host.bounce(6);
          await wait(TICK * 2);
        }
        if (que == 'baila' && _seen('abuela')) {
          final ab = _g('abuela');
          for (var i = 0; i < 4; i++) {
            ab['dy'] = i % 2 == 0 ? -1 : 0;
            await _tick();
          }
          ab['dy'] = 0;
        }
        return;
      }
      if (quien == 'bebe') {
        // the bebé in his stroller claps and points at the horse
        final c = W['coche'] as Map<String, dynamic>?;
        if (c == null) return;
        c['est'] = 'clap';
        await wait(TICK * 6);
        c['est'] = que == 'senala' ? 'senala' : 'idle';
        await wait(TICK * 6);
        c['est'] = 'idle';
        return;
      }
      if (quien == 'senor' && !_seen('senor') && _fila == 'altos') {
        // 55 step 4: the señor walks past (from the right of the window to senor.pasa) and looks at the tins.
        // OPEN: "the tin the frog is holding": no act gives the frog a tin (the tins are in the basket until the game):
        // the señor looks at the tins in the basket
        final w = _p.world('senor.pasa', 'altos');
        final p = _aparece('senor', 'senor.pasa');
        final cam = _p.view('altos');
        final from = _p.fromScreen(
          cam[0] + cam[2] + 20,
          _p.at('senor.pasa', 'altos').sy,
          0,
          'altos',
        );
        p
          ..['x'] = from.x
          ..['y'] = w[1]
          ..['dir'] = -1;
        await _andaA(p, w[0], w[1], 0);
        p['dir'] = -1;
      }
      if (que == 'sienta') {
        if (quien == 'abuela') return _sienta56();
        if (quien == 'luis') {
          // Luis sits down on the kerb (groups.bordillo: bordillo1), the last tin in his hands
          final luis = _g('luis');
          await _anda('luis', 'bordillo1');
          luis
            ..['sent'] = 1
            ..['dir'] = 1;
          W['tins'] = 0;
          host.SFX.blip();
          await wait(TICK * 3);
          return;
        }
      }
      final p = _g(quien);
      if (p['vis'] == 0) return;
      switch (que) {
        case 'saluda':
          for (var i = 0; i < 6; i++) {
            p['pose'] = i % 2 == 0 ? 'saluda0' : 'saluda1';
            await _tick();
          }
          p['pose'] = 'idle';
        case 'mira':
        case 'senala':
          final a = o['a'] as String?, at = _atOf(p, _fila);
          num? tx;
          if (a == 'coqui') {
            tx = host.frogBox(W['cq'] as Map<String, dynamic>).x + 16;
          } else if (a == 'nube') {
            // the cloud at the sky's left edge
            tx = 0;
          } else if (a != null) {
            final b = box(a, W);
            if (b != null) tx = b[0] + b[2] / 2;
          }
          if (tx != null && (tx - at.sx).abs() > 2) {
            p['dir'] = tx > at.sx ? 1 : -1;
          }
          if (quien == 'abuela' && a == 'nube') {
            // she looks up and holds the bread close
            p['dy'] = -1;
            host.SFX.trueno(.3);
          }
          if (que == 'senala') p['pose'] = 'mano';
          await wait(TICK * 5);
          p['dy'] = 0;
          p['pose'] = 'idle';
        case 'no':
          final d = _n(p['dir']) < 0 ? -1 : 1;
          for (var i = 0; i < 4; i++) {
            p['dir'] = i % 2 == 0 ? -d : d;
            await _tick();
          }
          p['dir'] = d;
        case 'papel':
          // Luis takes his paper out, turns it round twice and scratches his head
          final was = p['pose'];
          p['pose'] = 'taza';
          for (var i = 0; i < 4; i++) {
            p['lleva'] = i % 2 == 0 ? 'paper' : 'paperBack';
            await wait(TICK * 3);
          }
          p
            ..['lleva'] = null
            ..['pose'] = 'saluda0';
          await wait(TICK * 3);
          p['pose'] = was;
        case 'cometa':
          // the señora holds her kite up
          p
            ..['pose'] = 'saluda0'
            ..['lleva'] = 'kite';
          await wait(TICK * 8);
          p['pose'] = 'idle';
        default:
          await wait(TICK * 3);
      }
    },
  };
}
