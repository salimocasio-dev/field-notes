// La calle's cast: the sprites of the people and things more than one of the place's four scenes uses (esquina, parada,
// tiendas, cruce), from their scripts' Needs lists. First writer: order 54b (La esquina); the other three builders copy
// it and add to it only by adding.
//
//   - the obrero (esquina.md story 50; cruce.md "the obrero of story 50"): a road worker, a yellow helmet, a vest, with
//     his paddle (red side, green side), sitting on his bucket drinking, whistling, holding out two small flags;
//   - the bicycle (esquina.md: "a bicycle with a rider (the señor; Luis) and pushed"; tiendas.md "Luis's bicycle with a
//     basket"; cruce.md "Luis's bicycle with the basket", "don Pepe on his bicycle"): alone, with a rider, pushed;
//   - the traffic cones as sprites (esquina.md, cruce.md: "the cones"): standing, knocked over;
//   - the bebé on a grown-up's arm (esquina.md 48, 49; the sheets' rules.anchor: "the bebé on an arm is a part of the
//     carrier's sprite");
//   - who already exists, taken from where they are: the family (kit.js FAM, engine.js mkAbuela), don Pepe
//     (colmado_cast.dart), the señora and the señor of El banco (mostrador_sprites.dart mkCliente: El banco's figures
//     with their own extras), Canelo (kit.js mkPerro), the piragüero (El banco's).
//
// Drawn in the old sprites' way, as colmado_cast.dart does: kit.js mkPersona for a person (48 wide, a grown-up 56 rows, a
// child 44), engine.js Buf with its ramps and its dark outline for a thing, the old palette (kit.js PIEL, PELO, engine.js
// RP). The looks follow the previews' stand-ins (esquina-preview.html: OBRERO, the helmet, the cone, the bucket, the
// bicycle) where they give one; what no script and no stand-in gives is this file's guess (said at each). The content lane
// looks at every one on docs/proyecto/pixel/port/calle-sprites.png (tool/make_calle_sprites_test.dart).
// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/src/calle/calle_vehicles.dart';
import 'package:coqui_scenes/src/colmado/colmado_cast.dart';
import 'package:coqui_scenes/src/mostrador/mostrador_sprites.dart'
    show bancoWho, mkCliente;

int _h(String s) => hexColour(s);
List<int> _hs(List<String> s) => [for (final x in s) hexColour(x)];

/// A copy of [s] turned left for right (a sprite that faces right faces left).
Sprite mirrorSprite(Sprite s) {
  final px = Uint32List(s.w * s.h);
  for (var y = 0; y < s.h; y++) {
    for (var x = 0; x < s.w; x++) {
      px[y * s.w + (s.w - 1 - x)] = s.px[y * s.w + x];
    }
  }
  return Sprite(s.w, s.h, px);
}

/* ---------- the obrero ---------- */

/// The obrero (esquina-preview.html's OBRERO): a bald head under a yellow helmet (drawn over it: [mkCasco]), a
/// yellow-green vest with two pale stripes over a grey work shirt, dark trousers, boots.
final Who OBRERO = Who(
  piel: PIEL['b']!,
  pelo: PELO['negro']!,
  peinado: 'calvo',
  ropa: RP.grey,
  abajo: RP.stone,
  zapato: _h('#3A2A1C'),
  detalle: (b, X, tc, rx, t) {
    final V = _hs(['#8EA81C', '#B4D02A', '#D6EC3C', '#EAF86A']),
        stripe = _h('#F4F4E8');
    void on(num x, num y, int c) {
      if (b.has(x.toInt(), y.toInt())) b.px(x, y, c);
    }

    for (var y = 19; y < 40; y++) {
      for (var x = X - 8; x <= X + 8; x++) {
        if (x == X) {
          on(x, y, V[0]);
          continue;
        }
        on(x, y, x < X ? V[3] : V[2]);
      }
    }
    for (final y in const [27, 28, 33, 34]) {
      for (var x = X - 8; x <= X + 8; x++) {
        on(x, y, stripe);
      }
    }
  },
);

