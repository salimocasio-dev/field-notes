// Scene-specific sprites and cast outfits of La muralla (place 10, El fuerte, scene 4: `muralla`, order 77):
// - Preview-matching core props (muralla-preview.html `THING` & `doorOpen`, exact muralla-sheet.json box dimensions):
//   farol (10 x 12, lit & unlit), camara (12 x 22), vela (8 x 16, 3/2/1/0 rings + flame), jugo (6 x 10),
//   plato (12 x 6), silla (14 x 24), guitarra (10 x 22), sombrero (12 x 8), bolsa (10 x 12), caja (12 x 10),
//   libro (10 x 8), guagua (22 x 10, open/shut door, blinking lights, 0..4 window faces & waving hands),
//   lejos1 / lejos2 (4 x 7), doorOpen (24 x 28).
// - Additional Needs sprites (historia/notas/guiones/muralla.md):
//   paloma (8 x 6 ledge resting/eye-open, 10 x 8 flying burst), flash (20 x 20), fotoSlide (18 x 16, bright/medium/dark),
//   tambor (10 x 9), abanico (7 x 6), notaMusica (7 x 9), estrellas (15 x 9), corazon (11 x 10).
// - Cast outfits (`MURALLA_WHO`) matching muralla-preview.html `GU`, plus `withHat` straw hat and `murallaSpritesSheet()`.
// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/src/colmado/colmado_cast.dart' show inkBottom;

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

/* ---------- Cast outfits (muralla-preview.html `GU` + `FAM`) ---------- */

final Who _ninoA = Who(
  nino: true,
  piel: FAM['hermano']!.piel,
  pelo: PELO['castano']!,
  peinado: FAM['hermano']!.peinado,
  ropa: RP.red,
  abajo: FAM['hermano']!.abajo,
);

final Who _ninaB = Who(
  nino: true,
  piel: FAM['hermana']!.piel,
  pelo: FAM['hermana']!.pelo,
  peinado: FAM['hermana']!.peinado,
  ropa: RP.blue,
  abajo: FAM['hermana']!.abajo,
  lazo: _h('#78E070'),
);

/// Cast definitions matching muralla-preview.html `GU` and `FAM`.
final Map<String, Who> MURALLA_WHO = {
  'abuelo': FAM['abuelo']!,
  'luis': FAM['hermano']!,
  'carmen': FAM['hermana']!,
  'ninoA': _ninoA,
  'ninaB': _ninaB,
  'pepe': Who(
    piel: PIEL['b']!,
    pelo: PELO['blanco']!,
    peinado: 'corto',
    ropa: RP.wood.sublist(1),
    abajo: RP.grey,
    bigote: true,
  ),
  'maestra': Who(
    piel: PIEL['c']!,
    pelo: PELO['castano']!,
    peinado: 'largo',
    ropa: RP.teal,
    falda: true,
  ),
  'piraguero': Who(
    piel: PIEL['a']!,
    pelo: PELO['negro']!,
    peinado: 'corto',
    ropa: RP.yel,
    abajo: RP.blue,
  ),
  'senor': Who(
    piel: PIEL['b']!,
    pelo: PELO['negro']!,
    peinado: 'calvo',
    ropa: RP.grey.sublist(1),
    abajo: RP.stone,
    gafas: true,
  ),
  'senora': Who(
    piel: PIEL['c']!,
    pelo: PELO['castano']!,
    peinado: 'largo',
    ropa: RP.purp,
    falda: true,
  ),
  'musico1': Who(
    piel: PIEL['a']!,
    pelo: PELO['negro']!,
    peinado: 'corto',
    ropa: RP.cream.sublist(1),
    abajo: RP.wood,
  ),
  'musico2': Who(
    piel: PIEL['b']!,
    pelo: PELO['negro']!,
    peinado: 'corto',
    ropa: RP.orng,
    abajo: RP.stone,
  ),
};

/// Draws the straw hat on a `mkPersona` sprite matching muralla-preview.html `withHat`.
Sprite murallaWithHat(Sprite base) => _overlayOn(base, (b) {
  b.rect(PX - 9, 3, 18, 3, _h('#2A1810'));
  b.rect(PX - 6, 0, 12, 4, _h('#2A1810'));
  b.rect(PX - 8, 3, 16, 2, _h('#EED28A'));
  b.rect(PX - 5, 1, 10, 3, _h('#EED28A'));
  b.rect(PX - 5, 3, 10, 1, _h('#7A1C1C'));
});

