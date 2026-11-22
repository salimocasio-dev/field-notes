// La plaza's cast: the people and things more than one of the place's four scenes uses (plaza, reloj, quiosco,
// calendario). First writer: order 58b (La plaza, scene `plaza`); the other three builders copy it and add to it only by
// adding (a new pose, a new prop: a new case at the end of a switch, a new entry at the end of a list).
//
// Drawn in the old sprites' way, as colmado_cast.dart draws El colmado's: the same maker (kit.js mkPersona for a person,
// as the family and El banco's people are drawn; engine.js Buf with its ramps and its dark outline for a thing or an
// animal), the same palette (kit.js PIEL, PELO, engine.js RP), the same size (a grown-up 48 x 56, a child 48 x 44, as
// mkPersona makes them), the same outline (OUT). What makes each one his own (a hat, a cap, a coat, a watch chain) is
// drawn over the figure as banco.js's `extra` draws it, baked into the sprite. Every sprite faces us; the scene mirrors
// it when its person faces the other way (dir -1).
//
// The looks come from the scripts (historia/notas/guiones/plaza.md, reloj.md, quiosco.md, calendario.md, "New people"):
// Ana (two plaits, a yellow dress), her mamá (no look given: this file's), Beto (a red cap), Ana's abuela (a sun hat), the
// visitors with maps and cameras (one of them with a watch), don Tito (old, a waistcoat, a pocket watch on a chain), the
// vendedor (an apron, a paper hat), the maestra (glasses, a pile of exercise books with an apple on top), the doctor (a
// white coat, a stethoscope round his neck), the cocinero (a tall white hat, a wooden spoon in his pocket), the policía (a
// blue uniform, a cap, a whistle), la joven (a young woman: no look given, this file's). People who already exist are
// taken from where they are: Luis and Carmen (kit.js FAM), abuela (engine.js mkAbuela), El banco's people and the
// piragüero (banco.dart Banco.QUIEN, with their extras), Canelo (kit.js mkPerro), the pigeon (banco.js mkPaloma), the
// coin (colmado_cast.dart mkMoneda). The content lane looks at every one on docs/proyecto/pixel/port/plaza-cast-sprites.png
// (tool/make_plaza_sprites_test.dart).
// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/src/banco/banco.dart' show Banco;
import 'package:coqui_scenes/src/banco/banco_sprites.dart' show mkPaloma;
import 'package:coqui_scenes/src/colmado/colmado_cast.dart'
    show canvasSprite, inkBottom, overSprite;

int _h(String s) => hexColour(s);
List<int> _hs(List<String> s) => [for (final x in s) hexColour(x)];

/// A sprite with its fully transparent top rows cut off (a person drawn with room above for a hat).
Sprite cropTop(Sprite s) {
  var top = 0;
  outer:
  for (; top < s.h; top++) {
    for (var x = 0; x < s.w; x++) {
      if (s.px[top * s.w + x] >>> 24 != 0) break outer;
    }
  }
  if (top == 0 || top >= s.h) return s;
  final h = s.h - top, px = Uint32List(s.w * h);
  px.setAll(0, s.px.sublist(top * s.w));
  return Sprite(s.w, h, px);
}

/* ---------- who they are ---------- */

/// The new people of La plaza (page 13, orders 58 to 61), by their speaker keys: `ana`, `mama_ana`, `beto`,
/// `abuela_ana`, `tito`, `vendedor`, `maestra`, `doctor`, `cocinero`, `policia`, `la_joven`, and the visitors `turista`
/// (the woman with a map and a camera of story 62) and `turista2` to `turista6` (the five who line up after her).
/// [extra]: what is drawn over the figure, by name (see [plazaExtra]).
typedef PlazaWho = ({Who who, List<String> extra});

