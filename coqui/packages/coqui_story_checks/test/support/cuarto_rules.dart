// El cuarto's rules (cuarto-sheet.json's 10 checks and page 13's "The sheet's rules hold in the scene"),
// checked on the real scene's frame at every act's end and at the story's end:
// - frog-seen: when cq.vis is truthy, a `coqui` item exists and has 0 px hidden by the set, outside [x0, x0+196) x [0, 216),
//   or under a nearer sprite;
// - spots-in-view: every visible person and interactive sprite lies inside [x0, x0+196) x [0, 216);
// - sprites-apart: no two visible characters (people, Canelo at junto_mesita, frog) overlap sideways unless their feet
//   are >= 12 px apart (hung bed sprites use fy = sy + hang.rows);
// - heads-clear: everyone who sits or lies (cama_luis, cama_carmen, sentado_luis, sentado_carmen, butaca_abuelo) is
//   whole in the window and has top 14 drawn rows with 0 px hidden by the set, covered by any nearer sprite, or outside;
// - heads-pillow: whenever Luis or Carmen is in bed (cama_*, sentado_*), head spot (sx, sy) and top 14 head columns
//   lie inside that bed's pillow rectangle (`pillows[bed].screen`);
// - frog-mesita: when frog is at `mesita_coqui`, frog covers 0 px of `campana` box and 0 px of `plato` box (when drawn);
// - things-clear: `campana`, `plato`, `almohada`, `ropa_a`, `ropa_b` have 0 px hidden by set, covered by sprites, or
//   outside the window, and no sprite has any pixel in the light switch box (`places.box('luz')` = [49, 31, 10, 12]);
// - canelo-frog: when Canelo is at `junto_mesita` and frog is visible, Canelo covers 0 px of the frog;
// - frog-busca: when frog is at `busca_cama`, `busca_almohada`, or `busca_silla`, frog has 0 px hidden/covered/out;
// - bebe-clear: when `cuna == 1`, `cosa:bebe` has 0 px covered by nearer sprites and 0 px outside the window.
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/coqui_scenes.dart';

/// What went against a rule: when, which rule, the details.
typedef CuartoBreach = ({String at, String rule, String what});

final double _t30 = math.tan(math.pi / 6);

/// Watches a real El cuarto while a story plays: [wrap] its acts, then read [breaches] and [checked].
class CuartoRules {
  CuartoRules(this.scene) : _m = scene {
    if (scene.id != 'cuarto') {
      throw StateError('CuartoRules expects scene "cuarto", got "${scene.id}"');
    }
  }

  final SetScene scene;
  final dynamic _m;

  static final Map<String, Float32List> _zb = {};
  static final Map<String, SetBakes> _bakes = {};

  /// Baked set depth for [key].
  Float32List _zbOf(String key) => _zb['${scene.id}:$key'] ??= () {
    final bakes = _bakes[scene.id] ??= SetBakes(scene);
    final baked = bakes.bakeKey(key);
    return Float32List.fromList(baked.zb);
  }();

  final List<CuartoBreach> breaches = [];
  final List<CuartoBreach> notes = [];
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
  double? _cachedCOS;
  double? _cachedOY;
  double? _cachedBias;
  int? _cachedX0;
  List<int>? _cachedLuz;
  List<int>? _cachedCampana;
  List<int>? _cachedPlato;

  static final Expando<int> _spriteIds = Expando<int>();
  static int _nextSpriteId = 1;
  static int _spriteId(Sprite s) => _spriteIds[s] ??= _nextSpriteId++;

  static const int _maxCacheEntries = 4096;
  static final Map<String, List<({String rule, String what})>> _frameCache = {};

  static const Set<String> _inViewTags = {
    'coqui',
    'persona:abuela',
    'persona:abuelo',
    'persona:luis',
    'persona:carmen',
    'persona:perro',
    'cosa:almohada',
    'cosa:campana',
    'cosa:plato',
    'cosa:ropa_a',
    'cosa:ropa_b',
    'cosa:manta_abuelo',
    'cosa:bebe',
    'fx:zetas',
  };

  static const Set<String> _thingTags = {
    'cosa:campana',
    'cosa:plato',
    'cosa:almohada',
    'cosa:ropa_a',
    'cosa:ropa_b',
  };

