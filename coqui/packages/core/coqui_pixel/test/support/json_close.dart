/// Whether two JSON-shaped values are the same, numbers within [eps] (the old code's `Math.sin` and Dart's differ in the
/// last digits), and why not when they are not (`''` when they are).
String jsonDiff(Object? a, Object? b, {double eps = 1e-9, String at = r'$'}) {
  if (a is num && b is num) {
    return (a - b).abs() <= eps ? '' : '$at: $a against $b';
  }
  if (a is List && b is List) {
    if (a.length != b.length) {
      return '$at: ${a.length} elements against ${b.length}';
    }
    for (var i = 0; i < a.length; i++) {
      final d = jsonDiff(a[i], b[i], eps: eps, at: '$at[$i]');
      if (d.isNotEmpty) return d;
    }
    return '';
  }
  if (a is Map && b is Map) {
    final keys = {...a.keys, ...b.keys};
    for (final k in keys) {
      if (a.containsKey(k) != b.containsKey(k)) {
        return '$at.$k: only one has it';
      }
      final d = jsonDiff(a[k], b[k], eps: eps, at: '$at.$k');
      if (d.isNotEmpty) return d;
    }
    return '';
  }
  return a == b ? '' : '$at: $a against $b';
}
