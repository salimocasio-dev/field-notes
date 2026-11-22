// Port of historia/escenas/nevera.js's `COSA` (lines 40 to 101): every thing the scene draws, as a sprite, by its kind and
// its variant (`(COSA[k]||COSA.plato)(c)`), line for line. The background `fondo` (nevera.js:22 to :39) is not here: the
// set draws it (the sheet's `dropped`). COSA.banco (the old stool, made only by the dropped line 165) is kept with the
// others, as the table has it.
// ignore_for_file: non_constant_identifier_names

import 'package:coqui_pixel/coqui_pixel.dart';

// "#RRGGBB" colours
List<int> _hs(List<String> l) => [for (final s in l) hexColour(s)];
int _h(String s) => hexColour(s);

// JavaScript: `+x` (a number, or a story's string)
num _plus(Object? v) => v is num
    ? v
    : v is String
    ? (num.tryParse(v.trim()) ?? (v.trim().isEmpty ? 0 : double.nan))
    : v == null
    ? double.nan
    : (v == true ? 1 : 0);

// JavaScript: `n == null ? d : +n`
num _count(Object? n, num d) => n == null ? d : _plus(n);

// JavaScript: `String(v || "")`
String _str(Object? v) => !jsTruthy(v)
    ? ''
    : v is num
    ? jsNum(v)
    : '$v';

// JavaScript: `a.slice(0, n)` with n a number (NaN: none)
List<T> _slice<T>(List<T> a, num n) {
  if (n.isNaN) return const [];
  final k = n.truncate();
  return a.sublist(
    0,
    k < 0 ? (a.length + k).clamp(0, a.length) : (k < a.length ? k : a.length),
  );
}

// nevera.js: COLV. A cup or a bag in its owner's colour
final Map<String, List<int>> COLV = {
  'luis': _hs(['#2A8A3A', '#58C868']),
  'carmen': _hs(['#D05888', '#F898C0']),
  'abuelo': _hs(['#B8A070', '#E8D8A8']),
  'papa': _hs(['#2A60B0', '#58A0F0']),
  'mama': _hs(['#B02828', '#F05858']),
  'abuela': _hs(['#7A48A8', '#B888E8']),
  'coqui': _hs(['#D07818', '#F8B050']),
  'verde': _hs(['#1E7A30', '#48C060']),
  'rojo': _hs(['#B02828', '#F05858']),
  'azul': _hs(['#2A60B0', '#58A0F0']),
  'gris': _hs(['#6A6E80', '#B8BCCC']),
  'amarillo': _hs(['#C89010', '#F8D040']),
};

