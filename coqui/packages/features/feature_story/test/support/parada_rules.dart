// La parada's rules (parada-sheet.json's rules and checks, and the order's "The sheet's rules hold in the scene"), checked
// on the real scene's frame at the end of every act that is waited for (an act started with `suelto: 1` is checked at
// the `ya` that waits for it) and at the story's end. What is checked:
// - the frog is never behind a grown-up, a car or a guagua: none of the frog's pixels is hidden, in the frame as composed,
//   by a grown-up's or a guagua's (frog-seen), and the set, the children and the small things hide at most 40 of them
//   (the sheet's check frog-seen allows 40 under a child); what he holds himself (a strip, a box, the ball) is in front
//   of him and is not counted;
// - two sprites that stand together never overlap unless their feet are 12 px apart up-down (sprites-apart: the frog 32
//   wide, a grown-up 24, a child 24, Canelo 28, the feet's spot in the middle of the bottom edge), the sitters too;
// - every person, Canelo and the frog stands inside the picture, the feet's column inside the view's window (in-view);
// - nobody stands on the street but at a guagua's door (nobody-on-street: the door spots are y 5.45);
// - the first guagua (parada1) is whole inside the window and the second (parada2) is cut, if at all, only at its back
//   end, the window's right edge (guaguas-whole);
// - a guagua that stands at the stop stands in its lane (y 4.6) at parada1 or parada2 (rules.guagua);
// - while the frog is at a button (coqui.boton_sube, coqui.boton_baja, coqui.botones) nobody stands at fila1 or fila2
//   (row-free);
// - nobody at the row or at a button is hidden by the guagua or the set, and a grown-up at a door is not hidden by the
//   guagua (kerb-front, door-front);
// - Canelo at bajo_banco shows 60% of his pixels or more (canelo-shown).
// Besides the rules, [overDepth] counts the times the frog is drawn over a grown-up who stands nearer than he does.
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/coqui_scenes.dart';

/// What went against a rule: when, which rule, the details.
typedef ParadaBreach = ({String at, String rule, String what});

/// Watches a real La parada while a story plays: [wrap] its acts, then read [breaches] and [checked].
class ParadaRules {
  ParadaRules(this.scene) : _m = scene;

  /// The scene (La parada's; its own members, `placed`, `autos`, `compose`, `places`, are reached untyped: a feature
  /// may not import a package's src/).
  final SetScene scene;
  final dynamic _m;

  static final Map<String, BakedSet> _baked = {};
  static SetBakes? _bakes;
  BakedSet _bakeOf(String key) =>
      _baked[key] ??= (_bakes ??= SetBakes(scene)).bakeKey(key);

  final List<ParadaBreach> breaches = [];

  /// Kept for the report's shape (El esquina's); La parada has none.
  final List<ParadaBreach> known = [];

  /// Where the frog was drawn over a grown-up nearer than he (not a breach).
  final List<String> overDepth = [];
  int checked = 0;

  /// Every act of the scene, once done, has the frame checked (an act started loose: at the `ya` that waits for it).
  void wrap() {
    final acts = scene.acts;
    for (final k in acts.keys.toList()) {
      final f = acts[k]!;
      acts[k] = (o) async {
        await f(o);
        if (jsTruthy(o['suelto'])) return;
        check('after ${o['act'] ?? k}');
      };
    }
  }

  static const Set<String> _children = {'luis', 'carmen', 'nino3'};

  static bool _adult(String? tag) =>
      tag != null &&
      tag.startsWith('persona:') &&
      !_children.contains(tag.substring(8));

  static List<int>? _ink(Sprite s) {
    var x0 = s.w, y0 = s.h, x1 = -1, y1 = -1;
    for (var y = 0; y < s.h; y++) {
      for (var x = 0; x < s.w; x++) {
        if (s.px[y * s.w + x] >>> 24 == 0) continue;
        x0 = math.min(x0, x);
        x1 = math.max(x1, x);
        y0 = math.min(y0, y);
        y1 = math.max(y1, y);
      }
    }
    return x1 < 0 ? null : [x0, y0, x1, y1];
  }

