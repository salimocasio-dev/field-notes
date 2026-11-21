// The sprites historia/escenas/banco.js makes for itself, ported line for line (order 36b): the piragua cart (mkCarro,
// kept: the set draws the standing cart now and the rolling one is the set's own pixels, sheet carro), the small
// things (COSA), the pigeon (mkPaloma), the dogs (mkCan), the pushchair (mkCoche). The background (fondo) is the set's
// (the sheet's `dropped`). Colours are made once (`#RRGGBB` as `0xFFBBGGRR`).
// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'package:coqui_pixel/coqui_pixel.dart';

final Map<String, int> _hexes = {};

/// `"#RRGGBB"` as the int `0xFFBBGGRR`, made once.
int hx(String s) => _hexes[s] ??= hexColour(s);

List<int> _hs(List<String> l) => [for (final s in l) hx(s)];

// banco.js: mkCarro. The piragua cart: a box on two wheels, a block of ice, bottles of syrup, an umbrella
Sprite mkCarro(bool cerrado) {
  final b = Buf(48, 74);
  b.rect(23, 14, 2, 34, hx('#6E6E80'));
  if (cerrado) {
    b.rect(21, 2, 6, 26, hx('#E0483A'));
    b.rect(23, 2, 2, 26, hx('#F2F2F8'));
    b.frame(20, 1, 8, 28, OUT);
  } else {
    for (var i = 0; i < 5; i++) {
      final c = i % 2 != 0 ? hx('#F2F2F8') : hx('#E0483A');
      b.rect(4 + i * 8, 6 + (2 - i).abs() * 2, 8, 7 - (2 - i).abs(), c);
    }
    b.rect(3, 12, 42, 2, hx('#B8302A'));
    b.ell(24, 5, 4, 3, [hx('#E0483A')]);
  }
  b.rect(5, 46, 38, 18, hx('#3A9AD0'));
  b.rect(5, 46, 38, 3, hx('#7AC4EC'));
  b.rect(5, 61, 38, 3, hx('#1E6A9A'));
  b.frame(4, 45, 40, 20, OUT);
  b.rect(10, 51, 28, 7, hx('#F2F2F8'));
  for (final k in const [
    [13, 52, '#E0483A'],
    [19, 52, '#F0C020'],
    [25, 52, '#3E9A52'],
    [31, 52, '#7A56B0'],
  ]) {
    b.rect(k[0] as int, k[1] as int, 3, 5, hx(k[2] as String));
  }
  b.rect(8, 36, 13, 10, hx('#DCEEFF'));
  b.rect(8, 36, 13, 2, hx('#FFFFFF'));
  b.frame(7, 35, 15, 12, hx('#7AA8C8'));
  for (final k in const [
    [26, 38, '#E0483A'],
    [31, 38, '#F0C020'],
    [36, 38, '#3E9A52'],
  ]) {
    final x = k[0] as int, y = k[1] as int;
    b.rect(x, y, 4, 8, hx(k[2] as String));
    b.rect(x + 1, y - 3, 2, 3, hx('#C8C8D4'));
  }
  for (final x in const [12, 36]) {
    b.ell(x, 68, 6, 6, const [OUT]);
    b.ell(x, 68, 5, 5, _hs(const ['#5A5A6A', '#8A8A9A']));
    b.ell(x, 68, 1.5, 1.5, [hx('#C8C8D4')]);
  }
  return b.done();
}

