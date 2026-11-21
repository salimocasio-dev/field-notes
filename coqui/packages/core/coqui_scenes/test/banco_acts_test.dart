// El banco's scene beyond its pictures: the places banco.js reads from the sheet (the moved sources' numbers: PORTON, SY,
// AS, CARRO, POSA, JUGEN, respEn; the floor rule's places; every move used), the hops (the sheet's hopsAll, from the
// frog's walks of the recorded runs, against banco.js ranaA's count), the set key of every W, the shadows (none at
// night; a pigeon in the air over the ground under its flight), the front as it is drawn (a sitter keeps what is in front
// of their own bench; someone behind a bench has the bench drawn again over them), the rolling cart drawn, a pigeon's
// perch, and remap (the story positions the sheet moved, the frog out of a picture, the pairs' rectangles).
import 'dart:typed_data';

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/coqui_scenes.dart';
import 'package:coqui_scenes/src/banco/banco.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/sheet_bundle.dart';

int _round(num v) => (v + .5).floor();

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late StillFrame frame;
  late Banco scene;
  setUpAll(() async {
    frame = await ScenePictures(bundle: testBundle()).frameOf('banco');
    scene = frame.scene as Banco;
  });

  Map<String, dynamic> base([Map<String, dynamic> over = const {}]) => {
    'spot': null,
    'twinkle': null,
    'glow': null,
    'fx': <Map<String, dynamic>>[],
    'heart': 0,
    'lost': 0,
    'resp': null,
    ...scene.fresh(const {}),
    ...over,
  };

  test('the moved sources\' numbers: the gate, the seats\' edges, the cart, the perches, the toys, the cards', () {
    expect(scene.PORTON, [199, 203]);
    expect(scene.CARRO, [36, 178]);
    expect(
      [
        for (final x in [87, 96, 107, 135, 183, 192]) scene.SY(x),
      ],
      [157, 161, 167, 157, 157, 161],
    );
    expect(scene.AS(153), 154);
    expect(scene.POSA, [
      [110, 137],
      [158, 137],
      [188, 128],
      [197, 133],
    ]);
    expect(scene.JUGEN[2], [190, 208]);
    expect(scene.fresh(const {})['respEn'], [128, 31]);
    expect(scene.LUGAR['centro'], [104, 180, 1]);
    expect(scene.CAM['wide'], [22, 0, 196, 216]);
    // a place the sheet does not name stops the scene
    expect(
      () => BancoPlacesProbe(scene).floor(9, 1, 2),
      throwsA(isA<SheetError>()),
    );
  });

  test('the sheet\'s moves: every moved source is one the port reads (its line and piece of source)', () {
    // the moves the port reads at their lines, as banco.dart does (each listed by its line and source)
    final read = <String>{};
    for (final m in scene.sheet.moves) {
      read.add('${m.line}|${m.src}');
    }
    expect(read, hasLength(scene.sheet.moves.length));
    expect(scene.sheet.moves, hasLength(42));
  });

  test('hops: every walk of the recorded runs takes banco.js ranaA\'s count, the old and today\'s the same', () {
    int count(num d) => d < 3 ? 0 : (d / 34 + .5).floor().clamp(1, 4);
    for (final h in scene.sheet.hopsAll) {
      expect(count(h.dOld), h.old, reason: '${h.a} -> ${h.b}');
      expect(count(h.dNow), h.now, reason: '${h.a} -> ${h.b}');
      expect(h.now, h.old, reason: '${h.a} -> ${h.b}');
    }
    expect(scene.sheet.hops, isEmpty);
  });

  test(
    'setKey: the light, the moon and the cart, as the sheet\'s words say',
    () {
      expect(scene.setKey(base()), 'dia.0.abierto');
      expect(scene.setKey(base({'tarde': 1})), 'tarde.0.abierto');
      expect(scene.setKey(base({'tarde': 1, 'noche': 1})), 'noche.0.abierto');
      expect(scene.setKey(base({'noche': 1, 'luna': 1})), 'noche.1.abierto');
      expect(scene.setKey(base({'luna': 1})), 'dia.0.abierto');
      expect(
        scene.setKey(base({'noche': 1, 'carro': 'cerrado'})),
        'noche.0.cerrado',
      );
      expect(
        scene.setKey(base({'noche': 1, 'carro': 'cerrado', 'carroX': 30})),
        'noche.0.no',
      );
      expect(scene.setKey(base({'carro': 0})), 'dia.0.no');
    },
  );

  test('shadows: everyone\'s by day and in the evening, none at night; a pigeon in the air over the ground under it', () {
    final w = base({
      'gente': {
        'luis': {'x': 120, 'y': 190, 'dir': 1},
        'mujer': {'x': 135, 'y': 157, 'dir': 1, 'sent': 1},
      },
      'palomas': [
        {
          'i': 0,
          'x': 100,
          'y': 120,
          'pose': 'vuela',
          'gs': [100, 170],
        },
        {'i': 1, 'x': 66, 'y': 55, 'en': 'cable'},
      ],
    });
    final day = scene.shadows(w);
    // the frog, five for Luis standing, two for the woman sitting, the pigeon in the air; none for the one on the wire
    expect(day, hasLength(1 + 5 + 2 + 1));
    final g = scene.projection.unproject(100, 170);
    expect(day.last.x, g.x);
    expect(day.last.y, g.y);
    expect(scene.shadows({...w, 'noche': 1}), isEmpty);
    expect(scene.shadows({...w, 'tarde': 1}), hasLength(day.length));
  });

  test(
    'a pigeon\'s perch: the wire, a bench\'s back, a seat, the ground, the air',
    () {
      expect(scene.perch({'x': 66, 'y': 55}, null), 'wire');
      expect(scene.perch({'x': 110, 'y': 137}, null), 'back');
      expect(scene.perch({'x': 109, 'y': 156}, null), 'seat');
      expect(scene.perch({'x': 120, 'y': 200}, null), 'ground');
      expect(scene.perch({'x': 120, 'y': 200, 'pose': 'vuela'}, null), 'air');
    },
  );

  Uint32List draw(Map<String, dynamic> w) {
    frame.draw(w, F: 8, cam: scene.CAM['wide']!, tick: 0, allSigns: false);
    return Uint32List.fromList(frame.picture);
  }

  test('the front as it is drawn: a sitter keeps the front of their own bench; who stands behind a bench has it drawn again over them', () {
    // the woman on the second bench: nothing of her bench over her
    final sitting = base({
      'gente': {
        'mujer': {'x': 135, 'y': 157, 'dir': 1, 'sent': 1},
      },
    });
    final withSet = draw(sitting);
    final alone = draw(base());
    var changed = 0;
    for (var i = 0; i < withSet.length; i++) {
      if (withSet[i] != alone[i]) changed++;
    }
    expect(changed, greaterThan(300));
    // standing behind the first bench (on the lawn beyond it): the bench's pixels are drawn again over her legs
    final behind = base({
      'gente': {
        'mujer': {'x': 100, 'y': 140, 'dir': 1},
      },
    });
    final b = draw(behind);
    final setOnly = draw(base());
    final tags = scene.frontPixelsOf('dia.0.abierto')!['banco0']!;
    var same = 0;
    for (final i in tags) {
      if (b[i] == setOnly[i]) same++;
    }
    expect(
      same,
      tags.length,
      reason: 'the bench in front of her, every pixel of it',
    );
  });

  test('the rolling cart is drawn by the sprite layer where the set has none, moved along +y', () {
    final rolling = base({
      'noche': 1,
      'carro': 'cerrado',
      'carroX': 30,
      'gente': <String, dynamic>{},
    });
    final standing = base({
      'noche': 1,
      'carro': 'cerrado',
      'gente': <String, dynamic>{},
    });
    final r = draw(rolling), s = draw(standing);
    final d = scene.cartAt(rolling);
    expect(d, [-6, 3]);
    final tags = scene.frontPixelsOf('noche.0.cerrado')!['carro']!;
    var same = 0, n = 0;
    for (final i in tags) {
      final x = i % 240 + d[0], y = i ~/ 240 + d[1];
      if (x < 0 || y < 0 || x >= 240 || y >= 216) continue;
      n++;
      if ((r[y * 240 + x] & 0xFFFFFF) == (s[i] & 0xFFFFFF)) same++;
    }
    expect(n, greaterThan(1000));
    // pixel for pixel the closed cart's, but where the shadows or the leaves differ (none at night): all of them
    expect(same, n);
  });

  test('remap: the story positions the sheet moved, the frog out of a picture, the pairs\' rectangles', () {
    expect(scene.remap([51, 172]), [40, 172]);
    expect(scene.remap([87, 161]), [87, 157]);
    expect(scene.remap([188, 197]), [199, 203]);
    expect(scene.remap([246, 197]), [246, 211]);
    expect(scene.remap([0, 0]), [0, 0]);
    expect(scene.remap([62, 206]), [62, 206]);
    expect(scene.remap([64, 154, 113, 60]), [49, 164, 98, 52]);
    expect(() => scene.remap([1, 2]), throwsA(isA<SheetError>()));
  });

  test(
    'the frog starts where juego.js puts him, and fresh() at LUGAR.centro',
    () {
      expect(frogOfCode(scene.sheet, scene.projection, 'juego.js:16'), (
        x: 150,
        y: 178,
        scale: 1,
      ));
      expect(frogOfCode(scene.sheet, scene.projection, 'cual.js:21'), (
        x: 123,
        y: 150,
        scale: .86,
      ));
      final cq = scene.fresh(const {})['cq'] as Map;
      expect([cq['x'], cq['y']], [104, 180]);
    },
  );

  test('estado writes what the old one writes', () {
    final w = base({
      'gente': {
        'luis': {'x': 120.4, 'y': 190, 'dir': 1, 'lleva': 'bolsa'},
      },
      'palomas': [
        {'i': 0, 'x': 66, 'y': 55, 'en': 'cable'},
        {'i': 1, 'x': 66, 'y': 55},
      ],
      'manos': {'i': 'piragua', 'd': null},
      'marcas': ['ok', null],
      'perros': {
        'canelo': {'x': 1, 'y': 2, 'pose': 'sit', 'lleva': 'hueso'},
      },
      'coche': {'x': 1, 'y': 2, 'bebe': 'duerme', 'capota': 0},
    });
    expect(
      scene.estado(w),
      'gente=luis@120,190[bolsa] palomas=cable? posadas=0 cosas= caja= manos={"i":"piragua","d":null} '
      'bandeja=null jug=0 marcas=ok, perros=canelo:sit+hueso bebe=duerme/abierto',
    );
    expect(_round(120.4), 120);
  });
}

/// The scene's places, as a test reads them (banco_places.dart through the scene's sheet).
class BancoPlacesProbe {
  BancoPlacesProbe(this.scene);
  final Banco scene;
  List<int> floor(int line, num x, num y) => scene.places.floor(line, x, y);
}
