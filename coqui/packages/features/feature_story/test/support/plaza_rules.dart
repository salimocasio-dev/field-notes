// El banco de la plaza's rules (plaza-sheet.json's rules and checks, and page 13's "The sheet's rules hold in the scene"),
// checked on the real scene's frame at every act's end and at the story's end: the scene's acts are wrapped so that each,
// once done, has the frame looked at. What is checked:
// - the frog is whole: none of his drawn pixels is hidden by the set, outside the picture, or under a nearer sprite (a
//   nearer dog aside, as the sheet's frog-seen; a pigeon that sits on him in story 60's ending is the story's) (frog-seen);
// - the piragüero's head (the top 14 rows of his sprite) is clear of his awning, his cart and every nearer sprite
//   (piraguero-head: a seller's head and paper hat clear of his awning);
// - a photo or a drawing on a hook never covers a neighbouring hook (the hooks are the sheet's `ganchos`);
// - nobody covers the notice board's pictures or its rows of hooks (board-clear: no person's pixel inside the boxes of
//   things.fila_isla and fila_ciudad); the frog on the ledge (`repisa`, story 61's ending, where the story sends him) is
//   counted apart, in [PlazaRules.notes]: the sheet's check reads only moments 3 and 4, with the cards there;
// - the two answer bubbles cover neither the frog nor a pigeon (bubbles); with the frog at asiento1 (where story 60 puts
//   him) the pixels of a pigeon they cover are counted apart, in [PlazaRules.notes] (the sheet checks them at asiento4);
// - the frog on the cart covers no more than a quarter of the piragüero's box by his drawn pixels (frog-on-cart);
// - every person and thing drawn stands inside the picture and the view's window (spots-in-view; entrada apart: whoever
//   walks in or out passes it);
// - nobody stands on a place another person holds (two people's feet at least 10 px apart).
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/coqui_scenes.dart';

/// What went against a rule: when, which rule, the details.
typedef PlazaBreach = ({String at, String rule, String what});

final double _t30 = math.tan(math.pi / 6);

/// Watches a real El banco de la plaza while a story plays: [wrap] its acts, then read [breaches], [notes] and [checked].
class PlazaRules {
  PlazaRules(this.scene) : _m = scene;

  /// The scene (its own members, `placed`, `places`, `bubbleBoxes`, are reached untyped: a feature may not import a
  /// package's src/).
  final SetScene scene;
  final dynamic _m;

  static final Map<String, Float32List> _zb = {};
  static SetBakes? _bakes;
  Float32List _zbOf(String key) => _zb[key] ??= Float32List.fromList(
    (_bakes ??= SetBakes(scene)).bakeKey(key).zb,
  );
  final List<PlazaBreach> breaches = [];

  /// What the rules count apart (where the story's places and the sheet's checks do not meet): the frog on the ledge
  /// over the board, the bubbles over a pigeon. The report gives them to the content lane.
  final List<PlazaBreach> notes = [];
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

  Map<String, List<int>>? _hooks;
  List<List<int>>? _boardBoxes;
  double? _cachedS;
  double? _cachedBias;

