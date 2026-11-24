// El quiosco's scene-specific sprites (lib/src/quiosco/quiosco_sprites.dart): dimensions match quiosco-sheet.json
// standins (dome 20 x 18, tower 22 x 28, box 16 x 12, limber cup 6 x 7, number candles 8 x 12, candle tray 28 x 4,
// frog tray 22 x 10, box thing 12 x 12), every sprite draws non-empty pixels, and distinct variants differ.
import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/src/quiosco/quiosco_sprites.dart';
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
  test('nino, nina, Beto crown, and señor chef hat draw cleanly', () {
    final nino = mkQuioscoPersona('nino', 'idle');
    final nina = mkQuioscoPersona('nina', 'idle');
    final betoPlain = mkQuioscoPersona('beto', 'sienta');
    final betoCrown = mkQuioscoPersona('beto', 'sienta', corona: true);
    final senorPlain = mkQuioscoPersona('senor', 'sienta');
    final senorHat = mkQuioscoPersona('senor', 'sienta', gorroCocinero: true);
    for (final s in [nino, nina, betoCrown, senorHat]) {
      expect(_ink(s), greaterThan(150));
    }
    expect(hashOf(nino.px), isNot(hashOf(nina.px)));
    expect(hashOf(betoCrown.px), isNot(hashOf(betoPlain.px)));
    expect(hashOf(senorHat.px), isNot(hashOf(senorPlain.px)));
  });

  test('story 66 dome, saucer quesito, and frog trays match sheet sizes', () {
    final domes = [
      mkCupula(3),
      mkCupula(2),
      mkCupula(1),
      mkCupula(0),
      mkCupula(0, abierta: true),
    ];
    for (final d in domes) {
      expect([d.w, d.h], [20, 18]);
      expect(_ink(d), greaterThan(40));
    }
    expect({for (final d in domes) hashOf(d.px)}, hasLength(domes.length));

    final trays = [
      mkBandejaRana(null),
      mkBandejaRana('cafe'),
      mkBandejaRana('jugo'),
      mkBandejaRana('leche'),
      mkBandejaRana('cafe', derramado: true),
    ];
    for (final t in trays) {
      expect([t.w, t.h], [22, 10]);
      expect(_ink(t), greaterThan(50));
    }
    expect({for (final t in trays) hashOf(t.px)}, hasLength(trays.length));

    expect(
      hashOf(mkQuesitoPlato().px),
      isNot(hashOf(mkQuesitoPlato(trozo: true).px)),
    );
  });

  test('story 67 box, all 7 items, and limbers match sheet sizes', () {
    final boxes = [
      mkCajaQuiosco('cerrada'),
      mkCajaQuiosco('abierta'),
      mkCajaQuiosco('vacia'),
    ];
    for (final b in boxes) {
      expect([b.w, b.h], [16, 12]);
      expect(_ink(b), greaterThan(80));
    }
    expect({for (final b in boxes) hashOf(b.px)}, hasLength(3));

    const cosas = [
      'libro',
      'gorro',
      'estetoscopio',
      'libretas',
      'gorra',
      'bulto',
      'delantal',
    ];
    final ch = <String>{};
    for (final k in cosas) {
      final s = mkCosa67(k);
      expect([s.w, s.h], [12, 12]);
      expect(_ink(s), greaterThan(30));
      ch.add(hashOf(s.px));
    }
    expect(ch, hasLength(cosas.length));

    for (final c in const ['rojo', 'amarillo', 'blanco']) {
      final f = mkLimber(c), m = mkLimber(c, derretido: true);
      expect([f.w, f.h], [6, 7]);
      expect([m.w, m.h], [6, 7]);
      expect(hashOf(f.px), isNot(hashOf(m.px)));
    }
  });

  test('story 68 tower, tray, all 12 number candles, and bizcochos', () {
    final towers = [
      mkTorre68(3),
      mkTorre68(3, vela5: true),
      mkTorre68(3, vela5: true, encendida: true),
      mkTorre68(2, vela5: true),
      mkTorre68(1, vela5: true, humo: true),
    ];
    for (final t in towers) {
      expect([t.w, t.h], [22, 28]);
      expect(_ink(t), greaterThan(120));
    }
    expect({for (final t in towers) hashOf(t.px)}, hasLength(towers.length));

    final tr = mkBandejaVelas();
    expect([tr.w, tr.h], [28, 4]);
    expect(_ink(tr), greaterThan(50));

    final candleHashes = <String>{};
    for (var n = 1; n <= 12; n++) {
      final v = mkVelaNumero(n, 'a');
      expect([v.w, v.h], [8, 12]);
      expect(_ink(v), greaterThan(45));
      candleHashes.add(hashOf(v.px));
    }
    expect(candleHashes, hasLength(12));

    expect(
      hashOf(mkBizcocho(vela: true).px),
      isNot(hashOf(mkBizcocho(roto: true).px)),
    );
    expect(hashOf(mkDedos(3).px), isNot(hashOf(mkDedos(5).px)));
  });

  test('the sprite sheet list has every sprite non-empty', () {
    final list = quioscoSpritesSheet();
    expect(list.length, greaterThanOrEqualTo(40));
    for (final (label, s) in list) {
      expect(_ink(s), greaterThan(10), reason: label);
    }
  });
}
