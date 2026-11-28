// Scene-specific sprites and cast outfits of La noche (place 9, La casa, un día entero, scene 4: `noche`,
// order 73):
// - Preview-matching core props (noche-preview.html, exact dimensions matching noche-sheet.json):
//   jugo (10 x 10), flan (10 x 10), queso (10 x 10), frutas (10 x 10), vela (6 x 14: 3/2/1 lengths + flame),
//   bufanda (12 x 8: 3/2/1 stripes), lana (8 x 8), libro (12 x 8: 3/2/1 pages).
// - Lying-in-bed composite sprite (noche-preview.html `lying` + noche-sheet.json `things.cama`).
// - Additional Needs sprites (historia/notas/guiones/noche.md):
//   relojHands (14 x 14), tapaVapor (22 x 10), bufandaCuello (18 x 8: 3/2/1 stripes),
//   mesaLampara (8 x 12), libroPic (12 x 12: bote/estrella/rana), nota (7 x 9),
//   manosCue (12 x 8: sucias/limpias), perroNariz (10 x 8), periodico (14 x 10),
//   estrellasNoche (15 x 9), corazonNoche (11 x 10).
// - Cast outfits (`NOCHE_WHO`), matching noche-preview.html + pyjama outfits for stories 105 & 107.
// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/src/colmado/colmado_cast.dart' show inkBottom;

int _h(String s) => hexColour(s);

List<int> _ramp(List<String> hs) => [for (final s in hs) _h(s)];

Sprite _mk(int w, int h, void Function(Buf b) draw, {bool outline = true}) {
  final b = Buf(w, h);
  draw(b);
  return outline ? b.outline().done() : b.done();
}

/// First row of [s] with any opaque pixel (noche-preview.html `inkTop`).
int inkTop(Sprite s) {
  for (var y = 0; y < s.h; y++) {
    for (var x = 0; x < s.w; x++) {
      if (s.px[y * s.w + x] >>> 24 != 0) return y;
    }
  }
  return 0;
}

/* ---------- Cast outfits (noche-preview.html + night pyjamas) ---------- */

final Who _LUIS_PIJAMA = Who(
  piel: FAM['hermano']!.piel,
  pelo: FAM['hermano']!.pelo,
  peinado: FAM['hermano']!.peinado,
  ropa: _ramp(const ['#5874B8', '#7896DA', '#9AB6F4', '#BED2FF']),
  abajo: _ramp(const ['#465C98', '#5E78BC', '#7E98DC']),
  nino: true,
  zapato: _h('#D8D8E4'),
);

final Who _CARMEN_PIJAMA = Who(
  piel: FAM['hermana']!.piel,
  pelo: FAM['hermana']!.pelo,
  peinado: FAM['hermana']!.peinado,
  ropa: _ramp(const ['#8A5AA8', '#AA76C8', '#C696E4', '#DFBAFA']),
  abajo: _ramp(const ['#6E448A', '#8A5AA8', '#A878C6']),
  nino: true,
  lazo: FAM['hermana']!.lazo,
  zapato: _h('#D8D8E4'),
);

/// Cast definitions for La noche (`FAM` + night pyjama outfits for stories 105 and 107).
final Map<String, Who> NOCHE_WHO = {
  'abuelo': FAM['abuelo']!,
  'luis': FAM['hermano']!,
  'carmen': FAM['hermana']!,
  'luis_pijama': _LUIS_PIJAMA,
  'carmen_pijama': _CARMEN_PIJAMA,
};

