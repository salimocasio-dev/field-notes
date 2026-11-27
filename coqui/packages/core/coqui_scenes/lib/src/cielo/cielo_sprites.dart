// Scene-specific sprites of El cielo (place 7, La playa, scene 4: `cielo`, order 65):
// - Preview-matching sprites (cielo-preview.html, exact dimensions matching cielo-sheet.json boxes):
//   radio (12 x 9), vela (6 x 10: lit, leaning, out, hissing), tapaPuesta (26 x 18 glass dome), tapaSuelo (18 x 16
//   glass dome), chal (10 x 8 folded shawl), bandeja (20 x 10 tray with 3..1 glasses, optional straws/spilled),
//   sombrillaShut (8 x 44), sombrillaOpen (64 x 60 canopy + pole), chiringa (20 x 12), bola (9 x 9), telescopio
//   (14 x 22 tripod + cardboard tube), visor (28 x 28 round eyepiece view: moon, star, with or without falling light).
// - Additional Needs sprites (cielo.md): radio music notes & bubble (with optional sun), umbrella blown sideways,
//   flying kite, gull, big cloud, wind gusts, sun glow, rain layer, table raindrop splash, shawl draped on abuela,
//   supper plate, falling light in night sky, fingers count, wishing sparkles, frog song wave, answering coquí voices,
//   and heart celebration.
// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'dart:math' as math;

import 'package:coqui_pixel/coqui_pixel.dart';

int _h(String s) => hexColour(s);

List<int> _ramp(List<String> hs) => [for (final s in hs) _h(s)];

Sprite _mk(int w, int h, void Function(Buf b) draw, {bool outline = true}) {
  final b = Buf(w, h);
  draw(b);
  return outline ? b.outline().done() : b.done();
}

int _round(num v) => (v + 0.5).floor();

/* ---------- cielo-preview.html core props (exact box dimensions) ---------- */

/// Table radio: 12 x 9 (cielo-preview.html `THING.radio`, matches `spots.radio` [54,138,12,9]).
Sprite mkRadio() => _mk(12, 9, (b) {
  b.rect(0, 1, 12, 8, _h('#7A4A1E'));
  b.rect(1, 2, 7, 6, _h('#C8B070'));
  for (final y in const [3, 5, 7]) {
    b.rect(2, y, 5, 1, _h('#5A4A2A'));
  }
  b.ell(10, 5, 1.4, 1.4, [_h('#E8E0C8')]);
  b.line(2, 0, 7, 1, _h('#B8B8C8'));
});

/// Candle in a glass jar: 6 x 10 (cielo-preview.html `THING.vela`, matches `spots.velas.parts`).
/// [lit]: flame burning; [lean]: flame blown sideways by wind; [hiss]: raindrop hiss / smoke wisp when out.
Sprite mkVela({bool lit = true, bool lean = false, bool hiss = false}) =>
    _mk(6, 10, (b) {
      b.rect(0, 4, 6, 6, _h('#8CB8D8'));
      b.rect(1, 5, 4, 4, _h('#E8F4FA'));
      b.rect(2, 3, 2, 2, _h('#FFFBEA'));
      if (lit) {
        if (lean) {
          b.px(3, 2, _h('#FFFBEA'));
          b.px(4, 1, _h('#F8C838'));
          b.px(5, 1, _h('#FFE070'));
          b.px(4, 2, _h('#F8A028'));
        } else {
          b.px(2, 2, _h('#FFFBEA'));
          b.px(3, 2, _h('#FFFBEA'));
          b.px(2, 1, _h('#F8C838'));
          b.px(3, 1, _h('#F8C838'));
          b.px(2, 0, _h('#FFE070'));
        }
      } else {
        b.px(2, 2, _h('#4A4A54'));
        if (hiss) {
          b.px(2, 1, _h('#C8D8E8'));
          b.px(3, 0, _h('#E8F0F8'));
          b.px(1, 1, _h('#98C8F0'));
        } else {
          b.px(3, 1, _h('#B0B4C0'));
        }
      }
    });

