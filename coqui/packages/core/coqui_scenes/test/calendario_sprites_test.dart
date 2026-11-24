// El calendario's scene-specific sprites (lib/src/calendario/calendario_sprites.dart): dimensions match
// calendario-sheet.json (11 picture cards 14 x 12, sun peg 9 x 9, balloons 24 x 20, kite 28 x 14, bow 7 x 5,
// card box 14 x 10), every sprite draws non-empty pixels, and distinct variants differ.
import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/src/calendario/calendario_sprites.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/hash.dart';

int _ink(Sprite s) {
  var n = 0;
  for (final c in s.px) {
    if (c >>> 24 != 0) n++;
  }
  return n;
}

void main() {
  test('all 11 picture cards are 14 x 12 and distinct', () {
    expect(CALENDARIO_CARTAS, hasLength(11));
    final hashes = <String>{};
    for (final k in CALENDARIO_CARTAS) {
      final s = mkCartaCalendario(k);
      expect([s.w, s.h], [14, 12], reason: k);
      expect(_ink(s), greaterThan(100), reason: k);
      hashes.add(hashOf(s.px));
    }
    expect(hashes, hasLength(11));
  });

  test('sun peg, balloons, burst, kite, bows, box, bag, and baskets match sheet sizes', () {
    final sol = mkSolPeg();
    expect([sol.w, sol.h], [9, 9]);
    expect(_ink(sol), greaterThan(35));

    final g = [mkGlobos(3), mkGlobos(2), mkGlobos(1)];
    for (final s in g) {
      expect([s.w, s.h], [24, 20]);
      expect(_ink(s), greaterThan(45));
    }
    expect({for (final s in g) hashOf(s.px)}, hasLength(3));

    final solos = {for (var i = 0; i < 3; i++) hashOf(mkGloboSolo(i).px)};
    expect(solos, hasLength(3));
    expect(_ink(mkEstallido()), greaterThan(20));

    final kite = mkChiringa();
    expect([kite.w, kite.h], [28, 14]);
    expect(_ink(kite), greaterThan(120));

    final fly = {for (var m = 1; m <= 3; m++) hashOf(mkChiringaVuela(m, 0).px)};
    expect(fly, hasLength(3));

    final bow = mkLazo();
    expect([bow.w, bow.h], [7, 5]);
    expect(_ink(bow), greaterThan(15));

    final box = mkCajaCalendario();
    expect([box.w, box.h], [14, 10]);
    expect(_ink(box), greaterThan(60));

    expect(_ink(mkBultoEscolar()), greaterThan(30));
    expect(
      hashOf(mkCestaCalendario(llena: false).px),
      isNot(hashOf(mkCestaCalendario(llena: true).px)),
    );
  });

  test('the sprite sheet list has every sprite non-empty', () {
    final list = calendarioSpritesSheet();
    expect(list.length, greaterThanOrEqualTo(25));
    for (final (label, s) in list) {
      expect(_ink(s), greaterThan(10), reason: label);
    }
  });
}
