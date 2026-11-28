// Scene-specific sprites and character outfits of La entrada (place 8, La fonda, scene 1: `entrada`, order 66):
// - Character outfits matching entrada-preview.html (`ENTRADA_PEOPLE`: abuelo, luis, carmen, senor, senora, hombre,
//   mujer, joven, mesera with white apron + optional pencil/pad, mesero with/without bowtie + optional bandaged foot
//   and cane for story 85, vecino, vecina, plus amigo companion for joven in story 85).
// - Preview-matching props with exact dimensions from entrada-preview.html & entrada-sheet.json:
//   flores (10 x 12), estrella (8 x 10), platos (16 x 18), bandejaT (30 x 3), vela (6 x 10), cosaAgua (10 x 12),
//   cosaPan (10 x 12), menu (14 x 12), dulces (12 x 8), taburete (14 x 14), mantel (w x h in 5 colours).
// - Additional Needs sprites from historia/notas/guiones/entrada.md:
//   cafe (black / pale with milk), vasito (small glass with lemon for Coquí), panera (bread basket), salpicadura
//   (splash FX), corbata (frog's bow tie), notasMusica (vellonera music notes), corazon (3-of-3 heart), sombrero
//   (abuelo's hat for final84 n=1), bandejaLlena (mesero crossing with full tray), puertaViento (swing-door swoosh).
// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'package:coqui_pixel/coqui_pixel.dart';

int _h(String s) => hexColour(s);

List<int> _ramp(List<String> hs) => [for (final s in hs) _h(s)];

int _rgb(int r, int g, int b) =>
    (0xFF << 24) |
    (b.clamp(0, 255) << 16) |
    (g.clamp(0, 255) << 8) |
    r.clamp(0, 255);

Sprite _mk(int w, int h, void Function(Buf b) draw, {bool outline = true}) {
  final b = Buf(w, h);
  draw(b);
  return outline ? b.outline().done() : b.done();
}

/* ---------- character outfits (entrada-preview.html PEOPLE) ---------- */

final List<int> _whiteApron = _ramp(const [
  '#C8C8D0',
  '#E4E4EA',
  '#F6F6FA',
  '#FFFFFF',
]);

void _drawApron(Buf b, num X, {bool pad = false}) {
  final x = X.toInt();
  final G = _whiteApron;
  b.rect(x - 4, 18, 1, 4, G[1]);
  b.rect(x + 3, 18, 1, 4, G[1]);
  b.rect(x - 5, 22, 10, 24, G[2]);
  b.rect(x - 5, 22, 2, 24, G[3]);
  b.rect(x + 3, 22, 2, 24, G[1]);
  b.rect(x - 5, 45, 10, 1, G[0]);
  b.rect(x - 5, 22, 10, 1, G[3]);
  b.rect(x - 3, 34, 6, 4, G[1]);
  b.rect(x - 3, 34, 6, 1, G[3]);
  if (pad) {
    // Small notepad tucked in apron pocket + pencil tip (stays inside existing apron silhouette)
    b.rect(x - 2, 33, 4, 4, _h('#FFFBEA'));
    b.rect(x - 2, 33, 4, 1, _h('#B89A6A'));
    b.px(x + 2, 33, _h('#F8C838'));
  }
}

void _drawBowtie(Buf b, num X) {
  final x = X.toInt();
  b.rect(x - 3, 20, 6, 2, _h('#32323E'));
  b.px(x, 20, _h('#6E6E80'));
  b.px(x, 21, _h('#6E6E80'));
}

/// Mesera outfit (entrada-preview.html `PEOPLE.mesera`): red top, white apron, optional pad in pocket.
Who mkMeseraWho({bool pad = false}) => Who(
  piel: PIEL['b']!,
  pelo: PELO['negro']!,
  peinado: 'largo',
  ropa: RP.red,
  falda: true,
  zapato: _h('#3A2414'),
  detalle: (b, X, tc, rx, t) => _drawApron(b, X, pad: pad),
);

