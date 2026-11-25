// El calendario's rules (calendario-sheet.json's rules and checks, and page 13's "The sheet's rules hold in the scene"),
// checked on the real scene's frame at every act's end and at the story's end:
// - frog-seen: 0 px of the frog hidden by the set, outside the picture, or under a nearer sprite (excluding his own
//   held balloon `held:globo_coqui`);
// - senora-col1: the señora at `izq` covers 0 px of column 1 (`things.dia1`);
// - arch-card: when `cosa:arco_carta` is shown, 0 px outside the picture or view window;
// - balloons: when `cosa:globos` is shown, 0 px outside the picture or view window;
// - seat-heads: every person on `asiento1..3` lies inside the view window and has 0 px of their top 14 head rows
//   hidden by the set or covered by another sprite (excluding their own `held:*` basket/balloon);
// - spots-in-view: every visible person's drawn ink lies inside the picture and the view window [x0, x0 + 196).
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/coqui_scenes.dart';

/// What went against a rule: when, which rule, the details.
typedef CalendarioBreach = ({String at, String rule, String what});

final double _t30 = math.tan(math.pi / 6);

/// Watches a real El calendario while a story plays: [wrap] its acts, then read [breaches], [notes] and [checked].
class CalendarioRules {
  CalendarioRules(this.scene) : _m = scene;

  final SetScene scene;
  final dynamic _m;

  static final Map<String, Float32List> _zb = {};
  static SetBakes? _bakes;
  Float32List _zbOf(String key) => _zb[key] ??= Float32List.fromList(
    (_bakes ??= SetBakes(scene)).bakeKey(key).zb,
  );

  final List<CalendarioBreach> breaches = [];
  final List<CalendarioBreach> notes = [];
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
  List<int>? _cachedCol1;

  static final Map<
    String,
    ({
      List<({String rule, String what})> breaches,
      List<({String rule, String what})> notes,
    })
  >
  _frameCache = {};

  void check(String at) {
    final W = scene.host.W;
    checked++;
    final rawItems = (_m.placed(W, 0) as List);
    final setKey = scene.setKey(W);
    final gente = (W['gente'] as Map?) ?? const {};
    final sig = StringBuffer()..write(setKey);
    for (final k in const ['abuela', 'tito', 'senor', 'luis']) {
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
    final col1 = _cachedCol1 ??= (_m.places.box('dia1') as List).cast<int>();
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

    // 1. frog-seen
    final fi = items.indexWhere((it) => it.tag == 'coqui');
    if (fi >= 0) {
      final c = covOf(fi, ignore: (t) => t == 'held:globo_coqui');
      if (c.hid > 0 || c.cov > 0 || c.out > 0) {
        addBreach(
          'frog-seen',
          'frog at ${(W['cq'] as Map?)?['spot']}: ${c.hid} hidden by set, ${c.cov} under ${c.by}, ${c.out} outside',
        );
      }
    }

    // 2. senora-col1
    final si = items.indexWhere((it) => it.tag == 'persona:senora');
    if (si >= 0 && items[si].ink != null) {
      final it = items[si], ink = it.ink!;
      var hit = 0;
      for (var y = ink[1]; y <= ink[3]; y++) {
        final Y = it.top + y;
        if (Y < col1[1] || Y >= col1[1] + col1[3]) continue;
        for (var x = ink[0]; x <= ink[2]; x++) {
          if (it.s.px[y * it.s.w + x] >>> 24 == 0) continue;
          final X = it.left + x;
          if (X >= col1[0] && X < col1[0] + col1[2]) hit++;
        }
      }
      if (hit > 0) {
        addBreach('senora-col1', 'senora covers $hit px of column 1 $col1');
      }
    }

    // 3. arch-card & balloons whole in picture & window
    for (final tag in const ['cosa:arco_carta', 'cosa:globos']) {
      final idx = items.indexWhere((it) => it.tag == tag);
      if (idx < 0 || items[idx].ink == null) continue;
      final it = items[idx], ink = it.ink!;
      final l = it.left + ink[0], r = it.left + ink[2];
      final t = it.top + ink[1], b = it.top + ink[3];
      if (l < x0 || r >= winR || t < 0 || b >= 216) {
        addBreach(
          tag == 'cosa:globos' ? 'balloons' : 'arch-card',
          '$tag ink [$l..$r, $t..$b] out of window [$x0..${winR - 1}, 0..215]',
        );
      }
    }

    // 4. seat-heads (top 14 rows of anyone sitting on asiento1..3)
    for (var i = 0; i < items.length; i++) {
      final tag = items[i].tag;
      if (tag == null || !tag.startsWith('persona:')) continue;
      final who = tag.substring(8);
      if (who == 'perro') continue;
      final p = gente[who] as Map?;
      final spot = p?['spot'] as String?;
      if (spot != null && spot.startsWith('asiento')) {
        final c = covOf(
          i,
          maxRowsFromTop: 14,
          ignore: (t) => t != null && t.startsWith('held:'),
        );
        if (c.hid > 0 || c.cov > 0 || c.out > 0) {
          addBreach(
            'seat-heads',
            '$who at $spot head (top 14 rows): ${c.hid} hidden by set, ${c.cov} under ${c.by}, ${c.out} outside',
          );
        }
      }
    }

    // 5. spots-in-view: every visible person inside [x0, x0 + 196)
    for (final it in items) {
      if (it.tag == null || !it.tag!.startsWith('persona:')) continue;
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

    _frameCache[key] = (breaches: localBreaches, notes: localNotes);
  }
}
