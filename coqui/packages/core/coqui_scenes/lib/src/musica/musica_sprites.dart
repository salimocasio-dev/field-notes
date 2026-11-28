// Sprites that only La música draws (place 10, El fuerte, scene 2: `musica`; stories 111 to 113):
// - instruments on rack and held: `guitarra` (12 × 22), `tambor` (12 × 14), `guitarraH` (22 × 8), `tamborH` (12 × 12)
// - stage & props: `microfono` (6 × 28, upright/low/high), `nota` (14 × 14, lit/dark), `camara` (10 × 8), `album`,
//   spare photo paper sheets `hojas` (0..3), camera flash, printed photo, floating musical notes (small/big/jagged),
//   fanning hat, snack bite
// - people: `musico1` (hat), `musico2` (beard), standing/seated guests (`GU` 1..6 + `joven`), plus eyes-shut, laughing,
//   yawning, eating, and covering-ears variants.
//
// Every stand-in dimension matches musica-sheet.json's spot boxes and musica-preview.html.
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

/// Colour palette and outfits for La música's cast.
final Who MUSICA_MUSICO1 = Who(
  piel: PIEL['b']!,
  pelo: PELO['negro']!,
  peinado: 'corto',
  ropa: RP.tan,
  abajo: RP.grey,
);

final Who MUSICA_MUSICO2 = Who(
  piel: PIEL['c']!,
  pelo: PELO['castano']!,
  peinado: 'corto',
  ropa: RP.red,
  abajo: RP.wood,
);

/// Guest outfits matching musica-preview.html (`GU` 1..6) plus `joven` from `POOL113`.
final Map<String, Who> MUSICA_PEOPLE = {
  'mama': FAM['mama']!,
  'papa': FAM['papa']!,
  'abuelo': FAM['abuelo']!,
  'luis': FAM['hermano']!,
  'carmen': FAM['hermana']!,
  'musico1': MUSICA_MUSICO1,
  'musico2': MUSICA_MUSICO2,
  'mujer': Who(
    piel: PIEL['c']!,
    pelo: PELO['negro']!,
    peinado: 'largo',
    ropa: RP.purp,
    falda: true,
    zapato: _h('#3A2414'),
  ),
  'hombre': Who(
    piel: PIEL['b']!,
    pelo: PELO['castano']!,
    peinado: 'corto',
    ropa: RP.grn,
    abajo: RP.grey,
  ),
  'senora': Who(
    piel: PIEL['a']!,
    pelo: PELO['negro']!,
    peinado: 'largo',
    ropa: RP.teal,
    falda: true,
    zapato: _h('#7A1C1C'),
  ),
  'senor': Who(
    piel: PIEL['c']!,
    pelo: PELO['blanco']!,
    peinado: 'corto',
    ropa: RP.tan,
    abajo: RP.wood,
  ),
  'joven': Who(
    piel: PIEL['b']!,
    pelo: PELO['castano']!,
    peinado: 'corto',
    ropa: RP.blue,
    abajo: RP.grey,
  ),
};

Sprite _cloneSprite(Sprite src) =>
    Sprite(src.w, src.h, Uint32List.fromList(src.px));

void _fillBox(Sprite s, int x0, int y0, int w, int h, int col) {
  for (var y = y0; y < y0 + h; y++) {
    if (y < 0 || y >= s.h) continue;
    for (var x = x0; x < x0 + w; x++) {
      if (x < 0 || x >= s.w) continue;
      s.px[y * s.w + x] = col;
    }
  }
}

void _drawHat(Sprite s, int X) {
  _fillBox(s, X - 7, 0, 14, 5, _h('#2A1810'));
  _fillBox(s, X - 11, 4, 22, 3, _h('#2A1810'));
  _fillBox(s, X - 6, 1, 12, 3, _h('#E2A85A'));
  _fillBox(s, X - 10, 5, 20, 1, _h('#E2A85A'));
  _fillBox(s, X - 6, 3, 12, 1, _h('#A82A26'));
}

