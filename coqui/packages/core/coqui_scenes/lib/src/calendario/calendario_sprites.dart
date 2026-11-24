// The sprites El calendario adds to La plaza's cast (plaza_cast.dart):
// - All 11 picture cards (14 × 12): frutas, bola, bingo, bicicleta, guitarra, piragua, cafe, flores, pan, pollo, jugo;
// - Sun peg (9 × 9) for story 71;
// - Balloons (3..1 tied to the left post, 24 × 20), single balloon held / floating, and burst flash (story 69);
// - Kite on the paving (28 × 14) and flying (straight, leaning, spinning), paper bows (7 × 5), and Canelo shaking a bow
//   (story 70);
// - Señora's card box (14 × 10), school bag (`gesto bulto`), baskets (empty & full with fruit/goods for story 71),
//   and Luis's parked bicycle accent for story 69.
// Every sprite uses engine.js Buf (ramps + OUT outline) and is verified on docs/proyecto/pixel/port/calendario-sprites.png.
// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'package:coqui_pixel/coqui_pixel.dart';

int _h(String s) => hexColour(s);
List<int> _hs(List<String> s) => [for (final x in s) hexColour(x)];

/// All 11 picture card keys used by stories 69, 70, and 71 (`gen_calendario.py`).
const List<String> CALENDARIO_CARTAS = [
  'frutas',
  'bola',
  'bingo',
  'bicicleta',
  'guitarra',
  'piragua',
  'cafe',
  'flores',
  'pan',
  'pollo',
  'jugo',
];

/// A picture card (14 × 12, cream card with warm frame, red tack at top middle, and small picture).
Sprite mkCartaCalendario(String kind) {
  final b = Buf(14, 12);
  b.rect(1, 1, 12, 10, _h('#FFFBEA'));
  b.rect(1, 1, 12, 1, _h('#C8AE80'));
  b.rect(1, 10, 12, 1, _h('#C8AE80'));
  b.rect(1, 1, 1, 10, _h('#C8AE80'));
  b.rect(12, 1, 1, 10, _h('#C8AE80'));

  switch (kind) {
    case 'frutas':
      b.rect(3, 8, 8, 2, _h('#C8853C'));
      b.rect(3, 8, 8, 1, _h('#E2A85A'));
      b.ell(5, 6.2, 1.7, 1.7, [_h('#F2A650')]);
      b.ell(8.5, 5.8, 1.7, 1.7, [_h('#D0403A')]);
      b.ell(7, 6.6, 1.4, 1.4, [_h('#78B050')]);
    case 'bola':
      b.ell(7, 6.5, 3.3, 3.3, _hs(['#2E6CD0', '#4A8CE8', '#78B0F6']));
      b.line(4, 6, 10, 6, _h('#FFFFFF'));
    case 'bingo':
      b.ell(7, 6.5, 3.4, 3.4, _hs(['#D8C088', '#FBF0D2']));
      b.px(6, 5, _h('#D0403A'));
      b.px(8, 7, _h('#2E6CD0'));
      b.px(5, 8, _h('#389838'));
      b.px(9, 5, _h('#B87A10'));
    case 'bicicleta':
      b.ell(4.2, 8, 2.0, 2.0, [_h('#32323E')]);
      b.ell(9.8, 8, 2.0, 2.0, [_h('#32323E')]);
      b.line(4, 8, 7, 5, _h('#D0403A'));
      b.line(7, 5, 10, 8, _h('#D0403A'));
      b.line(6, 4, 8, 4, _h('#32323E'));
    case 'guitarra':
      b.ell(5.5, 8, 2.6, 2.2, _hs(['#C8853C', '#E2A85A']));
      b.line(7, 6, 11, 3, _h('#7A4A1E'));
      b.px(5, 8, _h('#2A1810'));
    case 'piragua':
      b.line(7, 10, 4, 6, _h('#F4CC88'));
      b.line(7, 10, 10, 6, _h('#F4CC88'));
      b.rect(5, 6, 5, 1, _h('#F4CC88'));
      b.rect(4, 4, 7, 2, _h('#D0403A'));
      b.rect(5, 3, 5, 1, _h('#78B0F6'));
    case 'cafe':
      b.rect(4, 5, 6, 4, _h('#FFFFFF'));
      b.rect(4, 5, 6, 1, _h('#7A4A1E'));
      b.rect(10, 6, 2, 2, _h('#B8B8C8'));
      b.rect(3, 9, 8, 1, _h('#B8B8C8'));
    case 'flores':
      b.ell(7, 5, 2.3, 2.3, _hs(['#EC6050', '#FA9080']));
      b.px(7, 5, _h('#FFE070'));
      b.line(7, 7, 7, 10, _h('#389838'));
      b.line(7, 9, 9, 8, _h('#389838'));
    case 'pan':
      b.ell(7, 7, 4.4, 2.5, _hs(['#A8682C', '#C8853C', '#E2A85A']));
      b.line(5, 5, 6, 8, _h('#7A4A1E'));
      b.line(8, 5, 9, 8, _h('#7A4A1E'));
    case 'pollo':
      b.ell(7, 7, 4.2, 2.8, _hs(['#8A4212', '#B8601C', '#DC8430']));
      b.rect(10, 8, 2, 2, _h('#F4CC88'));
    case 'jugo':
      b.rect(4, 4, 6, 6, _h('#F2A650'));
      b.rect(4, 4, 6, 1, _h('#FFE070'));
      b.px(10, 5, _h('#FFFFFF'));
      b.rect(7, 2, 1, 4, _h('#D0403A'));
    default:
      b.rect(5, 4, 4, 4, _h('#D0403A'));
  }
  // red tack at top middle
  b.px(7, 1, _h('#D0403A'));
  return b.outline().done();
}

