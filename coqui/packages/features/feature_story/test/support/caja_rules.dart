// La caja's rules (caja-sheet.json's rules and checks, and page 13's "The sheet's rules hold in the scene"), checked on
// the real scene's frame at every act's end and at the story's end: the scene's acts are wrapped so that each, once
// done, has the frame looked at (as El mostrador's, test/support/mostrador_rules.dart). The sprite layer is composed as
// the game composes it (the set's baked depth in place: Caja.layerOf). What is checked:
// - the frog is never behind a grown-up (don Pepe, the señora, the señor): where the frog's pixels and a grown-up's
//   overlap, the grown-up's pixel does not win (front.sprites: the nearer pixel wins);
// - nothing stands on the amount plate (importe-clear): no sprite pixel shows inside things.importe.box but the plate's;
// - a customer's thing has its price tag at `etiqueta`: each tag stands at its thing's world point plus the sheet's
//   spots.<spot>.etiqueta.dw;
// - the children outside show through the shop window's panes or the street doorway only
//   (ninos-fuera-through-window, nino-fuera-in-doorway): each shows at least 20 rows, and every pixel of theirs that
//   shows is over the street (the set's world x there, from its baked depth, left of -0.04: beyond the wall);
// - every person and thing drawn stands inside the picture, its middle inside the view's window (in-view);
// - nobody stands on a place another holds (people-apart: feet at least 12 px apart, by their world points; the three
//   children inside among themselves are the sheet's group and not checked, as the sheet's own check);
// - the frog's box covers no thing on the counter (frog-clear-of-counter);
// - a thing he must touch shows: at least 70% of the pixels of each of cosa_a, cosa_b, frasco, papel and bola (hidden
//   neither by the set nor by another sprite; what its own price tag covers counts as shown: the tag stands in front of it
//   by design), as Los estantes' rule.
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/coqui_scenes.dart';

/// What went against a rule: when, which rule, the details.
typedef CajaBreach = ({String at, String rule, String what});

/// Watches a real La caja while a story plays: [wrap] its acts, then read [breaches] and [checked].
class CajaRules {
  CajaRules(this.scene) : _m = scene;

  /// The scene (La caja's; its own members, `placed`, `places`, `layerOf`, are reached as the scene's, untyped: a
  /// feature may not import a package's src/).
  final SetScene scene;
  final dynamic _m;

  // the baked depth of each state, made once for every run of the process (the set is the same in every one)
  static final Map<String, Float32List> _zb = {};
  static SetBakes? _bakes;
  Float32List _zbOf(String key) => _zb[key] ??= Float32List.fromList(
    (_bakes ??= SetBakes(scene)).bakeKey(key).zb,
  );
  final List<CajaBreach> breaches = [];
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
      tag == 'persona:pepe' ||
      tag == 'persona:senora' ||
      tag == 'persona:senor';

  void _breach(String at, String rule, String what) =>
      breaches.add((at: at, rule: rule, what: what));

