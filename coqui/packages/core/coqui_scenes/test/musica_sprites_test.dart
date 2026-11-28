// La música's own sprites (lib/src/musica/musica_sprites.dart): dimensions match musica-sheet.json's spot boxes
// and musica-preview.html's stand-ins, every sprite has drawn ink, state variants differ visually, and expression
// overlays keep horizontal silhouette bounds.
import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/src/musica/musica_sprites.dart';
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
  test('preview-matching sprites keep musica-sheet.json box dimensions', () {
    expect((mkGuitarra().w, mkGuitarra().h), (12, 22));
    expect((mkTambor().w, mkTambor().h), (12, 14));
    expect((mkMicrofono().w, mkMicrofono().h), (6, 28));
    expect((mkNotaPapel().w, mkNotaPapel().h), (14, 14));
    expect((mkGuitarraH().w, mkGuitarraH().h), (22, 8));
    expect((mkCamara().w, mkCamara().h), (10, 8));
  });

  test('every sprite in musicaSpritesSheet has opaque pixels', () {
    final sheet = musicaSpritesSheet();
    expect(sheet.length, greaterThanOrEqualTo(30));
    for (final (name, s) in sheet) {
      expect(_ink(s), greaterThan(0), reason: '$name has no drawn pixels');
    }
  });

  test('state variants differ visually', () {
    expect(_same(mkMicrofono('up'), mkMicrofono('low')), isFalse);
    expect(_same(mkNotaPapel(lit: true), mkNotaPapel(lit: false)), isFalse);
    expect(_same(mkHojasMusica(1), mkHojasMusica(3)), isFalse);
    expect(_same(mkNotasFloat(kind: 0), mkNotasFloat(kind: 2)), isFalse);
    expect(_same(mkFotoPapel(bad: false), mkFotoPapel(bad: true)), isFalse);
    expect(
      _same(
        mkMusicaPersona('musico1', 'idle', sent: true, eyesShut: false),
        mkMusicaPersona('musico1', 'idle', sent: true, eyesShut: true),
      ),
      isFalse,
    );
  });

  test('non-fan overlays stay within person silhouette width', () {
    for (final id in const [
      'abuelo',
      'luis',
      'carmen',
      'senor',
      'senora',
      'joven',
      'mujer',
      'hombre',
    ]) {
      final base = _xBounds(mkMusicaPersona(id, 'idle'));
      for (final variant in [
        mkMusicaPersona(id, 'idle', laugh: true),
        mkMusicaPersona(id, 'idle', yawn: true),
        mkMusicaPersona(id, 'idle', eat: true),
        mkMusicaPersona(id, 'idle', coverEars: true),
      ]) {
        final b = _xBounds(variant);
        expect(b.$1, greaterThanOrEqualTo(base.$1), reason: '$id left bound');
        expect(b.$2, lessThanOrEqualTo(base.$2), reason: '$id right bound');
      }
    }
  });
}
