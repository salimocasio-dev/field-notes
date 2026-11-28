// Scene-specific sprites and cast outfits of La cuenta (place 8, La fonda, scene 4: `cuenta`, order 69):
// - Preview-matching core props (cuenta-preview.html, exact dimensions matching cuenta-sheet.json boxes):
//   carrito (76 x 22), copa (8 x 10: 0..3 scoops, little pool, big pool), flanes (14 x 8: normal, wobble),
//   mantecado (12 x 10: full, scooped), tapa (12 x 10), maquina (12 x 10: idle, beep),
//   frasco (10 x 12: 0..3 coins, bills, tipped), cuentaSlip (8 x 10).
// - Additional Needs sprites (historia/notas/guiones/cuenta.md):
//   tapaGrande (28 x 12), cuentaGrande (24 x 28 with crisp pixel digits), gavetaAbierta (18 x 7),
//   billetes (9 x 6), tarjeta (8 x 6), moneda (5 x 5), menta (5 x 5), sillaMano (9 x 12), beep (9 x 7),
//   platoFlan (10 x 6), vasoMantecado (7 x 8), guaguaPuerta (24 x 26), estrellasCuenta (15 x 9),
//   corazonCuenta (11 x 10).
// - People outfits (`CUENTA_WHO`), matching cuenta-preview.html lines 33-47.
// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'package:coqui_pixel/coqui_pixel.dart';

int _h(String s) => hexColour(s);

List<int> _ramp(List<String> hs) => [for (final s in hs) _h(s)];

Sprite _mk(int w, int h, void Function(Buf b) draw, {bool outline = true}) {
  final b = Buf(w, h);
  draw(b);
  return outline ? b.outline().done() : b.done();
}

/* ---------- People outfits (cuenta-preview.html lines 33-47) ---------- */

final List<int> _WHITE = _ramp(const [
  '#C8C8D0',
  '#E4E4EA',
  '#F6F6FA',
  '#FFFFFF',
]);

void Function(Buf b, num X, num tc, num rx, num t) _apron(List<int> G) =>
    (b, X, tc, rx, t) {
      b.rect(X - 4, 18, 1, 4, G[1]);
      b.rect(X + 3, 18, 1, 4, G[1]);
      b.rect(X - 5, 22, 10, 24, G[2]);
      b.rect(X - 5, 22, 2, 24, G[3]);
      b.rect(X + 3, 22, 2, 24, G[1]);
      b.rect(X - 5, 45, 10, 1, G[0]);
      b.rect(X - 5, 22, 10, 1, G[3]);
      b.rect(X - 3, 34, 6, 4, G[1]);
      b.rect(X - 3, 34, 6, 1, G[3]);
    };

/// Cast definitions for La cuenta (matches `cuenta-preview.html` `PEOPLE` + `abuelo_sin_gafas` for story 94).
final Map<String, Who> CUENTA_WHO = {
  'mesera': Who(
    piel: PIEL['b']!,
    pelo: PELO['castano']!,
    peinado: 'largo',
    ropa: _WHITE,
    falda: true,
    zapato: _h('#3A2414'),
    detalle: _apron(RP.teal),
  ),
  'mesero': Who(
    piel: PIEL['a']!,
    pelo: PELO['negro']!,
    peinado: 'corto',
    ropa: _WHITE,
    abajo: RP.stone,
    bigote: true,
  ),
  'cocinero': Who(
    piel: PIEL['c']!,
    pelo: PELO['castano']!,
    peinado: 'corto',
    ropa: _WHITE,
    abajo: RP.stone,
    bigote: true,
    detalle: _apron(RP.red),
  ),
  'abuelo': FAM['abuelo']!,
  'abuelo_sin_gafas': Who(
    piel: FAM['abuelo']!.piel,
    pelo: FAM['abuelo']!.pelo,
    peinado: FAM['abuelo']!.peinado,
    ropa: FAM['abuelo']!.ropa,
    abajo: FAM['abuelo']!.abajo,
    bigote: FAM['abuelo']!.bigote,
    detalle: FAM['abuelo']!.detalle,
  ),
  'luis': FAM['hermano']!,
  'carmen': FAM['hermana']!,
  'senor': Who(
    piel: PIEL['a']!,
    pelo: PELO['blanco']!,
    peinado: 'corto',
    ropa: RP.wood,
    abajo: RP.grey,
    bigote: true,
  ),
  'senora': Who(
    piel: PIEL['a']!,
    pelo: PELO['castano']!,
    peinado: 'corto',
    ropa: RP.grn,
    falda: true,
    zapato: _h('#F2F2F8'),
  ),
  'joven': Who(
    piel: PIEL['b']!,
    pelo: PELO['castano']!,
    peinado: 'corto',
    ropa: RP.cream.sublist(1),
    abajo: RP.blue,
    zapato: _h('#F2F2F8'),
  ),
  'mujer': Who(
    piel: PIEL['c']!,
    pelo: PELO['negro']!,
    peinado: 'largo',
    ropa: RP.yel,
    falda: true,
    zapato: _h('#7A4A10'),
  ),
};

