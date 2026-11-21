// La estufa's scene beyond its pictures: the places estufa.js reads from the sheet (the moved sources' numbers: REP,
// SVY, CUBO, SALY, FYS, BJ, EN, the window's family, Luis in cuidado, whoever comes in, the cards; the floor rule's
// numbers, a number the sheet does not name stops the scene), the hops (the sheet's hopsAll, from the frog's places,
// against estufa.js ranaA's count), the set key of every W, the shadows (on the floor only: none for the frog on the
// stool), the window's family seen only through the opening (the room drawn again over them), the stool drawn again over
// whoever stands behind it, the old fault kept (mamá's cup drawn as the baby), and remap (the pairs' positions the sheet
// moved, the frog out of a picture, the pairs' rectangles, the smell's curve).
import 'dart:math' as math;

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/coqui_scenes.dart';
import 'package:coqui_scenes/src/estufa/estufa.dart';
import 'package:coqui_scenes/src/estufa/estufa_places.dart';
import 'package:coqui_scenes/src/estufa/estufa_set.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/sheet_bundle.dart';

int _round(num v) => (v + .5).floor();

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late StillFrame frame;
  late Estufa scene;
  setUpAll(() async {
    frame = await ScenePictures(bundle: testBundle()).frameOf('estufa');
    scene = frame.scene as Estufa;
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

  test('the moved sources\' numbers, as the sheet\'s layout gives them', () {
    final n = scene.sheet.unknown['layout']['numbers'] as Map;
    expect(scene.FYS, n['FYS']);
    expect([for (var i = 0; i < 3; i++) scene.SVY(i)], n['SVY']);
    expect(scene.SALY, n['SALY']);
    expect(scene.BJ, n['BJ']);
    expect(scene.REP, [190, n['REPY']]);
    expect(scene.CUBO, [37, 208]);
    for (final k in (n['ENY'] as Map).keys) {
      expect(scene.EN[k]![1], (n['ENY'] as Map)[k], reason: 'EN.$k');
    }
    expect(scene.EN['saco'], [49, 68]);
    expect(scene.EN['jarra'], [188, 133]);
    expect(
      [scene.FX, scene.FY, scene.PISO],
      [
        [107, 145],
        121,
        150,
      ],
    );
    expect(scene.BANCO, [126, 184]);
    expect(scene.LUGAR['inicio'], [110, 157, 1]);
    expect(scene.CAM['wide'], [22, 0, 196, 216]);
    expect(scene.heartAt, [124, 24]);
    expect(scene.fresh(const {})['respEn'], [146, 20]);
    // a number the sheet does not name at its line stops the scene
    final p = EstufaPlaces(scene.sheet, estufaEngine());
    expect(p.at(231, 46), 46);
    expect(() => p.at(231, 47), throwsA(isA<SheetError>()));
    expect(() => p.at(2, 1), throwsA(isA<SheetError>()));
  });

  test('hops: every pair of the frog\'s places counts as ranaA counts it, the old count but saco-servir\'s', () {
    // estufa.js ranaA: Math.max(1, Math.min(3, Math.round(d / 40))), none under 3
    int count(List<num> a, List<num> b) {
      final dx = a[0] - b[0],
          dy = a[1] - b[1],
          d = math.sqrt(dx * dx + dy * dy);
      return d < 3 ? 0 : math.max(1, math.min(3, _round(d / 40)));
    }

    String spot(String k) => k == 'banco' ? 'frog.inicio' : 'frog.$k';
    final changed = <String>[];
    for (final h in scene.sheet.hopsAll) {
      final a = scene.sheet.spots[spot(h.a)]!,
          b = scene.sheet.spots[spot(h.b)]!;
      expect(count(a.now!, b.now!), h.now, reason: '${h.a} - ${h.b}');
      expect(count(a.old, b.old), h.old, reason: '${h.a} - ${h.b}');
      if (h.now != h.old) changed.add('${h.a}-${h.b}');
    }
    expect(scene.sheet.hopsAll, hasLength(28));
    expect(changed, ['saco-servir']);
    expect(
      (scene.sheet.unknown['checks'] as Map)['walked'],
      isNot(contains('saco-servir')),
    );
  });

  test(
    'the set key: banco 0 or false, the state without the stool; else with it',
    () {
      expect(scene.setKey(base()), 'banco1');
      expect(scene.setKey(base({'banco': 0})), 'banco0');
      expect(scene.setKey(base({'banco': false})), 'banco0');
    },
  );

  test('shadows: whoever stands on the floor; not the frog on the stool', () {
    final w = base({
      'gente': {
        'abuela': {'x': 82, 'y': 174},
        'luis': {'x': 171, 'y': 176},
        'papa': {'vis': 0},
      },
    });
    final s = scene.shadows(w);
    expect(s, hasLength(10));
    expect(s.where((c) => c.r == .35), hasLength(5));
    expect(s.where((c) => c.r == .3), hasLength(5));
    (w['cq'] as Map)
      ..['x'] = 35
      ..['y'] = 159;
    expect(scene.shadows(w), hasLength(11));
    expect(scene.shadows(w).first.r, .45);
  });

  test('the window\'s family is seen only through the opening, cut at the chest; their plates on the sill', () {
    final empty = base({});
    (empty['cq'] as Map)['vis'] = 0;
    final a = draw(empty);
    final w = base({
      'ventana': ['abuelo', 'mama', 'papa'],
    });
    (w['cq'] as Map)['vis'] = 0;
    final b = draw(w);
    final hole = (scene.sheet.otherPoints['ventana'] as Map)['hole'] as List;
    final xs = [for (final p in hole) (p as List)[0] as num],
        ys = [for (final p in hole) (p as List)[1] as num];
    var n = 0;
    for (var i = 0; i < a.length; i++) {
      if (a[i] == b[i]) continue;
      n++;
      final x = i % 240, y = i ~/ 240;
      expect(
        x >= xs.reduce(math.min) - 1 && x <= xs.reduce(math.max) + 1,
        isTrue,
        reason: '($x, $y)',
      );
      expect(
        y >= ys.reduce(math.min) - 1 && y <= ys.reduce(math.max) + 1,
        isTrue,
        reason: '($x, $y)',
      );
    }
    expect(n, greaterThan(200));
    // without the room drawn again over them they would show over the wall under the sill
    w['ventanacome'] = 1;
    final c = draw(w);
    var plates = 0;
    for (var i = 0; i < b.length; i++) {
      if (b[i] != c[i]) plates++;
    }
    expect(plates, greaterThan(20));
  });

  test('the stool is drawn again over whoever stands behind it, never over the frog on it', () {
    final e = estufaEngine();
    final w0 = base({});
    (w0['cq'] as Map)['vis'] = 0;
    final a = draw(w0);
    // Carmen just behind the stool's legs
    final w = base({
      'gente': {
        'carmen': {'x': 126, 'y': 186},
      },
    });
    (w['cq'] as Map)['vis'] = 0;
    final b = draw(w);
    final s = EstufaSet(e, PpBuild(e), EstufaState.fromKey('banco1'));
    s.k.PART_TAGS = List<String?>.filled(e.W * e.H, null);
    s.buildSet();
    var over = 0;
    for (var i = 0; i < a.length; i++) {
      final t = s.k.PART_TAGS![i];
      if ((t == 'banco' || t == 'banco.patas') && a[i] == b[i]) over++;
    }
    expect(over, greaterThan(0), reason: 'stool pixels kept over Carmen');
    // the frog on the stool is drawn whole
    final q = base({});
    final f = draw(q);
    var frog = 0;
    for (var i = 0; i < a.length; i++) {
      if (f[i] != a[i]) frog++;
    }
    expect(frog, greaterThan(300));
  });

  test('the old fault kept: a cup mamá holds is drawn as the baby (estufa.js:122, :125)', () {
    final w = base({
      'gente': {
        'mama': {'x': 169, 'y': 202, 'bebe': 'cal'},
      },
    });
    draw(w);
    expect(frame.host.lib.SP.containsKey('bbcal0'), isTrue);
    expect(scene.sheet.faults.single.line, 122);
  });

  test('remap: the pairs\' moved positions, the frog out of a picture, the rectangles, the smell', () {
    expect(scene.remap([126, 127]), [126, 107]);
    expect(scene.remap([195, 123]), [195, 141]);
    expect(scene.remap([84, 196]), [84, 196]);
    expect(scene.remap([0, 0]), [0, 0]);
    expect(scene.remap([116, 86, 105.5, 56]), [44, 79, 196, 104]);
    expect(() => scene.remap([1, 2]), throwsA(isA<SheetError>()));
    final set = <String, dynamic>{
      'gente': {
        'mama': {'x': 176, 'y': 152},
        'abuela': {'x': 156.25, 'y': 164},
      },
      'cosas': [
        {'k': 'olla', 'x': 150, 'y': 113},
      ],
      'olor': [106, 104, 90, 117],
    };
    scene.placePair(set);
    expect(set['gente']['mama'], {'x': 176, 'y': 178});
    expect((set['gente']['abuela'] as Map)['y'], 168);
    expect(set['cosas'][0]['y'], 107);
    expect(set['olor'], [106, 79, 90, 117]);
  });
}
