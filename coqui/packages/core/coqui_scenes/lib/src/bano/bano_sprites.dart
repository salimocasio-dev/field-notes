// Sprites that only El baño draws (place 9, La casa, un día entero, scene 2: `bano`; stories 99 to 101):
// - soap bar (`jabon`: 8 × 5, sizes 3, 2, 1)
// - folded towels (`toalla`: 12 × 8, five colours: rojo, azul, blanco, verde, amarillo)
// - toothpaste tube (`tubo`: 5 × 9, 4..0 marks) and frog's tiny brush (`cepillito`: 6 × 4, paste 0..3)
// - shelf toothbrush (`cepillo`: 12 × 6, with or without paste) and comb (`peinilla`: 12 × 6)
// - towel over head (`toallaCab`: 16 × 10), Carmen's step stool (`taburete`: 12 × 7), gauge red bar (`barra`: 8 × 3)
// - raincoat child (`lluvia`), abuelo in robe / combed, mud on hands/face/dog, clean shine, teeth sparkle,
//   paste in hair / comb in mouth, flat hair, shower/tap water streams, steam, bubbles, frog foam levels, mirror frog.
//
// Drawn in the old sprites' way (engine.js Buf + outline, kit.js mkPersona + PIEL/PELO/RP). Every dimension matches
// bano-sheet.json's spot boxes and bano-preview.html's stand-ins.
// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'dart:typed_data';

import 'package:coqui_pixel/coqui_pixel.dart';

int _h(String s) => hexColour(s);
List<int> _hs(List<String> s) => [for (final x in s) hexColour(x)];

Sprite _mk(int w, int h, void Function(Buf b) fn) {
  final b = Buf(w, h);
  fn(b);
  return b.outline().done();
}

Sprite _raw(int w, int h, void Function(Buf b) fn) {
  final b = Buf(w, h);
  fn(b);
  return b.done();
}

/// Colour ramps for the five towel colours (`rojo`, `azul`, `blanco`, `verde`, `amarillo`).
final Map<String, List<int>> BANO_TOWEL_RAMPS = {
  'rojo': _hs(['#8A2A24', '#C8403A', '#EC6050']),
  'azul': _hs(['#1E4FA8', '#3A78D8', '#78B0F6']),
  'blanco': _hs(['#B8B8C8', '#E4E4EA', '#FFFFFF']),
  'verde': _hs(['#2A6A34', '#4A9C4E', '#78C870']),
  'amarillo': _hs(['#B88418', '#E8B830', '#F8E070']),
};

/* ---------- people outfits & pose variants ---------- */

void _hood(Buf b, num X, num tc, num rx, num t) {
  final xi = X.toInt();
  b.ell(X, 11, 9, 9.6, RP.yel);
  b.rect(xi - 8, 12, 3, 9, RP.yel[1]);
  b.rect(xi + 5, 12, 3, 9, RP.yel[0]);
}

/// Raincoat child outfit (`bano-preview.html` `LLUVIA`): yellow coat with hood up.
final Who BANO_LLUVIA = Who(
  nino: true,
  piel: PIEL['b']!,
  pelo: _hs(['#B87A10', '#E0A020', '#F8C838']),
  peinado: 'corto',
  ropa: RP.yel,
  abajo: RP.yel,
  zapato: _h('#3A2414'),
  detalle: _hood,
);

/// Abuelo in bathrobe (`bano.md` Needs: "abuelo in his robe, combed").
final Who BANO_ABUELO_ROBE = Who(
  piel: PIEL['a']!,
  pelo: PELO['blanco']!,
  peinado: 'corto',
  ropa: _hs(['#285896', '#467EC2', '#70A8E8', '#9CCBF5']),
  abajo: _hs(['#285896', '#467EC2', '#70A8E8', '#9CCBF5']),
  zapato: _h('#5A3820'),
  bigote: true,
  detalle: (b, X, tc, rx, t) {
    final xi = X.toInt();
    // White towel over shoulder + robe sash
    b.rect(xi + 2, 18, 4, 8, _h('#F4F4FA'));
    b.rect(xi + 3, 18, 2, 8, _h('#D8DCE8'));
    b.rect(xi - 5, 29, 10, 2, _h('#DCE8F4'));
    b.rect(xi - 1, 20, 2, 24, _h('#1C3C6E'));
  },
);

