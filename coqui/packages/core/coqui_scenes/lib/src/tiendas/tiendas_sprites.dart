// What only Las tiendas has, drawn in the old sprites' way (engine.js Buf, its ramps and its dark outline; kit.js mkBebe,
// mkPersona), from the Needs list of historia/notas/guiones/tiendas.md: the stroller with the bebé (empty-handed, pointing,
// clapping; with a lollipop, a pencil, a top), abuela's coins in her hand (3 to 1), the shopkeeper's hand at a door, the
// letter, a fat purse, a small bag, a box of plasters, an envelope, a parcel, abuela's telephone, the lunch tins (3, 2, 1)
// with their wisps of steam (3 to 1), the open tin of rice, Luis's paper with a red cross and a bell, mamá in a nurse's
// coat, papá with a book, the two door signs, a head at a window and a hand that waves, the painter with his brush, the
// cloud, the kite, the stamp, the bread in its open bag (and in the big bag), a big bag, an umbrella shut and open. The
// stroller is the preview's stand-in (tiendas-preview.html mkCochecito: its size is the sheet's); every other look is this
// file's guess where the script gives none: the content lane looks at each one on
// docs/proyecto/pixel/port/tiendas-sprites.png (tool/tiendas_sprites_test.dart).
// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/src/calle/calle_cast.dart';
import 'package:coqui_scenes/src/colmado/colmado_cast.dart';
import 'package:coqui_scenes/src/mostrador/mostrador_sprites.dart'
    show mkCliente;

int _h(String s) => hexColour(s);
List<int> _hs(List<String> s) => [for (final x in s) hexColour(x)];

Sprite _mk(int w, int h, void Function(Buf b) fn) {
  final b = Buf(w, h);
  fn(b);
  return b.outline().done();
}

/* ---------- the stroller with the bebé ---------- */

/// What the bebé can hold in his fist (tiendas.md 54: in a wrong place he takes it from the counter).
const List<String> TOMA = ['lollipop', 'pencil', 'top'];

/// A thing in the bebé's fist: a lollipop (a red disc on a stick), a pencil (yellow, a pink end), a top (a striped cone).
Sprite mkToma(String k) => switch (k) {
  'lollipop' => _mk(7, 11, (b) {
    b.rect(3, 5, 1, 6, _h('#F4F4F4'));
    b.ell(3, 3, 3, 3, _hs(['#B82030', '#E83A4A', '#FF7A8A']));
    b.px(2, 2, _h('#FFFFFF'));
  }),
  'pencil' => _mk(4, 12, (b) {
    b.rect(1, 2, 2, 9, _h('#F0C020'));
    b.rect(1, 2, 1, 9, _h('#F8D850'));
    b.rect(1, 0, 2, 2, _h('#F08AA8'));
    b.px(1, 11, _h('#3A2A1A'));
  }),
  _ => _mk(9, 9, (b) {
    for (var y = 0; y < 6; y++) {
      final w = 8 - y;
      b.rect(
        4 - w / 2,
        y + 1,
        w,
        1,
        y % 2 == 0 ? _h('#3C8AE0') : _h('#E03C30'),
      );
    }
    b.rect(4, 0, 1, 2, _h('#6A4A2A'));
    b.px(4, 7, _h('#6A4A2A'));
  }),
};