/* ---------- cuenta-preview.html core props (exact box dimensions) ---------- */

/// Dessert cart: 76 x 22 (cuenta-preview.html `THING.carrito`, matches `spots.carrito` / `carrito2`).
Sprite mkCarrito() => _mk(76, 22, (b) {
  b.rect(1, 5, 74, 3, _h('#C8853C'));
  b.rect(1, 5, 74, 1, _h('#E2A85A'));
  b.rect(1, 7, 74, 1, _h('#92602E'));
  b.rect(1, 1, 2, 4, _h('#92602E'));
  b.rect(73, 1, 2, 4, _h('#92602E'));
  b.rect(4, 8, 2, 7, _h('#6E4220'));
  b.rect(70, 8, 2, 7, _h('#6E4220'));
  b.rect(4, 15, 68, 2, _h('#B88040'));
  b.rect(4, 15, 68, 1, _h('#D8A460'));
  b.ell(8, 18, 2.8, 2.8, _ramp(const ['#4A4A58', '#6E6E80']));
  b.ell(68, 18, 2.8, 2.8, _ramp(const ['#4A4A58', '#6E6E80']));
});

/// Frog's small cup with spoon: 8 x 10 (cuenta-preview.html `THING.copa`, matches `spots.copa` / `copa2`).
/// [scoops]: 0..3 ice cream scoops; [pool]: little melted pool (2 scoops ending); [bigPool]: big pool (1 scoop ending).
Sprite mkCopa({int scoops = 0, bool pool = false, bool bigPool = false}) =>
    _mk(8, 10, (b) {
      final n = scoops.clamp(0, 3);
      b.rect(1, 4, 6, 5, _h('#F6F6FA'));
      b.rect(1, 4, 6, 1, _h('#B0D4FF'));
      b.rect(2, 8, 4, 1, _h('#B8B8C8'));
      b.rect(5, 1, 1, 4, _h('#D8D8E4'));
      b.rect(5, 1, 2, 1, _h('#D8D8E4'));
      if (bigPool) {
        b.rect(1, 5, 6, 3, _h('#F6E4BC'));
        b.rect(2, 4, 4, 1, _h('#FFFBEA'));
      } else if (pool) {
        b.rect(1, 5, 6, 1, _h('#F6E4BC'));
      }
      if (n >= 1) {
        b.rect(2, 3, 2, 2, _h('#FFFBEA'));
        b.px(2, 3, _h('#F6E4BC'));
      }
      if (n >= 2) {
        b.rect(4, 3, 2, 2, _h('#F6E4BC'));
        b.px(4, 3, _h('#FFFBEA'));
      }
      if (n >= 3) {
        b.rect(3, 1, 2, 2, _h('#FFE4EC'));
        b.px(3, 1, _h('#FFFBEA'));
      }
    });

