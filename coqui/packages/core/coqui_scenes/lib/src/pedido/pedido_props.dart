// El pedido's props, cat, board pictures, plates, drinks, FX, and sprite sheet list (part of pedido_sprites.dart).
part of 'pedido_sprites.dart';

Sprite _mkCocineroProp(String prop) => _mk(14, 14, (b) {
  switch (prop) {
    case 'platano':
      b.cap(4, 2, 10, 11, 1.8, _ramp(const ['#3E7A2A', '#58A03C', '#88C860']));
    case 'tres_platanos':
      for (final x in const [3.5, 7.0, 10.5]) {
        b.cap(7, 2, x, 12, 1.4, _ramp(const ['#3E7A2A', '#58A03C', '#88C860']));
      }
      b.rect(3, 6, 8, 2, _h('#D0403A'));
    case 'sarten':
      b.ell(6, 8, 4.5, 3, _ramp(const ['#3A3A44', '#5A5A68', '#7A7A8A']));
      b.rect(10, 7, 4, 2, _h('#5A3A1E'));
      b.ell(6, 7.5, 2.4, 1.4, _ramp(const ['#C8861C', '#F6D060']));
    case 'prensa':
      b.rect(2, 9, 10, 3, _h('#A8682C'));
      b.rect(2, 4, 10, 3, _h('#C8853C'));
      b.rect(1, 5, 2, 6, _h('#7A4A1E'));
      b.ell(7, 8, 2.2, 1, _ramp(const ['#C8861C', '#F6D060']));
    case 'pilon':
      b.rect(4, 6, 6, 6, _h('#A8682C'));
      b.rect(3, 5, 8, 2, _h('#C8853C'));
      b.rect(5, 11, 4, 2, _h('#7A4A1E'));
      b.cap(7, 5, 10, 1, 1.2, _ramp(const ['#B87A3C', '#DFAA68']));
      b.ell(7, 5, 2.4, 1.2, _ramp(const ['#C8861C', '#F6D060']));
  }
});

/* ---------- the fonda's cat (26 x 20, anchor 12, 20) ---------- */

/// The fonda's grey cat: 26 x 20 (pedido-preview.html `THING.gato` for `sit`), plus `mira` (looking up at shelf),
/// `pata` (paw raised), `lame` (licking paw), `duerme` (curled asleep round as a ball).
Sprite mkGatoPedido(String pose, {int frame = 0}) => _mk(26, 20, (b) {
  final gr = _CAT_GREY;
  const X = 12, Y = 11;
  final eye = _h('#F8C838'), pink = _h('#FF8FB8');
  if (pose == 'duerme') {
    b.ell(X, Y + 4, 8.8, 4.8, gr);
    b.ell(X + 5, Y + 3, 4, 3.4, gr);
    b.rect(X + 3, Y - 1, 2, 2, gr[1]);
    b.rect(X + 7, Y - 1, 2, 2, gr[1]);
    b.rect(X + 4, Y + 3, 2, 1, OUT);
    b.cap(X - 8, Y + 6, X - 2, Y + 8, 1.3, [gr[1]]);
    return;
  }
  b.cap(X - 8, Y + 1, X - 11, Y - 6, 1.3, [gr[1]]);
  b.ell(X - 1, Y + 3, 5.6, 6, gr);
  b.rect(X + 2, Y + 4, 2, 6, gr[1]);
  b.ell(X - 3, Y + 8, 4, 2, [gr[1]]);
  if (pose == 'pata') {
    b.cap(X + 3, Y + 2, X + 2, Y - 6, 1.3, [gr[2]]);
    b.px(X + 2, Y - 7, pink);
  } else if (pose == 'lame') {
    final dy = frame % 2 == 0 ? 0 : 1;
    b.rect(X + 4, Y - 1 + dy, 2, 5, gr[2]);
    b.px(X + 5, Y - 1 + dy, pink);
  }
  final hx = X + 8;
  final hy = pose == 'mira' ? Y - 5 : Y - 4;
  b.ell(hx, hy, 4.6, 4.2, gr);
  b.rect(hx - 4, hy - 6, 3, 3, gr[1]);
  b.rect(hx + 2, hy - 6, 3, 3, gr[1]);
  if (pose == 'mira') {
    b.px(hx - 1, hy - 2, eye);
    b.px(hx + 2, hy - 2, eye);
    b.px(hx + 1, hy, pink);
  } else {
    b.px(hx - 1, hy - 1, eye);
    b.px(hx + 2, hy - 1, eye);
    b.px(hx + 1, hy + 1, pink);
  }
});

