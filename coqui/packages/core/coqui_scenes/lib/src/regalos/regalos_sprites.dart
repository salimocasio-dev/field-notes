// Scene-specific sprites of Los regalos (place 10, El fuerte, scene 3: `regalos`, order 76):
// - Cast definitions matching regalos-preview.html (`PEPE` without apron, `MAESTRA` teal blouse/skirt, `PIRA` orange
//   shirt/stone trousers) plus story overlays (abuela with bright cloth / paper sheet / long match; abuelo shaking
//   box / holding fan; Carmen wearing straw hat; Luis shushing / counting fingers; guests holding hands out / clapping);
// - Curtain sprites matching regalos-sheet.json `things.cortina` (`49x49` shut on 3/2/1 pegs + shadow variant, `25x49`
//   half open);
// - Table, bench, cord, and stool props matching exact regalos-sheet.json box dimensions (cake 16x12 bench with/without
//   net, 14x14 table, 18x18 with 7 unlit/lit/7/5/3/0 candles + smoke; gift box 14x14; flowers 12x16 bench & 14x14
//   table; candle box 10x8; photos 12x12 hung & 11x10 table for 3m/7m/3a/7a; packets 14x14 table & 14x12 stool +
//   open/torn variants);
// - Tiny straw hat for frog (`sombrerito`), torn paper scraps, flying peg, wind/tag FX, celebration stars & heart,
//   and `regalosSpritesSheet()` for the content lane's sprite review sheet.
// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'package:coqui_pixel/coqui_pixel.dart';

int _h(String s) => hexColour(s);

List<int> _ramp(List<String> hs) => [for (final s in hs) _h(s)];

Sprite _mk(int w, int h, void Function(Buf b) draw, {bool outline = true}) {
  final b = Buf(w, h);
  draw(b);
  return outline ? b.outline().done() : b.done();
}

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

final List<int> _WHITE = _ramp(const [
  '#C8C8D0',
  '#E4E4EA',
  '#F6F6FA',
  '#FFFFFF',
]);

/// Party guest outfits matching regalos-preview.html (`PEPE`, `MAESTRA`, `PIRA`).
final Map<String, Who> REGALOS_PEOPLE = {
  'pepe': Who(
    piel: PIEL['c']!,
    pelo: PELO['negro']!,
    peinado: 'corto',
    ropa: _WHITE,
    abajo: RP.grey,
    bigote: true,
  ),
  'maestra': Who(
    piel: PIEL['a']!,
    pelo: PELO['negro']!,
    peinado: 'largo',
    ropa: RP.teal,
    falda: true,
    zapato: _h('#3A2414'),
  ),
  'piraguero': Who(
    piel: PIEL['c']!,
    pelo: PELO['negro']!,
    peinado: 'corto',
    ropa: RP.orng,
    abajo: RP.stone,
    bigote: true,
  ),
};

/* ---------- cast variants (same canvas & anchor as base makers) ---------- */

/// Standing abuela (`mkAbuela`) with optional story overlays: paper list sheet (`lista`), long match (`fosforo`),
/// or smoothing bright cloth (`mantel`).
Sprite mkAbuelaRegalos(
  String pose,
  bool open, {
  bool lista = false,
  bool fosforo = false,
}) {
  final base = mkAbuela(pose, open);
  if (!lista && !fosforo) return base;
  return _overlayOn(base, (b) {
    if (lista) {
      // Sheet of paper held in hand (cols 22..27, rows 24..31).
      b.rect(22, 24, 6, 8, _h('#FFFFFF'));
      b.rect(23, 26, 4, 1, _h('#88A0C8'));
      b.rect(23, 28, 3, 1, _h('#88A0C8'));
      b.rect(23, 30, 4, 1, _h('#88A0C8'));
    }
    if (fosforo) {
      // Long lit match held out to the right (cols 35..41, rows 24..26).
      b.rect(35, 25, 5, 1, _h('#D8A860'));
      b.rect(40, 24, 2, 2, _h('#FFE050'));
      b.px(41, 24, _h('#FF8030'));
    }
  });
}

