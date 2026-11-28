// Scene-specific sprites of El pedido (place 8, La fonda, scene 2: `pedido`, order 67):
// - Cast definitions matching pedido-preview.html (`PEOPLE`: cocinero with compact white chef hat, mesera with white
//   apron, mesero in red shirt, and next-table guests senor, senora, joven, mujer), seated abuela directional pointing
//   poses, cooking/serving prop variants, and frog carrying a plate on his head (`lleva87`).
// - Props, cat, board pictures, plates, drinks, FX, and `pedidoSpritesSheet()` live in `pedido_props.dart`.
// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/src/colmado/colmado_cast.dart' show inkBottom;

part 'pedido_props.dart';

int _h(String s) => hexColour(s);

List<int> _ramp(List<String> hs) => [for (final s in hs) _h(s)];

Sprite _mk(int w, int h, void Function(Buf b) draw, {bool outline = true}) {
  final b = Buf(w, h);
  draw(b);
  return outline ? b.outline().done() : b.done();
}

final List<int> _WHITE = _ramp(const [
  '#C8C8D0',
  '#E4E4EA',
  '#F6F6FA',
  '#FFFFFF',
]);

final List<int> _PLATE = _ramp(const ['#A8A8B8', '#D0D0DC', '#F4F4FA']);

final List<int> _CAT_GREY = _ramp(const [
  '#5A5A6A',
  '#7E7E90',
  '#A2A2B2',
  '#C8C8D4',
]);

// pedido-preview.html: apron(WHITE)
void _whiteApron(Buf b, num X, num tc, num rx, num t) {
  final G = _WHITE;
  b.rect(X - 4, 18, 1, 4, G[1]);
  b.rect(X + 3, 18, 1, 4, G[1]);
  b.rect(X - 5, 22, 10, 24, G[2]);
  b.rect(X - 5, 22, 2, 24, G[3]);
  b.rect(X + 3, 22, 2, 24, G[1]);
  b.rect(X - 5, 45, 10, 1, G[0]);
  b.rect(X - 5, 22, 10, 1, G[3]);
  b.rect(X - 3, 34, 6, 4, G[1]);
  b.rect(X - 3, 34, 6, 1, G[3]);
}

/// Fonda staff and next-table guest outfits matching pedido-preview.html `PEOPLE`.
final Map<String, Who> PEDIDO_PEOPLE = {
  'cocinero': Who(
    piel: PIEL['c']!,
    pelo: PELO['castano']!,
    peinado: 'corto',
    ropa: _WHITE,
    abajo: RP.stone,
    bigote: true,
  ),
  'mesera': Who(
    piel: PIEL['b']!,
    pelo: PELO['negro']!,
    peinado: 'largo',
    ropa: RP.teal,
    falda: true,
    zapato: _h('#3A2414'),
    detalle: _whiteApron,
  ),
  'mesero': Who(
    piel: PIEL['c']!,
    pelo: PELO['negro']!,
    peinado: 'corto',
    ropa: RP.red,
    abajo: RP.blue,
    bigote: true,
  ),
  'senor': Who(
    piel: PIEL['a']!,
    pelo: PELO['blanco']!,
    peinado: 'corto',
    ropa: RP.wood,
    abajo: RP.grey,
    bigote: true,
  ),
  'senora': Who(
    piel: PIEL['a']!,
    pelo: PELO['castano']!,
    peinado: 'corto',
    ropa: RP.grn,
    falda: true,
    zapato: _h('#F2F2F8'),
  ),
  'joven': Who(
    piel: PIEL['b']!,
    pelo: PELO['castano']!,
    peinado: 'corto',
    ropa: RP.cream.sublist(1),
    abajo: RP.blue,
    zapato: _h('#F2F2F8'),
  ),
  'mujer': Who(
    piel: PIEL['c']!,
    pelo: PELO['negro']!,
    peinado: 'largo',
    ropa: RP.yel,
    falda: true,
    zapato: _h('#7A4A10'),
  ),
};