/// Who map for El baño's cast (`abuelo`, `luis`, `carmen`, `lluvia`).
final Map<String, Who> BANO_WHO = {
  'abuelo': FAM['abuelo']!,
  'abuelo_bata': BANO_ABUELO_ROBE,
  'luis': FAM['hermano']!,
  'carmen': FAM['hermana']!,
  'lluvia': BANO_LLUVIA,
};

/// Draws a character of El baño (`abuela`, `abuelo`, `abuelo_bata`, `luis`, `carmen`, `lluvia`) with optional
/// mud/shine/teeth/combing/paste-in-hair overlays strictly inside the sprite's width so spacing rules hold.
Sprite mkBanoPersona(
  String id,
  String pose, {
  bool open = false,
  bool mudHands = false,
  bool mudFace = false,
  bool shine = false,
  bool teeth = false,
  bool flatHair = false,
  bool pasteHair = false,
  bool combMouth = false,
  bool holdingTowel = false,
  bool smellFace = false,
}) {
  final Sprite base = id == 'abuela'
      ? mkAbuela(pose, open)
      : mkPersona(BANO_WHO[id] ?? FAM['hermano']!, pose, open, false);

  if (!mudHands &&
      !mudFace &&
      !shine &&
      !teeth &&
      !flatHair &&
      !pasteHair &&
      !combMouth &&
      !holdingTowel &&
      !smellFace) {
    return base;
  }

  final px = Uint32List.fromList(base.px);
  final w = base.w, h = base.h;
  void setPx(int x, int y, int col) {
    if (x >= 0 && x < w && y >= 0 && y < h) px[y * w + x] = col;
  }

  final cx = id == 'abuela' ? 30 : PX;
  final faceY = id == 'abuela' ? 13 : 11;
  final mud = _h('#6E4220');
  final mudD = _h('#4A2A14');
  final hi = _h('#FFFFFF');

  if (mudHands) {
    // Mud spots on hands (raised for `yo`, or at sides)
    final handY = pose == 'yo' ? 23 : 30;
    for (final hx in [cx - 7, cx + 6]) {
      setPx(hx, handY, mud);
      setPx(hx + 1, handY + 1, mudD);
      setPx(hx, handY + 1, mud);
    }
  }
  if (mudFace) {
    // Mud smudges on cheeks and nose
    setPx(cx - 3, faceY + 2, mud);
    setPx(cx - 2, faceY + 3, mudD);
    setPx(cx + 2, faceY + 2, mud);
    setPx(cx, faceY + 1, mudD);
  }
  if (shine) {
    // Bright sparkle dots near cheek/hands (within sprite bounds)
    setPx(cx - 4, faceY - 2, hi);
    setPx(cx + 4, faceY + 1, hi);
    setPx(cx - 6, 22, hi);
  }
  if (teeth) {
    // Big bright grin across mouth
    final rim = _h('#181820');
    for (var dx = -2; dx <= 2; dx++) {
      setPx(cx + dx, faceY + 3, rim);
      setPx(cx + dx, faceY + 4, hi);
      setPx(cx + dx, faceY + 5, rim);
    }
  }
  if (flatHair) {
    // Neatly parted flat hair crown
    final hair = (BANO_WHO[id] ?? FAM['hermano']!).pelo;
    for (var dx = -4; dx <= 4; dx++) {
      setPx(cx + dx, 4, hair[2]);
      setPx(cx + dx, 5, hair[1]);
    }
    setPx(cx, 4, hi);
  }
  if (pasteHair) {
    // Green mint toothpaste glob on head/hair
    setPx(cx - 1, 5, _h('#58B058'));
    setPx(cx, 5, _h('#84E084'));
    setPx(cx + 1, 6, _h('#58B058'));
    setPx(cx, 6, hi);
  }
  if (combMouth) {
    // Orange comb sticking sideways at mouth
    final comb = _h('#D8683A');
    final combH = _h('#F2A650');
    for (var dx = 0; dx < 7; dx++) {
      setPx(cx + dx, faceY + 3, combH);
      setPx(cx + dx, faceY + 4, comb);
    }
  }
  if (smellFace) {
    // Wrinkled nose expression when smelling dirty green towel
    final dark = _h('#181018');
    setPx(cx - 2, faceY + 1, dark);
    setPx(cx + 1, faceY + 1, dark);
    setPx(cx - 1, faceY + 4, dark);
    setPx(cx, faceY + 3, dark);
    setPx(cx + 1, faceY + 4, dark);
  }
  if (holdingTowel) {
    // Green and yellow folded towels over abuela's forearm (within her 48px width)
    setPx(cx - 9, 25, _h('#4A9C4E'));
    setPx(cx - 8, 25, _h('#78C870'));
    setPx(cx - 9, 26, _h('#2A6A34'));
    setPx(cx - 8, 26, _h('#4A9C4E'));
    setPx(cx - 7, 25, _h('#E8B830'));
    setPx(cx - 6, 25, _h('#F8E070'));
    setPx(cx - 7, 26, _h('#B88418'));
    setPx(cx - 6, 26, _h('#E8B830'));
  }

  return Sprite(w, h, px);
}

