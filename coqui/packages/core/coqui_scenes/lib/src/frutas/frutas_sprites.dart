// What only Las frutas has in its sprite layer (the place's shared cast is lib/src/colmado/colmado_cast.dart): the seven
// things of the bins whole (big and small where a story holds two of a kind), the aguacate cut (green or black inside), a
// slice of aguacate and of limón, the crates of the ledge (fresh and yesterday's, of tomatoes, onions and limones; full,
// half, empty and knocked over), what lies on the scale's pan, its needle, a finger on the dial, flies, abuela's basket
// with its three hollows (from the side and from above), a pot of soup and a guineo (the thoughts), don Pepe's knife,
// abuela's purse and the goat with its head in the low crate. Drawn in the old sprites' way (engine.js Buf: ramps, a
// dark outline); the fruit in the set's own colours and shapes (colmado-fuera.js: P_TOM, S_TOM, P_ONI, S_ONI, P_POT,
// S_POT, P_AGU, S_AGU, P_AGC avocadoCut, P_PIN pineapple, P_LIM, S_LIM, P_LIC limeCut), the size of frutas-preview.html's
// stand-ins where it has one. The content lane looks at each on docs/proyecto/pixel/port/frutas-sprites.png
// (tool/make_frutas_sprites_test.dart).
// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'dart:math' as math;

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/src/colmado/colmado_cast.dart';
import 'package:coqui_scenes/src/mostrador/mostrador_sprites.dart' as ms;

int _c(int r, int g, int b) => 0xFF000000 | (b << 16) | (g << 8) | r;
int _h(String s) => hexColour(s);
List<int> _hs(List<String> s) => [for (final x in s) hexColour(x)];

// rows of letters over a palette, at (x0, y0)
void _rows(
  Buf b,
  List<String> rows,
  Map<String, int> P, [
  int x0 = 0,
  int y0 = 0,
]) {
  for (var y = 0; y < rows.length; y++) {
    for (var x = 0; x < rows[y].length; x++) {
      final c = P[rows[y][x]];
      if (c != null) b.px(x0 + x, y0 + y, c);
    }
  }
}

/* ---------- the set's palettes (colmado-fuera.js) ---------- */

final Map<String, int> P_TOM = {
  'R': _c(218, 50, 46),
  'L': _c(250, 134, 108),
  'D': _c(164, 34, 46),
  'K': _c(110, 26, 44),
  'g': _c(84, 156, 62),
  'G': _c(146, 210, 88),
  's': _c(40, 88, 48),
};
const List<String> S_TOM = [
  '...s...',
  '.gGGGg.',
  'RLRgRRD',
  'LRRRRRD',
  'RRRRRDD',
  '.RDDDD.',
];
final Map<String, int> P_ONI = {
  'y': _c(236, 182, 86),
  'Y': _c(208, 148, 64),
  'S': _c(252, 226, 134),
  'D': _c(156, 102, 50),
  'K': _c(106, 68, 42),
  't': _c(232, 208, 142),
  'T': _c(128, 88, 52),
  'r': _c(222, 200, 150),
};
const List<String> S_ONI = [
  '...T...',
  '...t...',
  '..ySD..',
  '.ySYYD.',
  'ySYYYYD',
  'ySYYYYD',
  'yYSYYDD',
  '.yYSDD.',
  '..YDK..',
  '..r.r..',
];
final Map<String, int> P_POT = {
  'p': _c(190, 160, 118),
  'P': _c(168, 136, 96),
  'D': _c(128, 100, 72),
  'd': _c(96, 74, 56),
  'e': _c(84, 62, 44),
};
const List<String> S_POT = [
  '...ppPP.',
  '.pPPPPPD',
  'pPePPPPD',
  'PPPPPeDD',
  'PePPDDD.',
  '.dDDdd..',
];
final Map<String, int> P_AGU = {
  'a': _c(96, 152, 74),
  'A': _c(62, 112, 58),
  'H': _c(196, 234, 154),
  'D': _c(38, 76, 50),
  'K': _c(26, 52, 42),
};
// the small aguacate is the set's own (S_AGU[0], 8 x 10); the big one frutas-preview.html's aguacate_g (10 x 13)
const List<String> S_AGU = [
  '...aA...',
  '...aA...',
  '..aAAA..',
  '.aHAAAA.',
  'aHHAAAAD',
  'aHAAAADD',
  'aAAADAAD',
  'AAAAAADD',
  '.AAADDD.',
  '..DDDK..',
];
const List<String> S_AGU_G = [
  '....aA....',
  '....aA....',
  '...aAAA...',
  '..aHAAAA..',
  '..aHHAAAA.',
  '.aHHAAAAAD',
  '.aHAAAAADD',
  'aAAAADAAAD',
  'aAAAAAAADD',
  'AAAAAAADDD',
  '.AAAADDDD.',
  '..ADDDDK..',
  '...DDKK...',
];
final Map<String, int> P_LIM = {
  'l': _c(216, 244, 110),
  'L': _c(172, 218, 58),
  'D': _c(120, 172, 46),
  'd': _c(76, 120, 44),
};
const List<String> S_LIM = [
  '.llLL.',
  'lllLLD',
  'lLLLLD',
  'LLLLDD',
  '.LLDD.',
  '..dd..',
];
const List<String> S_LIM_G = [
  '..llLL..',
  '.lllLLLD',
  'lllLLLLD',
  'lLLLLLLD',
  'LLLLLLDD',
  'LLLLLDDD',
  '.LLLDDd.',
  '..dddd..',
];
final List<int> P_PLA = [_c(154, 208, 86), _c(108, 166, 62), _c(56, 100, 50)];

