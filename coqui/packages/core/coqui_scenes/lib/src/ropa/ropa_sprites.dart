// Scene-specific sprites of La ropa (place 7, La playa, scene 3: `ropa`, order 64):
// - Preview-matching stand-ins (ropa-preview.html): clothes on line (16 x 16: camisa, pantalon, vestido, toalla),
//   things afloat (14 x 9: sombrero, chancletas, gafas, traje, toallaAgua), shoes (24 x 8), plate of sandwiches
//   (16 x 10), crate (12 x 8), open bag (14 x 10), driver at window (14 x 14).
// - Story 78 Needs: dripping/towel-wrapped & dressed Luis/Carmen, fallen/shaken piece, sand cloud, gull, plate cloth,
//   0..3 sandwiches.
// - Story 79 Needs: wrung-out dripping towel, line-hung sombrero/chancletas/gafas/traje, 0..3 open bag contents, wave
//   strip, frog wrapped in dry towel, abuela hands-on-head / shaking wet hat.
// - Story 80 Needs: Luis & Carmen in swimming things, putting-on / taking-off camisa/vestido/sombrero/gafas/chancletas,
//   four look-alike children from behind (`ninos1..4`, <= 24 px wide, `pone` vs `quita` frames) + turned-around
//   stranger laughing, driver with 3/2/1 fingers + smiling/tapping/horn, Canelo wearing abuela's sun hat.
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

final List<int> _RED = _ramp(const ['#A82A26', '#D0403A', '#FA9080']);
final List<int> _BLUE = _ramp(const ['#1E4FA8', '#2E6CD0', '#78B0F6']);
final List<int> _YEL = _ramp(const ['#B87A10', '#F8C838', '#FFF4B0']);
final List<int> _STRAW = _ramp(const ['#B8841E', '#E2B84A', '#F6DC8A']);
final List<int> _WOOD = _ramp(const ['#7A4A1E', '#A8682C', '#C8853C']);
final int _PEG = _h('#5A4630');
final int _DROP = _h('#78CCF4');

/* ---------- clothes on the line (16 x 16, top-anchored on cuerda1..5) ---------- */

/// Red shirt hanging on the line (16 x 16, ropa-preview.html `THING.camisa`).
Sprite mkCamisaCuerda() => _mk(16, 16, (b) {
  b.rect(4, 2, 8, 12, _RED[1]);
  b.rect(1, 2, 3, 4, _RED[1]);
  b.rect(12, 2, 3, 4, _RED[1]);
  b.rect(4, 2, 8, 1, _RED[2]);
  b.rect(6, 2, 4, 1, _RED[0]);
  b.rect(4, 12, 8, 2, _RED[0]);
  b.px(3, 0, _PEG);
  b.px(12, 0, _PEG);
});

/// Blue trousers hanging on the line (16 x 16, ropa-preview.html `THING.pantalon`).
Sprite mkPantalonCuerda() => _mk(16, 16, (b) {
  b.rect(4, 1, 8, 3, _BLUE[1]);
  b.rect(4, 4, 3, 11, _BLUE[1]);
  b.rect(9, 4, 3, 11, _BLUE[1]);
  b.rect(7, 4, 2, 3, _BLUE[0]);
  b.rect(4, 1, 8, 1, _BLUE[2]);
  b.rect(4, 13, 3, 2, _BLUE[0]);
  b.rect(9, 13, 3, 2, _BLUE[0]);
  b.px(5, 0, _PEG);
  b.px(10, 0, _PEG);
});

/// Yellow dress hanging on the line (16 x 16, ropa-preview.html `THING.vestido`).
Sprite mkVestidoCuerda() => _mk(16, 16, (b) {
  b.rect(5, 1, 6, 5, _YEL[1]);
  b.rect(6, 1, 1, 2, _YEL[0]);
  b.rect(9, 1, 1, 2, _YEL[0]);
  for (var y = 6; y < 15; y++) {
    final hw = 3 + ((y - 6) * .6).floor();
    b.rect(8 - hw, y, 2 * hw, 1, y > 12 ? _YEL[0] : _YEL[1]);
  }
  b.rect(5, 5, 6, 1, _YEL[2]);
  b.px(5, 0, _PEG);
  b.px(10, 0, _PEG);
});