/// The stroller with the bebé, 24 x 36 (tiendas-preview.html mkCochecito: a dome of a hood behind his head, the bebé,
/// then the basket, two wheels and the handle on the right, where abuela pushes): its wheels' bottom on its spot, its
/// middle column 12 on the spot's column. [est]: the bebé `idle`, `clap` (claps), `senala` (points: an arm out to the
/// left); [toma]: what he holds in his fist (one of [TOMA]); [vacio]: the stroller with nobody in it (he is riding the
/// horse). [f]: the frame of a clap.
Sprite mkCochecito({
  String est = 'idle',
  String? toma,
  bool vacio = false,
  bool f = false,
}) {
  final hood = _mk(24, 36, (b) {
    b.ell(12, 12, 10.5, 10, _hs(['#1E4688', '#2E5AA8', '#4A7AD0']));
  });
  final front = _mk(24, 36, (b) {
    b.ell(12, 25.5, 11, 6, _hs(['#1E4688', '#2E5AA8', '#4A7AD0', '#8FB4F0']));
    b.rect(2, 22, 20, 1, _h('#B8D0F8'));
    for (final cx in const [5.5, 18.5]) {
      b.ell(cx, 32, 3.6, 3.6, _hs(['#20202A', '#44444E']));
      b.px(cx, 32, _h('#B8B8C4'));
    }
    b.line(22, 21, 22, 10, _h('#C8C8D4'));
    b.rect(20, 8, 3, 2, _h('#E4E4EC'));
  });
  final parts = <(Sprite, int, int)>[(hood, 0, 0)];
  if (!vacio) {
    parts.add((mkBebe(est == 'senala' ? 'idle' : est, f), -1, 4));
    if (est == 'senala') {
      // his arm out to the left, a finger pointing
      parts.add((
        _mk(9, 5, (b) {
          b.cap(8, 3, 2, 2, 1.4, _hs(['#E8B020', '#F8C838']));
          b.ell(1.5, 2, 1.6, 1.6, PIEL['a']!);
        }),
        -6,
        16,
      ));
    }
  }
  parts.add((front, 0, 0));
  if (!vacio && toma != null) {
    final t = mkToma(toma);
    // in his right fist (kit.js mkBebe idle: the hand at (21.5, 22.5) of the bebé at (-1, 4)), held up over the basket
    parts.add((t, 21 - t.w ~/ 2, 26 - t.h));
  }
  final top = parts.fold<int>(0, (a, p) => math.min(a, p.$3));
  final left = parts.fold<int>(0, (a, p) => math.min(a, p.$2));
  final w = parts.fold<int>(0, (a, p) => math.max(a, p.$2 + p.$1.w)) - left;
  final base = Sprite(w, 36 - top, Uint32List(w * (36 - top)));
  return overSprite(base, [
    for (final p in parts) (p.$1, p.$2 - left, p.$3 - top),
  ]);
}

/// The column of [mkCochecito]'s sprite that is its middle (the stroller's column 12; the sprite grows to the left when
/// the bebé points).
int cochecitoX(String est) => est == 'senala' ? 12 + 6 : 12;

/* ---------- small things held in a hand ---------- */

/// [n] gold coins in an open hand (abuela's: 1 to 3), 11 x 7, held at their bottom middle.
Sprite mkMonedasMano(int n) => _mk(11, 7, (b) {
  b.ell(5.5, 4.5, 5, 2.2, PIEL['a']!);
  for (var i = 0; i < n; i++) {
    b.ell(2.5 + i * 3, 2.5, 2, 2, _hs(['#C49628', '#FAD250', '#FFF0A0']));
  }
});

/// One coin (abuela's, going into a hand or the horse's coin box), 4 x 4.
Sprite mkMoneda54() =>
    _mk(4, 4, (b) => b.ell(2, 2, 1.8, 1.8, _hs(['#C49628', '#FAD250'])));

/// The shopkeeper's hand at a door: a sleeve and a hand held out, palm up (tiendas.md 54: "a hand and a sleeve; no
/// face"), 14 x 7, coming out of the doorway to the right; held at its left end.
Sprite mkManoTendero() => _mk(14, 7, (b) {
  b.rect(0, 1, 8, 5, _h('#5A7AB0'));
  b.rect(0, 1, 8, 1, _h('#7A9AD0'));
  b.rect(8, 2, 2, 4, _h('#E8E4DA'));
  b.ell(11.5, 4, 2.6, 2.2, PIEL['b']!);
});

/// Abuela's letter: a white envelope with a red stamp, 9 x 6.
Sprite mkCarta() => _mk(9, 6, (b) {
  b.rect(0, 0, 9, 6, _h('#FAFAF4'));
  b.line(0, 0, 4, 3, _h('#9AA0B0'));
  b.line(8, 0, 4, 3, _h('#9AA0B0'));
  b.rect(6, 1, 2, 2, _h('#E03C30'));
});

/// Abuela's purse: fat ([gordo]) after the banco, or flat, 9 x 7.
Sprite mkMonedero([bool gordo = true]) => _mk(9, gordo ? 8 : 6, (b) {
  final h = gordo ? 6.0 : 4.0;
  b.ell(
    4.5,
    (gordo ? 8 : 6) - h / 2 - 1,
    4.4,
    h / 2,
    _hs(['#6A2A5A', '#8A3A78', '#B05A9A']),
  );
  b.rect(3, 0, 3, 1, _h('#F0C020'));
  if (gordo) b.px(6, 3, _h('#F0D060'));
});

