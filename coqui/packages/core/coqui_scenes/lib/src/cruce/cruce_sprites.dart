// What only El cruce has, drawn in the old sprites' way (engine.js Buf, its ramps and its dark outline), from the Needs
// list of historia/notas/guiones/cruce.md. The bicycle seen end-on, the piragüero's cart, abuela's bag, the bottle and
// the camera are cruce-preview.html's stand-ins (THING), ported as they are drawn there; the bottle's water by the parts
// left, the block of ice in three sizes, the drops and the puddles, the letter, the small paper bag, the kite, the loaf,
// a photo sheet, the skipping rope and the card's road are this file's guesses where the script gives no look. The
// content lane looks at each one on docs/proyecto/pixel/port/cruce-sprites.png (tool/make_cruce_sprites_test.dart).
// ignore_for_file: non_constant_identifier_names

import 'dart:typed_data';

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/src/banco/banco_sprites.dart' as banco;
import 'package:coqui_scenes/src/colmado/colmado_cast.dart';
import 'package:coqui_scenes/src/mostrador/mostrador_sprites.dart'
    show mkCliente;

int _h(String s) => hexColour(s);
List<int> _hs(List<String> s) => [for (final x in s) hexColour(x)];

/// The bicycle seen end-on (cruce-preview.html `THING.bici`), 20 x 28: a thin wheel, the fork and the handlebar at the
/// height of a hand; [cesta]: the basket, with the block of ice in it at size [hielo] (3 big, 2, 1 small, 0 none: the
/// preview draws the big one; the smaller two are this file's).
Sprite mkBiciFrente({bool cesta = false, int hielo = 3}) {
  final b = Buf(20, 28);
  b.ell(10, 21, 2.2, 7, _hs(['#1E1E26', '#32323E', '#4A4A58']));
  b.rect(10, 19, 1, 4, _h('#B8B8C8'));
  b.line(10, 14, 10, 6, _h('#7C7C90'));
  b.rect(2, 5, 16, 1, _h('#4A4A5C'));
  b.rect(1, 4, 2, 3, _h('#2A2A32'));
  b.rect(17, 4, 2, 3, _h('#2A2A32'));
  if (cesta) {
    b.rect(5, 7, 10, 6, _h('#C8853C'));
    b.rect(5, 7, 10, 1, _h('#E2A85A'));
    for (var x = 5; x < 15; x += 2) {
      b.px(x + 1, 10, _h('#A8682C'));
    }
    if (hielo >= 3) {
      b.rect(6, 2, 8, 5, _h('#BCE4F4'));
      b.rect(6, 2, 8, 1, _h('#F0FAFF'));
      b.rect(12, 3, 2, 4, _h('#8CC4DE'));
    } else if (hielo == 2) {
      b.rect(7, 4, 6, 3, _h('#BCE4F4'));
      b.rect(7, 4, 6, 1, _h('#F0FAFF'));
      b.rect(11, 5, 2, 2, _h('#8CC4DE'));
    } else if (hielo == 1) {
      b.rect(8, 5, 4, 2, _h('#BCE4F4'));
      b.rect(8, 5, 4, 1, _h('#F0FAFF'));
    }
  }
  return b.outline().done();
}

/// The piragüero's cart (cruce-preview.html `THING.carrito`), 40 x 28: a box on two wheels, the block of ice on it (when
/// [hielo], this file's: the preview always draws it), two bottles of syrup and a red parasol.
Sprite mkCarrito({bool hielo = true}) {
  final b = Buf(40, 28);
  b.rect(3, 15, 34, 8, _h('#B88040'));
  b.rect(3, 15, 34, 1, _h('#D8A460'));
  b.rect(3, 22, 34, 1, _h('#6E4220'));
  b.rect(5, 17, 30, 1, _h('#92602E'));
  if (hielo) {
    b.rect(8, 10, 12, 5, _h('#BCE4F4'));
    b.rect(8, 10, 12, 1, _h('#F0FAFF'));
    b.rect(17, 11, 3, 4, _h('#8CC4DE'));
  }
  b.rect(24, 11, 3, 4, _h('#E02A2A'));
  b.rect(29, 11, 3, 4, _h('#F8C838'));
  b.line(20, 10, 20, 3, _h('#6E4220'));
  b.ell(20, 4, 15, 3, _hs(['#9A1C1C', '#D0403A', '#FA9080']));
  for (var x = 8; x < 33; x += 5) {
    b.rect(x, 3, 2, 3, _h('#FFFBEA'));
  }
  b.ell(9, 24, 3.4, 3.4, _hs(['#2A2A32', '#4A4A58']));
  b.ell(31, 24, 3.4, 3.4, _hs(['#2A2A32', '#4A4A58']));
  return b.outline().done();
}