/// Striped towel hanging on the line (16 x 16, ropa-preview.html `THING.toalla`, dry or wrung out / dripping).
Sprite mkToallaCuerda({bool mojada = false}) => _mk(16, 16, (b) {
  for (var y = 1; y < 14; y++) {
    b.rect(3, y, 10, 1, ((y ~/ 3) % 2) != 0 ? _h('#FFFFFF') : _BLUE[2]);
  }
  b.rect(3, 13, 10, 1, _BLUE[1]);
  b.px(4, 0, _PEG);
  b.px(11, 0, _PEG);
  if (mojada) {
    b.px(5, 14, _DROP);
    b.px(10, 14, _DROP);
  }
});

/// Sun hat pegged on the line, dripping (16 x 16, story 79 ending).
Sprite mkSombreroCuerda() => _mk(16, 16, (b) {
  b.ell(8, 8, 6.2, 2.2, _STRAW);
  b.ell(8, 6, 3.6, 3.0, _STRAW);
  b.rect(5, 7, 6, 1, _RED[1]);
  b.px(5, 0, _PEG);
  b.px(10, 0, _PEG);
  b.line(6, 1, 6, 3, _PEG);
  b.line(9, 1, 9, 3, _PEG);
  b.px(6, 12, _DROP);
  b.px(10, 13, _DROP);
});

/// Sandals pegged on the line, dripping (16 x 16, story 79 ending).
Sprite mkChancletasCuerda() => _mk(16, 16, (b) {
  for (final x in const [2, 9]) {
    b.ell(x + 2.5, 7, 2.5, 4.0, [_YEL[1]]);
    b.line(x + 1, 5, x + 4, 7, _RED[0]);
    b.line(x + 4, 5, x + 1, 7, _RED[0]);
  }
  b.px(4, 0, _PEG);
  b.px(11, 0, _PEG);
  b.px(4, 1, _PEG);
  b.px(11, 1, _PEG);
  b.px(4, 13, _DROP);
  b.px(11, 13, _DROP);
});

/// Dark glasses clipped on the line, dripping (16 x 16, story 79 ending).
Sprite mkGafasCuerda() => _mk(16, 16, (b) {
  b.ell(4.5, 6.5, 2.8, 2.6, [_h('#20202C'), _h('#3A3A4C')]);
  b.ell(11.5, 6.5, 2.8, 2.6, [_h('#20202C'), _h('#3A3A4C')]);
  b.line(7, 5, 9, 5, _h('#20202C'));
  b.px(4, 0, _PEG);
  b.px(11, 0, _PEG);
  b.line(4, 1, 4, 3, _PEG);
  b.line(11, 1, 11, 3, _PEG);
  b.px(4, 11, _DROP);
  b.px(11, 11, _DROP);
});

/// Swimming suit pegged on the line, dripping (16 x 16, story 79 ending).
Sprite mkTrajeCuerda() => _mk(16, 16, (b) {
  b.rect(4, 4, 8, 9, _RED[1]);
  b.rect(4, 2, 2, 2, _RED[1]);
  b.rect(10, 2, 2, 2, _RED[1]);
  b.rect(4, 4, 8, 1, _RED[2]);
  b.rect(6, 11, 4, 2, _RED[0]);
  b.px(4, 0, _PEG);
  b.px(11, 0, _PEG);
  b.px(6, 14, _DROP);
  b.px(10, 14, _DROP);
});

/* ---------- things afloat (14 x 9, bottom-anchored on agua1..5) ---------- */

/// Sun hat afloat (14 x 9, ropa-preview.html `THING.sombrero`).
Sprite mkSombreroAgua() => _mk(14, 9, (b) {
  b.ell(7, 6, 6.2, 2.2, _STRAW);
  b.ell(7, 4, 3.6, 3.2, _STRAW);
  b.rect(4, 5, 6, 1, _RED[1]);
});

/// Sandals afloat (14 x 9, ropa-preview.html `THING.chancletas`).
Sprite mkChancletasAgua() => _mk(14, 9, (b) {
  for (final x in const [1, 8]) {
    b.ell(x + 2.5, 5, 2.5, 3.2, [_YEL[1]]);
    b.line(x + 1, 3, x + 4, 5, _RED[0]);
    b.line(x + 4, 3, x + 1, 5, _RED[0]);
  }
});