/// Caramel flan on plate: 14 x 8 (cuenta-preview.html `THING.flanes`, matches `spots.flanes` / `flanes2`).
Sprite mkFlanes({bool wobble = false}) => _mk(14, 8, (b) {
  b.rect(1, 5, 12, 2, _h('#F6F6FA'));
  b.rect(1, 5, 12, 1, _h('#FFFFFF'));
  final dx = wobble ? 1 : 0;
  b.ell(7 + dx, 4, 4.4, 2.6, _ramp(const ['#B8601C', '#DC8430', '#F4CC88']));
  b.rect(4 + dx, 2, 6, 1, _h('#7A4A1E'));
});

/// Tub of ice cream with scoop: 12 x 10 (cuenta-preview.html `THING.mantecado`, matches `spots.mantecado`).
Sprite mkMantecado({bool scooped = false}) => _mk(12, 10, (b) {
  b.rect(1, 4, 10, 5, _h('#FFFBEA'));
  b.rect(1, 4, 10, 1, _h('#E0609A'));
  b.rect(1, 8, 10, 1, _h('#D8BC8A'));
  if (scooped) {
    b.ell(5, 3, 2.6, 1.8, _ramp(const ['#E8C890', '#F6E4BC', '#FFFBEA']));
    b.rect(8, 2, 2, 2, _h('#B8B8C8'));
  } else {
    b.ell(6, 3, 3.4, 2.4, _ramp(const ['#E8C890', '#F6E4BC', '#FFFBEA']));
  }
});

/// Hanging domed cover: 12 x 10 (cuenta-preview.html `THING.tapa`, matches `spots.tapa` / `tapa2`).
Sprite mkTapa() => _mk(12, 10, (b) {
  b.ell(6, 6, 5, 4, _ramp(const ['#9494A6', '#C8C8D4', '#F2F2F8']));
  b.rect(1, 7, 10, 2, _h('#B8B8C8'));
  b.rect(5, 1, 2, 2, _h('#6E6E80'));
});

/// Wide domed cover swung down over desserts briefly during `sirve93(nada)`: 28 x 12.
Sprite mkTapaGrande() => _mk(28, 12, (b) {
  b.ell(14, 9, 12.5, 6.5, _ramp(const ['#9494A6', '#C8C8D4', '#F2F2F8']));
  b.rect(2, 9, 24, 2, _h('#B8B8C8'));
  b.rect(12, 1, 4, 2, _h('#6E6E80'));
});

/// Card machine: 12 x 10 (cuenta-preview.html `THING.maquina`, matches `spots.maquina`).
Sprite mkMaquina({bool beep = false}) => _mk(12, 10, (b) {
  b.rect(1, 1, 10, 8, _h('#4A4A58'));
  b.rect(2, 2, 8, 2, beep ? _h('#7CE8A0') : _h('#9CCBDE'));
  for (final x in const [3, 5, 7, 9]) {
    for (final y in const [5, 7]) {
      b.px(x, y, _h('#D8D8E4'));
    }
  }
});