final Map<String, PlazaWho> PLAZA_GENTE = {
  // Ana: a girl of Carmen's age, two plaits, a yellow dress (plaza.md); black hair and red ribbons, so that she is not
  // Carmen (light brown plaits, a pink dress, yellow ribbons)
  'ana': (
    who: Who(
      nino: true,
      piel: PIEL['c']!,
      pelo: PELO['negro']!,
      peinado: 'trenzas',
      ropa: RP.yel,
      falda: true,
      lazo: _h('#E0483A'),
      zapato: _h('#E0483A'),
    ),
    extra: const [],
  ),
  // her mamá: no look in the scripts; a grown-up woman with Ana's black hair, long, a teal dress
  'mama_ana': (
    who: Who(
      piel: PIEL['c']!,
      pelo: PELO['negro']!,
      peinado: 'largo',
      ropa: RP.teal,
      falda: true,
      zapato: _h('#3A2A20'),
    ),
    extra: const ['pendientes'],
  ),
  // Beto: her small brother, a red cap (plaza.md)
  'beto': (
    who: Who(
      nino: true,
      piel: PIEL['c']!,
      pelo: PELO['negro']!,
      peinado: 'corto',
      ropa: RP.blue,
      abajo: RP.grey,
      zapato: _h('#F2F2F8'),
    ),
    extra: const ['gorra'],
  ),
  // her abuela, on a visit: a sun hat (plaza.md); white hair, a lilac dress
  'abuela_ana': (
    who: Who(
      piel: PIEL['c']!,
      pelo: PELO['blanco']!,
      peinado: 'corto',
      ropa: RP.purp,
      falda: true,
      zapato: _h('#F2F2F8'),
    ),
    extra: const ['pava'],
  ),
  // don Tito, the clock man: old, a waistcoat, a pocket watch on a chain (reloj.md)
  'tito': (
    who: Who(
      piel: PIEL['a']!,
      pelo: PELO['blanco']!,
      peinado: 'calvo',
      ropa: RP.cream.sublist(1),
      abajo: RP.wood,
      bigote: true,
      gafas: 1,
      detalle: (b, X, tc, rx, t) {
        // a dark waistcoat over the shirt, open at the middle, and the gold chain of his watch to its pocket
        final V = _hs(['#2A2440', '#3E3660', '#564C80']);
        b.rect(X - rx + 2, tc - 7, rx - 3, t + 6, V[1]);
        b.rect(X + 1, tc - 7, rx - 3, t + 6, V[0]);
        b.rect(X - rx + 2, tc - 7, 1, t + 6, V[2]);
        for (var i = 0; i < 5; i++) {
          b.px(X - 4 + i, tc - 1 + (i == 2 ? 1 : 0), _h('#F0C020'));
        }
        b.rect(X + 2, tc - 1, 3, 3, _h('#F0C020'));
        b.px(X + 3, tc, _h('#FFF4C0'));
      },
    ),
    extra: const [],
  ),
  // the vendedor of the quiosco: an apron, a paper hat (reloj.md, quiosco.md)
  'vendedor': (
    who: Who(
      piel: PIEL['b']!,
      pelo: PELO['negro']!,
      peinado: 'corto',
      ropa: RP.red,
      abajo: RP.grey,
      bigote: true,
      detalle: (b, X, tc, rx, t) {
        // a white apron from the chest to the knees, its strings at the waist
        final Wt = _hs(['#C8C8D4', '#E8E8F0', '#FFFFFF']);
        b.rect(X - 5, tc - 5, 10, t + 13, Wt[1]);
        b.rect(X - 5, tc - 5, 2, t + 13, Wt[2]);
        b.rect(X + 3, tc - 5, 2, t + 13, Wt[0]);
        b.rect(X - rx + 1, tc + 2, 2 * rx - 2, 1, Wt[0]);
      },
    ),
    extra: const ['gorro_papel'],
  ),
  // the maestra: glasses (quiosco.md); her pile of exercise books with an apple is held (pose `libros`)
  'maestra': (
    who: Who(
      piel: PIEL['a']!,
      pelo: PELO['castano']!,
      peinado: 'largo',
      ropa: RP.purp,
      falda: true,
      gafas: 1,
      zapato: _h('#7A1C1C'),
    ),
    extra: const ['mono'],
  ),
  // the doctor: a white coat, a stethoscope round his neck (quiosco.md)
  'doctor': (
    who: Who(
      piel: PIEL['b']!,
      pelo: PELO['negro']!,
      peinado: 'corto',
      ropa: _hs(['#C8C8D4', '#E4E4EC', '#F6F6FA', '#FFFFFF']),
      abajo: RP.blue,
      detalle: (b, X, tc, rx, t) {
        // the stethoscope: round his neck, its two tubes down his chest to the round end
        final G = _h('#50586A');
        b.rect(X - 4, 19, 1, 8, G);
        b.rect(X + 3, 19, 1, 8, G);
        b.rect(X - 4, 27, 8, 1, G);
        b.rect(X, 27, 1, 4, G);
        b.ell(X, 32, 1.6, 1.6, [_h('#8A94A8'), _h('#C8D0DC')]);
        // the coat's open front over a blue shirt
        b.rect(X - 1, 18, 2, t + 8, _h('#5A86D0'));
      },
    ),
    extra: const [],
  ),
  // the cocinero: a tall white hat, a wooden spoon in his pocket (quiosco.md)
  'cocinero': (
    who: Who(
      piel: PIEL['a']!,
      pelo: PELO['negro']!,
      peinado: 'corto',
      ropa: _hs(['#C8C8D4', '#E4E4EC', '#F6F6FA', '#FFFFFF']),
      abajo: _hs(['#3A3A46', '#4E4E5E', '#6A6A7A']),
      bigote: true,
      detalle: (b, X, tc, rx, t) {
        // two rows of buttons, and the wooden spoon sticking out of his breast pocket
        for (var i = 0; i < 3; i++) {
          b.px(X - 2, tc - 4 + i * 4, _h('#8A94A8'));
          b.px(X + 2, tc - 4 + i * 4, _h('#8A94A8'));
        }
        b.rect(X + 3, tc - 6, 4, 3, _h('#DCDCE6'));
        b.rect(X + 5, tc - 12, 1, 7, _h('#B8864A'));
        b.ell(X + 5.5, tc - 13, 1.4, 2, [_h('#8A5A2A'), _h('#C8965A')]);
      },
    ),
    extra: const ['gorro_cocinero'],
  ),
  // the policía: a blue uniform, a cap, a whistle (quiosco.md)
  'policia': (
    who: Who(
      piel: PIEL['b']!,
      pelo: PELO['negro']!,
      peinado: 'corto',
      ropa: _hs(['#1A2A5A', '#24407A', '#3456A0', '#4A70C0']),
      abajo: _hs(['#141E40', '#1C2A56', '#24366C']),
      zapato: _h('#14141A'),
      detalle: (b, X, tc, rx, t) {
        // a badge on his chest, a belt, and the whistle on its cord
        b.rect(X - 5, tc - 5, 3, 3, _h('#F0C020'));
        b.rect(X - rx + 1, tc + t - 3, 2 * rx - 2, 2, _h('#14141A'));
        b.line(X + 1, 19, X + 3, tc - 2, _h('#E0E0E8'));
        b.rect(X + 3, tc - 2, 3, 2, _h('#C8C8D4'));
      },
    ),
    extra: const ['gorra_policia'],
  ),
  // la joven, a young woman (quiosco.md 67: no look given): long brown hair with a band, a teal top, blue trousers
  'la_joven': (
    who: Who(
      piel: PIEL['b']!,
      pelo: PELO['castano']!,
      peinado: 'largo',
      ropa: _hs(['#B86A1A', '#E08A2A', '#F4AA4A', '#FFC870']),
      abajo: RP.blue,
      zapato: _h('#F2F2F8'),
    ),
    extra: const ['cinta'],
  ),
  // the visitors with maps and cameras (plaza.md 62): the first, la turista (a woman with a map and a camera), and the
  // five who line up after her; each has a camera on a strap, a sun visor or a hat; the last of the line has a watch
  'turista': (
    who: Who(
      piel: PIEL['c']!,
      pelo: _hs(['#B8862A', '#D8A848', '#F0CC70']),
      peinado: 'largo',
      ropa: RP.teal,
      abajo: _hs(['#C8B08A', '#DCC8A4', '#ECDCBC']),
      zapato: _h('#F2F2F8'),
    ),
    extra: const ['visera', 'camara'],
  ),
  'turista2': (
    who: Who(
      piel: PIEL['c']!,
      pelo: _hs(['#7A4A1A', '#9A6230', '#B87E48']),
      peinado: 'corto',
      ropa: _hs(['#B84A6A', '#D86A8A', '#F08AA8', '#FFB0C8']),
      abajo: _hs(['#C8B08A', '#DCC8A4', '#ECDCBC']),
      zapato: _h('#3A2A20'),
    ),
    extra: const ['sombrero_sol', 'camara'],
  ),
  'turista3': (
    who: Who(
      piel: PIEL['a']!,
      pelo: PELO['negro']!,
      peinado: 'largo',
      ropa: RP.orng,
      abajo: RP.blue,
      zapato: _h('#F2F2F8'),
    ),
    extra: const ['visera', 'mapa'],
  ),
  'turista4': (
    who: Who(
      piel: PIEL['c']!,
      pelo: PELO['blanco']!,
      peinado: 'calvo',
      ropa: RP.grn,
      abajo: _hs(['#C8B08A', '#DCC8A4', '#ECDCBC']),
      bigote: true,
      zapato: _h('#3A2A20'),
    ),
    extra: const ['sombrero_sol', 'mapa'],
  ),
  'turista5': (
    who: Who(
      piel: PIEL['c']!,
      pelo: _hs(['#B8862A', '#D8A848', '#F0CC70']),
      peinado: 'corto',
      ropa: RP.sky,
      abajo: RP.grey,
      gafas: 1,
      zapato: _h('#F2F2F8'),
    ),
    extra: const ['camara', 'reloj'],
  ),
  'turista6': (
    who: Who(
      piel: PIEL['b']!,
      pelo: PELO['castano']!,
      peinado: 'largo',
      ropa: RP.yel,
      abajo: RP.teal,
      zapato: _h('#3A2A20'),
    ),
    extra: const ['sombrero_sol', 'camara'],
  ),
};

