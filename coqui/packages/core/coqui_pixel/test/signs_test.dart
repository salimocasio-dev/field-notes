// The signs and marks of juego.js (hand, heart, star, spot, twinkle, bub, bang, the frog and his box, the answer
// bubbles, what a frame draws over the scene, the hand over the view) and the bird of kit.js, each drawn into a small
// picture and compared with the OLD code's drawing of the same call on a browser canvas (tool/make_signs_ref.mjs).
// Exact where the drawing uses only fillRect and unscaled drawImage; the bird is scaled 1.6 and rotated, so for it the
// rule is order 11's: no more than 3% of the picture's pixels differ by more than 24 in a channel.
// On the vm and in a browser the reference is the same fixture.
import 'dart:typed_data';

import 'package:coqui_pixel/coqui_pixel.dart';
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

  // `Signs.frog(shadow: false)`: the same frog without the old flat shadow (juego.js line 48), on the 8 reference cases.
  // The shadow's own pixels are what `shadow` draws alone on the case's background, at the place `frog` puts it.
  group('frog without the old shadow', () {
    final frogs = byKind['frog']!;

    /// The shadow of case [c], alone on its background: its colour where it draws, the background elsewhere.
    Uint32List shadowAlone(SignCase c) {
      final size = c.size!, px = Uint32List(size[0] * size[1]);
      final g = Ctx(px, size[0], size[1]);
      g.fillStyle = colour(c.background);
      g.fillRect(0, 0, size[0], size[1]);
      final q = c.args[0] as Map<String, dynamic>, b = frogBox(q);
      shadow(g, b.x + 2, (q['y'] as num) + 25, b.w - 5);
      return px;
    }

    test('there are 8 cases', () => expect(frogs.length, 8));

    // the cases whose frog covers all of his shadow (s .5 and dy 3.5 push him down over it): nothing to drop there
    const hidden = [54];

    test('shadow: true is the old picture, and shadow: false is the same everywhere but the shadow\'s own pixels, which hold the background', () {
      for (final c in frogs) {
        final bg = colour(c.background), alone = shadowAlone(c);
        final withShadow = replaySign(c, frogShadow: true).px!;
        final without = replaySign(c, frogShadow: false).px!;
        final ref = signReference(c);
        final bad = <String>[];
        var shadowPixels = 0, shown = 0, covered = 0;
        for (var i = 0; i < ref.length; i++) {
          if (withShadow[i] != ref[i]) bad.add('#$i true != the reference');
          if (alone[i] == bg) {
            // not the shadow's: the frog and the background, the same either way
            if (without[i] != withShadow[i]) bad.add('#$i outside');
            continue;
          }
          shadowPixels++;
          if (without[i] == bg) {
            // the shadow's pixel, with the frog not over it: the shadow with it, the background without
            if (withShadow[i] == alone[i]) {
              shown++;
            } else {
              bad.add('#$i shadow pixel not shown by shadow: true');
            }
          } else if (without[i] == withShadow[i]) {
            covered++; // the frog is over it: both pictures hold the frog's pixel
          } else {
            bad.add('#$i inside');
          }
        }
        // what is left in `without` is the frog's, not the shadow's colour
        final shadowColour = alone.firstWhere((v) => v != bg);
        expect(
          without.contains(shadowColour),
          isFalse,
          reason: '${c.label}: the shadow\'s colour is left',
        );
        expect(bad.take(10), isEmpty, reason: c.label);
        expect(shadowPixels, shown + covered, reason: c.label);
        expect(
          shown > 0,
          !hidden.contains(c.n),
          reason: '${c.label}: $shown shadow pixels show',
        );
      }
    });

    test('the flag does something: the two pictures differ', () {
      final same = <int>[];
      for (final c in frogs) {
        final a = replaySign(c, frogShadow: true).px!;
        final b = replaySign(c, frogShadow: false).px!;
        var differ = 0;
        for (var i = 0; i < a.length; i++) {
          if (a[i] != b[i]) differ++;
        }
        if (differ == 0) same.add(c.n);
        // and `true` is the default
        final d = replaySign(c).px!;
        for (var i = 0; i < a.length; i++) {
          if (a[i] != d[i]) fail('${c.label}: the default is not shadow: true');
        }
      }
      expect(same, hidden, reason: 'the cases where both pictures are equal');
    });
  });

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