/* ---------- the seven things, whole ---------- */

/// The things of the bins (the Needs' "each of the seven things whole"): `tomate`, `cebolla`, `papa`, `platano`,
/// `aguacate`, `pina`, `limon`, each its bottom middle on its place.
const List<String> FRUTAS = [
  'tomate',
  'cebolla',
  'papa',
  'platano',
  'aguacate',
  'pina',
  'limon',
];

/// One of the [FRUTAS]; [grande]: the big one of a story's two (43: a big and a small aguacate, piña, limón; the
/// others have one size).
Sprite mkFruta(String k, {bool grande = false}) {
  switch (k) {
    case 'tomate':
      final b = Buf(9, 8);
      _rows(b, S_TOM, P_TOM, 1, 1);
      return b.outline().done();
    case 'cebolla':
      final b = Buf(9, 12);
      _rows(b, S_ONI, P_ONI, 1, 1);
      return b.outline().done();
    case 'papa':
      final b = Buf(10, 8);
      _rows(b, S_POT, P_POT, 1, 1);
      return b.outline().done();
    case 'platano':
      return mkPlatano(false);
    case 'aguacate':
      final r = grande ? S_AGU_G : S_AGU;
      final b = Buf(r[0].length + 2, r.length + 2);
      _rows(b, r, P_AGU, 1, 1);
      return b.outline().done();
    case 'limon':
      final r = grande ? S_LIM_G : S_LIM;
      final b = Buf(r[0].length + 2, r.length + 2);
      _rows(b, r, P_LIM, 1, 1);
      return b.outline().done();
    case 'pina':
      return mkPina(grande);
  }
  throw ArgumentError.value(k, 'k', 'not a thing of the bins');
}

/// A plátano (one green finger, curved, its tip dark: the set's hand of plantains, one finger) or a guineo ([guineo]:
/// yellow, from the hand under the awning).
Sprite mkPlatano(bool guineo) {
  final b = Buf(14, 7);
  final P = guineo ? _hs(['#F8E070', '#E8C040', '#B08A20']) : P_PLA;
  for (var x = 1; x <= 12; x++) {
    final t = (x - 1) / 11,
        y = 2 + (2.2 * math.pow(2 * t - 1, 2)).round(),
        w = x < 3 || x > 11 ? 1 : 2;
    b.px(x, y - 1, P[0]);
    for (var k = 0; k < w; k++) {
      b.px(x, y + k, k == w - 1 ? P[2] : P[1]);
    }
  }
  b.px(12, 4, _h('#2C2A1C'));
  b.px(1, 3, _h('#3A2818'));
  return b.outline().done();
}

