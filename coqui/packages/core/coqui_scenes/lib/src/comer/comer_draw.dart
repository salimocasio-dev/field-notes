// What comer.js's draw() draws, line for line (comer.js:284 to :571 and the moved pieces of moves lines 21 and 548): the
// things (cosa, tenida, tenidaC, fuenteComp), the steam with its darker edge (the sheet's helps), the streams, the long
// spoons, the arms that bend, the hands, the bodies, the frog, the thoughts, the dog, the empty speech bubble of the words
// hidden (hab, LIBRE) and the answer cards' place (CARTAS).
// ignore_for_file: non_constant_identifier_names, constant_identifier_names
part of 'comer.dart';

// comer.js:423 GRIP. Where things are held: the hand's place from the thing's middle (a third number: held in both hands)
const Map<String, List<num>> GRIP = {
  'tazacu': [6, 3],
  'rollo': [-4, 2],
  'plato': [0, 3],
  'taza': [6, 3],
  'tenedor': [0, 3],
  'cuchara': [0, 4],
  'muslo': [8, 0],
  'vasojugo': [0, 2],
  'bizcochoT': [2, 6],
  'bizcochoL': [5, 8],
  'bebe': [0, 8],
  'bebeH': [0, 8],
  'pano': [0, 0],
  'cafetera': [7, 6],
  'jarrita': [5, 2],
  'cazo': [6, 1],
  'bandeja': [10, 3, 1],
  'olla': [10, 1, 1],
  'fuente': [11, 2, 1],
  'tenedorH': [0, 0],
  'monton': [0, 2],
  'platoma': [0, 6],
  'platoH': [0, 6],
  'bizcocho': [0, 4],
  'jarra': [0, 2],
  'jugo': [0, 2],
};

// comer.js:426 CONASA. What has its handle on the right of the drawing: it is turned so that the handle is on the side
// of his body
const Set<String> CONASA = {'taza', 'cafetera', 'jarrita', 'cazo'};

// a hand's place, an arm's end: {x, y, s (the side of the picture: -1 left, 1 right), it, k}
class _Hand {
  _Hand(this.x, this.y, this.s, this.it, this.k);
  final num x, y;
  int s;
  final M? it;
  final String k;
}

extension _Draw on Comer {
  /* ---------- the things ---------- */

  // comer.js: cosa (here cosaSpr: the kit's Escena has a cosa of its own, a thing by its key)
  Sprite cosaSpr(String k, [Object? c]) =>
      spr('cm$k${c == null ? '' : _js(c)}', () => cosaIm(k, c));

  // comer.js: tenidaC. A thing drawn by its middle (x,y), at esc times its size; flip turns it over (to the right).
  // Smoothing is off: it never blurs
  void tenidaC(
    Ctx c,
    String k,
    num x,
    num y, [
    Object? esc,
    Object? v,
    Object? flip,
  ]) {
    final im = cosaSpr(k, v), e = _or(esc, 1), w = im.w * e, h = im.h * e;
    c.save();
    c.smoothing = false;
    if (jsTruthy(flip)) {
      c.translate(_round(x).toDouble(), _round(y).toDouble());
      c.scale(-1, 1);
      c.drawImage(im, _round(-w / 2), _round(-h / 2), w, h);
    } else {
      c.drawImage(im, _round(x - w / 2), _round(y - h / 2), w, h);
    }
    c.restore();
  }

  // comer.js: tenida. A thing drawn by its foot (the middle of its bottom edge)
  void tenida(
    Ctx c,
    String k,
    num x,
    num y, [
    Object? ang,
    Object? esc,
    Object? v,
  ]) {
    final im = cosaSpr(k, v), e = _or(esc, 1);
    c.save();
    c.smoothing = false;
    c.drawImage(
      im,
      _round(x - im.w * e / 2),
      _round(y - im.h * e),
      im.w * e,
      im.h * e,
    );
    c.restore();
  }

  // comer.js: fuenteComp. The platter with its mounds and the fork on it, in one picture (so that it can be tipped as a
  // whole)
  Sprite fuenteComp(M it) {
    final cv = Sprite(52, 26, Uint32List(52 * 26)), g = Ctx(cv.px, 52, 26);
    g.smoothing = false;
    g.drawImage(cosaSpr('fuente', it['v']), 0, 0);
    for (final m in _byDy((it['montones'] as List?) ?? const [])) {
      final im = cosaSpr('monton');
      g.drawImage(
        im,
        _round(26 + (m['dx'] as num) - im.w / 2),
        _round(13 + 8.5 + (m['dy'] == null ? -4 : m['dy'] as num) - im.h / 2),
      );
    }
    if (jsTruthy(it['tenedor'])) {
      final t = it['tenedor'] as M, im = cosaSpr('tenedorH');
      g.drawImage(
        im,
        _round(26 + (t['dx'] as num) - im.w / 2),
        _round(13 + 9 - (t['dy'] as num) - im.h / 2),
      );
    }
    return cv;
  }

  // JavaScript: `.slice().sort((m,n)=>(m.dy||0)-(n.dy||0))`, a stable sort
  List<M> _byDy(List l) {
    final idx = [...l.cast<M>().indexed]
      ..sort((a, b) {
        final d = _n(a.$2['dy']).compareTo(_n(b.$2['dy']));
        return d != 0 ? d : a.$1.compareTo(b.$1);
      });
    return [for (final e in idx) e.$2];
  }

  /* ---------- what is drawn by hand: steam, a stream, a long spoon, an arm ---------- */

  // comer.js: ovalo
  void ovalo(Ctx c, num cx, num cy, num rx, num ry, int col) {
    for (var j = -ry; j <= ry; j++) {
      final hw = _round(
        rx * math.sqrt(math.max(0, 1 - (j * j) / ((ry + .5) * (ry + .5)))),
      );
      fr(c, cx - hw, cy + j, 2 * hw + 1, 1, col);
    }
  }

  // comer.js: vapor. Steam: two soft wisps that rise, sway and fade (the sheet's helps.lines: a darker blue-grey edge on
  // both sides of each wisp, #5C6C92, 4 px, for the old one-sided #B8C4D4)
  void vapor(Ctx c, num x, num y, [Object? n, Object? h]) {
    final t = (F >> 2) % 12, H = math.min(_or(h, 9), 9);
    c.save();
    for (var i = 0; i < _or(n, 2); i++) {
      final dx = i * 7 - 3;
      for (var k = 0; k < H; k++) {
        final sw = _round(math.sin((k + t * 1.2 + i * 4) / 2.4) * 2.4);
        c.globalAlpha = math.max(.12, .85 - k * 14 / H * .065).toDouble();
        fr(c, x + dx + sw - 1, y - k, 4, 1, hx('#5C6C92'));
        fr(c, x + dx + sw, y - k, 2, 1, hx('#FFFFFF'));
      }
    }
    c.restore();
  }