/// A small paper bag from the farmacia (a green cross on it), 7 x 9.
Sprite mkBolsita() => _mk(7, 9, (b) {
  b.rect(0, 1, 7, 8, _h('#E8D0A0'));
  b.rect(0, 1, 7, 1, _h('#C8A870'));
  b.rect(3, 3, 1, 4, _h('#28A050'));
  b.rect(2, 4, 3, 2, _h('#28A050'));
});

/// A box of plasters (white, a red band and a cross), 9 x 6.
Sprite mkCuritas() => _mk(9, 6, (b) {
  b.rect(0, 0, 9, 6, _h('#BFDDF4'));
  b.rect(0, 2, 9, 2, _h('#E05050'));
  b.rect(4, 1, 1, 4, _h('#FFFFFF'));
  b.rect(3, 2, 3, 2, _h('#FFFFFF'));
});

/// An envelope from the banco (brown, a gold seal), 9 x 6.
Sprite mkSobre() => _mk(9, 6, (b) {
  b.rect(0, 0, 9, 6, _h('#D8B070'));
  b.line(0, 0, 4, 3, _h('#A88040'));
  b.line(8, 0, 4, 3, _h('#A88040'));
  b.px(4, 3, _h('#F0C020'));
});

/// A parcel from the correo (brown paper, a string cross), 10 x 8.
Sprite mkPaquete() => _mk(10, 8, (b) {
  b.rect(0, 0, 10, 8, _h('#C08A50'));
  b.rect(0, 0, 10, 1, _h('#D8A468'));
  b.rect(4, 0, 1, 8, _h('#F4EAD0'));
  b.rect(0, 4, 10, 1, _h('#F4EAD0'));
});

/// The stamp abuela buys at the correo, 5 x 5.
Sprite mkSello() => _mk(5, 5, (b) {
  b.rect(0, 0, 5, 5, _h('#FAFAF4'));
  b.rect(1, 1, 3, 3, _h('#3C8AE0'));
});

/// Abuela's telephone (a small dark one with a lit screen), 5 x 8.
Sprite mkTelefono() => _mk(5, 8, (b) {
  b.rect(0, 0, 5, 8, _h('#2A2A34'));
  b.rect(1, 1, 3, 5, _h('#8AD0F0'));
});

/// What a thing that comes out of a door is, by its word (va54 `trae`, puerta56 `trae`): its sprite.
Sprite? mkTrae(String? k) => switch (k) {
  'letter' => mkCarta(),
  'purse' => mkMonedero(),
  'bag' => mkBolsita(),
  'plasters' => mkCuritas(),
  'envelope' => mkSobre(),
  'parcel' => mkPaquete(),
  'stamp' => mkSello(),
  'bigbag' => mkBolsaGrande(),
  'umbrella' => mkSombrillaCerrada(),
  'umbrellaOpen' => mkSombrillaAbierta(),
  'paperBack' => mkPapel(true),
  'tinOpen3' => mkFiambreraAbierta(3),
  'tinOpen2' => mkFiambreraAbierta(2),
  'tinOpen1' => mkFiambreraAbierta(0),
  'bread' => mkPan(),
  'breadbag' => mkPan(true),
  'telefono' => mkTelefono(),
  'kite' => mkCometa(),
  'paper' => mkPapel(),
  'book' => mkLibro(),
  'tin' => mkFiambreras(1, 0),
  'cruz' => mkLetrero('cruz'),
  'campana' => mkLetrero('campana'),
  'coins3' => mkMonedasMano(3),
  'coins2' => mkMonedasMano(2),
  'coins1' => mkMonedasMano(1),
  _ => null,
};

/// The big bag the frog brings out (story 56: "a big bag"), 12 x 14.
Sprite mkBolsaGrande() => _mk(12, 14, (b) {
  b.rect(0, 3, 12, 11, _h('#D8B880'));
  b.rect(0, 3, 12, 1, _h('#B89860'));
  b.rect(0, 3, 2, 11, _h('#E8CC98'));
  b.rect(3, 0, 1, 4, _h('#8A6A3A'));
  b.rect(8, 0, 1, 4, _h('#8A6A3A'));
  b.rect(3, 0, 6, 1, _h('#8A6A3A'));
});

