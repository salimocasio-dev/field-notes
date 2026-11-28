// La comida's own sprites (lib/src/comida/comida_sprites.dart): dimensions match comida-sheet.json's spot boxes and
// comida-preview.html's stand-ins, every sprite has drawn ink, state variants differ visually, and gesture overlays
// never widen a sitting person's horizontal silhouette.
import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/src/comida/comida_sprites.dart';
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
  test('preview-matching sprites keep comida-sheet.json box dimensions', () {
    expect((mkPlatillo('salado').w, mkPlatillo('salado').h), (14, 8));
    expect((mkPlatillo('dulce').w, mkPlatillo('dulce').h), (14, 8));
    expect((mkPlatillo('picante').w, mkPlatillo('picante').h), (14, 8));
    expect((mkJarra(3).w, mkJarra(3).h), (12, 18));
    expect((mkVasos(3).w, mkVasos(3).h), (26, 10));
    expect((mkSal().w, mkSal().h), (10, 12));
    expect((mkAzucar().w, mkAzucar().h), (10, 12));
    expect((mkHielo().w, mkHielo().h), (10, 12));
    expect((mkServilletas().w, mkServilletas().h), (10, 12));
    expect((mkSopa().w, mkSopa().h), (12, 8));
    expect((mkEnsalada().w, mkEnsalada().h), (12, 8));
    expect((mkTazon(3).w, mkTazon(3).h), (10, 8));
    expect((mkPlatoPerro().w, mkPlatoPerro().h), (12, 8));
    expect(
      (mkPerroComida('sleep', 0).w, mkPerroComida('sleep', 0).h),
      (30, 22),
    );
  });

  test('every sprite in comidaSpritesSheet has opaque pixels', () {
    final sheet = comidaSpritesSheet();
    expect(sheet.length, greaterThanOrEqualTo(45));
    for (final (name, s) in sheet) {
      expect(_ink(s), greaterThan(0), reason: '$name has no drawn pixels');
    }
  });

  test('state variants differ visually', () {
    expect(_same(mkPlatillo('salado'), mkPlatillo('dulce')), isFalse);
    expect(_same(mkPlatillo('dulce'), mkPlatillo('picante')), isFalse);
    expect(_same(mkJarra(3), mkJarra(2)), isFalse);
    expect(_same(mkJarra(2), mkJarra(1)), isFalse);
    expect(_same(mkJarra(1), mkJarra(0)), isFalse);
    expect(_same(mkVasos(3), mkVasos(2)), isFalse);
    expect(_same(mkVasos(3), mkVasos(3, finalMode: true)), isFalse);
    expect(
      _same(mkVasos(2, finalMode: true), mkVasos(1, finalMode: true)),
      isFalse,
    );
    expect(_same(mkSopa(caliente: true), mkSopa(caliente: false)), isFalse);
    expect(_same(mkTazon(0), mkTazon(1)), isFalse);
    expect(_same(mkTazon(1), mkTazon(2)), isFalse);
    expect(_same(mkTazon(2), mkTazon(3)), isFalse);
    expect(
      _same(mkPlatoPerro(lleno: false), mkPlatoPerro(lleno: true)),
      isFalse,
    );
    expect(_same(mkPlatoArroz('normal'), mkPlatoArroz('mas')), isFalse);
    expect(_same(mkPlatoArroz('normal'), mkPlatoArroz('menos')), isFalse);
    expect(_same(mkPerroComida('sit', 0), mkPerroComida('sleep', 0)), isFalse);
  });

  test('seated gesture overlays never widen silhouette bounds', () {
    for (final id in const ['abuela', 'abuelo', 'luis', 'carmen']) {
      final base = _xBounds(mkComidaPersona(id, 'idle', sent: true));
      for (final variant in [
        mkComidaPersona(id, 'idle', sent: true, ojos: true),
        mkComidaPersona(id, 'idle', sent: true, cara: true, rojo: true),
        mkComidaPersona(id, 'idle', sent: true, cuchara: true),
        mkComidaPersona(id, 'idle', sent: true, tapa: true),
      ]) {
        final b = _xBounds(variant);
        expect(b.$1, greaterThanOrEqualTo(base.$1), reason: '$id left bound');
        expect(b.$2, lessThanOrEqualTo(base.$2), reason: '$id right bound');
      }
    }
  });
}
