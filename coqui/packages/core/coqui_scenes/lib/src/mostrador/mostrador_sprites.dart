// What only El mostrador has in its sprite layer (the place's shared cast is lib/src/colmado/colmado_cast.dart): the
// tray of quesitos, a quesito, the coin dish, the malts, the pile of paper bags, the límbers (in their cups, licked,
// melted), the señora's basket, abuela's bag and her list, the rooster on the awning, the tick of the list card. Drawn
// in the old sprites' way (engine.js Buf: ramps, a dark outline), the size and colours of mostrador-preview.html's
// stand-ins where it has one. The content lane looks at each on docs/proyecto/pixel/port/mostrador-sprites.png
// (tool/make_colmado_sprites_test.dart). The señora, the señor and the piragua cart are El banco's (banco.dart QUIEN,
// banco_sprites.dart mkCarro and COSA.piragua).
// ignore_for_file: non_constant_identifier_names

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/src/banco/banco.dart' show Banco;
import 'package:coqui_scenes/src/banco/banco_sprites.dart' as banco;
import 'package:coqui_scenes/src/colmado/colmado_cast.dart';

int _h(String s) => hexColour(s);
List<int> _hs(List<String> s) => [for (final x in s) hexColour(x)];

/// A warm quesito: a golden pastry, puffed, with a sugar glaze (mostrador.md 36: "a tray of three warm quesitos").
Sprite mkQuesito([bool medio = false]) {
  final b = Buf(7, 6);
  if (medio) {
    b.ell(2.6, 3.2, 2.4, 2.2, _hs(['#E8A838', '#F6D070', '#FFF0A8']));
    b.rect(4, 1, 1, 4, _h('#FFF6D8')); // the cut side: the white cream inside
  } else {
    b.ell(3.5, 3.2, 3, 2.4, _hs(['#E8A838', '#F6D070', '#FFF0A8']));
    b.px(3, 2, _h('#D08A20'));
  }
  return b.outline().done();
}

/// The tray of quesitos with [n] of them on it (0 to 3; mostrador-preview.html's `bandeja`).
Sprite mkBandeja(int n) {
  final b = Buf(16, 10);
  b.rect(1, 6, 14, 2, _h('#9494A6'));
  b.rect(1, 6, 14, 1, _h('#D8D8E4'));
  const xs = [3.6, 8.0, 12.4];
  for (var i = 0; i < n && i < 3; i++) {
    b.ell(xs[i], 4.2, 2.6, 2.4, _hs(['#E8A838', '#F6D070', '#FFF0A8']));
    b.px(xs[i].round() - 1, 3 + (i == 1 ? 0 : 1), _h('#D08A20'));
  }
  return b.outline().done();
}

/// The coin dish with [n] coins in it (mostrador-preview.html's `platillo`).
Sprite mkPlatillo(int n) {
  final b = Buf(12, 7);
  b.ell(6, 4.6, 5, 1.9, _hs(['#9AA8C0', '#E4EAF4']));
  const at = [
    [3, 2],
    [6, 1],
    [5, 3],
    [8, 2],
    [2, 3],
  ];
  for (var i = 0; i < n && i < at.length; i++) {
    b.rect(
      at[i][0],
      at[i][1],
      3,
      2,
      i % 2 == 0 ? _h('#F0C020') : _h('#E0A818'),
    );
    b.px(at[i][0] + 1, at[i][1], _h('#FFE070'));
  }
  return b.outline().done();
}

/// A malt: a dark brown bottle with a cream label and a gold cap ([abierta]: the cap off, a wisp of foam).
Sprite mkMalta([bool abierta = false]) {
  final b = Buf(6, 14);
  b.rect(2, 1, 2, 4, _h('#5A3418'));
  if (abierta) {
    b.px(2, 0, _h('#F4ECD8'));
    b.px(3, 1, _h('#F4ECD8'));
  } else {
    b.px(2, 1, _h('#F0C020'));
    b.px(3, 1, _h('#F0C020'));
  }
  b.rect(1, 5, 4, 8, _h('#5A3418'));
  b.rect(1, 7, 4, 3, _h('#F2E4B0'));
  b.px(1, 6, _h('#9A6A3A'));
  return b.outline().done();
}

