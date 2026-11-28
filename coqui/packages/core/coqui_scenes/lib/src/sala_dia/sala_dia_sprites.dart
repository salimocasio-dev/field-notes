// Scene-specific sprites of La sala, de día (place 9, La casa, un día entero, scene 3: `sala_dia`, order 72):
// - Cast variants (abuela with floury hands / shush finger / telephone at ear or mouth; abuelo dozing / cupping ear /
//   smiling / nodding / holding telephone out; Luis & Carmen reading / writing / notebook / ball) keeping exact
//   sheet anchor dimensions;
// - Table & hand props matching sala_dia-sheet.json box dimensions (libro 12x8, papel 12x8, telefono 10x6,
//   pagina1..pagina3 16x12, estrellas 8x6, foto 10x8);
// - Story FX (floating book pictures, written sheet, paper plane, 3-size frog drawings, voice pictures, frog singing
//   rings, hearts, stars, aveces icons, album cover, wall clock hands, directional gesture cue);
// - `salaDiaSpritesSheet()` for the content lane's sprite sheet review.
// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'package:coqui_pixel/coqui_pixel.dart';

int _h(String s) => hexColour(s);

List<int> _ramp(List<String> hs) => [for (final s in hs) _h(s)];

Sprite _mk(int w, int h, void Function(Buf b) draw, {bool outline = true}) {
  final b = Buf(w, h);
  draw(b);
  return outline ? b.outline().done() : b.done();
}

/// Copies [base] and lets [paint] draw extra pixels directly onto its canvas without changing dimensions or feet row.
Sprite _overlayOn(Sprite base, void Function(Buf b) paint) {
  final b = Buf(base.w, base.h);
  for (var py = 0; py < base.h; py++) {
    for (var px = 0; px < base.w; px++) {
      final c = base.px[py * base.w + px];
      if (c >>> 24 != 0) b.px(px, py, c);
    }
  }
  paint(b);
  return b.done();
}

/// Lap anchor row for a seated person (`mkPersona` with `sent = true`: `16 + 2 * t + 3`, sala_dia-sheet.json rules.anchor).
int salaDiaSeatedLap(Who w) => 16 + 2 * (w.nino ? 7 : 11) + 3;

/* ---------- cast variants (same canvas & anchor as base makers) ---------- */

/// Standing abuela (`mkAbuela`) with optional story overlays: white flour on hands (`harina`), shush finger
/// (`silencio`), or holding the telephone to her ear (`phone == 'ear'`) or before her mouth (`phone == 'mouth'`).
Sprite mkAbuelaSalaDia(
  String pose,
  bool open, {
  bool harina = false,
  bool silencio = false,
  String? phone,
}) {
  final base = mkAbuela(pose, open);
  if (!harina && !silencio && phone == null) return base;
  return _overlayOn(base, (b) {
    if (harina) {
      // White flour dusting on both hands (columns ~21..24 and ~35..38, rows ~30..34).
      b.rect(21, 31, 3, 3, _h('#FFFFFF'));
      b.px(22, 30, _h('#F4F0E8'));
      b.rect(36, 31, 3, 3, _h('#FFFFFF'));
      b.px(37, 30, _h('#F4F0E8'));
    }
    if (silencio) {
      // Raised finger in front of lips (middle column 30, rows 15..19).
      b.rect(29, 15, 2, 4, _h('#D89B6C'));
      b.px(29, 14, _h('#EAB489'));
      b.px(28, 16, _h('#1F1A24'));
    }
    if (phone == 'ear') {
      // Telephone held against her left ear (cols 23..25, rows 12..17).
      b.rect(23, 12, 3, 6, _h('#2C2E38'));
      b.rect(24, 13, 1, 4, _h('#9CCBDE'));
      b.px(24, 13, _h('#FFE070'));
    } else if (phone == 'mouth') {
      // Telephone held before her mouth (cols 27..32, rows 16..19).
      b.rect(27, 16, 6, 4, _h('#2C2E38'));
      b.rect(28, 17, 4, 2, _h('#9CCBDE'));
      b.px(31, 17, _h('#FFE070'));
    }
  });
}