/// The visitors in the order they come to the cart (story 62: la turista first, then the line).
const List<String> TURISTAS = [
  'turista',
  'turista2',
  'turista3',
  'turista4',
  'turista5',
  'turista6',
];

/// The people of El banco (banco.dart Banco.QUIEN): their figure and their extras, as they are drawn in the park.
const List<String> GENTE_BANCO = [
  'senor',
  'senora',
  'hombre',
  'mujer',
  'joven',
  'piraguero',
];

/// Every person this cast draws, by key: the new ones, El banco's, and the family's two children.
List<String> get PLAZA_QUIENES => [
  ...PLAZA_GENTE.keys,
  ...GENTE_BANCO,
  'luis',
  'carmen',
];

/// Whether [id] is a child (a sprite 48 x 44).
bool plazaNino(String id) {
  if (id == 'luis' || id == 'carmen') return true;
  final w = PLAZA_GENTE[id]?.who ?? Banco.QUIEN[id]?.who;
  return w?.nino ?? false;
}

/* ---------- what is drawn over the figure ---------- */

/// What makes each one his own, drawn over the kit's figure (banco.js `extra`'s way: rectangles with a dark outline).
/// [h], [hy]: the middle column of the face and its middle row; [d]: the way he faces (1: the sprite's own way). El
/// banco's names (barba, gorra, mochila, sombrero, cola, baston, delantal) are banco.dart's `extra`, line for line; the
/// others are this file's.
void plazaExtra(Ctx c, String k, num h, num hy, int d, int imH) {
  switch (k) {
    // banco.dart Banco.extra, line for line
    case 'barba':
      fr(c, h - 5, hy + 2, 10, 4, _h('#24160E'));
      fr(c, h - 2, hy + 3, 4, 1, _h('#7A2A1A'));
      fr(c, h - 6, hy - 1, 1, 4, _h('#24160E'));
      fr(c, h + 5, hy - 1, 1, 4, _h('#24160E'));
    case 'gorra':
      fr(c, h - 7, hy - 8, 14, 5, OUT);
      fr(c, h - 6, hy - 7, 12, 3, _h('#D0302A'));
      fr(c, h + d * 5 - (d < 0 ? 5 : 0), hy - 4, 6, 2, OUT);
      fr(c, h + d * 5 - (d < 0 ? 4 : 0), hy - 4, 5, 1, _h('#D0302A'));
    case 'mochila':
      fr(c, h - d * 11 - (d < 0 ? -1 : 5), hy + 8, 6, 16, OUT);
      fr(c, h - d * 11 - (d < 0 ? 0 : 4), hy + 9, 4, 14, _h('#E88A2A'));
      fr(c, h - 6, hy + 10, 1, 12, _h('#B85A14'));
      fr(c, h + 5, hy + 10, 1, 12, _h('#B85A14'));
    case 'sombrero':
      fr(c, h - 6, hy - 13, 12, 7, OUT);
      fr(c, h - 5, hy - 12, 10, 5, _h('#6A4A2A'));
      fr(c, h - 5, hy - 8, 10, 1, _h('#2A1A0E'));
      fr(c, h - 9, hy - 7, 18, 3, OUT);
      fr(c, h - 8, hy - 6, 16, 1, _h('#6A4A2A'));
    case 'cola':
      fr(c, h - d * 8 - (d < 0 ? 0 : 3), hy - 5, 4, 11, OUT);
      fr(c, h - d * 8 - (d < 0 ? -1 : 2), hy - 4, 2, 9, _h('#44260E'));
      fr(c, h - d * 6 - (d < 0 ? 0 : 2), hy - 6, 3, 3, _h('#F0C020'));
    case 'baston':
      final bx = h + d * 12;
      fr(c, bx - 1, hy + 12, 3, imH - 24, OUT);
      fr(c, bx, hy + 13, 1, imH - 26, _h('#8A5A2A'));
      fr(c, bx - 3, hy + 11, 6, 3, OUT);
      fr(c, bx - 2, hy + 12, 4, 1, _h('#8A5A2A'));
    case 'delantal':
      fr(c, h - 6, hy + 12, 12, 14, _h('#F2F2F8'));
      fr(c, h - 6, hy + 12, 12, 1, _h('#C8C8D4'));
    // La plaza's own
    case 'pava':
      // a wide straw sun hat with a red band
      fr(c, h - 11, hy - 8, 22, 4, OUT);
      fr(c, h - 10, hy - 7, 20, 2, _h('#E8D08A'));
      fr(c, h - 6, hy - 13, 12, 6, OUT);
      fr(c, h - 5, hy - 12, 10, 5, _h('#F0DC9A'));
      fr(c, h - 5, hy - 9, 10, 1, _h('#D0402A'));
    case 'pendientes':
      fr(c, h - 6, hy + 2, 1, 2, _h('#F0C020'));
      fr(c, h + 5, hy + 2, 1, 2, _h('#F0C020'));
    case 'gorro_papel':
      // a folded paper hat, white, a little peak
      fr(c, h - 7, hy - 9, 14, 5, OUT);
      fr(c, h - 6, hy - 8, 12, 3, _h('#F6F6FA'));
      fr(c, h - 3, hy - 12, 6, 4, OUT);
      fr(c, h - 2, hy - 11, 4, 3, _h('#F6F6FA'));
      fr(c, h - 6, hy - 6, 12, 1, _h('#C8C8D4'));
    case 'mono':
      // a bun of hair at the back of her head
      fr(c, h - 3, hy - 12, 6, 4, OUT);
      fr(c, h - 2, hy - 11, 4, 2, _h('#643A1A'));
    case 'gorro_cocinero':
      // a tall white hat: a band and a puffed top
      fr(c, h - 7, hy - 9, 14, 5, OUT);
      fr(c, h - 6, hy - 8, 12, 3, _h('#F0F0F6'));
      fr(c, h - 8, hy - 19, 16, 11, OUT);
      fr(c, h - 7, hy - 18, 14, 9, _h('#FFFFFF'));
      fr(c, h - 7, hy - 10, 14, 1, _h('#D4D4DE'));
      fr(c, h - 3, hy - 17, 1, 6, _h('#E4E4EC'));
      fr(c, h + 2, hy - 17, 1, 6, _h('#E4E4EC'));
    case 'gorra_policia':
      // a peaked cap, dark blue, a gold badge
      fr(c, h - 7, hy - 10, 14, 6, OUT);
      fr(c, h - 6, hy - 9, 12, 4, _h('#24407A'));
      fr(c, h - 1, hy - 8, 2, 2, _h('#F0C020'));
      fr(c, h - 7, hy - 5, 14, 2, OUT);
      fr(c, h - 6, hy - 5, 12, 1, _h('#141E40'));
    case 'cinta':
      fr(c, h - 6, hy - 6, 12, 1, _h('#E0483A'));
    case 'visera':
      // a sun visor: a band and a peak, white
      fr(c, h - 7, hy - 7, 14, 3, OUT);
      fr(c, h - 6, hy - 6, 12, 1, _h('#FFFFFF'));
      fr(c, h + d * 3 - (d < 0 ? 6 : 0), hy - 5, 7, 2, OUT);
      fr(c, h + d * 3 - (d < 0 ? 5 : 0), hy - 5, 6, 1, _h('#F6F6FA'));
    case 'sombrero_sol':
      // a pale cloth hat with a soft brim
      fr(c, h - 9, hy - 7, 18, 3, OUT);
      fr(c, h - 8, hy - 6, 16, 1, _h('#E4DCC4'));
      fr(c, h - 6, hy - 12, 12, 6, OUT);
      fr(c, h - 5, hy - 11, 10, 4, _h('#F0E8D0'));
    case 'camara':
      // a camera on a strap across his chest
      c.fillStyle = _h('#20202A');
      for (var i = 0; i < 9; i++) {
        c.fillRect(h - 5 + i, hy + 8 + i, 1, 1);
      }
      fr(c, h + 1, hy + 15, 7, 5, OUT);
      fr(c, h + 2, hy + 16, 5, 3, _h('#3A3A46'));
      fr(c, h + 4, hy + 17, 2, 2, _h('#9CCBF5'));
    case 'mapa':
      // a folded map held at his side
      fr(c, h - d * 11 - (d < 0 ? -1 : 5), hy + 14, 7, 8, OUT);
      fr(c, h - d * 11 - (d < 0 ? 0 : 4), hy + 15, 5, 6, _h('#F4F0DC'));
      fr(c, h - d * 11 - (d < 0 ? 0 : 4), hy + 17, 5, 1, _h('#5AB46A'));
      fr(c, h - d * 11 - (d < 0 ? -2 : 2), hy + 15, 1, 6, _h('#4A90E2'));
    case 'reloj':
      // a watch on his left wrist
      fr(c, h - 10, hy + 19, 3, 3, OUT);
      fr(c, h - 9, hy + 20, 1, 1, _h('#F0C020'));
  }
}

