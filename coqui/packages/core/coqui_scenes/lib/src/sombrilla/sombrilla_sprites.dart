// Scene-specific sprites of La sombrilla (place 7, La playa, scene 2: `sombrilla`, order 63b):
// - Preview-matching sprites (sombrilla-preview.html): abuela lying on the blanket (52 x 18: sleep, stir, one eye open),
//   5 x 5 face shell, 8 x 8 spiral shell, row of 1..3 spiral shells (28 x 8), bucket of shells (12 x 12), sun hats
//   (16 x 12), dark glasses (16 x 12), sandals (16 x 12), beach ball (9 x 9).
// - Additional Needs sprites (sombrilla.md): floating Z's (1..3), sand mouth line (wide / small), sun hat drawn over
//   the sand face, green seaweed hair, flat shell ears, starfish, flat stones (hat pin, bracelet, ring), stick button,
//   Canelo running with spiral shell / digging / sandy nose / stick, Carmen lying on blanket (34 x 15), worn sun hat,
//   dark glasses & sandals, gust of wind, hush / clap cues.
//
// Dimensions match sombrilla-sheet.json's spot boxes (`cubo75` 12x12, `ojo_izq/ojo_der/nariz/boca` 5x5, `caracoles`
// 28x8, `sombreros/gafas/chancletas` 16x12, `bola` 9x9, `abuelaL` 52x18).
// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'dart:typed_data';

import 'package:coqui_pixel/coqui_pixel.dart';

int _h(String s) => hexColour(s);

List<int> _ramp(List<String> hs) => [for (final s in hs) _h(s)];

Sprite _mk(int w, int h, void Function(Buf b) draw, {bool outline = true}) {
  final b = Buf(w, h);
  draw(b);
  return outline ? b.outline().done() : b.done();
}

final List<int> _PINK = _ramp(const ['#D98A8A', '#F0B4AC', '#FFE0D8']);
final List<int> _SPIRAL = _ramp(const ['#9A6A40', '#C8985C', '#F0D09A']);
final int _DARK = _h('#3A2414');

/* ---------- abuela & Carmen lying on the blanket ---------- */

/// Abuela lying on her back on the blanket, head at the left (52 x 18, sombrilla-preview.html `THING.lying`).
/// [pose]: `'sleep'` (eyes closed), `'stir'` (eyes squinted / stirring), `'ojo'` (one eye open, smiling).
Sprite mkAbuelaAcostadaSombrilla({String pose = 'sleep'}) => _mk(52, 18, (b) {
  final S = RP.skin;
  final P = RP.purp;
  b.rect(41, 7, 7, 5, S[2]); // her legs out of the dress
  b.ell(49.5, 9.5, 2.4, 3.2, [_DARK]); // her shoes
  b.ell(27, 9.5, 14, 5.8, P); // the dress
  for (var i = 0; i < 6; i++) {
    b.px(15 + (i * 5) % 22, 12 + i % 3, P[4]);
  }
  b.ell(23, 8.8, 6, 3, RP.cream); // the apron
  b.cap(17, 12.5, 24, 13.2, 1.7, P);
  b.ell(26.5, 13.2, 1.8, 1.8, S); // her arm along her side
  b.rect(13, 7, 3, 5, S[1]); // the neck
  b.ell(9, 9.5, 6.6, 6.8, RP.grey);
  b.ell(3.6, 7.6, 2.4, 2.4, RP.grey); // the hair, the bun
  b.ell(10, 10, 4.4, 4.8, S); // the face, up
  if (pose == 'ojo') {
    // One eye open (white + pupil), the other closed, smiling
    b.rect(8, 8, 2, 2, _h('#FFFFFF'));
    b.px(9, 9, _h('#20140A'));
    b.rect(12, 9, 2, 1, _h('#20140A'));
    b.rect(10, 13, 3, 1, _h('#8E3020'));
    b.px(13, 12, _h('#8E3020'));
  } else if (pose == 'stir') {
    b.rect(8, 8, 2, 1, _h('#20140A'));
    b.rect(12, 8, 2, 1, _h('#20140A'));
    b.rect(10, 12, 2, 2, _h('#7A2A1A'));
  } else {
    b.rect(8, 9, 2, 1, _h('#20140A'));
    b.rect(12, 9, 2, 1, _h('#20140A'));
    b.rect(10, 13, 3, 1, _h('#7A2A1A'));
  }
});