  // comer.js: chorro. A stream falling from y0 to y1: 4 pixels wide, solid, it leaves the lip sideways (dir: -1 to the
  // left, 1 to the right) and bends down, and splashes
  void chorro(
    Ctx c,
    num x,
    num y0,
    num y1,
    String col0, [
    Object? dir,
    Object? fino,
  ]) {
    if (y1 <= y0) return;
    final col = hx(col0);
    if (jsTruthy(fino)) {
      // a thin straight stream, 2 px wide (milk into a cup), with a small ripple where it lands
      final h = y1 - y0;
      fr(c, x - 2, y0, 1, h, OUT);
      fr(c, x + 1, y0, 1, h, OUT);
      fr(c, x - 1, y0, 2, h, col);
      fr(c, x - 2, y1, 4, 1, col);
      return;
    }
    // milk is a thick white stream (6 px), coffee a thinner one
    final dd = _or(dir, -1),
        n = y1 - y0,
        wd = RegExp(r'^#F[BF]F[BF]F[4F]$', caseSensitive: false).hasMatch(col0)
            ? 6
            : 4,
        h2 = wd >> 1;
    for (var j = 0; j < n; j++) {
      final t = j / math.max(1, n),
          off = dd * _round(3 * (1 - math.pow(1 - t, 2)) * math.min(1, n / 6)),
          xx = x + off;
      fr(c, xx - h2 - 1, y0 + j, 1, 1, OUT);
      fr(c, xx + h2, y0 + j, 1, 1, OUT);
      fr(c, xx - h2, y0 + j, wd, 1, col);
    }
    final t = F % 4, xb = x + dd * 3;
    fr(c, xb - 4, y1 - 1, 9, 2, OUT);
    fr(c, xb - 3, y1 - 1, 7, 1, col);
    if (t < 2) {
      fr(c, xb - 5, y1 - 3, 2, 2, col);
      fr(c, xb + 4, y1 - 4, 1, 2, col);
    } else {
      fr(c, xb + 4, y1 - 3, 2, 2, col);
      fr(c, xb - 5, y1 - 4, 1, 2, col);
    }
  }

  // comer.js: trazo. A thick line (an arm, a handle) with a dark edge
  void trazo(Ctx c, num x0, num y0, num x1, num y1, int col, [num? ancho]) {
    final n = math.max(1, math.max((x1 - x0).abs(), (y1 - y0).abs()).ceil()),
        a = ancho == null || ancho == 0 ? 2 : ancho;
    for (var i = 0; i <= n; i++) {
      final x = _round(x0 + (x1 - x0) * i / n),
          y = _round(y0 + (y1 - y0) * i / n);
      fr(c, x - 1, y - 1, a + 2, a + 2, OUT);
    }
    for (var i = 0; i <= n; i++) {
      final x = _round(x0 + (x1 - x0) * i / n),
          y = _round(y0 + (y1 - y0) * i / n);
      fr(c, x, y, a, a, col);
    }
  }

  // comer.js: mano. A hand: a skin block with a dark edge, a little lighter on its upper side
  void _mano(Ctx c, num x, num y, [int? pi]) {
    final k = pi ?? RP.skin[2];
    fr(c, _round(x) - 3, _round(y) - 3, 6, 6, OUT);
    fr(c, _round(x) - 2, _round(y) - 2, 4, 4, k);
    fr(c, _round(x) - 2, _round(y) - 2, 2, 1, hx('#F4D8B8'));
  }

  // comer.js: cucharon. A long spoon: its handle from the hand (x0,y0) to its bowl (x1,y1); the bowl faces us. load: what
  // is in it ("monton" rice, "azu" sugar, "c"/"m" chocolate / butter, "" nothing)
  void cucharon(
    Ctx c,
    num x0,
    num y0,
    num x1,
    num y1,
    Object? load,
    Object? o0,
  ) {
    final o = (o0 as Map?) ?? const {};
    final mad = jsTruthy(o['plata'])
        ? [hx('#C8C8D4'), hx('#8A8A9A'), hx('#F8F8FF')]
        : [hx('#B07A3C'), hx('#8A5A2A'), hx('#D09A54')];
    // the handle: 2 px, a hand long; the bowl: a small oval, smaller than a fist
    trazo(c, x0, y0, x1, y1, mad[0], 2);
    final rx = _or(o['rx'], 2),
        ry = _or(o['ry'], 1),
        cx = _round(x1),
        cy = _round(y1);
    ovalo(c, cx, cy, rx + 1, ry + 1, OUT);
    ovalo(c, cx, cy, rx, ry, mad[1]);
    ovalo(c, cx, cy, math.max(1, rx - 1), math.max(0, ry - 1), mad[2]);
    void heap(num w, num h, int col, [int? hi]) {
      ovalo(c, cx, cy - 1, w + 1, h + 1, OUT);
      ovalo(c, cx, cy - 1, w, h, col);
      if (hi != null) fr(c, cx - math.max(0, w - 2), cy - 1 - h + 1, 1, 1, hi);
    }

    if (load == 'monton') {
      heap(2, 1, hx('#F2C028'), hx('#FFF4B0'));
    } else if (load == 'monton1') {
      heap(1, 1, hx('#F2C028'), hx('#FFF4B0'));
    } else if (load == 'azu') {
      // sugar: off-white grains in a small heap
      heap(rx, 1, hx('#FFFFFF'), hx('#B4BEE0'));
      fr(c, cx + 1, cy - 1, 1, 1, hx('#C8D0E8'));
    } else if (load == 'azuM') {
      // a teaspoon heaped with white sugar: a white mound over the bowl, a few grains showing, one light-blue glint
      ovalo(c, cx, cy - 3, 4, 3, OUT);
      ovalo(c, cx, cy - 3, 3, 2, hx('#FFFFFF'));
      ovalo(c, cx, cy - 4, 2, 1, hx('#FFFFFF'));
      fr(c, cx - 2, cy - 2, 1, 1, hx('#B4C0E0'));
      fr(c, cx + 1, cy - 3, 1, 1, hx('#B4C0E0'));
      fr(c, cx + 2, cy - 2, 1, 1, hx('#B4C0E0'));
      fr(c, cx - 1, cy - 5, 1, 1, hx('#9CD8FF'));
    } else if (load == 'ARR') {
      // one huge heaped spoonful of yellow rice
      ovalo(c, cx, cy - 3, 5, 3, OUT);
      ovalo(c, cx, cy - 3, 4, 2, ARROZ[1]);
      ovalo(c, cx, cy - 4, 3, 1, ARROZ[2]);
      for (final g in const [
        [-3, -3],
        [2, -2],
        [3, -3],
        [-1, -4],
        [0, -2],
        [-2, -5],
      ]) {
        fr(
          c,
          cx + g[0],
          cy + g[1],
          1,
          1,
          hs(g[0] + 9, g[1] + 9) % 2 != 0 ? hx('#FFF4B0') : hx('#B87A10'),
        );
      }
    } else if (load == 'c') {
      ovalo(c, cx, cy - 1, rx, 1, CHOC[1]);
      fr(c, cx - 1, cy - 2, 1, 1, hx('#C89A74'));
    } else if (load == 'm') {
      ovalo(c, cx, cy - 1, rx, 1, MANT);
      fr(c, cx - 1, cy - 2, 1, 1, hx('#FFFBE0'));
    }
  }