/* ---------- the people ---------- */

/// The poses this cast draws for every person (the gestures of the scripts' `gesto`, and what `llega`, `mano` and the
/// game show): `idle`; `saluda0`, `saluda1` (waves); `mano` (a hand held out to shake: mkPersona's `offer`); `senala`
/// (points: `tu`); `hombros` (shrugs: both hands out, `ojos`); `cabeza` (scratches his head: the hand at it); `rie`
/// (laughs: the mouth open, the hands on the chest, `yo`); `llama0`, `llama1` (calls from far off: waves, the mouth open);
/// `sienta` (sitting, seen from the front); `arrodilla` (kneels: the sitting figure, lower); `guino` (winks: one eye shut);
/// `mapa` (holds the map up), `foto` (takes a photo), `reloj` (looks at his watch: the arm up), `libros` (the maestra's pile
/// of exercise books with the apple, held in front).
const List<String> PLAZA_POSES = [
  'idle',
  'saluda0',
  'saluda1',
  'mano',
  'senala',
  'hombros',
  'cabeza',
  'rie',
  'llama0',
  'llama1',
  'sienta',
  'arrodilla',
  'guino',
];

/// The props' poses (people who carry the thing): [PLAZA_POSES] and these.
const List<String> PLAZA_POSES_COSAS = ['mapa', 'foto', 'reloj', 'libros'];