/// Abuela's bread in its open paper bag (tiendas-preview.html mkPan), 10 x 12; [enBolsa]: put into the big bag.
Sprite mkPan([bool enBolsa = false]) => enBolsa
    ? _mk(12, 16, (b) {
        b.rect(3, 0, 2, 4, _h('#E2A85A'));
        b.rect(6, 1, 2, 3, _h('#D09040'));
        b.rect(0, 4, 12, 12, _h('#D8B880'));
        b.rect(0, 4, 12, 1, _h('#B89860'));
        b.rect(0, 4, 2, 12, _h('#E8CC98'));
      })
    : _mk(10, 12, (b) {
        b.rect(1, 4, 8, 8, _h('#C89A60'));
        b.rect(1, 4, 3, 8, _h('#E0B880'));
        b.rect(1, 3, 8, 1, _h('#A87A40'));
        b.rect(2, 0, 2, 4, _h('#E2A85A'));
        b.rect(5, 1, 2, 3, _h('#D09040'));
        b.rect(3, 7, 4, 1, _h('#A87A40'));
      });

/// The umbrella shut (a furled red stick), 5 x 22, held at its middle.
Sprite mkSombrillaCerrada() => _mk(5, 22, (b) {
  b.rect(2, 0, 1, 3, _h('#4A3420'));
  b.ell(2.5, 10, 2, 7, _hs(['#8E2038', '#C0304E', '#E85C7C']));
  b.rect(2, 17, 1, 4, _h('#4A3420'));
  b.px(1, 21, _h('#4A3420'));
});

/// The umbrella open (tiendas-preview.html mkSombrilla: a dome with a scalloped edge and ribs, a stick down to the
/// hand, a hook), 40 x 50; its stick's foot is held.
Sprite mkSombrillaAbierta() => _mk(40, 50, (b) {
  final C = _hs(['#8E2038', '#C0304E', '#E85C7C', '#FF9AB0']);
  for (var y = 0; y <= 13; y++) {
    for (var x = 0; x < 40; x++) {
      final nx = (x + .5 - 20) / 19,
          ny = (y + .5 - 13) / 12,
          d = nx * nx + ny * ny;
      if (d > 1) continue;
      if (y >= 12 && ((x >> 2) % 2) == 1) continue;
      b.px(
        x,
        y,
        C[math.max(
          0,
          math.min(3, ((-nx * .4 - ny * .5 + .5) * 3 + .5).floor()),
        )],
      );
    }
  }
  for (final x in const [3, 10, 20, 30, 37]) {
    b.line(20, 1, x, 12, C[0]);
  }
  b.rect(20, 14, 1, 31, _h('#4A3420'));
  b.px(20, 0, _h('#4A3420'));
  b.line(20, 45, 18, 48, _h('#4A3420'));
  b.px(17, 48, _h('#4A3420'));
});

/// The señora's kite: a red and yellow diamond on a string with a tail of bows, 15 x 22, held at the string's end.
Sprite mkCometa() => _mk(15, 22, (b) {
  for (var y = 0; y < 13; y++) {
    final w = y < 5 ? y * 1.4 : (13 - y) * .9;
    b.rect(7 - w, y, w, 1, _h('#E03C30'));
    b.rect(7, y, w, 1, _h('#F0C020'));
  }
  b.line(7, 0, 7, 12, _h('#6A4A2A'));
  b.line(1, 5, 13, 5, _h('#6A4A2A'));
  b.line(7, 12, 9, 21, _h('#F4F4F4'));
  b.rect(7, 15, 3, 1, _h('#3C8AE0'));
  b.rect(8, 18, 3, 1, _h('#3C8AE0'));
});

/// Luis's paper with two small drawings, a red cross and a bell, 11 x 8; [vuelta]: turned round (the back, blank).
Sprite mkPapel([bool vuelta = false]) => _mk(11, 8, (b) {
  b.rect(0, 0, 11, 8, _h('#FAFAF0'));
  if (vuelta) return;
  b.rect(2, 3, 3, 1, _h('#E03030'));
  b.rect(3, 2, 1, 3, _h('#E03030'));
  b.ell(8, 3.5, 1.6, 2, _hs(['#C89A20', '#F0C020']));
  b.px(8, 6, _h('#C89A20'));
});

/// Papá's book (a blue cover), 8 x 9.
Sprite mkLibro() => _mk(8, 9, (b) {
  b.rect(0, 0, 8, 9, _h('#2E5AA8'));
  b.rect(0, 0, 1, 9, _h('#1E3A78'));
  b.rect(2, 2, 4, 1, _h('#F0C020'));
});

