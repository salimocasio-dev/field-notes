// Sprites that only La comida draws (place 8, La fonda, scene 3: `comida`; stories 90 to 92):
// - small plates of tostones, pineapple slices, small red peppers (`platillo1..3`: 14 × 8)
// - lemonade jar (`jarra`: 12 × 18, levels 3..0) and three glasses with straws (`vasos`: 26 × 10)
// - station shelf items (`sal`, `azucar`, `hielo`, `servilletas`: 10 × 12)
// - soup bowls (`sopa`: 12 × 8, steaming or cold), Carmen's salad (`ensalada`: 12 × 8)
// - frog's small bowl (`tazon`: 10 × 8, 0..3 spoonfuls) and dog's bowl (`plato_perro`: 12 × 8)
// - mesera and cocinero outfits (comida-preview.html), guests (senora, senor, joven, mujer), facial/pose overlays
//   (ojos, cara, rojo, tapa, cuchara), frog props (apron, napkin, big spoon, fire, steam, tongs), rice plate, red sauce
//   bottle, dog variants (looking up, eating, asleep on back).
//
// Drawn in the old sprites' way (engine.js Buf + outline, kit.js mkPersona + PIEL/PELO/RP). Every dimension matches
// comida-sheet.json's spot boxes and comida-preview.html's stand-ins.
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

/* ---------- people outfits (comida-preview.html) ---------- */

final List<int> _WHITE = _hs(['#C8C8D4', '#E8E8F0', '#FFFFFF', '#FFFFFF']);

