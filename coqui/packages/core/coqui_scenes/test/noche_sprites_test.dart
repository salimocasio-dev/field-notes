// La noche's own sprites (lib/src/noche/noche_sprites.dart): dimensions match noche-sheet.json and
// noche-preview.html's stand-ins, every sprite has drawn ink, and state variants differ visually.
import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/src/noche/noche_sprites.dart';
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
  test('preview-matching sprites keep noche-sheet.json box dimensions', () {
    expect((mkJugo().w, mkJugo().h), (10, 10));
    expect((mkFlan().w, mkFlan().h), (10, 10));
    expect((mkQueso().w, mkQueso().h), (10, 10));
    expect((mkFrutas().w, mkFrutas().h), (10, 10));
    expect((mkVelaNoche().w, mkVelaNoche().h), (6, 14));
    expect((mkBufanda().w, mkBufanda().h), (12, 8));
    expect((mkLana().w, mkLana().h), (8, 8));
    expect((mkLibroNoche().w, mkLibroNoche().h), (12, 8));
  });

  test('every sprite in nocheSpritesSheet has opaque pixels', () {
    final sheet = nocheSpritesSheet();
    expect(sheet.length, greaterThanOrEqualTo(35));
    for (final (name, s) in sheet) {
      expect(_ink(s), greaterThan(0), reason: '$name has no drawn pixels');
    }
  });

  test('state variants differ visually', () {
    expect(_same(mkVelaNoche(len: 3), mkVelaNoche(len: 2)), isFalse);
    expect(_same(mkVelaNoche(len: 2), mkVelaNoche(len: 1)), isFalse);
    expect(_same(mkVelaNoche(lit: true), mkVelaNoche(lit: false)), isFalse);
    expect(_same(mkBufanda(stripes: 3), mkBufanda(stripes: 2)), isFalse);
    expect(_same(mkBufanda(stripes: 2), mkBufanda(stripes: 1)), isFalse);
    expect(
      _same(mkBufandaCuello(stripes: 3), mkBufandaCuello(stripes: 1)),
      isFalse,
    );
    expect(_same(mkLibroNoche(pages: 3), mkLibroNoche(pages: 2)), isFalse);
    expect(_same(mkLibroNoche(pages: 2), mkLibroNoche(pages: 1)), isFalse);
    expect(_same(mkLana(rolling: false), mkLana(rolling: true)), isFalse);
    expect(_same(mkManosCue(clean: false), mkManosCue(clean: true)), isFalse);
    expect(_same(mkRelojHands(hora: 8), mkRelojHands(hora: 3)), isFalse);
  });

  test('lying-in-bed sprite clips to footY and includes blanket', () {
    final luis = mkLyingChild(
      who: NOCHE_WHO['luis_pijama']!,
      sx: 34,
      sy: 20,
      footY: 51,
      blanketW: 32,
      blanketCenterX: 46,
      blanketColour: const [236, 190, 110],
    );
    expect(luis.w, 100);
    expect(luis.h, 32);
    expect(_ink(luis), greaterThan(100));
  });

  test('NOCHE_WHO defines every cast outfit', () {
    for (final who in const [
      'abuelo',
      'luis',
      'carmen',
      'luis_pijama',
      'carmen_pijama',
    ]) {
      expect(NOCHE_WHO.containsKey(who), isTrue, reason: 'missing $who');
    }
  });
}
