// The arithmetic of ¿Dónde?'s pictures (M), and the games' instruction lines (I).
import 'package:feature_review/src/logic/repaso_plan.dart';
import 'package:feature_review/src/ui/repaso_layout.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('I: the six instruction lines, word for word; the two picture games say the same one', () {
    expect(
      {for (final k in GameKind.values) k: gameInstruction(k)},
      {
        GameKind.hear: 'Listen. Touch the word you heard.',
        GameKind.cual: 'Listen. Touch the picture that fits.',
        GameKind.build:
            "Listen. Touch the words in the order you hear. Two don't belong.",
        GameKind.match: 'Touch a sound, then its word.',
        GameKind.where: 'Listen. Touch the picture that fits.',
        GameKind.say: 'Listen. Say what comes next.',
      },
    );
    expect(gameInstruction(GameKind.where), gameInstruction(GameKind.cual));
  });

  test('M: the pictures are stacked at the largest whole scale at which all of them fit', () {
    // a wide, tall room at ratio 3: three pictures, 196 wide each at scale 3
    final big = planWhere(available: 3, width: 358, height: 700, dpr: 3);
    expect(big, (count: 3, k: 3));
    // the scale is the largest: one more would not fit
    expect(whereScaleFor(n: 3, width: 358, height: 700, dpr: 3), 3);
    expect(whereScaleFor(n: 3, width: 358, height: 700, dpr: 3) + 1, 4);
    expect(4 * 216 / 3 * 3 + 2 * whereGap, greaterThan(700));
  });

  test('M: three pictures are shown only when each is at least 150 px wide; otherwise two, the biggest that fit, never thumbnails', () {
    for (final dpr in [1.0, 2.0, 2.625, 3.0, 3.5]) {
      for (var w = 300.0; w <= 480; w += 20) {
        for (var h = 200.0; h <= 1000; h += 20) {
          final p = planWhere(available: 3, width: w, height: h, dpr: dpr);
          final width = 196 * p.k / dpr;
          expect(p.k, greaterThanOrEqualTo(1));
          if (p.count == 3) {
            expect(
              width,
              greaterThanOrEqualTo(whereMinWidth),
              reason: '$dpr $w x $h',
            );
            // they all fit
            expect(
              3 * 216 * p.k / dpr + 2 * whereGap,
              lessThanOrEqualTo(h + 1e-9),
            );
            expect(width, lessThanOrEqualTo(w + 1e-9));
          } else {
            expect(p.count, 2);
            // three could not be 150 wide each
            final three = whereScaleFor(n: 3, width: w, height: h, dpr: dpr);
            expect(
              three < 1 || 196 * three / dpr < whereMinWidth,
              isTrue,
              reason: '$dpr $w x $h gave two but three could be $three',
            );
            // the largest scale at which two fit (or 1 when none does)
            final two = whereScaleFor(n: 2, width: w, height: h, dpr: dpr);
            expect(p.k, two < 1 ? 1 : two);
          }
        }
      }
    }
  });

  test('M: the phones of the reference pictures: two big pictures, not three small ones', () {
    // 390 x 844 at ratio 2 and 3, 412 x 915 at 2.625: the room the game's area has (about 450 to 540 px high)
    for (final (dpr, w, h) in [
      (2.0, 358.0, 460.0),
      (3.0, 358.0, 460.0),
      (2.625, 380.0, 520.0),
    ]) {
      final p = planWhere(available: 3, width: w, height: h, dpr: dpr);
      expect(p.count, 2, reason: '$dpr');
      expect(
        196 * p.k / dpr,
        greaterThanOrEqualTo(150),
        reason: '$dpr: not a thumbnail',
      );
    }
    // an item that has only two pictures has two
    expect(planWhere(available: 2, width: 358, height: 900, dpr: 3).count, 2);
  });
}
