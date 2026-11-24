// What only El reloj (scene `reloj`, stories 63 to 65) draws, besides La plaza's cast (plaza_cast.dart): the clock's
// two turning hands, the twelve time cards (small clock faces), the plate of raw/golden/black pastelillos and fryer
// smoke/fire, the pulsing bell ring, don Tito's oil can and big winding key, the bouncing spring and open flap/shutters
// with the three wooden figures (rooster, man with guitar, small frog), the bingo cage of numbered balls, a held-up
// numbered ball, the three prizes (fruit basket, pineapple, hand of guineos), abuela's five big numeral squares, small
// player cards, and beans (reloj.md, "Needs", New sprites). Drawn in the old sprites' way (engine.js Buf, ramps, OUT).
// The content lane looks at each on docs/proyecto/pixel/port/reloj-sprites.png (tool/make_reloj_sprites_test.dart).
// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:coqui_pixel/coqui_pixel.dart';

int _h(String s) => hexColour(s);
List<int> _hs(List<String> s) => [for (final x in s) hexColour(x)];
int _round(num v) => (v + 0.5).floor();

/// A 3 × 5 pixel digit font (same as reloj-set.html and reloj-preview.html).
const List<String> _DIG = [
  '111101101101111',
  '010110010010111',
  '111001111100111',
  '111001111001111',
  '101101111001001',
  '111100111001111',
  '111100111101111',
  '111001001001001',
  '111101111101111',
  '111101111001111',
];

void _digits(Buf b, int n, int x, int y, int col) {
  final s = '$n';
  for (var k = 0; k < s.length; k++) {
    final d = _DIG[s.codeUnitAt(k) - 48];
    for (var r = 0; r < 5; r++) {
      for (var q = 0; q < 3; q++) {
        if (d[r * 3 + q] == '1') b.px(x + k * 4 + q, y + r, col);
      }
    }
  }
}

/* ---------- the clock's hands (turn about E.FACE / hands.pivot) ---------- */

/// One hand of the tower's clock: length [len] px from its pivot `(ax, ay) = (len + 3, len + 3)`, angled [deg] degrees
/// clockwise from 12 (straight up), 2 px wide with a small gold pin at the centre (reloj-preview.html `hand`).
({Sprite s, int ax, int ay}) mkManecilla(
  int len,
  double deg, {
  bool largo = true,
}) {
  final R = len + 3;
  final side = 2 * R + 2;
  final px = Uint32List(side * side);
  final c = Ctx(px, side, side);
  final a = deg * math.pi / 180;
  final col = largo ? _h('#2A2A36') : _h('#3C2C28');
  for (var t = 0.0; t <= len; t += 0.5) {
    final x = _round(R + math.sin(a) * t) - 1;
    final y = _round(R - math.cos(a) * t) - 1;
    fr(c, x, y, 2, 2, col);
  }
  // small brass centre pin
  fr(c, R - 1, R - 1, 2, 2, _h('#D8A840'));
  return (s: Sprite(side, side, px), ax: R, ay: R);
}

/* ---------- story 63: time cards, pastelillos, fryer, bell, oil can, key ---------- */

/// Time card size (reloj-sheet.json things.carta_a.box: 22 × 22).
const int CARTA_RELOJ = 22;

/// One time card over the frog (story 63): a 22 × 22 white square with a small clock face showing [hora] o'clock
/// (short hand at [hora], long hand at 12). [lit] highlights the border when touched/chosen.
Sprite mkCartaHora(int hora, {bool lit = false}) {
  final b = Buf(CARTA_RELOJ, CARTA_RELOJ);
  b.rect(0, 0, CARTA_RELOJ, CARTA_RELOJ, lit ? _h('#D06020') : _h('#2A1810'));
  b.rect(1, 1, 20, 20, lit ? _h('#FFF8D8') : _h('#FFFFFF'));
  b.rect(1, 1, 20, 1, _h('#F0EAD8'));
  b.ell(11, 11, 8, 8, [_h('#FFFBEA')]);
  for (var n = 0; n < 12; n++) {
    final a = n * math.pi / 6;
    final isQuarter = n % 3 == 0;
    b.px(
      _round(11 + math.sin(a) * 7),
      _round(11 - math.cos(a) * 7),
      isQuarter ? _h('#3A2014') : _h('#8E6440'),
    );
  }
  void hand(double len, double deg, int col) {
    final a = deg * math.pi / 180;
    b.line(11, 11, 11 + math.sin(a) * len, 11 - math.cos(a) * len, col);
  }

  hand(6.5, 0, _h('#2A1810'));
  hand(4.2, (hora % 12) * 30.0, _h('#2A1810'));
  b.px(11, 11, _h('#C03030'));
  return b.done();
}

