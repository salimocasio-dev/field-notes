// Los estantes' rules (estantes-sheet.json's rules and checks, and page 13's "The sheet's rules hold in the scene"),
// checked on the real scene's frame at every act's end and at the story's end: the scene's acts are wrapped so that
// each, once done, has the frame looked at (as El mostrador's, test/support/mostrador_rules.dart). What is checked (the
// amount plate and the price tag at `etiqueta` are La caja's and Las frutas' sheets', not this one's):
// - the frog is never behind a grown-up (don Pepe, the señora, the señor): where the frog's pixels and a grown-up's
//   overlap, the grown-up is not nearer (front.sprites: the nearer pixel wins);
// - every person and thing drawn stands inside the picture, its middle inside the view's window (spots-in-view);
// - nobody stands on a place another holds (people-apart: two people's, the frog's or Canelo's feet at least 12 px
//   apart);
// - Canelo sitting beside the frog is clear of him (perro-clear-of-frog: their drawn boxes do not overlap);
// - don Pepe off the floor is on the ladder at its rung (pepe.escalera; pepe-on-rung), and nowhere else; the frog off the
//   floor is on his crate (coqui.cajon);
// - a thing standing on a shelf or on the table stands at one of the sheet's places (shelf-places, mesa-fila-on-cloth);
// - don Pepe on the ladder is not hidden by the ladder (front.after): every pixel of him the set's depth would hide is a
//   ladder pixel.
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/coqui_scenes.dart';

/// What went against a rule: when, which rule, the details.
typedef EstantesBreach = ({String at, String rule, String what});

final double _t30 = math.tan(math.pi / 6);

/// Watches a real Los estantes while a story plays: [wrap] its acts, then read [breaches] and [checked].
class EstantesRules {
  EstantesRules(this.scene) : _m = scene;

  /// The scene (Los estantes'; its own members, `placed`, `places`, `ladderAt`, are reached as the scene's, untyped: a
  /// feature may not import a package's src/).
  final SetScene scene;
  final dynamic _m;

  // the baked depth of each state, made once for every run of the process (the set is the same in every one)
  static final Map<String, Float32List> _zb = {};
  static SetBakes? _bakes;
  Float32List _zbOf(String key) => _zb[key] ??= Float32List.fromList(
    (_bakes ??= SetBakes(scene)).bakeKey(key).zb,
  );
  final List<EstantesBreach> breaches = [];
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

  static const List<String> _adults = [
    'persona:pepe',
    'persona:senora',
    'persona:senor',
  ];

