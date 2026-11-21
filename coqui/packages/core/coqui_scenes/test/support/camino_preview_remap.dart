// TEST-ONLY. camino-preview.html's `remapW` and `baseW`, ported: how the preview moves a W written in OLD positions (a
// recorded run's W) to the new ones, so that a moment of a recorded run can be drawn by the Dart scene exactly as the
// preview draws it. The park is built round the old picture (the sheet's rules.floor), so nothing moves but the places
// the sheet moves: a person, Canelo or the cat at a moved place of an act the story uses (`moves`: Canelo's x capped at
// marks 7 and 8, the cat on the bench) goes to its new one, else one at a story position the sheet moved for that story
// (`remap` entries that moved: the cat on the bench, Canelo at the first tree); the frog at his moved place at the first
// tree (`moves` places of `cq`); a story's own W.respEn through the remap (h-camino beats.5); once a story's start act
// has run, the answer cards stand where its `respEn` says. It is the preview's rule, a dev tool's, not the scene's: the
// Dart scene's acts place everyone from the sheet themselves.
import 'package:coqui_pixel/coqui_pixel.dart';

Object? _copy(Object? v) => v is Map
    ? {for (final e in v.entries) e.key as String: _copy(e.value)}
    : v is List
    ? [for (final e in v) _copy(e)]
    : v;

int _round(num v) => (v + .5).floor();

/// camino-preview.html: `baseW` (juego.js fresh's fields, the scene's fresh, then [over]).
Map<String, dynamic> caminoPreviewBaseW(
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

/// camino-preview.html: `remapW` for the story [story] (its id) whose file names the acts [acts] (`PREVIEW.story`; null:
/// every move and every moved position, as `PREVIEW.story` null).
Map<String, dynamic> caminoPreviewRemapW(
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
  void move(Map<String, dynamic> p, bool Function(String who) whose) {
    final m = mv.where((q) => whose(q.who) && at(q.old, p)).firstOrNull;
    if (m != null) {
      p['x'] = m.now[0];
      p['y'] = m.now[1];
      return;
    }
    final r = rm.where((e) => at(e.old, p)).firstOrNull;
    if (r != null) {
      p['x'] = r.now![0];
      p['y'] = r.now![1];
    }
  }

  final gente = (w['gente'] as Map<String, dynamic>?) ?? const {};
  for (final en in gente.entries) {
    final p = en.value as Map<String, dynamic>?;
    if (p == null || p['x'] == null) continue;
    move(p, (who) => who == 'whoever' || who == en.key);
  }
  for (final k in const ['perro', 'gato']) {
    final p = w[k] as Map<String, dynamic>?;
    if (p == null || p['x'] == null) continue;
    move(p, (who) => who == k);
  }
  final q = w['cq'] as Map<String, dynamic>?;
  if (q != null) {
    final m = mv.where((p) => p.who == 'cq' && at(p.old, q)).firstOrNull;
    if (m != null) {
      q['x'] = m.now[0];
      q['y'] = m.now[1];
    }
  }
  // a story's own W.respEn (h-camino beats.5) through remap
  final re = w['respEn'];
  if (re is List) {
    final r = rm
        .where((e) => e.old[0] == re[0] && e.old[1] == re[1])
        .firstOrNull;
    if (r != null) w['respEn'] = [...r.now!];
  }
  // the answer cards in the sky (moves: inicio12, inicio13, inicio14 set W.respEn), once the act has run
  final en = sheet.moves
      .where((m) => m.respEn != null && (acts == null || acts.contains(m.act)))
      .firstOrNull;
  final g = w['gente'] as Map<String, dynamic>?;
  if (en != null &&
      story != null &&
      w['respEn'] == null &&
      g != null &&
      g.isNotEmpty) {
    w['respEn'] = en.respEn;
  }
  return w;
}
