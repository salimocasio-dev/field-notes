// What only La parada has, drawn in the old sprites' way (engine.js Buf, its ramps and its dark outline; kit.js
// mkPersona), from the Needs list of historia/notas/guiones/parada.md: the chofer (his cap, at his window, leaning out,
// whistling, thumb up), the strip of tickets (4 to 0) and one ticket torn off, the basket of rolls on the sill (3 to 0,
// steaming, with its cloth), two small tied boxes and one, the ball, Carmen's basket, a head at the guagua's glass, Canelo
// with a roll, the strangers who wait and ride (a child, a passenger), the frog's own signs (tongue out, a yawn, a droop).
// The looks follow parada-preview.html's stand-ins where they give one (CHOFER, NINO3, `boletos`, `cajas`, `cesta`,
// `panes`, `pelota`, the head at the glass: mkAbuela's top 22 rows, the face's middle on row 12); what no script and no
// stand-in gives is this file's guess (said at each). The content lane looks at each one on
// docs/proyecto/pixel/port/parada-sprites.png (tool/make_parada_sprites_test.dart).
// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'dart:typed_data';

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/src/calle/calle_cast.dart';
import 'package:coqui_scenes/src/colmado/colmado_cast.dart';
import 'package:coqui_scenes/src/mostrador/mostrador_sprites.dart'
    show bancoWho;

int _h(String s) => hexColour(s);

/* ---------- the people only this scene has ---------- */

/// The chofer (parada-preview.html's CHOFER): a blue uniform, black hair, a moustache; his cap is drawn over by [mkChofer].
final Who CHOFER = Who(
  piel: PIEL['b']!,
  pelo: PELO['negro']!,
  peinado: 'corto',
  ropa: RP.blue,
  abajo: RP.grey,
  bigote: true,
);

/// A third child (parada-preview.html's NINO3: not one of the family), who waits at the kerb in story 52.
final Who NINO3 = Who(
  nino: true,
  piel: PIEL['c']!,
  pelo: PELO['castano']!,
  peinado: 'corto',
  ropa: RP.yel,
  abajo: RP.grey,
  zapato: _h('#F2F2F8'),
);

/// A passenger who gets off the guagua in story 52's game (the script's "people inside"; no stand-in gives one: this
/// file's guess, a woman in purple with long hair).
final Who PASAJERA = Who(
  piel: PIEL['a']!,
  pelo: PELO['negro']!,
  peinado: 'largo',
  ropa: RP.purp,
  falda: true,
  zapato: _h('#3A2A1C'),
);

/// The other passenger who gets off (this file's guess: a man in a teal shirt).
final Who PASAJERO = Who(
  piel: PIEL['c']!,
  pelo: PELO['castano']!,
  peinado: 'corto',
  ropa: RP.teal,
  abajo: RP.wood,
);

/// The chofer's poses: `idle` at his window, `silba` whistling (a whistle at his mouth), `pulgar` a thumb up.
const List<String> CHOFER_POSES = ['idle', 'silba', 'pulgar'];