  /// Checks the frame of the scene's world now.
  void check(String at) {
    final W = scene.host.W;
    checked++;
    final rawItems = (_m.placed(W, 0) as List);
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
    final z = _zbOf(scene.setKey(W));
    final kS = _t30 / S;
    double planeAt(double d, double sy, int Y) => d + (sy - (Y + .5)) * kS;
    bool px(
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
      it,
      int X,
      int Y,
    ) {
      if (X < it.left || X >= it.right || Y < it.top || Y >= it.bottom) {
        return false;
      }
      final x = X - it.left, y = Y - it.top;
      return it.s.px[y * it.s.w + x] >>> 24 != 0;
    }

    // what hides a pixel (X, Y) of [it]: 'set', 'outside', a nearer sprite's tag, or null
    String? hider(
      double itD,
      double itSy,
      int X,
      int Y,
      List<
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
      >
      cands,
    ) {
      if (X < 0 || X >= 240 || Y < 0 || Y >= 216) return 'outside';
      final plane = planeAt(itD, itSy, Y);
      if (z[Y * 240 + X] > plane + bias) return 'set';
      for (var i = 0; i < cands.length; i++) {
        final o = cands[i];
        if (X < o.left || X >= o.right || Y < o.top || Y >= o.bottom) continue;
        final x = X - o.left, y = Y - o.top;
        if (o.s.px[y * o.s.w + x] >>> 24 == 0) continue;
        if (planeAt(o.d, o.sy, Y) > plane + .001) return o.tag;
      }
      return null;
    }

    // the frog is whole
    final frogs = [
      for (final i in items)
        if (i.tag == 'coqui') i,
    ];
    for (final f in frogs) {
      final hidden = <String, int>{};
      final fb = f.ink;
      if (fb != null) {
        final fx0 = f.left + fb[0],
            fy0 = f.top + fb[1],
            fx1 = f.left + fb[2],
            fy1 = f.top + fb[3];
        final cands = [
          for (final o in items)
            if (!identical(o, f) &&
                o.tag != null &&
                o.tag != 'perro' &&
                !o.tag!.startsWith('paloma:') &&
                o.right > fx0 &&
                o.left <= fx1 &&
                o.bottom > fy0 &&
                o.top <= fy1)
              o,
        ];
        final fs = f.s;
        for (var y = fb[1]; y <= fb[3]; y++) {
          for (var x = fb[0]; x <= fb[2]; x++) {
            if (fs.px[y * fs.w + x] >>> 24 == 0) {
              continue;
            }
            final h = hider(f.d, f.sy, f.left + x, f.top + y, cands);
            if (h != null) hidden[h] = (hidden[h] ?? 0) + 1;
          }
        }
      }
      // a person the scene could place nowhere that leaves him whole (`tapa`: no free spot of the row) is counted apart
      final apart = <String, int>{
        for (final e in hidden.entries)
          if (e.key.startsWith('persona:') &&
              ((W['gente'] as Map)[e.key.substring(8)] as Map?)?['tapa'] == 1)
            e.key: e.value,
      };
      for (final k in apart.keys) {
        hidden.remove(k);
      }
      if (apart.isNotEmpty) {
        notes.add((
          at: at,
          rule: 'the frog not whole (no free spot of the row)',
          what: '$apart',
        ));
      }
      if (hidden.isNotEmpty) {
        breaches.add((at: at, rule: 'the frog not whole', what: '$hidden'));
      }
    }
    // the piragüero's head
    for (final it in items) {
      if (it.tag != 'persona:piraguero') continue;
      final b = it.ink!;
      final px0 = it.left,
          py0 = it.top + b[1],
          px1 = it.right,
          py1 = it.top + b[1] + 14;
      final cands = [
        for (final o in items)
          if (!identical(o, it) &&
              o.tag != null &&
              o.right > px0 &&
              o.left < px1 &&
              o.bottom > py0 &&
              o.top < py1)
            o,
      ];
      final hidden = <String, int>{};
      for (var y = b[1]; y < b[1] + 14; y++) {
        for (var x = 0; x < it.s.w; x++) {
          if (it.s.px[y * it.s.w + x] >>> 24 == 0) {
            continue;
          }
          final h = hider(it.d, it.sy, it.left + x, it.top + y, cands);
          if (h != null) hidden[h] = (hidden[h] ?? 0) + 1;
        }
      }
      if (hidden.isNotEmpty) {
        breaches.add((
          at: at,
          rule: 'the piragüero\'s head covered',
          what: '$hidden',
        ));
      }
    }
    // a card on a hook never covers a neighbouring hook
    final hooks = _hooks ??= {
      for (final fila in const ['isla', 'ciudad'])
        fila: [
          for (final h
              in (_m.places.ganchos(fila) as List).cast<List<double>>())
            scene.projection.project(h[0], h[1], h[2]).sx.floor(),
        ],
    };
    for (final it in items) {
      if (it.tag == null || !it.tag!.startsWith('foto:')) continue;
      final t = it.tag!.substring(5);
      final fila = t.startsWith('isla') ? 'isla' : 'ciudad';
      final i = int.parse(t.substring(fila.length));
      final b = it.ink!;
      final x0 = it.left + b[0], x1 = it.left + b[2];
      final all = [...hooks['isla']!, ...hooks['ciudad']!];
      final mine = hooks[fila]![i];
      for (final h in all) {
        if (h == mine) continue;
        if (h >= x0 && h <= x1) {
          breaches.add((
            at: at,
            rule: 'a card covers a hook\'s neighbour',
            what: '$t over the hook at column $h',
          ));
        }
      }
    }
    // nobody covers the board's pictures and its rows of hooks
    if ((W['tablero'] as num? ?? 0) == 1) {
      final boxes = _boardBoxes ??= [
        for (final k in const ['fila_isla', 'fila_ciudad'])
          (_m.places.box(k) as List).cast<int>(),
      ];
      for (final it in items) {
        final tag = it.tag;
        if (tag == null ||
            (!tag.startsWith('persona:') &&
                tag != 'coqui' &&
                !tag.startsWith('cola:'))) {
          continue;
        }
        var n = 0;
        for (final b in boxes) {
          final x0 = math.max(b[0], it.left),
              x1 = math.min(b[0] + b[2], it.right);
          final y0 = math.max(b[1], it.top),
              y1 = math.min(b[1] + b[3], it.bottom);
          if (x0 >= x1 || y0 >= y1) continue;
          for (var Y = y0; Y < y1; Y++) {
            final pl = planeAt(it.d, it.sy, Y) + bias;
            final sy = Y - it.top;
            for (var X = x0; X < x1; X++) {
              if (it.s.px[sy * it.s.w + (X - it.left)] >>> 24 == 0) continue;
              if (z[Y * 240 + X] > pl) continue;
              n++;
            }
          }
        }
        if (n == 0) continue;
        final q = W['cq'] as Map;
        final onLedge = tag == 'coqui' && q['spot'] == 'repisa';
        (onLedge ? notes : breaches).add((
          at: at,
          rule: 'the board\'s pictures covered',
          what: '$tag${onLedge ? ' (on the ledge, repisa)' : ''}: $n px',
        ));
      }
    }
    // the answer bubbles cover neither the frog nor a pigeon
    final bb = _m.bubbleBoxes(W);
    if (bb != null) {
      for (final b in [
        (bb.a as List).cast<num>(),
        (bb.b as List).cast<num>(),
      ]) {
        final bx0 = b[0].toInt(),
            by0 = b[1].toInt(),
            bx1 = (b[0] + b[2]).toInt(),
            by1 = (b[1] + b[3]).toInt();
        for (final it in items) {
          final tag = it.tag;
          if (tag != 'coqui' && (tag == null || !tag.startsWith('paloma:'))) {
            continue;
          }
          final x0 = math.max(bx0, it.left), x1 = math.min(bx1, it.right);
          final y0 = math.max(by0, it.top), y1 = math.min(by1, it.bottom);
          if (x0 >= x1 || y0 >= y1) continue;
          var n = 0;
          for (var Y = y0; Y < y1; Y++) {
            final sy = Y - it.top;
            for (var X = x0; X < x1; X++) {
              if (it.s.px[sy * it.s.w + (X - it.left)] >>> 24 != 0) n++;
            }
          }
          if (n == 0) continue;
          final q = W['cq'] as Map;
          final pigeonOff4 = tag != 'coqui' && q['spot'] != 'asiento4';
          (pigeonOff4 ? notes : breaches).add((
            at: at,
            rule: 'a bubble over ${tag == 'coqui' ? 'the frog' : 'a pigeon'}',
            what: '$tag: $n px (the frog at ${q['spot']})',
          ));
        }
      }
    }
    // the frog on the cart: no more than a quarter of the piragüero's box
    final q = W['cq'] as Map;
    if (q['spot'] == 'carro_borde') {
      for (final p in items) {
        if (p.tag != 'persona:piraguero') continue;
        final b = p.ink!;
        final box = [
          p.left + b[0],
          p.top + b[1],
          b[2] - b[0] + 1,
          b[3] - b[1] + 1,
        ];
        for (final f in frogs) {
          var n = 0;
          for (var Y = box[1]; Y < box[1] + box[3]; Y++) {
            for (var X = box[0]; X < box[0] + box[2]; X++) {
              if (px(f, X, Y)) n++;
            }
          }
          if (n * 4 > box[2] * box[3]) {
            breaches.add((
              at: at,
              rule: 'the frog on the cart covers the piragüero',
              what: '$n of ${box[2] * box[3]} px',
            ));
          }
        }
      }
    }
    // inside the picture and the view
    final cam = scene.CAM['wide']!;
    for (final it in items) {
      final b = it.ink;
      if (b == null) continue;
      final tag = it.tag!;
      if (tag.startsWith('persona:')) {
        final p = (W['gente'] as Map)[tag.substring(8)] as Map?;
        if (p != null && p['spot'] == 'entrada') continue;
        if (p != null && p['spot'] != null && !_moving(p)) {
          // standing at a spot: checked
        } else {
          continue; // walking in or out
        }
      }
      if (tag.startsWith('paloma:') || tag.startsWith('cosa:')) {
        continue; // flying off, carried in a hand
      }
      final sx = it.left + (b[0] + b[2]) ~/ 2;
      if (sx < cam[0] ||
          sx >= cam[0] + cam[2] ||
          it.sy > 216 ||
          it.top + b[1] < 0) {
        breaches.add((
          at: at,
          rule: 'outside the view',
          what: '$tag at column $sx, row ${it.sy.toInt()}',
        ));
      }
    }
    // people apart (feet at least 10 px apart); whoever is at `entrada` or on the way (walking in or out) apart
    bool standing(String tag) {
      if (!tag.startsWith('persona:')) return true;
      final p = (W['gente'] as Map)[tag.substring(8)] as Map?;
      return p != null && p['spot'] != 'entrada' && !_moving(p);
    }

    final people = [
      for (final it in items)
        if (it.tag != null &&
            standing(it.tag!) &&
            (it.tag!.startsWith('persona:') ||
                it.tag == 'coqui' ||
                it.tag!.startsWith('cola:')))
          it,
    ];
    for (var i = 0; i < people.length; i++) {
      for (var j = i + 1; j < people.length; j++) {
        final a = people[i], b = people[j];
        final ba = a.ink!, bb2 = b.ink!;
        final ax = a.left + (ba[0] + ba[2]) / 2,
            bx = b.left + (bb2[0] + bb2[2]) / 2;
        final d = math.sqrt(
          (ax - bx) * (ax - bx) + (a.sy - b.sy) * (a.sy - b.sy),
        );
        if (d < 10) {
          breaches.add((
            at: at,
            rule: 'two people on one place',
            what: '${a.tag} ~ ${b.tag}: ${d.toStringAsFixed(1)} px',
          ));
        }
      }
    }
  }

  // a person is where its spot says (not on the way)
  bool _moving(Map p) {
    final w = (_m.places.world(p['spot'] as String) as List).cast<double>();
    return ((p['x'] as num) - w[0]).abs() > 1e-6 ||
        ((p['y'] as num) - w[1]).abs() > 1e-6;
  }
}
