// El colmado's cast: the sprites of the people and things more than one of the place's four scenes uses (mostrador,
// estantes, frutas, caja). First writer: order 50b (El mostrador); the other three builders copy it and add to it only
// by adding.
//
// Drawn in the old sprites' way: the same makers (kit.js mkPersona for a person, as the family and El banco's people
// are drawn; engine.js Buf with its ramps and its dark outline for an animal or a thing), the same palette (kit.js PIEL,
// PELO, engine.js RP), the same size (a grown-up 48 x 56, a child 48 x 44, as mkPersona makes them) and outline (OUT).
// The looks come from the scripts (historia/notas/guiones/mostrador.md: "don Pepe, the shopkeeper (a man with a
// moustache and an apron)"; frutas.md: the goat; the three children of mostrador.md 38 and caja.md 47 have no looks in
// the scripts: they are this file's). The previews' stand-ins gave size and place (mostrador-preview.html's PEPE, its
// goods, coins and bags); these follow them. The content lane looks at every one on
// docs/proyecto/pixel/port/colmado-sprites.png (tool/make_colmado_sprites_test.dart).
// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/src/balcon/balcon.dart' show abanico;

int _h(String s) => hexColour(s);
List<int> _hs(List<String> s) => [for (final x in s) hexColour(x)];

/// A sprite with the point that stands on its place: column [ax] on the spot's column, row [ay] on the spot's row (the
/// sheets' rules.anchor: the lowest drawn row rests on the row above, so the bottom edge is on the spot's row).
typedef Anchored = ({Sprite s, int ax, int ay});

/// The row under a sprite's lowest drawn pixel (its feet's bottom edge).
int inkBottom(Sprite s) {
  for (var y = s.h - 1; y >= 0; y--) {
    for (var x = 0; x < s.w; x++) {
      if (s.px[y * s.w + x] >>> 24 != 0) return y + 1;
    }
  }
  return s.h;
}

/// [s] with its middle column [ax] and its bottom edge (inkBottom) as its anchor.
Anchored anchored(Sprite s, [int? ax]) =>
    (s: s, ax: ax ?? s.w ~/ 2, ay: inkBottom(s));

/// A copy of [base] grown by [top] rows above, with each part drawn over it at (x, y) of the grown sprite (every pixel
/// with alpha drawn as it is).
Sprite overSprite(Sprite base, List<(Sprite, int, int)> parts, {int top = 0}) {
  final w = base.w, h = base.h + top, px = Uint32List(w * h);
  for (var y = 0; y < base.h; y++) {
    for (var x = 0; x < w; x++) {
      px[(y + top) * w + x] = base.px[y * w + x];
    }
  }
  for (final (p, ox, oy) in parts) {
    for (var y = 0; y < p.h; y++) {
      for (var x = 0; x < p.w; x++) {
        final c = p.px[y * p.w + x];
        if (c >>> 24 == 0) continue;
        final X = ox + x, Y = oy + y;
        if (X < 0 || Y < 0 || X >= w || Y >= h) continue;
        px[Y * w + X] = c;
      }
    }
  }
  return Sprite(w, h, px);
}

/// Draws [draw] on a new transparent picture of [w] x [h] through a canvas, and gives it as a sprite.
Sprite canvasSprite(int w, int h, void Function(Ctx g) draw) {
  final px = Uint32List(w * h);
  draw(Ctx(px, w, h));
  return Sprite(w, h, px);
}

/* ---------- don Pepe ---------- */

/// don Pepe: a man with a moustache and an apron (mostrador.md, "New people"). mostrador-preview.html's PEPE: short black
/// hair, a white shirt, grey trousers, a moustache, a green apron from the chest to the knees with a pocket.
final Who PEPE = Who(
  piel: PIEL['c']!,
  pelo: PELO['negro']!,
  peinado: 'corto',
  ropa: _hs(['#C8C8D0', '#E4E4EA', '#F6F6FA', '#FFFFFF']),
  abajo: RP.grey,
  bigote: true,
  detalle: (b, X, tc, rx, t) {
    // a green apron over his front, from the chest to the knees (drawn over the body, under the head and the arms)
    final G = RP.grn;
    b.rect(X - 4, 18, 1, 4, G[1]);
    b.rect(X + 3, 18, 1, 4, G[1]); // the straps
    b.rect(X - 5, 22, 10, 24, G[2]);
    b.rect(X - 5, 22, 2, 24, G[3]);
    b.rect(X + 3, 22, 2, 24, G[1]);
    b.rect(X - 5, 45, 10, 1, G[0]);
    b.rect(X - 5, 22, 10, 1, G[3]);
    b.rect(X - 3, 34, 6, 4, G[1]);
    b.rect(X - 3, 34, 6, 1, G[3]); // a pocket
  },
);

