// El cielo's own sprites (lib/src/cielo/cielo_sprites.dart): dimensions match cielo-sheet.json's spot boxes and
// cielo-preview.html's stand-ins, every sprite has drawn ink, and state variants differ visually.
import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/src/cielo/cielo_sprites.dart';
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
  test('preview-matching sprites keep cielo-sheet.json box dimensions', () {
    expect((mkRadio().w, mkRadio().h), (12, 9));
    expect((mkVela().w, mkVela().h), (6, 10));
    expect((mkTapaPuesta().w, mkTapaPuesta().h), (26, 18));
    expect((mkTapaSuelo().w, mkTapaSuelo().h), (18, 16));
    expect((mkChal().w, mkChal().h), (10, 8));
    expect((mkBandeja(3).w, mkBandeja(3).h), (20, 10));
    expect((mkSombrillaShut().w, mkSombrillaShut().h), (8, 44));
    expect((mkSombrillaOpen().w, mkSombrillaOpen().h), (64, 60));
    expect((mkChiringa().w, mkChiringa().h), (20, 12));
    expect((mkBolaCielo().w, mkBolaCielo().h), (9, 9));
    expect((mkTelescopio().w, mkTelescopio().h), (14, 22));
    expect((mkVisor('luna').w, mkVisor('luna').h), (28, 28));
  });

  test('every sprite in cieloSpritesSheet has opaque pixels', () {
    final sheet = cieloSpritesSheet();
    expect(sheet.length, greaterThanOrEqualTo(35));
    for (final (name, s) in sheet) {
      expect(_ink(s), greaterThan(0), reason: '$name has no drawn pixels');
    }
  });

  test('state variants differ visually', () {
    expect(_same(mkVela(lit: true), mkVela(lit: false)), isFalse);
    expect(_same(mkVela(lit: true), mkVela(lit: true, lean: true)), isFalse);
    expect(_same(mkBandeja(3), mkBandeja(2)), isFalse);
    expect(_same(mkBandeja(2), mkBandeja(1)), isFalse);
    expect(_same(mkBandeja(1), mkBandeja(1, finalMode: true)), isFalse);
    expect(
      _same(mkTelescopio(dir: 'luna'), mkTelescopio(dir: 'estrella')),
      isFalse,
    );
    expect(_same(mkVisor('luna'), mkVisor('estrella')), isFalse);
    expect(_same(mkVisor('luna'), mkVisor('luna', cae: true)), isFalse);
    expect(
      _same(mkRadioBurbuja(sol: false), mkRadioBurbuja(sol: true)),
      isFalse,
    );
  });

  test('glass dome has transparent interior so candles show through', () {
    final dome = mkTapaPuesta();
    // Centre interior pixel must be transparent (alpha 0)
    expect(dome.px[12 * dome.w + 13] >>> 24, 0);
    // No base row across the bottom centre
    expect(dome.px[(dome.h - 1) * dome.w + 13] >>> 24, 0);
  });
}
