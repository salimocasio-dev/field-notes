// What only Los estantes has in its sprite layer (the place's shared cast is lib/src/colmado/colmado_cast.dart): a can,
// a bottle, a broken bottle, the big cardboard box of the delivery (shut or open), the frog's crate, the crate of cans
// (full or tipped empty), a net holding n cans in a bunch, the little flag, don Pepe's drawing of the pyramid (on the
// wall, and in Canelo's mouth), abuela's note, the counting finger, the glasses (falling), don Pepe with his glasses on,
// and the bottle box seen from above with ten holes (drawn on the set's own projection, each pixel with its depth). The
// malts of story 41 are El mostrador's (mostrador_sprites.dart mkMalta), the señora and the señor El banco's
// (mostrador_sprites.dart mkCliente), Canelo and Luis kit.js's.
//
// Drawn in the old sprites' way (engine.js Buf: ramps, a dark outline), the size and colours of estantes-preview.html's
// stand-ins where it has one (its can, bottle, box, crates, nets, flag, drawing and bottle box). The content lane looks
// at each on docs/proyecto/pixel/port/estantes-sprites.png (tool/make_colmado_sprites_test.dart).
// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/src/colmado/colmado_cast.dart';

int _h(String s) => hexColour(s);

/* ---------- a can, a bottle (estantes-preview.html canAt, bottleAt) ---------- */

/// The label colours of the cans (estantes-preview.html's: red, blue, yellow).
const List<String> LABELS = ['#D0403A', '#4A8CE8', '#F8C838'];

// estantes-preview.html: canAt, a can 6 x 8 with its top left at (x, y)
void _canAt(Buf b, int x, int y, [String lab = '#D0403A']) {
  b.rect(x, y, 6, 8, _h('#B8B8C8'));
  b.rect(x, y, 6, 1, _h('#F2F2F8'));
  b.rect(x + 5, y, 1, 8, _h('#8E8EA0'));
  b.rect(x, y + 2, 6, 4, _h(lab));
  b.rect(x, y + 2, 1, 4, _h('#EC6050'));
  b.rect(x, y + 7, 6, 1, _h('#6E6E80'));
  b.px(x + 2, y + 3, _h('#FFF4B0'));
  b.px(x + 3, y + 4, _h('#FFF4B0'));
}

// estantes-preview.html: bottleAt, a bottle 5 x 11 with its top left at (x, y)
void _bottleAt(Buf b, int x, int y) {
  b.rect(x + 1, y, 3, 1, _h('#D0403A'));
  b.rect(x + 1, y + 1, 3, 3, _h('#5CAA5A'));
  b.rect(x, y + 4, 5, 7, _h('#5CAA5A'));
  b.rect(x + 1, y + 1, 1, 9, _h('#9CDC98'));
  b.rect(x + 4, y + 1, 1, 10, _h('#3A7A3E'));
  b.rect(x, y + 6, 5, 3, _h('#F6F0DC'));
  b.rect(x + 1, y + 7, 3, 1, _h('#D0403A'));
  b.rect(x, y + 10, 5, 1, _h('#3A7A3E'));
}

/// A can (8 x 10 with its outline), label [lab] (one of [LABELS]).
Sprite mkLata([int lab = 0]) {
  final b = Buf(8, 10);
  _canAt(b, 1, 1, LABELS[lab % LABELS.length]);
  return b.outline().done();
}

/// A bottle (7 x 13 with its outline): green, a cream label, a red cap.
Sprite mkBotella() {
  final b = Buf(7, 13);
  _bottleAt(b, 1, 1);
  return b.outline().done();
}

/// A bottle broken on the floor: green shards round a small pool.
Sprite mkBotellaRota() {
  final b = Buf(16, 7);
  b.ell(8, 4, 6.5, 2, [_h('#A8D8A0'), _h('#C8ECC0')]);
  for (final p in const [
    [2, 2, 3, 2],
    [6, 1, 2, 3],
    [10, 2, 3, 2],
    [13, 4, 2, 1],
    [4, 4, 2, 1],
  ]) {
    b.rect(p[0], p[1], p[2], p[3], _h('#3A7A3E'));
    b.px(p[0], p[1], _h('#9CDC98'));
  }
  b.rect(8, 4, 2, 1, _h('#F6F0DC'));
  return b.outline().done();
}