/// The obrero's helmet (esquina-preview.html's `helmet`): a yellow dome and a brim, 48 x 14, drawn over the head of a
/// persona canvas at its top left.
Sprite mkCasco() {
  final b = Buf(48, 14);
  b.ell(24, 6.2, 7.6, 4.8, RP.yel);
  b.rect(15, 8, 18, 2, RP.yel[1]);
  b.rect(15, 8, 18, 1, RP.yel[3]);
  b.rect(23, 1, 2, 3, RP.yel[0]);
  return b.outline().done();
}

/// The obrero's paddle: a round board on a stick, [side] `roja` (stop: red with a white bar) or `verde` (go: green with
/// a white arrow). 11 x 24, its stick's foot at the bottom middle. The look is this file's guess (esquina.md: "a paddle
/// (red on one side, green on the other)").
Sprite mkPaleta(String side) {
  final b = Buf(11, 24);
  b.rect(5, 10, 1, 14, _h('#B88040'));
  b.rect(4, 10, 1, 14, _h('#8A5A2A'));
  final c = side == 'verde'
      ? _hs(['#1E6A2A', '#2E8A3A', '#44A850', '#6CC878'])
      : _hs(['#8A1E1A', '#B8302A', '#D84A40', '#F07A6A']);
  b.ell(5, 5, 5, 5, c);
  if (side == 'verde') {
    b.rect(3, 5, 4, 1, _h('#FFFFFF'));
    b.px(6, 4, _h('#FFFFFF'));
    b.px(6, 6, _h('#FFFFFF'));
    b.px(7, 5, _h('#FFFFFF'));
  } else {
    b.rect(2, 4, 7, 2, _h('#FFFFFF'));
  }
  return b.outline().done();
}

/// A small flag on a stick ([color] `verde` or `roja`), 9 x 13, held at the stick's foot (bottom left).
Sprite mkBandera(String color) {
  final b = Buf(9, 13);
  b.rect(1, 0, 1, 13, _h('#B88040'));
  final c = color == 'verde'
      ? _hs(['#2E8A3A', '#44A850', '#6CC878'])
      : _hs(['#B8302A', '#D84A40', '#F07A6A']);
  b.rect(2, 1, 6, 5, c[1]);
  b.rect(2, 1, 6, 1, c[2]);
  b.rect(2, 5, 6, 1, c[0]);
  return b.outline().done();
}

/// The obrero's water bottle, 5 x 9 (held at its middle).
Sprite mkBotella() {
  final b = Buf(5, 9);
  b.rect(1, 2, 3, 6, _h('#9CCBF5'));
  b.rect(1, 2, 1, 6, _h('#DCEEFF'));
  b.rect(1, 0, 3, 2, _h('#2E6AC8'));
  return b.outline().done();
}

/// The poses of the obrero this cast draws: `idle` standing; `paleta_roja`, `paleta_verde` his paddle up, its red or
/// green side to us; `senala` pointing down (at the wet cement); `silba` a hand at his mouth (whistling); `banderas`
/// holding out the two small flags; `sentado` sitting (on his bucket); `bebe` sitting, drinking from his bottle;
/// `saluda0`, `saluda1` a hand lifted; `banderas_sentado` sitting, holding out the two small flags.
const List<String> OBRERO_POSES = [
  'idle',
  'paleta_roja',
  'paleta_verde',
  'senala',
  'silba',
  'banderas',
  'sentado',
  'bebe',
  'saluda0',
  'saluda1',
  'banderas_sentado',
];