/// The plate of pastelillos on the counter (`plato`, 14 × 7, reloj-preview.html `THING.plato`): [raw] raw ones
/// (0 to 3), [golden] golden fried ones, [black] burnt ones (shown at the ending or after frying).
Sprite mkPlatoPastelillos({int raw = 3, int golden = 0, int black = 0}) {
  final b = Buf(14, 7);
  b.ell(7, 4.4, 6.6, 2.4, _hs(['#9AA4B4', '#D8E0EC', '#F4F8FF']));
  final kinds = <String>[
    for (var i = 0; i < golden; i++) 'g',
    for (var i = 0; i < raw; i++) 'r',
    for (var i = 0; i < black; i++) 'b',
  ];
  const xs = [3.6, 7.0, 10.4];
  for (var i = 0; i < kinds.length && i < 3; i++) {
    final ramp = switch (kinds[i]) {
      'g' => _hs(['#B86A14', '#E89C28', '#FCD058']),
      'b' => _hs(['#1C181C', '#343038', '#504A54']),
      _ => _hs(['#C89A58', '#E8C078', '#F8DCA0']),
    };
    b.ell(xs[i], 3, 2.2, 1.7, ramp);
  }
  return b.outline().done();
}

/// One pastelillo held in a hand or on the ground (`raw`, `golden`, or `black`, optional [big] for the frog's).
Sprite mkPastelillo(String kind, {bool big = false}) {
  final w = big ? 11 : 8, h = big ? 7 : 6;
  final b = Buf(w, h);
  final ramp = switch (kind) {
    'golden' => _hs(['#B86A14', '#E89C28', '#FCD058']),
    'black' => _hs(['#1C181C', '#343038', '#504A54']),
    _ => _hs(['#C89A58', '#E8C078', '#F8DCA0']),
  };
  b.ell(w / 2, h / 2 + 0.5, w / 2 - 1.4, h / 2 - 1.3, ramp);
  return b.outline().done();
}

/// A puff of dark smoke rising from the fryer when a pastelillo burns (`f` 0 or 1).
Sprite mkHumo(int f) {
  final b = Buf(12, 12);
  final c = _hs(['#3A3A44', '#60606E', '#8A8A98']);
  b.ell(6 + (f == 0 ? -1 : 1), 8, 3.2, 2.6, c);
  b.ell(5 + (f == 0 ? 1 : -1), 4.5, 2.6, 2.2, c);
  return b.outline().done();
}

/// Small orange flame under the fryer when lit (`f` 0 or 1).
Sprite mkLlama(int f) {
  final b = Buf(8, 7);
  b.ell(4, 4.5, 2.6, 2.0, _hs(['#D04018', '#F08020', '#FCE050']));
  b.px(4 + (f == 0 ? 0 : 1), 1, _h('#FCE050'));
  return b.done();
}

/// Pulsing sound wave beside the clock tower when the bell rings (`f` 0 or 1).
Sprite mkCampanaOnda(int f) {
  final b = Buf(14, 14);
  final c = f == 0 ? _h('#F8D848') : _h('#FFF2A0');
  final r = f == 0 ? 4.0 : 5.5;
  for (var deg = -50; deg <= 50; deg += 15) {
    final a = deg * math.pi / 180;
    b.px(_round(2 + math.cos(a) * r), _round(7 + math.sin(a) * r), c);
    b.px(
      _round(3 + math.cos(a) * r),
      _round(7 + math.sin(a) * r),
      _h('#2A1810'),
    );
  }
  return b.done();
}