/// Glass dome drawn as a transparent outline edge with specular highlights (cielo-preview.html `dome`).
/// No base row so what stands inside is not crossed.
Sprite _mkDome(int w, int h) {
  final b = Buf(w, h);
  bool inside(int x, int y) {
    if (y < 0 || x < 0 || x >= w) return false;
    if (y >= h) return true;
    final nx = (x + .5 - w / 2) / (w / 2);
    final ny = (y + .5 - h) / h;
    return nx * nx + ny * ny <= 1;
  }

  final edge = _h('#7FB4D8');
  final hi = _h('#FFFFFF');
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      if (inside(x, y) &&
          !(inside(x - 1, y) &&
              inside(x + 1, y) &&
              inside(x, y - 1) &&
              inside(x, y + 1))) {
        b.px(x, y, edge);
      }
    }
  }
  b.px(_round(w * .22), _round(h * .38), hi);
  b.px(_round(w * .22), _round(h * .38) + 1, hi);
  b.px(_round(w * .3), _round(h * .2), hi);
  return b.done();
}

/// Glass cover over the three candles: 26 x 18 (matches `spots.tapa_puesta`).
Sprite mkTapaPuesta() => _mkDome(26, 18);

/// Glass cover standing on the deck floor: 18 x 16 (matches `spots.tapa`).
Sprite mkTapaSuelo() => _mkDome(18, 16);

/// Folded shawl on the deck floor: 10 x 8 (cielo-preview.html `THING.chal`, matches `spots.chal`).
Sprite mkChal() => _mk(10, 8, (b) {
  b.rect(0, 0, 10, 6, _h('#C8503C'));
  b.rect(0, 2, 10, 1, _h('#F4E0A0'));
  b.rect(0, 4, 10, 1, _h('#F4E0A0'));
  for (final x in const [1, 3, 5, 7, 9]) {
    b.px(x, 6, _h('#C8503C'));
  }
  for (final x in const [0, 2, 4, 6, 8]) {
    b.px(x, 7, _h('#F4E0A0'));
  }
});

/// Tray with [vasos] (1..3) tall glasses of orange juice: 20 x 10 (cielo-preview.html `THING.bandeja`, matches `spots.bandeja`).
/// When [finalMode] is true, shows extra straws (1 glass: 4 straws; 2 glasses: shared straw; 3 glasses: 3 straws).
Sprite mkBandeja(int vasos, {bool finalMode = false}) {
  final n = vasos.clamp(1, 3);
  return _mk(20, 10, (b) {
    b.rect(0, 8, 20, 2, _h('#A8682C'));
    b.rect(0, 8, 20, 1, _h('#C8853C'));
    final xs = const [2, 8, 14];
    for (var i = 0; i < 3; i++) {
      final x = xs[i];
      if (i < n) {
        b.rect(x, 1, 4, 7, _h('#F2A650'));
        b.rect(x, 1, 4, 1, _h('#FFE8B0'));
        b.rect(x + 1, 0, 1, 3, _h('#D0403A'));
        if (finalMode && n == 1 && i == 0) {
          // Four straws in the one remaining glass
          b.line(x, 2, x - 1, 0, _h('#40A868'));
          b.line(x + 2, 2, x + 3, 0, _h('#4088D8'));
          b.line(x + 3, 2, x + 5, 0, _h('#E85898'));
        } else if (finalMode && n == 2 && i == 1) {
          // Shared second straw
          b.line(x + 2, 2, x + 4, 0, _h('#40A868'));
        }
      } else {
        // Knocked-over glass & juice spill on the tray
        b.rect(x, 6, 5, 2, _h('#D8E8F4'));
        b.rect(x + 1, 7, 4, 1, _h('#F2A650'));
      }
    }
  });
}

/// Shut beach umbrella: 8 x 44 (cielo-preview.html `THING.sombrillaShut`, matches `spots.sombrilla`).
Sprite mkSombrillaShut() => _mk(8, 44, (b) {
  b.ell(4, 17, 3.6, 17, _ramp(const ['#B82A26', '#D0403A', '#FA9080']));
  for (final y in const [6, 12, 18, 24]) {
    b.rect(1, y, 6, 1, _h('#F4F0E4'));
  }
  b.rect(3, 34, 2, 10, _h('#7A4A1E'));
  b.px(3, 0, _h('#7A4A1E'));
});

