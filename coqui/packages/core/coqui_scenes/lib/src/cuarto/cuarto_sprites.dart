// Scene-specific sprites of El cuarto (place 9, La casa, un día entero, scene 1: `cuarto`, order 70):
// - Characters matching cuarto-preview.html & cuarto.md Needs:
//   - Luis & Carmen standing (awake/asleep, plus Carmen `pies` pointing at her feet, `rie`) and in-bed (`inBed`,
//     hung down from head on pillow with bed-colored blanket from chest/waist or uncovered);
//   - Luis dressing stages for story 98 (`mkLuisVestir`: pyjamas, trousers, shoes/socks, shirt, brimmed hat, watch,
//     plus `pelo98` 3 neat / 2 hair tuft / 1 hair tuft + shirt tail + grin, and `zapatos98` fallen pose);
//   - Abuelo standing & seated in armchair (`mkAbueloArmchair`: asleep/awake with storybook on chest);
//   - Abuela standing, `silencio` (finger to lips), and `foto` (with camera in hands / raised camera);
//   - Canelo sitting/licking (`mkPerroCuarto`) & nose under bed (`mkNariz`);
//   - Sleeping frog (`mkCoquiDuerme`);
// - Props (`almohada`, `plato`, `campana`, `mantaAbuelo`, `bebe`, `zetas`, `ropa` items, clock hands, FX) and
//   `cuartoSpritesSheet()` live in `cuarto_props.dart`.
// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/src/cuarto/cuarto_places.dart';

part 'cuarto_props.dart';

int _h(String s) => hexColour(s);

List<int> _ramp(List<String> hs) => [for (final s in hs) _h(s)];

Sprite _mk(int w, int h, void Function(Buf b) draw, {bool outline = true}) {
  final b = Buf(w, h);
  draw(b);
  return outline ? b.outline().done() : b.done();
}

/// First row from top containing any opaque pixel (`cuarto-preview.html: inkTop`).
int inkTop(Sprite s) {
  for (var y = 0; y < s.h; y++) {
    for (var x = 0; x < s.w; x++) {
      if (s.px[y * s.w + x] >>> 24 != 0) return y;
    }
  }
  return 0;
}

/// Middle column of opaque pixels (`cuarto-preview.html: inkMid`).
int inkMid(Sprite s) {
  var a = s.w;
  var z = -1;
  for (var y = 0; y < s.h; y++) {
    for (var x = 0; x < s.w; x++) {
      if (s.px[y * s.w + x] >>> 24 != 0) {
        if (x < a) a = x;
        if (x > z) z = x;
      }
    }
  }
  if (z < 0) return s.w ~/ 2;
  return (a + z) ~/ 2;
}

/// Lap anchor row for a seated person (`mkPersona` with `sent = true`: `16 + 2 * t + 3`, cuarto-sheet.json rules.anchor).
int cuartoSeatedLap(Who w) => 16 + 2 * (w.nino ? 7 : 11) + 3;

/// Copies [base] and lets [paint] draw extra pixels directly onto its canvas.
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

int _rgbOffset(List<int> c, int d) {
  int ch(int v) => (v + d).clamp(0, 255);
  return 0xFF000000 | (ch(c[2]) << 16) | (ch(c[1]) << 8) | ch(c[0]);
}