/// A piña (colmado-fuera.js pineapple: a golden-orange oval with a dark criss-cross, a crown of seven leaves). [grande]:
/// the set's size (15 x 20); the small one 11 x 15, the same drawing smaller.
Sprite mkPina(bool grande) {
  final s = grande ? 1.0 : .72;
  final w = (15 * s).round(), h = (20 * s).round();
  final b = Buf(w + 2, h + 2);
  final hi = _c(252, 204, 90),
      mid = _c(240, 160, 52),
      lo = _c(206, 116, 42),
      dk = _c(150, 84, 40),
      L = {
        'hi': _c(150, 78, 24),
        'mid': _c(128, 64, 22),
        'lo': _c(104, 52, 26),
        'dk': _c(80, 40, 28),
      },
      B = {'hi': hi, 'mid': mid, 'lo': lo, 'dk': dk},
      lv = [_c(122, 196, 86), _c(84, 156, 70), _c(54, 120, 62), _c(40, 94, 56)];
  const crown = [
    [.8, 5.4],
    [2.9, 2.8],
    [5.2, 1.0],
    [7.5, .2],
    [9.8, 1.0],
    [12.1, 2.8],
    [14.2, 5.4],
  ];
  const BX = 7.5, BY = 14.6, HW = 6.5, HH = 5.5;
  for (var r = 0; r < h; r++) {
    for (var c = 0; c < w; c++) {
      final px = (c + .5) / s, py = (r + .5) / s;
      final nx = (px - BX) / HW, ny = (py - BY) / HH, nn = nx * nx + ny * ny;
      int? col;
      if (nn <= 1) {
        final l = -.55 * nx - .6 * ny + .58 * math.sqrt(1 - nn),
            band = l > .78
                ? 'hi'
                : l > .5
                ? 'mid'
                : l > .2
                ? 'lo'
                : 'dk';
        final i = (px - .5).floor() - 7, j = (py - .5).floor() - 14;
        int m(int k) => ((k % 4) + 4) % 4;
        if (m(i + j) == 0 || m(i - j) == 0) {
          col = L[band];
        } else {
          col = m(i + j) == 2 && m(i - j) == 2 && band != 'dk' ? hi : B[band];
        }
      } else {
        var best = 9;
        for (var k = 0; k < 7; k++) {
          final tx = crown[k][0], ty = crown[k][1], bx = BX + (k - 3) * .9;
          const by = 10.6;
          final ex = tx - bx, ey = ty - by, len2 = ex * ex + ey * ey;
          final t = (((px - bx) * ex + (py - by) * ey) / len2).clamp(0.0, 1.0);
          final dx = px - bx - ex * t, dy = py - by - ey * t;
          if (math.sqrt(dx * dx + dy * dy) <= 1.05 * (1 - t) + .42) {
            best = math.min(best, (k - 3).abs());
          }
        }
        if (best < 9) col = lv[best];
      }
      if (col != null) b.px(c + 1, r + 1, col);
    }
  }
  return b.outline().done();
}

/* ---------- cut, and slices ---------- */

