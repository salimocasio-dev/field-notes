// A comer's scene beyond its pictures: the places comer.js reads from the sheet (the moved sources' numbers: SY round
// column 118, XP, DOOR, PB, the cloth's edges ENTOP, the place behind the table DETRAS, the seats' feet, the cards'
// centres CARTAS tries, the talk places LIBRE tries, HOPAT; every spot the stories name; a number the sheet does not name
// at its line stops the scene), the hops (the sheet's hopsAll: every pair of the frog's named places keeps its old count,
// counted on the old distance), the set key of every W, the shadows (whoever stands on the clear floor; none for a sitter,
// the frog), the table drawn again over whoever stands behind it (the sheet's front), of two seated in one row the one to
// the right drawn over the other, the answer cards' place (CARTAS) and remap (the positions the sheet moved, the frog out
// of a picture, the pairs' rectangles).
import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/coqui_scenes.dart';
import 'package:coqui_scenes/src/comer/comer.dart';
import 'package:coqui_scenes/src/comer/comer_places.dart';
import 'package:coqui_scenes/src/comer/comer_set.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/report.dart';
import 'support/sheet_bundle.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late StillFrame frame;
  late Comer scene;
  late ComerPlaces places;
  setUpAll(() async {
    frame = await ScenePictures(bundle: testBundle()).frameOf('comer');
    scene = frame.scene as Comer;
    places = ComerPlaces(scene.sheet, comerEngine());
  });
  final rows = <String>[];

  Map<String, dynamic> base([Map<String, dynamic> over = const {}]) {
    final w = <String, dynamic>{
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
    (w['cq'] as Map)['vis'] = 0;
    return w;
  }

  List<int> draw(Map<String, dynamic> w) {
    frame.draw(w, F: 0, cam: scene.CAM['wide']!, tick: 0, allSigns: false);
    return [...frame.picture];
  }

  Map<String, dynamic> person(
    num x,
    num y, [
    Map<String, dynamic> o = const {},
  ]) => {'x': x, 'y': y, 'dir': 1, 'tiene': <dynamic>[], ...o};

  test('the moved sources\' numbers, as the sheet\'s layout gives them; every spot the stories name', () {
    final n = scene.sheet.unknown['layout']['numbers'] as Map;
    expect(scene.SYC, n['SYC']);
    expect(scene.XP, n['XP']);
    expect(scene.DOOR, n['DOOR']);
    expect(scene.PB, n['PB']);
    for (final x in const [90, 114, 118, 138, 162, 202]) {
      expect(scene.SY(x, 132), 132 + (x - 118) / 2, reason: 'SY($x)');
    }
    // the seats (layout.seats): their feet and laps, each the old row stepped down by SY
    for (final s in (scene.sheet.unknown['layout']['seats'] as List)) {
      final i = (s as Map)['seat'] as int, old = s['old'] as List;
      expect(
        [scene.SILLA[i], scene.SY(scene.SILLA[i], old[1] as num)],
        s['feet'],
        reason: 'seat $i',
      );
      expect(
        [scene.SILLA[i], scene.SY(scene.SILLA[i], scene.FILA)],
        s['lap'],
        reason: 'seat $i',
      );
    }
    final cards = scene.sheet.raw['cards'] as Map;
    expect(scene.CARTAS_CX, cards['cx']);
    expect(scene.CARTAS_Y, cards['y']);
    expect(scene.LIBRE_AT, [
      for (final p in scene.sheet.talk!.places) [p.side, p.dy],
    ]);
    expect(
      scene.HOPAT,
      hasLength((scene.sheet.unknown['hopTable'] as Map)['places'] as int),
    );
    rows.add(
      'SY round ${scene.SYC}, XP ${scene.XP}, DOOR ${scene.DOOR}, PB ${scene.PB}; ${scene.CARTAS_CX.length} card centres; '
      '${scene.LIBRE_AT.length} talk places; HOPAT ${scene.HOPAT.length} places',
    );
    // the frog's spots are his feet (q.x + 16, q.y + 27), the others the thing's or person's x, y
    var k = 0;
    for (final (name, v) in [
      ('CE33', scene.CE33),
      ('BU33', scene.BU33),
      ('CH33', scene.CH33),
      ('HOME33', scene.HOME33),
      ('FETCH33', scene.FETCH33),
      ('HO33', scene.HO33),
      ('PA33', scene.PA33),
      ('PA33S', scene.PA33S),
      ('OLLA', scene.OLLA),
      ('FU34', scene.FU34),
      ('PLUIS', scene.PLUIS),
      ('PRANA', scene.PRANA),
      ('CASA34', scene.CASA34),
      ('EAT34', scene.EAT34),
      ('LUIS34', scene.LUIS34),
      ('PLAT34', scene.PLAT34),
      ('CONT34', scene.CONT34),
      ('ENC34', scene.ENC34),
      ('K1', scene.K1),
      ('K2', scene.K2),
      ('AZU', scene.AZU),
      ('TRANA', scene.TRANA),
      ('GRECA35', scene.GRECA35),
      ('GRECA35B', scene.GRECA35B),
      ('TABU', scene.TABU),
      ('CASA35', scene.CASA35),
      ('CAFE35', scene.CAFE35),
      ('CAZO35', scene.CAZO35),
      ('STOOL', scene.STOOL),
    ]) {
      if (!scene.sheet.spots.containsKey(name)) continue;
      expect(v, places.spot(name), reason: name);
      k++;
    }
    rows.add('$k named places equal their spots');
    expect(k, greaterThan(10));
    expect(scene.LUGAR['inicio'], [124, 141, 1]);
  });

  test('a number the sheet does not name at its line stops the scene; a moved line\'s numbers are not kept', () {
    expect(places.at(1237, 130), 130);
    expect(() => places.at(1237, 131), throwsA(isA<SheetError>()));
    expect(() => places.at(21, 118), throwsA(isA<SheetError>()));
    expect(() => places.at(0, 1), throwsA(isA<SheetError>()));
  });

  test('every pair of the frog\'s named places keeps its old hop count (hopsAll), counted on the old distance (HOPAT)', () {
    List<num> feet(String name) {
      if (scene.sheet.spots.containsKey(name)) return places.spot(name);
      return places.spot(scene.sheet.lugar[name]!.spot);
    }

    final all = scene.sheet.hopsAll;
    expect(all, hasLength(28));
    expect(scene.sheet.hops, isEmpty);
    var differ = 0;
    for (final h in all) {
      final a = feet(h.a), b = feet(h.b);
      expect(scene.hopCount(a, b), h.old, reason: '${h.a} - ${h.b}');
      expect(scene.hopCount(b, a), h.old, reason: '${h.b} - ${h.a}');
      if (h.now != h.old) differ++;
    }
    rows.add(
      'hops: all ${all.length} pairs keep their old count ($differ of them would change counted on the new distance)',
    );
  });

  test('one baked state for every W', () {
    expect(scene.setKey(base()), 'comer');
    expect(
      scene.setKey(
        base({
          'perro': {'x': 1, 'y': 2},
        }),
      ),
      'comer',
    );
  });

  test('the shadows: whoever stands on the clear floor, the dog; none for a sitter or the frog', () {
    final w = base({
      'gente': {
        'abuela': person(scene.LEP_ADULTO[0], scene.LEP_ADULTO[1]),
        'luis': person(scene.LEP_NINO[0], scene.LEP_NINO[1]),
        'mama': person(
          scene.SILLA[0],
          scene.SY(scene.SILLA[0], scene.ASIENTO),
          {'sent': 1},
        ),
      },
      'perro': {'x': 48, 'y': 208, 'pose': 'lie', 'dir': 1},
    });
    (w['cq'] as Map)['vis'] = 1;
    final s = scene.shadows(w);
    expect(s, hasLength(11));
    rows.add(
      'shadows: ${s.length} (abuela 5, Luis 5, the dog 1; mamá seated and the frog none)',
    );
  });

  test('the table is drawn again over whoever stands behind it, not over whoever stands in front of it', () {
    final e = comerEngine(), set = ComerSet(e, PpBuild(e));
    set.k.PART_TAGS = List<String?>.filled(e.W * e.H, null);
    set.buildSet();
    final tags = set.k.PART_TAGS!;
    bool table(int i) => tags[i] == 'mesa' || tags[i] == 'mesa.patas';
    final p0 = draw(base());
    (int, int) changed(Map<String, dynamic> w) {
      final p = draw(w);
      var all = 0, onTable = 0;
      for (var i = 0; i < p.length; i++) {
        if (p[i] == p0[i]) continue;
        all++;
        if (table(i)) onTable++;
      }
      return (all, onTable);
    }

    final behind = changed(
      base({
        'gente': {'abuela': person(150, scene.SY(150, scene.ATRAS))},
      }),
    );
    final front = changed(
      base({
        'gente': {'abuela': person(150, 206)},
      }),
    );
    rows.add(
      'abuela behind the table: ${behind.$1} px, ${behind.$2} on the table; in front: ${front.$1} px, ${front.$2} on the table',
    );
    expect(behind.$1, greaterThan(0));
    expect(behind.$2, 0);
    expect(front.$2, greaterThan(0));
  });

  test('of two seated in one row the one to the right is drawn over the other; abuela on her stool keeps her row', () {
    final a = scene.capa({'x': 100, 'y': 140, 'sent': 1});
    final b = scene.capa({'x': 120, 'y': 150, 'sent': 1});
    expect(b[0], greaterThan(a[0]));
    expect(scene.capa({'x': 206, 'y': 180, 'sent': 1})[0], 180);
  });

  test('CARTAS: the answer cards at the first centre whose cards are clear (nobody, or the four seated: the first)', () {
    final w = base({
      'resp': ['a', 'b'],
    });
    draw(w);
    expect(w['respEn'], [scene.CARTAS_CX.first, scene.CARTAS_Y]);
    final seated = base({
      'resp': ['a', 'b', 'c'],
      'gente': {
        for (final (i, id) in const [
          'mama',
          'carmen',
          'abuelo',
          'papa',
        ].indexed)
          id: person(scene.SILLA[i], scene.SY(scene.SILLA[i], scene.ASIENTO), {
            'sent': 1,
          }),
      },
    });
    draw(seated);
    final at = seated['respEn'] as List;
    expect(scene.CARTAS_CX, contains(at[0]));
    expect(at[1], scene.CARTAS_Y);
    rows.add(
      'CARTAS: with nobody ${w['respEn']}, three cards with the four seated $at',
    );
  });

  test('remap: every point at its new place, the moved ones moved; the frog out of a picture is no place; the rectangles', () {
    var moved = 0, points = 0;
    for (final e in scene.sheet.remapTable) {
      if (e.kind != 'point' || e.now == null) continue;
      expect(scene.remap(e.old), e.now, reason: '${e.old}');
      points++;
      if (e.moved) moved++;
    }
    expect(scene.remap([0, 0]), [0, 0]);
    expect(moved, greaterThan(0));
    // a rectangle gives the one crop of its pictures; one whose pictures are cropped differently stops (ask for a picture
    // by its name, as ScenePictures does)
    var rects = 0, byName = 0;
    for (final e in scene.sheet.remapTable) {
      if (e.kind != 'cam' && e.kind != 'crop') continue;
      final pics = e.to.pictures ?? const <String>[];
      final crops = {
        for (final n in pics)
          '${scene.sheet.pictures[n]!.zoom}:${scene.sheet.pictures[n]!.crop}',
        for (final c
            in e.crops?.values ?? const <({List<int> crop, int zoom})>[])
          '${c.zoom}:${c.crop}',
      };
      if (!e.to.level && e.crop == null && crops.length > 1) {
        expect(
          () => scene.remap(e.old),
          throwsA(isA<SheetError>()),
          reason: '${e.old}',
        );
        byName++;
      } else {
        expect(scene.remap(e.old), hasLength(4), reason: '${e.old}');
        rects++;
      }
    }
    expect(() => scene.remap([1, 2, 3]), throwsA(isA<SheetError>()));
    rows.add(
      'remap: $points points, $moved moved; $rects rectangles give their crop, $byName are asked for by name',
    );
  });

  tearDownAll(() => report('comer-acts', rows));
}
