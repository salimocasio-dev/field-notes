// La ropa's rules (ropa-sheet.json's rules and checks, and page 13's "The sheet's rules hold in the scene"), checked
// on the real scene's frame at every act's end and at the story's end:
// - frog-seen: 0 px of the frog hidden by the live set (including swaying palm fronds: drawLeaves(0)), outside the
//   picture/window [22, 218), or under a nearer sprite (excluding his own held/fx overlays);
// - spots-in-view: every visible person, dog, look-alike child, and interactive small thing lies inside [22, 218) x [0, 216);
// - pieces-on-line: clothes/towels hanging on `cuerda1..5` have 0 px hidden by the live set/fronds or covered by another sprite;
// - things-afloat: things floating on `agua1..5` (or `farOut`) have 0 px hidden by the live set/fronds or covered by another sprite;
// - children: in story 80, visible look-alike children (`ninos1..4`) have 0 px outside the window or hidden by the live set;
// - plate-clear: in story 78, `plato` has 0 px hidden by the live set or covered by another sprite;
// - driver: when `guagua == 1`, `chofer` has 0 px outside the window, hidden by the live set, or covered by another sprite;
// - sprites-apart: no two visible characters overlap sideways unless their feet are 12 px or more apart up-down.
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/coqui_scenes.dart';

/// What went against a rule: when, which rule, the details.
typedef RopaBreach = ({String at, String rule, String what});

final double _t30 = math.tan(math.pi / 6);

/// Watches a real La ropa while a story plays: [wrap] its acts, then read [breaches] and [checked].
class RopaRules {
  RopaRules(this.scene) : _m = scene {
    if (scene.id != 'ropa') {
      throw StateError('RopaRules expects scene "ropa", got "${scene.id}"');
    }
  }

  final SetScene scene;
  final dynamic _m;

  static final Map<String, Float32List> _zb = {};
  static final Map<String, SetBakes> _bakes = {};

  /// Live depth after `drawLeaves(0)` (ropa-sheet.json `front.plane`: `window.DEPTH.live()`).
  Float32List _zbOf(String key) => _zb['${scene.id}:$key'] ??= () {
    final bakes = _bakes[scene.id] ??= SetBakes(scene);
    final baked = bakes.bakeKey(key);
    baked.restoreInto(bakes.engine);
    bakes.engine.drawLeaves(0);
    return Float32List.fromList(bakes.engine.zb);
  }();

  final List<RopaBreach> breaches = [];
  int checked = 0;

  void wrap() {
    final acts = scene.acts;
    for (final k in acts.keys.toList()) {
      final f = acts[k]!;
      acts[k] = (o) async {
        await f(o);
        if (!jsTruthy(o['suelto'])) check('after ${o['act'] ?? k}');
      };
    }
  }

  static final Expando<List<int>> _inkCache = Expando<List<int>>();

  static List<int>? _inkOf(Sprite s) {
    final had = _inkCache[s];
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
    final res = x1 < 0 ? const <int>[] : [x0, y0, x1, y1];
    _inkCache[s] = res;
    return res.isEmpty ? null : res;
  }

  double? _cachedS;
  double? _cachedBias;
  int? _cachedX0;

  static final Expando<int> _spriteIds = Expando<int>();
  static int _nextSpriteId = 1;
  static int _spriteId(Sprite s) => _spriteIds[s] ??= _nextSpriteId++;

  static final Map<String, List<({String rule, String what})>> _frameCache = {};

  static const Set<String> _inViewTags = {
    'coqui',
    'persona:abuela',
    'persona:luis',
    'persona:carmen',
    'persona:perro',
    'persona:chico_a',
    'persona:chico_b',
    'persona:chica_a',
    'persona:chica_b',
    'cosa:camisa',
    'cosa:pantalon',
    'cosa:vestido',
    'cosa:zapatos',
    'cosa:sombrero',
    'cosa:toalla',
    'cosa:chancletas',
    'cosa:gafas',
    'cosa:traje',
    'cosa:plato',
    'cosa:bolsa',
    'fx:caja',
    'fx:toalla_seca',
    'fx:chofer',
  };

  static const Set<String> _lineItems = {
    'cosa:camisa',
    'cosa:pantalon',
    'cosa:vestido',
    'cosa:toalla',
    'cosa:sombrero',
    'cosa:chancletas',
    'cosa:gafas',
    'cosa:traje',
    'fx:toalla_seca',
  };