/* ---------- the big cardboard box of story 39 ---------- */

/// The big cardboard box's size (its sprite) and where its goods stand in it: each can's and each bottle's top left in
/// the box's sprite, the cans on the left, the bottles on the right (so a touch on one kind is never on the other).
const int CAJA_W = 42, CAJA_H = 24, CAJA_FRENTE = 10;

/// The top left of the i-th can (0 to 2) in the box's sprite.
({int x, int y}) cajaLata(int i) => (x: 3 + i * 6, y: CAJA_FRENTE - 6);

/// The top left of the i-th bottle (0 to 2) in the box's sprite.
({int x, int y}) cajaBotella(int i) => (x: 23 + i * 6, y: CAJA_FRENTE - 9);

/// The big cardboard box of the delivery (estantes-preview.html `caja`): [abierta] its flaps open and its dark inside
/// showing (the goods in it are sprites of their own, drawn behind its front), else its top shut, taped.
Sprite mkCajaGrande(bool abierta) {
  final b = Buf(CAJA_W, CAJA_H);
  final C = [_h('#8A5A2A'), _h('#B07A3C'), _h('#C8853C'), _h('#E2A85A')];
  const y0 = CAJA_FRENTE, x0 = 3, w = CAJA_W - 6, h = CAJA_H - CAJA_FRENTE - 1;
  if (abierta) {
    b.rect(
      x0 + 1,
      y0 - 2,
      w - 2,
      2,
      _h('#5A3A1A'),
    ); // the dark inside, behind the goods
    b.line(x0, y0, x0 - 3, y0 - 5, C[1]);
    b.line(x0 + 1, y0, x0 - 2, y0 - 5, C[1]);
    b.line(x0 + w - 1, y0, x0 + w + 2, y0 - 5, C[0]);
    b.line(x0 + w - 2, y0, x0 + w + 1, y0 - 5, C[0]); // the flaps, opened out
  } else {
    b.rect(x0, y0 - 4, w, 4, C[3]);
    b.rect(x0 + w ~/ 2 - 2, y0 - 4, 4, 4, _h('#E8D2A0')); // the top shut, taped
  }
  b.rect(x0, y0, w, h, C[2]);
  b.rect(x0, y0, w, 1, C[3]);
  b.rect(x0, y0 + h - 1, w, 1, C[0]);
  b.rect(x0 + w - 3, y0, 3, h, C[1]); // the darker side
  b.rect(x0 + w ~/ 2 - 2, y0, 4, h, _h('#E8D2A0')); // the tape
  return b.outline().done();
}

/* ---------- crates (estantes-preview.html crate) ---------- */

// estantes-preview.html: crate(wd, ht, full): the front ht high, cans standing in it (two rows of five) when full
Sprite _crate(int wd, int ht, bool full) {
  final top = full ? 14 : 3;
  final b = Buf(wd + 2, ht + top);
  final T = RP.wood;
  if (full) {
    for (var j = 0; j < 2; j++) {
      for (var i = 0; i < 5; i++) {
        _canAt(
          b,
          1 + ((wd - 30) / 2 + .5).floor() + i * 6,
          top - 6 - (j != 0 ? 0 : 3),
        );
      }
    }
  }
  b.rect(1, top, wd, ht, T[2]);
  b.rect(1, top, wd, 1, T[4]);
  for (var y = top + 4; y < top + ht - 1; y += 4) {
    b.rect(1, y, wd, 1, T[1]);
  }
  b.rect(1, top, 2, ht, T[1]);
  b.rect(wd - 1, top, 2, ht, T[1]);
  b.rect(1, top + ht - 1, wd, 1, T[0]);
  return b.outline().done();
}