/* ---------- board pictures (14 x 12, anchor 7, 6) ---------- */

void _drawPicDish(Buf b, String kind) {
  switch (kind) {
    case 'sopa':
      b.ell(7, 7.5, 5, 3, _ramp(const ['#7A4A1E', '#A8682C', '#C8853C']));
      b.ell(7, 6.2, 4.2, 1.5, _ramp(const ['#E87830', '#F6A050']));
      for (final (x, y) in const [(5, 3), (6, 2), (8, 3), (9, 2)]) {
        b.px(x, y, _h('#B8B8C8'));
      }
    case 'carne':
      b.ell(7, 7, 5.6, 3, _PLATE);
      b.ell(5.4, 6.2, 2, 1.6, _ramp(const ['#6A2A12', '#8A4212', '#B8601C']));
      b.ell(8.6, 6.6, 2, 1.6, _ramp(const ['#6A2A12', '#8A4212', '#B8601C']));
    case 'pescado':
      b.ell(7, 7, 5.6, 3, _PLATE);
      b.ell(6.2, 6.4, 3.4, 1.5, _ramp(const ['#6E7E96', '#98A8BE', '#C8D4E4']));
      b.line(9, 6, 11, 4.5, _h('#98A8BE'));
      b.line(9, 7, 11, 8, _h('#98A8BE'));
      b.px(4, 6, _h('#20140A'));
    case 'ensalada':
      b.ell(7, 7.5, 5, 3, _PLATE);
      b.ell(7, 6, 4.4, 2, _ramp(const ['#389838', '#58B058', '#88D078']));
      b.px(5, 5, _h('#D0403A'));
      b.px(8, 4, _h('#D0403A'));
      b.px(9, 6, _h('#D0403A'));
    case 'carne_tostones' || 'ct':
      b.ell(7, 7, 5.6, 3, _PLATE);
      b.ell(4.8, 6.2, 2, 1.6, _ramp(const ['#6A2A12', '#8A4212', '#B8601C']));
      for (final x in const [8.0, 10.0]) {
        b.ell(x, 6.4, 1.3, 1, _ramp(const ['#C8861C', '#F6D060']));
      }
    case 'carne_mofongo' || 'cm':
      b.ell(7, 7, 5.6, 3, _PLATE);
      b.ell(4.8, 6.2, 2, 1.6, _ramp(const ['#6A2A12', '#8A4212', '#B8601C']));
      b.ell(9.2, 5.6, 2.2, 2.2, _ramp(const ['#A8782C', '#D8AC58', '#F0D088']));
    case 'pescado_tostones' || 'pt':
      b.ell(7, 7, 5.6, 3, _PLATE);
      b.ell(4.8, 6.4, 2.6, 1.3, _ramp(const ['#6E7E96', '#98A8BE', '#C8D4E4']));
      for (final x in const [8.5, 10.5]) {
        b.ell(x, 6.4, 1.3, 1, _ramp(const ['#C8861C', '#F6D060']));
      }
    case 'pescado_mofongo' || 'pm':
      b.ell(7, 7, 5.6, 3, _PLATE);
      b.ell(4.8, 6.4, 2.6, 1.3, _ramp(const ['#6E7E96', '#98A8BE', '#C8D4E4']));
      b.ell(9.2, 5.6, 2.2, 2.2, _ramp(const ['#A8782C', '#D8AC58', '#F0D088']));
    case 'refresco':
      b.rect(6, 2, 3, 3, _h('#B8402A'));
      b.rect(5, 5, 5, 6, _h('#B8402A'));
      b.rect(5, 7, 5, 2, _h('#FAF0C8'));
      b.rect(6, 1, 3, 1, _h('#C8C8D4'));
      b.px(9, 0, _h('#D0403A'));
      b.px(9, 1, _h('#D0403A'));
    case 'limonada':
      b.rect(4, 3, 6, 8, _h('#F6F0A0'));
      b.rect(4, 3, 6, 1, _h('#FFFFFF'));
      b.ell(10, 3, 1.6, 1.6, [_h('#389838')]);
      b.line(7, 1, 7, 6, _h('#D0403A'));
    case 'jugo':
      b.rect(4, 3, 6, 8, _h('#F2A650'));
      b.rect(4, 3, 6, 1, _h('#FFE070'));
      b.line(8, 1, 8, 6, _h('#D0403A'));
    case 'cafe':
      b.rect(4, 5, 6, 5, _h('#FFFFFF'));
      b.rect(4, 5, 6, 1, _h('#7A4A1E'));
      b.rect(10, 6, 2, 3, _h('#B8B8C8'));
      b.rect(3, 10, 8, 1, _h('#B8B8C8'));
      b.px(6, 3, _h('#B8B8C8'));
      b.px(8, 2, _h('#B8B8C8'));
  }
}

