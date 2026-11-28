// El pedido's rules (pedido-sheet.json's 10 rules and checks, and page 13's "The sheet's rules hold in the scene"),
// checked on the real scene's frame at every act's end and at the story's end:
// - frog-seen: when cq.vis is truthy, a `coqui` item exists and has 0 px hidden by the set, outside [22, 218) x [0, 216),
//   or under a nearer sprite;
// - spots-in-view: every visible person and interactive sprite lies inside [22, 218) x [0, 216);
// - heads-clear: every seated person at a table (abuela, abuelo, luis, carmen, senor, senora, joven, mujer) has top 14
//   drawn rows with 0 px hidden by the set, covered by any nearer sprite, or outside the window;
// - cocinero-head: cocinero at hueco has top 14 drawn rows inside the hatch hole (x 97.9..196.7, y 7.05..43.5), 0 px
//   hidden by the set, 0 px covered by any nearer sprite;
// - plates-clear: shelf plates (`cosa:plato1..3`) and small plate / frog's plate (`cosa:platito`) have 0 px hidden by
//   the set, covered by any nearer sprite, or outside the window;
// - frog-shelf: when frog is at repisa_coqui, frog covers 0 px of the bell box (`campana`) and 0 px of any shelf plate;
// - panels-clear: the eight board panels (`cuadro1..4`, `bcuadro1..4`) have 0 px covered by anyone (board pictures
//   `cuadro:*` / `bcuadro:*` excepted);
// - drinks-clear: drinks (`cosa:bebida1..3`) and tall glass (`cosa:vasito`) have 0 px hidden by the set, covered by any
//   nearer sprite, outside the window, and cover 0 px of any seated person's head (top 14 rows);
// - guests-chest: guests at otra_mesa1..2 (senor, senora, joven, mujer) have top 30 drawn rows with 0 px hidden by the
//   set, covered by any nearer sprite, or outside the window;
// - sprites-apart: no two visible characters (people, cat, frog) overlap sideways unless their feet are >= 12 px apart.
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/coqui_scenes.dart';

/// What went against a rule: when, which rule, the details.
typedef PedidoBreach = ({String at, String rule, String what});

final double _t30 = math.tan(math.pi / 6);

/// Watches a real El pedido while a story plays: [wrap] its acts, then read [breaches] and [checked].
class PedidoRules {
  PedidoRules(this.scene) : _m = scene {
    if (scene.id != 'pedido') {
      throw StateError('PedidoRules expects scene "pedido", got "${scene.id}"');
    }
  }

  final SetScene scene;
  final dynamic _m;

  static final Map<String, Float32List> _zb = {};
  static final Map<String, SetBakes> _bakes = {};

  /// Baked set depth for [key] (`noche`).
  Float32List _zbOf(String key) => _zb['${scene.id}:$key'] ??= () {
    final bakes = _bakes[scene.id] ??= SetBakes(scene);
    final baked = bakes.bakeKey(key);
    return Float32List.fromList(baked.zb);
  }();