/// Seated abuelo (`mkPersona(FAM['abuelo']!, ..., sent = true)`) with optional story overlays: dozing eyes,
/// cupping a hand behind his ear (`oreja`), smiling, nodding, or holding the telephone out to the frog.
Sprite mkAbueloSalaDia(
  String pose,
  bool open, {
  bool doze = false,
  bool cupEar = false,
  bool smile = false,
  bool nod = false,
  bool holdPhone = false,
}) {
  final base = mkPersona(FAM['abuelo']!, pose, open, true);
  if (!doze && !cupEar && !smile && !nod && !holdPhone) return base;
  return _overlayOn(base, (b) {
    if (doze) {
      // Closed sleepy eyes over the head row (~10) and tiny 'z' accent beside temple (staying inside head box).
      b.rect(20, 11, 3, 1, _h('#3A2A24'));
      b.rect(25, 11, 3, 1, _h('#3A2A24'));
    }
    if (cupEar) {
      // Hand cupped behind his left ear (toward the frog: cols 15..18, rows 9..13).
      b.rect(16, 10, 2, 4, _h('#E2AA7E'));
      b.px(15, 11, _h('#C48A5E'));
      b.px(15, 12, _h('#C48A5E'));
    }
    if (smile) {
      // Warm curved smile under moustache (cols 22..25, row 14).
      b.rect(22, 14, 4, 1, _h('#FFFFFF'));
    }
    if (nod) {
      // Subtle downward chin accent (row 15).
      b.rect(22, 15, 4, 1, _h('#B87C56'));
    }
    if (holdPhone) {
      // Holding telephone out to his left toward the frog (cols 12..17, rows 24..28).
      b.rect(12, 24, 6, 4, _h('#2C2E38'));
      b.rect(13, 25, 4, 2, _h('#9CCBDE'));
      b.px(16, 25, _h('#FFE070'));
    }
  });
}

/// Seated child (`luis` or `carmen`) with optional small prop in hand (notebook, ball, pencil/writing).
Sprite mkNinoSalaDia(
  Who w,
  String pose,
  bool open, {
  bool notebook = false,
  bool ball = false,
  bool writes = false,
}) {
  final base = mkPersona(w, pose, open, true);
  if (!notebook && !ball && !writes) return base;
  return _overlayOn(base, (b) {
    if (notebook) {
      // Small pale notebook on lap/hand (cols 27..33, rows 24..29).
      b.rect(27, 24, 6, 5, _h('#3868A8'));
      b.rect(28, 25, 4, 3, _h('#FFFBEA'));
    }
    if (ball) {
      // Small coloured ball held in hand (cols 28..33, rows 22..27).
      b.ell(
        30.5,
        24.5,
        2.5,
        2.5,
        _ramp(const ['#C8382A', '#E85840', '#FFD070']),
      );
    }
    if (writes) {
      // Yellow pencil tip held at hand (cols 27..31, rows 24..26).
      b.rect(28, 24, 3, 2, _h('#F0C840'));
      b.px(27, 25, _h('#3A3A46'));
    }
  });
}

/* ---------- table & hand props (exact sheet dimensions) ---------- */

/// The book on the low table (12 × 8, matching sala_dia-sheet.json `libro` box).
/// [open]: open spread; [scribbled]: written in (wrong move in 102); [patched]: covered with a clean sheet.
Sprite mkLibro({
  bool open = false,
  bool scribbled = false,
  bool patched = false,
}) => _mk(12, 8, (b) {
  if (!open) {
    // sala_dia-preview.html: libro shut
    b.rect(1, 1, 10, 6, _h('#B8402A'));
    b.rect(1, 1, 10, 1, _h('#D8664A'));
    b.rect(2, 2, 8, 4, _h('#FFFBEA'));
    b.rect(6, 2, 1, 4, _h('#C8B890'));
    b.rect(1, 6, 10, 1, _h('#8A2A1A'));
  } else {
    // Open book spread (12 x 8)
    b.rect(1, 1, 10, 6, _h('#B8402A'));
    b.rect(2, 1, 4, 5, _h('#FFFBEA'));
    b.rect(6, 1, 4, 5, _h('#FFF7DC'));
    b.rect(5, 1, 1, 5, _h('#C8B890'));
    if (patched) {
      // Clean white sheet pasted over the right page
      b.rect(6, 2, 4, 4, _h('#FFFFFF'));
      b.px(7, 3, _h('#DCE8F8'));
    } else if (scribbled) {
      // Messy dark scribbles across the page
      b.px(7, 2, _h('#304078'));
      b.px(8, 3, _h('#304078'));
      b.px(7, 4, _h('#304078'));
      b.px(9, 4, _h('#304078'));
    } else {
      // Neat tiny text lines
      b.rect(3, 2, 2, 1, _h('#B8AA90'));
      b.rect(3, 4, 2, 1, _h('#B8AA90'));
      b.rect(7, 2, 2, 1, _h('#B8AA90'));
      b.rect(7, 4, 2, 1, _h('#B8AA90'));
    }
  }
});

