// Scene-specific sprites of La orilla (place 7, La playa, scene 1: `orilla`, order 62b):
// shells (pink, white, rows of 1..3), fishing boat (34 x 20, steady & rocking), gull, toy boats in 5 colours (14 x 10,
// floating & sinking), frog's boat (36 x 8) in 5 colours, Carmen's shell string (0..3) & frog necklace/wrist/hand,
// hanging towels in 4 colours (14 x 16, dry & dripping), folded towel pile (1..3, 14 x 10), bread basket (12 x 10),
// sand bucket, waves (small & big), sand/water splashes, camera & flash, paper fan, hand over frog's eyes, wrapped
// towel & abuela's hat, abuela lying back on the blanket, wading/sitting cut helpers, Canelo with shell / sandy nose.
//
// Dimensions match orilla-sheet.json's spot boxes (`conchas` 22x6, `bote` 34x20, `bote_a/b` 14x10, `navega` boat 36x8,
// `cuerda1/2` 14x16, `toallas` 14x10, `canasta` 12x10).
// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'dart:typed_data';

import 'package:coqui_pixel/coqui_pixel.dart';

int _h(String s) => hexColour(s);

/// The five toy boat colours (stories 73: verde, blanco in opening; rojo, azul, amarillo in game).
const List<String> ORILLA_BOTE_COLORES = [
  'verde',
  'blanco',
  'rojo',
  'azul',
  'amarillo',
];

/// The four towel colours (story 74: rojo, azul, amarillo, verde).
const List<String> ORILLA_TOALLA_COLORES = [
  'rojo',
  'azul',
  'amarillo',
  'verde',
];

/// Main / highlight / dark shade for a named Spanish colour.
(int, int, int) _colorTrio(String color) => switch (color) {
  'rojo' => (_h('#D0453A'), _h('#F08070'), _h('#962820')),
  'azul' => (_h('#3A78D0'), _h('#78A8F0'), _h('#245096')),
  'amarillo' => (_h('#E6B42E'), _h('#FCE078'), _h('#AA7E18')),
  'verde' => (_h('#3E9A4E'), _h('#7ACB86'), _h('#266832')),
  'blanco' => (_h('#E4E0D4'), _h('#FFFFFF'), _h('#AAA494')),
  _ => (_h('#D0453A'), _h('#F08070'), _h('#962820')),
};

Sprite _mk(int w, int h, void Function(Buf b) draw, {bool outline = true}) {
  final b = Buf(w, h);
  draw(b);
  return outline ? b.outline().done() : b.done();
}

/* ---------- people cut / wading helpers (orilla-preview.html) ---------- */

/// Cuts a sitting `mkPersona` or `mkAbuelaS` sprite just below the hips and adds a dark outline row under it
/// (orilla-preview.html `cut` / `sitCut`: no maker draws a person sitting or kneeling on the sand).
Sprite cutSandSit(Sprite src, int rows) {
  final h = rows.clamp(1, src.h);
  final outH = h + 1;
  final b = Buf(src.w, outH);
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < src.w; x++) {
      final c = src.px[y * src.w + x];
      if (c >>> 24 != 0) b.px(x, y, c);
    }
  }
  return b.outline().done();
}

/// Clips the bottom [clipRows] of a standing child wading in shallow water (`agua1`: 4 px ankles, `agua2`: 10 px
/// knees) and draws a pale foam ripple at the waterline.
Sprite wadeClip(Sprite src, int clipRows, {int frame = 0}) {
  var bottom = src.h;
  for (var y = src.h - 1; y >= 0; y--) {
    var any = false;
    for (var x = 0; x < src.w; x++) {
      if (src.px[y * src.w + x] >>> 24 != 0) {
        any = true;
        break;
      }
    }
    if (any) {
      bottom = y + 1;
      break;
    }
  }
  final keep = (bottom - clipRows).clamp(8, src.h);
  final px = Uint32List(src.w * keep);
  var minX = src.w, maxX = -1;
  for (var y = 0; y < keep; y++) {
    for (var x = 0; x < src.w; x++) {
      final c = src.px[y * src.w + x];
      px[y * src.w + x] = c;
      if (y >= keep - 2 && c >>> 24 != 0) {
        if (x < minX) minX = x;
        if (x > maxX) maxX = x;
      }
    }
  }
  if (maxX >= minX) {
    final foam = _h('#F4FAFC');
    final cyan = _h('#82DAD0');
    final y0 = keep - 1;
    final x0 = (minX - 2).clamp(0, src.w - 1);
    final x1 = (maxX + 2).clamp(0, src.w - 1);
    for (var x = x0; x <= x1; x++) {
      px[y0 * src.w + x] = ((x + frame) % 3 == 0) ? cyan : foam;
    }
  }
  return Sprite(src.w, keep, px);
}

