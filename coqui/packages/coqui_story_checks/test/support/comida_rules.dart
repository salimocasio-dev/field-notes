// La comida's rules (comida-sheet.json's rules and checks, and page 13's "The sheet's rules hold in the scene"),
// checked on the real scene's frame at every act's end and at the story's end:
// - frog-seen: when cq.vis is truthy, a `coqui` item must exist and have 0 px hidden by the set, outside
//   [22, 218) x [0, 216), or under a nearer sprite (excluding frog's own worn FX);
// - spots-in-view: every visible person and interactive sprite lies inside [22, 218) x [0, 216);
// - heads-clear: seated family at the long table (abuela, abuelo, luis, carmen) have 0 px of their top 14 drawn rows
//   hidden by the set or covered by any nearer sprite;
// - table-things-clear: platillo1..3, jarra, vasos (story 90), sopa1..3 and ensalada (story 91) have 0 px hidden by
//   the set or covered by any nearer sprite;
// - shelf-things-clear: sal, azucar, hielo, servilletas (story 91) have 0 px hidden by the set or covered by any
//   nearer sprite;
// - frog-station: when the frog stands at auxiliar_coqui and shelf items are shown, his top drawn row lies below the
//   shelf items' bottom drawn row;
// - line-whole: in story 92, the pot box [30, 56, 21, 16] has 0 sprite px drawn over it, plato_perro has 0 covered or
//   hidden by the set, and any person standing at fila1 has 0 covered, 0 hidden by the set, and 0 outside the window;
// - line-feet: in story 92, the bottom 8 drawn rows of any person standing at fila1..3 have 0 px hidden by the set;
// - sprites-apart: no two visible characters overlap sideways unless their feet are 12 px or more apart up-down.
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/coqui_scenes.dart';

/// What went against a rule: when, which rule, the details.
typedef ComidaBreach = ({String at, String rule, String what});

final double _t30 = math.tan(math.pi / 6);

/// Watches a real La comida while a story plays: [wrap] its acts, then read [breaches] and [checked].
class ComidaRules {
  ComidaRules(this.scene) : _m = scene {
    if (scene.id != 'comida') {
      throw StateError('ComidaRules expects scene "comida", got "${scene.id}"');
    }
  }

  final SetScene scene;
  final dynamic _m;

  static final Map<String, Float32List> _zb = {};
  static final Map<String, SetBakes> _bakes = {};
  static final Map<String, Set<int>> _potPixels = {};

  Float32List _zbOf(String key) => _zb['${scene.id}:$key'] ??= () {
    final bakes = _bakes[scene.id] ??= SetBakes(scene);
    final baked = bakes.bakeKey(key);
    return Float32List.fromList(baked.zb);
  }();

  /// Exact pixel indices of the pot inside `olla` box [30, 56, 21, 16], keyed by set state:
  /// on each row y, the serving table's top plane (z = 0.74) has depth `d_table(y) = v(y, 0.74) * COS + 0.74 * 0.5`;
  /// any pixel rising above the table top (z > 0.74) has `zb > d_table(y) + 0.05`.
  Set<int> _potMask(String key, List<int> ollaBox) =>
      _potPixels['${scene.id}:$key'] ??= () {
        final bakes = _bakes[scene.id] ??= SetBakes(scene);
        final baked = bakes.bakeKey(key);
        final zb = baked.zb;
        final e = scene.projection;
        const tableZ = 0.74;
        final out = <int>{};
        for (var y = ollaBox[1]; y < ollaBox[1] + ollaBox[3]; y++) {
          final vTable =
              (y + 0.5 - e.OY + tableZ * e.COS * e.S) / (e.S * e.SIN);
          final dTable = vTable * e.COS + tableZ * 0.5;
          for (var x = ollaBox[0]; x < ollaBox[0] + ollaBox[2]; x++) {
            final i = y * 240 + x;
            if (zb[i] > dTable + 0.05) {
              out.add(i);
            }
          }
        }
        return out;
      }();