// mkPersona's pose and whether the mouth is open, for a pose of this cast
(String, bool, bool) _kitPose(String pose, bool open) => switch (pose) {
  'saluda0' || 'llama0' => ('wave0', open || pose == 'llama0', false),
  'saluda1' || 'llama1' => ('wave1', open || pose == 'llama1', false),
  'mano' => ('offer', open, false),
  'senala' => ('tu', open, false),
  'hombros' => ('ojos', open, false),
  'cabeza' => ('wave0', open, false),
  'rie' => ('yo', true, false),
  'sienta' || 'arrodilla' => ('idle', open, true),
  'foto' => ('foto', open, false),
  'reloj' || 'libros' || 'mapa' => ('taza', open, false),
  _ => ('idle', open, false),
};

/// [id] in [pose] (one of [PLAZA_POSES] or [PLAZA_POSES_COSAS]); [open]: talking. The sprite is mkPersona's (48 wide,
/// its middle column [PX]) with what makes him his own drawn over it, its fully transparent top rows cut off: its feet at
/// its lowest drawn row (inkBottom), as every person's (the sheets' rules.anchor). [id]: a key of [PLAZA_GENTE], of El
/// banco's people ([GENTE_BANCO]), `luis` or `carmen`.
Sprite mkPlazaPersona(String id, String pose, {bool open = false}) {
  final Who who;
  final List<String> extra;
  if (id == 'luis' || id == 'carmen') {
    who = FAM[id == 'luis' ? 'hermano' : 'hermana']!;
    extra = const [];
  } else if (PLAZA_GENTE.containsKey(id)) {
    who = PLAZA_GENTE[id]!.who;
    extra = PLAZA_GENTE[id]!.extra;
  } else {
    final b = Banco.QUIEN[id];
    if (b == null || b.who == null) {
      throw ArgumentError.value(id, 'id', 'not one of La plaza\'s people');
    }
    who = b.who!;
    extra = b.extra;
  }
  final (kp, op, sent) = _kitPose(pose, open);
  final base = mkPersona(who, kp, op, sent);
  const top = 22; // room above the head for a hat
  final s = canvasSprite(base.w, base.h + top, (g) {
    g.drawImage(base, 0, top);
    final hy = top + 11;
    for (final k in extra) {
      if (k == 'baston' && sent) continue;
      plazaExtra(g, k, PX, hy, 1, base.h);
    }
    if (pose == 'guino') {
      // the right eye shut: a short dark line where it was, the cheek's colour under it
      fr(g, PX + 1, hy, 3, 1, _h('#20140A'));
    }
    if (pose == 'cabeza') {
      // fingers in the hair
      fr(g, PX + 6, hy - 6, 2, 2, who.pelo[2]);
    }
  });
  var out = cropTop(s);
  if (pose == 'mapa' || pose == 'reloj' || pose == 'libros') {
    // the held-out hand (mkPersona's `taza`: X + rx + 4.5, row 27) holds the thing
    final rx = who.nino ? 6.5 : 8, hand = PX + rx + 4.5;
    final off = s.h - out.h, y = top - off + 21 + 6;
    final Sprite th = switch (pose) {
      'mapa' => mkMapa(),
      'reloj' => mkRelojMuneca(),
      _ => mkCuadernos(),
    };
    out = overSprite(out, [(th, (hand - th.w / 2).round(), y - th.h + 2)]);
  }
  return out;
}