/// A sign hung beside a door (story 55): `cruz` a red cross on white (the hospital), `campana` a bell (the escuela),
/// 11 x 11.
Sprite mkLetrero(String k) => _mk(11, 11, (b) {
  b.rect(0, 0, 11, 11, _h('#FAFAF4'));
  if (k == 'cruz') {
    b.rect(4, 2, 3, 7, _h('#E03030'));
    b.rect(2, 4, 7, 3, _h('#E03030'));
  } else {
    b.ell(5.5, 5, 3, 3.4, _hs(['#B88A18', '#F0C020', '#F8E070']));
    b.rect(2, 7, 7, 1, _h('#B88A18'));
    b.px(5, 9, _h('#B88A18'));
  }
});

/* ---------- the lunch tins ---------- */

/// [n] lunch tins (1 to 3) stacked and tied with a cloth, a wisp of steam over the stack for each of [vapor] (0 to 3;
/// 3 the strongest), 14 x 26, the stack's bottom middle held.
Sprite mkFiambreras(int n, int vapor) {
  final b = Buf(14, 26);
  final top = 26 - n * 5 - 1;
  for (var i = 0; i < n; i++) {
    final y = 25 - (i + 1) * 5;
    b.rect(2, y, 10, 5, _h('#A8AEBC'));
    b.rect(2, y, 10, 1, _h('#E0E4EC'));
    b.rect(2, y + 4, 10, 1, _h('#7A8090'));
  }
  if (n > 0) {
    b.rect(6, top, 2, 26 - top - 1, _h('#D84848'));
    b.rect(5, top - 1, 4, 2, _h('#D84848'));
  }
  // the steam over the outline: no dark edge
  b.outline();
  final c = vapor >= 3
      ? _h('#FFFFFF')
      : vapor == 2
      ? _h('#E4ECF4')
      : _h('#C8D2DC');
  for (var k = 0; k < vapor; k++) {
    final x0 = 3.0 + k * 4;
    for (var y = 0; y < top - 3; y++) {
      b.px(x0 + math.sin(y * .9 + k) * 1.2, y, c);
    }
  }
  return b.done();
}

/// The tin opened (story 55's ending): rice in it, with [vapor] wisps of steam (0 to 3), 14 x 16, held at its bottom.
Sprite mkFiambreraAbierta(int vapor) {
  final b = Buf(14, 16);
  b.rect(1, 10, 12, 5, _h('#A8AEBC'));
  b.rect(1, 14, 12, 1, _h('#7A8090'));
  b.ell(7, 10, 6, 2, _hs(['#E8E4D8', '#FAFAF4', '#FFFFFF']));
  b.outline();
  final c = vapor >= 3 ? _h('#FFFFFF') : _h('#DCE4EC');
  for (var k = 0; k < vapor; k++) {
    for (var y = 0; y < 8; y++) {
      b.px(3.5 + k * 3.5 + math.sin(y * .9 + k) * 1.1, y, c);
    }
  }
  return b.done();
}

/* ---------- people of story 55 ---------- */

/// Mamá in her nurse's coat (story 55): FAM.mama in a white coat and white shoes, a red cross on its pocket.
final Who MAMA_ENFERMERA = Who(
  piel: FAM['mama']!.piel,
  pelo: FAM['mama']!.pelo,
  peinado: 'largo',
  ropa: _hs(['#B8C0CC', '#DCE2EA', '#F4F6FA', '#FFFFFF']),
  falda: true,
  zapato: _h('#F2F2F8'),
  detalle: (b, X, tc, rx, t) {
    b.rect(X + 2, tc - 3, 3, 1, _h('#E03030'));
    b.rect(X + 3, tc - 4, 1, 3, _h('#E03030'));
  },
);

/// The painter of the new building (story 55): white cap and overalls, a brush in his raised hand ([arriba]) or down.
final Who PINTOR = Who(
  piel: PIEL['b']!,
  pelo: _hs(['#E8E8E8', '#F4F4F4', '#FFFFFF']),
  peinado: 'corto',
  ropa: _hs(['#B8B8B0', '#DCDCD4', '#F0F0EA', '#FAFAF6']),
  abajo: _hs(['#B8B8B0', '#DCDCD4', '#F0F0EA']),
);

