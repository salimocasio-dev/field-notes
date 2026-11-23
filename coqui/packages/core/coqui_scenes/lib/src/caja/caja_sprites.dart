// What only La caja has in its sprite layer (the place's shared cast is lib/src/colmado/colmado_cast.dart): the numerals
// (5 x 7 for the amount and the keys, 3 x 5 for the price tags and a bill: caja-preview.html's fonts F57 and F35), the
// amount plate, the two answer keys, the price tags (front and back), the bills (a one, a twenty, three under the clip
// with the frog's drawing on it), the open drawer, the box of cans, the frying pan, the cups, pots, plates and glasses in
// a dear and a cheap make, the gift paper on its holder, a parcel with a bow, a torn sheet, a paper hat, the children's
// jar with its two lines and its level, the ball, the frog's own jar, a balloon. Drawn in the old sprites' way (engine.js
// Buf: ramps, a dark outline), the size and colours of caja-preview.html's stand-ins where it has one. The content lane
// looks at each on docs/proyecto/pixel/port/caja-sprites.png (tool/make_colmado_sprites_test.dart).
// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/src/colmado/colmado_cast.dart';

int _h(String s) => hexColour(s);
List<int> _hs(List<String> s) => [for (final x in s) hexColour(x)];

/* ---------- the numerals (caja-preview.html: F57, F35, numeral, numW) ---------- */

/// caja-preview.html F57: digits of 5 x 7 (the amount, the key cards).
const Map<String, List<String>> F57 = {
  '0': ['01110', '10001', '10011', '10101', '11001', '10001', '01110'],
  '1': ['00100', '01100', '00100', '00100', '00100', '00100', '01110'],
  '2': ['01110', '10001', '00001', '00010', '00100', '01000', '11111'],
  '3': ['11110', '00001', '00001', '01110', '00001', '00001', '11110'],
  '4': ['00010', '00110', '01010', '10010', '11111', '00010', '00010'],
  '5': ['11111', '10000', '11110', '00001', '00001', '10001', '01110'],
  '6': ['00110', '01000', '10000', '11110', '10001', '10001', '01110'],
  '7': ['11111', '00001', '00010', '00100', '01000', '01000', '01000'],
  '8': ['01110', '10001', '10001', '01110', '10001', '10001', '01110'],
  '9': ['01110', '10001', '10001', '01111', '00001', '00010', '01100'],
};

/// caja-preview.html F35: digits of 3 x 5 (the price tags, a bill).
const Map<String, List<String>> F35 = {
  '0': ['111', '101', '101', '101', '111'],
  '1': ['010', '110', '010', '010', '111'],
  '2': ['111', '001', '111', '100', '111'],
  '3': ['111', '001', '111', '001', '111'],
  '4': ['101', '101', '111', '001', '001'],
  '5': ['111', '100', '111', '001', '111'],
  '6': ['111', '100', '111', '101', '111'],
  '7': ['111', '001', '001', '010', '010'],
  '8': ['111', '101', '111', '101', '111'],
  '9': ['111', '101', '111', '001', '111'],
};

/// caja-preview.html `numeral`: calls [put] for each lit pixel of the number [n] in [font], the digits [gap] px apart,
/// each cell [k] x [k]; returns the width drawn.
int numeral(
  String n,
  Map<String, List<String>> font,
  int gap,
  int k,
  void Function(int x, int y) put,
) {
  var x = 0;
  for (final ch in n.split('')) {
    final g = font[ch];
    if (g == null) continue;
    final w = g[0].length;
    for (var r = 0; r < g.length; r++) {
      for (var c = 0; c < w; c++) {
        if (g[r][c] != '1') continue;
        for (var j = 0; j < k; j++) {
          for (var i = 0; i < k; i++) {
            put(x + c * k + i, r * k + j);
          }
        }
      }
    }
    x += w * k + gap;
  }
  return x - gap;
}

/// caja-preview.html `numW`: the width of [n] in [font].
int numW(String n, Map<String, List<String>> font, int gap, int k) =>
    n.length * font['0']![0].length * k + (n.length - 1) * gap;