  /* ---------- drawing people ---------- */

  // comer.js: hombroY, bocaY. Where things are held: the shoulder and the mouth of each, from his feet (up)
  int hombroY(String id, M p) {
    final sent = jsTruthy(p['sent']);
    return id == 'abuela'
        ? (sent ? 25 : 27)
        : Comer.NINO(id)
        ? (sent ? 19 : 22)
        : (sent ? 27 : 34);
  }

  int bocaY(String id, M p) {
    final sent = jsTruthy(p['sent']);
    return id == 'abuela'
        ? (sent ? 33 : 35)
        : Comer.NINO(id)
        ? (sent ? 25 : 28)
        : (sent ? 33 : 40);
  }

  // comer.js: sleeve, piel
  int sleeve(String id) =>
      id == 'abuela' ? RP.purp[1] : (QUIEN[id]?.ropa ?? RP.cream)[1];
  int piel(String id) =>
      id == 'abuela' ? RP.skin[2] : (QUIEN[id]?.piel ?? RP.skin)[2];

  // comer.js: brazoJ. An arm of two bones (L each): shoulder (sx,sy) to hand (hx,hy), with an elbow, a sleeve and a
  // hand. lado: -1 the arm on the left of the picture, 1 on the right (the elbow goes out and down). (window.__ALC, the
  // old page's list of hands too far for their arm, is a check of its own maker's: not kept)
  List<num> brazoJ(
    Ctx c,
    num sx,
    num sy,
    num hx,
    num hy,
    num L,
    int sl,
    int pi,
    int lado, [
    String? quien,
  ]) {
    final d0 = _hypot(hx - sx, hy - sy), d = d0 == 0 ? .01 : d0;
    final dd = math.min(d, 2 * L - .4),
        ux = (hx - sx) / d,
        uy = (hy - sy) / d,
        a = dd / 2,
        h = math.sqrt(math.max(0, L * L - a * a)),
        nx = -uy,
        ny = ux;
    final e1 = [sx + ux * a + nx * h, sy + uy * a + ny * h],
        e2 = [sx + ux * a - nx * h, sy + uy * a - ny * h];
    final e = uy.abs() > ux.abs() * 1.3
        ? ((e1[0] - sx) * lado > (e2[0] - sx) * lado ? e1 : e2)
        : (e1[1] > e2[1] ? e1 : e2);
    void seg(num x0, num y0, num x1, num y1, void Function(int x, int y) f) {
      final n = math.max(1, math.max((x1 - x0).abs(), (y1 - y0).abs()).ceil());
      for (var i = 0; i <= n; i++) {
        f(_round(x0 + (x1 - x0) * i / n), _round(y0 + (y1 - y0) * i / n));
      }
    }

    // the upper arm is as thick as 4 (3 for a child) pixels, in his sleeve; the forearm is bare skin, 3
    final th = L >= 8 ? 4 : 3;
    seg(sx, sy, e[0], e[1], (x, y) => fr(c, x - 2, y - 2, th + 2, th + 2, OUT));
    seg(e[0], e[1], hx, hy, (x, y) => fr(c, x - 2, y - 2, 5, 5, OUT));
    seg(sx, sy, e[0], e[1], (x, y) => fr(c, x - 1, y - 1, th, th, sl));
    seg(e[0], e[1], hx, hy, (x, y) => fr(c, x - 1, y - 1, 3, 3, pi));
    return e;
  }

  // comer.js: agarres. The hands that hold thing it, its middle at (ix, iy) (fl: turned over)
  List<List<num>> agarres(M it, num ix, num iy, Object? fl) {
    final k = _js(it['k']);
    final base = k.replaceFirst(RegExp(r'^tilt'), ''),
        e = _or(it['e'], 1),
        g = GRIP[base] ?? const [0, 3];
    num gx = g[0] * e, gy = g[1] * e;
    if (k.startsWith('tilt')) {
      final A = it['v'] == 'suave' ? -0.55 : -0.9,
          cs = math.cos(A),
          sn = math.sin(A),
          nx = gx * cs - gy * sn,
          ny = gx * sn + gy * cs;
      gx = nx;
      gy = ny;
    }
    final sg = jsTruthy(fl) ? -1 : 1;
    if (jsTruthy(it['una'])) {
      return [
        [ix, iy + gy],
      ];
    }
    if (jsTruthy(it['dos'])) {
      final h = it['dos'] is num ? it['dos'] as num : 11;
      return [
        [ix - h, iy + gy],
        [ix + h, iy + gy],
      ];
    }
    return g.length > 2 && g[2] != 0
        ? [
            [ix + sg * gx, iy + gy],
            [ix - sg * gx, iy + gy],
          ]
        : [
            [ix + sg * gx, iy + gy],
          ];
  }

  // comer.js: comeFl. What is at the mouth: a cup has its handle on the side of the body
  bool comeFl(M co, int d) =>
      CONASA.contains(co['k']) ? d > 0 : (d < 0 && co['k'] != 'tenedor');

  // comer.js: CUE. A person's arm: its bone's length and the shoulder's place off his middle (p.L: a longer arm for a
  // moment, reaching over the table)
  ({num L, num sx}) CUE(String id) {
    final p = G(id) ?? const <String, dynamic>{};
    var c = id == 'abuela'
        ? (L: 8 as num, sx: 7 as num)
        : Comer.NINO(id)
        ? (L: 7 as num, sx: 5.5 as num)
        : (L: 9 as num, sx: 7 as num);
    if (jsTruthy(p['L'])) c = (L: p['L'] as num, sx: c.sx);
    return c;
  }

  // the thing's kind without the tilt (`String(it.k).replace(/^tilt/,"")`)
  static String _base(M it) => _js(it['k']).replaceFirst(RegExp(r'^tilt'), '');