/// Abuela's bag (cruce-preview.html `THING.bolsa`), 13 x 14.
Sprite mkBolsa() {
  final b = Buf(13, 14);
  b.rect(1, 4, 11, 9, _h('#C89A60'));
  b.rect(1, 4, 4, 9, _h('#E0B880'));
  b.rect(1, 3, 11, 1, _h('#A87A40'));
  b.rect(4, 1, 5, 2, _h('#E2A85A'));
  b.rect(4, 7, 5, 1, _h('#A87A40'));
  return b.outline().done();
}

/// Abuela's bottle with three marks (cruce-preview.html `THING.botella`, full), 7 x 17; [n] the parts of water left (3
/// to the top mark, 0 empty: the lower levels are this file's); [tumbada]: tipping, turned on its side (17 x 7).
Sprite mkBotellaAgua(int n, {bool tumbada = false}) {
  final b = Buf(7, 17);
  b.rect(2, 0, 3, 3, _h('#EEDCB0'));
  b.rect(1, 3, 5, 13, _h('#BCE4F4'));
  b.rect(1, 3, 1, 13, _h('#F0FAFF'));
  // the water: from the top mark (row 6) down to the bottom, a mark lower each part lost
  final top = n >= 3 ? 6 : (n == 2 ? 9 : (n == 1 ? 12 : 15));
  if (n > 0) b.rect(1, top, 5, 15 - top, _h('#5AA8E0'));
  for (final y in const [7, 10, 13]) {
    b.rect(4, y, 2, 1, _h('#2A4A78'));
  }
  final s = b.outline().done();
  if (!tumbada) return s;
  // turned a quarter round, its neck to the right
  final out = Sprite(s.h, s.w, Uint32List(s.w * s.h));
  for (var y = 0; y < s.h; y++) {
    for (var x = 0; x < s.w; x++) {
      out.px[(s.w - 1 - x) * s.h + (s.h - 1 - y)] = s.px[y * s.w + x];
    }
  }
  return out;
}

/// Water on the pavement, flat (a puddle seen from above, squashed by the camera), [w] wide: [w] x 5.
Sprite mkCharco([int w = 14]) {
  final b = Buf(w, 5);
  b.ell(w / 2, 2.5, w / 2 - .5, 2, _hs(['#3E86C4', '#5AA8E0', '#8CC8F0']));
  b.rect(w / 2 - 2, 1, 2, 1, _h('#C8E8FA'));
  return b.done();
}

/// A drop of water, 3 x 4.
Sprite mkGota() {
  final b = Buf(3, 4);
  b.rect(1, 0, 1, 1, _h('#8CC8F0'));
  b.rect(0, 1, 3, 3, _h('#5AA8E0'));
  b.px(0, 1, _h('#C8E8FA'));
  return b.done();
}

/// The letter in abuela's hand, 9 x 7.
Sprite mkCarta() {
  final b = _Off(Buf(11, 9));
  b.rect(0, 0, 9, 7, _h('#FAF6EA'));
  b.line(0, 0, 4, 3, _h('#C8C0AC'));
  b.line(8, 0, 4, 3, _h('#C8C0AC'));
  b.rect(6, 1, 2, 2, _h('#E03C30'));
  return b.b.outline().done();
}

/// The small paper bag from the farmacia, 8 x 10, a green cross on it.
Sprite mkBolsita() {
  final b = _Off(Buf(10, 12));
  b.rect(0, 1, 8, 9, _h('#F4F0E4'));
  b.rect(0, 0, 8, 1, _h('#D8D0BC'));
  b.rect(3, 3, 2, 5, _h('#2EA44E'));
  b.rect(2, 4, 4, 3, _h('#2EA44E'));
  return b.b.outline().done();
}