/// Lap anchor row for a seated person (`mkPersona` with `sent = true`: `16 + 2 * t + 3`, pedido-sheet.json rules.anchor).
int pedidoSeatedLap(Who w) => 16 + 2 * (w.nino ? 7 : 11) + 3;

/// Copies [base] and lets [paint] draw extra pixels directly onto its canvas without changing dimensions or feet row.
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

/// Draws the cocinero standing in the hatch with a compact white chef hat whose top stays at canvas row 2
/// (screen y = 8 at hueco 146,61 — strictly inside the hatch hole y 7.05..43.5 with 0 px hidden by the wall above).
/// Optional [guina] closes his right eye into a wink; optional [prop] draws a kitchen prop inside the hatch
/// (`'platano'`, `'sarten'`, `'prensa'`, `'pilon'`, `'tres_platanos'`).
Sprite mkCocinero({
  String pose = 'idle',
  bool open = false,
  bool guina = false,
  String? prop,
}) {
  final base = mkPersona(PEDIDO_PEOPLE['cocinero']!, pose, open, false);
  return _overlayOn(base, (b) {
    const X = PX;
    // Compact pleated white chef toque over hair rows 2..7 (top border at y = 2 -> screen Y = 8 at hueco).
    b.rect(X - 5, 2, 10, 1, OUT);
    b.px(X - 6, 3, OUT);
    b.px(X + 5, 3, OUT);
    b.px(X - 6, 4, OUT);
    b.px(X + 5, 4, OUT);
    b.px(X - 6, 5, OUT);
    b.px(X + 5, 5, OUT);
    b.rect(X - 5, 3, 10, 3, _WHITE[3]);
    b.rect(X - 5, 5, 10, 1, _WHITE[2]);
    b.px(X - 2, 3, _WHITE[1]);
    b.px(X - 2, 4, _WHITE[1]);
    b.px(X + 1, 3, _WHITE[1]);
    b.px(X + 1, 4, _WHITE[1]);
    b.rect(X - 5, 6, 10, 2, _WHITE[1]);
    b.rect(X - 5, 6, 10, 1, _WHITE[2]);
    b.px(X - 6, 6, OUT);
    b.px(X + 5, 6, OUT);
    b.px(X - 6, 7, OUT);
    b.px(X + 5, 7, OUT);
    if (guina) {
      final skin = PIEL['c']![3];
      b.rect(X + 1, 10, 3, 2, skin);
      b.rect(X + 1, 11, 3, 1, _h('#20140A'));
    }
    if (prop != null) {
      final p = _mkCocineroProp(prop);
      final ox = X + 8, oy = 17;
      for (var py = 0; py < p.h; py++) {
        for (var px = 0; px < p.w; px++) {
          final c = p.px[py * p.w + px];
          if (c >>> 24 != 0) b.px(ox + px, oy + py, c);
        }
      }
    }
  });
}

/// Draws the mesera standing (teal dress + white apron), optionally holding her order pad or a dish plate.
Sprite mkMesera({
  String pose = 'idle',
  bool open = false,
  bool pad = false,
  String? plato,
}) {
  final base = mkPersona(PEDIDO_PEOPLE['mesera']!, pose, open, false);
  if (!pad && plato == null) return base;
  return _overlayOn(base, (b) {
    const X = PX;
    if (pad) {
      b.rect(X + 6, 24, 6, 8, OUT);
      b.rect(X + 7, 25, 4, 6, _h('#FFFBEA'));
      b.rect(X + 7, 25, 4, 1, _h('#B89A6A'));
      b.rect(X + 8, 27, 2, 1, _h('#6A6A7A'));
      b.rect(X + 8, 29, 2, 1, _h('#6A6A7A'));
    }
    if (plato != null) {
      final p = mkPlato(plato);
      final ox = X + 5, oy = 21;
      for (var py = 0; py < p.h; py++) {
        for (var px = 0; px < p.w; px++) {
          final c = p.px[py * p.w + px];
          if (c >>> 24 != 0 && ox + px < b.w) b.px(ox + px, oy + py, c);
        }
      }
    }
  });
}