/// nevera.js: COSA. Each thing's sprite, by its kind [k] and its variant [c] (null: undefined). A kind the table does not
/// have is a plate (`COSA[k]||COSA.plato`).
Sprite neveraCosa(String k, Object? c) {
  switch (k) {
    // a bottle of milk: n is how many cups are left in it (0 to 4)
    case 'leche':
      {
        final b = Buf(12, 19), n = _count(c, 4);
        b.rect(2, 6, 8, 12, _h('#BFE0F0'));
        b.rect(4, 2, 4, 4, _h('#BFE0F0'));
        b.rect(2, 6, 2, 12, _h('#E4F6FC'));
        if (n > 0) {
          final h = 3 * n;
          b.rect(3, 18 - h, 6, h, _h('#FFFFFF'));
        }
        b.rect(4, 0, 4, 2, _h('#3A70B0'));
        return b.outline().done();
      }
    // a wedge of cheese with holes: n portions (0 to 3)
    case 'queso':
      {
        final b = Buf(18, 13), n = _count(c, 3);
        if (n > 0) {
          final w = 5 + 4 * n;
          for (var i = 0; i < w; i++) {
            final h = 3 + (i * 6 / (w - 1)).floor();
            b.rect(1 + i, 11 - h, 1, h, _h('#F0A010'));
            b.px(1 + i, 11 - h, _h('#FFD050'));
          }
          b.rect(1, 10, w, 1, _h('#C07808'));
          for (final q in const [
            [4, 8],
            [8, 6],
            [12, 8],
            [14, 5],
            [10, 9],
          ]) {
            if (q[0] < w - 1) b.rect(q[0], q[1], 2, 2, _h('#C07808'));
          }
        }
        return b.outline().done();
      }
    // butter on a blue dish: n portions (0 to 3)
    case 'mantequilla':
      {
        final b = Buf(20, 11), n = _count(c, 3);
        b.ell(10, 8.4, 9, 2, _hs(['#3A70B0', '#5A90D0', '#8CB8E8']));
        if (n > 0) {
          final w = 3 + 3 * n;
          b.rect(4, 3, w, 5, _h('#FFF0A0'));
          b.rect(4, 3, w, 1, _h('#FFFBE0'));
          b.rect(4, 7, w, 1, _h('#E0C860'));
          b.rect(4 + w - 1, 3, 1, 5, _h('#E0C860'));
        }
        return b.outline().done();
      }
    // a sliced loaf on a board: n slices left (0 to 6)
    case 'pan':
      {
        final b = Buf(36, 16), n = _count(c, 6);
        b.rect(1, 12, 34, 3, _h('#B07A3C'));
        b.rect(1, 12, 34, 1, _h('#D09A54'));
        for (var i = 0; i < n; i++) {
          final x = 3 + i * 5;
          b.rect(x, 3, 4, 9, _h('#F6E4B4'));
          b.rect(x, 2, 4, 2, _h('#B87A30'));
          b.rect(x, 3, 1, 9, _h('#B87A30'));
          b.rect(x + 3, 3, 1, 9, _h('#D09A54'));
        }
        return b.outline().done();
      }
    // one slice, lying flat: plain, or with cheese (q), butter (m), or both
    case 'rebanada':
      {
        final b = Buf(13, 9), v = _str(c);
        b.ell(6.5, 5, 5.4, 3, _hs(['#B87A30', '#F6E4B4', '#FFF6DC']));
        if (v.contains('m')) {
          b.ell(6.5, 4.6, 3.6, 1.8, _hs(['#FFE890', '#FFF8D0']));
        }
        if (v.contains('q')) {
          b.rect(3, 3, 7, 3, _h('#F0A010'));
          b.px(5, 4, _h('#C07808'));
          b.px(8, 3, _h('#C07808'));
        }
        return b.outline().done();
      }
    case 'frutero':
      {
        final b = Buf(44, 13);
        b.ell(22, 9, 18, 3.6, _hs(['#8A5A2A', '#B07A3C']));
        b.ell(22, 5, 21, 4.6, _hs(['#8A5A2A', '#B07A3C', '#D09A54']));
        b.ell(22, 4.6, 18, 3.2, _hs(['#5A3A1A']));
        return b.outline().done();
      }
    case 'guineo':
      {
        final b = Buf(16, 10),
            C = c == 'pardo'
                ? _hs(['#4A2E12', '#6A4A22', '#8A6A32'])
                : c == 'pelado'
                ? _hs(['#E8DCB0', '#FBF4D8', '#FFFFFF'])
                : _hs(['#C89810', '#F0C820', '#FFE860']);
        b.cap(2, 3, 8, 7, 1.9, C);
        b.cap(8, 7, 13, 3, 1.9, C);
        b.px(1, 1, _h('#5A3A1A'));
        b.px(14, 1, _h('#5A3A1A'));
        if (c == 'pelado') {
          b.rect(5, 7, 2, 3, _h('#F0C820'));
          b.rect(9, 7, 2, 3, _h('#F0C820'));
        }
        if (c == 'medio') {
          b.cap(8, 7, 13, 3, 1.9, _hs(['#E8DCB0', '#FBF4D8', '#FFFFFF']));
          b.rect(7, 7, 2, 3, _h('#F0C820'));
          b.rect(9, 8, 2, 2, _h('#C89810'));
          b.rect(5, 8, 2, 2, _h('#C89810'));
        }
        if (c == 'manchas') {
          for (final q in const [
            [4, 4],
            [7, 6],
            [10, 5],
            [12, 3],
          ]) {
            b.rect(q[0], q[1], 2, 2, _h('#20140A'));
          }
          b.px(6, 5, _h('#6A8A4A'));
          b.px(9, 6, _h('#6A8A4A'));
        }
        return b.outline().done();
      }
    case 'manzana':
      {
        final b = Buf(11, 11);
        if (c == 'cortada' || c == 'parda') {
          final C = c == 'parda'
              ? _hs(['#7A5A2A', '#A8845A'])
              : _hs(['#F0E4B8', '#FFF8E0']);
          b.ell(3, 6.5, 2.6, 3.6, C);
          b.ell(8, 6.5, 2.6, 3.6, C);
          b.rect(0, 4, 1, 5, _h('#C02020'));
          b.rect(10, 4, 1, 5, _h('#C02020'));
          b.px(3, 6, _h('#5A3A1A'));
          b.px(8, 6, _h('#5A3A1A'));
          return b.outline().done();
        }
        b.ell(3.6, 6.4, 3, 4, _hs(['#A01818', '#D02828', '#F05848']));
        b.ell(7.4, 6.4, 3, 4, _hs(['#A01818', '#D02828', '#F05848']));
        b.rect(5, 1, 1, 3, _h('#5A3A1A'));
        b.px(6, 1, _h('#48A848'));
        b.px(2, 4, _h('#FFB0A0'));
        if (c == 'manchas') {
          for (final q in const [
            [2, 6],
            [6, 7],
            [7, 4],
          ]) {
            b.rect(q[0], q[1], 3, 2, _h('#20140A'));
          }
          b.px(5, 6, _h('#6A8A4A'));
          b.px(4, 9, _h('#6A8A4A'));
        }
        return b.outline().done();
      }
    case 'china':
      {
        final b = Buf(11, 11);
        if (c == 'cortada' || c == 'seca') {
          final C = c == 'seca'
              ? _hs(['#A87A40', '#C8A068'])
              : _hs(['#F08010', '#FFB040']);
          b.ell(3, 6.5, 2.8, 3.4, C);
          b.ell(8, 6.5, 2.8, 3.4, C);
          b.px(3, 6, _h('#FFE8B0'));
          b.px(8, 6, _h('#FFE8B0'));
          return b.outline().done();
        }
        b.ell(5.5, 6, 4.4, 4.2, _hs(['#D06808', '#F08818', '#FFB040']));
        b.px(5, 2, _h('#3A8A3A'));
        b.px(6, 2, _h('#3A8A3A'));
        b.rect(3, 4, 2, 2, _h('#FFD890'));
        for (final q in const [
          [7, 6],
          [4, 8],
          [8, 8],
        ]) {
          b.px(q[0], q[1], _h('#C86008'));
        }
        return b.outline().done();
      }
    // a cup nobody can see into, in its owner's colour
    case 'vaso':
      {
        final b = Buf(10, 13),
            C = COLV[c is String ? c : null] ?? _hs(['#9494A6', '#C8C8D4']);
        b.rect(1, 1, 8, 11, C[0]);
        b.rect(1, 1, 3, 11, C[1]);
        b.rect(1, 1, 8, 1, C[1]);
        return b.outline().done();
      }
    // the same cup seen from above: full of milk, or empty
    case 'vasoarriba':
      {
        final p = _str(c).split(':'), cc = p[0], n = p.length > 1 ? p[1] : null;
        final b = Buf(16, 16), C = COLV[cc] ?? _hs(['#9494A6', '#C8C8D4']);
        b.ell(8, 8, 7, 7, [C[0], C[1]]);
        b.ell(
          8,
          8,
          5,
          5,
          n == '1' ? _hs(['#DCE8F4', '#FFFFFF']) : _hs(['#3A3A46', '#5A5A6A']),
        );
        return b.outline().done();
      }
    // a bread roll; a basket of them (n: 0 to 4); a plate of fruit; a paper bag in its owner's colour
    case 'panecillo':
      {
        final b = Buf(13, 8);
        b.ell(
          6.5,
          4.4,
          5.6,
          3,
          c == 'viejo'
              ? _hs(['#6A7A3A', '#A89A5A', '#C8B878'])
              : _hs(['#A86A20', '#D09A48', '#F0C880']),
        );
        b.rect(4, 2, 1, 3, _h('#8A5A18'));
        b.rect(8, 2, 1, 3, _h('#8A5A18'));
        if (c == 'viejo') {
          b.rect(3, 4, 2, 2, _h('#4A8A4A'));
          b.rect(8, 5, 2, 1, _h('#4A8A4A'));
        }
        return b.outline().done();
      }
    case 'cesta':
      {
        final b = Buf(34, 15), n = _count(c, 4);
        for (final q in _slice(const [
          [9, 6],
          [17, 5],
          [25, 6],
          [13, 3],
        ], n)) {
          b.ell(q[0], q[1], 5, 3, _hs(['#A86A20', '#D09A48', '#F0C880']));
          b.rect(q[0] - 1, q[1] - 2, 1, 3, _h('#8A5A18'));
        }
        b.rect(3, 7, 28, 7, _h('#B07A3C'));
        for (var x = 4; x < 31; x += 4) {
          b.rect(x, 7, 2, 7, _h('#8A5A2A'));
        }
        b.rect(2, 7, 30, 2, _h('#D09A54'));
        return b.outline().done();
      }
    case 'platofruta':
      {
        final b = Buf(22, 12);
        b.ell(11, 8.4, 10, 3, _hs(['#3A70B0', '#5A90D0', '#8CB8E8']));
        final g = c == 'vieja'
            ? _hs(['#4A2E12', '#8A7A32', '#B8A848'])
            : _hs(['#C89810', '#F0C820', '#FFE860']);
        b.cap(4, 6, 9, 8, 1.7, g);
        b.ell(
          15,
          5.4,
          3.6,
          3.4,
          c == 'vieja'
              ? _hs(['#6A2A18', '#9A4A30'])
              : _hs(['#A01818', '#D02828', '#F05848']),
        );
        b.rect(15, 1, 1, 2, _h('#5A3A1A'));
        if (c == 'vieja') {
          b.rect(13, 5, 2, 2, _h('#4A3A1A'));
          b.rect(6, 7, 2, 1, _h('#3A2A0A'));
        }
        return b.outline().done();
      }
    case 'bolsa':
      {
        final p = _str(c).split(':'), cc = p[0], n = p.length > 1 ? p[1] : null;
        final b = Buf(13, 17), C = COLV[cc] ?? _hs(['#B8A070', '#E8D8A8']);
        b.rect(1, 4, 11, 12, _h('#D8B888'));
        b.rect(1, 4, 3, 12, _h('#E8CCA0'));
        b.rect(1, 4, 11, 2, _h('#B89868'));
        b.rect(3, 9, 7, 4, C[0]);
        b.rect(4, 10, 5, 2, C[1]);
        if (n == '1') b.ell(6.5, 3, 4, 2.4, _hs(['#A86A20', '#D09A48']));
        return b.outline().done();
      }
    case 'canasta':
      {
        final b = Buf(44, 18);
        b.rect(2, 9, 40, 8, _h('#B07A3C'));
        for (var x = 3; x < 41; x += 4) {
          b.rect(x, 9, 2, 8, _h('#8A5A2A'));
        }
        b.rect(1, 1, 42, 9, _h('#D09A54'));
        for (final x in const [3, 16, 29]) {
          b.rect(x, 2, 12, 7, _h('#FFFFFF'));
          b.rect(x, 2, 12, 1, _h('#8A6A4A'));
          for (var i = 0; i < 12; i += 4) {
            b.rect(x + i, 4, 2, 2, _h('#E0403A'));
            b.rect(x + i + 2, 6, 2, 2, _h('#E0403A'));
          }
        }
        return b.outline().done();
      }
    case 'pano':
      {
        final b = Buf(16, 7);
        b.rect(1, 1, 14, 5, _h('#FFFFFF'));
        for (var x = 1; x < 15; x += 4) {
          b.rect(x, 1, 2, 5, _h('#E0403A'));
        }
        return b.outline().done();
      }
    case 'sombrero':
      {
        final b = Buf(18, 8);
        b.ell(9, 6, 8, 1.8, _hs(['#C8A860', '#E8D090']));
        b.ell(9, 3.4, 4.6, 3, _hs(['#C8A860', '#E8D090', '#F8E8B0']));
        b.rect(5, 5, 8, 1, _h('#8A5A2A'));
        return b.outline().done();
      }
    case 'bandeja':
      {
        final b = Buf(38, 6);
        b.rect(1, 2, 36, 3, _h('#9494A6'));
        b.rect(1, 2, 36, 1, _h('#C8C8D4'));
        return b.outline().done();
      }
    // a coin; the tray with six dents (n coins in it); the jar with a piragua on it; a piragua; the cart, far off
    case 'moneda':
      {
        final b = Buf(6, 6);
        b.ell(3, 3, 2.6, 2.6, _hs(['#C89010', '#F0C020', '#FFE870']));
        return b.outline().done();
      }
    case 'monedas':
      {
        final b = Buf(24, 13), n = _count(c, 6);
        b.rect(1, 1, 22, 11, _h('#8A5A2A'));
        b.rect(1, 1, 22, 1, _h('#B07A3C'));
        for (var i = 0; i < 6; i++) {
          final x = 5 + (i % 3) * 7, y = 4 + (i / 3).floor() * 5;
          b.ell(x, y, 2.6, 2, _hs(['#5A3A1A']));
          if (i < n) {
            b.ell(x, y - 0.4, 2.4, 1.8, _hs(['#C89010', '#F0C020', '#FFE870']));
          }
        }
        return b.outline().done();
      }
    case 'piragua':
      {
        final n = _count(c, 1), b = Buf(11, (9 + 4 * n).toInt());
        final C = [
          _hs(['#C02040', '#F04868', '#FF98A8']),
          _hs(['#C89010', '#F0C020', '#FFE870']),
          _hs(['#2A60B0', '#58A0F0', '#A8D0FF']),
        ];
        for (var i = 0; i < 6; i++) {
          b.rect(
            2 + (i / 2).floor(),
            3 + 4 * n + i,
            7 - 2 * (i / 2).floor(),
            1,
            i % 2 != 0 ? _h('#F2F2F8') : _h('#DCDCE8'),
          );
        }
        for (var i = 0; i < n; i++) {
          b.ell(5.5, 4 * n - 4 * i, 3.8, 3.2, C[i % 3]);
        }
        return b.outline().done();
      }
    case 'tarro':
      {
        final n = _count(c, 3), b = Buf(16, 19);
        b.rect(1, 4, 14, 14, _h('#DCF2FA'));
        b.rect(1, 4, 2, 14, _h('#F2FBFF'));
        b.rect(3, 1, 10, 3, _h('#9494A6'));
        b.rect(3, 1, 10, 1, _h('#C8C8D4'));
        b.ell(5.5, 8, 2.6, 2, _hs(['#48A848', '#78D068']));
        b.px(4, 7, _h('#20140A'));
        b.px(6, 7, _h('#20140A'));
        b.ell(11, 8, 1.8, 1.6, _hs(['#F04868']));
        b.rect(10, 9, 3, 2, _h('#F2F2F8'));
        for (var i = 0; i < n; i++) {
          b.ell(4 + i * 4, 15, 2, 2, _hs(['#8A5A08', '#F0C020', '#FFE870']));
        }
        return b.outline().done();
      }
    case 'carta':
      {
        final b = Buf(14, 17);
        b.rect(1, 2, 12, 14, _h('#FFFDF0'));
        b.rect(6, 0, 2, 3, _h('#8A5A2A'));
        if (c == 'leche') {
          b.rect(5, 6, 4, 8, _h('#FFFFFF'));
          b.rect(6, 4, 2, 2, _h('#FFFFFF'));
          b.rect(6, 3, 2, 1, _h('#3A70B0'));
          b.frame(4, 5, 6, 10, _h('#8AB4C8'));
        } else {
          for (var i = 0; i < 8; i++) {
            final h = 2 + (i * 4 / 7).floor();
            b.rect(3 + i, 13 - h, 1, h, _h('#F0A010'));
          }
          b.px(6, 11, _h('#C07808'));
          b.px(9, 10, _h('#C07808'));
        }
        return b.outline().done();
      }
    case 'corteza':
      {
        final b = Buf(14, 8);
        b.rect(1, 5, 12, 2, _h('#F0A010'));
        b.rect(1, 6, 12, 1, _h('#C07808'));
        b.rect(11, 2, 2, 4, _h('#F0A010'));
        b.px(4, 3, _h('#FFD050'));
        b.px(7, 4, _h('#FFD050'));
        b.px(5, 2, _h('#F0A010'));
        return b.outline().done();
      }
    case 'soporte':
      {
        final b = Buf(16, 7);
        b.ell(8, 4.4, 7, 2, _hs(['#6A6E80', '#B8BCCC', '#E0E2EC']));
        b.ell(8, 4, 4, 1, _hs(['#8A8EA0']));
        return b.outline().done();
      }
    case 'platoazul':
      {
        final b = Buf(20, 6);
        b.ell(10, 3, 9, 2, _hs(['#3A70B0', '#5A90D0', '#8CB8E8']));
        return b.outline().done();
      }
    case 'carrito':
      {
        final b = Buf(22, 24);
        b.rect(10, 2, 1, 12, _h('#5A3A1A'));
        b.ell(10.5, 3, 9, 2.6, _hs(['#C02040', '#F04868', '#FF98A8']));
        b.rect(3, 13, 16, 7, _h('#F2F2F8'));
        b.rect(3, 13, 16, 2, _h('#58B4EC'));
        b.ell(7, 21, 2.4, 2.4, _hs(['#3A3A46', '#6A6A7A']));
        b.ell(15, 21, 2.4, 2.4, _hs(['#3A3A46', '#6A6A7A']));
        return b.outline().done();
      }
    // a bird on the wall: sitting (0), pecking (c0, c1)
    case 'ave':
      {
        final b = Buf(11, 9), dn = c == 'c1';
        b.ell(5, 5, 3.6, 2.6, _hs(['#2A2A36', '#4A4A58', '#6A6A7A']));
        b.rect(3, 6, 5, 2, _h('#F0C020'));
        b.ell(
          dn ? 8.4 : 8,
          dn ? 5.6 : 3,
          1.8,
          1.8,
          _hs(['#2A2A36', '#4A4A58']),
        );
        b.px(8, dn ? 4 : 2, _h('#FFFFFF'));
        b.px(9, dn ? 4 : 2, _h('#FFFFFF'));
        b.rect(10, dn ? 6 : 3, 1, 1, _h('#20140A'));
        b.rect(0, 4, 2, 1, _h('#2A2A36'));
        b.rect(4, 8, 1, 1, _h('#20140A'));
        b.rect(6, 8, 1, 1, _h('#20140A'));
        return b.outline().done();
      }
    // juice things: a net of chinas (n), a jug with four marks (n marks full), a clear glass, a puddle of juice
    case 'red':
      {
        final b = Buf(18, 13), n = _count(c, 4);
        for (final q in _slice(const [
          [5, 8],
          [12, 8],
          [8, 4],
          [14, 4],
        ], n)) {
          b.ell(q[0], q[1], 3.6, 3.4, _hs(['#D06808', '#F08818', '#FFB040']));
        }
        if (n == 0 || n.isNaN) b.rect(2, 10, 14, 2, _h('#C8C8D4'));
        return b.outline().done();
      }
    case 'jarra':
      {
        final b = Buf(23, 29), n = _count(c, 4);
        b.rect(3, 3, 13, 25, _h('#DCF2FA'));
        b.rect(3, 3, 2, 25, _h('#F2FBFF'));
        if (n > 0) b.rect(4, 27 - n * 5, 11, n * 5, _h('#F08818'));
        for (var i = 1; i <= 4; i++) {
          b.rect(11, 27 - i * 5, 5, 1, _h('#4A5A6A'));
        }
        b.rect(16, 7, 3, 1, _h('#B8D8E8'));
        b.rect(19, 8, 1, 11, _h('#B8D8E8'));
        b.rect(16, 19, 3, 1, _h('#B8D8E8'));
        b.rect(1, 3, 2, 2, _h('#DCF2FA'));
        return b.outline().done();
      }
    case 'claro':
      {
        final b = Buf(9, 13);
        b.rect(1, 1, 7, 11, _h('#DCF2FA'));
        b.rect(1, 1, 2, 11, _h('#F2FBFF'));
        if (c == '1' || c == 1) b.rect(2, 3, 5, 9, _h('#F08818'));
        if (c == 'leche') b.rect(2, 3, 5, 9, _h('#FFFFFF'));
        return b.outline().done();
      }
    case 'charcoj':
      {
        final b = Buf(28, 8);
        b.ell(13, 4.4, 11, 2.4, _hs(['#D87010', '#F08818']));
        b.ell(5, 5, 4, 1.6, _hs(['#F08818']));
        b.ell(22, 3.4, 4, 1.6, _hs(['#F08818']));
        b.rect(8, 3, 7, 1, _h('#FFC060'));
        return b.outline().done();
      }
    case 'exprimidor':
      {
        final b = Buf(12, 9);
        b.ell(6, 6, 5, 2.4, _hs(['#9494A6', '#C8C8D4', '#F2F2F8']));
        b.ell(6, 3.4, 2.6, 2.6, _hs(['#C8C8D4', '#F2F2F8']));
        return b.outline().done();
      }
    case 'platopan':
      {
        final b = Buf(17, 10), n = _count(c, 2);
        b.ell(8.5, 6.6, 7.6, 2.8, _hs(['#3A70B0', '#5A90D0', '#8CB8E8']));
        for (var i = 0; i < n; i++) {
          b.ell(
            6 + i * 5,
            4.6 - i,
            3.6,
            2.2,
            _hs(['#B87A30', '#F6E4B4', '#FFF6DC']),
          );
        }
        return b.outline().done();
      }
    case 'gotaj':
      {
        final b = Buf(4, 5);
        b.rect(1, 0, 2, 4, _h('#F08818'));
        return b.outline().done();
      }
    case 'chorro':
      {
        final hh = _plus(c), h = (hh != 0 && !hh.isNaN) ? hh : 26;
        final b = Buf(7, (h + 2).toInt());
        b.rect(2, 0, 3, h - 3, _h('#F08818'));
        b.rect(2, 0, 1, h - 3, _h('#FFB040'));
        b.ell(3.5, h - 2, 2, 2, _hs(['#C06008', '#F08818']));
        return b.outline().done();
      }
    // a cup seen from above, in a round picture: orange to the brim (1) or empty (0)
    case 'vista':
      {
        final p = _str(c).split(':'), cc = p[0], n = p.length > 1 ? p[1] : null;
        final b = Buf(24, 24), C = COLV[cc] ?? _hs(['#9494A6', '#C8C8D4']);
        b.ell(12, 12, 11, 11, _hs(['#FFFFFF']));
        b.ell(12, 12, 7.4, 7.4, [C[0], C[1]]);
        b.ell(
          12,
          12,
          5.2,
          5.2,
          n == '1'
              ? _hs(['#C06008', '#F08818', '#FFB040'])
              : _hs(['#2A2A36', '#4A4A58']),
        );
        if (n == '1') b.rect(9, 9, 2, 2, _h('#FFD890'));
        return b.outline().done();
      }
    case 'platorollo':
      {
        final b = Buf(22, 12);
        b.ell(11, 8.4, 10, 3, _hs(['#3A70B0', '#5A90D0', '#8CB8E8']));
        b.ell(11, 5, 6.4, 3.4, _hs(['#A86A20', '#D09A48', '#F0C880']));
        b.rect(8, 3, 1, 3, _h('#8A5A18'));
        b.rect(13, 3, 1, 3, _h('#8A5A18'));
        return b.outline().done();
      }
    case 'platolleno':
      {
        final b = Buf(22, 14);
        b.ell(11, 10.4, 10, 3, _hs(['#3A70B0', '#5A90D0', '#8CB8E8']));
        b.ell(7.5, 6, 5.4, 4.4, _hs(['#C8C8D4', '#FFFFFF']));
        b.ell(14.5, 6.4, 5, 4, _hs(['#7A2416', '#B84A2E']));
        for (final q in const [
          [5, 5],
          [8, 3],
          [9, 7],
        ]) {
          b.rect(q[0], q[1], 2, 1, _h('#A8A090'));
        }
        for (final q in const [
          [13, 5],
          [16, 7],
          [15, 4],
        ]) {
          b.rect(q[0], q[1], 2, 1, _h('#3A0E04'));
        }
        return b.outline().done();
      }
    case 'ollaarroz':
      {
        final b = Buf(34, 24);
        b.rect(4, 8, 26, 14, _h('#8A8A9A'));
        b.rect(4, 8, 5, 14, _h('#B8B8C8'));
        b.rect(4, 19, 26, 3, _h('#5A5A6A'));
        b.rect(1, 10, 3, 4, _h('#3A3A46'));
        b.rect(30, 10, 3, 4, _h('#3A3A46'));
        b.ell(17, 8, 13, 5, _hs(['#5A5A6A', '#9494A6', '#C8C8D4']));
        b.ell(17, 8.4, 11, 3.8, _hs(['#DCDCE8', '#FFFFFF']));
        for (final q in const [
          [9, 8],
          [13, 6],
          [17, 7],
          [21, 6],
          [24, 8],
          [11, 10],
          [15, 9],
          [19, 10],
          [22, 10],
        ]) {
          b.rect(q[0], q[1], 2, 1, _h('#A8A090'));
        }
        return b.outline().done();
      }
    // a slice being buttered with a knife; a slice with a wedge of cheese laid on it
    case 'untando':
      {
        final b = Buf(22, 13);
        b.ell(10, 8, 8.4, 4, _hs(['#B87A30', '#F6E4B4', '#FFF6DC']));
        b.ell(8, 7.4, 4.6, 2.4, _hs(['#FFE060', '#FFF0A0']));
        b.line(12, 7, 20, 2, _h('#C8C8D4'));
        b.line(12, 8, 20, 3, _h('#9494A6'));
        b.rect(18, 1, 3, 2, _h('#5A3A1A'));
        return b.outline().done();
      }
    case 'conqueso':
      {
        final b = Buf(22, 13);
        b.ell(10, 8, 8.4, 4, _hs(['#B87A30', '#F6E4B4', '#FFF6DC']));
        for (var i = 0; i < 10; i++) {
          final h = 2 + (i * 4 / 9).floor();
          b.rect(5 + i, 8 - h, 1, h, _h('#F0A010'));
          b.px(5 + i, 8 - h, _h('#FFD050'));
        }
        b.rect(8, 6, 2, 2, _h('#C07808'));
        b.rect(12, 5, 2, 2, _h('#C07808'));
        return b.outline().done();
      }
    case 'claroalreves':
      {
        final b = Buf(9, 19);
        b.rect(1, 1, 7, 11, _h('#DCF2FA'));
        b.rect(1, 1, 2, 11, _h('#F2FBFF'));
        b.rect(1, 1, 7, 1, _h('#B8D8E8'));
        b.rect(4, 15, 1, 2, _h('#F08818'));
        return b.done();
      }
    case 'charco':
      {
        final b = Buf(26, 9);
        b.ell(12, 5, 10, 3, _hs(['#B8B8C8', '#F2F2F8', '#FFFFFF']));
        b.ell(22, 3, 2.4, 1.4, _hs(['#FFFFFF']));
        b.ell(3, 2, 1.6, 1, _hs(['#FFFFFF']));
        return b.outline().done();
      }
    case 'gota':
      {
        final b = Buf(4, 5);
        b.rect(1, 0, 2, 4, _h('#FFFFFF'));
        return b.outline().done();
      }
    case 'banco':
      {
        final b = Buf(26, 20);
        b.rect(2, 1, 22, 4, RP.wood[3]);
        b.rect(2, 1, 22, 1, RP.wood[4]);
        b.rect(4, 5, 3, 14, RP.wood[1]);
        b.rect(19, 5, 3, 14, RP.wood[1]);
        b.rect(5, 11, 16, 2, RP.wood[1]);
        return b.outline().done();
      }
    // `COSA[k]||COSA.plato`
    case 'plato':
    default:
      {
        final b = Buf(15, 7);
        b.ell(7.5, 3.5, 6.6, 2.8, _hs(['#3A70B0', '#5A90D0', '#8CB8E8']));
        b.ell(7.5, 3.2, 4, 1.5, _hs(['#4A80C0']));
        return b.outline().done();
      }
  }
}