/* ---------- the register's amount, the keys ---------- */

/// The amount plate (caja-sheet.json things.importe: a pale plate 13 x 9 with the amount in two numerals of 5 x 7, 1 px
/// apart; caja-preview.html's paint): [n] the amount.
Sprite mkImporte(String n, {int w = 13, int h = 9}) {
  final px = Uint32List(w * h)
    ..fillRange(0, w * h, 0xFF000000 | _rgb(226, 242, 212));
  final nw = numW(n, F57, 1, 1), x0 = (w - nw) >> 1, y0 = (h - 7) >> 1;
  numeral(n, F57, 1, 1, (x, y) {
    final X = x0 + x, Y = y0 + y;
    if (X >= 0 && X < w && Y >= 0 && Y < h) {
      px[Y * w + X] = 0xFF000000 | _rgb(20, 48, 28);
    }
  });
  return Sprite(w, h, px);
}

int _rgb(int r, int g, int b) => (b << 16) | (g << 8) | r;

/// An answer key (caja-sheet.json spots.tecla_a, tecla_b: a card of 30 x 26 over the picture; caja-preview.html's): a
/// dark edge without its corners, a gold rim, a cream face, the numeral [n] in F57 at twice its size. [lit]: pressed (the
/// face a shade darker, the numeral one row lower).
Sprite mkTecla(String n, {int w = 30, int h = 26, bool lit = false}) {
  final px = Uint32List(w * h);
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      final edge = x == 0 || y == 0 || x == w - 1 || y == h - 1,
          corner = (x == 0 || x == w - 1) && (y == 0 || y == h - 1),
          inner = x == 1 || y == 1 || x == w - 2 || y == h - 2;
      if (corner) continue;
      px[y * w + x] =
          0xFF000000 |
          (edge
              ? _rgb(30, 40, 72)
              : inner
              ? _rgb(236, 200, 90)
              : lit
              ? _rgb(232, 222, 196)
              : _rgb(250, 246, 232));
    }
  }
  final nw = numW(n, F57, 2, 2),
      nx = (w - nw) >> 1,
      ny = ((h - 14) >> 1) + (lit ? 1 : 0);
  numeral(n, F57, 2, 2, (x, y) {
    final X = nx + x, Y = ny + y;
    if (X >= 0 && X < w && Y >= 0 && Y < h) {
      px[Y * w + X] = 0xFF000000 | _rgb(30, 40, 72);
    }
  });
  return Sprite(w, h, px);
}

/* ---------- price tags ---------- */

/// A price tag seen from the front (caja-preview.html's TAG: a card on a short stick, 11 x 10, the numeral [n] in F35).
Sprite mkEtiqueta(String n) {
  final b = Buf(11, 10);
  b.rect(1, 1, 9, 7, _h('#FFF8DC'));
  b.rect(1, 1, 9, 1, _h('#FFFFFF'));
  b.rect(1, 7, 9, 1, _h('#D8C890'));
  b.rect(5, 8, 1, 1, _h('#6A4A22'));
  final nw = numW(n, F35, 1, 1);
  numeral(
    n,
    F35,
    1,
    1,
    (x, y) => b.px(1 + ((9 - nw + 1) >> 1) + x, 2 + y, _h('#2A2018')),
  );
  return b.outline().done();
}

/// A price tag seen from the back (caja-preview.html's TAG_BACK, in the sheet's tag box 11 x 10): blank card, no
/// numeral.
Sprite mkEtiquetaAtras() {
  final b = Buf(11, 10);
  b.rect(1, 1, 9, 7, _h('#E6D8A8'));
  b.rect(1, 1, 9, 1, _h('#F2E8C0'));
  b.rect(1, 7, 9, 1, _h('#C0B078'));
  b.rect(5, 8, 1, 1, _h('#6A4A22'));
  b.px(2, 2, _h('#9A7A3A'));
  return b.outline().done();
}

/* ---------- money ---------- */