/// The chofer leaning out of his window (parada-preview.html `chofer`): mkPersona's top 32 rows with a blue cap drawn
/// over his head; the middle of his face is (PX, 11), the sheet's spot `chofer` (sprite box [-12, -9, 11, 20]). [pose]:
/// [CHOFER_POSES]; `pulgar` lifts a hand (mkPersona `wave0`) with the thumb up (this file's guess at a thumb).
Sprite mkChofer(String pose, {bool open = false}) {
  final base = mkPersona(
    CHOFER,
    pose == 'pulgar' ? 'wave0' : 'idle',
    open,
    false,
  );
  const rows = 32;
  final px = Uint32List(base.w * rows);
  for (var i = 0; i < px.length; i++) {
    px[i] = base.px[i];
  }
  final s = Sprite(base.w, rows, px);
  final g = Ctx(s.px, s.w, s.h);
  const X = PX;
  g.fillStyle = _h('#1E3A5C');
  g.fillRect(X - 7, 2, 14, 4);
  g.fillRect(X - 8, 6, 16, 1);
  g.fillStyle = _h('#2A1810');
  g.fillRect(X - 8, 7, 16, 1);
  if (pose == 'silba') {
    // a small silver whistle at the mouth's right
    g.fillStyle = _h('#C8CCD4');
    g.fillRect(X + 2, 14, 4, 2);
    g.fillStyle = _h('#3A3A44');
    g.fillRect(X + 6, 14, 1, 2);
  }
  if (pose == 'pulgar') {
    // the thumb, up over the lifted hand
    g.fillStyle = OUT;
    g.fillRect(X + 13, 4, 3, 5);
    g.fillStyle = PIEL['b']![3];
    g.fillRect(X + 14, 5, 1, 3);
  }
  return s;
}

/// A person who has no figure in La calle's cast (callePerson): the chofer standing, the strangers of story 52
/// (`nino3`, `pasajera`, `pasajero`). Null for anybody else.
Who? paradaWho(String id) => switch (id) {
  'chofer' => CHOFER,
  'nino3' => NINO3,
  'pasajera' => PASAJERA,
  'pasajero' => PASAJERO,
  _ => null,
};

/// [id] sitting on the seat (rules.anchor: mkPersona sitting, column PX, its bottom edge on the seat's top; abuela
/// KIT.mkAbuelaS, column 17). The señora and the señor sit as El banco's figures (their extras are for standing).
Anchored paradaSitting(String id, {bool open = false}) {
  if (id == 'abuela') {
    final s = mkAbuelaS('idle', open, false);
    return (s: s, ax: 17, ay: inkBottom(s));
  }
  final who = id == 'senora' || id == 'senor'
      ? bancoWho(id)
      : (paradaWho(id) ?? calleWho(id));
  final s = mkPersona(who, 'idle', open, true);
  return (s: s, ax: PX, ay: inkBottom(s));
}

/// A head at the guagua's glass (the sheet's ventana1, ventana2: "the middle of the face on the point (abuela mkAbuela
/// row 12 of the canvas, column 30; persona row 11, column 24)"): the person's top rows, the point of the face. The frog
/// (no anchor given in the sheet: this file's guess) is mkCoqui's top 18 rows, the face's middle at (16, 9).
({Sprite s, int ax, int ay}) mkCabeza(String id, {bool open = false}) {
  Sprite crop(Sprite s, int rows) {
    final px = Uint32List(s.w * rows);
    for (var i = 0; i < px.length && i < s.px.length; i++) {
      px[i] = s.px[i];
    }
    return Sprite(s.w, rows, px);
  }

  if (id == 'abuela') {
    return (s: crop(mkAbuela('idle', open), 22), ax: 30, ay: 12);
  }
  if (id == 'coqui') {
    return (s: crop(mkCoqui(1, 0, open), 18), ax: 16, ay: 9);
  }
  final who = id == 'senora' || id == 'senor'
      ? bancoWho(id)
      : (paradaWho(id) ?? calleWho(id));
  return (s: crop(mkPersona(who, 'idle', open, false), 22), ax: PX, ay: 11);
}

/* ---------- the small things ---------- */

Sprite _mk(int w, int h, void Function(Buf b) fn) {
  final b = Buf(w, h);
  fn(b);
  return b.outline().done();
}

/// The strip of [n] guagua tickets (parada-preview.html `boletos`: pale yellow, a tear mark between each), 4 to 1; its
/// width grows with [n] (3 columns a ticket, this file's way of showing how many).
Sprite mkBoletos(int n) {
  final w = 2 + 3 * n;
  return _mk(w + 2, 9, (b) {
    b.rect(1, 1, w, 7, _h('#F6E7A0'));
    b.rect(1, 1, w, 1, _h('#FFF6C8'));
    for (var i = 1; i < n; i++) {
      for (var y = 2; y < 8; y += 2) {
        b.px(1 + i * 3, y, _h('#B8A050'));
      }
    }
    b.rect(2, 4, w - 2, 1, _h('#C8B060'));
  });
}

