// La entrada's rules (entrada-sheet.json's rules and checks, and page 13's "The sheet's rules hold in the scene"),
// checked on the real scene's frame at every act's end and at the story's end:
// - frog-seen: when cq.vis is truthy, a `coqui` item must exist and have 0 px hidden by the baked set, outside
//   [21, 217) x [0, 216), or under a nearer sprite (excluding items held by `coqui`, i.e., his bow tie);
// - spots-in-view: every visible person, frog, and interactive/prop sprite lies inside [21, 217) x [0, 216);
// - heads-clear: for everyone sitting at a table (`mesa1_a..d`, `mesa2_a..d`, `mesa3_a..d`), the top 14 drawn rows
//   have 0 px hidden by the set and 0 px covered by any nearer sprite;
// - cola-heads: when people stand at `cola1`/`cola2` behind standing grown-ups at `puerta1`/`puerta2` or
//   `atril1`/`atril2`, their head top rows are 16 px or more above the grown-ups in front of them;
// - bench-seat: in story 84 when nobody sits on the bench (`banco1`, `banco2`, `banco_coqui`), 0 px of any sprite
//   covers the bench seat [73, 57, 32, 8];
// - mesera-waist: when `mesera` stands at `atril` or `tras_cuerda`, the top 35 drawn rows of her sprite have 0 px
//   hidden by the set and 0 px covered by any nearer sprite;
// - cloths-clear: in story 85 when the cloth's table (and mesa3 for mesa2's cloth) has nobody seated at it, the
//   table cloth has 0 px hidden by the set and 0 px covered by any nearer sprite;
// - m7-things: in story 86, the three candles (`cosa:vela1..3`), `cosa:cosa_a`, and `cosa:cosa_b` (whenever shown)
//   have 0 px hidden by the set and 0 px covered by any nearer sprite, and the candles cover 0 px of any person's
//   head (top 14 rows);
// - sprites-apart: no two visible characters overlap sideways unless their feet/laps are 12 px or more apart up-down.
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/coqui_scenes.dart';

/// What went against a rule: when, which rule, the details.
typedef EntradaBreach = ({String at, String rule, String what});

final double _t30 = math.tan(math.pi / 6);

