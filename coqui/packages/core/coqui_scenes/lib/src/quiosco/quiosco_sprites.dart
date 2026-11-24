// The sprites El quiosco adds to La plaza's cast (plaza_cast.dart):
// - El patio's `nino` and `nina` (quiosco.md 68, quiosco-preview.html outfits), plus Beto's paper crown (on & flying),
//   the señor wearing the cocinero's tall hat (story 67 step 3), and the vendedor's paper hat for Coquí (story 67 end);
// - Story 66: glass dome with 3..0 quesitos, quesito on a saucer (whole / piece), frog's tray with café / jugo de china /
//   vaso de leche (upright or tipped over & spilled), police whistle puff;
// - Story 67: box with lid on / off / turned empty, the 7 forgotten items (12 × 12 over the frog's head: libro, gorro,
//   estetoscopio, libretas, gorra, bulto, delantal), 3 limbers (red, yellow, white) frosty or melted;
// - Story 68: cake stand with Beto's tower of 3..1 bizcochos (with unlit / lit / blown-out 5 candle), number candles 1..12
//   (8 × 12, two-digit 10..12 drawn cleanly side by side), candle tray (28 × 4), small bizcocho (whole / broken),
//   hand-held fingers badge (3 or 5) and candle puff.
// Every sprite is drawn with engine.js Buf (ramps + OUT outline) and verified on docs/proyecto/pixel/port/quiosco-sprites.png.
// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/src/colmado/colmado_cast.dart'
    show canvasSprite, overSprite;
import 'package:coqui_scenes/src/plaza/plaza_cast.dart'
    show cropTop, mkPlazaPersona, plazaExtra;

int _h(String s) => hexColour(s);
List<int> _hs(List<String> s) => [for (final x in s) hexColour(x)];

/* ---------- extra cast members & headgear ---------- */

/// `nino` and `nina` of El patio (quiosco-preview.html outfits).
final Map<String, Who> QUIOSCO_NINOS = {
  'nino': Who(
    nino: true,
    piel: PIEL['b']!,
    pelo: PELO['castano']!,
    peinado: 'corto',
    ropa: RP.orng,
    abajo: RP.blue,
    zapato: _h('#F2F2F8'),
  ),
  'nina': Who(
    nino: true,
    piel: PIEL['c']!,
    pelo: PELO['negro']!,
    peinado: 'trenzas',
    ropa: RP.red,
    falda: true,
    lazo: _h('#FFE070'),
    zapato: _h('#F2F2F8'),
  ),
};

(String, bool, bool) _ninoPose(String pose, bool open) => switch (pose) {
  'saluda0' || 'llama0' => ('wave0', open || pose == 'llama0', false),
  'saluda1' || 'llama1' => ('wave1', open || pose == 'llama1', false),
  'mano' => ('offer', open, false),
  'senala' => ('tu', open, false),
  'hombros' => ('ojos', open, false),
  'rie' => ('yo', true, false),
  'sienta' || 'arrodilla' => ('idle', open, true),
  _ => ('idle', open, false),
};

/// Draws a person of El quiosco (`nino`, `nina`, or any person in `plaza_cast.dart`), optionally adding Beto's gold
/// paper crown (`corona: true`) or the chef hat on the señor (`gorroCocinero: true`).
Sprite mkQuioscoPersona(
  String id,
  String pose, {
  bool open = false,
  bool corona = false,
  bool gorroCocinero = false,
}) {
  Sprite base;
  if (QUIOSCO_NINOS.containsKey(id)) {
    final (kp, op, sent) = _ninoPose(pose, open);
    base = cropTop(mkPersona(QUIOSCO_NINOS[id]!, kp, op, sent));
  } else {
    base = mkPlazaPersona(id, pose, open: open);
  }
  if (!corona && !gorroCocinero) return base;
  const pad = 12;
  final s = canvasSprite(base.w, base.h + pad, (g) {
    g.drawImage(base, 0, pad);
    if (corona) {
      // gold paper birthday crown perched on Beto's head
      final cr = mkCorona();
      g.drawImage(cr, PX - cr.w ~/ 2, pad - 5);
    }
    if (gorroCocinero) {
      // tall white chef hat worn by the señor after story 67 step 3
      plazaExtra(g, 'gorro_cocinero', PX, pad + 11, 1, base.h);
    }
  });
  return cropTop(s);
}

