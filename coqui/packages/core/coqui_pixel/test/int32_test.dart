import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:test/test.dart';

void main() {
  group('toInt32 is JavaScript\'s `x | 0`', () {
    // [x, x | 0] as node 22 gives them
    const cases = <List<num>>[
      [0, 0],
      [1, 1],
      [-1, -1],
      [0.9, 0],
      [-0.9, 0],
      [1.5, 1],
      [-1.5, -1],
      [255.99999, 255],
      [-255.99999, -255],
      [2147483647, 2147483647],
      [2147483648, -2147483648],
      [-2147483648, -2147483648],
      [-2147483649, 2147483647],
      [4294967295, -1],
      [4294967296, 0],
      [4294967297, 1],
      [4294967295.5, -1],
      [-4294967295.5, 1],
      [6000000000.7, 1705032704],
      [-6000000000.7, -1705032704],
      [9007199254740991, -1],
      [9007199254740992, 0],
      [9007199254740994, 2],
      [-9007199254740994, -2],
      [1e21, -559939584],
      [-1e21, 559939584],
      [1e30, 0],
      [1.5e19, -824442880],
      [43758.5453 * 12345, 540199241],
      [0.1 + 0.2, 0],
      [-0.0, 0],
    ];
    test('on numbers', () {
      for (final c in cases) {
        expect(toInt32(c[0]), c[1], reason: '${c[0]} | 0');
      }
    });
    test('NaN and the infinities give 0', () {
      expect(toInt32(double.nan), 0);
      expect(toInt32(double.infinity), 0);
      expect(toInt32(double.negativeInfinity), 0);
    });
  });

  group('imul is JavaScript\'s Math.imul', () {
    // [a, b, Math.imul(a, b)] as node 22 gives them
    const cases = <List<int>>[
      [0, 0, 0],
      [1, 1, 1],
      [-1, -1, 1],
      [-1, 1, -1],
      [2, 3, 6],
      [65536, 65536, 0],
      [65535, 65535, -131071],
      [65537, 65537, 131073],
      [0x7fffffff, 0x7fffffff, 1],
      [0x7fffffff, 2, -2],
      [-2147483648, -1, -2147483648],
      [-2147483648, 2, 0],
      [0xffffffff, 0xffffffff, 1],
      [0xffffffff, 5, -5],
      [0x80000000, 0x80000001, -2147483648],
      [12345, 67890, 838102050],
      [123456789, 987654321, -67153019],
      [-123456789, 987654321, 67153019],
      [1597334677, 1597334677, 1664532153],
      [0x9e3779b9, 0x85ebca6b, -1055991213],
      [4294967296 + 7, 3, 21],
      [0x5bd1e995, 0x5bd1e995, 678072505],
      [1812433253, 69069, 1835542241],
    ];
    test('on fixed pairs', () {
      for (final c in cases) {
        expect(imul(c[0], c[1]), c[2], reason: 'imul(${c[0]}, ${c[1]})');
      }
    });
    test('on a few thousand pairs against BigInt', () {
      // Park-Miller: no product passes 2^47, so every platform makes the same numbers (it is not the code under test)
      var s = 123456789;
      int next() {
        s = s * 48271 % 2147483647;
        return s;
      }

      for (var n = 0; n < 4000; n++) {
        // values over the whole 32-bit range, as signed and as unsigned numbers
        final a = next() * 2 + (next() & 1) - (n.isEven ? 0 : 2147483648);
        final b = next() * 2 + (next() & 1) - (n % 3 == 0 ? 2147483648 : 0);
        final want = (BigInt.from(a) * BigInt.from(b)).toSigned(32).toInt();
        expect(imul(a, b), want, reason: 'imul($a, $b)');
      }
    });
    test('the result is a signed 32-bit integer', () {
      expect(imul(0x10000, 0x8000), -2147483648);
      expect(imul(0xffff, 0x10001), -1);
    });
  });
}
