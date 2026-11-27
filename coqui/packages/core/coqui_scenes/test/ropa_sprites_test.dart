// La ropa's scene-specific sprites (lib/src/ropa/ropa_sprites.dart): dimensions match ropa-sheet.json and
// ropa-preview.html (clothes on line 16x16, things afloat 14x9, shoes 24x8, plate 16x10, crate 12x8, bag 14x10,
// driver 14x14, back-facing look-alike children <= 24 px wide), every sprite draws non-empty pixels, and distinct
// variants differ.
import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/src/ropa/ropa_sprites.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/hash.dart';

int _ink(Sprite s) {
  var n = 0;
  for (final c in s.px) {
    if (c >>> 24 != 0) n++;
  }
  return n;
}

(int, int) _xSpan(Sprite s) {
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

void main() {
  test('preview-matching sprites match ropa-sheet.json dimensions', () {
    for (final s in [
      mkCamisaCuerda(),
      mkPantalonCuerda(),
      mkVestidoCuerda(),
      mkToallaCuerda(),
      mkToallaCuerda(mojada: true),
      mkSombreroCuerda(),
      mkChancletasCuerda(),
      mkGafasCuerda(),
      mkTrajeCuerda(),
    ]) {
      expect([s.w, s.h], [16, 16]);
      expect(_ink(s), greaterThan(25));
    }
    expect(
      hashOf(mkToallaCuerda().px),
      isNot(hashOf(mkToallaCuerda(mojada: true).px)),
    );

    for (final s in [
      mkSombreroAgua(),
      mkChancletasAgua(),
      mkGafasAgua(),
      mkTrajeAgua(),
      mkToallaAgua(),
    ]) {
      expect([s.w, s.h], [14, 9]);
      expect(_ink(s), greaterThan(20));
    }

    expect([mkZapatos().w, mkZapatos().h], [24, 8]);
    expect(_ink(mkZapatos()), greaterThan(40));

    final plates = [mkPlato(0), mkPlato(1), mkPlato(2), mkPlato(3)];
    for (final s in plates) {
      expect([s.w, s.h], [16, 10]);
      expect(_ink(s), greaterThan(30));
    }
    expect({for (final s in plates) hashOf(s.px)}, hasLength(4));

    expect([mkCajaRopa().w, mkCajaRopa().h], [12, 8]);
    expect([mkBolsaRopa(0).w, mkBolsaRopa(0).h], [14, 10]);
    expect(hashOf(mkBolsaRopa(0).px), isNot(hashOf(mkBolsaRopa(3).px)));

    final drivers = [
      mkChofer(fingers: 3),
      mkChofer(fingers: 2),
      mkChofer(fingers: 1),
      mkChofer(fingers: 0, smiling: true),
      mkChofer(fingers: 2, horn: true),
    ];
    for (final s in drivers) {
      expect([s.w, s.h], [14, 14]);
      expect(_ink(s), greaterThan(40));
    }
    expect({for (final s in drivers) hashOf(s.px)}, hasLength(5));
  });

  test('story 78, 79 and 80 Needs sprites are distinct, non-empty, and fit width limits', () {
    expect(_ink(mkPanoPlato()), greaterThan(20));
    expect(_ink(mkPiezaCaida('camisa')), greaterThan(20));
    expect(_ink(mkNubeArena(0)), greaterThan(10));
    expect(_ink(mkGaviotaRopa(0)), greaterThan(15));
    expect(_ink(mkOlaRopa(0)), greaterThan(200));
    expect(_ink(mkCoquiToallaRopa()), greaterThan(120));
    expect(
      hashOf(mkAbuelaManos(false).px),
      isNot(hashOf(mkAbuelaSombrero(false).px)),
    );
    expect(
      hashOf(mkNinoPlaya('luis', toalla: true).px),
      isNot(hashOf(mkNinoRopa('luis', 'idle', false).px)),
    );
    expect(
      hashOf(mkNinoPlaya('carmen').px),
      isNot(hashOf(mkNinoRopa('carmen', 'idle', false).px)),
    );
    // All four look-alike children from behind fit within 24 px centred on PX (24) -> [12..35].
    for (final tipo in const ['chico', 'chica']) {
      for (final que in [
        'sombrero',
        if (tipo == 'chico') 'camisa' else 'vestido',
      ]) {
        final hashes = <String>{};
        for (var phase = 0; phase <= 3; phase++) {
          final s = mkNinoAtras(tipo, que, phase);
          final (x0, x1) = _xSpan(s);
          expect(
            x0 >= 12 && x1 <= 35,
            isTrue,
            reason: '$tipo/$que phase $phase span [$x0..$x1] exceeds 24 px',
          );
          hashes.add(hashOf(s.px));
        }
        expect(hashes, hasLength(4));
      }
    }
    expect(_ink(mkNinoExtranoRie('chico')), greaterThan(200));
    expect(_ink(mkNinoExtranoRie('chica')), greaterThan(200));
    expect(_ink(mkPerroSombrero()), greaterThan(200));
  });

  test('the sprite sheet list has every sprite non-empty', () {
    final list = ropaSpritesSheet();
    expect(list.length, greaterThanOrEqualTo(40));
    for (final (label, s) in list) {
      expect(_ink(s), greaterThan(10), reason: label);
    }
  });
}
