// The names of the old file are kept, Spanish ones and capitals included, so a scene ports line for line
// (page 12, section 4 and section 6): the lints on names are off in this file.
// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'dart:math' as math;

import 'package:coqui_pixel/src/colour.dart';
import 'package:coqui_pixel/src/ctx.dart';
import 'package:coqui_pixel/src/scene.dart';
import 'package:coqui_pixel/src/sprite.dart';

/// Port of historia/escenas/kit.js: what every scene after El frente shares. The bird, abuela sitting, the people,
/// the baby, the dog, the basket, the raised hand, the card for the corner of the screen, and `escena()`, which
/// here is the base class [Escena].
///
/// The old file's globals (`W`, `F`, `wait`, `TICK`, `SFX`, `hopTo`, `bounce`, `fx`, `cam`, `S`, `frogBox`, `spr`)
/// are what a scene reaches through its [Scene.host]; `spr` is [SceneHost.lib], the game's one sprite cache. The kit's
/// sprites are cached under the keys the old code uses (`"kave" + st + fl`).
///
/// A flag the old code tests for truth (`open`, `sent`, `pies`, `fl`, `f`, a person's `nino`, `falda`, `bigote`,
/// `dormido`) is a `bool`, as in order 11 (`mkCoqui`'s `open`); a scene writes `habla != 0` where it held a number.

/// kit.js: `SW`, `SH`, the size of every scene's picture.
const int kitSW = 240, kitSH = 216;

/// What an act is (kit.js: an entry of `d.acts`): `async (o) => ...`, `o` the step's own fields.
typedef Act = Future<void> Function(Map<String, dynamic> o);

// JavaScript: Math.round
int _round(num v) => (v + 0.5).floor();

/// JavaScript's truth of a value from a JSON-shaped map: not null, not false, not 0, not NaN, not "".
bool _truthy(Object? v) {
  if (v == null) return false;
  if (v is bool) return v;
  if (v is num) return v != 0 && !v.isNaN;
  if (v is String) return v.isNotEmpty;
  return true;
}

/// A list of numbers from what a thing's box or hand holds: `[27, 57, 30, 56]` or a list read from a file.
List<num>? _nums(Object? v) {
  if (v == null) return null;
  if (v is List<num>) return v;
  return [for (final e in v as List) e as num];
}

/* ---------- the bird ---------- */

// kit.js: mkAve
Sprite mkAve(String st, bool fl) {
  final R = st == 'round',
      b = Buf(R ? 24 : 18, R ? 18 : 14),
      B = RP.blue,
      cx = R ? 11 : 8,
      cy = R ? 10 : 8;
  b.cap(cx - 6, cy - 1, cx - 9, cy - 3, 1.2, [B[1]]);
  b.ell(cx, cy, R ? 8 : 5.5, R ? 6.5 : 4.2, B);
  b.ell(cx - 1, cy + (R ? 2.5 : 1.5), R ? 5 : 3.4, R ? 3.4 : 2.2, [
    hexColour('#E8F4FF'),
  ]);
  b.ell(cx + (R ? 6 : 5), cy - (R ? 4 : 3), R ? 3.8 : 3.3, R ? 3.6 : 3.1, B);
  if (st == 'sleep' || R) {
    b.rect(cx + (R ? 6 : 5), cy - (R ? 4 : 3), 2, 1, OUT);
  } else {
    b.px(cx + 6, cy - 4, hexColour('#FFFFFF'));
    b.px(cx + 6, cy - 3, hexColour('#20140A'));
    b.px(cx + 7, cy - 3, hexColour('#20140A'));
  }
  b.rect(cx + (R ? 9 : 8), cy - (R ? 4 : 3), R ? 3 : 2, R ? 2 : 1, RP.yel[2]);
  b.px(cx + (R ? 9 : 8), cy - (R ? 2 : 2), RP.orng[2]);
  if (fl) {
    b.ell(cx - 1, cy - 4, 3.6, 2, [B[0], B[1]]);
  } else {
    b.ell(cx - 1, cy + 1, 3.6, 2, [B[0], B[1]]);
  }
  if (!R) {
    b.px(cx - 1, cy + 4, RP.orng[1]);
    b.px(cx + 2, cy + 4, RP.orng[1]);
  }
  return b.outline().done();
}

/// kit.js: `AVK`, the bird is drawn bigger than its pixels, so it reads at phone size.
const double AVK = 1.6;

// kit.js: the colours the bird's marks use every frame
const int _white = 0xFFFFFFFF;
const int _pink = 0xFFB88FFF; // "#FF8FB8"

/* ---------- abuela, sitting ---------- */

