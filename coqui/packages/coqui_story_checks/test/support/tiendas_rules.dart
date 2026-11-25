// Las tiendas' rules (tiendas-sheet.json's rules and checks, and page 13's "The sheet's rules hold in the scene"),
// checked on the real scene's frame at the end of every act that is waited for (an act started with `suelto: 1` is checked
// at the `ya` that waits for it) and at the story's end. What is checked:
// - the frog is never behind a grown-up (frog-seen): none of the frog's pixels is hidden, in the frame as composed, by a
//   grown-up's; the set hides none of him but on the horse, where its own neck may hide 30 (HORSE_NECK); a child, the
//   stroller or a small thing hide at most 40 of them (POOL);
// - two sprites that stand together never overlap unless their feet are 12 px apart up-down (sprites-apart: the frog 32
//   wide, a grown-up 24, a child 24, the stroller 24; the feet's spot in the middle of the bottom edge);
// - every person, the stroller and the frog stand inside the picture, the feet's column inside the view's window
//   (in-view);
// - nobody stands on the street; on the kerb only Luis and the frog sitting (bordillo1, bordillo2) (street-clear);
// - nobody covers a sign (signs-clear): no pixel of the sprite layer lies on the board of a front's sign;
// - who stands at a door is not hidden by the front's wall (door-front).
// Places of the sheet that break a rule by themselves are [known], not breaches (page 13 lists them for the content
// lane): the frog at coqui.puerta_banco and coqui.puerta_farmacia is hidden by the seat (the sheet's own info-people:
// 205 and 51 of his 536 pixels), and story 56's game puts the frog at the farmacia's door (puerta_farmacia) while abuela
// sits on the seat (banco_acera): 26 px across, 10 down.
// Besides the rules, [overDepth] counts the times the frog is drawn over a grown-up who stands nearer than he does, and
// [hiddenMost] is the most pixels of the frog the set hid at any check.
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/coqui_scenes.dart';

/// What went against a rule: when, which rule, the details.
typedef TiendasBreach = ({String at, String rule, String what});

/// Watches a real Las tiendas while a story plays: [wrap] its acts, then read [breaches] and [checked].
class TiendasRules {
  TiendasRules(this.scene) : _m = scene;

  /// The scene (Las tiendas'; its own members, `placed`, `compose`, `places`, `frogSpot`, are reached untyped: a feature
  /// may not import a package's src/).
  final SetScene scene;
  final dynamic _m;

  static final Map<String, BakedSet> _baked = {};
  static SetBakes? _bakes;
  BakedSet _bakeOf(String key) =>
      _baked[key] ??= (_bakes ??= SetBakes(scene)).bakeKey(key);

  final List<TiendasBreach> breaches = [];

  /// The places of the sheet that break a rule by themselves (see the file's head), when they happen.
  final List<TiendasBreach> known = [];

  static const Set<String> _knownPairs = {
    'persona:abuela@banco_acera ~ coqui@puerta_farmacia',
  };
  static const Set<String> _knownHidden = {
    'coqui.puerta_banco',
    'coqui.puerta_farmacia',
  };

  /// Where the frog was drawn over a grown-up nearer than he (not a breach: see the file's head).
  final List<String> overDepth = [];

  /// The most pixels of the frog the set hid at one check (away from the known places).
  int hiddenMost = 0;
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
      tag != null && tag.startsWith('persona:') && tag != 'persona:luis';

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

  static Uint8List? _signs;
  static final List<String> _signNames = [];

  // the picture's pixels on each sign's board (1 + the front's place in fronts), 0 elsewhere
  static Uint8List _signMask(SceneSheet sheet, PpEngine en) {
    final m = Uint8List(240 * 216);
    final fronts = (sheet.extras['fronts'] as Map).cast<String, dynamic>();
    _signNames.clear();
    for (final e in fronts.entries) {
      _signNames.add(e.key);
      final sg = (e.value as Map)['sign'] as Map;
      final xs = (sg['x'] as List).cast<num>(),
          zs = (sg['z'] as List).cast<num>(),
          sy0 = (sg['y'] as num).toDouble();
      for (var Y = 0; Y < 216; Y++) {
        for (var X = 0; X < 240; X++) {
          final x = sy0 + (X + .5 - en.OX) / en.S * en.R2;
          final z = ((x + sy0) / en.R2 * .5 - (Y + .5 - en.OY) / en.S) / en.COS;
          if (x >= xs[0] && x <= xs[1] && z >= zs[0] && z <= zs[1]) {
            m[Y * 240 + X] = _signNames.length;
          }
        }
      }
    }
    return m;
  }