/// Resting feet-up pose for `descansa107` on the sofa: removes dangling legs below the lap
/// and draws outstretched legs with shoes resting up on the cushion.
Sprite mkPersonaFeetUp(Who who, bool open) {
  final base = mkPersona(who, 'idle', open, true);
  final t = who.nino ? 7 : 11;
  final hc = 16 + 2 * t;
  final legRamp = who.abajo ?? who.ropa;
  final shoe = who.zapato ?? _h('#3A2414');
  final outline = _h('#221414');
  final b = Buf(base.w, base.h);
  // Keep upper body, arms, and upper hip/lap; omit dangling lower legs & shoes.
  for (var py = 0; py < math.min(base.h, hc + 2); py++) {
    for (var qx = 0; qx < base.w; qx++) {
      final c = base.px[py * base.w + qx];
      if (c >>> 24 != 0) b.px(qx, py, c);
    }
  }
  // Bottom outline under the raised hips.
  b.rect(PX - (who.nino ? 6 : 8), hc + 1, who.nino ? 13 : 17, 1, outline);
  // Outstretched legs resting up along the cushion to the right, plus upright shoes.
  final legLen = who.nino ? 9 : 12;
  b.rect(PX + 1, hc - 3, legLen + 2, 5, outline);
  b.rect(PX + 1, hc - 2, legLen + 1, 3, legRamp[1]);
  b.rect(PX + 2, hc - 2, legLen, 1, legRamp[2]);
  b.rect(PX + legLen, hc - 6, 5, 8, outline);
  b.rect(PX + legLen + 1, hc - 5, 3, 6, shoe);
  b.px(PX + legLen + 2, hc - 5, _h('#8E7A6A'));
  return b.done();
}

/* ---------- Lying-in-bed sprite (noche-preview.html `lying`) ---------- */

/// Builds the clipped lying-in-bed sprite with blanket for [who] at spot screen `(sx, sy)` and [camaMeta].
Sprite mkLyingChild({
  required Who who,
  required int sx,
  required int sy,
  required int footY,
  required int blanketW,
  required int blanketCenterX,
  required List<int> blanketColour,
  bool open = false,
}) {
  final p = mkPersona(who, 'idle', open, false);
  final top = inkTop(p);
  const chest = 24;
  final footRel = math.max(1, footY - sy);
  final dx = blanketCenterX - sx;
  const ax = 50;
  const w = 100;
  final h = footRel + 1;
  final px = Uint32List(w * h);

  // Draw standing child clipped to y < footRel, aligned at (ax - PX, -top).
  final ox = ax - PX;
  final oy = -top;
  for (var py = 0; py < p.h; py++) {
    final dstY = oy + py;
    if (dstY < 0 || dstY >= footRel) continue;
    for (var qx = 0; qx < p.w; qx++) {
      final col = p.px[py * p.w + qx];
      if (col >>> 24 == 0) continue;
      final dstX = ox + qx;
      if (dstX < 0 || dstX >= w) continue;
      px[dstY * w + dstX] = col;
    }
  }

  // Blanket from chest row down to footRel.
  final c0 = chest - top;
  if (c0 < footRel) {
    final x0 = ax + dx - (blanketW ~/ 2);
    final outline = rgbInt(42, 24, 16);
    final base = rgbInt(blanketColour[0], blanketColour[1], blanketColour[2]);
    final dark = rgbInt(
      math.max(0, blanketColour[0] - 34),
      math.max(0, blanketColour[1] - 34),
      math.max(0, blanketColour[2] - 34),
    );
    final hi = rgbInt(
      math.min(255, blanketColour[0] + 22),
      math.min(255, blanketColour[1] + 22),
      math.min(255, blanketColour[2] + 22),
    );
    void fillRect(int rx, int ry, int rw, int rh, int col) {
      for (var y = ry; y < ry + rh; y++) {
        if (y < 0 || y >= h) continue;
        for (var x = rx; x < rx + rw; x++) {
          if (x < 0 || x >= w) continue;
          px[y * w + x] = col;
        }
      }
    }

    fillRect(x0 - 1, c0 - 1, blanketW + 2, footRel - c0 + 2, outline);
    fillRect(x0, c0, blanketW, footRel - c0, base);
    fillRect(x0, c0, blanketW, 1, hi);
    for (var x = x0 + 4; x < x0 + blanketW - 2; x += 9) {
      fillRect(x, c0 + 2, 1, math.max(0, footRel - c0 - 3), dark);
    }
  }

  return Sprite(w, h, px);
}

int rgbInt(int r, int g, int b) =>
    0xFF000000 | ((b & 0xFF) << 16) | ((g & 0xFF) << 8) | (r & 0xFF);

/* ---------- Preview-matching small props (exact noche-preview.html dimensions) ---------- */

/// 10 x 10 jug of orange juice (noche-preview.html `THING.jugo`).
Sprite mkJugo() => _mk(10, 10, (b) {
  b.rect(2, 3, 5, 6, _h('#F2A650'));
  b.rect(2, 3, 5, 1, _h('#FFE070'));
  b.rect(3, 1, 3, 2, _h('#F4F4FA'));
  b.rect(7, 4, 1, 3, _h('#D8D8E4'));
  b.px(8, 5, _h('#D8D8E4'));
});