/// Whoever lies or sits up in a bed (`cama_luis`, `cama_carmen`): the standing sprite hung DOWN the bed from its
/// highest drawn row (`inkTop`), cut at [hang.rows] (40), with a blanket of [bedColor] and width [hang.width] (34)
/// over it starting at [blanketFrom] (24 lying, 30 sitting, or null for uncovered). Anchor is `(PX, 0)`.
Sprite mkInBed(
  Who who,
  List<int> bedColor,
  CuartoHang hang, {
  int? blanketFrom,
  String pose = 'idle',
  bool open = false,
}) {
  final src = mkPersona(who, pose, open, false);
  final top = inkTop(src);
  final rows = hang.rows;
  final b = Buf(src.w, rows);
  for (var py = 0; py < rows; py++) {
    final sy = top + py;
    if (sy >= src.h) break;
    for (var px = 0; px < src.w; px++) {
      final c = src.px[sy * src.w + px];
      if (c >>> 24 != 0) b.px(px, py, c);
    }
  }
  if (blanketFrom != null) {
    final f0 = blanketFrom - top;
    final hh = rows - f0 + 1;
    final bw = hang.width;
    if (hh > 2) {
      final bl = Buf(bw + 2, hh);
      bl.rect(1, 1, bw, hh - 1, _rgbOffset(bedColor, 0));
      bl.rect(1, 1, bw, 2, _rgbOffset(bedColor, 34));
      bl.rect(1, 3, bw, 1, _rgbOffset(bedColor, -30));
      bl.rect(1, 1, 2, hh - 1, _rgbOffset(bedColor, 18));
      bl.rect(bw - 1, 1, 2, hh - 1, _rgbOffset(bedColor, -26));
      for (var y = 8; y < hh - 2; y += 6) {
        bl.rect(5, y, bw - 8, 1, _rgbOffset(bedColor, -14));
      }
      final done = bl.outline().done();
      final ox = PX - (bw + 2) ~/ 2;
      final oy = f0 - 1;
      for (var py = 0; py < done.h; py++) {
        final dy = oy + py;
        if (dy < 0 || dy >= rows) continue;
        for (var px = 0; px < done.w; px++) {
          final c = done.px[py * done.w + px];
          if (c >>> 24 != 0) b.px(ox + px, dy, c);
        }
      }
    }
  }
  return b.done();
}

/// Abuela standing, optionally with a finger to her lips (`silencio`: 97 step 1), or carrying her camera (`foto`: 98)
/// or raising the camera to take the photo (`fotoUp`: 98 step 7). Anchor is `(30, inkBottom)`.
Sprite mkAbuelaCuarto({
  String pose = 'idle',
  bool open = false,
  bool silencio = false,
  bool foto = false,
  bool fotoUp = false,
}) {
  if (silencio) {
    final base = mkAbuela('idle', open);
    return _overlayOn(base, (b) {
      const X = 30;
      // Right hand raised to her lips with a vertical finger ("Shh").
      b.cap(X + 7, 23, X + 5, 17, 2, RP.purp);
      b.ell(X + 3.5, 16.5, 2.0, 2.0, RP.skin);
      b.rect(X, 12, 2, 5, RP.skin[3]);
      b.px(X - 1, 13, OUT);
      b.px(X + 2, 13, OUT);
      b.px(X, 11, OUT);
      b.px(X + 1, 11, OUT);
    });
  }
  final base = mkAbuela(pose, open);
  if (!foto && !fotoUp) return base;
  return _overlayOn(base, (b) {
    final cam = _mk(12, 9, (cb) {
      cb.rect(1, 2, 10, 6, _h('#3A3A46'));
      cb.rect(1, 2, 10, 1, _h('#6E6E80'));
      cb.ell(6, 5, 2.4, 2.4, [_h('#9CCBF5'), _h('#DCEEFF')]);
      cb.rect(7, 0, 3, 2, _h('#FFE070'));
      cb.ell(0.5, 7.5, 1.6, 1.6, PIEL['a']!);
      cb.ell(11.5, 7.5, 1.6, 1.6, PIEL['a']!);
    });
    final ox = 30 - 6;
    final oy = fotoUp ? 13 : 25;
    for (var py = 0; py < cam.h; py++) {
      for (var px = 0; px < cam.w; px++) {
        final c = cam.px[py * cam.w + px];
        if (c >>> 24 != 0) b.px(ox + px, oy + py, c);
      }
    }
  });
}

