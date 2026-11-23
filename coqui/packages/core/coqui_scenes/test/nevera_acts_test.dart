// La nevera's scene beyond its pictures: the places nevera.js reads from the sheet (the moved sources' numbers: the rows
// CT, SL, MU, PA, CB, VT, the fridge's boxes NEVERA and FRUTAS, HUECO, EN, the outside's glass, the cards; the floor rule's
// numbers, a number the sheet does not name stops the scene), the hops (the sheet's hopsAll: none changes, each against
// nevera.js ranaA's count), the set key of every W, the shadows (on the floor only: none for the frog on the stool or the
// counter, none for whoever is outside), whoever stands outside seen only through the window's opening, the set's front
// parts drawn again over whoever stands behind them, the fridge's hint boxes by state, and remap (the stories' and pairs'
// positions the sheet moved, the frog out of a picture, an x alone, the pairs' rectangles).
import 'dart:math' as math;

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/coqui_scenes.dart';
import 'package:coqui_scenes/src/nevera/nevera.dart';
import 'package:coqui_scenes/src/nevera/nevera_places.dart';
import 'package:coqui_scenes/src/nevera/nevera_set.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/sheet_bundle.dart';

int _round(num v) => (v + .5).floor();

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late StillFrame frame;
  late Nevera scene;
  setUpAll(() async {
    frame = await ScenePictures(bundle: testBundle()).frameOf('nevera');
    scene = frame.scene as Nevera;
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

  List<int> draw(Map<String, dynamic> w) {
    frame.draw(w, F: 0, cam: scene.CAM['wide']!, tick: 0, allSigns: false);
    return [...frame.picture];
  }

  test(
    'the moved sources\' numbers, as the sheet\'s layout and points give them',
    () {
      final n = scene.sheet.unknown['layout']['numbers'] as Map;
      for (final (k, f) in [
        ('CT', scene.CT),
        ('SL', scene.SL),
        ('MU', scene.MU),
        ('PA', scene.PA),
        ('CB', scene.CB),
        ('VT', scene.VT),
      ]) {
        for (final x in const [100, 151, 170, 207]) {
          expect(f(x), _round((n[k] as num) + x / 2), reason: '$k($x)');
        }
      }
      final pts = scene.sheet.raw['points'] as Map;
      expect(scene.HUECO, (pts['nevera'] as Map)['huecos']);
      expect(
        scene.EN['cesta'],
        ((pts['nevera'] as Map)['top'] as Map)['cesta'],
      );
      expect(scene.EN['pan'], [160, scene.CT(160)]);
      expect(scene.EN['vasos'], [202, scene.CT(202) - 1]);
      expect(scene.EN['pila'], [124, scene.CT(124)]);
      expect(
        scene.NEVERA,
        (scene.sheet.things['nevera']!.raw['boxes'] as List),
      );
      expect(
        scene.FRUTAS,
        (scene.sheet.things['frutas']!.raw['boxes'] as List),
      );
      expect(
        [scene.SILL, scene.PATIO, scene.MURO, scene.ENC, scene.PISO],
        [98, 120, 70, 112, 150],
      );
      expect(scene.BANCO, [120, 192]);
      expect(scene.LUGAR['inicio'], [104, 165, 1]);
      expect(scene.CAM['wide'], [28, 0, 196, 216]);
      expect(scene.heartAt, [124, 24]);
      expect(scene.fresh(const {})['respEn'], [154, 4]);
      // a number the sheet does not name at its line stops the scene
      final p = NeveraPlaces(scene.sheet, neveraEngine());
      expect(p.at(214, 94), 94);
      expect(() => p.at(214, 95), throwsA(isA<SheetError>()));
      expect(() => p.at(2, 1), throwsA(isA<SheetError>()));
    },
  );

  test('hops: none changes; every walk of the sheet\'s hopsAll counts as nevera.js ranaA counts it', () {
    // nevera.js ranaA: Math.max(1, Math.min(3, Math.round(d / 40))), none under 3
    int count(List<num> a, List<num> b) {
      final dx = a[0] - b[0],
          dy = a[1] - b[1],
          d = math.sqrt(dx * dx + dy * dy);
      return d < 3 ? 0 : math.max(1, math.min(3, _round(d / 40)));
    }

    expect(scene.sheet.hops, isEmpty);
    expect(scene.sheet.hopsAll, hasLength(10));
    for (final h in scene.sheet.hopsAll) {
      final r = h.raw;
      List<num> pt(Object? v) => [for (final x in v as List) x as num];
      expect(
        count(pt(r['a2']), pt(r['b2'])),
        h.now,
        reason: '${r['a2']} - ${r['b2']}',
      );
      expect(
        count(pt(r['a']), pt(r['b'])),
        h.old,
        reason: '${r['a']} - ${r['b']}',
      );
      expect(h.now, h.old);
    }
  });

  test(
    'the set key: the fridge, its drawer (open only), the sink, the stool',
    () {
      expect(scene.setKey(base()), '0.0.0.1');
      expect(scene.setKey(base({'banco': 0})), '0.0.0.0');
      expect(
        scene.setKey(
          base({
            'nev': {
              'abierta': 1,
              'cajon': {'guineo': 3},
              'h': [],
            },
            'pila': 'a',
          }),
        ),
        '1.1.a.1',
      );
      expect(
        scene.setKey(
          base({
            'nev': {'abierta': 1, 'cajonver': 1, 'cajon': {}, 'h': []},
          }),
        ),
        '1.2.0.1',
      );
      expect(
        scene.setKey(
          base({
            'nev': {'abierta': 2, 'cajonver': 1, 'cajon': {}},
            'pila': 'j',
          }),
        ),
        '2.0.j.1',
      );
      for (final b in scene.sheet.setKey.baked) {
        expect(NeveraState.fromKey(b.key!).key, b.key);
      }
    },
  );

  test('shadows: whoever stands on the floor; not whoever is outside, not the frog on the stool or the counter', () {
    final w = base({
      'gente': {
        'abuela': {'x': 94, 'y': 174},
        'luis': {'x': 146, 'y': 198},
        'abuelo': {'x': 207, 'y': 133, 'fuera': 1},
        'papa': {'vis': 0},
      },
    });
    final s = scene.shadows(w);
    // abuela five, Luis (a child) four
    expect(s, hasLength(9));
    expect(s.every((c) => c.r == .32), isTrue);
    (w['cq'] as Map)
      ..['x'] = 134
      ..['y'] = 84;
    expect(scene.frogOn(w['cq'] as Map<String, dynamic>), 'counter');
    expect(scene.shadows(w), hasLength(9));
    (w['cq'] as Map)
      ..['x'] = 114
      ..['y'] = 164;
    expect(scene.frogOn(w['cq'] as Map<String, dynamic>), 'floor');
    expect(scene.shadows(w), hasLength(10));
    expect(scene.shadows(w).first.r, .45);
    final c = base({
      'cosas': [
        {'k': 'charcoj', 'x': 150, 'y': 204},
        {'k': 'vaso', 'x': 170, 'y': scene.CT(170), 'z': 100},
      ],
    });
    expect(scene.shadows(c).where((s) => s.r == .18), hasLength(1));
  });

  test('whoever stands outside is drawn only on the set\'s pixels that show the outside, cut below by the sill', () {
    final empty = base({});
    (empty['cq'] as Map)['vis'] = 0;
    final a = draw(empty);
    final w = base({
      'gente': {
        'papa': {'x': 154, 'y': scene.PA(154), 'dir': 1, 'fuera': 1},
        'luis': {'x': 166, 'y': scene.PA(166) - 4, 'dir': -1, 'fuera': 1},
        'abuelo': {'x': 207, 'y': scene.PA(207) - 9, 'dir': -1, 'fuera': 1},
        'mama': {'x': 198, 'y': scene.PA(198), 'dir': -1, 'fuera': 1},
      },
      'patio': {
        'carrito': 1,
        'aves': [
          {'x': 158},
          {'x': 175, 'come': 1},
        ],
        'cosas': [
          {'k': 'panecillo', 'x': 178},
        ],
      },
    });
    (w['cq'] as Map)['vis'] = 0;
    final b = draw(w);
    final out = scene.zonesOf(scene.setKey(w)).outside;
    var n = 0, beyond = 0;
    for (var i = 0; i < a.length; i++) {
      if (a[i] == b[i]) continue;
      n++;
      if (!out.contains(i)) beyond++;
    }
    expect(n, greaterThan(1000));
    expect(beyond, 0);
    // the opening is the window's: its glass between its frame's boards, over the sill
    final zone = scene.zonesOf('0.0.0.1').zone;
    expect(out.length, greaterThan(5000));
    for (final i in out) {
      expect(zone[i], 'o');
    }
  });

  test('the counter and the fridge are drawn again over whoever stands behind them; nobody is drawn over in front', () {
    final w0 = base({});
    (w0['cq'] as Map)['vis'] = 0;
    final a = draw(w0);
    final tags = scene.tagsOf('0.0.0.1');
    // Luis just behind the counter's right end (his feet over the counter's foot: the floor under him is further back)
    final w = base({
      'gente': {
        'luis': {'x': 205, 'y': scene.CB(205) - 6, 'dir': -1},
      },
    });
    (w['cq'] as Map)['vis'] = 0;
    final b = draw(w);
    var kept = 0;
    for (var i = 0; i < a.length; i++) {
      if (tags[i] == 'mostrador' && a[i] == b[i]) kept++;
    }
    expect(kept, greaterThan(0), reason: 'counter pixels kept over Luis');
    // Luis in front of the counter: wholly drawn
    final c = base({
      'gente': {
        'luis': {'x': 205, 'y': 205, 'dir': -1},
      },
    });
    (c['cq'] as Map)['vis'] = 0;
    final d = draw(c);
    var drawn = 0;
    for (var i = 0; i < a.length; i++) {
      if (d[i] != a[i]) drawn++;
    }
    expect(drawn, greaterThan(400));
  });

  test('the fridge\'s hint box and hand by its door, its inside\'s hint box by its drawer', () {
    for (final (nev, k) in [
      (<String, dynamic>{'abierta': 0, 'h': []}, 0),
      (<String, dynamic>{'abierta': 1, 'h': []}, 1),
      (<String, dynamic>{'abierta': 2, 'h': []}, 2),
    ]) {
      final w = base({'nev': nev});
      draw(w);
      expect(
        scene.cosa('nevera')!.hintBox,
        (scene.sheet.things['nevera']!.raw['hintBoxes'] as List)[k],
      );
      expect(
        scene.handAt('nevera'),
        (scene.sheet.things['nevera']!.raw['hands'] as List)[k],
      );
      expect(scene.box('nevera', w), scene.NEVERA[k]);
    }
    final w = base({
      'nev': {'abierta': 1, 'cajonver': 1, 'cajon': {}, 'h': []},
    });
    draw(w);
    expect(
      scene.cosa('frutas')!.hintBox,
      (scene.sheet.things['frutas']!.raw['hintBoxes'] as List)[1],
    );
    expect(scene.box('frutas', w), scene.FRUTAS[1]);
  });

  test('remap: the stories\' and pairs\' moved positions, the frog out of a picture, an x alone, the rectangles', () {
    expect(scene.remap([142, 122]), [142, 108]);
    expect(scene.remap([206, 122]), [201, 137]);
    expect(scene.remap([178, 98]), [178, 114]);
    expect(scene.remap([184, 120]), [184, 130]);
    expect(scene.remap([150, 200]), [150, 200]);
    expect(scene.remap([0, 0]), [0, 0]);
    expect(scene.remap([170]), [170]);
    expect(scene.remap([124, 152, 56.5, 30]), [101, 152, 98, 52]);
    expect(scene.remap([138.67, 152, 27.17, 30]), [101, 152, 98, 52]);
    expect(() => scene.remap([1, 2]), throwsA(isA<SheetError>()));
    // pan and mantequilla were one old rectangle, cropped apart now: asked by name
    expect(() => scene.remap([132, 92, 75.3, 40]), throwsA(isA<SheetError>()));
    final set = <String, dynamic>{
      'gente': {
        'papa': {'x': 184, 'y': 120, 'fuera': 1},
        'abuelo': {'x': 150, 'y': 204},
      },
      'cosas': [
        {'k': 'platoazul', 'x': 160, 'y': 123, 'z': 300},
        {'k': 'queso', 'v': 3, 'x': 160, 'y': 121, 'z': 301},
      ],
    };
    scene.placePair(set);
    expect(set['gente']['papa'], {'x': 184, 'y': 130, 'fuera': 1});
    expect(set['gente']['abuelo'], {'x': 150, 'y': 204});
    expect([set['cosas'][0]['y'], set['cosas'][1]['y']], [118, 116]);
  });
}