/// Beto's gold paper birthday crown (14 × 8), worn on his head or flying off when he blows out the candle.
Sprite mkCorona() {
  final b = Buf(14, 8);
  final g0 = _h('#C08814'), g1 = _h('#F0C028'), g2 = _h('#FFF08A');
  b.rect(2, 4, 10, 3, g1);
  b.rect(2, 6, 10, 1, g0);
  // three peaks
  b.rect(2, 2, 2, 2, g1);
  b.px(2, 1, g2);
  b.rect(6, 1, 2, 3, g2);
  b.rect(10, 2, 2, 2, g1);
  b.px(11, 1, g2);
  // red jewel in middle
  b.px(6, 5, _h('#D83830'));
  b.px(7, 5, _h('#F86A5A'));
  return b.outline().done();
}

/// The vendedor's folded white paper hat (14 × 8), placed on Coquí's head at the end of story 67.
Sprite mkGorroPapelCoqui() {
  final b = Buf(14, 8);
  b.rect(2, 2, 10, 5, _h('#FFFFFF'));
  b.rect(2, 5, 10, 2, _h('#D8D8E4'));
  b.rect(1, 5, 12, 2, _h('#E8E8F2'));
  b.rect(3, 1, 8, 1, _h('#FFFFFF'));
  b.rect(2, 4, 10, 1, _h('#D03830'));
  return b.outline().done();
}

/* ---------- Story 66: glass dome, quesitos, frog's tray & drinks ---------- */

/// The glass dome on the counter (`barra_izq`, 20 × 18), holding [n] (0..3) golden quesitos, optionally lifted (`abierta`).
Sprite mkCupula(int n, {bool abierta = false}) {
  final b = Buf(20, 18);
  // ceramic plate base
  b.rect(1, 14, 18, 3, _h('#D8D8E4'));
  b.rect(2, 14, 16, 1, _h('#F6F6FA'));
  // glass dome (omitted when lifted at ending)
  if (!abierta) {
    b.ell(10, 12, 8.4, 10.6, _hs(['#9CCBDE', '#BCE4F4', '#DDF1FA']));
    b.rect(2, 12, 16, 2, _h('#BCE4F4'));
    // top knob
    b.rect(9, 1, 2, 2, _h('#DDF1FA'));
    // glass highlight streak
    b.rect(5, 5, 1, 4, _h('#FFFFFF'));
    b.px(6, 4, _h('#FFFFFF'));
  }
  // golden flaky quesitos sitting on the plate
  const xs = [5, 10, 15];
  final count = n.clamp(0, 3);
  for (var i = 0; i < count; i++) {
    final x = xs[i];
    b.ell(x.toDouble(), 12.2, 2.5, 2.0, _hs(['#B8741C', '#E49E32', '#F8CC62']));
    b.px(x - 1, 11, _h('#FFFBEA'));
  }
  // front plate rim
  b.rect(1, 14, 18, 3, _h('#D8D8E4'));
  b.rect(2, 14, 16, 1, _h('#F6F6FA'));
  return b.outline().done();
}

/// A quesito served on a little white saucer (12 × 8); [trozo] draws a smaller broken piece.
Sprite mkQuesitoPlato({bool trozo = false}) {
  final b = Buf(12, 8);
  b.rect(1, 5, 10, 2, _h('#E4E4EE'));
  b.rect(2, 5, 8, 1, _h('#FFFFFF'));
  if (trozo) {
    b.ell(6, 4, 2.0, 1.5, _hs(['#B8741C', '#E49E32', '#F8CC62']));
    b.px(5, 3, _h('#FFFBEA'));
  } else {
    b.ell(6, 3.8, 3.3, 2.1, _hs(['#B8741C', '#E49E32', '#F8CC62']));
    b.rect(4, 2, 3, 1, _h('#FFFBEA'));
  }
  return b.outline().done();
}

