// Los regalos's own sprites (lib/src/regalos/regalos_sprites.dart): dimensions match regalos-sheet.json's spot boxes
// and regalos-preview.html's stand-ins, every sprite has drawn ink, and state variants differ visually.
import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/src/regalos/regalos_sprites.dart';
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
  test('preview-matching sprites keep regalos-sheet.json box dimensions', () {
    expect((mkCortina(half: true).w, mkCortina(half: true).h), (25, 49));
    expect((mkCortina(pegs: 3).w, mkCortina(pegs: 3).h), (49, 49));
    expect(
      (mkBizcocho(16, 12, net: true).w, mkBizcocho(16, 12, net: true).h),
      (16, 12),
    );
    expect((mkBizcocho(14, 14).w, mkBizcocho(14, 14).h), (14, 14));
    expect(
      (
        mkBizcocho(18, 18, candles: true).w,
        mkBizcocho(18, 18, candles: true).h,
      ),
      (18, 18),
    );
    expect((mkRegaloBox().w, mkRegaloBox().h), (14, 14));
    expect((mkFlores(12, 16).w, mkFlores(12, 16).h), (12, 16));
    expect((mkFlores(14, 14).w, mkFlores(14, 14).h), (14, 14));
    expect((mkCajaVelas().w, mkCajaVelas().h), (10, 8));
    expect(
      (mkFotoRegalos('3m', hung: true).w, mkFotoRegalos('3m', hung: true).h),
      (12, 12),
    );
    expect(
      (mkFotoRegalos('3m', hung: false).w, mkFotoRegalos('3m', hung: false).h),
      (11, 10),
    );
    expect((mkPaquete(14, 14).w, mkPaquete(14, 14).h), (14, 14));
    expect((mkPaquete(14, 12).w, mkPaquete(14, 12).h), (14, 12));
  });

  test('every sprite in regalosSpritesSheet has opaque pixels', () {
    final sheet = regalosSpritesSheet();
    expect(sheet.length, greaterThanOrEqualTo(55));
    for (final (name, s) in sheet) {
      expect(_ink(s), greaterThan(0), reason: '$name has no drawn pixels');
    }
  });

  test('state variants differ visually', () {
    expect(_same(mkCortina(pegs: 3), mkCortina(pegs: 2)), isFalse);
    expect(_same(mkCortina(pegs: 2), mkCortina(pegs: 1)), isFalse);
    expect(
      _same(mkCortina(pegs: 3), mkCortina(pegs: 3, shadow: true)),
      isFalse,
    );
    expect(_same(mkBizcocho(16, 12, net: true), mkBizcocho(16, 12)), isFalse);
    expect(
      _same(
        mkBizcocho(18, 18, candles: true, litCandles: 7),
        mkBizcocho(18, 18, candles: true, litCandles: 5, smoked: true),
      ),
      isFalse,
    );
    expect(
      _same(
        mkBizcocho(18, 18, candles: true, litCandles: 5, smoked: true),
        mkBizcocho(18, 18, candles: true, litCandles: 3, smoked: true),
      ),
      isFalse,
    );
    expect(
      _same(
        mkBizcocho(18, 18, candles: true, litCandles: 3, smoked: true),
        mkBizcocho(18, 18, candles: true, litCandles: 0, smoked: true),
      ),
      isFalse,
    );
    expect(_same(mkRegaloBox(), mkRegaloBox(shaken: true)), isFalse);
    expect(_same(mkCajaVelas(), mkCajaVelas(empty: true)), isFalse);
    expect(
      _same(mkFotoRegalos('3m', hung: true), mkFotoRegalos('7a', hung: true)),
      isFalse,
    );
    expect(
      _same(mkFotoRegalos('7m', hung: false), mkFotoRegalos('3a', hung: false)),
      isFalse,
    );
    expect(_same(mkPaquete(14, 14, tagged: true), mkPaquete(14, 14)), isFalse);
    expect(_same(mkPaquete(14, 12), mkPaquete(14, 12, torn: true)), isFalse);
    expect(
      _same(
        mkAbuelaRegalos('idle', false),
        mkAbuelaRegalos('idle', false, lista: true),
      ),
      isFalse,
    );
    expect(
      _same(
        mkAbuelaRegalos('idle', false),
        mkAbuelaRegalos('idle', false, fosforo: true),
      ),
      isFalse,
    );
    expect(
      _same(
        mkPersonaRegalos(FAM['hermana']!, 'idle', false),
        mkPersonaRegalos(FAM['hermana']!, 'idle', false, sombrero: true),
      ),
      isFalse,
    );
    expect(
      _same(
        mkPersonaRegalos(FAM['abuelo']!, 'idle', false),
        mkPersonaRegalos(FAM['abuelo']!, 'idle', false, abanico: true),
      ),
      isFalse,
    );
  });
}