/// Don Tito's small brass oil can (story 63).
Sprite mkAceitera() {
  final b = Buf(9, 8);
  b.ell(4, 5, 2.8, 2.0, _hs(['#9A6A18', '#D8A430', '#F4D060']));
  b.line(6, 4, 8, 1, _h('#D8A430'));
  return b.outline().done();
}

/// Don Tito's big clock winding key (stories 63 and 64 endings).
Sprite mkLlaveReloj() {
  final b = Buf(11, 8);
  final g = _hs(['#9A6A18', '#D8A430', '#F4D060']);
  b.ell(3, 4, 2.4, 2.4, g);
  b.px(3, 4, _h('#2A1810'));
  b.rect(5, 3, 5, 2, g[1]);
  b.rect(8, 5, 2, 2, g[0]);
  return b.outline().done();
}

/* ---------- story 64: open flap, spring, crooked shutter, three wooden figures ---------- */

/// The open iron flap showing dark gears inside (`tapa`, 17 × 17).
Sprite mkTapaAbierta() {
  final b = Buf(17, 17);
  b.rect(1, 1, 15, 15, _h('#262834'));
  b.rect(2, 2, 13, 13, _h('#363846'));
  b.ell(6, 7, 3.2, 3.2, _hs(['#8E6418', '#C89830', '#ECC458']));
  b.ell(11, 11, 2.6, 2.6, _hs(['#7A7E90', '#B0B4C6', '#DCE0EE']));
  b.px(6, 7, _h('#262834'));
  b.px(11, 11, _h('#262834'));
  return b.outline().done();
}

/// A bouncing brass spring jumping out of the clock works (`resorte64`, `f` 0 or 1).
Sprite mkResorte(int f) {
  final b = Buf(10, 12);
  final c = _h('#ECC458');
  final d = _h('#8E6418');
  final off = f == 0 ? 0 : 1;
  for (var i = 0; i < 4; i++) {
    final y = 2 + i * 2 + off;
    if (y < 11) {
      b.line(2, y, 7, y + 1, c);
      b.px(2, y + 1, d);
    }
  }
  return b.outline().done();
}

/// A stuck crooked wooden shutter over one slot of `puertita` (15 × 11).
Sprite mkPostigoAtascado() {
  final b = Buf(15, 11);
  b.rect(2, 2, 11, 7, _h('#A46C3C'));
  b.line(1, 3, 13, 1, _h('#6E4220'));
  b.line(1, 9, 13, 7, _h('#6E4220'));
  b.rect(3, 3, 9, 5, _h('#C88C54'));
  return b.outline().done();
}

/// One of the three wooden figures that pop out of `puertita` (story 64 ending):
/// `'gallo'` (rooster), `'guitarra'` (man with guitar), `'coqui'` (small frog).
Sprite mkFiguraReloj(String quien) {
  final b = Buf(14, 13);
  switch (quien) {
    case 'gallo':
      b.ell(7, 7, 3.8, 3.2, _hs(['#D8D8CC', '#F4F4EC', '#FFFFFF']));
      b.ell(9, 4, 2.2, 2.0, _hs(['#D8D8CC', '#F4F4EC', '#FFFFFF']));
      b.rect(8, 1, 3, 2, _h('#E23232')); // comb
      b.rect(11, 4, 2, 1, _h('#F4BE3C')); // beak
      b.rect(2, 5, 3, 4, _h('#3C6E46')); // tail
      b.rect(6, 10, 1, 2, _h('#F4BE3C'));
      b.rect(8, 10, 1, 2, _h('#F4BE3C'));
    case 'guitarra':
      b.ell(5, 3.5, 2.0, 2.0, _hs(['#C48454', '#E8B48C', '#F8D4B4']));
      b.rect(3, 6, 4, 5, _h('#4A6EB8'));
      b.ell(9, 8.5, 2.4, 2.2, _hs(['#8E5424', '#C48446', '#E4A868']));
      b.line(7, 7, 12, 6, _h('#6E4220'));
    default: // small frog
      b.ell(7, 7, 4.0, 3.2, _hs(['#4E8E36', '#74B84E', '#9AD86E']));
      b.ell(5, 4, 1.5, 1.5, [_h('#FFFFFF')]);
      b.ell(9, 4, 1.5, 1.5, [_h('#FFFFFF')]);
      b.px(5, 4, _h('#20140A'));
      b.px(9, 4, _h('#20140A'));
  }
  return b.outline().done();
}

