// The names of the old file are kept, Spanish ones and capitals included, so a scene ports line for line
// (page 12, section 4 and section 6): the lints on names are off in this file.
// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'dart:math' as math;

import 'package:coqui_pixel/src/ctx.dart';
import 'package:coqui_pixel/src/js.dart';
import 'package:coqui_pixel/src/scene.dart';
import 'package:coqui_pixel/src/scene_host.dart';
import 'package:coqui_pixel/src/sprite.dart';

/// Port of the signs and marks of historia/juego.js ("signs and marks, the same in every scene"): the big hand, the
/// heart, the star, the "touch this" frame, the twinkle, the answer bubbles, the frog and his box.
///
/// A sign that needs nothing but its arguments is a function (`hand`, `heart`, `star`, `bang`, `frogBox`). The rest
/// read the game's state, which juego.js keeps in globals: they are methods of [Signs], which reads it through the
/// [SceneHost] (`W`, `F`, `cam`, `TALK`, `BUBL`, the sprite cache) and the scene (`E`: `box`, `handAt`, `heartAt`,
/// `respIcon`). One [Signs] per scene run; it holds no state of its own.

// juego.js: colours the signs use, as 0xFFBBGGRR
const int _white = 0xFFFFFFFF;
const int _gold = 0xFF40E0FF; // "#FFE040"
const int _goldHot = 0xFFB0F4FF; // "#FFF4B0"
const int _heartLight = 0xFF909AFF; // "#FF9A90"
const int _heartRed = 0xFF3C44E8; // "#E8443C"
const int _green = 0xFF489A2E; // "#2E9A48"
const int _redAnswer = 0xFF3A40D0; // "#D0403A"
const int _grey = 0xFFB0A49A; // "#9AA4B0"
const int _dim =
    0x991C0E06; // "rgba(6,14,28,.6)": 6, 14, 28 and 153 (.6 of 255)

// juego.js: HAND
const List<String> HAND = [
  '....oo......',
  '...owwo.....',
  '...owwo.....',
  '...owwo.....',
  '...owwooo...',
  '...owwowwoo.',
  'oo.owwowwowo',
  'owoowwwwwwwo',
  'owwowwwwwwwo',
  '.owwwwwwwwwo',
  '.owwwwwwwwwo',
  '..owwwwwwwo.',
  '..owwwwwwwo.',
  '...owwwwwo..',
  '...ooooooo..',
];

// juego.js: hand
// the big tapping hand: `down` it is pressed, with three little sparks; k is the size of one pixel
void hand(Ctx g, num x, num y, bool down, num k) {
  final o = down ? 0 : 3 * k;
  for (var j = 0; j < HAND.length; j++) {
    final rw = HAND[j];
    for (var i = 0; i < rw.length; i++) {
      final ch = rw[i];
      if (ch != '.') {
        fr(g, x + i * k, y + j * k + o, k, k, ch == 'o' ? OUT : _white);
      }
    }
  }
  if (down) {
    for (final p in const [
      [-4, -1],
      [2, -4],
      [8, -1],
    ]) {
      fr(g, x + 2 * k + p[0] * k - 1, y + p[1] * k - 1, k + 3, k + 3, OUT);
      fr(g, x + 2 * k + p[0] * k, y + p[1] * k, k + 1, k + 1, _gold);
    }
  }
}

// juego.js: HEART
const List<String> HEART = [
  '.##...##.',
  '####.####',
  '#########',
  '#########',
  '.#######.',
  '..#####..',
  '...###...',
  '....#....',
];

// juego.js: heart
void heart(Ctx g, num x, num y, num s) {
  for (var j = 0; j < HEART.length; j++) {
    final rw = HEART[j];
    for (var i = 0; i < rw.length; i++) {
      if (rw[i] == '#') fr(g, x + i * s - 1, y + j * s - 1, s + 2, s + 2, OUT);
    }
  }
  for (var j = 0; j < HEART.length; j++) {
    final rw = HEART[j];
    for (var i = 0; i < rw.length; i++) {
      if (rw[i] == '#') {
        fr(
          g,
          x + i * s,
          y + j * s,
          s,
          s,
          j < 2 && i < 3 ? _heartLight : _heartRed,
        );
      }
    }
  }
}

