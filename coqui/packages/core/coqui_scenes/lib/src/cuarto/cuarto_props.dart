// El cuarto's props, baby, Z's, pillow, plate, bell, blankets, clothes, clock hands, FX, and sprite sheet list
// (part of cuarto_sprites.dart).
part of 'cuarto_sprites.dart';

final List<int> _white = _ramp(const [
  '#C8C8D0',
  '#E4E4EA',
  '#F6F6FA',
  '#FFFFFF',
]);

final List<int> _brass = _ramp(const [
  '#7A4A1E',
  '#B88A2A',
  '#E0B84A',
  '#FFE070',
]);

final List<int> _plate = _ramp(const ['#A8A8B8', '#D0D0DC', '#F4F4FA']);

/// The big pillow on the floor (`almohada_suelo`): 20 x 12 (`cuarto-preview.html` `THING.almohada`).
Sprite mkAlmohada() => _mk(20, 12, (b) {
  b.ell(10, 6, 8.6, 4.6, _white);
  b.line(4, 4, 7, 3, _h('#C8C8D0'));
  b.line(13, 8, 16, 7, _h('#C8C8D0'));
});

/// The plate on the night table (`plato`) with [n] (0..3) pieces of bread with butter: 12 x 6
/// (`cuarto-preview.html` `THING.plato`).
Sprite mkPlatoCuarto(int n) {
  final count = n.clamp(0, 3);
  return _mk(12, 6, (b) {
    b.ell(6, 3.6, 5.4, 2.2, _plate);
    for (var i = 0; i < count; i++) {
      b.rect(2 + i * 3, 1, 3, 2, _h(i.isOdd ? '#D8A040' : '#F0C060'));
    }
  });
}

/// The brass bell on the night table (`campana`): 6 x 8 (`cuarto-preview.html` `THING.campana`).
Sprite mkCampana() => _mk(6, 8, (b) {
  b.rect(2, 0, 2, 1, _brass[1]);
  b.ell(3, 3.6, 2.4, 2.6, _brass);
  b.rect(0, 5, 6, 1, _brass[1]);
  b.rect(0, 6, 6, 1, _brass[0]);
  b.px(3, 7, _h('#6A6A7A'));
});

/// The plaid blanket on abuelo's knees (`manta_abuelo`): 16 x 10 (`cuarto-preview.html` `THING.mantaAbuelo`,
/// anchored at `(8, 6)`).
Sprite mkMantaAbuelo() => _mk(16, 10, (b) {
  b.rect(1, 1, 14, 8, _h('#C86A50'));
  for (var x = 1; x < 15; x += 4) {
    b.rect(x, 1, 1, 8, _h('#F0B890'));
  }
  for (var y = 2; y < 9; y += 3) {
    b.rect(1, y, 14, 1, _h('#7A3A2E'));
  }
});

/// The baby in the cradle (`bebe`): 14 x 10 (`cuarto-preview.html` `THING.bebe`), with [state]:
/// `'sleep'` (3 Z's), `'stir'` (2 Z's: turned over / sucking thumb), `'awake'` (1 Z: sitting up and laughing).
Sprite mkBebeCuarto(String state) => _mk(14, 10, (b) {
  final skin = PIEL['a']!;
  if (state == 'awake') {
    b.rect(3, 4, 8, 5, _h('#F8D858'));
    b.rect(3, 4, 8, 1, _h('#FFEA90'));
    b.ell(7, 3.4, 3.4, 3.0, skin);
    b.px(6, 3, _h('#20140A'));
    b.px(8, 3, _h('#20140A'));
    b.rect(6, 5, 2, 1, _h('#7A1C1C'));
    b.px(2, 5, skin[3]);
    b.px(11, 5, skin[3]);
    return;
  }
  if (state == 'stir') {
    b.ell(5, 5, 3.4, 3.4, skin);
    b.px(4, 5, _h('#20140A'));
    b.px(6, 5, _h('#20140A'));
    b.px(5, 6, skin[4]); // thumb near mouth
    b.rect(7, 2, 6, 7, _h('#F8D858'));
    b.rect(7, 2, 6, 1, _h('#FFEA90'));
    b.rect(7, 5, 6, 1, _h('#E0B030'));
    return;
  }
  b.ell(4, 5, 3.4, 3.4, skin);
  b.px(3, 5, _h('#20140A'));
  b.px(5, 5, _h('#20140A'));
  b.rect(7, 2, 6, 7, _h('#F8D858'));
  b.rect(7, 2, 6, 1, _h('#FFEA90'));
  b.rect(7, 4, 6, 1, _h('#E0B030'));
});

