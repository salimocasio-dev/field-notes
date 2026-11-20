// TEST-ONLY. sala-preview.html's `remapW` and `baseW`, ported: how the preview moves a W written in OLD positions (a
// recorded run's W) to the new ones, so that a moment of a recorded run can be drawn by the Dart scene exactly as the
// preview draws it. The room is built round the old picture (the sheet's rules.floor), so nothing moves but the places the
// sheet moves (`moves`): a person at a moved place of an act the story uses goes to its new one, and the frog hopped beside
// them (acts.junto) goes with them. It is the preview's rule, a dev tool's, not the scene's: the Dart scene's acts place
// people from the sheet themselves.
import 'package:coqui_pixel/coqui_pixel.dart';

Object? _copy(Object? v) => v is Map
    ? {for (final e in v.entries) e.key as String: _copy(e.value)}
    : v is List
    ? [for (final e in v) _copy(e)]
    : v;

int _round(num v) => (v + .5).floor();

/// sala-preview.html: `baseW` (juego.js fresh's fields, the scene's fresh, then [over]).
Map<String, dynamic> salaPreviewBaseW(
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

/// sala-preview.html: `remapW`, the moves of the acts in [acts] (null: every act's, as `PREVIEW.acts` null).
Map<String, dynamic> salaPreviewRemapW(
  Map<String, dynamic> w0,
  Sheet sheet, {
  List<String>? acts,
}) {
  final w = _copy(w0) as Map<String, dynamic>;
  final mv = [
    for (final m in sheet.moves)
      if (acts == null || acts.contains(m.act)) ...m.places,
  ];
  final moved = <(List<num>, List<num>)>[];
  final gente = (w['gente'] as Map<String, dynamic>?) ?? const {};
  for (final en in gente.entries) {
    final p = en.value as Map<String, dynamic>?;
    if (p == null || p['x'] == null) continue;
    for (final m in mv) {
      if ((m.who == 'whoever' || m.who == en.key) &&
          m.old[0] == _round(p['x'] as num) &&
          m.old[1] == _round(p['y'] as num)) {
        moved.add((m.old, m.now));
        p['x'] = m.now[0];
        p['y'] = m.now[1];
        break;
      }
    }
  }
  final q = w['cq'] as Map<String, dynamic>?;
  if (q != null) {
    int jx(List<num> p) => _round(p[0] + (p[0] < 120 ? -24 : 24) - 16);
    int jy(List<num> p) => _round(p[1] + 5 - 27);
    for (final (o, n) in moved) {
      if (q['x'] == jx(o) && q['y'] == jy(o)) {
        q['x'] = jx(n);
        q['y'] = jy(n);
      }
    }
  }
  return w;
}
