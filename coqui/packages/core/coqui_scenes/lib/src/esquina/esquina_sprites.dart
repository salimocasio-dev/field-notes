// What only La esquina has, drawn in the old sprites' way (engine.js Buf, its ramps and its dark outline; kit.js mkBebe,
// mkPersona), from the Needs list of historia/notas/guiones/esquina.md: the bebé's flowers (3, 2, 1) and one flower given,
// the three balloons on strings (3, 2, 1) and one flying off, don Pepe's broom, the lit lamp of the traffic light, the
// marks in the wet cement (a wheel track, a frog print, a hand print, a heart), the card of story 48 (three flowers, each
// under a face). The looks are this file's guesses where the script gives none; the content lane looks at each one on
// docs/proyecto/pixel/port/esquina-sprites.png (tool/make_calle_sprites_test.dart).
// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/src/calle/calle_cast.dart';
import 'package:coqui_scenes/src/colmado/colmado_cast.dart';

int _h(String s) => hexColour(s);

/// The colours of the three flowers (for mamá, papá, Luis) and of the three balloons.
const List<String> _FLOWERS = ['#E0407A', '#F0C020', '#8A5AD8'];
const List<String> _BALLOONS = ['#E03C30', '#3C8AE0', '#F0C020'];

/// One flower on its stem, 7 x 12, its stem's foot at the bottom middle; [i] its colour (0, 1, 2).
Sprite mkFlor(int i) {
  final b = Buf(7, 12);
  b.rect(3, 5, 1, 7, _h('#3A8A3A'));
  b.rect(4, 8, 2, 1, _h('#56A848'));
  final c = _h(_FLOWERS[i % 3]);
  b.rect(1, 1, 5, 3, c);
  b.rect(2, 0, 3, 5, c);
  b.px(3, 2, _h('#FFE070'));
  return b.outline().done();
}

/// [n] flowers held up together (the bebé's), 15 x 14, their stems meeting at the bottom middle.
Sprite mkFlores(int n) {
  final s = Sprite(15, 14, Uint32List(15 * 14));
  final parts = <(Sprite, int, int)>[
    for (var i = 0; i < n; i++) (mkFlor(i), [4, 0, 8][i], [2, 0, 1][i]),
  ];
  return overSprite(s, parts);
}

/// [n] balloons on strings (the frog's, the bebé's), 24 x 36, the strings meeting at the bottom middle (the hand).
Sprite mkGlobos(int n) {
  final b = Buf(24, 36);
  const at = [
    [7, 6],
    [16, 5],
    [12, 12],
  ];
  for (var i = 0; i < n; i++) {
    b.line(at[i][0], at[i][1] + 5, 12, 35, _h('#F4F4F4'));
  }
  for (var i = 0; i < n; i++) {
    final c = _h(_BALLOONS[i]);
    b.ell(at[i][0], at[i][1], 4.5, 5.5, [c, c, c, _h('#FFFFFF')]);
    b.px(at[i][0] - 2, at[i][1] - 3, _h('#FFFFFF'));
    b.rect(at[i][0], at[i][1] + 5, 1, 1, c);
  }
  return b.outline().done();
}

/// The broom (esquina-preview.html's `escoba`): a pale handle and a fan of bristles at the foot, 9 x 48.
Sprite mkEscoba() {
  final b = Buf(9, 48);
  b.rect(4, 0, 2, 40, _h('#B88040'));
  b.rect(4, 0, 1, 40, _h('#D8A460'));
  b.rect(1, 38, 8, 9, _h('#D8C060'));
  b.rect(1, 38, 8, 2, _h('#B89A30'));
  for (var x = 2; x < 9; x += 2) {
    b.rect(x, 41, 1, 6, _h('#B89A30'));
  }
  return b.outline().done();
}

/// don Pepe at his door with his broom (esquina-preview.html moment 4: the broom at (33, 8) of his sprite) in [pose].
Sprite mkPepeEscoba(String pose, {bool open = false}) =>
    overSprite(mkPepe(pose, open: open), [(mkEscoba(), 33, 8)]);

/// The lit lamp of the traffic light: a disc of the lamp's size (calle-base.js trafficLight: radius .16, its dark rim
/// from r^2 .017), 9 x 9, its middle on the lamp's point. [color] `roja`, `ambar`, `verde`.
Sprite mkLampara(String color) {
  final b = Buf(9, 9);
  final c = switch (color) {
    'roja' => [_h('#C82820'), _h('#F04838'), _h('#FF8070'), _h('#FFD0C0')],
    'ambar' => [_h('#D89018'), _h('#F8B830'), _h('#FFD870'), _h('#FFF0C0')],
    _ => [_h('#20A048'), _h('#38D068'), _h('#80F0A0'), _h('#D8FFE0')],
  };
  b.ell(4, 4, 3.2, 3.2, c);
  return b.done();
}

