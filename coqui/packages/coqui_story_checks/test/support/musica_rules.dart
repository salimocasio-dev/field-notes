// La música's rules (musica-sheet.json's rules and checks, and page 13's "The sheet's rules hold in the scene"),
// checked on the real scene's frame at every act's end and at the story's end:
// - spots-in-view: every visible person, hanging instrument, microphone, paper note, and frog lies inside
//   [22, 218) x [0, 216);
// - frog-seen: when cq.vis is truthy, a `coqui` item must exist with non-empty ink and 0 px hidden by the set, outside
//   [22, 218) x [0, 216), or under a nearer sprite (excluding Coquí's own held `cosa:camara` and overlay FX);
// - heads-clear: every seated person (on `taburete1`, `taburete2`, `banco1..4`, or `banqueta_abuela`) has 0 px of their
//   top 14 drawn rows hidden by the set or covered;
// - rack-clear: when `cosa:guitarra` or `cosa:tambor` hangs on the rack in Story 111, it has 0 px hidden or covered and
//   Coquí at `borde_coqui` covers neither box;
// - notes-clear: when `nota1..3` are shown in Story 112, all 3 have 0 px hidden, covered, or outside the view;
// - mic-clear: when `cosa:microfono` is shown, it has 0 px hidden or covered by non-bounce sprites, and whoever stands
//   at `ante_micro` has 0 px of their top 14 rows hidden or covered;
// - ronda-heads: in Story 113 `ronda113`, none of the five participants covers another's top 14 head rows;
// - sprites-apart: no two visible characters overlap sideways unless anchors are >= 12 px apart up-down (28 px across
//   for `coqui` pairs, 24 px between people).
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/coqui_scenes.dart';

/// What went against a rule: when, which rule, the details.
typedef MusicaBreach = ({String at, String rule, String what});

final double _t30 = math.tan(math.pi / 6);