/// Mesero outfit (entrada-preview.html `PEOPLE.mesero`): orange shirt, stone pants, mustache, optional bow tie,
/// bandaged foot, and walking stick (story 85).
Who mkMeseroWho({
  bool bowtie = true,
  bool bandage = false,
  bool cane = false,
}) => Who(
  piel: PIEL['a']!,
  pelo: PELO['negro']!,
  peinado: 'corto',
  ropa: RP.orng,
  abajo: RP.stone,
  bigote: true,
  detalle: (b, X, tc, rx, t) {
    final x = X.toInt();
    if (bowtie) _drawBowtie(b, X);
    if (bandage) {
      // White bandage wrap around right foot/ankle (sits on top of leg/shoe rows 42..46)
      b.rect(x + 1, 42, 5, 4, _h('#F6F6FA'));
      b.rect(x + 1, 43, 5, 1, _h('#C8C8D4'));
      b.rect(x + 2, 45, 4, 1, _h('#E4E4EA'));
    }
    if (cane) {
      // Wooden walking stick along right side (stays within 48 px sprite width)
      b.rect(x + 10, 26, 2, 20, _h('#7A4A1E'));
      b.rect(x + 9, 25, 4, 2, _h('#B88040'));
    }
  },
);

/// Every character outfit in La entrada (matching `entrada-preview.html` `PEOPLE` plus `amigo` for story 85).
final Map<String, Who> ENTRADA_PEOPLE = {
  'abuelo': FAM['abuelo']!,
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
  'hombre': Who(
    piel: PIEL['b']!,
    pelo: PELO['negro']!,
    peinado: 'corto',
    ropa: RP.blue,
    abajo: RP.grey,
  ),
  'mujer': Who(
    piel: PIEL['c']!,
    pelo: PELO['negro']!,
    peinado: 'largo',
    ropa: RP.yel,
    falda: true,
    zapato: _h('#7A4A10'),
  ),
  'joven': Who(
    piel: PIEL['b']!,
    pelo: PELO['castano']!,
    peinado: 'corto',
    ropa: RP.cream.sublist(1),
    abajo: RP.blue,
    zapato: _h('#F2F2F8'),
  ),
  'mesera': mkMeseraWho(),
  'mesero': mkMeseroWho(),
  'vecino': Who(
    piel: PIEL['c']!,
    pelo: PELO['negro']!,
    peinado: 'corto',
    ropa: RP.purp,
    abajo: RP.stone,
  ),
  'vecina': Who(
    piel: PIEL['a']!,
    pelo: PELO['castano']!,
    peinado: 'largo',
    ropa: RP.teal,
    falda: true,
    zapato: _h('#F2F2F8'),
  ),
  // Companion for joven in story 85 ("the joven comes in with a friend").
  'amigo': Who(
    piel: PIEL['a']!,
    pelo: PELO['negro']!,
    peinado: 'corto',
    ropa: RP.grn,
    abajo: RP.wood,
    zapato: _h('#3A2414'),
  ),
};

/* ---------- entrada-preview.html core props (exact box dimensions) ---------- */

final List<int> _glass = _ramp(const ['#9CCBDE', '#BCE4F4', '#DDF1FA']);

/// Flowers in a small vase: 10 x 12 (entrada-preview.html `THING.flores`, matches `spots.flores`).
Sprite mkFlores() => _mk(10, 12, (b) {
  b.rect(3, 8, 4, 4, _h('#4A8CE8'));
  b.rect(3, 8, 4, 1, _h('#B0D4FF'));
  b.ell(3.5, 4, 2, 2, _ramp(const ['#EC6050', '#FA9080']));
  b.ell(6.5, 3.5, 2, 2, _ramp(const ['#F8C838', '#FFF4B0']));
  b.ell(5, 2, 1.8, 1.8, [_h('#FFFFFF')]);
  b.px(3, 3, _h('#FFE070'));
  b.line(5, 6, 5, 8, _h('#389838'));
});