/// The anchor of a person's sprite: its middle column and its feet's bottom edge (kneeling: the same).
({int ax, int ay}) plazaAnchor(Sprite s) => (ax: PX, ay: inkBottom(s));

/* ---------- things more than one scene holds ---------- */

/// A folded map, open in a hand: cream with a green patch, a blue river, a red dot.
Sprite mkMapa() {
  final b = Buf(12, 9);
  b.rect(1, 1, 10, 7, _h('#F4F0DC'));
  b.rect(1, 1, 5, 7, _h('#E8E2C8'));
  b.rect(2, 3, 3, 3, _h('#8ACB7A'));
  b.line(7, 1, 9, 7, _h('#4A90E2'));
  b.px(4, 6, _h('#E0483A'));
  return b.outline().done();
}

/// A wrist watch seen close, held up to look at.
Sprite mkRelojMuneca() {
  final b = Buf(7, 7);
  b.ell(3.5, 3.5, 2.6, 2.6, _hs(['#B87A10', '#F0C020', '#FFE070']));
  b.ell(3.5, 3.5, 1.5, 1.5, [_h('#FFFFFF')]);
  b.px(3, 2, _h('#20140A'));
  b.px(4, 3, _h('#20140A'));
  return b.outline().done();
}

/// The maestra's pile of exercise books with an apple on top (quiosco.md).
Sprite mkCuadernos() {
  final b = Buf(14, 13);
  final cols = _hs(['#4A70C0', '#E0483A', '#5AB46A', '#F0C020']);
  for (var i = 0; i < 4; i++) {
    b.rect(1, 11 - i * 2, 12, 2, cols[i]);
    b.rect(1, 11 - i * 2, 12, 1, _h('#F4F4F8'));
  }
  b.ell(7, 2.6, 2.6, 2.4, _hs(['#9A1A1A', '#D0302A', '#F06A5A']));
  b.px(7, 0, _h('#5A3A1A'));
  b.px(8, 0, _h('#5AB46A'));
  return b.outline().done();
}