/// An aguacate cut in two, the halves side by side (43: "green inside" [bueno], or "black inside" [bueno] false: the
/// flesh dark and brown). Each half is colmado-fuera.js avocadoCut (11 x 12); the stone in the left one.
Sprite mkAguacateCortado(bool bueno) {
  final b = Buf(25, 14);
  final skin = _c(34, 66, 42),
      rim = bueno ? _c(96, 150, 58) : _c(70, 60, 36),
      fl = bueno ? _c(208, 224, 118) : _c(58, 44, 30),
      fh = bueno ? _c(232, 238, 158) : _c(82, 62, 40),
      st = _c(112, 72, 42),
      sl = _c(170, 118, 72),
      sd = _c(76, 48, 32);
  for (final (ox, stone) in const [(1, true), (13, false)]) {
    for (var r = 0; r < 12; r++) {
      for (var c = 0; c < 11; c++) {
        final px = c + .5 - 5.5, py = r + .5;
        final q1 = math.sqrt(
              math.pow(px / 5, 2) + math.pow((py - 7.3) / 4.7, 2),
            ),
            q2 = math.sqrt(
              math.pow(px / 3.1, 2) + math.pow((py - 3.5) / 3.4, 2),
            ),
            q = math.min(q1, q2);
        if (q > 1) continue;
        final dep = 1 - q;
        int col;
        if (dep < .17) {
          col = skin;
        } else {
          final sx = px, sy = py - 8.1, sr = math.sqrt(sx * sx + sy * sy);
          if (stone && sr < 2.3) {
            col = sr > 1.5 && sx + sy > 1.2
                ? sd
                : (sx < -.2 && sy < -.2 && sr > .4)
                ? sl
                : st;
          } else if (!stone && sr < 2.3) {
            col = bueno
                ? _c(184, 200, 96)
                : _c(46, 34, 24); // the hollow the stone left
          } else {
            col = dep < .3
                ? rim
                : dep < .46
                ? fl
                : fh;
          }
        }
        b.px(ox + c, 1 + r, col);
      }
    }
  }
  return b.outline().done();
}

/// A slice of aguacate (43: he holds one out to the frog): a pale green crescent with its dark skin.
Sprite mkTajadaAguacate() {
  final b = Buf(9, 6);
  b.ell(4.5, 2.4, 3.6, 1.9, _hs(['#B8CC6A', '#D0E076', '#E8EE9E']));
  b.rect(1, 3, 7, 1, _h('#22422A'));
  return b.outline().done();
}

/// A slice of limón (44: he cuts one and gives the frog a slice; colmado-fuera.js limeCut, half of it).
Sprite mkTajadaLimon() {
  final b = Buf(11, 7);
  final skin = _c(78, 142, 40),
      rind = _c(204, 228, 132),
      fl = _c(172, 210, 80),
      ln = _c(242, 251, 196);
  for (var r = 0; r < 5; r++) {
    for (var c = 0; c < 9; c++) {
      final dx = c - 4, dy = r - 4, q = math.sqrt(dx * dx + dy * dy);
      if (q > 4.4) continue;
      final col = q > 3.7
          ? skin
          : q > 3.0
          ? rind
          : (q > .9 && (dx == 0 || dy == 0 || dx.abs() == dy.abs()))
          ? ln
          : fl;
      b.px(c + 1, r + 1, col);
    }
  }
  return b.outline().done();
}

/* ---------- the crates of the ledge (44) ---------- */

