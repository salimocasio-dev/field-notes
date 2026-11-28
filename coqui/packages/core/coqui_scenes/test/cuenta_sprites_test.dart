// La cuenta's own sprites (lib/src/cuenta/cuenta_sprites.dart): dimensions match cuenta-sheet.json's spot boxes
// and cuenta-preview.html's stand-ins, every sprite has drawn ink, and state variants differ visually.
import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/src/cuenta/cuenta_sprites.dart';
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
  test('preview-matching sprites keep cuenta-sheet.json box dimensions', () {
    expect((mkCarrito().w, mkCarrito().h), (76, 22));
    expect((mkCopa().w, mkCopa().h), (8, 10));
    expect((mkFlanes().w, mkFlanes().h), (14, 8));
    expect((mkMantecado().w, mkMantecado().h), (12, 10));
    expect((mkTapa().w, mkTapa().h), (12, 10));
    expect((mkTapaGrande().w, mkTapaGrande().h), (28, 12));
    expect((mkMaquina().w, mkMaquina().h), (12, 10));
    expect((mkFrasco().w, mkFrasco().h), (10, 12));
    expect((mkCuentaSlip().w, mkCuentaSlip().h), (8, 10));
    expect((mkCuentaGrande(40).w, mkCuentaGrande(40).h), (24, 28));
  });

  test('every sprite in cuentaSpritesSheet has opaque pixels', () {
    final sheet = cuentaSpritesSheet();
    expect(sheet.length, greaterThanOrEqualTo(30));
    for (final (name, s) in sheet) {
      expect(_ink(s), greaterThan(0), reason: '$name has no drawn pixels');
    }
  });

  test('state variants differ visually', () {
    expect(_same(mkCopa(scoops: 0), mkCopa(scoops: 1)), isFalse);
    expect(_same(mkCopa(scoops: 1), mkCopa(scoops: 2)), isFalse);
    expect(_same(mkCopa(scoops: 2), mkCopa(scoops: 3)), isFalse);
    expect(_same(mkCopa(scoops: 2), mkCopa(scoops: 2, pool: true)), isFalse);
    expect(
      _same(mkCopa(scoops: 1, pool: true), mkCopa(scoops: 1, bigPool: true)),
      isFalse,
    );
    expect(_same(mkFlanes(wobble: false), mkFlanes(wobble: true)), isFalse);
    expect(
      _same(mkMantecado(scooped: false), mkMantecado(scooped: true)),
      isFalse,
    );
    expect(_same(mkMaquina(beep: false), mkMaquina(beep: true)), isFalse);
    expect(_same(mkFrasco(coins: 0), mkFrasco(coins: 1)), isFalse);
    expect(_same(mkFrasco(coins: 1), mkFrasco(coins: 2)), isFalse);
    expect(_same(mkFrasco(coins: 2), mkFrasco(coins: 3)), isFalse);
    expect(_same(mkFrasco(coins: 0), mkFrasco(bills: 1)), isFalse);
    expect(
      _same(mkFrasco(coins: 3), mkFrasco(coins: 3, tipped: true)),
      isFalse,
    );
    expect(_same(mkCuentaGrande(40), mkCuentaGrande(60)), isFalse);
    expect(
      _same(mkCuentaGrande(40, shine: false), mkCuentaGrande(40, shine: true)),
      isFalse,
    );
    expect(
      _same(mkGavetaAbierta(bills: false), mkGavetaAbierta(bills: true)),
      isFalse,
    );
  });

  test('CUENTA_WHO defines every cast outfit', () {
    for (final who in const [
      'mesera',
      'mesero',
      'cocinero',
      'abuelo',
      'abuelo_sin_gafas',
      'luis',
      'carmen',
      'senor',
      'senora',
      'joven',
      'mujer',
    ]) {
      expect(CUENTA_WHO.containsKey(who), isTrue, reason: 'missing $who');
    }
  });
}
