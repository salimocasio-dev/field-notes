// La calle's cast (lib/src/calle/calle_cast.dart): every sprite it draws is there and draws something, the people
// stand as the sheets' rules.anchor says a person of mkPersona stands (esquina-sheet.json rules.anchor: the middle column
// 24, the feet's bottom edge; abuela's column 30), and the rider's sprite has the bicycle under the hips.
import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/src/calle/calle_cast.dart';
import 'package:coqui_scenes/src/colmado/colmado_cast.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('every sprite of the cast draws something', () {
    final all = calleCastSheet();
    expect(all.length, greaterThan(40));
    for (final (name, s) in all) {
      expect(s.px.any((c) => c >>> 24 != 0), isTrue, reason: name);
    }
  });

  test('the obrero stands and sits as a person of mkPersona, his helmet on his head', () {
    for (final p in OBRERO_POSES) {
      final s = mkObrero(p);
      expect(s.w, 48, reason: p);
      final sits = p == 'sentado' || p == 'bebe' || p == 'banderas_sentado';
      final up = p.startsWith('paleta') ? 4 : 0;
      expect(s.h, (sits ? 49 : 56) + up, reason: p);
      expect(inkBottom(s), (sits ? 48 : 55) + up, reason: p);
    }
    // the helmet: yellow over the head's top rows
    final s = mkObrero('idle');
    expect(s.px[6 * 48 + 24], RP.yel[2]);
  });

  test('everybody of the place by key, anchored on the feet', () {
    for (final id in const [
      'abuela',
      'mama',
      'papa',
      'luis',
      'carmen',
      'pepe',
      'senora',
      'senor',
      'obrero',
    ]) {
      for (final pose in const ['idle', 'saluda0', 'saluda1', 'mano']) {
        final a = callePerson(id, pose);
        expect(a.ax, id == 'abuela' ? 30 : PX, reason: '$id $pose');
        expect(a.ay, inkBottom(a.s), reason: '$id $pose');
      }
    }
  });

  test('the bicycle, alone, ridden, pushed; the cones; the bucket', () {
    final b = mkBici();
    expect([b.w, b.h], [32, 19]);
    final r = mkCiclista(FAM['hermano']!), g = mkCiclista(FAM['papa']!);
    expect(r.w, 48);
    expect(inkBottom(r), r.h);
    expect(inkBottom(g), g.h);
    expect(mkBiciEmpujada(FAM['hermano']!).w, 72);
    expect([mkCono().w, mkCono().h], [13, 15]);
    expect([mkCono(true).w, mkCono(true).h], [17, 11]);
    expect([mkCubo().w, mkCubo().h], [14, 9]);
    expect(mirrorSprite(mirrorSprite(b)).px, b.px);
  });
}
