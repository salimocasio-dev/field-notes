// TEST-ONLY. nevera-preview.html's `remapW` and `baseW`: how the preview moves a W written in OLD positions (a recorded
// run's W) to the new ones, so that a moment of a recorded run can be drawn by the Dart scene exactly as the preview draws
// it. The kitchen is built round the old picture (the sheet's rules.floor), so nothing moves but what the sheet moves: a
// thing of `cosas` at a position the sheet moved for that story (`remap` entries that moved); whoever stands outside the
// window to PA at their x, by the preview's own table of their offsets (SHEET_HXS: "the maker's HXS"); the cards and cups
// the sheet's moves name; abuela at a moved place of hers; the clear glasses on the fridge's top; a thing lying before the
// counter (CB), on the sill (SL) or on the counter (CT) at its x; the smell over the tray; the frog on the counter; the
// answer cards.
import 'package:coqui_pixel/coqui_pixel.dart';

Object? _copy(Object? v) => v is Map
    ? {for (final e in v.entries) e.key as String: _copy(e.value)}
    : v is List
    ? [for (final e in v) _copy(e)]
    : v;

int _round(num v) => (v + 0.5).floor();

/// nevera-preview.html: `baseW` (juego.js fresh's fields, the scene's fresh, then [over]).
Map<String, dynamic> neveraPreviewBaseW(
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
  ..._copy(over) as Map<String, dynamic>,
};

// nevera-preview.html: SHEET_HXS. Whoever stands outside (the maker's HXS): [old x, new x, rows on PA + the old offset,
// the old offset it holds for]; null: any x, the same x
const Map<String, List<List<int?>>> _hxs = {
  'abuelo': [
    [207, 207, -9, null],
    [null, null, -1, null],
  ],
  'papa': [
    [158, 154, 0, null],
    [null, null, 0, null],
  ],
  'luis': [
    [173, 166, 0, null],
    [158, 158, -6, 8],
  ],
  'mama': [
    [200, 200, -4, null],
  ],
};

/// nevera-preview.html: `PV.remapW` for the story [story] (its id: `PREVIEW.story.id`; null: none).
Map<String, dynamic> neveraPreviewRemapW(
  Map<String, dynamic> w0,
  Sheet sheet, {
  String? story,
}) {
  final w = _copy(w0) as Map<String, dynamic>;
  final N = (sheet.raw['layout'] as Map)['numbers'] as Map;
  int Function(num) f(String k) =>
      (x) => _round((N[k] as num) + x / 2);
  final CT = f('CT'), SL = f('SL'), PA = f('PA'), CB = f('CB');
  const ENC = 112;
  final top = (sheet.raw['points'] as Map)['nevera']['top'] as Map;
  final done = <Object>{};
  final cosas = (w['cosas'] as List?) ?? const [];
  if (story != null) {
    for (final e in sheet.remapTable) {
      if (!(e.moved &&
          e.kind == 'point' &&
          e.uses.any((u) => u.startsWith('$story.json')))) {
        continue;
      }
      for (final o in cosas) {
        if (o is! Map || done.contains(o)) continue;
        if (_round(o['x'] as num) == e.old[0] &&
            _round(o['y'] as num) == e.old[1]) {
          o['x'] = e.now![0];
          o['y'] = e.now![1];
          done.add(o);
        }
      }
    }
  }
  final gente = (w['gente'] as Map?) ?? const {};
  final gente0 = (w0['gente'] as Map?) ?? const {};
  for (final en in gente.entries) {
    final id = en.key as String, p = en.value;
    if (p is! Map || p['x'] == null || !jsTruthy(p['fuera'])) continue;
    p['y'] = PA(_round(p['x'] as num)) + ((p['y'] as num) - 120) + 0;
    final y0 = (gente0[id] as Map)['y'] as num;
    List<int?>? hx;
    for (final h in _hxs[id] ?? const <List<int?>>[]) {
      if ((h[0] == null || _round(p['x'] as num) == h[0]) &&
          (h[3] == null || _round(y0) - 120 == h[3])) {
        hx = h;
        break;
      }
    }
    if (hx != null) {
      if (hx[1] != null) p['x'] = hx[1];
      p['y'] = PA(_round(p['x'] as num)) + (y0 - 120) + hx[2]!;
    }
  }
  final named = <String, List<num>>{};
  for (final m in sheet.moves) {
    for (final q in m.places) {
      if (RegExp(r'^(carta_|v_)').hasMatch(q.who)) {
        named['${q.who}@${q.old.join(',')}'] = q.now;
      }
    }
  }
  for (final m in sheet.moves) {
    for (final q in m.places) {
      if (q.who != 'abuela') continue;
      final p = gente['abuela'];
      if (p is Map &&
          _round(p['x'] as num) == q.old[0] &&
          _round(p['y'] as num) == q.old[1]) {
        p['x'] = q.now[0];
        p['y'] = q.now[1];
      }
    }
  }
  for (final o in cosas) {
    if (o is! Map || o['x'] == null || done.contains(o)) continue;
    final x = _round(o['x'] as num),
        nm = named['${o['id']}@$x,${_round(o['y'] as num)}'];
    if (nm != null) {
      o['x'] = nm[0];
      o['y'] = nm[1];
      continue;
    }
    if (o['id'] == 'c1' && o['y'] == 40) {
      o['x'] = (top['c1'] as List)[0];
      o['y'] = (top['c1'] as List)[1];
      continue;
    }
    if (o['id'] == 'c2' && o['y'] == 40) {
      o['x'] = (top['c2'] as List)[0];
      o['y'] = (top['c2'] as List)[1];
      continue;
    }
    final z = o['z'], y = o['y'] as num;
    if (z == 50 || z == 399 || z == 400) continue;
    if (z == 1 && y == 166) {
      o['y'] = CB(x);
      continue;
    }
    if (y >= 94 && y <= 102 && (z == 90 || z == 100)) {
      o['y'] = SL(x) + (y - 98);
      continue;
    }
    if (y >= ENC + 2 && y <= ENC + 20 && z is num && z >= 90 && z <= 500) {
      o['y'] = CT(x) + (y - (ENC + 10));
      continue;
    }
  }
  final olf = w['olfato'];
  if (olf is Map && olf['y'] == ENC + 13) {
    olf['y'] = CT(_round(olf['x'] as num)) + 3;
  }
  final cq = w['cq'];
  if (cq is Map && jsTruthy(cq['vis']) && cq['y'] == ENC + 9 - 27) {
    cq['y'] = CT((cq['x'] as num) + 16) - 1 - 27;
  }
  final r = w['respEn'];
  if (r is List && r[0] == 142 && r[1] == 10) {
    w['respEn'] = [
      ...sheet.moves
          .firstWhere((m) => m.src.startsWith('fresh:()=>({respEn:'))
          .places[0]
          .now,
    ];
  }
  return w;
}