/// A one-dollar bill, small (10 x 6 and its outline), green with a dark middle.
Sprite mkBillete() {
  final b = Buf(12, 8);
  b.rect(1, 1, 10, 6, _h('#6FAE5E'));
  b.rect(1, 1, 10, 1, _h('#B4DDA0'));
  b.rect(4, 3, 4, 2, _h('#3E7A3A'));
  b.rect(1, 6, 10, 1, _h('#45843C'));
  return b.outline().done();
}

/// A twenty-dollar bill with 20 on it (caja-preview.html's `billete20`).
Sprite mkBillete20() {
  final b = Buf(18, 10);
  b.rect(1, 1, 16, 8, _h('#7DBB6A'));
  b.rect(1, 1, 16, 1, _h('#C0E6AC'));
  b.rect(1, 8, 16, 1, _h('#4A8A40'));
  b.rect(2, 2, 1, 6, _h('#4A8A40'));
  b.rect(15, 2, 1, 6, _h('#4A8A40'));
  numeral('20', F35, 1, 1, (x, y) => b.px(5 + x, 3 + y, _h('#F8FFF0')));
  return b.outline().done();
}

/// The clip on the register's face with [n] bills under it (0 to 3; caja-preview.html's `billetes`, its top edge on
/// the point): a steel clip with the frog's drawing on it (a green frog's head: two eyes on a round).
Sprite mkClip(int n) {
  final b = Buf(14, 11);
  const at = [
    [3, 4],
    [1, 2],
    [0, 0],
  ];
  for (var i = 3 - math.min(3, n).toInt(); i < 3; i++) {
    final x = at[i][0], y = at[i][1];
    b.rect(x, y + 1, 10, 6, _h('#6FAE5E'));
    b.rect(x, y + 1, 10, 1, _h('#B4DDA0'));
    b.rect(x + 3, y + 3, 4, 2, _h('#3E7A3A'));
    b.rect(x, y + 6, 10, 1, _h('#45843C'));
  }
  b.rect(3, 0, 6, 3, _h('#9AA0AE'));
  b.rect(3, 0, 6, 1, _h('#D8DCE6'));
  b.rect(4, 1, 4, 2, _h('#5CC85C')); // the frog's drawing
  b.px(4, 1, _h('#FFFFFF'));
  b.px(7, 1, _h('#FFFFFF'));
  return b.outline().done();
}

/// The register's drawer pulled open: a tray seen from above and in front, its compartments of bills and coins.
Sprite mkGaveta() {
  final b = Buf(22, 9);
  b.rect(1, 1, 20, 5, _h('#3A3440'));
  for (var i = 0; i < 4; i++) {
    b.rect(2 + i * 5, 2, 4, 3, i < 2 ? _h('#6FAE5E') : _h('#2E2A34'));
    if (i < 2) b.rect(2 + i * 5, 2, 4, 1, _h('#B4DDA0'));
    if (i >= 2) {
      b.px(3 + i * 5, 3, _h('#F0C020'));
      b.px(4 + i * 5, 2, _h('#E0E4EC'));
    }
  }
  b.rect(1, 6, 20, 2, _h('#7A6A58'));
  b.rect(1, 6, 20, 1, _h('#A89880'));
  b.rect(9, 7, 4, 1, _h('#E0C060'));
  return b.outline().done();
}

/// The frog's own jar (caja.md 45: "the frog drops them into his jar"), small, with [n] bills in it (0 to 3).
Sprite mkJarra(int n) {
  final b = Buf(9, 11);
  b.rect(2, 1, 5, 1, _h('#C85A3C'));
  b.rect(1, 2, 7, 8, _h('#D8EEF6'));
  b.rect(1, 2, 1, 8, _h('#F4FBFE'));
  b.rect(6, 2, 2, 8, _h('#B4D2E0'));
  for (var i = 0; i < math.min(3, n); i++) {
    b.rect(2, 8 - i * 2, 5, 2, i % 2 == 0 ? _h('#6FAE5E') : _h('#45843C'));
  }
  return b.outline().done();
}

/* ---------- what customers set down ---------- */