/// The sun peg (9 × 9) centred on column k's coloured square (`sol1..sol7`).
Sprite mkSolPeg() {
  final b = Buf(9, 9);
  b.ell(4.5, 4.5, 3.4, 3.4, _hs(['#F8C838', '#FFE070', '#FFF4B0']));
  // four tiny cardinal rays
  b.px(4, 1, _h('#FFF4B0'));
  b.px(4, 7, _h('#FFF4B0'));
  b.px(1, 4, _h('#FFF4B0'));
  b.px(7, 4, _h('#FFF4B0'));
  return b.outline().done();
}

/// [n] (1..3) balloons tied to the left post's top (`globos`, 24 × 20).
Sprite mkGlobos(int n) {
  final b = Buf(24, 20);
  final specs = <(double, double, List<int>)>[
    (6.5, 6, _hs(['#A82A26', '#D0403A', '#FA9080'])),
    (12, 5, _hs(['#B87A10', '#F8C838', '#FFF4B0'])),
    (17.5, 6, _hs(['#1E4FA8', '#4A8CE8', '#B0D4FF'])),
  ];
  final count = n.clamp(0, 3);
  for (var i = 0; i < count; i++) {
    final (x, y, cols) = specs[i];
    b.line(x.round(), (y + 5).round(), 12, 18, _h('#6E6E80'));
  }
  for (var i = 0; i < count; i++) {
    final (x, y, cols) = specs[i];
    b.ell(x, y, 3.8, 4.6, cols);
    b.px(x.round() - 1, y.round() - 2, _h('#FFFFFF'));
  }
  return b.outline().done();
}

/// A single held or floating balloon (10 × 16) in red, yellow, or blue (story 69 ending).
Sprite mkGloboSolo(int colorIdx) {
  final b = Buf(10, 16);
  final cols = switch (colorIdx % 3) {
    0 => _hs(['#A82A26', '#D0403A', '#FA9080']),
    1 => _hs(['#B87A10', '#F8C838', '#FFF4B0']),
    _ => _hs(['#1E4FA8', '#4A8CE8', '#B0D4FF']),
  };
  b.line(5, 9, 5, 14, _h('#6E6E80'));
  b.ell(5, 5, 3.5, 4.2, cols);
  b.px(4, 3, _h('#FFFFFF'));
  return b.outline().done();
}

/// A burst flash when a balloon pops (`revienta69`, 14 × 14).
Sprite mkEstallido() {
  final b = Buf(14, 14);
  final y = _h('#FFE070'), r = _h('#FA6858');
  b.line(2, 2, 11, 11, y);
  b.line(11, 2, 2, 11, y);
  b.line(7, 1, 7, 12, r);
  b.line(1, 7, 12, 7, r);
  b.rect(5, 5, 4, 4, _h('#FFFFFF'));
  return b.outline().done();
}

/// The kite lying flat on the paving (`chiringa`, 28 × 14, red & yellow diamond with wooden cross sticks).
Sprite mkChiringa() {
  final b = Buf(28, 14);
  for (var y = 1; y < 13; y++) {
    final hw = (12.5 * (1 - (y - 6.5).abs() / 6.5)).round();
    for (var x = 14 - hw; x < 14 + hw; x++) {
      b.px(x, y, x < 14 ? _h('#D0403A') : _h('#F8C838'));
    }
  }
  b.line(2, 6, 25, 6, _h('#7A4A1E'));
  b.line(14, 1, 14, 12, _h('#7A4A1E'));
  return b.outline().done();
}