  final List<PedidoBreach> breaches = [];
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
  List<int>? _cachedCampana;
  List<(String, List<int>)>? _cachedPanels;

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
    'persona:cocinero',
    'persona:mesera',
    'persona:mesero',
    'persona:senor',
    'persona:senora',
    'persona:joven',
    'persona:mujer',
    'cosa:plato1',
    'cosa:plato2',
    'cosa:plato3',
    'cosa:platito',
    'cosa:bebida1',
    'cosa:bebida2',
    'cosa:bebida3',
    'cosa:vasito',
    'cosa:platanos',
    'cosa:gato',
    'cuadro:cuadro1',
    'cuadro:cuadro2',
    'cuadro:cuadro3',
    'cuadro:cuadro4',
    'bcuadro:bcuadro1',
    'bcuadro:bcuadro2',
    'bcuadro:bcuadro3',
    'bcuadro:bcuadro4',
  };

  static const Set<String> _seatedTags = {
    'persona:abuela',
    'persona:abuelo',
    'persona:luis',
    'persona:carmen',
    'persona:senor',
    'persona:senora',
    'persona:joven',
    'persona:mujer',
  };

  static const Set<String> _guestTags = {
    'persona:senor',
    'persona:senora',
    'persona:joven',
    'persona:mujer',
  };

  static const Set<String> _plateTags = {
    'cosa:plato1',
    'cosa:plato2',
    'cosa:plato3',
    'cosa:platito',
  };

  static const Set<String> _drinkTags = {
    'cosa:bebida1',
    'cosa:bebida2',
    'cosa:bebida3',
    'cosa:vasito',
  };

  static const List<String> _allPeople = [
    'abuela',
    'abuelo',
    'luis',
    'carmen',
    'cocinero',
    'mesera',
    'mesero',
    'senor',
    'senora',
    'joven',
    'mujer',
  ];

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
      ..write(story)
      ..write('|gato:')
      ..write(W['gatoVis']);
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
        final r = covOf(frogIdx);
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

    // 3. heads-clear (top 14 drawn rows of every seated person at a table)
    for (var i = 0; i < items.length; i++) {
      final tag = items[i].tag;
      if (tag == null || !_seatedTags.contains(tag)) continue;
      final r = covOf(i, maxRowsFromTop: 14);
      if (r.hid > 0 || r.cov > 0 || r.out > 0) {
        addBreach(
          'heads-clear',
          '$tag head hid=${r.hid} cov=${r.cov} (${r.by}) out=${r.out}',
        );
      }
    }

    // 4. cocinero-head (top 14 drawn rows inside hatch hole x 97.9..196.7, y 7.05..43.5, 0 hid, 0 cov)
    final cocIdx = items.indexWhere((it) => it.tag == 'persona:cocinero');
    if (cocIdx >= 0) {
      final coc = items[cocIdx];
      final ink = coc.ink;
      if (ink != null) {
        final yEnd = math.min(ink[3], ink[1] + 13);
        var outHole = 0;
        for (var y = ink[1]; y <= yEnd; y++) {
          final Y = coc.top + y;
          for (var x = ink[0]; x <= ink[2]; x++) {
            if (coc.s.px[y * coc.s.w + x] >>> 24 == 0) continue;
            final X = coc.left + x;
            if (X < 97.9 || X > 196.7 || Y < 7.05 || Y > 43.5) outHole++;
          }
        }
        final r = covOf(cocIdx, maxRowsFromTop: 14);
        if (outHole > 0 || r.hid > 0 || r.cov > 0 || r.out > 0) {
          addBreach(
            'cocinero-head',
            'cocinero head outHole=$outHole hid=${r.hid} cov=${r.cov} (${r.by}) out=${r.out}',
          );
        }
      }
    }

    // 5. plates-clear (repisa1..3 and platito)
    for (var i = 0; i < items.length; i++) {
      final tag = items[i].tag;
      if (tag == null || !_plateTags.contains(tag)) continue;
      final r = covOf(i);
      if (r.hid > 0 || r.cov > 0 || r.out > 0) {
        addBreach(
          'plates-clear',
          '$tag hid=${r.hid} cov=${r.cov} (${r.by}) out=${r.out}',
        );
      }
    }

    // 6. frog-shelf (when frog is at repisa_coqui, covers 0 px of campana box and 0 px of any shelf plate)
    if (frogIdx >= 0 && cq != null && cq['spot'] == 'repisa_coqui') {
      final campana = _cachedCampana ??= (_m.places.box('campana') as List)
          .cast<int>();
      final f = items[frogIdx];
      final ink = f.ink;
      if (ink != null) {
        var onBell = 0;
        for (var y = ink[1]; y <= ink[3]; y++) {
          final Y = f.top + y;
          if (Y < campana[1] || Y >= campana[1] + campana[3]) continue;
          for (var x = ink[0]; x <= ink[2]; x++) {
            final X = f.left + x;
            if (X < campana[0] || X >= campana[0] + campana[2]) continue;
            if (f.s.px[y * f.s.w + x] >>> 24 != 0) onBell++;
          }
        }
        if (onBell > 0) {
          addBreach(
            'frog-shelf',
            'frog at repisa_coqui covers $onBell px of bell box $campana',
          );
        }
        for (var i = 0; i < items.length; i++) {
          final tag = items[i].tag;
          if (tag == null || !_plateTags.contains(tag)) continue;
          final r = covOf(i, ignore: (t) => t != 'coqui');
          if (r.cov > 0) {
            addBreach(
              'frog-shelf',
              'frog at repisa_coqui covers ${r.cov} px of $tag',
            );
          }
        }
      }
    }

    // 7. panels-clear (the 8 board panels covered by nobody, board pictures excepted)
    final panels = _cachedPanels ??= [
      for (final name in const [
        'cuadro1',
        'cuadro2',
        'cuadro3',
        'cuadro4',
        'bcuadro1',
        'bcuadro2',
        'bcuadro3',
        'bcuadro4',
      ])
        (name, (_m.places.box(name) as List).cast<int>()),
    ];
    for (final (name, box) in panels) {
      final bx0 = box[0],
          by0 = box[1],
          bx1 = box[0] + box[2],
          by1 = box[1] + box[3];
      for (final it in items) {
        final tag = it.tag;
        if (tag != null &&
            (tag.startsWith('cuadro:') || tag.startsWith('bcuadro:'))) {
          continue;
        }
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
          final plane = it.overlay
              ? it.d
              : it.d + (it.sy - (Y + .5)) * _t30 / S;
          for (var x = ink[0]; x <= ink[2]; x++) {
            final X = it.left + x;
            if (X < bx0 || X >= bx1) continue;
            if (it.s.px[y * it.s.w + x] >>> 24 == 0) continue;
            if (!it.overlay && zb[Y * 240 + X] > plane + bias) continue;
            hit++;
          }
        }
        if (hit > 0) {
          addBreach('panels-clear', '$tag covers $hit px of panel $name $box');
        }
      }
    }

    // 8. drinks-clear (bebida1..3 and vasito: clear of everything and cover 0 px of any seated head)
    for (var i = 0; i < items.length; i++) {
      final tag = items[i].tag;
      if (tag == null || !_drinkTags.contains(tag)) continue;
      final r = covOf(i);
      if (r.hid > 0 || r.cov > 0 || r.out > 0) {
        addBreach(
          'drinks-clear',
          '$tag hid=${r.hid} cov=${r.cov} (${r.by}) out=${r.out}',
        );
      }
    }
    for (var i = 0; i < items.length; i++) {
      final tag = items[i].tag;
      if (tag == null || !_seatedTags.contains(tag)) continue;
      final r = covOf(
        i,
        maxRowsFromTop: 14,
        ignore: (t) => t == null || !_drinkTags.contains(t),
      );
      if (r.cov > 0) {
        addBreach(
          'drinks-clear',
          'drink covers ${r.cov} px (${r.by}) of $tag head',
        );
      }
    }

    // 9. guests-chest (top 30 drawn rows of guests at otra_mesa1..2)
    for (var i = 0; i < items.length; i++) {
      final tag = items[i].tag;
      if (tag == null || !_guestTags.contains(tag)) continue;
      final r = covOf(i, maxRowsFromTop: 30);
      if (r.hid > 0 || r.cov > 0 || r.out > 0) {
        addBreach(
          'guests-chest',
          '$tag chest hid=${r.hid} cov=${r.cov} (${r.by}) out=${r.out}',
        );
      }
    }

    // 10. sprites-apart (characters: all visible people + cat + frog)
    final chars = <({String id, int sx, int sy, String kind})>[];
    for (final k in _allPeople) {
      final p = gente[k] as Map?;
      if (p == null || !jsTruthy(p['vis'])) continue;
      final at = _m.places.atWorld(p['x'] as num, p['y'] as num, p['z'] as num);
      chars.add((
        id: k,
        sx: ((at.sx as num) + 0.5).floor(),
        sy: ((at.sy as num) + 0.5).floor(),
        kind: 'person',
      ));
    }
    if (jsTruthy(W['gatoVis'])) {
      final at = _m.places.at('banquito');
      chars.add((
        id: 'gato',
        sx: ((at.sx as num) + 0.5).floor(),
        sy: ((at.sy as num) + 0.5).floor(),
        kind: 'gato',
      ));
    }
    if (cq != null && jsTruthy(cq['vis'])) {
      final sp = cq['spot'];
      if (sp is String && (_m.places.has(sp) as bool)) {
        final at = _m.places.at(sp);
        chars.add((
          id: 'coqui',
          sx: ((at.sx as num) + 0.5).floor(),
          sy: ((at.sy as num) + 0.5).floor(),
          kind: 'coqui',
        ));
      } else {
        addBreach('scene-state', 'cq.vis is truthy with unknown spot "$sp"');
      }
    }
    for (var i = 0; i < chars.length; i++) {
      for (var j = i + 1; j < chars.length; j++) {
        final a = chars[i], b = chars[j];
        final across = (a.sx - b.sx).abs();
        final down = (a.sy - b.sy).abs();
        final needAcross = (a.kind == 'coqui' || b.kind == 'coqui')
            ? 28
            : (a.kind == 'gato' || b.kind == 'gato')
            ? 22
            : 24;
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
