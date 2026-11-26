// La sombrilla's rules (sombrilla-sheet.json's rules and checks, and page 13's "The sheet's rules hold in the scene"),
// checked on the real scene's frame at every act's end and at the story's end:
// - frog-seen: 0 px of the frog hidden by the baked set, outside the picture/window [22, 218), or under a nearer
//   sprite (excluding his own held/fx overlays);
// - spots-in-view: every visible person, dog and interactive small thing lies inside the picture and view window [22, 218);
// - face-clear: in story 75 (`dibujo == 'circulo'`), no person or frog covers any pixel of `ojo_izq`, `ojo_der`,
//   `nariz`, `boca`;
// - figure-clear: in story 76 (`dibujo == 'figura'`), no person, frog or dog covers any pixel of `cabeza`,
//   `brazo_izq`, `brazo_der`, `mano_izq`, `mano_der`;
// - feet-things-clear: in story 77, no person or frog covers either foot box of `pies` (`[121,159,12,8]`,
//   `[162,159,12,8]`), and `sombreros`, `gafas`, `chancletas` have 0 px hidden by the set or covered by another sprite;
// - players-whole: in story 77, every player at `sol1`/`sol2`/`sol3` has 0 px outside the window or hidden by the set;
// - abuela-manta: when abuela is on `manta`/`manta2`/`manta3`, her 24-px box lies inside the blanket [48..110] and
//   0 px of her sprite is hidden by the umbrella's canopy;
// - sprites-apart: no two visible characters overlap sideways unless their feet are 12 px or more apart up-down.
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/coqui_scenes.dart';

/// What went against a rule: when, which rule, the details.
typedef SombrillaBreach = ({String at, String rule, String what});

final double _t30 = math.tan(math.pi / 6);

/// Watches a real La sombrilla while a story plays: [wrap] its acts, then read [breaches] and [checked].
class SombrillaRules {
  SombrillaRules(this.scene) : _m = scene;

  final SetScene scene;
  final dynamic _m;

  // Deterministic across Sombrilla instances: the baked set depends only on the
  // pure sombrilla_set renderer and setKey (`hora-dibujo`).
  static final Map<String, Float32List> _zb = {};
  static SetBakes? _bakes;

  /// Baked depth of the set (nothing sways in La sombrilla: sombrilla-sheet.json `front.how`).
  Float32List _zbOf(String key) => _zb[key] ??= () {
    final bakes = _bakes ??= SetBakes(scene);
    final baked = bakes.bakeKey(key);
    return Float32List.fromList(baked.zb);
  }();

  final List<SombrillaBreach> breaches = [];
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
  List<int>? _cachedBlanket;
  List<List<int>>? _cachedFaceBoxes;
  List<List<int>>? _cachedFigBoxes;
  List<List<int>>? _cachedFeetBoxes;

  static final Expando<int> _spriteIds = Expando<int>();
  static int _nextSpriteId = 1;
  static int _spriteId(Sprite s) => _spriteIds[s] ??= _nextSpriteId++;

  static final Map<String, List<({String rule, String what})>> _frameCache = {};

  static const Set<String> _inViewTags = {
    'coqui',
    'persona:abuela',
    'persona:luis',
    'persona:carmen',
    'persona:perro',
    'cosa:cubo75',
    'cosa:caracoles',
    'cosa:sombreros',
    'cosa:gafas',
    'cosa:chancletas',
    'cosa:bola',
  };

  static const Set<String> _charTags = {
    'coqui',
    'persona:abuela',
    'persona:luis',
    'persona:carmen',
    'persona:perro',
  };