/// Abuelo seated in the armchair (`butaca_abuelo`), asleep or awake, with his storybook resting on his chest.
Sprite mkAbueloArmchair({
  bool dormido = true,
  bool open = false,
  String pose = 'idle',
}) {
  final w = FAM['abuelo']!.copyWith(dormido: dormido);
  final base = mkPersona(w, pose, open, true);
  return _overlayOn(base, (b) {
    const X = PX;
    // Open storybook on his chest (warm cream pages + red/wood cover).
    b.rect(X - 5, 22, 10, 7, OUT);
    b.rect(X - 4, 23, 8, 5, _h('#C8583C'));
    b.rect(X - 4, 23, 4, 4, _h('#FFF9E6'));
    b.rect(X + 1, 23, 3, 4, _h('#F4ECD0'));
    b.rect(X, 23, 1, 5, _h('#B89A6A'));
  });
}

/// Carmen standing, optionally pointing down at her own feet (`pies` in story 97 step 4).
Sprite mkCarmenCuarto({
  String pose = 'idle',
  bool open = false,
  bool pies = false,
}) {
  if (pies) {
    final base = mkPersona(FAM['hermana']!, 'idle', open, false);
    return _overlayOn(base, (b) {
      const X = PX;
      // Right arm pointing down toward her shoes.
      b.cap(X + 6, 21, X + 9, 31, 1.8, FAM['hermana']!.ropa);
      b.ell(X + 9, 33, 2.0, 2.0, FAM['hermana']!.piel);
      b.line(X + 9, 34, X + 7, 37, FAM['hermana']!.piel[3]);
    });
  }
  return mkPersona(FAM['hermana']!, pose, open, false);
}

final List<int> _PYJAMA_TOP = _ramp(const [
  '#5A82B8',
  '#7BA4D8',
  '#A6C8F0',
  '#CBE0FA',
]);

final List<int> _PYJAMA_PANTS = _ramp(const ['#4A70A4', '#6B92C6', '#8FB4E2']);

final List<int> _HAT_STRAW = _ramp(const [
  '#9A6E28',
  '#C4963C',
  '#E4BC5E',
  '#F8DC88',
]);

/// Luis dressing in story 98 (`vestir`): pyjamas or clothes (`trousers`, `shoes`, `shirt`, `hat`, `watch`),
/// plus `neat` (`pelo98` n: 3 neat, 2 hair tuft, 1 hair tuft + shirt tail + grin), or `tumbled` (`zapatos98`).
Sprite mkLuisVestir({
  bool trousers = false,
  bool shoes = false,
  bool shirt = false,
  bool hat = false,
  bool watch = false,
  int neat = 3,
  String pose = 'idle',
  bool open = false,
  bool dormido = false,
  bool tumbled = false,
}) {
  final luis = FAM['hermano']!;
  final who = Who(
    nino: true,
    piel: luis.piel,
    pelo: luis.pelo,
    peinado: luis.peinado,
    ropa: shirt ? luis.ropa : _PYJAMA_TOP,
    abajo: trousers ? luis.abajo : _PYJAMA_PANTS,
    zapato: shoes ? luis.zapato : _h('#C8CED8'),
    dormido: dormido,
  );
  final base = mkPersona(who, pose, open, tumbled);
  return _overlayOn(base, (b) {
    const X = PX;
    // Pyjama buttons when still in pyjama top.
    if (!shirt) {
      b.px(X, 21, _h('#E8F2FC'));
      b.px(X, 24, _h('#E8F2FC'));
      b.px(X, 27, _h('#E8F2FC'));
    }
    // Shirt tail hanging out at neat == 1 (two mistakes).
    if (neat <= 1 && shirt) {
      b.rect(X - 6, 30, 5, 3, luis.ropa[2]);
      b.rect(X + 1, 30, 4, 4, luis.ropa[1]);
      b.rect(X - 6, 33, 5, 1, OUT);
      b.rect(X + 1, 34, 4, 1, OUT);
    }
    // Grin when neat == 1 and mouth is closed ("a tuft of hair, and his shirt tail out; he grins").
    if (neat <= 1 && !open && !dormido) {
      b.rect(X - 2, 14, 5, 2, _h('#FFFFFF'));
      b.px(X - 3, 14, _h('#7A2A1A'));
      b.px(X + 3, 14, _h('#7A2A1A'));
    }
    // Wristwatch on right wrist.
    if (watch) {
      b.rect(X + 7, 27, 3, 2, _h('#6A3A1E'));
      b.rect(X + 8, 27, 2, 2, _h('#FFE070'));
    }
    // Tuft of hair standing up when neat <= 2 (unless covered by hat? keep tuft peeking out!).
    if (neat <= 2) {
      b.px(X - 1, 2, luis.pelo[1]);
      b.px(X, 1, luis.pelo[2]);
      b.px(X + 1, 2, luis.pelo[1]);
      b.px(X, 0, OUT);
      b.px(X - 1, 1, OUT);
      b.px(X + 1, 1, OUT);
    }
    // Brimmed straw hat (`sombrero`).
    if (hat) {
      b.ell(X, 5.5, 9.5, 2.2, _HAT_STRAW);
      b.rect(X - 5, 1, 10, 4, _HAT_STRAW[2]);
      b.rect(X - 5, 1, 10, 1, _HAT_STRAW[3]);
      b.rect(X - 5, 4, 10, 1, _h('#D0403A'));
      b.rect(X - 5, 0, 10, 1, OUT);
      b.rect(X - 9, 5, 4, 1, OUT);
      b.rect(X + 5, 5, 4, 1, OUT);
      if (neat <= 2) {
        // Tuft pokes slightly at side/crown if ruffled.
        b.px(X + 5, 2, luis.pelo[2]);
        b.px(X + 6, 1, OUT);
      }
    }
    // Tumbled shoes stuck in trousers (`zapatos98`).
    if (tumbled) {
      b.rect(X - 5, 31, 4, 3, _h('#F2F2F8'));
      b.rect(X + 1, 31, 4, 3, _h('#F2F2F8'));
    }
  });
}