/// Sleep Z's over the cradle (`zetas`): 14 x 10 (`cuarto-preview.html` `THING.zetas`), [n] in `1..3`.
Sprite mkZetas(int n) {
  final count = n.clamp(0, 3);
  return _mk(14, 10, (b) {
    void z(int x, int y, int k) {
      b.rect(x, y, k, 1, _h('#FFFFFF'));
      b.rect(x, y + k - 1, k, 1, _h('#FFFFFF'));
      for (var i = 0; i < k; i++) {
        b.px(x + k - 1 - i, y + i, _h('#FFFFFF'));
      }
    }

    if (count >= 1) z(1, 6, 3);
    if (count >= 2) z(5, 3, 4);
    if (count >= 3) z(9, 0, 5);
  });
}

/// Clothes & accessories for the chair (`ropa_a` / `ropa_b`, 12 x 10, anchor `(6, 10)`) and found items (`busca96`):
/// `'pantalon'`, `'zapatos'`, `'camisa'`, `'sombrero'`, `'reloj'`.
Sprite mkRopaCuarto(String kind) => _mk(12, 10, (b) {
  switch (kind) {
    case 'pantalon':
      b.rect(1, 1, 10, 8, _h('#6AA0E0'));
      b.rect(1, 1, 10, 2, _h('#9AC4F4'));
      b.rect(1, 4, 10, 1, _h('#4A78B8'));
      b.rect(1, 8, 10, 1, _h('#4A78B8'));
    case 'camisa':
      b.rect(3, 1, 6, 8, _h('#58A03C'));
      b.rect(0, 1, 3, 4, _h('#58A03C'));
      b.rect(9, 1, 3, 4, _h('#58A03C'));
      b.rect(4, 1, 4, 1, _h('#88C860'));
      b.rect(3, 8, 6, 1, _h('#3E7A2A'));
    case 'zapatos':
      b.ell(3.5, 6.2, 2.6, 2.0, [_h('#B8B8C8'), _h('#F2F2F8')]);
      b.rect(1, 8, 5, 1, _h('#3A2414'));
      b.ell(8.5, 5.2, 2.6, 2.0, [_h('#B8B8C8'), _h('#F2F2F8')]);
      b.rect(6, 7, 5, 1, _h('#3A2414'));
    case 'sombrero':
      b.ell(6, 6.5, 5.2, 2.2, _HAT_STRAW);
      b.rect(3, 2, 6, 4, _HAT_STRAW[2]);
      b.rect(3, 2, 6, 1, _HAT_STRAW[3]);
      b.rect(3, 5, 6, 1, _h('#D0403A'));
    case 'reloj':
      b.rect(5, 1, 2, 8, _h('#8A5A2A'));
      b.ell(6, 5, 3.0, 2.8, _brass);
      b.ell(6, 5, 1.8, 1.8, [_h('#FFFFFF')]);
      b.px(6, 4, _h('#20140A'));
      b.px(7, 5, _h('#20140A'));
  }
});

/// Wall clock hands (13 x 13, centered at `(6, 6)`): `hora == 7` (7:00) or `7.5` (7:30).
Sprite mkManecillas(double hora) {
  final b = Buf(13, 13);
  final hand = _h('#20140A');
  final half = (hora - 7.0).abs() > 0.2;
  if (!half) {
    // 7:00 -> minute hand straight up to 12; hour hand down-left to 7.
    b.line(6, 6, 6, 2, hand);
    b.line(6, 6, 4, 9, hand);
  } else {
    // 7:30 -> minute hand straight down to 6; hour hand down-left between 7 and 8.
    b.line(6, 6, 6, 10, hand);
    b.line(6, 6, 3, 8, hand);
  }
  b.px(6, 6, _h('#C03828'));
  return b.done();
}

/// Soft bell tinkle sparkle over `campana`: 14 x 8.
Sprite mkTinkleFx(int frame) {
  final b = Buf(14, 8);
  final c1 = _h('#FFE040');
  final c2 = _h('#FFF8C0');
  final d = frame % 2 == 0 ? 0 : 1;
  b.line(2 - d, 6, 0, 3, c1);
  b.line(11 + d, 6, 13, 3, c1);
  b.px(6, 1 + d, c2);
  b.px(7, 1 + d, c2);
  b.px(4, 2, c1);
  b.px(9, 2, c1);
  return b.done();
}

/// Howl / loud cry burst (`manta97` ok == 0): 14 x 10.
Sprite mkGritoFx(int frame) {
  final b = Buf(14, 10);
  final c1 = _h('#FFE040');
  final c2 = _h('#FF8040');
  final d = frame % 2 == 0 ? 0 : 1;
  b.line(2, 5, 0, 3 - d, c2);
  b.line(2, 7, 0, 8 + d, c1);
  b.line(11, 5, 13, 3 - d, c2);
  b.line(11, 7, 13, 8 + d, c1);
  b.rect(6, 1, 2, 5, c1);
  b.rect(6, 7, 2, 2, c2);
  return b.done();
}