/// A crate of the ledge (frutas-preview.html's `cajon`, 18 x 15: .7 wide): [k] what is in it (`tomates`, `cebollas`,
/// `limones`); [fresco]: fresh from the farm (green leaves, a shine, drops of water) or yesterday's (dull wood, limp
/// olive leaves, the fruit dark and wrinkled); [lleno] how full: 1, .5 (half eaten or spilled) or 0 (empty);
/// [volcado]: knocked over on its side. [pequeno]: the small crate of limones (44: 2), 12 wide.
Sprite mkCajon(
  String k, {
  bool fresco = true,
  double lleno = 1,
  bool volcado = false,
  bool pequeno = false,
}) {
  final w = pequeno ? 12 : 18, b = Buf(w, 15);
  final W0 = fresco
      ? [_c(92, 62, 40), _c(150, 98, 56), _c(196, 148, 92), _c(214, 176, 120)]
      : [_h('#4A4238'), _h('#5E5448'), _h('#7A6E5E'), _h('#8E8270')];
  final fruit = switch (k) {
    'cebollas' =>
      fresco
          ? [_c(236, 182, 86), _c(208, 148, 64), _c(252, 226, 134)]
          : [_h('#8A6A3A'), _h('#6E5230'), _h('#9A7A4A')],
    'limones' =>
      fresco
          ? [_c(172, 218, 58), _c(120, 172, 46), _c(216, 244, 110)]
          : [_h('#7A8A3A'), _h('#5E6C30'), _h('#8A9A4A')],
    _ =>
      fresco
          ? [_c(218, 50, 46), _c(164, 34, 46), _c(250, 134, 108)]
          : [_h('#7A4A3A'), _h('#5E3A30'), _h('#8E5A48')],
  };
  if (volcado) {
    // on its side: the open top turned to the left, the slats upright, a few spilled at its mouth
    b.rect(3, 6, w - 4, 8, W0[1]);
    for (var x = 4; x < w - 1; x += 3) {
      b.rect(x, 6, 1, 8, W0[0]);
    }
    b.rect(3, 6, w - 4, 1, W0[2]);
    b.rect(1, 6, 2, 8, _h('#2A1C14'));
    for (final (x, y) in const [(1, 11), (3, 12), (0, 13)]) {
      b.rect(x, y, 2, 2, fruit[0]);
    }
    return b.outline().done();
  }
  final x1 = w - 2;
  b.rect(1, 7, x1, 7, W0[1]);
  b.rect(1, 7, x1, 1, W0[2]);
  b.rect(1, 13, x1, 1, W0[0]);
  b.rect(1, 9, x1, 1, W0[0]);
  b.rect(1, 11, x1, 1, W0[0]);
  b.rect(w - 3, 7, 2, 7, W0[0]);
  if (lleno > 0) {
    // the fruit heaped over its rim: a full row, or half of it
    final n = lleno >= 1 ? (w - 2) ~/ 3 : ((w - 2) ~/ 3) ~/ 2;
    for (var i = 0; i < n; i++) {
      final x = 1 + i * 3 + (lleno >= 1 ? 0 : 1);
      b.ell(x + 1.5, 6, 1.6, 1.6, [fruit[1], fruit[0], fruit[2]]);
    }
    if (lleno >= 1) {
      for (var i = 0; i < n - 1; i++) {
        b.ell(3 + i * 3, 4.5, 1.5, 1.5, [fruit[1], fruit[0], fruit[2]]);
      }
    }
    if (fresco) {
      final lv = [_h('#4A9A3E'), _h('#6CC454'), _h('#3A8438')];
      for (var i = 0; i < (lleno >= 1 ? 4 : 2); i++) {
        b.rect(2 + i * 4, lleno >= 1 ? 2 : 4, 2, 2, lv[i % 3]);
      }
      // the shine and the drops of water
      for (final (x, y) in const [(3, 1), (9, 0), (14, 1)]) {
        if (x < w - 1) b.px(x, y + (lleno >= 1 ? 0 : 3), 0xFFFFFFFF);
      }
      for (final (x, y) in const [(3, 9), (9, 10), (13, 9)]) {
        if (x < w - 2) b.px(x, y, _h('#BFE4FF'));
      }
    } else {
      // limp olive leaves and wrinkles
      final lv = [_h('#7A8040'), _h('#5E6434')];
      for (var i = 0; i < (lleno >= 1 ? 3 : 1); i++) {
        b.rect(3 + i * 5, lleno >= 1 ? 3 : 5, 3, 1, lv[i % 2]);
      }
      b.rect(6, 8, 3, 1, _h('#6A6054'));
    }
  }
  return b.outline().done();
}

/// What lies on the scale's pan (44): a small heap of [k] (`tomates`, `cebollas`, `limones`), a pound ([n] 1) or half
/// ([n] .5: four limones, as the script has it), or a paper bag ([k] `bolsa`).
Sprite mkEnPlato(String k, double n) {
  if (k == 'bolsa') return mkBolsaPapel(true);
  final one = mkFruta(switch (k) {
    'cebollas' => 'cebolla',
    'limones' => 'limon',
    _ => 'tomate',
  });
  final places = n >= 1
      ? const [(0, 4), (6, 4), (12, 4), (3, 0), (9, 0)]
      : const [(2, 4), (8, 4), (5, 0), (11, 3)];
  final w = 12 + one.w, h = 4 + one.h;
  return canvasSprite(w, h, (g) {
    for (final (x, y) in places) {
      g.drawImage(one, x, y);
    }
  });
}

