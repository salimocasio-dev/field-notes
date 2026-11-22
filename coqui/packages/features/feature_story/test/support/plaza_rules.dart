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

  static List<int>? _ink(dynamic it) {
    final s = it.s as Sprite;
    var x0 = s.w, y0 = s.h, x1 = -1, y1 = -1;
    for (var y = 0; y < s.h; y++) {
      for (var x = 0; x < s.w; x++) {
        if (s.px[y * s.w + x] >>> 24 == 0) continue;
        x0 = math.min(x0, x);
        x1 = math.max(x1, x);
        y0 = math.min(y0, y);
        y1 = math.max(y1, y);
      }
    }
    return x1 < 0 ? null : [x0, y0, x1, y1];
  }

  /// Checks the frame of the scene's world now.
  void check(String at) {
    final W = scene.host.W;
    checked++;
    final items = (_m.placed(W, 0) as List).cast<dynamic>();
    final S = (_m.places.e.S as num).toDouble();
    final bias = (_m.places.bias as num).toDouble();
    final z = _zbOf(scene.setKey(W));
    double planeAt(dynamic it, int Y) =>
        (it.d as double) + ((it.sy as num) - (Y + .5)) * _t30 / S;
    bool px(dynamic it, int X, int Y) {
      final x = X - (it.left as int), y = Y - (it.top as int);
      final s = it.s as Sprite;
      if (x < 0 || y < 0 || x >= s.w || y >= s.h) return false;
      return s.px[y * s.w + x] >>> 24 != 0;
    }

    // what hides a pixel (X, Y) of [it]: 'set', 'outside', a nearer sprite's tag, or null
    String? hider(dynamic it, int X, int Y, bool Function(String tag) counts) {
      if (X < 0 || X >= 240 || Y < 0 || Y >= 216) return 'outside';
      final plane = planeAt(it, Y);
      if (z[Y * 240 + X] > plane + bias) return 'set';
      for (final o in items) {
        if (identical(o, it) || o.tag == null || !counts(o.tag as String)) {
          continue;
        }
        if (!px(o, X, Y)) continue;
        if (planeAt(o, Y) > plane + .001) return o.tag as String;
      }
      return null;
    }

    // the frog is whole
    final frogs = items.where((i) => i.tag == 'coqui').toList();
    for (final f in frogs) {
      final hidden = <String, int>{};
      for (var y = 0; y < (f.s as Sprite).h; y++) {
        for (var x = 0; x < (f.s as Sprite).w; x++) {
          if ((f.s as Sprite).px[y * (f.s as Sprite).w + x] >>> 24 == 0) {
            continue;
          }
          final h = hider(
            f,
            f.left + x,
            f.top + y,
            (t) => t != 'perro' && !t.startsWith('paloma:'),
          );
          if (h != null) hidden[h] = (hidden[h] ?? 0) + 1;
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
    for (final it in items.where((i) => i.tag == 'persona:piraguero')) {
      final b = _ink(it)!;
      final hidden = <String, int>{};
      for (var y = b[1]; y < b[1] + 14; y++) {
        for (var x = 0; x < (it.s as Sprite).w; x++) {
          if ((it.s as Sprite).px[y * (it.s as Sprite).w + x] >>> 24 == 0) {
            continue;
          }
          final h = hider(it, it.left + x, it.top + y, (t) => true);
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
    final hooks = <String, List<int>>{};
    for (final fila in const ['isla', 'ciudad']) {
      final g = (_m.places.ganchos(fila) as List).cast<List<double>>();
      hooks[fila] = [
        for (final h in g)
          scene.projection.project(h[0], h[1], h[2]).sx.floor(),
      ];
    }
    for (final it in items.where(
      (i) => i.tag != null && (i.tag as String).startsWith('foto:'),
    )) {
      final t = (it.tag as String).substring(5);
      final fila = t.startsWith('isla') ? 'isla' : 'ciudad';
      final i = int.parse(t.substring(fila.length));
      final b = _ink(it)!;
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
      final boxes = [
        for (final k in const ['fila_isla', 'fila_ciudad'])
          (_m.places.box(k) as List).cast<int>(),
      ];
      for (final it in items.where(
        (i) =>
            i.tag != null &&
            ((i.tag as String).startsWith('persona:') ||
                i.tag == 'coqui' ||
                (i.tag as String).startsWith('cola:')),
      )) {
        var n = 0;
        for (final b in boxes) {
          for (var Y = b[1]; Y < b[1] + b[3]; Y++) {
            for (var X = b[0]; X < b[0] + b[2]; X++) {
              if (!px(it, X, Y)) continue;
              if (z[Y * 240 + X] > planeAt(it, Y) + bias) continue;
              n++;
            }
          }
        }
        if (n == 0) continue;
        final q = W['cq'] as Map;
        final onLedge = it.tag == 'coqui' && q['spot'] == 'repisa';
        (onLedge ? notes : breaches).add((
          at: at,
          rule: 'the board\'s pictures covered',
          what: '${it.tag}${onLedge ? ' (on the ledge, repisa)' : ''}: $n px',
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
        for (final it in items.where(
          (i) =>
              i.tag == 'coqui' ||
              (i.tag != null && (i.tag as String).startsWith('paloma:')),
        )) {
          var n = 0;
          for (var Y = b[1].toInt(); Y < b[1] + b[3]; Y++) {
            for (var X = b[0].toInt(); X < b[0] + b[2]; X++) {
              if (px(it, X, Y)) n++;
            }
          }
          if (n == 0) continue;
          final q = W['cq'] as Map;
          final pigeonOff4 = it.tag != 'coqui' && q['spot'] != 'asiento4';
          (pigeonOff4 ? notes : breaches).add((
            at: at,
            rule:
                'a bubble over ${it.tag == 'coqui' ? 'the frog' : 'a pigeon'}',
            what: '${it.tag}: $n px (the frog at ${q['spot']})',
          ));
        }
      }
    }
    // the frog on the cart: no more than a quarter of the piragüero's box
    final q = W['cq'] as Map;
    if (q['spot'] == 'carro_borde') {
      for (final p in items.where((i) => i.tag == 'persona:piraguero')) {
        final b = _ink(p)!;
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
      final b = _ink(it);
      if (b == null) continue;
      final tag = it.tag as String;
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
          what: '$tag at column $sx, row ${it.sy}',
        ));
      }
    }
    // people apart (feet at least 10 px apart); whoever is at `entrada` or on the way (walking in or out) apart
    bool standing(dynamic it) {
      final tag = it.tag as String;
      if (!tag.startsWith('persona:')) return true;
      final p = (W['gente'] as Map)[tag.substring(8)] as Map?;
      return p != null && p['spot'] != 'entrada' && !_moving(p);
    }

    final people = [
      for (final it in items)
        if (it.tag != null &&
            standing(it) &&
            ((it.tag as String).startsWith('persona:') ||
                it.tag == 'coqui' ||
                (it.tag as String).startsWith('cola:')))
          it,
    ];
    for (var i = 0; i < people.length; i++) {
      for (var j = i + 1; j < people.length; j++) {
        final a = people[i], b = people[j];
        final ba = _ink(a)!, bb2 = _ink(b)!;
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