/// Glass jar: 10 x 12 (cuenta-preview.html `THING.frasco`, matches `spots.frasco`).
/// [coins]: 0..3 coins inside; [bills]: 0..2 folded bills inside; [tipped]: tipped sideways in `final94`.
Sprite mkFrasco({int coins = 0, int bills = 0, bool tipped = false}) =>
    _mk(10, 12, (b) {
      if (tipped) {
        b.rect(1, 4, 2, 6, _h('#B88040'));
        b.rect(3, 4, 6, 6, _h('#DDF1FA'));
        b.rect(4, 5, 4, 1, _h('#FFFFFF'));
        b.rect(8, 4, 1, 6, _h('#9CCBDE'));
        for (var i = 0; i < coins.clamp(0, 3); i++) {
          b.rect(2 + i * 2, 10, 2, 1, _h('#F8C838'));
        }
        return;
      }
      b.rect(1, 1, 8, 2, _h('#B88040'));
      b.rect(1, 3, 8, 8, _h('#DDF1FA'));
      b.rect(2, 4, 1, 6, _h('#FFFFFF'));
      b.rect(1, 10, 8, 1, _h('#9CCBDE'));
      final nc = coins.clamp(0, 3);
      if (nc >= 1) b.rect(3, 9, 2, 1, _h('#F8C838'));
      if (nc >= 2) b.rect(6, 9, 2, 1, _h('#F8C838'));
      if (nc >= 3) b.rect(4, 7, 3, 2, _h('#FFE070'));
      final nb = bills.clamp(0, 2);
      if (nb >= 1) b.rect(3, 7, 4, 2, _h('#58A860'));
      if (nb >= 2) b.rect(4, 5, 4, 2, _h('#76C87E'));
    });

/// Paper bill slip in hand: 8 x 10 (cuenta-sheet.json notes: "a slip, 8 x 10").
Sprite mkCuentaSlip() => _mk(8, 10, (b) {
  b.rect(1, 1, 6, 8, _h('#FAF6EE'));
  b.rect(2, 3, 4, 1, _h('#8A8A9C'));
  b.rect(2, 5, 3, 1, _h('#8A8A9C'));
  b.rect(2, 7, 4, 1, _h('#4A4A58'));
});

const Map<String, List<String>> _DIGITS = {
  '0': ['###', '#.#', '#.#', '#.#', '###'],
  '1': ['.#.', '##.', '.#.', '.#.', '###'],
  '2': ['###', '..#', '###', '#..', '###'],
  '3': ['###', '..#', '###', '..#', '###'],
  '4': ['#.#', '#.#', '###', '..#', '..#'],
  '5': ['###', '#..', '###', '..#', '###'],
  '6': ['###', '#..', '###', '#.#', '###'],
  '7': ['###', '..#', '..#', '.#.', '.#.'],
  '8': ['###', '#.#', '###', '#.#', '###'],
  '9': ['###', '#.#', '###', '..#', '###'],
};

/// Enlarged bill slip with crisp pixel digits at its foot (`cuenta94`, story 94 beat 2): 24 x 28.
Sprite mkCuentaGrande(int n, {bool shine = false}) => _mk(24, 28, (b) {
  b.rect(1, 1, 22, 26, _h('#FAF6EE'));
  b.rect(1, 1, 22, 2, _h('#E4DCCA'));
  // Receipt header & item lines
  b.rect(4, 5, 14, 1, _h('#8A8A9C'));
  b.rect(4, 8, 10, 1, _h('#A4A4B4'));
  b.rect(16, 8, 4, 1, _h('#A4A4B4'));
  b.rect(4, 11, 12, 1, _h('#A4A4B4'));
  b.rect(16, 11, 4, 1, _h('#A4A4B4'));
  b.rect(3, 14, 18, 1, _h('#5A5A6C'));
  // Highlight band for total number at slip's foot
  if (shine) {
    b.rect(3, 16, 18, 9, _h('#FFF2A0'));
  }
  final s = '$n';
  final scale = 1;
  final totalW = s.length * 4 - 1;
  final sx = (24 - totalW * scale) ~/ 2;
  final col = shine ? _h('#B84018') : _h('#2A2A38');
  for (var i = 0; i < s.length; i++) {
    final pat = _DIGITS[s[i]];
    if (pat == null) continue;
    final ox = sx + i * 4;
    for (var y = 0; y < pat.length; y++) {
      for (var x = 0; x < pat[y].length; x++) {
        if (pat[y][x] == '#') b.px(ox + x, 18 + y, col);
      }
    }
  }
});

/* ---------- Additional Needs sprites (historia/notas/guiones/cuenta.md) ---------- */