// kit.js: mkAbuelaS
// Poses: idle, fan (a paper fan, two frames), vaso (a glass held out), bebe (the glass at her mouth), zzz, and pies (her feet up)
Sprite mkAbuelaS(String pose, bool open, bool pies) {
  final b = Buf(52, 50), X = 17, S = RP.skin, P = RP.purp;
  final shoe = hexColour('#3A2414'), dark = hexColour('#20140A');
  // legs and lap first, the body over them
  if (pies) {
    b.cap(X + 8, 36, X + 27, 35, 3.4, P);
    b.rect(X + 26, 33, 8, 4, S[2]);
    b.ell(X + 35, 33.5, 2.2, 3.4, [shoe]);
    b.ell(X + 35, 37.5, 2.2, 2.6, [shoe]);
  } else {
    b.ell(X + 9, 36.5, 12, 5.2, P);
    b.rect(X + 15, 40, 3, 6, S[2]);
    b.rect(X + 19, 40, 3, 6, S[1]);
    b.ell(X + 17, 47, 3.2, 1.7, [shoe]);
    b.ell(X + 22, 47, 3.2, 1.7, [shoe]);
  }
  b.ell(X, 28, 8.6, 9.6, P);
  for (var i = 0; i < 7; i++) {
    b.px(X - 7 + hs(i, 3) % 15, 29 + hs(i, 5) % 8, P[4]);
  }
  b.ell(X + 1, 30, 5, 6.6, RP.cream);
  b.rect(X - 4, 23, 10, 1, RP.cream[1]);
  b.rect(X - 2, 17, 4, 4, S[1]);
  b.ell(X, 10, 8, 8.6, RP.grey);
  b.ell(X, 2.9, 3.6, 2.6, RP.grey);
  b.ell(X, 12.4, 5.8, 6.4, S);
  b.ell(X, 5.8, 6.2, 2.6, RP.grey);
  if (pose == 'zzz') {
    b.rect(X - 4, 12, 3, 1, dark);
    b.rect(X + 1, 12, 3, 1, dark);
  } else {
    b.px(X - 3, 12, dark);
    b.px(X + 2, 12, dark);
  }
  b.px(X - 4, 14, hexColour('#E08A70'));
  b.px(X + 3, 14, hexColour('#E08A70'));
  if (open) {
    b.rect(X - 1, 15, 3, 2, hexColour('#7A1C1C'));
  } else {
    b.rect(X - 2, 15, 4, 1, hexColour('#7A2A1A'));
    b.px(X - 3, 14, hexColour('#7A2A1A'));
    b.px(X + 2, 14, hexColour('#7A2A1A'));
  }
  b.px(X - 6, 14, hexColour('#F8C838'));
  b.px(X + 6, 14, hexColour('#F8C838'));
  b.cap(X - 7, 23, X - 6, 31, 2, P);
  b.ell(X - 5, 33.5, 2.1, 2.1, S); // her left arm rests
  if (pose == 'fan0' || pose == 'fan1') {
    // her arm up, to hold a paper fan (the scene draws the fan)
    b.cap(X + 7, 23, X + 12, 18, 2, P);
    b.ell(X + 13.5, 16.5, 2.2, 2.2, S);
  } else if (pose == 'vaso') {
    b.cap(X + 7, 24, X + 14, 29, 2, P);
    b.ell(X + 16, 29.5, 2.2, 2.2, S);
  } else if (pose == 'bebe') {
    b.cap(X + 7, 24, X + 11, 19, 2, P);
    b.ell(X + 10, 17.5, 2.2, 2.2, S);
  } else {
    b.cap(X + 8, 24, X + 11, 31, 2, P);
    b.ell(X + 12, 33, 2.1, 2.1, S);
  }
  return b.outline().done();
}

/* ---------- people ---------- */

/// kit.js: `PIEL`, the skin ramps.
final Map<String, List<int>> PIEL = {
  'a': hexColours(['#7A4A2A', '#9A6238', '#B87A48', '#D09460', '#E4B080']),
  'b': hexColours(['#5A3418', '#7A4A26', '#96623A', '#B07C50', '#C8966A']),
  'c': hexColours(['#8A5A38', '#AE7A50', '#CC9868', '#E2B484', '#F2CEA4']),
};

/// kit.js: `PELO`, the hair ramps.
final Map<String, List<int>> PELO = {
  'negro': hexColours(['#140C08', '#24160E', '#38241A']),
  'castano': hexColours(['#2A1608', '#44260E', '#643A1A']),
  'blanco': hexColours(['#9494A6', '#C8C8D4', '#F2F2F8']),
};

/// kit.js: `PX`, the middle of a person's sprite.
const int PX = 24;

/// What a person is (kit.js: the `who` of `mkPersona`): grown-up or child, skin, hair, clothes.
/// `nino` a child; `piel`, `pelo`, `ropa`, `abajo` ramps; `peinado` "corto", "largo", "trenzas" or "calvo";
/// `falda`, `bigote`; `gafas` 1 (on his nose) or "arriba" (pushed up on his head), as the scenes write it;
/// `lazo`, `zapato` colours; `dormido` asleep; `detalle` something more drawn on the body.
class Who {
  const Who({
    this.nino = false,
    required this.piel,
    required this.pelo,
    required this.peinado,
    required this.ropa,
    this.abajo,
    this.falda = false,
    this.bigote = false,
    this.gafas,
    this.lazo,
    this.zapato,
    this.dormido = false,
    this.detalle,
  });

  final bool nino;
  final List<int> piel, pelo, ropa;
  final List<int>? abajo;
  final String peinado;
  final bool falda, bigote, dormido;
  final Object? gafas;
  final int? lazo, zapato;
  final void Function(Buf b, num X, num tc, num rx, num t)? detalle;

