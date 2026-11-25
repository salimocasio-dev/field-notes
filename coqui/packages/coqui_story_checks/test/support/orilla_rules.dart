// La orilla's rules (orilla-sheet.json's rules and checks, and page 13's "The sheet's rules hold in the scene"),
// checked on the real scene's frame at every act's end and at the story's end:
// - frog-seen: 0 px of the frog hidden by the live set (including swaying palm fronds: drawLeaves(0)), outside the
//   picture/window [25, 221), or under a nearer sprite (excluding his own held/fx overlays);
// - spots-in-view: every visible person and interactive sprite lies inside the picture and view window [25, 221);
// - patch-clear: when castillo = 1, no sprite pixel covers the patch of smooth sand (`things.arena`);
// - towels-clear: when `toalla_a`/`toalla_b` hang on the rope, 0 px covered by a nearer sprite or hidden by the live set;
// - boats-clear: when `bote_a`/`bote_b` sit on the wet sand, 0 px covered by a nearer sprite or hidden by the live set;
// - sprites-apart: no two visible characters overlap sideways unless their feet are 12 px or more apart up-down
//   (story 74 step 4's brief `agua1`+`agua2` wait is 11 px down on the sheet's own spots and is counted apart as a note).
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/coqui_scenes.dart';

/// What went against a rule: when, which rule, the details.
typedef OrillaBreach = ({String at, String rule, String what});

final double _t30 = math.tan(math.pi / 6);

/// Watches a real La orilla while a story plays: [wrap] its acts, then read [breaches], [notes] and [checked].
class OrillaRules {
  OrillaRules(this.scene) : _m = scene;

  final SetScene scene;
  final dynamic _m;

  static final Map<String, Float32List> _zb = {};
  static SetBakes? _bakes;

  /// Live depth after `drawLeaves(0)` (orilla-sheet.json `front.plane`: `window.DEPTH.live()`).
  Float32List _zbOf(String key) => _zb[key] ??= () {
    final bakes = _bakes ??= SetBakes(scene);
    final baked = bakes.bakeKey(key);
    baked.restoreInto(bakes.engine);
    bakes.engine.drawLeaves(0);
    return Float32List.fromList(bakes.engine.zb);
  }();

  final List<OrillaBreach> breaches = [];
  final List<OrillaBreach> notes = [];
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
  List<int>? _cachedArena;

  static final Map<
    String,
    ({
      List<({String rule, String what})> breaches,
      List<({String rule, String what})> notes,
    })
  >
  _frameCache = {};

  static const Set<String> _inViewTags = {
    'coqui',
    'persona:abuela',
    'persona:luis',
    'persona:carmen',
    'persona:perro',
    'cosa:bote',
    'cosa:bote_a',
    'cosa:bote_b',
    'cosa:toalla_a',
    'cosa:toalla_b',
    'cosa:toallas',
    'cosa:conchas',
  };