/// Camera flash burst (`final98`): 14 x 14.
Sprite mkFlashCuarto() {
  final b = Buf(14, 14);
  final y = _h('#FFE870');
  final w = _h('#FFFFFF');
  b.line(7, 0, 7, 13, y);
  b.line(0, 7, 13, 7, y);
  b.line(2, 2, 11, 11, y);
  b.line(2, 11, 11, 2, y);
  b.ell(7, 7, 3.0, 3.0, [w]);
  return b.done();
}

/// Photo card on the camera screen (`final98`), showing Luis neat (`3`), with hair tuft (`2`),
/// or hair tuft + shirt tail + grin (`1`): 22 x 24.
Sprite mkFotoCard(int neat) => _mk(22, 24, (b) {
  b.rect(0, 0, 22, 24, _h('#FFFDF4'));
  b.rect(2, 2, 18, 17, _h('#C8DDF4'));
  // Mini Luis inside the photo frame.
  final skin = PIEL['b']!;
  final hair = PELO['negro']!;
  b.rect(8, 15, 2, 4, RP.blue[1]);
  b.rect(12, 15, 2, 4, RP.blue[0]);
  b.rect(7, 10, 8, 5, RP.grn[2]);
  if (neat <= 1) {
    b.rect(7, 14, 3, 2, RP.grn[3]);
    b.rect(12, 14, 3, 2, RP.grn[1]);
  }
  b.ell(11, 7, 3.2, 3.0, skin);
  b.rect(8, 4, 6, 2, hair[1]);
  if (neat <= 2) {
    b.px(11, 2, hair[2]);
    b.px(12, 3, hair[2]);
  }
  b.px(10, 7, _h('#20140A'));
  b.px(12, 7, _h('#20140A'));
  if (neat <= 1) {
    b.rect(10, 8, 3, 1, _h('#FFFFFF'));
  } else {
    b.rect(10, 8, 2, 1, _h('#7A2A1A'));
  }
});

/// Celebration star for 3-of-3 ending: 9 x 9.
Sprite mkEstrellaCuarto() => _mk(9, 9, (b) {
  final y = _h('#FFE040');
  final hi = _h('#FFF8C0');
  b.rect(4, 1, 1, 7, y);
  b.rect(1, 4, 7, 1, y);
  b.rect(3, 3, 3, 3, y);
  b.px(4, 4, hi);
  b.px(2, 2, y);
  b.px(6, 2, y);
  b.px(2, 6, y);
  b.px(6, 6, y);
});

/// Celebration heart for 3-of-3 ending: 11 x 10.
Sprite mkCorazonCuarto() => _mk(11, 10, (b) {
  const rows = [
    '..##...##..',
    '.####.####.',
    '###########',
    '###########',
    '###########',
    '.#########.',
    '..#######..',
    '...#####...',
    '....###....',
    '.....#.....',
  ];
  final r1 = _h('#D03048');
  final r2 = _h('#FF6880');
  for (var y = 0; y < rows.length; y++) {
    for (var x = 0; x < rows[y].length; x++) {
      if (rows[y][x] == '#') {
        b.px(x, y, (y <= 2 && x <= 4) ? r2 : r1);
      }
    }
  }
});

/// Directional cue arrow for `gesto` `senala` when pointing at a target: 9 x 7.
Sprite mkGestoFlechaCuarto({bool up = false, bool self = false}) {
  final b = Buf(9, 7);
  final fill = self ? _h('#9CCBF5') : _h('#FFE040');
  if (self) {
    b.rect(3, 0, 3, 2, OUT);
    b.rect(3, 5, 3, 2, OUT);
    b.rect(2, 1, 5, 5, OUT);
    b.rect(3, 1, 3, 5, fill);
    b.rect(2, 2, 5, 3, fill);
  } else if (up) {
    const mask = [
      '....#....',
      '...###...',
      '..#####..',
      '.#######.',
      '...###...',
      '...###...',
      '.........',
    ];
    for (var y = 0; y < mask.length; y++) {
      for (var x = 0; x < mask[y].length; x++) {
        if (mask[y][x] == '#') b.px(x, y, fill);
      }
    }
  } else {
    const mask = [
      '.........',
      '...###...',
      '...###...',
      '.#######.',
      '..#####..',
      '...###...',
      '....#....',
    ];
    for (var y = 0; y < mask.length; y++) {
      for (var x = 0; x < mask[y].length; x++) {
        if (mask[y][x] == '#') b.px(x, y, fill);
      }
    }
  }
  return b.done();
}