  /// Checks the frame of the scene's world now.
  void check(String at) {
    final W = scene.host.W;
    checked++;
    final p = _m.places;
    final baked = _bakeOf(scene.setKey(W));
    final layer = Uint32List(240 * 216),
        lz = Float32List(240 * 216),
        isV = Uint8List(240 * 216);
    var byAuto = 0, byGrown = 0, byOther = 0, frogPx = 0;
    final hiddenSet = <String, int>{}, hiddenAuto = <String, int>{};
    _m.compose(
      W,
      0,
      layer,
      lz,
      isV,
      baked.zb,
      hidden: (dynamic it, int i, String why) {
        final tag = it.tag as String?;
        if (tag != null) {
          if (why == 'set') hiddenSet[tag] = (hiddenSet[tag] ?? 0) + 1;
          if (why == 'auto') hiddenAuto[tag] = (hiddenAuto[tag] ?? 0) + 1;
        }
        if (tag != 'coqui' || why == 'held') return;
        if (why == 'auto') {
          byAuto++;
        } else if (why == 'sprite' && isV[i] == 2) {
          byGrown++;
        } else {
          byOther++;
        }
      },
    );
    final items = (_m.placed(W, 0) as List).cast<dynamic>();
    final frog = items.where((i) => i.tag == 'coqui').toList();
    for (final f in frog) {
      final s = f.s as Sprite;
      frogPx += s.px.where((c) => c >>> 24 != 0).length;
    }
    if (frog.isNotEmpty) {
      if (byAuto > 0 || byGrown > 0) {
        breaches.add((
          at: at,
          rule: 'frog behind a grown-up, a car or a guagua',
          what: '$byAuto px by guaguas, $byGrown by grown-ups of $frogPx',
        ));
      }
      if (byOther > 40) {
        breaches.add((
          at: at,
          rule: 'frog hidden by the set or a child (more than 40 px)',
          what: '$byOther px of $frogPx',
        ));
      }
      final f = frog.first;
      for (final g in items.where((i) => _adult(i.tag))) {
        if ((g.sy as num) <= (f.sy as num)) continue;
        final fb = _ink(f.s as Sprite)!, gb = _ink(g.s as Sprite)!;
        final fx0 = f.left + fb[0], fx1 = f.left + fb[2];
        final gx0 = g.left + gb[0], gx1 = g.left + gb[2];
        final fy0 = f.top + fb[1], fy1 = f.top + fb[3];
        final gy0 = g.top + gb[1], gy1 = g.top + gb[3];
        if (fx0 <= gx1 && gx0 <= fx1 && fy0 <= gy1 && gy0 <= fy1) {
          overDepth.add('$at: over ${g.tag}');
        }
      }
    }
    // sprites apart: people, Canelo and the frog standing at their spots (not on their way)
    final cam = scene.CAM['wide']!;
    final standing =
        <({String tag, num sx, num sy, int w, String spot, double y})>[];
    final q0 = W['cq'] as Map;
    String frogSpot = '';
    for (final e in scene.lugar.entries) {
      if (e.value[0] == q0['x'] && e.value[1] == q0['y']) {
        frogSpot = (_m.frogSpotOf(e.key) as String?) ?? e.key;
      }
    }
    final gente = (W['gente'] as Map).cast<String, dynamic>();
    for (final it in items) {
      final tag = it.tag as String?;
      if (tag == null) continue;
      if (tag == 'coqui') {
        final q = W['cq'] as Map;
        final w = frogSpot.isEmpty ? null : p.world(frogSpot) as List<double>;
        standing.add((
          tag: tag,
          sx: (q['x'] as num) + 16,
          sy: it.sy,
          w: 32,
          spot: frogSpot,
          y: w == null ? 0 : w[1],
        ));
      } else if (tag.startsWith('persona:') || tag == 'perro') {
        final id = tag == 'perro' ? 'perro' : tag.substring(8);
        final o = gente[id] as Map;
        final spot = o['spot'];
        final at = p.atWorld(o['x'], o['y'], o['z']);
        if (spot is! String || !p.has(spot)) continue;
        final w = p.world(spot) as List<double>;
        if (w[0] != o['x'] || w[1] != o['y']) continue; // on the way
        standing.add((
          tag: tag,
          sx: at.sx,
          sy: at.sy,
          w: tag == 'perro' ? 28 : 24,
          spot: spot,
          y: (o['y'] as num).toDouble(),
        ));
      }
    }
    for (var i = 0; i < standing.length; i++) {
      for (var j = i + 1; j < standing.length; j++) {
        final a = standing[i], b = standing[j];
        final across = (a.sx.round() - b.sx.round()).abs(),
            down = (a.sy.round() - b.sy.round()).abs();
        if (across < (a.w + b.w) / 2 && down < 12) {
          breaches.add((
            at: at,
            rule: 'two sprites overlap',
            what:
                '${a.tag}@${a.spot} ~ ${b.tag}@${b.spot}: $across px across, $down down',
          ));
        }
      }
    }
    // inside the picture and the view; nobody standing on the street but at a guagua's door
    for (final s in standing) {
      if (s.sx < cam[0] || s.sx >= cam[0] + cam[2] || s.sy > 216) {
        breaches.add((
          at: at,
          rule: 'outside the view',
          what: '${s.tag} at column ${s.sx.round()}, row ${s.sy.round()}',
        ));
      }
      if (s.y > 1.6 && s.y < 5.8 && !s.spot.startsWith('puerta_')) {
        breaches.add((
          at: at,
          rule: 'somebody on the street',
          what: '${s.tag} at ${s.spot}',
        ));
      }
      // kerb-front, door-front: nobody at the row or a button hidden by the guagua or the set; a grown-up at a door not
      // hidden by the guagua
      final row = s.spot.startsWith('fila') || s.spot.startsWith('coqui.');
      final nSet = hiddenSet[s.tag] ?? 0, nAuto = hiddenAuto[s.tag] ?? 0;
      if (row && (nSet > 0 || nAuto > 0)) {
        breaches.add((
          at: at,
          rule: 'somebody at the row or a button hidden',
          what: '${s.tag}@${s.spot}: $nSet px by the set, $nAuto by a guagua',
        ));
      }
      if (s.spot.startsWith('puerta_') && nAuto > 0) {
        breaches.add((
          at: at,
          rule: 'a person at a door hidden by the guagua',
          what: '${s.tag}@${s.spot}: $nAuto px',
        ));
      }
    }
    // row-free: while the frog works the buttons nobody stands at fila1 or fila2
    if (frogSpot.startsWith('coqui.boton') || frogSpot == 'coqui.botones') {
      for (final s in standing) {
        if (s.spot == 'fila1' || s.spot == 'fila2') {
          breaches.add((
            at: at,
            rule: 'somebody at fila1 or fila2 while the frog works the buttons',
            what: '${s.tag}@${s.spot}',
          ));
        }
      }
    }
    // Canelo at bajo_banco shows 60% or more
    for (final it in items) {
      if (it.tag != 'perro') continue;
      final o = gente['perro'] as Map;
      if (o['spot'] != 'bajo_banco') continue;
      final n = (it.s as Sprite).px.where((c) => c >>> 24 != 0).length;
      final hid = hiddenSet['perro'] ?? 0;
      if (n > 0 && (n - hid) / n < .6) {
        breaches.add((
          at: at,
          rule: 'Canelo under the seat shows less than 60%',
          what: '${n - hid} of $n px',
        ));
      }
    }
    // the guaguas: the first whole in the window, the second cut only at its back end; in the stop's lane when they
    // stand
    final autos = (W['autos'] as Map).cast<String, dynamic>();
    for (final a in (_m.autos(W) as List).cast<dynamic>()) {
      final key = (a.tag as String).substring(5);
      final v = autos[key] as Map;
      final stop = v['spot'];
      if (v['para'] != 1 || (stop != 'parada1' && stop != 'parada2')) continue;
      final w = p.world(stop) as List<double>;
      if (v['y'] != p.lane || v['x'] != w[0]) {
        breaches.add((
          at: at,
          rule: 'a guagua stands off its place',
          what: '$key at ${v['x']}, ${v['y']} ($stop)',
        ));
      }
      final b = _ink(a.v.s as Sprite)!;
      final x0 = a.left + b[0], x1 = a.left + b[2];
      final left = cam[0], right = cam[0] + cam[2] - 1;
      if (stop == 'parada1' && (x0 < left || x1 > right)) {
        breaches.add((
          at: at,
          rule: 'the first guagua cut by the window',
          what: '$key columns $x0 to $x1',
        ));
      }
      if (stop == 'parada2' && x0 < left) {
        breaches.add((
          at: at,
          rule: 'the second guagua cut at its front',
          what: '$key columns $x0 to $x1',
        ));
      }
    }
  }
}