/// A pigeon (El banco's: banco.js mkPaloma, 18 x 13) in a pose of La plaza: `posada` sitting (on the seat's back, a
/// hand, a cap, the frog's head), `anda0`, `anda1` walking (a step: its head bobs), `come` pecking (two frames by [f]),
/// `vuela` flying (two frames by [f]). Faces right (the scene mirrors it).
Sprite mkPalomaPz(String pose, [int f = 0]) => switch (pose) {
  'anda0' => mkPaloma(null, 0),
  'anda1' => mkPaloma('come', 0),
  'come' => mkPaloma('come', f),
  'vuela' => mkPaloma('vuela', f),
  _ => mkPaloma(null, 0),
};

/// The poses of the pigeon.
const List<String> PALOMA_POSES = ['posada', 'anda0', 'anda1', 'come', 'vuela'];

/// A flag, 11 x 8 with its outline: `us` (the United States: red and white stripes, a blue corner with white dots) or
/// `pr` (Puerto Rico: red and white stripes, a blue triangle with a white star).
Sprite mkBandera(String k) {
  final b = Buf(11, 8);
  final red = _h('#D0302A'), wh = _h('#FFFFFF'), bl = _h('#2A4AA8');
  for (var y = 1; y < 7; y++) {
    b.rect(1, y, 9, 1, y.isOdd ? red : wh);
  }
  if (k == 'us') {
    b.rect(1, 1, 4, 3, bl);
    b.px(2, 2, wh);
    b.px(4, 2, wh);
    b.px(3, 3, wh);
  } else {
    for (var y = 1; y < 7; y++) {
      final w = y <= 3 ? y + 1 : 7 - y + 1;
      b.rect(1, y, math.min(w, 5), 1, _h('#4A90E2'));
    }
    b.px(2, 3, wh);
    b.px(2, 4, wh);
  }
  return b.outline().done();
}