/// The frog's low crate (story 39: he stands on it), .3 high (estantes-preview.html `cajon`).
Sprite mkCajon() => _crate(26, 6, false);

/// The crate of cans of story 40 (`cajon_latas`), full, or tipped to show it empty ([lleno] false).
Sprite mkCajonLatas(bool lleno) => _crate(32, 8, lleno);

/* ---------- a net of cans (estantes-preview.html red) ---------- */

/// How the cans of a net of [n] (2 to 7) lie, row by row from the bottom: each can's top left in the net's sprite and
/// its label. The preview's nets of six and four; the others in the same way (rows of three or four, a can apart).
List<({int x, int y, int lab})> redLayout(int n) {
  const rowsOf = {
    1: [1],
    2: [2],
    3: [2, 1],
    4: [3, 1],
    5: [3, 2],
    6: [3, 2, 1],
    7: [4, 3],
  };
  final rows = rowsOf[n.clamp(1, 7)]!;
  final widest = rows.reduce(math.max);
  final out = <({int x, int y, int lab})>[];
  for (var r = 0; r < rows.length; r++) {
    final k = rows[r], x0 = 2 + (widest - k) * 3;
    for (var i = 0; i < k; i++) {
      final x = x0 + i * 6, y = 5 + (rows.length - 1 - r) * 5 + (i + r) % 2;
      out.add((x: x, y: y, lab: (x + y) % 3));
    }
  }
  return out;
}

/// The size of the net of [n] cans.
({int w, int h}) redSize(int n) {
  final l = redLayout(n);
  return (
    w: l.map((c) => c.x).reduce(math.max) + 6 + 3,
    h: l.map((c) => c.y).reduce(math.max) + 8 + 2,
  );
}

/// A net bag of [n] cans in a loose bunch, its cord up to a knot (estantes-preview.html `red`): a lattice over the cans.
Sprite mkRed(int n) {
  if (n <= 0) {
    // an empty net, lying flat
    final b = Buf(14, 4);
    b.rect(1, 1, 12, 2, _h('#E8B060'));
    return b.outline().done();
  }
  final l = redLayout(n), sz = redSize(n);
  final b = Buf(sz.w, sz.h);
  final sorted = [...l]..sort((p, q) => p.y.compareTo(q.y));
  for (final c in sorted) {
    _canAt(b, c.x, c.y, LABELS[c.lab]);
  }
  final cx = sz.w ~/ 2;
  for (var y = 4; y < sz.h - 1; y++) {
    for (var x = 1; x < sz.w - 1; x++) {
      if (b.has(x, y) && (x + y) % 4 == 0) b.px(x, y, _h('#E8B060'));
    }
  }
  b.line(cx - 3, 6, cx - 1, 1, _h('#E8B060'));
  b.line(cx + 3, 6, cx + 1, 1, _h('#E8B060'));
  b.rect(cx - 1, 1, 3, 3, _h('#A8682C'));
  b.px(cx, 0, _h('#A8682C'));
  return b.outline().done();
}

/* ---------- the flag, the drawing, the note, the finger, the glasses ---------- */

/// The little flag on top of the pyramid (estantes-preview.html `bandera`).
Sprite mkBandera() {
  final b = Buf(10, 13);
  b.rect(1, 1, 1, 11, _h('#8A5A2A'));
  b.rect(2, 1, 3, 3, _h('#2E6CD0'));
  b.rect(5, 1, 3, 3, _h('#D0403A'));
  b.rect(2, 4, 3, 2, _h('#D0403A'));
  b.rect(5, 4, 3, 2, _h('#2E6CD0'));
  b.rect(4, 1, 1, 5, _h('#FAFAFA'));
  b.rect(2, 3, 6, 1, _h('#FAFAFA'));
  return b.outline().done();
}