/// Small card with a star: 8 x 10 (entrada-preview.html `THING.estrella`, matches `spots.tarjeta`).
Sprite mkEstrella() => _mk(8, 10, (b) {
  b.rect(0, 0, 8, 10, _h('#FFFBEA'));
  b.frame(0, 0, 8, 10, _h('#B89A6A'));
  b.px(4, 2, _h('#F8C838'));
  b.rect(3, 3, 3, 1, _h('#F8C838'));
  b.rect(2, 4, 5, 1, _h('#F8C838'));
  b.rect(3, 5, 3, 1, _h('#F8C838'));
  b.px(3, 6, _h('#F8C838'));
  b.px(5, 6, _h('#F8C838'));
});

/// Mesero's tall pile of plates: 16 x 18 (entrada-preview.html `THING.platos`, matches `standins.platos`).
Sprite mkPlatos() => _mk(16, 18, (b) {
  for (var k = 0; k < 5; k++) {
    b.rect(1, 2 + k * 3, 14, 3, k % 2 != 0 ? _h('#F2F2F8') : _h('#FFFFFF'));
    b.rect(1, 4 + k * 3, 14, 1, _h('#9CCBDE'));
  }
  b.rect(3, 0, 10, 2, _h('#FFFFFF'));
});

/// Mesero's tray: 30 x 3, anchor (15, 0) (entrada-preview.html `THING.bandejaT`, matches `standins.bandeja`).
Sprite mkBandejaT() => _mk(30, 3, (b) {
  b.rect(1, 0, 28, 1, _h('#F2F2F8'));
  b.rect(1, 1, 28, 1, _h('#B8B8C8'));
});

/// Candle in a glass cup: 6 x 10 (entrada-preview.html `THING.vela`, matches `spots.velas.parts`).
Sprite mkVela({bool lit = true, bool smoke = false}) => _mk(6, 10, (b) {
  if (lit) {
    b.rect(2, 1, 2, 2, _h('#FFE070'));
    b.px(2, 0, _h('#FA9080'));
    b.px(3, 0, _h('#FA9080'));
  } else {
    b.px(2, 2, _h('#4A4A54'));
    if (smoke) {
      b.px(2, 1, _h('#C8D8E8'));
      b.px(3, 0, _h('#E8F0F8'));
    } else {
      b.px(3, 1, _h('#B0B4C0'));
    }
  }
  b.rect(1, 3, 4, 6, _glass[1]);
  b.rect(1, 3, 1, 6, _glass[2]);
  b.rect(2, 4, 2, 4, _h('#FBF0D2'));
  b.rect(1, 8, 4, 1, _glass[0]);
});

/// Glass of water: 10 x 12 (entrada-preview.html `THING.cosaA` when [con], `THING.cosaB` when ![con]).
Sprite mkCosaAgua({required bool con}) => _mk(10, 12, (b) {
  b.rect(2, 2, 6, 9, _glass[1]);
  b.rect(2, 2, 1, 9, _glass[2]);
  b.rect(3, 4, 4, 6, _h('#DDF1FA'));
  if (con) {
    // Small green island lemon slice on the rim
    b.rect(7, 0, 3, 3, _h('#78B050'));
    b.rect(8, 1, 1, 1, _h('#B8E088'));
  }
  b.rect(2, 10, 6, 1, _glass[0]);
});

/// Small plate of bread: 10 x 12, with a pat of butter when [con] is true, plain bread when false.
Sprite mkCosaPan({required bool con}) => _mk(10, 12, (b) {
  // Small plate at bottom
  b.rect(1, 9, 8, 2, _h('#F2F2F8'));
  b.rect(2, 10, 6, 1, _h('#B8B8C8'));
  // Slice of crusty bread
  b.rect(2, 4, 6, 5, _h('#D49A52'));
  b.rect(2, 4, 6, 1, _h('#9C6428'));
  b.rect(3, 5, 4, 4, _h('#F4E2B8'));
  if (con) {
    // Golden pat of butter on top of the slice
    b.rect(4, 3, 3, 3, _h('#F8C838'));
    b.rect(4, 3, 2, 1, _h('#FFF2A0'));
  }
});

