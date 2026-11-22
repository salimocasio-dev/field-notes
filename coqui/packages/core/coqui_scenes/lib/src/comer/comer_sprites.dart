// The sprites historia/escenas/comer.js makes for itself, ported line for line (order 40b): the high chair, the turned
// copies (giro), the cups, the milk jug, the things on the table, in a hand, on the stove and in a thought (COSA), the
// bodies without arms (mkPersonaN, mkAbuelaN, mkAbuelaSN), abuelo's two faces, the stool and the frog on his back. The
// background (fondo) and the old table (mkMesa) are the set's (the sheet's `dropped`). Colours are made once
// (`#RRGGBB` as `0xFFBBGGRR`).
// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'dart:math' as math;

import 'package:coqui_pixel/coqui_pixel.dart';

final Map<String, int> _hexes = {};

/// `"#RRGGBB"` as the int `0xFFBBGGRR`, made once.
int hx(String s) => _hexes[s] ??= hexColour(s);

List<int> _hs(List<String> l) => [for (final s in l) hx(s)];

// JavaScript: Math.round
int _round(num v) => (v + 0.5).floor();

// JavaScript: `+v` of what a sprite is given (a number, or a story's string)
num _plus(Object? v) => v is num
    ? v
    : v is String
    ? (num.tryParse(v.trim()) ?? (v.trim().isEmpty ? 0 : double.nan))
    : v == null
    ? double.nan
    : (v == true ? 1 : 0);

// JavaScript: `String(v)` of a value that is there
String _str(Object? v) => v is num ? jsNum(v) : '$v';

// JavaScript: `x || d` of a number that may be NaN or 0
num _or(num v, num d) => v.isNaN || v == 0 ? d : v;

/// The lip of what pours, as the old sprite carried it (`c.pico`): kept beside the picture.
final Expando<List<num>> PICO = Expando<List<num>>('pico');

/// The lip a sprite was made with (`im.pico`), or null.
List<num>? picoOf(Sprite s) => PICO[s];

// comer.js: PLATO, TAN, CHOC, MANT, ARROZ, CERA. The plates are blue: nothing white is lost on them
final List<int> PLATO = _hs(['#2A5C9C', '#4A86C8', '#8CB8E8']);
final List<int> TAN = _hs(['#A8682C', '#C8853C', '#E2A85A']),
    CHOC = _hs(['#2A1408', '#5A2E14', '#8A5A34']),
    ARROZ = _hs(['#C88A10', '#F2C028', '#FFE870']);
final int MANT = hx('#FFE070');
// the white-blue china of the bowls
final List<int> CERA = _hs(['#7A8AB8', '#C4D0F0', '#FFFFFF']);

// comer.js: LIQ. What is in a cup, seen from above
final Map<String, int> LIQ = {
  'negro': hx('#0C0806'),
  'marron': hx('#3A1A0A'),
  'claro': hx('#B8804A'),
  'palido': hx('#EBD3AC'),
  'leche': hx('#FFFFFF'),
  'vacia': hx('#4A84E0'),
  'azu': hx('#0C0806'),
};

// comer.js: mkSillaBebe. The high chair of the baby (v = "1": the baby is in it)
Sprite mkSillaBebe(Object? v) {
  final b = Buf(26, 36), W = RP.wood;
  // legs, a rung
  b.rect(3, 18, 2, 17, W[0]);
  b.rect(19, 18, 2, 17, W[0]);
  b.rect(3, 30, 18, 2, W[1]);
  // the seat
  b.rect(2, 16, 20, 3, W[2]);
  b.rect(2, 16, 20, 1, W[4]);
  // the back
  b.rect(2, 2, 2, 15, W[1]);
  b.rect(20, 2, 2, 15, W[1]);
  b.rect(2, 2, 20, 3, W[2]);
  b.rect(2, 2, 20, 1, W[4]);
  if (v == '1') {
    // a baby: a big round head with a tuft of hair, round cheeks, a smile, a white bib on a yellow shirt, one hand up
    // holding a small spoon
    b.ell(12, 14, 7.6, 5.6, _hs(['#B87A10', '#E0A020', '#F8C838']));
    b.ell(12, 15, 4.4, 3.6, _hs(['#E8F0FA', '#FFFFFF']));
    b.rect(8, 12, 8, 1, hx('#8CB8E8'));
    b.ell(12, 7.2, 6.6, 6.4, RP.skin.sublist(2));
    b.px(10, 6, hx('#20140A'));
    b.px(14, 6, hx('#20140A'));
    b.px(10, 5, hx('#FFFFFF'));
    b.px(14, 5, hx('#FFFFFF'));
    b.px(8, 9, hx('#E08A70'));
    b.px(16, 9, hx('#E08A70'));
    b.rect(11, 10, 3, 1, hx('#7A2A1A'));
    b.px(10, 9, hx('#7A2A1A'));
    b.px(14, 9, hx('#7A2A1A'));
    final c = PELO['castano']![2];
    b.px(12, 0, c);
    b.px(13, 1, c);
    b.px(11, 1, c);
    b.px(12, 1, c);
    // his arm, from the shoulder up to his fist
    b.rect(16, 12, 3, 2, RP.skin[2]);
    b.rect(18, 9, 3, 4, RP.skin[2]);
    b.rect(19, 8, 2, 2, RP.skin[2]);
    // a small spoon in his fist
    b.ell(20, 7, 2.2, 2.2, RP.skin.sublist(2));
    b.rect(21, 1, 1, 6, hx('#C8C8D4'));
    b.ell(21.5, 1, 1.8, 1.4, _hs(['#C8C8D4', '#F8F8FF']));
  } else {
    // the spoon lies on the tray while he is out of the chair
    b.rect(14, 17, 6, 1, hx('#C8C8D4'));
    b.ell(21, 17, 1.8, .9, _hs(['#C8C8D4', '#F8F8FF']));
  }
  // the tray
  b.rect(0, 19, 24, 3, hx('#8CB8E8'));
  b.rect(0, 19, 24, 1, hx('#D8E8FA'));
  return b.outline().done();
}

/* ---------- sprites ---------- */

// comer.js: borra. A round piece gone (the pixels made clear: the canvas keeps no colour where nothing is)
void borra(Buf b, num cx, num cy, num r) {
  for (var y = (cy - r).floor(); y <= (cy + r).ceil(); y++) {
    for (var x = (cx - r).floor(); x <= (cx + r).ceil(); x++) {
      if (x >= 0 &&
          y >= 0 &&
          x < b.w &&
          y < b.h &&
          (x + .5 - cx) * (x + .5 - cx) + (y + .5 - cy) * (y + .5 - cy) <=
              r * r) {
        b.d[y * b.w + x] = 0;
      }
    }
  }
}

// comer.js: giro. A copy turned by ang (radians, clockwise on the screen), nearest pixels, so it stays crisp; pico: a
// point of it (the lip of a pot) turned with it
Sprite giro(Sprite cv, num ang, [List<num>? pico]) {
  final w = cv.w, h = cv.h, r = math.sqrt(w * w + h * h).ceil(), b = Buf(r, r);
  final sc = cv.px, cs = math.cos(ang), sn = math.sin(ang);
  final cx = w / 2, cy = h / 2, ox = r / 2, oy = r / 2;
  for (var y = 0; y < r; y++) {
    for (var x = 0; x < r; x++) {
      final dx = x + .5 - ox, dy = y + .5 - oy;
      final sx = (dx * cs + dy * sn + cx).floor(),
          sy = (-dx * sn + dy * cs + cy).floor();
      if (sx < 0 || sy < 0 || sx >= w || sy >= h) continue;
      final v = sc[sy * w + sx];
      if ((v >>> 24) > 0) b.px(x, y, v & 0xFFFFFF);
    }
  }
  final out = b.done();
  if (pico != null) {
    final dx = pico[0] - cx, dy = pico[1] - cy;
    PICO[out] = [ox + dx * cs - dy * sn, oy + dx * sn + dy * cs];
  }
  return out;
}

// comer.js: bola
void bola(Buf b, num x, num y, num rx, num ry, List<int> col) {
  b.ell(x, y, rx, ry, col);
}

// comer.js: rollitos. A small split roll in the basket or on the tray: its foot at (x,yb), 10 x 6, with its own dark edge
// so that the rolls can be counted
void rollitos(Buf b, num x, num yb) {
  b.ell(x, yb - 2.8, 5.2, 3.1, const [OUT]);
  b.ell(x, yb - 2.8, 4.3, 2.3, TAN);
  b.rect(x - 3, yb - 4, 6, 1, hx('#FFF0C8'));
  b.rect(x - 3, yb - 2, 6, 1, hx('#8A5A18'));
  b.px(x - 2, yb - 5, hx('#F4CC88'));
}

// comer.js: tajada. A wedge of cake at (x0,y0), k its size: frosting white on top (a triangle), then sponge, jam, sponge
// down its front, a cherry
void tajada(Buf b, num x0, num y0, [num? k0]) {
  final k = k0 == null || k0 == 0 ? 1 : k0;
  int X(num v) => _round(x0 + v * k);
  int Y(num v) => _round(y0 + v * k);
  for (var r = 0; r < 5; r++) {
    final a = X(1 + r * 2), e = X(15), yy = Y(1 + r);
    for (var x = a; x <= e; x++) {
      b.px(x, yy, r == 0 ? hx('#FFFFFF') : hx('#FFF4E0'));
    }
    if (k > .8) b.px(e, yy, hx('#E8D8C0'));
  }
  final fy = Y(6), h2 = math.max(2, _round(2 * k));
  for (var y = fy; y < fy + h2; y++) {
    for (var x = X(5); x <= X(15); x++) {
      b.px(x, y, hx('#E8B050'));
    }
  }
  for (var x = X(5); x <= X(15); x++) {
    b.px(x, fy + h2, hx('#C8302A'));
  }
  final sy = fy + math.max(3, _round(3 * k));
  for (var y = sy; y < sy + math.max(2, _round(3 * k)); y++) {
    for (var x = X(5); x <= X(15); x++) {
      b.px(x, y, hx('#D89A3C'));
    }
  }
  b.px(X(11), Y(0), hx('#D0302A'));
  b.px(X(12), Y(0), hx('#D0302A'));
  b.px(X(11), Y(-1), hx('#48A848'));
}