/// Don Pepe's drawing pinned to the wall: a sheet of paper with a pyramid of cans and its flag (estantes-preview.html
/// `papel`).
Sprite mkPapel() {
  final b = Buf(14, 17);
  b.rect(1, 1, 12, 15, _h('#F6F0DC'));
  b.rect(11, 14, 2, 2, _h('#D8D2BC'));
  b.rect(1, 15, 12, 1, _h('#C8C2AC'));
  b.rect(12, 1, 1, 15, _h('#E4DEC8'));
  b.rect(6, 1, 2, 2, _h('#D0403A'));
  final ink = _h('#4A4A5A');
  b.line(7, 5, 3, 13, ink);
  b.line(7, 5, 11, 13, ink);
  b.line(3, 13, 11, 13, ink);
  b.line(5, 9, 9, 9, ink);
  b.line(4, 11, 10, 11, ink);
  b.line(7, 9, 7, 13, _h('#8A8A9A'));
  return b.outline().done();
}

/// Canelo running with the drawing in his mouth (kit.js mkPerro 'run', the paper folded at his muzzle), facing right.
Sprite mkPerroPapel(bool f) {
  final dog = mkPerro('run', f);
  final b = Buf(8, 9);
  b.rect(1, 1, 6, 7, _h('#F6F0DC'));
  b.rect(6, 1, 1, 7, _h('#D8D2BC'));
  b.line(2, 5, 4, 2, _h('#4A4A5A'));
  b.line(4, 2, 6, 5, _h('#4A4A5A'));
  return overSprite(dog, [(b.outline().done(), 30 - 10, 12 - 4 - 3)]);
}

/// Abuela's note (story 41): a slip of paper with a box of ten bottles drawn on it, two rows of five.
Sprite mkNota() {
  final b = Buf(16, 12);
  b.rect(1, 1, 14, 10, _h('#F6F0DC'));
  b.rect(14, 1, 1, 10, _h('#E4DEC8'));
  b.frame(2, 3, 12, 6, _h('#8A5A2A'));
  for (var j = 0; j < 2; j++) {
    for (var i = 0; i < 5; i++) {
      b.px(3 + i * 2, 4 + j * 2, _h('#5CAA5A'));
    }
  }
  return b.outline().done();
}

/// A finger pointing down, on each thing as it is counted (the Needs' `cuenta`: "a finger goes along n things").
Sprite mkDedo() {
  final b = Buf(7, 10);
  const skin = 0xFF68A4E8; // kit.js mano's skin, "#E8A468"
  b.rect(2, 0, 3, 4, skin);
  b.rect(1, 3, 5, 3, skin);
  b.rect(3, 6, 1, 3, skin);
  b.px(2, 6, skin);
  return b.outline().done();
}

/// Don Pepe's glasses, falling (two round lenses on a dark wire).
Sprite mkGafas() {
  final b = Buf(11, 6);
  final dark = _h('#2A1810'), glass = _h('#BCE0F4');
  b.frame(1, 1, 4, 4, dark);
  b.frame(6, 1, 4, 4, dark);
  b.rect(2, 2, 2, 2, glass);
  b.rect(7, 2, 2, 2, glass);
  b.px(5, 2, dark);
  return b.done();
}

/// Don Pepe with his glasses on his nose (mkPersona's `gafas: 1`), in the poses of [mkPepe] this scene uses: `idle`,
/// `saluda0`, `saluda1`, `alcanza`, `escalera_alto`, `mano`, `escalera`. Without [gafas] it is the cast's mkPepe.
Sprite mkPepeGafas(String pose, {bool open = false, bool gafas = true}) {
  if (!gafas) return mkPepe(pose, open: open);
  final w = PEPE.copyWith(gafas: 1);
  switch (pose) {
    case 'saluda0':
    case 'saluda1':
      return mkPersona(w, pose == 'saluda0' ? 'wave0' : 'wave1', open, false);
    case 'alcanza':
    case 'escalera_alto':
      return mkPersona(w, 'wave0', open, false);
    case 'mano':
      return mkPersona(w, 'offer', open, false);
    case 'escalera':
      return mkPersona(w, 'ojos', open, false);
    default:
      return mkPersona(w, 'idle', open, false);
  }
}