/// Menu card: 14 x 12 (entrada-preview.html `THING.menu` when [open] is true, closed cover when false).
Sprite mkMenu({bool open = false}) => _mk(14, 12, (b) {
  if (open) {
    b.rect(0, 0, 14, 12, _h('#FFFBEA'));
    b.frame(0, 0, 14, 12, _h('#B89A6A'));
    b.rect(6, 1, 2, 10, _h('#B89A6A'));
    b.rect(2, 3, 3, 4, _h('#F2A650'));
    b.rect(9, 3, 3, 4, _h('#78B0F6'));
    b.rect(2, 8, 3, 2, _h('#D0403A'));
    b.rect(9, 8, 3, 2, _h('#389838'));
  } else {
    b.rect(2, 0, 10, 12, _h('#9E3430'));
    b.frame(2, 0, 10, 12, _h('#6E1E1C'));
    b.rect(3, 1, 1, 10, _h('#C8544E'));
    b.rect(5, 3, 5, 2, _h('#F8C838'));
    b.rect(6, 6, 3, 3, _h('#FFFBEA'));
  }
});

/// Saucer with [n] (0..3) wrapped sweets: 12 x 8 (entrada-preview.html `THING.dulces` for n=3).
Sprite mkDulces(int n) {
  final count = n.clamp(0, 3);
  return _mk(12, 8, (b) {
    b.ell(6, 5.5, 5.4, 1.6, _ramp(const ['#D8D8E4', '#F2F2F8']));
    b.rect(1, 5, 10, 1, _h('#B8B8C8'));
    if (count >= 1) {
      b.rect(2, 2, 2, 3, _h('#D0403A'));
      b.px(1, 3, _h('#D0403A'));
      b.px(4, 3, _h('#D0403A'));
    }
    if (count >= 2) {
      b.rect(5, 1, 2, 4, _h('#F8C838'));
      b.px(4, 2, _h('#F8C838'));
      b.px(7, 2, _h('#F8C838'));
    }
    if (count >= 3) {
      b.rect(8, 2, 2, 3, _h('#4A8CE8'));
      b.px(7, 3, _h('#4A8CE8'));
      b.px(10, 3, _h('#4A8CE8'));
    }
  });
}

/// Mesero's wooden stool: 14 x 14 (entrada-preview.html `THING.taburete`, matches `standins.taburete`).
Sprite mkTaburete() => _mk(14, 14, (b) {
  b.rect(1, 1, 12, 3, _h('#B88040'));
  b.rect(1, 1, 12, 1, _h('#D8A460'));
  b.rect(2, 4, 2, 10, _h('#6E4220'));
  b.rect(10, 4, 2, 10, _h('#6E4220'));
  b.rect(6, 4, 2, 9, _h('#92602E'));
  b.rect(2, 9, 10, 1, _h('#6E4220'));
});

/// Table cloth colours supported in story 85 (`rojo`, `azul`, `verde`, `amarillo`, `blanco`).
const Map<String, List<int>> ENTRADA_CLOTH_COLORS = {
  'rojo': [196, 60, 54],
  'azul': [52, 96, 190],
  'verde': [58, 148, 86],
  'amarillo': [224, 180, 56],
  'blanco': [236, 232, 224],
};

/// Cloth over a table: [w] x [h] with [topRows] rows of table top and front hem below (entrada-preview.html `cloth`).
Sprite mkMantel(int w, int h, int topRows, String color) {
  final col = ENTRADA_CLOTH_COLORS[color] ?? ENTRADA_CLOTH_COLORS['blanco']!;
  int k(int d) => _rgb(col[0] + d, col[1] + d, col[2] + d);
  final b = Buf(w, h);
  b.rect(0, 0, w, topRows, k(14));
  b.rect(0, 0, w, 1, k(34));
  b.rect(0, 0, 1, topRows, k(26));
  b.rect(w - 1, 0, 1, topRows, k(-8));
  b.rect(0, topRows, w, h - topRows, k(-18));
  b.rect(0, topRows, w, 1, k(-4));
  for (var x = 6; x < w - 3; x += 9) {
    b.rect(x, topRows + 1, 1, h - topRows - 1, k(-34));
  }
  b.rect(0, h - 1, w, 1, k(-44));
  return b.done();
}