/// The painter in [pose] (`idle`, or `brocha`: the brush lifted, a drop of blue paint on it).
Sprite mkPintor(String pose, {bool open = false}) {
  final p = mkPersona(PINTOR, pose == 'brocha' ? 'wave0' : 'idle', open, false);
  final brush = _mk(5, 10, (b) {
    b.rect(2, 3, 1, 7, _h('#A8743A'));
    b.rect(0, 0, 5, 4, _h('#78CEDC'));
  });
  // the raised hand of mkPersona 'wave0' (kit.js: at (X + rx + 5, 10)); the lowered right hand (X + rx + 1, 33.5)
  return pose == 'brocha'
      ? overSprite(p, [(brush, PX + 8 + 5 - 2, 1)])
      : overSprite(p, [(brush, PX + 8 + 1 - 2, 28)]);
}

/// A head at a window (story 55): the top 16 rows of a grown-up's sprite (the señor's), shaking ([no]) or still.
Sprite mkCabezaVentana() {
  final s = mkPersona(FAM['abuelo']!, 'idle', false, false);
  const w = 20, h = 17;
  final px = Uint32List(w * h);
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      final sx = PX - 10 + x;
      if (y < s.h) px[y * w + x] = s.px[y * s.w + sx];
    }
  }
  return Sprite(w, h, px);
}

/// A hand that waves from a window at the top of the tall building (story 55), 7 x 9; [f] its two frames.
Sprite mkManoVentana(bool f) => _mk(7, 9, (b) {
  b.rect(2, 5, 3, 4, _h('#E8E4DA'));
  b.ell(f ? 2.5 : 4.5, 3, 2.4, 2.6, PIEL['a']!);
});

/* ---------- the sky of story 56 ---------- */

/// The dark cloud (story 56), 56 x 22: round lumps, darker underneath.
Sprite mkNube() => _mk(56, 22, (b) {
  final D = _hs(['#464A5C', '#5C6074', '#74788C', '#8C90A4']);
  for (final c in const [
    [12, 14, 11, 7],
    [26, 10, 13, 9],
    [40, 13, 12, 8],
    [20, 16, 12, 5],
    [34, 17, 14, 4],
  ]) {
    b.ell(c[0], c[1], c[2], c[3], D);
  }
});

/// Every sprite this file draws, in order, for the sheet picture (tiendas-sprites.png).
List<(String, Sprite)> tiendasSpriteSheet() => [
  ('cochecito con el bebe', mkCochecito()),
  ('cochecito: el bebe senala', mkCochecito(est: 'senala')),
  ('cochecito: el bebe aplaude', mkCochecito(est: 'clap', f: true)),
  for (final t in TOMA) ('cochecito: el bebe con $t', mkCochecito(toma: t)),
  ('cochecito vacio', mkCochecito(vacio: true)),
  for (final t in TOMA) (t, mkToma(t)),
  for (var n = 3; n >= 1; n--) ('$n monedas en la mano', mkMonedasMano(n)),
  ('una moneda', mkMoneda54()),
  ('la mano del tendero', mkManoTendero()),
  ('la carta', mkCarta()),
  ('el monedero gordo', mkMonedero()),
  ('la bolsita de la farmacia', mkBolsita()),
  ('las curitas', mkCuritas()),
  ('el sobre', mkSobre()),
  ('el paquete', mkPaquete()),
  ('el sello', mkSello()),
  ('el telefono', mkTelefono()),
  ('la bolsa grande', mkBolsaGrande()),
  ('el pan en su bolsa abierta', mkPan()),
  ('el pan en la bolsa grande', mkPan(true)),
  ('la sombrilla cerrada', mkSombrillaCerrada()),
  ('la sombrilla abierta', mkSombrillaAbierta()),
  ('la cometa', mkCometa()),
  ('el papel de Luis', mkPapel()),
  ('el papel de Luis, al reves', mkPapel(true)),
  ('el libro de papa', mkLibro()),
  ('letrero: cruz', mkLetrero('cruz')),
  ('letrero: campana', mkLetrero('campana')),
  for (var n = 3; n >= 1; n--)
    for (var v = 3; v >= 1; v--)
      ('$n fiambreras, $v vapor', mkFiambreras(n, v)),
  for (var v = 3; v >= 1; v--)
    ('la fiambrera abierta, $v vapor', mkFiambreraAbierta(v)),
  ('mama enfermera', mkPersona(MAMA_ENFERMERA, 'idle', false, false)),
  (
    'mama enfermera con el letrero',
    withHeld(
      mkPersona(MAMA_ENFERMERA, 'taza', false, false),
      mkLetrero('cruz'),
      'taza',
      false,
    ),
  ),
  (
    'papa con el libro',
    withHeld(
      mkPersona(FAM['papa']!, 'taza', false, false),
      mkLibro(),
      'taza',
      false,
    ),
  ),
  ('el pintor', mkPintor('idle')),
  ('el pintor levanta la brocha', mkPintor('brocha')),
  ('una cabeza en la ventana', mkCabezaVentana()),
  ('una mano en la ventana', mkManoVentana(false)),
  ('la nube', mkNube()),
  (
    'abuela con la carta',
    withHeld(mkAbuela('idle', false), mkCarta(), 'idle', true),
  ),
  (
    'abuela con las monedas',
    withHeld(mkAbuela('offer', false), mkMonedasMano(3), 'offer', true),
  ),
  (
    'abuela con el telefono',
    withHeld(mkAbuela('wave0', false), mkTelefono(), 'wave0', true),
  ),
  ('abuela sentada', mkAbuelaS('idle', false, false)),
  (
    'abuela con la sombrilla abierta',
    withHeld(
      mkAbuela('wave0', false),
      mkSombrillaAbierta(),
      'wave0',
      true,
      up: true,
    ),
  ),
  (
    'la senora con la cometa',
    withHeld(
      mkCliente('senora', 'wave0'),
      mkCometa(),
      'wave0',
      false,
      up: true,
    ),
  ),
  (
    'Luis con el papel',
    withHeld(
      callePerson('luis', 'taza').s,
      mkPapel(),
      'taza',
      false,
      nino: true,
    ),
  ),
  ('Luis sentado', mkPersona(FAM['hermano']!, 'idle', false, true)),
  (
    'Luis en bicicleta con las fiambreras',
    mkCiclista(FAM['hermano']!, cesta: true),
  ),
];

