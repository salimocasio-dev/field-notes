// La estufa's touch boxes. (1) Every thing of the set lies inside its touch box: in both states, each pixel the set's
// part for the stove drew (set-kit.js `part`: `estufa`) is inside its box (the sheet's things.estufa.box); the kitchen's
// box is the whole picture, its hint box inside it; each set thing's hand inside its box. (2) Every thing of the sprite
// layer the sheet moved lies inside its box: the pots at their burners' rows, the pan, the cups of rice and beans, the
// tray, the jug (each drawn alone on the set, the pixels that change against the set with nothing on it: inside the
// box). (3) hit, in the kit's order, gives each thing's key at the middle of its box when it shows, but where the old
// order gives the point to a thing tested before it (listed in [shadowedBy]). The people's boxes (caja) and the pieces on
// abuela's plate are relative to them, as in the old file (code lines 105, 111): unchanged.
import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/coqui_scenes.dart';
import 'package:coqui_scenes/src/estufa/estufa.dart';
import 'package:coqui_scenes/src/estufa/estufa_set.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/report.dart';
import 'support/sheet_bundle.dart';

/// The middles hit gives to another thing, because the kit tests that thing first, each with why.
const Map<String, String> shadowedBy = {
  'cocina -> estufa': 'the middle of the kitchen\'s box (120, 108) is on the stove: the stove comes before the kitchen, last in the hit order',
};

/// What the old file's own box leaves out of its sprite (the box and the sprite are placed relative to each other as in
/// estufa.js; only their row moved), each a test of the pixels outside it and why.
final Map<String, (bool Function(int x, int y, List<num> b), String)> asOld = {
  'sarten': (
    (x, y, b) => x >= b[0] + b[2] && y >= b[1] && y < b[1] + b[3],
    'the pan\'s handle: its sprite is 46 wide, drawn round x + 6, the box 36 wide from x - 17 (estufa.js:101, :112)',
  ),
  'bandeja': (
    (x, y, b) => x == b[0] - 1 || (x >= b[0] + b[2] && x < b[0] + b[2] + 3),
    'the tray\'s left column (its sprite 46 wide round x 50, from 27; the box from 28) and the third egg\'s right edge '
        '(round x 72, to 75; the box to 73) (estufa.js:112, :142)',
  ),
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Estufa scene;
  late StillFrame frame;
  setUpAll(() async {
    frame = await ScenePictures(bundle: testBundle()).frameOf('estufa');
    scene = frame.scene as Estufa;
  });
  final rows = <String>[];

  bool inside(List<num> b, int x, int y) =>
      x >= b[0] && x < b[0] + b[2] && y >= b[1] && y < b[1] + b[3];

  for (final key in const ['banco1', 'banco0']) {
    test(
      '$key: every pixel of the stove is inside its box; the kitchen, its hint box and the hands',
      () {
        final e = estufaEngine(),
            s = EstufaSet(e, PpBuild(e), EstufaState.fromKey(key));
        s.k.PART_TAGS = List<String?>.filled(e.W * e.H, null);
        s.buildSet();
        final tags = s.k.PART_TAGS!, box = scene.sheet.things['estufa']!.box!;
        var n = 0, out = 0;
        for (var i = 0; i < tags.length; i++) {
          if (tags[i] != 'estufa') continue;
          n++;
          if (!inside(box, i % e.W, i ~/ e.W)) out++;
        }
        rows.add('$key estufa: $n px, $out outside $box');
        expect(n, greaterThan(0));
        expect(out, 0);
        final k = scene.sheet.things['cocina']!, kb = k.box!, hb = k.hintBox!;
        expect(kb, [0, 0, 240, 216]);
        expect(
          hb[0] >= kb[0] &&
              hb[1] >= kb[1] &&
              hb[0] + hb[2] <= kb[0] + kb[2] &&
              hb[1] + hb[3] <= kb[1] + kb[3],
          isTrue,
        );
        for (final t in const ['estufa', 'cocina']) {
          final h = scene.sheet.things[t]!.hand!,
              bx = scene.sheet.things[t]!.box!;
          expect(inside(bx, h[0], h[1]), isTrue, reason: '$t: its hand');
        }
      },
    );
  }

  // a W with nothing on the counters and the stove, the stool there, nobody, the frog away
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

  final things = <String, void Function(Map<String, dynamic> w)>{
    'olla0': (w) =>
        (w['fuegos'] as List)[0] = {'k': 'olla', 'con': 'arroz', 'n': 2},
    'olla1': (w) =>
        (w['fuegos'] as List)[1] = {'k': 'olla', 'con': 'hab', 'n': 2},
    'sarten': (w) => (w['fuegos'] as List)[0] = {
      'k': 'sarten',
      'cosas': [
        {'k': 'muslo', 'v': 'crudo', 'sal': 0},
        {'k': 'frito', 'v': 'crudo', 'sal': 0},
      ],
    },
    'saco': (w) => w['izq'] = {'saco': 3},
    'tazon': (w) => w['izq'] = {'tazon': 3},
    'bandeja': (w) => w['izq'] = {
      'bandeja': {'pollo': 3, 'huevo': 3},
    },
    'jarra': (w) => w['izq'] = {'jarra': 1},
  };
  for (final en in things.entries) {
    test('${en.key}: every pixel it draws is inside its box (with its slack)', () {
      final w = empty();
      en.value(w);
      final px = drawn(w), b = scene.box(en.key, w)!, t = scene.cosa(en.key)!;
      final m = t.m ?? 3, bm = [b[0] - m, b[1] - m, b[2] + 2 * m, b[3] + 2 * m];
      final outside = px.where((i) => !inside(bm, i % 240, i ~/ 240)).toList();
      final old = asOld[en.key];
      final out = outside
          .where((i) => old == null || !old.$1(i % 240, i ~/ 240, bm))
          .toList();
      rows.add(
        '${en.key}: ${px.length} px, ${outside.length} outside $b (slack $m)${old == null ? '' : ', all as the old: ${old.$2}'}',
      );
      expect(px, isNotEmpty);
      expect(
        out,
        isEmpty,
        reason:
            '${en.key}: ${[
              for (final i in out.take(12)) [i % 240, i ~/ 240],
            ]} outside $bm',
      );
      expect(t.si!(w), isTrue);
    });
  }

  test('hit gives each thing at the middle of its box', () {
    for (final en in {
      ...things,
      'estufa': (Map<String, dynamic> w) {},
      'cocina': (Map<String, dynamic> w) {},
    }.entries) {
      final w = empty();
      en.value(w);
      final b = scene.box(en.key, w)!;
      final got = scene.hit(b[0] + b[2] / 2, b[1] + b[3] / 2, w);
      rows.add('hit ${en.key} at its middle: $got');
      if (got != en.key) {
        expect(
          shadowedBy.containsKey('${en.key} -> $got'),
          isTrue,
          reason: '${en.key}: $got',
        );
      }
    }
  });
  tearDownAll(() => report('estufa-boxes', rows));
}