  static const List<String> _allPeople = ['abuela', 'abuelo', 'luis', 'carmen'];

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
    final cq = W['cq'] as Map<String, dynamic>?;

    final sig = StringBuffer()
      ..write(scene.id)
      ..write('|')
      ..write(setKey)
      ..write('|')
      ..write(story)
      ..write('|perro:')
      ..write(W['perroVis'])
      ..write(':')
      ..write(W['perroSpot']);
    for (final k in _allPeople) {
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
      ..write(cq?['dx'])
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
        ..write(it.hungZ)
        ..write(',')
        ..write(it.dd)
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
    final localNotes = <({String rule, String what})>[];
    void addBreach(String rule, String what) {
      localBreaches.add((rule: rule, what: what));
      breaches.add((at: at, rule: rule, what: what));
    }

    void addNote(String rule, String what) {
      localNotes.add((rule: rule, what: what));
      notes.add((at: at, rule: rule, what: what));
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
            double? hungZ,
            double dd,
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
              hungZ: it.hungZ as double?,
              dd: (it.dd as num).toDouble(),
              ink: _inkOf(it.s as Sprite),
            ),
        ];

    final s = _cachedS ??= (_m.places.e.S as num).toDouble();
    final cos = _cachedCOS ??= (_m.places.e.COS as num).toDouble();
    final oy = _cachedOY ??= (_m.places.e.OY as num).toDouble();
    final bias = _cachedBias ??= (_m.places.bias as num).toDouble();
    final x0 = _cachedX0 ??= ((_m.places.view('wide') as List)[0] as num)
        .toInt();
    final winR = x0 + 196;
    final zb = _zbOf(setKey);