/// The obrero in [pose] (one of [OBRERO_POSES]); [open]: talking. mkPersona's figure (48 wide, its middle column [PX])
/// with the helmet over its head (the sitting figure is 7 rows shorter: the helmet is at the same place, its head is).
Sprite mkObrero(String pose, {bool open = false}) {
  final sent =
      pose == 'sentado' || pose == 'bebe' || pose == 'banderas_sentado';
  final p = switch (pose) {
    'paleta_roja' || 'paleta_verde' || 'saluda0' => 'wave0',
    'saluda1' => 'wave1',
    'senala' => 'tu',
    'silba' => 'yo',
    'banderas' || 'banderas_sentado' => 'offer',
    'bebe' => 'wave0',
    _ => 'idle',
  };
  final base = mkPersona(OBRERO, p, open, sent);
  final parts = <(Sprite, int, int)>[(mkCasco(), 0, 0)];
  if (pose == 'paleta_roja' || pose == 'paleta_verde') {
    // the paddle in the lifted hand (kit.js mkPersona 'wave0': the hand at X + rx + 5, row 10)
    final pl = mkPaleta(pose == 'paleta_verde' ? 'verde' : 'roja');
    parts.add((pl, PX + 8 + 5 - 5, 10 - 14));
  } else if (pose == 'banderas' || pose == 'banderas_sentado') {
    // the two flags in the hand held out (kit.js 'offer': the hand at X - rx - 9.5, row 25)
    parts
      ..add((mkBandera('verde'), PX - 8 - 10 - 1, 25 - 12))
      ..add((mkBandera('roja'), PX - 8 - 10 + 3, 25 - 10));
  } else if (pose == 'bebe') {
    parts.add((mkBotella(), PX + 8 + 5 - 2, 10 - 2));
  }
  return overSprite(base, parts, top: pose.startsWith('paleta') ? 4 : 0);
}

/* ---------- the bucket and the cones ---------- */

/// The obrero's bucket, upturned (esquina-preview.html's `cubo`), 14 x 9, its bottom middle on its place.
Sprite mkCubo() {
  final b = Buf(14, 9);
  b.rect(1, 2, 12, 6, _h('#8A94A6'));
  b.rect(1, 2, 3, 6, _h('#B4BCCC'));
  b.rect(10, 2, 3, 6, _h('#66707E'));
  b.ell(7, 2.5, 6, 1.6, _hs(['#5A6270', '#A8B0C0']));
  b.rect(1, 7, 12, 1, _h('#566070'));
  return b.outline().done();
}

/// A traffic cone (esquina-preview.html's `cono`, orange with a white band as the set's own cones): standing 13 x 15, or
/// knocked over ([caido]) 17 x 11; its bottom middle on its place.
Sprite mkCono([bool caido = false]) {
  if (caido) {
    final b = Buf(17, 11);
    for (var x = 0; x < 13; x++) {
      final h = 2 + (x * .6).floor(), y = (5.5 - h / 2 + .5).floor();
      b.rect(
        1 + x,
        y + 1,
        1,
        h,
        (x >= 5 && x <= 7)
            ? _h('#FAF6EC')
            : (x % 2 != 0 ? _h('#EE7828') : _h('#F08A3C')),
      );
    }
    b.rect(13, 1, 2, 9, _h('#E26824'));
    b.rect(13, 1, 1, 9, _h('#F4A060'));
    return b.outline().done();
  }
  final b = Buf(13, 15);
  for (var y = 0; y < 12; y++) {
    final w = 2 + (y * .75).floor(), x = (6.5 - w / 2 + .5).floor();
    b.rect(
      x,
      1 + y,
      w,
      1,
      (y >= 5 && y <= 7)
          ? _h('#FAF6EC')
          : (y % 2 != 0 ? _h('#EE7828') : _h('#F08A3C')),
    );
  }
  b.rect(1, 12, 11, 2, _h('#E26824'));
  b.rect(1, 12, 11, 1, _h('#F4A060'));
  return b.outline().done();
}

/* ---------- the bicycle ---------- */