/// Open beach umbrella: 64 x 60, canopy 64 x 16 whose foot is 44 px above the sand (cielo-preview.html `THING.sombrillaOpen`).
Sprite mkSombrillaOpen() => _mk(64, 60, (b) {
  final cream = _h('#F4F0E4');
  final red = _h('#D0403A');
  for (var y = 0; y < 16; y++) {
    for (var x = 0; x < 64; x++) {
      final nx = (x + .5 - 32) / 32;
      final ny = (y + .5 - 16) / 16;
      if (nx * nx + ny * ny <= 1) {
        b.px(x, y, ((x ~/ 8) % 2 != 0) ? cream : red);
      }
    }
  }
  b.rect(31, 16, 2, 44, _h('#7A4A1E'));
});

/// Beach umbrella blown sideways onto the tray (`tropiezo81 sombrilla`): 24 x 12.
Sprite mkSombrillaCaida() => _mk(24, 12, (b) {
  b.ell(10, 6, 9, 4.5, _ramp(const ['#B82A26', '#D0403A', '#FA9080']));
  for (final x in const [5, 10, 15]) {
    b.rect(x, 2, 1, 8, _h('#F4F0E4'));
  }
  b.rect(18, 5, 6, 2, _h('#7A4A1E'));
});

/// Diamond kite lying on the sand: 20 x 12 (cielo-preview.html `THING.chiringa`, matches `spots.chiringa`).
Sprite mkChiringa() => _mk(20, 12, (b) {
  final red = _h('#D0403A');
  final gold = _h('#F8C838');
  for (var y = 0; y < 12; y++) {
    final hw = _round(9.5 * (1 - (y - 5.5).abs() / 6));
    for (var x = 10 - hw; x < 10 + hw; x++) {
      b.px(x, y, x < 10 ? red : gold);
    }
  }
  b.line(1, 5, 18, 5, _h('#7A4A1E'));
  b.line(10, 0, 10, 11, _h('#7A4A1E'));
});

/// Kite flying in the sky with fluttering ribbon tail: 20 x 20.
Sprite mkChiringaVuela(int frame) => _mk(20, 20, (b) {
  final red = _h('#D0403A');
  final gold = _h('#F8C838');
  for (var y = 0; y < 12; y++) {
    final hw = _round(7.5 * (1 - (y - 5.5).abs() / 6));
    for (var x = 10 - hw; x < 10 + hw; x++) {
      b.px(x, y, x < 10 ? red : gold);
    }
  }
  b.line(3, 5, 16, 5, _h('#7A4A1E'));
  b.line(10, 0, 10, 11, _h('#7A4A1E'));
  final sway = frame % 2 == 0 ? 1 : -1;
  b.line(10, 12, 10 + sway, 15, _h('#F4F0E4'));
  b.line(10 + sway, 15, 10 - sway, 19, _h('#F4F0E4'));
  b.px(10 + sway, 14, _h('#D0403A'));
  b.px(10 - sway, 17, _h('#3E8CE8'));
});

/// Beach ball: 9 x 9 (cielo-preview.html `THING.bola`, matches `spots.bola`).
Sprite mkBolaCielo() => _mk(9, 9, (b) {
  b.ell(4.5, 4.5, 3.9, 3.9, _ramp(const ['#2E6CD0', '#4A8CE8', '#B0D4FF']));
  b.line(1, 4, 7, 4, _h('#FFFFFF'));
});

/// Cardboard tube telescope on wooden tripod: 14 x 22 (cielo-preview.html `THING.telescopio`, matches `spots.telescopio`).
/// [dir]: `'luna'` (pointing upper-left toward moon), `'estrella'` (upper-right toward star), `'up'` (default).
Sprite mkTelescopio({String dir = 'up'}) => _mk(14, 22, (b) {
  final wood = _h('#6E4A2A');
  final tube = _ramp(const ['#B8884A', '#D8B878', '#F0DCA8']);
  b.line(7, 10, 2, 21, wood);
  b.line(7, 10, 12, 21, wood);
  b.line(7, 10, 7, 21, wood);
  if (dir == 'luna') {
    b.cap(11, 7, 3, 2, 1.8, tube);
  } else {
    b.cap(3, 7, 11, 2, 1.8, tube);
  }
});