/// The low crate the malts stand in, with a coin painted on its front (mostrador.md 37: "a coin is drawn on their
/// crate": each one costs a coin).
Sprite mkCajaMaltas() {
  final b = Buf(18, 6);
  b.rect(1, 1, 16, 4, _h('#C89A60'));
  b.rect(1, 1, 16, 1, _h('#E0B880'));
  b.ell(9, 3, 1.8, 1.6, _hs(['#B87A10', '#F0C020']));
  return b.outline().done();
}

/// The pile of paper bags under the counter's edge, a coin painted on the top one (mostrador.md 37).
Sprite mkPilaBolsas() {
  final b = Buf(14, 7);
  for (var i = 0; i < 3; i++) {
    b.rect(1, 1 + i * 2, 12, 2, i % 2 == 0 ? _h('#C89A60') : _h('#E0B880'));
  }
  b.ell(7, 2, 1.8, 1.4, _hs(['#B87A10', '#F0C020']));
  return b.outline().done();
}

/// A límber in its paper cup: the frozen top domed over the rim. [col] `white` (coconut) or `orange` (mango).
/// [estado]: `vaso` whole, `lamido` with a bite out of the top, `charco` melted into a puddle on the counter.
Sprite mkLimber(String col, [String estado = 'vaso']) {
  final top = col == 'white'
      ? _hs(['#C8C8D4', '#E8E8F0', '#FFFFFF'])
      : _hs(['#C8601A', '#F08A2A', '#FFB870']);
  if (estado == 'charco') {
    final b = Buf(14, 6);
    b.ell(7, 3.4, 6, 1.9, top);
    b.rect(
      5,
      1,
      4,
      2,
      _h('#BCD6EE'),
    ); // the empty cup, on its side in the puddle
    return b.outline().done();
  }
  final b = Buf(9, 12);
  b.ell(4.5, 4, 2.9, 2.4, top);
  if (estado == 'lamido') {
    b.px(5, 2, 0);
    b.px(6, 2, 0);
    b.px(6, 3, 0);
  }
  b.rect(2, 5, 5, 6, _h('#BCD6EE'));
  b.rect(2, 6, 5, 3, top[1]);
  b.rect(6, 5, 1, 6, _h('#8CB0D0'));
  return b.outline().done();
}

/// The small tray the two límbers of story 38's opening stand on.
Sprite mkBandejita() {
  final b = Buf(26, 4);
  b.rect(1, 1, 24, 2, _h('#9494A6'));
  b.rect(1, 1, 24, 1, _h('#D8D8E4'));
  return b.outline().done();
}

/// A límber's top seen through the freezer's glass lid (one of the five).
Sprite mkLimberTapa(String col) {
  final b = Buf(5, 4);
  b.ell(
    2.5,
    2,
    2,
    1.5,
    col == 'white' ? _hs(['#E8E8F0', '#FFFFFF']) : _hs(['#F08A2A', '#FFB870']),
  );
  return b.done();
}

/// The señora's basket, shut (its lid down) or open (mostrador-preview.html's `cesta`).
Sprite mkCesta([bool abierta = false]) {
  final b = Buf(14, 11);
  b.rect(1, 4, 12, 6, _h('#C8853C'));
  for (var y = 4; y < 10; y += 2) {
    for (var x = 1; x < 13; x += 2) {
      b.px(x + (y >> 1) % 2, y, _h('#A8682C'));
    }
  }
  b.rect(1, 4, 12, 1, _h('#E2A85A'));
  b.rect(2, 1, 1, 3, _h('#A8682C'));
  b.rect(11, 1, 1, 3, _h('#A8682C'));
  b.rect(2, 1, 10, 1, _h('#A8682C'));
  if (!abierta) b.rect(1, 3, 12, 2, _h('#B87A34')); // the lid
  return b.outline().done();
}