  // comer.js: manosDe. The hands of somebody, absolute: [{x,y,s: side of the picture (-1 left, 1 right), it, k}] (those
  // that hold, point, wave, or carry a thing to the mouth)
  List<_Hand> manosDe(String id, M p, int a) {
    final x = _round(p['x'] as num),
        y = _round(p['y'] as num),
        d = _d(p),
        hy = hombroY(id, p),
        cu = CUE(id),
        out = <_Hand>[];
    int side(num hx, num pre) => pre != 0
        ? pre.toInt()
        : ((hx - x).abs() < 3
              ? d
              : hx > x
              ? 1
              : -1);
    void pon(num hx, num hyy, M? it, num pre, String kind) =>
        out.add(_Hand(hx, hyy, side(hx, pre), it, kind));
    for (final v in (p['tiene'] as List?) ?? const []) {
      final it = v as M;
      if (it['vis'] == 0) continue;
      if (it['k'] == 'brazo') {
        pon(
          x + d * (it['gx'] as num),
          y - (it['gy'] as num),
          it,
          jsTruthy(it['sh']) ? (it['sh'] as num) * d : 0,
          'brazo',
        );
        continue;
      }
      if (it['k'] == 'uten') {
        pon(
          x + d * (it['ax'] as num),
          y - (it['ay'] as num),
          it,
          jsTruthy(it['side'])
              ? it['side'] as num
              : (jsTruthy(it['sh']) ? (it['sh'] as num) * d : 0),
          'uten',
        );
        continue;
      }
      final fl = it['flip'] ?? (CONASA.contains(_base(it)) ? d > 0 : false);
      it['_fl'] = fl;
      if (it['gx'] != null) {
        pon(x + d * (it['gx'] as num), y - (it['gy'] as num), it, 0, 'item');
        continue;
      }
      final ix = x + d * (it['dx'] as num), iy = y - (it['dy'] as num);
      final H = agarres(it, ix, iy, fl);
      if (H.length > 1) {
        final L1 = H[0][0] < H[1][0] ? H[0] : H[1],
            R1 = H[0][0] < H[1][0] ? H[1] : H[0];
        pon(L1[0], L1[1], it, -1, 'item');
        pon(R1[0], R1[1], it, 1, 'item');
      } else {
        pon(
          H[0][0],
          H[0][1],
          it,
          jsTruthy(it['sh']) ? (it['sh'] as num) * d : 0,
          'item',
        );
      }
    }
    if (jsTruthy(p['come'])) {
      final co = p['come'] as M,
          my = y - bocaY(id, p) + (a % 2),
          cxx = x + d * (co['dx'] == null ? 13 : co['dx'] as num),
          H = agarres(co, cxx, my + _n(co['dy']), comeFl(co, d));
      pon(H[0][0], H[0][1], co, 0, 'come');
    }
    if (jsTruthy(p['bebe2'])) {
      final co = <String, dynamic>{'k': 'taza'},
          H = agarres(
            co,
            x + d * 14,
            y - bocaY(id, p) + 3 - (a % 2),
            comeFl(co, d),
          );
      pon(H[0][0], H[0][1], co, 0, 'come');
    }
    // two things never in the same hand: the second goes to the other arm
    for (var i = 1; i < out.length; i++) {
      final m = out[i], before = out.sublist(0, i);
      if (before.any((q) => q.s == m.s && !identical(q.it, m.it)) &&
          !before.any((q) => q.s == -m.s)) {
        m.s = -m.s;
      }
    }
    // poses that need no thing: a hand out, up, on the chest
    bool usado(int s) => out.any((m) => m.s == s);
    final POSE = jsTruthy(p['pose']) ? p['pose'] as String : 'idle';
    if (POSE == 'offer' || POSE == 'tu') {
      if (!usado(d) &&
          !out.any((m) => m.k != 'come' && m.it != null && m.s == d)) {
        pon(x + d * (cu.sx + cu.L * 2 - 3), y - hy + 4, null, d, 'pose');
      }
    } else if (POSE == 'wave0' || POSE == 'wave1') {
      if (!usado(d)) {
        pon(
          x + d * (cu.sx + 4 + (POSE == 'wave1' ? 2 : 0)),
          y - hy - cu.L - 3,
          null,
          d,
          'pose',
        );
      }
    } else if (POSE == 'yo') {
      // a hand on his belly: when he sits the belly is under the table, so one hand, at his chest, with its arm (not two
      // blocks lying on the cloth)
      if (jsTruthy(p['sent'])) {
        if (!usado(1)) pon(x + 4, y - hy + cu.L - 2, null, 1, 'pose');
      } else {
        if (!usado(-1)) pon(x - 3, y - hy + cu.L - 1, null, -1, 'pose');
        if (!usado(1)) pon(x + 3, y - hy + cu.L - 1, null, 1, 'pose');
      }
    } else if (POSE == 'bless') {
      if (!usado(d)) pon(x + d * 3, y - hy + cu.L - 1, null, d, 'pose');
    }
    return out;
  }

  // comer.js: brazosQuietos. His arms at rest: the sides that are not busy, hanging; when he sits, resting on the lap
  void brazosQuietos(Ctx c, String id, M p, int a, List<_Hand> vivos) {
    final x = _round(p['x'] as num),
        y = _round(p['y'] as num),
        hy = hombroY(id, p),
        cu = CUE(id),
        sl = sleeve(id),
        pi = piel(id);
    for (final s in const [-1, 1]) {
      if (vivos.any((m) => m.s == s)) continue;
      final sx = x + s * cu.sx,
          sy = y - hy,
          hx = x + s * (cu.sx + 1.5),
          hyy = jsTruthy(p['sent']) ? sy + cu.L * 1.25 : sy + cu.L * 1.7;
      brazoJ(c, sx, sy, hx, hyy, cu.L, sl, pi, s);
      _mano(c, hx, hyy, pi);
    }
  }

