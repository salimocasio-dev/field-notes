/// The few JavaScript behaviours app.html's `yo`, `bienvenida` and `listo` lean on, spelled out
/// (page 12, section 6).
library;

/// `if (x)` on a stored setting: 0, false, "", null and NaN are false; everything else is true.
bool jsTruthy(Object? v) {
  if (v == null || v == false || v == '') return false;
  if (v is num) return v != 0 && !v.isNaN;
  return true;
}

/// `Math.round(x)`: halves go up, also below zero.
int jsRound(num x) => (x + 0.5).floor();

/// `pl(n, u, p)` of `yo`: `n === 1 ? u : (p || u + "s")`.
String plural(num n, String one, [String? many]) =>
    n == 1 ? one : (many ?? '${one}s');

/// `"" + v` for a value read from the store: a whole number has no `.0`, a missing key is "undefined".
String jsString(Object? v) {
  if (v == null) return 'undefined';
  if (v is double && v.isFinite && v == v.truncateToDouble()) {
    return v.truncate().toString();
  }
  return '$v';
}