/// Abuela's shopping bag (a straw bag on her arm) and her list (a paper with three pictures).
Sprite mkBolsaAbuela() {
  final b = Buf(12, 13);
  b.cap(3, 5, 6, 1, 1, [_h('#8A5A2A')]);
  b.cap(9, 5, 6, 1, 1, [_h('#8A5A2A')]);
  b.rect(1, 5, 10, 7, _h('#E2B860'));
  for (var y = 6; y < 12; y += 2) {
    b.rect(1, y, 10, 1, _h('#C89A40'));
  }
  return b.outline().done();
}

/// The list in a hand: a small white paper with three coloured marks.
Sprite mkListaMano() {
  final b = Buf(7, 9);
  b.rect(1, 1, 5, 7, _h('#FFFDF4'));
  b.rect(2, 2, 3, 1, _h('#4678D2'));
  b.rect(2, 4, 3, 1, _h('#C48440'));
  b.rect(2, 6, 3, 1, _h('#FAD860'));
  return b.outline().done();
}

/// The rooster on the awning (mostrador-preview.html's `gallo`): [canta] its head up, its beak open.
Sprite mkGallo([bool canta = false]) {
  final b = Buf(16, 17);
  b.line(5, 8, 1, 3, _h('#1E6A58'));
  b.line(5, 9, 0, 6, _h('#2E8A6A'));
  b.line(5, 10, 1, 9, _h('#1E6A58'));
  b.line(6, 8, 3, 2, _h('#3AA078'));
  b.ell(7.5, 10, 4.6, 3.6, _hs(['#7A2E16', '#B8541E', '#DC8234', '#F2B05C']));
  final dy = canta ? -1 : 0;
  b.ell(11.5, 5.5 + dy, 2.6, 2.7, _hs(['#B8541E', '#DC8234', '#F2B05C']));
  b.rect(10, 1 + dy, 3, 2, _h('#E02A2A'));
  b.px(11, 0, _h('#E02A2A'));
  if (canta) {
    b.rect(14, 3, 2, 1, _h('#F0C020'));
    b.rect(14, 5, 2, 1, _h('#F0C020'));
  } else {
    b.rect(14, 5, 2, 1, _h('#F0C020'));
  }
  b.rect(13, 7 + dy, 1, 2, _h('#E02A2A'));
  b.px(12, 5 + dy, _h('#201818'));
  b.rect(6, 13, 1, 3, _h('#D8A030'));
  b.rect(9, 13, 1, 3, _h('#D8A030'));
  b.rect(5, 16, 3, 1, _h('#D8A030'));
  b.rect(8, 16, 3, 1, _h('#D8A030'));
  return b.outline().done();
}

/// The tick a thing of the list card gets when it is bought.
Sprite mkVisto() {
  final b = Buf(7, 6);
  b.line(1, 3, 2, 4, _h('#3E9A52'));
  b.line(2, 4, 5, 1, _h('#3E9A52'));
  b.line(1, 2, 2, 3, _h('#3E9A52'));
  b.line(2, 3, 5, 0, _h('#3E9A52'));
  return b.done();
}

/// The piragua cup (El banco's COSA.piragua).
Sprite mkPiragua() => banco.COSA['piragua']!();

/// The piragua cart (El banco's mkCarro).
Sprite mkCarritoPiragua() => banco.mkCarro(false);

/// El banco's [id] (`senora`, `senor`, `piraguero`): its figure's look (banco.dart QUIEN).
Who bancoWho(String id) => Banco.QUIEN[id]!.who!;