/// Carmen's pad of paper (12 × 8, matching sala_dia-sheet.json `papel` box).
/// [hojas]: 5..0 clean sheets left; [miniFrog]: very small green frog drawn in top corner (102: 4).
Sprite mkPapel(int hojas, {bool miniFrog = false}) => _mk(12, 8, (b) {
  final n = hojas.clamp(0, 5);
  // Backing cardboard at bottom edge
  b.rect(1, 1, 10, 6, _h('#D8C8A8'));
  if (n > 0) {
    // Stack height reflects remaining sheets (5 -> fullest, 1 -> thin sheet)
    final stackH = (2 + (n * 4 + 4) ~/ 5).clamp(2, 6);
    b.rect(1, 1, 10, stackH, _h('#FFFFFF'));
    b.rect(1, 1, 10, 1, _h('#B8B8C8'));
    if (stackH >= 4) b.rect(2, 3, 7, 1, _h('#9CB4DE'));
    if (stackH >= 6) b.rect(2, 5, 6, 1, _h('#9CB4DE'));
    // Sheet-count ticks along the right edge
    for (var i = 0; i < n && i < 5; i++) {
      b.px(10, 1 + i, _h('#DCE4F0'));
    }
    if (miniFrog) {
      // Very small green frog drawn in the top-left corner of the top sheet
      b.rect(2, 2, 3, 2, _h('#4CA844'));
      b.px(2, 2, _h('#7CE068'));
      b.px(4, 2, _h('#7CE068'));
    }
  } else {
    // Empty pad backing
    b.rect(2, 2, 8, 4, _h('#C4B090'));
  }
});

/// The telephone (10 × 6, matching sala_dia-sheet.json `telefono` box).
/// [lit]: screen lit with mamá's tiny portrait; [bars]: 0..3 battery bars; [blink]: low-bar warning blink;
/// [ringing]: ring shake highlight.
Sprite mkTelefono({
  bool lit = false,
  bool ringing = false,
  int bars = 3,
  bool blink = false,
}) => _mk(10, 6, (b) {
  final n = bars.clamp(0, 3);
  b.rect(1, 1, 8, 4, ringing ? _h('#525264') : _h('#3A3A46'));
  if (!lit) {
    b.rect(2, 2, 6, 2, _h('#242834'));
  } else {
    b.rect(2, 2, 6, 2, _h('#9CCBDE'));
    // Tiny portrait of mamá on the left of screen
    b.px(3, 2, _h('#5A3420'));
    b.px(3, 3, _h('#E8B088'));
    // Battery bars in the right corner (cols 5, 6, 7)
    for (var i = 0; i < 3; i++) {
      final bx = 5 + i;
      if (i < n) {
        final col = (blink && i == n - 1)
            ? _h('#E84030')
            : (n == 1 ? _h('#F0A030') : _h('#52D058'));
        b.px(bx, 2, col);
        b.px(bx, 3, col);
      } else {
        b.px(bx, 2, _h('#3A4A58'));
      }
    }
    if (ringing) b.px(8, 1, _h('#FFE070'));
  }
});

