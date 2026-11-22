// What only El banco de la plaza (scene `plaza`, stories 60 to 62) draws, besides La plaza's cast (plaza_cast.dart): the
// two answer bubbles over the frog and their pictures (a name badge, two hands shaking), the frog's bag of bread, a
// visitor's bubble (the flag of the United States and a small piragua or guagua), a helper's bubble with both flags, the
// small photos of faces on the board's hooks, the blank cards under their stone (3 to 0) and one blown away, the frog's
// three drawings and the pencil, the coin jar (empty to full), piraguas of one, two and three colours (plaza.md, "Needs",
// New sprites). Drawn in the old sprites' way (engine.js Buf, ramps, the dark outline OUT). The content lane looks at
// each on docs/proyecto/pixel/port/plaza-sprites.png (tool/make_plaza_sprites_test.dart).
// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/src/plaza/plaza_cast.dart';

int _h(String s) => hexColour(s);
List<int> _hs(List<String> s) => [for (final x in s) hexColour(x)];

/// The answer bubbles' size (plaza-sheet.json things.burbuja_a.box: 22 x 22).
const int BURBUJA = 22;

// a round white bubble filling w x h, its outline OUT, a small tail at the bottom middle
void _globo(Buf b, int w, int h, {bool cola = true, int? fondo}) {
  final c = fondo ?? _h('#FFFFFF');
  b.ell(
    (w - 1) / 2,
    (h - (cola ? 4 : 1)) / 2,
    (w - 2) / 2,
    (h - (cola ? 5 : 2)) / 2,
    [c],
  );
  if (cola) {
    b.rect(w ~/ 2 - 2, h - 6, 4, 2, c);
    b.rect(w ~/ 2 - 1, h - 4, 2, 2, c);
    b.px(w ~/ 2, h - 2, c);
  }
}

/// An answer bubble (story 60): `insignia` (a name badge: a white card on a red band, a dark line of writing) or `manos`
/// (two hands shaking). [lit]: the frog says its line now (a yellow ground).
Sprite mkBurbuja(String que, {bool lit = false}) {
  final b = Buf(BURBUJA, BURBUJA);
  _globo(b, BURBUJA, BURBUJA, fondo: lit ? _h('#FFF0A0') : null);
  final S = PIEL['c']!;
  if (que == 'insignia') {
    b.rect(5, 5, 12, 9, _h('#D0302A'));
    b.rect(5, 5, 12, 3, _h('#E85A4A'));
    b.rect(6, 8, 10, 5, _h('#FFFFFF'));
    b.rect(7, 10, 6, 1, _h('#24160E'));
    b.rect(7, 12, 4, 1, _h('#6A5A4A'));
  } else {
    // two hands meeting, one from each side, each with its sleeve
    b.rect(2, 9, 4, 4, _h('#4A70C0'));
    b.rect(16, 9, 4, 4, _h('#5AB46A'));
    b.ell(8.5, 10.5, 3.2, 2.2, [S[3], S[2]]);
    b.ell(13.5, 10.5, 3.2, 2.2, [S[2], S[1]]);
    b.rect(9, 8, 4, 1, S[1]);
    b.px(11, 12, S[0]);
  }
  return b.outline().done();
}

/// The frog's little bag of bread (story 60).
Sprite mkBolsaPan() {
  final b = Buf(10, 11);
  b.rect(1, 3, 8, 7, _h('#E8D8B0'));
  b.rect(1, 3, 3, 7, _h('#F4E8C8'));
  b.rect(2, 1, 3, 3, _h('#E2A85A'));
  b.rect(5, 2, 3, 2, _h('#C48440'));
  return b.outline().done();
}

/// A crumb of bread, held out.
Sprite mkMigaja() {
  final b = Buf(5, 4);
  b.rect(1, 1, 3, 2, _h('#E2A85A'));
  return b.outline().done();
}

/// A small piragua (a paper cone of shaved ice): [colores] 1 (red), 2 (red and blue), 3 (red, yellow, blue: the
/// painting on the cart). [grande]: as big as the frog (story 62's ending).
Sprite mkPiraguaPz(int colores, {bool grande = false}) {
  final k = grande ? 2 : 1, w = 9 * k + 2, h = 14 * k + 2, b = Buf(w, h);
  final cone = _hs(['#C8B890', '#E8DCB8', '#F8F0D8']);
  // the cone
  for (var y = 0; y < 7 * k; y++) {
    final half = (7 * k - y) * 4.0 / (7 * k) * k;
    b.rect(
      (w / 2 - half / 2).round(),
      1 + 7 * k + y,
      half.round().clamp(1, w),
      1,
      y % (3 * k) == 0 ? cone[0] : cone[1],
    );
  }
  // the ice: a dome of one, two or three colours
  final cols = switch (colores) {
    1 => _hs(['#B02030', '#E0384A', '#F87080']),
    2 => _hs(['#B02030', '#E0384A', '#4A70C0']),
    _ => _hs(['#E0384A', '#F0C020', '#4A70C0']),
  };
  for (var i = 0; i < 3; i++) {
    final c = colores == 1 ? cols[1] : cols[i % cols.length];
    b.ell(1 + 1.5 * k + i * 2.5 * k, 1 + 5.5 * k, 2.2 * k, 3.6 * k, [c]);
  }
  b.px(w ~/ 2 - k, 2 + k, _h('#FFFFFF'));
  return b.outline().done();
}