/// Carmen lying on the blanket in the shade (`fuera77` at `manta3`, 34 x 15, head at right so clear of abuela at `manta2`).
Sprite mkCarmenAcostada() => _mk(34, 15, (b) {
  final S = RP.skin;
  final shirt = _ramp(const ['#C84658', '#E86878', '#F898A4']);
  final shorts = _ramp(const ['#3A6AA8', '#5888C8', '#84B0E8']);
  final hair = _ramp(const ['#2A1A10', '#4A301E', '#6A462C']);
  // Legs & shoes to the left
  b.rect(3, 6, 6, 4, S[2]);
  b.ell(2.5, 8, 1.8, 2.5, [_DARK]);
  // Shorts & coral shirt
  b.ell(11, 8, 4.5, 3.8, shorts);
  b.ell(18, 8, 6.2, 4.4, shirt);
  b.cap(16, 10.5, 21, 11.2, 1.4, S);
  // Head & dark hair with ponytail at right
  b.ell(26, 7.8, 4.6, 4.8, hair);
  b.ell(31, 6.5, 2.0, 2.0, hair);
  b.ell(25, 8.2, 3.4, 3.6, S);
  b.px(24, 7, _h('#20140A'));
  b.px(26, 7, _h('#20140A'));
  b.rect(24, 10, 2, 1, _h('#8E3020'));
});

/* ---------- shells, bucket, three beach things & ball (sombrilla-preview.html) ---------- */

/// One face shell: 5 x 5 with dark outline (sombrilla-preview.html `THING.concha5`, anchor centre 2, 2).
Sprite mkConcha5() => _mk(5, 5, (b) {
  b.ell(2.5, 2.5, 1.5, 1.5, _PINK);
});

/// One spiral shell: 8 x 8 (sombrilla-preview.html `THING.caracol`).
Sprite mkCaracol() => _mk(8, 8, (b) {
  b.ell(4, 4, 2.9, 2.9, _SPIRAL);
  b.px(4, 4, _DARK);
  b.px(5, 4, _DARK);
  b.px(5, 3, _DARK);
  b.px(3, 3, _DARK);
  b.px(4, 2, _DARK);
});

/// Row of [n] (1 to 3) spiral shells: 28 x 8, centres 10 px apart (sombrilla-preview.html `row(n)`).
Sprite mkCaracoles(int n) {
  final count = n.clamp(1, 3);
  return _mk(28, 8, (b) {
    for (var i = 0; i < count; i++) {
      final cx = 4 + i * 10;
      b.ell(cx, 4, 2.9, 2.9, _SPIRAL);
      b.px(cx, 4, _DARK);
      b.px(cx + 1, 4, _DARK);
      b.px(cx + 1, 3, _DARK);
      b.px(cx - 1, 3, _DARK);
      b.px(cx, 2, _DARK);
    }
  });
}

/// Bucket of white shells: 12 x 12 (sombrilla-preview.html `THING.cubo`, matches `spots.cubo75`).
Sprite mkCuboConchas() => _mk(12, 12, (b) {
  b.rect(1, 4, 10, 7, _h('#3E7CD0'));
  b.rect(1, 4, 10, 1, _h('#78B0F6'));
  b.rect(0, 3, 12, 1, _h('#2A58A0'));
  b.line(2, 3, 5, 0, _h('#6E6E80'));
  b.line(9, 3, 6, 0, _h('#6E6E80'));
  for (final (x, y) in const [(3, 2), (5, 2), (7, 2), (4, 1), (6, 1)]) {
    b.px(x, y, _h('#FFFBEA'));
  }
});

/// Sun hats in the row: 16 x 12 (sombrilla-preview.html `THING.sombreros`).
Sprite mkSombreros() => _mk(16, 12, (b) {
  final straw = _ramp(const ['#B8862C', '#DCAC4C', '#F4D07C']);
  b.ell(8, 8.5, 6.8, 2.6, straw);
  b.ell(8, 5.5, 3.8, 3.6, straw);
  b.rect(5, 6, 6, 1, _h('#D0403A'));
});

/// Dark glasses in the row: 16 x 12 (sombrilla-preview.html `THING.gafas`).
Sprite mkGafas() => _mk(16, 12, (b) {
  final lens = _ramp(const ['#20242E', '#3A4256']);
  b.ell(4.5, 7, 3.4, 3.6, lens);
  b.ell(11.5, 7, 3.4, 3.6, lens);
  b.rect(7, 5, 2, 1, _h('#20242E'));
  b.line(1, 5, 1, 2, _h('#20242E'));
  b.line(14, 5, 14, 2, _h('#20242E'));
  b.px(3, 5, _h('#78B0F6'));
  b.px(10, 5, _h('#78B0F6'));
});

