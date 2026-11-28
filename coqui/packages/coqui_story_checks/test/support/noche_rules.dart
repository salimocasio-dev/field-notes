// La noche's rules (noche-sheet.json's rules and checks, and page 13's "The sheet's rules hold in the scene"),
// checked on the real scene's frame at every act's end and at the story's end:
// - frog-seen: when cq.vis is truthy, a `coqui` item exists and has 0 px hidden by the set, outside
//   [22, 218) x [0, 216), or under a nearer sprite (ignoring `fx:bufanda_cuello` worn on the frog);
// - spots-in-view: every visible person, frog, and interactive sprite lies inside [22, 218) x [0, 216);
// - heads-clear: the head (top 14 drawn rows) of everyone sitting on a seat (`sofa1..3`, `butaca`, `silla1..4`) has
//   0 px hidden by the set or covered by any nearer sprite (ignoring `fx:periodico` over sleeping abuelo);
// - bed-heads: the head (top 14 drawn rows) of everyone lying in the bed (`cama1`, `cama2`) has 0 px hidden by the
//   set (arch rim), covered, or outside the window;
// - lamps-tv-clear: in stories 105 & 107, `luz1`, `luz2`, `luz3`, and `television` boxes are covered by 0 sprite px;
// - sideboard-clear: in story 106, `jugo`, `flan`, `queso`, `frutas` and `vela` have 0 hid, 0 cov, 0 out;
// - frog-arm / frog-sideboard / frog-sill: frog at `brazo_coqui`, `aparador_coqui`, `ventana_coqui` is whole and
//   covers 0 px of sideboard items;
// - sprites-apart: no two visible characters overlap sideways (24 px across for people, 28 px with the frog) unless
//   their feet are 12 px or more apart up-down.
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/coqui_scenes.dart';

const List<String> _nochePersonas = [
  'abuela',
  'abuelo',
  'luis',
  'carmen',
  'perro',
];

/// What went against a rule: when, which rule, the details.
typedef NocheBreach = ({String at, String rule, String what});

final double _t30 = math.tan(math.pi / 6);

/// Watches a real La noche while a story plays: [wrap] its acts, then read [breaches] and [checked].
class NocheRules {
  NocheRules(this.scene) : _m = scene {
    if (scene.id != 'noche') {
      throw StateError('NocheRules expects scene "noche", got "${scene.id}"');
    }
  }

  final SetScene scene;
  final dynamic _m;

  static final Map<String, Float32List> _zb = {};
  static final Map<String, SetBakes> _bakes = {};

  /// Baked depth (`baked.zb`, matching noche-preview.html `window.DEPTH.z`).
  Float32List _zbOf(String key) => _zb['${scene.id}:$key'] ??= () {
    final bakes = _bakes[scene.id] ??= SetBakes(scene);
    final baked = bakes.bakeKey(key);
    return Float32List.fromList(baked.zb);
  }();

  final List<NocheBreach> breaches = [];
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
  double? _cachedOY;
  double? _cachedCos;
  double? _cachedBias;
  int? _cachedX0;

  static final Expando<int> _spriteIds = Expando<int>();
  static int _nextSpriteId = 1;
  static int _spriteId(Sprite s) => _spriteIds[s] ??= _nextSpriteId++;

  static const int _maxCacheEntries = 4096;
  static final Map<String, List<({String rule, String what})>> _frameCache = {};

  static const Set<String> _inViewTags = {
    'coqui',
    'cosa:bufanda',
    'cosa:lana',
    'cosa:libro',
    'cosa:jugo',
    'cosa:flan',
    'cosa:queso',
    'cosa:frutas',
    'cosa:vela',
    'persona:abuela',
    'persona:abuelo',
    'persona:luis',
    'persona:carmen',
    'persona:perro',
  };

  static const Set<String> _seatedSpots = {
    'sofa1',
    'sofa2',
    'sofa3',
    'butaca',
    'silla1',
    'silla2',
    'silla3',
    'silla4',
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

    final sig = StringBuffer()
      ..write(scene.id)
      ..write('|')
      ..write(setKey)
      ..write('|')
      ..write(story);
    for (final k in _nochePersonas) {
      final p = gente[k] as Map?;
      if (p == null) continue;
      sig
        ..write('|')
        ..write(k)
        ..write('=')
        ..write(p['vis'])
        ..write(':')
        ..write(p['spot'])
        ..write(':')
        ..write(p['x'])
        ..write(',')
        ..write(p['y'])
        ..write(',')
        ..write(p['z'])
        ..write(':')
        ..write(p['pose'])
        ..write(':')
        ..write(p['lying']);
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
        ..write(it.lying)
        ..write(',')
        ..write(it.lyingZ)
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
            bool lying,
            double lyingZ,
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
              lying: it.lying as bool,
              lyingZ: (it.lyingZ as num).toDouble(),
              ink: _inkOf(it.s as Sprite),
            ),
        ];