/// Dark glasses afloat (14 x 9, ropa-preview.html `THING.gafas`).
Sprite mkGafasAgua() => _mk(14, 9, (b) {
  b.ell(3.5, 5, 2.8, 2.4, [_h('#20202C'), _h('#3A3A4C')]);
  b.ell(10.5, 5, 2.8, 2.4, [_h('#20202C'), _h('#3A3A4C')]);
  b.line(6, 4, 8, 4, _h('#20202C'));
  b.line(0, 3, 1, 3, _h('#20202C'));
  b.line(12, 3, 13, 3, _h('#20202C'));
});

/// Swimming suit afloat (14 x 9, ropa-preview.html `THING.traje`).
Sprite mkTrajeAgua() => _mk(14, 9, (b) {
  b.ell(7, 5.5, 5.4, 3, [_RED[0], _RED[1], _RED[2]]);
  b.rect(3, 2, 2, 3, _RED[1]);
  b.rect(9, 2, 2, 3, _RED[1]);
  b.rect(6, 6, 2, 2, _BLUE[1]);
});

/// Towel afloat (14 x 9, ropa-preview.html `THING.toallaAgua`).
Sprite mkToallaAgua() => _mk(14, 9, (b) {
  for (var x = 1; x < 13; x++) {
    b.rect(x, 2, 1, 5, ((x ~/ 3) % 2) != 0 ? _h('#FFFFFF') : _BLUE[2]);
  }
  b.rect(1, 6, 12, 1, _BLUE[1]);
});

/* ---------- props on sand / bench / window ---------- */

/// Two pairs of shoes side by side: white at left, black at right (24 x 8, ropa-preview.html `THING.zapatos`).
Sprite mkZapatos() => _mk(24, 8, (b) {
  final pairs = [
    (0, _ramp(const ['#8E8EA4', '#F2F2F8', '#FFFFFF'])),
    (12, _ramp(const ['#0E0E16', '#32323E', '#5A5A6E'])),
  ];
  for (final (x0, c) in pairs) {
    for (final dx in const [1, 6]) {
      b.ell(x0 + dx + 2.5, 3.8, 2.5, 3.1, c);
      b.rect(x0 + dx, 6, 5, 1, c[0]);
      b.line(x0 + dx + 1, 2, x0 + dx + 3, 2, c[0]);
    }
  }
});

/// Plate with [n] (0 to 3) sandwiches (16 x 10, ropa-preview.html `THING.plato` at n=3).
Sprite mkPlato(int n) {
  final count = n.clamp(0, 3);
  const spots = [(4.0, 3.0), (7.5, 2.0), (11.0, 3.0)];
  return _mk(16, 10, (b) {
    b.ell(8, 6, 7.2, 3.2, _ramp(const ['#FFFFFF', '#E8E8F0']));
    for (var i = 0; i < count; i++) {
      final (x, y) = spots[i];
      b.ell(x, y + 1, 2.6, 2, _ramp(const ['#F4DCA0', '#FBEBC0']));
      b.px(x.floor(), y.floor() + 1, _h('#C8603C'));
    }
  });
}

/// Cloth lifted off or laid beside the plate (12 x 6).
Sprite mkPanoPlato() => _mk(12, 6, (b) {
  b.rect(1, 1, 10, 4, _h('#F8F4EC'));
  b.rect(1, 2, 10, 1, _h('#D46458'));
  b.rect(1, 4, 10, 1, _h('#D46458'));
});

/// Small wooden crate under the plate (12 x 8, ropa-preview.html `THING.caja`).
Sprite mkCajaRopa() => _mk(12, 8, (b) {
  b.rect(0, 0, 12, 8, _WOOD[1]);
  b.rect(0, 0, 12, 1, _WOOD[2]);
  b.rect(0, 4, 12, 1, _WOOD[0]);
  b.rect(0, 7, 12, 1, _WOOD[0]);
});