/// A box of cans (caja-preview.html's `latas`): a cardboard box with two tins on it.
Sprite mkLatas() {
  final b = Buf(16, 14);
  b.rect(1, 7, 14, 6, _h('#B8803C'));
  b.rect(1, 7, 14, 1, _h('#DDB070'));
  b.rect(12, 8, 3, 5, _h('#946228'));
  b.rect(6, 9, 4, 1, _h('#E6D2A0'));
  b.rect(3, 2, 4, 5, _h('#D83A3A'));
  b.rect(3, 2, 4, 1, _h('#F58A8A'));
  b.rect(3, 4, 4, 1, _h('#F2E8D0'));
  b.rect(8, 2, 4, 5, _h('#E8C040'));
  b.rect(8, 2, 4, 1, _h('#FFEC90'));
  b.rect(8, 4, 4, 1, _h('#C0392B'));
  return b.outline().done();
}

/// A frying pan (caja.md 47: Carmen's `sarten`), black, its handle to the right.
Sprite mkSarten() {
  final b = Buf(20, 8);
  b.ell(7, 4, 6, 2.6, _hs(['#1E1E24', '#34343E', '#4C4C58']));
  b.ell(7, 3.6, 4.6, 1.6, [_h('#24242C')]);
  b.rect(13, 3, 6, 2, _h('#6A4424'));
  b.rect(13, 3, 6, 1, _h('#8A5C34'));
  return b.outline().done();
}