/* ---------- the scale ---------- */

/// The scale's needle over its dial (frutas.md: "the needle is a sprite over the dial"; colmado-fuera.js dial with its
/// `needle`: a red line 5 px long from the middle, to 12, 3 or 6 o'clock, its middle dark), [n] 0 rest, .5 medio, 1
/// libra. 11 x 11: its middle pixel (5, 5) on the dial's middle.
Sprite mkAguja(double n) {
  final b = Buf(11, 11);
  final (nx, ny) = n >= 1
      ? (0, 1)
      : n > 0
      ? (1, 0)
      : (0, -1);
  for (var k = 0; k <= 5; k++) {
    b.px(5 + nx * k, 5 + ny * k, _c(224, 40, 40));
  }
  b.px(5, 5, _c(40, 40, 52));
  return b.done();
}

/// A finger laid on the dial (44: "he lays a finger on it", "on the full mark"): a hand's tip, skin-coloured, its point
/// at the bottom left (1, 6).
Sprite mkDedo() {
  final b = Buf(9, 8);
  b.rect(1, 3, 4, 2, RP.skin[2]);
  b.ell(5.5, 3.5, 2.6, 2.4, RP.skin);
  b.rect(1, 4, 3, 1, RP.skin[1]);
  return b.outline().done();
}

/* ---------- small things ---------- */

/// A fly (frutas-preview.html's `mosca`), its wings by the frame [f].
Sprite mkMosca(int f) {
  final b = Buf(5, 4);
  b.px(1, 2, _h('#20140A'));
  b.px(2, 2, _h('#20140A'));
  final wing = _h('#E8F0FF');
  if (f % 2 == 0) {
    b.px(1, 1, wing);
    b.px(3, 1, wing);
  } else {
    b.px(0, 1, wing);
    b.px(3, 2, wing);
  }
  b.px(2, 1, wing);
  return b.done();
}

/// Abuela's basket on the ledge (43: "lined with a cloth with three hollows: for a limón, an aguacate and a piña"),
/// from the side (frutas-preview.html's `canasta`, 24 x 14): wicker, a cloth over it, three hollows in a row.
Sprite mkCanasta() {
  final b = Buf(24, 14);
  b.rect(1, 6, 22, 7, _h('#C8853C'));
  for (var y = 6; y < 13; y += 2) {
    for (var x = 1; x < 23; x += 2) {
      b.px(x + (y >> 1) % 2, y, _h('#A8682C'));
    }
  }
  b.rect(1, 12, 22, 1, _h('#8A5222'));
  b.ell(12, 5, 11.4, 3.4, _hs(['#D8B8C8', '#F0DCE4', '#FFF4F6']));
  for (final x in CANASTA_HUECOS) {
    b.ell(x, 5.4, 3.1, 1.9, _hs(['#B890A4', '#D0A8BC']));
    b.ell(x, 4.8, 2.2, 1.2, [_h('#D8B8C8')]);
  }
  b.rect(1, 6, 22, 1, _h('#E2A85A'));
  return b.outline().done();
}

/// The columns of the three hollows in [mkCanasta] (the limón's, the aguacate's, the piña's).
const List<int> CANASTA_HUECOS = [5, 12, 19];

/// The basket seen from above (43: 8, "the three hollows are seen from above"): the cloth with its three hollows, and in
/// each what is in it ([en]: a thing of [FRUTAS] or null), big enough to tell apart (30 x 18).
Sprite mkCanastaArriba(List<String?> en) {
  final b = Buf(32, 20);
  b.ell(16, 10, 15, 9, _hs(['#8A5222', '#A8682C', '#C8853C']));
  b.ell(16, 10, 13, 7.4, _hs(['#D8B8C8', '#F0DCE4', '#FFF4F6']));
  for (final x in const [7.5, 16.0, 24.5]) {
    b.ell(x, 10, 3.8, 3.4, _hs(['#B890A4', '#D0A8BC']));
  }
  final s = b.outline().done();
  final parts = <(Sprite, int, int)>[];
  for (var i = 0; i < 3 && i < en.length; i++) {
    final k = en[i];
    if (k == null) continue;
    final f = k == 'pina' ? mkPina(false) : mkFruta(k);
    final cx = const [7.5, 16.0, 24.5][i];
    parts.add((f, (cx - f.w / 2).round(), 12 - f.h + 1));
  }
  return overSprite(s, parts, top: 0);
}