/// Standing person (`mkPersona`) with optional story overlays: straw hat (`sombrero`), paper fan (`abanico`),
/// shush finger (`silencio`), counting fingers (`dedos`), hands held out (`manos`), clapping (`aplaude`),
/// or hiding eyes (`ojos` for 1-peg laughing Carmen).
Sprite mkPersonaRegalos(
  Who w,
  String pose,
  bool open, {
  bool sombrero = false,
  bool abanico = false,
  bool silencio = false,
  bool dedos = false,
  bool manos = false,
  bool aplaude = false,
  bool ojos = false,
}) {
  final base = mkPersona(w, pose, open, false);
  if (!sombrero &&
      !abanico &&
      !silencio &&
      !dedos &&
      !manos &&
      !aplaude &&
      !ojos) {
    return base;
  }
  final skin = w.piel[2];
  return _overlayOn(base, (b) {
    if (sombrero) {
      // Straw sun hat sitting neatly on head top (stays within existing top rows).
      final yTop = w.nino ? 2 : 4;
      b.rect(17, yTop + 2, 14, 2, _h('#E8C870'));
      b.rect(19, yTop, 10, 2, _h('#D8B458'));
      b.rect(19, yTop + 1, 10, 1, _h('#D0403A'));
    }
    if (abanico) {
      // Open folded paper fan in right hand (cols 30..36, rows 25..31).
      b.rect(30, 26, 6, 5, _h('#FFF0C0'));
      b.px(31, 26, _h('#E86878'));
      b.px(33, 26, _h('#E86878'));
      b.px(35, 26, _h('#E86878'));
      b.rect(32, 30, 2, 2, _h('#B88440'));
    }
    if (silencio) {
      // Finger held to lips.
      final my = w.nino ? 11 : 13;
      b.rect(23, my, 2, 4, skin);
      b.px(23, my - 1, _h('#1F1A24'));
    }
    if (dedos) {
      // Raised counting fingers beside shoulder.
      final y0 = w.nino ? 15 : 18;
      b.rect(31, y0, 3, 4, skin);
      b.px(31, y0 - 1, skin);
      b.px(33, y0 - 1, skin);
    }
    if (manos) {
      // Both hands held out in front (ready to give or receive).
      final y0 = w.nino ? 21 : 26;
      b.rect(16, y0, 3, 2, skin);
      b.rect(29, y0, 3, 2, skin);
    }
    if (aplaude) {
      // Clapping hands together with two tiny spark pixels.
      final y0 = w.nino ? 20 : 25;
      b.rect(22, y0, 4, 3, skin);
      b.px(21, y0 - 1, _h('#FFE070'));
      b.px(26, y0 - 1, _h('#FFE070'));
    }
    if (ojos) {
      // Hands playfully over eyes (1-peg ending).
      b.rect(19, 8, 4, 3, skin);
      b.rect(25, 8, 4, 3, skin);
    }
  });
}

/* ---------- curtain sprites (regalos-sheet.json: box 49x49, half 25x49) ---------- */