/* ---------- the bottle box seen from above (estantes-preview.html botellero) ---------- */

/// A sprite that carries the depth of each of its pixels ([z], -1e9 where it draws nothing), and the point of it that
/// is on its spot's screen point ([ax], [ay]).
typedef FlatSprite = ({Sprite s, Float32List z, int ax, int ay});

/// The top of the bottle box (estantes-preview.html BOX_H) and the radius of a hole (HOLE_R).
const double BOX_H = .14, HOLE_R = .085;

/// The world point of hole [k] (0 to 9: two rows of five, along x) of a box whose middle is [c] (x, y) and footprint
/// [f] (along x, along y): where a bottle top is, at the box's top height.
List<double> holeAt(List<double> c, List<double> f, int k) {
  final x0 = c[0] - f[0] / 2, y0 = c[1] - f[1] / 2, i = k % 5, j = k ~/ 5;
  return [x0 + (i + .5) * f[0] / 5, y0 + (j + .5) * f[1] / 2, BOX_H];
}

/// The bottle box lying on the floor with its middle at world point [c] and its footprint [f] (1.0 x .5, the long side
/// along x), .14 high: ten holes (two rows of five) and [n] bottle tops, drawn pixel by pixel from engine [e]'s own
/// projection (estantes-preview.html `botellero`, pixel for pixel): the top face, the front face (y = y1) and the right
/// face (x = x1), the rim, a dark outline at the depth of its neighbour.
FlatSprite mkBotellero(PpEngine e, List<double> c, List<double> f, int n) {
  final cx = c[0], cy = c[1], fw = f[0], fd = f[1];
  final x0 = cx - fw / 2, x1 = cx + fw / 2, y0 = cy - fd / 2, y1 = cy + fd / 2;
  const h = BOX_H;
  final R2 = math.sqrt2, COS = math.sqrt(3) / 2;
  const SIN = .5;
  var mx0 = 1e9, mx1 = -1e9, my0 = 1e9, my1 = -1e9;
  for (final x in [x0, x1]) {
    for (final y in [y0, y1]) {
      for (final z in [0.0, h]) {
        final p = e.project(x, y, z);
        mx0 = math.min(mx0, p.sx);
        mx1 = math.max(mx1, p.sx);
        my0 = math.min(my0, p.sy);
        my1 = math.max(my1, p.sy);
      }
    }
  }
  final bx0 = mx0.floor() - 1,
      bx1 = mx1.ceil() + 1,
      by0 = my0.floor() - 1,
      by1 = my1.ceil() + 1;
  final cw = bx1 - bx0, ch = by1 - by0;
  final px = Uint32List(cw * ch),
      zmap = Float32List(cw * ch)..fillRange(0, cw * ch, -1e9);
  double dep(double x, double y, double z) => (x + y) / R2 * COS + z * SIN;
  void put(int qx, int qy, int col, double d) {
    px[qy * cw + qx] = col;
    zmap[qy * cw + qx] = d;
  }

  final cap = [_h('#D0403A'), _h('#E8B030')];
  final rim = _h('#E2A85A'), card = _h('#C8853C'), hole = _h('#3A2414');
  final gold = _h('#F6D870');
  for (var qy = 0; qy < ch; qy++) {
    for (var qx = 0; qx < cw; qx++) {
      final sx = bx0 + qx + .5, sy = by0 + qy + .5, u = (sx - e.OX) / e.S;
      // the top face: the floor point under the pixel, at the box's top height
      final v = ((sy - e.OY) / e.S + h * COS) / SIN,
          x = (u + v) / R2,
          y = (v - u) / R2;
      if (x >= x0 && x <= x1 && y >= y0 && y <= y1) {
        final i = math.min(4, ((x - x0) / fw * 5).floor()),
            j = math.min(1, ((y - y0) / fd * 2).floor());
        final hx = x0 + (i + .5) * fw / 5, hy = y0 + (j + .5) * fd / 2;
        final r = math.sqrt((x - hx) * (x - hx) + (y - hy) * (y - hy)),
            k = j * 5 + i;
        var col =
            math.min(math.min(x - x0, x1 - x), math.min(y - y0, y1 - y)) < .04
            ? rim
            : card;
        if (r <= HOLE_R) {
          col = k < n ? (r < HOLE_R * .45 ? gold : cap[k % 2]) : hole;
        }
        put(qx, qy, col, dep(x, y, h));
        continue;
      }
      // the front face (the plane y = y1) and the right face (the plane x = x1), z from 0 to h
      final xf = y1 + u * R2,
          vf = (xf + y1) / R2,
          zf = (vf * SIN - (sy - e.OY) / e.S) / COS;
      if (xf >= x0 && xf <= x1 && zf >= 0 && zf <= h) {
        put(
          qx,
          qy,
          zf > h - .03 ? _h('#B88040') : _h('#92602E'),
          dep(xf, y1, zf),
        );
        continue;
      }
      final yr = x1 - u * R2,
          vr = (x1 + yr) / R2,
          zr = (vr * SIN - (sy - e.OY) / e.S) / COS;
      if (yr >= y0 && yr <= y1 && zr >= 0 && zr <= h) {
        put(
          qx,
          qy,
          zr > h - .03 ? _h('#A8702E') : _h('#6E4220'),
          dep(x1, yr, zr),
        );
      }
    }
  }
  // the outline: a dark pixel round the picture's edge, at the depth of its neighbour
  bool has(int qx, int qy) =>
      qx >= 0 && qy >= 0 && qx < cw && qy < ch && px[qy * cw + qx] >>> 24 != 0;
  final add = <(int, int, double)>[];
  for (var qy = 0; qy < ch; qy++) {
    for (var qx = 0; qx < cw; qx++) {
      if (has(qx, qy)) continue;
      for (final d in const [
        [-1, 0],
        [1, 0],
        [0, -1],
        [0, 1],
      ]) {
        if (has(qx + d[0], qy + d[1])) {
          add.add((qx, qy, zmap[(qy + d[1]) * cw + qx + d[0]]));
          break;
        }
      }
    }
  }
  for (final (qx, qy, d) in add) {
    put(qx, qy, OUT, d);
  }
  final sp = e.project(cx, cy, 0);
  return (
    s: Sprite(cw, ch, px),
    z: zmap,
    ax: (sp.sx + .5).floor() - bx0,
    ay: (sp.sy + .5).floor() - by0,
  );
}

