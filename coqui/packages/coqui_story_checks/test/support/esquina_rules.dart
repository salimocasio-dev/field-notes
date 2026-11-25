// La esquina's rules (esquina-sheet.json's rules and checks, and page 13's "The sheet's rules hold in the scene"), checked
// on the real scene's frame at the end of every act that is waited for (an act started with `suelto: 1` is checked at
// the `ya` that waits for it) and at the story's end. What is checked:
// - the frog is never behind a grown-up, a car or a guagua: none of the frog's pixels is hidden, in the frame as composed,
//   by a grown-up's or a vehicle's (frog-seen), and the pole, the children and the other things hide at most 40 of them
//   (the sheet's check frog-seen allows 40);
// - two sprites that stand together never overlap unless their feet are 12 px apart up-down (sprites-apart: the frog 32
//   wide, a grown-up 24, a child 24, the feet's spot in the middle of the bottom edge);
// - a guagua that stops in story 49 or 50 stands in the near lane (the sheet's routes.trafico: lane `cerca`);
// - every person and the frog stands inside the picture, the feet's column inside the view's window (spots-in-view);
// - nobody stands still on the street but the obrero and who gets out of a car on the kerb stone (street-people);
// - mamá at enfrente is whole inside the window (enfrente-in-window);
// - who stands at the colmado's door is not hidden by the set (door-people);
// - in story 50's game (the obrero on his bucket), while two things wait at the lane's ends, the hole shows at least 45% of
//   its pixels (hole-shows, the sheet's moment 7).
// Two pairs of the sheet's own places overlap (story 48: the frog at toca_carro beside abuela at acera2, 6 px across and
// 11 down; the frog at toca_guagua beside mamá at acera3, 6 across and 5 down: the scripts put them together, the sheet's
// sprites-apart check never met them): they are [known], not breaches, and page 13 lists them for the content lane.
// Besides the rules, [overDepth] counts the times the frog is drawn over a grown-up who stands nearer than he does (the
// scene keeps him seen: the sheet's places put him behind one there; page 13 lists them for the content lane).
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/coqui_scenes.dart';

/// What went against a rule: when, which rule, the details.
typedef EsquinaBreach = ({String at, String rule, String what});

/// Watches a real La esquina while a story plays: [wrap] its acts, then read [breaches] and [checked].
class EsquinaRules {
  EsquinaRules(this.scene) : _m = scene;

  /// The scene (La esquina's; its own members, `placed`, `autos`, `compose`, `places`, are reached untyped: a feature
  /// may not import a package's src/).
  final SetScene scene;
  final dynamic _m;

  static final Map<String, BakedSet> _baked = {};
  static SetBakes? _bakes;
  BakedSet _bakeOf(String key) =>
      _baked[key] ??= (_bakes ??= SetBakes(scene)).bakeKey(key);

  final List<EsquinaBreach> breaches = [];

  /// The overlaps of the sheet's own places that the scripts put together (see the file's head), when they happen.
  final List<EsquinaBreach> known = [];

  static const Set<String> _knownPairs = {
    'persona:abuela@acera2 ~ coqui@toca_carro',
    'persona:mama@acera3 ~ coqui@toca_guagua',
  };

  /// Where the frog was drawn over a grown-up nearer than he (not a breach: see the file's head).
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