  final List<ComidaBreach> breaches = [];
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
  List<int>? _cachedOllaBox;

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
    'persona:mesera',
    'persona:cocinero',
    'persona:senor',
    'persona:senora',
    'persona:joven',
    'persona:mujer',
    'persona:perro',
    'cosa:platillo1',
    'cosa:platillo2',
    'cosa:platillo3',
    'cosa:jarra',
    'cosa:vasos',
    'cosa:sal',
    'cosa:azucar',
    'cosa:hielo',
    'cosa:servilletas',
    'cosa:sopa1',
    'cosa:sopa2',
    'cosa:sopa3',
    'cosa:ensalada',
    'cosa:tazon',
    'cosa:plato_perro',
  };

  static const Set<String> _frogOwnFx = {
    'fx:delantal',
    'fx:servilleta_brazo',
    'fx:cucharon',
    'fx:lleva',
    'fx:carita_roja',
    'fx:fuego',
    'fx:vapor',
    'fx:corazon',
    'fx:estrella',
  };

  static const Set<String> _tableThings = {
    'cosa:platillo1',
    'cosa:platillo2',
    'cosa:platillo3',
    'cosa:jarra',
    'cosa:vasos',
    'cosa:sopa1',
    'cosa:sopa2',
    'cosa:sopa3',
    'cosa:ensalada',
  };

  static const Set<String> _shelfThings = {
    'cosa:sal',
    'cosa:azucar',
    'cosa:hielo',
    'cosa:servilletas',
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
      ..write('|')
      ..write(W['estacionVis']);
    for (final k in const [
      'abuela',
      'abuelo',
      'luis',
      'carmen',
      'mesera',
      'cocinero',
      'senor',
      'senora',
      'joven',
      'mujer',
    ]) {
      final p = gente[k] as Map?;
      sig
        ..write('|')
        ..write(p?['vis'])
        ..write(':')
        ..write(p?['spot'])
        ..write(':')
        ..write(p?['sent']);
    }
    sig
      ..write('|cq:')
      ..write(cq?['vis'])
      ..write(':')
      ..write(cq?['spot'])
      ..write(':')
      ..write(cq?['x'])
      ..write(',')
      ..write(cq?['y']);
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
    final ollaBox = _cachedOllaBox ??= List<int>.from(
      _m.places.box('olla') as List,
    );

    const w0 = 240, h0 = 216;
    const eps = .001;

    // Build sprite z-buffer (without frog's own FX for frog-seen check, and full for everything else)
    final fullZ = Float32List(w0 * h0)..fillRange(0, w0 * h0, -1e9);
    final noFrogFxZ = Float32List(w0 * h0)..fillRange(0, w0 * h0, -1e9);
    final nonFrogTag = List<String?>.filled(w0 * h0, null);

    // Precompute each item's drawn pixels and visible (non-set-hidden) horizontal bounds
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
            int visX0,
            int visX1,
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
      var visX0 = w0, visX1 = -1;
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
            if (X < visX0) visX0 = X;
            if (X > visX1) visX1 = X;
            if (plane >= fullZ[i] - eps) {
              fullZ[i] = plane;
            }
            if (!_frogOwnFx.contains(tag) && plane >= noFrogFxZ[i] - eps) {
              noFrogFxZ[i] = plane;
              if (tag != 'coqui') nonFrogTag[i] = tag;
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
        visX0: visX0,
        visX1: visX1,
      ));
    }

    // 1. spots-in-view
    for (final it in items) {
      if (it.tag == null || !_inViewTags.contains(it.tag)) continue;
      final ink = it.ink;
      if (ink == null) continue;
      final ix0 = it.left + ink[0];
      final iy0 = it.top + ink[1];
      final ix1 = it.left + ink[2];
      final iy1 = it.top + ink[3];
      if (ix0 < x0 || ix1 >= x1 || iy0 < 0 || iy1 >= h0) {
        add(
          'spots-in-view',
          '${it.tag} bounds [$ix0..$ix1, $iy0..$iy1] outside [$x0..${x1 - 1}, 0..215]',
        );
      }
    }

    // 2. frog-seen
    if (cq != null && jsTruthy(cq['vis'])) {
      final frog = items.where((it) => it.tag == 'coqui').toList();
      if (frog.isEmpty) {
        add('frog-seen', 'cq.vis is truthy but no coqui item was placed');
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

    // 3. heads-clear (seated family: abuela, abuelo, luis, carmen)
    for (final who in const ['abuela', 'abuelo', 'luis', 'carmen']) {
      final p = gente[who] as Map?;
      if (p == null || p['vis'] == 0 || p['sent'] != 1) continue;
      for (final it in items) {
        if (it.tag != 'persona:$who' || it.ink == null) continue;
        final ink = it.ink!;
        final headTop = it.top + ink[1];
        final headEnd = headTop + 14;
        var hidden = 0, covered = 0;
        for (var py = ink[1]; py <= ink[3]; py++) {
          final Y = it.top + py;
          if (Y < headTop || Y >= headEnd) continue;
          final plane = it.d + (it.sy - (Y + .5)) * _t30 / S;
          for (var px = ink[0]; px <= ink[2]; px++) {
            if (it.s.px[py * it.s.w + px] >>> 24 == 0) continue;
            final X = it.left + px;
            if (X < 0 || X >= w0 || Y < 0 || Y >= h0) continue;
            final i = Y * w0 + X;
            if (zb[i] > plane + bias) {
              hidden++;
            } else if (fullZ[i] > plane + eps) {
              covered++;
            }
          }
        }
        if (hidden > 0 || covered > 0) {
          add('heads-clear', '$who head: hidden=$hidden covered=$covered');
        }
      }
    }

    // 4. table-things-clear & 5. shelf-things-clear
    for (final it in items) {
      if (it.tag == null || it.ink == null) continue;
      final isTable = _tableThings.contains(it.tag);
      final isShelf = _shelfThings.contains(it.tag);
      if (!isTable && !isShelf) continue;
      final ink = it.ink!;
      var hidden = 0, covered = 0;
      for (var py = ink[1]; py <= ink[3]; py++) {
        final Y = it.top + py;
        final plane = it.d + (it.sy - (Y + .5)) * _t30 / S;
        for (var px = ink[0]; px <= ink[2]; px++) {
          if (it.s.px[py * it.s.w + px] >>> 24 == 0) continue;
          final X = it.left + px;
          if (X < 0 || X >= w0 || Y < 0 || Y >= h0) continue;
          final i = Y * w0 + X;
          if (zb[i] > plane + bias) {
            hidden++;
          } else if (fullZ[i] > plane + eps) {
            covered++;
          }
        }
      }
      if (hidden > 0 || covered > 0) {
        add(
          isTable ? 'table-things-clear' : 'shelf-things-clear',
          '${it.tag}: hidden=$hidden covered=$covered',
        );
      }
    }

    // 6. frog-station: frog at auxiliar_coqui has top row strictly below shelf items' bottom row
    if (cq != null &&
        jsTruthy(cq['vis']) &&
        cq['spot'] == 'auxiliar_coqui' &&
        W['estacionVis'] == 1) {
      final frog = items.where((it) => it.tag == 'coqui').toList();
      final shelf = items.where((it) => _shelfThings.contains(it.tag)).toList();
      if (frog.isNotEmpty && shelf.isNotEmpty && frog.last.ink != null) {
        final frogTop = frog.last.top + frog.last.ink![1];
        var shelfBot = -1;
        for (final sh in shelf) {
          if (sh.ink != null) {
            shelfBot = math.max(shelfBot, sh.top + sh.ink![3]);
          }
        }
        if (frogTop <= shelfBot) {
          add(
            'frog-station',
            'frog top row $frogTop overlaps shelf bottom row $shelfBot',
          );
        }
      }
    }

    // 7. line-whole & 8. line-feet (story 92)
    if (story == 92) {
      // Exact pot pixels inside [30, 56, 21, 16]: 0 sprite pixels drawn over the pot.
      final pot = _potMask(setKey, ollaBox);
      var potCov = 0;
      for (final i in pot) {
        if (fullZ[i] > -1e8) {
          potCov++;
        }
      }
      if (potCov > 0) {
        add(
          'line-whole',
          'pot box $ollaBox has $potCov sprite px drawn over it',
        );
      }

      // plato_perro: 0 covered, 0 hidden
      for (final it in items) {
        if (it.tag != 'cosa:plato_perro' || it.ink == null) continue;
        final ink = it.ink!;
        var hidden = 0, covered = 0;
        for (var py = ink[1]; py <= ink[3]; py++) {
          final Y = it.top + py;
          final plane = it.d + (it.sy - (Y + .5)) * _t30 / S;
          for (var px = ink[0]; px <= ink[2]; px++) {
            if (it.s.px[py * it.s.w + px] >>> 24 == 0) continue;
            final X = it.left + px;
            if (X < 0 || X >= w0 || Y < 0 || Y >= h0) continue;
            final i = Y * w0 + X;
            if (zb[i] > plane + bias) {
              hidden++;
            } else if (fullZ[i] > plane + eps) {
              covered++;
            }
          }
        }
        if (hidden > 0 || covered > 0) {
          add('line-whole', 'plato_perro: hidden=$hidden covered=$covered');
        }
      }

      // fila1..3 persons: fila1 whole (0 hidden, 0 covered, 0 out); fila1..3 bottom 8 rows 0 hidden
      for (final en in gente.entries) {
        final p = en.value as Map?;
        if (p == null || p['vis'] == 0) continue;
        final spot = p['spot'] as String?;
        if (spot != 'fila1' && spot != 'fila2' && spot != 'fila3') continue;
        for (final it in items) {
          if (it.tag != 'persona:${en.key}' || it.ink == null) continue;
          final ink = it.ink!;
          final feetStart = it.top + ink[3] - 7;
          var hidden = 0, covered = 0, feetHidden = 0;
          for (var py = ink[1]; py <= ink[3]; py++) {
            final Y = it.top + py;
            final plane = it.d + (it.sy - (Y + .5)) * _t30 / S;
            for (var px = ink[0]; px <= ink[2]; px++) {
              if (it.s.px[py * it.s.w + px] >>> 24 == 0) continue;
              final X = it.left + px;
              if (X < 0 || X >= w0 || Y < 0 || Y >= h0) continue;
              final i = Y * w0 + X;
              if (zb[i] > plane + bias) {
                hidden++;
                if (Y >= feetStart) feetHidden++;
              } else if (fullZ[i] > plane + eps) {
                covered++;
              }
            }
          }
          if (spot == 'fila1' && (hidden > 0 || covered > 0)) {
            add(
              'line-whole',
              '${en.key} at fila1: hidden=$hidden covered=$covered',
            );
          }
          if (feetHidden > 0) {
            add('line-feet', '${en.key} at $spot: feetHidden=$feetHidden');
          }
        }
      }
    }

    // 9. sprites-apart (comida-sheet-make.js): sprite boxes centred on each character's anchor
    // (frog 32, dog 28, grown-up/child 24) do not overlap sideways unless their feet are >= 12 px apart up-down.
    final chars = <({String tag, double sx, num sy, double width})>[];
    for (final it in items) {
      if (it.tag == null || it.ink == null) continue;
      if (it.tag == 'coqui') {
        if (cq == null) continue;
        final fb = scene.host.frogBox(cq);
        chars.add((tag: 'coqui', sx: fb.x + fb.w / 2, sy: it.sy, width: 32.0));
      } else if (it.tag == 'persona:perro') {
        chars.add((
          tag: 'persona:perro',
          sx: it.left + 15.0,
          sy: it.sy,
          width: 28.0,
        ));
      } else if (it.tag!.startsWith('persona:')) {
        final who = it.tag!.substring('persona:'.length);
        final p = gente[who] as Map?;
        final sent = p != null && p['sent'] == 1;
        final ax = who == 'abuela' ? (sent ? 17.0 : 30.0) : 24.0;
        chars.add((tag: it.tag!, sx: it.left + ax, sy: it.sy, width: 24.0));
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