/// Canelo in El cuarto: `'sit'` (cuarto-preview.html `perro`), `'lick'` (`final96` n=1: licks his nose).
Sprite mkPerroCuarto(String pose, {int frame = 0}) {
  final base = mkPerro('sit', frame % 2 != 0);
  if (pose != 'lick') return base;
  return _overlayOn(base, (b) {
    final dy = frame % 2 == 0 ? 0 : -1;
    b.rect(20, 7 + dy, 3, 2, _h('#FF8FB8'));
    b.px(22, 6 + dy, _h('#FFB8D4'));
  });
}

/// Canelo's nose under Luis's bed (`bajo_cama`): 10 x 8 (`cuarto-preview.html` `THING.nariz`).
Sprite mkNariz() => _mk(10, 8, (b) {
  final t = _ramp(const ['#8A5A2A', '#B07A3C', '#D09A54', '#E8BE80']);
  b.ell(5, 5.6, 4.4, 2.4, t);
  b.rect(3, 3, 4, 2, _h('#20140A'));
  b.px(4, 3, _h('#5A4A4A'));
});

/// Frog sleeping on/beside the big pillow (`duerme96`, 32 x 20, anchor `(16, 19)`): eyes shut, curled flat.
Sprite mkCoquiDuerme() => _mk(32, 20, (b) {
  final t = RP.tan;
  const cx = 16.0;
  b.ell(cx - 7, 15, 4.5, 2.8, t);
  b.ell(cx + 7, 15, 4.5, 2.8, t);
  b.ell(cx, 12, 10.5, 6.0, t);
  b.ell(cx, 14, 6.5, 3.8, RP.cream);
  // Shut eyelids.
  for (final dx in const [-5.0, 5.0]) {
    b.ell(cx + dx, 7.5, 4.0, 3.2, t);
    b.rect(cx + dx - 2.5, 8, 5, 1, OUT);
  }
  b.line(cx - 3.5, 11.5, cx + 3.5, 11.5, OUT);
});