// juego.js: star
void star(Ctx g, num x, num y, num s, [bool hot = false]) {
  final col = hot ? _white : _gold;
  fr(g, x - 1, y - s - 1, 3, 2 * s + 3, OUT);
  fr(g, x - s - 1, y - 1, 2 * s + 3, 3, OUT);
  fr(g, x, y - s, 1, 2 * s + 1, col);
  fr(g, x - s, y, 2 * s + 1, 1, col);
  fr(g, x - 1, y - 1, 3, 3, col);
}

// juego.js: spot
// the big "touch this" sign: everything else goes dim, a thick pulsing frame, and (drawn later) a big tapping hand.
// `SW`, `SH` are the picture's size (juego.js: the globals `SW`, `SH`).
void spot(Ctx g, List<num> b, int a, int SW, int SH) {
  final e = a % 4 < 2 ? 0 : 2,
      x0 = math.max(0, b[0] - 5 - e),
      y0 = math.max(0, b[1] - 5 - e),
      x1 = math.min(SW, b[0] + b[2] + 5 + e),
      y1 = math.min(SH, b[1] + b[3] + 5 + e);
  g.fillStyle = _dim;
  g.fillRect(0, 0, SW, y0);
  g.fillRect(0, y1, SW, SH - y1);
  g.fillRect(0, y0, x0, y1 - y0);
  g.fillRect(x1, y0, SW - x1, y1 - y0);
  void ring(num o, num t, int col) {
    fr(g, x0 - o, y0 - o, x1 - x0 + 2 * o, t, col);
    fr(g, x0 - o, y1 + o - t, x1 - x0 + 2 * o, t, col);
    fr(g, x0 - o, y0 - o, t, y1 - y0 + 2 * o, col);
    fr(g, x1 + o - t, y0 - o, t, y1 - y0 + 2 * o, col);
  }

  ring(5, 5, OUT);
  ring(4, 3, e != 0 ? _goldHot : _gold);
}

// juego.js: G_HAND
const List<String> G_HAND = [
  '..#.#.#..',
  '..#.#.#.#',
  '..#.#.#.#',
  '..#.#.#.#',
  '#.#####.#',
  '#.######.',
  '########.',
  '.#######.',
  '..#####..',
  '..#####..',
];

// juego.js: G_HEART
const List<String> G_HEART = [
  '.##.##.',
  '#######',
  '#######',
  '.#####.',
  '..###..',
  '...#...',
];

// juego.js: BUB
/// The two bubbles drawn from their own pixels: `hola` (a hand) and `amor` (a heart), each with its colour.
const Map<String, (List<String>, int)> BUB = {
  'hola': (G_HAND, 0xFF306AB4), // "#B46A30"
  'amor': (G_HEART, 0xFF3A40E0), // "#E0403A"
};

// juego.js: BUBL
/// The answer bubbles' icons by key. A new map every call: scenes add their own keys (`Object.assign(BUBL, ...)`), so
/// a game holds one, and [SceneHost.BUBL] hands it out.
Map<String, List<String>> newBUBL() => {
  'como': ['ok', 'q', 'sad'],
  'bien': ['ok'],
  'mal': ['sad'],
  'quien': ['hand', 'q'],
  'lluvia': ['gota', 'sad'],
};

// juego.js: BANG
const List<String> BANG = [
  '.....#.....',
  '#....#....#',
  '.#...#...#.',
  '..#.###.#..',
  '...#####...',
  '###########',
  '...#####...',
  '..#.###.#..',
  '.#...#...#.',
  '#....#....#',
  '.....#.....',
];

// juego.js: bang
// the "knock" mark
void bang(Ctx g, num cx, num cy, num s) {
  final x0 = cx - (5.5 * s).floor(), y0 = cy - (5.5 * s).floor();
  for (var j = 0; j < BANG.length; j++) {
    final rw = BANG[j];
    for (var i = 0; i < rw.length; i++) {
      if (rw[i] == '#') {
        fr(g, x0 + i * s - 1, y0 + j * s - 1, s + 2, s + 2, OUT);
      }
    }
  }
  for (var j = 0; j < BANG.length; j++) {
    final rw = BANG[j];
    for (var i = 0; i < rw.length; i++) {
      if (rw[i] == '#') {
        fr(
          g,
          x0 + i * s,
          y0 + j * s,
          s,
          s,
          (i - 5).abs() < 2 && (j - 5).abs() < 2 ? _white : _gold,
        );
      }
    }
  }
}

