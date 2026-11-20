// TEST-ONLY. balcon-preview.html's `remapW` and `baseW`, ported: how the preview moves a W written in OLD positions (a
// recorded run's W) to the new ones, so that a moment of a recorded run can be drawn by the Dart scene exactly as the
// preview draws it. The frog goes to the nearest frog spot and abuela to the nearest of her spots (within 60, by the
// same offset); a glass or jug on the table goes to the new place of its old one (X2, the middle, the pairs' 106; any
// other x keeps its offset from the table's middle; one on the small chair goes to its seat); the bird on the window's
// flower box or the small chair goes to its point there, on the table beside a glass as acts.aveva puts it, or else to
// the pairs' point of its old x (order 30b). It is the
// preview's rule, a dev tool's, not the scene's: the Dart scene's acts place things from the sheet themselves.
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

/// balcon-preview.html: `baseW` (juego.js fresh's fields, the scene's fresh, the OLD scene's fresh `ab` and `cq`, then
/// [over]).
Map<String, dynamic> balconPreviewBaseW(
  Map<String, dynamic> fresh,
  Map<String, dynamic> over,
) => {
  'spot': null,
  'twinkle': null,
  'glow': null,
  'fx': <Map<String, dynamic>>[],
  'heart': 0,
  'lost': 0,
  'resp': null,
  ...fresh,
  // balcon-preview.html: OLD_FRESH (the old fresh(): abuela in the old doorway, the frog on the old path)
  'ab': <String, dynamic>{
    'en': 'puerta',
    'x': 178,
    'y': 125,
    'pose': 'idle',
    'bub': null,
    'al': 1,
    'trae': 0,
  },
  'cq': <String, dynamic>{
    'x': 104,
    'y': 185,
    's': 1,
    'dy': 0,
    'al': 1,
    'vis': 1,
    'bub': null,
  },
  ..._copy(over) as Map<String, dynamic>,
};

/// balcon-preview.html: `remapW`.
Map<String, dynamic> balconPreviewRemapW(Map<String, dynamic> w0, Sheet sheet) {
  final w = _copy(w0) as Map<String, dynamic>;
  final spots = (sheet.raw['spots'] as Map<String, dynamic>).values
      .cast<Map<String, dynamic>>();
  List<num> nums(Object? l) => (l as List).cast<num>();
  final frogs = <_Move>[
    for (final s in spots)
      if (s['frog'] != null) (old: nums(s['old']), now: nums(s['frog'])),
  ];
  final abs = <_Move>[
    for (final s in spots)
      if (s['ab'] != null) (old: nums(s['old']), now: nums(s['ab'])),
  ];
  List<int> ptR(String n) => [
    for (final v in nums(sheet.raw['points'][n]['screen'])) (v + .5).floor(),
  ];
  final tc = ptR('mesa.centro')[0], mesaY = sheet.numberOf('MESA_Y');
  Map<String, dynamic>? moveBy(List<_Move> list, Map<String, dynamic>? q) {
    if (q == null || q['x'] == null) return q;
    final e = _near(list, q['x'] as num, q['y'] as num, 60);
    if (e == null) return q;
    return {
      ...q,
      'x': (q['x'] as num) + e.now[0] - e.old[0],
      'y': (q['y'] as num) + e.now[1] - e.old[1],
    };
  }

  // balcon-preview.html: TABLE_X, tableX
  const tableXs = {
    106: 'mesa.toma',
    108: 'mesa.izq',
    120: 'mesa.centro',
    132: 'mesa.der',
  };
  num tableX(num x) {
    final n = tableXs[x];
    return n != null ? ptR(n)[0] : x - 120 + tc;
  }

  Map<String, dynamic> moveGlass(Map<String, dynamic> v) {
    final x = v['x'] as num;
    // on the small chair
    if (v['y'] != null && (x - 160).abs() < 2) {
      final a = ptR('ASIENTO');
      return {...v, 'x': a[0], 'y': a[1] - 1};
    }
    // on the table
    return {...v, 'x': tableX(x)};
  }

  // balcon-preview.html: BIRD_X
  const birdXs = {127: 'ave.mesa.toma', 132: 'ave.mesa.der'};
  Map<String, dynamic>? moveBird(Map<String, dynamic>? a) {
    if (a == null ||
        a['x'] == null ||
        a['mode'] == 'head' ||
        a['mode'] == 'none') {
      return a;
    }
    final o = {...a}, x = a['x'] as num, y = a['y'] as num;
    if ((x - 120).abs() < 2 && (y - 86).abs() < 2) {
      final p = ptR('PERCH');
      o['x'] = p[0];
      o['y'] = p[1];
    } else if ((x - 160).abs() < 2 && (y - 135).abs() < 2) {
      final p = ptR('ASIENTO');
      o['x'] = p[0];
      o['y'] = p[1];
    } else if ((y - 128).abs() < 2) {
      // beside a glass as acts.aveva puts it (19 px on the middle's side of it), or the pairs' point of its old x
      Map<String, dynamic>? beside;
      for (final k in const ['vasos', 'jarras']) {
        for (final v
            in ((w0[k] as List?) ?? const []).cast<Map<String, dynamic>>()) {
          final vx = v['x'] as num;
          if (beside == null &&
              v['y'] == null &&
              x == vx + (vx < 120 ? 19 : -19)) {
            beside = v;
          }
        }
      }
      if (beside != null) {
        final nx = tableX(beside['x'] as num);
        o['x'] = nx + (nx < tc ? 19 : -19);
      } else {
        final n = birdXs[x];
        o['x'] = n != null ? ptR(n)[0] : x - 120 + tc;
      }
      o['y'] = mesaY;
    }
    return o;
  }

  w['cq'] = moveBy(frogs, w['cq'] as Map<String, dynamic>?);
  if (w['ab'] != null) w['ab'] = moveBy(abs, w['ab'] as Map<String, dynamic>);
  for (final k in const ['vasos', 'jarras']) {
    if (w[k] != null) {
      w[k] = [
        for (final v in (w[k] as List).cast<Map<String, dynamic>>())
          moveGlass(v),
      ];
    }
  }
  w['ave'] = moveBird(w['ave'] as Map<String, dynamic>?);
  return w;
}
