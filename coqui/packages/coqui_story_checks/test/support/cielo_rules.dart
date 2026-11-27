// El cielo's rules (cielo-sheet.json's rules and checks, and page 13's "The sheet's rules hold in the scene"), checked
// on the real scene's frame at every act's end and at the story's end:
// - frog-seen: when cq.vis is truthy, a `coqui` item must exist and have 0 px hidden by the live set (including
//   swaying palm fronds: drawLeaves(0)), outside [22, 218) x [0, 216), or under a nearer sprite (excluding frog FX);
// - spots-in-view: every visible person and interactive sprite lies inside [22, 218) x [0, 216);
// - abuela-head: abuela's top 14 drawn rows have 0 px hidden by the live set/fronds or covered by any nearer sprite;
// - sky-clear: no sprite pixel covers the sky's active landmarks (sun/cloud in azul, moon/star in noche);
// - candles-clear: in story 82, all three candles (`cosa:vela1..3`) have 0 px hidden by the live set/fronds or covered
//   by any nearer sprite (excluding the transparent glass dome `cosa:tapa` when placed over them);
// - umbrella-canopy: in story 81 when the umbrella is open, neither the frog nor the tray (`cosa:jugos`) has any pixel
//   under the umbrella or inside the open canopy box [119, 124, 64, 16];
// - visor: in story 83 when `cosa:visor` is shown, it lies inside [22, 218) x [0, 216) and covers 0 px of any person's
//   head (top 14 rows) or of the frog;
// - sprites-apart: no two visible characters overlap sideways unless their feet are 12 px or more apart up-down.
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/coqui_scenes.dart';

/// What went against a rule: when, which rule, the details.
typedef CieloBreach = ({String at, String rule, String what});

final double _t30 = math.tan(math.pi / 6);

/// Watches a real El cielo while a story plays: [wrap] its acts, then read [breaches] and [checked].
class CieloRules {
  CieloRules(this.scene) : _m = scene {
    if (scene.id != 'cielo') {
      throw StateError('CieloRules expects scene "cielo", got "${scene.id}"');
    }
  }

  final SetScene scene;
  final dynamic _m;

  static final Map<String, Float32List> _zb = {};
  static final Map<String, SetBakes> _bakes = {};

  /// Live depth after `drawLeaves(0)` (cielo-sheet.json `front.plane`: `window.DEPTH.live()`).
  Float32List _zbOf(String key) => _zb['${scene.id}:$key'] ??= () {
    final bakes = _bakes[scene.id] ??= SetBakes(scene);
    final baked = bakes.bakeKey(key);
    baked.restoreInto(bakes.engine);
    bakes.engine.drawLeaves(0);
    return Float32List.fromList(bakes.engine.zb);
  }();

  final List<CieloBreach> breaches = [];
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

  static const Set<String> _inViewTags = {
    'coqui',
    'persona:abuela',
    'persona:luis',
    'persona:carmen',
    'persona:perro',
    'cosa:radio',
    'cosa:jugos',
    'cosa:sombrilla',
    'cosa:chiringa',
    'cosa:bola',
    'cosa:vela1',
    'cosa:vela2',
    'cosa:vela3',
    'cosa:chal',
    'cosa:tapa',
    'cosa:telescopio',
    'cosa:visor',
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
    final cq = W['cq'] as Map?;
    final cielo = W['cielo'] as String?;
    final sombOpen = W['sombrillaAbierta'] == 1;
    final tapaPuesta = W['tapaPuesta'] == 1;
    final tropiezo = W['tropiezo'] as String?;

    final sig = StringBuffer()
      ..write(scene.id)
      ..write('|')
      ..write(setKey)
      ..write('|')
      ..write(story)
      ..write('|')
      ..write(sombOpen)
      ..write('|')
      ..write(tapaPuesta)
      ..write('|')
      ..write(tropiezo);
    for (final k in const ['abuela', 'luis', 'carmen']) {
      final p = gente[k] as Map?;
      sig
        ..write('|')
        ..write(p?['vis'])
        ..write(':')
        ..write(p?['spot'])
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
      bool Function(String? tag)? ignore,
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
            final o = items[j];
            if (ignore != null && ignore(o.tag)) continue;
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
        final r = covOf(frogIdx, ignore: (t) => t == 'fx:nota');
        if (r.hid > 0 || r.cov > 0 || r.out > 0) {
          addBreach(
            'frog-seen',
            'frog hid=${r.hid} cov=${r.cov} (${r.by}) out=${r.out} of ${r.total}',
          );
        }
      }
    }

