// El cruce's rules (cruce-sheet.json's rules and checks, and page 13's "The sheet's rules hold in the scene"), checked on
// the real scene's frame at the end of every act that is waited for (an act started with `suelto: 1` is checked at the
// `ya` that waits for it) and at the story's end. What is checked:
// - the frog is never behind a grown-up: none of the frog's pixels is hidden, in the frame as composed, by a grown-up's
//   (frog-seen), and the set, the children, the dog and the things hide at most 40 of them (the sheet's check frog-seen
//   allows "a nearer dog aside"); at detras_canelo 60% or more of him shows (frog-places);
// - two sprites that stand together never overlap unless their feet are 12 px apart up-down (sprites-apart: the frog 32
//   wide, a grown-up 24, a child 24, the dog 28, the feet's spot in the middle of the bottom edge), but for the pairs the
//   sheet does not count: one of the back row (fila_atras1 to 3, bebe_alto) against one on the seat or the ground in
//   front, the frog in the gap (hueco, lado_abuela) against abuela or Luis on the seat;
// - every person and the frog standing has the feet's column inside the window of the view shown (spots-in-view);
// - while the back row stands, the head of each of them shows 100 px or more (family-heads: the top 14 drawn rows);
// - a person at centro covers none of the stripes' lower half (centro-stripes: rows 140 to 145, columns 63 to 123).
// Two pairs of the sheet's own places overlap and the sheet's sprites-apart check never met them (its moments do not
// hold them): the frog at tras_papa behind papá at papa_camara (the script's start: 0 across, 10 down) and the frog at
// delante_canelo with Canelo at suelo_canelo (0 across, 9 down). They are [known], not breaches; so is what the set hides
// of the frog at tras_papa (the sheet: "info, not a check", 57 px). Page 13 lists them for the content lane.
// Besides the rules, [overDepth] counts the times the frog is drawn over a grown-up who stands nearer than he does (the
// scene keeps him seen).
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/coqui_scenes.dart';

/// What went against a rule: when, which rule, the details.
typedef CruceBreach = ({String at, String rule, String what});

/// Watches a real El cruce while a story plays: [wrap] its acts, then read [breaches] and [checked].
class CruceRules {
  CruceRules(this.scene) : _m = scene;

  /// The scene (El cruce's; its own members, `placed`, `compose`, `places`, `frogSpotOf`, are reached untyped: a
  /// feature may not import a package's src/).
  final SetScene scene;
  final dynamic _m;

  static final Map<String, BakedSet> _baked = {};
  static SetBakes? _bakes;
  BakedSet _bakeOf(String key) =>
      _baked[key] ??= (_bakes ??= SetBakes(scene)).bakeKey(key);

  final List<CruceBreach> breaches = [];

  /// The overlaps of the sheet's own places that its checks never met (see the file's head), when they happen.
  final List<CruceBreach> known = [];

  static const Set<String> _knownPairs = {
    'persona:papa@papa_camara ~ coqui@tras_papa',
    'persona:perro@suelo_canelo ~ coqui@delante_canelo',
  };

