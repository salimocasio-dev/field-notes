/// What a number looks like in JavaScript when it is joined to a string: `1` and not `1.0`.
///
/// The old code builds its sprite-cache keys that way (`"cq" + q.s + "_" + bl`), so a key made here is the old one.
// JavaScript: String(n), `"" + n`
String jsNum(num n) {
  if (n is int) return '$n';
  if (n == n.truncateToDouble() && n.abs() < 1e21) return '${n.truncate()}';
  return '$n';
}