/// Open bag on the sand with [n] (0 to 3) recovered things peeking out (14 x 10, ropa-preview.html `THING.bolsa` at n=0).
Sprite mkBolsaRopa(int n) {
  final count = n.clamp(0, 3);
  return _mk(14, 10, (b) {
    b.rect(1, 3, 12, 7, _h('#C8A468'));
    b.rect(1, 3, 12, 1, _h('#E2C88A'));
    b.ell(7, 3.5, 5.4, 1.8, [_h('#4A3220')]);
    if (count >= 1) b.rect(3, 2, 3, 2, _STRAW[1]);
    if (count >= 2) b.rect(7, 2, 3, 2, _RED[1]);
    if (count >= 3) b.rect(5, 1, 3, 2, _YEL[1]);
    b.line(4, 3, 5, 0, _WOOD[0]);
    b.line(10, 3, 9, 0, _WOOD[0]);
    b.line(5, 0, 9, 0, _WOOD[0]);
  });
}

/// Bus driver in his window (14 x 14, ropa-preview.html `THING.chofer` at fingers=3).
Sprite mkChofer({
  int fingers = 3,
  bool smiling = false,
  bool tapping = false,
  bool horn = false,
}) {
  final f = fingers.clamp(0, 3);
  return _mk(14, 14, (b) {
    b.rect(2, 9, 10, 5, _h('#3A6EA8'));
    b.ell(6, 6, 3.6, 3.8, _ramp(const ['#8A5A2A', '#B07A3C', '#D09A54']));
    b.rect(2, 2, 8, 2, _h('#2E3A4E'));
    b.rect(3, 1, 6, 1, _h('#2E3A4E'));
    b.px(5, 6, _h('#20140A'));
    b.px(8, 6, _h('#20140A'));
    if (smiling) {
      b.rect(5, 8, 3, 1, _h('#F4E4C8'));
    }
    if (horn) {
      b.line(10, 9, 12, 7, _h('#B07A3C'));
      b.px(12, 6, _h('#F8C838'));
    } else if (tapping) {
      b.line(9, 10, 12, 11, _h('#B07A3C'));
      b.px(12, 12, _h('#D09A54'));
    } else if (f > 0) {
      b.line(11, 9, 12, 4, _h('#B07A3C'));
      const xs = [11, 12, 13];
      for (var i = 0; i < f; i++) {
        b.px(xs[i], 2, _h('#D09A54'));
      }
    }
  });
}

/* ---------- story 78 sprites ---------- */

/// Crumpled clothing piece fallen on the sand (`sacude78` / `baja78 ok=0`, 14 x 9).
Sprite mkPiezaCaida(String que) => _mk(14, 9, (b) {
  final ramp = switch (que) {
    'camisa' => _RED,
    'pantalon' => _BLUE,
    'vestido' => _YEL,
    _ => _ramp(const ['#8E8EA4', '#F2F2F8', '#FFFFFF']),
  };
  b.ell(7, 5.5, 5.2, 2.5, ramp);
  b.rect(4, 3, 5, 2, ramp[1]);
});

/// Sand cloud blown over the bench and onto the sandwich (`sacude78`, 22 x 12, no outline).
Sprite mkNubeArena(int frame) {
  final px = Uint32List(22 * 12);
  final s1 = _h('#F2E0B0');
  final s2 = _h('#D6BA80');
  final ox = (frame % 2) * 2;
  for (final (x, y) in const [
    (2, 6),
    (5, 4),
    (8, 3),
    (11, 2),
    (14, 4),
    (17, 6),
    (4, 8),
    (7, 7),
    (10, 6),
    (13, 8),
    (16, 9),
    (19, 8),
  ]) {
    final X = (x + ox).clamp(0, 20);
    px[y * 22 + X] = (x + y).isEven ? s1 : s2;
    px[y * 22 + X + 1] = s2;
  }
  return Sprite(22, 12, px);
}

