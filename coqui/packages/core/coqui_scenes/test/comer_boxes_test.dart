// A comer's touch boxes. (1) Every thing of the set lies inside its touch box: each pixel the table drew (set-kit.js
// `part`: `mesa`, `mesa.patas`) is inside the table's box (things.mesa.box), each pixel of chair i (`silla<i>`) inside papá's
// chair's box when he sits there (things.silla_papa.byChair[i]); the room's box is the picture; each set thing's hand and
// hint box inside its box. (2) Every thing of the sprite layer that has a box of its own lies inside it where the stories put
// it: the butter and the chocolate, the basket, the coffee pot, the sugar bowl, the pot of rice, the platter on the stove and
// on the table, papá's plate and the frog's (each drawn alone, the pixels that change against the same picture with nothing
// on it: inside the box with its slack), but where the old file's own box leaves part of its sprite out (listed in [asOld]).
// (3) hit, in the kit's order, gives each thing's key at the middle of its box when it shows, but where the old order gives
// the point to a thing tested before it (listed in [shadowedBy]). The people's boxes (caja) and the frog's speaking box are
// relative to them, as in the old file (comer.js:331, :336).
import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/coqui_scenes.dart';
import 'package:coqui_scenes/src/comer/comer.dart';
import 'package:coqui_scenes/src/comer/comer_set.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/report.dart';
import 'support/sheet_bundle.dart';

/// The middles hit gives to another thing, because the kit tests that thing first, each with why.
const Map<String, String> shadowedBy = {
  'cocina -> mesa':
      'the room\'s box is the whole picture and its middle (120, 108) is on the table, which the kit tests first '
      '(comer.js:337: the table before the room)',
};

