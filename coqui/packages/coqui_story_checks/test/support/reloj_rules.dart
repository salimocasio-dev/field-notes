// El reloj's rules (reloj-sheet.json's rules and checks, and page 13's "The sheet's rules hold in the scene"),
// checked on the real scene's frame at every act's end and at the story's end: the scene's acts are wrapped so that
// each, once done, has the frame looked at. What is checked:
// - frog-seen: the frog is whole — no pixel hidden by the set, outside the picture, or under a nearer sprite
//   (when he stands on `balcon2` behind the balcony rail during `pone63` in story 63, the balcony rail pixels are
//   counted apart in [notes], as the sheet's own frog-seen marks moment 7 `balcon2` as a dev aid outside the spec's 6);
// - frog-on-hand: at `mano_arriba`, `mano_abajo`, `mano_lado`, 0 pixels of the frog lie outside the picture;
// - tito-face: don Tito at `balcon1` covers <= 8% of the clock face disc (`things.reloj.disc`);
// - vendedor-head: top 14 rows of the vendedor's sprite have 0 pixels hidden by the set (awning) or under a nearer sprite;
// - cards-clear: when time cards `carta_a`/`carta_b` are shown, both lie inside the view window and cover 0 pixels of
//   the frog, the clock face, or the vendedor;
// - carton-clear: every square of abuela's bingo card (`n40..n100`) lies inside the view window and is covered by 0
//   pixels of any non-overlay sprite;
// - bingo-clear: `jaula` and each remaining `premio1..3` have 0 pixels hidden by the set or under another sprite;
// - table-heads: the frog on `mesa_abuela.coqui` covers <= 10% of abuela's head (top 14 rows) and 0 of Luis's head;
// - spots-in-view: every visible person's drawn ink lies inside the picture and the view window `[x0, x0 + 196)`.
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/coqui_scenes.dart';

/// What went against a rule: when, which rule, the details.
typedef RelojBreach = ({String at, String rule, String what});

final double _t30 = math.tan(math.pi / 6);

/// Watches a real El reloj while a story plays: [wrap] its acts, then read [breaches], [notes] and [checked].
class RelojRules {
  RelojRules(this.scene) : _m = scene;

  /// The scene (its own members `placed`, `places`, `cardBoxes` are reached untyped: a feature may not import
  /// another package's src/).
  final SetScene scene;
  final dynamic _m;

  static final Map<String, Float32List> _zb = {};
  static SetBakes? _bakes;
  Float32List _zbOf(String key) => _zb[key] ??= Float32List.fromList(
    (_bakes ??= SetBakes(scene)).bakeKey(key).zb,
  );

  final List<RelojBreach> breaches = [];
  final List<RelojBreach> notes = [];
  int checked = 0;