/// The curtain across the arch (`49x49` shut, `25x49` half open).
/// [pegs]: 3 = whole across top, 2 = right corner sagging, 1 = hanging by left peg;
/// [shadow]: Carmen's dark silhouette cast through the cloth (`sombra114`).
Sprite mkCortina({bool half = false, int pegs = 3, bool shadow = false}) {
  final w = half ? 25 : 49;
  const h = 49;
  return _mk(w, h, (b) {
    final C = _ramp(const ['#8A2E48', '#B04466', '#D26A86', '#E896AC']);
    final pegCount = pegs.clamp(1, 3);
    for (var x = 1; x < w - 1; x++) {
      // Top row sags down toward the right when pegs are lost (only on shut curtain).
      var topY = 3;
      if (!half && pegCount == 2 && x > w ~/ 2) {
        topY = 3 + ((x - w ~/ 2) * 14) ~/ (w ~/ 2);
      } else if (!half && pegCount == 1 && x > 6) {
        topY = 3 + ((x - 6) * 26) ~/ (w - 7);
      }
      final k = x % 6;
      final c = k == 0
          ? C[0]
          : (k == 1 || k == 5)
          ? C[1]
          : (k == 2 || k == 4)
          ? C[2]
          : C[3];
      if (h - 1 - topY > 0) {
        b.rect(x, topY, 1, h - 1 - topY, c);
        b.px(x, topY, _h('#6A2038'));
      }
    }
    b.rect(1, h - 3, w - 2, 2, _h('#6A2038'));
    // Wooden pegs along the top cord (3 -> all three, 2 -> left + middle, 1 -> left only).
    final pegXs = [4, w ~/ 2, w - 5];
    final count = half ? 3 : pegCount;
    for (var i = 0; i < count; i++) {
      final px = pegXs[i];
      b.rect(px - 1, 1, 3, 4, _h('#E2BE78'));
      b.rect(px - 1, 1, 1, 4, _h('#B48A44'));
    }
    if (shadow && !half) {
      // Dark silhouette of Carmen approaching from behind the curtain.
      final sh = _h('#4A1428');
      b.ell(24, 21, 5, 5, [sh, sh, sh]);
      b.rect(19, 26, 10, 14, sh);
      b.rect(18, 36, 12, 8, sh);
    }
  });
}

/* ---------- cake, box, flowers, candle box, photos, packets (exact sheet sizes) ---------- */

/// Birthday cake:
/// - on bench (`16x12`, with or without net cover);
/// - on table without candles (`14x14`);
/// - on table with 7 candles (`18x18`, [litCandles] = 0..7 burning, [smoked] = true shows black wicks & tiny smoke).
Sprite mkBizcocho(
  int w,
  int h, {
  bool net = false,
  bool candles = false,
  int litCandles = 0,
  bool smoked = false,
  bool cut = false,
}) => _mk(w, h, (b) {
  final y0 = candles ? 4 : 3;
  final cx = w ~/ 2;
  b.rect(1, y0, w - 2, 3, _h('#FFFBEA'));
  b.rect(1, y0 + 3, w - 2, h - 2 - (y0 + 3), _h('#F2D6A8'));
  b.rect(1, h - 2, w - 2, 1, _h('#C8A070'));
  b.rect(1, y0 + 3, w - 2, 1, _h('#E4C48C'));
  if (cut) {
    // Missing slice on right side (story 116)
    b.rect(w - 5, y0, 4, h - 2 - y0, _h('#D8A878'));
    b.rect(w - 4, y0 + 2, 2, 2, _h('#E85868'));
  }
  if (candles) {
    for (var k = 0; k < 7; k++) {
      final x = (w - 13) ~/ 2 + 2 * k;
      final isLit = k < litCandles;
      b.rect(x, 1, 1, 4, _h('#FBF0D2'));
      if (isLit) {
        b.px(x, 1, _h('#FFC030'));
        b.px(x, 2, _h('#FBF0D2'));
      } else if (smoked) {
        b.px(x, 1, _h('#9CA6B4')); // wisp of smoke
        b.px(x, 2, _h('#2C2428')); // blackened wick
      } else {
        b.px(x, 1, _h('#5A4030'));
      }
    }
  } else {
    b.rect(cx - 1, 1, 3, 2, _h('#D0403A'));
    b.px(cx, 1, _h('#F2705A'));
    b.px(cx, 2, _h('#FFE070'));
    b.px(cx - 3, y0, _h('#E2402E'));
    b.px(cx + 3, y0, _h('#E2402E'));
  }
  if (net) {
    for (var y = 1; y < h - 1; y++) {
      for (var x = 1; x < w - 1; x++) {
        if ((x + y) % 3 == 0 && y >= y0 - 2) b.px(x, y, _h('#DCE6EE'));
      }
    }
  }
});