/// Abuela's basket in her hands (42, 44): the open basket of the shop's customers (mostrador_sprites.dart mkCesta).
Sprite mkCestaAbuela() => ms.mkCesta(true);

/// Abuela's list in her hand (mostrador_sprites.dart mkListaMano).
Sprite mkLista() => ms.mkListaMano();

/// Abuela's purse (44: "abuela looks into her purse"): a small dark red purse with a clasp, held open.
Sprite mkMonedero() {
  final b = Buf(10, 8);
  b.rect(1, 3, 8, 4, _h('#8A2A3A'));
  b.rect(1, 3, 8, 1, _h('#B8485A'));
  b.ell(5, 3, 3, 1, [_h('#2A1018')]);
  b.rect(3, 1, 4, 1, _h('#D8B040'));
  return b.outline().done();
}

/// Don Pepe's knife (43: "behind it with his knife"; frutas-preview.html's `cuchillo`, 4 x 14).
Sprite mkCuchillo() {
  final b = Buf(4, 14);
  b.rect(1, 1, 2, 8, _h('#E4E8F0'));
  b.rect(2, 1, 1, 8, 0xFFFFFFFF);
  b.px(1, 1, _h('#B8BCC8'));
  b.rect(1, 9, 2, 4, _h('#6E4220'));
  b.rect(1, 9, 2, 1, _h('#B88040'));
  return b.outline().done();
}

/// A pot of soup (42: the thought over abuela): a dark pot with two handles, its lid off, steam over it.
Sprite mkOlla() {
  final b = Buf(18, 15);
  b.ell(9, 10, 6.5, 4, _hs(['#3A3A48', '#5A5A6E', '#7A7A90']));
  b.rect(2.5, 6, 13, 5, _h('#5A5A6E'));
  b.rect(2.5, 6, 3, 5, _h('#7A7A90'));
  b.ell(9, 6, 6.5, 1.6, _hs(['#C8782C', '#E8A040']));
  b.rect(0, 7, 2, 2, _h('#3A3A48'));
  b.rect(16, 7, 2, 2, _h('#3A3A48'));
  for (final x in const [6, 9, 12]) {
    b.px(x, 3, _h('#E8F0FA'));
    b.px(x + 1, 2, _h('#E8F0FA'));
    b.px(x, 1, _h('#E8F0FA'));
  }
  return b.outline().done();
}

/* ---------- the goat with its head in the low crate ---------- */