// banco.js: COSA. Small things, each drawn with its foot at the bottom middle
final Map<String, Sprite Function()> COSA = {
  'piragua': () {
    final b = Buf(9, 13);
    b.ell(4.5, 4, 3.6, 3.4, _hs(const ['#E0483A', '#FFFFFF', '#FFFFFF']));
    b.rect(2, 2, 2, 2, hx('#E0483A'));
    for (var y = 0; y < 6; y++) {
      b.rect(
        2 + (y * .42).floor(),
        7 + y,
        5 - (y * .84).floor(),
        1,
        hx('#F4E2B4'),
      );
    }
    b.px(4, 12, hx('#D8BC8A'));
    return b.outline().done();
  },
  'piragua3': () {
    final b = Buf(13, 18);
    b.ell(6.5, 6, 5.6, 5.2, [hx('#FFFFFF')]);
    b.rect(1, 5, 4, 4, hx('#E0483A'));
    b.rect(5, 1, 4, 7, hx('#F0C020'));
    b.rect(9, 5, 3, 4, hx('#3A9AD0'));
    b.rect(3, 2, 2, 3, hx('#E0483A'));
    b.rect(9, 2, 2, 3, hx('#3A9AD0'));
    for (var y = 0; y < 8; y++) {
      b.rect(
        3 + (y * .45).floor(),
        10 + y,
        7 - (y * .9).floor(),
        1,
        hx('#F4E2B4'),
      );
    }
    b.px(6, 17, hx('#D8BC8A'));
    return b.outline().done();
  },
  'papel': () {
    final b = Buf(7, 8);
    for (var y = 0; y < 6; y++) {
      b.rect(
        1 + (y * .42).floor(),
        1 + y,
        5 - (y * .84).floor(),
        1,
        hx('#F4E2B4'),
      );
    }
    b.px(3, 7, hx('#D8BC8A'));
    return b.outline().done();
  },
  'agua': () {
    final b = Buf(7, 13);
    b.rect(1, 4, 5, 8, hx('#9CD8F0'));
    b.rect(1, 4, 2, 8, hx('#DCF2FA'));
    b.rect(2, 1, 3, 3, hx('#DCF2FA'));
    b.rect(1, 6, 5, 1, hx('#FFFFFF'));
    b.rect(2, 0, 3, 1, hx('#7AA8C8'));
    return b.outline().done();
  },
  'vacia': () {
    final b = Buf(7, 13);
    b.rect(1, 4, 5, 8, hx('#EAF6FA'));
    b.rect(2, 1, 3, 3, hx('#EAF6FA'));
    b.rect(1, 11, 5, 1, hx('#9CD8F0'));
    b.rect(2, 0, 3, 1, hx('#7AA8C8'));
    return b.outline().done();
  },
  'sombrero': () {
    final b = Buf(16, 8);
    b.rect(4, 1, 8, 5, hx('#6A4A2A'));
    b.rect(4, 1, 8, 1, hx('#8A6A44'));
    b.rect(4, 4, 8, 1, hx('#2A1A0E'));
    b.rect(1, 6, 14, 1, hx('#6A4A2A'));
    return b.outline().done();
  },
  'sombrilla': () {
    final b = Buf(11, 32);
    b.rect(5, 6, 1, 24, hx('#3A3A46'));
    for (var y = 8; y < 28; y++) {
      final w = y < 12
          ? 1 + ((y - 8) >> 1)
          : y > 23
          ? 3 - ((y - 24) >> 1)
          : 3;
      b.rect(
        5 - w,
        y,
        w * 2 + 1,
        1,
        (y + ((y >> 2) % 2)) % 5 == 0 ? hx('#16203A') : hx('#2A3C6E'),
      );
    }
    b.rect(5, 1, 1, 6, hx('#8A5A2A'));
    b.rect(6, 0, 3, 1, hx('#8A5A2A'));
    b.rect(9, 1, 1, 3, hx('#8A5A2A'));
    b.rect(5, 30, 1, 2, hx('#C8C8D4'));
    return b.outline().done();
  },
  'billetera': () {
    final b = Buf(15, 11);
    b.rect(1, 1, 13, 9, hx('#8A5A2A'));
    b.rect(1, 1, 13, 2, hx('#B8854A'));
    b.rect(1, 5, 13, 1, hx('#5A3A1A'));
    b.rect(6, 4, 3, 3, hx('#F0C020'));
    return b.outline().done();
  },
  'mochila': () {
    final b = Buf(15, 17);
    b.rect(1, 3, 13, 13, hx('#E88A2A'));
    b.rect(1, 3, 13, 2, hx('#F8B860'));
    b.rect(3, 8, 9, 6, hx('#B85A14'));
    b.rect(3, 8, 9, 1, hx('#F8B860'));
    b.rect(5, 0, 5, 3, hx('#B85A14'));
    b.px(7, 11, hx('#F2F2F8'));
    return b.outline().done();
  },
  'baston': () {
    final b = Buf(8, 30);
    b.rect(3, 3, 2, 26, hx('#8A5A2A'));
    b.rect(3, 1, 5, 2, hx('#8A5A2A'));
    b.rect(7, 2, 1, 3, hx('#8A5A2A'));
    b.rect(3, 28, 2, 1, hx('#3A3A46'));
    return b.outline().done();
  },
  'cartera': () {
    final b = Buf(13, 13);
    b.rect(1, 5, 11, 7, hx('#A8283C'));
    b.rect(1, 5, 11, 2, hx('#D0485C'));
    b.px(6, 8, hx('#F0C020'));
    b.rect(3, 1, 1, 4, hx('#7A1C2A'));
    b.rect(9, 1, 1, 4, hx('#7A1C2A'));
    b.rect(3, 0, 7, 1, hx('#7A1C2A'));
    return b.outline().done();
  },
  'gorra': () {
    final b = Buf(14, 7);
    b.rect(1, 1, 9, 5, hx('#D0302A'));
    b.rect(1, 1, 9, 1, hx('#F0605A'));
    b.rect(9, 4, 5, 2, hx('#A82020'));
    return b.outline().done();
  },
  'periodico': () {
    final b = Buf(15, 8);
    b.rect(1, 1, 13, 6, hx('#F2F2F8'));
    for (final y in const [2, 4]) {
      b.rect(2, y, 11, 1, hx('#9494A6'));
    }
    b.rect(7, 1, 1, 6, hx('#C8C8D4'));
    return b.outline().done();
  },
  'bolsa': () {
    final b = Buf(10, 13);
    b.rect(1, 3, 8, 9, hx('#C89A60'));
    b.rect(1, 3, 3, 9, hx('#E0B880'));
    b.rect(1, 1, 8, 2, hx('#A87A40'));
    b.rect(2, 0, 6, 1, hx('#C89A60'));
    return b.outline().done();
  },
  'hueso': () {
    final b = Buf(13, 7);
    b.rect(3, 2, 7, 3, hx('#F8F4E8'));
    for (final p in const [
      [2, 1],
      [2, 5],
      [10, 1],
      [10, 5],
    ]) {
      b.ell(p[0], p[1], 1.6, 1.6, [hx('#F8F4E8')]);
    }
    return b.outline().done();
  },
  'caja': () {
    final b = Buf(28, 16);
    b.rect(1, 5, 26, 10, hx('#C89A60'));
    b.rect(1, 5, 26, 2, hx('#E0B880'));
    b.rect(1, 13, 26, 2, hx('#A87A40'));
    b.rect(3, 2, 22, 3, hx('#8A6234'));
    b.rect(12, 8, 4, 2, hx('#8A6234'));
    return b.outline().done();
  },
  'sonajero': () {
    final b = Buf(8, 12);
    b.ell(4, 4, 3, 3, _hs(const ['#E86AA0', '#F8A0C8']));
    b.px(3, 3, hx('#FFFFFF'));
    b.rect(3, 7, 2, 4, hx('#F0C020'));
    return b.outline().done();
  },
  'oso': () {
    final b = Buf(15, 10);
    b.rect(1, 4, 13, 3, hx('#D0302A'));
    b.rect(4, 1, 7, 3, hx('#D0302A'));
    b.rect(5, 2, 2, 2, hx('#BFE0EA'));
    b.rect(8, 2, 2, 2, hx('#BFE0EA'));
    b.rect(1, 4, 13, 1, hx('#F0605A'));
    for (final x in const [4, 11]) {
      b.ell(x, 7.5, 1.8, 1.8, [hx('#20202A')]);
      b.px(x, 7, hx('#C8C8D4'));
    }
    return b.outline().done();
  },
  'bloque': () {
    final b = Buf(9, 9);
    b.rect(1, 1, 7, 7, hx('#3A6AC8'));
    b.rect(1, 1, 7, 2, hx('#7AA0F0'));
    b.rect(3, 3, 3, 3, hx('#F0C020'));
    return b.outline().done();
  },
  'patito': () {
    final b = Buf(11, 9);
    b.ell(5, 5.5, 4, 2.6, _hs(const ['#C89A10', '#F0C020', '#FFE060']));
    b.ell(8, 2.5, 2, 2, _hs(const ['#F0C020', '#FFE060']));
    b.px(9, 2, OUT);
    b.rect(10, 3, 1, 1, hx('#E88A2A'));
    return b.outline().done();
  },
  'chal': () {
    final b = Buf(20, 10);
    b.ell(10, 5, 9, 4, _hs(const ['#5A3A8A', '#7A56B0', '#A07ED0']));
    for (var x = 2; x < 18; x += 3) {
      b.px(x, 9, hx('#5A3A8A'));
    }
    return b.outline().done();
  },
  'bola': () {
    final b = Buf(9, 9);
    b.ell(4.5, 4.5, 3.6, 3.6, _hs(const ['#C8401E', '#F4683C', '#FFA07A']));
    b.rect(2, 4, 5, 1, hx('#FFFFFF'));
    return b.outline().done();
  },
  'bandeja': () {
    final b = Buf(22, 6);
    b.rect(1, 2, 20, 3, hx('#8A5A2A'));
    b.rect(1, 2, 20, 1, hx('#D8AA70'));
    b.rect(0, 1, 2, 2, hx('#8A5A2A'));
    b.rect(20, 1, 2, 2, hx('#8A5A2A'));
    return b.outline().done();
  },
};

