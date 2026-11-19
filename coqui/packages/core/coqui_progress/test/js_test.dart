// The JavaScript behaviours palabras.js leans on (lib/src/js.dart), against what node gives:
// the values and their expected text come from tool/make_fixture.mjs. Run on the VM and in Chrome:
// numbers behave differently on a phone and in a browser.
import 'package:coqui_progress/src/js.dart';
import 'package:test/test.dart';

import 'fixtures/progress_fixture.dart';

void main() {
  group('a number is written as JavaScript writes it', () {
    test('there are ${numberCases.length} doubles to check', () {
      expect(numberCases.length, greaterThan(400));
    });
    for (final (value, expected) in numberCases) {
      test(expected, () {
        expect(jsNumberToString(value), expected);
        expect(jsonStringify(value), expected);
      });
    }
    test('a whole value has no ".0", on the VM too', () {
      expect(jsonStringify(5.0), '5');
      expect(
        jsonStringify(<String, dynamic>{'a': 2.0, 'b': 0.5, 'c': 3}),
        '{"a":2,"b":0.5,"c":3}',
      );
      expect(
        jsonStringify([1772744400000.0, -0.0, 0.0]),
        '[1772744400000,0,0]',
      );
    });
    test('NaN and Infinity are null', () {
      expect(jsonStringify(double.nan), 'null');
      expect(
        jsonStringify([double.infinity, double.negativeInfinity]),
        '[null,null]',
      );
    });
    test(
      'jsNumberOut keeps a whole value as an integer and a fraction as it is',
      () {
        expect(jsNumberOut(5.0), isA<int>());
        expect(jsNumberOut(5.0), 5);
        expect(jsNumberOut(2.5), 2.5);
        expect(jsNumberOut(1 / 3), 1 / 3);
        expect(jsNumberOut(1e21), 1e21);
        expect(jsNumberOut(double.nan).isNaN, isTrue);
      },
    );
  });

  group('a string is written as JSON.stringify writes it', () {
    for (final (units, expected) in stringCases) {
      test(
        '${units.length} code units, first ${units.isEmpty ? '-' : units.first}: $expected',
        () {
          expect(jsonStringify(String.fromCharCodes(units)), expected);
        },
      );
    }
  });

  group('JSON.stringify of a structure', () {
    test('compact, keys in the order of the map, null kept', () {
      expect(
        jsonStringify(<String, dynamic>{
          'w': 'casa',
          'n': null,
          'ok': true,
          'l': <Object?>[],
          'm': <String, dynamic>{},
          'x': [1, 'a', null, false],
        }),
        '{"w":"casa","n":null,"ok":true,"l":[],"m":{},"x":[1,"a",null,false]}',
      );
    });
  });

  group('truthiness, as `if (x)` and `x || y`', () {
    test('false for null, false, 0, -0, NaN and ""', () {
      for (final v in <Object?>[null, false, 0, 0.0, -0.0, double.nan, '']) {
        expect(jsTruthy(v), isFalse, reason: '$v');
      }
    });
    test('true for the rest, an empty list and map too', () {
      for (final v in <Object?>[
        true,
        1,
        -1,
        0.5,
        'a',
        '0',
        <Object?>[],
        <String, dynamic>{},
      ]) {
        expect(jsTruthy(v), isTrue, reason: '$v');
      }
    });
  });

  group('Number(x) of a stored value', () {
    test('null is 0, a key that is not there is NaN, a string is parsed', () {
      expect(jsToNumber(null), 0);
      expect(jsToNumber(true), 1);
      expect(jsToNumber(' 12 '), 12);
      expect(jsToNumber(''), 0);
      expect(jsToNumber('x').isNaN, isTrue);
      expect(jsToNumber(<Object?>[]).isNaN, isTrue);
      expect(jsNumberAt(<String, dynamic>{'a': null}, 'a'), 0);
      expect(jsNumberAt(<String, dynamic>{}, 'a').isNaN, isTrue);
      expect(jsNumberAt(<String, dynamic>{'a': 2.5}, 'a'), 2.5);
    });
  });

  group('Object.assign of what JSON.parse gives', () {
    test('an object copies its keys over the target, in place', () {
      final t = <String, dynamic>{'a': 1, 'b': 2};
      jsAssign(t, <String, dynamic>{'b': 3, 'c': 4});
      expect(t.keys, ['a', 'b', 'c']);
      expect(t, {'a': 1, 'b': 3, 'c': 4});
    });
    test('null and the other primitives copy nothing; an array its indexes; a string its characters', () {
      final t = <String, dynamic>{'a': 1};
      jsAssign(t, null);
      jsAssign(t, 5);
      jsAssign(t, true);
      expect(t, {'a': 1});
      jsAssign(t, <Object?>['x', null]);
      jsAssign(t, 'yz');
      expect(t, {'a': 1, '0': 'y', '1': 'z'});
    });
  });
}