/// Sandals in the row: 16 x 12 (sombrilla-preview.html `THING.chancletas`).
Sprite mkChancletas() => _mk(16, 12, (b) {
  final green = _ramp(const ['#2E9A48', '#4CBC58']);
  for (final x in const [4, 11]) {
    b.ell(x, 7, 2.9, 4.2, green);
    b.line(x - 2, 5, x, 3, _h('#F8F8F0'));
    b.line(x + 2, 5, x, 3, _h('#F8F8F0'));
  }
});

/// Beach ball: 9 x 9 (sombrilla-preview.html `THING.bola`).
Sprite mkBolaPlaya() => _mk(9, 9, (b) {
  b.ell(4.5, 4.5, 3.4, 3.4, _ramp(const ['#D0403A', '#EC6050', '#FA9080']));
  b.line(2, 4, 7, 4, _h('#FFFFFF'));
});

/* ---------- story 75: Z's, mouth line, sand sun hat ---------- */

void _drawZ(Buf b, int ox, int oy, int sz, int col) {
  if (sz <= 4) {
    b.rect(ox, oy, 4, 1, col);
    b.px(ox + 2, oy + 1, col);
    b.px(ox + 1, oy + 2, col);
    b.rect(ox, oy + 3, 4, 1, col);
  } else {
    b.rect(ox, oy, 5, 1, col);
    b.px(ox + 3, oy + 1, col);
    b.px(ox + 2, oy + 2, col);
    b.px(ox + 1, oy + 3, col);
    b.rect(ox, oy + 4, 5, 1, col);
  }
}

/// Floating Z's over sleeping abuela (1..3 Z's, 26 x 18, bobbing gently with [frame]).
Sprite mkZetas(int n, int frame) {
  final count = n.clamp(1, 3);
  final dy = frame % 2 == 0 ? 0 : -1;
  return _mk(26, 18, (b) {
    final c1 = _h('#FAF8E8');
    final c2 = _h('#DCE8FA');
    if (count >= 1) _drawZ(b, 2, 11 + dy, 4, c1);
    if (count >= 2) _drawZ(b, 9, 6 - dy, 4, c2);
    if (count >= 3) _drawZ(b, 17, 2 + dy, 5, c1);
  });
}

/// Mouth line drawn with the stick on the sand face (`boca75`: `'grande'` 26 x 6 or `'pequena'` 12 x 5).
Sprite mkBocaLinea(String t) {
  final line = _h('#78644C');
  final hi = _h('#967E60');
  if (t == 'grande') {
    return _mk(26, 6, (b) {
      b.line(2, 1, 8, 4, line);
      b.line(8, 4, 17, 4, line);
      b.line(17, 4, 23, 1, line);
      b.line(8, 3, 17, 3, hi);
    }, outline: false);
  }
  return _mk(12, 5, (b) {
    b.line(2, 1, 4, 3, line);
    b.line(4, 3, 7, 3, line);
    b.line(7, 3, 9, 1, line);
    b.rect(4, 2, 4, 1, hi);
  }, outline: false);
}

/// Sun hat drawn over the sand face in story 75's ending (46 x 14).
Sprite mkSombreroArena() => _mk(46, 14, (b) {
  final straw = _ramp(const ['#C49438', '#E2B456', '#F8DA88']);
  b.ell(23, 10, 21, 3, straw);
  b.ell(23, 6, 11, 4.5, straw);
  b.rect(12, 7, 22, 2, _h('#D0403A'));
});

/* ---------- story 76: seaweed hair, shell ears, starfish, flat stones, stick, Canelo ---------- */

/// Green seaweed hair laid along the top of the sand figure's head (42 x 12).
Sprite mkPeloAlgas() => _mk(42, 12, (b) {
  final d = _h('#286E46'), m = _h('#468C50'), l = _h('#68B064');
  for (var x = 4; x < 38; x += 4) {
    final top = (x < 10 || x > 32) ? 4 : 1;
    b.rect(x, top, 3, 7, m);
    b.rect(x + 1, top, 1, 5, l);
    b.rect(x, top + 5, 2, 3, d);
  }
  b.ell(21, 5, 16, 3.2, [d, m, l]);
});

/// Flat shell for the figure's ear (8 x 10, left or right side of head).
Sprite mkOrejaConcha({bool right = false}) => _mk(8, 10, (b) {
  final col = _ramp(const ['#C89882', '#E8BCA8', '#FCE0D0']);
  b.ell(right ? 3.5 : 4.5, 5, 2.8, 3.8, col);
  b.px(right ? 3 : 4, 5, _h('#9A6E5A'));
});

