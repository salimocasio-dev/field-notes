// El mostrador's rules (mostrador-sheet.json's rules and checks, and page 13's "The sheet's rules hold in the scene"), checked
// on the real scene's frame at every act's end and at the story's end: the scene's acts are wrapped so that each, once
// done, has the frame looked at. What is checked (the rules that are El mostrador's; the amount plate, the price tag
// at `etiqueta` and the children seen through the shop window's panes are La caja's sheet's, not this one's):
// - the frog is never behind a grown-up: where the frog's pixels and a grown-up's overlap, the grown-up is not nearer
//   (front.sprites: the nearer pixel wins);
// - every person and thing drawn stands inside the picture, its feet inside the view's window (spots-in-view);
// - the three children at the door show their heads whole (ninos-puerta-heads: the top 14 rows of each, hidden neither by
//   the set nor by another sprite);
// - nobody stands on a place another person holds (people-apart: two people's feet at least 10 px apart);
// - the frog on the counter stands only at coqui.mostrador, off the register's body (frog-register-body).
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/coqui_scenes.dart';
// the scene's own type (its placed sprites): a test reaches it through the package's file
// ignore: implementation_imports
import 'package:coqui_scenes/src/mostrador/mostrador.dart';

/// What went against a rule: when, which rule, the details.
typedef MostradorBreach = ({String at, String rule, String what});

final double _t30 = math.tan(math.pi / 6);

/// Watches a real El mostrador while a story plays: [wrap] its acts, then read [breaches] and [checked].
class MostradorRules {
  MostradorRules(this.scene);

  final Mostrador scene;

  // the baked depth of each state, made once for every run of the process (the set is the same in every one)
  static final Map<String, Float32List> _zb = {};
  static SetBakes? _bakes;
  Float32List _zbOf(String key) => _zb[key] ??= Float32List.fromList(
    (_bakes ??= SetBakes(scene)).bakeKey(key).zb,
  );
  final List<MostradorBreach> breaches = [];
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

  static bool _adult(String tag) =>
      tag.startsWith('persona:') &&
      !tag.contains(':nino') &&
      tag != 'persona:luis' &&
      tag != 'persona:carmen';

  List<int>? _ink(MostradorItem it) {
    final s = it.s;
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
    final items = scene.placed(W, 0);
    final S = scene.places.e.S;
    double planeK(MostradorItem it) => it.d + it.sy * _t30 / S;
    // the frog is never behind a grown-up
    for (final f in items.where((i) => i.tag == 'coqui')) {
      for (final p in items.where((i) => i.tag != null && _adult(i.tag!))) {
        if (planeK(p) <= planeK(f)) continue;
        var n = 0;
        for (var y = 0; y < f.s.h; y++) {
          for (var x = 0; x < f.s.w; x++) {
            if (f.s.px[y * f.s.w + x] >>> 24 == 0) continue;
            final X = f.left + x - p.left, Y = f.top + y - p.top;
            if (X < 0 || Y < 0 || X >= p.s.w || Y >= p.s.h) continue;
            if (p.s.px[Y * p.s.w + X] >>> 24 != 0) n++;
          }
        }
        if (n > 0) {
          breaches.add((
            at: at,
            rule: 'frog behind a grown-up',
            what: '${p.tag}: $n px over the frog',
          ));
        }
      }
    }
    // inside the picture and the view
    final cam = scene.CAM[scene.donde(W)]!;
    for (final it in items) {
      final b = _ink(it);
      if (b == null) continue;
      final sx = it.left + (b[0] + b[2]) ~/ 2;
      if (it.tag!.startsWith('cosa:carrito')) {
        continue; // the cart outside, seen through the door: cut by the door
      }
      if (sx < cam[0] ||
          sx >= cam[0] + cam[2] ||
          it.sy > 216 ||
          it.top + b[1] < 0) {
        breaches.add((
          at: at,
          rule: 'outside the view',
          what: '${it.tag} at column $sx, row ${it.sy}',
        ));
      }
    }
    // the children's heads at the door
    final key = scene.setKey(W);
    final z = _zbOf(key);
    final bias = scene.places.bias;
    for (final it in items.where(
      (i) => i.tag != null && i.tag!.startsWith('persona:nino'),
    )) {
      final spot = ((W['gente'] as Map)[it.tag!.substring(8)] as Map)['spot'];
      if (spot is! String || !spot.startsWith('ninos_puerta')) continue;
      final b = _ink(it)!;
      var hidden = 0;
      for (var y = b[1]; y < b[1] + 14 && y < it.s.h; y++) {
        final Y = it.top + y, plane = it.d + (it.sy - (Y + .5)) * _t30 / S;
        for (var x = 0; x < it.s.w; x++) {
          if (it.s.px[y * it.s.w + x] >>> 24 == 0) continue;
          final X = it.left + x;
          if (X < 0 || X >= 240 || Y < 0 || Y >= 216) continue;
          if (z[Y * 240 + X] > plane + bias) hidden++;
        }
      }
      if (hidden > 0) {
        breaches.add((
          at: at,
          rule: 'a child\'s head hidden at the door',
          what: '${it.tag}: $hidden px',
        ));
      }
    }
    // people apart (feet at least 10 px apart), in the picture shown
    final people = [
      for (final it in items)
        if (it.tag != null &&
            (it.tag!.startsWith('persona:') || it.tag == 'coqui'))
          it,
    ];
    for (var i = 0; i < people.length; i++) {
      for (var j = i + 1; j < people.length; j++) {
        final a = people[i], b = people[j];
        final ba = _ink(a)!, bb = _ink(b)!;
        final ax = a.left + (ba[0] + ba[2]) / 2,
            bx = b.left + (bb[0] + bb[2]) / 2;
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
    // the frog on the counter: only at coqui.mostrador
    final q = W['cq'] as Map;
    if (jsTruthy(q['vis']) && q['z'] == 1) {
      final L = scene.lugar['mostrador']!;
      if (q['x'] != L[0] || q['y'] != L[1]) {
        breaches.add((
          at: at,
          rule: 'the frog on the counter off his place',
          what: 'at ${q['x']},${q['y']}',
        ));
      }
    }
  }
}