  // comer.js: cuerpo. Every person is drawn here without arms; his arms are drawn over him (cuerpo: the arms at rest;
  // objetos: the arms that hold, point or wave)
  void cuerpo(Ctx c, String id, int a) {
    final p = G(id);
    if (p == null || p['vis'] == 0) return;
    final w = QUIEN[id],
        x = _round(p['x'] as num),
        y = _round(p['y'] as num),
        habla = TALK == id && a % 2 != 0 ? 1 : 0,
        d = _d(p),
        pie = jsTruthy(p['paso']) ? _n(p['pie']).toInt() : 0,
        bob = jsTruthy(p['paso']) && pie == 0 ? -1 : 0;
    final vivos = manosDe(id, p, a);
    if (id == 'abuela') {
      final hb = habla != 0 || jsTruthy(p['abre']) || jsTruthy(p['boca'])
          ? 1
          : 0;
      if (jsTruthy(p['sent'])) {
        final top = y - 48;
        final im = spr('abSN$hb', () => recolor(mkAbuelaSN(hb != 0), APRON));
        if (d < 0) {
          c.save();
          c.translate(x.toDouble(), top.toDouble());
          c.scale(-1, 1);
          c.drawImage(im, -17, 0);
          c.restore();
        } else {
          c.drawImage(im, x - 17, top);
        }
        brazosQuietos(c, id, p, a, vivos);
        return;
      }
      final top = y - 50 + bob;
      c.save();
      c.translate(x.toDouble(), top.toDouble());
      if (d < 0) c.scale(-1, 1);
      c.drawImage(
        spr('abN$hb$pie', () => recolor(mkAbuelaN(hb != 0, pie), APRON)),
        -24,
        0,
      );
      c.restore();
      brazosQuietos(c, id, p, a, vivos);
      return;
    }
    final cf = p['cara'] == 'feliz' || p['cara'] == 'asco',
        gi = _n(p['giro']) * d,
        op = habla != 0 || jsTruthy(p['boca']) || jsTruthy(p['sopla']) ? 1 : 0,
        sent = jsTruthy(p['sent']),
        cierra = jsTruthy(p['cierra']);
    final im = spr(
      'pmN$id$op${sent ? 1 : 0}$pie${cierra ? 'c' : ''}${cf ? p['cara'] : ''}${gi != 0 ? jsNum(gi) : ''}',
      () => mkPersonaN(
        w!,
        op != 0,
        sent,
        pie,
        dormido: cierra,
        cara: cf ? p['cara'] as String : null,
        giro: gi,
      ),
    );
    final top = y - im.h + 1 + bob + _n(p['dy']);
    c.save();
    c.translate(x.toDouble(), top.toDouble());
    if (d < 0) c.scale(-1, 1);
    c.drawImage(im, -PX, 0);
    c.restore();
    brazosQuietos(c, id, p, a, vivos);
    final sk = (w!.piel)[2];
    final K = hx('#20140A');
    if (p['cara'] == 'mal') {
      // a big plain frown: eyes squeezed shut, thick brows sloping down to the nose, a wide mouth turned down, a red mark
      // of being cross
      fr(c, x - 6, top + 11, 13, 9, sk);
      for (final q in const [
        [-6, 8],
        [-5, 8],
        [-4, 9],
        [-3, 9],
        [-2, 10],
      ]) {
        fr(c, x + q[0], top + q[1] - 1, 1, 2, K);
      }
      for (final q in const [
        [6, 8],
        [5, 8],
        [4, 9],
        [3, 9],
        [2, 10],
      ]) {
        fr(c, x + q[0], top + q[1] - 1, 1, 2, K);
      }
      for (final q in const [
        [-5, 12],
        [-4, 13],
        [-3, 12],
        [-2, 13],
      ]) {
        fr(c, x + q[0], top + q[1], 1, 1, K);
      }
      for (final q in const [
        [5, 12],
        [4, 13],
        [3, 12],
        [2, 13],
      ]) {
        fr(c, x + q[0], top + q[1], 1, 1, K);
      }
      fr(c, x - 3, top + 16, 7, 2, hx('#5A1A10'));
      fr(c, x - 5, top + 17, 2, 2, hx('#5A1A10'));
      fr(c, x + 4, top + 17, 2, 2, hx('#5A1A10'));
      fr(c, x - 6, top + 19, 2, 1, hx('#5A1A10'));
      fr(c, x + 5, top + 19, 2, 1, hx('#5A1A10'));
      fr(c, x + 7, top + 1, 1, 4, hx('#D0302A'));
      fr(c, x + 6, top + 2, 3, 1, hx('#D0302A'));
      fr(c, x + 8, top + 3, 1, 1, hx('#D0302A'));
    }
    if (cierra) {
      if (jsTruthy(w.gafas)) {
        // eyes shut inside his glasses: a short line in each lens
        fr(c, x - 4, top + 10, 2, 2, hx('#EEDCB0'));
        fr(c, x + 1, top + 10, 2, 2, hx('#EEDCB0'));
        fr(c, x - 4, top + 11, 2, 1, K);
        fr(c, x + 1, top + 11, 2, 1, K);
      } else {
        for (final q in const [
          [-6, 13],
          [-5, 12],
          [-4, 11],
          [-3, 11],
          [-2, 12],
          [-1, 13],
        ]) {
          fr(c, x + q[0], top + q[1] - 1, 1, 2, K);
        }
        for (final q in const [
          [1, 13],
          [2, 12],
          [3, 11],
          [4, 11],
          [5, 12],
          [6, 13],
        ]) {
          fr(c, x + q[0], top + q[1] - 1, 1, 2, K);
        }
        fr(c, x - 5, top + 13, 2, 1, sk);
        fr(c, x + 3, top + 13, 2, 1, sk);
      }
    }
    if (p['cara'] == 'ceno') {
      // a plain frown, the eyes open: brows sloping down to the nose, a mouth turned down
      fr(c, x - 5, top + 13, 11, 5, sk);
      for (final q in const [
        [-6, 8],
        [-5, 8],
        [-4, 9],
        [-3, 9],
        [-2, 10],
      ]) {
        fr(c, x + q[0], top + q[1] - 1, 1, 2, K);
      }
      for (final q in const [
        [6, 8],
        [5, 8],
        [4, 9],
        [3, 9],
        [2, 10],
      ]) {
        fr(c, x + q[0], top + q[1] - 1, 1, 2, K);
      }
      fr(c, x - 3, top + 15, 7, 1, hx('#5A1A10'));
      fr(c, x - 4, top + 16, 2, 1, hx('#5A1A10'));
      fr(c, x + 3, top + 16, 2, 1, hx('#5A1A10'));
    }
    if (p['cara'] == 'calma') {
      // a calm face: a straight mouth
      fr(c, x - 4, top + 13, 9, 4, sk);
      fr(c, x - 2, top + 15, 5, 1, hx('#7A2A1A'));
    }
    if (jsTruthy(p['sopla'])) {
      // cheeks puffed (round, each with its own dark edge, the moustache untouched), lips pursed (a small round mouth
      // under the moustache), and three small breath dashes in a row from his lips to the steaming forkful he holds in
      // front of him
      ovalo(c, x - 5, top + 16, 3, 2, OUT);
      ovalo(c, x - 5, top + 16, 2, 1, sk);
      ovalo(c, x + 6, top + 16, 3, 2, OUT);
      ovalo(c, x + 6, top + 16, 2, 1, sk);
      fr(c, x - 1, top + 16, 3, 2, OUT);
      fr(c, x, top + 16, 1, 1, hx('#7A1C1C'));
      for (final k in const [8, 13, 18]) {
        fr(c, x + d * k - 2, top + 16, 5, 3, OUT);
        fr(c, x + d * k - 1, top + 17, 3, 1, hx('#FFFFFF'));
      }
    }
  }