/// A visitor's bubble (story 62): the flag of the United States and a small picture of what she asks for (`piragua` or
/// `guagua`). Nothing in English is ever heard: this is what she says.
Sprite mkPideBurbuja(String cosa) {
  final b = Buf(30, 20);
  _globo(b, 30, 20);
  final pic = cosa == 'guagua' ? mkGuaguaChica() : mkPiraguaPz(1);
  final f = mkBandera('us');
  final s = b.done();
  return _put(s, [(f, 3, 4), (pic, 18 - pic.w ~/ 2 + 2, 8 - pic.h ~/ 2 + 1)]);
}

/// A helper's bubble (story 62: Ana, or whoever can help): both flags, the island's and the United States'.
Sprite mkTraduceBurbuja() {
  final b = Buf(30, 18);
  _globo(b, 30, 18);
  return _put(b.done(), [(mkBandera('pr'), 3, 4), (mkBandera('us'), 15, 4)]);
}

// [parts] drawn over [base] at their places (each pixel with alpha as it is), then outlined again
Sprite _put(Sprite base, List<(Sprite, int, int)> parts) {
  final b = Buf(base.w, base.h);
  for (var y = 0; y < base.h; y++) {
    for (var x = 0; x < base.w; x++) {
      final c = base.px[y * base.w + x];
      if (c >>> 24 != 0) b.px(x, y, c);
    }
  }
  for (final (p, ox, oy) in parts) {
    for (var y = 0; y < p.h; y++) {
      for (var x = 0; x < p.w; x++) {
        final c = p.px[y * p.w + x];
        if (c >>> 24 != 0) b.px(ox + x, oy + y, c);
      }
    }
  }
  return b.done();
}

/// A small guagua, seen from the side (what the visitor asks for in story 62, step 3).
Sprite mkGuaguaChica() {
  final b = Buf(13, 9);
  b.rect(1, 1, 11, 5, _h('#F0C020'));
  b.rect(1, 1, 11, 1, _h('#FFE070'));
  for (var x = 2; x < 11; x += 3) {
    b.rect(x, 2, 2, 2, _h('#9CCBF5'));
  }
  b.ell(3.5, 6.5, 1.6, 1.6, [_h('#24242A')]);
  b.ell(9.5, 6.5, 1.6, 1.6, [_h('#24242A')]);
  return b.outline().done();
}

/// A small photo of [quien]'s face, hung on a hook (story 61): a white frame round a face with the person's skin and
/// hair (as plaza-cast-sprites.png draws them); `coqui` the frog's green face.
Sprite mkFoto(String quien) {
  final b = Buf(9, 10);
  b.rect(1, 1, 7, 8, _h('#FAFAF4'));
  b.rect(2, 2, 5, 5, _h('#BFD8F0'));
  if (quien == 'coqui') {
    b.ell(4.5, 5, 2.4, 2, [_h('#4CAF50'), _h('#7CD67A')]);
    b.px(3, 4, _h('#20140A'));
    b.px(6, 4, _h('#20140A'));
  } else {
    final w = plazaWho(quien) ?? PLAZA_GENTE['ana']!.who;
    b.ell(4.5, 5.2, 2, 2.2, [w.piel[3], w.piel[2]]);
    b.rect(3, 2, 4, 2, w.pelo[1]);
    b.px(4, 5, _h('#20140A'));
    b.px(5, 5, _h('#20140A'));
  }
  b.rect(2, 7, 5, 1, _h('#E4E4DC'));
  return b.outline().done();
}

/// The blank cards under their stone on the board's ledge (story 61): [n] cards (3 to 0) and the grey stone on them.
Sprite mkTarjetas(int n) {
  final b = Buf(18, 13);
  for (var i = 0; i < n; i++) {
    b.rect(2 + i, 6 - i, 12, 6, _h('#FAFAF4'));
    b.rect(2 + i, 6 - i, 12, 1, _h('#E4E4DC'));
  }
  b.ell(
    9,
    5.5 + (3 - n) * 0.8,
    3.6,
    2.4,
    _hs(['#6A6A72', '#8A8A94', '#B0B0BA']),
  );
  return b.outline().done();
}