  void check(String at) {
    final W = scene.host.W;
    checked++;
    final rawStory = W['story'];
    final rawDibujo = W['dibujo'];
    if (rawStory is! num || rawDibujo is! String) {
      breaches.add((
        at: at,
        rule: 'scene-state',
        what: 'missing story ($rawStory) or dibujo ($rawDibujo) in W',
      ));
      return;
    }
    final rawItems = (_m.placed(W, 0) as List);
    final setKey = scene.setKey(W);
    final story = rawStory.toInt();
    final dibujo = rawDibujo;
    final gente = (W['gente'] as Map?) ?? const {};
    final cq = W['cq'] as Map?;
    final sig = StringBuffer()
      ..write(setKey)
      ..write('|')
      ..write(story)
      ..write('|')
      ..write(dibujo)
      ..write('|')
      ..write(W['perroVis'])
      ..write('|')
      ..write(W['perroSpot'])
      ..write('|')
      ..write(cq?['vis'])
      ..write('|')
      ..write(cq?['spot']);
    for (final k in const ['abuela', 'luis', 'carmen']) {
      final p = gente[k] as Map?;
      sig
        ..write('|')
        ..write(p?['vis'])
        ..write(':')
        ..write(p?['spot']);
    }
    for (final dynamic it in rawItems) {
      final s = it.s as Sprite;
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
        ..write(_spriteId(s));
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
            bool flat,
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
              d: it.d as double,
              tag: it.tag as String?,
              flat: it.flat as bool,
              ink: _inkOf(it.s as Sprite),
            ),
        ];
    final S = _cachedS ??= (_m.places.e.S as num).toDouble();
    final bias = _cachedBias ??= (_m.places.bias as num).toDouble();
    final x0 = _cachedX0 ??= ((_m.places.view('wide') as List)[0] as num)
        .toInt();
    final winR = x0 + 196;
    final blanket = _cachedBlanket ??= (_m.places.blanketBox as List)
        .cast<int>();
    final faceBoxes = _cachedFaceBoxes ??= [
      for (final id in const ['ojo_izq', 'ojo_der', 'nariz', 'boca'])
        (_m.places.box(id) as List).cast<int>(),
    ];
    final figBoxes = _cachedFigBoxes ??= [
      for (final id in const [
        'cabeza',
        'brazo_izq',
        'brazo_der',
        'mano_izq',
        'mano_der',
      ])
        (_m.places.box(id) as List).cast<int>(),
    ];
    final feetBoxes = _cachedFeetBoxes ??= [
      for (final b in _m.places.boxesOf('pies') as List)
        (b as List).cast<int>(),
    ];
    final zb = _zbOf(setKey);