/* ---------- Additional Needs sprites (entrada.md) ---------- */

/// Coffee cup on saucer: 8 x 8. Pale café con leche when [conLeche], dark black coffee when false.
Sprite mkCafe({required bool conLeche}) => _mk(8, 8, (b) {
  b.rect(1, 6, 6, 1, _h('#E4E4EA'));
  b.rect(2, 3, 4, 3, _h('#FFFFFF'));
  b.rect(6, 4, 1, 2, _h('#D8D8E4'));
  b.rect(2, 2, 4, 2, conLeche ? _h('#D2A474') : _h('#3A2218'));
  b.px(3, 0, _h('#E8F0F8'));
  b.px(4, 1, _h('#E8F0F8'));
});

/// Small water glass with green lemon slice for Coquí (story 86 `vasito86`): 7 x 9.
Sprite mkVasito() => _mk(7, 9, (b) {
  b.rect(1, 2, 5, 6, _glass[1]);
  b.rect(1, 2, 1, 6, _glass[2]);
  b.rect(2, 3, 3, 4, _h('#DDF1FA'));
  b.rect(4, 0, 3, 3, _h('#78B050'));
  b.px(5, 1, _h('#B8E088'));
  b.rect(1, 7, 5, 1, _glass[0]);
});

/// Woven basket of warm bread (story 86 `final86`): 14 x 10.
Sprite mkPanera() => _mk(14, 10, (b) {
  b.rect(1, 5, 12, 4, _h('#B88040'));
  b.rect(2, 5, 10, 1, _h('#D8A460'));
  for (var x = 2; x < 12; x += 2) {
    b.px(x, 7, _h('#7A4A1E'));
  }
  b.ell(4, 4, 2.5, 2, _ramp(const ['#C88A40', '#F0C878']));
  b.ell(7, 3.5, 2.6, 2.2, _ramp(const ['#C88A40', '#F4D488']));
  b.ell(10, 4, 2.5, 2, _ramp(const ['#C88A40', '#F0C878']));
});

/// Water splash droplets when a wrong item is snatched back (story 86 `da86 ok=0`): 12 x 8.
Sprite mkSalpicadura(int frame) {
  final b = Buf(12, 8);
  final c1 = _h('#BCE4F4');
  final c2 = _h('#FFFFFF');
  if (frame % 2 == 0) {
    b.rect(4, 4, 4, 2, c1);
    b.px(2, 2, c1);
    b.px(3, 3, c2);
    b.px(9, 2, c1);
    b.px(8, 3, c2);
    b.px(6, 1, c2);
  } else {
    b.px(1, 1, c1);
    b.px(3, 2, c2);
    b.px(5, 0, c1);
    b.px(8, 2, c2);
    b.px(10, 1, c1);
    b.rect(3, 5, 6, 1, c1);
  }
  return b.done();
}

/// Frog's little dark bow tie (story 85 `corbata85`): 8 x 5.
Sprite mkCorbata() => _mk(8, 5, (b) {
  b.rect(1, 1, 2, 3, _h('#32323E'));
  b.rect(5, 1, 2, 3, _h('#32323E'));
  b.rect(3, 2, 2, 1, _h('#6E6E80'));
});

/// Musical notes floating from the vellonera (story 85 `final85`): 14 x 10.
Sprite mkNotasMusica(int frame) => _mk(14, 10, (b) {
  final dy = frame % 2 == 0 ? 0 : -1;
  final c = _h('#FFF2A0');
  b.rect(2, 6 + dy, 2, 2, c);
  b.line(3, 6 + dy, 3, 2 + dy, c);
  b.line(3, 2 + dy, 7, 1 + dy, c);
  b.rect(6, 5 - dy, 2, 2, c);
  b.line(7, 5 - dy, 7, 1 + dy, c);
  b.rect(10, 4 + dy, 2, 2, _h('#B8E4FF'));
  b.line(11, 4 + dy, 11, 1 + dy, _h('#B8E4FF'));
});