/// Coral starfish laid in the sand hand (11 x 11).
Sprite mkEstrellaMar() => _mk(11, 11, (b) {
  final c1 = _h('#E46A40'), c2 = _h('#F89864');
  b.line(5, 1, 5, 9, c1);
  b.line(1, 4, 9, 4, c1);
  b.line(2, 9, 5, 5, c1);
  b.line(8, 9, 5, 5, c1);
  b.rect(4, 3, 3, 3, c2);
  b.px(5, 2, c2);
});

/// Flat stone laid on the sand figure (`'cabeza'` hat pin 9x7, `'brazo'` bracelet 8x6, `'mano'` ring 7x6).
Sprite mkPiedra(String kind) {
  final stone = _ramp(const ['#6E7A88', '#98A4B4', '#C4D0DC']);
  return switch (kind) {
    'cabeza' => _mk(9, 7, (b) {
      b.ell(4.5, 3.5, 3.4, 2.3, stone);
      b.px(4, 2, _h('#E8F0F8'));
    }),
    'brazo' => _mk(8, 6, (b) {
      b.ell(4, 3, 2.8, 1.9, stone);
      b.px(3, 2, _h('#E8F0F8'));
    }),
    _ => _mk(7, 6, (b) {
      b.ell(3.5, 3, 2.2, 1.8, stone);
      b.px(3, 2, _h('#E8F0F8'));
    }),
  };
}

/// Stick laid as a button by Canelo in story 76's 1-button ending (12 x 5).
Sprite mkPaloBoton() => _mk(12, 5, (b) {
  b.line(1, 3, 10, 2, _h('#7A522C'));
  b.line(2, 2, 9, 1, _h('#A47644'));
});