/// What the old file's own box leaves out of its sprite (the box and the sprite are placed relative to each other as in
/// comer.js; only where they stand moved), each a test of the pixels outside it and why.
final Map<String, (bool Function(int x, int y, List<num> b), String)> asOld = {
  'azucarera': (
    (x, y, b) => true,
    'the sugar bowl on the table: its sprite is 38 x 20 with the lid lying beside it on the right, drawn round x by its foot; '
        'the box 24 x 18 from x - 12, y - 18 (comer.js:213, :336)',
  ),
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Comer scene;
  late StillFrame frame;
  setUpAll(() async {
    frame = await ScenePictures(bundle: testBundle()).frameOf('comer');
    scene = frame.scene as Comer;
  });
  final rows = <String>[];

  bool inside(List<num> b, num x, num y) =>
      x >= b[0] && x < b[0] + b[2] && y >= b[1] && y < b[1] + b[3];

  test('the set: every pixel of the table inside its box, of each chair inside papá\'s chair\'s box there; hands and hint boxes', () {
    final e = comerEngine(), s = ComerSet(e, PpBuild(e));
    s.k.PART_TAGS = List<String?>.filled(e.W * e.H, null);
    s.buildSet();
    final tags = s.k.PART_TAGS!;
    final byChair = scene.sheet.things['silla_papa']!.raw['byChair'] as List;
    final mesa = scene.box('mesa', const {})!;
    var n = 0, out = 0;
    final nCh = [0, 0, 0, 0], outCh = [0, 0, 0, 0];
    for (var i = 0; i < tags.length; i++) {
      final t = tags[i];
      if (t == null) continue;
      final x = i % e.W, y = i ~/ e.W;
      if (t == 'mesa' || t == 'mesa.patas') {
        n++;
        if (!inside(mesa, x, y)) out++;
      }
      final m = RegExp(r'^silla(\d)$').firstMatch(t);
      if (m != null) {
        final k = int.parse(m[1]!);
        nCh[k]++;
        final b = (byChair[k] as List).cast<num>();
        if (!inside(b, x, y)) outCh[k]++;
      }
    }
    rows.add('mesa: $n px, $out outside $mesa');
    expect(n, greaterThan(0));
    expect(out, 0);
    for (var k = 0; k < 4; k++) {
      // papá's chair at seat k (W.sitio.papa)
      final w = {
        'sitio': {'papa': k},
      };
      expect(scene.box('silla_papa', w), byChair[k]);
      rows.add('silla$k: ${nCh[k]} px, ${outCh[k]} outside ${byChair[k]}');
      expect(nCh[k], greaterThan(0));
      expect(outCh[k], 0, reason: 'silla$k');
    }
    expect(scene.box('silla_papa', const {}), byChair[3]);
    expect(scene.box('cocina', const {}), [0, 0, 240, 216]);
    scene.host.W
      ..clear()
      ..addAll(scene.fresh(const {}));
    for (final k in const ['mesa', 'cocina', 'silla_papa']) {
      final b = scene.box(k, scene.host.W)!, h = scene.handAt(k)!;
      final hb = scene.cosa(k)!.hintBox ?? b;
      expect(inside(b, h[0], h[1]), isTrue, reason: '$k: its hand $h in $b');
      expect(
        hb[0] >= b[0] &&
            hb[1] >= b[1] &&
            hb[0] + hb[2] <= b[0] + b[2] &&
            hb[1] + hb[3] <= b[1] + b[3],
        isTrue,
        reason: '$k: its hint box $hb in $b',
      );
      rows.add('$k: box $b, hand $h, hint box $hb');
    }
  });

  // a W with nothing anywhere, nobody, the frog away
  Map<String, dynamic> empty() {
    final w = <String, dynamic>{
      'spot': null,
      'twinkle': null,
      'fx': <Map<String, dynamic>>[],
      'heart': 0,
      'lost': 0,
      'resp': null,
      ...scene.fresh(const {}),
    };
    (w['cq'] as Map)['vis'] = 0;
    return w;
  }

  List<int> drawn(Map<String, dynamic> w) {
    final cam = scene.CAM['wide']!;
    frame.draw(empty(), F: 0, cam: cam, tick: 0, allSigns: false);
    final before = [...frame.picture];
    frame.draw(w, F: 0, cam: cam, tick: 0, allSigns: false);
    return [
      for (var i = 0; i < before.length; i++)
        if (frame.picture[i] != before[i]) i,
    ];
  }

  // each thing alone, where the stories put it (its id, kind and value; no steam: what rises from it is not the thing)
  late final things = <String, Map<String, dynamic>>{
    'mant': {
      'k': 'mantequilla',
      'v': '5',
      'x': scene.BU33[0],
      'y': scene.BU33[1],
    },
    'choc': {'k': 'choc', 'v': '5', 'x': scene.CH33[0], 'y': scene.CH33[1]},
    'cesta': {'k': 'cesta', 'v': '5:0', 'x': scene.CE33[0], 'y': scene.CE33[1]},
    'cafetera': {'k': 'cafetera', 'x': scene.CAFE35[0], 'y': scene.CAFE35[1]},
    'azucarera': {
      'k': 'azucarera',
      'x': scene.AZU[0],
      'y': scene.AZU[1],
      'spoons': 8,
    },
    'olla': {
      'k': 'olla',
      'v': 'lleno0',
      'x': scene.OLLA[0],
      'y': scene.OLLA[1],
    },
    'fuente@stove': {
      'k': 'fuente',
      'v': 'c',
      'x': scene.PLAT34[0],
      'y': scene.PLAT34[1],
      'montones': <dynamic>[],
      'tenedor': {'dx': -4, 'dy': 3},
    },
    'fuente@table': {
      'k': 'fuente',
      'v': '',
      'x': scene.FU34[0],
      'y': scene.FU34[1],
      'montones': [
        for (final (i, dx) in const [-9, -4, -9, -4, 4, 9, 7].indexed)
          {
            'dx': dx,
            'dy': const [-4, -4, -8, -8, -8, -8, -4][i],
            'g': i < 4 ? 'm' : 'p',
          },
      ],
      'tenedor': {'dx': 8, 'dy': 15},
    },
    'pl_papa': {
      'k': 'plato',
      'v': 'p3',
      'x': scene.SILLA[3],
      'y': scene.SY(scene.SILLA[3], scene.FILA),
      'rollos': <dynamic>[],
    },
    'pl_rana': {
      'k': 'platito',
      'v': 'o',
      'x': scene.PRANA[0],
      'y': scene.PRANA[1],
    },
  };

  Map<String, dynamic> withThing(String key) {
    final id = key.split('@')[0];
    return empty()
      ..['cosas'] = [
        {'id': id, ...things[key]!},
      ];
  }

  for (final key in const [
    'mant',
    'choc',
    'cesta',
    'cafetera',
    'azucarera',
    'olla',
    'fuente@stove',
    'fuente@table',
    'pl_papa',
    'pl_rana',
  ]) {
    test('$key: every pixel it draws is inside its box (with its slack)', () {
      final k = key.split('@')[0];
      final w = withThing(key);
      final px = drawn(w), b = scene.box(k, w)!, t = scene.cosa(k)!;
      final m = t.m ?? 3, bm = [b[0] - m, b[1] - m, b[2] + 2 * m, b[3] + 2 * m];
      final outside = px.where((i) => !inside(bm, i % 240, i ~/ 240)).toList();
      final old = asOld[k];
      final out = outside
          .where((i) => old == null || !old.$1(i % 240, i ~/ 240, bm))
          .toList();
      rows.add(
        '$key: ${px.length} px, ${outside.length} outside $b (slack $m)${old == null ? '' : ', as the old: ${old.$2}'}',
      );
      expect(px, isNotEmpty);
      expect(
        out,
        isEmpty,
        reason:
            '$key: ${[
              for (final i in out.take(12)) [i % 240, i ~/ 240],
            ]} outside $bm',
      );
      expect(t.si!(w), isTrue);
    });
  }

  test('the frog\'s speaking boxes: one 16 x 10 box over his head, the same for all five; hit answers di_buen (the sheet\'s faults)', () {
    final w = empty();
    (w['cq'] as Map)['vis'] = 1;
    scene.host.W
      ..clear()
      ..addAll(w);
    final boxes = {
      for (final k in const [
        'di_buen',
        'di_tambien',
        'di_lleno',
        'di_poco',
        'di_mucho',
      ])
        k: scene.box(k, w),
    };
    final b = frame.host.frogBox(w['cq'] as Map<String, dynamic>);
    final want = [b.x + (b.w.toInt() >> 1) - 8, b.y - 27, 16, 10];
    for (final e in boxes.entries) {
      expect(e.value, want, reason: e.key);
    }
    expect(scene.hit(want[0] + 8, want[1] + 5, w), 'di_buen');
    expect(scene.sheet.faults.first.what, contains('di_buen'));
    rows.add('speaking boxes: all five $want; hit at its middle: di_buen');
  });

  test('hit gives each thing at the middle of its box', () {
    for (final key in [...things.keys, 'mesa', 'cocina', 'silla_papa']) {
      final k = key.split('@')[0];
      final w = things.containsKey(key) ? withThing(key) : empty();
      final b = scene.box(k, w)!;
      final got = scene.hit(b[0] + b[2] / 2, b[1] + b[3] / 2, w);
      rows.add('hit $key at its middle: $got');
      if (got != k) {
        expect(
          shadowedBy.containsKey('$k -> $got'),
          isTrue,
          reason: '$key: $got',
        );
      }
    }
  });
  tearDownAll(() => report('comer-boxes', rows));
}