/// One of the album's three pages (16 × 12, matching sala_dia-sheet.json `pagina1..pagina3` boxes):
/// 1 = morning (low rising sun), 2 = afternoon (high orange sun), 3 = night (moon & stars).
/// [glow]: gold highlight border; [hasPhoto]: miniature photo stuck in corner; [torn]: peeled corner with gold star.
Sprite mkPagina(
  int n, {
  bool glow = false,
  bool hasPhoto = false,
  bool torn = false,
}) => _mk(16, 12, (b) {
  if (n == 1) {
    // Morning: pale sky, green hill, low rising sun
    b.rect(1, 1, 14, 10, _h('#FFFBEA'));
    b.rect(1, 8, 14, 3, _h('#7AB06A'));
    b.ell(8, 8, 3, 2.4, _ramp(const ['#E87830', '#F6A050', '#FFD070']));
  } else if (n == 2) {
    // Afternoon: warm sky, green ground, high orange sun
    b.rect(1, 1, 14, 10, _h('#FFFBEA'));
    b.rect(1, 9, 14, 2, _h('#7AB06A'));
    b.ell(8, 4.5, 2.8, 2.8, _ramp(const ['#E87830', '#F6A050', '#FFD070']));
  } else {
    // Night: deep blue sky, moon and stars
    b.rect(1, 1, 14, 10, _h('#2A3070'));
    b.ell(8, 5.5, 2.8, 2.8, _ramp(const ['#C8C8D4', '#F2F2F8', '#FFFFFF']));
    b.px(3, 3, _h('#FFE070'));
    b.px(12, 7, _h('#FFE070'));
    b.px(12, 2, _h('#FFE070'));
  }
  if (hasPhoto) {
    // Stuck photo tile on bottom-left of page
    b.rect(2, 5, 5, 5, _h('#FFFFFF'));
    b.rect(3, 6, 3, 3, _h('#78A8E0'));
    b.px(4, 7, _h('#3A3A46'));
  }
  if (torn) {
    // Torn top-right corner patched with a gold star
    b.rect(11, 2, 3, 3, _h('#D8C4A0'));
    b.px(12, 3, _h('#FFD84A'));
    b.px(11, 3, _h('#FFE880'));
    b.px(13, 3, _h('#FFE880'));
    b.px(12, 2, _h('#FFE880'));
  }
  if (glow) {
    // Bright gold highlight border around the page
    final g = _h('#FFE050');
    b.rect(1, 1, 14, 1, g);
    b.rect(1, 10, 14, 1, g);
    b.rect(1, 1, 1, 10, g);
    b.rect(14, 1, 1, 10, g);
  }
});

/// The box of gold stars (8 × 6, matching sala_dia-sheet.json `estrellas` box).
Sprite mkEstrellasBox(int count) => _mk(8, 6, (b) {
  final n = count.clamp(0, 3);
  b.rect(1, 2, 6, 3, _h('#B88040'));
  b.rect(1, 2, 6, 1, _h('#D8A460'));
  if (n >= 1) b.px(2, 1, _h('#FFD84A'));
  if (n >= 2) b.px(4, 1, _h('#FFE870'));
  if (n >= 3) b.px(5, 1, _h('#FFD84A'));
});

/// The photo in Carmen's hands (10 × 8, matching sala_dia-sheet.json `foto` box).
/// Supports all 7 photo keys from story 104 (`luis_computadora`, `abuela_libro`, `abuelo_lee`, `abuela_escribe`,
/// `carmen_juega`, `luis_lee`, `abuela_juega`) plus [torn] corner with gold star.
Sprite mkFoto(String que, {bool torn = false}) => _mk(10, 8, (b) {
  b.rect(1, 1, 8, 6, _h('#FFFBEA'));
  // Neutral indoor backdrop (no window, no clock — time of day is never hinted)
  b.rect(2, 2, 6, 4, _h('#DFD4BE'));
  switch (que) {
    case 'luis_computadora':
      // Blue screen + boy
      b.rect(2, 2, 3, 3, _h('#68B8E8'));
      b.rect(6, 2, 2, 2, _h('#4A3222'));
      b.rect(6, 4, 2, 2, _h('#4880C8'));
    case 'abuela_libro':
      // White bun + red book
      b.rect(2, 2, 2, 2, _h('#E8E8EE'));
      b.rect(2, 4, 2, 2, _h('#7850A0'));
      b.rect(5, 3, 3, 3, _h('#C04832'));
    case 'abuelo_lee':
      // Cream shirt + open book
      b.rect(2, 2, 2, 2, _h('#E4B48C'));
      b.rect(2, 4, 2, 2, _h('#F0E4C4'));
      b.rect(5, 3, 3, 2, _h('#B8402A'));
      b.px(6, 3, _h('#FFFBEA'));
    case 'abuela_escribe':
      // Abuela + white pad
      b.rect(2, 2, 2, 2, _h('#E8E8EE'));
      b.rect(2, 4, 2, 2, _h('#7850A0'));
      b.rect(5, 4, 3, 2, _h('#FFFFFF'));
      b.px(6, 4, _h('#5078C0'));
    case 'carmen_juega':
      // Pink dress + bright ball
      b.rect(2, 2, 2, 2, _h('#4A3222'));
      b.rect(2, 4, 2, 2, _h('#D86888'));
      b.rect(6, 3, 2, 2, _h('#E84838'));
      b.px(6, 3, _h('#FFD060'));
    case 'luis_lee':
      // Boy + red book
      b.rect(2, 2, 2, 2, _h('#4A3222'));
      b.rect(2, 4, 2, 2, _h('#4880C8'));
      b.rect(5, 3, 3, 2, _h('#B8402A'));
      b.px(6, 4, _h('#FFFBEA'));
    case 'abuela_juega':
      // Abuela + bright ball
      b.rect(2, 2, 2, 2, _h('#E8E8EE'));
      b.rect(2, 4, 2, 2, _h('#7850A0'));
      b.rect(6, 3, 2, 2, _h('#E84838'));
      b.px(6, 3, _h('#FFD060'));
    default:
      b.rect(2, 2, 6, 3, _h('#9CCBF5'));
      b.rect(4, 3, 2, 2, _h('#3A3A46'));
  }
  if (torn) {
    // Torn corner with gold star
    b.px(7, 2, _h('#FFD84A'));
    b.px(8, 2, _h('#FFE880'));
    b.px(7, 1, _h('#FFE880'));
  }
});