/// Coquí's tray (22 × 10) carrying [que] (`cafe`, `jugo`, `leche`, or `null` empty), upright or tipped over (`derramado`).
Sprite mkBandejaRana(String? que, {bool derramado = false}) {
  final b = Buf(22, 10);
  // metal tray
  b.rect(1, 6, 20, 3, _h('#B8B8C8'));
  b.rect(2, 6, 18, 1, _h('#F2F2F8'));
  if (que == null) return b.outline().done();
  final liq = switch (que) {
    'jugo' => _h('#F49622'),
    'leche' => _h('#FFFDF4'),
    _ => _h('#6A3A1A'),
  };
  if (derramado) {
    // tipped cup lying on its side with puddle spreading across the tray
    b.rect(2, 6, 10, 2, liq);
    b.rect(11, 3, 5, 4, _h('#F6F6FA'));
    b.rect(11, 4, 1, 2, liq);
    b.px(16, 4, _h('#D8D8E4'));
  } else if (que == 'cafe') {
    // white coffee mug with handle and dark coffee top
    b.rect(8, 1, 6, 5, _h('#FFFFFF'));
    b.rect(9, 1, 4, 1, liq);
    b.rect(14, 2, 2, 3, _h('#E4E4EE'));
    b.px(14, 3, _h('#B8B8C8'));
  } else {
    // tall glass of orange juice or milk
    b.rect(8, 1, 6, 5, _h('#D8EEFA'));
    b.rect(9, 2, 4, 4, liq);
    b.px(9, 2, _h('#FFFFFF'));
  }
  return b.outline().done();
}

/// A small musical puff when the policía blows his whistle (10 × 8).
Sprite mkPitoOnda(int f) {
  final b = Buf(10, 8);
  final c = f == 0 ? _h('#FFE070') : _h('#FFFFFF');
  b.rect(2, 3, 2, 2, c);
  b.rect(5, 2 - f, 2, 1, c);
  b.rect(5, 5 + f, 2, 1, c);
  b.px(8, 3, c);
  return b.outline().done();
}

/* ---------- Story 67: box, 7 forgotten things, 3 limbers ---------- */

/// The lost-and-found box at `barra_fin` (16 × 12): `cerrada` (lid on), `abierta` (lid off), or `vacia` (upside down).
Sprite mkCajaQuiosco(String estado) {
  final b = Buf(16, 12);
  final w0 = _h('#8E5A28'), w1 = _h('#C4823A'), w2 = _h('#E2A85A');
  if (estado == 'vacia') {
    // turned upside down and empty
    b.rect(1, 3, 14, 8, w1);
    b.rect(1, 3, 14, 2, w2);
    b.rect(2, 9, 12, 2, w0);
  } else if (estado == 'abierta') {
    // open box with dark interior rim showing
    b.rect(1, 4, 14, 7, w1);
    b.rect(2, 2, 12, 2, _h('#3C2414'));
    b.rect(1, 4, 14, 1, w2);
    b.rect(7, 4, 2, 7, w0);
  } else {
    // lid firmly on
    b.rect(1, 3, 14, 8, w1);
    b.rect(1, 3, 14, 1, w2);
    b.rect(1, 1, 14, 2, w2);
    b.rect(7, 1, 2, 10, w0);
  }
  return b.outline().done();
}

