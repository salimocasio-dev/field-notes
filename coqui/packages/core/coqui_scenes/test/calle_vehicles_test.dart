// La calle's vehicle sprites (lib/src/calle/calle_vehicles.dart) against the JavaScript's bake of calle-base.js
// `vehicle` (tool/make_calle_vehicles_ref.mjs): every look (the red car, the blue car and the guagua in both headings,
// the guagua with each of its three roof pictures), plain and under La esquina's afternoon light, has the JavaScript's
// box, floor point, pixels and depths (equal hashes: 0 pixels differ). The new looks (a door open, a window down) are
// the plain look with only their own part drawn over it; driving moves a vehicle along its lane and stops it on its
// point; the composition puts a person in front of a vehicle over it and one behind it under it.
import 'dart:convert';
import 'dart:typed_data';

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/src/calle/calle_vehicles.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fixtures/calle_vehicles_refs.dart';
import 'support/hash.dart';

void main() {
  final refs = (jsonDecode(calleVehiclesRefs) as List)
      .cast<Map<String, dynamic>>();
  const tarde = ([1.0, .93, .84], [10.0, 2.0, -8.0]);

  test('every look of the four scenes is in the reference', () {
    expect(refs.length, 2 * (3 * 2 + 3 * 2));
  });

  for (final r in refs) {
    final kind = r['kind'] as String,
        heading = r['heading'] as String,
        board = r['board'] as String?,
        light = r['light'] as String?;
    test(
      '$kind $heading ${board ?? ''} ${light ?? ''}: the JavaScript\'s picture',
      () {
        var v = vehicleSprite(kind, heading, board: board);
        if (light == 'tarde') v = litVehicle(v, tarde.$1, tarde.$2);
        final p = r['box'] as List;
        expect([v.s.w, v.s.h], [p[2], p[3]]);
        expect([v.ax, v.ay], [r['ax'], r['ay']]);
        expect(v.s.px.where((c) => c != 0).length, r['n']);
        expect(hashOf(v.s.px), r['pix']);
        expect(hashOf(v.z), r['z']);
      },
    );
  }

  test('a new look changes only its own part of the plain picture', () {
    for (final (k, look) in const [
      ('guagua', 'puerta'),
      ('carro', 'ventana'),
      ('azul', 'puerta'),
    ]) {
      for (final h in VEHICLE_HEADINGS) {
        final a = vehicleSprite(k, h), b = vehicleSprite(k, h, look: look);
        expect([b.s.w, b.s.h, b.ax, b.ay], [a.s.w, a.s.h, a.ax, a.ay]);
        var changed = 0;
        for (var i = 0; i < a.s.px.length; i++) {
          if (a.s.px[i] != b.s.px[i]) changed++;
        }
        expect(changed, greaterThan(10), reason: '$k $h $look');
        expect(changed, lessThan(a.s.px.length ~/ 5), reason: '$k $h $look');
      }
    }
    final w = vehicleSprite('carro', 'i', look: 'ventana').window!;
    expect(w.where((m) => m == 1).length, greaterThan(20));
  });

  test('a vehicle drives along its lane and stops on its point', () async {
    final v = <String, dynamic>{'x': 9.5, 'y': 4.8};
    final xs = <double>[];
    await drive(v, .7, () async => xs.add(v['x'] as double));
    expect(v['x'], .7);
    for (var i = 1; i < xs.length; i++) {
      expect(xs[i], lessThan(xs[i - 1]));
    }
    expect(xs.length, inInclusiveRange(20, 60));
  });

  test(
    'a person in front of a vehicle is drawn over it, one behind it is not',
    () {
      final e = PpEngine(
        w: 240,
        h: 216,
        s: 26,
        originX: 30,
        originY: -8,
        shadowX: .9,
        shadowY: -.1,
      );
      final v = vehicleSprite('guagua', 'i');
      final at = placeVehicle(e, v, 4.5, 4.8);
      final layer = Uint32List(240 * 216), lz = Float32List(240 * 216);
      lz.fillRange(0, lz.length, -1e9);
      final isV = Uint8List(240 * 216);
      putVehicle(v, at.left, at.top, at.d, layer, lz, isV, null);
      // a pixel of the guagua's side, 20 rows over its floor's middle
      final i = (at.sy - 20) * 240 + at.sx;
      expect(isV[i], 1);
      double plane(num x, num y) {
        final p = e.project(x, y, 0);
        return SceneFront.depthAt(p.d, p.sy, at.sy - 20, e.S);
      }

      expect(personOver(i, plane(4.5, 6.5), .3, lz, isV), isTrue);
      expect(personOver(i, plane(4.5, 2.8), .3, lz, isV), isFalse);
    },
  );
}