/* ---------- wall clock hands & story FX ---------- */

/// Hands for the round wall clock (`E.CLOCK`, 11 × 11 without outer outline so it sits cleanly inside the clock dial).
/// Default: 3:00 (afternoon, Story 104: "Son las tres de la tarde").
Sprite mkRelojManecillas({int hour = 3}) => _mk(11, 11, (b) {
  final col = _h('#2A2226');
  // Centre pin at (5, 5)
  b.px(5, 5, _h('#B8382A'));
  // Minute hand pointing to 12 (up: rows 1..4)
  b.rect(5, 1, 1, 4, col);
  // Hour hand: 3 -> right (cols 6..8); 9 -> left; 6 -> down; 12 -> up
  if (hour == 3) {
    b.rect(6, 5, 3, 1, col);
  } else if (hour == 9) {
    b.rect(2, 5, 3, 1, col);
  } else if (hour == 6) {
    b.rect(5, 6, 1, 3, col);
  } else {
    b.rect(6, 5, 3, 1, col);
  }
}, outline: false);

/// Small floating picture from reading the book (`lee102`): `'barco'` (boat) or `'estrella'` (star), 10 × 8.
Sprite mkLeePic(String kind) => _mk(10, 8, (b) {
  b.rect(1, 1, 8, 6, _h('#FFFDF4'));
  if (kind == 'barco') {
    b.rect(2, 5, 6, 1, _h('#4A88D8'));
    b.rect(3, 4, 4, 1, _h('#B06030'));
    b.rect(5, 2, 2, 2, _h('#E85040'));
  } else {
    b.px(5, 2, _h('#F0B820'));
    b.rect(3, 3, 4, 1, _h('#FFD84A'));
    b.rect(4, 4, 2, 1, _h('#F0B820'));
    b.px(3, 5, _h('#F0B820'));
    b.px(6, 5, _h('#F0B820'));
  }
});

/// Written sheet floating/shown for `escribe102` (letters) or `nombres102` (two names: Carmen + Coquí), 12 × 8.
Sprite mkHojaEscrita({bool nombres = false}) => _mk(12, 8, (b) {
  b.rect(1, 1, 10, 6, _h('#FFFFFF'));
  b.rect(2, 2, 7, 1, _h('#3858A8'));
  if (nombres) {
    // Second name written underneath in green for Coquí
    b.rect(2, 4, 6, 1, _h('#3A9848'));
    b.px(9, 4, _h('#3A9848'));
  } else {
    b.rect(2, 4, 5, 1, _h('#5A78C0'));
    b.rect(2, 5, 8, 1, _h('#9CB4DE'));
  }
});

/// Paper plane folded from a clean sheet (`da102` wrong when child should read), 10 × 7.
Sprite mkAvionPapel() => _mk(10, 7, (b) {
  b.rect(1, 3, 8, 1, _h('#FFFFFF'));
  b.rect(2, 2, 6, 1, _h('#EEF4FA'));
  b.rect(4, 1, 3, 1, _h('#FFFFFF'));
  b.rect(3, 4, 4, 1, _h('#C8D4E4'));
  b.px(5, 5, _h('#A8B8CC'));
});

