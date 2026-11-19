import 'package:coqui_contracts/src/platform.dart';

/// The standard mulberry32 generator, the one the old tools use for recorded
/// runs. The same seed gives the same values on the VM and on the web.
///
/// In JavaScript (the ten values for seed 1 in the tests come from this):
///
///     node -e 'function mulberry32(a){return function(){let t=(a+=0x6d2b79f5);t=Math.imul(t^(t>>>15),t|1);t^=t+Math.imul(t^(t>>>7),t|61);return((t^(t>>>14))>>>0)/4294967296;};}const r=mulberry32(1);for(let i=0;i<10;i++)console.log(r())'
class Mulberry32 implements Rng {
  Mulberry32(int seed) : _a = seed & _mask;

  static const int _mask = 0xFFFFFFFF;
  int _a;

  @override
  double next() {
    _a = (_a + 0x6D2B79F5) & _mask;
    var t = _a;
    t = _imul(t ^ (t >>> 15), t | 1);
    t = (t ^ ((t + _imul(t ^ (t >>> 7), t | 61)) & _mask)) & _mask;
    return ((t ^ (t >>> 14)) & _mask) / 4294967296;
  }

  // DECISION(order 02): Math.imul on unsigned 32-bit values, by 16-bit halves,
  // kept private here. The public imul is order 10's, in coqui_pixel, and
  // coqui_contracts may depend on nothing.
  static int _imul(int a, int b) {
    final aHi = (a >>> 16) & 0xFFFF;
    final aLo = a & 0xFFFF;
    final bHi = (b >>> 16) & 0xFFFF;
    final bLo = b & 0xFFFF;
    final cross = ((aHi * bLo + aLo * bHi) & 0xFFFF) * 0x10000;
    return (aLo * bLo + cross) & _mask;
  }
}