/* ---------- shells (6 x 6 each; row of 3 is 22 x 6) ---------- */

void _drawShell(Buf b, int ox, int oy, List<int> ramp, int hi, int dark) {
  b.ell(ox + 3, oy + 3.2, 2.5, 2.3, ramp);
  b.px(ox + 2, oy + 2, hi);
  b.px(ox + 3, oy + 4, dark);
}

/// One pink shell (6 x 6), for a tower top or carried by the frog / wave.
Sprite mkConcha() => _mk(6, 6, (b) {
  _drawShell(
    b,
    0,
    0,
    [_h('#C8508A'), _h('#F07AAE'), _h('#FFB4D2')],
    _h('#FFE4F0'),
    _h('#B04074'),
  );
});

/// One small white shell (6 x 6), for tower 3 in story 72's 2-shell ending.
Sprite mkConchaBlanca() => _mk(6, 6, (b) {
  _drawShell(
    b,
    0,
    0,
    [_h('#B8B4A8'), _h('#E4E0D4'), _h('#FFFFFF')],
    _h('#FFFFFF'),
    _h('#948E82'),
  );
});

/// Row of [n] (1 to 3) pink shells (22 x 6 canvas, 8 px middle to middle: `orilla-sheet.json` `spots.conchas`).
Sprite mkConchas(int n) {
  final count = n.clamp(1, 3);
  return _mk(22, 6, (b) {
    const xs = [0, 8, 16];
    for (var i = 0; i < count; i++) {
      _drawShell(
        b,
        xs[i],
        0,
        [_h('#C8508A'), _h('#F07AAE'), _h('#FFB4D2')],
        _h('#FFE4F0'),
        _h('#B04074'),
      );
    }
  });
}

/* ---------- fishing boat (34 x 20) & gull ---------- */

/// The fishing boat far out at anchor (34 x 20: matches `spots.bote.box = [168, 13, 34, 20]`).
Sprite mkBotePesca({bool rock = false}) => _mk(34, 20, (b) {
  final dy = rock ? 1 : 0;
  // Wooden mast & small pennant
  b.rect(22, 2 + dy, 2, 10, _h('#7A5634'));
  b.rect(24, 3 + dy, 4, 2, _h('#D0453A'));
  b.rect(24, 5 + dy, 2, 1, _h('#F08070'));
  // Blue cabin with dark window
  b.rect(8, 6 + dy, 10, 6, _h('#56A0BE'));
  b.rect(8, 6 + dy, 10, 1, _h('#8CCCE4'));
  b.rect(10, 8 + dy, 5, 3, _h('#283C5A'));
  b.px(11, 8 + dy, _h('#7CB4D8'));
  // White hull with red waterline stripe
  b.rect(2, 12 + dy, 30, 3, _h('#FAF8F0'));
  b.rect(2, 12 + dy, 30, 1, _h('#FFFFFF'));
  b.rect(4, 15 + dy, 26, 2, _h('#CE3E36'));
  b.rect(7, 17 + dy, 20, 1, _h('#9A2A24'));
});

/// A gull flying up from the fishing boat (12 x 8, 2 wing frames).
Sprite mkGaviota(int frame) => _mk(12, 8, (b) {
  final w = _h('#FAF8F4'), g = _h('#C8CCD4'), y = _h('#F0B83A');
  b.rect(4, 4, 4, 2, w);
  b.px(8, 4, y);
  if (frame % 2 == 0) {
    b.rect(1, 2, 3, 2, w);
    b.rect(7, 2, 3, 2, w);
    b.px(2, 3, g);
    b.px(8, 3, g);
  } else {
    b.rect(1, 5, 3, 2, g);
    b.rect(7, 5, 3, 2, g);
  }
});

/* ---------- toy boats (14 x 10) & frog's boat (36 x 8) ---------- */