// comer.js: mkTaza. A cup, 17 x 17: foot, side with a handle, rim, what is in it. sp: a teaspoon stands in it
Sprite mkTaza(Object? v0, Object? sp0) {
  final b = Buf(17, 17);
  var v = jsTruthy(v0) ? _str(v0) : '';
  var sp = jsTruthy(sp0);
  final monton = v.endsWith('+');
  if (monton) v = v.substring(0, v.length - 1);
  final mitad = v.endsWith('_'),
      L = LIQ[mitad ? v.substring(0, v.length - 1) : v] ?? LIQ['vacia']!;
  if (mitad) v = v.substring(0, v.length - 1);
  b.ell(6.6, 13.2, 5.4, 3, _hs(['#1E4FA8', '#2E6CD0', '#4A8CE8']));
  b.rect(1, 7, 11, 6, hx('#2E6CD0'));
  b.rect(1, 7, 3, 6, hx('#4A8CE8'));
  b.rect(9, 7, 3, 6, hx('#1E4FA8'));
  b.cap(12, 9, 15, 9.6, 1.1, _hs(['#1E4FA8', '#2E6CD0']));
  b.cap(15, 9.6, 13.2, 12.4, 1.1, _hs(['#1E4FA8', '#2E6CD0']));
  borra(b, 14, 10.6, .9);
  b.ell(6.6, 7, 6.2, 2.7, _hs(['#B4C8F0', '#E4ECFF', '#FFFFFF']));
  if (v == 'vacia') {
    // empty: the cup's own mid blue inside, no liquid
    b.ell(6.6, 7, 4.9, 2, [LIQ['vacia']!]);
    b.px(4, 6, hx('#9CC0F4'));
    b.px(5, 6, hx('#9CC0F4'));
  } else if (mitad) {
    b.ell(6.6, 6.8, 4.9, 2.1, [LIQ['vacia']!]);
    b.ell(6.6, 7.8, 3.6, 1.3, [L]);
  } else if (v == 'leche') {
    b.ell(6.6, 7.1, 4.8, 1.9, [hx('#FFFFFF')]);
  } else {
    b.ell(6.6, 7.1, 4.8, 1.9, [L]);
    if (v == 'negro' || v == 'azu') b.px(4, 6, hx('#5A3A28'));
    if (v == 'marron') b.px(4, 6, hx('#A87848'));
    if (v == 'claro') b.px(4, 6, hx('#E4B884'));
    if (v == 'palido') b.px(4, 6, hx('#F0CC88'));
  }
  if (v == 'azu') {
    // too much sugar: an off-white heap of grains on the coffee, and a spoon
    b.ell(6.6, 6.4, 3.8, 2.2, _hs(['#C8BEA0', '#E6DDC2', '#F6F0DC']));
    b.ell(6.6, 4.8, 2.2, 1.5, _hs(['#E6DDC2', '#F6F0DC']));
    for (final q in const [
      [4, 6],
      [6, 5],
      [8, 6],
      [5, 7],
      [7, 4],
      [9, 7],
    ]) {
      b.px(q[0], q[1], hs(q[0], q[1]) % 2 != 0 ? hx('#9A8A66') : hx('#FFFBEA'));
    }
    sp = true;
  }
  if (monton) {
    // a small white heap of sugar on the coffee, for a moment before it is stirred in
    b.ell(6.6, 6, 3, 1.8, _hs(['#C8CEE0', '#FFFFFF']));
    b.px(6, 4, hx('#FFFFFF'));
    b.px(8, 5, hx('#FFFFFF'));
  }
  if (sp) {
    b.rect(7, 0, 2, 8, hx('#E0E0EC'));
    b.rect(8, 0, 1, 8, hx('#8A8A9A'));
    b.rect(7, 0, 1, 1, hx('#FFFFFF'));
  }
  return b.outline().done();
}

// comer.js: mkLechera. The milk jug, drawn from its shape (a round belly, a neck with a rim, a beak, a ring handle) turned
// by ang (clockwise): each pixel asks which part of the jug it is on, so a turned jug is as clean as a straight one
Sprite mkLechera(num ang) {
  const S = 16;
  final b = Buf(S, S),
      cx = S / 2,
      cy = S / 2 + .4,
      cs = math.cos(ang),
      sn = math.sin(ang),
      W = _hs(['#8CA0D4', '#BCCCEE', '#E8EFFC', '#FFFFFF']);
  bool tri(num u, num v) {
    const A = [1.8, -5.3], B = [5.5, -4.3], C = [1.9, -2.5];
    num sg(List<num> p, List<num> q, List<num> r) =>
        (p[0] - r[0]) * (q[1] - r[1]) - (q[0] - r[0]) * (p[1] - r[1]);
    final P = [u, v], d1 = sg(P, A, B), d2 = sg(P, B, C), d3 = sg(P, C, A);
    return !((d1 < 0 || d2 < 0 || d3 < 0) && (d1 > 0 || d2 > 0 || d3 > 0));
  }

  for (var y = 0; y < S; y++) {
    for (var x = 0; x < S; x++) {
      final dx = x + .5 - cx,
          dy = y + .5 - cy,
          u = dx * cs + dy * sn,
          v = -dx * sn + dy * cs;
      final bel = math.pow(u / 4.3, 2) + math.pow((v - 1.3) / 3.5, 2) <= 1,
          neck = u >= -2 && u <= 2 && v >= -4.6 && v <= -1.3,
          rim = u >= -2.7 && u <= 2.7 && v >= -5.2 && v <= -3.9,
          beak = tri(u, v),
          hd = math.pow((u + 4.7) / 2.3, 2) + math.pow((v - .1) / 3, 2),
          ring = hd <= 1 && hd >= .3 && u < -3;
      if (bel || neck || rim || beak) {
        final t = -u * .11 - v * .09 + .5 + (hs(x, y) % 3 - 1) * .02;
        b.px(
          x,
          y,
          t > .72
              ? W[3]
              : t > .42
              ? W[2]
              : t > .14
              ? W[1]
              : W[0],
        );
      } else if (ring) {
        b.px(x, y, hd > .7 || u < -5.4 ? hx('#7C90C8') : hx('#AEC0E8'));
      }
    }
  }
  final c = b.outline().done();
  PICO[c] = [cx + 5.4 * cs - (-4.4) * sn, cy + 5.4 * sn + (-4.4) * cs];
  return c;
}

// the grains of rice of a heap: light or dark by the place
int _grano(num x, num y) => hs(x, y) % 2 != 0 ? hx('#FFF4B0') : hx('#B87A10');