/// Carmen's final frog drawing on the clean sheets left (`final102`, `n` = 1, 2, or 3):
/// 1 = small frog (12 × 10), 2 = medium frog (20 × 14), 3 = big frog as wide as the table (32 × 16).
Sprite mkDibujoRana(int n) {
  final level = n.clamp(1, 3);
  if (level == 1) {
    return _mk(12, 10, (b) {
      b.rect(1, 1, 10, 8, _h('#FFFDF6'));
      b.ell(6, 6, 2.5, 2, _ramp(const ['#3A8838', '#52B44A', '#80DC6A']));
      b.px(5, 4, _h('#FFFFFF'));
      b.px(7, 4, _h('#FFFFFF'));
    });
  }
  if (level == 2) {
    return _mk(20, 14, (b) {
      b.rect(1, 1, 18, 12, _h('#FFFDF6'));
      b.rect(9, 1, 1, 12, _h('#E4E0D4'));
      b.ell(10, 8, 5, 3.5, _ramp(const ['#3A8838', '#52B44A', '#80DC6A']));
      b.rect(7, 4, 2, 2, _h('#FFFFFF'));
      b.rect(11, 4, 2, 2, _h('#FFFFFF'));
      b.px(8, 5, _h('#1F1A24'));
      b.px(11, 5, _h('#1F1A24'));
      b.rect(8, 9, 4, 1, _h('#2B662A'));
    });
  }
  return _mk(32, 16, (b) {
    // Three clean sheets side by side with a big happy frog
    b.rect(1, 1, 30, 14, _h('#FFFDF6'));
    b.rect(10, 1, 1, 14, _h('#E4E0D4'));
    b.rect(21, 1, 1, 14, _h('#E4E0D4'));
    b.ell(16, 9, 8.5, 4.5, _ramp(const ['#3A8838', '#52B44A', '#80DC6A']));
    b.rect(11, 3, 3, 3, _h('#FFFFFF'));
    b.rect(18, 3, 3, 3, _h('#FFFFFF'));
    b.px(12, 4, _h('#1F1A24'));
    b.px(19, 4, _h('#1F1A24'));
    b.rect(13, 10, 6, 1, _h('#2B662A'));
    // Tiny star & heart accents on the sheet corners
    b.px(4, 4, _h('#FFD84A'));
    b.px(27, 4, _h('#E85068'));
  });
}

/// Small voice picture for Story 103 (`pone103`):
/// mamá's voice: `'guagua'` (bus), `'playa'` (beach); abuelo's voice: `'pez'` (fish), `'sombrero'` (hat). 10 × 8.
Sprite mkVozPic(String kind) => _mk(10, 8, (b) {
  b.rect(1, 1, 8, 6, _h('#FFFDF4'));
  switch (kind) {
    case 'guagua':
      b.rect(2, 3, 6, 3, _h('#E8A830'));
      b.rect(3, 4, 2, 1, _h('#9CCBF5'));
      b.rect(6, 4, 1, 1, _h('#9CCBF5'));
      b.px(3, 6, _h('#303038'));
      b.px(6, 6, _h('#303038'));
    case 'playa':
      b.rect(2, 2, 6, 2, _h('#88C8F4'));
      b.rect(2, 4, 6, 1, _h('#3888D0'));
      b.rect(2, 5, 6, 1, _h('#E8C878'));
      b.px(6, 2, _h('#FFE050'));
    case 'pez':
      b.rect(3, 3, 4, 2, _h('#4A90D8'));
      b.px(7, 2, _h('#4A90D8'));
      b.px(7, 5, _h('#4A90D8'));
      b.px(4, 3, _h('#1F1A24'));
    default: // sombrero
      b.rect(3, 2, 4, 2, _h('#D8A858'));
      b.rect(2, 4, 6, 1, _h('#B88438'));
      b.rect(3, 4, 4, 1, _h('#C84030'));
  }
});

/// Sound rings floating from the frog's mouth towards the telephone (`anillos103`, `final103`), 10 × 8.
Sprite mkAnillos(int phase) => _mk(10, 8, (b) {
  final c1 = phase % 2 == 0 ? _h('#FFE050') : _h('#88E0F8');
  final c2 = phase % 2 == 0 ? _h('#88E0F8') : _h('#FFE050');
  b.rect(2, 3, 1, 2, c1);
  b.rect(4, 2, 1, 4, c2);
  b.rect(7, 1, 1, 6, c1);
  b.px(6, 1, c1);
  b.px(6, 6, c1);
}, outline: false);

/// Telephone ring-wave highlight (`suena103`), 14 × 7.
Sprite mkTelefonoRing(int phase) => _mk(14, 7, (b) {
  final c = phase % 2 == 0 ? _h('#FFE050') : _h('#FFF6B0');
  b.px(2, 3, c);
  b.px(3, 2, c);
  b.px(3, 4, c);
  b.px(11, 3, c);
  b.px(10, 2, c);
  b.px(10, 4, c);
  b.px(6, 1, c);
  b.px(7, 1, c);
}, outline: false);

