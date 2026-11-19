/// The trace as text and as a comparison: what `coqui/tool/ref/trazas/juega.mjs` writes (`stringify`), and a deep
/// comparison of two traces.
library;

import 'dart:convert';

/// A trace as JSON text in the format of `coqui/ref/trazas/<story>/<plan>.json`: the long lists one entry to a line, the
/// rest indented by one space. Numbers that are whole print without a decimal point, as JavaScript prints them.
String traceToText(Map<String, dynamic> t) {
  const long = ['clips', 'sounds', 'steps', 'touches', 'choices', 'decisions'];
  final head = <String, dynamic>{}, tail = <String, dynamic>{};
  for (final e in t.entries) {
    (long.contains(e.key) ? tail : head)[e.key] = e.value;
  }
  final enc = JsonEncoder.withIndent(' ');
  var s = enc.convert(_normTree(head)).replaceFirst(RegExp(r'\n}$'), '');
  for (final k in long) {
    if (!tail.containsKey(k)) continue;
    final l = tail[k] as List;
    s += ',\n ${jsonEncode(k)}: [';
    if (l.isEmpty) {
      s += ']';
    } else {
      s += '\n${l.map((x) => '  ${_compact(x)}').join(',\n')}\n ]';
    }
  }
  return '$s\n}\n';
}

String _compact(Object? x) => jsonEncode(_normTree(x));

// a double that is whole prints as an integer (JavaScript has one kind of number)
Object? _normTree(Object? v) {
  if (v is double && v.isFinite && v == v.truncateToDouble() && v.abs() < 1e21) {
    return v.truncate();
  }
  if (v is Map) return {for (final e in v.entries) e.key: _normTree(e.value)};
  if (v is List) return [for (final e in v) _normTree(e)];
  return v;
}

/// Compares two JSON-shaped values. Returns the first difference as `path: a vs b`, or null when they are equal. A
/// number equals a number of the same value (`700` and `700.0`). Map keys are compared as sets (JSON has no key order).
String? firstDifference(Object? a, Object? b, [String path = '']) {
  if (a is Map && b is Map) {
    for (final k in {...a.keys, ...b.keys}) {
      if (!a.containsKey(k)) return '$path.$k: missing in the first (second has ${_show(b[k])})';
      if (!b.containsKey(k)) return '$path.$k: missing in the second (first has ${_show(a[k])})';
      final d = firstDifference(a[k], b[k], '$path.$k');
      if (d != null) return d;
    }
    return null;
  }
  if (a is List && b is List) {
    final n = a.length < b.length ? a.length : b.length;
    for (var i = 0; i < n; i++) {
      final d = firstDifference(a[i], b[i], '$path[$i]');
      if (d != null) return d;
    }
    if (a.length != b.length) {
      return '$path: length ${a.length} vs ${b.length}'
          '${a.length > b.length ? ' (first has more, from ${_show(a[n])})' : ' (second has more, from ${_show(b[n])})'}';
    }
    return null;
  }
  if (a is num && b is num) return a == b ? null : '$path: ${_show(a)} vs ${_show(b)}';
  return a == b ? null : '$path: ${_show(a)} vs ${_show(b)}';
}

String _show(Object? v) {
  final s = jsonEncode(_normTree(v));
  return s.length > 160 ? '${s.substring(0, 157)}...' : s;
}