/// The things of story 46, each in a dear make ([cara]: larger, or finer) and a cheap one: `taza` (a large cup with a
/// gold rim; a small one with a flower), `olla` (a large pot; a small one), `plato` (a plate with a gold rim and a blue
/// pattern; a plain white one), `vaso` (a tall cut glass with a gold rim; a short plain one). Seen from the front,
/// standing on the counter. caja-preview.html's `taza` gives the size of the small cup.
Sprite mkCosa(String k, bool cara) {
  switch (k) {
    case 'taza':
      if (cara) {
        final b = Buf(15, 13);
        b.rect(2, 3, 10, 9, _h('#F2EEE6'));
        b.rect(2, 3, 2, 9, _h('#FFFFFF'));
        b.rect(10, 3, 2, 9, _h('#C9C2B4'));
        b.rect(3, 12, 8, 1, _h('#C9C2B4'));
        b.rect(2, 2, 10, 1, _h('#E8C040'));
        b.rect(2, 3, 10, 1, _h('#F6DA70'));
        b.rect(2, 10, 10, 1, _h('#E8C040'));
        b.rect(12, 4, 2, 1, _h('#C9C2B4'));
        b.rect(13, 5, 1, 4, _h('#C9C2B4'));
        b.rect(12, 9, 2, 1, _h('#C9C2B4'));
        b.rect(5, 6, 4, 2, _h('#3A6AC8'));
        return b.outline().done();
      }
      final b = Buf(13, 11);
      b.rect(2, 3, 8, 7, _h('#F2EEE6'));
      b.rect(2, 3, 2, 7, _h('#FFFFFF'));
      b.rect(8, 3, 2, 7, _h('#C9C2B4'));
      b.rect(3, 10, 6, 1, _h('#C9C2B4'));
      b.rect(2, 2, 8, 1, _h('#E6E0D2'));
      b.rect(3, 2, 6, 1, _h('#5A3418'));
      b.rect(10, 4, 2, 1, _h('#C9C2B4'));
      b.rect(11, 5, 1, 3, _h('#C9C2B4'));
      b.rect(10, 8, 2, 1, _h('#C9C2B4'));
      b.px(5, 6, _h('#E3A6B8'));
      b.px(6, 5, _h('#E3A6B8'));
      b.px(7, 6, _h('#E3A6B8'));
      b.px(6, 7, _h('#E3A6B8'));
      b.px(6, 6, _h('#F0C020'));
      return b.outline().done();
    case 'olla':
      if (cara) {
        final b = Buf(20, 14);
        b.rect(3, 4, 14, 9, _h('#B8BCC8'));
        b.rect(3, 4, 3, 9, _h('#E4E8F0'));
        b.rect(14, 4, 3, 9, _h('#8A8E9C'));
        b.rect(2, 3, 16, 2, _h('#9AA0AE'));
        b.rect(8, 1, 4, 2, _h('#5A5E6A'));
        b.rect(0, 6, 3, 2, _h('#3A3E48'));
        b.rect(17, 6, 3, 2, _h('#3A3E48'));
        return b.outline().done();
      }
      final b = Buf(15, 11);
      b.rect(3, 4, 9, 6, _h('#B8BCC8'));
      b.rect(3, 4, 2, 6, _h('#E4E8F0'));
      b.rect(10, 4, 2, 6, _h('#8A8E9C'));
      b.rect(2, 3, 11, 2, _h('#9AA0AE'));
      b.rect(6, 1, 3, 2, _h('#5A5E6A'));
      b.rect(0, 5, 3, 2, _h('#3A3E48'));
      b.rect(12, 5, 3, 2, _h('#3A3E48'));
      return b.outline().done();
    case 'plato':
      if (cara) {
        final b = Buf(17, 9);
        b.ell(8.5, 4.5, 7.5, 3.4, _hs(['#C9C2B4', '#F2EEE6', '#FFFFFF']));
        b.ell(8.5, 4.5, 4.5, 1.8, [_h('#E6E0D2')]);
        for (var x = 2; x < 15; x += 3) {
          b.px(x, 2 + (x % 2), _h('#3A6AC8'));
        }
        b.rect(3, 7, 11, 1, _h('#E8C040'));
        return b.outline().done();
      }
      final b = Buf(14, 7);
      b.ell(7, 3.5, 6, 2.6, _hs(['#C9C2B4', '#EEEAE2']));
      b.ell(7, 3.5, 3.5, 1.2, [_h('#E2DCD0')]);
      return b.outline().done();
    case 'vaso':
      if (cara) {
        final b = Buf(9, 15);
        b.rect(1, 2, 7, 12, _h('#CFE8F2'));
        b.rect(1, 2, 2, 12, _h('#F4FBFE'));
        b.rect(6, 2, 2, 12, _h('#A8CCDC'));
        b.rect(1, 1, 7, 1, _h('#E8C040'));
        for (var y = 5; y < 12; y += 3) {
          b.line(2, y, 6, y + 2, _h('#8AB4C8'));
          b.line(6, y, 2, y + 2, _h('#8AB4C8'));
        }
        return b.outline().done();
      }
      final b = Buf(8, 11);
      b.rect(1, 2, 6, 8, _h('#DCEEF4'));
      b.rect(1, 2, 2, 8, _h('#F4FBFE'));
      b.rect(5, 2, 2, 8, _h('#B4D2E0'));
      b.rect(1, 1, 6, 1, _h('#C4DCE6'));
      return b.outline().done();
  }
  throw ArgumentError.value(k, 'k', 'not a thing of story 46');
}

/// The kinds [mkCosa] draws.
const List<String> COSAS46 = ['taza', 'olla', 'plato', 'vaso'];

/// What a customer sets down (`cliente` {cosa}): `latas`, `olla` (the cheap make), `sarten`, `arroz` (the shelves'
/// rice, the cast's), or anything else: a box of cans.
Sprite mkCompra(String? k) => switch (k) {
  'olla' => mkCosa('olla', false),
  'sarten' => mkSarten(),
  'arroz' => mkGenero('arroz'),
  _ => mkLatas(),
};

/* ---------- the gift paper ---------- */

const List<String> _papeles = [
  '#F06C8C',
  '#6CB8F0',
  '#F0D45C',
  '#7CD08C',
  '#C48CF0',
];