/// Where each sprite of this file lands in its sheet picture (plaza-cast-sprites.png): every person in every pose, then
/// the things, in order, for the tool that makes the picture.
List<(String, Sprite)> plazaCastSheet() => [
  for (final id in PLAZA_GENTE.keys)
    for (final p in PLAZA_POSES) ('$id $p', mkPlazaPersona(id, p)),
  for (final id in PLAZA_GENTE.keys)
    ('$id idle, talking', mkPlazaPersona(id, 'idle', open: true)),
  // the people who already exist, in a few of the new poses (their figures are El banco's and the family's)
  for (final id in [...GENTE_BANCO, 'luis', 'carmen'])
    for (final p in const ['idle', 'mano', 'hombros', 'rie', 'sienta'])
      ('$id $p', mkPlazaPersona(id, p)),
  for (final id in TURISTAS)
    for (final p in PLAZA_POSES_COSAS.take(3))
      ('$id $p', mkPlazaPersona(id, p)),
  ('maestra libros', mkPlazaPersona('maestra', 'libros')),
  for (final p in PALOMA_POSES) ('paloma $p', mkPalomaPz(p)),
  ('paloma vuela 1', mkPalomaPz('vuela', 1)),
  ('paloma come 1', mkPalomaPz('come', 1)),
  ('bandera us', mkBandera('us')),
  ('bandera pr', mkBandera('pr')),
  ('mapa', mkMapa()),
  ('reloj de pulsera', mkRelojMuneca()),
  ('cuadernos y manzana', mkCuadernos()),
];

/// The figure of [id] (one of [PLAZA_QUIENES]), or null.
Who? plazaWho(String id) => id == 'luis'
    ? FAM['hermano']
    : id == 'carmen'
    ? FAM['hermana']
    : PLAZA_GENTE[id]?.who ?? Banco.QUIEN[id]?.who;