/// A toy boat on the wet sand (14 x 10: matches `spots.bote_a/bote_b.box`).
Sprite mkBoteJuguete(String color, {bool hundido = false}) {
  final (main, hi, dark) = _colorTrio(color);
  return _mk(14, 10, (b) {
    if (!hundido) {
      b.rect(1, 6, 12, 3, main);
      b.rect(1, 6, 12, 1, hi);
      b.rect(3, 9, 8, 1, dark);
      b.rect(7, 1, 1, 5, _h('#7A4A1E'));
      for (var y = 0; y < 4; y++) {
        b.rect(8, 1 + y, 4 - y, 1, _h('#FFFBEA'));
      }
    } else {
      // Tilted & taking on water
      b.rect(2, 7, 10, 2, main);
      b.rect(4, 6, 6, 1, _h('#52B4D4'));
      b.rect(8, 3, 1, 4, _h('#7A4A1E'));
      b.rect(9, 4, 3, 2, _h('#DCE8EE'));
    }
  });
}

/// The boat hull the frog rides (36 x 8: matches `orilla-sheet.json` `spots.navega.boat = [36, 8]`).
Sprite mkBoteRana(String color, {bool hundido = false}) {
  final (main, hi, dark) = _colorTrio(color);
  return _mk(36, 8, (b) {
    if (!hundido) {
      b.rect(1, 2, 34, 4, main);
      b.rect(1, 2, 34, 1, hi);
      b.rect(4, 6, 28, 2, dark);
      b.rect(0, 1, 36, 1, _h('#7A4A1E'));
    } else {
      // Tilted hull dipping into water
      b.rect(2, 4, 30, 3, main);
      b.rect(6, 3, 22, 1, _h('#52B4D4'));
      b.rect(5, 6, 24, 2, dark);
    }
  });
}

/* ---------- Carmen's shell string & frog necklace (story 73) ---------- */

/// Carmen's string with [n] (0..3) pink shells tied on it (14 x 10).
Sprite mkCollar(int n) {
  final count = n.clamp(0, 3);
  return _mk(14, 10, (b) {
    final s = _h('#D8C496');
    // Hanging loop of string
    b.rect(2, 1, 1, 4, s);
    b.rect(11, 1, 1, 4, s);
    b.rect(3, 5, 2, 2, s);
    b.rect(9, 5, 2, 2, s);
    b.rect(5, 7, 4, 1, s);
    const pts = [(3, 5), (6, 6), (9, 5)];
    for (var i = 0; i < count; i++) {
      final (px, py) = pts[i];
      b.rect(px, py, 3, 3, _h('#F07AAE'));
      b.px(px + 1, py, _h('#FFE4F0'));
    }
  });
}

/// Story 73 ending prize on the frog: n=3 necklace, n=2 wrist string, n=1 single shell in hand (16 x 12).
Sprite mkCollarRana(int n) {
  final count = n.clamp(1, 3);
  return _mk(16, 12, (b) {
    final s = _h('#E4D0A0');
    if (count == 3) {
      // Necklace hanging down the frog's chest
      b.rect(3, 1, 1, 4, s);
      b.rect(12, 1, 1, 4, s);
      b.rect(4, 5, 2, 2, s);
      b.rect(10, 5, 2, 2, s);
      b.rect(6, 7, 4, 1, s);
      for (final (px, py) in const [(4, 5), (7, 7), (10, 5)]) {
        b.rect(px, py, 3, 3, _h('#F07AAE'));
        b.px(px + 1, py, _h('#FFE4F0'));
      }
    } else if (count == 2) {
      // Tied round his wrist
      b.rect(4, 5, 8, 2, s);
      b.rect(5, 4, 3, 3, _h('#F07AAE'));
      b.rect(9, 4, 3, 3, _h('#F07AAE'));
      b.px(6, 4, _h('#FFE4F0'));
      b.px(10, 4, _h('#FFE4F0'));
    } else {
      // Single shell in hand
      b.ell(8, 6, 3, 2.5, [_h('#C8508A'), _h('#F07AAE'), _h('#FFB4D2')]);
      b.px(7, 5, _h('#FFE4F0'));
    }
  });
}

/* ---------- towels & basket (story 74) ---------- */

/// Towel hanging on the rope (14 x 16: matches `spots.cuerda1/cuerda2.box`).
Sprite mkToallaColgada(String color, {bool gotea = false}) {
  final (main, hi, dark) = _colorTrio(color);
  return _mk(14, 16, (b) {
    b.rect(1, 1, 12, 14, main);
    b.rect(1, 1, 12, 2, hi);
    b.rect(1, 10, 12, 1, hi);
    b.rect(1, 12, 12, 1, hi);
    b.rect(6, 3, 2, 7, dark);
    if (gotea) {
      final drop = _h('#78CCF4');
      b.rect(3, 13, 1, 2, drop);
      b.rect(7, 14, 1, 2, drop);
      b.rect(10, 13, 1, 2, drop);
    }
  });
}

