// TEST-ONLY. patio-preview.html's `remapW` and `baseW`, ported: how the preview moves a W written in OLD positions (a
// recorded run's W) to the new ones, so that a moment of a recorded run can be drawn by the Dart scene exactly as the
// preview draws it. The yard is built round the old picture (the sheet's rules.floor), so nothing moves but the places the
// sheet moves: a person at a moved place of an act the story uses (`moves`) goes to its new one (and takes its sort row,
// the baby in mamá's arms), else one at a story position the sheet moved for that story (`remap` entries that moved);
// the frog at one of his places that moved (LUGAR.porton, LUGAR.sale: `moves` places of `cq`); W.soly 24 is 26; after
// inicio11 the answer cards stand where `respEn` says. It is the preview's rule, a dev tool's, not the scene's: the Dart
// scene's acts place people from the sheet themselves.
import 'package:coqui_pixel/coqui_pixel.dart';

Object? _copy(Object? v) => v is Map
    ? {for (final e in v.entries) e.key as String: _copy(e.value)}
    : v is List
    ? [for (final e in v) _copy(e)]
    : v;

int _round(num v) => (v + .5).floor();

/// patio-preview.html: `baseW` (juego.js fresh's fields, the scene's fresh, then [over]).
Map<String, dynamic> patioPreviewBaseW(
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

/// patio-preview.html: `remapW` for the story [story] (its id) whose file names the acts [acts] (`PREVIEW.story`; null:
/// every move and every moved position, as `PREVIEW.story` null).
Map<String, dynamic> patioPreviewRemapW(
  Map<String, dynamic> w0,
  Sheet sheet, {
  String? story,
  List<String>? acts,
}) {
  final w = _copy(w0) as Map<String, dynamic>;
  final mv = [
    for (final m in sheet.moves)
      if (acts == null || acts.contains(m.act) || m.act == '*') ...m.places,
  ];
  final rm = [
    for (final e in sheet.remapTable)
      if (e.moved &&
          (story == null || e.uses.any((u) => u.startsWith('$story.json'))))
        e,
  ];
  bool at(List<num> old, Map<String, dynamic> p) =>
      old[0] == _round(p['x'] as num) && old[1] == _round(p['y'] as num);
  final gente = (w['gente'] as Map<String, dynamic>?) ?? const {};
  for (final en in gente.entries) {
    final p = en.value as Map<String, dynamic>?;
    if (p == null || p['x'] == null) continue;
    final m = mv
        .where((q) => (q.who == 'whoever' || q.who == en.key) && at(q.old, p))
        .firstOrNull;
    if (m != null) {
      p['x'] = m.now[0];
      p['y'] = m.now[1];
      if (m.z != null) p['z'] = m.z;
      continue;
    }
    final r = rm.where((e) => at(e.old, p)).firstOrNull;
    if (r != null) {
      p['x'] = r.now![0];
      p['y'] = r.now![1];
    }
  }
  // round 4: the frog at one of his places that moved (moves, places who "cq": LUGAR.porton and LUGAR.sale)
  final q = w['cq'] as Map<String, dynamic>?;
  if (q != null) {
    final m = mv.where((p) => p.who == 'cq' && at(p.old, q)).firstOrNull;
    if (m != null) {
      q['x'] = m.now[0];
      q['y'] = m.now[1];
    }
  }
  if (w['soly'] == 24) w['soly'] = 26;
  final en = sheet.moves
      .where((m) => m.respEn != null && (acts == null || acts.contains(m.act)))
      .firstOrNull;
  final g = w['gente'] as Map<String, dynamic>?;
  if (en != null && g != null && g['abuela'] != null && g['mama'] != null) {
    w['respEn'] = en.respEn;
  }
  return w;
}
