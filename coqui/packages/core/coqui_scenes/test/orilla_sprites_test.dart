// La orilla's scene-specific sprites (lib/src/orilla/orilla_sprites.dart): dimensions match orilla-sheet.json
// (shells 6x6 & row 22x6, fishing boat 34x20, toy boats 14x10 in 5 colours, frog's boat 36x8 in 5 colours, hanging
// towels 14x16 in 4 colours, towel pile 14x10, bread basket 12x10), every sprite draws non-empty pixels, and
// distinct variants differ.
import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/src/orilla/orilla_sprites.dart';
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
  test('shells, fishing boat, gull, and basket match sheet sizes', () {
    final c = mkConcha();
    final cb = mkConchaBlanca();
    expect([c.w, c.h], [6, 6]);
    expect([cb.w, cb.h], [6, 6]);
    expect(hashOf(c.px), isNot(hashOf(cb.px)));

    final rows = [mkConchas(1), mkConchas(2), mkConchas(3)];
    for (final s in rows) {
      expect([s.w, s.h], [22, 6]);
      expect(_ink(s), greaterThan(15));
    }
    expect({for (final s in rows) hashOf(s.px)}, hasLength(3));

    final b0 = mkBotePesca(), b1 = mkBotePesca(rock: true);
    expect([b0.w, b0.h], [34, 20]);
    expect([b1.w, b1.h], [34, 20]);
    expect(hashOf(b0.px), isNot(hashOf(b1.px)));

    expect(hashOf(mkGaviota(0).px), isNot(hashOf(mkGaviota(1).px)));

    final canasta = mkCanastaPlaya();
    expect([canasta.w, canasta.h], [12, 10]);
    expect(_ink(canasta), greaterThan(60));
  });

  test('toy boats (5 colours) and frog boats (5 colours) match sheet sizes and are distinct', () {
    final toys = <String>{};
    final frogs = <String>{};
    for (final col in ORILLA_BOTE_COLORES) {
      final t = mkBoteJuguete(col);
      expect([t.w, t.h], [14, 10], reason: col);
      expect(_ink(t), greaterThan(50), reason: col);
      toys.add(hashOf(t.px));

      final f = mkBoteRana(col);
      expect([f.w, f.h], [36, 8], reason: col);
      expect(_ink(f), greaterThan(150), reason: col);
      frogs.add(hashOf(f.px));
    }
    expect(toys, hasLength(5));
    expect(frogs, hasLength(5));
    expect(
      hashOf(mkBoteJuguete('blanco').px),
      isNot(hashOf(mkBoteJuguete('blanco', hundido: true).px)),
    );
    expect(
      hashOf(mkBoteRana('rojo').px),
      isNot(hashOf(mkBoteRana('rojo', hundido: true).px)),
    );
  });

  test('towels (4 colours), pile (1..3), necklaces (0..3), waves, and abuela lying back', () {
    final towels = <String>{};
    for (final col in ORILLA_TOALLA_COLORES) {
      final t = mkToallaColgada(col);
      expect([t.w, t.h], [14, 16], reason: col);
      expect(_ink(t), greaterThan(180), reason: col);
      towels.add(hashOf(t.px));
    }
    expect(towels, hasLength(4));
    expect(
      hashOf(mkToallaColgada('rojo').px),
      isNot(hashOf(mkToallaColgada('rojo', gotea: true).px)),
    );

    final piles = [mkPilaToallas(1), mkPilaToallas(2), mkPilaToallas(3)];
    for (final p in piles) {
      expect([p.w, p.h], [14, 10]);
    }
    expect({for (final p in piles) hashOf(p.px)}, hasLength(3));

    final collars = [for (var n = 0; n <= 3; n++) hashOf(mkCollar(n).px)];
    expect(collars.toSet(), hasLength(4));
    final prizes = [for (var n = 1; n <= 3; n++) hashOf(mkCollarRana(n).px)];
    expect(prizes.toSet(), hasLength(3));

    expect(_ink(mkAbuelaAcostada()), greaterThan(200));
    expect(_ink(mkOla(false, 0)), greaterThan(500));
    expect(_ink(mkOla(true, 0)), greaterThan(1000));
    expect(_ink(mkPerroConcha(false)), greaterThan(250));
    expect(_ink(mkPerroArena()), greaterThan(200));
  });

  test('the sprite sheet list has every sprite non-empty', () {
    final list = orillaSpritesSheet();
    expect(list.length, greaterThanOrEqualTo(35));
    for (final (label, s) in list) {
      expect(_ink(s), greaterThan(10), reason: label);
    }
  });
}