  // comer.js: objetos. What he holds and eats, drawn after (over) his body; behind the table, after the table too. Each
  // thing is in a hand at the end of an arm with an elbow
  void objetos(Ctx c, String id, int a) {
    final p = G(id);
    if (p == null || p['vis'] == 0) return;
    final x = _round(p['x'] as num),
        y = _round(p['y'] as num),
        d = _d(p),
        hy = hombroY(id, p),
        pi = piel(id),
        sl = sleeve(id),
        cu = CUE(id),
        ms = manosDe(id, p, a);
    // the arms first, the things over them, the hands last
    for (final m in ms) {
      brazoJ(
        c,
        x + m.s * cu.sx,
        y - hy,
        m.x,
        m.y,
        cu.L,
        sl,
        pi,
        m.s,
        '$id:${m.it != null ? _js(m.it!['k']) : m.k}',
      );
    }
    for (final v in (p['tiene'] as List?) ?? const []) {
      final it = v as M;
      if (it['vis'] == 0 || it['k'] == 'brazo') continue;
      if (it['k'] == 'uten') {
        cucharon(
          c,
          x + d * (it['ax'] as num),
          y - (it['ay'] as num),
          x + d * (it['bx'] as num),
          y - (it['by'] as num),
          it['load'],
          it['o'],
        );
        continue;
      }
      final ix = x + d * (it['dx'] as num),
          iy = y - (it['dy'] as num),
          fl = it['_fl'] ?? false;
      final kk = it['k'] == 'taza' && jsTruthy(it['sp'])
          ? 'tazacu'
          : it['k'] as String;
      if (jsTruthy(it['ang']) && it['k'] == 'fuente') {
        final g = giro(fuenteComp(it), it['ang'] as num);
        c.save();
        c.smoothing = false;
        c.drawImage(g, _round(ix - g.w / 2), _round(iy - g.h / 2));
        c.restore();
      } else if (jsTruthy(it['ang'])) {
        final g = spr(
          'cmg${it['k']}${it['v'] == null ? '' : _js(it['v'])}${_js(it['ang'])}',
          () => giro(cosaSpr(it['k'] as String, it['v']), it['ang'] as num),
        );
        c.save();
        c.smoothing = false;
        c.drawImage(g, _round(ix - g.w / 2), _round(iy - g.h / 2));
        c.restore();
      } else {
        tenidaC(c, kk, ix, iy, it['e'], it['v'], fl);
      }
      if (it['k'] == 'plato') {
        for (final r in (it['rollos'] as List?) ?? const []) {
          rolloD(c, ix + _n((r as Map)['dx']), iy + 3, r as M, a);
        }
      }
      if (it['k'] == 'fuente' && !jsTruthy(it['ang'])) {
        for (final m in _byDy((it['montones'] as List?) ?? const [])) {
          tenidaC(
            c,
            'monton',
            ix + (m['dx'] as num),
            iy + 6 + (m['dy'] == null ? -4 : m['dy'] as num),
          );
        }
        if (jsTruthy(it['tenedor'])) {
          final t = it['tenedor'] as M;
          tenidaC(
            c,
            'tenedorH',
            ix + (t['dx'] as num),
            iy + 4.5 - (t['dy'] as num),
          );
        }
      }
      if (jsTruthy(it['vapor'])) {
        vapor(c, ix, iy - _or(it['e'], 1) * 9 - 2, _or(it['vn'], 1), it['vh']);
      }
      // a stream from the lip of what he pours
      if (jsTruthy(it['chorro'])) {
        final im = cosaSpr(it['k'] as String, it['v']), e = _or(it['e'], 1);
        final pico = picoOf(im);
        if (pico != null) {
          final ch = it['chorro'] as M,
              px = ix + (pico[0] - im.w / 2) * e * (jsTruthy(fl) ? -1 : 1),
              py = iy + (pico[1] - im.h / 2) * e + 1;
          chorro(
            c,
            _round(px),
            _round(py),
            _round(py) + (ch['h'] as num),
            ch['col'] as String,
            jsTruthy(fl) ? 1 : -1,
            ch['fino'],
          );
        }
      }
    }
    if (jsTruthy(p['come'])) {
      final co = p['come'] as M,
          my = y - bocaY(id, p) + (a % 2),
          cxx = x + d * (co['dx'] == null ? 13 : co['dx'] as num);
      tenidaC(
        c,
        co['k'] as String,
        cxx,
        my + _n(co['dy']),
        _or(co['e'], 1),
        co['v'],
        comeFl(co, d),
      );
      if (jsTruthy(co['vapor'])) vapor(c, cxx, my - 8, 1);
    }
    if (jsTruthy(p['bebe2'])) {
      tenidaC(
        c,
        'taza',
        x + d * 14,
        y - bocaY(id, p) + 3 - (a % 2),
        1,
        p['bebe2'],
        comeFl(<String, dynamic>{'k': 'taza'}, d),
      );
    }
    for (final m in ms) {
      _mano(c, m.x, m.y, pi);
    }
  }

  // comer.js: rana. The frog; his round belly (lleno) and his lying on his back (espalda) are drawn here
  void rana(Ctx g, M q, int a) {
    final b = frogBox(q),
        bl = (F % 47) < 2 ? 1 : 0,
        op =
            (q['bub'] == 'hola' || TALK == 'coqui' || jsTruthy(q['hace'])) &&
                a % 2 != 0
            ? 1
            : 0,
        dy = _round(_n(q['dy'])),
        cx = b.x + (b.w.toInt() >> 1),
        fy = b.y + b.h + dy;
    g.save();
    g.smoothing = false;
    if (jsTruthy(q['espalda'])) {
      g.drawImage(spr('cqesp$op', () => mkRanaEsp(op != 0)), cx - 20, fy - 31);
      g.restore();
      return;
    }
    if (jsTruthy(q['caida'])) {
      // half way over
      final ca = q['caida'] as num,
          gi = spr(
            'cqcai${jsNum(ca)}',
            () => giro(mkCoqui(1, 0, false), ca * .75),
          );
      g.drawImage(
        gi,
        cx - (gi.w >> 1),
        b.y + dy + (b.h.toInt() >> 1) - (gi.h >> 1),
      );
      g.restore();
      return;
    }
    final s = q['s'] as num;
    g.globalAlpha = (q['al'] as num).toDouble();
    g.drawImage(
      spr('cq${jsNum(s)}_$bl$op', () => mkCoqui(s, bl, op != 0)),
      b.x,
      b.y + dy,
    );
    g.globalAlpha = 1;
    g.restore();
    if (jsTruthy(q['lleno'])) {
      final f = q['hinch'] == null ? 1 : (q['hinch'] as num) / 3;
      if (f > 0) {
        for (final r in const [
          [-7, 0],
          [-9, 1],
          [-10, 2],
          [-10, 3],
          [-9, 4],
          [-7, 5],
        ]) {
          final x0 = _round(r[0] * f);
          fr(
            g,
            cx + x0 - 1,
            b.y + dy + 12 + r[1],
            -2 * x0 + 2,
            1,
            hx('#FBF0D2'),
          );
        }
        fr(g, cx - _round(10 * f), b.y + dy + 14, 1, 3, OUT);
        fr(g, cx + _round(9 * f), b.y + dy + 14, 1, 3, OUT);
        fr(g, cx, b.y + dy + 15, 1, 1, hx('#B89A6A'));
      }
    }
    if (jsTruthy(q['mal'])) {
      // a plain sour face, big: brows thick and sloping down to the nose, eyes squeezed, a wide mouth turned down
      final fx = cx, fy2 = b.y + dy;
      for (final r in const [
        [-10, 3],
        [-9, 4],
        [-8, 4],
        [-7, 5],
        [-6, 5],
        [-5, 6],
      ]) {
        fr(g, fx + r[0], fy2 + r[1] - 1, 1, 3, OUT);
      }
      for (final r in const [
        [10, 3],
        [9, 4],
        [8, 4],
        [7, 5],
        [6, 5],
        [5, 6],
      ]) {
        fr(g, fx + r[0] - 1, fy2 + r[1] - 1, 1, 3, OUT);
      }
      fr(g, fx - 6, fy2 + 13, 13, 3, hx('#7A1C1C'));
      fr(g, fx - 8, fy2 + 15, 3, 3, hx('#7A1C1C'));
      fr(g, fx + 6, fy2 + 15, 3, 3, hx('#7A1C1C'));
      fr(g, fx - 7, fy2 + 12, 2, 1, OUT);
      fr(g, fx + 6, fy2 + 12, 2, 1, OUT);
    }
    final sl = RP.tan[2], pi = RP.tan[3];
    final its = [
      for (final v in (q['tiene'] as List?) ?? const [])
        if ((v as Map)['vis'] != 0) v as M,
    ];
    bool flOf(M it) {
      if (it['flip'] != null) return jsTruthy(it['flip']);
      return CONASA.contains(_base(it)) && (it['dx'] as num) > 0;
    }

    for (final it in its) {
      List<List<num>> H;
      if (it['k'] == 'brazo') {
        H = [
          [cx + (it['gx'] as num), fy - (it['gy'] as num)],
        ];
      } else if (it['k'] == 'uten') {
        H = [
          [cx + (it['ax'] as num), fy - (it['ay'] as num)],
        ];
      } else if (it['gx'] != null) {
        H = [
          [cx + (it['gx'] as num), fy - (it['gy'] as num)],
        ];
      } else {
        H = agarres(
          it,
          cx + (it['dx'] as num),
          fy - (it['dy'] as num),
          flOf(it),
        );
      }
      it['_H'] = H;
      for (final h in H) {
        final s = h[0] >= cx ? 1 : -1;
        brazoJ(
          g,
          cx + s * 7,
          fy - 12,
          h[0],
          h[1],
          7,
          sl,
          pi,
          s,
          'rana:${it['k']}',
        );
      }
    }
    for (final it in its) {
      if (it['k'] == 'brazo') continue;
      if (it['k'] == 'uten') {
        cucharon(
          g,
          cx + (it['ax'] as num),
          fy - (it['ay'] as num),
          cx + (it['bx'] as num),
          fy - (it['by'] as num),
          it['load'],
          it['o'],
        );
      } else {
        final ix = cx + (it['dx'] as num),
            iy = fy - (it['dy'] as num),
            fl = flOf(it);
        tenidaC(g, it['k'] as String, ix, iy, it['e'], it['v'], fl);
        if (jsTruthy(it['chorro'])) {
          final im = cosaSpr(it['k'] as String, it['v']), e = _or(it['e'], 1);
          final pico = picoOf(im);
          if (pico != null) {
            final ch = it['chorro'] as M,
                px = ix + (pico[0] - im.w / 2) * e * (fl ? -1 : 1),
                py = iy + (pico[1] - im.h / 2) * e + 1;
            chorro(
              g,
              _round(px),
              _round(py),
              _round(py) + (ch['h'] as num),
              ch['col'] as String,
              fl ? 1 : -1,
            );
          }
        }
        if (jsTruthy(it['vapor'])) {
          vapor(g, ix, iy - _or(it['e'], 1) * 9 - 2, _or(it['vn'], 1));
        }
      }
      // (a spoon: comer.js would look for its lip and steam at cx + its dx, which a spoon has not; it has neither)
    }
    for (final it in its) {
      for (final h in (it['_H'] as List?) ?? const []) {
        _mano(g, (h as List)[0] as num, h[1] as num, pi);
      }
    }
  }