/// Canelo running with a spiral shell in his mouth (30 x 22).
Sprite mkPerroCaracol(bool step) {
  final base = mkPerro('run', step);
  final px = Uint32List.fromList(base.px);
  final sh = mkCaracol();
  const ox = 21, oy = 6;
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

/// Canelo digging at `hoyo` with a small sand spray (30 x 22).
Sprite mkPerroCava(int frame) {
  final base = mkPerro('husmea', frame % 2 == 1);
  final px = Uint32List.fromList(base.px);
  final s1 = _h('#EAE0B8'), s2 = _h('#C8B07C');
  final off = frame % 2;
  for (final (x, y) in const [(22, 17), (24, 15), (26, 18), (21, 19)]) {
    final yy = (y - off).clamp(0, base.h - 1);
    if (x < base.w) {
      px[yy * base.w + x] = (x + y).isEven ? s1 : s2;
    }
  }
  return Sprite(base.w, base.h, px);
}

/// Canelo with sand on his nose (story 76 2-button ending, 30 x 22).
Sprite mkPerroArenaSombrilla() {
  final base = mkPerro('sit', false);
  final px = Uint32List.fromList(base.px);
  final s1 = _h('#F0E4BC'), s2 = _h('#D6BE8A');
  for (final (x, y) in const [(22, 10), (23, 10), (23, 11), (24, 10)]) {
    if (x < base.w && y < base.h) {
      px[y * base.w + x] = (x + y).isEven ? s1 : s2;
    }
  }
  return Sprite(base.w, base.h, px);
}

/// Canelo with a stick in his mouth (story 76 1-button ending, 30 x 22).
Sprite mkPerroPalo() {
  final base = mkPerro('sit', false);
  final px = Uint32List.fromList(base.px);
  final st = mkPaloBoton();
  const ox = 18, oy = 10;
  for (var y = 0; y < st.h; y++) {
    for (var x = 0; x < st.w; x++) {
      final c = st.px[y * st.w + x];
      if (c >>> 24 == 0) continue;
      final X = ox + x, Y = oy + y;
      if (X >= 0 && X < base.w && Y >= 0 && Y < base.h) {
        px[Y * base.w + X] = c;
      }
    }
  }
  return Sprite(base.w, base.h, px);
}

/* ---------- story 77: worn accessories, gust of wind, hush & clap cues ---------- */

/// Sun hat worn on a character's head (18 x 9).
Sprite mkSombreroPuesto() => _mk(18, 9, (b) {
  final straw = _ramp(const ['#B8862C', '#DCAC4C', '#F4D07C']);
  b.ell(9, 6.2, 7.8, 2.0, straw);
  b.ell(9, 3.6, 4.4, 2.8, straw);
  b.rect(5, 4, 8, 1, _h('#D0403A'));
});

/// Dark glasses worn on a character's face (12 x 5).
Sprite mkGafasPuestas() => _mk(12, 5, (b) {
  b.rect(1, 1, 4, 3, _h('#20242E'));
  b.rect(7, 1, 4, 3, _h('#20242E'));
  b.rect(5, 2, 2, 1, _h('#20242E'));
  b.px(2, 2, _h('#78B0F6'));
  b.px(8, 2, _h('#78B0F6'));
});

/// Green sandals worn on a character's feet (14 x 5).
Sprite mkChancletasPuestas() => _mk(14, 5, (b) {
  b.rect(1, 2, 5, 2, _h('#2E9A48'));
  b.rect(2, 1, 3, 1, _h('#F8F8F0'));
  b.rect(8, 2, 5, 2, _h('#2E9A48'));
  b.rect(9, 1, 3, 1, _h('#F8F8F0'));
});

/// Gust of wind streaks (`viento77`, 64 x 18, no outline).
Sprite mkViento(int frame) {
  final px = Uint32List(64 * 18);
  final c1 = _h('#FAFDFE'), c2 = _h('#D4EEF8');
  final ox = (frame * 6) % 16;
  for (final (y, x0, len) in const [(3, 4, 26), (9, 14, 32), (14, 2, 24)]) {
    for (var i = 0; i < len; i++) {
      final x = (x0 + i + ox) % 64;
      px[y * 64 + x] = i % 3 == 0 ? c2 : c1;
    }
  }
  return Sprite(64, 18, px);
}

/// Clap sparks over a resting player clapping from the blanket in story 77's ending (12 x 8).
Sprite mkAplauso(int frame) {
  final px = Uint32List(12 * 8);
  final y = _h('#FCE478'), w = _h('#FFFFFF');
  final pts = frame % 2 == 0
      ? const [(2, 4), (4, 2), (7, 2), (9, 4), (5, 5), (6, 5)]
      : const [(1, 3), (3, 1), (8, 1), (10, 3), (5, 4), (6, 4)];
  for (var i = 0; i < pts.length; i++) {
    final (px0, py0) = pts[i];
    px[py0 * 12 + px0] = i.isEven ? y : w;
  }
  return Sprite(12, 8, px);
}

/// Every scene-specific sprite La sombrilla draws, for the sprite sheet & tests.
List<(String, Sprite)> sombrillaSpritesSheet() => [
  ('abuela_sleep', mkAbuelaAcostadaSombrilla(pose: 'sleep')),
  ('abuela_stir', mkAbuelaAcostadaSombrilla(pose: 'stir')),
  ('abuela_ojo', mkAbuelaAcostadaSombrilla(pose: 'ojo')),
  ('carmen_acostada', mkCarmenAcostada()),
  ('concha5', mkConcha5()),
  ('caracol', mkCaracol()),
  ('caracoles_1', mkCaracoles(1)),
  ('caracoles_2', mkCaracoles(2)),
  ('caracoles_3', mkCaracoles(3)),
  ('cubo_conchas', mkCuboConchas()),
  ('sombreros', mkSombreros()),
  ('gafas', mkGafas()),
  ('chancletas', mkChancletas()),
  ('bola_playa', mkBolaPlaya()),
  ('zetas_1', mkZetas(1, 0)),
  ('zetas_2', mkZetas(2, 0)),
  ('zetas_3', mkZetas(3, 0)),
  ('boca_grande', mkBocaLinea('grande')),
  ('boca_pequena', mkBocaLinea('pequena')),
  ('sombrero_arena', mkSombreroArena()),
  ('pelo_algas', mkPeloAlgas()),
  ('oreja_izq', mkOrejaConcha(right: false)),
  ('oreja_der', mkOrejaConcha(right: true)),
  ('estrella_mar', mkEstrellaMar()),
  ('piedra_cabeza', mkPiedra('cabeza')),
  ('piedra_brazo', mkPiedra('brazo')),
  ('piedra_mano', mkPiedra('mano')),
  ('palo_boton', mkPaloBoton()),
  ('perro_caracol', mkPerroCaracol(false)),
  ('perro_cava', mkPerroCava(0)),
  ('perro_arena', mkPerroArenaSombrilla()),
  ('perro_palo', mkPerroPalo()),
  ('sombrero_puesto', mkSombreroPuesto()),
  ('gafas_puestas', mkGafasPuestas()),
  ('chancletas_puestas', mkChancletasPuestas()),
  ('viento', mkViento(0)),
  ('aplauso', mkAplauso(0)),
];