/// Canelo (`mkPerro('stand', ...)`), optionally with mud patches on his coat.
Sprite mkBanoPerro(int frame, {bool muddy = false}) {
  final base = mkPerro('stand', frame != 0);
  if (!muddy) return base;
  final px = Uint32List.fromList(base.px);
  final mud = _h('#5A3418');
  final mudD = _h('#3C200E');
  for (final p in const [
    [10, 10],
    [11, 10],
    [15, 11],
    [16, 12],
    [19, 10],
    [8, 13],
  ]) {
    final i = p[1] * base.w + p[0];
    if (i >= 0 && i < px.length && px[i] >>> 24 != 0) {
      px[i] = (p[0] + p[1]).isEven ? mud : mudD;
    }
  }
  return Sprite(base.w, base.h, px);
}

/// Frog with optional muddy feet or foam levels in sink (`foam`: 0..3).
Sprite mkBanoCoqui(
  int anim, {
  int f = 0,
  bool muddyFeet = false,
  int foam = 0,
}) {
  final base = mkCoqui(1, f, anim != 0);
  if (!muddyFeet && foam <= 0) return base;
  final px = Uint32List.fromList(base.px);
  final w = base.w, h = base.h;
  void setPx(int x, int y, int col) {
    if (x >= 0 && x < w && y >= 0 && y < h && px[y * w + x] >>> 24 != 0) {
      px[y * w + x] = col;
    }
  }

  if (muddyFeet) {
    final mud = _h('#6E4220');
    final mudD = _h('#4A2A14');
    for (var x = 8; x <= 23; x++) {
      setPx(x, 22, mud);
      setPx(x, 23, mudD);
    }
  }
  if (foam >= 3) {
    // Foam hat on top of head (inside frog's 32x27 canvas)
    final fm = _h('#F4FAFF');
    final fmD = _h('#CBE4F4');
    for (var x = 11; x <= 20; x++) {
      px[2 * w + x] = fmD;
      px[3 * w + x] = fm;
      px[4 * w + x] = fm;
    }
    for (var x = 13; x <= 18; x++) {
      px[1 * w + x] = fm;
    }
  }
  return Sprite(w, h, px);
}

/* ---------- small things (bano-preview.html exact sizes & anchors) ---------- */

/// Bar of soap (`jabon`): 8 × 5, size [n] = 3 (full), 2 (half), 1 (sliver).
Sprite mkJabon(int n) => _mk(8, 5, (b) {
  if (n >= 3) {
    b.rect(1, 1, 6, 3, _h('#9CD8EC'));
    b.rect(1, 1, 6, 1, _h('#D8F2FA'));
    b.px(2, 2, _h('#FFFFFF'));
  } else if (n == 2) {
    b.rect(2, 2, 4, 2, _h('#9CD8EC'));
    b.rect(2, 2, 4, 1, _h('#D8F2FA'));
  } else {
    b.rect(3, 3, 2, 1, _h('#D8F2FA'));
  }
});