/// One blank card, flying in the wind (two frames by [f]).
Sprite mkTarjetaVuela(int f) {
  final b = Buf(14, 10);
  if (f % 2 == 0) {
    b.rect(1, 3, 12, 5, _h('#FAFAF4'));
  } else {
    for (var x = 1; x < 13; x++) {
      b.rect(x, 1 + (x ~/ 3), 1, 5, _h('#FAFAF4'));
    }
  }
  return b.outline().done();
}

/// The frog's drawings on the cards (story 61's ending): `casa` (abuela's house), `abuela`, `familia` (the whole family).
Sprite mkDibujo(String k) {
  final b = Buf(10, 10);
  b.rect(1, 1, 8, 8, _h('#FAFAF4'));
  final ink = _h('#2A4AA8'), red = _h('#D0302A');
  switch (k) {
    case 'casa':
      b.line(2, 4, 4, 2, red);
      b.line(5, 2, 7, 4, red);
      b.rect(2, 4, 6, 4, _h('#F0C020'));
      b.rect(4, 5, 2, 3, ink);
    case 'abuela':
      b.ell(5, 3.5, 1.8, 1.8, [_h('#E2B484')]);
      b.rect(4, 2, 3, 1, _h('#C8C8D4'));
      b.rect(3, 5, 5, 3, _h('#8A5AB8'));
    default:
      for (var i = 0; i < 3; i++) {
        b.px(2 + i * 2, 3 + (i.isOdd ? 1 : 0), _h('#8A5A38'));
        b.rect(2 + i * 2, 5, 1, 3, i.isOdd ? red : ink);
      }
  }
  return b.outline().done();
}

/// The pencil Ana gives the frog.
Sprite mkLapiz() {
  final b = Buf(12, 5);
  b.rect(1, 1, 8, 3, _h('#F0C020'));
  b.rect(9, 1, 1, 3, _h('#E2B484'));
  b.px(10, 2, _h('#24242A'));
  b.rect(1, 1, 1, 3, _h('#E0786A'));
  return b.outline().done();
}

/// The piragüero's coin jar (story 62): glass, [n] coins in it (0 to 7: full to the top).
Sprite mkJarra(int n) {
  final b = Buf(11, 14);
  b.rect(1, 2, 9, 11, _h('#D8ECF4'));
  b.rect(2, 1, 7, 1, _h('#B8D0DC'));
  b.rect(1, 2, 2, 11, _h('#F0F8FC'));
  final gold = _hs(['#B87A10', '#F0C020', '#FFE070']);
  for (var i = 0; i < n.clamp(0, 7); i++) {
    b.rect(
      2 + (i % 3) * 2 + (i ~/ 3) % 2,
      11 - (i ~/ 3) * 2 - (i % 2),
      3,
      2,
      gold[i % 3],
    );
  }
  return b.outline().done();
}

/// Everything this file draws, for its sheet picture (plaza-sprites.png).
List<(String, Sprite)> plazaSpriteSheet() => [
  ('burbuja insignia', mkBurbuja('insignia')),
  ('burbuja manos', mkBurbuja('manos')),
  ('burbuja insignia, dicha', mkBurbuja('insignia', lit: true)),
  ('burbuja manos, dicha', mkBurbuja('manos', lit: true)),
  ('bolsa de pan', mkBolsaPan()),
  ('migaja', mkMigaja()),
  ('pide piragua', mkPideBurbuja('piragua')),
  ('pide guagua', mkPideBurbuja('guagua')),
  ('traduce: las dos banderas', mkTraduceBurbuja()),
  ('guagua chica', mkGuaguaChica()),
  for (final q in const [
    'ana',
    'luis',
    'abuela_ana',
    'coqui',
    'senora',
    'senor',
  ])
    ('foto $q', mkFoto(q)),
  for (var n = 3; n >= 0; n--) ('tarjetas $n', mkTarjetas(n)),
  ('tarjeta vuela 0', mkTarjetaVuela(0)),
  ('tarjeta vuela 1', mkTarjetaVuela(1)),
  for (final k in const ['casa', 'abuela', 'familia'])
    ('dibujo $k', mkDibujo(k)),
  ('lapiz', mkLapiz()),
  for (final n in const [0, 1, 3, 5, 7]) ('jarra $n', mkJarra(n)),
  for (final c in const [1, 2, 3]) ('piragua $c', mkPiraguaPz(c)),
  for (final c in const [1, 2, 3])
    ('piragua grande $c', mkPiraguaPz(c, grande: true)),
];