/// Overlays a small held prop or expression onto a cast sprite.
Sprite mkPersonaMurallaExtra(
  Sprite base, {
  bool hat = false,
  bool drum = false,
  bool guitar = false,
  bool guitarLift = false,
  bool plateInHand = false,
  bool tongue = false,
  bool belly = false,
  bool kiss = false,
  bool legUp = false,
  bool fan = false,
  int fanPhase = 0,
  String? hugItem,
}) {
  var s = hat ? murallaWithHat(base) : base;
  if (!drum &&
      !guitar &&
      !guitarLift &&
      !plateInHand &&
      !tongue &&
      !belly &&
      !kiss &&
      !legUp &&
      !fan &&
      hugItem == null) {
    return s;
  }
  return _overlayOn(s, (b) {
    if (drum) {
      // Compact hand drum resting across lap/waist.
      b.rect(PX - 5, 30, 10, 7, _h('#2A1810'));
      b.rect(PX - 4, 31, 8, 5, _h('#C85428'));
      b.rect(PX - 4, 31, 8, 1, _h('#F4E8C8'));
      b.px(PX - 2, 33, _h('#F8C838'));
      b.px(PX + 2, 33, _h('#F8C838'));
    }
    if (guitar) {
      // Guitar strapped diagonally across musico1.
      b.rect(PX - 6, 24, 2, 9, _h('#6E4220'));
      b.ell(PX - 4, 34, 3.4, 3.6, [
        _h('#92602E'),
        _h('#B88040'),
        _h('#D8A460'),
      ]);
      b.px(PX - 4, 34, _h('#2A1810'));
    }
    if (guitarLift) {
      // Raised guitar neck celebrating the last song.
      b.rect(PX + 6, 12, 2, 11, _h('#6E4220'));
      b.ell(PX + 7, 25, 3.4, 3.6, [
        _h('#92602E'),
        _h('#B88040'),
        _h('#D8A460'),
      ]);
    }
    if (plateInHand) {
      b.ell(PX + 9, 27, 4.5, 1.5, [
        _h('#A8A8B8'),
        _h('#D0D0DC'),
        _h('#F4F4FA'),
      ]);
      b.rect(PX + 7, 26, 4, 1, _h('#E0A040'));
    }
    if (tongue) {
      b.rect(PX + 1, 18, 2, 2, _h('#E85878'));
    }
    if (belly) {
      b.rect(PX - 3, 28, 6, 3, _h('#E8A468'));
    }
    if (kiss) {
      b.px(PX + 8, 14, _h('#E85878'));
      b.px(PX + 9, 13, _h('#FA98B0'));
    }
    if (legUp) {
      // Clear right-side foot pixels slightly & lift left boot in mid-step.
      b.rect(PX + 4, 42, 4, 3, _h('#2A1810'));
      b.rect(PX + 5, 43, 2, 1, _h('#D8A460'));
    }
    if (fan) {
      final fy = fanPhase % 2 == 0 ? 18 : 16;
      b.rect(PX + 7, fy, 5, 4, _h('#F4E8C8'));
      b.rect(PX + 8, fy + 1, 3, 2, _h('#E06040'));
    }
    if (hugItem != null) {
      final col = switch (hugItem) {
        'caja' => _h('#DC8430'),
        'bolsa' => _h('#34B0B0'),
        'sombrero' => _h('#EED28A'),
        _ => _h('#2E6CD0'),
      };
      b.rect(PX - 4, 26, 8, 7, _h('#2A1810'));
      b.rect(PX - 3, 27, 6, 5, col);
    }
  });
}

/* ---------- Preview-matching props (exact muralla-preview.html `THING` dimensions) ---------- */