/// Watches a real La música while a story plays: [wrap] its acts, then read [breaches] and [checked].
class MusicaRules {
  MusicaRules(this.scene) : _m = scene {
    if (scene.id != 'musica') {
      throw StateError('MusicaRules expects scene "musica", got "${scene.id}"');
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

  final List<MusicaBreach> breaches = [];
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

  static const Set<String> _seatSpots = {
    'taburete1',
    'taburete2',
    'banco1',
    'banco2',
    'banco3',
    'banco4',
    'banqueta_abuela',
  };

  static const Set<String> _frogOwnProps = {
    'cosa:camara',
    'fx:flash',
    'fx:foto',
    'fx:notas',
    'fx:corazon',
    'fx:estrella',
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
    final cq = W['cq'] as Map<String, dynamic>?;

    final sig = StringBuffer()
      ..write(scene.id)
      ..write('|')
      ..write(setKey)
      ..write('|')
      ..write(story)
      ..write('|cq:')
      ..write(cq?['vis'])
      ..write(':')
      ..write(cq?['spot'])
      ..write(':')
      ..write(cq?['x'])
      ..write(',')
      ..write(cq?['y'])
      ..write(',')
      ..write(cq?['dy']);
    for (final en in gente.entries) {
      final p = en.value as Map?;
      sig
        ..write('|')
        ..write(en.key)
        ..write(':')
        ..write(p?['vis'])
        ..write(':')
        ..write(p?['spot'])
        ..write(':')
        ..write(p?['rondaRole']);
    }
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

    final frameBreaches = <({String rule, String what})>[];
    void add(String rule, String what) {
      frameBreaches.add((rule: rule, what: what));
      breaches.add((at: at, rule: rule, what: what));
    }

    final zb = _zbOf(setKey);
    final S = _cachedS ??= (_m.places.e.S as num).toDouble();
    final bias = _cachedBias ??= (_m.places.bias as num).toDouble();
    final x0 = _cachedX0 ??= (_m.places.view('wide')[0] as num).toInt();
    final x1 = x0 + 196;

    const w0 = 240, h0 = 216;
    const eps = .001;
    final frogDy = (cq?['dy'] as num?)?.toDouble() ?? 0.0;

    final fullZ = Float32List(w0 * h0)..fillRange(0, w0 * h0, -1e9);
    final noFrogFxZ = Float32List(w0 * h0)..fillRange(0, w0 * h0, -1e9);
    final noFrogBounceZ = Float32List(w0 * h0)..fillRange(0, w0 * h0, -1e9);

    final items =
        <
          ({
            String? tag,
            Sprite s,
            int left,
            int top,
            num sy,
            double d,
            bool overlay,
            List<int>? ink,
          })
        >[];

    for (final dynamic it in rawItems) {
      final s = it.s as Sprite;
      final tag = it.tag as String?;
      final left = it.left as int;
      final top = it.top as int;
      final sy = it.sy as num;
      final d = (it.d as num).toDouble();
      final overlay = it.overlay as bool;
      final ink = _inkOf(s);
      if (ink != null) {
        for (var py = ink[1]; py <= ink[3]; py++) {
          final Y = top + py;
          if (Y < 0 || Y >= h0) continue;
          final plane = overlay ? d : d + (sy - (Y + .5)) * _t30 / S;
          for (var px = ink[0]; px <= ink[2]; px++) {
            if (s.px[py * s.w + px] >>> 24 == 0) continue;
            final X = left + px;
            if (X < 0 || X >= w0) continue;
            final i = Y * w0 + X;
            if (!overlay && zb[i] > plane + bias) continue;
            if (plane >= fullZ[i] - eps) {
              fullZ[i] = plane;
            }
            if (!_frogOwnProps.contains(tag) &&
                !overlay &&
                plane >= noFrogFxZ[i] - eps) {
              noFrogFxZ[i] = plane;
            }
            if (!overlay &&
                !(tag == 'coqui' && frogDy < 0) &&
                !(tag == 'cosa:camara' && frogDy < 0) &&
                plane >= noFrogBounceZ[i] - eps) {
              noFrogBounceZ[i] = plane;
            }
          }
        }
      }
      items.add((
        tag: tag,
        s: s,
        left: left,
        top: top,
        sy: sy,
        d: d,
        overlay: overlay,
        ink: ink,
      ));
    }

    // 1. spots-in-view
    for (final it in items) {
      final tag = it.tag;
      if (tag == null || it.overlay) continue;
      final tracked =
          tag == 'coqui' ||
          tag.startsWith('persona:') ||
          tag == 'cosa:guitarra' ||
          tag == 'cosa:tambor' ||
          tag == 'cosa:microfono' ||
          tag.startsWith('nota:');
      if (!tracked) continue;
      final ink = it.ink;
      if (ink == null) continue;
      final ix0 = it.left + ink[0];
      final iy0 = it.top + ink[1];
      final ix1 = it.left + ink[2];
      final iy1 = it.top + ink[3];
      if (ix0 < x0 || ix1 >= x1 || iy0 < 0 || iy1 >= h0) {
        add(
          'spots-in-view',
          '$tag bounds [$ix0..$ix1, $iy0..$iy1] outside [$x0..${x1 - 1}, 0..215]',
        );
      }
    }

    // 2. frog-seen
    if (cq != null && jsTruthy(cq['vis'])) {
      final frog = items.where((it) => it.tag == 'coqui').toList();
      if (frog.isEmpty) {
        add('frog-seen', 'cq.vis is truthy but no coqui item was placed');
      } else if (frog.last.ink == null) {
        add('frog-seen', 'coqui item has empty ink');
      } else {
        final it = frog.last;
        final ink = it.ink!;
        var hidden = 0, covered = 0, outWin = 0;
        for (var py = ink[1]; py <= ink[3]; py++) {
          final Y = it.top + py;
          final plane = it.d + (it.sy - (Y + .5)) * _t30 / S;
          for (var px = ink[0]; px <= ink[2]; px++) {
            if (it.s.px[py * it.s.w + px] >>> 24 == 0) continue;
            final X = it.left + px;
            if (X < x0 || X >= x1 || Y < 0 || Y >= h0) {
              outWin++;
              continue;
            }
            final i = Y * w0 + X;
            if (zb[i] > plane + bias) {
              hidden++;
            } else if (noFrogFxZ[i] > plane + eps) {
              covered++;
            }
          }
        }
        if (hidden > 0 || covered > 0 || outWin > 0) {
          add(
            'frog-seen',
            'coqui at ${cq['spot']}: hidden=$hidden covered=$covered out=$outWin',
          );
        }
      }
    }

    // Helper for sprite visibility check (full or head rows)
    ({int hidden, int covered, int outWin}) checkCover(
      ({
        String? tag,
        Sprite s,
        int left,
        int top,
        num sy,
        double d,
        bool overlay,
        List<int>? ink,
      })
      it, {
      int? maxHeadRows,
      Float32List? zAgainst,
    }) {
      final ink = it.ink!;
      final headTop = it.top + ink[1];
      final headEnd = maxHeadRows == null ? h0 : headTop + maxHeadRows;
      final zBuf = zAgainst ?? fullZ;
      var hidden = 0, covered = 0, outWin = 0;
      for (var py = ink[1]; py <= ink[3]; py++) {
        final Y = it.top + py;
        if (Y >= headEnd) break;
        final plane = it.d + (it.sy - (Y + .5)) * _t30 / S;
        for (var px = ink[0]; px <= ink[2]; px++) {
          if (it.s.px[py * it.s.w + px] >>> 24 == 0) continue;
          final X = it.left + px;
          if (X < x0 || X >= x1 || Y < 0 || Y >= h0) {
            outWin++;
            continue;
          }
          final i = Y * w0 + X;
          if (zb[i] > plane + bias) {
            hidden++;
          } else if (zBuf[i] > plane + eps) {
            covered++;
          }
        }
      }
      return (hidden: hidden, covered: covered, outWin: outWin);
    }

    // 3. heads-clear (seated people)
    for (final en in gente.entries) {
      final who = en.key;
      final p = en.value as Map?;
      if (p == null || p['vis'] == 0) continue;
      final spot = p['spot'] as String?;
      if (spot == null || !_seatSpots.contains(spot)) continue;
      for (final it in items) {
        if (it.tag != 'persona:$who' || it.ink == null) continue;
        final r = checkCover(it, maxHeadRows: 14, zAgainst: noFrogBounceZ);
        if (r.hidden > 0 || r.covered > 0 || r.outWin > 0) {
          add(
            'heads-clear',
            '$who at $spot head: hidden=${r.hidden} covered=${r.covered} out=${r.outWin}',
          );
        }
      }
    }

    // 4. rack-clear (Story 111 rack instruments)
    if (story == 111) {
      for (final it in items) {
        if ((it.tag != 'cosa:guitarra' && it.tag != 'cosa:tambor') ||
            it.ink == null) {
          continue;
        }
        final r = checkCover(it, zAgainst: noFrogBounceZ);
        if (r.hidden > 0 || r.covered > 0 || r.outWin > 0) {
          add(
            'rack-clear',
            '${it.tag}: hidden=${r.hidden} covered=${r.covered} out=${r.outWin}',
          );
        }
      }
    }

    // 5. notes-clear (Story 112 hanging paper notes)
    if (story == 112) {
      for (final it in items) {
        if (it.tag == null || !it.tag!.startsWith('nota:') || it.ink == null) {
          continue;
        }
        final r = checkCover(it, zAgainst: noFrogFxZ);
        if (r.hidden > 0 || r.covered > 0 || r.outWin > 0) {
          add(
            'notes-clear',
            '${it.tag}: hidden=${r.hidden} covered=${r.covered} out=${r.outWin}',
          );
        }
      }
    }

    // 6. mic-clear (`cosa:microfono` + `ante_micro` head)
    for (final it in items) {
      if (it.tag == 'cosa:microfono' && it.ink != null) {
        final r = checkCover(it, zAgainst: noFrogBounceZ);
        if (r.hidden > 0 || r.covered > 0 || r.outWin > 0) {
          add(
            'mic-clear',
            'microfono: hidden=${r.hidden} covered=${r.covered} out=${r.outWin}',
          );
        }
      }
    }
    for (final en in gente.entries) {
      final who = en.key;
      final p = en.value as Map?;
      if (p == null || p['vis'] == 0 || p['spot'] != 'ante_micro') continue;
      for (final it in items) {
        if (it.tag != 'persona:$who' || it.ink == null) continue;
        final r = checkCover(it, maxHeadRows: 14, zAgainst: noFrogBounceZ);
        if (r.hidden > 0 || r.covered > 0) {
          add(
            'mic-clear',
            '$who at ante_micro head: hidden=${r.hidden} covered=${r.covered}',
          );
        }
      }
    }

    // 7. ronda-heads (Story 113 `ronda113` five participants)
    if (story == 113) {
      for (final en in gente.entries) {
        final who = en.key;
        final p = en.value as Map?;
        if (p == null || p['vis'] == 0 || p['rondaRole'] == null) continue;
        for (final it in items) {
          if (it.tag != 'persona:$who' || it.ink == null) continue;
          final r = checkCover(it, maxHeadRows: 14, zAgainst: noFrogBounceZ);
          if (r.hidden > 0 || r.covered > 0) {
            add(
              'ronda-heads',
              '$who (${p['rondaRole']} at ${p['spot']}) head: hidden=${r.hidden} covered=${r.covered}',
            );
          }
        }
      }
    }

    // 8. sprites-apart
    final chars =
        <({String tag, String? spot, double sx, num sy, double width})>[];
    for (final it in items) {
      if (it.tag == null || it.ink == null || it.overlay) continue;
      if (it.tag == 'coqui') {
        if (cq == null) continue;
        final fb = scene.host.frogBox(cq);
        chars.add((
          tag: 'coqui',
          spot: cq['spot'] as String?,
          sx: fb.x + fb.w / 2,
          sy: it.sy,
          width: 32.0,
        ));
      } else if (it.tag!.startsWith('persona:')) {
        final who = it.tag!.substring('persona:'.length);
        final p = gente[who] as Map?;
        final spot = p?['spot'] as String?;
        final seated = spot != null && _seatSpots.contains(spot);
        final ax = who == 'abuela' ? (seated ? 17.0 : 30.0) : 24.0;
        chars.add((
          tag: it.tag!,
          spot: spot,
          sx: it.left + ax,
          sy: it.sy,
          width: 24.0,
        ));
      }
    }
    for (var i = 0; i < chars.length; i++) {
      for (var j = i + 1; j < chars.length; j++) {
        final a = chars[i], b = chars[j];
        final needAcross = (a.width + b.width) / 2;
        final dx = (a.sx - b.sx).abs();
        final dy = (a.sy - b.sy).abs();
        if (dx < needAcross && dy < 12) {
          add(
            'sprites-apart',
            '${a.tag} [${a.sx},${a.sy}] ~ ${b.tag} [${b.sx},${b.sy}] (dx=$dx < $needAcross, dy=$dy < 12)',
          );
        }
      }
    }

    if (_frameCache.length >= _maxCacheEntries) _frameCache.clear();
    _frameCache[key] = frameBreaches;
  }
}