  /// `Object.assign({}, w, {dormido: 1})`, `Object.assign({}, FAM[id], {gafas: p.gafas})`: a copy with some fields changed.
  Who copyWith({bool? dormido, Object? gafas}) => Who(
    nino: nino,
    piel: piel,
    pelo: pelo,
    peinado: peinado,
    ropa: ropa,
    abajo: abajo,
    falda: falda,
    bigote: bigote,
    gafas: gafas ?? this.gafas,
    lazo: lazo,
    zapato: zapato,
    dormido: dormido ?? this.dormido,
    detalle: detalle,
  );
}

// kit.js: mkPersona
// pose = idle | wave0 | wave1 | offer | yo (a hand on the chest) | tu (pointing at someone) | foto (a camera at the face)
//        | taza (holding a cup) | ojos (arms out in front)
// sent = sitting, seen from the front. The sprite's feet are at its bottom edge and its middle is PX.
Sprite mkPersona(Who w, String pose, bool open, bool sent) {
  final t = w.nino ? 7 : 11,
      l = sent ? 4 : (w.nino ? 7 : 11),
      rx = w.nino ? 6.5 : 8,
      H = 18 + 2 * t + l + 4,
      b = Buf(48, H + 1),
      X = PX,
      S = w.piel,
      R = w.ropa,
      A = w.abajo ?? w.ropa,
      P = w.pelo;
  final tc = 18 + t, hc = 18 + 2 * t - 2, lt = hc + 2, lb = lt + l;
  final dark = hexColour('#2A1810'),
      eye = hexColour('#20140A'),
      blush = hexColour('#E08A70'),
      mouth = hexColour('#7A1C1C'),
      mouth2 = hexColour('#7A2A1A'),
      shoe = w.zapato ?? hexColour('#3A2414');
  // legs and shoes
  if (w.falda) {
    b.rect(X - 4, lt, 3, l, S[2]);
    b.rect(X + 1, lt, 3, l, S[1]);
  } else {
    b.rect(X - 5, lt - 2, 4, l + 2, A[1]);
    b.rect(X + 1, lt - 2, 4, l + 2, A[0]);
    b.rect(X - 5, lt - 2, 1, l + 2, A[2]);
  }
  b.ell(X - 3.5, lb + 1.5, 3.3, 1.8, [shoe]);
  b.ell(X + 3.5, lb + 1.5, 3.3, 1.8, [shoe]);
  // body
  final A2 = [A[0], A[1], A[1]];
  if (w.falda) {
    b.ell(X, tc, rx, t + 1, R);
    b.ell(X, hc + 1, rx + 2.4, sent ? 4 : 5.5, R);
  } else {
    b.ell(X, hc, rx - .8, 3.4, A2);
    b.ell(X, tc - 1, rx, t, R);
  }
  if (sent && !w.falda) {
    // knees, towards us
    b.ell(X - 4, hc + 2, 4.2, 3.2, A2);
    b.ell(X + 4, hc + 2, 4.2, 3.2, A2);
  }
  if (w.detalle != null) w.detalle!(b, X, tc, rx, t);
  b.rect(X - 2, 16, 4, 4, S[1]);
  // hair behind the face, the face, hair on top
  if (w.peinado == 'largo') {
    b.ell(X, 11, 8, 8.8, P);
    b.rect(X - 8, 11, 3, t + 2, P[1]);
    b.rect(X + 5, 11, 3, t + 2, P[0]);
  }
  b.ell(X, 11.4, 5.8, 6.4, S);
  if (w.peinado == 'calvo') {
    b.ell(X - 6, 9.5, 2, 3.4, P);
    b.ell(X + 6, 9.5, 2, 3.4, P);
  } else if (w.peinado == 'trenzas') {
    final lazo = w.lazo ?? hexColour('#FFE070');
    b.ell(X, 5.6, 6.4, 3, P);
    b.cap(X - 7, 9, X - 8, 19, 1.6, P);
    b.cap(X + 7, 9, X + 8, 19, 1.6, P);
    b.rect(X - 10, 19, 4, 3, lazo);
    b.rect(X + 6, 19, 4, 3, lazo);
    b.px(X, 3, P[2]);
  } else {
    b.ell(X, 5.4, 6.4, w.peinado == 'largo' ? 3.2 : 2.8, P);
    if (w.peinado == 'corto') {
      b.rect(X - 6, 6, 1, 4, P[1]);
      b.rect(X + 5, 6, 1, 4, P[0]);
    }
  }
  if (w.dormido) {
    b.rect(X - 4, 11, 3, 1, eye);
    b.rect(X + 1, 11, 3, 1, eye);
  } else {
    b.px(X - 3, 11, eye);
    b.px(X + 2, 11, eye);
  }
  b.px(X - 4, 13, blush);
  b.px(X + 3, 13, blush);
  if (w.gafas == 1) {
    b.frame(X - 5, 9, 4, 4, dark);
    b.frame(X, 9, 4, 4, dark);
    b.px(X - 1, 10, dark);
    if (!w.dormido) {
      b.px(X - 3, 11, eye);
      b.px(X + 2, 11, eye);
    }
  } else if (w.gafas == 'arriba') {
    // pushed up on his head; he squints
    b.frame(X - 5, 3, 4, 3, dark);
    b.frame(X, 3, 4, 3, dark);
    b.px(X - 1, 4, dark);
    b.rect(X - 4, 11, 3, 1, eye);
    b.rect(X + 1, 11, 3, 1, eye);
  }
  if (w.bigote) {
    b.rect(X - 4, 14, 8, 2, P[2]);
    b.rect(X - 4, 15, 2, 1, P[1]);
    b.rect(X + 2, 15, 2, 1, P[1]);
    if (open) b.rect(X - 1, 16, 3, 1, mouth);
  } else if (open) {
    b.rect(X - 1, 15, 3, 2, mouth);
  } else {
    b.rect(X - 2, 15, 4, 1, mouth2);
    b.px(X - 3, 14, mouth2);
    b.px(X + 2, 14, mouth2);
  }
  // arms
  final sh = 21;
  void izq() {
    b.cap(X - rx + 1, sh, X - rx - 1, sh + t - 1, 1.9, R);
    b.ell(X - rx - 1, sh + t + 1.5, 2, 2, S);
  }

  void der() {
    b.cap(X + rx - 1, sh, X + rx + 1, sh + t - 1, 1.9, R);
    b.ell(X + rx + 1, sh + t + 1.5, 2, 2, S);
  }

  if (pose == 'wave0' || pose == 'wave1') {
    izq();
    b.cap(X + rx - 1, sh, X + rx + 4, 13, 1.9, R);
    b.ell(X + rx + 5 + (pose == 'wave1' ? 1.5 : 0), 10, 2.2, 2.2, S);
  } else if (pose == 'offer') {
    der();
    b.cap(X - rx + 1, sh + 1, X - rx - 7, sh + 4, 1.9, R);
    b.ell(X - rx - 9.5, sh + 4, 2.2, 2.2, S);
  } else if (pose == 'yo') {
    b.cap(X + rx - 1, sh, X + rx + 2, sh + 5, 1.9, R);
    b.cap(X + rx + 2, sh + 5, X + 3, sh + 4, 1.7, R);
    b.cap(X - rx + 1, sh, X - rx - 2, sh + 5, 1.9, R);
    b.cap(X - rx - 2, sh + 5, X - 3, sh + 4, 1.7, R);
    b.ell(X + 2.5, sh + 3.5, 2.6, 2.6, S);
    b.ell(X - 2.5, sh + 3.5, 2.6, 2.6, S);
  } else if (pose == 'tu') {
    izq();
    b.cap(X + rx - 1, sh, X + rx + 7, sh + 6, 1.9, R);
    b.ell(X + rx + 9, sh + 8, 2.4, 2.4, S);
    b.line(X + rx + 11, sh + 10, X + rx + 13, sh + 12, S[3]);
    b.line(X + rx + 11, sh + 9, X + rx + 13, sh + 11, S[2]);
  } else if (pose == 'foto') {
    b.cap(X - rx + 1, sh, X - 5, 13, 1.9, R);
    b.cap(X + rx - 1, sh, X + 5, 13, 1.9, R);
    b.rect(X - 7, 6, 14, 9, hexColour('#3A3A46'));
    b.rect(X - 7, 6, 14, 1, hexColour('#6E6E80'));
    b.ell(X, 10.5, 3, 3, [hexColour('#9CCBF5'), hexColour('#DCEEFF')]);
    b.rect(X + 3, 4, 3, 2, hexColour('#FFE070'));
    b.ell(X - 6, 13.5, 2, 2, S);
    b.ell(X + 6, 13.5, 2, 2, S);
  } else if (pose == 'taza') {
    izq();
    b.cap(X + rx - 1, sh, X + rx + 3, sh + 6, 1.9, R);
    b.ell(X + rx + 4.5, sh + 6, 2.2, 2.2, S);
  } else if (pose == 'ojos') {
    b.cap(X - rx + 1, sh, X - 4, sh + 9, 1.9, R);
    b.cap(X + rx - 1, sh, X + 4, sh + 9, 1.9, R);
    b.ell(X - 4, sh + 11, 2.2, 2.2, S);
    b.ell(X + 4, sh + 11, 2.2, 2.2, S);
  } else {
    izq();
    der();
  }
  return b.outline().done();
}