/// Celebration heart for 3-of-3 endings: 11 x 10.
Sprite mkCorazon() => _mk(11, 10, (b) {
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

/// Straw hat held by abuelo when the kitchen swing door flaps (story 84 `final84 n=1`): 14 x 8.
Sprite mkSombrero() => _mk(14, 8, (b) {
  b.rect(1, 5, 12, 2, _h('#E4C47C'));
  b.rect(3, 1, 8, 4, _h('#F0D48C'));
  b.rect(3, 4, 8, 1, _h('#8A3A2E'));
  b.rect(4, 1, 6, 1, _h('#FFF2C0'));
});

/// Mesero's full tray during story 84 crossing (`pasa84 que=bandeja`): 20 x 12.
Sprite mkBandejaLlena() => _mk(20, 12, (b) {
  b.rect(1, 9, 18, 2, _h('#B8B8C8'));
  b.rect(1, 9, 18, 1, _h('#F2F2F8'));
  // Two glasses + bowl on tray
  b.rect(3, 3, 4, 6, _glass[1]);
  b.rect(4, 4, 2, 4, _h('#DDF1FA'));
  b.rect(9, 4, 5, 5, _h('#FFFBEA'));
  b.rect(10, 3, 3, 2, _h('#D49A52'));
  b.rect(15, 3, 3, 6, _glass[1]);
  b.rect(16, 4, 1, 4, _h('#F2A650'));
});

/// All La entrada sprites with names for the content lane's sprite sheet (`tool/make_entrada_sprites_test.dart`).
List<(String, Sprite)> entradaSpritesSheet() => [
  ('mesera', mkPersona(mkMeseraWho(), 'idle', false, false)),
  ('mesera pad', mkPersona(mkMeseraWho(pad: true), 'idle', false, false)),
  ('mesero', mkPersona(mkMeseroWho(), 'idle', false, false)),
  (
    'mesero 85',
    mkPersona(
      mkMeseroWho(bowtie: false, bandage: true, cane: true),
      'idle',
      false,
      true,
    ),
  ),
  ('vecino', mkPersona(ENTRADA_PEOPLE['vecino']!, 'idle', false, false)),
  ('vecina', mkPersona(ENTRADA_PEOPLE['vecina']!, 'idle', false, false)),
  ('amigo', mkPersona(ENTRADA_PEOPLE['amigo']!, 'idle', false, false)),
  ('flores', mkFlores()),
  ('estrella', mkEstrella()),
  ('platos', mkPlatos()),
  ('bandeja T', mkBandejaT()),
  ('bandeja llena', mkBandejaLlena()),
  ('vela lit', mkVela(lit: true)),
  ('vela out', mkVela(lit: false)),
  ('vela smoke', mkVela(lit: false, smoke: true)),
  ('agua con', mkCosaAgua(con: true)),
  ('agua sin', mkCosaAgua(con: false)),
  ('pan con', mkCosaPan(con: true)),
  ('pan sin', mkCosaPan(con: false)),
  ('menu cerrado', mkMenu(open: false)),
  ('menu abierto', mkMenu(open: true)),
  ('dulces 3', mkDulces(3)),
  ('dulces 2', mkDulces(2)),
  ('dulces 1', mkDulces(1)),
  ('dulces 0', mkDulces(0)),
  ('taburete', mkTaburete()),
  ('mantel rojo', mkMantel(57, 24, 15, 'rojo')),
  ('mantel azul', mkMantel(57, 24, 15, 'azul')),
  ('mantel verde', mkMantel(57, 24, 15, 'verde')),
  ('mantel amarillo', mkMantel(57, 24, 15, 'amarillo')),
  ('mantel blanco', mkMantel(57, 24, 15, 'blanco')),
  ('cafe con leche', mkCafe(conLeche: true)),
  ('cafe negro', mkCafe(conLeche: false)),
  ('vasito', mkVasito()),
  ('panera', mkPanera()),
  ('salpicadura 0', mkSalpicadura(0)),
  ('salpicadura 1', mkSalpicadura(1)),
  ('corbata', mkCorbata()),
  ('notas musica', mkNotasMusica(0)),
  ('corazon', mkCorazon()),
  ('sombrero', mkSombrero()),
];