    double planeOf(
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
        double? hungZ,
        double dd,
        List<int>? ink,
      })
      f,
      int yPos,
    ) {
      if (f.overlay) return f.d;
      if (f.hungZ != null) {
        return (2 * cos / s) * (yPos + .5 - oy) + 2 * f.hungZ! + f.dd;
      }
      return f.d + (f.sy - (yPos + .5)) * _t30 / s;
    }

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
        final plane = planeOf(f, Y);
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
            final op = planeOf(o, Y);
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
        final r = covOf(frogIdx);
        if (r.hid > 0 || r.cov > 0 || r.out > 0) {
          addBreach(
            'frog-seen',
            'frog hid=${r.hid} cov=${r.cov} (${r.by}) out=${r.out} of ${r.total}',
          );
        }
      }
    }

    // 2. frog-busca
    final qSpot = cq?['spot'] as String?;
    if (frogIdx >= 0 &&
        qSpot != null &&
        const ['busca_cama', 'busca_almohada', 'busca_silla'].contains(qSpot)) {
      final r = covOf(frogIdx);
      if (r.hid > 0 || r.cov > 0 || r.out > 0) {
        addBreach(
          'frog-busca',
          'frog at $qSpot hid=${r.hid} cov=${r.cov} (${r.by}) out=${r.out}',
        );
      }
    }

    // 3. spots-in-view
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

    // 4. heads-clear & 5. heads-pillow (everyone who lies/sits in bed or sits in armchair)
    for (final k in const ['luis', 'carmen', 'abuelo']) {
      final p = gente[k] as Map?;
      if (p == null || !jsTruthy(p['vis'])) continue;
      final spot = p['spot'] as String?;
      if (spot == null) continue;
      final isBed = const [
        'cama_luis',
        'cama_carmen',
        'sentado_luis',
        'sentado_carmen',
      ].contains(spot);
      final isChair = spot == 'butaca_abuelo';
      if (!isBed && !isChair) continue;
      final idx = items.indexWhere((it) => it.tag == 'persona:$k');
      if (idx < 0) continue;
      final whole = covOf(idx);
      if (whole.out > 0) {
        addBreach('heads-clear', '$k at $spot out=${whole.out}');
      }
      final head = covOf(idx, maxRowsFromTop: 14);
      if (head.hid > 0 || head.cov > 0 || head.out > 0) {
        final onlyCoquiOnBed =
            k == 'luis' &&
            qSpot == 'cama_coqui' &&
            head.hid == 0 &&
            head.out == 0 &&
            head.by.length == 1 &&
            head.by.containsKey('coqui');
        if (onlyCoquiOnBed) {
          addNote(
            'heads-clear (cama_coqui)',
            '$k at $spot head covered ${head.cov} px by frog on bed at cama_coqui',
          );
        } else {
          addBreach(
            'heads-clear',
            '$k at $spot head hid=${head.hid} cov=${head.cov} (${head.by}) out=${head.out}',
          );
        }
      }
      if (isBed) {
        final hang = _m.places.hang(spot);
        final pil = _m.places.pillows[hang.bed as int];
        final sc = pil.screen as List<double>;
        final at = _m.places.at(spot);
        final sx = ((at.sx as num) + 0.5).floor();
        final sy = ((at.sy as num) + 0.5).floor();
        if (sx < sc[0] || sx > sc[2] || sy < sc[1] || sy > sc[3]) {
          addBreach('heads-pillow', '$k at $spot ($sx,$sy) outside pillow $sc');
        }
        final it = items[idx];
        final ink = it.ink;
        if (ink != null) {
          final yEnd = math.min(ink[3], ink[1] + 13);
          var minX = 240, maxX = -1;
          for (var y = ink[1]; y <= yEnd; y++) {
            for (var x = ink[0]; x <= ink[2]; x++) {
              if (it.s.px[y * it.s.w + x] >>> 24 == 0) continue;
              final X = it.left + x;
              if (X < minX) minX = X;
              if (X > maxX) maxX = X;
            }
          }
          if (maxX >= 0 && (minX < sc[0].floor() || maxX > sc[2].ceil())) {
            addBreach(
              'heads-pillow',
              '$k head cols [$minX..$maxX] outside pillow [${sc[0]}..${sc[2]}]',
            );
          }
        }
      }
    }

    // 6. frog-mesita (at mesita_coqui, covers 0 px of campana box and 0 px of plato box)
    if (frogIdx >= 0 && qSpot == 'mesita_coqui') {
      final f = items[frogIdx];
      final ink = f.ink;
      if (ink != null) {
        final campana = _cachedCampana ??=
            (_m.places.spotBox('campana') as List).cast<int>();
        final plato = _cachedPlato ??= (_m.places.spotBox('plato') as List)
            .cast<int>();
        void checkBox(String name, List<int> box) {
          var hit = 0;
          for (var y = ink[1]; y <= ink[3]; y++) {
            final Y = f.top + y;
            if (Y < box[1] || Y >= box[1] + box[3]) continue;
            for (var x = ink[0]; x <= ink[2]; x++) {
              final X = f.left + x;
              if (X < box[0] || X >= box[0] + box[2]) continue;
              if (f.s.px[y * f.s.w + x] >>> 24 != 0) hit++;
            }
          }
          if (hit > 0) {
            addBreach(
              'frog-mesita',
              'frog at mesita_coqui covers $hit px of $name box $box',
            );
          }
        }

        if (jsTruthy(W['campanaVis'])) checkBox('campana', campana);
        if (jsTruthy(W['platoVis'])) checkBox('plato', plato);
      }
    }

    // 7. things-clear (campana, plato, almohada, ropa_a, ropa_b + switch box [49, 31, 10, 12])
    for (var i = 0; i < items.length; i++) {
      final tag = items[i].tag;
      if (tag == null || !_thingTags.contains(tag)) continue;
      final r = covOf(i);
      if (r.hid > 0 || r.cov > 0 || r.out > 0) {
        addBreach(
          'things-clear',
          '$tag hid=${r.hid} cov=${r.cov} (${r.by}) out=${r.out}',
        );
      }
    }
    final luz = _cachedLuz ??= (_m.places.box('luz') as List).cast<int>();
    final lx0 = luz[0],
        ly0 = luz[1],
        lx1 = luz[0] + luz[2],
        ly1 = luz[1] + luz[3];
    for (final it in items) {
      final ink = it.ink;
      if (ink == null) continue;
      if (it.left + ink[2] < lx0 ||
          it.left + ink[0] >= lx1 ||
          it.top + ink[3] < ly0 ||
          it.top + ink[1] >= ly1) {
        continue;
      }
      var hit = 0;
      for (var y = ink[1]; y <= ink[3]; y++) {
        final Y = it.top + y;
        if (Y < ly0 || Y >= ly1) continue;
        for (var x = ink[0]; x <= ink[2]; x++) {
          final X = it.left + x;
          if (X < lx0 || X >= lx1) continue;
          if (it.s.px[y * it.s.w + x] >>> 24 != 0) hit++;
        }
      }
      if (hit > 0) {
        addBreach(
          'things-clear',
          '${it.tag} has $hit px inside switch box $luz',
        );
      }
    }

    // 8. canelo-frog (Canelo at junto_mesita covers 0 px of frog)
    if (frogIdx >= 0 &&
        jsTruthy(W['perroVis']) &&
        W['perroSpot'] == 'junto_mesita') {
      final r = covOf(frogIdx, ignore: (t) => t != 'persona:perro');
      if (r.cov > 0) {
        addBreach(
          'canelo-frog',
          'Canelo at junto_mesita covers ${r.cov} px of frog',
        );
      }
    }

    // 9. bebe-clear (bebe 0 covered by sprites, 0 outside window)
    final bebeIdx = items.indexWhere((it) => it.tag == 'cosa:bebe');
    if (bebeIdx >= 0) {
      final r = covOf(bebeIdx);
      if (r.cov > 0 || r.out > 0) {
        addBreach('bebe-clear', 'bebe cov=${r.cov} (${r.by}) out=${r.out}');
      }
    }

    // 10. sprites-apart
    final chars = <({String id, int sx, int fy, String kind})>[];
    for (final k in _allPeople) {
      final p = gente[k] as Map?;
      if (p == null || !jsTruthy(p['vis'])) continue;
      final at = _m.places.atWorld(p['x'] as num, p['y'] as num, p['z'] as num);
      final spot = p['spot'] as String?;
      final hang = spot != null ? _m.places.hang(spot) : null;
      final sy = ((at.sy as num) + 0.5).floor();
      chars.add((
        id: k,
        sx: ((at.sx as num) + 0.5).floor(),
        fy: hang != null ? sy + (hang.rows as int) : sy,
        kind: 'person',
      ));
    }
    if (jsTruthy(W['perroVis']) && W['perroSpot'] == 'junto_mesita') {
      final at = _m.places.at('junto_mesita');
      chars.add((
        id: 'perro',
        sx: ((at.sx as num) + 0.5).floor(),
        fy: ((at.sy as num) + 0.5).floor(),
        kind: 'perro',
      ));
    }
    if (cq != null && jsTruthy(cq['vis'])) {
      final fb = scene.host.frogBox(cq);
      chars.add((
        id: 'coqui',
        sx: (fb.x + fb.w / 2).round(),
        fy: ((cq['y'] as num) + 25).round(),
        kind: 'coqui',
      ));
    }
    for (var i = 0; i < chars.length; i++) {
      for (var j = i + 1; j < chars.length; j++) {
        final a = chars[i], b = chars[j];
        final across = (a.sx - b.sx).abs();
        final down = (a.fy - b.fy).abs();
        final bool hasCoqui = a.kind == 'coqui' || b.kind == 'coqui';
        final bool hasPerro = a.kind == 'perro' || b.kind == 'perro';
        final int needAcross = hasCoqui && hasPerro
            ? 30
            : (hasCoqui ? 28 : (hasPerro ? 26 : 24));
        if (across < needAcross && down < 12) {
          final isCoquiOnLuisBed =
              qSpot == 'cama_coqui' &&
              ((a.id == 'coqui' && b.id == 'luis') ||
                  (b.id == 'coqui' && a.id == 'luis'));
          if (isCoquiOnLuisBed) {
            addNote(
              'sprites-apart (cama_coqui)',
              '${a.id} (${a.sx},${a.fy}) ~ ${b.id} (${b.sx},${b.fy}): $across across and $down down',
            );
          } else {
            addBreach(
              'sprites-apart',
              '${a.id} (${a.sx},${a.fy}) ~ ${b.id} (${b.sx},${b.fy}): $across across (< $needAcross) and $down down (< 12)',
            );
          }
        }
      }
    }

    if (_frameCache.length < _maxCacheEntries) {
      _frameCache[key] = List<({String rule, String what})>.unmodifiable(
        localBreaches,
      );
    }
  }
}