/// kit.js: `FAM`, abuela's family, the same people in every place.
final Map<String, Who> FAM = {
  'mama': Who(
    piel: PIEL['a']!,
    pelo: PELO['castano']!,
    peinado: 'largo',
    ropa: RP.red,
    falda: true,
    zapato: hexColour('#7A1C1C'),
  ),
  'papa': Who(
    piel: PIEL['b']!,
    pelo: PELO['negro']!,
    peinado: 'corto',
    ropa: RP.blue,
    abajo: RP.wood,
  ),
  'abuelo': Who(
    piel: PIEL['a']!,
    pelo: PELO['blanco']!,
    peinado: 'calvo',
    ropa: RP.cream.sublist(1),
    abajo: RP.grey,
    bigote: true,
    gafas: 1,
    detalle: (b, X, tc, rx, t) {
      b.rect(X, tc - 8, 1, t + 6, hexColour('#B89A6A'));
      b.rect(X - 5, tc - 2, 3, 3, hexColour('#D8BC8A'));
      b.rect(X + 3, tc - 2, 3, 3, hexColour('#D8BC8A'));
    },
  ),
  'hermano': Who(
    nino: true,
    piel: PIEL['b']!,
    pelo: PELO['negro']!,
    peinado: 'corto',
    ropa: RP.grn,
    abajo: RP.blue,
    zapato: hexColour('#F2F2F8'),
  ),
  'hermana': Who(
    nino: true,
    piel: PIEL['a']!,
    pelo: PELO['castano']!,
    peinado: 'trenzas',
    ropa: hexColours(['#B8407A', '#E0609A', '#FF8FB8', '#FFB8D4']),
    falda: true,
    lazo: hexColour('#FFE070'),
    zapato: hexColour('#F2F2F8'),
  ),
};