/// Folded towel (`toalla_a` / `toalla_b`): 12 × 8, two stripes.
Sprite mkToalla(String color) {
  final c = BANO_TOWEL_RAMPS[color] ?? BANO_TOWEL_RAMPS['rojo']!;
  return _mk(12, 8, (b) {
    b.rect(1, 1, 10, 6, c[1]);
    b.rect(1, 1, 10, 1, c[2]);
    b.rect(1, 5, 10, 1, c[0]);
    b.rect(1, 3, 10, 1, c[2]);
  });
}

/// Tube of toothpaste (`tubo`): 5 × 9, [n] = 4..0 squeeze marks left.
Sprite mkTubo(int n) => _mk(5, 9, (b) {
  b.rect(1, 1, 3, 2, _h('#D0403A'));
  b.rect(1, 3, 3, 5, _h('#F6F6FA'));
  b.rect(1, 5, 3, 1, _h('#4A8CE8'));
  b.rect(1, 7, 3, 1, _h('#B8B8C8'));
  // Show remaining squeeze level as subtle stripe marks on body
  if (n <= 3) b.px(2, 7, _h('#9098AC'));
  if (n <= 2) b.px(2, 6, _h('#9098AC'));
  if (n <= 1) b.px(2, 4, _h('#9098AC'));
});

/// Frog's tiny toothbrush (`cepillito`): 6 × 4, [paste] = 0 (plain), 1 (dot), 2 (stripe), 3 (fat stripe).
Sprite mkCepillito({int paste = 0}) => _mk(6, 4, (b) {
  b.rect(1, 2, 3, 1, _h('#4A8CE8'));
  b.rect(4, 1, 1, 1, _h('#F6F6FA'));
  b.rect(3, 1, 1, 1, _h('#F6F6FA'));
  b.px(4, 2, _h('#F6F6FA'));
  if (paste == 1) {
    b.px(4, 1, _h('#58B058'));
  } else if (paste == 2) {
    b.rect(3, 1, 2, 1, _h('#58B058'));
  } else if (paste >= 3) {
    b.rect(2, 1, 3, 1, _h('#58B058'));
    b.px(3, 0, _h('#84E084'));
  }
});

/// Toothbrush on shelf (`cepillo`): 12 × 6, with or without squeeze of paste.
Sprite mkCepillo({bool paste = true}) => _mk(12, 6, (b) {
  b.rect(1, 3, 6, 2, _h('#4A8CE8'));
  b.rect(6, 1, 5, 3, _h('#F6F6FA'));
  if (paste) {
    b.rect(7, 1, 3, 1, _h('#58B058'));
    b.rect(7, 2, 3, 1, _h('#F6F6FA'));
  }
});

/// Comb on shelf (`peinilla`): 12 × 6.
Sprite mkPeinilla() => _mk(12, 6, (b) {
  b.rect(1, 1, 10, 2, _h('#D8683A'));
  for (var x = 2; x <= 9; x += 2) {
    b.rect(x, 3, 1, 2, _h('#D8683A'));
  }
  b.rect(1, 1, 10, 1, _h('#F2A650'));
});

/// Towel over child's head (`toallaCab`): 16 × 10.
Sprite mkToallaCab() => _mk(16, 10, (b) {
  b.rect(1, 1, 14, 8, _h('#F6F6FA'));
  b.rect(1, 1, 14, 1, _h('#FFFFFF'));
  b.rect(1, 3, 14, 1, _h('#78B0F6'));
  b.rect(1, 8, 14, 1, _h('#B8B8C8'));
});

/// Small stool under Carmen (`taburete`): 12 × 7, its top row on her feet's row.
Sprite mkTabureteBano() => _mk(12, 7, (b) {
  b.rect(1, 1, 10, 2, _h('#D8A460'));
  b.rect(1, 1, 10, 1, _h('#F2C888'));
  b.rect(2, 3, 2, 4, _h('#92602E'));
  b.rect(8, 3, 2, 4, _h('#92602E'));
  b.rect(4, 4, 4, 1, _h('#B88040'));
});