/// 10 x 12 paper lantern hanging from the cord (lit or unlit for `apaga119`).
Sprite mkFarol({bool lit = true}) => _mk(10, 12, (b) {
  b.rect(4, 0, 2, 2, _h('#5A4A3C'));
  if (lit) {
    b.ell(
      5,
      6,
      4,
      4.2,
      _ramp(const ['#B8401C', '#E0601C', '#F8A030', '#FFD070']),
    );
    b.rect(3, 4, 4, 3, _h('#FFE9A0'));
    b.rect(4, 10, 2, 1, _h('#E0601C'));
    b.px(5, 11, _h('#E0601C'));
  } else {
    b.ell(5, 6, 4, 4.2, _ramp(const ['#443E46', '#58505C', '#6E6674']));
    b.rect(4, 10, 2, 1, _h('#443E46'));
    b.px(5, 11, _h('#443E46'));
  }
});

/// 12 x 22 abuela's camera on three legs (`THING.camara`).
Sprite mkCamara() => _mk(12, 22, (b) {
  b.rect(1, 1, 10, 7, _h('#3A3A46'));
  b.rect(1, 1, 10, 1, _h('#6E6E80'));
  b.ell(6, 5, 2.2, 2.2, [_h('#9CCBF5'), _h('#DCEEFF')]);
  b.rect(8, 0, 3, 1, _h('#FFE070'));
  b.rect(5, 8, 2, 5, _h('#6E6E80'));
  b.line(6, 12, 1, 21, _h('#4A4A5A'));
  b.line(6, 12, 6, 21, _h('#4A4A5A'));
  b.line(6, 12, 10, 21, _h('#4A4A5A'));
});

/// 8 x 16 tall candle in glass (`THING.vela`), with 3/2/1/0 red rings & lit/guttering flame.
Sprite mkVelaMuralla({
  int rings = 3,
  bool lit = true,
  bool guttering = false,
}) => _mk(8, 16, (b) {
  final top = switch (rings.clamp(0, 3)) {
    3 => 4,
    2 => 6,
    1 => 8,
    _ => 10,
  };
  b.rect(1, 9, 6, 6, _h('#CFE4EE'));
  b.rect(2, top, 4, 10 - top + 1, _h('#FBF0D2'));
  for (final y in const [9, 7, 5].take(rings.clamp(0, 3))) {
    b.rect(2, y, 4, 1, _h('#C8301C'));
  }
  if (lit && rings > 0) {
    if (guttering) {
      b.rect(3, top - 1, 2, 1, _h('#F2A650'));
      b.px(3, top - 2, _h('#FFE070'));
    } else {
      b.rect(3, top - 2, 2, 2, _h('#F2A650'));
      b.px(3, top - 3, _h('#FFE070'));
      b.px(4, top - 3, _h('#FFE070'));
      b.px(3, top - 1, _h('#FFFBEA'));
    }
  } else {
    b.px(3, top - 1, _h('#5A4A3C'));
  }
});

/// 6 x 10 glass of juice (`THING.jugo`).
Sprite mkJugoMuralla() => _mk(6, 10, (b) {
  b.rect(1, 2, 4, 7, _h('#F2A650'));
  b.rect(1, 2, 4, 1, _h('#FFE070'));
  b.rect(1, 3, 1, 5, _h('#FBCB86'));
});

/// 12 x 6 plate with food (`THING.plato`).
Sprite mkPlatoMuralla() => _mk(12, 6, (b) {
  b.ell(6, 3.6, 5, 1.6, _ramp(const ['#A8A8B8', '#D0D0DC', '#F4F4FA']));
  b.ell(6, 2.4, 2.8, 1.2, [_h('#B8601C'), _h('#E0A040')]);
  b.px(8, 2, _h('#389838'));
});

/// 14 x 24 wooden chair (`THING.silla`).
Sprite mkSillaMuralla() => _mk(14, 24, (b) {
  b.rect(2, 1, 2, 14, _h('#92602E'));
  b.rect(10, 1, 2, 14, _h('#92602E'));
  for (final y in const [2, 6, 10]) {
    b.rect(2, y, 10, 2, _h('#B88040'));
  }
  b.rect(1, 14, 12, 3, _h('#D8A460'));
  b.rect(1, 14, 12, 1, _h('#EEC888'));
  b.rect(2, 17, 2, 6, _h('#6E4220'));
  b.rect(10, 17, 2, 6, _h('#6E4220'));
});