// kit.js: mkBebe
// the baby, sitting. est = idle | clap | llora | come
Sprite mkBebe(String est, bool f) {
  final b = Buf(26, 28), X = 13, S = PIEL['a']!, Y = RP.yel;
  final hair = PELO['castano']![2], eye = hexColour('#20140A');
  b.ell(X - 5, 24.5, 3.4, 2.2, [S[2]]);
  b.ell(X + 5, 24.5, 3.4, 2.2, [S[2]]);
  b.ell(X, 19, 7, 6.4, Y.sublist(1));
  b.ell(X, 23, 5, 2.6, [hexColour('#FFFFFF'), hexColour('#F2F2F8')]);
  if (est == 'clap') {
    b.cap(X - 6, 16, X - 3 - (f ? 2 : 0), 12, 1.6, [Y[2]]);
    b.cap(X + 6, 16, X + 3 + (f ? 2 : 0), 12, 1.6, [Y[2]]);
    b.ell(X - 2 - (f ? 2 : 0), 11, 1.8, 1.8, S);
    b.ell(X + 2 + (f ? 2 : 0), 11, 1.8, 1.8, S);
  } else {
    b.cap(X - 6, 16, X - 8, 21, 1.6, [Y[2]]);
    b.cap(X + 6, 16, X + 8, 21, 1.6, [Y[2]]);
    b.ell(X - 8.5, 22.5, 1.8, 1.8, S);
    b.ell(X + 8.5, 22.5, 1.8, 1.8, S);
  }
  b.ell(X, 8, 6.4, 6.6, S);
  b.px(X, 1, hair);
  b.px(X + 1, 0, hair);
  b.px(X - 1, 2, hair);
  if (est == 'llora') {
    b.rect(X - 4, 7, 3, 1, eye);
    b.rect(X + 2, 7, 3, 1, eye);
    b.ell(X, 11.5, 2.2, 2, [hexColour('#7A1C1C')]);
    b.px(X - 4, 9 + (f ? 1 : 0), hexColour('#7CC0FF'));
    b.px(X + 4, 9 + (f ? 0 : 1), hexColour('#7CC0FF'));
  } else {
    b.px(X - 3, 7, eye);
    b.px(X + 3, 7, eye);
    b.px(X - 4, 10, hexColour('#E08A70'));
    b.px(X + 4, 10, hexColour('#E08A70'));
    if (est == 'come') {
      b.rect(X - 3, 10, 6, 3, hexColour('#F2D08A'));
      b.rect(X - 2, 10, 4, 1, hexColour('#FF8FB8'));
    } else {
      b.rect(X - 2, 11, 4, 1, hexColour('#7A2A1A'));
      b.px(X - 3, 10, hexColour('#7A2A1A'));
      b.px(X + 2, 10, hexColour('#7A2A1A'));
    }
  }
  return b.outline().done();
}

/* ---------- shared by the scenes of the park: Canelo the dog, a basket, the raised hand of "wait", a card ---------- */