    ({int hid, int cov, int out, Map<String, int> by, int total}) covOf(
      int idx, {
      bool Function(String? tag)? ignore,
    }) {
      final f = items[idx];
      final ink = f.ink;
      if (ink == null) {
        return (hid: 0, cov: 0, out: 0, by: const {}, total: 0);
      }
      var hid = 0, cov = 0, outPx = 0, total = 0;
      final by = <String, int>{};
      for (var y = ink[1]; y <= ink[3]; y++) {
        final Y = f.top + y;
        final plane = f.d + (f.sy - (Y + .5)) * _t30 / S;
        for (var x = ink[0]; x <= ink[2]; x++) {
          if (f.s.px[y * f.s.w + x] >>> 24 == 0) continue;
          total++;
          final X = f.left + x;
          if (X < x0 || X >= winR || Y < 0 || Y >= 216) {
            outPx++;
            continue;
          }
          if (zb[Y * 240 + X] > plane + bias) {
            hid++;
            continue;
          }
          String? winner;
          var best = plane + .001;
          for (var j = 0; j < items.length; j++) {
            if (j == idx) continue;
            final o = items[j];
            if (o.flat) continue;
            if (ignore != null && ignore(o.tag)) continue;
            if (X < o.left || X >= o.right || Y < o.top || Y >= o.bottom) {
              continue;
            }
            final ox = X - o.left, oy = Y - o.top;
            if (o.s.px[oy * o.s.w + ox] >>> 24 == 0) continue;
            final op = o.d + (o.sy - (Y + .5)) * _t30 / S;
            if (zb[Y * 240 + X] > op + bias) continue;
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

    int charOverlapBoxes(List<List<int>> boxes, Set<String> whoHit) {
      var hits = 0;
      for (final it in items) {
        if (it.tag == null || !_charTags.contains(it.tag)) continue;
        final ink = it.ink;
        if (ink == null) continue;
        for (var y = ink[1]; y <= ink[3]; y++) {
          final Y = it.top + y;
          final plane = it.d + (it.sy - (Y + .5)) * _t30 / S;
          for (var x = ink[0]; x <= ink[2]; x++) {
            if (it.s.px[y * it.s.w + x] >>> 24 == 0) continue;
            final X = it.left + x;
            if (X < 0 || X >= 240 || Y < 0 || Y >= 216) continue;
            if (zb[Y * 240 + X] > plane + bias) continue;
            for (final b in boxes) {
              if (X >= b[0] &&
                  X < b[0] + b[2] &&
                  Y >= b[1] &&
                  Y < b[1] + b[3]) {
                hits++;
                whoHit.add(it.tag!);
                break;
              }
            }
          }
        }
      }
      return hits;
    }

    // 1. frog-seen: 0 px hidden by set, outside window, or under another sprite
    final fi = items.indexWhere((it) => it.tag == 'coqui');
    if (fi >= 0) {
      final c = covOf(
        fi,
        ignore: (t) =>
            t != null && (t.startsWith('held:coqui_') || t.startsWith('fx:')),
      );
      if (c.hid > 0 || c.cov > 0 || c.out > 0) {
        addBreach(
          'frog-seen',
          'frog at ${(W['cq'] as Map?)?['spot']}: ${c.hid} hidden by set, ${c.cov} under ${c.by}, ${c.out} outside',
        );
      }
    }

    // 2. spots-in-view: every visible character and interactive small thing inside window [x0, winR) x [0, 216)
    for (final it in items) {
      if (it.tag == null || !_inViewTags.contains(it.tag)) continue;
      final ink = it.ink;
      if (ink == null) continue;
      final l = it.left + ink[0], r = it.left + ink[2];
      final t = it.top + ink[1], b = it.top + ink[3];
      if (l < x0 || r >= winR || t < 0 || b >= 216) {
        addBreach(
          'spots-in-view',
          '${it.tag} ink [$l..$r, $t..$b] out of window [$x0..${winR - 1}, 0..215]',
        );
      }
    }

    // 3. face-clear: in story 75 (`circulo`), nobody covers the 4 face boxes
    if (dibujo == 'circulo') {
      final who = <String>{};
      final n = charOverlapBoxes(faceBoxes, who);
      if (n > 0) {
        addBreach('face-clear', '$n character px inside face boxes ($who)');
      }
    }

    // 4. figure-clear: in story 76, nobody covers head, arms or hands
    if (dibujo == 'figura' && story == 76) {
      final who = <String>{};
      final n = charOverlapBoxes(figBoxes, who);
      if (n > 0) {
        addBreach('figure-clear', '$n character px inside figure boxes ($who)');
      }
    }

    // 5. feet-things-clear & players-whole (story 77)
    if (story == 77) {
      final who = <String>{};
      final n = charOverlapBoxes(feetBoxes, who);
      if (n > 0) {
        addBreach(
          'feet-things-clear',
          '$n character px inside feet boxes ($who)',
        );
      }
      for (final tag in const [
        'cosa:sombreros',
        'cosa:gafas',
        'cosa:chancletas',
      ]) {
        final idx = items.indexWhere((it) => it.tag == tag);
        if (idx < 0) continue;
        final c = covOf(idx);
        if (c.hid > 0 || c.cov > 0 || c.out > 0) {
          addBreach(
            'feet-things-clear',
            '$tag: ${c.hid} hidden by set, ${c.cov} under ${c.by}, ${c.out} outside',
          );
        }
      }
      for (final k in const ['abuela', 'luis', 'carmen']) {
        final p = gente[k];
        if (p is! Map || p['vis'] == 0) continue;
        final spot = p['spot'] as String?;
        if (spot != 'sol1' && spot != 'sol2' && spot != 'sol3') continue;
        final idx = items.indexWhere((it) => it.tag == 'persona:$k');
        if (idx < 0) continue;
        final c = covOf(
          idx,
          ignore: (t) =>
              t != null &&
              (t == 'cosa:bola' ||
                  t.startsWith('worn:') ||
                  t.startsWith('held:') ||
                  t.startsWith('fx:')),
        );
        if (c.hid > 0 || c.out > 0) {
          addBreach(
            'players-whole',
            '$k@$spot: ${c.hid} hidden by set, ${c.out} outside window',
          );
        }
      }
    }

    // 6. abuela-manta: when abuela is on `manta`/`manta2`/`manta3`, her 24-px box is inside the blanket and
    //    0 px of her sprite is hidden by the umbrella canopy
    final ab = gente['abuela'];
    if (ab is Map && ab['vis'] != 0) {
      final spot = ab['spot'] as String?;
      if (spot == 'manta' || spot == 'manta2' || spot == 'manta3') {
        final at = _m.places.atWorld(
          ab['x'] as num,
          ab['y'] as num,
          ab['z'] as num,
        );
        final cx = ((at.sx as num) + 0.5).floor();
        final bx0 = blanket[0], bx1 = blanket[0] + blanket[2] - 1;
        if (cx - 12 < bx0 || cx + 11 > bx1) {
          addBreach(
            'abuela-manta',
            'abuela@$spot 24-px box [${cx - 12}..${cx + 11}] outside blanket [$bx0..$bx1]',
          );
        }
        final idx = items.indexWhere((it) => it.tag == 'persona:abuela');
        if (idx >= 0) {
          final c = covOf(idx);
          if (c.hid > 0) {
            addBreach(
              'abuela-manta',
              'abuela@$spot: ${c.hid} px hidden by umbrella/set',
            );
          }
        }
      }
    }

    // 7. sprites-apart: character pairs checked as sombrilla-sheet.json
    final chars = <({String id, String spot, int cx, int sy, int w})>[];
    for (final k in const ['abuela', 'luis', 'carmen']) {
      final p = gente[k];
      if (p is! Map || p['vis'] == 0) continue;
      final at = _m.places.atWorld(p['x'] as num, p['y'] as num, p['z'] as num);
      chars.add((
        id: k,
        spot: (p['spot'] as String?) ?? k,
        cx: ((at.sx as num) + 0.5).floor(),
        sy: ((at.sy as num) + 0.5).floor(),
        w: 24,
      ));
    }
    if (W['perroVis'] == 1) {
      final pSpot = (W['perroSpot'] as String?) ?? 'perro';
      final at = _m.places.at(pSpot);
      chars.add((
        id: 'perro',
        spot: pSpot,
        cx: ((at.sx as num) + 0.5).floor(),
        sy: ((at.sy as num) + 0.5).floor(),
        w: 28,
      ));
    }
    final q = W['cq'];
    if (q is Map && jsTruthy(q['vis'])) {
      final spot = (q['spot'] as String?) ?? 'coqui';
      final at = _m.places.has(spot) ? _m.places.at(spot) : null;
      if (at != null) {
        chars.add((
          id: 'coqui',
          spot: spot,
          cx: ((at.sx as num) + 0.5).floor(),
          sy: ((at.sy as num) + 0.5).floor(),
          w: 32,
        ));
      }
    }
    for (var i = 0; i < chars.length; i++) {
      for (var j = i + 1; j < chars.length; j++) {
        final a = chars[i], b = chars[j];
        final across = (a.cx - b.cx).abs();
        final down = (a.sy - b.sy).abs();
        final need = (a.w + b.w) ~/ 2;
        if (across < need && down < 12) {
          addBreach(
            'sprites-apart',
            '${a.id}@${a.spot} ~ ${b.id}@${b.spot}: $across across (need $need), $down down (need 12)',
          );
        }
      }
    }

    _frameCache[key] = localBreaches;
  }
}