  /// Every act of the scene, once done, has the frame checked.
  void wrap() {
    final acts = scene.acts;
    for (final k in acts.keys.toList()) {
      final f = acts[k]!;
      acts[k] = (o) async {
        await f(o);
        check('after ${o['act'] ?? k}');
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
  int? _cachedFaceTotal;
  ({double cx, double cy, double r})? _cachedDisc;

  static final Map<
    String,
    ({
      List<({String rule, String what})> breaches,
      List<({String rule, String what})> notes,
    })
  >
  _frameCache = {};

  /// Checks the frame of the scene's world now.
  void check(String at) {
    final W = scene.host.W;
    checked++;
    final rawItems = (_m.placed(W, 0) as List);
    final setKey = scene.setKey(W);
    final spot = (W['cq'] as Map?)?['spot'] as String?;
    final frogDy = ((W['cq'] as Map?)?['dy'] as num? ?? 0).abs();
    final titoSpot =
        ((W['gente'] as Map?)?['tito'] as Map?)?['spot'] as String?;
    final dynamic cb = _m.cardBoxes(W);
    final mesas = W['mesas'];
    final sig = StringBuffer()
      ..write(setKey)
      ..write('|')
      ..write(spot)
      ..write('|')
      ..write(frogDy > 0 ? 1 : 0)
      ..write('|')
      ..write(titoSpot)
      ..write('|')
      ..write(mesas)
      ..write('|');
    if (cb != null) {
      sig
        ..write(cb.a)
        ..write(',')
        ..write(cb.b);
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
              ink: _inkOf(it.s as Sprite),
            ),
        ];
    final S = _cachedS ??= (_m.places.e.S as num).toDouble();
    final bias = _cachedBias ??= (_m.places.bias as num).toDouble();
    final x0 = _cachedX0 ??= ((_m.places.view('wide') as List)[0] as num)
        .toInt();
    final winR = x0 + 196;
    final zb = _zbOf(setKey);

    // Build per-pixel max sprite plane map (excluding a given index) on demand.
    ({int hid, int cov, int out, Map<String, int> by, int total}) covOf(
      int idx, {
      int? maxRowsFromTop,
    }) {
      final f = items[idx];
      final ink = f.ink;
      if (ink == null) {
        return (hid: 0, cov: 0, out: 0, by: const {}, total: 0);
      }
      final yLim = maxRowsFromTop == null
          ? f.s.h
          : math.min(f.s.h, ink[1] + maxRowsFromTop);
      var hid = 0, cov = 0, outPx = 0, total = 0;
      final by = <String, int>{};
      for (var y = ink[1]; y < yLim; y++) {
        final Y = f.top + y;
        final plane = f.d + (f.sy - (Y + .5)) * _t30 / S;
        for (var x = ink[0]; x <= ink[2]; x++) {
          if (f.s.px[y * f.s.w + x] >>> 24 == 0) continue;
          total++;
          final X = f.left + x;
          if (X < 0 || X >= 240 || Y < 0 || Y >= 216) {
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

    // 1. frog-seen & frog-on-hand
    final fi = items.indexWhere((it) => it.tag == 'coqui');
    if (fi >= 0) {
      final c = covOf(fi);
      if (c.out > 0) {
        addBreach(
          'frog-on-hand',
          '${c.out} px of frog outside picture (spot $spot)',
        );
      }
      if (c.hid > 0 || c.cov > 0) {
        final msg =
            'frog at $spot: ${c.hid} hidden by set, ${c.cov} under ${c.by}';
        if (spot == 'balcon2' && c.cov == 0) {
          // On balcon2 (dev aid moment 7, behind the balcony rail) the rail's bars sit in front of his feet.
          addNote('frog-seen (balcon2 rail)', msg);
        } else if (spot == 'escalera' &&
            c.hid == 0 &&
            c.by.length == 1 &&
            (c.by['persona:luis'] ?? 0) <= 8) {
          // On escalera (dev aid moment 8, ladder transit behind pie1) Luis's hair touches the frog's lower corner.
          addNote('frog-seen (escalera transit)', msg);
        } else {
          addBreach('frog-seen', msg);
        }
      }
    }

    // 2. tito-face (<= 8% of face disc covered by don Tito at balcon1)
    final ti = items.indexWhere((it) => it.tag == 'persona:tito');
    if (ti >= 0 && titoSpot == 'balcon1') {
      final disc = _cachedDisc ??=
          _m.places.faceDisc as ({double cx, double cy, double r});
      final faceTotal = _cachedFaceTotal ??= () {
        var n = 0;
        for (var y = 0; y < 216; y++) {
          for (var x = 0; x < 240; x++) {
            final dx = x + .5 - disc.cx, dy = y + .5 - disc.cy;
            if (dx * dx + dy * dy < disc.r * disc.r) n++;
          }
        }
        return n;
      }();
      final t = items[ti];
      final ink = t.ink;
      if (ink != null) {
        var onFace = 0;
        for (var y = ink[1]; y <= ink[3]; y++) {
          final Y = t.top + y;
          if (Y < 0 || Y >= 216) continue;
          final plane = t.d + (t.sy - (Y + .5)) * _t30 / S;
          for (var x = ink[0]; x <= ink[2]; x++) {
            if (t.s.px[y * t.s.w + x] >>> 24 == 0) continue;
            final X = t.left + x;
            if (X < 0 || X >= 240) continue;
            if (zb[Y * 240 + X] > plane + bias) continue;
            final dx = X + .5 - disc.cx, dy = Y + .5 - disc.cy;
            if (dx * dx + dy * dy < disc.r * disc.r) onFace++;
          }
        }
        if (onFace > faceTotal * 0.08) {
          addBreach(
            'tito-face',
            'don Tito covers $onFace of $faceTotal px (> 8%)',
          );
        }
      }
    }

    // 3. vendedor-head (top 14 rows of vendedor clear of set/awning and nearer sprites)
    final vi = items.indexWhere((it) => it.tag == 'persona:vendedor');
    if (vi >= 0) {
      final c = covOf(vi, maxRowsFromTop: 14);
      if (c.hid > 0 || c.cov > 0) {
        addBreach(
          'vendedor-head',
          '${c.hid} hidden by set, ${c.cov} covered by ${c.by}',
        );
      }
    }

    // 4. cards-clear (time cards inside window, covering neither frog, face nor vendedor)
    if (cb != null) {
      final disc = _cachedDisc ??=
          _m.places.faceDisc as ({double cx, double cy, double r});
      for (final (name, b) in [
        ('carta_a', cb.a as List<num>),
        ('carta_b', cb.b as List<num>),
      ]) {
        final bx = b[0].toInt(),
            by = b[1].toInt(),
            bw = b[2].toInt(),
            bh = b[3].toInt();
        if (bx < x0 || bx + bw > winR || by < 0 || by + bh > 216) {
          addBreach('cards-clear', '$name $b outside window [$x0, $winR)');
        }
        var onFace = 0;
        for (var y = by; y < by + bh; y++) {
          for (var x = bx; x < bx + bw; x++) {
            final dx = x + .5 - disc.cx, dy = y + .5 - disc.cy;
            if (dx * dx + dy * dy < disc.r * disc.r) onFace++;
          }
        }
        if (onFace > 0) {
          addBreach('cards-clear', '$name covers $onFace px of face');
        }
        for (final checkIdx in [fi, vi]) {
          if (checkIdx < 0) continue;
          final o = items[checkIdx];
          final ink = o.ink;
          if (ink == null) continue;
          var hit = 0;
          for (var y = ink[1]; y <= ink[3]; y++) {
            final Y = o.top + y;
            if (Y < by || Y >= by + bh) continue;
            for (var x = ink[0]; x <= ink[2]; x++) {
              final X = o.left + x;
              if (X < bx || X >= bx + bw) continue;
              if (o.s.px[y * o.s.w + x] >>> 24 != 0) hit++;
            }
          }
          if (hit > 0) {
            addBreach('cards-clear', '$name covers $hit px of ${o.tag}');
          }
        }
      }
    }

    // 5. carton-clear, bingo-clear, table-heads (story 65)
    if (mesas == 1) {
      for (final n in const [40, 60, 80, 90, 100]) {
        final b = _m.places.box('n$n') as List<int>;
        if (b[0] < x0 || b[0] + b[2] > winR || b[1] < 0 || b[1] + b[3] > 216) {
          addBreach('carton-clear', 'n$n $b outside window [$x0, $winR)');
        }
        for (final o in items) {
          final ink = o.ink;
          if (ink == null) continue;
          var hit = 0;
          for (var y = ink[1]; y <= ink[3]; y++) {
            final Y = o.top + y;
            if (Y < b[1] || Y >= b[1] + b[3]) continue;
            for (var x = ink[0]; x <= ink[2]; x++) {
              final X = o.left + x;
              if (X < b[0] || X >= b[0] + b[2]) continue;
              if (o.s.px[y * o.s.w + x] >>> 24 != 0) hit++;
            }
          }
          if (hit > 0) {
            addBreach('carton-clear', 'n$n overlaps $hit px of ${o.tag}');
          }
        }
      }
      for (final k in const [
        'cosa:jaula',
        'cosa:premio1',
        'cosa:premio2',
        'cosa:premio3',
      ]) {
        final idx = items.indexWhere((it) => it.tag == k);
        if (idx < 0) continue;
        final c = covOf(idx);
        if (c.hid > 0 || c.cov > 0) {
          addBreach(
            'bingo-clear',
            '$k: ${c.hid} hidden by set, ${c.cov} under ${c.by}',
          );
        }
      }
      // table-heads: frog resting on mesa_abuela.coqui covers <= 10% of abuela's head (top 14 rows) and 0 of Luis's
      for (final (who, lim) in const [('abuela', 0.10), ('luis', 0.0)]) {
        final idx = items.indexWhere((it) => it.tag == 'persona:$who');
        if (idx < 0) continue;
        final c = covOf(idx, maxRowsFromTop: 14);
        final byFrog = c.by['coqui'] ?? 0;
        if (byFrog > c.total * lim + 1e-9) {
          if (frogDy > 0) {
            addNote(
              'table-heads (frog bounce)',
              'frog mid-bounce covers $byFrog of ${c.total} px of $who head',
            );
          } else {
            addBreach(
              'table-heads',
              'frog covers $byFrog of ${c.total} px of $who head',
            );
          }
        }
      }
    }

    // 6. spots-in-view: every visible person inside the window and picture
    for (final it in items) {
      if (it.tag == null || !it.tag!.startsWith('persona:')) continue;
      final ink = it.ink;
      if (ink == null) continue;
      final l = it.left + ink[0], r = it.left + ink[2];
      final t = it.top + ink[1], b = it.top + ink[3];
      if (l < x0 || r >= winR || t < 0 || b >= 216) {
        addBreach(
          'spots-in-view',
          '${it.tag} [$l..$r, $t..$b] outside window [$x0..${winR - 1}, 0..215]',
        );
      }
    }

    _frameCache[key] = (breaches: localBreaches, notes: localNotes);
  }
}