/// 10 x 10 flan on its plate with caramel on top (noche-preview.html `THING.flan`).
Sprite mkFlan() => _mk(10, 10, (b) {
  b.ell(5, 7.4, 4.2, 1.6, [_h('#A8A8B8'), _h('#D0D0DC'), _h('#F4F4FA')]);
  b.rect(2, 4, 6, 3, _h('#F6D060'));
  b.rect(2, 3, 6, 1, _h('#B8601C'));
  b.rect(3, 2, 4, 1, _h('#B8601C'));
  b.px(3, 5, _h('#FFE890'));
});

/// 10 x 10 wedge of cheese with holes (noche-preview.html `THING.queso`).
Sprite mkQueso() => _mk(10, 10, (b) {
  for (var y = 2; y < 9; y++) {
    b.rect(1, y, 2 + ((y - 2) * 1.2 + 0.5).floor(), 1, _h('#F6D060'));
  }
  b.rect(1, 8, 8, 1, _h('#C8861C'));
  b.px(3, 6, _h('#C8861C'));
  b.px(5, 7, _h('#C8861C'));
  b.px(2, 4, _h('#C8861C'));
});

/// 10 x 10 bowl of fruit (noche-preview.html `THING.frutas`).
Sprite mkFrutas() => _mk(10, 10, (b) {
  b.ell(3, 4.4, 1.8, 1.8, [_h('#D0403A'), _h('#FA9080')]);
  b.ell(5.6, 3.6, 1.8, 1.8, [_h('#DC8430'), _h('#FBCB86')]);
  b.ell(7.4, 5, 1.6, 1.6, [_h('#389838'), _h('#84DC78')]);
  b.rect(1, 6, 8, 2, _h('#8E806C'));
  b.rect(2, 8, 6, 1, _h('#6A5E50'));
  b.rect(1, 6, 8, 1, _h('#B4A68E'));
});

/// 6 x 14 candle in lengths 3 (tall), 2 (medium), 1 (stub), [lit] or unlit (noche-preview.html `THING.vela`).
Sprite mkVelaNoche({int len = 3, bool lit = true}) => _mk(6, 14, (b) {
  final l = len.clamp(1, 3);
  final bodyH = l == 3 ? 8 : (l == 2 ? 5 : 3);
  final bodyY = 13 - bodyH;
  b.rect(1, bodyY, 4, bodyH, _h('#FBF0D2'));
  b.rect(1, bodyY, 1, bodyH, _h('#EEDCB0'));
  b.rect(4, bodyY, 1, bodyH, _h('#D8BC8A'));
  if (lit) {
    final fy = bodyY - 2;
    b.rect(2, fy, 2, 2, _h('#F2A650'));
    b.px(2, fy - 1, _h('#FFE070'));
    b.px(3, fy - 1, _h('#FFE070'));
    if (fy - 2 >= 1) b.px(2, fy - 2, _h('#FFF4B0'));
    b.px(3, fy, _h('#FFFBEA'));
  } else {
    b.px(2, bodyY - 1, _h('#464044'));
  }
});

/// 12 x 8 knitted scarf with [stripes] (3, 2, or 1) across abuela's hands (noche-preview.html `THING.bufanda`).
Sprite mkBufanda({int stripes = 3}) => _mk(12, 8, (b) {
  final n = stripes.clamp(1, 3);
  b.rect(1, 2, 10, 5, _h('#E0A020'));
  b.rect(1, 2, 10, 1, _h('#F8C838'));
  const xs = [3, 6, 9];
  for (var i = 0; i < n; i++) {
    b.rect(xs[i], 2, 1, 5, _h('#D0403A'));
  }
  b.rect(0, 5, 2, 2, _h('#D0403A'));
  if (n >= 2) b.rect(10, 5, 2, 2, _h('#D0403A'));
});