/// Picture on a board panel: 14 x 12 (pedido-preview.html `THING.pic`).
/// When [lit] is true, draws a bright golden highlight border inside the same 14 x 12 box (stays clear of neighbors).
Sprite mkCuadroPic(String kind, {bool lit = false}) => _mk(14, 12, (b) {
  b.rect(0, 0, 14, 12, lit ? _h('#FFFDF4') : _h('#FFFBEA'));
  b.frame(0, 0, 14, 12, lit ? _h('#FFE040') : _h('#B89A6A'));
  if (lit) {
    b.frame(1, 1, 12, 10, _h('#F8B828'));
  }
  _drawPicDish(b, kind);
});

/// Small dish order bubble shown above a seated family member in story 87 (`pide87`): 14 x 12.
Sprite mkOrdenBurbuja(String dish) => _mk(14, 12, (b) {
  b.rect(1, 0, 12, 10, _h('#FFFDF4'));
  b.rect(0, 1, 14, 8, _h('#FFFDF4'));
  b.rect(6, 10, 2, 2, _h('#FFFDF4'));
  _drawPicDish(b, dish);
});

/* ---------- shelf plates & small plates ---------- */

/// Plate on the shelf or table: 14 x 8 (pedido-preview.html `THING.plato`, matches `spots.repisa1..3`).
Sprite mkPlato(String kind) => _mk(14, 8, (b) {
  b.ell(7, 4.5, 6.4, 3, _PLATE);
  switch (kind) {
    case 'sopa':
      b.ell(7, 3.8, 4, 1.6, _ramp(const ['#E87830', '#F6A050']));
    case 'carne':
      b.ell(5, 3.6, 2.2, 1.5, _ramp(const ['#6A2A12', '#8A4212', '#B8601C']));
      b.ell(9, 3.8, 2.2, 1.5, _ramp(const ['#6A2A12', '#8A4212', '#B8601C']));
    case 'pescado':
      b.ell(6.5, 3.8, 3.8, 1.5, _ramp(const ['#6E7E96', '#98A8BE', '#C8D4E4']));
      b.line(10, 3, 12, 1.5, _h('#98A8BE'));
      b.line(10, 4, 12, 5.5, _h('#98A8BE'));
    case 'ensalada':
      b.ell(7, 3.8, 4.4, 1.8, _ramp(const ['#389838', '#58B058', '#88D078']));
      b.px(5, 3, _h('#D0403A'));
      b.px(8, 2, _h('#D0403A'));
      b.px(9, 4, _h('#D0403A'));
    case 'tostones':
      for (final (x, y) in const [(4.2, 3.7), (7.0, 3.2), (9.8, 3.7)]) {
        b.ell(x, y, 1.6, 1.1, _ramp(const ['#C8861C', '#F6D060']));
      }
    case 'mofongo':
      b.ell(7, 3.0, 3.0, 2.4, _ramp(const ['#A8782C', '#D8AC58', '#F0D088']));
    case 'carne_tostones':
      b.ell(4.6, 3.6, 2.0, 1.4, _ramp(const ['#6A2A12', '#8A4212', '#B8601C']));
      b.ell(8.2, 3.8, 1.3, 1.0, _ramp(const ['#C8861C', '#F6D060']));
      b.ell(10.2, 3.5, 1.3, 1.0, _ramp(const ['#C8861C', '#F6D060']));
    case 'carne_mofongo':
      b.ell(4.6, 3.6, 2.0, 1.4, _ramp(const ['#6A2A12', '#8A4212', '#B8601C']));
      b.ell(9.2, 3.1, 2.2, 2.0, _ramp(const ['#A8782C', '#D8AC58', '#F0D088']));
    case 'pescado_tostones':
      b.ell(4.8, 3.8, 2.6, 1.2, _ramp(const ['#6E7E96', '#98A8BE', '#C8D4E4']));
      b.ell(8.6, 3.8, 1.3, 1.0, _ramp(const ['#C8861C', '#F6D060']));
      b.ell(10.6, 3.5, 1.3, 1.0, _ramp(const ['#C8861C', '#F6D060']));
    case 'pescado_mofongo':
      b.ell(4.8, 3.8, 2.6, 1.2, _ramp(const ['#6E7E96', '#98A8BE', '#C8D4E4']));
      b.ell(9.2, 3.1, 2.2, 2.0, _ramp(const ['#A8782C', '#D8AC58', '#F0D088']));
  }
});

