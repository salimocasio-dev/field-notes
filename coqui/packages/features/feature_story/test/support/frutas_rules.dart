// Las frutas' rules (frutas-sheet.json's rules and checks, and page 13's "The sheet's rules hold in the scene"), checked on
// the real scene's frame at every act's end and at the story's end: the scene's acts are wrapped so that each, once
// done, has the frame looked at. What is checked (the amount plate and the price tag at `etiqueta` are La caja's and
// El mostrador's sheets', not this one's: this sheet names neither):
// - the frog is never behind a grown-up (don Pepe, abuela, the señora): where the frog's pixels and a grown-up's
//   overlap, the grown-up is not nearer (front.sprites: the nearer pixel wins);
// - every person, the goat and every thing drawn stands inside the picture, its middle inside the view's window
//   (checks: in-view);
// - the frog's drawn box clears the small things on the ledge: the coins, the basket, the crates, a bag (checks:
//   frog-places);
// - the two crates of the ledge do not overlap (checks: cajones-apart);
// - the goat eating from the low crate has its muzzle on cabra.cajon (checks: goat-reach; rules.anchor);
// - abuela at abuela.delante covers no pixel of a bin (checks: abuela-clear-of-bins), and with the cart there she is at
//   least 10 px clear of it (checks: cart-clear);
// - don Pepe at pepe.detras shows at least 24 rows over the stand (checks: pepe-over-stand, rules.person).
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/coqui_scenes.dart';

/// What went against a rule: when, which rule, the details.
typedef FrutasBreach = ({String at, String rule, String what});

final double _t30 = math.tan(math.pi / 6);

/// Watches a real Las frutas while a story plays: [wrap] its acts, then read [breaches] and [checked].
class FrutasRules {
  FrutasRules(this.scene) : _m = scene;

  /// The scene (Las frutas'; its own members, `placed`, `places`, `partTagsOf`, are reached as the scene's, untyped: a
  /// feature may not import a package's src/).
  final SetScene scene;
  final dynamic _m;

  // the baked depth of each state, made once for every run of the process (the set is the same in every one)
  static final Map<String, Float32List> _zb = {};
  static SetBakes? _bakes;
  Float32List _zbOf(String key) => _zb[key] ??= Float32List.fromList(
    (_bakes ??= SetBakes(scene)).bakeKey(key).zb,
  );
  final List<FrutasBreach> breaches = [];
  int checked = 0;

  static const List<String> _bins = [
    'tomates',
    'cebollas',
    'papas',
    'platanos',
    'aguacates',
    'pinas',
    'limones',
  ];

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
      tag == 'persona:pepe' ||
      tag == 'persona:abuela' ||
      tag == 'persona:senora';

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

  // an item's drawn box on the picture: [x0, y0, x1, y1] (inclusive)
  static List<int>? _box(dynamic it) {
    final b = _ink(it);
    if (b == null) return null;
    final l = it.left as int, t = it.top as int;
    return [l + b[0], t + b[1], l + b[2], t + b[3]];
  }

  static bool _overlap(List<int> a, List<int> b) =>
      a[0] <= b[2] && b[0] <= a[2] && a[1] <= b[3] && b[1] <= a[3];

  void _breach(String at, String rule, String what) =>
      breaches.add((at: at, rule: rule, what: what));