// banco.js: mkPaloma. A pigeon: sitting, pecking (head down), flying (wings up and down)
Sprite mkPaloma(String? pose, int f) {
  final b = Buf(18, 13),
      C = _hs(const ['#5A5A6A', '#8A8A9A', '#B8B8C8']),
      baja = pose == 'come' && f != 0,
      bebe = pose == 'bebe';
  if (pose == 'vuela') {
    b.ell(7, 7, 4.4, 2.6, C);
    b.cap(6, 6, 4, f != 0 ? 1 : 11, 1.6, [C[2]]);
    b.cap(8, 6, 10, f != 0 ? 1 : 11, 1.6, [C[1]]);
  } else {
    b.ell(6, 7, 4.6, 3.2, C);
    b.cap(2, 7, 0, 5, 1.2, [C[0]]);
    b.rect(5, 10, 1, 2, hx('#E0483A'));
    b.rect(8, 10, 1, 2, hx('#E0483A'));
  }
  final duerme = pose == 'duerme',
      hxx = baja
          ? 11
          : bebe
          ? 12
          : duerme
          ? 9
          : 10,
      hy = baja
          ? 8
          : bebe
          ? (f != 0 ? 2 : 3)
          : duerme
          ? 6
          : 4;
  if (bebe) b.cap(9, 6, hxx, hy + 1, 1.4, [C[1]]);
  b.ell(hxx, hy, 2.4, 2.4, C);
  if (duerme) {
    b.rect(hxx, hy - 1, 2, 1, OUT);
  } else {
    b.px(hxx + 1, hy - 1, OUT);
  }
  if (!duerme) {
    b.rect(hxx + 2, hy + (baja || bebe ? 1 : 0), 2, 1, hx('#E88A2A'));
  }
  if (!baja && !bebe) b.rect(8, 5, 2, 2, hx('#3E9A52'));
  if (pose == 'come' && f == 0) {
    b.px(14, 11, hx('#F2F2F8'));
    b.px(16, 10, hx('#E0483A'));
  }
  if (bebe && f != 0) b.rect(15, 6, 1, 2, hx('#5AB4EA'));
  return b.outline().done();
}

