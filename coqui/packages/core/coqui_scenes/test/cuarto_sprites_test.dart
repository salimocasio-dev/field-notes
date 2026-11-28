// El cuarto's own sprites (lib/src/cuarto/cuarto_sprites.dart): dimensions match cuarto-sheet.json's spot boxes
// and cuarto-preview.html's stand-ins, every sprite has drawn ink, and state variants differ visually.
import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/src/cuarto/cuarto_sprites.dart';
import 'package:flutter_test/flutter_test.dart';

int _ink(Sprite s) {
  var n = 0;
  for (final p in s.px) {
    if (p >>> 24 != 0) n++;
  }
  return n;
}

bool _same(Sprite a, Sprite b) {
  if (a.w != b.w || a.h != b.h) return false;
  for (var i = 0; i < a.px.length; i++) {
    if (a.px[i] != b.px[i]) return false;
  }
  return true;
}

void main() {
  test('preview-matching sprites keep cuarto-sheet.json box dimensions', () {
    expect((mkAlmohada().w, mkAlmohada().h), (20, 12));
    expect((mkPlatoCuarto(3).w, mkPlatoCuarto(3).h), (12, 6));
    expect((mkCampana().w, mkCampana().h), (6, 8));
    expect((mkMantaAbuelo().w, mkMantaAbuelo().h), (16, 10));
    expect((mkNariz().w, mkNariz().h), (10, 8));
    expect((mkBebeCuarto('sleep').w, mkBebeCuarto('sleep').h), (14, 10));
    expect((mkZetas(3).w, mkZetas(3).h), (14, 10));
    for (final k in const [
      'pantalon',
      'camisa',
      'zapatos',
      'sombrero',
      'reloj',
    ]) {
      final s = mkRopaCuarto(k);
      expect((s.w, s.h), (12, 10), reason: 'ropa $k size');
    }
    const hang = (
      rows: 40,
      bed: 0,
      foot: 100,
      lyingFrom: 24,
      sittingFrom: 30,
      width: 34,
      z: 0.5,
    );
    final inBed = mkInBed(
      FAM['hermano']!,
      const [110, 150, 220],
      hang,
      blanketFrom: 24,
    );
    expect((inBed.w, inBed.h), (48, 40));
  });

  test('every sprite in cuartoSpritesSheet has opaque pixels', () {
    final sheet = cuartoSpritesSheet();
    expect(sheet.length, greaterThanOrEqualTo(45));
    for (final (name, s) in sheet) {
      expect(_ink(s), greaterThan(0), reason: '$name has no drawn pixels');
    }
  });

  test('state variants differ visually', () {
    const hang = (
      rows: 40,
      bed: 0,
      foot: 100,
      lyingFrom: 24,
      sittingFrom: 30,
      width: 34,
      z: 0.5,
    );
    const blue = [110, 150, 220];
    expect(
      _same(
        mkInBed(FAM['hermano']!, blue, hang, blanketFrom: 24),
        mkInBed(FAM['hermano']!, blue, hang, blanketFrom: 30),
      ),
      isFalse,
    );
    expect(
      _same(
        mkInBed(FAM['hermano']!, blue, hang, blanketFrom: 24),
        mkInBed(FAM['hermano']!, blue, hang, blanketFrom: null),
      ),
      isFalse,
    );
    expect(
      _same(mkAbueloArmchair(dormido: true), mkAbueloArmchair(dormido: false)),
      isFalse,
    );
    expect(_same(mkAbuelaCuarto(), mkAbuelaCuarto(silencio: true)), isFalse);
    expect(_same(mkAbuelaCuarto(), mkAbuelaCuarto(foto: true)), isFalse);
    expect(
      _same(mkAbuelaCuarto(foto: true), mkAbuelaCuarto(fotoUp: true)),
      isFalse,
    );
    expect(_same(mkPerroCuarto('sit'), mkPerroCuarto('lick')), isFalse);
    expect(_same(mkBebeCuarto('sleep'), mkBebeCuarto('stir')), isFalse);
    expect(_same(mkBebeCuarto('stir'), mkBebeCuarto('awake')), isFalse);
    expect(_same(mkZetas(3), mkZetas(2)), isFalse);
    expect(_same(mkZetas(2), mkZetas(1)), isFalse);
    expect(_same(mkPlatoCuarto(3), mkPlatoCuarto(2)), isFalse);
    expect(_same(mkPlatoCuarto(2), mkPlatoCuarto(1)), isFalse);
    expect(_same(mkPlatoCuarto(1), mkPlatoCuarto(0)), isFalse);
    expect(_same(mkManecillas(7.0), mkManecillas(7.5)), isFalse);
    expect(
      _same(mkLuisVestir(), mkLuisVestir(trousers: true, shoes: true)),
      isFalse,
    );
    expect(
      _same(
        mkLuisVestir(trousers: true, shoes: true, shirt: true),
        mkLuisVestir(
          trousers: true,
          shoes: true,
          shirt: true,
          hat: true,
          watch: true,
        ),
      ),
      isFalse,
    );
    expect(
      _same(
        mkLuisVestir(
          trousers: true,
          shoes: true,
          shirt: true,
          hat: true,
          watch: true,
          neat: 3,
        ),
        mkLuisVestir(
          trousers: true,
          shoes: true,
          shirt: true,
          hat: true,
          watch: true,
          neat: 2,
        ),
      ),
      isFalse,
    );
    expect(
      _same(
        mkLuisVestir(
          trousers: true,
          shoes: true,
          shirt: true,
          hat: true,
          watch: true,
          neat: 2,
        ),
        mkLuisVestir(
          trousers: true,
          shoes: true,
          shirt: true,
          hat: true,
          watch: true,
          neat: 1,
        ),
      ),
      isFalse,
    );
    expect(_same(mkFotoCard(3), mkFotoCard(2)), isFalse);
    expect(_same(mkFotoCard(2), mkFotoCard(1)), isFalse);
  });
}
