/// What a number looks like in JavaScript when it is joined to a string: `1` and not `1.0`.
///
/// The old code builds its sprite-cache keys that way (`"cq" + q.s + "_" + bl`), so a key made here is the old one.
// JavaScript: String(n), `"" + n`
String jsNum(num n) {
  if (n is int) return '$n';
  if (n == n.truncateToDouble() && n.abs() < 1e21) return '${n.truncate()}';
  return '$n';
}

/// JavaScript's truth of a value from a JSON-shaped map (`if (x)`): not null, not false, not 0, not NaN, not "".
/// Anything else, a list or a map included, is true. Page 12, section 6: spell a truth test out; this is the spelled-out one
/// for a value whose type is not known.
// JavaScript: if (x)
bool jsTruthy(Object? v) {
  if (v == null) return false;
  if (v is bool) return v;
  if (v is num) return v != 0 && !v.isNaN;
  if (v is String) return v.isNotEmpty;
  return true;
}