/// One red bar of the heater gauge (`barra`): 8 × 3, no outline (the set's gauge is dark).
Sprite mkBarraGauge() => _raw(8, 3, (b) {
  b.rect(0, 0, 8, 2, _h('#E24A3C'));
  b.rect(0, 0, 8, 1, _h('#FA8070'));
  b.rect(0, 2, 8, 1, _h('#8A2A24'));
});

/* ---------- water, steam, bubbles, foam, mirror reflection ---------- */

/// Shower water stream falling from shower head (`14 × 20`, animated).
Sprite mkAguaDucha(int frame) => _raw(14, 20, (b) {
  final c1 = _h('#9CD8F8'), c2 = _h('#DCEEFF');
  final off = frame % 3;
  for (var y = 0; y < 20; y++) {
    if ((y + off) % 3 == 0) continue;
    b.px(2 + (y ~/ 6), y, y.isEven ? c1 : c2);
    b.px(6, y, y.isOdd ? c1 : c2);
    b.px(10 - (y ~/ 6), y, y.isEven ? c2 : c1);
  }
});

/// Sink tap water stream (`4 × 10`, animated).
Sprite mkAguaLlave(int frame) => _raw(4, 10, (b) {
  final c1 = _h('#8CCCF4'), c2 = _h('#E4F4FF');
  final off = frame % 2;
  for (var y = 0; y < 10; y++) {
    b.px(1, y, (y + off).isEven ? c1 : c2);
    b.px(2, y, (y + off).isOdd ? c1 : c2);
  }
});

/// Gentle steam wisps (`14 × 12`, animated).
Sprite mkVaporBano(int frame) => _raw(14, 12, (b) {
  final c1 = _h('#F4FAFF'), c2 = _h('#C8DCEB');
  final o = frame % 2;
  for (final x in const [3, 7, 11]) {
    b.px(x + o, 9, c2);
    b.px(x - o, 6, c1);
    b.px(x + o, 3, c2);
    b.px(x, 1, c1);
  }
});

/// Soap bubbles floating during washing (`12 × 10`, animated).
Sprite mkBurbujas(int frame) => _raw(12, 10, (b) {
  final rim = _h('#B8E4F8'), hi = _h('#FFFFFF');
  final dy = frame % 2;
  b.ell(3, 3 + dy.toDouble(), 2, 2, [rim, hi]);
  b.ell(8, 6 - dy.toDouble(), 2.2, 2.2, [rim, hi]);
  b.px(5, 1 + dy, hi);
});

/// Foam pile around frog in sink (`24 × 12`, [level] = 1 sliver, 2 chin, 3 mountain).
Sprite mkEspumaSink(int level) => _raw(24, 12, (b) {
  final c0 = _h('#CBE4F4'), c1 = _h('#F4FAFF'), hi = _h('#FFFFFF');
  if (level <= 1) {
    b.ell(6, 9, 2.5, 1.5, [c0, c1]);
    b.ell(18, 9, 2.5, 1.5, [c0, c1]);
    b.px(12, 10, hi);
  } else if (level == 2) {
    b.ell(12, 8, 9, 3.2, [c0, c1, hi]);
    b.ell(6, 7, 4, 2, [c0, c1]);
    b.ell(18, 7, 4, 2, [c0, c1]);
  } else {
    b.ell(12, 7, 11, 4.5, [c0, c1, hi]);
    b.ell(7, 5, 5, 3, [c1, hi]);
    b.ell(17, 5, 5, 3, [c1, hi]);
  }
});

/// Frog reflection inside the mirror (`12 × 10`, clipped to mirror pane).
Sprite mkEspejoCoqui({bool sparkle = false}) => _raw(12, 10, (b) {
  b.ell(6, 6, 4, 3, [_h('#3C9A52'), _h('#68C872')]);
  b.px(4, 4, _h('#FFFFFF'));
  b.px(7, 4, _h('#FFFFFF'));
  b.px(5, 4, _h('#141818'));
  b.px(8, 4, _h('#141818'));
  if (sparkle) {
    b.rect(4, 7, 4, 1, _h('#FFFFFF'));
    b.px(1, 2, _h('#FFFFFF'));
    b.px(10, 2, _h('#FFFFFF'));
  }
});

