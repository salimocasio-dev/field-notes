// El colmado's cast (lib/src/colmado/colmado_cast.dart): every sprite it draws is there and has its size, and the people
// stand as the sheets' rules.anchor says a person of mkPersona stands (mostrador-sheet.json rules.anchor: 53 rows drawn
// standing, the lowest drawn row 54 of a 56-row canvas; 46 sitting, of a 49-row canvas; the middle column 24).
import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/src/colmado/colmado_cast.dart';
import 'package:flutter_test/flutter_test.dart';

int _top(Sprite s) {
  for (var y = 0; y < s.h; y++) {
    for (var x = 0; x < s.w; x++) {
      if (s.px[y * s.w + x] >>> 24 != 0) return y;
    }
  }
  return s.h;
}

void main() {
  test('every sprite of the cast draws something', () {
    final all = colmadoCastSheet();
    expect(all.length, greaterThan(40));
    for (final (name, s) in all) {
      expect(s.px.any((c) => c >>> 24 != 0), isTrue, reason: name);
    }
  });

  test('don Pepe stands and sits as a person of mkPersona (rules.anchor)', () {
    for (final p in PEPE_POSES) {
      final s = mkPepe(p);
      expect(s.w, 48, reason: p);
      final sits = p == 'sentado' || p.startsWith('abanico');
      expect(s.h, sits ? 49 : 56, reason: p);
      expect(inkBottom(s), sits ? 48 : 55, reason: p);
      if (!p.startsWith('abanico')) {
        expect(inkBottom(s) - _top(s), sits ? 46 : 53, reason: p);
      }
    }
  });

  test('the three children are three, not the family\'s, and stand as children of mkPersona', () {
    expect(NINOS, hasLength(3));
    for (var i = 0; i < 3; i++) {
      expect(NINOS[i].nino, isTrue);
      expect(identical(NINOS[i], FAM['hermano']), isFalse);
      expect(identical(NINOS[i], FAM['hermana']), isFalse);
      final s = mkNino(i, 'idle');
      expect(s.w, 48);
      expect(inkBottom(s), s.h - 1);
    }
  });

  test('the goat, the coins, the bags and the nine goods', () {
    for (final p in const ['de_pie', 'cuello', 'come', 'mastica']) {
      final s = mkCabra(p, 0);
      expect([s.w, s.h], [36, 28], reason: p);
      expect(inkBottom(s), lessThanOrEqualTo(28), reason: p);
    }
    expect(mkCabra('mastica', 0).px, isNot(mkCabra('mastica', 1).px));
    expect([mkMoneda().w, mkMoneda().h], [7, 7]);
    expect(GENEROS, hasLength(9));
    for (final k in GENEROS) {
      final s = mkGenero(k);
      expect(s.w, lessThanOrEqualTo(16), reason: k);
      expect(s.h, lessThanOrEqualTo(14), reason: k);
    }
    expect(() => mkGenero('nada'), throwsArgumentError);
  });
}