/// Small plate with [rounds] (0..3) golden fried rounds: 12 x 8 (pedido-preview.html `THING.platito`, `repisa_fin`).
Sprite mkPlatito(int rounds) {
  final n = rounds.clamp(0, 3);
  return _mk(12, 8, (b) {
    b.ell(6, 4.5, 5.4, 3, _PLATE);
    if (n == 0) {
      b.ell(6, 4.2, 3.2, 1.4, [_h('#B8B8C8')]);
    } else {
      const pts = [(3.6, 3.7), (6.0, 3.2), (8.4, 3.7)];
      for (var i = 0; i < n; i++) {
        b.ell(
          pts[i].$1,
          pts[i].$2,
          1.5,
          1,
          _ramp(const ['#C8861C', '#F6D060']),
        );
      }
    }
  });
}

/// The frog's own plate in story 88 (`repisa_fin`): 0 = empty (12 x 8, matches `THING.platoRana`),
/// 1 = four tostones (12 x 8), 2 = full plate (12 x 8), 3 = heaped mountain (12 x 10).
Sprite mkPlatoRana(int level) {
  final lv = level.clamp(0, 3);
  final h = lv == 3 ? 10 : 8;
  final dy = h - 8;
  return _mk(12, h, (b) {
    final gold = _ramp(const ['#C8861C', '#F6D060']);
    b.ell(6, 4.5 + dy, 5.4, 3, _PLATE);
    if (lv == 0) {
      b.ell(6, 4.2 + dy, 3.2, 1.4, [_h('#B8B8C8')]);
    } else if (lv == 1) {
      for (final (x, y) in const [
        (3.4, 3.9),
        (5.4, 3.3),
        (7.4, 3.9),
        (9.0, 3.4),
      ]) {
        b.ell(x, y + dy, 1.3, 0.9, gold);
      }
    } else if (lv == 2) {
      for (final (x, y) in const [
        (3.2, 4.1),
        (5.4, 4.2),
        (7.6, 4.1),
        (9.2, 3.8),
        (4.5, 2.8),
        (7.2, 2.8),
      ]) {
        b.ell(x, y + dy, 1.4, 1.0, gold);
      }
    } else {
      for (final (x, y) in const [
        (3.0, 4.2),
        (5.2, 4.4),
        (7.4, 4.3),
        (9.2, 4.0),
        (4.0, 2.8),
        (6.2, 2.7),
        (8.4, 2.9),
        (5.0, 1.4),
        (7.2, 1.4),
        (6.0, 0.3),
      ]) {
        b.ell(x, y + dy, 1.4, 1.0, gold);
      }
    }
  });
}

/* ---------- hanging plantains (14 x 18, anchor 7, 0) ---------- */

