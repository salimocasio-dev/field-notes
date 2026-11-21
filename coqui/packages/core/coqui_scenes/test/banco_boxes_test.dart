// El banco's touch boxes. (1) Every thing of the set lies inside its touch box: in each of its seven reached states,
// each pixel the set's part for that thing drew (set-kit.js `part`) is inside its box (the sheet's things.<id>.box): the
// cart (open, closed), the lamp post, the three benches; the park (the ground and everything on it under the sky line)
// in its box; the park's hint box inside its box. (2) The rolling cart (sheet carro.rolling: the set's own cart, pixel
// for pixel, moved along +y) lies inside its box, which moves with it, at every tick of its way home: from W.carroX =
// CARRO[0] down by 1.1 a frame (banco.js:196) until it has left the picture. (3) hit, in the kit's order, gives each set
// thing's key at the middle of its box in every state it shows in, but where the old order gives the point to a thing
// tested before it (listed in [shadowedBy]). The boxes of the sprite layer (a person's caja, a dog's, the pushchair's,
// the pigeons') are relative to them, as in the old file (code lines 126 to 132): unchanged.
import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/coqui_scenes.dart';
import 'package:coqui_scenes/src/banco/banco.dart';
import 'package:coqui_scenes/src/banco/banco_set.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/report.dart';
import 'support/sheet_bundle.dart';

/// The set's parts that draw each thing of the set (banco-set.html: `part(name, ...)`).
const Map<String, List<String>> partsOf = {
  'carro': ['carro'],
  'farol': ['farol'],
  'banco0': ['banco0'],
  'banco1': ['banco1'],
  'banco2': ['banco2'],
};

/// The middles hit gives to another thing, because the kit tests that thing first, each with why.
const Map<String, String> shadowedBy = {
  'parque -> banco0': 'the middle of the park\'s box (120, 128) is on the first bench: the kit tests the benches first, and the park, last in the hit order, answers everywhere off them',
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Banco scene;
  setUpAll(() async {
    scene =
        (await ScenePictures(bundle: testBundle()).frameOf('banco')).scene
            as Banco;
  });
  final rows = <String>[];

  bool inside(List<num> b, int x, int y) =>
      x >= b[0] && x < b[0] + b[2] && y >= b[1] && y < b[1] + b[3];

  for (final b in const [
    'dia.0.abierto',
    'dia.0.no',
    'tarde.0.abierto',
    'noche.0.abierto',
    'noche.0.cerrado',
    'noche.0.no',
    'noche.1.abierto',
  ]) {
    test('$b: every pixel of each thing of the set is inside its box', () {
      final e = bancoEngine(),
          s = BancoSet(e, PpBuild(e), BancoState.fromKey(b));
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
        if (en.key == 'carro' && b.endsWith('.no')) {
          expect(n, 0, reason: '$b: no cart in the set');
        } else {
          expect(n, greaterThan(0), reason: '$b ${en.key}');
        }
        expect(out, 0, reason: '$b ${en.key}');
      }
      // the park: everything the set drew under the sky (zb over -1e8) that no other thing's part drew
      final park = scene.sheet.things['parque']!, pb = park.box!;
      var out = 0;
      for (var i = 0; i < tags.length; i++) {
        if (e.bakedZ[i] < -1e8) continue;
        if (partsOf.values.any((l) => l.contains(tags[i]))) continue;
        final y = i ~/ e.W;
        if (y < pb[1]) continue; // the pole's top, the lamp's, the wire over the park's box: the sky's
        if (!inside(pb, i % e.W, y)) out++;
      }
      expect(out, 0, reason: '$b parque');
      final hb = park.hintBox!;
      expect(
        hb[0] >= pb[0] &&
            hb[1] >= pb[1] &&
            hb[0] + hb[2] <= pb[0] + pb[2] &&
            hb[1] + hb[3] <= pb[1] + pb[3],
        isTrue,
      );
      for (final k in [...partsOf.keys, 'parque']) {
        final h = scene.sheet.things[k]!.hand!,
            bx = scene.sheet.things[k]!.box!;
        expect(inside(bx, h[0], h[1]), isTrue, reason: '$k: its hand');
      }
    });
  }

  test('the rolling cart lies inside its box at every tick of its way home', () {
    final W = <String, dynamic>{
      ...scene.fresh(const {}),
      'noche': 1,
      'carro': 'cerrado',
      'carroX': scene.CARRO[0],
    };
    final e = bancoEngine(),
        s = BancoSet(e, PpBuild(e), BancoState.fromKey('noche.0.cerrado'));
    s.k.PART_TAGS = List<String?>.filled(e.W * e.H, null);
    s.buildSet();
    final cart = [
      for (var i = 0; i < e.W * e.H; i++)
        if (s.k.PART_TAGS![i] == 'carro') i,
    ];
    var ticks = 0, seen = 0;
    while (true) {
      final d = scene.cartAt(W), box = scene.box('carro', W)!;
      var shown = 0, out = 0;
      for (final i in cart) {
        final x = i % 240 + d[0], y = i ~/ 240 + d[1];
        if (x < 0 || y < 0 || x >= 240 || y >= 216) continue;
        shown++;
        if (!inside(box, x, y)) out++;
      }
      expect(out, 0, reason: 'carroX ${W['carroX']}: $out outside $box');
      if (shown == 0) break;
      seen += shown;
      ticks++;
      W['carroX'] = (W['carroX'] as num) - 1.1; // banco.js:196, each frame
    }
    rows.add(
      'the rolling cart: $ticks ticks in the picture, $seen pixels, 0 outside its box',
    );
    expect(ticks, greaterThan(30));
  });

  test('hit gives each thing of the set at the middle of its box', () {
    final W = <String, dynamic>{...scene.fresh(const {})};
    (W['cq'] as Map)['vis'] = 0;
    for (final k in [...partsOf.keys, 'parque']) {
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
  tearDownAll(() => report('banco-boxes', rows));
}