/// 10 x 22 guitar (`THING.guitarra`).
Sprite mkGuitarra() => _mk(10, 22, (b) {
  b.rect(4, 1, 2, 11, _h('#6E4220'));
  b.rect(3, 0, 4, 2, _h('#4A2A14'));
  b.ell(5, 16, 4, 4.4, [_h('#92602E'), _h('#B88040'), _h('#D8A460')]);
  b.ell(5, 12.6, 2.8, 2.6, [_h('#92602E'), _h('#B88040')]);
  b.ell(5, 15.4, 1.3, 1.3, [_h('#2A1810')]);
});

/// 12 x 8 straw hat (`THING.sombrero`).
Sprite mkSombrero() => _mk(12, 8, (b) {
  b.ell(6, 5.4, 5, 1.8, [_h('#C8A050'), _h('#EED28A')]);
  b.ell(6, 3.2, 3, 2.6, [_h('#C8A050'), _h('#EED28A')]);
  b.rect(3, 3, 6, 1, _h('#7A1C1C'));
});

/// 10 x 12 cloth shopping bag (`THING.bolsa`).
Sprite mkBolsa() => _mk(10, 12, (b) {
  b.rect(1, 4, 8, 7, _h('#34B0B0'));
  b.rect(1, 4, 8, 1, _h('#5CCCC8'));
  b.rect(2, 1, 1, 4, _h('#1A6E70'));
  b.rect(7, 1, 1, 4, _h('#1A6E70'));
  b.rect(2, 1, 6, 1, _h('#1A6E70'));
  b.rect(3, 7, 4, 2, _h('#F8C838'));
});

/// 12 x 10 gift/personal box (`THING.caja`).
Sprite mkCaja() => _mk(12, 10, (b) {
  b.rect(1, 2, 10, 7, _h('#B8601C'));
  b.rect(1, 2, 10, 2, _h('#DC8430'));
  b.rect(5, 2, 2, 7, _h('#F8C838'));
});

/// 10 x 8 closed book (`THING.libro`).
Sprite mkLibroMuralla() => _mk(10, 8, (b) {
  b.rect(1, 1, 8, 6, _h('#2E6CD0'));
  b.rect(1, 1, 1, 6, _h('#1E4FA8'));
  b.rect(3, 2, 4, 1, _h('#FFFBEA'));
  b.rect(3, 4, 3, 1, _h('#FFFBEA'));
});

/// 22 x 10 guagua seen on the far road (`THING.guagua`), supporting door open/shut, blinking lights, and 0..4 faces.
Sprite mkGuagua({bool openDoor = true, bool blink = false, int faces = 0}) =>
    _mk(22, 10, (b) {
      b.rect(1, 1, 20, 7, _h('#E0A020'));
      b.rect(1, 1, 20, 1, _h('#F8C838'));
      b.rect(1, 6, 20, 1, _h('#C8301C'));
      for (var i = 0; i < 4; i++) {
        b.rect(3 + i * 4, 2, 3, 3, _h('#FFF4B0'));
        if (i < faces) {
          // Tiny passenger silhouette in lit window
          b.rect(4 + i * 4, 2, 2, 2, _h('#7A4C2C'));
          b.px(4 + i * 4, 4, _h('#38629A'));
        }
      }
      if (openDoor) {
        b.rect(17, 2, 3, 5, _h('#2A1810'));
      } else {
        b.rect(17, 2, 3, 4, _h('#C88618'));
        b.rect(17, 2, 3, 2, _h('#FFF4B0'));
      }
      b.px(21, 6, blink ? _h('#FFFFFF') : _h('#FFFFC0'));
      if (blink) b.px(21, 5, _h('#FFFFA0'));
      b.ell(5, 8.4, 1.7, 1.5, [_h('#2A1810')]);
      b.ell(16, 8.4, 1.7, 1.5, [_h('#2A1810')]);
    });

/// 4 x 7 far road figure 1 (`THING.lejos1`, no outline).
Sprite mkLejos1() => _mk(4, 7, (b) {
  b.rect(1, 0, 2, 2, _h('#D09460'));
  b.rect(0, 2, 4, 3, _h('#4A4A6A'));
  b.rect(0, 5, 4, 2, _h('#2A2A38'));
}, outline: false);