/// The held things that are held up from below (the kite by its string, the open umbrella by its stick): their bottom
/// is at the hand; every other thing hangs from it.
bool heldUp(String? k) => k == 'kite' || k == 'umbrellaOpen';

/// Where a held thing is drawn on a person's sprite (its hand in [pose]), as the top left of [thing] on the person's
/// canvas: abuela (mkAbuela, [abuela]) or a mkPersona figure (a grown-up or a child, [nino]). Hands: kit.js / engine.js
/// (abuela 'offer' at (11.5, 27), 'wave0' at (42.5, 10), idle at (40, 35.5); a persona 'taza' at (X + rx + 4.5, 27),
/// 'offer' at (X - rx - 9.5, 25), 'wave0' at (X + rx + 5, 10), idle at (X + rx + 1, 21 + t + 1.5)).
(int, int) handOf(
  Sprite thing,
  String pose,
  bool abuela, {
  bool nino = false,
  bool up = false,
}) {
  final (num hx, num hy) = abuela
      ? switch (pose) {
          'offer' => (11.5, 27),
          'wave0' || 'wave1' => (42.5, 10),
          _ => (40, 35.5),
        }
      : () {
          final rx = nino ? 6.5 : 8, t = nino ? 7 : 11;
          return switch (pose) {
            'taza' => (PX + rx + 4.5, 27),
            'offer' => (PX - rx - 9.5, 25),
            'wave0' || 'wave1' => (PX + rx + 5, 10),
            _ => (PX + rx + 1, 21 + t + 1.5),
          };
        }();
  // a thing hangs from the hand: its top middle at the hand; one held up has its bottom middle there
  return up
      ? ((hx - thing.w / 2).round(), (hy - thing.h + 3).round())
      : ((hx - thing.w / 2).round(), (hy - 2).round());
}

/// [person] with [thing] in its hand (see [handOf]); the canvas grows to hold it.
Sprite withHeld(
  Sprite person,
  Sprite thing,
  String pose,
  bool abuela, {
  bool nino = false,
  bool up = false,
}) {
  final (x, y) = handOf(thing, pose, abuela, nino: nino, up: up);
  final l = math.min(0, x), t = math.min(0, y);
  final w = math.max(person.w, x + thing.w) - l,
      h = math.max(person.h, y + thing.h) - t;
  final base = Sprite(w, h, Uint32List(w * h));
  return overSprite(base, [(person, -l, -t), (thing, x - l, y - t)]);
}