/// Wrapped present box with red bow (`14x14`, matching regalos-sheet.json `regalo`).
Sprite mkRegaloBox({bool shaken = false}) => _mk(14, 14, (b) {
  b.rect(1, 5, 12, 8, _h('#E8A0C0'));
  b.rect(1, 5, 12, 1, _h('#F8C8DC'));
  b.rect(1, 12, 12, 1, _h('#B87898'));
  b.rect(6, 5, 2, 8, _h('#FFFBEA'));
  b.rect(1, 8, 12, 2, _h('#FFFBEA'));
  b.ell(4.4, 3.4, 2.4, 1.8, _ramp(const ['#B02828', '#D0403A', '#F08070']));
  b.ell(9.6, 3.4, 2.4, 1.8, _ramp(const ['#B02828', '#D0403A', '#F08070']));
  b.rect(6, 3, 2, 3, _h('#B02828'));
  if (shaken) {
    b.px(1, 2, _h('#FFE070'));
    b.px(12, 2, _h('#FFE070'));
  }
});

/// Bunch of flowers in a glass jar (`12x16` on bench, `14x14` on table, matching regalos-sheet.json `flores`).
Sprite mkFlores(int w, int h) => _mk(w, h, (b) {
  final cx = w ~/ 2, dy = h - 16;
  b.rect(cx - 3, h - 6, 6, 5, _h('#9CCBF5'));
  b.rect(cx - 3, h - 6, 1, 5, _h('#E8F4FF'));
  b.rect(cx - 2, h - 4, 4, 2, _h('#6FA8DC'));
  b.line(cx - 2, 6 + dy, cx - 1, h - 6, _h('#389838'));
  b.line(cx, 5 + dy, cx, h - 6, _h('#389838'));
  b.line(cx + 2, 7 + dy, cx + 1, h - 6, _h('#389838'));
  b.ell(cx - 2.6, 4 + dy, 2, 2, _ramp(const ['#B02828', '#D0403A', '#FA9080']));
  b.ell(cx, 2.6 + dy, 2, 2, _ramp(const ['#D0A010', '#F8C838', '#FFE890']));
  b.ell(cx + 2.8, 5 + dy, 2, 2, _ramp(const ['#C8C8D8', '#F4F4FA', '#FFFFFF']));
});

/// Box of birthday candles (`10x8`, matching regalos-sheet.json `caja_velas`).
Sprite mkCajaVelas({bool empty = false}) => _mk(10, 8, (b) {
  b.rect(1, 3, 8, 4, _h('#F2A650'));
  b.rect(1, 3, 8, 1, _h('#FFD080'));
  b.rect(1, 6, 8, 1, _h('#B87020'));
  if (!empty) {
    for (final x in const [2, 4, 6, 7]) {
      b.rect(x, 1, 1, 2, _h('#FBF0D2'));
    }
  }
});

const Map<String, String> _FOTO_BG = {
  '3m': '#BCD8F0',
  '7m': '#F8E0A8',
  '3a': '#B8E0B0',
  '7a': '#F8C8D8',
};

/// Photo of Carmen (`3m`, `7m`, `3a`, `7a`): `12x12` hung from a peg on the cord, or `11x10` lying on the table.
Sprite mkFotoRegalos(String kind, {required bool hung}) {
  final w = hung ? 12 : 11;
  final h = hung ? 12 : 10;
  return _mk(w, h, (b) {
    final y0 = hung ? 3 : 1;
    final ph = h - 1 - y0;
    final cx = w ~/ 2;
    b.rect(1, y0, w - 2, ph, _h('#FBF4DC'));
    b.rect(2, y0 + 1, w - 4, ph - 2, _h(_FOTO_BG[kind] ?? '#BCD8F0'));
    final mx = cx, my = y0 + 1 + (ph - 2) ~/ 2;
    if (kind == '3m') {
      b.ell(mx, my + 1, 2.6, 2, _ramp(const ['#8FB0D8', '#C8DCF0', '#FFFFFF']));
      b.px(mx + 1, my - 1, _h('#E8B088'));
      b.px(mx + 2, my - 1, _h('#E8B088'));
    } else if (kind == '7m') {
      b.ell(
        mx - .5,
        my + 1,
        2.2,
        2,
        _ramp(const ['#E8C060', '#F8E090', '#FFF4C0']),
      );
      b.px(mx - 1, my - 1, _h('#E8B088'));
      b.px(mx, my - 1, _h('#E8B088'));
      b.px(mx + 2, my + 1, _h('#C0C0D0'));
      b.px(mx + 3, my, _h('#C0C0D0'));
    } else if (kind == '3a') {
      b.px(mx - 1, my - 1, _h('#E8B088'));
      b.px(mx, my - 1, _h('#E8B088'));
      b.rect(mx - 1, my, 2, 2, _h('#D0407A'));
      b.px(mx + 2, my + 1, _h('#D0403A'));
      b.px(mx + 3, my + 1, _h('#D0403A'));
    } else {
      b.rect(mx - 1, my - 2, 2, 1, _h('#44260E'));
      b.px(mx - 1, my - 1, _h('#E8B088'));
      b.px(mx, my - 1, _h('#E8B088'));
      b.rect(mx - 2, my, 4, 2, _h('#E0609A'));
    }
    if (hung) {
      b.rect(cx - 1, 1, 2, 3, _h('#E2BE78'));
      b.px(cx - 1, 1, _h('#B48A44'));
    }
  });
}