// banco.js: mkCan. A dog. tipo: canelo (brown), viejo (big, grey, a long white beard and eyebrows), joven (small, white
// with black patches)
Sprite mkCan(String tipo, String? pose, int f, bool pena) {
  final b = Buf(32, 24),
      T =
          const {
            'canelo': ['#8A5A2A', '#B07A3C', '#D09A54', '#E8BE80'],
            'viejo': ['#5A5A66', '#7E7E8C', '#A0A0AE', '#B8B8C6'],
            'joven': ['#B8B8C8', '#E6E6F0', '#FFFFFF', '#FFFFFF'],
          }[tipo]?.map(hx).toList() ??
          <int>[],
      v = tipo == 'viejo',
      j = tipo == 'joven';
  const X = 13, Y = 13;
  // (a dog of another kind, which only the test act prueba could ask for, has no tones: the port throws there)
  int t(int i) => T[i];
  final lie = pose == 'lie' || pose == 'cansado' || pose == 'duerme',
      sit =
          pose == 'sit' || pose == 'come' || pose == 'bark' || pose == 'triste',
      run = pose == 'run',
      a = f != 0 ? 1 : -1;
  const k = 1;
  final cola = pose == 'triste' || v || pena
      ? [X - 12, Y + 5]
      : j
      ? [X - 10, Y - 3 + (f != 0 ? 1 : -1)]
      : [X - 12, Y - 6 + (f != 0 ? 1 : -1)];
  b.cap(X - 9 * k, Y + 1, cola[0], cola[1], 1.4, [t(1)]);
  if (lie) {
    b.ell(X, Y + 6, 10 * k, 4, T);
    b.rect(X + 6, Y + 8, 6, 2, t(1));
  } else if (sit) {
    b.ell(X - 1, Y + 4, 7 * k, 6 * k + (v ? 1 : 0), T);
    b.rect(X + 3, Y + 5, 2, 6, t(1));
    b.rect(X + 6, Y + 5, 2, 6, t(2));
    b.ell(X - 4, Y + 9, 4, 2, [t(1)]);
  } else {
    b.ell(X, Y + 2, 10 * k, (v ? 6 : 5) * k, T);
    if (run) {
      b.cap(X - 6, Y + 5, X - 11 + a * 2, Y + 9, 1.3, [t(1)]);
      b.cap(X - 3, Y + 5, X - 7 - a * 2, Y + 10, 1.3, [t(0)]);
      b.cap(X + 5, Y + 5, X + 10 + a * 2, Y + 9, 1.3, [t(1)]);
      b.cap(X + 7, Y + 5, X + 12 - a * 2, Y + 10, 1.3, [t(2)]);
    } else {
      final w = pose == 'walk' ? a : 0;
      b.rect(X - 7 + w, Y + 6, 2, 5, t(1));
      b.rect(X - 4 - w, Y + 6, 2, 5, t(0));
      b.rect(X + 4 + w, Y + 6, 2, 5, t(1));
      b.rect(X + 7 - w, Y + 6, 2, 5, t(2));
    }
  }
  if (j) {
    b.ell(
      X - 3,
      Y +
          (lie
              ? 5
              : sit
              ? 3
              : 1),
      3,
      2.4,
      [hx('#20202A')],
    );
    b.ell(
      X + 4,
      Y +
          (lie
              ? 7
              : sit
              ? 6
              : 3),
      2,
      1.6,
      [hx('#20202A')],
    );
  }
  // the head
  final hX = X + 10 * k + (j ? 1 : 0),
      hy =
          (lie
              ? Y + 4
              : pose == 'triste'
              ? Y - 1
              : v
              ? Y - 2
              : Y - 3) +
          (pena && !lie ? 2 : 0);
  if (tipo == 'canelo') b.rect(hX - 4, hy + 4, 5, 2, RP.red[2]);
  b.ell(hX, hy, 5 * k + (v ? .6 : 0), 4.6 * k + (v ? .4 : 0), T);
  b.ell(hX + 4 * k, hy + 1.5, 3 * k, 2.2 * k, [t(3)]);
  final caidas =
      pena || pose == 'triste' || pose == 'cansado' || pose == 'duerme';
  if (caidas) {
    b.cap(hX - 3, hy - 3, hX - 4, hy + 3, 1.6, [j ? hx('#20202A') : t(0)]);
  } else {
    b.cap(hX - 3, hy - 3, hX - 5, hy + 2, 1.5, [j ? hx('#20202A') : t(0)]);
    b.cap(hX + 1, hy - 4, hX + 2, hy - 7, 1.3, [j ? hx('#20202A') : t(0)]);
  }
  if (v) {
    b.rect(hX + 2, hy + 3, 6, 2, hx('#FFFFFF'));
    b.rect(hX + 3, hy + 5, 4, 1, hx('#FFFFFF'));
    b.rect(hX + 3, hy + 1, 5, 2, hx('#FFFFFF'));
    b.rect(hX, hy - 3, 4, 1, hx('#FFFFFF'));
    b.rect(hX + 6, hy, 2, 2, OUT);
  } // his long white beard, his white eyebrows
  if (pose == 'cansado') {
    b.rect(hX, hy - 1, 2, 2, OUT);
    b.px(hX, hy - 1, hx('#FFFFFF'));
    b.rect(hX + 2, hy + 3, 4, f != 0 ? 3 : 2, hx('#7A1C1C'));
    b.rect(hX + 4, hy + 5, 2, f != 0 ? 4 : 3, hx('#F08AA0'));
    b.rect(hX - 1, hy - 6 + (f != 0 ? 1 : 0), 2, 3, hx('#A8DCF8'));
  } // heavy open eyes, a yawn, his tongue out
  else {
    if (pose == 'duerme') {
      b.rect(hX, hy - 1, 3, 1, OUT);
    } else {
      b.px(hX + 1, hy - 1, OUT);
    }
    if (pose == 'bark' && f != 0) {
      b.rect(hX + 3, hy + 3, 4, 2, hx('#7A1C1C'));
    } else if (pose == 'come') {
      b.rect(hX + 3, hy + 3, 3, 2, f != 0 ? hx('#7A1C1C') : t(3));
    } else if (!v) {
      b.px(hX + 4, hy + 3, hx('#7A2A1A'));
    }
  }
  if (!v) b.px(hX + 6 * k, hy + 1, OUT);
  if (pose == 'triste') {
    b.rect(hX + 2, hy + 1, 1, 2 + (f != 0 ? 1 : 0), hx('#5A9AEA'));
  } // a tear
  return b.outline().done();
}