  // comer.js: nube. A thought: an outlined cloud of round lobes, a trail of small circles that leads to the one who
  // thinks, and a thing in it. (x,y): the top left of the cloud's box; aim: the head of the one who thinks
  void nube(Ctx g, num x, num y, M o, [Object? dir, List<num>? aim]) {
    final im = cosaSpr(o['k'] as String, o['v']),
        e = _or(o['e'], 1),
        w = math.max(28, _round(im.w * e) + 8),
        h = math.max(20, _round(im.h * e) + 6);
    final Lb = [
      for (final l in [
        [w * .27, h * .6, h * .36],
        [w * .5, h * .4, h * .41],
        [w * .73, h * .6, h * .36],
        [w * .5, h * .66, h * .36],
      ])
        [_round(x + l[0]), _round(y + l[1]), math.max(3, _round(l[2]))],
    ];
    for (final l in Lb) {
      ovalo(g, l[0], l[1], l[2] + 1, l[2] + 1, OUT);
    }
    for (final l in Lb) {
      ovalo(g, l[0], l[1], l[2], l[2], hx('#FFFFFF'));
    }
    final cxn = x + w / 2,
        cyn = y + h / 2,
        A = aim ?? [cxn - 6, y + h + 14],
        vx = A[0] - cxn,
        vy = A[1] - cyn,
        dd0 = _hypot(vx, vy),
        dd = dd0 == 0 ? 1 : dd0,
        ux = vx / dd,
        uy = vy / dd,
        e0 =
            math.min(
              w / 2 / math.max(.01, ux.abs()),
              h / 2 / math.max(.01, uy.abs()),
            ) *
            .92;
    for (final q in [
      [e0 + 3, 3],
      [e0 + 8, 2],
    ]) {
      final px = _round(cxn + ux * q[0]), py = _round(cyn + uy * q[0]);
      ovalo(g, px, py, q[1] + 1, q[1] + 1, OUT);
      ovalo(g, px, py, q[1], q[1], hx('#FFFFFF'));
    }
    tenidaC(g, o['k'] as String, x + (w >> 1), y + (h >> 1), e, o['v']);
  }

  // comer.js: rolloD. A roll with its state (st: ab open and empty, ce closed, mo with a bite out of it, m2 half eaten;
  // con: chocolate or butter in it)
  void rolloD(Ctx c, num x, num yb, M r, int a) => tenida(
    c,
    'rollo',
    x,
    yb,
    0,
    1,
    '${_js(r['st'])}${jsTruthy(r['con']) ? ':${_js(r['con'])}' : ''}',
  );

  // comer.js: nCesta. How many rolls the basket holds
  num nCesta() => _plus(_js(ob('cesta')!['v']).split(':')[0]);

  // comer.js: cosaDibuja
  void cosaDibuja(Ctx c, M o, int a) {
    final k = o['k'] as String, x = o['x'] as num, y = o['y'] as num;
    if (k == 'plato' || k == 'platoc') {
      tenida(c, k, x, y, 0, o['e'], o['v']);
      for (final r in (o['rollos'] as List?) ?? const []) {
        rolloD(c, x + _n((r as Map)['dx']), y - 2, r as M, a);
      }
      if (jsTruthy(o['vapor'])) vapor(c, x, y - 12, 1);
      return;
    }
    if (k == 'tabla') {
      tenida(c, 'tabla', x, y);
      if (jsTruthy(o['rollo'])) rolloD(c, x, y - 3, o['rollo'] as M, a);
      return;
    }
    if (k == 'fuente') {
      tenida(c, 'fuente', x, y);
      for (final m in _byDy((o['montones'] as List?) ?? const [])) {
        tenida(
          c,
          'monton',
          x + (m['dx'] as num),
          y + (m['dy'] == null ? -4 : m['dy'] as num),
        );
      }
      if (jsTruthy(o['tenedor'])) {
        final t = o['tenedor'] as M;
        tenida(
          c,
          'tenedorH',
          x + (t['dx'] as num),
          y - (t['dy'] == null ? 4 : t['dy'] as num),
          0,
          1,
        );
      }
      return;
    }
    if (k == 'olla') {
      tenida(c, 'olla', x, y, 0, 1, o['v']);
      if (jsTruthy(o['vapor']) && o['v'] != 'vacio') vapor(c, x, y - 22, 2);
      return;
    }
    tenida(
      c,
      k == 'taza' && jsTruthy(o['sp']) ? 'tazacu' : k,
      x,
      y,
      0,
      _or(o['e'], 1),
      k == 'azucarera'
          ? 'L${jsTruthy(o['tomada']) ? '0' : jsNum(math.min(3, o['spoons'] == null ? 3 : o['spoons'] as num))}'
          : o['v'],
    );
    if (jsTruthy(o['vapor']) && !(k == 'cesta' && nCesta() < 1)) {
      vapor(
        c,
        x + _n(o['vdx']),
        y -
            (o['vdy'] == null
                ? (k == 'cesta'
                      ? 18
                      : k == 'taza'
                      ? 15
                      : 12)
                : o['vdy'] as num),
        _or(o['vn'], 2),
        o['vh'],
      );
    }
  }