/// Wrapped gift packet (`14x14` on table, `14x12` on low stool): [tagged] = paper name tag attached (before wind),
/// [open] = neatly opened gift box (right push in 116), [torn] = torn paper and no bow (wrong push in 116).
Sprite mkPaquete(
  int w,
  int h, {
  bool tagged = false,
  bool torn = false,
  bool open = false,
}) => _mk(w, h, (b) {
  final cx = w ~/ 2;
  if (torn) {
    // Torn open packet, bow gone, surprise peeking out
    b.rect(1, 5, w - 2, h - 6, _h('#78B092'));
    b.rect(3, 3, w - 6, 4, _h('#FFF0B8'));
    b.px(2, 5, _h('#B4E0C8'));
    b.px(w - 3, 5, _h('#B4E0C8'));
    b.rect(5, 4, 4, 2, _h('#E86878'));
  } else if (open) {
    // Neatly opened box with lifted lid & golden gift glow inside
    b.rect(1, 5, w - 2, h - 6, _h('#8EC8A8'));
    b.rect(1, h - 2, w - 2, 1, _h('#5E9C80'));
    b.rect(2, 5, w - 4, 2, _h('#FFF0B8'));
    b.rect(2, 2, w - 4, 2, _h('#B4E0C8'));
    b.rect(cx - 1, 2, 2, 2, _h('#D0403A'));
    b.px(cx, 4, _h('#FFE050'));
    b.px(cx - 2, 3, _h('#FFE050'));
    b.px(cx + 2, 3, _h('#FFE050'));
  } else {
    b.rect(1, 4, w - 2, h - 5, _h('#8EC8A8'));
    b.rect(1, 4, w - 2, 1, _h('#B4E0C8'));
    b.rect(1, h - 2, w - 2, 1, _h('#5E9C80'));
    b.rect(cx - 1, 4, 2, h - 5, _h('#FFFBEA'));
    b.ell(
      cx - 2.4,
      3,
      2.2,
      1.6,
      _ramp(const ['#B02828', '#D0403A', '#F08070']),
    );
    b.ell(
      cx + 2.4,
      3,
      2.2,
      1.6,
      _ramp(const ['#B02828', '#D0403A', '#F08070']),
    );
    b.rect(cx - 1, 2, 2, 3, _h('#B02828'));
    if (tagged) {
      b.rect(w - 4, 6, 3, 3, _h('#FFFBEA'));
      b.px(w - 3, 7, _h('#3A3A46'));
    }
  }
});

/* ---------- FX & ending props ---------- */

/// Torn wrapping paper scrap on the floor by the low stool (`final116`), 10 × 6.
Sprite mkPapelRoto() => _mk(10, 6, (b) {
  b.rect(1, 2, 8, 3, _h('#8EC8A8'));
  b.rect(2, 1, 4, 2, _h('#B4E0C8'));
  b.px(7, 2, _h('#D0403A'));
});