/* ---------- story 65: bingo cage, held ball, prizes, numeral squares, bean ---------- */

/// The wire cage of numbered balls on its stand (`jaula`, 20 × 22, reloj-preview.html `THING.jaula`).
Sprite mkJaula({int spin = 0}) {
  final b = Buf(20, 22);
  b.ell(10, 10, 9, 9, _hs(['#8A8EA0', '#C8CCDC', '#F0F4FC']));
  b.ell(10, 10, 7.2, 7.2, [_h('#E8ECF8')]);
  final balls = spin % 2 == 0
      ? const [
          (6.0, 8.0, '#E04A3A'),
          (11.0, 6.0, '#F8C838'),
          (13.0, 11.0, '#3A8AE0'),
          (8.0, 13.0, '#4CBC58'),
          (10.0, 10.0, '#FFFFFF'),
        ]
      : const [
          (8.0, 6.0, '#E04A3A'),
          (13.0, 8.0, '#F8C838'),
          (11.0, 13.0, '#3A8AE0'),
          (6.0, 11.0, '#4CBC58'),
          (10.0, 9.0, '#FFFFFF'),
        ];
  for (final (x, y, c) in balls) {
    b.ell(x, y, 2.2, 2.2, [_h(c)]);
  }
  b.rect(9, 19, 2, 2, _h('#6E4220'));
  b.rect(3, 20, 14, 2, _h('#92602E'));
  b.rect(17, 9 + (spin % 2), 3, 2, _h('#6E4220'));
  return b.outline().done();
}

/// A numbered bingo ball held up by the señora in the opening (story 65, `bola65 {n, muestra: 1}`).
Sprite mkBolaBingo(int n) {
  final b = Buf(18, 16);
  b.ell(9, 8, 7.8, 6.8, _hs(['#D8A020', '#F8D458', '#FFF4A8']));
  b.ell(9, 8, 6.4, 5.4, [_h('#FFFFFF')]);
  final s = '$n';
  final w = s.length * 4 - 1;
  _digits(b, n, _round((18 - w) / 2), 6, _h('#2A1810'));
  return b.outline().done();
}

/// The three prizes on the prize shelf (16 × 16, reloj-preview.html `THING.premio`):
/// 1 = basket of fruit (best), 2 = pineapple, 3 = hand of guineos.
Sprite mkPremio(int k) {
  final b = Buf(16, 16);
  if (k == 1) {
    b.rect(1, 8, 14, 7, _h('#B88040'));
    b.rect(1, 8, 14, 1, _h('#D8A460'));
    b.ell(5, 6, 3, 3, _hs(['#C03030', '#E85A4A', '#FA9080']));
    b.ell(10, 5, 3.2, 3.2, _hs(['#D8A020', '#F8C838', '#FFE070']));
    b.ell(8, 3, 2.6, 2.6, _hs(['#2E9A48', '#4CBC58', '#84DC78']));
    b.ell(12.5, 8, 2.4, 2.4, _hs(['#7A2A8A', '#A858B8', '#D090E0']));
    for (var x = 2; x < 14; x += 3) {
      b.rect(x, 11, 1, 4, _h('#92602E'));
    }
  } else if (k == 2) {
    b.ell(8, 10, 5.6, 5.6, _hs(['#B8741C', '#E0A020', '#F8C838']));
    for (var y = 6; y < 15; y += 3) {
      for (var x = 4; x < 13; x += 3) {
        b.px(x + (y % 2), y, _h('#8A4212'));
      }
    }
    for (final (x, h) in const [(5, 5), (8, 7), (11, 5)]) {
      b.rect(x, 5 - h + 3, 2, h, _h('#2E9A48'));
    }
    b.rect(6, 0, 4, 3, _h('#4CBC58'));
  } else {
    for (final (x, y, a) in const [(2, 3, 0), (5, 5, 1), (8, 7, 2)]) {
      b.cap(
        x + 1,
        y + 6,
        x + 9 + a,
        y + 3,
        1.7,
        _hs(['#C8A020', '#F8D838', '#FFF080']),
      );
      b.px(x + 9 + a, y + 3, _h('#6E4220'));
    }
    b.rect(1, 12, 5, 2, _h('#6E4220'));
  }
  return b.outline().done();
}