// kit.js: mkPerro
Sprite mkPerro(String pose, bool f) {
  final b = Buf(30, 22),
      T = hexColours(['#8A5A2A', '#B07A3C', '#D09A54', '#E8BE80']),
      X = 13,
      Y = 12;
  final lie = pose == 'lie' || pose == 'panza',
      sit = pose == 'sit' || pose == 'eat' || pose == 'bark',
      baja = pose == 'husmea';
  if (pose == 'panza') {
    b.ell(X, 15, 10, 4.5, T);
    b.ell(X + 1, 13, 7, 2.6, [hexColour('#F4E0B8')]);
    for (final p in const [
      [-6, 9],
      [-1, 8],
      [4, 8],
      [8, 9],
    ]) {
      b.rect(X + p[0], p[1], 2, 4, T[1]);
    }
    b.ell(X + 11, 15, 4.6, 4, T);
    b.px(X + 13, 14, OUT);
    b.rect(X + 14, 16, 2, 1, OUT);
    return b.outline().done();
  }
  // tail, body, legs
  b.cap(X - 9, Y - 1, X - 12, Y - 6 + (f ? 1 : -1), 1.4, [T[1]]);
  if (lie) {
    b.ell(X, Y + 5, 10, 4, T);
    b.rect(X + 6, Y + 7, 6, 2, T[1]);
  } else if (sit) {
    b.ell(X - 1, Y + 3, 7, 6, T);
    b.rect(X + 3, Y + 4, 2, 6, T[1]);
    b.rect(X + 6, Y + 4, 2, 6, T[2]);
    b.ell(X - 4, Y + 8, 4, 2, [T[1]]);
  } else {
    final run = pose == 'run', a = f ? 1 : -1;
    b.ell(X, Y + 1, 10, 5, T);
    if (run) {
      b.cap(X - 6, Y + 4, X - 11 + a * 2, Y + 8, 1.3, [T[1]]);
      b.cap(X - 3, Y + 4, X - 7 - a * 2, Y + 9, 1.3, [T[0]]);
      b.cap(X + 5, Y + 4, X + 10 + a * 2, Y + 8, 1.3, [T[1]]);
      b.cap(X + 7, Y + 4, X + 12 - a * 2, Y + 9, 1.3, [T[2]]);
    } else {
      b.rect(X - 7 + a, Y + 5, 2, 5, T[1]);
      b.rect(X - 4 - a, Y + 5, 2, 5, T[0]);
      b.rect(X + 4 + a, Y + 5, 2, 5, T[1]);
      b.rect(X + 7 - a, Y + 5, 2, 5, T[2]);
    }
  }
  // head: one ear up, one down; a red collar
  final hx = X + 10, hy = lie ? Y + 3 : (baja ? Y + 5 : Y - 4);
  b.rect(hx - 4, hy + (baja ? -2 : 4), 5, 2, RP.red[2]);
  b.ell(hx, hy, 5, 4.6, T);
  b.ell(hx + 4, hy + 1.5, 3, 2.2, [T[3]]);
  b.cap(hx - 3, hy - 3, hx - 5, hy + 2, 1.5, [T[0]]);
  b.cap(hx + 1, hy - 4, hx + 2, hy - 7, 1.3, [T[0]]);
  b.px(hx + 1, hy - 1, OUT);
  b.px(hx + 6, hy + 1, OUT);
  if (pose == 'bark' && f) {
    b.rect(hx + 3, hy + 3, 4, 2, hexColour('#7A1C1C'));
  } else if (pose == 'eat') {
    b.rect(hx + 3, hy + 3, 3, 2, f ? hexColour('#7A1C1C') : T[3]);
  } else {
    b.px(hx + 4, hy + 3, hexColour('#7A2A1A'));
  }
  if (pose == 'lie') {
    b.rect(hx, hy - 1, 2, 1, OUT);
  }
  return b.outline().done();
}

// kit.js: mkCesta
Sprite mkCesta() {
  final b = Buf(20, 12), T = RP.orng;
  b.rect(1, 3, 18, 8, T[2]);
  for (var y = 3; y < 11; y += 2) {
    for (var x = 1; x < 19; x += 2) {
      b.px(x + (y >> 1) % 2, y, T[0]);
    }
  }
  b.rect(0, 2, 20, 2, T[3]);
  return b.outline().done();
}

// kit.js: mano
// an open raised hand: wait
const int _handSkin = 0xFF68A4E8; // "#E8A468"
const List<List<int>> _handRects = [
  [0, 4, 2, 6],
  [3, 1, 2, 9],
  [6, 0, 2, 10],
  [9, 1, 2, 9],
  [0, 9, 11, 6],
  [11, 8, 3, 3],
  [2, 15, 7, 2],
];
void mano(Ctx g, num x, num y) {
  void u(num a, num b, num w, num h, int col) => fr(g, x + a, y + b, w, h, col);
  for (final r in _handRects) {
    u(r[0] - 1, r[1] - 1, r[2] + 2, r[3] + 2, OUT);
  }
  for (final r in _handRects) {
    u(r[0], r[1], r[2], r[3], _handSkin);
  }
}

// kit.js: tarjeta
// a card for the corner of the screen
void tarjeta(Ctx g, num x, num y, num w, num h) {
  g.fillStyle = OUT;
  g.fillRect(x - 1, y, w + 2, h);
  g.fillRect(x, y - 1, w, h + 2);
  g.fillStyle = 0xFFF4FDFF; // "#FFFDF4"
  g.fillRect(x, y, w, h);
}

/* ---------- a place, from its description ---------- */

/// kit.js: `escena(d)`. The base class of the scenes after El frente.
///
/// A scene passed `escena` a description `d`; it extends this class and says the same things:
///
/// - `d.cosas`, the things that can be touched, front to back: [cosas] (`Thing`: `id`, `box` as `[x, y, w, h]` or a
///   function of W, `si`, `hand`, `m`, `z`).
/// - `d.lugar`: [lugar]. `d.CAM`: [CAM]. `d.heartAt`: [heartAt] (120, 30 when the scene does not say).
/// - `d.fresh`, `d.draw`, `d.hud`, `d.poke`, `d.stake`, `d.talkAt`, `d.respIcon`, `d.estado`: the members of [Scene] of
///   the same name.
/// - `d.acts`: [ownActs]. The kit adds the shared acts `ir`, `burbuja`, `calla`, `pose`, `fin` to the same map
///   when the scene has no act of that name, so a scene's own act can call them as `acts['ir']!(o)`.
///
/// It gives the scene [box], [hit] and [handAt], as `escena()` does, and the bird (`avePos`, `drawAve`, `aveA`,
/// `aveVa`, `aveHit`, which kit.js exports beside it).
abstract class Escena extends Scene {
  @override
  int get SW => kitSW;
  @override
  int get SH => kitSH;