/// Green plantains hanging from the hook: 14 x 18 (pedido-preview.html `THING.platanos`, matches `spots.platanos`).
/// Always shows the green bunch at the back, plus [tied] (0..3) plantains tied with a red ribbon.
Sprite mkPlatanos(int tied) {
  final n = tied.clamp(0, 3);
  return _mk(14, 18, (b) {
    final backGreen = _ramp(const ['#2E6420', '#468430', '#6AA84A']);
    final frontGreen = _ramp(const ['#3E7A2A', '#58A03C', '#88C860']);
    b.rect(6, 0, 2, 3, _h('#6A6A7A'));
    for (final (x, y) in const [(2.5, 15.0), (11.5, 15.0)]) {
      b.cap(7, 3.5, x, y, 1.6, backGreen);
    }
    const frontPts = [(5.0, 16.5), (7.0, 17.0), (9.0, 16.5)];
    for (var i = 0; i < n; i++) {
      b.cap(7, 3.5, frontPts[i].$1, frontPts[i].$2, 1.7, frontGreen);
    }
    if (n > 0) {
      final rw = n == 3 ? 8 : (n == 2 ? 6 : 4);
      final rx = 7 - rw ~/ 2;
      b.rect(rx, 8, rw, 2, _h('#D0403A'));
      b.px(6, 7, _h('#D0403A'));
      if (n >= 2) b.px(8, 7, _h('#D0403A'));
    }
  });
}

/* ---------- drinks on tray & tall juice glass ---------- */

/// Drink on the tray: 10 x 14 (pedido-preview.html `THING.bebida`, matches `spots.bebida1..3`).
Sprite mkBebida(String kind) => _mk(10, 14, (b) {
  switch (kind) {
    case 'refresco':
      b.rect(4, 2, 2, 3, _h('#B8402A'));
      b.rect(2, 5, 6, 8, _h('#B8402A'));
      b.rect(2, 8, 6, 2, _h('#FAF0C8'));
      b.rect(4, 1, 2, 1, _h('#C8C8D4'));
      b.px(7, 0, _h('#D0403A'));
      b.px(7, 1, _h('#D0403A'));
    case 'limonada':
      b.rect(2, 4, 6, 9, _h('#F6F0A0'));
      b.rect(2, 4, 6, 1, _h('#FFFFFF'));
      b.ell(8, 4, 1.6, 1.6, [_h('#389838')]);
      b.line(5, 0, 5, 7, _h('#D0403A'));
    case 'cafe':
      b.rect(1, 7, 6, 6, _h('#FFFFFF'));
      b.rect(1, 7, 6, 1, _h('#7A4A1E'));
      b.rect(7, 8, 2, 3, _h('#B8B8C8'));
      b.rect(0, 13, 8, 1, _h('#B8B8C8'));
      b.px(3, 4, _h('#B8B8C8'));
      b.px(5, 2, _h('#B8B8C8'));
  }
});

/// Tall glass of orange juice with straw & paper umbrella: 8 x 18 (pedido-preview.html `THING.vasito`, `spots.vasito`).
/// [thirds]: 3 = full, 2 = 2/3, 1 = 1/3, 0 = empty glass.
Sprite mkVasito(int thirds) {
  final n = thirds.clamp(0, 3);
  return _mk(8, 18, (b) {
    b.rect(1, 5, 6, 13, _h('#DCECF8'));
    b.rect(2, 6, 4, 11, _h('#F2F8FC'));
    if (n > 0) {
      final fillH = n == 3 ? 13 : (n == 2 ? 9 : 5);
      final fillY = 18 - fillH;
      b.rect(1, fillY, 6, fillH, _h('#F69628'));
      b.rect(1, fillY, 6, 1, _h('#FFE070'));
    }
    b.line(5, 0, 4, 9, _h('#D0403A'));
    b.ell(2, 3, 2.2, 1.2, _ramp(const ['#4A8CE8', '#B0D4FF']));
    b.px(2, 4, _h('#6A6A7A'));
  });
}

/* ---------- transient FX & gesture cues ---------- */

/// Bell ring sparkle over the hatch shelf bell: 14 x 8.
Sprite mkCampanaBrillo(int frame) {
  final b = Buf(14, 8);
  final c1 = _h('#FFE040'), c2 = _h('#FFF8C0');
  final d = frame % 2 == 0 ? 0 : 1;
  b.line(2 - d, 6, 0, 3, c1);
  b.line(11 + d, 6, 13, 3, c1);
  b.px(6, 1 + d, c2);
  b.px(7, 1 + d, c2);
  b.px(4, 2, c1);
  b.px(9, 2, c1);
  return b.done();
}