/// The poses of don Pepe this cast draws (the four of page 13 and the small moves the scripts' `gesto` names):
/// `idle` standing; `saluda0`, `saluda1` a hand lifted (two frames); `alcanza` reaching up to a shelf (an arm up);
/// `mano` a hand out over the counter; `sentado` sitting; `abanico0`, `abanico1` sitting with a paper fan (two frames);
/// `escalera` on the ladder, both hands out to its rails; `escalera_alto` on the ladder, reaching up.
const List<String> PEPE_POSES = [
  'idle',
  'saluda0',
  'saluda1',
  'alcanza',
  'mano',
  'sentado',
  'abanico0',
  'abanico1',
  'escalera',
  'escalera_alto',
];

/// don Pepe in [pose] (one of [PEPE_POSES]); [open]: talking. The sprite is mkPersona's (48 wide, its middle column
/// [PX]); a sitting pose is mkPersona's sitting figure, its anchor its feet as every person's (the sheets' rules.anchor).
Sprite mkPepe(String pose, {bool open = false}) {
  switch (pose) {
    case 'saluda0':
    case 'saluda1':
      return mkPersona(
        PEPE,
        pose == 'saluda0' ? 'wave0' : 'wave1',
        open,
        false,
      );
    case 'alcanza':
    case 'escalera_alto':
      return mkPersona(PEPE, 'wave0', open, false);
    case 'mano':
      return mkPersona(PEPE, 'offer', open, false);
    case 'sentado':
      return mkPersona(PEPE, 'idle', open, true);
    case 'abanico0':
    case 'abanico1':
      // the arm up, a paper fan at the hand (El balcón's fan, as abuela's), its leaves swung by the frame
      final f = pose == 'abanico1' ? 1 : 0,
          s = mkPersona(PEPE, f == 0 ? 'wave0' : 'wave1', open, true);
      final fan = canvasSprite(
        20,
        12,
        (g) => abanico(g, 10 + f, 10, 8, -60, 60),
      );
      return overSprite(s, [(fan, PX + 8 + 5 - 10, 0)]);
    case 'escalera':
      return mkPersona(PEPE, 'ojos', open, false);
    default:
      return mkPersona(PEPE, 'idle', open, false);
  }
}

/* ---------- the three children ---------- */

/// The three children of El colmado (mostrador.md 38: they wait at the door, each with a coin; caja.md 47: at the shop
/// window, then in). No script gives their looks; they are not the family's children (Luis and Carmen are in the same
/// pictures): a boy in yellow (mostrador-preview.html's third child), a girl with long hair in blue, a boy in red.
final List<Who> NINOS = [
  Who(
    nino: true,
    piel: PIEL['c']!,
    pelo: PELO['castano']!,
    peinado: 'corto',
    ropa: RP.yel,
    abajo: RP.grey,
    zapato: _h('#F2F2F8'),
  ),
  Who(
    nino: true,
    piel: PIEL['b']!,
    pelo: PELO['negro']!,
    peinado: 'largo',
    ropa: RP.blue,
    falda: true,
    zapato: _h('#F2F2F8'),
  ),
  Who(
    nino: true,
    piel: PIEL['a']!,
    pelo: PELO['negro']!,
    peinado: 'corto',
    ropa: RP.red,
    abajo: RP.blue,
    zapato: _h('#3A2414'),
  ),
];