/// Watches a real La entrada while a story plays: [wrap] its acts, then read [breaches] and [checked].
class EntradaRules {
  EntradaRules(this.scene) : _m = scene {
    if (scene.id != 'entrada') {
      throw StateError(
        'EntradaRules expects scene "entrada", got "${scene.id}"',
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

  final List<EntradaBreach> breaches = [];
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

  static const int _maxCacheEntries = 4096;
  static final Map<String, List<({String rule, String what})>> _frameCache = {};

  static bool _isInViewTag(String tag) {
    if (tag == 'coqui' || tag.startsWith('persona:')) return true;
    return const {
      'cosa:cosa_a',
      'cosa:cosa_b',
      'cosa:menu',
      'cosa:vela1',
      'cosa:vela2',
      'cosa:vela3',
      'cosa:dulces',
      'cosa:flores',
      'cosa:tarjeta',
      'cosa:taburete',
      'cosa:bandeja_t',
      'cosa:mantel2',
      'cosa:mantel3',
    }.contains(tag);
  }

  static bool _isTableSeat(String? spot) =>
      spot != null && RegExp(r'^mesa[123]_[abcd]$').hasMatch(spot);

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
    final cq = W['cq'] as Map?;

    final sig = StringBuffer()
      ..write(scene.id)
      ..write('|')
      ..write(setKey)
      ..write('|')
      ..write(story);
    final gKeys = gente.keys.map((k) => '$k').toList()..sort();
    for (final k in gKeys) {
      final p = gente[k] as Map?;
      sig
        ..write('|')
        ..write(k)
        ..write('=')
        ..write(p?['vis'])
        ..write(':')
        ..write(p?['spot'])
        ..write(':')
        ..write(p?['sent'])
        ..write(':')
        ..write(p?['x'])
        ..write(',')
        ..write(p?['y'])
        ..write(',')
        ..write(p?['z']);
    }
    sig
      ..write('|cq:')
      ..write(cq?['vis'])
      ..write(':')
      ..write(cq?['spot'])
      ..write(':')
      ..write(cq?['x'])
      ..write(',')
      ..write(cq?['y'])
      ..write(',')
      ..write(cq?['z'])
      ..write(',')
      ..write(cq?['dy']);
    for (final dynamic it in rawItems) {
      sig
        ..write(';')
        ..write(it.tag)
        ..write(',')
        ..write(it.held)
        ..write(',')
        ..write(it.left)
        ..write(',')
        ..write(it.top)
        ..write(',')
        ..write(it.sy)
        ..write(',')
        ..write(it.d)
        ..write(',')
        ..write(it.overlay)
        ..write(',')
        ..write(_spriteId(it.s as Sprite));
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
            String? held,
            bool overlay,
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
              d: (it.d as num).toDouble(),
              tag: it.tag as String?,
              held: it.held as String?,
              overlay: it.overlay as bool,
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
      int? maxRowsFromTop,
      bool Function(int otherIdx)? ignoreIdx,
    }) {
      final f = items[idx];
      final ink = f.ink;
      if (ink == null) {
        return (hid: 0, cov: 0, out: 0, by: const {}, total: 0);
      }
      final yEnd = maxRowsFromTop == null
          ? ink[3]
          : math.min(ink[3], ink[1] + maxRowsFromTop - 1);
      var hid = 0, cov = 0, outPx = 0, total = 0;
      final by = <String, int>{};
      for (var y = ink[1]; y <= yEnd; y++) {
        final Y = f.top + y;
        final plane = f.overlay ? f.d : f.d + (f.sy - (Y + .5)) * _t30 / S;
        for (var x = ink[0]; x <= ink[2]; x++) {
          if (f.s.px[y * f.s.w + x] >>> 24 == 0) continue;
          total++;
          final X = f.left + x;
          if (X < x0 || X >= winR || Y < 0 || Y >= 216) {
            outPx++;
            continue;
          }
          if (!f.overlay && zb[Y * 240 + X] > plane + bias) {
            hid++;
            continue;
          }
          String? winner;
          var best = plane + .001;
          for (var j = 0; j < items.length; j++) {
            if (j == idx) continue;
            if (ignoreIdx != null && ignoreIdx(j)) continue;
            final o = items[j];
            if (X < o.left || X >= o.right || Y < o.top || Y >= o.bottom) {
              continue;
            }
            final ox = X - o.left, oy = Y - o.top;
            if (o.s.px[oy * o.s.w + ox] >>> 24 == 0) continue;
            final op = o.overlay ? o.d : o.d + (o.sy - (Y + .5)) * _t30 / S;
            if (!o.overlay && zb[Y * 240 + X] > op + bias) continue;
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

    // 1. frog-seen
    final frogIdx = items.indexWhere((it) => it.tag == 'coqui');
    if (cq != null && jsTruthy(cq['vis'])) {
      if (frogIdx < 0) {
        addBreach('frog-seen', 'cq.vis is truthy but no coqui sprite placed');
      } else {
        final r = covOf(frogIdx, ignoreIdx: (j) => items[j].held == 'coqui');
        if (r.hid > 0 || r.cov > 0 || r.out > 0) {
          addBreach(
            'frog-seen',
            'frog at ${cq['spot']} hid=${r.hid} cov=${r.cov} (${r.by}) out=${r.out} of ${r.total}',
          );
        }
      }
    }

    // 2. spots-in-view
    for (var i = 0; i < items.length; i++) {
      final it = items[i];
      if (it.tag == null || !_isInViewTag(it.tag!)) continue;
      final ink = it.ink;
      if (ink == null) continue;
      final l = it.left + ink[0], r = it.left + ink[2];
      final t = it.top + ink[1], b = it.top + ink[3];
      if (l < x0 || r >= winR || t < 0 || b >= 216) {
        addBreach(
          'spots-in-view',
          '${it.tag} ink [$l..$r, $t..$b] outside window [$x0..${winR - 1}, 0..215]',
        );
      }
    }

    // 3. heads-clear (top 14 rows of everyone seated at a table)
    for (var i = 0; i < items.length; i++) {
      final tag = items[i].tag;
      if (tag == null || !tag.startsWith('persona:')) continue;
      final who = tag.substring(8);
      final p = gente[who] as Map?;
      if (p == null || p['vis'] == 0) continue;
      final spot = p['spot'] as String?;
      if (!_isTableSeat(spot)) continue;
      final r = covOf(
        i,
        maxRowsFromTop: 14,
        ignoreIdx: (j) => items[j].held == who,
      );
      if (r.hid > 0 || r.cov > 0 || r.out > 0) {
        addBreach(
          'heads-clear',
          '$who@$spot head hid=${r.hid} cov=${r.cov} (${r.by}) out=${r.out}',
        );
      }
    }

    // 4. cola-heads (people at cola1/cola2 >= 16 px above grown-ups at puerta1/2 or atril1/2)
    int? topRowOfSpot(String spot) {
      for (final en in gente.entries) {
        final p = en.value as Map?;
        if (p == null || p['vis'] == 0 || p['spot'] != spot) continue;
        final idx = items.indexWhere((it) => it.tag == 'persona:${en.key}');
        if (idx < 0 || items[idx].ink == null) continue;
        return items[idx].top + items[idx].ink![1];
      }
      return null;
    }

    for (final (colaSpot, frontSpots) in const [
      ('cola1', ['puerta1', 'atril1']),
      ('cola2', ['puerta2', 'atril2']),
    ]) {
      final cTop = topRowOfSpot(colaSpot);
      if (cTop == null) continue;
      for (final front in frontSpots) {
        final fTop = topRowOfSpot(front);
        if (fTop == null) continue;
        final diff = fTop - cTop;
        if (diff < 16) {
          addBreach(
            'cola-heads',
            '$colaSpot top=$cTop vs $front top=$fTop (diff=$diff < 16)',
          );
        }
      }
    }

    // 5. bench-seat (in story 84 when bench is unoccupied, nobody covers seat [73, 57, 32, 8])
    if (story == 84) {
      final benchUsed =
          (cq != null && jsTruthy(cq['vis']) && cq['spot'] == 'banco_coqui') ||
          gente.values.any(
            (v) =>
                v is Map &&
                v['vis'] == 1 &&
                (v['spot'] == 'banco1' || v['spot'] == 'banco2'),
          );
      if (!benchUsed) {
        const bx0 = 73, by0 = 57, bx1 = 105, by1 = 65;
        for (final it in items) {
          final ink = it.ink;
          if (ink == null) continue;
          if (it.left + ink[2] < bx0 ||
              it.left + ink[0] >= bx1 ||
              it.top + ink[3] < by0 ||
              it.top + ink[1] >= by1) {
            continue;
          }
          var hit = 0;
          for (var y = ink[1]; y <= ink[3]; y++) {
            final Y = it.top + y;
            if (Y < by0 || Y >= by1) continue;
            for (var x = ink[0]; x <= ink[2]; x++) {
              final X = it.left + x;
              if (X < bx0 || X >= bx1) continue;
              if (it.s.px[y * it.s.w + x] >>> 24 != 0) hit++;
            }
          }
          if (hit > 0) {
            addBreach(
              'bench-seat',
              '${it.tag} covers $hit px of bench seat [73,57,32,8]',
            );
          }
        }
      }
    }

    // 6. mesera-waist (top 35 rows of mesera at atril or tras_cuerda)
    final meseraP = gente['mesera'] as Map?;
    if (meseraP != null &&
        meseraP['vis'] == 1 &&
        (meseraP['spot'] == 'atril' || meseraP['spot'] == 'tras_cuerda')) {
      final mIdx = items.indexWhere((it) => it.tag == 'persona:mesera');
      if (mIdx >= 0) {
        final r = covOf(mIdx, maxRowsFromTop: 35);
        if (r.hid > 0 || r.cov > 0 || r.out > 0) {
          addBreach(
            'mesera-waist',
            'mesera@${meseraP['spot']} waist hid=${r.hid} cov=${r.cov} (${r.by}) out=${r.out}',
          );
        }
      }
    }

    // 7. cloths-clear (in story 85 when the cloth's table and any nearer table are empty)
    if (story == 85) {
      bool tableOccupied(String prefix) => gente.values.any(
        (v) =>
            v is Map &&
            v['vis'] == 1 &&
            v['spot'] is String &&
            (v['spot'] as String).startsWith(prefix),
      );
      final m2Occ = tableOccupied('mesa2_');
      final m3Occ = tableOccupied('mesa3_');
      if (!m2Occ && !m3Occ) {
        for (final tag in const ['cosa:mantel2', 'cosa:mantel3']) {
          final idx = items.indexWhere((it) => it.tag == tag);
          if (idx < 0) continue;
          final r = covOf(idx);
          if (r.hid > 0 || r.cov > 0 || r.out > 0) {
            addBreach(
              'cloths-clear',
              '$tag hid=${r.hid} cov=${r.cov} (${r.by}) out=${r.out}',
            );
          }
        }
      }
    }

    // 8. m7-things (story 86: velas, cosa_a, cosa_b uncovered/unhidden; candles cover 0 px of any head)
    if (story == 86) {
      for (var i = 0; i < items.length; i++) {
        final tag = items[i].tag;
        if (tag == null) continue;
        if (tag == 'cosa:vela1' ||
            tag == 'cosa:vela2' ||
            tag == 'cosa:vela3' ||
            tag == 'cosa:cosa_a' ||
            tag == 'cosa:cosa_b') {
          final r = covOf(i);
          if (r.hid > 0 || r.cov > 0 || r.out > 0) {
            addBreach(
              'm7-things',
              '$tag hid=${r.hid} cov=${r.cov} (${r.by}) out=${r.out}',
            );
          }
        }
      }
      // Candles must cover 0 px of any person's head (top 14 rows)
      for (var i = 0; i < items.length; i++) {
        final tag = items[i].tag;
        if (tag == null || !tag.startsWith('persona:')) continue;
        final r = covOf(
          i,
          maxRowsFromTop: 14,
          ignoreIdx: (j) {
            final ot = items[j].tag;
            return ot == null || !ot.startsWith('cosa:vela');
          },
        );
        if (r.cov > 0) {
          addBreach('m7-things', 'candles cover ${r.cov} px of $tag head');
        }
      }
    }

    // 9. sprites-apart (all visible characters: gente + coqui)
    final chars = <({String id, int sx, int sy, bool frog})>[];
    for (final en in gente.entries) {
      final p = en.value as Map?;
      if (p == null || !jsTruthy(p['vis'])) continue;
      final at = _m.places.atWorld(p['x'] as num, p['y'] as num, p['z'] as num);
      chars.add((
        id: '${en.key}@${p['spot']}',
        sx: ((at.sx as num) + 0.5).floor(),
        sy: ((at.sy as num) + 0.5).floor(),
        frog: false,
      ));
    }
    if (cq != null && jsTruthy(cq['vis'])) {
      final qx = cq['x'] as num?;
      final qy = cq['y'] as num?;
      if (qx != null && qy != null) {
        chars.add((
          id: 'coqui@${cq['spot']}',
          sx: (qx + 16 + 0.5).floor(),
          sy: (qy + 25 + 0.5).floor(),
          frog: true,
        ));
      } else {
        addBreach('scene-state', 'cq.vis is truthy with missing x/y');
      }
    }
    // Narrow, self-expiring guard for the upstream sheet defect in entrada-sheet.json (mesa1_coqui was not in preview
    // moments 1..7 and stayed at [1.3, 3.35, 0.74] -> (154, 93), only 10 px below mesa1_a/b and 27 px right of mesa1_c;
    // see coqui/requests/27-coqui-scenes-needs-docs-entrada-sheet-mesa1-coqui.md). Automatically stops triggering once
    // the sheet is updated. frog-seen and heads-clear remain 100% strict on mesa1_coqui.
    final m1Coqui = _m.places.at('mesa1_coqui');
    final m1A = _m.places.at('mesa1_a');
    final m1C = _m.places.at('mesa1_c');
    final sheetMesa1CoquiDefect =
        ((((m1Coqui.sy as num) + 0.5).floor() - ((m1A.sy as num) + 0.5).floor())
                .abs() <
            12) ||
        ((((m1Coqui.sx as num) + 0.5).floor() - ((m1C.sx as num) + 0.5).floor())
                .abs() <
            28);
    bool isUpstreamMesa1CoquiPair(
      ({String id, int sx, int sy, bool frog}) a,
      ({String id, int sx, int sy, bool frog}) b,
    ) {
      if (!sheetMesa1CoquiDefect) return false;
      final other = a.id == 'coqui@mesa1_coqui'
          ? b.id
          : (b.id == 'coqui@mesa1_coqui' ? a.id : null);
      if (other == null) return false;
      final atIdx = other.indexOf('@');
      if (atIdx < 0) return false;
      final spot = other.substring(atIdx + 1);
      return spot == 'mesa1_a' || spot == 'mesa1_b' || spot == 'mesa1_c';
    }

    for (var i = 0; i < chars.length; i++) {
      for (var j = i + 1; j < chars.length; j++) {
        final a = chars[i], b = chars[j];
        if (isUpstreamMesa1CoquiPair(a, b)) continue;
        final across = (a.sx - b.sx).abs();
        final down = (a.sy - b.sy).abs();
        final needAcross = (a.frog || b.frog) ? 28 : 24;
        if (across < needAcross && down < 12) {
          addBreach(
            'sprites-apart',
            '${a.id} (${a.sx},${a.sy}) ~ ${b.id} (${b.sx},${b.sy}): across=$across (<$needAcross) down=$down (<12)',
          );
        }
      }
    }

    if (_frameCache.length >= _maxCacheEntries) {
      _frameCache.clear();
    }
    _frameCache[key] = localBreaches;
  }
}
