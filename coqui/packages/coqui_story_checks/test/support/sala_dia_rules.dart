// La sala, de día's rules (sala_dia-sheet.json's checks, and page 13's "The sheet's rules hold in the scene"),
// checked on the real scene's frame at every act's end and at the story's end:
// - frog-seen: when cq.vis is truthy, a `coqui` item exists and has 0 px hidden by the set, outside [22, 218) x [0, 216),
//   or under a nearer sprite;
// - spots-in-view: every visible person and interactive sprite lies inside [22, 218) x [0, 216);
// - heads-clear: every seated person (abuelo, luis, carmen) has top 14 drawn rows with 0 px hidden by the set, covered
//   by any nearer sprite, or outside the window;
// - low-table: children on cushions (cojin1, cojin2) are hidden by the set only below sprite row 25 of their ink
//   (the chest — 0 px hidden above sprite row 25);
// - desk-head: Luis at escritorio has top 14 head rows with 0 px hidden by the set, 0 px over computadora's box
//   [31, 55, 17, 13], 0 px covered by any nearer sprite;
// - touch-clear: interactive table props (libro, papel, telefono, pagina1..pagina3, estrellas) have 0 px hidden by the
//   set, 0 px covered by any nearer sprite, 0 px outside the window;
// - frog-brazo: when frog is at brazo_coqui and abuelo is visible, frog covers 0 px of oreja_abuelo and boca_abuelo;
// - sprites-apart: no two visible characters (people, frog) overlap sideways unless their feet are >= 12 px apart.
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/coqui_scenes.dart';

/// What went against a rule: when, which rule, the details.
typedef SalaDiaBreach = ({String at, String rule, String what});

final double _t30 = math.tan(math.pi / 6);

/// Watches a real La sala, de día while a story plays: [wrap] its acts, then read [breaches] and [checked].
class SalaDiaRules {
  SalaDiaRules(this.scene) : _m = scene {
    if (scene.id != 'sala_dia') {
      throw StateError(
        'SalaDiaRules expects scene "sala_dia", got "${scene.id}"',
      );
    }
  }

  final SetScene scene;
  final dynamic _m;

  static final Map<String, Float32List> _zb = {};
  static final Map<String, SetBakes> _bakes = {};

  /// Baked set depth for [key] (`0` or `1`).
  Float32List _zbOf(String key) => _zb['${scene.id}:$key'] ??= () {
    final bakes = _bakes[scene.id] ??= SetBakes(scene);
    final baked = bakes.bakeKey(key);
    return Float32List.fromList(baked.zb);
  }();

  final List<SalaDiaBreach> breaches = [];
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
  List<int>? _cachedView;
  List<int>? _cachedCompu;
  List<int>? _cachedOreja;
  List<int>? _cachedBoca;

  static final Expando<int> _spriteIds = Expando<int>();
  static int _nextSpriteId = 1;
  static int _spriteId(Sprite s) => _spriteIds[s] ??= _nextSpriteId++;

  static const int _maxCacheEntries = 4096;
  static final Map<String, List<({String rule, String what})>> _frameCache = {};

  static const Set<String> _inViewTags = {
    'coqui',
    'persona:abuelo',
    'persona:luis',
    'persona:carmen',
    'persona:abuela',
    'cosa:libro',
    'cosa:papel',
    'cosa:telefono',
    'cosa:pagina1',
    'cosa:pagina2',
    'cosa:pagina3',
    'cosa:estrellas',
    'cosa:foto',
  };

  static const Set<String> _seatedTags = {
    'persona:abuelo',
    'persona:luis',
    'persona:carmen',
  };

  static const Set<String> _touchClearTags = {
    'cosa:libro',
    'cosa:papel',
    'cosa:telefono',
    'cosa:pagina1',
    'cosa:pagina2',
    'cosa:pagina3',
    'cosa:estrellas',
  };

  static const Set<String> _characterTags = {
    'coqui',
    'persona:abuelo',
    'persona:luis',
    'persona:carmen',
    'persona:abuela',
  };

  static bool _inBox(int x, int y, List<int> b) =>
      x >= b[0] && x < b[0] + b[2] && y >= b[1] && y < b[1] + b[3];