/// One big numeral square of abuela's bingo card (14 × 14, reloj-preview.html `THING.numero`).
Sprite mkCuadroBingo(int n) {
  final b = Buf(14, 14);
  b.rect(0, 0, 14, 14, _h('#2A1810'));
  b.rect(1, 1, 12, 12, _h('#FFF6D8'));
  b.rect(1, 1, 12, 1, _h('#FFFFFF'));
  final w = '$n'.length * 4 - 1;
  _digits(b, n, _round((14 - w) / 2), 4, _h('#2A1810'));
  return b.done();
}

/// A dry habichuela (bean) laid on a square of abuela's card (6 × 4, reloj-preview.html `THING.frijol`).
Sprite mkFrijol() {
  final b = Buf(6, 4);
  b.ell(3, 2, 2.6, 1.8, _hs(['#6E4A2A', '#A07A4A', '#D8B880']));
  return b.outline().done();
}

/// A small bingo card on another player's table (Luis, the señor, don Tito) with [beans] dots.
Sprite mkCartonChico(int beans) {
  final b = Buf(12, 8);
  b.rect(1, 1, 10, 6, _h('#FFF6D8'));
  b.rect(1, 1, 10, 1, _h('#E85A4A'));
  for (var i = 0; i < beans.clamp(0, 5); i++) {
    b.px(2 + (i % 3) * 3, 3 + (i ~/ 3) * 2, _h('#6E4A2A'));
  }
  return b.outline().done();
}

/// All sprites of this file for docs/proyecto/pixel/port/reloj-sprites.png (tool/make_reloj_sprites_test.dart).
List<(String, Sprite)> relojSpriteSheet() => [
  ('mano larga 0', mkManecilla(19, 0, largo: true).s),
  ('mano larga 90', mkManecilla(19, 90, largo: true).s),
  ('mano larga 180', mkManecilla(19, 180, largo: true).s),
  ('mano corta 150 (5h)', mkManecilla(12, 150, largo: false).s),
  for (var h = 1; h <= 12; h++) ('carta $h h', mkCartaHora(h)),
  ('plato 3 crudos', mkPlatoPastelillos(raw: 3)),
  ('plato 2 crudos', mkPlatoPastelillos(raw: 2)),
  ('plato 3 dorados', mkPlatoPastelillos(raw: 0, golden: 3)),
  ('plato 2 dorados 1 negro', mkPlatoPastelillos(raw: 0, golden: 2, black: 1)),
  ('plato 1 dorado 2 negros', mkPlatoPastelillos(raw: 0, golden: 1, black: 2)),
  ('pastelillo dorado', mkPastelillo('golden')),
  ('pastelillo dorado grande', mkPastelillo('golden', big: true)),
  ('pastelillo negro', mkPastelillo('black')),
  ('humo 0', mkHumo(0)),
  ('humo 1', mkHumo(1)),
  ('llama 0', mkLlama(0)),
  ('campana onda 0', mkCampanaOnda(0)),
  ('aceitera', mkAceitera()),
  ('llave reloj', mkLlaveReloj()),
  ('tapa abierta', mkTapaAbierta()),
  ('resorte 0', mkResorte(0)),
  ('postigo atascado', mkPostigoAtascado()),
  ('figura gallo', mkFiguraReloj('gallo')),
  ('figura guitarra', mkFiguraReloj('guitarra')),
  ('figura coqui', mkFiguraReloj('coqui')),
  ('jaula 0', mkJaula(spin: 0)),
  ('jaula 1', mkJaula(spin: 1)),
  ('bola 90', mkBolaBingo(90)),
  ('bola 100', mkBolaBingo(100)),
  ('premio 1 canasta', mkPremio(1)),
  ('premio 2 pina', mkPremio(2)),
  ('premio 3 guineos', mkPremio(3)),
  for (final n in const [40, 60, 80, 90, 100]) ('cuadro $n', mkCuadroBingo(n)),
  ('frijol', mkFrijol()),
  ('carton chico 4', mkCartonChico(4)),
];