void _drawBeard(Sprite s, int X) {
  _fillBox(s, X - 6, 13, 12, 7, _h('#2A1810'));
  _fillBox(s, X - 5, 14, 10, 5, _h('#3A2414'));
  _fillBox(s, X - 2, 15, 4, 1, _h('#7A2A1A'));
}

/// Builds a person sprite for La música (standing or seated), including musician hat/beard and expression overlays.
Sprite mkMusicaPersona(
  String id,
  String pose, {
  bool open = false,
  bool sent = false,
  bool pies = false,
  bool eyesShut = false,
  bool laugh = false,
  bool yawn = false,
  bool eat = false,
  bool coverEars = false,
  bool fan = false,
  bool dance = false,
  int danceStep = 0,
}) {
  if (id == 'abuela') {
    final base = sent ? mkAbuelaS(pose, open, pies) : mkAbuela(pose, open);
    if (!laugh && !sent) return base;
    final s = _cloneSprite(base);
    final X = sent ? 17 : 30;
    if (laugh) {
      _fillBox(s, X - 2, 14, 4, 2, _h('#7A2A1A'));
    }
    return s;
  }

  final who = MUSICA_PEOPLE[id] ?? MUSICA_PEOPLE['senora']!;
  final effectiveOpen = open || laugh || yawn;
  final base = mkPersona(who, pose, effectiveOpen, sent);
  if (id != 'musico1' &&
      id != 'musico2' &&
      !eyesShut &&
      !laugh &&
      !yawn &&
      !eat &&
      !coverEars &&
      !fan &&
      !dance) {
    return base;
  }

  final s = _cloneSprite(base);
  const X = PX;
  if (id == 'musico1') {
    _drawHat(s, X);
  } else if (id == 'musico2') {
    _drawBeard(s, X);
  }

  if (eyesShut || laugh || yawn) {
    // Shut/curved eyes over eye row (y = 10 on mkPersona)
    final col = _h('#2A1810');
    _fillBox(s, X - 4, 10, 3, 1, col);
    _fillBox(s, X + 2, 10, 3, 1, col);
  }
  if (yawn) {
    _fillBox(s, X - 2, 13, 4, 3, _h('#5A1C1C'));
    _fillBox(s, X - 1, 14, 2, 2, _h('#1C0A0A'));
  }
  if (laugh) {
    // Smile + hand pressed to belly while laughing
    _fillBox(s, X - 3, 13, 6, 2, _h('#8A2A24'));
    _fillBox(s, X - 2, 14, 4, 1, _h('#FFFFFF'));
    if (!sent) {
      final skin = who.piel[1];
      _fillBox(s, X - 2, 24, 5, 3, skin);
      _fillBox(s, X - 2, 24, 5, 1, OUT);
    }
  }
  if (eat) {
    // Pastelito/snack held near chest/mouth
    _fillBox(s, X + 2, 18, 5, 3, _h('#E2A85A'));
    _fillBox(s, X + 3, 19, 3, 1, _h('#FFF0C0'));
  }
  if (coverEars) {
    final skin = who.piel[1];
    _fillBox(s, X - 8, 9, 2, 4, skin);
    _fillBox(s, X + 6, 9, 2, 4, skin);
    _fillBox(s, X - 9, 9, 1, 4, OUT);
    _fillBox(s, X + 8, 9, 1, 4, OUT);
  }
  if (fan) {
    // Hat / fan held alongside face
    _fillBox(s, X - 12, 12, 5, 7, _h('#E2A85A'));
    _fillBox(s, X - 12, 14, 5, 1, _h('#A82A26'));
  }
  if (dance && !sent) {
    // Dancing: raised alternating arms + lifted step cue + small rhythm accents
    final skin = who.piel[1];
    final shirt = who.ropa[1];
    final step = danceStep % 2;
    if (step == 0) {
      // Right arm raised high, left arm out to side, left foot stepped up
      _fillBox(s, X + 7, 13, 3, 6, shirt);
      _fillBox(s, X + 8, 10, 3, 3, skin);
      _fillBox(s, X + 8, 9, 3, 1, OUT);
      _fillBox(s, X - 10, 19, 3, 3, shirt);
      _fillBox(s, X - 11, 22, 2, 2, skin);
      _fillBox(s, X - 6, 39, 4, 2, _h('#4A2E1A'));
    } else {
      // Left arm raised high, right arm out to side, right foot stepped up
      _fillBox(s, X - 10, 13, 3, 6, shirt);
      _fillBox(s, X - 11, 10, 3, 3, skin);
      _fillBox(s, X - 11, 9, 3, 1, OUT);
      _fillBox(s, X + 7, 19, 3, 3, shirt);
      _fillBox(s, X + 9, 22, 2, 2, skin);
      _fillBox(s, X + 2, 39, 4, 2, _h('#4A2E1A'));
    }
    // Rhythm accent pixels beside shoulders
    final noteCol = _h('#FFE070');
    _fillBox(s, step == 0 ? X - 10 : X + 8, 8, 2, 2, noteCol);
  }

  return s;
}