  // kit.js: `heartAt:d.heartAt||[120,30]`
  @override
  List<num> get heartAt => const [120, 30];

  /// The scene's own acts (kit.js: `d.acts`).
  Map<String, Act> get ownActs => {};

  @override
  late final Map<String, Act> acts = _withSharedActs(ownActs);

  // kit.js: `for(const k in comunes)if(!(k in acts))acts[k]=comunes[k]` (the scene's own actions win)
  Map<String, Act> _withSharedActs(Map<String, Act> own) {
    final comunes = <String, Act>{
      'ir': _ir,
      'burbuja': _burbuja,
      'calla': _calla,
      'pose': _pose,
      'fin': _fin,
    };
    for (final e in comunes.entries) {
      own.putIfAbsent(e.key, () => e.value);
    }
    return own;
  }

  Map<String, dynamic> get _W => host.W;

  Map<String, dynamic> _cq() => _W['cq'] as Map<String, dynamic>;

  // kit.js: escena, cosa
  Thing? cosa(String k) {
    for (final t in cosas) {
      if (t.id == k) return t;
    }
    return null;
  }

  // kit.js: escena, B
  List<num>? _B(Thing t, Map<String, dynamic> w) {
    final b = t.box;
    return _nums(b is Function ? b(w) : b);
  }

  // kit.js: escena, ve
  bool _ve(Thing t, Map<String, dynamic> w) => t.si == null || t.si!(w);

  // kit.js: escena, box
  @override
  List<num>? box(String k, Map<String, dynamic> W) {
    final t = cosa(k);
    return t == null ? null : _B(t, W);
  }

  // kit.js: escena, hit
  @override
  String? hit(num x, num y, Map<String, dynamic> w) {
    bool inb(List<num>? b, num m) =>
        b != null &&
        x >= b[0] - m &&
        x < b[0] + b[2] + m &&
        y >= b[1] - m &&
        y < b[1] + b[3] + m;
    num slack(Thing t) => t.m ?? 3;
    for (final t in cosas) {
      if (t.z && _ve(t, w) && inb(_B(t, w), slack(t))) return t.id;
    }
    if (aveHit(x, y)) return 'pajaro';
    final q = w['cq'] as Map<String, dynamic>, fb = host.frogBox(q);
    if (_truthy(q['vis']) &&
        x >= fb.x &&
        x < fb.x + fb.w &&
        y >= fb.y &&
        y < fb.y + fb.h) {
      return 'coqui';
    }
    for (final t in cosas) {
      if (!t.z && _ve(t, w) && inb(_B(t, w), slack(t))) return t.id;
    }
    return null;
  }

  // kit.js: escena, handAt
  @override
  List<num>? handAt(String k) {
    final t = cosa(k);
    if (t == null) return null;
    if (_truthy(t.hand)) {
      final h = t.hand;
      return _nums(h is Function ? h(_W) : h);
    }
    final b = _B(t, _W)!;
    return [_round(b[0] + b[2] / 2), _round(b[1] + b[3] / 2)];
  }

  /* ---- the shared acts (kit.js: escena, comunes) ---- */

  // kit.js: comunes.ir
  Future<void> _ir(Map<String, dynamic> o) async {
    final a = o['a'], key = _truthy(a) ? a : o['en'];
    final L = key is String ? lugar[key] : null;
    if (L == null) return;
    final q = _cq();
    final dx = (q['x'] as num) - L[0], dy = (q['y'] as num) - L[1];
    final dd = math.sqrt(dx * dx + dy * dy);
    if (dd < 3) {
      q['s'] = L[2];
      return;
    }
    await host.hopTo(
      L[0],
      L[1],
      math.max(1, math.min(4, _round(dd / 30))),
      L[2],
    );
  }

  // kit.js: comunes.burbuja
  Future<void> _burbuja(Map<String, dynamic> o) async {
    if (o['quien'] == 'cq') {
      _cq()['bub'] = o['que'];
      host.SFX.coqui();
      host.bounce(6);
    } else if (_truthy(_W['ab'])) {
      (_W['ab'] as Map<String, dynamic>)['bub'] = o['que'];
    }
  }

  // kit.js: comunes.calla
  Future<void> _calla(Map<String, dynamic> o) async {
    if (_truthy(_W['ab'])) (_W['ab'] as Map<String, dynamic>)['bub'] = null;
    _cq()['bub'] = null;
  }

  // kit.js: comunes.pose
  Future<void> _pose(Map<String, dynamic> o) async {
    if (_truthy(_W['ab']))
      (_W['ab'] as Map<String, dynamic>)['pose'] = o['que'];
  }