/// Child [i] (0, 1, 2) in [pose]: `idle`, `saluda0`, `saluda1`, `moneda` (a coin in the held-out hand), `triste` (looks
/// down: the idle figure; the scene draws the face), `limber_a`, `limber_b` (a límber in the hand: white, orange).
Sprite mkNino(int i, String pose, {bool open = false}) {
  final w = NINOS[i];
  switch (pose) {
    case 'saluda0':
    case 'saluda1':
      return mkPersona(w, pose == 'saluda0' ? 'wave0' : 'wave1', open, false);
    case 'moneda':
      // kit.js mkPersona 'taza': the right hand out at (X + rx + 4.5, 21 + 6); the coin in it
      final s = mkPersona(w, 'taza', open, false);
      return overSprite(s, [(mkMoneda(), PX + 6 + 4 - 3, 21 + 6 - 4)]);
    case 'limber_a':
    case 'limber_b':
      final s = mkPersona(w, 'taza', open, false),
          l = mkLimberPalo(pose == 'limber_a' ? 'white' : 'orange');
      return overSprite(s, [(l, PX + 6 + 4 - 4, 21 + 6 - l.h + 2)]);
    default:
      return mkPersona(w, 'idle', open, false);
  }
}

/* ---------- the goat (frutas) ---------- */

/// The goat at its post (frutas.md: it stretches its neck to the bins, eats what lands on the low crate, chews). Drawn as
/// kit.js's dog is: ramps, ellipses, a dark outline; white with a grey-brown back, two short horns, a beard, a rope
/// collar. [pose]: `de_pie` standing, `cuello` its neck stretched out, `come` its head down at the crate, `mastica`
/// chewing (two frames by [f]). Faces right (the scene mirrors it). 36 x 28, its feet at the bottom edge.
Sprite mkCabra(String pose, int f) {
  final b = Buf(36, 28);
  final T = _hs(['#8A8478', '#B8B0A0', '#DCD6C8', '#F4F0E6']),
      D = _hs(['#5A4A3A', '#7A6650']),
      horn = _h('#C8B48A'),
      hoof = _h('#3A2A20'),
      eye = _h('#20140A');
  final X = 15, Y = 14;
  // tail, legs, body
  b.cap(X - 10, Y - 2, X - 12, Y - 6, 1.2, [T[2]]);
  for (final (dx, c) in [(-8, T[1]), (-5, T[0]), (5, T[1]), (8, T[0])]) {
    b.rect(X + dx, Y + 4, 2, 8, c);
    b.rect(X + dx, Y + 11, 2, 1, hoof);
  }
  b.ell(X, Y + 1, 11, 6, T);
  b.ell(X - 1, Y - 3, 8, 2, [D[1]]); // the darker back
  // neck and head: up (de_pie, mastica), forward (cuello), down at the crate (come)
  final hx = pose == 'cuello'
          ? X + 17
          : pose == 'come'
          ? X + 13
          : X + 11,
      hy = pose == 'cuello'
          ? Y - 2
          : pose == 'come'
          ? Y + 6
          : Y - 7;
  b.cap(X + 7, Y - 1, hx - 2, hy + 1, 3, T);
  b.ell(hx, hy, 4.4, 3.6, T);
  b.ell(hx + 3.5, hy + 1.2, 2.4, 2, [T[3]]); // the muzzle
  b.cap(hx - 1, hy - 3, hx - 3, hy - 7, 1, [horn]);
  b.cap(hx + 1, hy - 3, hx, hy - 7, 1, [horn]);
  b.cap(hx - 3, hy - 1, hx - 6, hy + 2, 1.3, [T[1]]); // an ear
  b.px(hx + 1, hy - 1, eye);
  final chew = pose == 'mastica' && f % 2 == 1;
  b.rect(hx + 2, hy + 4 + (chew ? 1 : 0), 2, 3, D[0]); // the beard
  b.px(hx + 5, hy + 2 + (chew ? 1 : 0), _h('#7A2A1A'));
  b.rect(hx - 4, hy + 3, 3, 1, _h('#B8302A')); // the rope collar
  return b.outline().done();
}

/* ---------- coins, bags, the goods ---------- */