/// All El cuarto sprites with names for the content lane's sprite sheet (`tool/make_cuarto_sprites_test.dart`).
List<(String, Sprite)> cuartoSpritesSheet() {
  const dummyHang = (
    rows: 40,
    bed: 0,
    foot: 100,
    lyingFrom: 24,
    sittingFrom: 30,
    width: 34,
    z: 0.5,
  );
  const blueBed = [110, 150, 220];
  const pinkBed = [236, 150, 170];
  return [
    (
      'luis_cama_lie',
      mkInBed(
        FAM['hermano']!.copyWith(dormido: true),
        blueBed,
        dummyHang,
        blanketFrom: 24,
      ),
    ),
    (
      'luis_cama_sit',
      mkInBed(FAM['hermano']!, blueBed, dummyHang, blanketFrom: 30),
    ),
    (
      'luis_cama_palpa',
      mkInBed(
        FAM['hermano']!.copyWith(dormido: true),
        blueBed,
        dummyHang,
        blanketFrom: 30,
        pose: 'ojos',
      ),
    ),
    (
      'carmen_cama_lie',
      mkInBed(
        FAM['hermana']!.copyWith(dormido: true),
        pinkBed,
        dummyHang,
        blanketFrom: 24,
      ),
    ),
    (
      'carmen_cama_sit',
      mkInBed(FAM['hermana']!, pinkBed, dummyHang, blanketFrom: 30),
    ),
    ('luis_pie', mkPersona(FAM['hermano']!, 'idle', false, false)),
    ('carmen_pie', mkCarmenCuarto()),
    ('carmen_pies_gesto', mkCarmenCuarto(pies: true)),
    ('luis_pijama', mkLuisVestir()),
    ('luis_pantalon_zapatos', mkLuisVestir(trousers: true, shoes: true)),
    ('luis_pantalon_calcetines', mkLuisVestir(trousers: true)),
    ('luis_camisa', mkLuisVestir(trousers: true, shirt: true)),
    (
      'luis_vestido_todo',
      mkLuisVestir(
        trousers: true,
        shoes: true,
        shirt: true,
        hat: true,
        watch: true,
      ),
    ),
    (
      'luis_tuft_2',
      mkLuisVestir(
        trousers: true,
        shoes: true,
        shirt: true,
        hat: true,
        watch: true,
        neat: 2,
      ),
    ),
    (
      'luis_shirt_tail_1',
      mkLuisVestir(
        trousers: true,
        shoes: true,
        shirt: true,
        hat: true,
        watch: true,
        neat: 1,
      ),
    ),
    ('luis_tumbled', mkLuisVestir(trousers: true, shoes: true, tumbled: true)),
    ('abuelo_butaca_sleep', mkAbueloArmchair(dormido: true)),
    ('abuelo_butaca_awake', mkAbueloArmchair(dormido: false)),
    ('abuelo_pie', mkPersona(FAM['abuelo']!, 'idle', false, false)),
    ('abuela_puerta', mkAbuelaCuarto()),
    ('abuela_silencio', mkAbuelaCuarto(silencio: true)),
    ('abuela_foto', mkAbuelaCuarto(foto: true)),
    ('abuela_foto_up', mkAbuelaCuarto(fotoUp: true)),
    ('perro_sit', mkPerroCuarto('sit')),
    ('perro_lick', mkPerroCuarto('lick')),
    ('nariz', mkNariz()),
    ('coqui_duerme', mkCoquiDuerme()),
    ('almohada', mkAlmohada()),
    ('plato_3', mkPlatoCuarto(3)),
    ('plato_2', mkPlatoCuarto(2)),
    ('plato_1', mkPlatoCuarto(1)),
    ('plato_0', mkPlatoCuarto(0)),
    ('campana', mkCampana()),
    ('manta_abuelo', mkMantaAbuelo()),
    ('bebe_sleep', mkBebeCuarto('sleep')),
    ('bebe_stir', mkBebeCuarto('stir')),
    ('bebe_awake', mkBebeCuarto('awake')),
    ('zetas_3', mkZetas(3)),
    ('zetas_2', mkZetas(2)),
    ('zetas_1', mkZetas(1)),
    ('ropa_pantalon', mkRopaCuarto('pantalon')),
    ('ropa_camisa', mkRopaCuarto('camisa')),
    ('ropa_zapatos', mkRopaCuarto('zapatos')),
    ('ropa_sombrero', mkRopaCuarto('sombrero')),
    ('ropa_reloj', mkRopaCuarto('reloj')),
    ('reloj_7_00', mkManecillas(7.0)),
    ('reloj_7_30', mkManecillas(7.5)),
    ('tinkle_fx', mkTinkleFx(0)),
    ('grito_fx', mkGritoFx(0)),
    ('flash_fx', mkFlashCuarto()),
    ('foto_card_3', mkFotoCard(3)),
    ('foto_card_2', mkFotoCard(2)),
    ('foto_card_1', mkFotoCard(1)),
    ('estrella', mkEstrellaCuarto()),
    ('corazon', mkCorazonCuarto()),
  ];
}