/// The kite flying in the sky at the end of story 70 (`modo`: 3 straight, 2 leaning, 1 spinning).
Sprite mkChiringaVuela(int modo, int f) {
  final b = Buf(26, 26);
  final tilt = modo == 3 ? 0 : (modo == 2 ? 3 : (f % 2 == 0 ? 5 : -5));
  for (var dy = -8; dy <= 8; dy++) {
    final hw = (8.5 * (1 - dy.abs() / 8.5)).round();
    final cx = 13 + (dy * tilt) ~/ 8;
    for (var dx = -hw; dx <= hw; dx++) {
      final x = cx + dx, y = 11 + dy;
      if (x >= 1 && x < 25 && y >= 1 && y < 22) {
        b.px(x, y, dx < 0 ? _h('#D0403A') : _h('#F8C838'));
      }
    }
  }
  b.line(13, 3, 13 + tilt, 19, _h('#7A4A1E'));
  b.line(6, 11, 20, 11, _h('#7A4A1E'));
  // tail with bows matching modo (3, 2, or 1)
  b.line(13 + tilt, 19, 13 + tilt + 3, 24, _h('#6E6E80'));
  for (var i = 0; i < modo.clamp(1, 3); i++) {
    final bx = (13 + tilt + i).clamp(2, 23);
    final by = (20 + i * 2).clamp(2, 24);
    b.rect(bx - 1, by, 3, 1, _h('#EC6050'));
  }
  return b.outline().done();
}

/// One paper bow of the kite's tail (`lazo1..3`, 7 × 5).
Sprite mkLazo() {
  final b = Buf(7, 5);
  b.ell(2, 2.2, 1.6, 1.5, [_h('#EC6050')]);
  b.ell(5, 2.2, 1.6, 1.5, [_h('#EC6050')]);
  b.px(3, 2, _h('#FFE070'));
  return b.outline().done();
}

/// The señora's wooden box of picture cards (`caja`, 14 × 10).
Sprite mkCajaCalendario() {
  final b = Buf(14, 10);
  b.rect(1, 3, 12, 6, _h('#C8853C'));
  b.rect(1, 3, 12, 1, _h('#E2A85A'));
  b.rect(1, 2, 12, 2, _h('#A8682C'));
  // cards peeking out of the open box
  b.rect(4, 1, 6, 2, _h('#FFFBEA'));
  b.px(7, 1, _h('#D0403A'));
  return b.outline().done();
}

/// A school bag held up or tossed during `gesto bulto` (story 70, 10 × 10).
Sprite mkBultoEscolar() {
  final b = Buf(10, 10);
  b.rect(2, 3, 6, 6, _h('#D86828'));
  b.rect(2, 3, 6, 2, _h('#F08A3C'));
  b.rect(3, 1, 4, 2, _h('#924014'));
  b.rect(4, 5, 2, 2, _h('#F0C020'));
  return b.outline().done();
}

/// A wicker basket on a seated person's lap in story 71 (12 × 9), either empty or filled with fruit/goods (`llena`).
Sprite mkCestaCalendario({bool llena = false}) {
  final b = Buf(12, 9);
  // arched handle
  b.rect(3, 1, 6, 1, _h('#925E28'));
  b.rect(2, 2, 1, 3, _h('#925E28'));
  b.rect(9, 2, 1, 3, _h('#925E28'));
  if (llena) {
    // colourful fruit and bread peeking over the rim
    b.ell(4.5, 3.5, 1.8, 1.5, [_h('#F2A650')]);
    b.ell(7.5, 3.5, 1.8, 1.5, [_h('#D0403A')]);
    b.ell(6, 3.2, 1.5, 1.4, [_h('#78B050')]);
  }
  // woven basket body
  b.rect(2, 4, 8, 4, _h('#C88A40'));
  b.rect(2, 4, 8, 1, _h('#E6B268'));
  b.rect(3, 6, 6, 1, _h('#9E662A'));
  return b.outline().done();
}

/// Every sprite this file draws, for `tool/make_calendario_sprites_test.dart` -> `docs/proyecto/pixel/port/calendario-sprites.png`.
List<(String, Sprite)> calendarioSpritesSheet() => [
  for (final k in CALENDARIO_CARTAS) ('carta $k', mkCartaCalendario(k)),
  ('sol', mkSolPeg()),
  ('globos 3', mkGlobos(3)),
  ('globos 2', mkGlobos(2)),
  ('globos 1', mkGlobos(1)),
  ('globo rojo', mkGloboSolo(0)),
  ('globo amarillo', mkGloboSolo(1)),
  ('globo azul', mkGloboSolo(2)),
  ('estallido', mkEstallido()),
  ('chiringa', mkChiringa()),
  ('chiringa vuela 3', mkChiringaVuela(3, 0)),
  ('chiringa vuela 2', mkChiringaVuela(2, 0)),
  ('chiringa vuela 1', mkChiringaVuela(1, 0)),
  ('lazo', mkLazo()),
  ('caja', mkCajaCalendario()),
  ('bulto escolar', mkBultoEscolar()),
  ('cesta vacia', mkCestaCalendario(llena: false)),
  ('cesta llena', mkCestaCalendario(llena: true)),
];