  static bool _adult(String? tag) =>
      tag != null &&
      tag.startsWith('persona:') &&
      tag != 'persona:luis' &&
      tag != 'persona:carmen';

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
    // the frame as composed, and what hides what of the frog
    var byAuto = 0, byGrown = 0, byOther = 0, frogPx = 0;
    final hiddenOf = <dynamic, int>{};
    _m.compose(
      W,
      0,
      layer,
      lz,
      isV,
      baked.zb,
      hidden: (dynamic it, int i, String why) {
        hiddenOf[it] = (hiddenOf[it] ?? 0) + 1;
        if (it.tag != 'coqui') return;
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
          what: '$byAuto px by vehicles, $byGrown by grown-ups of $frogPx',
        ));
      }
      if (byOther > 40) {
        breaches.add((
          at: at,
          rule: 'frog hidden by the set or a child (more than 40 px)',
          what: '$byOther px of $frogPx',
        ));
      }
      // the frog drawn over a grown-up who stands nearer (a sheet's place behind one)
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
    // sprites apart: people and the frog standing (not on their way)
    final cam = scene.CAM['wide']!;
    final standing = <({String tag, num sx, num sy, int w, String spot})>[];
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
        standing.add((
          tag: tag,
          sx: (q['x'] as num) + 16,
          sy: it.sy,
          w: 32,
          spot: frogSpot,
        ));
      } else if (tag.startsWith('persona:')) {
        final id = tag.substring(8);
        final o = gente[id] as Map;
        final spot = o['spot'];
        final at = p.atWorld(o['x'], o['y'], o['z']);
        if (spot is! String || !p.has(spot)) continue;
        final w = p.world(spot) as List<double>;
        if (w[0] != o['x'] || w[1] != o['y']) continue; // on the way
        standing.add((tag: tag, sx: at.sx, sy: at.sy, w: 24, spot: spot));
      }
    }
    for (var i = 0; i < standing.length; i++) {
      for (var j = i + 1; j < standing.length; j++) {
        final a = standing[i], b = standing[j];
        // on whole pixels, as the sheet's check measures (its screen points are rounded)
        final across = (a.sx.round() - b.sx.round()).abs(),
            down = (a.sy.round() - b.sy.round()).abs();
        if (across < (a.w + b.w) / 2 && down < 12) {
          final pair = '${a.tag}@${a.spot} ~ ${b.tag}@${b.spot}';
          (_knownPairs.contains(pair) ? known : breaches).add((
            at: at,
            rule: 'two sprites overlap',
            what: '$pair: ${across.round()} px across, ${down.round()} down',
          ));
        }
      }
    }
    // inside the picture and the view; nobody standing on the street but the obrero and on the kerb stone
    for (final s in standing) {
      if (s.sx < cam[0] || s.sx >= cam[0] + cam[2] || s.sy > 216) {
        breaches.add((
          at: at,
          rule: 'outside the view',
          what: '${s.tag} at column ${s.sx.round()}, row ${s.sy.round()}',
        ));
      }
      if (s.tag == 'coqui') continue;
      final o = gente[s.tag.substring(8)] as Map;
      final spot = o['spot'] as String;
      final y = (o['y'] as num).toDouble();
      if (y > 1.8 &&
          y < 5.8 &&
          !spot.startsWith('obrero') &&
          !spot.startsWith('sale_')) {
        breaches.add((
          at: at,
          rule: 'a person on the street',
          what: '${s.tag} at $spot',
        ));
      }
    }
    // mamá at enfrente whole in the window; who stands at the door not hidden by the set
    for (final it in items) {
      final tag = it.tag as String?;
      if (tag == null || !tag.startsWith('persona:')) continue;
      final o = gente[tag.substring(8)] as Map;
      final spot = o['spot'];
      if (spot == 'enfrente') {
        final b = _ink(it.s as Sprite)!;
        if (it.left + b[0] < cam[0] || it.left + b[2] >= cam[0] + cam[2]) {
          breaches.add((
            at: at,
            rule: 'mamá at enfrente cut by the window',
            what: 'columns ${it.left + b[0]} to ${it.left + b[2]}',
          ));
        }
      }
      if (spot == 'puerta' || spot == 'pepe.puerta') {
        final n = hiddenOf[it] ?? 0;
        if (n > 0) {
          breaches.add((
            at: at,
            rule: 'a person at the door hidden',
            what: '$tag: $n px',
          ));
        }
      }
    }
    // a guagua that stops stands in the near lane
    final autos = (W['autos'] as Map).cast<String, dynamic>();
    final cerca = (p.lanes['cerca'].entra as List<double>)[1];
    for (final e in autos.entries) {
      final v = e.value as Map;
      if (v['vis'] == 0 || v['kind'] != 'guagua' || v['spot'] == null) continue;
      if (v['y'] != cerca) {
        breaches.add((
          at: at,
          rule: 'a guagua stops off the near lane',
          what: '${v['spot']} y ${v['y']}',
        ));
      }
    }
    // story 50: the hole shows while two things wait at the lane's ends
    final ends = (W['carriles'] as Map).values.where(
      (k) => autos[k] != null && (autos[k] as Map)['vis'] != 0,
    );
    final obrero = gente['obrero'] as Map?;
    if (jsTruthy(W['obra']) &&
        ends.length == 2 &&
        obrero != null &&
        obrero['vis'] != 0 &&
        obrero['spot'] == 'obrero.cubo') {
      final e = p.e as PpEngine;
      var hole = 0, shown = 0;
      for (var iy = 0; iy < 216; iy++) {
        for (var ix = cam[0].toInt(); ix < cam[0] + cam[2]; ix++) {
          final i = iy * 240 + ix;
          if (baked.zb[i] != baked.groundZ[i]) continue;
          final g = e.unproject(ix + .5, iy + .5);
          if (g.y < 1.8 || g.y > 3.8 || g.x < .4 || g.x > 2.8) continue;
          hole++;
          if (layer[i] >>> 24 == 0) shown++;
        }
      }
      if (hole > 0 && shown / hole < .45) {
        breaches.add((
          at: at,
          rule: 'the hole hidden',
          what: '$shown of $hole px show',
        ));
      }
    }
  }
}