/// One ticket torn off (the strip's ticket alone), 6 x 9.
Sprite mkBoleto() => _mk(6, 9, (b) {
  b.rect(1, 1, 4, 7, _h('#F6E7A0'));
  b.rect(1, 1, 4, 1, _h('#FFF6C8'));
  b.rect(2, 4, 2, 1, _h('#C8B060'));
});

/// The basket of [n] warm rolls (parada-preview.html `panes`: a wicker rim and the rolls, seen from the front, a thread
/// of steam), 12 x 10; [tapado] its cloth over it (a white cloth with a red check: this file's guess); [vapor] the steam.
Sprite mkPanes(int n, {bool tapado = false, bool vapor = true}) =>
    _mk(12, 10, (b) {
      b.rect(1, 6, 10, 3, _h('#C8853C'));
      for (var x = 1; x < 11; x += 2) {
        b.px(x + 1 - (x >> 1) % 2, 7, _h('#A8682C'));
      }
      b.rect(0, 5, 12, 1, _h('#E2A85A'));
      if (tapado) {
        b.rect(1, 2, 10, 4, _h('#F4F0E8'));
        for (var x = 2; x < 11; x += 3) {
          b.rect(x, 2, 1, 4, _h('#D84040'));
        }
        return;
      }
      for (final x in [3, 6, 9].take(n)) {
        b.ell(x, 3.6, 1.9, 1.6, [_h('#A8682C'), _h('#C48440'), _h('#E2A85A')]);
      }
      if (vapor && n > 0) {
        b.px(5, 0, _h('#FFFFFF'));
        b.px(7, 1, _h('#FFFFFF'));
      }
    });

/// One roll (in Canelo's mouth, in a hand), 5 x 4.
Sprite mkPan() => _mk(5, 4, (b) {
  b.ell(2, 2, 1.9, 1.4, [_h('#A8682C'), _h('#C48440'), _h('#E2A85A')]);
});

/// Two small boxes tied with string (parada-preview.html `cajas`), 21 x 10; [n] 1: one of them (11 x 10).
Sprite mkCajas(int n) => _mk(n >= 2 ? 21 : 11, 10, (b) {
  for (final x0 in n >= 2 ? const [1, 11] : const [1]) {
    b.rect(x0, 2, 9, 7, _h('#B8804A'));
    b.rect(x0, 2, 9, 1, _h('#D8A46A'));
    b.rect(x0 + 4, 2, 1, 7, _h('#F4ECD8'));
    b.rect(x0, 5, 9, 1, _h('#F4ECD8'));
  }
});

/// Luis and Carmen's ball (parada-preview.html `pelota`), 11 x 11.
Sprite mkPelota() => _mk(11, 11, (b) {
  b.ell(5, 5, 4, 4, RP.red);
  b.rect(3, 3, 2, 1, _h('#FFFFFF'));
  b.rect(2, 6, 7, 1, RP.yel[3]);
});

/// Carmen's basket (parada-preview.html `cesta`), 20 x 12.
Sprite mkCestaCarmen() => _mk(20, 12, (b) {
  b.rect(1, 3, 18, 8, _h('#C8853C'));
  for (var y = 3; y < 11; y += 2) {
    for (var x = 1; x < 19; x += 2) {
      b.px(x + (y >> 1) % 2, y, _h('#A8682C'));
    }
  }
  b.rect(0, 2, 20, 2, _h('#E2A85A'));
});

/// Canelo (kit.js mkPerro) in [pose] with a roll in his mouth (the head's front, mkPerro's hx + 4: this file's guess).
Sprite mkPerroPan(String pose, bool f) {
  final p = mkPerro(pose, f);
  final lie = pose == 'lie', hy = lie ? 15 : 8;
  return overSprite(p, [(mkPan(), 25, hy)]);
}