/// The goat eating from the low crate (frutas-sheet.json rules.anchor: "in the pose with its neck stretched down its head
/// is at cabra.cajon", 3 columns right of its middle and 20 rows above its feet): colmado_cast.dart mkCabra's body
/// (its colours, legs, back and horns), its neck stretched forward over its front legs, its head bowed so that its
/// muzzle's tip is the anchor's point. [f]: chewing (two frames). 36 x 33: its middle column 18, its feet's bottom edge
/// on row 32; the muzzle's lowest pixel at (21, 12).
Sprite mkCabraCajon(int f) {
  final b = Buf(36, 33);
  final T = _hs(['#8A8478', '#B8B0A0', '#DCD6C8', '#F4F0E6']),
      D = _hs(['#5A4A3A', '#7A6650']),
      horn = _h('#C8B48A'),
      hoof = _h('#3A2A20'),
      eye = _h('#20140A');
  // the body as mkCabra's, 3 columns further left, so that the head stretched forward over the front legs is on the
  // anchor's point (column 21: the sprite's middle, 18, and 3)
  const X = 12, Y = 19;
  b.cap(X - 10, Y - 2, X - 11, Y - 6, 1.2, [T[2]]);
  for (final (dx, c) in [(-8, T[1]), (-5, T[0]), (5, T[1]), (8, T[0])]) {
    b.rect(X + dx, Y + 4, 2, 8, c);
    b.rect(X + dx, Y + 11, 2, 1, hoof);
  }
  b.ell(X, Y + 1, 11, 6, T);
  b.ell(X - 1, Y - 3, 8, 2, [D[1]]);
  // the neck forward and a little up, the head bowed over the crate: its muzzle's lowest pixel on row 12 (20 rows above
  // the feet's bottom edge, row 32), column 21
  const hx = X + 9.0, hy = 8.4;
  b.cap(X + 6, Y - 2, hx - 1, hy + 2, 2.6, T);
  b.ell(hx, hy, 3.3, 3.2, T);
  final chew = f % 2 == 1 ? .4 : 0;
  b.ell(hx, 10.9 + chew, 2.3, 1.7, [T[3]]); // the muzzle, down
  b.cap(hx - 2, hy - 2.5, hx - 6, hy - 5, 1, [horn]);
  b.cap(hx - 1, hy - 3, hx - 4, hy - 7, 1, [horn]);
  b.cap(hx - 3, hy, hx - 6, hy + 2, 1.2, [T[1]]); // an ear
  b.px(hx + 1, hy - 1, eye);
  b.rect(hx - 2, 12, 2, 2, D[0]); // the beard, under the bowed chin
  b.rect(hx - 4, hy + 3, 3, 1, _h('#B8302A')); // the rope collar
  return b.outline().done();
}

/// Every sprite this file draws, in order, for the sheet picture (frutas-sprites.png).
List<(String, Sprite)> frutasSpriteSheet() => [
  for (final k in FRUTAS) (k, mkFruta(k)),
  ('aguacate grande', mkFruta('aguacate', grande: true)),
  ('pina grande', mkFruta('pina', grande: true)),
  ('limon grande', mkFruta('limon', grande: true)),
  ('guineo', mkPlatano(true)),
  ('aguacate cortado, bueno', mkAguacateCortado(true)),
  ('aguacate cortado, malo', mkAguacateCortado(false)),
  ('tajada de aguacate', mkTajadaAguacate()),
  ('tajada de limon', mkTajadaLimon()),
  for (final k in const ['tomates', 'cebollas']) ...[
    ('cajon de $k, fresco', mkCajon(k)),
    ('cajon de $k, de ayer', mkCajon(k, fresco: false)),
    ('cajon de $k, fresco, la mitad', mkCajon(k, lleno: .5)),
    ('cajon de $k, fresco, volcado', mkCajon(k, volcado: true)),
    ('cajon de $k, vacio', mkCajon(k, lleno: 0)),
  ],
  ('cajita de limones, fresca', mkCajon('limones', pequeno: true)),
  ('en el plato: una libra de tomates', mkEnPlato('tomates', 1)),
  ('en el plato: media libra de cebollas', mkEnPlato('cebollas', .5)),
  ('en el plato: media libra de limones', mkEnPlato('limones', .5)),
  ('en el plato: una bolsa', mkEnPlato('bolsa', 1)),
  ('aguja, en reposo', mkAguja(0)),
  ('aguja, media libra', mkAguja(.5)),
  ('aguja, una libra', mkAguja(1)),
  ('dedo en la pesa', mkDedo()),
  ('mosca 0', mkMosca(0)),
  ('mosca 1', mkMosca(1)),
  ('canasta', mkCanasta()),
  (
    'canasta desde arriba, llena',
    mkCanastaArriba(const ['limon', 'aguacate', 'pina']),
  ),
  (
    'canasta desde arriba, solo la pina',
    mkCanastaArriba(const [null, null, 'pina']),
  ),
  ('cesta de abuela (El mostrador)', mkCestaAbuela()),
  ('lista (El mostrador)', mkLista()),
  ('monedero', mkMonedero()),
  ('cuchillo', mkCuchillo()),
  ('olla de sopa', mkOlla()),
  ('cabra, la cabeza en el cajon 0', mkCabraCajon(0)),
  ('cabra, la cabeza en el cajon 1', mkCabraCajon(1)),
];