// banco.js: mkCoche. The pushchair. capota: the hood is down over the baby. bebe: duerme, llora, rie
Sprite mkCoche(bool capota, String? bebe, int f) {
  final b = Buf(38, 42), Az = _hs(const ['#1E5A8A', '#3A8AC8', '#6AB4E8']);
  for (final x in const [10, 28]) {
    b.ell(x, 37, 4, 4, const [OUT]);
    b.ell(x, 37, 3, 3, _hs(const ['#5A5A6A', '#8A8A9A']));
    b.px(x, 37, hx('#C8C8D4'));
  }
  b.rect(9, 31, 20, 2, hx('#5A5A6A'));
  b.cap(33, 9, 29, 30, 1, [hx('#5A5A6A')]);
  b.rect(31, 7, 6, 2, hx('#3A3A46'));
  b.rect(4, 19, 26, 12, Az[1]);
  b.rect(4, 19, 26, 2, Az[2]);
  b.rect(4, 29, 26, 2, Az[0]);
  if (capota) {
    b.ell(15, 15, 12, 10, Az);
    b.rect(3, 17, 26, 3, Az[0]);
    for (var x = 6; x < 26; x += 5) {
      b.rect(x, 8, 1, 9, Az[0]);
    }
  } else {
    final P = PIEL['b']!;
    b.ell(8, 14, 6, 9, [Az[0], Az[1]]);
    b.rect(12, 16, 16, 4, hx('#F8F4E8'));
    b.ell(19, 12, 5.4, 5.2, [P[1], P[2], P[3]]);
    b.rect(16, 6, 6, 2, hx('#44260E'));
    if (bebe == 'llora') {
      b.rect(16, 11, 2, 1, OUT);
      b.rect(21, 11, 2, 1, OUT);
      b.rect(17, 13, 5, 3, hx('#7A1C1C'));
      b.rect(15, 12, 1, 3 + (f != 0 ? 1 : 0), hx('#5A9AEA'));
      b.rect(23, 12, 1, 3 + (f != 0 ? 0 : 1), hx('#5A9AEA'));
    } else if (bebe == 'rie') {
      b.px(17, 11, OUT);
      b.px(21, 11, OUT);
      b.rect(17, 13, 5, 2, hx('#7A1C1C'));
      b.rect(18, 13, 3, 1, hx('#FFFFFF'));
    } else {
      b.rect(16, 11, 2, 1, OUT);
      b.rect(21, 11, 2, 1, OUT);
      b.px(19, 14, hx('#7A2A1A'));
    }
  }
  return b.outline().done();
}
