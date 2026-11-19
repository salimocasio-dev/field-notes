// TEST-ONLY. frente-preview.html's `remapW` and `baseW`, ported: how the preview moves a W written in OLD positions (a
// recorded run's W) to the new ones, so that a moment of a recorded run can be drawn by the Dart scene exactly as the
// preview draws it. The frog goes to the nearest spot (within 60), the bird, a slice and the flying leaves to the
// nearest bird point (within 40) unless they are in the sky. It is the preview's rule, a dev tool's, not the scene's:
// the Dart scene's acts place things from the sheet themselves.
import 'dart:math' as math;

import 'package:coqui_pixel/coqui_pixel.dart';

Object? _copy(Object? v) => v is Map
    ? {for (final e in v.entries) e.key as String: _copy(e.value)}
    : v is List
    ? [for (final e in v) _copy(e)]
    : v;

typedef _Move = ({List<num> old, List<num> now});

_Move? _near(List<_Move> list, num x, num y, num lim) {
  _Move? best;
  var bd = lim;
  for (final e in list) {
    final dx = e.old[0] - x,
        dy = e.old[1] - y,
        d = math.sqrt(dx * dx + dy * dy);
    if (d < bd) {
      bd = d;
      best = e;
    }
  }
  return best;
}

/// frente-preview.html: `baseW` (juego.js fresh's fields, the scene's fresh, then [over]).
Map<String, dynamic> previewBaseW(
  Map<String, dynamic> fresh,
  Map<String, dynamic> over,
) => {
  'cq': {'x': 150, 'y': 178, 's': 1, 'dy': 0, 'al': 1, 'vis': 1, 'bub': null},
  'spot': null,
  'twinkle': null,
  'glow': null,
  'fx': <Map<String, dynamic>>[],
  'heart': 0,
  'lost': 0,
  'resp': null,
  ...fresh,
  ..._copy(over) as Map<String, dynamic>,
};

/// frente-preview.html: `remapW`.
Map<String, dynamic> previewRemapW(Map<String, dynamic> w0, Sheet sheet) {
  final w = _copy(w0) as Map<String, dynamic>;
  final frogs = <_Move>[
    for (final s in (sheet.raw['spots'] as Map<String, dynamic>).values)
      if ((s as Map<String, dynamic>)['frog'] != null)
        (
          old: (s['old'] as List).cast<num>(),
          now: (s['frog'] as List).cast<num>(),
        ),
  ];
  final birds = <_Move>[
    for (final e in (sheet.raw['points'] as Map<String, dynamic>).entries)
      if (e.key.startsWith('ave.') || e.key == 'corazon')
        (
          old: ((e.value as Map<String, dynamic>)['old'] as List).cast<num>(),
          now: [
            for (final v in (e.value['screen'] as List).cast<num>())
              (v + .5).floor(),
          ],
        ),
  ];
  Map<String, dynamic>? moveFrog(Map<String, dynamic>? q) {
    if (q == null) return q;
    final e = _near(frogs, q['x'] as num, q['y'] as num, 60);
    if (e == null) return q;
    return {
      ...q,
      'x': (q['x'] as num) + e.now[0] - e.old[0],
      'y': (q['y'] as num) + e.now[1] - e.old[1],
    };
  }

  Map<String, dynamic>? movePoint(Map<String, dynamic>? o) {
    if (o == null || o['x'] == null) return o;
    final x = o['x'] as num, y = o['y'] as num;
    if (y < 45 || x < -5 || x > 245)
      return o; // the sky and off the picture: unchanged
    final e = _near(birds, x, y, 40);
    if (e == null) return o;
    return {...o, 'x': x + e.now[0] - e.old[0], 'y': y + e.now[1] - e.old[1]};
  }

  w['cq'] = moveFrog(w['cq'] as Map<String, dynamic>?);
  final ave = w['ave'] as Map<String, dynamic>?;
  if (ave != null && (ave['mode'] == 'sit' || ave['mode'] == 'fly')) {
    w['ave'] = movePoint(ave);
  }
  if (w['trozo'] != null)
    w['trozo'] = movePoint(w['trozo'] as Map<String, dynamic>);
  if (w['hojas'] != null)
    w['hojas'] = movePoint(w['hojas'] as Map<String, dynamic>);
  return w;
}