// juego.js: frogBox
/// The frog's box: `x`, `y`, `w`, `h` (the old `{x, y, w, h}`), from his state `q` (`x`, `y`, `s`).
({num x, num y, num w, num h}) frogBox(Map<String, dynamic> q) {
  final s = q['s'] as num;
  final w = (30 * s + 0.5).floor() + 2, h = (25 * s + 0.5).floor() + 2;
  return (
    x: ((q['x'] as num) + (32 - w) / 2 + 0.5).floor(),
    y: (q['y'] as num) + 27 - h,
    w: w,
    h: h,
  );
}

// engine.js: shadow. [Signs.frog] has a parameter of that name, which hides the function inside it.
void _flatShadow(Ctx g, num x, num y, num w) => shadow(g, x, y, w);

/// The signs that read the game's state.
class Signs {
  Signs({required this.host, required this.scene}) {
    // juego.js: `GL.gota=[...];GC.gota="#3A86E6";` a rain drop, for bubbles
    host.lib.GL['gota'] = const [
      '..#..',
      '..#..',
      '.###.',
      '.###.',
      '#####',
      '#####',
      '.###.',
    ];
    host.lib.GC['gota'] = 0xFFE6863A;
  }

  final SceneHost host;

  /// The scene that is on (juego.js: `E`).
  final Scene scene;

  Map<String, dynamic> get _W => host.W;

  // juego.js: twinkle
  // little stars turning round box [b]
  void twinkle(Ctx g, List<num> b) {
    final F = host.F, cx = b[0] + b[2] / 2, cy = b[1] + b[3] / 2;
    for (var k = 0; k < 3; k++) {
      final an = F / 7 + k * 2.094;
      star(
        g,
        (cx + (b[2] / 2 + 5) * math.cos(an) + 0.5).floor(),
        (cy + (b[3] / 2 + 5) * math.sin(an) + 0.5).floor(),
        (F >> 2) % 2 != 0 ? 3 : 2,
        k == (F >> 3) % 3,
      );
    }
  }

  // juego.js: bub
  // a picture bubble at tx, ty (where its tail points)
  void bub(Ctx g, String k, num tx, num ty, int a) {
    final icons = host.BUBL[k];
    if (icons != null) {
      host.lib.bubble(g, icons, tx, ty, a);
      return;
    }
    final (rows, col) = BUB[k]!;
    final w = rows[0].length + 6,
        h = rows.length + 6,
        x = (tx - w / 2 + 0.5).floor(),
        y = ty - h - 5 - (a % 2);
    fr(g, x - 1, y, w + 2, h, OUT);
    fr(g, x, y - 1, w, h + 2, OUT);
    fr(g, x, y, w, h, _white);
    fr(g, tx - 2, y + h, 5, 1, _white);
    fr(g, tx - 2, y + h + 1, 5, 1, OUT);
    fr(g, tx - 1, y + h + 1, 3, 1, _white);
    fr(g, tx - 1, y + h + 2, 3, 1, OUT);
    fr(g, tx, y + h + 2, 1, 1, _white);
    fr(g, tx, y + h + 3, 1, 1, OUT);
    for (var j = 0; j < rows.length; j++) {
      final rw = rows[j];
      for (var i = 0; i < rw.length; i++) {
        if (rw[i] == '#') fr(g, x + 3 + i, y + 3 + j, 1, 1, col);
      }
    }
  }