/// Outfits for La comida's cast (comida-preview.html + Banco.QUIEN['mujer']).
/// Family (`abuelo`, `luis`, `carmen`) use `FAM`; `abuela` uses `mkAbuela` / `mkAbuelaS`.
final Map<String, Who> COMIDA_WHO = {
  'abuelo': FAM['abuelo']!,
  'luis': FAM['hermano']!,
  'carmen': FAM['hermana']!,
  'senora': Who(
    piel: PIEL['a']!,
    pelo: PELO['castano']!,
    peinado: 'corto',
    ropa: RP.grn,
    falda: true,
    zapato: _h('#F2F2F8'),
  ),
  'senor': Who(
    piel: PIEL['a']!,
    pelo: PELO['blanco']!,
    peinado: 'corto',
    ropa: RP.wood,
    abajo: RP.grey,
    bigote: true,
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
  'mesera': Who(
    piel: PIEL['c']!,
    pelo: PELO['negro']!,
    peinado: 'largo',
    ropa: _WHITE,
    falda: true,
    zapato: _h('#3A2414'),
    detalle: (b, X, tc, rx, t) {
      final G = RP.teal;
      b.rect(X - 4, 18, 1, 4, G[1]);
      b.rect(X + 3, 18, 1, 4, G[1]);
      b.rect(X - 5, 22, 10, 22, G[2]);
      b.rect(X - 5, 22, 2, 22, G[3]);
      b.rect(X + 3, 22, 2, 22, G[1]);
      b.rect(X - 5, 43, 10, 1, G[0]);
      b.rect(X - 5, 22, 10, 1, G[3]);
    },
  ),
  'cocinero': Who(
    piel: PIEL['a']!,
    pelo: PELO['negro']!,
    peinado: 'calvo',
    ropa: _WHITE,
    abajo: RP.grey,
    bigote: true,
    detalle: (b, X, tc, rx, t) {
      b.rect(X - 1, 20, 2, 12, RP.grey[1]);
      b.rect(X - 4, 24, 2, 2, RP.red[2]);
      b.rect(X + 2, 24, 2, 2, RP.red[2]);
    },
  ),
};

/// Lap anchor row for a sitting `mkPersona` sprite (comida-sheet.json `rules.anchor`).
int comidaLapRow(String id) {
  if (id == 'abuela') return 36;
  final w = COMIDA_WHO[id];
  final t = (w != null && w.nino) ? 7 : 11;
  return 16 + 2 * t + 3;
}

/// Horizontal anchor column for character [id] (`rules.anchor`).
int comidaAnchorX(String id, {bool sent = false}) {
  if (id == 'abuela') return sent ? 17 : 30;
  return PX;
}

/// Draws a character of La comida with optional facial/hand gesture variants (`ojos`, `cara`, `rojo`, `cuchara`,
/// `tapa`) painted strictly inside the figure's sprite box so sheet spacing rules never break.
Sprite mkComidaPersona(
  String id,
  String pose, {
  bool open = false,
  bool sent = false,
  bool ojos = false,
  bool cara = false,
  bool rojo = false,
  bool cuchara = false,
  bool tapa = false,
}) {
  Sprite base;
  if (id == 'abuela') {
    base = sent
        ? mkAbuelaS(pose, open || ojos, false)
        : mkAbuela(pose, open || ojos);
  } else {
    var who = COMIDA_WHO[id] ?? COMIDA_WHO['senora']!;
    if (ojos) who = who.copyWith(dormido: true);
    base = mkPersona(who, pose, open || ojos, sent);
  }
  if (!rojo && !cara && !cuchara && !tapa && !(id == 'abuela' && ojos)) {
    return base;
  }
  final px = Uint32List.fromList(base.px);
  final w = base.w, h = base.h;
  void setPx(int x, int y, int col) {
    if (x >= 0 && x < w && y >= 0 && y < h) px[y * w + x] = col;
  }

  final cx = comidaAnchorX(id, sent: sent);
  final faceY = id == 'abuela' ? (sent ? 11 : 13) : 11;

  // Red flush over face region (pepper reaction)
  if (rojo) {
    for (var y = faceY - 5; y <= faceY + 6; y++) {
      if (y < 0 || y >= h) continue;
      for (var x = cx - 5; x <= cx + 5; x++) {
        if (x < 0 || x >= w) continue;
        final c = px[y * w + x];
        if (c >>> 24 == 0) continue;
        final r = c & 0xFF, g = (c >> 8) & 0xFF, bl = (c >> 16) & 0xFF;
        // Tint warm/skin pixels red while preserving dark eyes/outlines/hair
        if (r > 130 && g > 70 && r >= bl) {
          final nr = (r + 70).clamp(0, 255);
          final ng = (g * 0.45).round().clamp(0, 255);
          final nb = (bl * 0.45).round().clamp(0, 255);
          px[y * w + x] = 0xFF000000 | (nb << 16) | (ng << 8) | nr;
        }
      }
    }
  }

  // Abuela closed eyes for `ojos` (mkPersona already uses `dormido: true`)
  if (id == 'abuela' && ojos) {
    final eye = _h('#141010');
    final mouth = _h('#7A2228');
    setPx(cx - 3, faceY, eye);
    setPx(cx - 2, faceY, eye);
    setPx(cx + 1, faceY, eye);
    setPx(cx + 2, faceY, eye);
    setPx(cx - 1, faceY + 4, mouth);
    setPx(cx, faceY + 4, mouth);
    setPx(cx, faceY + 5, mouth);
  }

  // Grimace (`cara`: scrunched eyes + wavy frown)
  if (cara) {
    final dark = _h('#181018');
    setPx(cx - 3, faceY - 1, dark);
    setPx(cx - 2, faceY, dark);
    setPx(cx + 2, faceY - 1, dark);
    setPx(cx + 1, faceY, dark);
    setPx(cx - 2, faceY + 4, dark);
    setPx(cx - 1, faceY + 3, dark);
    setPx(cx, faceY + 4, dark);
    setPx(cx + 1, faceY + 3, dark);
    setPx(cx + 2, faceY + 4, dark);
  }

  // Spoon held upright inside the person's own silhouette width (`cuchara` in story 91)
  if (cuchara) {
    final sx = cx + 6;
    final sy = id == 'abuela' ? 22 : 21;
    final rim = _h('#1C2028');
    final sil = _h('#D8E0EC');
    final hi = _h('#FFFFFF');
    for (var dy = 0; dy < 8; dy++) {
      setPx(sx, sy + dy, sil);
      setPx(sx + 1, sy + dy, rim);
    }
    // Spoon bowl at top
    setPx(sx - 1, sy - 2, rim);
    setPx(sx, sy - 3, rim);
    setPx(sx + 1, sy - 2, rim);
    setPx(sx, sy - 2, hi);
    setPx(sx, sy - 1, sil);
  }

  // Hand raised flat covering cup (`tapa` in story 91), inside existing arm width
  if (tapa) {
    final sx = cx + 2;
    final sy = 24;
    final hand = _h('#E8B48A');
    final rim = _h('#2A1C14');
    for (var dx = 0; dx < 5; dx++) {
      setPx(sx + dx, sy, rim);
      setPx(sx + dx, sy + 1, hand);
      setPx(sx + dx, sy + 2, hand);
      setPx(sx + dx, sy + 3, rim);
    }
  }

  return Sprite(w, h, px);
}

/* ---------- table plates, jar, glasses (story 90; comida-preview.html) ---------- */

void _smallPlate(Buf b) {
  b.ell(7, 5.4, 6.8, 2.6, _hs(['#8C92AA', '#C8CCDC', '#F4F6FA']));
}

/// Small plate of tostones (`salado`), pineapple (`dulce`), or red peppers (`picante`): 14 × 8.
Sprite mkPlatillo(String sabor) => _mk(14, 8, (b) {
  _smallPlate(b);
  if (sabor == 'salado') {
    for (final x in const [4.5, 7.5, 10.5]) {
      b.ell(x, 3.6, 2.2, 1.6, _hs(['#B8781C', '#E0A838', '#F8D870']));
    }
    b.px(5, 3, _h('#FFFFFF'));
    b.px(8, 2, _h('#FFFFFF'));
  } else if (sabor == 'dulce') {
    for (final x in const [4.5, 7.5, 10.5]) {
      b.ell(x, 3.6, 2.3, 1.7, _hs(['#E8B830', '#F8D048']));
      b.ell(x, 3.6, .8, .6, _hs(['#FFF4B0']));
    }
  } else {
    // picante: small red peppers with green stems (kept at y >= 2 so outline stays at y >= 1, clear of jarra row 104)
    for (final x in const [4, 7, 10]) {
      b.rect(x - 1, 3, 3, 3, _h('#D0281E'));
      b.px(x, 2, _h('#2E9A48'));
      b.px(x + 1, 5, _h('#8A1812'));
    }
  }
});

/// Jar of lemonade (`jarra`): 12 × 18, [n] = 3, 2, 1, or 0 glasses left.
Sprite mkJarra(int n) => _mk(12, 18, (b) {
  // Glass body
  b.rect(1, 3, 10, 15, _h('#DCECF4'));
  // Lemonade fill proportional to n (3..0)
  final fillH = n <= 0 ? 0 : (n == 1 ? 5 : (n == 2 ? 10 : 14));
  if (fillH > 0) {
    final topY = 18 - fillH;
    b.rect(2, topY, 8, fillH, _h('#E8F2B8'));
    b.rect(2, topY, 8, 1, _h('#F4F8D0'));
    for (final p in const [
      [3, 6],
      [7, 11],
      [4, 14],
    ]) {
      if (p[1] >= topY + 1) {
        b.ell(p[0] + 1, p[1], 1.9, 1.9, _hs(['#78B050', '#B8E070']));
      }
    }
  }
  // Glass rims and reflections
  b.rect(1, 3, 1, 15, _h('#BFD8E8'));
  b.rect(10, 3, 1, 15, _h('#8CB4CC'));
  b.rect(0, 1, 12, 2, _h('#BFD8E8'));
  b.rect(2, 0, 8, 1, _h('#8CB4CC'));
  // Condensation drops
  b.px(8, 5, _h('#FFFFFF'));
  b.px(8, 6, _h('#FFFFFF'));
  b.px(3, 10, _h('#FFFFFF'));
});

/// Three glasses beside the jar (`vasos`): 26 × 10.
/// [n] = glasses still left for afterwards (3, 2, 1). In [finalMode]:
/// 3 -> all 3 filled with lemonade & straws; 2 -> 2 filled + lemon slice beside 3rd; 1 -> 1 filled with 3 straws.
Sprite mkVasos(int n, {bool finalMode = false}) => _mk(26, 10, (b) {
  const xs = [1, 10, 19];
  for (var i = 0; i < 3; i++) {
    final x = xs[i];
    final active = i < n;
    if (finalMode && n == 1 && i > 0) {
      // Empty glasses set aside slightly dimmer
      b.rect(x, 3, 7, 7, _h('#B8C8D4'));
      b.rect(x, 3, 1, 7, _h('#88A4B8'));
      b.rect(x + 6, 3, 1, 7, _h('#6E8CA4'));
      b.rect(x, 9, 7, 1, _h('#88A4B8'));
      continue;
    }
    if (!active && !finalMode) {
      // Used glass set aside empty
      b.rect(x, 3, 7, 7, _h('#B8C8D4'));
      b.rect(x, 3, 1, 7, _h('#88A4B8'));
      b.rect(x + 6, 3, 1, 7, _h('#6E8CA4'));
      b.rect(x, 9, 7, 1, _h('#88A4B8'));
      continue;
    }
    b.rect(x, 2, 7, 8, finalMode && active ? _h('#E8F2A8') : _h('#E4F0F8'));
    b.rect(x, 2, 1, 8, _h('#9CC8E0'));
    b.rect(x + 6, 2, 1, 8, _h('#7AA8C8'));
    b.rect(x, 9, 7, 1, _h('#9CC8E0'));
    if (finalMode && n == 1 && i == 0) {
      // Three straws in one glass
      b.line(x + 2, 0, x + 3, 6, _h('#D0403A'));
      b.line(x + 4, 0, x + 4, 6, _h('#3898D0'));
      b.line(x + 6, 0, x + 4, 6, _h('#48B858'));
    } else if (finalMode && n == 2 && i == 2) {
      // Lemon slices given to frog
      b.ell(x + 3.5, 6, 2.5, 2.0, _hs(['#78B050', '#B8E070']));
    } else {
      b.line(x + 5, 0, x + 3, 6, _h('#D0403A'));
    }
  }
});

/* ---------- station shelf items (story 91; comida-preview.html) ---------- */

/// Salt shaker (`sal`): 10 × 12.
Sprite mkSal() => _mk(10, 12, (b) {
  b.rect(2, 4, 6, 8, _h('#F4F4F8'));
  b.rect(2, 4, 1, 8, _h('#C8CCD8'));
  b.rect(7, 4, 1, 8, _h('#B0B6C8'));
  b.rect(2, 1, 6, 3, _h('#B8B8C8'));
  b.px(4, 2, _h('#6E6E80'));
  b.px(6, 2, _h('#6E6E80'));
});

/// Sugar bowl (`azucar`): 10 × 12.
Sprite mkAzucar() => _mk(10, 12, (b) {
  b.ell(5, 8, 4.8, 3.8, _hs(['#B8407A', '#E0609A', '#FFB8D4']));
  b.rect(1, 6, 8, 1, _h('#FFFFFF'));
  b.rect(3, 2, 4, 2, _h('#F4F4F8'));
  b.rect(4, 0, 2, 2, _h('#E0609A'));
  b.rect(2, 5, 6, 1, _h('#F4F4F8'));
});

/// Ice bucket with tongs (`hielo`): 10 × 12.
Sprite mkHielo() => _mk(10, 12, (b) {
  for (var y = 4; y < 12; y++) {
    final inset = (y - 4) ~/ 4;
    b.rect(
      1 + inset,
      y,
      8 - 2 * inset,
      1,
      y < 6 ? _h('#D8E4F0') : _h('#9AA8BC'),
    );
  }
  b.rect(1, 4, 8, 1, _h('#F4F8FF'));
  b.rect(2, 3, 2, 2, _h('#E8F4FF'));
  b.rect(5, 2, 2, 2, _h('#E8F4FF'));
  b.line(8, 0, 6, 4, _h('#8C94A8'));
  b.line(9, 1, 7, 5, _h('#8C94A8'));
});

/// Pile of napkins (`servilletas`): 10 × 12.
Sprite mkServilletas() => _mk(10, 12, (b) {
  b.rect(1, 6, 8, 6, _h('#FFFFFF'));
  b.rect(1, 6, 8, 1, _h('#E8E8F0'));
  b.rect(1, 9, 8, 1, _h('#DCDCE8'));
  b.rect(8, 6, 1, 6, _h('#C8C8D8'));
  b.rect(2, 3, 7, 3, _h('#F8F8FC'));
  b.rect(3, 1, 5, 2, _h('#FFFFFF'));
  b.line(2, 3, 8, 5, _h('#C8C8D8'));
});

/* ---------- soup bowls and salad (story 91; comida-preview.html) ---------- */

/// Bowl of soup (`sopa1..3`): 12 × 8, [caliente] bright warm orange vs cool muted broth.
Sprite mkSopa({bool caliente = true}) => _mk(12, 8, (b) {
  b.ell(6, 5, 5.8, 3, _hs(['#8E5A2A', '#C8853C', '#E8D0A0']));
  b.ell(
    6,
    3.2,
    4.8,
    1.8,
    caliente
        ? _hs(['#C0501C', '#E07A30', '#F8A850'])
        : _hs(['#786058', '#987E74', '#B49A8E']),
  );
});

/// Gentle steam wisps over a hot soup bowl (`6 × 6`, animated).
Sprite mkVaporSopa(int frame) {
  final b = Buf(6, 6);
  final c1 = _h('#F0F4FF');
  final c2 = _h('#BCC8DC');
  final o = frame % 2;
  b.px(1 + o, 4, c2);
  b.px(2 - o, 2, c1);
  b.px(1 + o, 0, c2);
  b.px(4 - o, 5, c2);
  b.px(3 + o, 3, c1);
  b.px(4 - o, 1, c2);
  return b.done();
}

/// Carmen's plate of salad (`ensalada`): 12 × 8.
Sprite mkEnsalada() => _mk(12, 8, (b) {
  b.ell(6, 5.2, 5.8, 2.6, _hs(['#8C92AA', '#C8CCDC', '#F4F6FA']));
  b.ell(6, 3.4, 4.6, 2.2, _hs(['#2E9A48', '#4CBC58', '#84DC78']));
  b.px(4, 3, _h('#D0403A'));
  b.px(8, 2, _h('#D0403A'));
  b.px(6, 4, _h('#F8C838'));
});

/* ---------- serving table bowls & dog (story 92; comida-preview.html) ---------- */

/// Frog's small bowl (`tazon`): 10 × 8, [n] = 0, 1, 2, or 3 spoonfuls of arroz con pollo.
Sprite mkTazon(int n) => _mk(10, 8, (b) {
  b.ell(5, 4.6, 4.8, 3.3, _hs(['#7A4A1E', '#A8682C', '#E2A85A']));
  b.rect(1, 1, 8, 1, _h('#F4CC88'));
  if (n <= 0) {
    b.rect(2, 2, 6, 1, _h('#4A2A14'));
  } else if (n == 1) {
    b.ell(5, 2.6, 2.4, 1.1, _hs(['#C89028', '#E8B848', '#F8D878']));
  } else if (n == 2) {
    b.ell(5, 2.4, 3.3, 1.5, _hs(['#C89028', '#E8B848', '#F8D878']));
    b.px(4, 2, _h('#D04028'));
  } else {
    b.ell(5, 2.0, 3.8, 1.9, _hs(['#C89028', '#E8B848', '#F8D878']));
    b.px(4, 1, _h('#D04028'));
    b.px(6, 2, _h('#50A040'));
  }
});

/// Dog's bowl (`plato_perro`): 12 × 8, [lleno] = heaped with rice from a serving.
Sprite mkPlatoPerro({bool lleno = false}) => _mk(12, 8, (b) {
  b.ell(6, 5, 5.8, 3, _hs(['#7A1C1C', '#B02A24', '#E0504A']));
  b.rect(2, 2, 8, 1, _h('#E0504A'));
  if (lleno) {
    b.ell(6, 2.4, 4.0, 1.8, _hs(['#C89028', '#E8B848', '#F8D878']));
    b.px(5, 2, _h('#D04028'));
    b.px(7, 2, _h('#50A040'));
  } else {
    b.rect(3, 3, 6, 1, _h('#6E4A2A'));
    b.px(4, 3, _h('#A8682C'));
    b.px(7, 3, _h('#A8682C'));
  }
});

/// The fonda's dog (`perro`): `'sit'` (stand-in Canelo sitting), `'up'` (looking up), `'eat'` (eating), `'sleep'`
/// (asleep on its back, round, story 92 final n=1).
Sprite mkPerroComida(String mood, int frame) {
  if (mood == 'sleep') {
    // Sleeping on its back, round belly up (30 × 22, same anchor as mkPerro)
    return _mk(30, 22, (b) {
      b.ell(15, 16, 8.5, 5.2, _hs(['#8C5628', '#C28244', '#E2A86A']));
      b.ell(15, 14.5, 5.5, 3.2, _hs(['#D8A66E', '#F0CCA0']));
      // Four paws sticking up
      for (final x in const [9, 12, 18, 21]) {
        b.rect(x, 9, 2, 4, _h('#A86E34'));
      }
      // Head resting at left, closed eye
      b.ell(7, 16.5, 3.4, 3.0, _hs(['#8C5628', '#C28244', '#E2A86A']));
      b.rect(5, 16, 2, 1, _h('#181010'));
      b.px(4, 17, _h('#221818'));
    });
  }
  if (mood == 'eat') {
    return mkPerro('sniff', frame % 2 != 0);
  }
  return mkPerro('sit', frame % 2 != 0);
}

/* ---------- frog overlays, rice plate, sauce bottle, celebration FX ---------- */

/// Small white-and-teal waiter apron over the frog's belly (story 91): 12 × 9.
Sprite mkDelantalCoqui() => _mk(12, 9, (b) {
  b.rect(2, 1, 8, 7, _h('#FFFFFF'));
  b.rect(2, 1, 8, 1, _h('#46847A'));
  b.rect(2, 7, 8, 1, _h('#C8D4DC'));
  b.rect(4, 4, 4, 2, _h('#DCE8EE'));
});

/// Folded white napkin over Coquí's arm (story 91 step 9): 6 × 7.
Sprite mkServilletaBrazo() => _mk(6, 7, (b) {
  b.rect(1, 1, 4, 5, _h('#FFFFFF'));
  b.rect(1, 4, 4, 1, _h('#D8DCE8'));
});

/// Big serving spoon held by Coquí (story 92): 6 × 14.
Sprite mkCucharonCoqui() => _mk(6, 14, (b) {
  b.rect(2, 4, 2, 9, _h('#98A0B0'));
  b.ell(3, 3, 2.4, 2.0, _hs(['#788292', '#C0C8D8', '#F0F4FA']));
});

/// Fire puff from the frog's mouth (story 90 `fuego90`): 14 × 10.
Sprite mkFuegoCoqui(int frame) => _mk(14, 10, (b) {
  final sh = frame % 2;
  b.ell(5 + sh, 5, 4.5, 3.6, _hs(['#C82418', '#F06018', '#FFD838']));
  b.ell(10, 4 + sh, 3.0, 2.2, _hs(['#F06018', '#FFE860']));
});

/// Steam rising off the frog's head after water (story 90 `fuego90`): 12 × 8.
Sprite mkVaporCoqui(int frame) {
  final b = Buf(12, 8);
  final o = frame % 2;
  final c1 = _h('#F4F8FF'), c2 = _h('#C0D0E4');
  for (final x in const [2, 6, 9]) {
    b.rect(x + o, 4, 2, 3, c2);
    b.rect(x + 1 - o, 1, 2, 3, c1);
  }
  return b.done();
}

/// Red face blush overlay for the frog (`fuego90`): 14 × 8.
Sprite mkCaritaRoja() {
  final b = Buf(14, 8);
  final r1 = _h('#E83828'), r2 = _h('#FF6848');
  b.rect(1, 2, 4, 4, r1);
  b.rect(2, 3, 2, 2, r2);
  b.rect(9, 2, 4, 4, r1);
  b.rect(10, 3, 2, 2, r2);
  return b.done();
}

/// Tongs carrying an ice cube (`trae91 hielo`): 8 × 9.
Sprite mkPinzasHielo() => _mk(8, 9, (b) {
  b.line(1, 0, 3, 5, _h('#9CA4B8'));
  b.line(6, 0, 4, 5, _h('#9CA4B8'));
  b.rect(2, 4, 4, 4, _h('#D8F0FF'));
  b.px(3, 5, _h('#FFFFFF'));
});

/// Plate of arroz con pollo held out in story 92 (`normal`, `mas`, `menos`, `vacio`): 14 × 9.
Sprite mkPlatoArroz(String nivel) => _mk(14, 9, (b) {
  b.ell(7, 6.2, 6.4, 2.3, _hs(['#8C92AA', '#C8CCDC', '#F4F6FA']));
  if (nivel == 'vacio') return;
  final rx = nivel == 'mas' ? 5.2 : (nivel == 'menos' ? 2.8 : 4.2);
  final ry = nivel == 'mas' ? 3.2 : (nivel == 'menos' ? 1.6 : 2.4);
  final cy = nivel == 'mas' ? 3.6 : (nivel == 'menos' ? 4.8 : 4.2);
  b.ell(7, cy, rx, ry, _hs(['#C89028', '#E8B848', '#F8D878']));
  b.px(6, cy.round(), _h('#D04028'));
  if (nivel != 'menos') b.px(8, cy.round() - 1, _h('#50A040'));
});

/// Bottle of red hot sauce / pique (story 92): 6 × 11.
Sprite mkSalsaRoja() => _mk(6, 11, (b) {
  b.rect(2, 1, 2, 3, _h('#F4F4F8'));
  b.rect(1, 4, 4, 6, _h('#D0281E'));
  b.rect(1, 6, 4, 2, _h('#F8E060'));
  b.px(2, 5, _h('#FF7868'));
});

/// Falling red sauce drop (`prueba92 salsa`): 4 × 5.
Sprite mkGotaSalsa() => _mk(4, 5, (b) {
  b.px(2, 1, _h('#D0281E'));
  b.rect(1, 2, 2, 2, _h('#E83828'));
});

/// Falling grains of salt (`prueba92 sal`): 6 × 6.
Sprite mkGranosSal() {
  final b = Buf(6, 6);
  final w = _h('#FFFFFF');
  b.px(1, 1, w);
  b.px(4, 2, w);
  b.px(2, 4, w);
  b.px(5, 5, w);
  return b.done();
}

/// Small heart celebration cue: 9 × 8.
Sprite mkCorazonComida() => _mk(9, 8, (b) {
  final r = _h('#E83850'), hi = _h('#FF8898');
  b.rect(1, 2, 3, 2, r);
  b.rect(5, 2, 3, 2, r);
  b.rect(2, 4, 5, 2, r);
  b.rect(3, 6, 3, 1, r);
  b.px(2, 2, hi);
});

/// Small star celebration cue: 7 × 7.
Sprite mkEstrellaComida() => _mk(7, 7, (b) {
  final g = _h('#F8D848'), hi = _h('#FFF8B0');
  b.rect(3, 1, 1, 5, g);
  b.rect(1, 3, 5, 1, g);
  b.px(2, 2, g);
  b.px(4, 2, g);
  b.px(2, 4, g);
  b.px(4, 4, g);
  b.px(3, 3, hi);
});

/// Every sprite La comida owns, for `tool/make_comida_sprites_test.dart`.
List<(String, Sprite)> comidaSpritesSheet() => [
  ('platillo salado', mkPlatillo('salado')),
  ('platillo dulce', mkPlatillo('dulce')),
  ('platillo picante', mkPlatillo('picante')),
  ('jarra 3', mkJarra(3)),
  ('jarra 2', mkJarra(2)),
  ('jarra 1', mkJarra(1)),
  ('jarra 0', mkJarra(0)),
  ('vasos 3', mkVasos(3)),
  ('vasos 2', mkVasos(2)),
  ('vasos 1', mkVasos(1)),
  ('vasos final 3', mkVasos(3, finalMode: true)),
  ('vasos final 2', mkVasos(2, finalMode: true)),
  ('vasos final 1', mkVasos(1, finalMode: true)),
  ('sal', mkSal()),
  ('azucar', mkAzucar()),
  ('hielo', mkHielo()),
  ('servilletas', mkServilletas()),
  ('sopa caliente', mkSopa(caliente: true)),
  ('sopa fria', mkSopa(caliente: false)),
  ('vapor sopa', mkVaporSopa(0)),
  ('ensalada', mkEnsalada()),
  ('tazon 0', mkTazon(0)),
  ('tazon 1', mkTazon(1)),
  ('tazon 2', mkTazon(2)),
  ('tazon 3', mkTazon(3)),
  ('plato perro', mkPlatoPerro()),
  ('plato perro lleno', mkPlatoPerro(lleno: true)),
  ('plato arroz normal', mkPlatoArroz('normal')),
  ('plato arroz mas', mkPlatoArroz('mas')),
  ('plato arroz menos', mkPlatoArroz('menos')),
  ('salsa roja', mkSalsaRoja()),
  ('gota salsa', mkGotaSalsa()),
  ('granos sal', mkGranosSal()),
  ('delantal coqui', mkDelantalCoqui()),
  ('servilleta brazo', mkServilletaBrazo()),
  ('cucharon coqui', mkCucharonCoqui()),
  ('fuego coqui', mkFuegoCoqui(0)),
  ('vapor coqui', mkVaporCoqui(0)),
  ('pinzas hielo', mkPinzasHielo()),
  ('corazon', mkCorazonComida()),
  ('estrella', mkEstrellaComida()),
  ('mesera', mkComidaPersona('mesera', 'idle')),
  ('cocinero', mkComidaPersona('cocinero', 'idle')),
  ('senora', mkComidaPersona('senora', 'idle')),
  ('senor', mkComidaPersona('senor', 'idle')),
  ('joven', mkComidaPersona('joven', 'idle')),
  ('mujer', mkComidaPersona('mujer', 'idle')),
  ('abuelo sentado', mkComidaPersona('abuelo', 'idle', sent: true)),
  ('carmen ojos', mkComidaPersona('carmen', 'idle', sent: true, ojos: true)),
  (
    'luis rojo cara',
    mkComidaPersona('luis', 'idle', sent: true, cara: true, rojo: true),
  ),
  (
    'abuela cuchara',
    mkComidaPersona('abuela', 'idle', sent: true, cuchara: true),
  ),
  ('luis tapa', mkComidaPersona('luis', 'idle', sent: true, tapa: true)),
  ('perro sentado', mkPerroComida('sit', 0)),
  ('perro comiendo', mkPerroComida('eat', 0)),
  ('perro dormido', mkPerroComida('sleep', 0)),
];