/// A bicycle seen from the side (esquina-preview.html's `bici`), 32 x 19, its front wheel at the right (it faces right:
/// [mirrorSprite] turns it); [cesta]: a basket over the front wheel (tiendas.md, cruce.md: "Luis's bicycle with a
/// basket"; the basket's look is this file's guess).
Sprite mkBici({bool cesta = false}) {
  final b = Buf(32, 19);
  final tyre = _h('#2E2E38'), hub = _h('#9AA0AE'), frame = _h('#C03030');
  void ring(num cx, num cy, num r) {
    for (num a = 0; a < 6.3; a += .12) {
      b.px(cx + math.cos(a) * r, cy + math.sin(a) * r, tyre);
    }
  }

  ring(7, 12, 5.6);
  ring(24, 12, 5.6);
  b.px(7, 12, hub);
  b.px(24, 12, hub);
  b.line(7, 12, 14, 5, frame);
  b.line(14, 5, 22, 5, frame);
  b.line(22, 5, 24, 12, frame);
  b.line(14, 5, 17, 12, frame);
  b.line(17, 12, 7, 12, frame);
  b.line(17, 12, 22, 5, frame);
  b.line(13, 4, 15, 4, tyre);
  b.line(22, 5, 21, 2, tyre);
  b.line(20, 2, 23, 2, tyre);
  if (cesta) {
    b.rect(24, 1, 7, 5, _h('#B88A4A'));
    b.rect(24, 1, 7, 1, _h('#D8AC6A'));
    b.rect(26, 2, 1, 4, _h('#8A6232'));
    b.rect(29, 2, 1, 4, _h('#8A6232'));
  }
  return b.outline().done();
}

/// A rider on the bicycle: [who] sitting (mkPersona's sitting figure) with the row of the hips on the saddle, the bicycle
/// under; facing right. The sprite is 48 wide, its middle column [PX] over the saddle; the feet of the
/// bicycle (its wheels' bottom) at its bottom edge. [person] gives the rider's own sprite instead of [who]'s (abuela,
/// don Pepe).
Sprite mkCiclista(
  Who? who, {
  bool open = false,
  bool cesta = false,
  String pose = 'idle',
  Sprite? person,
}) {
  final rider = person ?? mkPersona(who!, pose, open, true);
  final nino = who?.nino ?? false;
  // the hips' row of the sitting figure: kit.js mkPersona hc = 18 + 2 t - 2 (t 11 a grown-up, 7 a child)
  final hc = nino ? 30 : 38;
  final bike = mkBici(cesta: cesta);
  // the saddle (the stand-in's bar at row 4, columns 13 to 15) under the hips
  final by = hc - 4 + 1, bx = PX - 14;
  final h = by + bike.h;
  final base = Sprite(48, h, Uint32List(48 * h));
  return overSprite(base, [(bike, bx, by), (rider, 0, 0)]);
}

/// The bicycle pushed: [who] standing beside it (the bicycle 26 px to the right of the person's middle,
/// esquina-preview.html moment 3), both on the ground; 72 wide, the person's middle at column [PX].
Sprite mkBiciEmpujada(
  Who? who, {
  bool open = false,
  bool cesta = false,
  Sprite? person,
}) {
  final p = person ?? mkPersona(who!, 'taza', open, false);
  final bike = mkBici(cesta: cesta);
  final pb = inkBottom(p), h = pb;
  final base = Sprite(72, h, Uint32List(72 * h));
  return overSprite(base, [(bike, PX + 26 - 16, pb - bike.h), (p, 0, 0)]);
}

/* ---------- the bebé on an arm ---------- */

/// [carrier] with the bebé (kit.js mkBebe, sitting, [est]) over its chest at ([x], [y]) of the carrier's sprite
/// (esquina-preview.html: abuela's at (14, 14), a persona's at (10, 14)): the arm that holds him is the picture's left.
Sprite withBebe(
  Sprite carrier,
  int x,
  int y, {
  String est = 'idle',
  bool f = false,
}) => overSprite(carrier, [(mkBebe(est, f), x, y)]);

/* ---------- who is who ---------- */