/// Tiny straw hat worn by Coquí (`abre116`, `sombrerito`), 12 × 6.
Sprite mkSombrerito() => _mk(12, 6, (b) {
  b.rect(1, 3, 10, 2, _h('#E8C870'));
  b.rect(3, 1, 6, 2, _h('#D8B458'));
  b.rect(3, 2, 6, 1, _h('#D0403A'));
});

/// Overlays Coquí's tiny straw hat onto a rendered frog canvas at `(hx, hy)`.
Sprite overlaySombreritoOnFrog(Sprite base, int hx, int hy) {
  final ht = mkSombrerito();
  return _overlayOn(base, (buf) {
    for (var py = 0; py < ht.h; py++) {
      for (var px0 = 0; px0 < ht.w; px0++) {
        final c = ht.px[py * ht.w + px0];
        if (c >>> 24 == 0) continue;
        final tx = hx + px0, ty = hy + py;
        if (tx >= 0 && tx < base.w && ty >= 0 && ty < base.h) {
          buf.px(tx, ty, c);
        }
      }
    }
  });
}

/// Bright cloth banner highlight during `mantel114`, 32 × 5.
Sprite mkMantelBrillo() => _mk(32, 5, (b) {
  for (var x = 1; x < 31; x++) {
    b.rect(x, 1, 1, 3, (x ~/ 3) % 2 == 0 ? _h('#FFE050') : _h('#E85868'));
  }
});

/// Wind gust streaks (`viento115`, `etiquetas116`), 18 × 8.
Sprite mkVientoFx(int phase) => _mk(18, 8, (b) {
  final c = phase % 2 == 0 ? _h('#DCEEFF') : _h('#FFFFFF');
  b.rect(2, 2, 10, 1, c);
  b.rect(5, 5, 11, 1, c);
  b.px(12, 1, c);
  b.px(16, 4, c);
}, outline: false);

/// Flying wooden peg (`lleva114` wrong), 6 × 6.
Sprite mkPinzaVolando() => _mk(6, 6, (b) {
  b.rect(2, 1, 2, 4, _h('#E2BE78'));
  b.px(2, 1, _h('#B48A44'));
});