/// A wheel's track across one part of the wet cement: a dark band with tread marks, 13 x 6.
Sprite mkRastro() {
  final b = Buf(13, 6);
  for (var x = 0; x < 13; x++) {
    final y = 3 - (x * .25).floor();
    b.rect(x, y, 1, 3, _h('#8A8A92'));
    if (x % 2 == 0) b.px(x, y + 1, _h('#6A6A72'));
  }
  return b.done();
}

/// The frog's print in the wet cement: four toes and a round foot, 7 x 6.
Sprite mkHuella() {
  final b = Buf(7, 6);
  final c = _h('#9A9AA2');
  b.ell(3.5, 4, 2, 1.6, [c]);
  for (final x in const [0, 2, 4, 6]) {
    b.px(x, x == 0 || x == 6 ? 1 : 0, c);
  }
  return b.done();
}

/// Luis's hand print in the wet cement, 8 x 8.
Sprite mkManoCemento() {
  final b = Buf(8, 8);
  final c = _h('#9A9AA2');
  b.ell(4, 5, 2.6, 2.2, [c]);
  for (var i = 0; i < 4; i++) {
    b.rect(1 + i * 2, 0, 1, 3, c);
  }
  b.rect(7, 4, 1, 2, c);
  return b.done();
}

/// A heart drawn with a finger round the prints, 21 x 17: its line only.
Sprite mkCorazonCemento() {
  final b = Buf(21, 17);
  final c = _h('#8A8A94');
  for (var t = 0.0; t < 2 * math.pi; t += .04) {
    final x = 16 * math.pow(math.sin(t), 3),
        y =
            13 * math.cos(t) -
            5 * math.cos(2 * t) -
            2 * math.cos(3 * t) -
            math.cos(4 * t);
    b.px(10 + x * .6, 7 - y * .55, c);
  }
  return b.done();
}

/// Luis kneeling at the cement (esquina-preview.html's stand-in: the sitting figure).
Sprite mkLuisRodillas({bool open = false}) =>
    mkPersona(FAM['hermano']!, 'taza', open, true);

/// A carrier's sprite with the bebé on its arm and, when [flores] > 0, the flowers in his raised hands; the bebé
/// [est] (`idle`, `clap`). abuela's at (14, 14) of her sprite, a persona's at (10, 14) (esquina-preview.html).
Sprite conBebe(
  Sprite carrier,
  bool abuela, {
  int flores = 0,
  String est = 'idle',
  bool f = false,
  int globos = 0,
}) {
  final x = abuela ? 14 : 10, y = 14;
  var s = withBebe(carrier, x, y, est: est, f: f);
  if (flores > 0) {
    final fl = mkFlores(flores);
    s = overSprite(s, [(fl, x + 13 + 2, y - 9)], top: 0);
  }
  if (globos > 0) {
    final g = mkGlobos(globos);
    s = overSprite(s, [(g, x + 13 - 12, 0)], top: 22);
  }
  return s;
}

/// Every sprite this file draws, in order, for the sheet picture (esquina-sprites.png).
List<(String, Sprite)> esquinaSpriteSheet() => [
  for (var i = 0; i < 3; i++) ('flor ${i + 1}', mkFlor(i)),
  for (var n = 3; n >= 1; n--) ('$n flores', mkFlores(n)),
  for (var n = 3; n >= 1; n--) ('$n globos', mkGlobos(n)),
  ('escoba', mkEscoba()),
  ('don Pepe con la escoba', mkPepeEscoba('idle')),
  for (final c in const ['roja', 'ambar', 'verde']) ('luz $c', mkLampara(c)),
  ('rastro de rueda', mkRastro()),
  ('huella de Coqui', mkHuella()),
  ('mano de Luis', mkManoCemento()),
  ('corazon', mkCorazonCemento()),
  ('Luis de rodillas', mkLuisRodillas()),
  for (var n = 3; n >= 1; n--)
    (
      'abuela con el bebe y $n flores',
      conBebe(mkAbuela('idle', false), true, flores: n),
    ),
  (
    'mama con el bebe y 3 globos',
    conBebe(mkPersona(FAM['mama']!, 'idle', false, false), false, globos: 3),
  ),
  (
    'papa con el bebe en alto',
    conBebe(mkPersona(FAM['papa']!, 'wave0', false, false), false, est: 'clap'),
  ),
];