/// The holder of gift paper with [n] sheets on it (0 to 5; caja-preview.html's `papel`: a wooden foot, the sheets
/// standing in it, each its own colour with a white top edge).
Sprite mkPapel(int n) {
  final b = Buf(20, 15);
  b.rect(1, 11, 18, 3, _h('#8A5A2C'));
  b.rect(1, 11, 18, 1, _h('#B07A44'));
  b.rect(1, 9, 1, 3, _h('#B07A44'));
  b.rect(18, 9, 1, 3, _h('#B07A44'));
  for (var k = 0; k < math.min(5, n); k++) {
    final c = _h(_papeles[k]);
    b.rect(3 + k * 3, 2 + (k % 2), 3, 9 - (k % 2), c);
    b.rect(3 + k * 3, 2 + (k % 2), 3, 1, _h('#FFFFFF'));
  }
  return b.outline().done();
}

/// A parcel wrapped in gift paper of colour [c] (0 to 4), tied with a string and a bow on top.
Sprite mkRegalo(int c, {bool grande = false}) {
  final w = grande ? 16 : 13, h = grande ? 14 : 12;
  final b = Buf(w, h);
  final col = _h(_papeles[c % _papeles.length]);
  b.rect(1, 4, w - 2, h - 5, col);
  b.rect(1, 4, w - 2, 1, _h('#FFFFFF'));
  b.rect(w ~/ 2 - 1, 4, 2, h - 5, _h('#F6F0E0'));
  b.rect(1, 4 + (h - 5) ~/ 2, w - 2, 1, _h('#F6F0E0'));
  b.rect(w ~/ 2 - 4, 1, 3, 3, _h('#E03030'));
  b.rect(w ~/ 2 + 1, 1, 3, 3, _h('#E03030'));
  b.rect(w ~/ 2 - 1, 2, 2, 2, _h('#B01818'));
  return b.outline().done();
}

/// A torn sheet of gift paper of colour [c]: two jagged halves.
Sprite mkPapelRoto(int c) {
  final b = Buf(14, 10);
  final col = _h(_papeles[c % _papeles.length]);
  for (var y = 1; y < 9; y++) {
    final cut = 6 + (y % 3) - 1;
    b.rect(1, y, cut - 1, 1, col);
    b.rect(cut + 1, y + (y.isEven ? 0 : 0), 12 - cut, 1, col);
  }
  b.rect(1, 1, 5, 1, _h('#FFFFFF'));
  return b.outline().done();
}

/// A paper hat folded from a sheet of colour [c] (caja.md 46: "folds the last sheet into a paper hat for the frog").
Sprite mkGorro(int c) {
  final b = Buf(14, 9);
  final col = _h(_papeles[c % _papeles.length]);
  for (var y = 1; y < 7; y++) {
    final half = y + 1;
    b.rect(7 - half, y, half * 2, 1, col);
  }
  b.rect(1, 7, 12, 1, _h('#FFFFFF'));
  return b.outline().done();
}

/// A balloon on a string (caja.md 46: "a line of people, each with a birthday hat or a balloon"), colour [c].
Sprite mkGlobo(int c) {
  final b = Buf(9, 18);
  final col = _h(_papeles[(c + 1) % _papeles.length]);
  b.ell(4.5, 4.5, 3.6, 4.2, [col]);
  b.px(3, 2, _h('#FFFFFF'));
  b.px(4, 9, col);
  for (var y = 10; y < 17; y++) {
    b.px(4 + (y % 2), y, _h('#6A6A70'));
  }
  return b.outline().done();
}

/* ---------- the children's jar, the ball ---------- */

/// The rows of money in the children's jar for its level (0 at the start, 1 just under the first line, 2 at it, 3 at
/// the second line; a half step between: 0.5 a little over the start).
int _filas(num level) {
  if (level >= 3) return 9;
  if (level >= 2) return 5;
  if (level >= 1) return 4;
  if (level >= .5) return 3;
  return 2;
}

