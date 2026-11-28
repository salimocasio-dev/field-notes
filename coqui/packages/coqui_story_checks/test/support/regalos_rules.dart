// Los regalos's rules (regalos-sheet.json's checks, and page 13's "The sheet's rules hold in the scene"),
// checked on the real scene's frame at every act's end and at the story's end:
// - frog-seen: when cq.vis is truthy, a `coqui` item exists and has 0 px hidden by the set, outside [19, 215) x [0, 216),
//   or under a nearer sprite;
// - spots-in-view & curtain-in-window: every visible person, curtain, and interactive sprite lies inside [19, 215);
// - heads-behind-table: anyone standing at tras_mesa, tras_mesa2, or tras_mesa3 has top 14 drawn rows with 0 px hidden
//   by the set, covered by any nearer sprite, or outside the window;
// - fondo-head: when Carmen is visible at fondo2, her top 14 head rows stay inside the arch hole, 0 px hidden by set,
//   0 px covered by the curtain;
// - things-clear (bench-things, table-things, photos-cord, photos-table, cake, packet-stool): interactive props have
//   0 px hidden by the set and 0 px covered by any person or the frog (per regalos-sheet.json notes: thing-over-thing
//   such as fotos4 touching cake by 2 px is info);
// - step-clear: when abuelo stands on taburete, he covers 0 px of any photo or wall peg;
// - sprites-apart: no two visible characters (people, frog) overlap sideways unless their feet are >= 12 px apart.
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/coqui_scenes.dart';

/// What went against a rule: when, which rule, the details.
typedef RegalosBreach = ({String at, String rule, String what});

final double _t30 = math.tan(math.pi / 6);