/// Celebration star (9 × 9).
Sprite mkEstrellaRegalos() => _mk(9, 9, (b) {
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

/// Celebration heart (9 × 9).
Sprite mkCorazonRegalos() => _mk(9, 9, (b) {
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
Sprite mkGestoFlechaRegalos({bool up = false}) => _mk(9, 7, (b) {
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

/// Every sprite unique to Los regalos, for the content lane's sprite review sheet.
List<(String, Sprite)> regalosSpritesSheet() => [
  ('abuela_idle', mkAbuelaRegalos('idle', false)),
  ('abuela_lista', mkAbuelaRegalos('idle', false, lista: true)),
  ('abuela_fosforo', mkAbuelaRegalos('idle', false, fosforo: true)),
  ('abuelo_idle', mkPersonaRegalos(FAM['abuelo']!, 'idle', false)),
  (
    'abuelo_abanico',
    mkPersonaRegalos(FAM['abuelo']!, 'idle', false, abanico: true),
  ),
  ('luis_idle', mkPersonaRegalos(FAM['hermano']!, 'idle', false)),
  (
    'luis_silencio',
    mkPersonaRegalos(FAM['hermano']!, 'idle', false, silencio: true),
  ),
  ('luis_dedos', mkPersonaRegalos(FAM['hermano']!, 'idle', false, dedos: true)),
  ('carmen_idle', mkPersonaRegalos(FAM['hermana']!, 'idle', false)),
  (
    'carmen_sombrero',
    mkPersonaRegalos(FAM['hermana']!, 'idle', false, sombrero: true),
  ),
  (
    'carmen_manos',
    mkPersonaRegalos(FAM['hermana']!, 'idle', false, manos: true),
  ),
  ('carmen_ojos', mkPersonaRegalos(FAM['hermana']!, 'idle', false, ojos: true)),
  ('pepe_idle', mkPersonaRegalos(REGALOS_PEOPLE['pepe']!, 'idle', false)),
  (
    'pepe_aplaude',
    mkPersonaRegalos(REGALOS_PEOPLE['pepe']!, 'idle', false, aplaude: true),
  ),
  ('maestra_idle', mkPersonaRegalos(REGALOS_PEOPLE['maestra']!, 'idle', false)),
  (
    'maestra_manos',
    mkPersonaRegalos(REGALOS_PEOPLE['maestra']!, 'idle', false, manos: true),
  ),
  (
    'piraguero_idle',
    mkPersonaRegalos(REGALOS_PEOPLE['piraguero']!, 'idle', false),
  ),
  (
    'piraguero_manos',
    mkPersonaRegalos(REGALOS_PEOPLE['piraguero']!, 'idle', false, manos: true),
  ),
  ('cortina_half', mkCortina(half: true)),
  ('cortina_3', mkCortina(pegs: 3)),
  ('cortina_3_sombra', mkCortina(pegs: 3, shadow: true)),
  ('cortina_2', mkCortina(pegs: 2)),
  ('cortina_1', mkCortina(pegs: 1)),
  ('bizcocho_red', mkBizcocho(16, 12, net: true)),
  ('bizcocho_banco', mkBizcocho(16, 12)),
  ('bizcocho_mesa', mkBizcocho(14, 14)),
  ('bizcocho_7_unlit', mkBizcocho(18, 18, candles: true)),
  ('bizcocho_7_lit', mkBizcocho(18, 18, candles: true, litCandles: 7)),
  (
    'bizcocho_5_lit',
    mkBizcocho(18, 18, candles: true, litCandles: 5, smoked: true),
  ),
  (
    'bizcocho_3_lit',
    mkBizcocho(18, 18, candles: true, litCandles: 3, smoked: true),
  ),
  (
    'bizcocho_0_out',
    mkBizcocho(18, 18, candles: true, litCandles: 0, smoked: true),
  ),
  ('bizcocho_cut', mkBizcocho(14, 14, cut: true)),
  ('regalo', mkRegaloBox()),
  ('regalo_shaken', mkRegaloBox(shaken: true)),
  ('flores_banco', mkFlores(12, 16)),
  ('flores_mesa', mkFlores(14, 14)),
  ('caja_velas', mkCajaVelas()),
  ('caja_velas_empty', mkCajaVelas(empty: true)),
  ('foto_cuerda_3m', mkFotoRegalos('3m', hung: true)),
  ('foto_cuerda_7m', mkFotoRegalos('7m', hung: true)),
  ('foto_cuerda_3a', mkFotoRegalos('3a', hung: true)),
  ('foto_cuerda_7a', mkFotoRegalos('7a', hung: true)),
  ('foto_mesa_3m', mkFotoRegalos('3m', hung: false)),
  ('foto_mesa_7m', mkFotoRegalos('7m', hung: false)),
  ('foto_mesa_3a', mkFotoRegalos('3a', hung: false)),
  ('foto_mesa_7a', mkFotoRegalos('7a', hung: false)),
  ('paquete_mesa_tag', mkPaquete(14, 14, tagged: true)),
  ('paquete_mesa', mkPaquete(14, 14)),
  ('paquete_stool', mkPaquete(14, 12)),
  ('paquete_stool_open', mkPaquete(14, 12, open: true)),
  ('paquete_stool_torn', mkPaquete(14, 12, torn: true)),
  ('papel_roto', mkPapelRoto()),
  ('sombrerito', mkSombrerito()),
  ('mantel_brillo', mkMantelBrillo()),
  ('viento_0', mkVientoFx(0)),
  ('pinza_volando', mkPinzaVolando()),
  ('estrella_fx', mkEstrellaRegalos()),
  ('corazon_fx', mkCorazonRegalos()),
  ('gesto_flecha_dn', mkGestoFlechaRegalos()),
  ('gesto_flecha_up', mkGestoFlechaRegalos(up: true)),
];