/// One of the 7 forgotten items held over Coquí's head in story 67 (12 × 12, sheet standin `cosa_cabeza`):
/// `libro`, `gorro`, `estetoscopio`, `libretas`, `gorra`, `bulto`, `delantal`.
Sprite mkCosa67(String cosa) {
  final b = Buf(12, 12);
  switch (cosa) {
    case 'libro':
      // thick blue university book with cream pages
      b.rect(1, 1, 10, 10, _h('#2E6CD0'));
      b.rect(1, 1, 10, 2, _h('#78B0F6'));
      b.rect(2, 4, 8, 6, _h('#FBF0D2'));
      b.rect(2, 4, 8, 1, _h('#B89A6A'));
    case 'gorro':
      // tall pleated white chef's hat
      b.ell(4, 3.5, 2.5, 2.3, _hs(['#D8D8E4', '#FFFFFF']));
      b.ell(8, 3.5, 2.5, 2.3, _hs(['#D8D8E4', '#FFFFFF']));
      b.ell(6, 2.8, 2.8, 2.2, _hs(['#E8E8F2', '#FFFFFF']));
      b.rect(3, 5, 6, 5, _h('#F4F4FA'));
      b.rect(3, 8, 6, 2, _h('#D8D8E4'));
    case 'estetoscopio':
      // doctor's stethoscope with earpieces and metallic chest-piece
      final g = _h('#4A5468');
      b.rect(2, 2, 2, 4, g);
      b.rect(8, 2, 2, 4, g);
      b.px(2, 1, _h('#E4E4EE'));
      b.px(9, 1, _h('#E4E4EE'));
      b.rect(3, 6, 6, 1, g);
      b.rect(5, 7, 2, 2, g);
      b.ell(6, 9.5, 2.0, 1.8, _hs(['#8A94A8', '#D8E0EC']));
    case 'libretas':
      // stack of exercise books with a red apple on top
      b.rect(1, 8, 10, 2, _h('#4A70C0'));
      b.rect(1, 6, 10, 2, _h('#5AB46A'));
      b.rect(1, 6, 10, 1, _h('#F4F4F8'));
      b.rect(1, 8, 10, 1, _h('#F4F4F8'));
      b.ell(6, 3.5, 2.4, 2.2, _hs(['#9A1A1A', '#D8342A', '#F46A5A']));
      b.px(6, 1, _h('#5AB46A'));
    case 'gorra':
      // blue police cap with gold badge and silver whistle beside it
      b.rect(2, 2, 8, 4, _h('#24407A'));
      b.rect(3, 2, 6, 1, _h('#4A70C0'));
      b.rect(1, 5, 10, 2, _h('#141E40'));
      b.rect(5, 3, 2, 2, _h('#F0C020'));
      // silver whistle below
      b.rect(3, 8, 5, 2, _h('#D8E0EC'));
      b.px(8, 9, _h('#8A94A8'));
    case 'bulto':
      // student's school bag with books peeking out
      b.rect(2, 3, 8, 8, _h('#D86828'));
      b.rect(2, 3, 8, 3, _h('#F08A3C'));
      b.rect(4, 1, 4, 2, _h('#924014'));
      b.rect(3, 7, 6, 3, _h('#B8501C'));
      b.rect(5, 6, 2, 2, _h('#F0C020'));
    case 'delantal':
      // shopkeeper's teal apron with pocket and straps
      b.rect(3, 1, 1, 3, _h('#288A82'));
      b.rect(8, 1, 1, 3, _h('#288A82'));
      b.rect(2, 3, 8, 8, _h('#3EB4A8'));
      b.rect(2, 3, 2, 8, _h('#68D4C8'));
      b.rect(4, 7, 4, 3, _h('#288A82'));
    default:
      b.rect(2, 2, 8, 8, _h('#F0C020'));
  }
  return b.outline().done();
}

/// One limber cup (6 × 7): `rojo`, `amarillo`, or `blanco`, either frosty (`derretido: false`) or melted into its cup.
Sprite mkLimber(String color, {bool derretido = false}) {
  final b = Buf(6, 7);
  final c = switch (color) {
    'rojo' => _h('#D83834'),
    'amarillo' => _h('#F8C838'),
    _ => _h('#F2F2F8'),
  };
  final cHi = switch (color) {
    'rojo' => _h('#F87A72'),
    'amarillo' => _h('#FFF098'),
    _ => _h('#FFFFFF'),
  };
  if (derretido) {
    // melted flat liquid low inside the clear cup
    b.rect(1, 3, 4, 3, _h('#D4E6F0'));
    b.rect(1, 4, 4, 2, c);
    b.rect(2, 5, 2, 1, _h('#F2F2F8'));
  } else {
    // tall frosty frozen limber mound rising above the cup
    b.rect(1, 1, 4, 5, c);
    b.rect(1, 1, 4, 1, cHi);
    b.rect(1, 4, 4, 2, _h('#E4EAF2'));
    b.rect(2, 5, 2, 1, _h('#FFFFFF'));
  }
  return b.outline().done();
}

/* ---------- Story 68: cake stand tower, number candles 1..12, bizcochos ---------- */

