// TEST-ONLY. lago-preview.html's `remapW` and `baseW`, ported: how the preview moves a W written in OLD positions (a
// recorded run's W) to the new ones, so that a moment of a recorded run can be drawn by the Dart scene exactly as the
// preview draws it. The lake and its dock are built round the old picture (the sheet's rules.floor), so nothing moves
// but the places the sheet moves: a child, Canelo, a duck, a bird (and its post, casa), a boat, the fish, the bread, the
// flower, the bag or the sack at a moved place of an act the story uses (`moves`, and the moves of every act, `*`) goes
// to its new one, else one at a story position the sheet moved for that story (`remap` entries that moved); the duck
// paddling round the post moves with the post (`moves.shift`); a boat that reached Carmen goes to its slot in the new
// row (`slotC`); the frog likewise. It is the preview's rule, a dev tool's, not the scene's: the Dart scene's acts place
// everyone from the sheet themselves.
import 'package:coqui_pixel/coqui_pixel.dart';

Object? _copy(Object? v) => v is Map
    ? {for (final e in v.entries) e.key as String: _copy(e.value)}
    : v is List
    ? [for (final e in v) _copy(e)]
    : v;

int _round(num v) => (v + .5).floor();

/// lago-preview.html: `baseW` (juego.js fresh's fields, the scene's fresh, then [over]).
Map<String, dynamic> lagoPreviewBaseW(
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

// lago-preview.html: PV.slot. A boat that reached Carmen: the old slotC(i) row to the new one (the sheet's moves, line
// 62: SLOTC in the moved source)
List<num>? _slot(Sheet sheet, Map<String, dynamic> o) {
  final i =
      _round(((o['x'] as num) - 98) / 6) + ((o['y'] as num) > 121 ? 13 : 0);
  if (i < 0 || i > 25) return null;
  final m = sheet.moves.firstWhere((m) => m.src.startsWith('const slotC='));
  final sl = RegExp(r'SLOTC=\[(\[.*?\])\]').firstMatch(m.to)![1]!;
  final pts = [
    for (final p in RegExp(r'\[(\d+),(\d+)\]').allMatches(sl))
      [int.parse(p[1]!), int.parse(p[2]!)],
  ];
  return pts[i < 11 ? i : 11];
}

/// lago-preview.html: `remapW` for the story [story] (its id) whose file names the acts [acts] (`PREVIEW.story`; null:
/// every move and every moved position, as `PREVIEW.story` null).
Map<String, dynamic> lagoPreviewRemapW(
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
  List<num>? find(String who, num x, num y) {
    final rx = _round(x), ry = _round(y);
    for (final q in mv) {
      if ((q.who == 'whoever' || q.who == who) &&
          q.old[0] == rx &&
          q.old[1] == ry) {
        return q.now;
      }
    }
    for (final e in rm) {
      if (e.old[0] == rx && e.old[1] == ry) return e.now;
    }
    return null;
  }

  void move(String who, Map<String, dynamic> p) {
    final m = find(who, p['x'] as num, p['y'] as num);
    if (m != null) {
      p['x'] = m[0];
      p['y'] = m[1];
    }
  }

  final gente = (w['gente'] as Map<String, dynamic>?) ?? const {};
  for (final en in gente.entries) {
    final p = en.value as Map<String, dynamic>?;
    if (p == null || p['x'] == null) continue;
    move(en.key, p);
  }
  final pe = w['perro'] as Map<String, dynamic>?;
  if (pe != null && pe['x'] != null) move('perro', pe);
  ({String who, String when, List<num> by})? sh;
  for (final m in sheet.moves) {
    if (m.shift != null) {
      sh = m.shift;
      break;
    }
  }
  for (final v in ((w['patos'] as Map?) ?? const {}).values) {
    final o = v as Map<String, dynamic>?;
    if (o == null || o['x'] == null) continue;
    if (sh != null && jsTruthy(o[sh.when])) {
      o['x'] = (o['x'] as num) + sh.by[0];
      o['y'] = (o['y'] as num) + sh.by[1];
    } else {
      move('pato', o);
    }
  }
  for (final v in ((w['aves'] as Map?) ?? const {}).values) {
    final o = v as Map<String, dynamic>?;
    if (o == null || o['x'] == null) continue;
    move('ave', o);
    final casa = o['casa'];
    if (jsTruthy(casa)) {
      final m = find('ave', (casa as List)[0] as num, casa[1] as num);
      if (m != null) o['casa'] = [...m];
    }
  }
  for (final v in ((w['botes'] as Map?) ?? const {}).values) {
    final o = v as Map<String, dynamic>?;
    if (o == null || o['x'] == null) continue;
    if (o['en'] == 'carmen') {
      final s = _slot(sheet, o);
      if (s != null) {
        o['x'] = s[0];
        o['y'] = s[1];
      }
    } else {
      move('bote', o);
    }
  }
  for (final v in ((w['peces'] as Map?) ?? const {}).values) {
    final o = v as Map<String, dynamic>?;
    if (o == null || o['x'] == null) continue;
    move('pez', o);
  }
  final q = w['cq'] as Map<String, dynamic>?;
  if (q != null) {
    List<num>? m;
    for (final p in mv) {
      if (p.who == 'cq' && p.old[0] == q['x'] && p.old[1] == q['y']) {
        m = p.now;
        break;
      }
    }
    if (m == null) {
      for (final e in rm) {
        if (e.old[0] == q['x'] && e.old[1] == q['y']) {
          m = e.now;
          break;
        }
      }
    }
    if (m != null) {
      q['x'] = m[0];
      q['y'] = m[1];
    }
  }
  final pan = w['pan'] as Map<String, dynamic>?;
  if (pan != null && pan['con'] == null && pan['x'] != null) move('pan', pan);
  for (final k in const ['flor', 'bolsa', 'saco']) {
    final v = w[k];
    if (jsTruthy(v)) {
      final m = find(k, (v as List)[0] as num, v[1] as num);
      if (m != null) w[k] = [...m];
    }
  }
  return w;
}
