/// `x | 0` in JavaScript: the number cut to a signed 32-bit integer (page 12, section 6).
///
/// A fraction is dropped toward zero, a number outside the 32-bit range wraps, NaN and the infinities give 0.
/// It gives the same answer on the VM and in the browser, where `int` is a double.
// JavaScript: x | 0
int toInt32(num x) {
  if (x.isNaN || x.isInfinite) return 0;
  int u;
  if (x is int) {
    // On the VM this is the exact low 32 bits of a 64-bit int; in the browser JavaScript's `&` cuts the
    // exact value of the double to 32 bits, however large it is.
    u = x & 0xFFFFFFFF;
  } else if (x.abs() >= 9007199254740992.0) {
    // 2^53 or more: a double is a whole number already, and `remainder` is exact.
    u = x.remainder(4294967296.0).truncate() & 0xFFFFFFFF;
  } else {
    u = x.truncate() & 0xFFFFFFFF;
  }
  return u >= 0x80000000 ? u - 0x100000000 : u;
}

/// `Math.imul(a, b)` in JavaScript: the low 32 bits of the product, as a signed 32-bit integer.
///
/// It multiplies 16-bit halves, so no step passes 2^53 and the browser loses no bits. Never write `a * b` for
/// 32-bit values (page 12, section 6).
// JavaScript: Math.imul
int imul(int a, int b) {
  final x = toInt32(a), y = toInt32(b);
  final ah = (x >> 16) & 0xFFFF, al = x & 0xFFFF;
  final bh = (y >> 16) & 0xFFFF, bl = y & 0xFFFF;
  // The high half of the product is only needed modulo 2^16, so cut it before shifting it up.
  final mid = ((ah * bl + al * bh) & 0xFFFF) * 65536;
  return toInt32(al * bl + mid);
}