    // 2. spots-in-view
    for (var i = 0; i < items.length; i++) {
      final it = items[i];
      if (it.tag == null || !_inViewTags.contains(it.tag)) continue;
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

    // 3. abuela-head (top 14 rows of abuela's sprite)
    final abIdx = items.indexWhere((it) => it.tag == 'persona:abuela');
    if (abIdx >= 0) {
      final r = covOf(abIdx, maxRowsFromTop: 14);
      if (r.hid > 0 || r.cov > 0 || r.out > 0) {
        addBreach(
          'abuela-head',
          'abuela head hid=${r.hid} cov=${r.cov} (${r.by}) out=${r.out}',
        );
      }
    }

    // 4. sky-clear (active sky landmarks: sun & cloud in azul; moon & star in noche)
    final skyBoxes = <(String, List<int>)>[
      if (cielo == 'azul') ...[
        ('sun', const [187, 17, 18, 18]),
        ('cloud', (_m.places.box('nube') as List).cast<int>()),
      ],
      if (cielo == 'noche') ...[
        ('moon', (_m.places.box('luna') as List).cast<int>()),
        ('star', (_m.places.box('estrella') as List).cast<int>()),
      ],
    ];
    for (final (name, box) in skyBoxes) {
      final bx0 = box[0],
          by0 = box[1],
          bx1 = box[0] + box[2],
          by1 = box[1] + box[3];
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
          addBreach('sky-clear', '${it.tag} covers $hit px of sky $name $box');
        }
      }
    }

    // 5. candles-clear (story 82)
    if (story == 82) {
      for (var i = 0; i < items.length; i++) {
        final tag = items[i].tag;
        if (tag == null || !tag.startsWith('cosa:vela')) continue;
        final r = covOf(i, ignore: (t) => tapaPuesta && t == 'cosa:tapa');
        if (r.hid > 0 || r.cov > 0 || r.out > 0) {
          addBreach(
            'candles-clear',
            '$tag hid=${r.hid} cov=${r.cov} (${r.by}) out=${r.out}',
          );
        }
      }
    }

    // 6. umbrella-canopy (story 81 when open and upright)
    if (story == 81 && sombOpen && tropiezo != 'sombrilla') {
      const canopy = [119, 124, 64, 16];
      for (final targetTag in const ['coqui', 'cosa:jugos']) {
        final idx = items.indexWhere((it) => it.tag == targetTag);
        if (idx < 0) continue;
        final f = items[idx];
        final ink = f.ink;
        if (ink == null) continue;
        var inCanopy = 0;
        for (var y = ink[1]; y <= ink[3]; y++) {
          final Y = f.top + y;
          if (Y < canopy[1] || Y >= canopy[1] + canopy[3]) continue;
          for (var x = ink[0]; x <= ink[2]; x++) {
            final X = f.left + x;
            if (X < canopy[0] || X >= canopy[0] + canopy[2]) continue;
            if (f.s.px[y * f.s.w + x] >>> 24 != 0) inCanopy++;
          }
        }
        if (inCanopy > 0) {
          addBreach(
            'umbrella-canopy',
            '$targetTag has $inCanopy px inside open canopy $canopy',
          );
        }
        final r = covOf(idx, ignore: (t) => t != 'cosa:sombrilla');
        if (r.cov > 0) {
          addBreach(
            'umbrella-canopy',
            '$targetTag has ${r.cov} px covered by open umbrella',
          );
        }
      }
    }

    // 7. visor (story 83: covers 0 px of any person's head or frog)
    final visorIdx = items.indexWhere((it) => it.tag == 'cosa:visor');
    if (visorIdx >= 0) {
      for (var i = 0; i < items.length; i++) {
        final tag = items[i].tag;
        if (tag == null) continue;
        final isPerson = tag.startsWith('persona:');
        final isFrog = tag == 'coqui';
        if (!isPerson && !isFrog) continue;
        final r = covOf(
          i,
          maxRowsFromTop: isPerson ? 14 : null,
          ignore: (t) => t != 'cosa:visor',
        );
        if (r.cov > 0) {
          addBreach('visor', 'visor covers ${r.cov} px of $tag');
        }
      }
    }

    // 8. sprites-apart (characters: abuela, luis, carmen, coqui)
    final chars = <({String id, int sx, int sy, bool frog})>[];
    for (final k in const ['abuela', 'luis', 'carmen']) {
      final p = gente[k] as Map?;
      if (p == null || p['vis'] == 0) continue;
      final at = _m.places.atWorld(p['x'] as num, p['y'] as num, p['z'] as num);
      chars.add((
        id: k,
        sx: ((at.sx as num) + 0.5).floor(),
        sy: ((at.sy as num) + 0.5).floor(),
        frog: false,
      ));
    }
    if (cq != null && jsTruthy(cq['vis'])) {
      final sp = cq['spot'];
      if (sp is String && (_m.places.hasWorld(sp) as bool)) {
        final at = _m.places.at(sp);
        chars.add((
          id: 'coqui',
          sx: ((at.sx as num) + 0.5).floor(),
          sy: ((at.sy as num) + 0.5).floor(),
          frog: true,
        ));
      } else {
        addBreach(
          'scene-state',
          'cq.vis is truthy with unknown/non-world spot "$sp"',
        );
      }
    }
    for (var i = 0; i < chars.length; i++) {
      for (var j = i + 1; j < chars.length; j++) {
        final a = chars[i], b = chars[j];
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