/// Draws the mesero standing (red shirt + blue pants + mustache), optionally with pad, hand fan (`abanico`), or
/// straw-pull pose (`sorbo`).
Sprite mkMesero({
  String pose = 'idle',
  bool open = false,
  bool pad = false,
  bool abanico = false,
  bool sorbo = false,
  int fanFrame = 0,
}) {
  final kp = sorbo ? 'taza' : pose;
  final base = mkPersona(PEDIDO_PEOPLE['mesero']!, kp, open, false);
  if (!pad && !abanico && !sorbo) return base;
  return _overlayOn(base, (b) {
    const X = PX;
    if (pad) {
      b.rect(X + 6, 24, 6, 8, OUT);
      b.rect(X + 7, 25, 4, 6, _h('#FFFBEA'));
      b.rect(X + 7, 25, 4, 1, _h('#B89A6A'));
      b.rect(X + 8, 27, 2, 1, _h('#6A6A7A'));
    }
    if (abanico) {
      final shift = fanFrame % 2 == 0 ? 0 : 2;
      b.ell(
        X + 10 + shift,
        19,
        4.2,
        3.2,
        _ramp(const ['#D8B870', '#F4E4A8', '#FFFBEA']),
      );
      b.line(X + 8 + shift, 21, X + 12 + shift, 17, _h('#9A682C'));
      b.line(X + 10 + shift, 22, X + 10 + shift, 16, _h('#9A682C'));
    }
    if (sorbo) {
      b.px(X - 5, 8, _h('#8CC8FA'));
      b.px(X - 5, 9, _h('#DCF0FF'));
      b.line(X + 2, 15, X + 10, 22, _h('#D0403A'));
    }
  });
}

/// Seated abuela with directional pointing poses (`senala_izq`, `senala_der`, `yo`) keeping anchor (17, 36).
Sprite mkAbuelaPedido(String pose, bool open) {
  if (pose == 'senala_izq') {
    final base = mkAbuelaS('idle', open, false);
    return _overlayOn(base, (b) {
      const X = 17;
      b.cap(X - 7, 23, X - 12, 18, 2, RP.purp);
      b.ell(X - 13.5, 17, 2.1, 2.1, RP.skin);
      b.px(X - 16, 17, OUT);
      b.px(X - 15, 15, OUT);
      b.px(X - 15, 19, OUT);
    });
  }
  final abPose = switch (pose) {
    'senala_der' || 'senala' => 'vaso',
    'yo' || 'bebe' || 'come' => 'bebe',
    _ => 'idle',
  };
  return mkAbuelaS(abPose, open, false);
}

/// Frog carrying a plate on his head (`lleva87`, 32 x 33, feet anchored at bottom).
Sprite mkCoquiPlato(String dish, {bool open = false, bool blink = false}) {
  final frog = mkCoqui(1, blink ? 1 : 0, open);
  final plate = mkPlato(dish);
  const padTop = 6;
  final b = Buf(frog.w, frog.h + padTop);
  for (var py = 0; py < frog.h; py++) {
    for (var px = 0; px < frog.w; px++) {
      final c = frog.px[py * frog.w + px];
      if (c >>> 24 != 0) b.px(px, py + padTop, c);
    }
  }
  final ox = 16 - plate.w ~/ 2;
  for (var py = 0; py < plate.h; py++) {
    for (var px = 0; px < plate.w; px++) {
      final c = plate.px[py * plate.w + px];
      if (c >>> 24 != 0) b.px(ox + px, py, c);
    }
  }
  return b.done();
}

/// Anchor row (`ay`) for [mkCoquiPlato] (bottom of frog's feet).
int coquiPlatoBottom(Sprite s) => inkBottom(s);