/// Round telescope eyepiece picture: 28 x 28 (cielo-preview.html `THING.visor`, matches `spots.visor` [186,104,28,28]).
/// [what]: `'luna'` (close-up moon) or `'estrella'` (close-up big four-pointed star).
/// [cae]: when true, draws a bright falling light with tail streaking across the eyepiece!
Sprite mkVisor(String what, {bool cae = false, int frame = 0}) => _mk(28, 28, (
  b,
) {
  final rim = _h('#3A4060');
  final sky = _h('#18204A');
  final moon = _h('#EEF0F4');
  final crater = _h('#B8BCC8');
  final star = _h('#FFF6B8');
  final starHi = _h('#FFFFFF');
  for (var y = 0; y < 28; y++) {
    for (var x = 0; x < 28; x++) {
      final r = math.sqrt(
        (x + .5 - 14) * (x + .5 - 14) + (y + .5 - 14) * (y + .5 - 14),
      );
      if (r > 14) continue;
      if (r > 12.2) {
        b.px(x, y, rim);
        continue;
      }
      if (what == 'luna') {
        final c1 = math.sqrt((x - 9) * (x - 9) + (y - 9) * (y - 9)) < 2.2;
        final c2 = math.sqrt((x - 17) * (x - 17) + (y - 15) * (y - 15)) < 3;
        final c3 = math.sqrt((x - 11) * (x - 11) + (y - 19) * (y - 19)) < 1.8;
        b.px(x, y, (c1 || c2 || c3) ? crater : moon);
      } else {
        final dx = (x + .5 - 14).abs(), dy = (y + .5 - 14).abs();
        if ((dx < 1.6 && dy < 9.5) || (dy < 1.6 && dx < 9.5) || dx + dy < 5.0) {
          b.px(x, y, dx + dy < 2.5 ? starHi : star);
        } else {
          b.px(x, y, sky);
        }
      }
    }
  }
  if (cae) {
    final shift = (frame % 3) * 3;
    final hx = (18 - shift).clamp(6, 22);
    final hy = (8 + shift).clamp(6, 21);
    b.line(hx, hy, (hx + 5).clamp(5, 22), (hy - 3).clamp(5, 22), _h('#98D4FF'));
    b.rect(hx - 1, hy - 1, 2, 2, _h('#FFFFFF'));
    b.px(hx, hy, _h('#FFE870'));
  }
});

/* ---------- Additional Needs sprites (cielo.md) ---------- */