/// The cake stand at `barra_izq` (22 × 28) with Beto's tower of [n] (1..3) frosted bizcochos.
/// [vela5]: whether the 5 candle stands on top; [encendida]: flame lit; [humo]: smoke wisp after blowing it out.
Sprite mkTorre68(
  int n, {
  bool vela5 = false,
  bool encendida = false,
  bool humo = false,
}) {
  final b = Buf(22, 28);
  // silver cake stand pedestal
  b.ell(11, 25.5, 8.5, 1.4, [_h('#D8D8E4')]);
  b.rect(10, 20, 2, 6, _h('#B8B8C8'));
  b.ell(11, 20, 9.2, 1.6, [_h('#F2F2F8')]);

  final count = n.clamp(1, 3);
  final cCake = _h('#E2A85A'), cCake2 = _h('#F4CC88'), cIce = _h('#FFFBEA');
  // bottom tier (always present)
  b.rect(3, 14, 16, 6, cCake);
  b.rect(3, 14, 16, 2, cIce);
  var topY = 14;
  if (count >= 2) {
    b.rect(5, 9, 12, 5, cCake2);
    b.rect(5, 9, 12, 2, cIce);
    topY = 9;
  }
  if (count >= 3) {
    b.rect(7, 4, 8, 5, cCake);
    b.rect(7, 4, 8, 2, cIce);
    topY = 4;
  }
  if (vela5) {
    // small red 5-candle standing on the top tier
    final vy = (topY - 3).clamp(1, 20);
    b.rect(10, vy, 2, 3, _h('#D0403A'));
    if (encendida && vy > 0) {
      b.rect(10, vy - 1, 2, 1, _h('#FFE070'));
    } else if (humo && vy > 0) {
      b.px(11, vy - 1, _h('#C8D4E0'));
    }
  }
  return b.outline().done();
}

/// The silver tray under `vela_a..c` (28 × 4, sheet standin `bandeja_velas`).
Sprite mkBandejaVelas() {
  final b = Buf(28, 4);
  b.rect(1, 1, 26, 2, _h('#C8C8D4'));
  b.rect(1, 1, 26, 1, _h('#F2F2F8'));
  return b.outline().done();
}

// 3×5 crisp pixel digits for number candles 0..9
const List<List<String>> _DIG3 = [
  ['###', '#.#', '#.#', '#.#', '###'], // 0
  ['.#.', '##.', '.#.', '.#.', '###'], // 1
  ['###', '..#', '###', '#..', '###'], // 2
  ['###', '..#', '###', '..#', '###'], // 3
  ['#.#', '#.#', '###', '..#', '..#'], // 4
  ['###', '#..', '###', '..#', '###'], // 5
  ['###', '#..', '###', '#.#', '###'], // 6
  ['###', '..#', '..#', '.#.', '.#.'], // 7
  ['###', '#.#', '###', '#.#', '###'], // 8
  ['###', '#.#', '###', '..#', '###'], // 9
];

void _drawDigit(Buf b, int d, int x0, int y0, int col) {
  final g = _DIG3[d.clamp(0, 9)];
  for (var y = 0; y < 5; y++) {
    for (var x = 0; x < 3; x++) {
      if (g[y][x] == '#') b.px(x0 + x, y0 + y, col);
    }
  }
}

/// A number candle for [n] (1..12) in slot colour [slot] (`a`, `b`, `c`) — 8 × 12 (sheet standin `vela_a..c`).
/// Two-digit numbers (10, 11, 12) draw two side-by-side miniature digits inside the 8 × 12 candle badge.
Sprite mkVelaNumero(int n, String slot) {
  final b = Buf(8, 12);
  final bg = switch (slot) {
    'a' => _h('#D0403A'),
    'b' => _h('#2E9A48'),
    _ => _h('#4A8CE8'),
  };
  final fg = _h('#FFFDF4');
  // flame / wick at top
  b.rect(3, 1, 2, 2, _h('#FFE070'));
  // candle body
  b.rect(1, 3, 6, 8, bg);
  final v = n.clamp(0, 12);
  if (v < 10) {
    _drawDigit(b, v, 2, 5, fg);
  } else {
    // 10, 11, 12: thin '1' at x=1 plus second digit at x=3..5
    for (var y = 5; y < 10; y++) {
      b.px(1, y, fg);
    }
    _drawDigit(b, v % 10, 3, 5, fg);
  }
  return b.outline().done();
}