/// Pile of [n] (1 to 3) folded dry towels on the blanket (14 x 10: matches `spots.toallas.box`).
Sprite mkPilaToallas(int n) {
  final count = n.clamp(1, 3);
  return _mk(14, 10, (b) {
    if (count >= 1) {
      b.rect(1, 7, 12, 2, _h('#3A78D0'));
      b.rect(1, 7, 12, 1, _h('#78A8F0'));
    }
    if (count >= 2) {
      b.rect(2, 4, 10, 3, _h('#E8B83A'));
      b.rect(2, 4, 10, 1, _h('#F8DC78'));
    }
    if (count >= 3) {
      b.rect(1, 1, 12, 3, _h('#D0453A'));
      b.rect(1, 1, 12, 1, _h('#F08070'));
    }
  });
}

/// Basket with bread on abuela's blanket (12 x 10: matches `spots.canasta.box`).
Sprite mkCanastaPlaya() => _mk(12, 10, (b) {
  b.rect(1, 4, 10, 5, _h('#C8853C'));
  for (var y = 4; y < 9; y += 2) {
    for (var x = 1; x < 11; x += 2) {
      b.px(x + ((y >> 1) % 2), y, _h('#8A5A24'));
    }
  }
  b.rect(1, 3, 10, 1, _h('#E2A85A'));
  b.ell(4, 2.5, 2.5, 1.6, [_h('#E2A85A'), _h('#F4CC88')]);
  b.ell(8, 2.2, 2.2, 1.4, [_h('#D09450'), _h('#F4CC88')]);
});

/// Folded towel carried by the frog or wrapped over shoulders (12 x 8).
Sprite mkToallaPuesta(String color) {
  final (main, hi, dark) = _colorTrio(color);
  return _mk(14, 8, (b) {
    b.rect(1, 1, 12, 6, main);
    b.rect(1, 1, 12, 2, hi);
    b.rect(1, 5, 12, 1, dark);
  });
}

/// Story 74 ending (3 towels): the frog wrapped snugly in a towel (22 x 18).
Sprite mkToallaRana() => _mk(22, 18, (b) {
  b.ell(11, 10, 9, 7, [_h('#245096'), _h('#3A78D0'), _h('#78A8F0')]);
  b.rect(4, 11, 14, 2, _h('#FFFFFF'));
  // Frog's two eyes peeking out over the towel
  b.ell(8, 4, 2.5, 2.2, [_h('#3E8E3E'), _h('#68C858')]);
  b.ell(14, 4, 2.5, 2.2, [_h('#3E8E3E'), _h('#68C858')]);
  b.px(8, 4, _h('#181414'));
  b.px(14, 4, _h('#181414'));
});

/// Story 74 ending (1 or 2 towels): abuela's sun hat over the frog (24 x 14).
Sprite mkSombreroRana() => _mk(24, 14, (b) {
  // Straw sun hat brim & crown
  b.ell(12, 10, 10.5, 3, [_h('#B88E46'), _h('#DFB868'), _h('#F4DC94')]);
  b.ell(12, 6, 6, 4.5, [_h('#C89E52'), _h('#E8C87A'), _h('#F8E4A4')]);
  b.rect(6, 7, 12, 2, _h('#D0453A'));
});

/* ---------- abuela lying back with hat over face (story 74 `acuesta`) ---------- */

/// Abuela resting on her blanket with her sun hat over her face (26 x 22, fits within `manta_abuela` clear of basket & towels).
Sprite mkAbuelaAcostada() => _mk(26, 22, (b) {
  // Blanket pillow / dress body lying back
  b.ell(13, 15, 10.5, 5, [_h('#644888'), _h('#8A68B4'), _h('#B294D8')]);
  b.rect(4, 16, 18, 3, _h('#76569C'));
  // Arms resting at sides
  b.rect(3, 13, 3, 4, _h('#C88E68'));
  b.rect(20, 13, 3, 4, _h('#C88E68'));
  // Sun hat tilted over her face
  b.ell(13, 7, 8.5, 3.2, [_h('#B88E46'), _h('#DFB868'), _h('#F4DC94')]);
  b.ell(13, 4.5, 5, 3, [_h('#C89E52'), _h('#E8C87A'), _h('#F8E4A4')]);
  b.rect(8, 5, 10, 2, _h('#D0453A'));
});