/// comer.js: COSA. Things on the table, on the stove, in a hand, in a thought. Each is drawn by its foot or its middle;
/// the argument is what the old function took (v).
final Map<String, Sprite Function(Object? v)> COSA = {
  // the same plate with a very small heap of rice ("poco": 5 px wide) or a mountain of it ("mucho": wider than the middle
  // of the plate, 9 px high, a few grains fallen beside it); 17 x 19, the plate in the bottom 10 rows
  'platoA': (v) {
    final b = Buf(17, 19);
    b.ell(8.5, 14.4, 7.4, 3, PLATO);
    b.ell(8.5, 14, 5.2, 2, _hs(['#6AA0DC', '#A8CCF0']));
    if (v == 'poco') {
      b.ell(8.5, 13.3, 2.6, 1.5, ARROZ);
      b.px(7, 12, hx('#FFF4B0'));
      b.px(9, 13, hx('#B87A10'));
    } else {
      b.ell(8.5, 13.2, 6.3, 2.4, _hs(['#C88A10', '#F2C028', '#FFE060']));
      b.ell(8.5, 10.6, 5.2, 4.4, ARROZ);
      b.ell(8.5, 7.8, 3.2, 3.2, ARROZ);
      for (final q in const [
        [7, 5],
        [9, 6],
        [6, 8],
        [10, 9],
        [8, 11],
        [5, 12],
        [12, 12],
        [7, 13],
        [11, 14],
        [8, 9],
        [9, 12],
        [4, 10],
        [12, 10],
      ]) {
        b.px(q[0], q[1], _grano(q[0], q[1]));
      }
      // grains on the rim, beside the heap
      for (final q in const [
        [2, 15],
        [4, 16],
        [13, 16],
        [14, 15],
        [11, 17],
      ]) {
        b.px(q[0], q[1], hx('#F2C028'));
      }
      b.px(14, 15, hx('#FFF4B0'));
    }
    return b.outline().done();
  },
  // a blue plate, 17 x 10 (15 wide: a little wider than a roll, narrower than a grown-up's shoulders); v: what lies on
  // it. "r" rice, "r2" less, "r1" a little, "o" a mound, "rm" rice and a mound, "h" a mound mixed into the rice (a heap),
  // "mi" crumbs, "p1".."p3" mounds
  'plato': (v0) {
    if (v0 == 'poco' || v0 == 'mucho') return COSA['platoA']!(v0);
    final b = Buf(17, 10);
    b.ell(8.5, 5.4, 7.4, 3.1, PLATO);
    b.ell(8.5, 5, 5.2, 2, _hs(['#6AA0DC', '#A8CCF0']));
    final v = jsTruthy(v0) ? _str(v0) : '';
    if (v == 'r' || v == 'rm' || v == 'h') {
      b.ell(8.5, 4.8, 4.6, 1.8, _hs(['#C88A10', '#F2C028', '#FFE060']));
      for (final q in const [
        [6, 4],
        [9, 5],
        [11, 4],
        [7, 6],
      ]) {
        b.px(q[0], q[1], _grano(q[0], q[1]));
      }
    }
    if (v == 'r2') {
      b.ell(8.5, 4.9, 3.4, 1.4, _hs(['#C88A10', '#F2C028', '#FFE060']));
      for (final q in const [
        [7, 5],
        [10, 4],
      ]) {
        b.px(q[0], q[1], _grano(q[0], q[1]));
      }
    }
    if (v == 'r1') {
      b.ell(8.5, 4.9, 2, .9, _hs(['#C88A10', '#F2C028', '#FFE060']));
      b.px(8, 4, hx('#FFF4B0'));
    }
    if (v == 'o1') {
      b.ell(8.5, 4.4, 1.8, 1.3, ARROZ);
      b.px(8, 4, hx('#FFF4B0'));
    }
    if (v == 'rm' || v == 'o') {
      b.ell(8.5, 3.7, 2.8, 2.2, ARROZ);
      b.px(7, 2, hx('#FFF4B0'));
      b.px(9, 3, hx('#FFF4B0'));
      b.px(10, 5, hx('#B87A10'));
    }
    if (v == 'h') {
      b.ell(6.8, 3.8, 2.7, 2.1, ARROZ);
      b.ell(10.6, 4, 2.5, 1.9, ARROZ);
      b.px(6, 2, hx('#B87A10'));
      b.px(11, 3, hx('#B87A10'));
      b.px(8, 2, hx('#FFF4B0'));
    }
    if (v == 'mi') {
      for (final q in const [
        [6, 5],
        [8, 6],
        [11, 5],
        [13, 5],
        [9, 4],
      ]) {
        b.px(q[0], q[1], hx('#C8853C'));
      }
    }
    if (RegExp(r'^p[123]$').hasMatch(v)) {
      // papá's mounds: three separate ones (two in front, one behind), each with its own shadow; the first two are the
      // left and the right one
      for (final q in const [
        [4.4, 5.6],
        [12.6, 5.6],
        [8.5, 3.4],
      ].sublist(0, int.parse(v[1]))) {
        b.ell(q[0], q[1] + 1.3, 2.3, .9, [hx('#B87A10')]);
        b.ell(q[0], q[1], 1.9, 1.5, ARROZ);
        b.px(q[0] - 1, q[1] - 1, hx('#FFF4B0'));
      }
    }
    return b.outline().done();
  },
  // a child's plate, 15 x 9 (13 wide); v "mi": crumbs
  'platoc': (v) {
    final b = Buf(15, 9);
    b.ell(7.5, 5, 6.4, 2.7, PLATO);
    b.ell(7.5, 4.7, 4.4, 1.7, _hs(['#6AA0DC', '#A8CCF0']));
    if (v == 'mi') {
      for (final q in const [
        [5, 5],
        [7, 6],
        [10, 4],
        [9, 6],
        [6, 4],
      ]) {
        b.px(q[0], q[1], hx('#C8853C'));
      }
    }
    return b.outline().done();
  },
  // a plate with an apple on it; a plate with a huge heap of rice; a white jug of milk; drops of water
  'platoma': (_) {
    final b = Buf(26, 20);
    b.ell(13, 15.6, 12.4, 4.4, PLATO);
    b.ell(13, 15, 8.4, 2.8, _hs(['#6AA0DC', '#A8CCF0']));
    b.ell(9.4, 9.4, 4.2, 4.6, _hs(['#A01818', '#D02828', '#F05848']));
    b.ell(15.6, 9.4, 4.2, 4.6, _hs(['#A01818', '#D02828', '#F05848']));
    b.rect(12, 3, 2, 4, hx('#5A3A1A'));
    b.rect(14, 3, 3, 2, hx('#48A848'));
    b.px(7, 7, hx('#FFB0A0'));
    b.px(8, 6, hx('#FFB0A0'));
    return b.outline().done();
  },
  'platoH': (_) {
    final b = Buf(26, 20);
    b.ell(13, 15.6, 12.4, 4.4, PLATO);
    b.ell(13, 15, 8.4, 2.8, _hs(['#6AA0DC', '#A8CCF0']));
    b.ell(13, 12.4, 8.6, 3.8, _hs(['#F0F0F4', '#FFFFFF']));
    b.ell(13, 8.6, 7, 5.4, _hs(['#E4E4EC', '#F8F8FC', '#FFFFFF']));
    b.ell(13, 4.8, 4, 3.2, _hs(['#E4E4EC', '#F8F8FC', '#FFFFFF']));
    for (final q in const [
      [9, 9],
      [14, 7],
      [16, 11],
      [11, 12],
      [10, 6],
      [13, 4],
      [17, 9],
    ]) {
      b.px(q[0], q[1], hs(q[0], q[1]) % 2 != 0 ? hx('#C8C8D8') : hx('#FFFFFF'));
    }
    return b.outline().done();
  },
  'gotas': (_) {
    final b = Buf(14, 10);
    for (final q in const [
      [1, 6],
      [4, 2],
      [7, 5],
      [10, 1],
      [12, 6],
      [3, 8],
      [9, 8],
    ]) {
      b.rect(q[0], q[1], 2, 2, hx('#78B8F0'));
      b.px(q[0], q[1], hx('#E4F4FF'));
    }
    return b.outline().done();
  },
  // the frog's own small plate
  'platito': (v) {
    final b = Buf(14, 8);
    b.ell(7, 4.6, 5.8, 2.4, PLATO);
    b.ell(7, 4.3, 3.8, 1.5, _hs(['#6AA0DC', '#A8CCF0']));
    if (v == 'o') {
      b.ell(7, 3.4, 2.4, 1.9, ARROZ);
      b.px(6, 2, hx('#FFF4B0'));
    } else if (v == 'o2') {
      b.ell(7, 3.8, 1.8, 1.4, ARROZ);
      b.px(6, 3, hx('#FFF4B0'));
    } else if (v == 'o1') {
      b.ell(7, 4, 1.1, .9, ARROZ);
    }
    if (v == 'mi') {
      for (final q in const [
        [5, 4],
        [8, 5],
        [10, 3],
      ]) {
        b.px(q[0], q[1], hx('#C8853C'));
      }
    }
    return b.outline().done();
  },
  // a roll, 17 x 12: the same size as the rolls in the basket, everywhere (basket, board, hand, plate). "ab" cut open and
  // empty, "ab:c"/"ab:m" open with chocolate / butter in it, "ce" closed, "ce:c"/"ce:m" closed with the filling showing at
  // the seam, "mo:c"/"mo:m" with a bite out of it, "m2" half eaten
  'rollo': (v) {
    final s = (jsTruthy(v) ? _str(v) : 'ce').split(':'),
        st = s[0],
        con = s.length > 1 ? s[1] : null,
        F = con == 'c' ? CHOC[1] : MANT,
        FL = con == 'c' ? CHOC[2] : hx('#FFFBE0'),
        b = Buf(11, 9);
    const X = 5.5;
    final hasCon = con != null && con.isNotEmpty;
    if (st == 'ab') {
      b.ell(X, 5.4, 4.4, 2.6, TAN);
      b.ell(X, 4.3, 3.5, 1.5, _hs(['#FFF0C8', '#FFFAE4']));
      b.rect(3, 6, 5, 1, hx('#8A5A18'));
      if (hasCon) b.ell(X, 4.4, 3, 1.1, [F, F, FL]);
    } else if (st == 'm2') {
      b.ell(4.3, 5.5, 3.2, 2.4, TAN);
      b.rect(2, 6, 4, 1, hx('#8A5A18'));
      borra(b, 8, 4.2, 2.1);
      b.ell(6.6, 5.2, 1.1, 1.6, _hs(['#FFF0C8', '#FFFAE4']));
      if (hasCon) b.ell(6.6, 5.4, .7, .9, [F, F, FL]);
      b.px(8, 7, hx('#C8853C'));
    } else if (st == 'mo') {
      b.ell(X, 5.4, 4.4, 2.6, TAN);
      b.rect(3, 6, 5, 1, hx('#8A5A18'));
      b.px(3, 4, hx('#F4CC88'));
      b.px(4, 4, hx('#F4CC88'));
      borra(b, 9.4, 3.9, 2.1);
      b.ell(8, 5, 1.3, 1.6, _hs(['#FFF0C8', '#FFFAE4']));
      if (hasCon) {
        b.ell(8, 5.2, .8, 1, [F, F, FL]);
      } else {
        b.ell(8, 5.2, .8, 1, [hx('#E8D4A0')]);
      }
    } else {
      b.ell(X, 5.4, 4.4, 2.6, TAN);
      b.rect(3, 6, 5, 1, hx('#8A5A18'));
      b.px(3, 4, hx('#F4CC88'));
      b.px(4, 4, hx('#F4CC88'));
      b.px(5, 4, hx('#F4CC88'));
      if (hasCon) {
        b.rect(2, 5, 7, 1, F);
        b.rect(3, 5, 5, 1, FL);
      }
    }
    return b.outline().done();
  },
  // the basket of rolls (36 x 21), low enough to leave the places behind it free. v: "n:c": n rolls (0 to 5), c = 1 the
  // cloth lies over them; the cloth otherwise lies folded on the right rim, a small striped towel, inside the basket's
  // outline, on the left rim
  'cesta': (v) {
    final b = Buf(36, 21), s = (v == null ? '5:0' : _str(v)).split(':');
    final n = _plus(s[0]), c1 = s.length > 1 ? s[1] : null;
    final tapa = c1 == '1', media = c1 == '2', sin = c1 == '4';
    if (!tapa) {
      const P = [
        [12, 13],
        [21, 13],
        [30, 13],
        [16.5, 10],
        [25.5, 10],
      ];
      final ps = [
        ...P.sublist(0, n.isNaN ? 0 : math.max(0, math.min(5, n.toInt()))),
      ];
      // JavaScript's sort is stable: the index breaks a tie
      final idx = [...ps.indexed]
        ..sort((a, c) {
          final d = a.$2[1].compareTo(c.$2[1]);
          return d != 0 ? d : a.$1.compareTo(c.$1);
        });
      for (final p in idx) {
        rollitos(b, p.$2[0], p.$2[1]);
      }
    }
    b.rect(1, 13, 32, 7, hx('#B07A3C'));
    for (var x = 2; x < 33; x += 4) {
      b.rect(x, 13, 2, 7, hx('#8A5A2A'));
    }
    b.rect(0, 12, 34, 2, hx('#D09A54'));
    b.rect(0, 19, 34, 1, hx('#7A4A1E'));
    if (tapa && n <= 1) {
      // one roll lies under a small cloth, its end showing
      b.ell(19.5, 11.4, 2.8, 2.2, TAN);
      b.px(18, 10, hx('#F4CC88'));
      b.ell(11, 9.6, 9.4, 4.2, _hs(['#D0302A', '#F4B8B0', '#FFFFFF']));
      for (var x = 3; x < 19; x += 4) {
        b.rect(x, 7 + (x % 8 != 0 ? 0 : 1), 2, 4, hx('#FFFFFF'));
      }
      b.rect(1, 11, 21, 2, hx('#F4B8B0'));
      for (var x = 2; x < 21; x += 4) {
        b.rect(x, 11, 2, 2, hx('#D0302A'));
      }
    } else if (tapa) {
      if (n > 0) {
        b.ell(31, 9.5, 3, 2.6, TAN);
        b.px(29, 8, hx('#F4CC88'));
      }
      b.ell(16, 9.6, 15, 4.6, _hs(['#D0302A', '#F4B8B0', '#FFFFFF']));
      for (var x = 3; x < 30; x += 4) {
        b.rect(x, 7 + (x % 8 != 0 ? 0 : 1), 2, 4, hx('#FFFFFF'));
      }
      b.rect(1, 11, 32, 2, hx('#F4B8B0'));
      for (var x = 2; x < 33; x += 4) {
        b.rect(x, 11, 2, 2, hx('#D0302A'));
      }
    } else if (media) {
      // the cloth half over the rolls
      b.ell(22, 9.6, 10, 4.2, _hs(['#D0302A', '#F4B8B0', '#FFFFFF']));
      for (var x = 14; x < 30; x += 4) {
        b.rect(x, 7, 2, 4, hx('#FFFFFF'));
      }
    } else if (sin) {
      // no towel on the rim: it is in her hand
    } else {
      // a folded towel on the left rim (where abuela reaches it): white with red stripes
      b.rect(2, 6, 6, 6, hx('#FFFFFF'));
      b.rect(2, 6, 6, 1, hx('#E8E8F0'));
      b.rect(4, 6, 1, 6, hx('#D0302A'));
      b.rect(7, 6, 1, 6, hx('#D0302A'));
      b.rect(2, 11, 6, 1, hx('#D0302A'));
    }
    return b.outline().done();
  },
  // the two fillings: the same small bowl of blue and white china, 22 x 15. butter: a yellow block (v = how much is left,
  // 1 to 5); chocolate: melted, dark brown and shiny, with a spoon in it (v: the same)
  'mantequilla': (v) {
    final b = Buf(22, 15),
        n = math.max(1, math.min(5, _plus(jsTruthy(v) ? v : 5)));
    b.ell(11, 10.4, 10.2, 4, CERA);
    b.ell(11, 8.6, 8.4, 3, _hs(['#8A96C0', '#C4D0F0']));
    b.rect(3, 11, 16, 1, hx('#2E6CD0'));
    // a block of butter in the dish: it gets smaller as it is used
    final w = (5 + n * 1.6).truncate(),
        h = 2 + (n * .8).truncate(),
        x0 = 11 - (w >> 1),
        y0 = 9 - h;
    b.rect(x0, y0 + 1, w, h - 1, MANT);
    b.rect(x0 + 1, y0, w - 1, 1, hx('#FFFBE0'));
    b.rect(x0 + w - 1, y0 + 1, 1, h - 1, hx('#E0C860'));
    b.rect(x0, y0 + h - 1, w, 1, hx('#E0C860'));
    return b.outline().done();
  },
  // melted chocolate in the same bowl: dark, glossy, filling the bowl; a spoon handle stands in it
  'choc': (v) {
    final b = Buf(22, 15),
        n = math.max(1, math.min(5, _plus(jsTruthy(v) ? v : 5)));
    b.ell(11, 10.4, 10.2, 4, CERA);
    b.ell(11, 8.6, 8.4, 3, _hs(['#8A96C0', '#C4D0F0']));
    b.rect(3, 11, 16, 1, hx('#2E6CD0'));
    final rx = 3.6 + n * 1, ry = 1.3 + n * .35;
    b.ell(11, 8.8, rx, ry, [CHOC[0], CHOC[1], CHOC[2]]);
    b.px(8, 8, hx('#C89A74'));
    b.px(9, 8, hx('#C89A74'));
    b.px(13, 9, hx('#A0724C'));
    b.cap(13, 8, 18, 2, .7, _hs(['#8A8A9A', '#C8C8D4']));
    b.px(18, 1, hx('#F8F8FF'));
    return b.outline().done();
  },
  // a wooden board to fill the roll on
  'tabla': (_) {
    final b = Buf(24, 9), W = RP.wood;
    b.rect(1, 2, 22, 5, W[3]);
    b.rect(1, 2, 22, 1, W[4]);
    b.rect(1, 6, 22, 1, W[1]);
    b.rect(1, 7, 22, 1, W[0]);
    for (var x = 3; x < 20; x += 5) {
      b.rect(x, 4, 3, 1, W[2]);
    }
    b.rect(19, 3, 3, 1, W[0]);
    return b.outline().done();
  },
  // v "c": with a forkful of rice on it; "t": with a piece of cake (cream on top, brown sponge)
  'tenedor': (v) {
    final b = Buf(7, 15);
    for (final x in const [1, 3, 5]) {
      b.rect(x, 4, 1, 4, hx('#E8E8F2'));
    }
    b.rect(1, 7, 5, 2, hx('#D0D0DC'));
    b.rect(3, 9, 1, 6, hx('#D0D0DC'));
    b.rect(4, 9, 1, 6, hx('#9A9AAC'));
    if (v == 'c') {
      b.ell(3.5, 3.6, 3, 2.2, ARROZ);
      b.px(2, 2, hx('#FFF4B0'));
    }
    if (v == 't') {
      b.rect(0, 0, 7, 2, hx('#FFF8EC'));
      b.rect(0, 2, 7, 3, hx('#A8682C'));
      b.rect(0, 2, 7, 1, hx('#E0A458'));
      b.px(6, 0, hx('#FFFFFF'));
      b.px(0, 4, hx('#7A4A1E'));
      b.px(6, 4, hx('#7A4A1E'));
    }
    return b.outline().done();
  },
  'cuchara': (_) {
    final b = Buf(7, 12);
    b.ell(3.5, 3, 2.4, 3, _hs(['#8A8A9C', '#C8C8D4', '#F8F8FF']));
    b.rect(3, 5, 1, 7, hx('#C8C8D4'));
    b.rect(4, 5, 1, 7, hx('#8A8A9C'));
    return b.outline().done();
  },
  // a fork lying flat, tines to the left, 18 x 8
  'tenedorH': (_) {
    final b = Buf(18, 8);
    for (final y in const [1, 3, 5]) {
      b.rect(0, y, 6, 1, hx('#E8E8F2'));
    }
    b.rect(5, 1, 2, 5, hx('#D0D0DC'));
    b.rect(7, 3, 10, 2, hx('#D0D0DC'));
    b.rect(7, 4, 10, 1, hx('#9A9AAC'));
    return b.outline().done();
  },
  // a mound of yellow rice, 10 x 8
  'monton': (v) {
    final b = Buf(6, 5);
    if (v == '1') {
      b.ell(3, 3, 2, 1.5, ARROZ);
      b.px(2, 2, hx('#FFF4B0'));
    } else if (v == '2') {
      b.ell(3, 3.2, 1.2, .9, ARROZ);
    } else {
      b.ell(3, 2.8, 2.5, 1.9, ARROZ);
      b.px(2, 1, hx('#FFF4B0'));
      b.px(4, 2, hx('#FFF4B0'));
      b.rect(1, 4, 4, 1, hx('#B87A10'));
    }
    return b.done();
  },
  // the pot of rice on the table, 24 x 21: "lleno" (heaped, with its spoon), "lleno0" (no spoon), "vacio"
  'olla': (v0) {
    final b = Buf(24, 21);
    b.rect(3, 7, 18, 12, hx('#8A8A9A'));
    b.rect(3, 7, 5, 12, hx('#B8B8C8'));
    b.rect(3, 16, 18, 3, hx('#5A5A6A'));
    b.rect(0, 9, 3, 3, hx('#3A3A46'));
    b.rect(21, 9, 3, 3, hx('#3A3A46'));
    b.ell(12, 7, 9, 3.2, _hs(['#5A5A6A', '#9494A6', '#C8C8D4']));
    final v = jsTruthy(v0) ? _str(v0) : '';
    if (RegExp(r'^n[1-7]$').hasMatch(v)) {
      // the rice goes down with every scoop: the surface is smaller and lower
      final L = int.parse(v[1]);
      b.ell(12, 7.2, 7.4, 2.6, _hs(['#1E1E28', '#2A2A36']));
      b.ell(
        12,
        6.8 + L * .25,
        math.max(2.4, 7.4 - L * .62),
        2.6 - L * .14,
        _hs(['#C88A10', '#F2C028', '#FFE060']),
      );
      if (L <= 3) {
        b.ell(
          12,
          5.4 + L * .5,
          math.max(1.5, 4.8 - L * 1.2),
          math.max(1, 2.8 - L * .6),
          ARROZ,
        );
      }
      for (final q in const [
        [8, 7],
        [10, 7],
        [14, 7],
        [12, 6],
      ]) {
        if ((q[0] - 12).abs() < 7.4 - L * .62) {
          b.px(q[0], q[1] + (L > 3 ? 1 : 0), _grano(q[0], q[1]));
        }
      }
    } else if (v == 'vacio') {
      b.ell(12, 7.4, 7.4, 2.6, _hs(['#1E1E28', '#2A2A36']));
      b.px(8, 7, hx('#FFF4B0'));
      b.px(16, 8, hx('#B87A10'));
    } else if (v == 'm1') {
      b.ell(12, 7.4, 7.4, 2.6, _hs(['#1E1E28', '#2A2A36']));
      b.ell(12, 8, 4, 1.4, _hs(['#C88A10', '#F2C028']));
      b.px(11, 8, hx('#FFF4B0'));
    } else if (v == 'm2') {
      b.ell(12, 7.2, 7.4, 2.6, _hs(['#1E1E28', '#2A2A36']));
      b.ell(12, 7.8, 6, 2, _hs(['#C88A10', '#F2C028', '#FFE060']));
      b.px(10, 7, hx('#FFF4B0'));
      b.px(14, 8, hx('#B87A10'));
    } else if (v == 'm3') {
      b.ell(12, 6.8, 7.4, 2.6, _hs(['#C88A10', '#F2C028', '#FFE060']));
      for (final q in const [
        [8, 6],
        [10, 7],
        [14, 6],
        [16, 7],
        [12, 6],
      ]) {
        b.px(q[0], q[1], _grano(q[0], q[1]));
      }
    } else {
      b.ell(12, 6.8, 7.4, 2.6, _hs(['#C88A10', '#F2C028', '#FFE060']));
      b.ell(12, 5, 4.8, 2.8, ARROZ);
      for (final q in const [
        [8, 6],
        [10, 7],
        [14, 6],
        [16, 7],
        [17, 6],
        [9, 5],
        [14, 4],
      ]) {
        b.px(q[0], q[1], _grano(q[0], q[1]));
      }
    }
    if (v == 'lleno') b.cap(16, 6, 20, 1, .8, _hs(['#B07A3C', '#D09A54']));
    final c = b.outline().done();
    PICO[c] = const [2, 7];
    return c;
  },
  // the platter for the second helpings, 28 x 17 (about as wide as abuela): a blue plate with a rim; the mounds lie on it
  // (drawn by the scene), and papá's fork. v "c": lying on the stove, seen from the front, flat
  'fuente': (v) {
    if (v == 'c') {
      final b = Buf(28, 9);
      b.ell(14, 5, 13, 3.4, _hs(['#2A5C9C', '#4A86C8', '#8CB8E8']));
      b.ell(14, 4.5, 11, 2, _hs(['#6AA0DC', '#A8CCF0']));
      return b.outline().done();
    }
    final b = Buf(28, 17);
    b.ell(14, 9, 13, 6.6, _hs(['#2A5C9C', '#4A86C8', '#8CB8E8']));
    b.ell(14, 8.4, 11, 5, _hs(['#6AA0DC', '#A8CCF0']));
    b.rect(8, 14, 12, 1, hx('#2E6CD0'));
    return b.outline().done();
  },
  'sillaBebe': (v) => mkSillaBebe(v),
  'taburete': (_) => mkTaburete(),
  'bebe': (_) => mkBebe('idle', false),
  // the baby of the high chair, out of it, in somebody's hands: 16 x 20, the same head, shirt and bib
  'bebeH': (_) {
    final b = Buf(16, 20);
    b.ell(8, 14.6, 7.4, 5.2, _hs(['#B87A10', '#E0A020', '#F8C838']));
    b.ell(8, 15.2, 4.4, 3.6, _hs(['#E8F0FA', '#FFFFFF']));
    b.rect(4, 12, 8, 1, hx('#8CB8E8'));
    b.ell(8, 6.8, 6.4, 6.2, RP.skin.sublist(2));
    b.px(6, 6, hx('#20140A'));
    b.px(10, 6, hx('#20140A'));
    b.px(6, 5, hx('#FFFFFF'));
    b.px(10, 5, hx('#FFFFFF'));
    b.px(4, 9, hx('#E08A70'));
    b.px(12, 9, hx('#E08A70'));
    b.rect(7, 10, 3, 1, hx('#7A2A1A'));
    b.px(6, 9, hx('#7A2A1A'));
    b.px(10, 9, hx('#7A2A1A'));
    for (final q in const [
      [8, 0],
      [9, 1],
      [7, 1],
      [8, 1],
    ]) {
      b.px(q[0], q[1], PELO['castano']![2]);
    }
    return b.outline().done();
  },
  // a thought: a mound with a heart; his own round belly with a hand on it beside his clean plate (full, content)
  'montoncor': (_) {
    final b = Buf(20, 19);
    b.ell(10, 15.6, 8.6, 3, PLATO);
    b.ell(10, 15, 5.8, 1.8, _hs(['#6AA0DC', '#A8CCF0']));
    b.ell(10, 12.4, 4, 2.8, ARROZ);
    b.px(9, 11, hx('#FFF4B0'));
    const H = [
      '.##.##.',
      '#######',
      '#######',
      '.#####.',
      '..###..',
      '...#...',
    ];
    for (var j = 0; j < H.length; j++) {
      final rw = H[j];
      for (var i = 0; i < 7; i++) {
        if (rw[i] == '#') {
          b.px(
            7 + i - 3,
            0 + j,
            j < 2 && i < 3 ? hx('#FF9A90') : hx('#E8443C'),
          );
        }
      }
    }
    return b.outline().done();
  },
  'barriga': (_) {
    final b = Buf(48, 36), T = RP.tan;
    // his clean plate
    b.ell(7, 32, 6, 2.4, PLATO);
    b.ell(7, 31.6, 4, 1.4, [hx('#A8CCF0')]);
    // his feet
    b.ell(21, 34, 4.4, 2, T);
    b.ell(37, 34, 4.4, 2, T);
    // the big round belly, twice as wide as his head
    b.ell(29, 22, 15.4, 11.6, [T[2]]);
    b.ell(29, 22.4, 13, 9.4, _hs(['#EEDCB0', '#FBF0D2']));
    b.px(29, 23, hx('#B89A6A'));
    b.px(30, 23, hx('#B89A6A'));
    // eyes shut, a smile
    b.ell(29, 8, 7.6, 4.8, T);
    for (final dx in const [-5, 5]) {
      b.ell(29 + dx, 4.4, 3, 3, T);
      b.rect(29 + dx - 1.5, 3.6, 3, 1, hx('#20140A'));
    }
    b.rect(26, 10, 6, 1, hx('#7A2A1A'));
    b.px(25, 9, hx('#7A2A1A'));
    b.px(32, 9, hx('#7A2A1A'));
    // both hands on the belly
    b.ell(19, 20, 3, 2.4, [T[3]]);
    b.px(17, 18, T[4]);
    b.px(19, 17, T[4]);
    b.px(21, 18, T[4]);
    b.ell(39, 20, 3, 2.4, [T[3]]);
    b.px(37, 18, T[4]);
    b.px(39, 17, T[4]);
    b.px(41, 18, T[4]);
    return b.outline().done();
  },
  // cups seen a little from above, 17 x 17: a blue cup with a handle; v: what is in it (negro black coffee, marron dark
  // brown, palido light tan, leche white milk, vacia empty: its dark inside)
  'taza': (v) => mkTaza(v, 0),
  // a cup with a spoon standing in it (sugar was stirred in)
  'tazacu': (v) => mkTaza(v, 1),
  // the sugar bowl, 22 x 20: white china with a blue band and two small ear handles, a heap of white sugar over its rim
  // with four cubes on top and two light-blue glints, one teaspoon standing in it (v "0": the spoon is gone). v "L3" /
  // "L0": the same on the table, 38 x 20 (the bowl in the middle), with its lid lying beside it on the right
  'azucarera': (v) {
    final s = v == null ? '3' : _str(v), lid = s.isNotEmpty && s[0] == 'L';
    final n0 = _plus(lid ? s.substring(1) : s);
    final n = math.max(0, math.min(3, _or(n0, 0))),
        W = lid ? 38 : 22,
        ox = (W - 22) >> 1,
        b = Buf(W, 20);
    void Rc(num x, num y, num w, num h, int c) => b.rect(x + ox, y, w, h, c);
    void Pp(num x, num y, int c) => b.px(x + ox, y, c);
    void row(int y, int x0, int x1, int Function(int x, int y) f) {
      for (var x = x0; x <= x1; x++) {
        Pp(x, y, f(x, y));
      }
    }

    // cool white china, light from the left
    int china(int x, int y) => x <= 5
        ? hx('#F4F8FF')
        : x <= 8
        ? hx('#DCE6F8')
        : x <= 12
        ? hx('#C0CEEC')
        : x <= 14
        ? hx('#9CAEDA')
        : hx('#7A8EC4');
    // the body
    for (final r in const [
      [10, 4, 17],
      [11, 4, 17],
      [12, 4, 17],
      [13, 4, 17],
      [14, 4, 17],
      [15, 5, 16],
      [16, 6, 15],
      [17, 7, 14],
    ]) {
      row(r[0], r[1], r[2], china);
    }
    // the lip, and the line under it
    row(
      10,
      4,
      17,
      (x, y) => x <= 8
          ? hx('#FFFFFF')
          : x <= 14
          ? hx('#E4ECFA')
          : hx('#B4C4E8'),
    );
    row(11, 4, 17, (x, y) => hx('#8CA0D0'));
    // the blue band
    row(13, 4, 17, (x, y) => hx('#6AA8F8'));
    row(14, 4, 17, (x, y) => x >= 15 ? hx('#1E4FA8') : hx('#2E6CD0'));
    row(
      15,
      5,
      16,
      (x, y) => x <= 6
          ? hx('#DCE6F8')
          : x <= 12
          ? hx('#9CAEDA')
          : hx('#7A8EC4'),
    );
    row(
      16,
      6,
      15,
      (x, y) => x <= 8
          ? hx('#B4C4E8')
          : x <= 12
          ? hx('#7A8EC4')
          : hx('#6478B0'),
    );
    row(17, 7, 14, (x, y) => x <= 9 ? hx('#8CA0D0') : hx('#6478B0'));
    // two ear handles, small rings hanging from the sides
    for (final h in const [
      [1, 1],
      [18, 0],
    ]) {
      final x = h[0], L = h[1] != 0;
      Rc(x, 12, 3, 1, L ? hx('#F4F8FF') : hx('#C0CEEC'));
      Rc(x, 16, 3, 1, L ? hx('#9CAEDA') : hx('#6478B0'));
      Rc(L ? x : x + 2, 13, 1, 3, L ? hx('#DCE6F8') : hx('#7A8EC4'));
    }
    // the heap of white sugar: bright, with grains
    for (final r in const [
      [4, 9, 12],
      [5, 8, 13],
      [6, 7, 14],
      [7, 5, 16],
      [8, 4, 17],
      [9, 4, 17],
    ]) {
      row(r[0], r[1], r[2], (x, y) {
        final t = hs(x, y) % 7;
        return t == 0
            ? hx('#B4C4E8')
            : t == 1
            ? hx('#E4ECFA')
            : hx('#FFFFFF');
      });
    }
    // four small square cubes
    for (final q in const [
      [5, 6],
      [9, 3],
      [13, 6],
      [9, 6],
    ]) {
      Rc(q[0], q[1], 3, 3, hx('#FFFFFF'));
      Rc(q[0], q[1] + 2, 3, 1, hx('#7A8EC4'));
      Rc(q[0] + 2, q[1], 1, 2, hx('#9CAEDA'));
      Rc(q[0], q[1], 1, 1, hx('#FFFFFF'));
    }
    // two light-blue glints
    for (final q in const [
      [7, 4],
      [12, 9],
    ]) {
      Pp(q[0], q[1], hx('#6CC4FF'));
      Pp(q[0] + 1, q[1], hx('#A8DCFF'));
    }
    // the teaspoon
    if (n > 0) {
      Rc(15, 0, 1, 9, hx('#8A8A9A'));
      Rc(16, 0, 1, 9, hx('#C8C8D4'));
      b.ell(15.8 + ox, 1, 1.8, 1.4, _hs(['#C8C8D4', '#F8F8FF']));
    }
    if (lid) {
      // the lid, face up: a low dome with a blue band round its rim and a blue knob
      b.ell(33, 17.4, 4.7, 1.7, _hs(['#6478B0', '#9CAEDA']));
      b.ell(33, 15.6, 4.2, 2.7, _hs(['#8CA0D4', '#DCE6F8', '#FFFFFF']));
      for (var x = 28; x < 38; x++) {
        if (b.has(x, 17)) b.px(x, 17, hx('#2E6CD0'));
      }
      b.rect(32, 12, 2, 3, hx('#9CAEDA'));
      b.rect(32, 12, 2, 2, hx('#2E6CD0'));
      b.px(32, 12, hx('#6AA8F8'));
    }
    return b.outline().done();
  },
  // the big pot of coffee (enamel, blue, a spout and a handle), 18 x 21; pico: the lip
  'cafetera': (_) {
    final b = Buf(18, 21);
    b.rect(4, 7, 10, 12, hx('#2A5C9C'));
    b.rect(4, 7, 2, 12, hx('#6AA0DC'));
    b.rect(4, 16, 10, 3, hx('#1A3C6C'));
    b.ell(9, 6.6, 5.4, 2, _hs(['#1A3C6C', '#2A5C9C']));
    b.rect(7, 2, 3, 3, hx('#141418'));
    b.rect(2, 7, 2, 2, hx('#2A5C9C'));
    b.rect(1, 6, 2, 2, hx('#2A5C9C'));
    b.rect(14, 8, 2, 9, hx('#141418'));
    b.rect(13, 8, 3, 2, hx('#141418'));
    b.rect(13, 15, 3, 2, hx('#141418'));
    b.px(7, 11, hx('#FFFFFF'));
    b.px(10, 14, hx('#FFFFFF'));
    final c = b.outline().done();
    PICO[c] = const [1, 7];
    return c;
  },
  // the greca: the little coffee pot, red, two chambers with a waist between them, a lid with a knob, a spout and a black
  // handle, 14 x 16; pico: the spout
  'jarrita': (_) {
    final b = Buf(14, 16);
    b.rect(2, 9, 8, 6, hx('#B0302A'));
    b.rect(2, 9, 2, 6, hx('#F08880'));
    b.rect(2, 13, 8, 2, hx('#7A1C1C'));
    b.rect(3, 7, 6, 3, hx('#8A2020'));
    b.rect(3, 7, 1, 3, hx('#C8403A'));
    b.rect(2, 2, 8, 6, hx('#B0302A'));
    b.rect(2, 2, 2, 6, hx('#F08880'));
    b.rect(2, 2, 8, 1, hx('#C8403A'));
    b.rect(5, 0, 2, 2, hx('#141418'));
    b.rect(1, 3, 1, 2, hx('#B0302A'));
    b.rect(10, 3, 2, 2, hx('#141418'));
    b.rect(11, 3, 2, 10, hx('#141418'));
    b.rect(10, 11, 2, 2, hx('#141418'));
    b.px(5, 12, hx('#FFFFFF'));
    b.px(6, 4, hx('#FFFFFF'));
    final c = b.outline().done();
    PICO[c] = const [1, 3];
    return c;
  },
  // the milk pan: a saucepan, grey metal with a black handle and a pouring lip, v "1" with milk, "0" empty; 21 x 11;
  // pico: the lip
  'cazo': (v) {
    final b = Buf(21, 11);
    b.rect(2, 4, 11, 6, hx('#8E92A6'));
    b.rect(2, 4, 2, 6, hx('#C8CCDA'));
    b.rect(2, 8, 11, 2, hx('#5A5E70'));
    b.ell(7.5, 4, 6, 2.2, _hs(['#6A6E80', '#B8BCCC', '#E8EAF2']));
    b.ell(
      7.5,
      4,
      4.8,
      1.5,
      v == '0'
          ? _hs(['#2A2A36', '#4A4A58'])
          : _hs(['#E4DCC8', '#F6F1E4', '#FFFFFF']),
    );
    b.rect(13, 4, 6, 2, hx('#141418'));
    b.rect(17, 3, 2, 4, hx('#141418'));
    b.px(1, 3, hx('#B8BCCC'));
    b.px(0, 3, hx('#B8BCCC'));
    final c = b.outline().done();
    PICO[c] = const [0, 3];
    return c;
  },
  // the dog's bowl: with milk in it, or empty
  'tazon': (v) {
    final b = Buf(22, 10);
    b.ell(11, 6, 10, 3.6, _hs(['#2A5C9C', '#4A86C8', '#8CB8E8']));
    b.ell(11, 4.8, 7.8, 2.4, _hs(['#1E3A68', '#2A5C9C']));
    if (v == '1') {
      b.ell(11, 4.8, 7.8, 2.4, _hs(['#E4DCC8', '#F6F1E4', '#FFFFFF']));
    } else if (v == '2') {
      b.ell(11, 5.2, 4.6, 1.4, _hs(['#E4DCC8', '#F6F1E4', '#FFFFFF']));
    }
    return b.outline().done();
  },
  // a baking tray with n rolls on it, for abuela to carry: a metal tray with a rim all round and a handle at each end,
  // 26 x 21 (about as wide as abuela): two rolls across and two rows, each roll apart from the next with its own dark
  // edge, so that all four are counted at a glance
  'bandeja': (n0) {
    final b = Buf(26, 21), n = n0 == null ? 4 : _plus(n0);
    b.rect(2, 5, 22, 14, hx('#6A6E80'));
    b.rect(3, 6, 20, 12, hx('#E0D2A8'));
    b.rect(3, 6, 20, 1, hx('#B8A878'));
    b.rect(2, 4, 22, 2, hx('#D8DCEA'));
    b.rect(0, 10, 3, 4, hx('#4A4E60'));
    b.rect(23, 10, 3, 4, hx('#4A4E60'));
    const P = [
      [8, 12],
      [18, 12],
      [8, 18],
      [18, 18],
    ];
    final k = n.isNaN ? 0 : math.max(0, math.min(4, n.toInt()));
    for (final p in P.sublist(0, k)) {
      rollitos(b, p[0], p[1]);
    }
    b.rect(2, 18, 22, 2, hx('#6A6E80'));
    b.rect(2, 18, 22, 1, hx('#E8ECF8'));
    b.rect(2, 19, 22, 1, hx('#4A4E60'));
    return b.outline().done();
  },
  'pano': (_) {
    final b = Buf(12, 10);
    b.rect(1, 1, 10, 8, hx('#F8F8FF'));
    b.rect(1, 4, 10, 1, hx('#E0403A'));
    b.rect(1, 7, 10, 1, hx('#E0403A'));
    return b.outline().done();
  },
  'charco': (_) {
    final b = Buf(19, 8);
    b.ell(8, 4, 5.4, 1.8, [hx('#6A3214')]);
    b.ell(12, 3, 3, 1.4, [hx('#6A3214')]);
    return b.outline().done();
  },
  // pictures of the pairs: a drumstick, a slice of cake, a bowl of rice for the dog, a jug, a glass
  'muslo': (v) {
    final b = Buf(24, 14);
    b.ell(8, 7, 7.8, 5.6, _hs(['#8A4A14', '#C87A28', '#E8A848']));
    b.px(5, 4, hx('#F8D890'));
    b.px(6, 3, hx('#F8D890'));
    b.px(7, 3, hx('#F8D890'));
    b.rect(14, 6, 6, 2, hx('#F2EAD8'));
    b.ell(20, 5.6, 2.4, 2.4, [hx('#F2EAD8')]);
    b.ell(20, 9.4, 2.4, 2.4, [hx('#F2EAD8')]);
    if (v == 'b') {
      // a bite out of it
      borra(b, 1, 5, 3.6);
      b.ell(4.6, 6, 1.6, 2.6, [hx('#F8E4B0')]);
      borra(b, 1.6, 5.2, 2.8);
    }
    return b.outline().done();
  },
  'manzana': (_) {
    final b = Buf(11, 11);
    b.ell(3.6, 6.4, 3, 4, _hs(['#A01818', '#D02828', '#F05848']));
    b.ell(7.4, 6.4, 3, 4, _hs(['#A01818', '#D02828', '#F05848']));
    b.rect(5, 1, 1, 3, hx('#5A3A1A'));
    b.px(6, 1, hx('#48A848'));
    b.px(2, 4, hx('#FFB0A0'));
    return b.outline().done();
  },
  // a teaspoon lying on the table, 12 x 4: a handle and a small bowl
  'cucharilla': (_) {
    final b = Buf(12, 4);
    b.rect(1, 1, 7, 1, hx('#C8C8D4'));
    b.rect(1, 2, 6, 1, hx('#8A8A9A'));
    b.ell(9, 1.8, 1.9, 1.2, _hs(['#8A8A9A', '#F8F8FF']));
    return b.outline().done();
  },
  // a slice of cake: a wedge with frosting on top and a layer of jam in its side. On a small plate (22 x 16); a bite of
  // it on a fork (14 x 14); a whole slice on a fork (22 x 16)
  'bizcocho': (v) {
    final b = Buf(22, 16);
    b.ell(11, 12.6, 10.4, 3.2, PLATO);
    b.ell(11, 12, 7.4, 2, _hs(['#6AA0DC', '#A8CCF0']));
    tajada(b, 3, 1);
    // a bite: a round piece gone, the cut shows pale sponge along its edge
    void muerde(num cx, num cy, num r) {
      for (var y = 0; y < b.h; y++) {
        for (var x = 0; x < b.w; x++) {
          if (b.has(x, y) &&
              (b.d[y * b.w + x] & 0xFF) > 180 &&
              _hypot(x + .5 - cx, y + .5 - cy) < r + 1.5) {
            b.px(x, y, hx('#F8E4B0'));
          }
        }
      }
      borra(b, cx, cy, r);
    }

    if (v == 'b2') {
      // a big bite gone from the left of the slice, crumbs on the plate
      muerde(7, 8.2, 5.4);
      for (final q in const [
        [9, 13],
        [11, 13],
        [13, 13],
      ]) {
        b.px(q[0], q[1], hx('#E8D8C0'));
      }
    }
    // one small bite from its left side
    if (v == 'b1') muerde(8.6, 8.8, 2.3);
    return b.outline().done();
  },
  'bizcochoT': (_) {
    final b = Buf(16, 15);
    tajada(b, 0, 2, .55);
    b.rect(8, 9, 7, 1, hx('#C8C8D4'));
    b.rect(10, 10, 1, 5, hx('#C8C8D4'));
    b.rect(11, 10, 1, 5, hx('#8A8A9A'));
    b.rect(3, 8, 1, 3, hx('#C8C8D4'));
    b.rect(6, 8, 1, 3, hx('#C8C8D4'));
    return b.outline().done();
  },
  'bizcochoL': (_) {
    final b = Buf(24, 18);
    tajada(b, 0, 0, 1);
    b.rect(15, 12, 8, 1, hx('#C8C8D4'));
    b.rect(17, 13, 1, 5, hx('#C8C8D4'));
    b.rect(18, 13, 1, 5, hx('#8A8A9A'));
    b.rect(4, 11, 1, 4, hx('#C8C8D4'));
    b.rect(8, 11, 1, 4, hx('#C8C8D4'));
    b.rect(12, 11, 1, 4, hx('#C8C8D4'));
    return b.outline().done();
  },
  'entero': (_) {
    final b = Buf(26, 16);
    b.ell(13, 10, 11.6, 4.6, _hs(['#C88A30', '#E8B050', '#F8DC90']));
    b.ell(13, 6.8, 11.6, 4.2, _hs(['#F2E4D0', '#FFF4E0', '#FFFFFF']));
    for (final x in const [7, 13, 19]) {
      b.px(x, 5, hx('#D0302A'));
    }
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
  // the dog's bowl for the pair: the same bowl in both pictures. "limpio": clean inside, light and a shine; "lleno":
  // heaped with white rice
  'cuenco': (v) {
    final b = Buf(30, 18);
    b.ell(15, 11, 14, 5.6, _hs(['#2A5C9C', '#4A86C8', '#8CB8E8']));
    b.rect(2, 11, 26, 1, hx('#1E3A68'));
    if (v == 'lleno') {
      b.ell(15, 9.4, 11.4, 3.8, _hs(['#E4E4EC', '#FFFFFF']));
      b.ell(15, 6.6, 8.6, 4.8, _hs(['#E4E4EC', '#F8F8FC', '#FFFFFF']));
      b.ell(15, 3.6, 5, 3, _hs(['#E4E4EC', '#F8F8FC', '#FFFFFF']));
      for (final q in const [
        [9, 8],
        [13, 5],
        [18, 6],
        [21, 9],
        [12, 10],
        [16, 3],
        [19, 10],
      ]) {
        b.px(
          q[0],
          q[1],
          hs(q[0], q[1]) % 2 != 0 ? hx('#B8B8CC') : hx('#FFFFFF'),
        );
      }
    } else {
      b.ell(15, 9.4, 11.4, 3.8, _hs(['#4A7EC0', '#8CB4E4']));
      b.ell(15, 10.2, 8.4, 2, _hs(['#6A98D4', '#A8C8EE']));
      b.rect(7, 7, 7, 1, hx('#FFFFFF'));
      b.rect(8, 8, 3, 1, hx('#FFFFFF'));
      b.px(21, 10, hx('#FFFFFF'));
    }
    return b.outline().done();
  },
  // the shadow of a cup or a plate on the cloth, so that it sits and does not float
  'sombra': (_) {
    final b = Buf(22, 6);
    b.ell(11, 3, 10, 2.4, [hx('#E69C94')]);
    return b.done();
  },
  'granos': (_) {
    final b = Buf(8, 5);
    for (final q in const [
      [1, 1],
      [3, 3],
      [5, 0],
      [6, 3],
    ]) {
      b.px(q[0], q[1], hx('#F6F0DC'));
    }
    return b.outline().done();
  },
  // a grain falling from the spoon: two white pixels square
  'grano': (_) {
    final b = Buf(2, 2);
    b.rect(0, 0, 2, 2, hx('#FFFFFF'));
    return b.outline().done();
  },
  // the same grain with its dark edge, so that it shows on the white of the cloth (the pair)
  'granob': (_) {
    final b = Buf(4, 4);
    b.rect(1, 1, 2, 2, hx('#FFFFFF'));
    return b.outline().done();
  },
  'jarra': (v) {
    final b = Buf(23, 29), n = v == null ? 4 : _plus(v);
    b.rect(3, 3, 13, 25, hx('#DCF2FA'));
    b.rect(3, 3, 2, 25, hx('#F2FBFF'));
    if (n > 0) b.rect(4, 27 - n * 5, 11, n * 5, hx('#F08818'));
    for (var i = 1; i <= 4; i++) {
      b.rect(11, 27 - i * 5, 5, 1, hx('#4A5A6A'));
    }
    b.rect(16, 7, 3, 1, hx('#B8D8E8'));
    b.rect(19, 8, 1, 11, hx('#B8D8E8'));
    b.rect(16, 19, 3, 1, hx('#B8D8E8'));
    b.rect(1, 3, 2, 2, hx('#DCF2FA'));
    return b.outline().done();
  },
  'jugo': (_) {
    final b = Buf(23, 29);
    b.rect(3, 3, 13, 25, hx('#DCF2FA'));
    b.rect(3, 3, 2, 25, hx('#F2FBFF'));
    b.rect(4, 27 - 20, 11, 20, hx('#F08818'));
    b.rect(4, 7, 11, 2, hx('#FFB040'));
    b.rect(16, 7, 3, 1, hx('#B8D8E8'));
    b.rect(19, 8, 1, 11, hx('#B8D8E8'));
    b.rect(16, 19, 3, 1, hx('#B8D8E8'));
    b.rect(1, 3, 2, 2, hx('#DCF2FA'));
    return b.outline().done();
  },
  'jugopoco': (_) {
    final b = Buf(23, 29);
    b.rect(3, 3, 13, 25, hx('#DCF2FA'));
    b.rect(3, 3, 2, 25, hx('#F2FBFF'));
    b.rect(4, 25, 11, 2, hx('#F08818'));
    b.rect(4, 24, 11, 1, hx('#FFB040'));
    b.rect(16, 7, 3, 1, hx('#B8D8E8'));
    b.rect(19, 8, 1, 11, hx('#B8D8E8'));
    b.rect(16, 19, 3, 1, hx('#B8D8E8'));
    b.rect(1, 3, 2, 2, hx('#DCF2FA'));
    return b.outline().done();
  },
  // the milk jug for the pair: a small white pitcher, about 12 x 11, a round belly, a pouring spout and a ring handle; v
  // "T": tipped (26 degrees, to pour to the right: the handle up on the left, the spout down on the right); pico: the lip
  // of the spout
  'lechera': (v) => mkLechera(v == 'T' ? .45 : 0),
  // a glass of orange juice, 9 x 13
  'vasojugo': (_) {
    final b = Buf(9, 13);
    b.rect(1, 1, 7, 11, hx('#DCF2FA'));
    b.rect(1, 1, 2, 11, hx('#F2FBFF'));
    b.rect(2, 4, 5, 8, hx('#F08818'));
    b.rect(2, 3, 5, 1, hx('#FFB040'));
    return b.outline().done();
  },
  // a big hand, laid flat on the belly (v: the colour of the skin)
  'manoG': (v) {
    final b = Buf(10, 8), c = hexColour(jsTruthy(v) ? '$v' : '#D09460');
    b.ell(5, 4.4, 4.4, 3.2, [c]);
    b.px(2, 1, c);
    b.px(4, 0, c);
    b.px(6, 0, c);
    b.px(8, 1, c);
    b.px(3, 6, hx('#7A4A2A'));
    b.px(5, 6, hx('#7A4A2A'));
    b.px(7, 6, hx('#7A4A2A'));
    return b.outline().done();
  },
  // a thing for a thought: a question mark; a heart
  'interroga': (_) {
    final b = Buf(9, 13);
    const Q = [
      '..###..',
      '.##.##.',
      '.##.##.',
      '....##.',
      '...##..',
      '..##...',
      '..##...',
      '.......',
      '..##...',
    ];
    for (var j = 0; j < Q.length; j++) {
      for (var i = 0; i < 7; i++) {
        if (Q[j][i] == '#') b.px(1 + i, 1 + j, hx('#3A3A46'));
      }
    }
    return b.outline(hx('#FFFFFF')).done();
  },
  'corazon': (_) {
    final b = Buf(9, 8);
    const H = [
      '.##.##.',
      '#######',
      '#######',
      '.#####.',
      '..###..',
      '...#...',
    ];
    for (var j = 0; j < H.length; j++) {
      for (var i = 0; i < 7; i++) {
        if (H[j][i] == '#') {
          b.px(1 + i, 1 + j, j < 2 && i < 3 ? hx('#FF9A90') : hx('#E8443C'));
        }
      }
    }
    return b.outline().done();
  },
};

// JavaScript: Math.hypot
double _hypot(num a, num b) => math.sqrt(a * a + b * b);

// comer.js: cosaIm. A tipped pot (`tilt` + its kind) is the standing one turned (at 50 degrees, or 32 for "suave") to
// pour to the left
Sprite cosaIm(String k, [Object? c]) {
  if (k.startsWith('tilt')) {
    final base = k.substring(4),
        b = COSA[base]!(c == 'suave' ? null : c),
        g = giro(b, c == 'suave' ? -0.55 : -0.9, PICO[b]);
    return g;
  }
  return (COSA[k] ?? COSA['plato']!)(c);
}

/* ---------- what is drawn by hand ---------- */

// comer.js: recolor. The colours of a picture changed by the map (opaque pixels only)
Sprite recolor(Sprite cv, Map<int, int> map) {
  final p = cv.px;
  for (var i = 0; i < p.length; i++) {
    final v = p[i];
    if ((v >>> 24) == 0) continue;
    final m = map[v & 0xFFFFFF];
    if (m != null) p[i] = (v & 0xFF000000) | (m & 0xFFFFFF);
  }
  return cv;
}

// comer.js: APRON. abuela's apron is teal here, so that it is not the white of the rice and the sugar
final Map<int, int> APRON = {
  for (final e in const {
    '#B89A6A': '#2A8A8E',
    '#D8BC8A': '#3AAAAA',
    '#EEDCB0': '#5CCCC8',
    '#FBF0D2': '#8CE0DA',
    '#FFFBEA': '#B8F0EA',
  }.entries)
    hx(e.key) & 0xFFFFFF: hx(e.value),
};

// comer.js: mkAbuelaC, mkAbuelaSC (made by the old file, used by none of its lines)
Sprite mkAbuelaC(String ps, bool hb) => recolor(mkAbuela(ps, hb), APRON);
Sprite mkAbuelaSC(String ps, bool hb) =>
    recolor(mkAbuelaS(ps, hb, false), APRON);

/* ---------- bodies without arms, arms that bend, legs that step ---------- */

// comer.js:21 QUIEN's abuelo: he wears a green shirt here: the cream of his own would melt into the white of the rice
final Who ABUELO_VERDE = () {
  final a = FAM['abuelo']!;
  return Who(
    nino: a.nino,
    piel: a.piel,
    pelo: a.pelo,
    peinado: a.peinado,
    ropa: RP.grn.sublist(1),
    abajo: a.abajo,
    falda: a.falda,
    bigote: a.bigote,
    gafas: a.gafas,
    lazo: a.lazo,
    zapato: a.zapato,
    dormido: a.dormido,
    detalle: (b, X, tc, rx, t) {
      b.rect(X, tc - 8, 1, t + 6, RP.grn[0]);
      b.rect(X - 5, tc - 1, 3, 3, RP.grn[0]);
      b.rect(X + 3, tc - 1, 3, 3, RP.grn[0]);
      b.rect(X - 5, tc - 1, 3, 1, RP.grn[3]);
      b.rect(X + 3, tc - 1, 3, 1, RP.grn[3]);
    },
  );
}();

// comer.js: mkPersonaN. Every person is drawn here without arms; his arms are drawn over him. [dormido], [cara], [giro]:
// the old `Object.assign({}, w, ...)` of cuerpo (his eyes shut, abuelo's two faces, his head turned a little)
Sprite mkPersonaN(
  Who w,
  bool open,
  bool sent,
  int pie, {
  bool dormido = false,
  String? cara,
  num giro = 0,
}) {
  final t = w.nino ? 7 : 11,
      l = sent ? 4 : (w.nino ? 7 : 11),
      rx = w.nino ? 6.5 : 8,
      H = 18 + 2 * t + l + 4,
      b = Buf(48, H + 1);
  const X = PX;
  final S = w.piel, Rr = w.ropa, A = w.abajo ?? w.ropa, P = w.pelo;
  final tc = 18 + t, hc = 18 + 2 * t - 2, lt = hc + 2, lb = lt + l;
  final dark = hx('#2A1810'), eye = hx('#20140A');
  final lf = sent ? 0 : 2, L1 = pie == 1 ? lf : 0, L2 = pie == 2 ? lf : 0;
  final sleep = dormido || w.dormido;
  // one foot is lifted when he steps
  if (w.falda) {
    b.rect(X - 4, lt, 3, l - L1, S[2]);
    b.rect(X + 1, lt, 3, l - L2, S[1]);
  } else {
    b.rect(X - 5, lt - 2, 4, l + 2 - L1, A[1]);
    b.rect(X + 1, lt - 2, 4, l + 2 - L2, A[0]);
    b.rect(X - 5, lt - 2, 1, l + 2 - L1, A[2]);
  }
  b.ell(X - 3.5, lb + 1.5 - L1, 3.3, 1.8, [w.zapato ?? hx('#3A2414')]);
  b.ell(X + 3.5, lb + 1.5 - L2, 3.3, 1.8, [w.zapato ?? hx('#3A2414')]);
  final A2 = [A[0], A[1], A[1]];
  if (w.falda) {
    b.ell(X, tc, rx, t + 1, Rr);
    b.ell(X, hc + 1, rx + 2.4, sent ? 4 : 5.5, Rr);
  } else {
    b.ell(X, hc, rx - .8, 3.4, A2);
    b.ell(X, tc - 1, rx, t, Rr);
  }
  if (sent && !w.falda) {
    b.ell(X - 4, hc + 2, 4.2, 3.2, A2);
    b.ell(X + 4, hc + 2, 4.2, 3.2, A2);
  }
  if (w.detalle != null) w.detalle!(b, X, tc, rx, t);
  b.rect(X - 2, 16, 4, 4, S[1]);
  if (w.peinado == 'largo') {
    b.ell(X, 11, 8, 8.8, P);
    b.rect(X - 8, 11, 3, t + 2, P[1]);
    b.rect(X + 5, 11, 3, t + 2, P[0]);
  }
  b.ell(X, 11.4, 5.8, 6.4, S);
  if (w.peinado == 'calvo') {
    b.ell(X - 6, 9.5, 2, 3.4, P);
    b.ell(X + 6, 9.5, 2, 3.4, P);
  } else if (w.peinado == 'trenzas') {
    b.ell(X, 5.6, 6.4, 3, P);
    b.cap(X - 7, 9, X - 8, 19, 1.6, P);
    b.cap(X + 7, 9, X + 8, 19, 1.6, P);
    b.rect(X - 10, 19, 4, 3, w.lazo ?? hx('#FFE070'));
    b.rect(X + 6, 19, 4, 3, w.lazo ?? hx('#FFE070'));
    b.px(X, 3, P[2]);
  } else {
    b.ell(X, 5.4, 6.4, w.peinado == 'largo' ? 3.2 : 2.8, P);
    if (w.peinado == 'corto') {
      b.rect(X - 6, 6, 1, 4, P[1]);
      b.rect(X + 5, 6, 1, 4, P[0]);
    }
  }
  // the features of the face; w.giro: his head turned a little (the face slides to one side)
  final XF = X + giro;
  if (sleep) {
    b.rect(XF - 4, 11, 3, 1, eye);
    b.rect(XF + 1, 11, 3, 1, eye);
  } else {
    b.px(XF - 3, 11, eye);
    b.px(XF + 2, 11, eye);
  }
  b.px(XF - 4, 13, hx('#E08A70'));
  b.px(XF + 3, 13, hx('#E08A70'));
  if (w.gafas == 1) {
    b.frame(XF - 5, 9, 4, 4, dark);
    b.frame(XF, 9, 4, 4, dark);
    b.px(XF - 1, 10, dark);
    if (!sleep) {
      b.px(XF - 3, 11, eye);
      b.px(XF + 2, 11, eye);
    }
  } else if (w.gafas == 'arriba') {
    b.frame(X - 5, 3, 4, 3, dark);
    b.frame(X, 3, 4, 3, dark);
    b.px(X - 1, 4, dark);
    b.rect(X - 4, 11, 3, 1, eye);
    b.rect(X + 1, 11, 3, 1, eye);
  }
  if (w.bigote) {
    b.rect(XF - 4, 14, 8, 2, P[2]);
    b.rect(XF - 4, 15, 2, 1, P[1]);
    b.rect(XF + 2, 15, 2, 1, P[1]);
    if (open) b.rect(XF - 1, 16, 3, 1, hx('#7A1C1C'));
  } else if (open) {
    b.rect(X - 1, 15, 3, 2, hx('#7A1C1C'));
  } else {
    b.rect(X - 2, 15, 4, 1, hx('#7A2A1A'));
    b.px(X - 3, 14, hx('#7A2A1A'));
    b.px(X + 2, 14, hx('#7A2A1A'));
  }
  if (cara == 'feliz' || cara == 'asco') caraAbuelo(b, XF, cara!);
  return b.outline().done();
}

// comer.js: caraAbuelo. The two faces of abuelo with the cake (drawn over his plain face; the glasses stay on): feliz:
// eyes shut with joy (an arch in each lens), flushed cheeks, a wide open laughing mouth with teeth and a tongue; asco:
// brows slanting down, eyes squeezed, a mouth turned down and his tongue out. x: the middle of his face
void caraAbuelo(Buf b, num x, String cara) {
  final K = hx('#20140A'), cr = hx('#EEDCB0');
  // the lenses are clear, the eyes are drawn on them
  for (final lx in [x - 4, x + 1]) {
    b.rect(lx, 10, 2, 2, cr);
  }
  if (cara == 'feliz') {
    for (final lx in [x - 4, x + 1]) {
      b.px(lx, 10, K);
      b.px(lx + 1, 10, K);
    }
    for (final px in [x - 4, x - 3, x + 2, x + 3]) {
      b.px(px, 13, hx('#EE7E6A'));
    }
    b.rect(x - 4, 16, 8, 1, hx('#7A1C1C'));
    b.rect(x - 3, 17, 6, 1, hx('#FFFFFF'));
    b.px(x - 4, 17, hx('#7A1C1C'));
    b.px(x + 3, 17, hx('#7A1C1C'));
    b.rect(x - 4, 18, 8, 1, hx('#8A1C1C'));
    b.rect(x - 2, 18, 4, 1, hx('#EE6A78'));
    b.rect(x - 3, 19, 6, 1, hx('#8A1C1C'));
    b.rect(x - 1, 19, 2, 1, hx('#EE6A78'));
  } else {
    for (final q in [
      [x - 5, 6],
      [x - 4, 6],
      [x - 3, 7],
      [x - 2, 7],
      [x + 4, 6],
      [x + 3, 6],
      [x + 2, 7],
      [x + 1, 7],
    ]) {
      b.rect(q[0], q[1], 1, 1, K);
    }
    b.px(x - 4, 10, K);
    b.px(x - 3, 11, K);
    b.px(x + 2, 10, K);
    b.px(x + 1, 11, K);
    b.rect(x - 3, 16, 6, 1, hx('#5A1A10'));
    b.px(x - 4, 17, hx('#5A1A10'));
    b.px(x + 3, 17, hx('#5A1A10'));
    b.rect(x - 1, 17, 3, 3, hx('#F07890'));
    b.rect(x, 17, 1, 3, hx('#C8506A'));
  }
}

// comer.js: mkAbuelaN. abuela standing, no arms (48 x 51, her middle at 24)
Sprite mkAbuelaN(bool open, int pie) {
  final b = Buf(48, 51), S = RP.skin, P = RP.purp;
  const X = 24, lf = 2;
  final L1 = pie == 1 ? lf : 0, L2 = pie == 2 ? lf : 0;
  b.ell(X - 4, 47.5 - L1, 3.4, 1.9, [hx('#3A2414')]);
  b.ell(X + 4, 47.5 - L2, 3.4, 1.9, [hx('#3A2414')]);
  b.rect(X - 5, 41, 3, 6 - L1, S[2]);
  b.rect(X + 2, 41, 3, 6 - L2, S[1]);
  b.ell(X, 31, 9, 12.5, P);
  b.ell(X, 38, 10.5, 5, P);
  for (var i = 0; i < 9; i++) {
    b.px(X - 8 + hs(i, 3) % 17, 34 + hs(i, 5) % 8, P[4]);
  }
  b.ell(X, 33, 5.4, 8.5, RP.cream);
  b.rect(X - 5, 24, 10, 1, RP.cream[1]);
  b.rect(X - 2, 17, 4, 4, S[1]);
  b.ell(X, 10, 8, 8.6, RP.grey);
  b.ell(X, 2.9, 3.6, 2.6, RP.grey);
  b.ell(X, 12.4, 5.8, 6.4, S);
  b.ell(X, 5.8, 6.2, 2.6, RP.grey);
  b.px(X - 3, 12, hx('#20140A'));
  b.px(X + 2, 12, hx('#20140A'));
  b.px(X - 4, 14, hx('#E08A70'));
  b.px(X + 3, 14, hx('#E08A70'));
  if (open) {
    b.rect(X - 1, 15, 3, 2, hx('#7A1C1C'));
  } else {
    b.rect(X - 2, 15, 4, 1, hx('#7A2A1A'));
    b.px(X - 3, 14, hx('#7A2A1A'));
    b.px(X + 2, 14, hx('#7A2A1A'));
  }
  b.px(X - 6, 14, hx('#F8C838'));
  b.px(X + 6, 14, hx('#F8C838'));
  return b.outline().done();
}

// comer.js: mkAbuelaSN. abuela sitting, no arms (52 x 50, her middle at 17, her knees to the right)
Sprite mkAbuelaSN(bool open) {
  final b = Buf(52, 50), S = RP.skin, P = RP.purp;
  const X = 17;
  b.ell(X + 9, 36.5, 12, 5.2, P);
  b.rect(X + 15, 40, 3, 6, S[2]);
  b.rect(X + 19, 40, 3, 6, S[1]);
  b.ell(X + 17, 47, 3.2, 1.7, [hx('#3A2414')]);
  b.ell(X + 22, 47, 3.2, 1.7, [hx('#3A2414')]);
  b.ell(X, 28, 8.6, 9.6, P);
  for (var i = 0; i < 7; i++) {
    b.px(X - 7 + hs(i, 3) % 15, 29 + hs(i, 5) % 8, P[4]);
  }
  b.ell(X + 1, 30, 5, 6.6, RP.cream);
  b.rect(X - 4, 23, 10, 1, RP.cream[1]);
  b.rect(X - 2, 17, 4, 4, S[1]);
  b.ell(X, 10, 8, 8.6, RP.grey);
  b.ell(X, 2.9, 3.6, 2.6, RP.grey);
  b.ell(X, 12.4, 5.8, 6.4, S);
  b.ell(X, 5.8, 6.2, 2.6, RP.grey);
  b.px(X - 3, 12, hx('#20140A'));
  b.px(X + 2, 12, hx('#20140A'));
  b.px(X - 4, 14, hx('#E08A70'));
  b.px(X + 3, 14, hx('#E08A70'));
  if (open) {
    b.rect(X - 1, 15, 3, 2, hx('#7A1C1C'));
  } else {
    b.rect(X - 2, 15, 4, 1, hx('#7A2A1A'));
    b.px(X - 3, 14, hx('#7A2A1A'));
    b.px(X + 2, 14, hx('#7A2A1A'));
  }
  b.px(X - 6, 14, hx('#F8C838'));
  b.px(X + 6, 14, hx('#F8C838'));
  return b.outline().done();
}

// comer.js: mkTaburete. A stool: a round wooden seat on three legs, 22 x 16
Sprite mkTaburete() {
  final b = Buf(22, 16), W = RP.wood;
  b.rect(3, 5, 2, 10, W[0]);
  b.rect(17, 5, 2, 10, W[0]);
  b.rect(10, 6, 2, 9, W[1]);
  b.rect(4, 11, 14, 1, W[1]);
  b.ell(11, 4.4, 10, 3.4, [W[1], W[2], W[3], W[4]]);
  return b.outline().done();
}

// comer.js: mkRanaEsp. The frog lying on his back, his round belly up
Sprite mkRanaEsp(bool open) {
  final b = Buf(40, 32), T = RP.tan;
  // hands and feet in the air
  b.ell(7, 15, 4, 6, T);
  b.ell(33, 15, 4, 6, T);
  b.ell(9, 28, 5, 3.4, T);
  b.ell(31, 28, 5, 3.4, T);
  b.rect(4, 6, 3, 6, T[2]);
  b.rect(33, 6, 3, 6, T[2]);
  b.rect(6, 24, 3, 5, T[2]);
  b.rect(31, 24, 3, 5, T[2]);
  // the round belly, up
  b.ell(20, 19, 14.4, 11, T);
  b.ell(20, 19.4, 11.8, 8.6, _hs(['#EEDCB0', '#FBF0D2', '#FFFBEA']));
  b.px(20, 20, hx('#B89A6A'));
  b.px(21, 20, hx('#B89A6A'));
  b.ell(20, 6, 8, 5, T);
  for (final dx in const [-5, 5]) {
    b.ell(20 + dx, 3.4, 3.4, 3.4, [hx('#FFFFFF')]);
    b.ell(20 + dx + .6, 2.8, 1.6, 1.8, [hx('#20140A')]);
  }
  if (open) {
    b.ell(20, 9, 2.8, 1.8, [hx('#7A1C1C')]);
  } else {
    b.line(17, 9, 23, 9, OUT);
  }
  return b.outline().done();
}

// comer.js:21 QUIEN. abuela is drawn by her own sprites (null: `{}`)
final Map<String, Who?> QUIEN = {
  'luis': FAM['hermano']!,
  'carmen': FAM['hermana']!,
  'abuelo': ABUELO_VERDE,
  'mama': FAM['mama']!,
  'papa': FAM['papa']!,
  'abuela': null,
};