/// A small frosted bizcocho (10 × 8), either whole (optionally with a candle) or broken in two pieces (`roto: true`).
Sprite mkBizcocho({bool roto = false, bool vela = false}) {
  final b = Buf(10, 8);
  final cCake = _h('#E2A85A'), cIce = _h('#FFFBEA');
  if (roto) {
    // broken into two halves on the counter/ground
    b.rect(1, 4, 3, 3, cCake);
    b.rect(1, 4, 3, 1, cIce);
    b.rect(6, 4, 3, 3, cCake);
    b.rect(6, 4, 3, 1, cIce);
  } else {
    b.rect(2, 3, 6, 4, cCake);
    b.rect(2, 3, 6, 1, cIce);
    if (vela) {
      b.rect(4, 1, 2, 2, _h('#D0403A'));
      b.px(4, 0, _h('#FFE070'));
    }
  }
  return b.outline().done();
}

/// Fingers badge held up during `gesto(dedos, n: 3 | 5)` (10 × 10).
Sprite mkDedos(int n) {
  final b = Buf(10, 10);
  final skin = _h('#F4C698'), bg = _h('#2E9A48');
  b.rect(1, 1, 8, 8, n == 3 ? bg : _h('#FFF0C8'));
  final count = n.clamp(1, 5);
  final startX = 5 - count;
  for (var i = 0; i < count; i++) {
    b.rect(startX + i * 2, 2, 1, 4, n == 3 ? _h('#8AE070') : skin);
  }
  b.rect(2, 6, 6, 2, n == 3 ? _h('#60C450') : skin);
  return b.outline().done();
}

/// Coquí with the vendedor's paper hat on (used as an overlay helper for the sprite sheet).
Sprite mkCoquiGorroPreview() =>
    overSprite(mkCoqui(1, 0, false), [(mkGorroPapelCoqui(), 9, -2)]);

/// Every sprite this file draws, for `tool/make_quiosco_sprites_test.dart` -> `docs/proyecto/pixel/port/quiosco-sprites.png`.
List<(String, Sprite)> quioscoSpritesSheet() => [
  ('nino idle', mkQuioscoPersona('nino', 'idle')),
  ('nina idle', mkQuioscoPersona('nina', 'idle')),
  ('beto corona', mkQuioscoPersona('beto', 'sienta', corona: true)),
  ('senor gorro', mkQuioscoPersona('senor', 'sienta', gorroCocinero: true)),
  ('corona', mkCorona()),
  ('gorro papel', mkGorroPapelCoqui()),
  ('cupula 3', mkCupula(3)),
  ('cupula 2', mkCupula(2)),
  ('cupula 1', mkCupula(1)),
  ('cupula abierta', mkCupula(0, abierta: true)),
  ('quesito plato', mkQuesitoPlato()),
  ('quesito trozo', mkQuesitoPlato(trozo: true)),
  ('bandeja vacia', mkBandejaRana(null)),
  ('bandeja cafe', mkBandejaRana('cafe')),
  ('bandeja jugo', mkBandejaRana('jugo')),
  ('bandeja leche', mkBandejaRana('leche')),
  ('bandeja derramada', mkBandejaRana('cafe', derramado: true)),
  ('pito onda', mkPitoOnda(0)),
  ('caja cerrada', mkCajaQuiosco('cerrada')),
  ('caja abierta', mkCajaQuiosco('abierta')),
  ('caja vacia', mkCajaQuiosco('vacia')),
  for (final k in const [
    'libro',
    'gorro',
    'estetoscopio',
    'libretas',
    'gorra',
    'bulto',
    'delantal',
  ])
    ('cosa $k', mkCosa67(k)),
  ('limber rojo', mkLimber('rojo')),
  ('limber amarillo', mkLimber('amarillo')),
  ('limber blanco', mkLimber('blanco')),
  ('limber derretido', mkLimber('rojo', derretido: true)),
  ('torre 3', mkTorre68(3)),
  ('torre 3 vela 5', mkTorre68(3, vela5: true, encendida: true)),
  ('torre 2', mkTorre68(2, vela5: true)),
  ('torre 1', mkTorre68(1, vela5: true, humo: true)),
  ('bandeja velas', mkBandejaVelas()),
  for (var i = 1; i <= 12; i++)
    ('vela $i', mkVelaNumero(i, i % 3 == 1 ? 'a' : (i % 3 == 2 ? 'b' : 'c'))),
  ('bizcocho', mkBizcocho(vela: true)),
  ('bizcocho roto', mkBizcocho(roto: true)),
  ('dedos 5', mkDedos(5)),
  ('dedos 3', mkDedos(3)),
];