    final sVal = _cachedS ??= (_m.places.e.S as num).toDouble();
    final oyVal = _cachedOY ??= (_m.places.e.OY as num).toDouble();
    final cos = _cachedCos ??= (_m.places.e.COS as num).toDouble();
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
        bool lying,
        double lyingZ,
        List<int>? ink,
      })
      f,
      int Y,
    ) {
      if (f.overlay) return f.d;
      if (f.lying) {
        return (((Y + .5) - oyVal + f.lyingZ * 22.5) / (sVal / 2)) * cos +
            f.lyingZ * .5;
      }
      return f.d + (f.sy - (Y + .5)) * _t30 / sVal;
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
            if (op > best || (j > idx && op >= plane - .001)) {
              if (op > best) best = op;
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

    int boxCoveredBy(List<int> box, {bool Function(String? tag)? only}) {
      final bx0 = box[0],
          by0 = box[1],
          bx1 = box[0] + box[2],
          by1 = box[1] + box[3];
      var hit = 0;
      for (final it in items) {
        if (only != null && !only(it.tag)) continue;
        final ink = it.ink;
        if (ink == null) continue;
        if (it.left + ink[2] < bx0 ||
            it.left + ink[0] >= bx1 ||
            it.top + ink[3] < by0 ||
            it.top + ink[1] >= by1) {
          continue;
        }
        for (var y = ink[1]; y <= ink[3]; y++) {
          final Y = it.top + y;
          if (Y < by0 || Y >= by1) continue;
          final plane = planeOf(it, Y);
          for (var x = ink[0]; x <= ink[2]; x++) {
            final X = it.left + x;
            if (X < bx0 || X >= bx1) continue;
            if (it.s.px[y * it.s.w + x] >>> 24 == 0) continue;
            if (!it.overlay && zb[Y * 240 + X] > plane + bias) continue;
            hit++;
          }
        }
      }
      return hit;
    }

    // 1. frog-seen (plus frog-arm, frog-sideboard, frog-sill)
    final frogIdx = items.indexWhere((it) => it.tag == 'coqui');
    if (cq != null && jsTruthy(cq['vis'])) {
      if (frogIdx < 0) {
        addBreach('frog-seen', 'cq.vis is truthy but no coqui sprite placed');
      } else {
        final r = covOf(frogIdx, ignore: (t) => t == 'fx:bufanda_cuello');
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

    // 3. heads-clear (everyone sitting on sofa1..3, butaca, silla1..4)
    for (final k in _nochePersonas) {
      final p = gente[k] as Map?;
      if (p == null || !jsTruthy(p['vis'])) continue;
      final sp = p['spot'] as String?;
      if (sp == null || !_seatedSpots.contains(sp)) continue;
      final idx = items.indexWhere((it) => it.tag == 'persona:$k');
      if (idx < 0) {
        addBreach(
          'heads-clear',
          'visible seated $k at $sp has no placed persona:$k sprite',
        );
        continue;
      }
      final ignorePaper = k == 'abuelo' && p['pose'] == 'zzz';
      final r = covOf(
        idx,
        maxRowsFromTop: 14,
        ignore: ignorePaper ? (t) => t == 'fx:periodico' : null,
      );
      if (r.hid > 0 || r.cov > 0 || r.out > 0) {
        addBreach(
          'heads-clear',
          '$k at $sp head hid=${r.hid} cov=${r.cov} (${r.by}) out=${r.out}',
        );
      }
    }

    // 4. bed-heads (cama1, cama2: top 14 rows inside arch hole with 0 hid/cov/out)
    for (final k in const ['luis', 'carmen']) {
      final p = gente[k] as Map?;
      if (p == null || !jsTruthy(p['vis']) || !jsTruthy(p['lying'])) continue;
      final sp = p['spot'] as String?;
      final idx = items.indexWhere((it) => it.tag == 'persona:$k');
      if (idx < 0) {
        addBreach('bed-heads', 'lying $k at $sp has no placed sprite');
        continue;
      }
      final r = covOf(idx, maxRowsFromTop: 14);
      if (r.hid > 0 || r.cov > 0 || r.out > 0) {
        addBreach(
          'bed-heads',
          '$k in $sp head hid=${r.hid} cov=${r.cov} (${r.by}) out=${r.out}',
        );
      }
    }

    // 5. lamps-tv-clear (105 & 107)
    if (story == 105 || story == 107) {
      for (final thing in const ['luz1', 'luz2', 'luz3', 'television']) {
        final box = (_m.places.box(thing) as List).cast<int>();
        final cov = boxCoveredBy(box);
        if (cov > 0) {
          addBreach('lamps-tv-clear', '$thing $box covered by $cov sprite px');
        }
      }
    }

    // 6. sideboard-clear (106)
    if (story == 106) {
      for (final tag in const [
        'cosa:jugo',
        'cosa:flan',
        'cosa:queso',
        'cosa:frutas',
        'cosa:vela',
      ]) {
        final idx = items.indexWhere((it) => it.tag == tag);
        if (idx < 0) {
          addBreach('sideboard-clear', 'missing $tag in story 106');
          continue;
        }
        // Sheet sideboard spots pack adjacent dishes 4-7 px apart; check against characters and fx.
        final r = covOf(idx, ignore: (t) => t != null && t.startsWith('cosa:'));
        if (r.hid > 0 || r.cov > 0 || r.out > 0) {
          addBreach(
            'sideboard-clear',
            '$tag hid=${r.hid} cov=${r.cov} (${r.by}) out=${r.out}',
          );
        }
      }
    }

    // 7. sprites-apart (all visible characters + frog)
    final chars = <({String id, int sx, int sy, bool frog})>[];
    for (final k in _nochePersonas) {
      final p = gente[k] as Map?;
      if (p == null || !jsTruthy(p['vis'])) continue;
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
