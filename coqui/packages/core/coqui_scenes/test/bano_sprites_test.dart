// El baño's own sprites (lib/src/bano/bano_sprites.dart): dimensions match bano-sheet.json's spot boxes and
// bano-preview.html's stand-ins, every sprite has drawn ink, state variants differ visually, and gesture overlays
// never widen a character's horizontal silhouette.
import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/src/bano/bano_sprites.dart';
import 'package:flutter_test/flutter_test.dart';

int _ink(Sprite s) {
  var n = 0;
  for (final p in s.px) {
    if (p >>> 24 != 0) n++;
  }
  return n;
}

(int, int) _xBounds(Sprite s) {
  var x0 = s.w, x1 = -1;
  for (var y = 0; y < s.h; y++) {
    for (var x = 0; x < s.w; x++) {
      if (s.px[y * s.w + x] >>> 24 == 0) continue;
      if (x < x0) x0 = x;
      if (x > x1) x1 = x;
    }
  }
  return (x0, x1);
}

bool _same(Sprite a, Sprite b) {
  if (a.w != b.w || a.h != b.h) return false;
  for (var i = 0; i < a.px.length; i++) {
    if (a.px[i] != b.px[i]) return false;
  }
  return true;
}

void main() {
  test('preview-matching sprites keep bano-sheet.json box dimensions', () {
    expect((mkJabon(3).w, mkJabon(3).h), (8, 5));
    expect((mkToalla('rojo').w, mkToalla('rojo').h), (12, 8));
    expect((mkTubo(4).w, mkTubo(4).h), (5, 9));
    expect((mkCepillito().w, mkCepillito().h), (6, 4));
    expect((mkCepillo().w, mkCepillo().h), (12, 6));
    expect((mkPeinilla().w, mkPeinilla().h), (12, 6));
    expect((mkToallaCab().w, mkToallaCab().h), (16, 10));
    expect((mkTabureteBano().w, mkTabureteBano().h), (12, 7));
    expect((mkBarraGauge().w, mkBarraGauge().h), (8, 3));
  });

  test('every sprite in banoSpritesSheet has opaque pixels', () {
    final sheet = banoSpritesSheet();
    expect(sheet.length, greaterThanOrEqualTo(30));
    for (final (name, s) in sheet) {
      expect(_ink(s), greaterThan(0), reason: '$name has no drawn pixels');
    }
  });

  test('state variants differ visually', () {
    expect(_same(mkJabon(3), mkJabon(2)), isFalse);
    expect(_same(mkJabon(2), mkJabon(1)), isFalse);
    expect(_same(mkToalla('rojo'), mkToalla('azul')), isFalse);
    expect(_same(mkToalla('blanco'), mkToalla('verde')), isFalse);
    expect(_same(mkTubo(4), mkTubo(2)), isFalse);
    expect(_same(mkTubo(2), mkTubo(1)), isFalse);
    expect(_same(mkCepillito(paste: 0), mkCepillito(paste: 1)), isFalse);
    expect(_same(mkCepillito(paste: 1), mkCepillito(paste: 3)), isFalse);
    expect(_same(mkCepillo(paste: true), mkCepillo(paste: false)), isFalse);
    expect(_same(mkEspumaSink(1), mkEspumaSink(3)), isFalse);
    expect(
      _same(mkBanoPerro(0, muddy: false), mkBanoPerro(0, muddy: true)),
      isFalse,
    );
    expect(
      _same(mkBanoCoqui(0, muddyFeet: true), mkBanoCoqui(0, foam: 3)),
      isFalse,
    );
  });

  test('pose overlays stay within person silhouette width', () {
    for (final id in const ['abuela', 'abuelo', 'luis', 'carmen']) {
      final base = _xBounds(mkBanoPersona(id, 'idle'));
      for (final variant in [
        mkBanoPersona(id, 'idle', mudHands: true, mudFace: true),
        mkBanoPersona(id, 'idle', shine: true, teeth: true),
        mkBanoPersona(id, 'idle', flatHair: true, pasteHair: true),
        mkBanoPersona(id, 'idle', combMouth: true),
      ]) {
        final b = _xBounds(variant);
        expect(b.$1, greaterThanOrEqualTo(base.$1), reason: '$id left bound');
        expect(b.$2, lessThanOrEqualTo(base.$2), reason: '$id right bound');
      }
    }
  });
}