/// A coin (mostrador-preview.html's): 7 x 7, gold.
Sprite mkMoneda() {
  final b = Buf(7, 7);
  b.ell(3.5, 3.5, 2.6, 2.6, _hs(['#B87A10', '#F0C020', '#FFE070']));
  return b.outline().done();
}

/// A paper bag, brown, folded at the top (mostrador-preview.html's `bolsa`); [llena]: something sticks out of it.
Sprite mkBolsaPapel([bool llena = false]) {
  final b = Buf(11, 14);
  b.rect(1, 4, 9, 9, _h('#C89A60'));
  b.rect(1, 4, 3, 9, _h('#E0B880'));
  b.rect(1, 3, 9, 1, _h('#A87A40'));
  b.rect(4, 7, 4, 1, _h('#A87A40'));
  if (llena) {
    b.rect(3, 1, 2, 3, _h('#F4F6FA'));
    b.rect(6, 0, 2, 4, _h('#962828'));
  } else {
    b.rect(6, 1, 2, 3, _h('#E2A85A'));
  }
  return b.outline().done();
}

/// Carmen's cloth bag (mostrador.md 37: "a cloth bag on her shoulder", "held open"): green and white stripes, a strap;
/// [abierta]: held open, its dark inside showing.
Sprite mkBolsaTela([bool abierta = false]) {
  final b = Buf(14, 18);
  b.cap(3, 7, 7, 1, 1, [_h('#3E8A4E')]);
  b.cap(10, 7, 7, 1, 1, [_h('#3E8A4E')]); // the strap
  for (var y = 7; y < 17; y++) {
    for (var x = 1; x < 13; x++) {
      b.px(x, y, (x ~/ 2) % 2 == 0 ? _h('#5AB46A') : _h('#F2F2E8'));
    }
  }
  b.rect(1, 16, 12, 1, _h('#2E6A3A'));
  if (abierta) b.ell(7, 7.5, 5.5, 1.6, [_h('#2A2018')]);
  return b.outline().done();
}

/// The nine goods of the shelves (mostrador-preview.html's stand-ins: the size and the colours colmado-dentro.js's
/// stand-ins have), each its bottom middle on its place: leche, pan, mantequilla, queso, cafe, arroz, azucar, jugo,
/// habichuelas.
const List<String> GENEROS = [
  'leche',
  'pan',
  'mantequilla',
  'queso',
  'cafe',
  'arroz',
  'azucar',
  'jugo',
  'habichuelas',
];