/// Every sprite this file draws, in order, for the sheet picture (estantes-sprites.png). The bottle box seen from above
/// is drawn on [e] (the set's engine) at the sheet's abuela's box, with 7, 8, 9 and 10 bottles.
List<(String, Sprite)> estantesSpriteSheet(
  PpEngine e,
  List<double> caja,
  List<double> footprint,
) => [
  for (var i = 0; i < 3; i++) ('lata ${i + 1}', mkLata(i)),
  ('botella', mkBotella()),
  ('botella rota', mkBotellaRota()),
  ('caja grande, cerrada', mkCajaGrande(false)),
  ('caja grande, abierta', mkCajaGrande(true)),
  ('cajon de coqui', mkCajon()),
  ('cajon de latas, lleno', mkCajonLatas(true)),
  ('cajon de latas, vacio', mkCajonLatas(false)),
  for (var n = 2; n <= 7; n++) ('red de $n latas', mkRed(n)),
  ('bandera', mkBandera()),
  ('dibujo de don Pepe', mkPapel()),
  ('Canelo con el dibujo', mkPerroPapel(false)),
  ('nota de abuela', mkNota()),
  ('dedo que cuenta', mkDedo()),
  ('gafas', mkGafas()),
  for (final p in const ['idle', 'mano', 'escalera', 'escalera_alto'])
    ('pepe con gafas, $p', mkPepeGafas(p)),
  for (final n in const [7, 8, 9, 10])
    ('caja de botellas desde arriba, $n', mkBotellero(e, caja, footprint, n).s),
];