/// A kite (from the tienda), 11 x 16: a diamond and its tail.
Sprite mkCometa() {
  final b = Buf(11, 16);
  for (var y = 0; y < 10; y++) {
    final hw = y < 5 ? y : 9 - y;
    b.rect(5 - hw, y, 2 * hw + 1, 1, y < 5 ? _h('#E03C30') : _h('#F0C020'));
  }
  b.line(5, 0, 5, 9, _h('#8A5A2A'));
  b.line(5, 10, 6, 15, _h('#8A5A2A'));
  b.rect(5, 12, 2, 1, _h('#3C8AE0'));
  return b.outline().done();
}

/// A loaf (from the colmado), 14 x 7.
Sprite mkPan() {
  final b = Buf(14, 7);
  b.ell(7, 3.5, 6.5, 3, _hs(['#A8682C', '#C8853C', '#E2A85A']));
  for (final x in const [4, 7, 10]) {
    b.line(x, 1, x - 1, 3, _h('#F4D49A'));
  }
  return b.outline().done();
}

/// The camera (cruce-preview.html `THING.camara`), 10 x 7.
Sprite mkCamara() {
  final b = Buf(10, 7);
  b.rect(0, 1, 10, 6, _h('#3A3A46'));
  b.rect(0, 1, 10, 1, _h('#6E6E80'));
  b.ell(5, 4.5, 2.4, 2.4, _hs(['#9CCBF5', '#DCEEFF']));
  b.rect(7, 0, 2, 1, _h('#FFE070'));
  return b.outline().done();
}

/// A photo sheet, small (on the card, on the seat), 8 x 9: white, a picture in it when [hecha] ([mala]: spoiled, a big
/// green shape over it).
Sprite mkHoja({bool hecha = false, bool mala = false}) {
  final b = _Off(Buf(10, 11));
  b.rect(0, 0, 8, 9, _h('#FCFCF8'));
  if (hecha) {
    b.rect(1, 1, 6, 5, _h('#8AB0D8'));
    b.rect(1, 4, 6, 2, _h('#B88A5A'));
    if (mala) {
      b.ell(4, 3.5, 3, 3, _hs(['#2E8A3E', '#46B050']));
    } else {
      for (final x in const [2, 4, 6]) {
        b.rect(x, 2, 1, 3, _h('#6A3A2A'));
      }
    }
  }
  return b.b.outline().done();
}

/// A piragua in a paper cone (El banco's), and one with two spoons.
Sprite mkPiraguaCruce({bool dos = false}) {
  final p = banco.COSA['piragua']!();
  if (!dos) return p;
  final b = Buf(p.w + 4, p.h + 4);
  b.line(1, 0, 4, 6, _h('#D8D8E0'));
  b.line(p.w + 2, 0, p.w - 1, 6, _h('#D8D8E0'));
  return overSprite(b.done(), [(p, 2, 4)]);
}

/// The piragüero (El parque's: El banco's señor with his apron), standing; [pose] mkPersona's.
Sprite mkPiraguero(String pose, {bool open = false}) =>
    mkCliente('piraguero', pose, open: open);

/// Abuelo, standing (kit.js FAM.abuelo).
Sprite mkAbuelo(String pose, {bool open = false}) =>
    mkPersona(FAM['abuelo']!, pose, open, false);

/// A skipping rope held at both ends round a child: the arc over her head, [w] wide, [h] high.
Sprite mkCuerda(int w, int h) {
  final b = Buf(w, h);
  for (var x = 0; x < w; x++) {
    final t = (x - (w - 1) / 2) / ((w - 1) / 2);
    final y = ((h - 2) * t * t).round();
    b.px(x, y, _h('#E03C30'));
  }
  return b.done();
}

// a Buf drawn one pixel in from its edges, so that the outline has room round a thing that fills its box
class _Off {
  _Off(this.b);

  final Buf b;

  void rect(num x, num y, num w, num h, int c) => b.rect(x + 1, y + 1, w, h, c);
  void px(num x, num y, int c) => b.px(x + 1, y + 1, c);
  void line(num x0, num y0, num x1, num y1, int c) =>
      b.line(x0 + 1, y0 + 1, x1 + 1, y1 + 1, c);
  void ell(num cx, num cy, num rx, num ry, List<int> r) =>
      b.ell(cx + 1, cy + 1, rx, ry, r);
}