/// Alternating study icon bubble over Luis (`aveces104`): `'compu'` (computer) or `'libro'` (book/notebook), 12 × 10.
Sprite mkAvecesPic(String kind) => _mk(12, 10, (b) {
  b.rect(1, 1, 10, 8, _h('#FFFDF4'));
  if (kind == 'compu') {
    b.rect(2, 2, 8, 5, _h('#464A58'));
    b.rect(3, 3, 6, 3, _h('#88D4F8'));
    b.rect(4, 7, 4, 1, _h('#464A58'));
  } else {
    b.rect(2, 2, 8, 6, _h('#B8402A'));
    b.rect(3, 3, 3, 4, _h('#FFFBEA'));
    b.rect(6, 3, 3, 4, _h('#FFF7DC'));
  }
});

/// Shut album cover with the frog's photo in the middle and [stars] (1..3) gold stars round it (`final104`), 18 × 14.
Sprite mkPortadaAlbum(int stars) => _mk(18, 14, (b) {
  final n = stars.clamp(1, 3);
  b.rect(1, 1, 16, 12, _h('#4A68A8'));
  b.rect(1, 1, 2, 12, _h('#364E84'));
  // Frog photo centred on the cover
  b.rect(5, 4, 8, 6, _h('#FFFBEA'));
  b.ell(9, 7.5, 2.5, 1.8, _ramp(const ['#3A8838', '#52B44A', '#80DC6A']));
  b.px(8, 6, _h('#FFFFFF'));
  b.px(10, 6, _h('#FFFFFF'));
  // 1..3 gold stars arranged around the photo
  if (n >= 1) b.rect(4, 2, 2, 2, _h('#FFD84A'));
  if (n >= 2) b.rect(13, 2, 2, 2, _h('#FFD84A'));
  if (n >= 3) b.rect(13, 10, 2, 2, _h('#FFD84A'));
});

/// Gold celebration star (9 × 9).
Sprite mkEstrellaSalaDia() => _mk(9, 9, (b) {
  final g = _h('#FFD84A'), hi = _h('#FFF29A');
  b.px(4, 1, hi);
  b.rect(3, 2, 3, 1, g);
  b.rect(1, 3, 7, 1, hi);
  b.rect(2, 4, 5, 1, g);
  b.rect(3, 5, 3, 1, g);
  b.rect(2, 6, 2, 1, g);
  b.rect(5, 6, 2, 1, g);
  b.px(1, 7, g);
  b.px(7, 7, g);
});

/// Pink celebration heart (9 × 9).
Sprite mkCorazonSalaDia() => _mk(9, 9, (b) {
  final r = _h('#E84868'), hi = _h('#FF8CA4');
  b.rect(2, 2, 2, 1, hi);
  b.rect(5, 2, 2, 1, r);
  b.rect(1, 3, 7, 2, r);
  b.px(2, 3, hi);
  b.rect(2, 5, 5, 1, r);
  b.rect(3, 6, 3, 1, r);
  b.px(4, 7, r);
});

/// Directional gesture cue arrow (9 × 7).
Sprite mkGestoFlechaSalaDia({bool up = false}) => _mk(9, 7, (b) {
  final c = _h('#FFE050');
  if (up) {
    b.px(4, 1, c);
    b.rect(3, 2, 3, 1, c);
    b.rect(2, 3, 5, 1, c);
    b.rect(4, 4, 1, 2, c);
  } else {
    b.rect(4, 1, 1, 2, c);
    b.rect(2, 3, 5, 1, c);
    b.rect(3, 4, 3, 1, c);
    b.px(4, 5, c);
  }
});