/// 8 x 8 ball of wool, optionally [rolling] (noche-preview.html `THING.lana`).
Sprite mkLana({bool rolling = false}) => _mk(8, 8, (b) {
  b.ell(4, 4, 2.8, 2.8, [_h('#A82A26'), _h('#D0403A'), _h('#FA9080')]);
  b.line(2, 3, 5, 5, _h('#FFB8B0'));
  b.line(3, 2, 6, 4, _h('#7A1C1C'));
  if (rolling) {
    b.px(1, 6, _h('#D0403A'));
    b.px(0, 7, _h('#FA9080'));
  } else {
    b.px(6, 6, _h('#D0403A'));
    b.px(7, 7, _h('#D0403A'));
  }
});

/// 12 x 8 open storybook showing [pages] (3, 2, or 1) (noche-preview.html `THING.libro`).
Sprite mkLibroNoche({int pages = 3}) => _mk(12, 8, (b) {
  final n = pages.clamp(1, 3);
  b.rect(1, 2, 10, 5, _h('#2E6CD0'));
  b.rect(2, 2, 4, 4, _h('#FFFBEA'));
  b.rect(6, 2, 4, 4, _h('#F2EBD4'));
  b.rect(5, 2, 2, 4, _h('#B89A6A'));
  b.line(3, 3, 4, 3, _h('#8E806C'));
  if (n >= 2) b.line(7, 3, 8, 3, _h('#8E806C'));
  if (n >= 3) {
    b.line(3, 4, 4, 4, _h('#8E806C'));
    b.line(7, 4, 8, 4, _h('#8E806C'));
  }
});

/* ---------- Additional Needs sprites (noche.md) ---------- */

/// 14 x 14 clock hands for [hora] (default 8 o'clock, minute hand up).
Sprite mkRelojHands({int hora = 8}) {
  final b = Buf(14, 14);
  const cx = 7, cy = 7;
  // Minute hand pointing straight up (12)
  b.line(cx, cy, cx, cy - 4, _h('#2E2628'));
  // Hour hand
  final ang = (hora % 12) * math.pi / 6;
  final hx = cx + (math.sin(ang) * 3.2).round();
  final hy = cy - (math.cos(ang) * 3.2).round();
  b.line(cx, cy, hx, hy, _h('#7A1C1C'));
  b.px(cx, cy, _h('#2E2628'));
  return b.done();
}

/// 18 x 8 scarf worn on frog in `final105`, scaled visually for [stripes] (3 twice round, 2 once, 1 collar).
Sprite mkBufandaCuello({int stripes = 3}) => _mk(18, 8, (b) {
  final n = stripes.clamp(1, 3);
  final h = n == 3 ? 3 : 2;
  b.rect(2, 1, 14, h, _h('#E0A020'));
  b.rect(2, 1, 14, 1, _h('#F8C838'));
  const xs = [4, 8, 12];
  for (var i = 0; i < n; i++) {
    b.rect(xs[i], 1, 1, h, _h('#D0403A'));
  }
  if (n >= 2) b.rect(4, 1 + h, 2, n == 3 ? 3 : 2, _h('#D0403A'));
  if (n >= 3) b.rect(12, 1 + h, 2, 3, _h('#E0A020'));
});

/// 22 x 10 covered dish with steam lifted (`tapa106`).
Sprite mkTapaVapor() => _mk(22, 10, (b) {
  b.ell(11, 7, 9, 2, [_h('#A8A8B8'), _h('#D0D0DC'), _h('#F4F4FA')]);
  b.ell(11, 5, 6, 2.5, [_h('#8E8E9E'), _h('#C8C8D4'), _h('#E8E8F2')]);
  b.px(11, 2, _h('#F8C838'));
  b.px(5, 1, _h('#DCE8F4'));
  b.px(6, 0, _h('#F4F8FC'));
  b.px(16, 1, _h('#DCE8F4'));
  b.px(17, 0, _h('#F4F8FC'));
});

/// 8 x 12 small table lamp brought by abuelo in `final106(1)`.
Sprite mkMesaLampara() => _mk(8, 12, (b) {
  b.rect(3, 6, 2, 5, _h('#6E4220'));
  b.rect(2, 10, 4, 1, _h('#4A2A14'));
  b.rect(1, 2, 6, 4, _h('#FFE880'));
  b.rect(2, 1, 4, 1, _h('#FFF4B0'));
});