/// Guitar hanging on the rack: 12 × 22 (musica-preview.html `guitarra`).
Sprite mkGuitarra() => _mk(12, 22, (b) {
  b.rect(5, 1, 2, 2, _h('#4A2A14'));
  b.rect(5, 3, 2, 8, _h('#6E4220'));
  b.ell(6, 13, 3.6, 3, _hs(['#A8682C', '#C8853C', '#E2A85A']));
  b.ell(6, 17.4, 4.8, 3.6, _hs(['#A8682C', '#C8853C', '#E2A85A']));
  b.ell(6, 15.4, 1.3, 1.3, [_h('#2A1810')]);
  b.rect(5, 19, 2, 1, _h('#4A2A14'));
});

/// Drum hanging on the rack: 12 × 14 (musica-preview.html `tambor`).
Sprite mkTambor() => _mk(12, 14, (b) {
  b.ell(6, 3, 4.8, 1.9, _hs(['#D8D8E4', '#F4F4FA']));
  b.rect(1, 3, 10, 9, _h('#B8601C'));
  b.rect(1, 3, 3, 9, _h('#92602E'));
  b.rect(9, 3, 2, 9, _h('#7A4A1E'));
  b.rect(1, 5, 10, 1, _h('#6E4220'));
  b.rect(1, 9, 10, 1, _h('#6E4220'));
  b.ell(6, 12, 4.8, 1.2, [_h('#7A4A1E')]);
});

/// Guitar lying across the músico's knees: 22 × 8 (musica-preview.html `guitarraH`).
Sprite mkGuitarraH() => _mk(22, 8, (b) {
  b.rect(1, 3, 6, 2, _h('#6E4220'));
  b.rect(0, 3, 2, 2, _h('#4A2A14'));
  b.ell(10, 4, 3.4, 2.6, _hs(['#A8682C', '#C8853C', '#E2A85A']));
  b.ell(16.5, 4, 4.6, 3, _hs(['#A8682C', '#C8853C', '#E2A85A']));
  b.ell(15, 4, 1.2, 1.2, [_h('#2A1810')]);
});

/// Barrel drum held across the músico's knees: 12 × 12.
Sprite mkTamborH() => _mk(12, 12, (b) {
  b.ell(6, 3, 4.8, 1.9, _hs(['#D8D8E4', '#F4F4FA']));
  b.rect(1, 3, 10, 7, _h('#B8601C'));
  b.rect(1, 5, 10, 1, _h('#6E4220'));
  b.rect(1, 8, 10, 1, _h('#6E4220'));
  b.ell(6, 10, 4.8, 1.1, [_h('#7A4A1E')]);
});