/// El banco's señora or señor in [pose] (mkPersona's), with what El banco draws over the figure to make each one his own
/// (banco.dart `extra`: the señor's hat and cane, the señora's ponytail), facing right: the sprite grows 2 rows above for
/// the hat. [lleva]: what is drawn in the held-out hand (`cesta`, `cesta_abierta`, `bolsa`), or null.
Sprite mkCliente(String id, String pose, {bool open = false, String? lleva}) {
  final w = Banco.QUIEN[id]!,
      base = mkPersona(w.who!, lleva != null ? 'taza' : pose, open, false);
  final px = canvasSprite(base.w, base.h + 2, (c) {
    c.drawImage(base, 0, 2);
    const h = PX, hy = 2 + 11, d = 1;
    for (final k in w.extra) {
      if (k == 'sombrero') {
        fr(c, h - 6, hy - 13, 12, 7, OUT);
        fr(c, h - 5, hy - 12, 10, 5, _h('#6A4A2A'));
        fr(c, h - 5, hy - 8, 10, 1, _h('#2A1A0E'));
        fr(c, h - 9, hy - 7, 18, 3, OUT);
        fr(c, h - 8, hy - 6, 16, 1, _h('#6A4A2A'));
      } else if (k == 'cola') {
        fr(c, h - d * 8 - 3, hy - 5, 4, 11, OUT);
        fr(c, h - d * 8 - 2, hy - 4, 2, 9, _h('#44260E'));
        fr(c, h - d * 6 - 2, hy - 6, 3, 3, _h('#F0C020'));
      } else if (k == 'baston' && lleva == null) {
        const bx = h + d * 12;
        fr(c, bx - 1, hy + 12, 3, base.h - 24, OUT);
        fr(c, bx, hy + 13, 1, base.h - 26, _h('#8A5A2A'));
        fr(c, bx - 3, hy + 11, 6, 3, OUT);
        fr(c, bx - 2, hy + 12, 4, 1, _h('#8A5A2A'));
      }
    }
  });
  if (lleva == null) return px;
  // kit.js mkPersona 'taza': the right hand out at (X + rx + 4.5, 21 + 6); the thing hangs from it
  final t = lleva == 'bolsa'
      ? mkBolsaPapel()
      : mkCesta(lleva == 'cesta_abierta');
  return overSprite(px, [(t, PX + 8 + 4 - t.w ~/ 2, 2 + 21 + 6 - 1)]);
}

/// Every sprite this file draws, in order, for the sheet picture (mostrador-sprites.png).
List<(String, Sprite)> mostradorSpriteSheet() => [
  ('quesito', mkQuesito()),
  ('medio quesito', mkQuesito(true)),
  for (var n = 3; n >= 0; n--) ('bandeja, $n quesitos', mkBandeja(n)),
  for (final n in const [0, 1, 2, 3, 5])
    ('platillo, $n monedas', mkPlatillo(n)),
  ('malta', mkMalta()),
  ('malta abierta', mkMalta(true)),
  ('caja de las maltas', mkCajaMaltas()),
  ('pila de bolsas de papel', mkPilaBolsas()),
  for (final c in const ['white', 'orange']) ...[
    ('limber $c', mkLimber(c)),
    ('limber $c, lamido', mkLimber(c, 'lamido')),
    ('limber $c, derretido', mkLimber(c, 'charco')),
    ('limber $c, en la nevera', mkLimberTapa(c)),
  ],
  ('bandejita de los limbers', mkBandejita()),
  ('cesta cerrada', mkCesta()),
  ('cesta abierta', mkCesta(true)),
  ('bolsa de abuela', mkBolsaAbuela()),
  ('lista en la mano', mkListaMano()),
  ('gallo', mkGallo()),
  ('gallo, canta', mkGallo(true)),
  ('visto', mkVisto()),
  ('piragua (El banco)', mkPiragua()),
  ('carrito de piraguas (El banco)', mkCarritoPiragua()),
  ('la senora (El banco)', mkCliente('senora', 'idle')),
  (
    'la senora con la cesta cerrada',
    mkCliente('senora', 'idle', lleva: 'cesta'),
  ),
  (
    'la senora con la cesta abierta',
    mkCliente('senora', 'idle', lleva: 'cesta_abierta'),
  ),
  ('el senor (El banco)', mkCliente('senor', 'idle')),
  ('el senor con su bolsa', mkCliente('senor', 'idle', lleva: 'bolsa')),
  (
    'el piraguero (El banco)',
    mkPersona(bancoWho('piraguero'), 'idle', false, false),
  ),
  ('una moneda en la fila', mkMoneda()),
];