  static const Set<String> _atras = {
    'fila_atras1',
    'fila_atras2',
    'fila_atras3',
    'bebe_alto',
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

  static const Set<String> _young = {
    'persona:luis',
    'persona:carmen',
    'persona:bebe',
    'persona:perro',
  };

  static bool _adult(String? tag) =>
      tag != null && tag.startsWith('persona:') && !_young.contains(tag);

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
        isG = Uint8List(240 * 216);
    var byGrown = 0, byOther = 0, frogPx = 0;
    _m.compose(
      W,
      0,
      layer,
      lz,
      isG,
      baked.zb,
      hidden: (dynamic it, int i, String why) {
        if (it.tag != 'coqui') return;
        if (why == 'sprite' && isG[i] == 2) {
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
    final q0 = W['cq'] as Map;
    var frogSpot = '';
    for (final e in scene.lugar.entries) {
      if (e.value[0] == q0['x'] && e.value[1] == q0['y']) {
        frogSpot = (_m.frogSpotOf(e.key) as String?) ?? e.key;
      }
    }
    if (frog.isNotEmpty) {
      if (byGrown > 0) {
        breaches.add((
          at: at,
          rule: 'frog behind a grown-up',
          what: '$byGrown px of $frogPx',
        ));
      }
      if (frogSpot == 'tras_papa') {
        if (byOther > 40) {
          known.add((
            at: at,
            rule: 'frog hidden at tras_papa',
            what: '$byOther px of $frogPx',
          ));
        }
      } else if (frogSpot == 'detras_canelo') {
        if (byOther > frogPx * .4) {
          breaches.add((
            at: at,
            rule: 'frog at detras_canelo less than 60% seen',
            what: '$byOther px hidden of $frogPx',
          ));
        }
      } else if (byOther > 40) {
        breaches.add((
          at: at,
          rule: 'frog hidden by the set, a child or a thing (more than 40 px)',
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
    // sprites apart: people and the frog standing at their spots (not on their way)
    final cam = scene.host.cam;
    final standing = <({String tag, num sx, num sy, int w, String spot})>[];
    final gente = (W['gente'] as Map).cast<String, dynamic>();
    for (final it in items) {
      final tag = it.tag as String?;
      if (tag == null) continue;
      if (tag == 'coqui') {
        if (frogSpot.isEmpty) continue;
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
        if (spot is! String || !p.has(spot)) continue;
        final w = p.world(spot) as List<double>;
        if (w[0] != o['x'] || w[1] != o['y']) continue; // on the way
        final at = p.atWorld(o['x'], o['y'], o['z']);
        final width = id == 'perro' ? 28 : 24;
        standing.add((tag: tag, sx: at.sx, sy: at.sy, w: width, spot: spot));
      }
    }
    bool exempt(
      ({String tag, num sx, num sy, int w, String spot}) a,
      ({String tag, num sx, num sy, int w, String spot}) b,
    ) {
      if (_atras.contains(a.spot) != _atras.contains(b.spot)) return true;
      bool gap(String t, String s) =>
          t == 'coqui' && (s == 'hueco' || s == 'lado_abuela');
      bool sits(String s) => s == 'asiento1' || s == 'asiento2';
      return (gap(a.tag, a.spot) && sits(b.spot)) ||
          (gap(b.tag, b.spot) && sits(a.spot));
    }

    for (var i = 0; i < standing.length; i++) {
      for (var j = i + 1; j < standing.length; j++) {
        final a = standing[i], b = standing[j];
        final across = (a.sx.round() - b.sx.round()).abs(),
            down = (a.sy.round() - b.sy.round()).abs();
        if (across < (a.w + b.w) / 2 && down < 12 && !exempt(a, b)) {
          final pair = '${a.tag}@${a.spot} ~ ${b.tag}@${b.spot}';
          final pair2 = '${b.tag}@${b.spot} ~ ${a.tag}@${a.spot}';
          final isKnown =
              _knownPairs.contains(pair) || _knownPairs.contains(pair2);
          (isKnown ? known : breaches).add((
            at: at,
            rule: 'two sprites overlap',
            what: '$pair: $across px across, $down down',
          ));
        }
      }
    }
    // inside the picture and the view shown
    for (final s in standing) {
      if (s.sx < cam[0] || s.sx >= cam[0] + cam[2] || s.sy > 216) {
        breaches.add((
          at: at,
          rule: 'outside the view',
          what:
              '${s.tag}@${s.spot} at column ${s.sx.round()}, row ${s.sy.round()}',
        ));
      }
    }
    // the back row's heads show; nobody at centro on the stripes' lower half
    for (final it in items) {
      final tag = it.tag as String?;
      if (tag == null || !tag.startsWith('persona:')) continue;
      final o = gente[tag.substring(8)] as Map;
      final spot = o['spot'];
      final s = it.s as Sprite;
      if (spot == 'fila_atras1' ||
          spot == 'fila_atras2' ||
          spot == 'fila_atras3') {
        final b = _ink(s)!;
        var shown = 0, all = 0;
        for (var y = b[1]; y < b[1] + 14 && y < s.h; y++) {
          for (var x = 0; x < s.w; x++) {
            final c = s.px[y * s.w + x];
            if (c >>> 24 == 0) continue;
            final X = it.left + x, Y = it.top + y;
            if (X < 0 || Y < 0 || X >= 240 || Y >= 216) continue;
            all++;
            if (layer[Y * 240 + X] == c) shown++;
          }
        }
        if (shown < math.min(100, all)) {
          breaches.add((
            at: at,
            rule: 'a head of the back row hidden',
            what: '$tag at $spot: $shown of $all px show',
          ));
        }
      }
      if (spot == 'centro') {
        var on = 0;
        for (var y = 0; y < s.h; y++) {
          final Y = it.top + y;
          if (Y < 140 || Y > 145) continue;
          for (var x = 0; x < s.w; x++) {
            final X = it.left + x;
            if (X < 63 || X > 123 || s.px[y * s.w + x] >>> 24 == 0) continue;
            on++;
          }
        }
        if (on > 0) {
          breaches.add((
            at: at,
            rule: 'a person at centro on the stripes',
            what: '$tag: $on px',
          ));
        }
      }
    }
  }
}