  // juego.js: frog
  /// The frog [q] (W.cq) with his shadow; his mouth moves while he talks. With [shadow] false the old flat shadow
  /// (juego.js line 48, `shadow(g,b.x+2,q.y+25,b.w-5)`) is not drawn and everything else is: a scene whose engine casts
  /// the frog's shadow asks for that.
  void frog(Ctx g, Map<String, dynamic> q, int a, {bool shadow = true}) {
    final F = host.F, b = frogBox(q);
    final bl = F % 47 < 2 ? 1 : 0,
        op = ((q['bub'] == 'hola' || host.TALK == 'coqui') && a % 2 != 0)
            ? 1
            : 0;
    final s = q['s'] as num;
    if (shadow) _flatShadow(g, b.x + 2, (q['y'] as num) + 25, b.w - 5);
    g.drawImage(
      host.lib.spr('cq${jsNum(s)}_$bl$op', () => mkCoqui(s, bl, op != 0)),
      b.x,
      b.y + ((q['dy'] as num) + 0.5).floor(),
    );
  }

  /* the two answer bubbles of the Say move: the frog nodding (sí) and the frog shaking his head (no) */

  // juego.js: respBox
  List<num>? respBox(String k) {
    final W = _W, resp = W['resp'] as List<dynamic>?;
    if (resp == null || !resp.contains(k)) return null;
    final q = W['cq'] as Map<String, dynamic>,
        b = frogBox(q),
        n = resp.length,
        i = resp.indexOf(k),
        m = n > 2 ? 76 : 60,
        en = W['respEn'] as List<dynamic>?,
        cam = host.cam;
    // respEn: a scene that needs its people seen while he chooses puts the bubbles elsewhere
    final num cx = en != null
            ? en[0] as num
            : math.max(
                cam[0] + m,
                math.min(cam[0] + cam[2] - m, b.x + b.w / 2),
              ),
        y = en != null ? en[1] as num : math.max(4, b.y - 46);
    // two answer bubbles, or three in a row
    return n > 2
        ? [(cx - 70 + i * 50 + 0.5).floor(), y, 40, 36]
        : i == 0
        ? [(cx - 50 + 0.5).floor(), y, 40, 36]
        : [(cx + 10 + 0.5).floor(), y, 40, 36];
  }

  // juego.js: bx
  // an answer bubble's box, else the scene's box, else the frog's (an answer bubble that is gone stands for the frog who said it)
  List<num> bx(String k) {
    final r = respBox(k);
    if (r != null) return r;
    final e = (k == 'si' || k == 'no') ? null : scene.box(k, _W);
    if (e != null) return e;
    final b = frogBox(_W['cq'] as Map<String, dynamic>);
    return [b.x, b.y, b.w, b.h];
  }

