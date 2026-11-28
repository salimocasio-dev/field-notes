// La muralla's own sprites (lib/src/muralla/muralla_sprites.dart): dimensions match muralla-sheet.json's spot boxes
// and muralla-preview.html's stand-ins, every sprite has drawn ink, and state variants differ visually.
import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/src/muralla/muralla_sprites.dart';
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
  test('preview-matching sprites keep muralla-sheet.json box dimensions', () {
    expect((mkFarol().w, mkFarol().h), (10, 12));
    expect((mkCamara().w, mkCamara().h), (12, 22));
    expect((mkVelaMuralla().w, mkVelaMuralla().h), (8, 16));
    expect((mkJugoMuralla().w, mkJugoMuralla().h), (6, 10));
    expect((mkPlatoMuralla().w, mkPlatoMuralla().h), (12, 6));
    expect((mkSillaMuralla().w, mkSillaMuralla().h), (14, 24));
    expect((mkGuitarra().w, mkGuitarra().h), (10, 22));
    expect((mkSombrero().w, mkSombrero().h), (12, 8));
    expect((mkBolsa().w, mkBolsa().h), (10, 12));
    expect((mkCaja().w, mkCaja().h), (12, 10));
    expect((mkLibroMuralla().w, mkLibroMuralla().h), (10, 8));
    expect((mkGuagua().w, mkGuagua().h), (22, 10));
    expect((mkLejos1().w, mkLejos1().h), (4, 7));
    expect((mkLejos2().w, mkLejos2().h), (4, 7));
    expect(
      (
        mkDoorOpen(24, 28, const [206, 70, 64]).w,
        mkDoorOpen(24, 28, const [206, 70, 64]).h,
      ),
      (24, 28),
    );
  });

  test('every sprite in murallaSpritesSheet has opaque pixels', () {
    final sheet = murallaSpritesSheet();
    expect(sheet.length, greaterThanOrEqualTo(35));
    for (final (name, s) in sheet) {
      expect(_ink(s), greaterThan(0), reason: '$name has no drawn pixels');
    }
  });

  test('state variants differ visually', () {
    expect(_same(mkFarol(lit: true), mkFarol(lit: false)), isFalse);
    expect(_same(mkVelaMuralla(rings: 3), mkVelaMuralla(rings: 2)), isFalse);
    expect(_same(mkVelaMuralla(rings: 2), mkVelaMuralla(rings: 1)), isFalse);
    expect(
      _same(
        mkVelaMuralla(rings: 1, lit: true),
        mkVelaMuralla(rings: 0, lit: false),
      ),
      isFalse,
    );
    expect(
      _same(
        mkGuagua(openDoor: true, faces: 0),
        mkGuagua(openDoor: false, faces: 4),
      ),
      isFalse,
    );
    expect(_same(mkFotoSlide(3), mkFotoSlide(1)), isFalse);
    expect(_same(mkPaloma(flying: false), mkPaloma(flying: true)), isFalse);
    final baseMusico = mkPersona(MURALLA_WHO['musico1']!, 'idle', false, true);
    expect(_same(baseMusico, murallaWithHat(baseMusico)), isFalse);
  });
}