/// Open register drawer extending below the register front: 18 x 7.
Sprite mkGavetaAbierta({bool bills = false}) => _mk(18, 7, (b) {
  b.rect(1, 1, 16, 5, _h('#505464'));
  b.rect(2, 2, 14, 3, _h('#363A48'));
  b.rect(6, 2, 1, 3, _h('#6E7488'));
  b.rect(11, 2, 1, 3, _h('#6E7488'));
  b.rect(8, 5, 2, 1, _h('#DEB252'));
  if (bills) {
    b.rect(3, 2, 3, 2, _h('#58A860'));
    b.rect(7, 2, 3, 2, _h('#76C87E'));
  }
});

/// Folded green bills: 9 x 6.
Sprite mkBilletes() => _mk(9, 6, (b) {
  b.rect(1, 1, 7, 4, _h('#58A860'));
  b.rect(2, 2, 5, 2, _h('#84D48C'));
  b.px(4, 2, _h('#3B7A42'));
  b.px(4, 3, _h('#3B7A42'));
});

/// Payment card: 8 x 6.
Sprite mkTarjeta() => _mk(8, 6, (b) {
  b.rect(1, 1, 6, 4, _h('#3E8CE8'));
  b.rect(1, 2, 6, 1, _h('#244C8A'));
  b.rect(2, 3, 2, 1, _h('#F8C838'));
});

/// Golden coin: 5 x 5.
Sprite mkMoneda() => _mk(5, 5, (b) {
  b.rect(1, 1, 3, 3, _h('#F8C838'));
  b.px(2, 2, _h('#FFF2A0'));
});

/// Green-and-white mint: 5 x 5.
Sprite mkMenta() => _mk(5, 5, (b) {
  b.rect(1, 1, 3, 3, _h('#F6F6FA'));
  b.px(1, 2, _h('#78C8AA'));
  b.px(3, 2, _h('#78C8AA'));
  b.px(2, 1, _h('#78C8AA'));
});

/// Wooden chair held in mesera's hand (`sillas95`): 9 x 12.
Sprite mkSillaMano() => _mk(9, 12, (b) {
  b.rect(1, 1, 7, 2, _h('#C69662'));
  b.rect(1, 4, 7, 2, _h('#C69662'));
  b.rect(1, 6, 7, 2, _h('#9C6A40'));
  b.rect(1, 1, 1, 10, _h('#9C6A40'));
  b.rect(7, 1, 1, 10, _h('#9C6A40'));
});

/// Beep signal icon over card machine (`cobra94 tarjeta`): 9 x 7.
Sprite mkBeep() => _mk(9, 7, (b) {
  b.px(2, 4, _h('#7CE8A0'));
  b.rect(4, 3, 1, 3, _h('#7CE8A0'));
  b.rect(6, 1, 1, 5, _h('#B8FFD0'));
});

/// Small served flan on plate (sent to guest in `sirve93`): 10 x 6.
Sprite mkPlatoFlan() => _mk(10, 6, (b) {
  b.rect(1, 4, 8, 1, _h('#F6F6FA'));
  b.rect(2, 2, 6, 2, _h('#DC8430'));
  b.rect(3, 1, 4, 1, _h('#7A4A1E'));
});

/// Small served cup of ice cream (sent to guest in `sirve93`): 7 x 8.
Sprite mkVasoMantecado() => _mk(7, 8, (b) {
  b.rect(1, 4, 5, 3, _h('#F6F6FA'));
  b.rect(1, 4, 5, 1, _h('#B0D4FF'));
  b.rect(2, 2, 3, 2, _h('#FFFBEA'));
  b.px(3, 1, _h('#F6E4BC'));
});