/// Steam wisps rising off a hot plate: 10 x 8.
Sprite mkVapor(int frame) {
  final b = Buf(10, 8);
  final c = _h('#EEF2F8');
  final s = frame % 2 == 0 ? 0 : 1;
  b.px(2 + s, 6, c);
  b.px(3 - s, 4, c);
  b.px(2 + s, 2, c);
  b.px(7 - s, 5, c);
  b.px(6 + s, 3, c);
  b.px(7 - s, 1, c);
  return b.done();
}

/// Kitchen cooking flame puff in the hatch: 12 x 10.
Sprite mkLlama(int frame) {
  final b = Buf(12, 10);
  final f = frame % 2 == 0 ? 0 : 1;
  b.ell(6, 7 - f, 4.2, 3, _ramp(const ['#E85820', '#F8A028', '#FFE870']));
  b.ell(4, 5 + f, 2, 2.5, _ramp(const ['#F8A028', '#FFF8C0']));
  b.ell(8, 5, 2, 2.2, _ramp(const ['#F8A028', '#FFF8C0']));
  return b.done();
}

/// Celebration star for 3-of-3 ending: 9 x 9.
Sprite mkEstrellaPedido() => _mk(9, 9, (b) {
  final y = _h('#FFE040'), hi = _h('#FFF8C0');
  b.rect(4, 1, 1, 7, y);
  b.rect(1, 4, 7, 1, y);
  b.rect(3, 3, 3, 3, y);
  b.px(2, 2, y);
  b.px(6, 2, y);
  b.px(2, 6, y);
  b.px(6, 6, y);
  b.px(4, 4, hi);
});

/// Directional gesture target cue: 9 x 7.
/// - `self: true`: mint/gold self-highlight diamond (e.g. Luis pointing at himself for "para mí").
/// - `up: true`: golden upward pointer arrow (for board/panel targets, placed below the board).
/// - default: golden downward pointer arrow (placed above a person's head or thing).
Sprite mkGestoFlecha({bool self = false, bool up = false}) => _mk(9, 7, (b) {
  if (self) {
    final fill = _h('#68E8A0'), hi = _h('#FFF8C0');
    b.px(4, 1, hi);
    b.rect(3, 2, 3, 1, hi);
    b.rect(2, 3, 5, 1, fill);
    b.rect(3, 4, 3, 1, fill);
    b.px(4, 5, fill);
    return;
  }
  final gold = _h('#FFE040'), hi = _h('#FFF8C0');
  if (up) {
    b.px(4, 1, hi);
    b.rect(3, 2, 3, 1, hi);
    b.rect(2, 3, 5, 1, gold);
    b.rect(3, 4, 3, 2, gold);
  } else {
    b.rect(3, 1, 3, 2, hi);
    b.rect(2, 3, 5, 1, gold);
    b.rect(3, 4, 3, 1, gold);
    b.px(4, 5, gold);
  }
});

/// Celebration heart for 3-of-3 ending: 11 x 10.
Sprite mkCorazonPedido() => _mk(11, 10, (b) {
  final r = _h('#E44650'), hi = _h('#FFA0A8');
  b.rect(2, 1, 2, 2, r);
  b.rect(7, 1, 2, 2, r);
  b.rect(1, 2, 9, 3, r);
  b.rect(2, 5, 7, 2, r);
  b.rect(3, 7, 5, 1, r);
  b.rect(4, 8, 3, 1, r);
  b.px(5, 9, r);
  b.px(2, 2, hi);
});

