// TEST-ONLY. estufa-preview.html's `remapW` and `baseW`: how the preview moves a W written in OLD positions (a recorded
// run's W) to the new ones, so that a moment of a recorded run can be drawn by the Dart scene exactly as the preview
// draws it. The kitchen is built round the old picture (the sheet's rules.floor), so nothing moves but the places the
// sheet moves: a person at a moved place of a move (`moves`: its who and old place), else at a position the sheet moved
// for that story (`remap` entries that moved); a thing of `cosas` or `vuelos` and abuela's plate at such a position; the
// smell's curve (a moved `rect`); the frog at a moved place of his (`moves` who cq), else at a moved position every use
// of which is a frog's.
import 'package:coqui_pixel/coqui_pixel.dart';

Object? _copy(Object? v) => v is Map
    ? {for (final e in v.entries) e.key as String: _copy(e.value)}
    : v is List
    ? [for (final e in v) _copy(e)]
    : v;

int _round(num v) => (v + 0.5).floor();

/// estufa-preview.html: `baseW` (juego.js fresh's fields, the scene's fresh, then [over]).
Map<String, dynamic> estufaPreviewBaseW(
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

/// estufa-preview.html: `PV.remapW` for the story [story] (its id: `PREVIEW.story`; null: every moved position).
Map<String, dynamic> estufaPreviewRemapW(
  Map<String, dynamic> w0,
  Sheet sheet, {
  String? story,
}) {
  final w = _copy(w0) as Map<String, dynamic>;
  final mv = [for (final m in sheet.moves) ...m.places];
  final rm = [
    for (final e in sheet.remapTable)
      if (e.moved &&
          e.kind == 'point' &&
          (story == null || e.uses.any((u) => u.startsWith('$story.json'))))
        e,
  ];
  List<num>? find(String who, num x, num y) {
    final rx = _round(x), ry = _round(y);
    for (final q in mv) {
      if (q.who == who && q.old[0] == rx && q.old[1] == ry) return q.now;
    }
    for (final e in rm) {
      if (e.old[0] == rx && e.old[1] == ry) return e.now;
    }
    return null;
  }

  final gente = (w['gente'] as Map?) ?? const {};
  for (final en in gente.entries) {
    final p = en.value;
    if (p is! Map || p['x'] is! num) continue;
    final x = p['x'] as num, y = p['y'] as num;
    final m = find(en.key as String, x, y);
    if (m != null) {
      p['x'] = m[0] + (x - _round(x));
      p['y'] = m[1] + (y - _round(y));
    }
  }
  for (final k in const ['cosas', 'vuelos']) {
    for (final p in (w[k] as List?) ?? const []) {
      if (p is! Map || p['x'] is! num) continue;
      final m = find('cosa', p['x'] as num, p['y'] as num);
      if (m != null) {
        p['x'] = m[0];
        p['y'] = m[1];
      }
    }
  }
  final plata = w['plata'];
  if (plata is Map) {
    final m = find('plata', plata['x'] as num, plata['y'] as num);
    if (m != null) {
      plata['x'] = m[0];
      plata['y'] = m[1];
    }
  }
  final olor = w['olor'];
  if (olor is List && olor.length == 4) {
    for (final e in sheet.remapTable) {
      if (e.moved && e.kind == 'rect' && e.old.join(',') == olor.join(',')) {
        w['olor'] = [...e.now!];
        break;
      }
    }
  }
  final cq = w['cq'];
  if (cq is Map) {
    List<num>? mq;
    for (final q in mv) {
      if (q.who == 'cq' && q.old[0] == cq['x'] && q.old[1] == cq['y']) {
        mq = q.now;
        break;
      }
    }
    if (mq == null) {
      for (final e in rm) {
        if (e.old[0] == cq['x'] &&
            e.old[1] == cq['y'] &&
            e.uses.every((u) => u.endsWith('.cq'))) {
          mq = e.now;
          break;
        }
      }
    }
    if (mq != null) {
      cq['x'] = mq[0];
      cq['y'] = mq[1];
    }
  }
  return w;
}