/// Night guagua bus glimpsed through the open doorway (`final95`): 24 x 26.
Sprite mkGuaguaPuerta() => _mk(24, 26, (b) {
  b.rect(1, 2, 22, 20, _h('#4682B4'));
  b.rect(1, 2, 22, 2, _h('#96BEDC'));
  b.rect(3, 5, 10, 7, _h('#D8ECFA'));
  b.rect(15, 5, 6, 14, _h('#2C4C70'));
  b.rect(16, 6, 4, 6, _h('#FFF2A0'));
  b.rect(3, 15, 4, 3, _h('#FFFA90'));
  b.rect(9, 15, 4, 3, _h('#FFFA90'));
  b.rect(2, 21, 5, 4, _h('#363A48'));
  b.rect(17, 21, 5, 4, _h('#363A48'));
});

/// Celebration stars for 3-of-3 endings: 15 x 9.
Sprite mkEstrellasCuenta() => _mk(15, 9, (b) {
  final y1 = _h('#FFE070');
  final y2 = _h('#FFFFFF');
  for (final (cx, cy) in const [(3, 4), (7, 2), (11, 4)]) {
    b.px(cx, cy, y2);
    b.px(cx - 1, cy, y1);
    b.px(cx + 1, cy, y1);
    b.px(cx, cy - 1, y1);
    b.px(cx, cy + 1, y1);
  }
});

/// Celebration heart for 3-of-3 endings: 11 x 10.
Sprite mkCorazonCuenta() => _mk(11, 10, (b) {
  final r = _h('#E44650');
  final hi = _h('#FFA0A8');
  b.rect(2, 1, 2, 2, r);
  b.rect(7, 1, 2, 2, r);
  b.rect(1, 2, 9, 3, r);
  b.rect(2, 5, 7, 2, r);
  b.rect(3, 7, 5, 1, r);
  b.rect(4, 8, 3, 1, r);
  b.px(5, 9, r);
  b.px(2, 2, hi);
});

/// All La cuenta sprites with names for the content lane's sprite sheet (`tool/make_cuenta_sprites_test.dart`).
List<(String, Sprite)> cuentaSpritesSheet() => [
  ('carrito', mkCarrito()),
  ('copa 0', mkCopa(scoops: 0)),
  ('copa 1', mkCopa(scoops: 1)),
  ('copa 2', mkCopa(scoops: 2)),
  ('copa 3', mkCopa(scoops: 3)),
  ('copa pool', mkCopa(scoops: 2, pool: true)),
  ('copa bigPool', mkCopa(scoops: 1, bigPool: true)),
  ('flanes', mkFlanes()),
  ('flanes wobble', mkFlanes(wobble: true)),
  ('mantecado', mkMantecado()),
  ('mantecado scooped', mkMantecado(scooped: true)),
  ('tapa', mkTapa()),
  ('tapa grande', mkTapaGrande()),
  ('maquina', mkMaquina()),
  ('maquina beep', mkMaquina(beep: true)),
  ('frasco 0', mkFrasco(coins: 0)),
  ('frasco 1', mkFrasco(coins: 1)),
  ('frasco 2', mkFrasco(coins: 2)),
  ('frasco 3', mkFrasco(coins: 3)),
  ('frasco bills', mkFrasco(bills: 2)),
  ('frasco tipped', mkFrasco(coins: 3, tipped: true)),
  ('cuenta slip', mkCuentaSlip()),
  ('cuenta grande 40', mkCuentaGrande(40)),
  ('cuenta grande shine', mkCuentaGrande(40, shine: true)),
  ('gaveta abierta', mkGavetaAbierta()),
  ('gaveta abierta bills', mkGavetaAbierta(bills: true)),
  ('billetes', mkBilletes()),
  ('tarjeta', mkTarjeta()),
  ('moneda', mkMoneda()),
  ('menta', mkMenta()),
  ('silla mano', mkSillaMano()),
  ('beep', mkBeep()),
  ('plato flan', mkPlatoFlan()),
  ('vaso mantecado', mkVasoMantecado()),
  ('guagua puerta', mkGuaguaPuerta()),
  ('estrellas', mkEstrellasCuenta()),
  ('corazon', mkCorazonCuenta()),
];
