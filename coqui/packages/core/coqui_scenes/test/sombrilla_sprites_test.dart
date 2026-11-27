// La sombrilla's scene-specific sprites (lib/src/sombrilla/sombrilla_sprites.dart): dimensions match
// sombrilla-sheet.json and sombrilla-preview.html (abuela lying 52x18, face shell 5x5, spiral shell 8x8, spiral row
// 28x8, bucket 12x12, hats/glasses/sandals 16x12, beach ball 9x9), every sprite draws non-empty pixels, and distinct
// variants differ.
import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/src/sombrilla/sombrilla_sprites.dart';
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
  test('preview-matching sprites match sombrilla-sheet.json dimensions', () {
    final abSleep = mkAbuelaAcostadaSombrilla(pose: 'sleep');
    final abStir = mkAbuelaAcostadaSombrilla(pose: 'stir');
    final abOjo = mkAbuelaAcostadaSombrilla(pose: 'ojo');
    for (final s in [abSleep, abStir, abOjo]) {
      expect([s.w, s.h], [52, 18]);
      expect(_ink(s), greaterThan(400));
    }
    expect({
      hashOf(abSleep.px),
      hashOf(abStir.px),
      hashOf(abOjo.px),
    }, hasLength(3));

    final c5 = mkConcha5();
    expect([c5.w, c5.h], [5, 5]);
    expect(_ink(c5), greaterThan(10));

    final car = mkCaracol();
    expect([car.w, car.h], [8, 8]);
    expect(_ink(car), greaterThan(30));

    final rows = [mkCaracoles(1), mkCaracoles(2), mkCaracoles(3)];
    for (final s in rows) {
      expect([s.w, s.h], [28, 8]);
      expect(_ink(s), greaterThan(30));
    }
    expect({for (final s in rows) hashOf(s.px)}, hasLength(3));

    expect([mkCuboConchas().w, mkCuboConchas().h], [12, 12]);
    expect([mkSombreros().w, mkSombreros().h], [16, 12]);
    expect([mkGafas().w, mkGafas().h], [16, 12]);
    expect([mkChancletas().w, mkChancletas().h], [16, 12]);
    expect([mkBolaPlaya().w, mkBolaPlaya().h], [9, 9]);
  });

  test('story 75, 76 and 77 Needs sprites are distinct and non-empty', () {
    final zs = [mkZetas(1, 0), mkZetas(2, 0), mkZetas(3, 0)];
    expect({for (final z in zs) hashOf(z.px)}, hasLength(3));
    expect(
      hashOf(mkBocaLinea('grande').px),
      isNot(hashOf(mkBocaLinea('pequena').px)),
    );
    expect(_ink(mkSombreroArena()), greaterThan(200));
    expect(_ink(mkPeloAlgas()), greaterThan(150));
    expect(
      hashOf(mkOrejaConcha(right: false).px),
      isNot(hashOf(mkOrejaConcha(right: true).px)),
    );
    expect(_ink(mkEstrellaMar()), greaterThan(40));
    expect({
      hashOf(mkPiedra('cabeza').px),
      hashOf(mkPiedra('brazo').px),
      hashOf(mkPiedra('mano').px),
    }, hasLength(3));
    expect(_ink(mkPaloBoton()), greaterThan(15));
    expect(_ink(mkPerroCaracol(false)), greaterThan(250));
    expect(_ink(mkPerroCava(0)), greaterThan(250));
    expect(_ink(mkPerroArenaSombrilla()), greaterThan(250));
    expect(_ink(mkPerroPalo()), greaterThan(250));
    expect(_ink(mkCarmenAcostada()), greaterThan(200));
    expect(_ink(mkSombreroPuesto()), greaterThan(60));
    expect(_ink(mkGafasPuestas()), greaterThan(20));
    expect(_ink(mkChancletasPuestas()), greaterThan(25));
    expect(_ink(mkViento(0)), greaterThan(40));
    expect(_ink(mkAplauso(0)), greaterThan(4));
  });

  test('the sprite sheet list has every sprite non-empty', () {
    final list = sombrillaSpritesSheet();
    expect(list.length, greaterThanOrEqualTo(35));
    for (final (label, s) in list) {
      expect(_ink(s), greaterThan(4), reason: label);
    }
  });
}