  List<int>? _ink(dynamic it) {
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

  void _breach(String at, String rule, String what) =>
      breaches.add((at: at, rule: rule, what: what));

  /// Checks the frame of the scene's world now.
  void check(String at) {
    final W = scene.host.W;
    checked++;
    final items = (_m.placed(W, 0) as List).cast<dynamic>();
    final S = (_m.places.e.S as num).toDouble();
    double planeK(dynamic it) => (it.d as double) + (it.sy as num) * _t30 / S;
    // the frog is never behind a grown-up
    for (final f in items.where((i) => i.tag == 'coqui')) {
      for (final p in items.where((i) => _adults.contains(i.tag))) {
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
    // inside the picture and the view
    final cam = scene.CAM['wide']!;
    for (final it in items) {
      final b = _ink(it);
      if (b == null) continue;
      final sx = it.left + (b[0] + b[2]) ~/ 2;
      if (sx < cam[0] ||
          sx >= cam[0] + cam[2] ||
          it.sy > 216 ||
          it.top + b[1] < 0) {
        _breach(
          at,
          'outside the view',
          '${it.tag} at column $sx, row ${it.sy}',
        );
      }
    }
    // people apart (feet at least 12 px apart: the sheet's people-apart)
    final people = [
      for (final it in items)
        if (it.tag != null &&
            ((it.tag as String).startsWith('persona:') || it.tag == 'coqui'))
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
        if (d < 12) {
          _breach(
            at,
            'two people on one place',
            '${a.tag} ~ ${b.tag}: ${d.toStringAsFixed(1)} px',
          );
        }
      }
    }
    // Canelo sitting beside the frog is clear of him
    final gente = W['gente'] as Map;
    final perro = gente['perro'] as Map?;
    if (perro != null && perro['vis'] != 0 && perro['spot'] == 'perro.rana') {
      final d = items.where((i) => i.tag == 'persona:perro').firstOrNull;
      final f = items.where((i) => i.tag == 'coqui').firstOrNull;
      if (d != null && f != null) {
        final bd = _ink(d)!, bf = _ink(f)!;
        final dx0 = d.left + bd[0], dx1 = d.left + bd[2];
        final dy0 = d.top + bd[1], dy1 = d.top + bd[3];
        final fx0 = f.left + bf[0], fx1 = f.left + bf[2];
        final fy0 = f.top + bf[1], fy1 = f.top + bf[3];
        if (dx0 <= fx1 && fx0 <= dx1 && dy0 <= fy1 && fy0 <= dy1) {
          _breach(at, 'Canelo on the frog', 'boxes overlap');
        }
      }
    }
    // off the floor: don Pepe on the ladder's rung, the frog on his crate
    final pepe = gente['pepe'] as Map?;
    if (pepe != null && pepe['vis'] != 0 && (pepe['z'] as num) > 0) {
      if (pepe['spot'] != 'pepe.escalera') {
        _breach(
          at,
          'don Pepe off the floor, not on his rung',
          '${pepe['spot']}',
        );
      } else {
        final w = (_m.places.world('pepe.escalera') as List).cast<num>();
        if (pepe['x'] != w[0] || pepe['y'] != w[1] || pepe['z'] != w[2]) {
          _breach(
            at,
            'don Pepe off his rung',
            '${pepe['x']},${pepe['y']},${pepe['z']}',
          );
        }
      }
    }
    final q = W['cq'] as Map;
    if (jsTruthy(q['vis']) && (q['z'] as num? ?? 0) > 0) {
      final L = scene.lugar['cajon']!;
      if (q['x'] != L[0] || q['y'] != L[1]) {
        _breach(
          at,
          'the frog off the floor, not on his crate',
          'at ${q['x']},${q['y']}',
        );
      }
    }
    // a thing on a shelf or on the table stands at one of the sheet's places
    for (final o in (W['cosas'] as List).cast<Map>()) {
      final spot = o['spot'];
      if (o['vis'] == 0 || o['con'] != null || o['vuela'] != null) continue;
      if (spot is! String ||
          !(spot.startsWith('estante.') || spot.startsWith('mesa.fila.'))) {
        continue;
      }
      final w = (_m.places.world(spot) as List).cast<num>();
      if (o['x'] != w[0] || o['y'] != w[1] || o['z'] != w[2]) {
        _breach(at, 'a thing off its place', '${o['id']} at $spot');
      }
    }
    // don Pepe on the ladder: the ladder does not hide him (front.after), everything else of the set still may
    final key = scene.setKey(W);
    final z = _zbOf(key);
    final bias = (_m.places.bias as num).toDouble();
    for (final it in items.where((i) => i.tag == 'persona:pepe')) {
      if (it.ladder as bool) continue;
      var hidden = 0;
      for (var y = 0; y < it.s.h; y++) {
        final Y = it.top + y, plane = it.d + (it.sy - (Y + .5)) * _t30 / S;
        for (var x = 0; x < it.s.w; x++) {
          if (it.s.px[y * it.s.w + x] >>> 24 == 0) continue;
          final X = it.left + x;
          if (X < 0 || X >= 240 || Y < 0 || Y >= 216) continue;
          final i = Y * 240 + X;
          if (z[i] > plane + bias && !(_m.ladderAt(W, i) as bool)) hidden++;
        }
      }
      if (hidden > 0) {
        _breach(at, 'don Pepe on the ladder hidden by the set', '$hidden px');
      }
    }
  }
}
