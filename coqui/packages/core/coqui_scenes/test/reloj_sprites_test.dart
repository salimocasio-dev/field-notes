// El reloj's scene-specific sprites (lib/src/reloj/reloj_sprites.dart): dimensions match reloj-sheet.json
// (time cards 22 x 22, plate 14 x 7, cage 20 x 22, prizes 16 x 16, numeral squares 14 x 14, bean 6 x 4),
// every sprite draws non-empty pixels, and distinct variants (12 time cards, 3 prizes, 3 wooden figures,
// 10 bingo balls, 5 numeral squares, raw/golden/black plates, two frames of flame/smoke/spring/cage) differ.
import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/src/reloj/reloj_sprites.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/hash.dart';

int _ink(Sprite s) {
  var n = 0;
  for (final c in s.px) {
    if (c >>> 24 != 0) n++;
  }
  return n;
}

void main() {
  test('clock hands turn cleanly around their pivot', () {
    final angles = [0.0, 45.0, 90.0, 150.0, 180.0, 270.0];
    final longHashes = <String>{};
    final shortHashes = <String>{};
    for (final deg in angles) {
      final lg = mkManecilla(19, deg, largo: true);
      final sh = mkManecilla(12, deg, largo: false);
      expect(lg.ax, 22);
      expect(lg.ay, 22);
      expect(sh.ax, 15);
      expect(sh.ay, 15);
      expect(_ink(lg.s), greaterThan(30));
      expect(_ink(sh.s), greaterThan(20));
      longHashes.add(hashOf(lg.s.px));
      shortHashes.add(hashOf(sh.s.px));
    }
    expect(longHashes, hasLength(angles.length));
    expect(shortHashes, hasLength(angles.length));
  });

  test('all 12 time cards are 22 x 22 and distinct', () {
    final hashes = <String>{};
    for (var h = 1; h <= 12; h++) {
      final s = mkCartaHora(h);
      expect([s.w, s.h], [22, 22]);
      expect(_ink(s), 22 * 22);
      hashes.add(hashOf(s.px));
    }
    expect(hashes, hasLength(12));
  });

  test('pastelillos, plates, fryer effects and tower props draw cleanly', () {
    final plates = [
      mkPlatoPastelillos(raw: 3),
      mkPlatoPastelillos(raw: 2),
      mkPlatoPastelillos(raw: 1),
      mkPlatoPastelillos(raw: 0, golden: 3),
      mkPlatoPastelillos(raw: 0, golden: 2, black: 1),
      mkPlatoPastelillos(raw: 0, golden: 1, black: 2),
    ];
    for (final p in plates) {
      expect([p.w, p.h], [14, 7]);
      expect(_ink(p), greaterThan(20));
    }
    expect({for (final p in plates) hashOf(p.px)}, hasLength(plates.length));

    final pieces = [
      mkPastelillo('raw'),
      mkPastelillo('golden'),
      mkPastelillo('black'),
      mkPastelillo('golden', big: true),
      mkHumo(0),
      mkHumo(1),
      mkLlama(0),
      mkLlama(1),
      mkCampanaOnda(0),
      mkCampanaOnda(1),
      mkAceitera(),
      mkLlaveReloj(),
      mkTapaAbierta(),
      mkResorte(0),
      mkResorte(1),
      mkPostigoAtascado(),
    ];
    for (final s in pieces) {
      expect(_ink(s), greaterThan(10));
    }
    expect(hashOf(mkHumo(0).px), isNot(hashOf(mkHumo(1).px)));
    expect(hashOf(mkLlama(0).px), isNot(hashOf(mkLlama(1).px)));
    expect(hashOf(mkResorte(0).px), isNot(hashOf(mkResorte(1).px)));
  });

  test('the three wooden figures are distinct and fit inside puertita', () {
    final figs = [
      for (final who in const ['gallo', 'guitarra', 'coqui'])
        mkFiguraReloj(who),
    ];
    for (final s in figs) {
      expect(s.w, lessThanOrEqualTo(19));
      expect(s.h, lessThanOrEqualTo(14));
      expect(_ink(s), greaterThan(25));
    }
    expect({for (final s in figs) hashOf(s.px)}, hasLength(3));
  });

  test(
    'bingo cage, balls, prizes, numeral squares and bean match sheet sizes',
    () {
      final j0 = mkJaula(spin: 0), j1 = mkJaula(spin: 1);
      expect([j0.w, j0.h], [20, 22]);
      expect([j1.w, j1.h], [20, 22]);
      expect(hashOf(j0.px), isNot(hashOf(j1.px)));

      final balls = {
        for (var n = 10; n <= 100; n += 10) hashOf(mkBolaBingo(n).px),
      };
      expect(balls, hasLength(10));

      final prizes = [for (var k = 1; k <= 3; k++) mkPremio(k)];
      for (final p in prizes) {
        expect([p.w, p.h], [16, 16]);
        expect(_ink(p), greaterThan(50));
      }
      expect({for (final p in prizes) hashOf(p.px)}, hasLength(3));

      final squares = [
        for (final n in const [40, 60, 80, 90, 100]) mkCuadroBingo(n),
      ];
      for (final sq in squares) {
        expect([sq.w, sq.h], [14, 14]);
        expect(_ink(sq), 14 * 14);
      }
      expect({for (final sq in squares) hashOf(sq.px)}, hasLength(5));

      final bean = mkFrijol();
      expect([bean.w, bean.h], [6, 4]);
      expect(_ink(bean), greaterThan(8));

      final smallCard = mkCartonChico(3);
      expect(_ink(smallCard), greaterThan(20));
    },
  );
}
