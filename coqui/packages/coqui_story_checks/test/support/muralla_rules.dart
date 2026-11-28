// La muralla's rules (muralla-sheet.json's rules and checks, and page 13's "The sheet's rules hold in the scene"),
// checked on the real scene's frame at every act's end and at the story's end:
// - frog-seen: when cq.vis is truthy, a `coqui` item exists with 0 px hidden by the set, outside [22, 218) x [0, 216),
//   or under a nearer sprite;
// - spots-in-view: every visible person, frog, and interactive cosa:* sprite lies inside [22, 218) x [0, 216);
// - heads-clear: everyone sitting on the bench (`banco1..banco4`) has top 14 drawn rows whole in view with 0 hid/cov;
// - lanterns-clear: visible `farol1..3` have 0 hid, 0 cov, 0 out;
// - doors-clear: closed sentry doors (`puerta_roja`, `puerta_azul`) have 0 sprite px covering their boxes; anyone
//   inside `dentro_roja`/`dentro_azul` starts 2 px below door top and has head (top 14 drawn rows) inside the box;
// - candle-clear: in story 118, `vela` has 0 hid, 0 cov, 0 out;
// - table-clear: in stories 118 & 119, visible table items (`jugo`, `plato`, `silla`, `guitarra`, `sombrero`, `bolsa`,
//   `caja`, `libro`) have 0 hid, 0 cov, 0 out;
// - guagua-clear: in story 119, `guagua` has 0 hid, 0 cov, 0 out;
// - camera-clear: in story 117, `camara` has 0 hid, 0 cov, 0 out;
// - end-clear: in story 119 final (`pretil*`), grown-ups at parapet have 0 px in guagua box and bench guest is head-clear;
// - steps-clear: no visible character stands inside the steps hole (`u 2.2..3.7, v 6.2..8.4`);
// - sprites-apart: no two visible characters overlap sideways (`24 px` across people, `28 px` with frog) unless feet
//   are `12 px` or more apart vertically.
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/coqui_scenes.dart';

const List<String> _murallaPersonas = [
  'abuela',
  'abuelo',
  'luis',
  'carmen',
  'musico1',
  'musico2',
  'pepe',
  'maestra',
  'piraguero',
  'senor',
  'senora',
];

const Set<String> _benchSpots = {'banco1', 'banco2', 'banco3', 'banco4'};

const Set<String> _tableTags = {
  'cosa:jugo',
  'cosa:plato',
  'cosa:silla',
  'cosa:guitarra',
  'cosa:sombrero',
  'cosa:bolsa',
  'cosa:caja',
  'cosa:libro',
};

const Set<String> _inViewTags = {
  'coqui',
  'cosa:farol1',
  'cosa:farol2',
  'cosa:farol3',
  'cosa:camara',
  'cosa:vela',
  'cosa:guagua',
  ..._tableTags,
  'persona:abuela',
  'persona:abuelo',
  'persona:luis',
  'persona:carmen',
  'persona:musico1',
  'persona:musico2',
  'persona:pepe',
  'persona:maestra',
  'persona:piraguero',
  'persona:senor',
  'persona:senora',
};

/// What went against a rule: when, which rule, the details.
typedef MurallaBreach = ({String at, String rule, String what});

final double _t30 = math.tan(math.pi / 6);

/// Watches a real La muralla while a story plays: [wrap] its acts, then read [breaches] and [checked].
class MurallaRules {
  MurallaRules(this.scene) : _m = scene {
    if (scene.id != 'muralla') {
      throw StateError(
        'MurallaRules expects scene "muralla", got "${scene.id}"',
      );
    }
  }

  final SetScene scene;
  final dynamic _m;

  static final Map<String, Float32List> _zb = {};
  static final Map<String, SetBakes> _bakes = {};

  Float32List _zbOf(String key) => _zb['${scene.id}:$key'] ??= () {
    final bakes = _bakes[scene.id] ??= SetBakes(scene);
    final baked = bakes.bakeKey(key);
    return Float32List.fromList(baked.zb);
  }();

  final List<MurallaBreach> breaches = [];
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
  double? _cachedR2;
  double? _cachedBias;
  int? _cachedX0;

  static final Expando<int> _spriteIds = Expando<int>();
  static int _nextSpriteId = 1;
  static int _spriteId(Sprite s) => _spriteIds[s] ??= _nextSpriteId++;

  static const int _maxCacheEntries = 4096;
  static final Map<String, List<({String rule, String what})>> _frameCache = {};