/// 4 x 7 far road figure 2 (`THING.lejos2`, no outline).
Sprite mkLejos2() => _mk(4, 7, (b) {
  b.rect(1, 0, 2, 2, _h('#B87A48'));
  b.rect(0, 2, 4, 3, _h('#8A3A1C'));
  b.rect(0, 5, 4, 2, _h('#2A2A38'));
}, outline: false);

/// Open sentry-box door (`24 x 28` stand-in matching muralla-preview.html `doorOpen`, no outline).
Sprite mkDoorOpen(int w, int h, List<int> colour) => _mk(w, h, (b) {
  final leaf =
      0xFF000000 |
      ((colour[2] & 0xFF) << 16) |
      ((colour[1] & 0xFF) << 8) |
      (colour[0] & 0xFF);
  b.rect(0, 0, w, h, _h('#1A1424'));
  b.rect(0, 0, w, 1, _h('#2A2038'));
  b.rect(0, h - 3, w, 3, _h('#3A2E34'));
  b.rect(0, 0, 3, h, leaf);
  b.rect(w - 2, 3, 1, h - 7, _h('#2A2038'));
}, outline: false);

/* ---------- Additional Needs sprites ---------- */

/// Sleeping/awake ledge pigeon (10 x 8, optional open eye) or flapping pigeon burst (`flying: true`).
Sprite mkPaloma({bool flying = false, bool openEye = false}) => _mk(10, 8, (b) {
  final gray = _ramp(const ['#7A8294', '#A2AAB8', '#C6CEDC']);
  if (flying) {
    b.ell(5, 5, 3.2, 2.0, gray);
    b.cap(2, 4, 1, 1, 1.2, [gray[2]]);
    b.cap(6, 4, 9, 1, 1.2, [gray[2]]);
    b.px(7, 4, _h('#E8A030'));
  } else {
    b.ell(5, 5, 3.2, 2.2, gray);
    b.ell(7, 3, 1.8, 1.8, gray);
    b.px(8, 3, _h('#E8A030'));
    b.px(7, 2, openEye ? _h('#FFFFFF') : _h('#2A2038'));
  }
});

/// Camera flash burst (20 x 20) for `foto117`.
Sprite mkFlashMuralla() => _mk(20, 20, (b) {
  final col = _h('#FFFBE0');
  b.ell(10, 10, 5, 5, [_h('#FFE880'), col]);
  b.rect(9, 1, 2, 18, col);
  b.rect(1, 9, 18, 2, col);
  b.line(3, 3, 16, 16, col);
  b.line(16, 3, 3, 16, col);
}, outline: false);

/// Sliding printed photo (`18 x 16`, brightness 3 bright, 2 medium, 1 dark with white eyes/teeth).
Sprite mkFotoSlide(int brightness) => _mk(18, 16, (b) {
  b.rect(1, 1, 16, 14, _h('#F4F4FA'));
  final sky = switch (brightness.clamp(1, 3)) {
    3 => _h('#3B669A'),
    2 => _h('#263B5E'),
    _ => _h('#161A26'),
  };
  b.rect(2, 2, 14, 10, sky);
  final dot = switch (brightness.clamp(1, 3)) {
    3 => _h('#FFE070'),
    2 => _h('#D89838'),
    _ => _h('#403848'),
  };
  for (final x in const [4, 8, 12]) {
    b.rect(x, 3, 2, 2, dot);
  }
  final fg = brightness <= 1 ? _h('#242230') : _h('#D89A60');
  for (final x in const [4, 7, 10, 13]) {
    b.rect(x, 7, 2, 4, fg);
    if (brightness <= 1) {
      b.px(x, 8, _h('#FFFFFF'));
      b.px(x + 1, 9, _h('#F4F4FA'));
    }
  }
});

/// 7 x 9 golden music note for `cancion118`.
Sprite mkNotaMuralla() => _mk(7, 9, (b) {
  final c = _h('#FFD848');
  b.rect(3, 1, 1, 6, c);
  b.rect(4, 1, 2, 2, c);
  b.rect(1, 5, 3, 3, c);
});

