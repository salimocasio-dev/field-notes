// La mesa's touch boxes. (1) Every thing of the set lies inside its touch box: in each of its three reached states, each
// pixel the set's parts for that thing drew (mesa-set.html `part`, the last part that drew each pixel) is inside its box
// (the sheet's things.<id>.box): the table with its cloth, legs and chairs; the stove with its hood and the panel behind
// it; the kitchen (everything else the set drew, the walls, the counters, the door, the window) in its box; each thing's
// hand inside its box, each hint box inside its box. (2) The pot and its lid on the stove (the sprite layer, moves line
// 159) lie inside the pot's box (things.olla, moved with the pot). (3) hit, in the kit's order, gives each set thing's
// key at the middle of its box, but where the old order gives the point to a thing tested before it (listed in
// [shadowedBy]). The boxes of the sprite layer (a person's caja, the counter's stacks', Canelo's, the baby's) are
// relative to them, as in the old file (code lines 121 to 129): unchanged.
import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/coqui_scenes.dart';
import 'package:coqui_scenes/src/mesa/mesa.dart';
import 'package:coqui_scenes/src/mesa/mesa_set.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/report.dart';
import 'support/sheet_bundle.dart';

/// The set's parts that draw each thing of the set (mesa-set.html: `part(name, ...)`).
const Map<String, List<String>> partsOf = {
  'mesa': ['mesa', 'mesa.patas', 'sillas', 'sillas.patas'],
  'estufa': ['estufa', 'campana'],
};

/// The middles hit gives to another thing, because the kit tests that thing first, each with why.
const Map<String, String> shadowedBy = {
  'cocina -> mesa': 'the middle of the kitchen\'s box (120, 108) is on the table\'s: the kit tests the table first, and the kitchen, last in the hit order, answers everywhere off the table and the stove (the old box\'s middle, (120, 119), was off the old table)',
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Mesa scene;
  setUpAll(() async {
    scene =
        (await ScenePictures(bundle: testBundle()).frameOf('mesa')).scene
            as Mesa;
  });
  final rows = <String>[];

  bool inside(List<num> b, int x, int y) =>
      x >= b[0] && x < b[0] + b[2] && y >= b[1] && y < b[1] + b[3];
  bool within(List<num> a, List<num> b) =>
      a[0] >= b[0] &&
      a[1] >= b[1] &&
      a[0] + a[2] <= b[0] + b[2] &&
      a[1] + a[3] <= b[1] + b[3];

  for (final b in const ['m0h0', 'm1h0', 'm0h1']) {
    test('$b: every pixel of each thing of the set is inside its box', () {
      final e = mesaEngine(), s = MesaSet(e, PpBuild(e), MesaState.fromKey(b));
      s.k.PART_TAGS = List<String?>.filled(e.W * e.H, null);
      s.buildSet();
      final tags = s.k.PART_TAGS!;
      for (final en in partsOf.entries) {
        final box = scene.sheet.things[en.key]!.box!;
        var n = 0, out = 0;
        for (var i = 0; i < tags.length; i++) {
          if (!en.value.contains(tags[i])) continue;
          n++;
          if (!inside(box, i % e.W, i ~/ e.W)) out++;
        }
        rows.add('$b ${en.key}: $n px, $out outside $box');
        expect(n, greaterThan(0), reason: '$b ${en.key}');
        expect(out, 0, reason: '$b ${en.key}');
      }
      // the kitchen: everything the set drew in the view (not the dark over the cut walls) that no other thing's part drew
      final cocina = scene.sheet.things['cocina']!, cb = cocina.box!;
      var n = 0, out = 0;
      for (var i = 0; i < tags.length; i++) {
        if (e.bakedZ[i] < -1e8) continue;
        if (partsOf.values.any((l) => l.contains(tags[i]))) continue;
        final x = i % e.W;
        if (x < 22 || x >= 218) continue; // outside the one view
        n++;
        if (!inside(cb, x, i ~/ e.W)) out++;
      }
      rows.add('$b cocina: $n px, $out outside $cb');
      expect(out, 0, reason: '$b cocina');
      for (final k in const ['mesa', 'estufa', 'cocina']) {
        final t = scene.sheet.things[k]!;
        expect(
          inside(t.box!, t.hand![0], t.hand![1]),
          isTrue,
          reason: '$k: its hand',
        );
        if (t.hintBox != null) {
          expect(
            within(t.hintBox!, t.box!),
            isTrue,
            reason: '$k: its hint box',
          );
        }
      }
    });
  }

  test('the pot and its lid on the stove lie inside the pot\'s box', () {
    final box = scene.sheet.things['olla']!.box!;
    final e0 = scene.ESTUFA[0], e1 = scene.ESTUFA[1];
    // mesa.js:159 as moved: tenida(c, "olla", ESTUFA[0] + 16, ESTUFA[1] + 5), the lid at ESTUFA[1] - 7; a sprite's foot
    // is its bottom middle
    for (final (k, x, y, w, h) in [
      ('olla', e0 + 16, e1 + 5, 24, 16),
      ('ollavacia', e0 + 16, e1 + 5, 24, 18),
      ('tapa', e0 + 16, e1 - 7, 22, 7),
    ]) {
      final r = [x - (w >> 1), y - h, w, h];
      rows.add('$k at $r, the box $box');
      expect(within(r, box), isTrue, reason: k);
    }
  });

  test('hit gives each thing of the set at the middle of its box', () {
    final W = <String, dynamic>{...scene.fresh(const {})};
    (W['cq'] as Map)['vis'] = 0;
    for (final k in const ['mesa', 'estufa', 'cocina']) {
      final b = scene.box(k, W)!;
      final x = b[0] + b[2] / 2, y = b[1] + b[3] / 2;
      final got = scene.hit(x, y, W);
      rows.add('hit $k at its middle: $got');
      if (got != k) {
        expect(
          shadowedBy.containsKey('$k -> $got'),
          isTrue,
          reason: '$k: $got',
        );
      }
    }
  });
  tearDownAll(() => report('mesa-boxes', rows));
}