/// All El pedido sprites with names for the content lane's sprite sheet (`tool/make_pedido_sprites_test.dart`).
List<(String, Sprite)> pedidoSpritesSheet() => [
  ('cocinero', mkCocinero()),
  ('cocinero guina', mkCocinero(guina: true)),
  ('cocinero platano', mkCocinero(prop: 'platano')),
  ('cocinero sarten', mkCocinero(prop: 'sarten')),
  ('cocinero prensa', mkCocinero(prop: 'prensa')),
  ('cocinero pilon', mkCocinero(prop: 'pilon')),
  ('cocinero 3 platanos', mkCocinero(prop: 'tres_platanos')),
  ('mesera', mkMesera()),
  ('mesera pad', mkMesera(pad: true)),
  ('mesera plato', mkMesera(plato: 'carne')),
  ('mesero', mkMesero()),
  ('mesero abanico', mkMesero(abanico: true)),
  ('mesero sorbo', mkMesero(sorbo: true)),
  ('abuela senala izq', mkAbuelaPedido('senala_izq', false)),
  ('abuela senala der', mkAbuelaPedido('senala_der', false)),
  ('coqui plato carne', mkCoquiPlato('carne')),
  ('gato sit', mkGatoPedido('sit')),
  ('gato mira', mkGatoPedido('mira')),
  ('gato pata', mkGatoPedido('pata')),
  ('gato lame', mkGatoPedido('lame')),
  ('gato duerme', mkGatoPedido('duerme')),
  ('pic sopa', mkCuadroPic('sopa')),
  ('pic sopa lit', mkCuadroPic('sopa', lit: true)),
  ('pic carne', mkCuadroPic('carne')),
  ('pic pescado', mkCuadroPic('pescado')),
  ('pic ensalada', mkCuadroPic('ensalada')),
  ('pic carne tostones', mkCuadroPic('carne_tostones')),
  ('pic carne mofongo', mkCuadroPic('carne_mofongo')),
  ('pic pescado tostones', mkCuadroPic('pescado_tostones')),
  ('pic pescado mofongo', mkCuadroPic('pescado_mofongo')),
  ('pic refresco', mkCuadroPic('refresco')),
  ('pic limonada', mkCuadroPic('limonada')),
  ('pic jugo', mkCuadroPic('jugo')),
  ('pic cafe', mkCuadroPic('cafe')),
  ('orden sopa', mkOrdenBurbuja('sopa')),
  ('orden carne', mkOrdenBurbuja('carne')),
  ('orden pescado', mkOrdenBurbuja('pescado')),
  ('orden ensalada', mkOrdenBurbuja('ensalada')),
  ('plato sopa', mkPlato('sopa')),
  ('plato carne', mkPlato('carne')),
  ('plato pescado', mkPlato('pescado')),
  ('plato ensalada', mkPlato('ensalada')),
  ('plato tostones', mkPlato('tostones')),
  ('plato mofongo', mkPlato('mofongo')),
  ('plato carne tostones', mkPlato('carne_tostones')),
  ('plato carne mofongo', mkPlato('carne_mofongo')),
  ('plato pescado tostones', mkPlato('pescado_tostones')),
  ('plato pescado mofongo', mkPlato('pescado_mofongo')),
  ('platito 3', mkPlatito(3)),
  ('platito 2', mkPlatito(2)),
  ('platito 1', mkPlatito(1)),
  ('platito 0', mkPlatito(0)),
  ('plato rana 0', mkPlatoRana(0)),
  ('plato rana 1', mkPlatoRana(1)),
  ('plato rana 2', mkPlatoRana(2)),
  ('plato rana 3', mkPlatoRana(3)),
  ('platanos 3', mkPlatanos(3)),
  ('platanos 2', mkPlatanos(2)),
  ('platanos 1', mkPlatanos(1)),
  ('platanos 0', mkPlatanos(0)),
  ('bebida refresco', mkBebida('refresco')),
  ('bebida limonada', mkBebida('limonada')),
  ('bebida cafe', mkBebida('cafe')),
  ('vasito 3', mkVasito(3)),
  ('vasito 2', mkVasito(2)),
  ('vasito 1', mkVasito(1)),
  ('vasito 0', mkVasito(0)),
  ('campana brillo', mkCampanaBrillo(0)),
  ('vapor', mkVapor(0)),
  ('llama', mkLlama(0)),
  ('gesto flecha', mkGestoFlecha()),
  ('gesto flecha up', mkGestoFlecha(up: true)),
  ('gesto flecha self', mkGestoFlecha(self: true)),
  ('estrella', mkEstrellaPedido()),
  ('corazon', mkCorazonPedido()),
];