/* ---------- waves, splashes, drips, camera, fan, bucket, hand, Canelo ---------- */

/// A foaming wave running up the wet sand (small: 184 x 9, big: 190 x 15).
Sprite mkOla(bool grande, int frame) {
  final w = grande ? 190 : 184;
  final h = grande ? 15 : 9;
  final px = Uint32List(w * h);
  final foam = _h('#FAFDFE');
  final shallow = _h('#7CE0D8');
  final mid = _h('#4CB4D4');
  final deep = _h('#3692C0');
  for (var x = 0; x < w; x++) {
    final wob = ((x + frame * 7) % 16 < 8) ? 0 : 1;
    final top = 1 + wob;
    final bot = h - 2 - ((x + frame * 5) % 12 < 6 ? 0 : 1);
    for (var y = top; y <= bot; y++) {
      final d = bot - y;
      final c = d <= 1
          ? foam
          : d <= (grande ? 4 : 2)
          ? shallow
          : d <= (grande ? 8 : 4)
          ? mid
          : deep;
      px[y * w + x] = c;
    }
  }
  return Sprite(w, h, px);
}

/// Digging sand spray or water ducking splash (18 x 10, 2 frames).
Sprite mkSalpicadura(bool arena, int frame) {
  final c1 = arena ? _h('#E6D2A0') : _h('#FAFDFE');
  final c2 = arena ? _h('#C8B07C') : _h('#7CE0D8');
  final px = Uint32List(18 * 10);
  final off = frame % 2;
  const pts = [
    (3, 5),
    (5, 2),
    (8, 1),
    (10, 2),
    (13, 3),
    (15, 6),
    (2, 7),
    (6, 6),
    (11, 6),
    (14, 8),
  ];
  for (var i = 0; i < pts.length; i++) {
    final (x, y) = pts[i];
    final yy = (y + (i.isEven ? off : -off)).clamp(0, 8);
    px[yy * 18 + x] = i.isEven ? c1 : c2;
    if (x + 1 < 18) px[yy * 18 + x + 1] = c2;
  }
  return Sprite(18, 10, px);
}

/// Water droplets around a dripping child or frog (20 x 22, 2 frames).
Sprite mkGotas(int frame) {
  final px = Uint32List(20 * 22);
  final d1 = _h('#88D4F8');
  final d2 = _h('#E8F8FF');
  final dy = (frame % 2) * 3;
  for (final (x, y) in const [
    (2, 4),
    (17, 5),
    (4, 12),
    (15, 11),
    (7, 17),
    (12, 16),
  ]) {
    final yy = (y + dy) % 20;
    px[yy * 20 + x] = d2;
    px[(yy + 1) * 20 + x] = d1;
  }
  return Sprite(20, 22, px);
}

/// Sand bucket (9 x 9) for `torres72`.
Sprite mkCuboArena() => _mk(9, 9, (b) {
  b.rect(2, 3, 5, 5, _h('#D0453A'));
  b.rect(2, 3, 5, 1, _h('#F08070'));
  b.rect(1, 2, 7, 1, _h('#FCE078'));
  b.rect(3, 1, 3, 1, _h('#B8B4A8'));
});

/// Abuela's camera (10 x 8) and flash star (14 x 14) for `foto`.
Sprite mkCamara() => _mk(10, 8, (b) {
  b.rect(1, 2, 8, 5, _h('#3A3E48'));
  b.rect(3, 1, 3, 1, _h('#666C7A'));
  b.rect(4, 3, 3, 3, _h('#84B8DC'));
  b.px(5, 4, _h('#FFFFFF'));
});

Sprite mkFlash() {
  final px = Uint32List(14 * 14);
  final w = _h('#FFFFFF'), y = _h('#FFF098');
  for (var i = 0; i < 14; i++) {
    px[7 * 14 + i] = i > 3 && i < 10 ? w : y;
    px[i * 14 + 7] = i > 3 && i < 10 ? w : y;
  }
  for (var d = -3; d <= 3; d++) {
    px[(7 + d) * 14 + (7 + d)] = w;
    px[(7 + d) * 14 + (7 - d)] = w;
  }
  return Sprite(14, 14, px);
}

/// Small paper fan (9 x 8, 2 frames) for `gesto abanica`.
Sprite mkAbanicoMano(int frame) => _mk(9, 8, (b) {
  final c1 = _h('#F4DC94'), c2 = _h('#D0453A');
  if (frame % 2 == 0) {
    b.rect(2, 1, 5, 4, c1);
    b.rect(3, 2, 3, 2, c2);
    b.rect(4, 5, 1, 2, _h('#8A5A24'));
  } else {
    b.rect(1, 2, 6, 4, c1);
    b.rect(2, 3, 4, 2, c2);
    b.rect(4, 6, 1, 1, _h('#8A5A24'));
  }
});

