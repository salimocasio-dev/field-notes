// The sprites historia/escenas/mesa.js makes for itself, ported line for line (order 37b): the things on the table, on the
// counter, in a hand (COSA). The background (fondo, mkPuesto) and the old table (mkMesa) are the set's (the sheet's
// `dropped`). Colours are made once (`#RRGGBB` as `0xFFBBGGRR`).
// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'package:coqui_pixel/coqui_pixel.dart';

final Map<String, int> _hexes = {};

/// `"#RRGGBB"` as the int `0xFFBBGGRR`, made once.
int hx(String s) => _hexes[s] ??= hexColour(s);

List<int> _hs(List<String> l) => [for (final s in l) hx(s)];

// JavaScript: `+n` of what a sprite is given (a count)
num _plus(Object? v) => v is num
    ? v
    : (v is String ? num.tryParse(v.trim()) ?? double.nan : double.nan);

/// mesa.js: COSA. Things on the table, on the counter, in a hand. Each is drawn with its foot at the bottom middle. The
/// argument is what the old function took (`tabla(n)`: how many slices; `mancha(c)`: its colour); the others take none.
final Map<String, Sprite Function(Object? c)> COSA = {
  'plato': (_) {
    final b = Buf(13, 7);
    b.ell(6.5, 3.5, 5.6, 2.8, _hs(const ['#B8B8C8', '#F2F2F8', '#FFFFFF']));
    b.ell(6.5, 3.2, 3.2, 1.4, [hx('#DCDCE8')]);
    return b.outline().done();
  },
  'hondo': (_) {
    final b = Buf(13, 9);
    b.ell(6.5, 5.5, 4.4, 3, _hs(const ['#B8B8C8', '#DCDCE8']));
    b.ell(6.5, 3.6, 5.6, 3, _hs(const ['#B8B8C8', '#F2F2F8', '#FFFFFF']));
    b.ell(6.5, 3.4, 4, 1.9, _hs(const ['#D88820', '#F0A838']));
    return b.outline().done();
  },
  'taza': (_) {
    final b = Buf(10, 10);
    b.rect(1, 2, 6, 7, hx('#F2F2F8'));
    b.rect(1, 2, 2, 7, hx('#FFFFFF'));
    b.rect(1, 8, 6, 1, hx('#C8C8D4'));
    b.rect(7, 3, 1, 1, hx('#F2F2F8'));
    b.rect(8, 4, 1, 3, hx('#F2F2F8'));
    b.rect(7, 7, 1, 1, hx('#F2F2F8'));
    b.rect(2, 2, 4, 2, hx('#C8C8D4'));
    return b.outline().done();
  },
  'tazall': (_) {
    final b = Buf(10, 10);
    b.rect(1, 2, 6, 7, hx('#F2F2F8'));
    b.rect(1, 2, 2, 7, hx('#FFFFFF'));
    b.rect(1, 8, 6, 1, hx('#C8C8D4'));
    b.rect(7, 3, 1, 1, hx('#F2F2F8'));
    b.rect(8, 4, 1, 3, hx('#F2F2F8'));
    b.rect(7, 7, 1, 1, hx('#F2F2F8'));
    b.rect(2, 2, 4, 2, hx('#6A3214'));
    return b.outline().done();
  },
  'vaso': (_) {
    final b = Buf(10, 14);
    b.rect(1, 1, 8, 12, hx('#DCF2FA'));
    b.rect(1, 5, 8, 8, hx('#58B4EC'));
    b.rect(1, 5, 8, 1, hx('#A8DCF8'));
    b.rect(1, 1, 2, 12, hx('#F2FBFF'));
    return b.outline().done();
  },
  'vacio': (_) {
    final b = Buf(10, 14);
    b.rect(1, 1, 8, 12, hx('#E4F4FA'));
    b.rect(1, 1, 2, 12, hx('#F8FDFF'));
    return b.outline().done();
  },
  'caido': (_) {
    final b = Buf(16, 9);
    b.rect(1, 2, 12, 6, hx('#DCF2FA'));
    b.rect(1, 2, 12, 2, hx('#F8FDFF'));
    b.rect(12, 1, 2, 8, hx('#B8D8E8'));
    b.rect(1, 7, 12, 1, hx('#A8DCF8'));
    return b.outline().done();
  },
  'cuchara': (_) {
    final b = Buf(9, 18);
    b.ell(4.5, 5, 3, 4, _hs(const ['#8A8A9C', '#C8C8D4', '#F8F8FF']));
    b.rect(4, 9, 1, 8, hx('#C8C8D4'));
    return b.outline().done();
  },
  'tenedor': (_) {
    final b = Buf(9, 18);
    for (final x in const [1, 4, 7]) {
      b.rect(x, 1, 1, 6, hx('#D8D8E4'));
    }
    b.rect(1, 7, 7, 2, hx('#C8C8D4'));
    b.rect(4, 9, 1, 8, hx('#C8C8D4'));
    return b.outline().done();
  },
  'cuchillo': (_) {
    final b = Buf(9, 18);
    b.ell(4.5, 3.5, 2.2, 2.6, _hs(const ['#B8B8C8', '#DCDCE8']));
    b.rect(2, 3, 5, 7, hx('#DCDCE8'));
    b.rect(2, 3, 1, 7, hx('#FFFFFF'));
    b.rect(6, 3, 1, 7, hx('#9494A6'));
    b.rect(3, 10, 3, 1, hx('#8A8A9A'));
    b.rect(3, 11, 3, 6, hx('#4A2A12'));
    b.rect(3, 11, 1, 6, hx('#7A4A22'));
    return b.outline().done();
  },
  'bizcocho': (_) {
    final b = Buf(10, 9);
    b.rect(1, 4, 8, 4, hx('#E8B050'));
    b.rect(1, 4, 8, 1, hx('#F8DC90'));
    b.rect(1, 2, 8, 2, hx('#FFF4E0'));
    b.px(4, 1, hx('#D0302A'));
    b.px(5, 1, hx('#D0302A'));
    return b.outline().done();
  },
  'tabla': (n) {
    final b = Buf(20, 11);
    b.rect(0, 8, 20, 2, hx('#8A5A2A'));
    const ps = [
      [1, 3],
      [7, 3],
      [13, 3],
    ];
    // JavaScript: `.slice(0, n == null ? 3 : +n)`
    final m = n == null ? 3 : _plus(n);
    final end = m.isNaN ? 0 : m.clamp(0, 3).toInt();
    for (final p in ps.take(end)) {
      b.rect(p[0], p[1] + 2, 6, 3, hx('#E8B050'));
      b.rect(p[0], p[1], 6, 2, hx('#FFF4E0'));
      b.px(p[0] + 2, p[1] - 1, hx('#D0302A'));
    }
    return b.outline().done();
  },
  'pastel': (_) {
    final b = Buf(11, 11);
    b.rect(2, 6, 7, 4, hx('#C87838'));
    b.rect(3, 6, 1, 4, hx('#E09A58'));
    b.rect(6, 6, 1, 4, hx('#E09A58'));
    b.ell(5.5, 5, 4.4, 2.6, _hs(const ['#F2A0C0', '#FFC8DC', '#FFFFFF']));
    b.rect(5, 1, 2, 2, hx('#D0302A'));
    return b.outline().done();
  },
  'tazacaida': (_) {
    final b = Buf(12, 9);
    b.rect(2, 2, 8, 6, hx('#F2F2F8'));
    b.rect(2, 2, 8, 2, hx('#FFFFFF'));
    b.rect(1, 3, 2, 4, hx('#6A3214'));
    b.rect(4, 0, 3, 2, hx('#F2F2F8'));
    return b.outline().done();
  },
  'cesta': (_) {
    final b = Buf(22, 13);
    b.rect(2, 6, 18, 6, hx('#C8853C'));
    for (var x = 2; x < 20; x += 3) {
      b.rect(x, 6, 1, 6, hx('#8A5A2A'));
    }
    b.rect(1, 5, 20, 2, hx('#E2A85A'));
    for (final p in const [
      [6, 4],
      [11, 3],
      [16, 4],
    ]) {
      b.ell(p[0], p[1], 3, 2.4, _hs(const ['#A8682C', '#C8853C', '#E2A85A']));
    }
    return b.outline().done();
  },
  'panecillo': (_) {
    final b = Buf(9, 7);
    b.ell(4.5, 3.5, 3.6, 2.6, _hs(const ['#A8682C', '#C8853C', '#E2A85A']));
    b.rect(4, 2, 1, 2, hx('#F4CC88'));
    return b.outline().done();
  },
  'ollavacia': (_) {
    final b = Buf(24, 18);
    b.ell(12, 9, 9, 8, _hs(const ['#5A5A6A', '#8A8A9A', '#B8B8C8']));
    b.ell(12, 9, 7, 6, _hs(const ['#1E1E28', '#2A2A36']));
    b.rect(1, 8, 2, 3, hx('#3A3A46'));
    b.rect(21, 8, 2, 3, hx('#3A3A46'));
    return b.outline().done();
  },
  'jarronv': (_) {
    final b = Buf(14, 17);
    b.rect(2, 2, 8, 14, hx('#E4F4FA'));
    b.rect(2, 2, 2, 14, hx('#F8FDFF'));
    b.rect(10, 5, 2, 1, hx('#B8D8E8'));
    b.rect(12, 6, 1, 5, hx('#B8D8E8'));
    b.rect(10, 11, 2, 1, hx('#B8D8E8'));
    b.rect(0, 2, 2, 2, hx('#E4F4FA'));
    return b.outline().done();
  },
  'entero': (_) {
    final b = Buf(24, 13);
    b.ell(12, 8, 10.6, 4, _hs(const ['#C88A30', '#E8B050', '#F8DC90']));
    b.ell(12, 5.5, 10.6, 3.6, _hs(const ['#F2E4D0', '#FFF4E0', '#FFFFFF']));
    for (final x in const [6, 12, 18]) {
      b.px(x, 4, hx('#D0302A'));
    }
    return b.outline().done();
  },
  'roto': (_) {
    final b = Buf(17, 9);
    b.rect(1, 4, 5, 4, hx('#E8B050'));
    b.rect(1, 3, 5, 2, hx('#FFF4E0'));
    b.rect(4, 5, 2, 3, hx('#C88A30'));
    b.rect(9, 5, 4, 3, hx('#E8B050'));
    b.rect(9, 4, 4, 1, hx('#FFF4E0'));
    b.rect(9, 6, 1, 2, hx('#C88A30'));
    b.rect(7, 1, 2, 2, hx('#D0302A'));
    for (final q in const [
      [7, 7],
      [14, 7],
      [15, 4],
      [6, 2],
    ]) {
      b.px(q[0], q[1], hx('#E8B050'));
    }
    return b.outline().done();
  },
  'charco': (_) {
    final b = Buf(19, 8), C = hx('#6A3214');
    b.ell(8, 4, 5.4, 1.8, [C]);
    b.ell(12, 3, 3, 1.4, [C]);
    b.ell(4, 5, 2.4, 1.2, [C]);
    b.rect(13, 5, 3, 1, C);
    b.rect(6, 3, 3, 1, hx('#B87A4A'));
    b.outline();
    b.px(17, 6, C);
    b.px(1, 1, C);
    b.px(17, 1, C);
    return b.done();
  },
  'agua': (_) {
    final b = Buf(21, 8), C = hx('#58B4EC');
    b.ell(9, 4, 7, 2.4, [C]);
    b.ell(15, 3, 3.4, 1.6, [C]);
    b.rect(3, 6, 4, 1, C);
    b.rect(6, 3, 4, 1, hx('#C8ECFC'));
    b.outline();
    b.px(19, 6, C);
    b.px(1, 1, C);
    return b.done();
  },
  'mantelito': (_) {
    final b = Buf(34, 7);
    b.rect(1, 1, 32, 5, hx('#FFFFFF'));
    for (var x = 1; x < 33; x += 4) {
      b.rect(x, 1, 2, 5, hx('#E0403A'));
    }
    b.rect(1, 3, 32, 1, hx('#FFFFFF'));
    return b.outline().done();
  },
  'olla': (_) {
    final b = Buf(24, 16);
    b.rect(3, 5, 18, 10, hx('#8A8A9A'));
    b.rect(3, 5, 4, 10, hx('#B8B8C8'));
    b.rect(3, 13, 18, 2, hx('#5A5A6A'));
    b.rect(1, 6, 2, 3, hx('#3A3A46'));
    b.rect(21, 6, 2, 3, hx('#3A3A46'));
    b.rect(3, 4, 18, 2, hx('#C87020'));
    return b.outline().done();
  },
  'tapa': (_) {
    final b = Buf(22, 7);
    b.ell(11, 7, 9.6, 5, _hs(const ['#6A6A7A', '#9494A6', '#C8C8D4']));
    b.rect(9, 0, 4, 2, hx('#3A3A46'));
    return b.outline().done();
  },
  'jarra': (_) {
    final b = Buf(15, 14);
    b.rect(3, 3, 8, 10, hx('#A8482A'));
    b.rect(3, 3, 3, 10, hx('#D0704A'));
    b.rect(2, 2, 10, 2, hx('#7A2E18'));
    b.rect(11, 5, 2, 1, hx('#7A2E18'));
    b.rect(13, 6, 1, 4, hx('#7A2E18'));
    b.rect(11, 10, 2, 1, hx('#7A2E18'));
    b.rect(0, 3, 3, 2, hx('#A8482A'));
    return b.outline().done();
  },
  'jarron': (_) {
    final b = Buf(14, 17);
    b.rect(2, 2, 8, 14, hx('#DCF2FA'));
    b.rect(2, 6, 8, 10, hx('#58B4EC'));
    b.rect(2, 2, 2, 14, hx('#F2FBFF'));
    b.rect(10, 5, 2, 1, hx('#B8D8E8'));
    b.rect(12, 6, 1, 5, hx('#B8D8E8'));
    b.rect(10, 11, 2, 1, hx('#B8D8E8'));
    b.rect(0, 2, 2, 2, hx('#DCF2FA'));
    return b.outline().done();
  },
  'espa': (_) {
    final b = Buf(13, 8);
    b.ell(6.5, 4.6, 5, 2.6, _hs(const ['#C89A30', '#F0D070', '#FBEAA8']));
    for (final q in const [
      [2, 5],
      [4, 3],
      [6, 5],
      [8, 3],
      [10, 5],
    ]) {
      b.px(q[0], q[1], hx('#B88820'));
      b.px(q[0] + 1, q[1] + 1, hx('#B88820'));
    }
    b.ell(4.5, 2.6, 1.6, 1.5, _hs(const ['#8A2A12', '#C0401E']));
    b.ell(8.5, 2.8, 1.6, 1.5, _hs(const ['#8A2A12', '#C0401E']));
    return b.outline().done();
  },
  'pan': (_) {
    final b = Buf(14, 8);
    b.ell(4.5, 4.5, 3.6, 3, _hs(const ['#A8682C', '#C8853C', '#E2A85A']));
    b.rect(4, 3, 1, 2, hx('#F4CC88'));
    b.rect(9, 3, 4, 4, hx('#F8E060'));
    b.rect(9, 3, 4, 1, hx('#FFF4A0'));
    return b.outline().done();
  },
  'comida': (_) {
    final b = Buf(13, 7);
    b.ell(4.5, 4, 3.6, 2.4, _hs(const ['#DCDCE8', '#FFFFFF']));
    b.ell(9, 4, 3, 2.2, _hs(const ['#7A2E18', '#A8482A']));
    b.px(8, 3, hx('#D0704A'));
    return b.outline().done();
  },
  'hueso': (_) {
    final b = Buf(15, 8);
    b.rect(4, 3, 7, 2, hx('#F8F4E8'));
    for (final p in const [
      [3, 2],
      [3, 5],
      [11, 2],
      [11, 5],
    ]) {
      b.ell(p[0], p[1], 1.7, 1.7, [hx('#F8F4E8')]);
    }
    return b.outline().done();
  },
  'lio': (_) {
    final b = Buf(32, 18);
    b.ell(16, 12, 14, 5.4, _hs(const ['#C8C8D4', '#F2F2F8', '#FFFFFF']));
    b.rect(4, 14, 24, 2, hx('#D0302A'));
    b.rect(8, 9, 2, 4, hx('#D8D8E4'));
    b.rect(21, 9, 2, 4, hx('#D8D8E4'));
    b.outline();
    b.ell(8, 5, 5, 2, _hs(const ['#8A8A9A', '#DCDCE8', '#FFFFFF']));
    b.frame(2, 2, 13, 6, OUT);
    b.rect(19, 2, 6, 6, hx('#F2F2F8'));
    b.frame(18, 1, 8, 8, OUT);
    b.rect(26, 3, 2, 1, OUT);
    b.rect(28, 4, 1, 3, OUT);
    b.rect(26, 7, 2, 1, OUT);
    return b.done();
  },
  'bandeja': (_) {
    final b = Buf(30, 8);
    b.rect(1, 2, 28, 5, hx('#8A5A2A'));
    b.rect(1, 2, 28, 1, hx('#B07A3C'));
    b.rect(2, 3, 26, 3, hx('#6A421C'));
    return b.outline().done();
  },
  'florero': (_) {
    final b = Buf(13, 20);
    b.rect(4, 11, 5, 8, hx('#58B4EC'));
    b.rect(4, 11, 2, 8, hx('#A8DCF8'));
    for (final f in const [
      [3, 5, '#E0403A'],
      [9, 4, '#F0C020'],
      [6, 2, '#FF8FB8'],
    ]) {
      final fx = f[0] as int, fy = f[1] as int;
      b.rect(fx, fy + 2, 1, 9 - fy + 2, RP.grn[1]);
      b.ell(fx + .5, fy, 2.2, 2.2, [hx(f[2] as String)]);
    }
    return b.outline().done();
  },
  'pano': (_) {
    final b = Buf(12, 10);
    b.rect(1, 1, 10, 8, hx('#F8F8FF'));
    b.rect(1, 4, 10, 1, hx('#E0403A'));
    b.rect(1, 7, 10, 1, hx('#E0403A'));
    return b.outline().done();
  },
  'mancha': (c) {
    final b = Buf(15, 8), C = hx(c as String);
    b.ell(7, 4, 5.4, 2.6, [C]);
    b.ell(11, 2.5, 2, 1.3, [C]);
    b.px(2, 6, C);
    b.px(13, 6, C);
    return b.done();
  },
};
