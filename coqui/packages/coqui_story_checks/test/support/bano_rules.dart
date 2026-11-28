// El baño's rules (bano-sheet.json's rules and checks, and page 13's "The sheet's rules hold in the scene"),
// checked on the real scene's frame at every act's end and at the story's end:
// - frog-seen: when cq.vis is truthy, a `coqui` item must exist and have 0 px hidden by the set, outside
//   [20, 216) x [0, 216), or under a nearer sprite (excluding frog's own sink foam / celebration FX);
// - spots-in-view: every visible person and interactive sprite lies inside [20, 216) x [0, 216);
// - heads-clear: Carmen raised on `banquito` has 0 px of her top 14 drawn rows hidden by the set or covered;
// - ducha-body: whoever stands at `ducha_dentro` shows top 14 rows over the low front wall and is hidden below;
// - fixtures-clear: llave_ducha, llave_lavamanos, espejo (excluding mirror reflection), and calentador (excluding bars)
//   have 0 px covered;
// - shelf-things-clear: cosa_a, cosa_b, tubo, and cepillito (when shown) have 0 px hidden or covered;
// - towels-clear: toalla_a, toalla_b (when shown) have 0 px hidden or covered;
// - frog-shelf: frog at `repisa_coqui` covers neither tap;
// - frog-sink: frog at `lavamanos_coqui` has 0 px hidden, covered, or outside;
// - bars-in-gauge: gauge bars lie inside calentador's box and match calentador.bars with 0 px hidden or covered;
// - sprites-apart: no two visible characters overlap sideways unless feet are >= 12 px apart up-down (exempting
//   `ducha_dentro` + `ducha_perro` as bano-sheet.json does).
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/coqui_scenes.dart';

/// What went against a rule: when, which rule, the details.
typedef BanoBreach = ({String at, String rule, String what});

final double _t30 = math.tan(math.pi / 6);