/// Watches a real Los regalos while a story plays: [wrap] its acts, then read [breaches] and [checked].
class RegalosRules {
  RegalosRules(this.scene) : _m = scene {
    if (scene.id != 'regalos') {
      throw StateError(
        'RegalosRules expects scene "regalos", got "${scene.id}"',
      );
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

  final List<RegalosBreach> breaches = [];
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
  List<double>? _cachedArch;
  List<List<int>>? _cachedPegs;

  static final Expando<int> _spriteIds = Expando<int>();
  static int _nextSpriteId = 1;
  static int _spriteId(Sprite s) => _spriteIds[s] ??= _nextSpriteId++;

  static const int _maxCacheEntries = 4096;
  static final Map<String, List<({String rule, String what})>> _frameCache = {};

  static const Set<String> _inViewTags = {
    'coqui',
    'cosa:cortina',
    'persona:abuela',
    'persona:abuelo',
    'persona:luis',
    'persona:carmen',
    'persona:pepe',
    'persona:maestra',
    'persona:piraguero',
    'cosa:bizcocho',
    'cosa:regalo',
    'cosa:flores',
    'cosa:caja_velas',
    'cosa:foto_3m',
    'cosa:foto_7m',
    'cosa:foto_3a',
    'cosa:foto_7a',
    'cosa:paquete',
    'cosa:paquete_mesa1',
    'cosa:paquete_mesa2',
    'cosa:paquete_mesa3',
  };

  static const Set<String> _thingClearTags = {
    'cosa:bizcocho',
    'cosa:regalo',
    'cosa:flores',
    'cosa:caja_velas',
    'cosa:foto_3m',
    'cosa:foto_7m',
    'cosa:foto_3a',
    'cosa:foto_7a',
    'cosa:paquete',
    'cosa:paquete_mesa1',
    'cosa:paquete_mesa2',
    'cosa:paquete_mesa3',
  };

  static const Set<String> _characterTags = {
    'coqui',
    'persona:abuela',
    'persona:abuelo',
    'persona:luis',
    'persona:carmen',
    'persona:pepe',
    'persona:maestra',
    'persona:piraguero',
  };

  static const Set<String> _behindTableSpots = {
    'tras_mesa',
    'tras_mesa2',
    'tras_mesa3',
  };

  static bool _inBox(int x, int y, List<int> b) =>
      x >= b[0] && x < b[0] + b[2] && y >= b[1] && y < b[1] + b[3];

  void check(String at) {
    checked++;
    final w = scene.host.W;
    final key = scene.setKey(w);
    final S = _cachedS ??= scene.projection.S;
    final bias = _cachedBias ??= _m.places.bias as double;
    final x0 = _cachedX0 ??= ((_m.places.view('wide') as List)[0] as num)
        .toInt();
    final x1 = x0 + 196;
    final arch = _cachedArch ??= (_m.places.archBounds as List<double>);
    final pegs = _cachedPegs ??= (_m.places.pegBoxes as List<List<int>>);

    final list = (_m.placed(w, 0) as List);
    final gente = (w['gente'] as Map?) ?? const {};
    final cqMap = w['cq'] as Map?;
    final cqVis = cqMap != null && jsTruthy(cqMap['vis']);
    final cqSpot = (cqMap?['spot'] as String?) ?? '';

    final spotByTag = <String, String>{};
    for (final en in gente.entries) {
      final p = en.value as Map?;
      if (p != null && p['vis'] != 0 && p['spot'] is String) {
        spotByTag['persona:${en.key}'] = p['spot'] as String;
      }
    }

    final keyBuf = StringBuffer()
      ..write(key)
      ..write('|')
      ..write(cqVis ? cqSpot : '0');
    for (final en in spotByTag.entries) {
      keyBuf
        ..write('|')
        ..write(en.key)
        ..write('=')
        ..write(en.value);
    }
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
    const w0 = 240, h0 = 216;
    final topZ = Float32List(w0 * h0)..fillRange(0, w0 * h0, -1e9);
    final topIdx = Int32List(w0 * h0)..fillRange(0, w0 * h0, -1);
    final charZ = Float32List(w0 * h0)..fillRange(0, w0 * h0, -1e9);
    final charIdx = Int32List(w0 * h0)..fillRange(0, w0 * h0, -1);

    for (var idx = 0; idx < list.length; idx++) {
      final it = list[idx];
      final tag = it.tag as String?;
      final isChar = tag != null && _characterTags.contains(tag);
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
          if (topZ[i] <= plane + .001) {
            topZ[i] = plane;
            topIdx[i] = idx;
          }
          if (isChar && charZ[i] <= plane + .001) {
            charZ[i] = plane;
            charIdx[i] = idx;
          }
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
        var hidden = 0, covered = 0, outWin = 0;
        for (var py = 0; py < sp.h; py++) {
          final Y = top + py;
          final plane = d + (sy - (Y + .5)) * _t30 / S;
          for (var px = 0; px < sp.w; px++) {
            if (sp.px[py * sp.w + px] >>> 24 == 0) continue;
            final X = left + px;
            if (X < x0 || X >= x1 || Y < 0 || Y >= h0) {
              outWin++;
              continue;
            }
            final i = Y * w0 + X;
            if (zb[i] > plane + bias) {
              hidden++;
            } else if (topIdx[i] != idx) {
              covered++;
            }
          }
        }
        if (hidden > 0 || covered > 0 || outWin > 0) {
          fail(
            'frog-seen',
            'coqui at $cqSpot: hidden=$hidden covered=$covered out=$outWin',
          );
        }
      }
      if (!foundFrog) fail('frog-seen', 'cq.vis is truthy but no coqui item');
    }

    // 2. spots-in-view, heads-behind-table, fondo-head, things-clear, step-clear
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

      final spot = spotByTag[tag];
      if (spot != null && _behindTableSpots.contains(spot)) {
        final headEnd = gy0 + 14;
        var hidden = 0, covered = 0, outWin = 0;
        for (var py = ink[1]; py <= ink[3]; py++) {
          final Y = top + py;
          if (Y < gy0 || Y >= headEnd) continue;
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
            'heads-behind-table',
            '$tag at $spot head: hidden=$hidden covered=$covered out=$outWin',
          );
        }
      }

      if (tag == 'persona:carmen' && spot == 'fondo2') {
        final cortinaIdx = list.indexWhere((e) => e.tag == 'cosa:cortina');
        final headEnd = gy0 + 14;
        var outHole = 0, hidden = 0, behindCurtain = 0;
        for (var py = ink[1]; py <= ink[3]; py++) {
          final Y = top + py;
          if (Y < gy0 || Y >= headEnd) continue;
          final plane = overlay ? d : d + (it.sy - (Y + .5)) * _t30 / S;
          for (var px = ink[0]; px <= ink[2]; px++) {
            if (sp.px[py * sp.w + px] >>> 24 == 0) continue;
            final X = left + px;
            if (X < arch[0] || X > arch[1] || Y < arch[2] || Y > arch[3]) {
              outHole++;
              continue;
            }
            final i = Y * w0 + X;
            if (!overlay && zb[i] > plane + bias) {
              hidden++;
            } else if (cortinaIdx >= 0 && topIdx[i] == cortinaIdx) {
              behindCurtain++;
            }
          }
        }
        if (outHole > 0 || hidden > 0 || behindCurtain > 0) {
          fail(
            'fondo-head',
            'carmen at fondo2 head: outHole=$outHole hidden=$hidden behindCurtain=$behindCurtain',
          );
        }
      }

      if (tag == 'persona:abuelo' && spot == 'taburete') {
        var pegHits = 0;
        for (var py = ink[1]; py <= ink[3]; py++) {
          final Y = top + py;
          if (Y < 0 || Y >= h0) continue;
          final plane = overlay ? d : d + (it.sy - (Y + .5)) * _t30 / S;
          for (var px = ink[0]; px <= ink[2]; px++) {
            if (sp.px[py * sp.w + px] >>> 24 == 0) continue;
            final X = left + px;
            if (X < 0 || X >= w0) continue;
            if (!overlay && zb[Y * w0 + X] > plane + bias) continue;
            for (final pb in pegs) {
              if (_inBox(X, Y, pb)) pegHits++;
            }
          }
        }
        if (pegHits > 0) {
          fail('step-clear', 'abuelo at taburete covers $pegHits peg px');
        }
      }

      if (_thingClearTags.contains(tag)) {
        var hidden = 0, coveredByChar = 0, outWin = 0;
        final byWho = <String>{};
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
            } else if (charIdx[i] >= 0 && charZ[i] > plane + .001) {
              coveredByChar++;
              byWho.add('${list[charIdx[i]].tag}@($X,$Y)');
            }
          }
        }
        if (hidden > 0 || coveredByChar > 0 || outWin > 0) {
          fail(
            'things-clear',
            '$tag: hidden=$hidden coveredByChar=$coveredByChar(${byWho.take(3).join(',')}) out=$outWin',
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
