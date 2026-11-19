// jsSort against Node 22's Array.prototype.sort (fixture made by tool/diff/sort_probe.mjs).
import 'dart:convert';
import 'dart:io';

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:feature_review/src/logic/js_sort.dart';
import 'package:flutter_test/flutter_test.dart';

int fnv(Iterable<int> list) {
  var h = 0x811c9dc5;
  for (final x in list) {
    for (var k = 0; k < 4; k++) {
      h ^= (x >>> (8 * k)) & 255;
      h = (h * 0x01000193) & 0xFFFFFFFF;
    }
  }
  return h;
}

List<int> structured(int n, int seed) {
  final rnd = Mulberry32(seed);
  final out = <int>[];
  while (out.length < n) {
    final len = 1 + (rnd.next() * 40).floor();
    final dir = rnd.next() < 0.5 ? 1 : -1;
    var v = (rnd.next() * 1000).floor();
    for (var i = 0; i < len && out.length < n; i++) {
      out.add(v);
      v += dir * (rnd.next() * 3).floor();
    }
  }
  return out;
}

void main() {
  final fixture =
      jsonDecode(File('test/fixtures/sort.json').readAsStringSync())
          as Map<String, dynamic>;
  final cases = [
    for (final c in fixture['cases'] as List) c as Map<String, dynamic>,
  ];

  test('the fixture has the cases', () {
    expect(cases.where((c) => c['kind'] == 'shuffle').length, greaterThan(150));
    expect(cases.where((c) => c['kind'] == 'structured').length, 50);
  });

  test(
    'the old shuffle (random() - .5): same order and same number of draws as Node, n = 0 to 500',
    () {
      var checked = 0;
      for (final c in cases.where((c) => c['kind'] == 'shuffle')) {
        final n = c['n'] as int;
        final rnd = Mulberry32(c['seed'] as int);
        var calls = 0;
        final a = List<int>.generate(n, (i) => i);
        jsSort<int>(a, (x, y) {
          calls++;
          return rnd.next() - 0.5;
        });
        final why = 'n=$n seed=${c['seed']}';
        expect(calls, c['calls'], reason: '$why: number of draws');
        expect(fnv(a), c['hash'], reason: '$why: result');
        if (c['result'] != null) {
          expect(a, (c['result'] as List).cast<int>(), reason: why);
        }
        checked++;
      }
      expect(checked, greaterThan(150));
    },
  );

  test(
    'a consistent comparison on data with runs and ties (merges, galloping): the same calls in the same order as Node',
    () {
      for (final c in cases.where((c) => c['kind'] == 'structured')) {
        final n = c['n'] as int;
        final data = structured(n, c['seed'] as int);
        final items = List<int>.generate(n, (i) => i);
        final seq = <int>[];
        jsSort<int>(items, (x, y) {
          seq
            ..add(x)
            ..add(y);
          return data[x] - data[y];
        });
        final why = 'n=$n seed=${c['seed']}';
        expect(seq.length ~/ 2, c['calls'], reason: '$why: number of calls');
        expect(fnv(seq), c['calls_hash'], reason: '$why: sequence of calls');
        expect(fnv(items), c['hash'], reason: '$why: result');
      }
    },
  );
}