/// Luis's hand over the frog's eyes during `esconde72` (18 x 8).
Sprite mkManoTapa() => _mk(18, 8, (b) {
  b.rect(2, 2, 14, 4, _h('#D89C70'));
  b.rect(2, 2, 14, 1, _h('#F0BA8E'));
  b.rect(1, 3, 2, 3, _h('#C08256'));
  b.rect(15, 3, 2, 3, _h('#C08256'));
});

/// Canelo running with a pink shell in his mouth (30 x 22, fits `perro` width).
Sprite mkPerroConcha(bool step) {
  final base = mkPerro('run', step);
  final px = Uint32List.fromList(base.px);
  final sh = mkConcha();
  const ox = 23, oy = 6;
  for (var y = 0; y < sh.h; y++) {
    for (var x = 0; x < sh.w; x++) {
      final c = sh.px[y * sh.w + x];
      if (c >>> 24 == 0) continue;
      final X = ox + x, Y = oy + y;
      if (X >= 0 && X < base.w && Y >= 0 && Y < base.h) {
        px[Y * base.w + X] = c;
      }
    }
  }
  return Sprite(base.w, base.h, px);
}

/// Canelo lying down with sand on his nose (story 72 1-shell ending, 30 x 22).
Sprite mkPerroArena() {
  final base = mkPerro('lie', false);
  final px = Uint32List.fromList(base.px);
  final sand1 = _h('#EAE0B8'), sand2 = _h('#D4BC88');
  for (final (x, y) in const [(23, 13), (24, 13), (24, 14), (25, 13)]) {
    if (x < base.w && y < base.h) {
      px[y * base.w + x] = (x + y).isEven ? sand1 : sand2;
    }
  }
  return Sprite(base.w, base.h, px);
}

/// Every scene-specific sprite La orilla draws, for the sprite sheet & tests.
List<(String, Sprite)> orillaSpritesSheet() => [
  ('concha', mkConcha()),
  ('concha_blanca', mkConchaBlanca()),
  ('conchas_1', mkConchas(1)),
  ('conchas_2', mkConchas(2)),
  ('conchas_3', mkConchas(3)),
  ('bote_pesca', mkBotePesca()),
  ('bote_pesca_rock', mkBotePesca(rock: true)),
  ('gaviota_0', mkGaviota(0)),
  ('gaviota_1', mkGaviota(1)),
  for (final c in ORILLA_BOTE_COLORES) ('bote_$c', mkBoteJuguete(c)),
  ('bote_blanco_hundido', mkBoteJuguete('blanco', hundido: true)),
  for (final c in ORILLA_BOTE_COLORES) ('bote_rana_$c', mkBoteRana(c)),
  ('bote_rana_rojo_hundido', mkBoteRana('rojo', hundido: true)),
  for (var n = 0; n <= 3; n++) ('collar_$n', mkCollar(n)),
  for (var n = 1; n <= 3; n++) ('collar_rana_$n', mkCollarRana(n)),
  for (final c in ORILLA_TOALLA_COLORES) ('toalla_$c', mkToallaColgada(c)),
  ('toalla_rojo_gotea', mkToallaColgada('rojo', gotea: true)),
  for (var n = 1; n <= 3; n++) ('pila_toallas_$n', mkPilaToallas(n)),
  ('canasta_playa', mkCanastaPlaya()),
  ('toalla_puesta_azul', mkToallaPuesta('azul')),
  ('toalla_rana', mkToallaRana()),
  ('sombrero_rana', mkSombreroRana()),
  ('abuela_acostada', mkAbuelaAcostada()),
  ('ola_pequena', mkOla(false, 0)),
  ('ola_grande', mkOla(true, 0)),
  ('salpicadura_arena', mkSalpicadura(true, 0)),
  ('salpicadura_mar', mkSalpicadura(false, 0)),
  ('gotas', mkGotas(0)),
  ('cubo_arena', mkCuboArena()),
  ('camara', mkCamara()),
  ('flash', mkFlash()),
  ('abanico_mano', mkAbanicoMano(0)),
  ('mano_tapa', mkManoTapa()),
  ('perro_concha', mkPerroConcha(false)),
  ('perro_arena', mkPerroArena()),
];