  // kit.js: comunes.fin
  Future<void> _fin(Map<String, dynamic> o) async {
    final b = host.cam, W = _W;
    if (!_truthy(W['lost'])) {
      W['heart'] = 1;
      host.SFX.win();
      host.fx({
        't': 'star',
        'n': 40,
        'pts': [
          for (final p in [
            [b[0] + 8, b[1] + 14],
            [b[0] + b[2] - 8, b[1] + 16],
            [b[0] + b[2] / 2 - 20, b[1] + 8],
            [b[0] + b[2] / 2 + 22, b[1] + 10],
          ])
            [_round(p[0]), _round(p[1])],
        ],
      });
    } else if ((W['lost'] as num) <
        ((host.S['stake'] as Map<String, dynamic>)['steps'] as num)) {
      host.SFX.win();
    } else {
      host.SFX.coqui();
    }
    await host.wait(1700);
  }

  /* ---- the bird (kit.js: avePos, drawAve, aveA, aveVa, aveHit) ---- */

  // kit.js: avePos
  // v = {mode:none|fly|sit|head, x, y (its feet), dir, st:n|sleep|feliz|round, dip}
  List<num> avePos(Map<String, dynamic> v) {
    if (v['mode'] == 'head') {
      final q = _cq(), b = host.frogBox(q);
      return [b.x + b.w / 2, b.y + _round(q['dy'] as num) + 2];
    }
    final dip = _truthy(v['dip']) ? v['dip'] as num : 0;
    return [_round(v['x'] as num), _round((v['y'] as num) + dip)];
  }

  // kit.js: drawAve
  void drawAve(Ctx c, Map<String, dynamic>? v) {
    if (v == null || v['mode'] == 'none') return;
    final F = host.F, p = avePos(v);
    final stv = v['st'], st = _truthy(stv) ? stv as String : 'n';
    final fl = v['mode'] == 'fly' ? (F >> 1) % 2 : 0;
    final im = host.lib.spr('kave$st$fl', () => mkAve(st, fl != 0));
    final w = im.w, h = im.h;
    final dir = _truthy(v['dir']) ? v['dir'] as num : 1;
    final H = _round(h * AVK);
    c.save();
    c.smoothing = false;
    c.translate(p[0].toDouble(), (p[1] - H + 2).toDouble());
    if (_truthy(v['dip'])) {
      c.translate(0, H.toDouble());
      c.rotate(dir * .5);
      c.translate(0, -H.toDouble());
    }
    c.scale(dir * AVK, AVK);
    c.drawImage(im, -_round(w / 2), 0);
    c.restore();
    if (st == 'round') {
      // asleep
      final z = (F >> 3) % 3, zx = p[0] + 8 + z * 2, zy = p[1] - H - 9 - z * 2;
      void Z(num x, num y, int k) {
        fr(c, x - 1, y - 1, 4 * k + 2, 5 * k + 2, OUT);
        for (final r in const [
          [0, 0, 4, 1],
          [3, 1, 1, 1],
          [2, 2, 1, 1],
          [1, 3, 1, 1],
          [0, 4, 4, 1],
        ]) {
          fr(c, x + r[0] * k, y + r[1] * k, r[2] * k, r[3] * k, _white);
        }
      }

      Z(zx, zy, 2);
      Z(zx + 11, zy - 7, 1);
    }
    if (st == 'feliz' && (F >> 2) % 2 != 0) {
      fr(c, p[0] - 2, p[1] - H - 5, 2, 2, _pink);
      fr(c, p[0] + 1, p[1] - H - 5, 2, 2, _pink);
      fr(c, p[0] - 1, p[1] - H - 3, 3, 2, _pink);
    }
  }

  // kit.js: aveA
  Future<void> aveA(num tx, num ty, int n) async {
    final v = _W['ave'] as Map<String, dynamic>;
    final x0 = v['x'] as num, y0 = v['y'] as num;
    for (var i = 1; i <= n; i++) {
      final t = i / n;
      v['x'] = x0 + (tx - x0) * t;
      v['y'] = y0 + (ty - y0) * t - math.sin(math.pi * t) * 6;
      await host.wait(host.TICK);
    }
    v['x'] = tx;
    v['y'] = ty;
  }

  // kit.js: aveVa
  // the bird flies to a spot and lands there
  Future<void> aveVa(num tx, num ty, [int? n, int? dir]) async {
    final W = _W, have = W['ave'];
    if (!_truthy(have) || (have as Map<String, dynamic>)['mode'] == 'none') {
      W['ave'] = <String, dynamic>{
        'mode': 'fly',
        'x': kitSW + 12,
        'y': 30,
        'dir': -1,
        'st': 'n',
      };
    }
    final v = W['ave'] as Map<String, dynamic>, p = avePos(v);
    v['x'] = p[0];
    v['y'] = p[1];
    v['dip'] = 0;
    v['mode'] = 'fly';
    v['dir'] = tx >= (v['x'] as num) ? 1 : -1;
    host.SFX.swoop();
    await aveA(tx, ty, (n != null && n != 0) ? n : 9);
    v['mode'] = 'sit';
    if (dir != null && dir != 0) v['dir'] = dir;
  }

  // kit.js: aveHit
  bool aveHit(num x, num y) {
    final v = _W['ave'];
    if (!_truthy(v) || (v as Map<String, dynamic>)['mode'] == 'none') {
      return false;
    }
    final p = avePos(v);
    return (x - p[0]).abs() < 16 && y > p[1] - 24 && y < p[1] + 5;
  }
}