/// Celebration heart & star overlays (`10 × 10`).
Sprite mkCorazonBano() => _mk(10, 10, (b) {
  final r = _h('#E44A50'), hi = _h('#FF9AA2');
  b.ell(3.5, 3.5, 2, 2, [r, hi]);
  b.ell(6.5, 3.5, 2, 2, [r]);
  b.rect(2, 4, 6, 2, r);
  b.rect(3, 6, 4, 1, r);
  b.rect(4, 7, 2, 1, r);
});

Sprite mkEstrellaBano() => _mk(10, 10, (b) {
  final y = _h('#F8D848'), hi = _h('#FFF8B8');
  b.rect(4, 1, 2, 8, y);
  b.rect(1, 4, 8, 2, y);
  b.rect(3, 3, 4, 4, y);
  b.px(4, 3, hi);
});

/// Singing notes over shower (`8 × 8`).
Sprite mkNotasBano(int frame) => _raw(8, 8, (b) {
  final c = _h('#FFFFFF');
  final dy = frame % 2;
  b.rect(2, 2 + dy, 1, 4, c);
  b.rect(2, 2 + dy, 3, 1, c);
  b.rect(1, 5 + dy, 2, 2, c);
  b.px(6, 1 + (1 - dy), _h('#FFE070'));
});

/// Complete catalogue of El baño's own sprites for `tool/make_bano_sprites_test.dart`.
List<(String, Sprite)> banoSpritesSheet() => [
  ('jabon (n=3)', mkJabon(3)),
  ('jabon (n=2)', mkJabon(2)),
  ('jabon (n=1)', mkJabon(1)),
  ('toalla rojo', mkToalla('rojo')),
  ('toalla azul', mkToalla('azul')),
  ('toalla blanco', mkToalla('blanco')),
  ('toalla verde', mkToalla('verde')),
  ('toalla amarillo', mkToalla('amarillo')),
  ('tubo (n=4)', mkTubo(4)),
  ('tubo (n=1)', mkTubo(1)),
  ('cepillito (0)', mkCepillito(paste: 0)),
  ('cepillito (1)', mkCepillito(paste: 1)),
  ('cepillito (2)', mkCepillito(paste: 2)),
  ('cepillito (3)', mkCepillito(paste: 3)),
  ('cepillo (paste)', mkCepillo(paste: true)),
  ('cepillo (clean)', mkCepillo(paste: false)),
  ('peinilla', mkPeinilla()),
  ('toallaCab', mkToallaCab()),
  ('taburete', mkTabureteBano()),
  ('barra', mkBarraGauge()),
  ('agua ducha', mkAguaDucha(0)),
  ('agua llave', mkAguaLlave(0)),
  ('vapor', mkVaporBano(0)),
  ('burbujas', mkBurbujas(0)),
  ('espuma (1)', mkEspumaSink(1)),
  ('espuma (2)', mkEspumaSink(2)),
  ('espuma (3)', mkEspumaSink(3)),
  ('espejo coqui', mkEspejoCoqui(sparkle: true)),
  ('lluvia', mkBanoPersona('lluvia', 'idle')),
  ('abuelo bata', mkBanoPersona('abuelo_bata', 'idle')),
  ('luis yo mud', mkBanoPersona('luis', 'yo', mudHands: true)),
  ('carmen teeth', mkBanoPersona('carmen', 'idle', teeth: true)),
  ('luis flat hair', mkBanoPersona('luis', 'idle', flatHair: true)),
  ('carmen paste hair', mkBanoPersona('carmen', 'idle', pasteHair: true)),
  ('luis comb mouth', mkBanoPersona('luis', 'idle', combMouth: true)),
  ('abuela towels', mkBanoPersona('abuela', 'idle', holdingTowel: true)),
  ('perro muddy', mkBanoPerro(0, muddy: true)),
  ('coqui muddy', mkBanoCoqui(0, muddyFeet: true)),
  ('coqui foam hat', mkBanoCoqui(0, foam: 3)),
];
