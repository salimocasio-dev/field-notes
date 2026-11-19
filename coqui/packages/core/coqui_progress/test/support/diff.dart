/// The first place where [a] and [b] differ, as a message, or null when they are the same JSON.
/// Numbers are compared as numbers, exactly: 3 and 3.0 are the same, 0.1 and 0.10000000000000002
/// are not. Keys are compared as a set (the order of keys is tested through the text).
String? firstDifference(Object? a, Object? b, [String path = r'$']) {
  if (a is Map && b is Map) {
    for (final k in a.keys) {
      if (!b.containsKey(k)) return '$path.$k: only in the first: ${a[k]}';
    }
    for (final k in b.keys) {
      if (!a.containsKey(k)) return '$path.$k: only in the second: ${b[k]}';
    }
    for (final k in a.keys) {
      final d = firstDifference(a[k], b[k], '$path.$k');
      if (d != null) return d;
    }
    return null;
  }
  if (a is List && b is List) {
    if (a.length != b.length) {
      return '$path: length ${a.length} against ${b.length}';
    }
    for (var i = 0; i < a.length; i++) {
      final d = firstDifference(a[i], b[i], '$path[$i]');
      if (d != null) return d;
    }
    return null;
  }
  if (a is num && b is num) {
    return a == b ? null : '$path: $a against $b';
  }
  return a == b
      ? null
      : '$path: ${a.runtimeType} $a against ${b.runtimeType} $b';
}