/// 15 x 9 three celebration stars.
Sprite mkEstrellasMuralla() => _mk(15, 9, (b) {
  for (final (sx, sy) in const [(2, 4), (7, 1), (12, 4)]) {
    b.rect(sx - 1, sy, 3, 3, _h('#F8C838'));
    b.px(sx, sy - 1, _h('#FFE880'));
    b.px(sx, sy + 3, _h('#FFE880'));
    b.px(sx - 2, sy + 1, _h('#FFE880'));
    b.px(sx + 2, sy + 1, _h('#FFE880'));
  }
});

/// 11 x 10 pink celebration heart.
Sprite mkCorazonMuralla() => _mk(11, 10, (b) {
  final c = _h('#E85878');
  final hi = _h('#FA98B0');
  b.rect(2, 2, 3, 2, c);
  b.rect(6, 2, 3, 2, c);
  b.rect(1, 3, 9, 2, c);
  b.rect(2, 5, 7, 2, c);
  b.rect(4, 7, 3, 1, c);
  b.px(5, 8, c);
  b.px(3, 3, hi);
});

/// All La muralla sprites, for the content lane's sheet (`tool/make_muralla_sprites_test.dart`).
List<(String, Sprite)> murallaSpritesSheet() => [
  ('abuela', mkAbuela('idle', false)),
  ('abuelo', mkPersona(MURALLA_WHO['abuelo']!, 'idle', false, false)),
  ('luis', mkPersona(MURALLA_WHO['luis']!, 'idle', false, false)),
  ('carmen', mkPersona(MURALLA_WHO['carmen']!, 'idle', false, false)),
  ('pepe', mkPersona(MURALLA_WHO['pepe']!, 'idle', false, false)),
  ('maestra', mkPersona(MURALLA_WHO['maestra']!, 'idle', false, false)),
  ('piraguero', mkPersona(MURALLA_WHO['piraguero']!, 'idle', false, false)),
  ('senor', mkPersona(MURALLA_WHO['senor']!, 'idle', false, false)),
  ('senora', mkPersona(MURALLA_WHO['senora']!, 'idle', false, false)),
  (
    'musico1_sent',
    murallaWithHat(mkPersona(MURALLA_WHO['musico1']!, 'idle', false, true)),
  ),
  ('musico2_sent', mkPersona(MURALLA_WHO['musico2']!, 'idle', false, true)),
  ('farol_lit', mkFarol(lit: true)),
  ('farol_off', mkFarol(lit: false)),
  ('camara', mkCamara()),
  ('vela_3', mkVelaMuralla(rings: 3, lit: true)),
  ('vela_2', mkVelaMuralla(rings: 2, lit: true)),
  ('vela_1', mkVelaMuralla(rings: 1, lit: true, guttering: true)),
  ('vela_0', mkVelaMuralla(rings: 0, lit: false)),
  ('jugo', mkJugoMuralla()),
  ('plato', mkPlatoMuralla()),
  ('silla', mkSillaMuralla()),
  ('guitarra', mkGuitarra()),
  ('sombrero', mkSombrero()),
  ('bolsa', mkBolsa()),
  ('caja', mkCaja()),
  ('libro', mkLibroMuralla()),
  ('guagua_open', mkGuagua(openDoor: true, faces: 0)),
  ('guagua_4', mkGuagua(openDoor: false, faces: 4)),
  ('lejos1', mkLejos1()),
  ('lejos2', mkLejos2()),
  ('puerta_roja_open', mkDoorOpen(24, 28, const [206, 70, 64])),
  ('puerta_azul_open', mkDoorOpen(24, 28, const [70, 110, 206])),
  ('paloma_rest', mkPaloma(flying: false, openEye: true)),
  ('paloma_fly', mkPaloma(flying: true)),
  ('flash', mkFlashMuralla()),
  ('foto_3', mkFotoSlide(3)),
  ('foto_1', mkFotoSlide(1)),
  ('nota', mkNotaMuralla()),
  ('estrellas', mkEstrellasMuralla()),
  ('corazon', mkCorazonMuralla()),
];

/// Bottom ink anchor helper re-exported for `muralla.dart`.
int murallaInkBottom(Sprite s) => inkBottom(s);