  /// Checks the frame of the scene's world now.
  void check(String at) {
    final W = scene.host.W;
    checked++;
    final items = (_m.placed(W, 0) as List).cast<dynamic>();
    final S = (_m.places.e.S as num).toDouble();
    final bias = (_m.places.bias as num).toDouble();
    final key = scene.setKey(W);
    final z = _zbOf(key);
    double planeK(dynamic it) => (it.d as double) + (it.sy as num) * _t30 / S;
    final gente = (W['gente'] as Map).cast<String, dynamic>();
    final cosas = (W['cosas'] as List).cast<Map>();
    String? spotOf(String tag) {
      if (tag.startsWith('persona:')) {
        return (gente[tag.substring(8)] as Map?)?['spot'] as String?;
      }
      if (tag.startsWith('cosa:')) {
        final id = tag.substring(5);
        for (final o in cosas) {
          if (o['id'] == id && o['vis'] != 0) {
            return o['con'] != null || o['sx'] != null
                ? null
                : o['spot'] as String?;
          }
        }
      }
      return null;
    }

    // the frog is never behind a grown-up
    final frog = items.where((i) => i.tag == 'coqui').toList();
    for (final f in frog) {
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
          _breach(
            at,
            'frog behind a grown-up',
            '${p.tag}: $n px over the frog',
          );
        }
      }
    }
    // inside the picture and the view (a thing in the air is on its way: not placed)
    final cam = scene.CAM['wide']!;
    for (final it in items) {
      final b = _box(it);
      if (b == null) continue;
      if (it.d == 99) continue;
      final sx = (b[0] + b[2]) ~/ 2;
      if (sx < cam[0] || sx >= cam[0] + cam[2] || it.sy > 216 || b[1] < 0) {
        _breach(
          at,
          'outside the view',
          '${it.tag} at column $sx, row ${it.sy}',
        );
      }
    }
    // the frog's box clears the small things on the ledge
    const ledge = {
      'monedas4',
      'monedas2',
      'canasta',
      'cajon_a',
      'cajon_b',
      'bolsa',
    };
    for (final f in frog) {
      final fb = _box(f);
      if (fb == null) continue;
      for (final it in items) {
        final tag = it.tag as String?;
        if (tag == null || !ledge.contains(spotOf(tag))) continue;
        final b = _box(it);
        if (b != null && _overlap(fb, b)) {
          _breach(
            at,
            'the frog over a thing on the ledge',
            '$tag at ${spotOf(tag)}',
          );
        }
      }
    }
    // the two crates apart
    final crates = [
      for (final it in items)
        if (it.tag == 'cosa:cajon_a' && spotOf('cosa:cajon_a') == 'cajon_a' ||
            it.tag == 'cosa:cajon_b' && spotOf('cosa:cajon_b') == 'cajon_b')
          it,
    ];
    if (crates.length == 2) {
      final a = _box(crates[0]), b = _box(crates[1]);
      if (a != null && b != null && _overlap(a, b)) {
        _breach(at, 'the crates overlap', '$a ~ $b');
      }
    }
    // the goat's muzzle on the low crate
    final cabra = W['cabra'] as Map?;
    if (cabra != null && cabra['pose'] == 'cajon') {
      final g = items.firstWhere((i) => i.tag == 'cabra');
      final c = (_m.places.at('cabra.cajon'));
      final cx = ((c.sx as double) + .5).floor(),
          cy = ((c.sy as double) + .5).floor();
      var on = false;
      for (var dy = -1; dy <= 0 && !on; dy++) {
        for (var dx = -1; dx <= 1 && !on; dx++) {
          final X = cx + dx - (g.left as int), Y = cy + dy - (g.top as int);
          final s = g.s as Sprite;
          if (X >= 0 &&
              Y >= 0 &&
              X < s.w &&
              Y < s.h &&
              s.px[Y * s.w + X] >>> 24 != 0) {
            on = true;
          }
        }
      }
      if (!on) {
        _breach(
          at,
          'the goat\'s muzzle off the low crate',
          'no goat pixel at $cx,$cy',
        );
      }
    }
    // abuela at abuela.delante covers no bin; with the cart there, 10 px clear of it
    final tags = (_m.partTagsOf(key) as List).cast<String?>();
    for (final it in items.where((i) => i.tag == 'persona:abuela')) {
      if (gente['abuela']?['spot'] != 'abuela.delante') continue;
      var over = 0;
      for (var y = 0; y < it.s.h; y++) {
        final Y = it.top + y;
        if (Y < 0 || Y >= 216) continue;
        for (var x = 0; x < it.s.w; x++) {
          if (it.s.px[y * it.s.w + x] >>> 24 == 0) continue;
          final X = it.left + x;
          if (X < 0 || X >= 240) continue;
          if (_bins.contains(tags[Y * 240 + X])) over++;
        }
      }
      if (over > 0) _breach(at, 'abuela over a bin', '$over px');
      var cx0 = 240, cy0 = 216, cx1 = -1, cy1 = -1;
      for (var i = 0; i < tags.length; i++) {
        if (tags[i] != 'carro') continue;
        final x = i % 240, y = i ~/ 240;
        cx0 = math.min(cx0, x);
        cx1 = math.max(cx1, x);
        cy0 = math.min(cy0, y);
        cy1 = math.max(cy1, y);
      }
      final ab = _box(it);
      if (cx1 >= 0 && ab != null) {
        final gx = math.max(0, math.max(cx0 - ab[2], ab[0] - cx1) - 1),
            gy = math.max(0, math.max(cy0 - ab[3], ab[1] - cy1) - 1);
        if (math.max(gx, gy) < 10) {
          _breach(at, 'abuela near the cart', '${math.max(gx, gy)} px apart');
        }
      }
    }
    // don Pepe behind the stand shows 24 rows or more (rules.person)
    for (final it in items.where((i) => i.tag == 'persona:pepe')) {
      if (gente['pepe']?['spot'] != 'pepe.detras') continue;
      var rows = 0;
      for (var y = 0; y < it.s.h; y++) {
        final Y = it.top + y;
        if (Y < 0 || Y >= 216) continue;
        final plane = it.d + (it.sy - (Y + .5)) * _t30 / S;
        for (var x = 0; x < it.s.w; x++) {
          if (it.s.px[y * it.s.w + x] >>> 24 == 0) continue;
          final X = it.left + x;
          if (X < 0 || X >= 240) continue;
          if (z[Y * 240 + X] > plane + bias) continue;
          rows++;
          break;
        }
      }
      if (rows < 24) {
        _breach(at, 'don Pepe hidden by the stand', '$rows rows show');
      }
    }
  }
}