/// Microphone on its stand: 6 × 28 (musica-preview.html `microfono`; [tilt] `'up'|'high'|'low'`).
Sprite mkMicrofono([String tilt = 'up']) => _mk(6, 28, (b) {
  final headY = tilt == 'low' ? 12.0 : (tilt == 'high' ? 2.5 : 3.0);
  b.rect(2, headY.round() + 2, 2, 22 - headY.round(), _h('#6E6E80'));
  b.ell(3, headY, 1.9, 2.4, _hs(['#3A3A46', '#6E6E80', '#B8B8C8']));
  b.rect(1, 24, 4, 2, _h('#3A3A46'));
});

/// Hanging paper note over the stage: 14 × 14 (musica-preview.html `nota`).
Sprite mkNotaPapel({bool lit = true}) => _mk(14, 14, (b) {
  b.rect(1, 1, 12, 12, lit ? _h('#FFE070') : _h('#464258'));
  b.rect(2, 2, 10, 10, lit ? _h('#FFF4B0') : _h('#5C5872'));
  final ink = lit ? _h('#20140A') : _h('#2A2636');
  b.ell(5, 9.5, 2, 1.5, [ink]);
  b.rect(6, 3, 1, 7, ink);
  b.rect(7, 3, 3, 1, ink);
  b.rect(9, 4, 1, 2, ink);
});

/// Abuela's camera on the frog's chest: 10 × 8 (musica-preview.html `camara`).
Sprite mkCamara() => _mk(10, 8, (b) {
  b.rect(1, 2, 8, 5, _h('#3A3A46'));
  b.rect(1, 2, 8, 1, _h('#6E6E80'));
  b.ell(5, 4.6, 1.8, 1.8, _hs(['#2E6CD0', '#9CCBF5', '#DCEEFF']));
  b.rect(6, 1, 2, 1, _h('#FFE070'));
});

/// Open album on abuela's lap when she sits on the floor stool.
Sprite mkAlbumMusica() => _mk(14, 8, (b) {
  b.rect(1, 2, 12, 5, _h('#92502A'));
  b.rect(2, 2, 4, 4, _h('#F4F0E0'));
  b.rect(8, 2, 4, 4, _h('#F4F0E0'));
  b.rect(6, 2, 2, 5, _h('#6E381A'));
});

/// Spare white photo sheets (`1..3`) sticking out of abuela's pocket.
Sprite mkHojasMusica(int n) => _mk(8, 8, (b) {
  final c = n.clamp(1, 3);
  for (var i = 0; i < c; i++) {
    b.rect(1 + i * 2, 2 - (i & 1), 2, 5, _h('#F8F8FF'));
    b.rect(1 + i * 2, 2 - (i & 1), 2, 1, _h('#C0D8F0'));
  }
});

/// Floating musical notes (`kind`: 0 = small notes, 1 = big notes, 2 = jagged sour noise).
Sprite mkNotasFloat({int kind = 0, int anim = 0}) {
  final dy = (anim % 2) == 0 ? 0 : -1;
  if (kind == 2) {
    return _mk(16, 12, (b) {
      b.line(2, 8 + dy, 5, 3 + dy, _h('#EC5050'));
      b.line(5, 3 + dy, 8, 9 + dy, _h('#EC5050'));
      b.line(8, 9 + dy, 11, 3 + dy, _h('#F8B038'));
      b.line(11, 3 + dy, 13, 8 + dy, _h('#F8B038'));
    });
  }
  final col = kind == 1 ? _h('#FFE070') : _h('#9CCBF5');
  final w = kind == 1 ? 14 : 12;
  return _mk(w, 12, (b) {
    b.ell(4, 8 + dy, 1.8, 1.3, [col]);
    b.rect(5, 3 + dy, 1, 5, col);
    b.rect(5, 3 + dy, 4, 1, col);
    if (kind == 1) {
      b.ell(10, 7 - dy, 1.8, 1.3, [col]);
      b.rect(11, 2 - dy, 1, 5, col);
    }
  });
}