  // juego.js: respDraw
  void respDraw(Ctx g, int a) {
    final W = _W, F = host.F, lib = host.lib;
    final resp = (W['resp'] as List<dynamic>?) ?? const [];
    for (final k in resp.cast<String>()) {
      final b = respBox(k)!,
          x = b[0],
          y = b[1],
          w = b[2],
          h = b[3],
          t = (F >> 1) % 8,
          o = const [0, 1, 2, 1, 0, -1, -2, -1][t];
      fr(g, x - 1, y, w + 2, h, OUT);
      fr(g, x, y - 1, w, h + 2, OUT);
      fr(g, x, y, w, h, _white);
      final tx = resp.indexOf(k) == 0 ? x + w - 8 : x + 8;
      if (!jsTruthy(W['respEn'])) {
        fr(g, tx - 3, y + h, 7, 1, _white);
        fr(g, tx - 3, y + h + 1, 7, 1, OUT);
        fr(g, tx - 2, y + h + 1, 5, 1, _white);
        fr(g, tx - 2, y + h + 2, 5, 1, OUT);
        fr(g, tx - 1, y + h + 2, 3, 1, _white);
        fr(g, tx - 1, y + h + 3, 3, 1, OUT);
      }
      final voz = W['respVoz'] as Map<String, dynamic>?;
      if (voz != null && jsTruthy(voz[k])) {
        // an answer that cannot be drawn: the bubble says it aloud, and he picks by ear
        final on = W['respOn'] == k,
            m = on && a % 2 != 0 ? 1 : 0,
            col = on ? _green : _grey,
            n = on ? 1 + (F >> 1) % 3 : 3;
        if (on) {
          fr(g, x + 1, y + 1, w - 2, 2, _gold);
          fr(g, x + 1, y + h - 3, w - 2, 2, _gold);
          fr(g, x + 1, y + 1, 2, h - 2, _gold);
          fr(g, x + w - 3, y + 1, 2, h - 2, _gold);
        }
        g.drawImage(
          lib.spr('cqv$m', () => mkCoqui(.5, 0, m != 0)),
          x + 4,
          y + 11 - (on ? m : 0),
        );
        for (var i = 0; i < n; i++) {
          fr(g, x + 25 + i * 4, y + 17 - i * 3, 2, 4 + i * 6, col);
        }
        continue;
      }
      if (k != 'si' && k != 'no') {
        // a picture answer: the scene draws what is in the bubble
        scene.respIcon(g, k, x, y, w, h, a);
        continue;
      }
      final hx = x + (w / 2 + 0.5).floor() - 11 + (k == 'no' ? o * 2 : 0),
          hy = y + 7 + (k == 'si' ? o * 2 : 0);
      g.drawImage(lib.spr('cq.7_0', () => mkCoqui(.7, 0, false)), hx, hy);
      // motion marks: up and down for sí, side to side for no
      final col = k == 'si' ? _green : _redAnswer;
      if (k == 'si') {
        for (final p in [
          [x + 4, y + 9],
          [x + w - 6, y + 9],
        ]) {
          fr(g, p[0], p[1], 2, 14, col);
          fr(g, p[0] - 1, p[1] + 1, 4, 1, col);
          fr(g, p[0] - 1, p[1] + 12, 4, 1, col);
        }
      } else {
        for (final p in [
          [x + 5, y + 4],
          [x + 5, y + h - 6],
        ]) {
          fr(g, p[0], p[1], w - 10, 2, col);
          fr(g, p[0] + 1, p[1] - 1, 1, 4, col);
          fr(g, p[0] + w - 12, p[1] - 1, 1, 4, col);
        }
      }
    }
  }

  // juego.js: draw, after `E.draw(c,W,a)`
  /// What juego.js's `draw` puts over the scene's own drawing, in its order: the answer bubbles, the twinkle, the
  /// "touch this" frame, the effects, the heart. `a` is `F >> 1`. Drops the effects that are over (`W.fx`).
  void drawSigns(Ctx c, int a) {
    final W = _W, F = host.F, cam = host.cam;
    if (W['resp'] != null) respDraw(c, a);
    final tw = W['twinkle'];
    if (jsTruthy(tw)) twinkle(c, bx(tw as String));
    final sp = W['spot'];
    if (jsTruthy(sp)) spot(c, bx(sp as String), a, scene.SW, scene.SH);
    final fxs = (W['fx'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .where((e) => F - (e['f0'] as num) < (e['n'] as num))
        .toList();
    W['fx'] = fxs;
    for (final e in fxs) {
      final k = F - (e['f0'] as num);
      if (e['t'] == 'star') {
        final pts = e['pts'] as List<dynamic>;
        for (var i = 0; i < pts.length; i++) {
          final p = pts[i] as List<dynamic>;
          star(
            c,
            p[0] as num,
            p[1] as num,
            (i + a) % 2 != 0 ? 4 : 2,
            (i + a) % 2 != 0,
          );
        }
      } else if (e['t'] == 'knock') {
        final s = cam[2] > 150 ? 2 : 1, ex = e['x'] as num, ey = e['y'] as num;
        if (k < 2) {
          bang(c, ex, ey, s);
        } else if (k >= 3 && k < 6) {
          bang(c, ex + 3 * s, ey - 2 * s, s);
        }
      }
    }
    if (jsTruthy(W['heart'])) {
      heart(c, scene.heartAt[0], scene.heartAt[1] - (a % 2), 3);
    }
  }

  // juego.js: draw, the hand over the picture
  /// Where the big hand points, in the scene's picture, or null when nothing is marked (`W.spot` is not set).
  /// The hand is drawn by the frame after the view: see `drawFrame`.
  List<num>? handPoint() {
    final sp = _W['spot'];
    if (!jsTruthy(sp)) return null;
    final rb = respBox(sp as String);
    return rb != null
        ? [rb[0] + rb[2] / 2, rb[1] + rb[3] - 6]
        : scene.handAt(sp);
  }
}