  void check(String at) {
    checked++;
    final w = scene.host.W;
    final key = scene.setKey(w);
    final S = _cachedS ??= scene.projection.S;
    final bias = _cachedBias ??= _m.places.bias as double;
    final view = _cachedView ??= [
      for (final n in (_m.places.view('wide') as List)) (n as num).toInt(),
    ];
    final x0 = view[0];
    final x1 = x0 + view[2];
    final compu = _cachedCompu ??= (_m.places.box('computadora') as List<int>);
    final oreja = _cachedOreja ??= (_m.places.box('oreja_abuelo') as List<int>);
    final boca = _cachedBoca ??= (_m.places.box('boca_abuelo') as List<int>);

    final list = (_m.placed(w, 0) as List);
    final gente = (w['gente'] as Map?) ?? const {};
    final luisSpot = (gente['luis'] as Map?)?['spot'] as String? ?? '';
    final carmenSpot = (gente['carmen'] as Map?)?['spot'] as String? ?? '';
    final abueloVis = jsTruthy((gente['abuelo'] as Map?)?['vis']);
    final cqMap = w['cq'] as Map?;
    final cqVis = cqMap != null && jsTruthy(cqMap['vis']);
    final cqSpot = (cqMap?['spot'] as String?) ?? '';

    final keyBuf = StringBuffer()
      ..write(key)
      ..write('|')
      ..write(luisSpot)
      ..write('|')
      ..write(carmenSpot)
      ..write('|')
      ..write(abueloVis ? '1' : '0')
      ..write('|')
      ..write(cqVis ? cqSpot : '0');
    for (final it in list) {
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
        ..write((it.d as double).toStringAsFixed(4))
        ..write(',')
        ..write((it.overlay as bool) ? '1' : '0');
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
    final w0 = scene.SW, h0 = view[3];
    final topZ = Float32List(w0 * h0)..fillRange(0, w0 * h0, -1e9);
    final topIdx = Int32List(w0 * h0)..fillRange(0, w0 * h0, -1);

    for (var idx = 0; idx < list.length; idx++) {
      final it = list[idx];
      final sp = it.s as Sprite;
      final left = it.left as int, top = it.top as int;
      final sy = it.sy as num;
      final d = it.d as double;
      final overlay = it.overlay as bool;
      for (var py = 0; py < sp.h; py++) {
        final Y = top + py;
        if (Y < 0 || Y >= h0) continue;
        final plane = overlay ? d : d + (sy - (Y + .5)) * _t30 / S;
        final row = Y * w0, srow = py * sp.w;
        for (var px = 0; px < sp.w; px++) {
          if (sp.px[srow + px] >>> 24 == 0) continue;
          final X = left + px;
          if (X < 0 || X >= w0) continue;
          final i = row + X;
          if (!overlay && zb[i] > plane + bias) continue;
          if (topZ[i] > plane + .001) continue;
          topZ[i] = plane;
          topIdx[i] = idx;
        }
      }
    }

    // 1. frog-seen
    if (cqVis) {
      var foundFrog = false;
      for (var idx = 0; idx < list.length; idx++) {
        final it = list[idx];
        if (it.tag != 'coqui') continue;
        foundFrog = true;
        final sp = it.s as Sprite;
        final left = it.left as int, top = it.top as int;
        final sy = it.sy as num;
        final d = it.d as double;
        final overlay = it.overlay as bool;
        var hidden = 0, covered = 0, outWin = 0;
        var coverOreja = 0, coverBoca = 0;
        for (var py = 0; py < sp.h; py++) {
          final Y = top + py;
          final plane = overlay ? d : d + (sy - (Y + .5)) * _t30 / S;
          for (var px = 0; px < sp.w; px++) {
            if (sp.px[py * sp.w + px] >>> 24 == 0) continue;
            final X = left + px;
            if (X < x0 || X >= x1 || Y < 0 || Y >= h0) {
              outWin++;
              continue;
            }
            final i = Y * w0 + X;
            if (!overlay && zb[i] > plane + bias) {
              hidden++;
              continue;
            }
            if (topIdx[i] != idx) {
              covered++;
            } else if (cqSpot == 'brazo_coqui' && abueloVis) {
              if (_inBox(X, Y, oreja)) coverOreja++;
              if (_inBox(X, Y, boca)) coverBoca++;
            }
          }
        }
        if (hidden > 0 || covered > 0 || outWin > 0) {
          fail(
            'frog-seen',
            'coqui at $cqSpot: hidden=$hidden covered=$covered out=$outWin',
          );
        }
        if (coverOreja > 0 || coverBoca > 0) {
          fail(
            'frog-brazo',
            'coqui at brazo_coqui covers oreja=$coverOreja boca=$coverBoca',
          );
        }
      }
      if (!foundFrog) fail('frog-seen', 'cq.vis is truthy but no coqui item');
    }

    // 2. spots-in-view, heads-clear, low-table, desk-head, touch-clear
    final charBoxes = <({String tag, int x0, int x1, int sy})>[];
    for (var idx = 0; idx < list.length; idx++) {
      final it = list[idx];
      final tag = it.tag as String?;
      if (tag == null) continue;
      final sp = it.s as Sprite;
      final ink = _inkOf(sp);
      if (ink == null) continue;
      final left = it.left as int, top = it.top as int;
      final sy = (it.sy as num).round();
      final d = it.d as double;
      final overlay = it.overlay as bool;
      final gx0 = left + ink[0], gy0 = top + ink[1];
      final gx1 = left + ink[2], gy1 = top + ink[3];

      if (_inViewTags.contains(tag)) {
        if (gx0 < x0 || gx1 >= x1 || gy0 < 0 || gy1 >= h0) {
          fail(
            'spots-in-view',
            '$tag bounds [$gx0..$gx1, $gy0..$gy1] outside [$x0..${x1 - 1}, 0..215]',
          );
        }
      }

      if (_characterTags.contains(tag)) {
        charBoxes.add((tag: tag, x0: gx0, x1: gx1, sy: sy));
      }

      if (_seatedTags.contains(tag)) {
        final headEnd = gy0 + 14;
        var headHidden = 0, headCovered = 0, headOut = 0, headOverCompu = 0;
        var aboveChestHidden = 0;
        final checkLowTable =
            (tag == 'persona:luis' && luisSpot == 'cojin1') ||
            (tag == 'persona:carmen' && carmenSpot == 'cojin2');
        final checkDeskHead = tag == 'persona:luis' && luisSpot == 'escritorio';

        for (var py = ink[1]; py <= ink[3]; py++) {
          final Y = top + py;
          final plane = overlay ? d : d + (it.sy - (Y + .5)) * _t30 / S;
          final isHead = Y >= gy0 && Y < headEnd;
          final aboveChest = (py - ink[1]) < 25;
          for (var px = ink[0]; px <= ink[2]; px++) {
            if (sp.px[py * sp.w + px] >>> 24 == 0) continue;
            final X = left + px;
            if (X < x0 || X >= x1 || Y < 0 || Y >= h0) {
              if (isHead) headOut++;
              continue;
            }
            final i = Y * w0 + X;
            final isHidden = !overlay && zb[i] > plane + bias;
            if (isHead) {
              if (isHidden) {
                headHidden++;
              } else if (topIdx[i] != idx) {
                headCovered++;
              }
              if (checkDeskHead && _inBox(X, Y, compu)) headOverCompu++;
            }
            if (checkLowTable && aboveChest && isHidden) {
              aboveChestHidden++;
            }
          }
        }
        if (headHidden > 0 || headCovered > 0 || headOut > 0) {
          fail(
            'heads-clear',
            '$tag head: hidden=$headHidden covered=$headCovered out=$headOut',
          );
        }
        if (checkLowTable && aboveChestHidden > 0) {
          fail(
            'low-table',
            '$tag hidden above chest (row 25): $aboveChestHidden px',
          );
        }
        if (checkDeskHead && headOverCompu > 0) {
          fail(
            'desk-head',
            'luis at escritorio head overlaps computadora: $headOverCompu px',
          );
        }
      }

      if (_touchClearTags.contains(tag)) {
        var hidden = 0, covered = 0, outWin = 0;
        for (var py = ink[1]; py <= ink[3]; py++) {
          final Y = top + py;
          final plane = overlay ? d : d + (it.sy - (Y + .5)) * _t30 / S;
          for (var px = ink[0]; px <= ink[2]; px++) {
            if (sp.px[py * sp.w + px] >>> 24 == 0) continue;
            final X = left + px;
            if (X < x0 || X >= x1 || Y < 0 || Y >= h0) {
              outWin++;
              continue;
            }
            final i = Y * w0 + X;
            if (!overlay && zb[i] > plane + bias) {
              hidden++;
            } else if (topIdx[i] != idx) {
              covered++;
            }
          }
        }
        if (hidden > 0 || covered > 0 || outWin > 0) {
          fail(
            'touch-clear',
            '$tag: hidden=$hidden covered=$covered out=$outWin',
          );
        }
      }
    }

    // 3. sprites-apart
    for (var i = 0; i < charBoxes.length; i++) {
      for (var j = i + 1; j < charBoxes.length; j++) {
        final a = charBoxes[i], b = charBoxes[j];
        final overlapX = a.x0 <= b.x1 && b.x0 <= a.x1;
        final dy = (a.sy - b.sy).abs();
        if (overlapX && dy < 12) {
          fail(
            'sprites-apart',
            '${a.tag} [${a.x0}..${a.x1}, sy=${a.sy}] ~ ${b.tag} [${b.x0}..${b.x1}, sy=${b.sy}] (dy=$dy < 12)',
          );
        }
      }
    }

    if (_frameCache.length >= _maxCacheEntries) _frameCache.clear();
    _frameCache[cacheKey] = frameBreaches;
    for (final b in frameBreaches) {
      breaches.add((at: at, rule: b.rule, what: b.what));
    }
  }
}