  /// Checks the frame of the scene's world now.
  void check(String at) {
    final W = scene.host.W;
    checked++;
    final items = (_m.placed(W, 0) as List).cast<dynamic>();
    final z = _zbOf(scene.setKey(W));
    final layer = _m.layerOf(W, z);
    final tags = layer.tags as List<String?>;
    final places = _m.places;
    final e = places.e as PpEngine;
    // the pixels each sprite shows, and how many it draws
    final shown = <String, int>{}, drawn = <String, int>{};
    for (final t in tags) {
      if (t != null) shown[t] = (shown[t] ?? 0) + 1;
    }
    // a thing's pixels its own price tag covers are hidden by design (the tag stands in front of it): they count as shown
    for (final it in items) {
      final t = it.tag as String;
      if (!t.startsWith('etiqueta:')) continue;
      final own = 'cosa:${t.substring(9)}';
      final thing = items.where((i) => i.tag == own).firstOrNull;
      if (thing == null) continue;
      final s = thing.s as Sprite;
      for (var y = 0; y < s.h; y++) {
        for (var x = 0; x < s.w; x++) {
          if (s.px[y * s.w + x] >>> 24 == 0) continue;
          final X = thing.left + x, Y = thing.top + y;
          if (X < 0 || X >= 240 || Y < 0 || Y >= 216) continue;
          if (tags[Y * 240 + X] == t) shown[own] = (shown[own] ?? 0) + 1;
        }
      }
    }
    for (final it in items) {
      final s = it.s as Sprite;
      var n = 0;
      for (var y = 0; y < s.h; y++) {
        for (var x = 0; x < s.w; x++) {
          if (s.px[y * s.w + x] >>> 24 == 0) continue;
          final X = it.left + x, Y = it.top + y;
          if (X < 0 || X >= 240 || Y < 0 || Y >= 216) continue;
          n++;
        }
      }
      drawn[it.tag as String] = n;
    }
    // the frog is never behind a grown-up: no pixel of the frog's sprite shows a grown-up there
    for (final f in items.where((i) => i.tag == 'coqui')) {
      final s = f.s as Sprite;
      final over = <String, int>{};
      for (var y = 0; y < s.h; y++) {
        for (var x = 0; x < s.w; x++) {
          if (s.px[y * s.w + x] >>> 24 == 0) continue;
          final X = f.left + x, Y = f.top + y;
          if (X < 0 || X >= 240 || Y < 0 || Y >= 216) continue;
          final t = tags[Y * 240 + X];
          if (t != null && _adult(t)) over[t] = (over[t] ?? 0) + 1;
        }
      }
      for (final o in over.entries) {
        _breach(at, 'frog behind a grown-up', '${o.key}: ${o.value} px');
      }
    }
    // nothing stands on the amount plate
    final pl = places.importe;
    final b = pl.box as List<int>;
    var onPlate = 0;
    final whoOn = <String>{};
    for (var y = b[1]; y < b[1] + b[3]; y++) {
      for (var x = b[0]; x < b[0] + b[2]; x++) {
        final t = tags[y * 240 + x];
        if (t != null && t != 'importe') {
          onPlate++;
          whoOn.add(t);
        }
      }
    }
    if (onPlate > 0) {
      _breach(at, 'something on the amount plate', '$whoOn: $onPlate px');
    }
    // the price tags at `etiqueta`
    final byTag = {for (final it in items) it.tag as String: it};
    for (final o in (W['cosas'] as List).cast<Map<String, dynamic>>()) {
      if (o['tag'] == null || o['vis'] == 0 || o['con'] != null) continue;
      final it = byTag['etiqueta:${o['id']}'];
      final dw = places.etiqueta(o['spot'] as String) as List<double>?;
      if (it == null || dw == null) {
        _breach(at, 'a price tag missing', '${o['id']} at ${o['spot']}');
        continue;
      }
      final w = it.world as List<double>;
      final want = [
        (o['x'] as num) + dw[0],
        (o['y'] as num) + dw[1],
        (o['z'] as num) + dw[2],
      ];
      for (var i = 0; i < 3; i++) {
        if ((w[i] - want[i]).abs() > 1e-9) {
          _breach(at, 'a price tag off etiqueta', '${o['id']}: $w, not $want');
          break;
        }
      }
    }
    // the children outside: through the window's panes or the doorway, over the street only
    final gente = (W['gente'] as Map).cast<String, dynamic>();
    for (final en in gente.entries) {
      final p = en.value as Map;
      final spot = p['spot'];
      if (p['vis'] == 0 || spot is! String || !spot.startsWith('ninos_fuera')) {
        continue;
      }
      final tag = 'persona:${en.key}';
      final rows = <int>{};
      var overWall = 0;
      for (var i = 0; i < tags.length; i++) {
        if (tags[i] != tag) continue;
        final X = i % 240, Y = i ~/ 240;
        rows.add(Y);
        if (_worldX(e, X + .5, Y + .5, z[i]) >= -.04) overWall++;
      }
      if (rows.length < 20) {
        _breach(
          at,
          'a child outside not seen',
          '$tag at $spot: ${rows.length} rows',
        );
      }
      if (overWall > 0) {
        _breach(
          at,
          'a child outside over the wall',
          '$tag at $spot: $overWall px',
        );
      }
    }
    // inside the picture and the view
    final cam = scene.CAM['wide']!;
    for (final it in items) {
      final s = it.s as Sprite;
      var x0 = s.w, x1 = -1, y0 = s.h;
      for (var y = 0; y < s.h; y++) {
        for (var x = 0; x < s.w; x++) {
          if (s.px[y * s.w + x] >>> 24 == 0) continue;
          x0 = math.min(x0, x);
          x1 = math.max(x1, x);
          y0 = math.min(y0, y);
        }
      }
      if (x1 < 0) continue;
      final sx = it.left + (x0 + x1) ~/ 2;
      if (sx < cam[0] ||
          sx >= cam[0] + cam[2] ||
          it.sy > 216 ||
          it.top + y0 < 0) {
        _breach(
          at,
          'outside the view',
          '${it.tag} at column $sx, row ${it.sy}',
        );
      }
    }
    // people apart: feet at least 12 px apart (the three children inside among themselves are not checked)
    final feet = <String, ({double sx, double sy})>{};
    for (final en in gente.entries) {
      final p = en.value as Map;
      if (p['vis'] == 0) continue;
      if ((p['x'] as num) < 0) continue; // outside the wall
      final a = places.atWorld(p['x'], p['y'], p['z']);
      feet[en.key] = (sx: a.sx as double, sy: a.sy as double);
    }
    final q = W['cq'] as Map;
    if (jsTruthy(q['vis'])) {
      final fb = scene.host.frogBox(q.cast<String, dynamic>());
      feet['coqui'] = (
        sx: (fb.x + fb.w / 2).toDouble(),
        sy: ((q['y'] as num) + 25).toDouble(),
      );
    }
    final ks = feet.keys.toList();
    for (var i = 0; i < ks.length; i++) {
      for (var j = i + 1; j < ks.length; j++) {
        if (ks[i].startsWith('nino') && ks[j].startsWith('nino')) continue;
        final a = feet[ks[i]]!, c = feet[ks[j]]!;
        final d = math.sqrt(
          (a.sx - c.sx) * (a.sx - c.sx) + (a.sy - c.sy) * (a.sy - c.sy),
        );
        if (d < 12 - 1e-6) {
          _breach(
            at,
            'two people on one place',
            '${ks[i]} ~ ${ks[j]}: ${d.toStringAsFixed(1)} px',
          );
        }
      }
    }
    // the frog's box covers no thing on the counter
    if (jsTruthy(q['vis'])) {
      final fb = scene.host.frogBox(q.cast<String, dynamic>());
      for (final it in items) {
        final t = it.tag as String;
        if (!(t.startsWith('cosa:') || t.startsWith('etiqueta:'))) continue;
        final id = t.substring(t.indexOf(':') + 1);
        final o = (W['cosas'] as List)
            .cast<Map<String, dynamic>>()
            .where((c) => c['id'] == id)
            .firstOrNull;
        if (o == null || o['con'] != null || (o['z'] as num) < 1) continue;
        final s = it.s as Sprite;
        var n = 0;
        for (var y = 0; y < s.h; y++) {
          for (var x = 0; x < s.w; x++) {
            if (s.px[y * s.w + x] >>> 24 == 0) continue;
            final X = it.left + x, Y = it.top + y;
            if (X >= fb.x && X < fb.x + fb.w && Y >= fb.y && Y < fb.y + fb.h) {
              n++;
            }
          }
        }
        if (n > 0) {
          _breach(at, 'the frog over a thing on the counter', '$t: $n px');
        }
      }
    }
    // a thing he must touch shows (70%)
    for (final k in const ['cosa_a', 'cosa_b', 'frasco', 'papel', 'bola']) {
      final t = 'cosa:$k';
      final n = drawn[t];
      if (n == null || n == 0) continue;
      final o = (W['cosas'] as List)
          .cast<Map<String, dynamic>>()
          .where((c) => c['id'] == k)
          .firstOrNull;
      if (o == null || o['con'] != null) continue;
      final s = shown[t] ?? 0;
      if (s < .7 * n) {
        _breach(at, 'a thing he must touch hidden', '$k: $s of $n px show');
      }
    }
  }

  // the world x of the set's pixel at screen point (sx, sy) with depth [d] (pp-engine.js project inverted: the
  // projection is a rotation of (x - y, x + y, z) and the depth)
  static double _worldX(PpEngine e, double sx, double sy, double d) {
    final u = (sx - e.OX) / e.S, a = (sy - e.OY) / e.S;
    final v = .5 * a + e.COS * d;
    return (u + v) * e.R2 / 2;
  }
}
