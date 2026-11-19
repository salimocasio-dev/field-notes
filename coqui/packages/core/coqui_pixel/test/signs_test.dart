// The signs and marks of juego.js (hand, heart, star, spot, twinkle, bub, bang, the frog and his box, the answer
// bubbles, what a frame draws over the scene, the hand over the view) and the bird of kit.js, each drawn into a small
// picture and compared with the OLD code's drawing of the same call on a browser canvas (tool/make_signs_ref.mjs).
// Exact where the drawing uses only fillRect and unscaled drawImage; the bird is scaled 1.6 and rotated, so for it the
// rule is order 11's: no more than 3% of the picture's pixels differ by more than 24 in a channel.
// On the vm and in a browser the reference is the same fixture.
import 'package:test/test.dart';

import 'support/ctx_replay.dart' show diffTile, tolerance;
import 'support/json_close.dart';
import 'support/signs_replay.dart';

void main() {
  final cases = loadSignCases();
  final byKind = <String, List<SignCase>>{};
  for (final c in cases) {
    byKind.putIfAbsent(c.kind, () => []).add(c);
  }

  test('the reference holds 132 cases of 15 kinds', () {
    expect(cases.length, 132);
    expect(byKind.length, 15);
  });

  test(
    'every reference picture shows something, but the two that should be empty',
    () {
      // a spot round the whole picture dims nothing and its frame is outside; a bird that is gone draws nothing
      final blank = <int>[];
      for (final c in cases.where((c) => c.size != null)) {
        final bg = colour(c.kind == 'handSign' ? '#0E1A24' : c.background);
        if (signReference(c).where((v) => v != bg).length < 10) blank.add(c.n);
      }
      expect(blank, [24, 83]);
    },
  );

  // the bird is scaled and rotated: the rule is the tolerance one
  const scaled = {'drawAve'};

  for (final kind in byKind.keys) {
    final list = byKind[kind]!;
    final pictures = list.where((c) => c.size != null).toList();
    if (pictures.isEmpty) {
      test('$kind: ${list.length} values, the same as the old code gives', () {
        for (final c in list) {
          final r = replaySign(c);
          expect(jsonDiff(r.value, c.value), '', reason: c.label);
        }
      });
      continue;
    }
    var any = 0, far = 0, total = 0;
    final results = <SignCase, ({int any, int far, int total, String first})>{};
    for (final c in pictures) {
      final r = replaySign(c);
      final d = diffTile(r.px!, signReference(c));
      any += d.any;
      far += d.far;
      total += d.total;
      results[c] = (
        any: d.any,
        far: d.far,
        total: d.total,
        first: d.first
            .take(10)
            .map(
              (x) =>
                  '#${x.index} ref ${x.ref.toRadixString(16)} dart ${x.dart.toRadixString(16)}',
            )
            .join(', '),
      );
    }
    final rule = scaled.contains(kind)
        ? 'within $tolerance in 97% of the pixels of each picture'
        : 'exact';
    test(
      '$kind: ${pictures.length} pictures, $any of $total pixels differ at all, $far by more than $tolerance ($rule)',
      () {
        for (final c in pictures) {
          final r = results[c]!;
          if (scaled.contains(kind)) {
            expect(
              r.far,
              lessThanOrEqualTo(r.total * 3 ~/ 100),
              reason: '${c.label}: ${r.first}',
            );
          } else {
            expect(r.any, 0, reason: '${c.label}: ${r.first}');
          }
        }
      },
    );
    // the values a picture case also gives (the effects that are left after the frame's filter)
    final withValue = list
        .where((c) => c.value != null && c.size != null)
        .toList();
    if (withValue.isNotEmpty) {
      test(
        '$kind: the effects left after the frame drop the ones that are over, as the old code does',
        () {
          for (final c in withValue) {
            expect(jsonDiff(replaySign(c).value, c.value), '', reason: c.label);
          }
        },
      );
    }
  }
}