/// Camera flash burst and printed paper photo.
Sprite mkFlashMusica() => _mk(16, 14, (b) {
  final w = _h('#FFFFFF'), y = _h('#FFE070');
  b.ell(8, 7, 4, 3, [y, w]);
  b.rect(7, 1, 2, 12, w);
  b.rect(2, 6, 12, 2, w);
});

Sprite mkFotoPapel({bool bad = false}) => _mk(10, 12, (b) {
  b.rect(1, 1, 8, 10, _h('#F4F4FA'));
  b.rect(2, 2, 6, 6, bad ? _h('#B85050') : _h('#6EA8E0'));
  if (bad) {
    b.line(3, 3, 6, 6, _h('#FFE070'));
    b.line(6, 3, 3, 6, _h('#FFE070'));
  }
});

/// Pink pixel heart for celebration.
Sprite mkCorazonMusica() => _mk(9, 8, (b) {
  final col = _h('#E84878');
  b.rect(2, 2, 2, 2, col);
  b.rect(5, 2, 2, 2, col);
  b.rect(1, 3, 7, 2, col);
  b.rect(2, 5, 5, 1, col);
  b.rect(3, 6, 3, 1, col);
  b.px(4, 6, col);
});

/// Gold pixel star for celebration.
Sprite mkEstrellaMusica() => _mk(9, 9, (b) {
  final col = _h('#FFD840');
  b.rect(4, 1, 1, 7, col);
  b.rect(1, 4, 7, 1, col);
  b.rect(3, 3, 3, 3, col);
  b.px(2, 6, col);
  b.px(6, 6, col);
});

/// Every La música-only sprite with its unique name, for `tool/make_musica_sprites_test.dart`.
List<(String, Sprite)> musicaSpritesSheet() => [
  ('guitarra', mkGuitarra()),
  ('tambor', mkTambor()),
  ('guitarra_h', mkGuitarraH()),
  ('tambor_h', mkTamborH()),
  ('microfono_up', mkMicrofono('up')),
  ('microfono_low', mkMicrofono('low')),
  ('microfono_high', mkMicrofono('high')),
  ('nota_lit', mkNotaPapel(lit: true)),
  ('nota_dark', mkNotaPapel(lit: false)),
  ('camara', mkCamara()),
  ('album', mkAlbumMusica()),
  ('hojas_1', mkHojasMusica(1)),
  ('hojas_2', mkHojasMusica(2)),
  ('hojas_3', mkHojasMusica(3)),
  ('notas_small', mkNotasFloat(kind: 0)),
  ('notas_big', mkNotasFloat(kind: 1)),
  ('notas_sour', mkNotasFloat(kind: 2)),
  ('flash', mkFlashMusica()),
  ('foto_ok', mkFotoPapel(bad: false)),
  ('foto_bad', mkFotoPapel(bad: true)),
  ('corazon', mkCorazonMusica()),
  ('estrella', mkEstrellaMusica()),
  ('musico1', mkMusicaPersona('musico1', 'idle', sent: true)),
  (
    'musico1_shut',
    mkMusicaPersona('musico1', 'idle', sent: true, eyesShut: true),
  ),
  ('musico2', mkMusicaPersona('musico2', 'idle', sent: true)),
  (
    'musico2_shut',
    mkMusicaPersona('musico2', 'idle', sent: true, eyesShut: true),
  ),
  ('abuela_s', mkMusicaPersona('abuela', 'idle', sent: true)),
  ('senora', mkMusicaPersona('senora', 'idle')),
  ('mujer_laugh', mkMusicaPersona('mujer', 'idle', laugh: true)),
  ('hombre_yawn', mkMusicaPersona('hombre', 'idle', yawn: true)),
  ('joven_eat', mkMusicaPersona('joven', 'idle', eat: true)),
  ('senor_ears', mkMusicaPersona('senor', 'idle', coverEars: true)),
  ('abuelo_fan', mkMusicaPersona('abuelo', 'idle', sent: true, fan: true)),
];