/// The frog's signs over his head (this file's guesses): `lengua` a pink tongue out (tired), `bosteza` a yawn (an open
/// round mouth and a "z"), `gota` a drop of sweat (drooping in the sun), 9 x 9.
Sprite mkSignoCoqui(String que) => _mk(9, 9, (b) {
  switch (que) {
    case 'lengua':
      b.rect(3, 2, 3, 5, _h('#F07890'));
      b.rect(4, 3, 1, 3, _h('#FFA0B4'));
    case 'bosteza':
      b.ell(3.5, 4.5, 2.6, 2.6, [_h('#5A1C24'), _h('#7A2A34')]);
      b.rect(6, 0, 3, 1, _h('#FFFFFF'));
      b.px(7, 1, _h('#FFFFFF'));
      b.rect(6, 2, 3, 1, _h('#FFFFFF'));
    default:
      b.ell(4, 5, 2, 2.6, [_h('#60A8E8'), _h('#90C8F4'), _h('#D0ECFF')]);
      b.px(4, 1, _h('#90C8F4'));
  }
});

/// The sun on the card (parada.md 53: "the sun, low and yellow, on the card"): [paso] 0 low and yellow, 1 going down
/// (orange), 2 evening (red over a dark band), 13 x 13 (this file's guess at the three).
Sprite mkSolCarta(int paso) => _mk(13, 13, (b) {
  final c = switch (paso) {
    0 => [_h('#E8B020'), _h('#F8D040'), _h('#FFE878'), _h('#FFF6C0')],
    1 => [_h('#E07020'), _h('#F09030'), _h('#F8B058'), _h('#FFD8A0')],
    _ => [_h('#B83020'), _h('#D84830'), _h('#F07050'), _h('#FFA888')],
  };
  final y = 3.0 + paso * 2.5;
  b.ell(6, y + 2, 4, 4, c);
  if (paso == 2) b.rect(0, 10, 13, 3, _h('#46385E'));
});

/// Every sprite this file draws, in order, for the sheet picture (parada-sprites.png).
List<(String, Sprite)> paradaSpriteSheet() => [
  for (final p in CHOFER_POSES) ('chofer $p', mkChofer(p)),
  ('chofer, talking', mkChofer('idle', open: true)),
  ('chofer standing', mkPersona(CHOFER, 'idle', false, false)),
  ('nino3', mkPersona(NINO3, 'idle', false, false)),
  ('pasajera', mkPersona(PASAJERA, 'idle', false, false)),
  ('pasajero', mkPersona(PASAJERO, 'idle', false, false)),
  for (final id in const ['abuela', 'senora', 'senor'])
    ('$id sitting', paradaSitting(id).s),
  for (final id in const ['abuela', 'luis', 'coqui', 'senora', 'carmen'])
    ('$id at the glass', mkCabeza(id).s),
  for (var n = 4; n >= 1; n--) ('$n boletos', mkBoletos(n)),
  ('boleto', mkBoleto()),
  for (var n = 3; n >= 0; n--) ('$n panes', mkPanes(n)),
  ('panes, the cloth over them', mkPanes(3, tapado: true)),
  ('pan', mkPan()),
  ('2 cajas', mkCajas(2)),
  ('1 caja', mkCajas(1)),
  ('pelota', mkPelota()),
  ('cesta', mkCestaCarmen()),
  ('Canelo with a roll, running', mkPerroPan('run', false)),
  ('Canelo with a roll, lying', mkPerroPan('lie', false)),
  ('Canelo eating', mkPerro('eat', true)),
  for (final s in const ['lengua', 'bosteza', 'gota'])
    ('Coqui: $s', mkSignoCoqui(s)),
  for (var p = 0; p < 3; p++) ('sol $p', mkSolCarta(p)),
];