/// 12 x 12 floating picture from abuela's book (`final107`: `'bote'`, `'estrella'`, `'rana'`).
Sprite mkLibroPic(String kind) => _mk(12, 12, (b) {
  b.rect(1, 1, 10, 10, _h('#FFFBEA'));
  if (kind == 'bote') {
    b.rect(2, 7, 8, 2, _h('#8A5A2A'));
    b.rect(5, 3, 1, 4, _h('#4A2A14'));
    b.rect(6, 3, 3, 3, _h('#4682DC'));
  } else if (kind == 'estrella') {
    b.rect(5, 2, 2, 8, _h('#F8C838'));
    b.rect(2, 5, 8, 2, _h('#F8C838'));
    b.rect(4, 4, 4, 4, _h('#FFE880'));
  } else {
    // rana
    b.ell(6, 6.5, 3.2, 2.8, [_h('#2E8A2E'), _h('#52B848'), _h('#84DC78')]);
    b.px(4, 4, _h('#FFFBEA'));
    b.px(7, 4, _h('#FFFBEA'));
  }
});

/// 7 x 9 music note for TV (`tele105`) and frog singing (`canta107`).
Sprite mkNotaMusical() => _mk(7, 9, (b) {
  b.rect(4, 1, 1, 6, _h('#FFE070'));
  b.rect(4, 1, 2, 2, _h('#F8C838'));
  b.ell(2.6, 6.4, 1.8, 1.4, [_h('#F2A650'), _h('#FFE070')]);
});

/// 12 x 8 hands cue (dirty grey or bright clean) for story 106 step 2.
Sprite mkManosCue({required bool clean}) => _mk(12, 8, (b) {
  final c = clean ? _h('#84DC78') : _h('#787884');
  final hi = clean ? _h('#F2FCE8') : _h('#9E9EA8');
  b.rect(1, 2, 4, 4, c);
  b.rect(7, 2, 4, 4, c);
  b.rect(2, 1, 2, 1, hi);
  b.rect(8, 1, 2, 1, hi);
});

/// 10 x 8 Canelo nose peeking up at the table edge (`nariz106`).
Sprite mkPerroNariz() => _mk(10, 8, (b) {
  b.ell(5, 4.5, 3.8, 2.4, [_h('#B07A3C'), _h('#D09A54')]);
  b.rect(4, 2, 2, 2, _h('#241610'));
});

/// 30 x 26 Canelo rearing on hind legs with front paws up on the table (`perro106`).
Sprite mkPerroMesa(bool mouthOpen) {
  final t = _ramp(const ['#8A5A2A', '#B07A3C', '#D09A54', '#E8BE80']);
  final out = _h('#221414');
  return _mk(30, 26, (b) {
    // Wagging tail and planted hind legs
    b.cap(8, 19, 4, mouthOpen ? 16 : 14, 1.4, [t[1]]);
    b.ell(12, 18, 5.5, 5.0, t);
    b.rect(9, 20, 2, 5, t[0]);
    b.rect(13, 20, 2, 5, t[2]);
    // Upright chest leaning toward the table, with both front paws raised
    b.ell(16, 12, 4.2, 4.6, t);
    b.cap(17, 10, 22, 6, 1.4, [t[1]]);
    b.cap(19, 12, 24, 7, 1.4, [t[2]]);
    b.rect(21, 5, 3, 2, t[3]);
    b.rect(23, 6, 3, 2, t[3]);
    // Head with red collar, ears, eye, nose, and optional eager bark
    b.rect(14, 7, 5, 2, _h('#D84848'));
    b.ell(18, 4, 4.4, 3.8, t);
    b.ell(22, 5, 2.6, 1.8, [t[3]]);
    b.cap(15, 2, 14, 6, 1.3, [t[0]]);
    b.cap(19, 1, 20, 0, 1.2, [t[0]]);
    b.px(19, 3, out);
    b.px(24, 4, out);
    if (mouthOpen) {
      b.rect(21, 6, 3, 2, _h('#7A1C1C'));
    }
  });
}

/// 14 x 10 open newspaper for abuelo sleeping (`levantados107`) or folding (`dobla`).
Sprite mkPeriodico() => _mk(14, 10, (b) {
  b.rect(1, 1, 12, 8, _h('#F4F0E4'));
  b.rect(2, 2, 4, 2, _h('#8E8880'));
  b.rect(7, 2, 5, 1, _h('#6A645E'));
  b.rect(2, 5, 10, 1, _h('#8E8880'));
  b.rect(2, 7, 8, 1, _h('#8E8880'));
});