/// One of the [GENEROS].
Sprite mkGenero(String k) {
  switch (k) {
    case 'leche':
      final b = Buf(10, 14);
      b.rect(1, 4, 8, 9, _h('#F4F6FA'));
      b.rect(7, 4, 2, 9, _h('#C6CEDC'));
      b.rect(1, 7, 8, 3, _h('#4678D2'));
      b.rect(2, 2, 6, 2, _h('#F4F6FA'));
      b.rect(3, 1, 4, 1, _h('#C6CEDC'));
      return b.outline().done();
    case 'pan':
      final b = Buf(15, 10);
      b.ell(
        7.5,
        5,
        6.2,
        3.6,
        _hs(['#A8682C', '#C48440', '#E2A85A', '#F4CC88']),
      );
      for (final p in const [
        [4, 3],
        [7, 2],
        [10, 3],
      ]) {
        b.line(p[0], p[1], p[0] + 1, p[1] + 2, _h('#8A5222'));
      }
      return b.outline().done();
    case 'mantequilla':
      final b = Buf(13, 8);
      b.rect(1, 2, 11, 5, _h('#FAD860'));
      b.rect(1, 2, 11, 2, _h('#FFE98C'));
      b.rect(1, 6, 11, 1, _h('#F0F0E8'));
      return b.outline().done();
    case 'queso':
      final b = Buf(12, 12);
      b.rect(1, 4, 10, 7, _h('#F6B03C'));
      b.rect(2, 2, 8, 3, _h('#FCD070'));
      b.rect(8, 4, 3, 7, _h('#DC9428'));
      b.px(4, 7, _h('#D68C28'));
      b.px(6, 9, _h('#D68C28'));
      b.px(3, 9, _h('#D68C28'));
      return b.outline().done();
    case 'cafe':
      final b = Buf(10, 14);
      b.rect(1, 3, 8, 10, _h('#962828'));
      b.rect(1, 1, 8, 3, _h('#B04040'));
      b.rect(1, 7, 8, 3, _h('#F0C85A'));
      b.px(4, 8, _h('#7A4A1E'));
      b.px(5, 8, _h('#7A4A1E'));
      return b.outline().done();
    case 'arroz':
      final b = Buf(12, 14);
      b.rect(1, 3, 10, 10, _h('#F0ECDE'));
      b.rect(3, 1, 6, 3, _h('#F0ECDE'));
      b.rect(9, 3, 2, 10, _h('#CFC9B4'));
      b.rect(1, 7, 10, 3, _h('#4A9A5A'));
      return b.outline().done();
    case 'azucar':
      final b = Buf(11, 14);
      b.rect(1, 3, 9, 10, _h('#9AC8F0'));
      b.rect(2, 1, 7, 2, _h('#9AC8F0'));
      b.rect(8, 3, 2, 10, _h('#78A8D8'));
      b.rect(1, 7, 9, 3, _h('#FAFAFA'));
      return b.outline().done();
    case 'jugo':
      final b = Buf(10, 14);
      b.rect(1, 2, 8, 11, _h('#F69628'));
      b.rect(7, 2, 2, 11, _h('#D07818'));
      b.rect(1, 6, 8, 3, _h('#FAF0C8'));
      b.rect(2, 1, 6, 1, _h('#F69628'));
      return b.outline().done();
    case 'habichuelas':
      final b = Buf(11, 12);
      b.rect(1, 2, 9, 9, _h('#BE3232'));
      b.rect(1, 2, 2, 9, _h('#DE5A5A'));
      b.rect(1, 5, 9, 4, _h('#FAECC8'));
      b.rect(1, 2, 9, 1, _h('#C8C8D4'));
      return b.outline().done();
  }
  throw ArgumentError.value(k, 'k', 'not one of the goods');
}

/// A límber on its stick, out of its cup (held, or licked): [col] `white` (coconut) or `orange` (mango), as
/// mostrador.md 38 names them.
Sprite mkLimberPalo(String col) {
  final b = Buf(8, 12);
  final c = col == 'white'
      ? _hs(['#C8C8D4', '#E8E8F0', '#FFFFFF'])
      : _hs(['#C8601A', '#F08A2A', '#FFB870']);
  b.rect(1, 1, 6, 7, c[1]);
  b.rect(1, 1, 2, 7, c[2]);
  b.rect(5, 1, 2, 7, c[0]);
  b.rect(3, 8, 2, 3, _h('#D8BC8A'));
  return b.outline().done();
}

/// Where a sprite drawn by [mk] lands in a sheet picture (colmado-sprites.png): every pose this file draws, in order, for
/// the tool that makes the picture.
List<(String, Sprite)> colmadoCastSheet() => [
  for (final p in PEPE_POSES) ('pepe $p', mkPepe(p)),
  ('pepe idle, talking', mkPepe('idle', open: true)),
  for (var i = 0; i < 3; i++)
    for (final p in const ['idle', 'saluda0', 'moneda', 'limber_a', 'limber_b'])
      ('nino ${i + 1} $p', mkNino(i, p)),
  for (final p in const ['de_pie', 'cuello', 'come'])
    ('cabra $p', mkCabra(p, 0)),
  ('cabra mastica 0', mkCabra('mastica', 0)),
  ('cabra mastica 1', mkCabra('mastica', 1)),
  ('moneda', mkMoneda()),
  ('bolsa de papel', mkBolsaPapel()),
  ('bolsa de papel, llena', mkBolsaPapel(true)),
  ('bolsa de tela', mkBolsaTela()),
  ('bolsa de tela, abierta', mkBolsaTela(true)),
  for (final k in GENEROS) (k, mkGenero(k)),
  ('limber blanco', mkLimberPalo('white')),
  ('limber anaranjado', mkLimberPalo('orange')),
];

/// The largest of a list of numbers (for the sheet picture's layout).
int maxOf(Iterable<int> v) => v.reduce(math.max);