  // comer.js:554 the dog, at his place in the sorted list
  void perro(Ctx c, M o, int a) {
    final pose = o['pose'];
    final f = pose == 'eat' || pose == 'walk' || jsTruthy(o['cola'])
        ? (a >> 1) % 2
        : 0;
    final im = spr('pe${_js(pose)}$f', () => mkPerro(_js(pose), f != 0));
    c.save();
    c.translate(
      _round(o['x'] as num).toDouble(),
      _round(o['y'] as num).toDouble(),
    );
    final e = _or(o['e'], 1);
    c.scale(((_d(o) < 0 ? -1 : 1) * e).toDouble(), e.toDouble());
    c.translate(0, (-im.h + 2).toDouble());
    c.drawImage(im, -13, 0);
    // a few grains of rice on his nose
    if (jsTruthy(o['granos'])) {
      for (final g in const [
        [24, 10],
        [26, 9],
        [28, 11],
      ]) {
        fr(c, g[0] - 13 + 1, g[1] - 1, 2, 2, hx('#FFFFFF'));
      }
    }
    // his tongue out, into the bowl
    if (jsTruthy(o['lengua'])) {
      fr(c, 14, 13, 5, 3, OUT);
      fr(c, 15, 13, 3, 2, hx('#F07890'));
    }
    c.restore();
  }

  // comer.js:562 hab. With the words hidden, a speaker's empty speech bubble over him (a tail to his head)
  void hab(Ctx c, num tx, num ty, num bcx) {
    const bw = 17, bh = 11;
    final bx = bcx - 8, by = ty - 4 - bh;
    fr(c, bx - 1, by, bw + 2, bh, OUT);
    fr(c, bx, by - 1, bw, bh + 2, OUT);
    fr(c, bx, by, bw, bh, hx('#FFFFFF'));
    fr(c, bx, by, bw, 1, hx('#F2F2F8'));
    for (final i in const [-4, 0, 4]) {
      fr(c, bcx + i - 1, by + 4, 2, 2, hx('#2A1810'));
    }
    final ax = math.max(bx + 3, math.min(bx + bw - 3, tx));
    for (var r = 0; r < 5; r++) {
      final px = _round(ax + (tx - ax) * r / 4), hw = math.max(0, 3 - r);
      fr(c, px - hw - 1, by + bh + r - 0, 2 * hw + 3, 1, OUT);
      if (r < 4) fr(c, px - hw, by + bh + r, 2 * hw + 1, 1, hx('#FFFFFF'));
    }
  }

  // moves line 21: a face of each one shown, as LIBRE and CARTAS take it: [x - 6, y - alto + 7 (abuela sitting: one row
  // less) + dy, 12, 10]
  List<num> _face(String k, M p) => [
    _round(p['x'] as num) - 6,
    _round(p['y'] as num) -
        alto(k) +
        7 -
        (k == 'abuela' && jsTruthy(p['sent']) ? 1 : 0) +
        _round(_n(p['dy'])),
    12,
    10,
  ];

  static bool _on(List<num> a, List<num> b) =>
      a[0] < b[0] + b[2] &&
      b[0] < a[0] + a[2] &&
      a[1] < b[1] + b[3] &&
      b[1] < a[1] + a[3];

  // moves line 21: LIBRE. With the words hidden, an empty bubble goes to the first talk place (the sheet's talk.places:
  // [side, dy]) whose bubble is wholly inside the view and clear of every other face; else the old place
  List<num> LIBRE(String who, num tx, num ty, num h) {
    final Fc = <List<num>>[];
    for (final en in ((W['gente'] as M?) ?? const {}).entries) {
      final p = en.value as M?;
      if (en.key != who && p != null && p['vis'] != 0) {
        Fc.add(_face(en.key, p));
      }
    }
    final cq = W['cq'] as M?;
    if (who != 'coqui' && cq != null && jsTruthy(cq['vis'])) {
      final b = frogBox(cq);
      Fc.add([b.x + 2, b.y + _round(_n(cq['dy'])), b.w - 4, _round(b.h * .6)]);
    }
    final cm = cam;
    for (final sd in LIBRE_AT) {
      final x = tx + sd[0] * (h + 16),
          y = ty + sd[1],
          r = [x - 9, y - 16, 19, 13];
      if (r[0] >= cm[0] &&
          r[1] >= 0 &&
          r[0] + r[2] <= cm[0] + cm[2] &&
          !Fc.any((f) => _on(f, r))) {
        return [x, y];
      }
    }
    return [tx, ty];
  }

  // moves line 21: CARTAS. The answer cards (W.respEn) at every frame while the frog chooses: the first centre of the
  // sheet's cards (going down from 162) whose cards are clear of the rounds card when it is up, whose hint hands
  // (juego.js HAND, from the card's foot - 6, both frames) are on no face and whose hint frames (card +- 12) cross no
  // head; else the first
  List<num> CARTAS(M W) {
    final n = (W['resp'] as List).length, Fc = <List<num>>[];
    for (final en in ((W['gente'] as M?) ?? const {}).entries) {
      final p = en.value as M?;
      if (p != null && p['vis'] != 0) Fc.add(_face(en.key, p));
    }
    final y0 = CARTAS_Y, cm = cam;
    for (final cx in CARTAS_CX) {
      var ok = true;
      for (var i = 0; i < n && ok; i++) {
        final c = n > 2
            ? [_round(cx - 70 + i * 50), y0, 40, 36]
            : i == 0
            ? [_round(cx - 50), y0, 40, 36]
            : [_round(cx + 10), y0, 40, 36];
        final fr0 = [c[0] - 12, c[1] - 12, 64, 60],
            hx0 = c[0] + 8,
            hy0 = c[1] + 30;
        if (jsTruthy(W['tarjeta']) &&
            _on([c[0] - 2, c[1] - 2, 44, 40], [cm[0] + 3, 3, 68, 26])) {
          ok = false;
        }
        for (final f in Fc) {
          if (_on(fr0, [f[0] - 2, f[1] - 6, 16, 16])) ok = false;
          for (final o in const [0, 9]) {
            for (var j = 0; j < HAND.length; j++) {
              final rw = HAND[j];
              for (var x = 0; x < 12; x++) {
                if (rw[x] != '.' &&
                    _on([hx0 + x * 3, hy0 + j * 3 + o, 3, 3], f)) {
                  ok = false;
                }
              }
            }
          }
          if (!ok) break;
        }
      }
      if (ok) return [cx, y0];
    }
    return [CARTAS_CX[0], y0];
  }
}