/// The children's jar (caja-preview.html's `frasco`, taller: a lid, a glass body, the drawing of a ball taped to it):
/// money fills it to [level] (see [_filas]); two lines marked on the glass when [lines] (the first, lower one, at the
/// fifth row up; the second at the ninth).
Sprite mkFrasco(num level, {bool lines = true}) {
  final b = Buf(13, 18);
  b.rect(3, 1, 7, 2, _h('#C85A3C'));
  b.rect(3, 1, 7, 1, _h('#E27D5E'));
  b.rect(1, 3, 11, 13, _h('#D8EEF6'));
  b.rect(1, 3, 1, 13, _h('#F4FBFE'));
  b.rect(10, 3, 2, 13, _h('#B4D2E0'));
  b.rect(1, 16, 11, 1, _h('#9EC0D2'));
  final n = _filas(level);
  for (var r = 0; r < n; r++) {
    for (var x = 2; x < 10; x++) {
      b.px(
        x,
        15 - r,
        (x + r) % 3 == 0
            ? _h('#45843C')
            : (x + r) % 3 == 1
            ? _h('#6FAE5E')
            : _h('#F0C020'),
      );
    }
  }
  if (lines) {
    for (final r in const [11, 7]) {
      b.rect(2, r, 8, 1, _h('#2A4C9C'));
    }
  }
  // the drawing of the ball taped on the glass, above the lines
  b.ell(6, 4.5, 1.6, 1.4, [_h('#E03030')]);
  b.px(6, 4, _h('#F8F8F8'));
  return b.outline().done();
}

/// The ball (caja.md 47: in the shop window), 9 x 9: six coloured segments round its middle, a grey shade lower right.
Sprite mkBola() {
  final b = Buf(11, 11);
  const cols = [
    '#E03030',
    '#F8F8F8',
    '#3070E0',
    '#F0D030',
    '#F8F8F8',
    '#40A850',
  ];
  for (var y = 0; y < 9; y++) {
    for (var x = 0; x < 9; x++) {
      final dx = x - 4, dy = y - 4;
      if (dx * dx + dy * dy > 15) continue;
      final a = (math.atan2(dy, dx) + math.pi) / (2 * math.pi);
      final c = _h(cols[(a * 6).floor() % 6]);
      b.px(
        x + 1,
        y + 1,
        dx * dx + dy * dy > 10 && dx + dy > 2 ? _h('#7A7A86') : c,
      );
    }
  }
  b.px(5, 5, _h('#FFFFFF'));
  return b.outline().done();
}

/// Every sprite this file draws, in order, for the sheet picture (caja-sprites.png).
List<(String, Sprite)> cajaSpriteSheet() => [
  for (final n in const [
    '10',
    '11',
    '12',
    '13',
    '14',
    '15',
    '16',
    '17',
    '18',
    '19',
    '20',
  ])
    ('importe $n', mkImporte(n)),
  ('tecla 11', mkTecla('11')),
  ('tecla 11, pulsada', mkTecla('11', lit: true)),
  ('tecla 9', mkTecla('9')),
  ('tecla 20', mkTecla('20')),
  for (final n in const ['9', '11', '14', '16', '18', '20'])
    ('etiqueta $n', mkEtiqueta(n)),
  ('etiqueta de espaldas', mkEtiquetaAtras()),
  ('billete de un peso', mkBillete()),
  ('billete de veinte', mkBillete20()),
  for (var n = 3; n >= 0; n--) ('clip, $n billetes', mkClip(n)),
  ('gaveta abierta', mkGaveta()),
  for (var n = 0; n <= 3; n++) ('jarra de Coqui, $n', mkJarra(n)),
  ('caja de latas', mkLatas()),
  ('sarten', mkSarten()),
  for (final k in COSAS46) ...[
    ('$k cara', mkCosa(k, true)),
    ('$k barata', mkCosa(k, false)),
  ],
  for (var n = 5; n >= 0; n--) ('papel, $n hojas', mkPapel(n)),
  ('regalo', mkRegalo(0)),
  ('regalo grande', mkRegalo(1, grande: true)),
  ('papel roto', mkPapelRoto(2)),
  ('gorro de papel', mkGorro(3)),
  ('globo', mkGlobo(0)),
  for (final l in const [0, .5, 1, 2, 3]) ('frasco, nivel $l', mkFrasco(l)),
  ('bola', mkBola()),
];