/// Gull swooping for a lost sandwich (`sacude78`, 12 x 8).
Sprite mkGaviotaRopa(int frame) => _mk(12, 8, (b) {
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

/// Story 78/80 child in swimming things, optionally wrapped in a towel or dripping (48 x 44, `ax = 24, ay = 41`).
Sprite mkNinoPlaya(
  String who, {
  bool toalla = false,
  bool gotea = false,
  int frame = 0,
}) {
  final isLuis = who == 'luis';
  final fam = FAM[isLuis ? 'hermano' : 'hermana']!;
  final w = Who(
    nino: true,
    piel: fam.piel,
    pelo: fam.pelo,
    peinado: fam.peinado,
    lazo: fam.lazo,
    ropa: toalla
        ? _ramp(const ['#3A78D0', '#78A8F0', '#FFFFFF'])
        : (isLuis ? fam.piel : RP.red),
    abajo: isLuis ? RP.blue : fam.piel,
    falda: false,
    zapato: fam.piel[1],
  );
  final base = mkPersona(w, 'idle', false, false);
  if (!gotea) return base;
  final px = Uint32List.fromList(base.px);
  final dy = (frame % 2) * 2;
  for (final (x, y) in const [(15, 22), (32, 23), (17, 31), (30, 32)]) {
    final Y = (y + dy).clamp(0, base.h - 1);
    px[Y * base.w + x] = _DROP;
  }
  return Sprite(base.w, base.h, px);
}

/// Story 78/80 dressed child: Luis in red shirt + blue trousers + white shoes; Carmen in yellow dress + black shoes.
Sprite mkNinoRopa(
  String who,
  String pose,
  bool open, {
  bool gafas = false,
  bool sombrero = false,
  bool abanica = false,
  bool chancletas = false,
}) {
  final isLuis = who == 'luis';
  final fam = FAM[isLuis ? 'hermano' : 'hermana']!;
  final w = Who(
    nino: true,
    piel: fam.piel,
    pelo: fam.pelo,
    peinado: fam.peinado,
    lazo: fam.lazo,
    ropa: isLuis ? RP.red : RP.yel,
    abajo: isLuis ? RP.blue : null,
    falda: !isLuis,
    zapato: chancletas ? _YEL[1] : (isLuis ? _h('#F2F2F8') : _h('#2A2A38')),
    gafas: gafas ? 1 : null,
  );
  final base = mkPersona(w, pose, open, false);
  if (!sombrero && !abanica) return base;
  final px = Uint32List.fromList(base.px);
  if (sombrero) {
    final hat = mkSombreroPuestoRopa();
    const ox = 15, oy = 1;
    for (var y = 0; y < hat.h; y++) {
      for (var x = 0; x < hat.w; x++) {
        final c = hat.px[y * hat.w + x];
        if (c >>> 24 == 0) continue;
        final X = ox + x, Y = oy + y;
        if (X >= 0 && X < base.w && Y >= 0 && Y < base.h) {
          px[Y * base.w + X] = c;
        }
      }
    }
  }
  if (abanica) {
    final fan = mkSombreroAgua();
    const ox = 27, oy = 12;
    for (var y = 0; y < fan.h; y++) {
      for (var x = 0; x < fan.w; x++) {
        final c = fan.px[y * fan.w + x];
        if (c >>> 24 == 0) continue;
        final X = ox + x, Y = oy + y;
        if (X >= 0 && X < base.w && Y >= 0 && Y < base.h) {
          px[Y * base.w + X] = c;
        }
      }
    }
  }
  return Sprite(base.w, base.h, px);
}

/* ---------- story 79 sprites ---------- */

/// Flat wave strip rolling in over the shallow water (`ola79`, `lejos79`, 168 x 10).
Sprite mkOlaRopa(int frame) {
  const w = 168, h = 10;
  final px = Uint32List(w * h);
  final foam = _h('#FAFDFE');
  final shallow = _h('#7CE0D8');
  final mid = _h('#4CB4D4');
  for (var x = 0; x < w; x++) {
    final wob = ((x + frame * 7) % 16 < 8) ? 0 : 1;
    final top = 1 + wob;
    final bot = h - 2 - ((x + frame * 5) % 12 < 6 ? 0 : 1);
    for (var y = top; y <= bot; y++) {
      final d = bot - y;
      px[y * w + x] = d <= 1 ? foam : (d <= 3 ? shallow : mid);
    }
  }
  return Sprite(w, h, px);
}

/// Frog wrapped snugly in abuela's dry towel (`final79`, 22 x 18).
Sprite mkCoquiToallaRopa() => _mk(22, 18, (b) {
  b.ell(11, 10, 9, 7, [_h('#245096'), _h('#3A78D0'), _h('#78A8F0')]);
  b.rect(4, 11, 14, 2, _h('#FFFFFF'));
  b.ell(8, 4, 2.5, 2.2, [_h('#3E8E3E'), _h('#68C858')]);
  b.ell(14, 4, 2.5, 2.2, [_h('#3E8E3E'), _h('#68C858')]);
  b.px(8, 4, _h('#181414'));
  b.px(14, 4, _h('#181414'));
});

/// Abuela standing with both hands on her head (`gesto manos`, 48 x 51, `ax = 30`).
Sprite mkAbuelaManos(bool open) {
  final base = mkAbuela('idle', open);
  final px = Uint32List.fromList(base.px);
  // Add raised elbows / hands touching her hair bun
  final s = RP.skin[2], p = RP.purp[2];
  for (final (x, y) in const [
    (21, 9),
    (22, 9),
    (21, 10),
    (22, 10),
    (37, 9),
    (38, 9),
    (37, 10),
    (38, 10),
  ]) {
    px[y * base.w + x] = s;
  }
  for (final (x, y) in const [
    (20, 12),
    (20, 13),
    (20, 14),
    (39, 12),
    (39, 13),
    (39, 14),
  ]) {
    px[y * base.w + x] = p;
  }
  return Sprite(base.w, base.h, px);
}

/// Abuela shaking her wet straw hat (`trae79 sombrero` opening, 48 x 51, `ax = 30`).
Sprite mkAbuelaSombrero(bool open) {
  final base = mkAbuela('offer', open);
  final px = Uint32List.fromList(base.px);
  final hat = mkSombreroAgua();
  const ox = 2, oy = 18;
  for (var y = 0; y < hat.h; y++) {
    for (var x = 0; x < hat.w; x++) {
      final c = hat.px[y * hat.w + x];
      if (c >>> 24 == 0) continue;
      final X = ox + x, Y = oy + y;
      if (X >= 0 && X < base.w && Y >= 0 && Y < base.h) {
        px[Y * base.w + X] = c;
      }
    }
  }
  return Sprite(base.w, base.h, px);
}

/* ---------- story 80 sprites ---------- */

/// Straw hat worn on a child's head (18 x 9).
Sprite mkSombreroPuestoRopa() => _mk(18, 9, (b) {
  b.ell(9, 6.2, 7.6, 2.0, _STRAW);
  b.ell(9, 3.6, 4.2, 2.8, _STRAW);
  b.rect(5, 4, 8, 1, _RED[1]);
});

/// Child seen from behind at the water's edge (`ninos1..4`: `tipo` 'chico' or 'chica',
/// `que` 'sombrero' | 'camisa' | 'vestido', `phase` 0 (off/in hand) .. 3 (on), 48 x 44, `ax = 24`, <= 24 px wide).
Sprite mkNinoAtras(String tipo, String que, int phase) {
  final p = phase.clamp(0, 3);
  final isBoy = tipo == 'chico';
  final fam = FAM[isBoy ? 'hermano' : 'hermana']!;
  final skin = fam.piel;
  final hair = fam.pelo;
  return _mk(48, 44, (b) {
    const X = PX; // 24 -> keeps ink inside [14..33] (width 20 <= 24)
    // Legs & feet
    if (isBoy) {
      b.rect(X - 4, 29, 3, 8, _BLUE[1]);
      b.rect(X + 1, 29, 3, 8, _BLUE[0]);
      b.rect(X - 5, 37, 4, 2, _h('#F2F2F8'));
      b.rect(X + 1, 37, 4, 2, _h('#F2F2F8'));
    } else {
      b.rect(X - 4, 29, 3, 8, skin[2]);
      b.rect(X + 1, 29, 3, 8, skin[1]);
      b.rect(X - 5, 37, 4, 2, _h('#2A2A38'));
      b.rect(X + 1, 37, 4, 2, _h('#2A2A38'));
    }

    // Torso (always red shirt for boy unless shirt is off, yellow dress for girl unless dress is off -> red swimsuit)
    if (isBoy) {
      final hasShirt = que != 'camisa' || p >= 2;
      final torso = hasShirt ? RP.red : skin;
      b.ell(X, 24, 6.2, 6.4, torso);
      if (que == 'camisa' && p == 1) {
        // Pulling shirt up from waist/chest
        b.rect(X - 6, 23, 12, 5, _RED[1]);
      } else if (que == 'camisa' && p == 2) {
        // Pulling shirt over head
        b.rect(X - 5, 11, 10, 6, _RED[1]);
      }
    } else {
      final hasDress = que != 'vestido' || p >= 2;
      if (hasDress) {
        b.ell(X, 24, 6.2, 6.4, RP.yel);
        b.ell(X, 30, 8.2, 4.4, RP.yel);
      } else {
        // Red one-piece swimsuit from behind
        b.ell(X, 24, 5.4, 6.0, RP.red);
        b.rect(X - 4, 19, 2, 3, RP.red[2]);
        b.rect(X + 2, 19, 2, 3, RP.red[2]);
      }
      if (que == 'vestido' && p == 1) {
        b.rect(X - 6, 24, 12, 6, _YEL[1]);
      } else if (que == 'vestido' && p == 2) {
        b.rect(X - 6, 12, 12, 7, _YEL[1]);
      }
    }

    // Arms (raised when putting on / taking off at phase 1 or 2)
    final armCol = isBoy
        ? (que == 'camisa' && p < 2 ? skin : RP.red)
        : (que == 'vestido' && p < 2 ? skin : RP.yel);
    if (p == 1 || p == 2) {
      b.cap(X - 6, 20, X - 8, p == 2 ? 12 : 16, 1.8, armCol);
      b.cap(X + 6, 20, X + 8, p == 2 ? 12 : 16, 1.8, armCol);
    } else {
      b.cap(X - 6, 20, X - 8, 28, 1.8, armCol);
      b.cap(X + 6, 20, X + 8, 28, 1.8, armCol);
      b.ell(X - 8, 29, 1.8, 1.8, skin);
      b.ell(X + 8, 29, 1.8, 1.8, skin);
    }

    // Neck & back of head (hair covers the back!)
    b.rect(X - 2, 16, 4, 3, skin[1]);
    b.ell(X, 11.4, 5.8, 6.4, hair);
    if (!isBoy) {
      // Two braids from behind with yellow bows
      final bow = _h('#FFE070');
      b.cap(X - 6, 12, X - 7, 20, 1.5, hair);
      b.cap(X + 6, 12, X + 7, 20, 1.5, hair);
      b.rect(X - 8, 20, 3, 2, bow);
      b.rect(X + 5, 20, 3, 2, bow);
    }

    // Straw hat when `que == 'sombrero'` (0: held in right hand, 1: lifted beside shoulder, 2: above head, 3: on head)
    if (que == 'sombrero') {
      if (p == 0) {
        b.ell(X + 7, 29, 2.6, 2.0, _STRAW);
        b.rect(X + 5, 29, 4, 1, _RED[1]);
      } else if (p == 1) {
        b.ell(X + 7, 16, 2.8, 2.2, _STRAW);
        b.rect(X + 5, 16, 4, 1, _RED[1]);
      } else if (p == 2) {
        b.ell(X, 3.5, 6.8, 2.0, _STRAW);
        b.ell(X, 1.5, 3.8, 1.8, _STRAW);
        b.rect(X - 3, 2, 6, 1, _RED[1]);
      } else {
        b.ell(X, 6.5, 7.2, 2.0, _STRAW);
        b.ell(X, 4.0, 4.0, 2.5, _STRAW);
        b.rect(X - 3, 5, 6, 1, _RED[1]);
      }
    } else if (p == 0) {
      // Holding straw hat in right hand (script: "with straw hats in their hands")
      b.ell(X + 7, 29, 2.6, 2.0, _STRAW);
    }
  });
}

/// Strange look-alike child turned round laughing (`busca80 ok=0`, 48 x 44, `ax = 24`).
Sprite mkNinoExtranoRie(String tipo) {
  final isBoy = tipo == 'chico';
  final w = Who(
    nino: true,
    piel: isBoy ? PIEL['a']! : PIEL['b']!,
    pelo: isBoy ? PELO['castano']! : PELO['negro']!,
    peinado: isBoy ? 'corto' : 'trenzas',
    lazo: _h('#78B0F6'),
    ropa: isBoy ? RP.red : RP.yel,
    abajo: isBoy ? RP.blue : null,
    falda: !isBoy,
    zapato: isBoy ? _h('#F2F2F8') : _h('#2A2A38'),
  );
  return mkPersona(w, 'yo', true, false);
}

/// Canelo sitting wearing abuela's sun hat (`final80`, 30 x 22).
Sprite mkPerroSombrero() {
  final base = mkPerro('sit', false);
  final px = Uint32List.fromList(base.px);
  final hat = mkSombreroAgua();
  const ox = 16, oy = 0;
  for (var y = 0; y < hat.h; y++) {
    for (var x = 0; x < hat.w; x++) {
      final c = hat.px[y * hat.w + x];
      if (c >>> 24 == 0) continue;
      final X = ox + x, Y = oy + y;
      if (X >= 0 && X < base.w && Y >= 0 && Y < base.h) {
        px[Y * base.w + X] = c;
      }
    }
  }
  return Sprite(base.w, base.h, px);
}

/// Every scene-specific sprite La ropa draws, for the sprite sheet & tests.
List<(String, Sprite)> ropaSpritesSheet() => [
  ('camisa_cuerda', mkCamisaCuerda()),
  ('pantalon_cuerda', mkPantalonCuerda()),
  ('vestido_cuerda', mkVestidoCuerda()),
  ('toalla_cuerda', mkToallaCuerda()),
  ('toalla_mojada', mkToallaCuerda(mojada: true)),
  ('sombrero_cuerda', mkSombreroCuerda()),
  ('chancletas_cuerda', mkChancletasCuerda()),
  ('gafas_cuerda', mkGafasCuerda()),
  ('traje_cuerda', mkTrajeCuerda()),
  ('sombrero_agua', mkSombreroAgua()),
  ('chancletas_agua', mkChancletasAgua()),
  ('gafas_agua', mkGafasAgua()),
  ('traje_agua', mkTrajeAgua()),
  ('toalla_agua', mkToallaAgua()),
  ('zapatos', mkZapatos()),
  ('plato_3', mkPlato(3)),
  ('plato_2', mkPlato(2)),
  ('plato_1', mkPlato(1)),
  ('plato_0', mkPlato(0)),
  ('pano_plato', mkPanoPlato()),
  ('caja', mkCajaRopa()),
  ('bolsa_0', mkBolsaRopa(0)),
  ('bolsa_3', mkBolsaRopa(3)),
  ('chofer_3', mkChofer(fingers: 3)),
  ('chofer_2', mkChofer(fingers: 2)),
  ('chofer_1', mkChofer(fingers: 1)),
  ('chofer_sonrie', mkChofer(fingers: 0, smiling: true)),
  ('chofer_bocina', mkChofer(fingers: 2, horn: true)),
  ('pieza_caida', mkPiezaCaida('camisa')),
  ('nube_arena', mkNubeArena(0)),
  ('gaviota_0', mkGaviotaRopa(0)),
  ('ola_ropa', mkOlaRopa(0)),
  ('coqui_toalla', mkCoquiToallaRopa()),
  ('abuela_manos', mkAbuelaManos(false)),
  ('abuela_sombrero', mkAbuelaSombrero(false)),
  ('luis_toalla', mkNinoPlaya('luis', toalla: true)),
  ('carmen_traje', mkNinoPlaya('carmen', gotea: true)),
  ('luis_vestido', mkNinoRopa('luis', 'idle', false, sombrero: true)),
  ('carmen_vestida', mkNinoRopa('carmen', 'idle', false, gafas: true)),
  ('chico_atras_pone', mkNinoAtras('chico', 'sombrero', 2)),
  ('chico_atras_quita', mkNinoAtras('chico', 'sombrero', 0)),
  ('chica_atras_vestido', mkNinoAtras('chica', 'vestido', 3)),
  ('chico_rie', mkNinoExtranoRie('chico')),
  ('perro_sombrero', mkPerroSombrero()),
];