/// The people of La calle by their key (the stories' `quien` and speaker keys): `abuela`, `mama`, `papa`, `luis`,
/// `carmen`, `pepe`, `senora`, `senor`, `obrero`. Each in [pose]: `idle`; `saluda0`, `saluda1` a hand lifted; `mano` a hand
/// held out; `ojos` both hands up to the face; and the obrero's own (OBRERO_POSES). The anchor is the feet's bottom edge
/// and the middle column (the sheets' rules.anchor: abuela's column 30, a persona's [PX]).
Anchored callePerson(String id, String pose, {bool open = false}) {
  final persona = switch (pose) {
    'saluda0' => 'wave0',
    'saluda1' => 'wave1',
    'mano' => 'offer',
    'ojos' => 'ojos',
    'taza' => 'taza',
    _ => 'idle',
  };
  switch (id) {
    case 'abuela':
      final s = mkAbuela(
        persona == 'wave0' || persona == 'wave1' || persona == 'offer'
            ? persona
            : 'idle',
        open,
      );
      return (s: s, ax: 30, ay: inkBottom(s));
    case 'pepe':
      final s = mkPepe(pose, open: open);
      return (s: s, ax: PX, ay: inkBottom(s));
    case 'senora':
    case 'senor':
      final s = mkCliente(id, persona == 'ojos' ? 'ojos' : persona, open: open);
      return (s: s, ax: PX, ay: inkBottom(s));
    case 'obrero':
      final s = mkObrero(pose, open: open);
      return (s: s, ax: PX, ay: inkBottom(s));
  }
  final who = calleWho(id);
  final s = mkPersona(who, persona, open, false);
  return (s: s, ax: PX, ay: inkBottom(s));
}

/// The figure (mkPersona's Who) of a person of the family or the place: `mama`, `papa`, `luis` (FAM.hermano), `carmen`
/// (FAM.hermana), `obrero`.
Who calleWho(String id) => switch (id) {
  'mama' => FAM['mama']!,
  'papa' => FAM['papa']!,
  'luis' => FAM['hermano']!,
  'carmen' => FAM['hermana']!,
  'obrero' => OBRERO,
  _ => throw ArgumentError.value(id, 'id', 'not a person of La calle'),
};

/// Every sprite and pose this file draws, and the vehicles (calle_vehicles.dart), in order, for the sheet picture
/// (calle-sprites.png).
List<(String, Sprite)> calleCastSheet() => [
  for (final v in calleVehicleSheet()) ('vehiculo ${v.key}', v.s),
  for (final p in OBRERO_POSES) ('obrero $p', mkObrero(p)),
  ('obrero idle, talking', mkObrero('idle', open: true)),
  ('casco', mkCasco()),
  ('paleta roja', mkPaleta('roja')),
  ('paleta verde', mkPaleta('verde')),
  ('bandera verde', mkBandera('verde')),
  ('bandera roja', mkBandera('roja')),
  ('botella', mkBotella()),
  ('cubo', mkCubo()),
  ('cono', mkCono()),
  ('cono caido', mkCono(true)),
  ('bicicleta', mkBici()),
  ('bicicleta con cesta', mkBici(cesta: true)),
  ('ciclista: el senor', mkCiclista(null, person: _sentado('senor'))),
  ('ciclista: Luis', mkCiclista(FAM['hermano']!)),
  ('ciclista: Luis, con cesta', mkCiclista(FAM['hermano']!, cesta: true)),
  ('ciclista: don Pepe', mkCiclista(PEPE)),
  ('bicicleta empujada: Luis', mkBiciEmpujada(FAM['hermano']!)),
  ('abuela con el bebe', withBebe(mkAbuela('idle', false), 14, 14)),
  (
    'mama con el bebe',
    withBebe(mkPersona(FAM['mama']!, 'idle', false, false), 10, 14),
  ),
  (
    'papa con el bebe',
    withBebe(mkPersona(FAM['papa']!, 'idle', false, false), 10, 14),
  ),
];

/// El banco's señora or señor sitting (for a rider): their figure sitting (El banco's extras, the hat and the cane, are
/// for a figure standing).
Sprite _sentado(String id) => mkPersona(bancoWho(id), 'idle', false, true);