  static const Set<String> _afloatItems = {
    'cosa:sombrero',
    'cosa:chancletas',
    'cosa:gafas',
    'cosa:traje',
    'cosa:toalla',
  };

  void check(String at) {
    final W = scene.host.W;
    checked++;
    final rawStory = W['story'];
    if (rawStory is! num) {
      breaches.add((
        at: at,
        rule: 'scene-state',
        what: 'missing story ($rawStory) in W',
      ));
      return;
    }
    final rawItems = (_m.placed(W, 0) as List);
    final setKey = scene.setKey(W);
    final story = rawStory.toInt();
    final gente = (W['gente'] as Map?) ?? const {};
    final ninos = (W['ninos'] as Map?) ?? const {};
    final cq = W['cq'] as Map?;
    final sig = StringBuffer()
      ..write(scene.id)
      ..write('|')
      ..write(setKey)
      ..write('|')
      ..write(story)
      ..write('|')
      ..write(W['guagua'])
      ..write('|')
      ..write(W['perroVis'])
      ..write('|')
      ..write(cq?['vis'])
      ..write('|')
      ..write(cq?['spot']);
    for (final k in const ['abuela', 'luis', 'carmen']) {
      final p = gente[k] as Map?;
      sig
        ..write('|')
        ..write(p?['vis'])
        ..write(':')
        ..write(p?['spot']);
    }
    for (final k in const ['chico_a', 'chico_b', 'chica_a', 'chica_b']) {
      sig
        ..write('|')
        ..write(ninos[k]);
    }
    for (final dynamic it in rawItems) {
      final s = it.s as Sprite;
      sig
        ..write(';')
        ..write(it.tag)
        ..write(',')
        ..write(it.spot)
        ..write(',')
        ..write(it.left)
        ..write(',')
        ..write(it.top)
        ..write(',')
        ..write(it.sy)
        ..write(',')
        ..write(it.d)
        ..write(',')
        ..write(_spriteId(s));
    }
    final key = sig.toString();
    final cached = _frameCache[key];
    if (cached != null) {
      for (final b in cached) {
        breaches.add((at: at, rule: b.rule, what: b.what));
      }
      return;
    }

    final localBreaches = <({String rule, String what})>[];
    void addBreach(String rule, String what) {
      localBreaches.add((rule: rule, what: what));
      breaches.add((at: at, rule: rule, what: what));
    }

    final items =
        <
          ({
            Sprite s,
            int left,
            int top,
            int right,
            int bottom,
            double sy,
            double d,
            String? tag,
            String? spot,
            bool flat,
            List<int>? ink,
          })
        >[
          for (final dynamic it in rawItems)
            (
              s: it.s as Sprite,
              left: it.left as int,
              top: it.top as int,
              right: (it.left as int) + (it.s as Sprite).w,
              bottom: (it.top as int) + (it.s as Sprite).h,
              sy: (it.sy as num).toDouble(),
              d: it.d as double,
              tag: it.tag as String?,
              spot: it.spot as String?,
              flat: it.flat as bool,
              ink: _inkOf(it.s as Sprite),
            ),
        ];
    final S = _cachedS ??= (_m.places.e.S as num).toDouble();
    final bias = _cachedBias ??= (_m.places.bias as num).toDouble();
    final x0 = _cachedX0 ??= ((_m.places.view('wide') as List)[0] as num)
        .toInt();
    final winR = x0 + 196;
    final zb = _zbOf(setKey);

    ({int hid, int cov, int out, Map<String, int> by, int total}) covOf(
      int idx, {
      bool Function(String? tag)? ignore,
    }) {
      final f = items[idx];
      final ink = f.ink;
      if (ink == null) {
        return (hid: 0, cov: 0, out: 0, by: const {}, total: 0);
      }
      var hid = 0, cov = 0, outPx = 0, total = 0;
      final by = <String, int>{};
      for (var y = ink[1]; y <= ink[3]; y++) {
        final Y = f.top + y;
        final plane = f.d + (f.sy - (Y + .5)) * _t30 / S;
        for (var x = ink[0]; x <= ink[2]; x++) {
          if (f.s.px[y * f.s.w + x] >>> 24 == 0) continue;
          total++;
          final X = f.left + x;
          if (X < x0 || X >= winR || Y < 0 || Y >= 216) {
            outPx++;
            continue;
          }
          if (zb[Y * 240 + X] > plane + bias) {
            hid++;
            continue;
          }
          String? winner;
          var best = plane + .001;
          for (var j = 0; j < items.length; j++) {
            if (j == idx) continue;
            final o = items[j];
            if (o.flat) continue;
            if (ignore != null && ignore(o.tag)) continue;
            if (X < o.left || X >= o.right || Y < o.top || Y >= o.bottom) {
              continue;
            }
            final ox = X - o.left, oy = Y - o.top;
            if (o.s.px[oy * o.s.w + ox] >>> 24 == 0) continue;
            final op = o.d + (o.sy - (Y + .5)) * _t30 / S;
            if (zb[Y * 240 + X] > op + bias) continue;
            if (op > best) {
              best = op;
              winner = o.tag ?? 'sprite';
            }
          }
          if (winner != null) {
            cov++;
            by[winner] = (by[winner] ?? 0) + 1;
          }
        }
      }
      return (hid: hid, cov: cov, out: outPx, by: by, total: total);
    }

    // 1. frog-seen: 0 px hidden by live set (including fronds), outside window, or under another sprite
    // Only ignore the frog's own held-item overlay (`held:coqui_*`), never props/fx like `fx:chofer` or `fx:toalla_seca`.
    final fi = items.indexWhere((it) => it.tag == 'coqui');
    if (fi >= 0) {
      final c = covOf(
        fi,
        ignore: (t) => t != null && t.startsWith('held:coqui_'),
      );
      if (c.hid > 0 || c.cov > 0 || c.out > 0) {
        addBreach(
          'frog-seen',
          'frog at ${(W['cq'] as Map?)?['spot']}: ${c.hid} hidden by set/fronds, ${c.cov} under ${c.by}, ${c.out} outside',
        );
      }
    }

    // 2. spots-in-view: every visible character and interactive small thing inside window [x0, winR) x [0, 216)
    for (final it in items) {
      if (it.tag == null || !_inViewTags.contains(it.tag)) continue;
      final ink = it.ink;
      if (ink == null) continue;
      final l = it.left + ink[0], r = it.left + ink[2];
      final t = it.top + ink[1], b = it.top + ink[3];
      if (l < x0 || r >= winR || t < 0 || b >= 216) {
        addBreach(
          'spots-in-view',
          '${it.tag} ink [$l..$r, $t..$b] out of window [$x0..${winR - 1}, 0..215]',
        );
      }
    }

    // 3. pieces-on-line: clothes/towels hanging on `cuerda1..5` (classified explicitly by spot, never by pixel row)
    for (var i = 0; i < items.length; i++) {
      final it = items[i];
      if (it.spot == null || !it.spot!.startsWith('cuerda')) continue;
      if (it.tag == null || !_lineItems.contains(it.tag)) {
        addBreach(
          'pieces-on-line',
          'unexpected line item tag ${it.tag} at ${it.spot}',
        );
        continue;
      }
      final c = covOf(i);
      if (c.hid > 0 || c.cov > 0 || c.out > 0) {
        addBreach(
          'pieces-on-line',
          '${it.tag}@${it.spot}: ${c.hid} hidden by set/fronds, ${c.cov} under ${c.by}, ${c.out} outside',
        );
      }
    }

    // 4. things-afloat: floating things (`agua1..5` / `farOut`, classified explicitly by spot)
    for (var i = 0; i < items.length; i++) {
      final it = items[i];
      if (it.spot == null ||
          (!it.spot!.startsWith('agua') && it.spot != 'farOut')) {
        continue;
      }
      if (it.tag == null || !_afloatItems.contains(it.tag)) {
        addBreach(
          'things-afloat',
          'unexpected afloat tag ${it.tag} at ${it.spot}',
        );
        continue;
      }
      final c = covOf(i);
      if (c.hid > 0 || c.cov > 0 || c.out > 0) {
        addBreach(
          'things-afloat',
          '${it.tag}@${it.spot}: ${c.hid} hidden by set/fronds, ${c.cov} under ${c.by}, ${c.out} outside',
        );
      }
    }

    // 5. children: in story 80, look-alike children at `ninos1..4` have 0 px hidden by live set or outside window
    if (story == 80) {
      for (var i = 0; i < items.length; i++) {
        final it = items[i];
        if (it.tag == null ||
            !const {
              'persona:chico_a',
              'persona:chico_b',
              'persona:chica_a',
              'persona:chica_b',
            }.contains(it.tag)) {
          continue;
        }
        final c = covOf(i);
        if (c.hid > 0 || c.out > 0) {
          addBreach(
            'children',
            '${it.tag}: ${c.hid} hidden by set, ${c.out} outside',
          );
        }
      }
    }

    // 6. plate-clear: in story 78, `cosa:plato` has 0 px hidden by set or covered by another sprite
    if (story == 78) {
      final pi = items.indexWhere((it) => it.tag == 'cosa:plato');
      if (pi < 0) {
        addBreach('plate-clear', 'cosa:plato missing in story 78');
      } else {
        final c = covOf(
          pi,
          ignore: (t) => t == 'fx:pano_plato' || t == 'fx:nube',
        );
        if (c.hid > 0 || c.cov > 0 || c.out > 0) {
          addBreach(
            'plate-clear',
            'plato: ${c.hid} hidden by set, ${c.cov} under ${c.by}, ${c.out} outside',
          );
        }
      }
    }

    // 7. driver: when guagua = 1, `fx:chofer` has 0 px hidden by set, outside window, or under another sprite
    if (W['guagua'] == 1) {
      final di = items.indexWhere((it) => it.tag == 'fx:chofer');
      if (di < 0) {
        addBreach('driver', 'fx:chofer missing when guagua == 1');
      } else {
        final c = covOf(di);
        if (c.hid > 0 || c.cov > 0 || c.out > 0) {
          addBreach(
            'driver',
            'chofer: ${c.hid} hidden by set, ${c.cov} under ${c.by}, ${c.out} outside',
          );
        }
      }
    }

    // 8. sprites-apart: character pairs checked as ropa-sheet.json
    final chars = <({String id, String spot, int cx, int sy, int w})>[];
    for (final k in const ['abuela', 'luis', 'carmen']) {
      final p = gente[k];
      if (p is! Map) continue;
      final vis = p['vis'];
      if (vis != 0 && vis != 1) {
        addBreach('scene-state', 'gente[$k].vis is $vis (expected 0 or 1)');
      }
      if (vis != 1) continue;
      final at = _m.places.atWorld(p['x'] as num, p['y'] as num, p['z'] as num);
      chars.add((
        id: k,
        spot: (p['spot'] as String?) ?? k,
        cx: ((at.sx as num) + 0.5).floor(),
        sy: ((at.sy as num) + 0.5).floor(),
        w: 24,
      ));
    }
    for (final en in ninos.entries) {
      final cid = '${en.key}';
      final spot = en.value;
      if (spot is! String || !_m.places.has(spot)) {
        addBreach('scene-state', 'ninos[$cid] spot is $spot (invalid)');
        continue;
      }
      final at = _m.places.at(spot);
      chars.add((
        id: cid,
        spot: spot,
        cx: ((at.sx as num) + 0.5).floor(),
        sy: ((at.sy as num) + 0.5).floor(),
        w: 24,
      ));
    }
    if (W['perroVis'] == 1) {
      final pi = items.indexWhere((it) => it.tag == 'persona:perro');
      if (pi >= 0) {
        final it = items[pi];
        chars.add((
          id: 'perro',
          spot: 'perro',
          cx: it.left + 15,
          sy: it.sy.round(),
          w: 28,
        ));
      }
    }
    if (cq is Map && jsTruthy(cq['vis'])) {
      final spot = (cq['spot'] as String?) ?? 'coqui';
      final at = _m.places.has(spot) ? _m.places.at(spot) : null;
      if (at != null) {
        chars.add((
          id: 'coqui',
          spot: spot,
          cx: ((at.sx as num) + 0.5).floor(),
          sy: ((at.sy as num) + 0.5).floor(),
          w: 32,
        ));
      }
    }
    for (var i = 0; i < chars.length; i++) {
      for (var j = i + 1; j < chars.length; j++) {
        final a = chars[i], b = chars[j];
        final across = (a.cx - b.cx).abs();
        final down = (a.sy - b.sy).abs();
        final need = (a.w + b.w) ~/ 2;
        if (across < need && down < 12) {
          addBreach(
            'sprites-apart',
            '${a.id}@${a.spot} ~ ${b.id}@${b.spot}: $across across (need $need), $down down (need 12)',
          );
        }
      }
    }

    _frameCache[key] = localBreaches;
  }
}