  /// Checks the frame of the scene's world now.
  void check(String at) {
    final W = scene.host.W;
    checked++;
    final p = _m.places;
    final fila = W['fila'] == 'altos' ? 'altos' : 'tiendas';
    final sheet = p.of(fila) as SceneSheet;
    final en = p.engineOf(fila) as PpEngine;
    final baked = _bakeOf(scene.setKey(W));
    final layer = Uint32List(240 * 216),
        lz = Float32List(240 * 216),
        isV = Uint8List(240 * 216);
    var bySet = 0, byGrown = 0, byOther = 0, frogPx = 0;
    final hiddenOf = <dynamic, Map<String, int>>{};
    _m.compose(
      W,
      0,
      layer,
      lz,
      isV,
      baked.zb,
      hidden: (dynamic it, int i, String why) {
        final h = hiddenOf[it] ??= {};
        h[why] = (h[why] ?? 0) + 1;
        if (it.tag != 'coqui') return;
        if (why == 'set') {
          bySet++;
        } else if (why == 'grown') {
          byGrown++;
        } else {
          byOther++;
        }
      },
    );
    final items = (_m.placed(W, 0) as List).cast<dynamic>();
    final frog = items.where((i) => i.tag == 'coqui').toList();
    final frogSpot = _m.frogSpot(W) as String? ?? '';
    for (final f in frog) {
      final s = f.s as Sprite;
      frogPx += s.px.where((c) => c >>> 24 != 0).length;
    }
    if (frog.isNotEmpty) {
      if (byGrown > 0) {
        breaches.add((
          at: at,
          rule: 'frog behind a grown-up',
          what: '$byGrown px of $frogPx',
        ));
      }
      final onHorse = frogSpot == 'caballito';
      if (_knownHidden.contains(frogSpot) && bySet > 0) {
        known.add((
          at: at,
          rule: 'frog hidden by the set',
          what: '$frogSpot: $bySet px of $frogPx',
        ));
      } else {
        hiddenMost = math.max(hiddenMost, bySet);
        if (bySet > (onHorse ? 30 : 0)) {
          breaches.add((
            at: at,
            rule: 'frog hidden by the set',
            what:
                '${frogSpot.isEmpty ? 'on his way' : frogSpot}: $bySet px of $frogPx',
          ));
        }
      }
      if (byOther > 40) {
        breaches.add((
          at: at,
          rule: 'frog hidden by a child, the stroller or a thing (more than 40 px)',
          what: '$byOther px of $frogPx',
        ));
      }
      // the frog drawn over a grown-up who stands nearer
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
    // the sprites that stand: the people and the stroller on their spots (not on their way), the frog on one of his
    final cam = (p.view(fila) as List).cast<num>();
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
      } else if (tag.startsWith('persona:') || tag == 'cochecito') {
        final o = tag == 'cochecito'
            ? (W['coche'] as Map)
            : gente[tag.substring(8)] as Map;
        final spot = o['spot'];
        if (spot is! String || !p.has(spot, fila)) continue;
        final w = p.world(spot, fila) as List<double>;
        if (w[0] != o['x'] || w[1] != o['y']) continue; // on the way
        final a = p.atWorld(o['x'], o['y'], o['z'] ?? 0, fila);
        standing.add((tag: tag, sx: a.sx, sy: a.sy, w: 24, spot: spot));
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
          final pair2 = '${b.tag}@${b.spot} ~ ${a.tag}@${a.spot}';
          (_knownPairs.contains(pair) || _knownPairs.contains(pair2)
                  ? known
                  : breaches)
              .add((
                at: at,
                rule: 'two sprites overlap',
                what: '$pair: $across px across, $down down',
              ));
        }
      }
    }
    // inside the picture and the view; nobody on the street, on the kerb only who sits there
    for (final s in standing) {
      if (s.sx < cam[0] || s.sx >= cam[0] + cam[2] || s.sy > 216) {
        breaches.add((
          at: at,
          rule: 'outside the view',
          what: '${s.tag} at column ${s.sx.round()}, row ${s.sy.round()}',
        ));
      }
      final w = p.world(s.spot, fila) as List<double>;
      if (w[1] > 2.6 && s.spot != 'bordillo1' && s.spot != 'bordillo2') {
        breaches.add((
          at: at,
          rule: 'somebody on the kerb or the street',
          what: '${s.tag} at ${s.spot} (y ${w[1]})',
        ));
      }
    }
    // who stands at a door is not hidden by the front's wall
    for (final it in items) {
      final tag = it.tag as String?;
      if (tag == null || !tag.startsWith('persona:')) continue;
      final o = gente[tag.substring(8)] as Map;
      final spot = o['spot'];
      if (spot is! String || !spot.startsWith('puerta_')) continue;
      if (o['x'] != (p.world(spot, fila) as List)[0]) continue;
      final hid = hiddenOf[it]?['set'] ?? 0;
      // the post box stands in front of the correo's door (the sheet's door-front: 106 of abuela's pixels there)
      if (hid > (spot == 'puerta_correo' ? 106 : 0)) {
        breaches.add((
          at: at,
          rule: 'a person at a door hidden',
          what: '$tag at $spot: $hid px',
        ));
      }
    }
    // nobody covers a sign: the layer's pixels on the boards of the four signs (fronts.<k>.sign, on the wall's plane)
    if (fila == 'tiendas') {
      final mask = _signs ??= _signMask(sheet, en);
      var covered = 0;
      final by = <String>{};
      for (var i = 0; i < mask.length; i++) {
        if (mask[i] == 0 || layer[i] >>> 24 == 0) continue;
        covered++;
        by.add(_signNames[mask[i] - 1]);
      }
      if (covered > 0) {
        breaches.add((
          at: at,
          rule: 'a sign covered',
          what: '$covered px of the signs of ${by.join(', ')}',
        ));
      }
    }
  }
}