  void check(String at) {
    final w = scene.host.W;
    checked++;
    final rawStory = w['story'];
    if (rawStory is! num) {
      breaches.add((
        at: at,
        rule: 'scene-state',
        what: 'missing story ($rawStory) in W',
      ));
      return;
    }
    final story = rawStory.toInt();
    final key = scene.setKey(w);
    final S = _cachedS ??= scene.projection.S;
    final r2 = _cachedR2 ??= scene.projection.R2;
    final bias = _cachedBias ??= _m.places.bias as double;
    final x0 = _cachedX0 ??= ((_m.places.view('wide') as List)[0] as num)
        .toInt();
    final x1 = x0 + 196;

    final list = (_m.placed(w, 0) as List);
    final gente = (w['gente'] as Map?) ?? const {};
    final cq = (w['cq'] as Map?)?.cast<String, dynamic>();
    final cqVis = cq != null && jsTruthy(cq['vis']);
    final cqSpot = (cq?['spot'] as String?) ?? '';
    final redOpen = jsTruthy(w['redDoorOpen']);
    final blueOpen = jsTruthy(w['blueDoorOpen']);

    final keyBuf = StringBuffer()
      ..write(key)
      ..write('|')
      ..write(story)
      ..write('|')
      ..write(redOpen ? 1 : 0)
      ..write(blueOpen ? 1 : 0)
      ..write(jsTruthy(w['guaguaGone']) ? 1 : 0)
      ..write('|')
      ..write(cqVis ? '$cqSpot:${cq['x']},${cq['y']},${cq['dy']}' : '0');
    for (final k in _murallaPersonas) {
      final p = gente[k] as Map?;
      if (p == null) continue;
      keyBuf
        ..write('|')
        ..write(k)
        ..write('=')
        ..write(p['vis'])
        ..write(':')
        ..write(p['spot'])
        ..write(':')
        ..write(p['pose'])
        ..write(':')
        ..write(p['x'])
        ..write(',')
        ..write(p['y'])
        ..write(',')
        ..write(p['z']);
    }
    for (final dynamic it in list) {
      keyBuf
        ..write(';')
        ..write(it.tag ?? '')
        ..write('@')
        ..write(_spriteId(it.s as Sprite))
        ..write(',')
        ..write(it.left)
        ..write(',')
        ..write(it.top)
        ..write(',')
        ..write(it.sy)
        ..write(',')
        ..write(it.dy)
        ..write(',')
        ..write((it.d as double).toStringAsFixed(4))
        ..write(',')
        ..write((it.overlay as bool) ? '1' : '0')
        ..write(',')
        ..write(it.clipBox ?? '');
    }
    final cacheKey = keyBuf.toString();
    final cached = _frameCache[cacheKey];
    if (cached != null) {
      for (final b in cached) {
        breaches.add((at: at, rule: b.rule, what: b.what));
      }
      return;
    }

    final frameBreaches = <({String rule, String what})>[];
    void fail(String rule, String what) =>
        frameBreaches.add((rule: rule, what: what));

    final zb = _zbOf(key);
    const w0 = 240, h0 = 216;
    final topZ = Float32List(w0 * h0)..fillRange(0, w0 * h0, -1e9);
    final topIdx = Int32List(w0 * h0)..fillRange(0, w0 * h0, -1);

    for (var idx = 0; idx < list.length; idx++) {
      final dynamic it = list[idx];
      final sp = it.s as Sprite;
      final left = it.left as int, top = it.top as int;
      final sy = it.sy as num;
      final d = it.d as double;
      final dy = it.dy as int;
      final cb = (it.clipBox as List<int>?);
      final overlay = it.overlay as bool;
      for (var py = 0; py < sp.h; py++) {
        final Y = top + py;
        if (Y < 0 || Y >= h0) continue;
        if (cb != null && (Y < cb[1] || Y >= cb[1] + cb[3])) continue;
        final plane = overlay ? d : d + (sy - ((Y - dy) + .5)) * _t30 / S;
        final row = Y * w0, srow = py * sp.w;
        for (var px = 0; px < sp.w; px++) {
          if (sp.px[srow + px] >>> 24 == 0) continue;
          final X = left + px;
          if (X < 0 || X >= w0) continue;
          if (cb != null && (X < cb[0] || X >= cb[0] + cb[2])) continue;
          final i = row + X;
          if (!overlay && zb[i] > plane + bias) continue;
          if (topZ[i] <= plane + .001) {
            topZ[i] = plane;
            topIdx[i] = idx;
          }
        }
      }
    }

    ({int hid, int cov, int out, String by, int count}) covOf(
      int idx, {
      int? maxRowsFromTop,
      bool Function(String? tag)? ignore,
    }) {
      final dynamic it = list[idx];
      final sp = it.s as Sprite;
      final left = it.left as int, top = it.top as int;
      final sy = it.sy as num;
      final d = it.d as double;
      final dy = it.dy as int;
      final cb = it.clipBox as List<int>?;
      final overlay = it.overlay as bool;
      final ink = _inkOf(sp);
      if (ink == null) return (hid: 0, cov: 0, out: 0, by: '', count: 0);
      final pyEnd = maxRowsFromTop == null
          ? sp.h
          : math.min(sp.h, ink[1] + maxRowsFromTop);
      var hid = 0, cov = 0, out = 0, count = 0;
      final by = <String, int>{};
      for (var py = ink[1]; py < pyEnd; py++) {
        final Y = top + py;
        final plane = overlay ? d : d + (sy - ((Y - dy) + .5)) * _t30 / S;
        for (var px = ink[0]; px <= ink[2]; px++) {
          if (sp.px[py * sp.w + px] >>> 24 == 0) continue;
          final X = left + px;
          if (cb != null &&
              (X < cb[0] ||
                  X >= cb[0] + cb[2] ||
                  Y < cb[1] ||
                  Y >= cb[1] + cb[3])) {
            continue;
          }
          count++;
          if (X < x0 || X >= x1 || Y < 0 || Y >= h0) {
            out++;
            continue;
          }
          final i = Y * w0 + X;
          if (!overlay && zb[i] > plane + bias) {
            hid++;
          } else if (topIdx[i] != idx) {
            final wIdx = topIdx[i];
            final wt = wIdx >= 0 ? list[wIdx].tag as String? : null;
            if (ignore != null && ignore(wt)) continue;
            cov++;
            by['$wt'] = (by['$wt'] ?? 0) + 1;
          }
        }
      }
      return (hid: hid, cov: cov, out: out, by: '$by', count: count);
    }

    int boxCoveredBy(List<int> b) {
      var cov = 0;
      for (var y = math.max(0, b[1]); y < math.min(h0, b[1] + b[3]); y++) {
        for (var x = math.max(x0, b[0]); x < math.min(x1, b[0] + b[2]); x++) {
          final wIdx = topIdx[y * w0 + x];
          if (wIdx >= 0) {
            final t = list[wIdx].tag as String?;
            if (t != null && (t.startsWith('persona:') || t == 'coqui')) cov++;
          }
        }
      }
      return cov;
    }

    // 1. frog-seen
    if (cqVis) {
      final fIdx = list.indexWhere((it) => it.tag == 'coqui');
      if (fIdx < 0) {
        fail('frog-seen', 'cq.vis is truthy but no coqui item placed');
      } else {
        final r = covOf(fIdx);
        if (r.hid > 0 || r.cov > 0 || r.out > 0) {
          fail(
            'frog-seen',
            'coqui at $cqSpot: hid=${r.hid} cov=${r.cov} (${r.by}) out=${r.out}',
          );
        }
      }
    }

    // 2. spots-in-view
    for (var idx = 0; idx < list.length; idx++) {
      final dynamic it = list[idx];
      final tag = it.tag as String?;
      if (tag == null || !_inViewTags.contains(tag)) continue;
      final cb = it.clipBox as List<int>?;
      if (cb != null) continue;
      final ink = _inkOf(it.s as Sprite);
      if (ink == null) continue;
      final l = (it.left as int) + ink[0], r = (it.left as int) + ink[2];
      final t = (it.top as int) + ink[1], b = (it.top as int) + ink[3];
      if (l < x0 || r >= x1 || t < 0 || b >= h0) {
        fail(
          'spots-in-view',
          '$tag [$l..$r, $t..$b] outside [$x0..${x1 - 1}, 0..215]',
        );
      }
    }

    // 3. heads-clear (everyone seated on bench)
    for (final k in _murallaPersonas) {
      final p = gente[k] as Map?;
      if (p == null || !jsTruthy(p['vis'])) continue;
      final sp = p['spot'] as String?;
      if (sp == null || !_benchSpots.contains(sp)) continue;
      final idx = list.indexWhere((it) => it.tag == 'persona:$k');
      if (idx < 0) {
        fail('heads-clear', 'visible seated $k at $sp has no sprite');
        continue;
      }
      // In story 119 all three hanging lanterns remain lit until the final apaga119 while guests sit on the bench.
      final r = covOf(
        idx,
        maxRowsFromTop: 14,
        ignore: story == 119
            ? (t) => t != null && t.startsWith('cosa:farol')
            : null,
      );
      if (r.hid > 0 || r.cov > 0 || r.out > 0) {
        fail(
          'heads-clear',
          '$k at $sp head hid=${r.hid} cov=${r.cov} (${r.by}) out=${r.out}',
        );
      }
    }

    // 4. lanterns-clear
    for (final tag in const ['cosa:farol1', 'cosa:farol2', 'cosa:farol3']) {
      final idx = list.indexWhere((it) => it.tag == tag);
      if (idx < 0) continue;
      final r = covOf(idx);
      if (r.hid > 0 || r.cov > 0 || r.out > 0) {
        fail(
          'lanterns-clear',
          '$tag hid=${r.hid} cov=${r.cov} (${r.by}) out=${r.out}',
        );
      }
    }

    // 5. doors-clear (story 117: sentry box doors are interactive targets)
    if (story == 117) {
      if (!redOpen) {
        final rb = (_m.places.box('puerta_roja') as List).cast<int>();
        final cov = boxCoveredBy(rb);
        if (cov > 0) {
          fail('doors-clear', 'closed puerta_roja covered by $cov px');
        }
      }
      if (!blueOpen) {
        final bb = (_m.places.box('puerta_azul') as List).cast<int>();
        final cov = boxCoveredBy(bb);
        if (cov > 0) {
          fail('doors-clear', 'closed puerta_azul covered by $cov px');
        }
      }
    }
    for (var idx = 0; idx < list.length; idx++) {
      final dynamic it = list[idx];
      final cb = it.clipBox as List<int>?;
      if (cb == null) continue;
      final tag = '${it.tag}';
      if (!tag.startsWith('persona:')) continue;
      final sp = it.s as Sprite;
      final ink = _inkOf(sp);
      if (ink == null) continue;
      final headTop = (it.top as int) + ink[1];
      if (headTop != cb[1] + 2) {
        fail(
          'doors-clear',
          '$tag inside door headTop=$headTop expected ${cb[1] + 2}',
        );
      }
      final r = covOf(idx, maxRowsFromTop: 14);
      if (r.hid > 0 || r.cov > 0 || r.out > 0) {
        fail(
          'doors-clear',
          '$tag inside door head hid=${r.hid} cov=${r.cov} (${r.by}) out=${r.out}',
        );
      }
    }

    // 6. candle-clear (story 118)
    if (story == 118) {
      final idx = list.indexWhere((it) => it.tag == 'cosa:vela');
      if (idx < 0) {
        fail('candle-clear', 'missing cosa:vela in story 118');
      } else {
        final r = covOf(idx);
        if (r.hid > 0 || r.cov > 0 || r.out > 0) {
          fail(
            'candle-clear',
            'vela hid=${r.hid} cov=${r.cov} (${r.by}) out=${r.out}',
          );
        }
      }
    }

    // 7. table-clear (stories 118 & 119)
    if (story == 118 || story == 119) {
      for (var idx = 0; idx < list.length; idx++) {
        final tag = list[idx].tag as String?;
        if (tag == null || !_tableTags.contains(tag)) continue;
        final r = covOf(idx);
        if (r.hid > 0 || r.cov > 0 || r.out > 0) {
          fail(
            'table-clear',
            '$tag hid=${r.hid} cov=${r.cov} (${r.by}) out=${r.out}',
          );
        }
      }
    }

    // 8. guagua-clear (story 119 once turn/game begins, matching moments 5 and 6) & end-clear
    if (story == 119) {
      final gIdx = list.indexWhere((it) => it.tag == 'cosa:guagua');
      if (gIdx < 0) {
        fail('guagua-clear', 'missing cosa:guagua in story 119');
      } else {
        final b4Busy = _murallaPersonas.any((k) {
          final p = gente[k] as Map?;
          return p != null && jsTruthy(p['vis']) && p['spot'] == 'banco4';
        });
        if (!b4Busy) {
          final r = covOf(
            gIdx,
            ignore: jsTruthy(w['guaguaGone'])
                ? (t) => t == 'cosa:farol3'
                : null,
          );
          if (r.hid > 0 || r.cov > 0 || r.out > 0) {
            fail(
              'guagua-clear',
              'guagua hid=${r.hid} cov=${r.cov} (${r.by}) out=${r.out}',
            );
          }
        }
        if (jsTruthy(w['guaguaGone'])) {
          final gIt = list[gIdx];
          final gSp = gIt.s as Sprite;
          final gx0 = gIt.left as int, gy0 = gIt.top as int;
          final gx1 = gx0 + gSp.w, gy1 = gy0 + gSp.h;
          for (var idx = 0; idx < list.length; idx++) {
            final dynamic it = list[idx];
            final tag = it.tag as String?;
            if (tag == null || !tag.startsWith('persona:')) continue;
            final who = tag.substring(8);
            final p = gente[who] as Map?;
            if (p == null || !jsTruthy(p['vis'])) continue;
            final spName = p['spot'] as String?;
            if (spName == null || !spName.startsWith('pretil')) continue;
            final sp = it.s as Sprite;
            final left = it.left as int, top = it.top as int;
            var hit = 0;
            for (var py = 0; py < sp.h; py++) {
              final Y = top + py;
              if (Y < gy0 || Y >= gy1) continue;
              for (var px = 0; px < sp.w; px++) {
                if (sp.px[py * sp.w + px] >>> 24 == 0) continue;
                final X = left + px;
                if (X >= gx0 && X < gx1) hit++;
              }
            }
            if (hit > 0) {
              fail('end-clear', '$who at $spName covers $hit px of guagua');
            }
          }
        }
      }
    }

    // 9. camera-clear (story 117)
    if (story == 117) {
      final cIdx = list.indexWhere((it) => it.tag == 'cosa:camara');
      if (cIdx < 0) {
        fail('camera-clear', 'missing cosa:camara in story 117');
      } else {
        final r = covOf(cIdx);
        if (r.hid > 0 || r.cov > 0 || r.out > 0) {
          fail(
            'camera-clear',
            'camara hid=${r.hid} cov=${r.cov} (${r.by}) out=${r.out}',
          );
        }
      }
    }

    // 10. steps-clear (nobody stands inside steps hole u 2.2..3.7, v 6.2..8.4)
    for (final k in _murallaPersonas) {
      final p = gente[k] as Map?;
      if (p == null || !jsTruthy(p['vis'])) continue;
      final sp = p['spot'] as String?;
      if (sp == null || (_m.places.isPxSpot(sp) as bool)) continue;
      final x = (p['x'] as num).toDouble(), y = (p['y'] as num).toDouble();
      final u = (x - y) / r2, v = (x + y) / r2;
      if (u > 2.2 && u < 3.7 && v > 6.2 && v < 8.4) {
        fail('steps-clear', '$k at ($u, $v) stands in steps hole');
      }
    }

    // 11. sprites-apart
    final chars = <({String id, int sx, int sy, bool frog})>[];
    for (var idx = 0; idx < list.length; idx++) {
      final dynamic it = list[idx];
      final tag = it.tag as String?;
      if (tag == null) continue;
      if (tag == 'coqui') {
        final b = scene.host.frogBox(cq!);
        chars.add((
          id: 'coqui',
          sx: (b.x + b.w / 2).round(),
          sy: (b.y + b.h).round(),
          frog: true,
        ));
      } else if (tag.startsWith('persona:')) {
        if (it.clipBox != null) continue;
        final who = tag.substring(8);
        final p = gente[who] as Map?;
        if (p == null || (_m.places.isPxSpot('${p['spot']}') as bool)) continue;
        final sp = it.s as Sprite;
        final ax = who == 'abuela' ? 30 : PX;
        chars.add((
          id: who,
          sx: (it.left as int) + ax,
          sy: (it.sy as num).round(),
          frog: false,
        ));
        final _ = sp;
      }
    }
    for (var i = 0; i < chars.length; i++) {
      for (var j = i + 1; j < chars.length; j++) {
        final a = chars[i], b = chars[j];
        final across = (a.sx - b.sx).abs();
        final down = (a.sy - b.sy).abs();
        final need = (a.frog || b.frog) ? 28 : 24;
        if (across < need && down < 12) {
          fail(
            'sprites-apart',
            '${a.id} (${a.sx},${a.sy}) vs ${b.id} (${b.sx},${b.sy}): across=$across < $need, down=$down < 12',
          );
        }
      }
    }

    if (_frameCache.length < _maxCacheEntries) {
      _frameCache[cacheKey] = List.unmodifiable(frameBreaches);
    }
    for (final b in frameBreaches) {
      breaches.add((at: at, rule: b.rule, what: b.what));
    }
  }
}