/// 15 x 9 three golden stars for 3-of-3 celebration.
Sprite mkEstrellasNoche() => _mk(15, 9, (b) {
  for (final (sx, sy) in const [(2, 4), (7, 1), (12, 4)]) {
    b.rect(sx - 1, sy, 3, 3, _h('#F8C838'));
    b.px(sx, sy - 1, _h('#FFE880'));
    b.px(sx, sy + 3, _h('#FFE880'));
    b.px(sx - 2, sy + 1, _h('#FFE880'));
    b.px(sx + 2, sy + 1, _h('#FFE880'));
  }
});

/// 11 x 10 pink heart for 3-of-3 celebration.
Sprite mkCorazonNoche() => _mk(11, 10, (b) {
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

/// All La noche sprites, for the content lane's sheet (`tool/make_noche_sprites_test.dart`).
List<(String, Sprite)> nocheSpritesSheet() => [
  ('abuela_silla', mkAbuelaS('idle', false, false)),
  ('abuela_pie', mkAbuela('idle', false)),
  ('abuelo_silla', mkPersona(NOCHE_WHO['abuelo']!, 'idle', false, true)),
  ('abuelo_pies', mkPersonaFeetUp(NOCHE_WHO['abuelo']!, false)),
  ('abuelo_pie', mkPersona(NOCHE_WHO['abuelo']!, 'idle', false, false)),
  (
    'luis_pijama_piso',
    mkPersona(NOCHE_WHO['luis_pijama']!, 'idle', false, true),
  ),
  ('luis_pijama_pies', mkPersonaFeetUp(NOCHE_WHO['luis_pijama']!, false)),
  (
    'carmen_pijama_piso',
    mkPersona(NOCHE_WHO['carmen_pijama']!, 'idle', false, true),
  ),
  (
    'luis_pijama_pie',
    mkPersona(NOCHE_WHO['luis_pijama']!, 'idle', false, false),
  ),
  (
    'carmen_pijama_pie',
    mkPersona(NOCHE_WHO['carmen_pijama']!, 'idle', false, false),
  ),
  ('perro_eat', mkPerro('eat', false)),
  ('perro_sit', mkPerro('sit', false)),
  ('perro_mesa', mkPerroMesa(false)),
  ('jugo', mkJugo()),
  ('flan', mkFlan()),
  ('queso', mkQueso()),
  ('frutas', mkFrutas()),
  ('vela_3_lit', mkVelaNoche(len: 3, lit: true)),
  ('vela_2_lit', mkVelaNoche(len: 2, lit: true)),
  ('vela_1_lit', mkVelaNoche(len: 1, lit: true)),
  ('vela_3_off', mkVelaNoche(len: 3, lit: false)),
  ('bufanda_3', mkBufanda(stripes: 3)),
  ('bufanda_2', mkBufanda(stripes: 2)),
  ('bufanda_1', mkBufanda(stripes: 1)),
  ('bufanda_cuello_3', mkBufandaCuello(stripes: 3)),
  ('bufanda_cuello_2', mkBufandaCuello(stripes: 2)),
  ('bufanda_cuello_1', mkBufandaCuello(stripes: 1)),
  ('lana', mkLana()),
  ('libro_3', mkLibroNoche(pages: 3)),
  ('libro_2', mkLibroNoche(pages: 2)),
  ('libro_1', mkLibroNoche(pages: 1)),
  ('reloj_8', mkRelojHands(hora: 8)),
  ('tapa_vapor', mkTapaVapor()),
  ('mesa_lampara', mkMesaLampara()),
  ('libro_bote', mkLibroPic('bote')),
  ('libro_estrella', mkLibroPic('estrella')),
  ('libro_rana', mkLibroPic('rana')),
  ('nota', mkNotaMusical()),
  ('manos_sucias', mkManosCue(clean: false)),
  ('manos_limpias', mkManosCue(clean: true)),
  ('perro_nariz', mkPerroNariz()),
  ('periodico', mkPeriodico()),
  ('estrellas', mkEstrellasNoche()),
  ('corazon', mkCorazonNoche()),
];

/// Bottom ink anchor helper re-exported for `noche.dart`.
int nocheInkBottom(Sprite s) => inkBottom(s);