/// Musical notes floating over the radio: 14 x 10.
Sprite mkRadioNotas(int frame) => _mk(14, 10, (b) {
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

/// Small speech bubble over the radio (showing sound waves, or a bright yellow sun when [sol] is true): 16 x 14.
Sprite mkRadioBurbuja({bool sol = false}) => _mk(16, 14, (b) {
  b.rect(1, 1, 14, 9, _h('#FAF8F0'));
  b.rect(0, 2, 16, 7, _h('#FAF8F0'));
  b.rect(6, 10, 3, 2, _h('#FAF8F0'));
  b.px(7, 12, _h('#FAF8F0'));
  if (sol) {
    b.ell(8, 5.5, 2.5, 2.5, _ramp(const ['#F8A828', '#FFD848']));
    for (final (x, y) in const [
      (8, 1),
      (8, 9),
      (4, 5),
      (12, 5),
      (5, 2),
      (11, 2),
      (5, 8),
      (11, 8),
    ]) {
      b.px(x, y, _h('#F8A828'));
    }
  } else {
    b.line(4, 4, 4, 6, _h('#3A5A8A'));
    b.line(7, 3, 7, 7, _h('#3A5A8A'));
    b.line(10, 4, 10, 6, _h('#3A5A8A'));
    b.px(12, 5, _h('#3A5A8A'));
  }
});

/// White gull gliding across the sky (story 81 opening): 14 x 8.
Sprite mkGaviotaCielo(int frame) => _mk(14, 8, (b) {
  final w = _h('#FAF8F4');
  final tip = _h('#6A7488');
  if (frame % 2 == 0) {
    b.line(1, 2, 6, 4, w);
    b.line(7, 4, 12, 2, w);
    b.rect(5, 4, 4, 2, w);
    b.px(1, 2, tip);
    b.px(12, 2, tip);
  } else {
    b.line(1, 5, 6, 3, w);
    b.line(7, 3, 12, 5, w);
    b.rect(5, 3, 4, 2, w);
    b.px(1, 5, tip);
    b.px(12, 5, tip);
  }
});

/// Big white cloud sliding over the sun (story 81): 36 x 18.
Sprite mkNubeGrande() => _mk(36, 18, (b) {
  final top = _ramp(const ['#DCE6F4', '#F4F8FF']);
  b.ell(18, 11, 13, 5.5, top);
  b.ell(10, 10, 7, 5, top);
  b.ell(26, 10, 7.5, 5, top);
  b.ell(16, 6, 7.5, 5, top);
  b.ell(23, 7, 6.5, 4.5, top);
});

/// Wind gust streaks: 26 x 12.
Sprite mkVientoRacha(int frame) {
  final b = Buf(26, 12);
  final c1 = _h('#EEF6FF');
  final c2 = _h('#C0DCF8');
  final ox = (frame % 3) * 2;
  b.line(ox, 2, 16 + ox, 2, c1);
  b.px(17 + ox, 1, c1);
  b.line(4 + ox, 6, 20 + ox, 6, c2);
  b.px(21 + ox, 5, c2);
  b.line(2 + ox, 10, 14 + ox, 10, c1);
  return b.done();
}

/// Diagonal rain streaks across the sky & yard (story 82 `tiempo82 lluvia`): 196 x 150, no outline.
Sprite mkLluvia(int frame) {
  final b = Buf(196, 150);
  final c1 = _h('#B8D8F8');
  final c2 = _h('#8AB4E4');
  final off = (frame % 4) * 7;
  for (var row = 0; row < 140; row += 16) {
    for (var col = 0; col < 192; col += 18) {
      final x = (col + ((row * 5 + off) % 18)) % 192;
      final y = (row + off) % 144;
      b.line(x + 2, y, x, y + 6, (col + row) % 3 == 0 ? c1 : c2);
    }
  }
  return b.done();
}

/// Raindrop splash on the table: 10 x 6.
Sprite mkGotaTabla(int frame) {
  final b = Buf(10, 6);
  final c = _h('#A8D4FA');
  if (frame % 2 == 0) {
    b.rect(4, 0, 2, 3, c);
    b.rect(3, 4, 4, 1, _h('#E4F2FF'));
  } else {
    b.px(2, 2, c);
    b.px(7, 2, c);
    b.rect(3, 4, 4, 1, c);
  }
  return b.done();
}

/// Shawl draped over seated abuela's shoulders (story 82 `chal puesto=1`, story 83): 18 x 10.
Sprite mkChalPuesto() => _mk(18, 10, (b) {
  b.rect(1, 0, 16, 7, _h('#C8503C'));
  b.rect(0, 2, 18, 5, _h('#C8503C'));
  b.rect(1, 2, 16, 1, _h('#F4E0A0'));
  b.rect(1, 5, 16, 1, _h('#F4E0A0'));
  for (var x = 1; x < 17; x += 2) {
    b.px(x, 7, _h('#C8503C'));
    b.px(x, 8, _h('#F4E0A0'));
  }
});

/// Warm supper bowl on the table in `final82`: 10 x 6.
Sprite mkCena() => _mk(10, 6, (b) {
  b.rect(1, 3, 8, 3, _h('#FAF6EE'));
  b.rect(2, 2, 6, 2, _h('#D87A38'));
  b.px(3, 0, _h('#E8F0F8'));
  b.px(6, 0, _h('#E8F0F8'));
});

/// Falling light with glowing tail in the night sky (story 83 `luz83`): 18 x 8.
Sprite mkLuzFugaz(int frame) {
  final b = Buf(18, 8);
  b.line(2, 6, 15, 1, _h('#90C8FF'));
  b.line(2, 5, 12, 2, _h('#D4ECFF'));
  b.rect(1, 5, 3, 2, _h('#FFFFFF'));
  b.px(2, 5, frame % 2 == 0 ? _h('#FFE870') : _h('#FFFFFF'));
  return b.done();
}

/// Fingers held up indicator (`gesto dedos` / `deseos`): 12 x 10.
Sprite mkDedos(int n) {
  final count = n.clamp(1, 3);
  return _mk(12, 10, (b) {
    b.rect(1, 1, 10, 8, _h('#FAF8F0'));
    final c = _h('#D05A3C');
    for (var i = 0; i < count; i++) {
      final x = 3 + i * 3;
      b.rect(x, 2, 2, 5, c);
    }
    b.rect(2, 6, count * 3 + 1, 2, c);
  });
}

/// Wishing sparkles beside Carmen (`gesto ojos`): 10 x 8.
Sprite mkOjosDeseo(int frame) {
  final b = Buf(10, 8);
  final c1 = _h('#FFE870');
  final c2 = _h('#FFFFFF');
  final dy = frame % 2 == 0 ? 0 : 1;
  b.px(3, 2 + dy, c1);
  b.px(3, 1 + dy, c2);
  b.px(3, 3 + dy, c2);
  b.px(2, 2 + dy, c2);
  b.px(4, 2 + dy, c2);
  b.px(7, 5 - dy, c1);
  b.px(7, 4 - dy, c2);
  b.px(7, 6 - dy, c2);
  return b.done();
}

/// Coquí song note wave (`canta83`): 12 x 10.
Sprite mkNotaCoqui(int frame) => _mk(12, 10, (b) {
  final dy = frame % 2 == 0 ? 0 : -1;
  final c = _h('#90F4B0');
  b.rect(2, 6 + dy, 2, 2, c);
  b.line(3, 6 + dy, 3, 2 + dy, c);
  b.line(3, 2 + dy, 8, 1 + dy, c);
  b.rect(7, 5 - dy, 2, 2, _h('#FFF290'));
  b.line(8, 5 - dy, 8, 1 + dy, _h('#FFF290'));
});

/// Small answering coquí voice note in the dark (`canta83`, `final83`): 9 x 8.
Sprite mkEcoCoqui(int frame) => _mk(9, 8, (b) {
  final dy = frame % 2 == 0 ? 0 : -1;
  final c = _h('#A8F0D0');
  b.rect(2, 5 + dy, 2, 2, c);
  b.line(3, 5 + dy, 3, 1 + dy, c);
  b.line(3, 1 + dy, 6, 2 + dy, c);
});

/// Celebration heart for 3-of-3 ending: 11 x 10.
Sprite mkCorazonCielo() => _mk(11, 10, (b) {
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

/// All El cielo sprites with names for the content lane's sprite sheet (`tool/make_cielo_sprites_test.dart`).
List<(String, Sprite)> cieloSpritesSheet() => [
  ('radio', mkRadio()),
  ('radio notas', mkRadioNotas(0)),
  ('radio burbuja', mkRadioBurbuja()),
  ('radio sol', mkRadioBurbuja(sol: true)),
  ('vela lit', mkVela(lit: true)),
  ('vela lean', mkVela(lit: true, lean: true)),
  ('vela out', mkVela(lit: false)),
  ('vela hiss', mkVela(lit: false, hiss: true)),
  ('tapa puesta', mkTapaPuesta()),
  ('tapa suelo', mkTapaSuelo()),
  ('chal suelo', mkChal()),
  ('chal puesto', mkChalPuesto()),
  ('bandeja 3', mkBandeja(3)),
  ('bandeja 2', mkBandeja(2)),
  ('bandeja 1', mkBandeja(1)),
  ('bandeja final 1', mkBandeja(1, finalMode: true)),
  ('sombrilla shut', mkSombrillaShut()),
  ('sombrilla open', mkSombrillaOpen()),
  ('sombrilla caida', mkSombrillaCaida()),
  ('chiringa', mkChiringa()),
  ('chiringa vuela', mkChiringaVuela(0)),
  ('bola', mkBolaCielo()),
  ('telescopio up', mkTelescopio(dir: 'up')),
  ('telescopio luna', mkTelescopio(dir: 'luna')),
  ('visor luna', mkVisor('luna')),
  ('visor luna cae', mkVisor('luna', cae: true)),
  ('visor estrella', mkVisor('estrella')),
  ('visor estrella cae', mkVisor('estrella', cae: true)),
  ('gaviota 0', mkGaviotaCielo(0)),
  ('gaviota 1', mkGaviotaCielo(1)),
  ('nube grande', mkNubeGrande()),
  ('viento racha', mkVientoRacha(0)),
  ('gota tabla', mkGotaTabla(0)),
  ('cena', mkCena()),
  ('luz fugaz', mkLuzFugaz(0)),
  ('dedos 3', mkDedos(3)),
  ('dedos 2', mkDedos(2)),
  ('ojos deseo', mkOjosDeseo(0)),
  ('nota coqui', mkNotaCoqui(0)),
  ('eco coqui', mkEcoCoqui(0)),
  ('corazon', mkCorazonCielo()),
];