  void check(String at) {
    final W = scene.host.W;
    checked++;
    final rawItems = (_m.placed(W, 0) as List);
    final setKey = scene.setKey(W);
    final castillo = (W['castillo'] == 1 || W['castillo'] == true) ? 1 : 0;
    final gente = (W['gente'] as Map?) ?? const {};
    final sig = StringBuffer()
      ..write(setKey)
      ..write('|')
      ..write(castillo);
    for (final k in const ['abuela', 'luis', 'carmen']) {
      sig
        ..write('|')
        ..write((gente[k] as Map?)?['spot']);
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
        ..write(identityHashCode(it.s));
    }
    final key = sig.toString();
    final cached = _frameCache[key];
    if (cached != null) {
      for (final b in cached.breaches) {
        breaches.add((at: at, rule: b.rule, what: b.what));
      }
      for (final n in cached.notes) {
        notes.add((at: at, rule: n.rule, what: n.what));
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
    final arena = _cachedArena ??= (_m.places.box('arena') as List).cast<int>();
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

    // 1. frog-seen: 0 px hidden by live set (including fronds), outside window, or under another sprite
    final fi = items.indexWhere((it) => it.tag == 'coqui');
    if (fi >= 0) {
      final c = covOf(
        fi,
        ignore: (t) =>
            t != null &&
            (t.startsWith('held:collar_rana') ||
                t.startsWith('held:coqui_') ||
                t.startsWith('fx:')),
      );
      if (c.hid > 0 || c.cov > 0 || c.out > 0) {
        addBreach(
          'frog-seen',
          'frog at ${(W['cq'] as Map?)?['spot']}: ${c.hid} hidden by set, ${c.cov} under ${c.by}, ${c.out} outside',
        );
      }
    }

    // 2. spots-in-view: every visible character and interactive sprite inside window [x0, winR) x [0, 216)
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

    // 3. patch-clear: when castillo = 1, no sprite covers any pixel of the patch of smooth sand (orilla-sheet.json:
    // 379 pixels on rows 143..153 inside E.PATCH; the rounded bounding box extends 1 row to 154 where the frog's
    // top outline rests at coqui.castillo).
    if (castillo == 1) {
      var patchHit = 0;
      final whoHit = <String>{};
      final e = _m.places.e as PpEngine;
      for (final it in items) {
        if (it.flat || it.ink == null) continue;
        final ink = it.ink!;
        for (var y = ink[1]; y <= ink[3]; y++) {
          final Y = it.top + y;
          if (Y < arena[1] || Y >= arena[1] + arena[3]) continue;
          for (var x = ink[0]; x <= ink[2]; x++) {
            if (it.s.px[y * it.s.w + x] >>> 24 == 0) continue;
            final X = it.left + x;
            if (X < arena[0] || X >= arena[0] + arena[2]) continue;
            final g = e.unproject(X + .5, Y + .5);
            final u = (g.x - g.y) / e.R2;
            final v = (g.x + g.y) / e.R2;
            final du = (u - 1.2) / .85;
            final dv = (v - 5.45) / .42;
            if (du * du + dv * dv < 1.0) {
              patchHit++;
              if (it.tag != null) whoHit.add(it.tag!);
            }
          }
        }
      }
      if (patchHit > 0) {
        addBreach(
          'patch-clear',
          '$patchHit sprite px on smooth sand patch $arena ($whoHit)',
        );
      }
    }

    // 4. towels-clear: `toalla_a` and `toalla_b` on the rope covered by nobody and no palm frond
    for (final tag in const ['cosa:toalla_a', 'cosa:toalla_b']) {
      final idx = items.indexWhere((it) => it.tag == tag);
      if (idx < 0) continue;
      final c = covOf(idx);
      if (c.hid > 0 || c.cov > 0 || c.out > 0) {
        addBreach(
          'towels-clear',
          '$tag: ${c.hid} hidden by set/frond, ${c.cov} under ${c.by}, ${c.out} outside',
        );
      }
    }

    // 5. boats-clear: `bote_a` and `bote_b` on wet sand covered by nobody and hidden by nothing
    for (final tag in const ['cosa:bote_a', 'cosa:bote_b']) {
      final idx = items.indexWhere((it) => it.tag == tag);
      if (idx < 0) continue;
      final c = covOf(idx);
      if (c.hid > 0 || c.cov > 0 || c.out > 0) {
        addBreach(
          'boats-clear',
          '$tag: ${c.hid} hidden by set, ${c.cov} under ${c.by}, ${c.out} outside',
        );
      }
    }

    // 6. sprites-apart: character pairs checked as orilla-sheet.json
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
      final at = _m.places.at('perro');
      chars.add((
        id: 'perro',
        spot: 'perro',
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
          final isAguaPair =
              (a.spot == 'agua1' && b.spot == 'agua2') ||
              (a.spot == 'agua2' && b.spot == 'agua1');
          final msg =
              '${a.id}@${a.spot} ~ ${b.id}@${b.spot}: $across across (need $need), $down down (need 12)';
          if (isAguaPair) {
            addNote('sprites-apart', msg);
          } else {
            addBreach('sprites-apart', msg);
          }
        }
      }
    }

    _frameCache[key] = (breaches: localBreaches, notes: localNotes);
  }
}