/// Every sprite unique to La sala, de día, for the content lane's sprite review sheet.
List<(String, Sprite)> salaDiaSpritesSheet() => [
  ('abuela_idle', mkAbuelaSalaDia('idle', false)),
  ('abuela_harina', mkAbuelaSalaDia('idle', false, harina: true)),
  ('abuela_silencio', mkAbuelaSalaDia('idle', false, silencio: true)),
  ('abuela_phone_ear', mkAbuelaSalaDia('idle', false, phone: 'ear')),
  ('abuela_phone_mouth', mkAbuelaSalaDia('idle', false, phone: 'mouth')),
  ('abuelo_idle', mkAbueloSalaDia('idle', false)),
  ('abuelo_doze', mkAbueloSalaDia('idle', false, doze: true)),
  ('abuelo_oreja', mkAbueloSalaDia('idle', false, cupEar: true)),
  ('abuelo_smile', mkAbueloSalaDia('idle', false, smile: true)),
  ('abuelo_nod', mkAbueloSalaDia('idle', false, nod: true)),
  ('abuelo_phone', mkAbueloSalaDia('idle', false, holdPhone: true)),
  ('luis_idle', mkNinoSalaDia(FAM['hermano']!, 'idle', false)),
  (
    'luis_notebook',
    mkNinoSalaDia(FAM['hermano']!, 'idle', false, notebook: true),
  ),
  ('luis_ball', mkNinoSalaDia(FAM['hermano']!, 'idle', false, ball: true)),
  ('luis_writes', mkNinoSalaDia(FAM['hermano']!, 'idle', false, writes: true)),
  ('carmen_idle', mkNinoSalaDia(FAM['hermana']!, 'idle', false)),
  (
    'carmen_writes',
    mkNinoSalaDia(FAM['hermana']!, 'idle', false, writes: true),
  ),
  ('libro_shut', mkLibro()),
  ('libro_open', mkLibro(open: true)),
  ('libro_scribbled', mkLibro(open: true, scribbled: true)),
  ('libro_patched', mkLibro(open: true, patched: true)),
  ('papel_5', mkPapel(5)),
  ('papel_3_frog', mkPapel(3, miniFrog: true)),
  ('papel_1', mkPapel(1)),
  ('papel_0', mkPapel(0)),
  ('telefono_dark', mkTelefono()),
  ('telefono_ring', mkTelefono(lit: true, ringing: true, bars: 3)),
  ('telefono_3', mkTelefono(lit: true, bars: 3)),
  ('telefono_2_blink', mkTelefono(lit: true, bars: 2, blink: true)),
  ('telefono_1', mkTelefono(lit: true, bars: 1)),
  ('pagina1', mkPagina(1)),
  ('pagina1_glow', mkPagina(1, glow: true)),
  ('pagina2', mkPagina(2)),
  ('pagina2_photo', mkPagina(2, hasPhoto: true)),
  ('pagina3', mkPagina(3)),
  ('pagina3_torn', mkPagina(3, torn: true)),
  ('estrellas_3', mkEstrellasBox(3)),
  ('estrellas_2', mkEstrellasBox(2)),
  ('estrellas_1', mkEstrellasBox(1)),
  ('estrellas_0', mkEstrellasBox(0)),
  ('foto_luis_compu', mkFoto('luis_computadora')),
  ('foto_abuela_libro', mkFoto('abuela_libro')),
  ('foto_abuelo_lee', mkFoto('abuelo_lee')),
  ('foto_abuela_escribe', mkFoto('abuela_escribe')),
  ('foto_carmen_juega', mkFoto('carmen_juega')),
  ('foto_luis_lee', mkFoto('luis_lee')),
  ('foto_abuela_juega', mkFoto('abuela_juega')),
  ('foto_torn', mkFoto('abuelo_lee', torn: true)),
  ('reloj_3', mkRelojManecillas()),
  ('lee_barco', mkLeePic('barco')),
  ('lee_estrella', mkLeePic('estrella')),
  ('hoja_escrita', mkHojaEscrita()),
  ('hoja_nombres', mkHojaEscrita(nombres: true)),
  ('avion_papel', mkAvionPapel()),
  ('dibujo_rana_1', mkDibujoRana(1)),
  ('dibujo_rana_2', mkDibujoRana(2)),
  ('dibujo_rana_3', mkDibujoRana(3)),
  ('voz_guagua', mkVozPic('guagua')),
  ('voz_playa', mkVozPic('playa')),
  ('voz_pez', mkVozPic('pez')),
  ('voz_sombrero', mkVozPic('sombrero')),
  ('anillos_0', mkAnillos(0)),
  ('anillos_1', mkAnillos(1)),
  ('telefono_ring_0', mkTelefonoRing(0)),
  ('aveces_compu', mkAvecesPic('compu')),
  ('aveces_libro', mkAvecesPic('libro')),
  ('portada_3', mkPortadaAlbum(3)),
  ('portada_2', mkPortadaAlbum(2)),
  ('portada_1', mkPortadaAlbum(1)),
  ('estrella_fx', mkEstrellaSalaDia()),
  ('corazon_fx', mkCorazonSalaDia()),
  ('gesto_flecha_dn', mkGestoFlechaSalaDia()),
  ('gesto_flecha_up', mkGestoFlechaSalaDia(up: true)),
];