/// Watches a real El baño while a story plays: [wrap] its acts, then read [breaches] and [checked].
class BanoRules {
  BanoRules(this.scene) : _m = scene {
    if (scene.id != 'bano') {
      throw StateError('BanoRules expects scene "bano", got "${scene.id}"');
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

  final List<BanoBreach> breaches = [];
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
  List<int>? _cachedTapShower;
  List<int>? _cachedTapSink;
  List<int>? _cachedMirror;
  List<int>? _cachedHeater;

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
    'cosa:jabon',
    'cosa:toalla_a',
    'cosa:toalla_b',
    'cosa:cosa_a',
    'cosa:cosa_b',
    'cosa:tubo',
    'cosa:cepillito',
  };

  static const Set<String> _frogOwnFx = {
    'fx:espuma',
    'fx:corazon',
    'fx:estrella',
    'fx:vapor_sink',
  };

  static const Set<String> _shelfThings = {
    'cosa:cosa_a',
    'cosa:cosa_b',
    'cosa:tubo',
    'cosa:cepillito',
  };

  static const Set<String> _towelThings = {'cosa:toalla_a', 'cosa:toalla_b'};

  static bool _inBox(int x, int y, List<int> b) =>
      x >= b[0] && x < b[0] + b[2] && y >= b[1] && y < b[1] + b[3];

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
      ..write(W['perroVis'])
      ..write(':')
      ..write(W['perroSpot']);
    for (final k in const ['abuela', 'abuelo', 'luis', 'carmen']) {
      final p = gente[k] as Map?;
      sig
        ..write('|')
        ..write(p?['vis'])
        ..write(':')
        ..write(p?['spot']);
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
    final tapShower = _cachedTapShower ??= List<int>.from(
      _m.places.box('llave_ducha') as List,
    );
    final tapSink = _cachedTapSink ??= List<int>.from(
      _m.places.box('llave_lavamanos') as List,
    );
    final mirrorBox = _cachedMirror ??= List<int>.from(
      _m.places.box('espejo') as List,
    );
    final heaterBox = _cachedHeater ??= List<int>.from(
      _m.places.box('calentador') as List,
    );

    const w0 = 240, h0 = 216;
    const eps = .001;
    final frogDy = (cq?['dy'] as num?)?.toDouble() ?? 0.0;
    final anyoneAtAnteEspejo = gente.values.any(
      (p) => p is Map && p['vis'] != 0 && p['spot'] == 'ante_espejo',
    );

    final fullZ = Float32List(w0 * h0)..fillRange(0, w0 * h0, -1e9);
    final noFrogFxZ = Float32List(w0 * h0)..fillRange(0, w0 * h0, -1e9);
    final worldNonOverlayZ = Float32List(w0 * h0)..fillRange(0, w0 * h0, -1e9);
    final worldNonOverlayTag = List<String?>.filled(w0 * h0, null);

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
            if (!overlay &&
                tag != 'fx:agua_llave' &&
                !(tag == 'coqui' && frogDy < 0) &&
                (tag == null || !tag.startsWith('fx:barra_')) &&
                plane >= worldNonOverlayZ[i] - eps) {
              worldNonOverlayZ[i] = plane;
              worldNonOverlayTag[i] = tag;
            }
            if (!_frogOwnFx.contains(tag) && plane >= noFrogFxZ[i] - eps) {
              noFrogFxZ[i] = plane;
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

    // 2. frog-seen & frog-sink & frog-shelf
    if (cq != null && jsTruthy(cq['vis'])) {
      final frog = items.where((it) => it.tag == 'coqui').toList();
      if (frog.isEmpty) {
        add('frog-seen', 'cq.vis is truthy but no coqui item was placed');
      } else {
        final it = frog.last;
        final ink = it.ink!;
        var hidden = 0, covered = 0, outWin = 0, onTap = 0;
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
            if (cq['spot'] == 'repisa_coqui' &&
                (_inBox(X, Y, tapShower) || _inBox(X, Y, tapSink))) {
              onTap++;
            }
          }
        }
        if (hidden > 0 || covered > 0 || outWin > 0) {
          add(
            'frog-seen',
            'coqui at ${cq['spot']}: hidden=$hidden covered=$covered out=$outWin',
          );
          if (cq['spot'] == 'lavamanos_coqui') {
            add('frog-sink', 'coqui at lavamanos_coqui not whole');
          }
        }
        if (onTap > 0) {
          add('frog-shelf', 'coqui at repisa_coqui covers tap ($onTap px)');
        }
      }
    }

    // 3. heads-clear (Carmen on banquito) & 4. ducha-body (whoever stands at ducha_dentro)
    for (final who in const ['abuela', 'abuelo', 'luis', 'carmen']) {
      final p = gente[who] as Map?;
      if (p == null || p['vis'] == 0) continue;
      final spot = p['spot'] as String?;
      if (spot != 'banquito' && spot != 'ducha_dentro') continue;
      for (final it in items) {
        if (it.tag != 'persona:$who' || it.ink == null) continue;
        final ink = it.ink!;
        final headTop = it.top + ink[1];
        final headEnd = headTop + 14;
        var headHidden = 0, headCovered = 0, bodyHidden = 0;
        for (var py = ink[1]; py <= ink[3]; py++) {
          final Y = it.top + py;
          final plane = it.d + (it.sy - (Y + .5)) * _t30 / S;
          final inHead = Y >= headTop && Y < headEnd;
          for (var px = ink[0]; px <= ink[2]; px++) {
            if (it.s.px[py * it.s.w + px] >>> 24 == 0) continue;
            final X = it.left + px;
            if (X < 0 || X >= w0 || Y < 0 || Y >= h0) continue;
            final i = Y * w0 + X;
            if (zb[i] > plane + bias) {
              if (inHead) headHidden++;
              bodyHidden++;
            } else if (fullZ[i] > plane + eps) {
              if (inHead) headCovered++;
            }
          }
        }
        if (spot == 'banquito' && (headHidden > 0 || headCovered > 0)) {
          add(
            'heads-clear',
            '$who at banquito head: hidden=$headHidden covered=$headCovered',
          );
        }
        if (spot == 'ducha_dentro' &&
            (headHidden > 0 || headCovered > 0 || bodyHidden == 0)) {
          add(
            'ducha-body',
            '$who at ducha_dentro: headHidden=$headHidden headCovered=$headCovered bodyHidden=$bodyHidden',
          );
        }
      }
    }

    // 5. fixtures-clear: taps, mirror, and gauge box have 0 px covered by world sprites
    // (matches bano-sheet.json moments 4 and 5: Story 100 before Abuelo steps up to `ante_espejo`).
    if (story == 100 && !anyoneAtAnteEspejo) {
      for (final (name, b) in [
        ('llave_ducha', tapShower),
        ('llave_lavamanos', tapSink),
        ('espejo', mirrorBox),
        ('calentador', heaterBox),
      ]) {
        var cov = 0;
        final tags = <String>{};
        String? sample;
        for (var y = b[1]; y < b[1] + b[3]; y++) {
          for (var x = b[0]; x < b[0] + b[2]; x++) {
            final i = y * w0 + x;
            if (worldNonOverlayZ[i] > -1e8) {
              cov++;
              final t = worldNonOverlayTag[i];
              if (t != null) tags.add(t);
              sample ??= '($x,$y by $t dy=$frogDy)';
            }
          }
        }
        if (cov > 0) {
          add(
            'fixtures-clear',
            '$name $b covered by $cov sprite px $tags $sample',
          );
        }
      }
    }

    // 6. shelf-things-clear & 7. towels-clear
    for (final it in items) {
      if (it.tag == null || it.ink == null) continue;
      final isShelf = _shelfThings.contains(it.tag);
      final isTowel = _towelThings.contains(it.tag);
      if (!isShelf && !isTowel) continue;
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
          isShelf ? 'shelf-things-clear' : 'towels-clear',
          '${it.tag}: hidden=$hidden covered=$covered',
        );
      }
    }

    // 8. bars-in-gauge
    for (final it in items) {
      if (it.tag == null ||
          !it.tag!.startsWith('fx:barra_') ||
          it.ink == null) {
        continue;
      }
      final ink = it.ink!;
      var out = 0, hidden = 0, covered = 0;
      for (var py = ink[1]; py <= ink[3]; py++) {
        final Y = it.top + py;
        final plane = it.d + (it.sy - (Y + .5)) * _t30 / S;
        for (var px = ink[0]; px <= ink[2]; px++) {
          if (it.s.px[py * it.s.w + px] >>> 24 == 0) continue;
          final X = it.left + px;
          if (!_inBox(X, Y, heaterBox)) {
            out++;
            continue;
          }
          final i = Y * w0 + X;
          if (zb[i] > plane + bias) {
            hidden++;
          } else if (fullZ[i] > plane + eps) {
            covered++;
          }
        }
      }
      if (out > 0 || hidden > 0 || covered > 0) {
        add(
          'bars-in-gauge',
          '${it.tag}: out=$out hidden=$hidden covered=$covered',
        );
      }
    }

    // 9. sprites-apart
    final chars =
        <({String tag, String? spot, double sx, num sy, double width})>[];
    for (final it in items) {
      if (it.tag == null || it.ink == null) continue;
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
      } else if (it.tag == 'persona:perro') {
        chars.add((
          tag: 'persona:perro',
          spot: W['perroSpot'] as String?,
          sx: it.left + 15.0,
          sy: it.sy,
          width: 28.0,
        ));
      } else if (it.tag!.startsWith('persona:')) {
        final who = it.tag!.substring('persona:'.length);
        final p = gente[who] as Map?;
        final ax = who == 'abuela' ? 30.0 : 24.0;
        chars.add((
          tag: it.tag!,
          spot: p?['spot'] as String?,
          sx: it.left + ax,
          sy: it.sy,
          width: 24.0,
        ));
      }
    }
    for (var i = 0; i < chars.length; i++) {
      for (var j = i + 1; j < chars.length; j++) {
        final a = chars[i], b = chars[j];
        final isShowerPair =
            (a.spot == 'ducha_dentro' && b.spot == 'ducha_perro') ||
            (b.spot == 'ducha_dentro' && a.spot == 'ducha_perro');
        if (isShowerPair) continue;
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
