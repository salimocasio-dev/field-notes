// comer.js:575 to :795, line for line: the meeting at the stove, the long spoons in a person's and in the frog's hands,
// the forks, what is poured and from where, the frog's hands and his teaspoon, the sugar's grains, walking (mueve, ruta,
// the ways behind the table: detras, delante, atras, moves lines 21 and 698 to 719), coming in, going out, sitting down
// and getting up, the hands that reach, take, carry and put down, the rolls of story 33, the frog's fork and his belly.
// ignore_for_file: non_constant_identifier_names, constant_identifier_names
part of 'comer.dart';

extension _Moves on Comer {
  M get _cq => W['cq'] as M;
  List get _cosas => W['cosas'] as List;
  List get _vuelos => W['vuelos'] as List;

  // JavaScript: `p.tiene = p.tiene.filter(t => t !== x)`
  void _quita(M p, Object? x) =>
      p['tiene'] = [for (final t in (p['tiene'] as List)) if (!identical(t, x)) t];

  // JavaScript: `list.find(t => t.k === k)` (or one of [ks])
  M? _find(Object? list, bool Function(M t) f) {
    for (final t in (list as List?) ?? const []) {
      if (t is Map && f(t as M)) return t;
    }
    return null;
  }

  // JavaScript: `l.splice(l.indexOf(v), 1)`: with v gone, the last goes
  static void _splice(List l, Object? v) {
    final j = l.indexOf(v);
    if (j >= 0) {
      l.removeAt(j);
    } else if (l.isNotEmpty) {
      l.removeLast();
    }
  }

  /* ---------- the places of story 34 ---------- */

  // comer.js: aEncuentro34 (moves line 575: along the front to ENC34). Luis walks along the front to abuela, who is at
  // the stove
  Future<void> aEncuentro34() async {
    final l = G('luis')!;
    await ruta('luis', [
      [l['x'] as num, FR],
      [ENC34[0], FR],
      [ENC34[0], ENC34[1]],
    ]);
    l['dir'] = 1;
  }

  // comer.js: deEncuentro34 (moves line 576)
  Future<void> deEncuentro34() async {
    final l = G('luis')!;
    await ruta('luis', [
      [ENC34[0], FR],
      [LUIS34[0], FR],
      [LUIS34[0], LUIS34[1]],
    ]);
    l['dir'] = 1;
  }

  // comer.js: TENE, D1
  M TENE(String k, num dx, num dy, [M? o]) => {'k': k, 'dx': dx, 'dy': dy, ...?o};
  int D1(M p) => _d(p);

  // comer.js: cucharaPos. A long spoon in somebody's hand: the hand and the bowl move together, the handle is no longer
  // than his forearm; where must the hand and the bowl be for the bowl to be at the point (wx,wy) of the picture
  List<num> cucharaPos(String id, num wx, num wy, M? sp) {
    final p = G(id)!, d = D1(p), cu = CUE(id);
    final side = sp != null && jsTruthy(sp['side']) ? sp['side'] as num : d;
    final S = [
          _round(p['x'] as num) + side * cu.sx,
          _round(p['y'] as num) - hombroY(id, p),
        ],
        vx = wx - S[0],
        vy = wy - S[1],
        dist0 = _hypot(vx, vy),
        dist = dist0 == 0 ? 1 : dist0,
        u = [vx / dist, vy / dist],
        HL = math.min(2 * cu.L - 2, 13),
        hd = math.max(5, math.min(2 * cu.L - .5, dist - HL)),
        H = [S[0] + u[0] * hd, S[1] + u[1] * hd],
        B = [H[0] + u[0] * HL, H[1] + u[1] * HL];
    final x = _round(p['x'] as num), y = _round(p['y'] as num);
    return [(H[0] - x) * d, y - H[1], (B[0] - x) * d, y - B[1]];
  }

  // comer.js: cucharaA
  Future<void> cucharaA(String id, M sp, num wx, num wy, [num? n0]) async {
    final t = cucharaPos(id, wx, wy, sp),
        a = [sp['ax'] as num, sp['ay'] as num, sp['bx'] as num, sp['by'] as num];
    final n = n0 == null || n0 == 0 ? 4 : n0;
    for (var i = 1; i <= n; i++) {
      sp['ax'] = a[0] + (t[0] - a[0]) * i / n;
      sp['ay'] = a[1] + (t[1] - a[1]) * i / n;
      sp['bx'] = a[2] + (t[2] - a[2]) * i / n;
      sp['by'] = a[3] + (t[3] - a[3]) * i / n;
      await wait(TICK);
    }
    sp['ax'] = t[0];
    sp['ay'] = t[1];
    sp['bx'] = t[2];
    sp['by'] = t[3];
  }

  // comer.js: spoonOf, spoonW, bigSpoon
  M? spoonOf(String id) => _find(G(id)!['tiene'], (t) => t['k'] == 'uten');
  ({List<num> h, List<num> b}) spoonW(String id, M sp) {
    final p = G(id)!, d = D1(p);
    final x = _round(p['x'] as num), y = _round(p['y'] as num);
    return (
      h: [x + d * (sp['ax'] as num), y - (sp['ay'] as num)],
      b: [x + d * (sp['bx'] as num), y - (sp['by'] as num)],
    );
  }

  M bigSpoon([M? o]) => {
    'k': 'uten',
    'ax': 10,
    'ay': 24,
    'bx': 22,
    'by': 28,
    'load': '',
    'o': <String, dynamic>{'rx': 2, 'ry': 1},
    ...?o,
  };

  // comer.js: cucharaPosR. The frog's own hands: a spoon whose bowl is at (wx,wy)
  List<num> cucharaPosR(num wx, num wy, bool izq) {
    final sx = cx() + (izq ? -7 : 7),
        sy = pies() - 12,
        vx = wx - sx,
        vy = wy - sy,
        dist0 = _hypot(vx, vy),
        dist = dist0 == 0 ? 1 : dist0,
        u = [vx / dist, vy / dist],
        HL = 10,
        hd = math.max(4, math.min(11.5, dist - HL)),
        H = [sx + u[0] * hd, sy + u[1] * hd],
        B = [H[0] + u[0] * HL, H[1] + u[1] * HL];
    return [H[0] - cx(), pies() - H[1], B[0] - cx(), pies() - B[1]];
  }

  // comer.js: cucharaAR
  Future<void> cucharaAR(M sp, num wx, num wy, bool izq, [num? n0]) async {
    final t = cucharaPosR(wx, wy, izq),
        a = [sp['ax'] as num, sp['ay'] as num, sp['bx'] as num, sp['by'] as num];
    final n = n0 == null || n0 == 0 ? 4 : n0;
    for (var i = 1; i <= n; i++) {
      sp['ax'] = a[0] + (t[0] - a[0]) * i / n;
      sp['ay'] = a[1] + (t[1] - a[1]) * i / n;
      sp['bx'] = a[2] + (t[2] - a[2]) * i / n;
      sp['by'] = a[3] + (t[3] - a[3]) * i / n;
      sp['gx'] = sp['ax'];
      sp['gy'] = sp['ay'];
      await wait(TICK);
    }
    sp['ax'] = t[0];
    sp['ay'] = t[1];
    sp['bx'] = t[2];
    sp['by'] = t[3];
    sp['gx'] = sp['ax'];
    sp['gy'] = sp['ay'];
  }

  // comer.js: luisRest. Where Luis rests his spoon: hanging low at his side, not held up
  List<num> luisRest() {
    final l = G('luis')!;
    return [_round(l['x'] as num) + 7, _round(l['y'] as num) - 12];
  }

  // comer.js: pasaCuchara. The spoon goes from a person's hand to another's (or the frog's), in view: the receiver's
  // hand comes to the middle of the handle while the giver's hand is still on it (both hands on it for a moment), then
  // the giver lets go and his arm goes back to rest
  Future<M?> pasaCuchara(String de, String a) async {
    final sp = spoonOf(de);
    if (sp == null) return null;
    final W_ = spoonW(de, sp),
        T = [
          W_.h[0] + (W_.b[0] - W_.h[0]) * .6,
          W_.h[1] + (W_.b[1] - W_.h[1]) * .6,
        ];
    Future<void> suelta2() async {
      final g = G(de)!, d = D1(g), r = rel(de, W_.h[0], W_.h[1]);
      final s = (W_.h[0] - (g['x'] as num)).abs() < 3
          ? d
          : W_.h[0] > (g['x'] as num)
          ? 1
          : -1;
      final hb = <String, dynamic>{
        'k': 'brazo',
        '_m': 9,
        'gx': r[0],
        'gy': r[1],
        'sh': s * d,
      };
      _quita(g, sp);
      (g['tiene'] as List).add(hb);
      final rr = restHand(de);
      await manoA(de, rr[0] * (hb['sh'] as num), rr[1], 3);
      sinManos(de);
    }

    if (a == 'rana') {
      final q = _cq;
      await ranaA(T[0] + 12, T[1] + 15);
      final hb = <String, dynamic>{'k': 'brazo', 'gx': -8, 'gy': 3},
          g1 = [T[0] - cx(), pies() - T[1]];
      (q['tiene'] as List).add(hb);
      for (var i = 1; i <= 3; i++) {
        hb['gx'] = -8 + (g1[0] + 8) * i / 3;
        hb['gy'] = 3 + (g1[1] - 3) * i / 3;
        await wait(TICK);
      }
      await wait(TICK * 3);
      final sp2 = <String, dynamic>{
        'k': 'uten',
        'ax': T[0] - cx(),
        'ay': pies() - T[1],
        'bx': W_.b[0] - cx(),
        'by': pies() - W_.b[1],
        'load': sp['load'],
        'o': <String, dynamic>{'rx': 2, 'ry': 1, 'plata': 0},
        'gx': 0,
        'gy': 0,
      };
      sp2['gx'] = sp2['ax'];
      sp2['gy'] = sp2['ay'];
      _quita(q, hb);
      (q['tiene'] as List).add(sp2);
      SFX.blip();
      await suelta2();
      return sp2;
    }
    final p = G(a)!, d = D1(p), r = rel(a, T[0], T[1]);
    await manoA(a, r[0], r[1], 3, 0);
    await wait(TICK * 3);
    final sp2 = <String, dynamic>{
      'k': 'uten',
      'ax': r[0],
      'ay': r[1],
      'bx': (W_.b[0] - _round(p['x'] as num)) * d,
      'by': _round(p['y'] as num) - W_.b[1],
      'load': sp['load'],
      'o': sp['o'],
    };
    sinManos(a);
    (p['tiene'] as List).add(sp2);
    SFX.blip();
    await suelta2();
    return sp2;
  }

  // comer.js: cucharaDeRana. And from the frog's hands to a person's
  Future<M?> cucharaDeRana(String a) async {
    final q = _cq, sp = _find(q['tiene'], (t) => t['k'] == 'uten');
    if (sp == null) return null;
    final p = G(a)!,
        d = D1(p),
        H = [cx() + (sp['ax'] as num), pies() - (sp['ay'] as num)],
        B = [cx() + (sp['bx'] as num), pies() - (sp['by'] as num)],
        T = [H[0] + (B[0] - H[0]) * .6, H[1] + (B[1] - H[1]) * .6],
        r = rel(a, T[0], T[1]);
    // both hands on it
    await manoA(a, r[0], r[1], 3, 0);
    await wait(TICK * 3);
    final sp2 = <String, dynamic>{
      'k': 'uten',
      'ax': r[0],
      'ay': r[1],
      'bx': (B[0] - _round(p['x'] as num)) * d,
      'by': _round(p['y'] as num) - B[1],
      'load': sp['load'],
      'o': sp['o'],
    };
    sinManos(a);
    (p['tiene'] as List).add(sp2);
    _quita(q, sp);
    SFX.blip();
    await wait(TICK * 2);
    return sp2;
  }

  // comer.js: lado34 (moves line 605: beside the plate on the cloth, on the row there, SY). The frog's place when he tips
  // a mound onto the plate of the one at seat i (x): beside the plate on the cloth, the spoon in the hand on the side of
  // the plate
  ({num fx, num fy, bool izq}) lado34(num px) => px > 150
      ? (fx: px - 17, fy: SY(px - 17, 138), izq: false)
      : (fx: px + 17, fy: SY(px + 17, 138), izq: true);

  // comer.js: fuenteMonton. The mounds on the platter: g "m" a helping (front row), g "p" papá's (back row, at his end)
  ({M fu, M m, num x, num y})? fuenteMonton(String g) {
    final fu = ob('fuente');
    if (fu == null || !jsTruthy(fu['montones'])) return null;
    final m = _find(fu['montones'], (m) => m['g'] == g);
    return m != null
        ? (
            fu: fu,
            m: m,
            x: (fu['x'] as num) + (m['dx'] as num),
            y: (fu['y'] as num) + (m['dy'] == null ? -4 : m['dy'] as num) - 3,
          )
        : null;
  }

  // comer.js: origen (moves line 608: the platter is on the table while it lies lower than its place on the stove's
  // top)
  ({num x, num y}) origen() {
    final fu = ob('fuente'), h = fuenteMonton('m');
    if (h != null && fu != null && (fu['y'] as num) > PLAT34[1] + 20) {
      return (x: h.x, y: h.y);
    }
    final ol = ob('olla')!;
    return (x: ol['x'] as num, y: (ol['y'] as num) - 14);
  }

  /* ---------- story 34: forks and forkfuls ---------- */

  // comer.js: tenedorDe, FRESTO (a fork at rest in a hand: low, at his plate)
  M? tenedorDe(String id) => _find(G(id)!['tiene'], (t) => t['k'] == 'tenedor');
  List<num> FRESTO(String id) => id == 'luis' ? const [-9, 19] : const [7, 12];

  // comer.js: dejaTenedor (moves line 616: the fork lies on the row by the plate, SY). He lays his fork down by his
  // plate (it stays there)
  Future<void> dejaTenedor(String id) async {
    final p = G(id)!, f = tenedorDe(id), pl = ob('pl_$id');
    if (f == null) return;
    final d = D1(p), plx = pl!['x'] as num, ply = pl['y'] as num;
    final dx = plx + (id == 'luis' ? -18 : 18);
    await mueveTiene(
      id,
      f,
      (dx - (p['x'] as num)) * d,
      (p['y'] as num) - (ply - 1 + (dx - plx) / 2),
      3,
    );
    _cosas.add(<String, dynamic>{
      'id': 'tf_$id',
      'k': 'tenedorH',
      'x': dx,
      'y': ply - 1 + (dx - plx) / 2,
    });
    SFX.blip();
    await suelta(id, f);
  }

  // comer.js: tomaTenedor. Or takes it up again
  Future<M> tomaTenedor(String id) async {
    final p = G(id)!;
    final had = tenedorDe(id);
    if (had != null) return had;
    final c = ob('tf_$id'), r = FRESTO(id);
    if (c == null) {
      final it = <String, dynamic>{'k': 'tenedor', 'e': 1, 'dx': r[0], 'dy': r[1]};
      (p['tiene'] as List).add(it);
      return it;
    }
    final it = await toma(id, c, null, null, {'n': 3});
    it['k'] = 'tenedor';
    it['e'] = 1;
    it['v'] = '';
    _splice(_cosas, c);
    await mueveTiene(id, it, r[0], r[1], 3);
    return it;
  }

  // comer.js: forkfuls. The fork goes down to his plate, comes up with rice on it (the plate has less: niveles are the
  // plate's states after each forkful), goes to his mouth, he chews; then the fork goes back to rest
  Future<void> forkfuls(String id, M pl, List<String> niveles) async {
    final p = G(id)!, f = await tomaTenedor(id);
    final d = D1(p);
    // seated, the plate is far below his shoulder: the fork dips just over it
    final pd = [
      ((pl['x'] as num) - (p['x'] as num)) * d,
      jsTruthy(p['sent']) ? 17 : (p['y'] as num) - ((pl['y'] as num) - 6),
    ];
    for (final nv in niveles) {
      await mueveTiene(id, f, pd[0], pd[1] - 4, 3);
      await wait(TICK * 2);
      f['v'] = 'c';
      pl['v'] = nv;
      SFX.blip();
      await wait(TICK * 4);
      await mueveTiene(
        id,
        f,
        jsTruthy(p['sent']) ? 9 : 11,
        bocaY(id, p) - 6,
        3,
      );
      await wait(TICK * 3);
      f['v'] = '';
      p['boca'] = 1;
      await wait(TICK * 4);
      p['boca'] = 0;
      await wait(TICK * 2);
    }
    final r = FRESTO(id);
    await mueveTiene(id, f, r[0], r[1], 3);
  }

  // comer.js: nivelOlla. The level of rice in the pot at the n-th scoop (18 scoops in all: a level for every other)
  String nivelOlla(num n) => n <= 1
      ? 'lleno0'
      : n >= 18
      ? 'vacio'
      : 'n${math.min(7, math.max(1, ((n - 1) * 7 / 16).ceil()))}';

  /* ---------- the places of story 35 ---------- */

  // comer.js: copa, liq
  M? copa(String id) => ob('t_$id');
  void liq(String id, String v, [Object? vapor]) {
    final t = copa(id);
    if (t != null) {
      t['v'] = v;
      if (vapor != null) t['vapor'] = vapor;
    }
  }

  // comer.js: vierteItem. Something he pours: its lip is put at (tx,ty); it is turned over to pour to the right (flip),
  // the stream falls h from the lip. For a person (p) or the frog (p = "rana"). The hand is where the handle is
  M vierteItem(
    Object p,
    String k,
    Object? v,
    num tx,
    num ty,
    bool flip,
    num h,
    String col, [
    num? e,
  ]) {
    final im = cosaSpr('tilt$k', v),
        pico = picoOf(im)!,
        E = e == null || e == 0 ? 1 : e,
        s = flip ? -1 : 1,
        ox = (pico[0] - im.w / 2) * E * s,
        oy = (pico[1] - im.h / 2) * E,
        cxA = tx - ox,
        cyA = ty - oy;
    final ch = <String, dynamic>{'h': h, 'col': col};
    if (p == 'rana') {
      return {
        'k': 'tilt$k',
        'v': v,
        'dx': cxA - cx(),
        'dy': pies() - cyA,
        'e': E,
        'flip': flip,
        'chorro': ch,
      };
    }
    final pp = p as M, d = _d(pp);
    return {
      'k': 'tilt$k',
      'v': v,
      'dx': (cxA - (pp['x'] as num)) * d,
      'dy': (pp['y'] as num) - cyA,
      'e': E,
      'flip': flip,
      'chorro': ch,
    };
  }

  // comer.js: puestoVierte (moves line 638: never a place on the floor under the table, MESAPIE). Where must somebody
  // stand so that his hand reaches the handle when the lip of what he pours is at (tx,ty): along his row, the place where
  // the handle is nearest to his shoulder; he walks there (a few steps), then pours
  ({num x, num y, num d}) puestoVierte(
    String id,
    String k,
    Object? v,
    num tx,
    num ty,
    bool flip,
    List<num> ys,
    Object? dir,
  ) {
    final cu = CUE(id);
    var best = (x: _round(tx + 19) as num, y: ys[0], d: 99 as num);
    for (final y in ys) {
      final hy = hombroY(id, const {'sent': 0});
      for (var x = _round(tx - 44); x <= tx + 48; x += 2) {
        if ((x - tx).abs() < 14 || MESAPIE(x, y)) continue;
        final fake = <String, dynamic>{
          'x': x,
          'y': y,
          'dir': jsTruthy(dir) ? dir : -1,
          'sent': 0,
        };
        final it = vierteItem(fake, k, v, tx, ty, flip, 10, '#000'),
            d = _d(fake),
            H = agarres(
              it,
              x + d * (it['dx'] as num),
              y - (it['dy'] as num),
              flip,
            )[0],
            sy = y - hy,
            dd = math.min(
              _hypot(H[0] - (x - cu.sx), H[1] - sy),
              _hypot(H[0] - (x + cu.sx), H[1] - sy),
            );
        if (dd < best.d - .5 ||
            ((dd - best.d).abs() <= .5 && (x - tx).abs() < (best.x - tx).abs())) {
          best = (x: x, y: y, d: dd);
        }
      }
    }
    return best;
  }

  // comer.js: vierteA
  Future<M> vierteA(
    String id,
    String k,
    Object? v,
    num tx,
    num ty,
    bool flip,
    num h,
    String col, [
    List<num>? ys,
  ]) async {
    final p = G(id)!,
        pz = puestoVierte(id, k, v, tx, ty, flip, ys ?? FRENTE, p['dir']);
    if ((pz.x - (p['x'] as num)).abs() > 1 || (pz.y - (p['y'] as num)).abs() > 1) {
      final d0 = p['dir'];
      await mueve(id, pz.x, pz.y);
      p['dir'] = d0;
    }
    return vierteItem(p, k, v, tx, ty, flip, h, col);
  }

  // comer.js: CUCHITA. The frog's teaspoon: the handle is shorter than his forearm
  M CUCHITA() => {
    'k': 'uten',
    'ax': 9,
    'ay': 12,
    'bx': 17,
    'by': 15,
    'load': '',
    'o': <String, dynamic>{'plata': 1, 'rx': 1, 'ry': 1},
    'gx': 9,
    'gy': 12,
  };

  // comer.js: ranaToma. The frog's hands: he takes a thing in his hand (he must stand beside it) and holds it at (dx,dy)
  // from his feet
  Future<M> ranaToma(M o, num? dx, num? dy, [M? opt0]) async {
    final opt = opt0 ?? const <String, dynamic>{};
    final q = _cq,
        e = _or(o['e'], 1),
        im = cosaSpr(o['k'] as String, o['v']),
        cxw = o['x'] as num,
        cyw = (o['y'] as num) - im.h * e / 2;
    final it = <String, dynamic>{
      'k': o['k'],
      'v': o['v'],
      'e': o['e'],
      'dx': cxw - cx(),
      'dy': pies() - cyw,
      ...?(opt['extra'] as M?),
    };
    if (jsTruthy(o['sp'])) it['sp'] = o['sp'];
    if (jsTruthy(o['vapor'])) it['vapor'] = o['vapor'];
    final fl =
        opt['flip'] ??
        (CONASA.contains(o['k']) ? (it['dx'] as num) > 0 : false);
    it['flip'] = fl;
    final H = agarres(it, cxw, cyw, fl)[0], sd = H[0] >= cx() ? 1 : -1;
    final hb = <String, dynamic>{'k': 'brazo', 'gx': sd * 9, 'gy': 3};
    (q['tiene'] as List).add(hb);
    final g1 = [H[0] - cx(), pies() - H[1]];
    for (var i = 1; i <= 3; i++) {
      hb['gx'] = sd * 9 + (g1[0] - sd * 9) * i / 3;
      hb['gy'] = 3 + (g1[1] - 3) * i / 3;
      await wait(TICK);
    }
    _quita(q, hb);
    o['vis'] = 0;
    (q['tiene'] as List).add(it);
    SFX.blip();
    await wait(TICK);
    if (dx != null) {
      final x0 = it['dx'] as num, y0 = it['dy'] as num, n = _or(opt['m'], 4);
      for (var i = 1; i <= n; i++) {
        it['dx'] = x0 + (dx - x0) * i / n;
        it['dy'] = y0 + (dy! - y0) * i / n;
        await wait(TICK);
      }
    }
    return it;
  }

  // comer.js: ranaPon. He sets it down with its foot at (x,y)
  Future<void> ranaPon(M it, M o, num x, num y, [num? n0]) async {
    final q = _cq,
        e = _or(it['e'], 1),
        im = cosaSpr(it['k'] as String, it['v']),
        t = [x - cx(), pies() - (y - im.h * e / 2)],
        x0 = it['dx'] as num,
        y0 = it['dy'] as num;
    final n = n0 == null || n0 == 0 ? 4 : n0;
    for (var i = 1; i <= n; i++) {
      it['dx'] = x0 + (t[0] - x0) * i / n;
      it['dy'] = y0 + (t[1] - y0) * i / n;
      await wait(TICK);
    }
    o.addAll({'v': it['v'], 'x': x, 'y': y, 'vis': 1});
    if (jsTruthy(it['sp'])) o['sp'] = it['sp'];
    _quita(q, it);
    SFX.blip();
    await wait(TICK);
  }

  // comer.js: bowlSugar, ranaCucharita. His teaspoon: he takes the spoon that stands in the sugar bowl (the bowl shows
  // none while he has it), dips it into the sugar and lifts it, heaped
  M bowlSugar() => ob('azucarera')!;
  Future<M> ranaCucharita() async {
    final q = _cq, az = bowlSugar();
    var sp = _find(q['tiene'], (t) => t['k'] == 'uten');
    if (sp == null) {
      await ranaA(AZU[0] - 14, AZU[1] - 2);
      sp = CUCHITA();
      final w = [AZU[0] + 5, AZU[1] - 18];
      sp['ax'] = w[0] - cx();
      sp['ay'] = pies() - w[1];
      sp['bx'] = (sp['ax'] as num) + 9;
      sp['by'] = (sp['ay'] as num) + 3;
      sp['gx'] = sp['ax'];
      sp['gy'] = sp['ay'];
      (q['tiene'] as List).add(sp);
      az['tomada'] = 1;
      SFX.blip();
      await wait(TICK * 3);
    }
    await ranaA(AZU[0] - 14, AZU[1] - 2);
    await cucharaAR(sp, AZU[0] + 1, AZU[1] - 9, false, 4);
    await wait(TICK * 2);
    sp['load'] = 'azu';
    SFX.blip();
    await wait(TICK * 4);
    return sp;
  }

  // comer.js: granosCaen. Grains of sugar fall from the spoon over a cup, one after the other (six white dots, two
  // pixels each, over about ten ticks)
  Future<void> granosCaen(num cxw, num cyw) async {
    const xs = [-3, 1, -1, 2, 0, -2];
    final gs = [
      for (final dx in xs)
        <String, dynamic>{'k': 'grano', 'x': cxw + dx, 'y': cyw - 17, 'e': 1},
    ];
    SFX.blip();
    for (var t = 0; t < xs.length + 4; t++) {
      for (var i = 0; i < gs.length; i++) {
        final g = gs[i], k = _vuelos.indexOf(g);
        if (t >= i && t < i + 4) {
          if (k < 0) _vuelos.add(g);
          g['y'] = cyw - 17 + (t - i) * 3;
        } else if (t >= i + 4 && k >= 0) {
          _vuelos.removeAt(k);
        }
      }
      await wait(TICK);
    }
    for (final g in gs) {
      final k = _vuelos.indexOf(g);
      if (k >= 0) _vuelos.removeAt(k);
    }
  }

  // comer.js: azucarEn (moves line 662: the frog beside the cup on the cloth, on the row of the one who holds it, SY).
  // The teaspoon with sugar is brought to a cup (the cup is at (cxw,cyw) at the moment): grains fall from it into the
  // cup in three little falls, he stirs, and the spoon stays standing in the cup
  Future<void> azucarEn(
    num cxw,
    num cyw,
    M sp,
    M cup,
    bool mal,
    String? who,
  ) async {
    final q = _cq;
    final wx = G(who)!['x'] as num;
    final fx = cxw <= 150 ? cxw - 22 : cxw + 16,
        fy = SY(wx, 146) + (wx < 118 ? 6 : -6),
        iz = fx > cxw;
    await ranaA(fx, fy);
    await cucharaAR(sp, cxw + (iz ? 4 : -4), cyw - 12, iz, 5);
    if (mal) W['lista35'] = 1;
    await wait(TICK * 3);
    sp['load'] = '';
    await granosCaen(cxw, cyw);
    // the grains fall, a small white heap lies on the coffee for a moment, then he stirs
    {
      final base = cup['v'];
      cup['v'] = '${_js(base)}+';
      await wait(TICK * 5);
      cup['v'] = base;
    }
    if (mal) cup['v'] = 'azu';
    await wait(TICK * 2);
    // the spoon goes back into the bowl (it is his, and only carries sugar)
    await ranaA(AZU[0] - 14, AZU[1] - 2);
    await cucharaAR(sp, AZU[0] + 5, AZU[1] - 17, false, 4);
    _quita(q, sp);
    bowlSugar()['tomada'] = 0;
    SFX.blip();
    await wait(TICK * 3);
    // and the man stirs with his own teaspoon and leaves it standing in his cup
    if (!mal && who != null) await revuelve(who);
  }

  // comer.js: revuelve. Each man has a teaspoon of his own lying by his cup: after the sugar goes in he takes it with his
  // free hand, stirs, and leaves it standing in the cup
  Future<void> revuelve(String id) async {
    final p = G(id)!,
        tc = ob('tc_$id'),
        cup = _find(p['tiene'], (x) => x['k'] == 'taza' || x['k'] == 'tazacu');
    if (tc == null || tc['vis'] == 0 || cup == null) return;
    final it = await toma(id, tc, null, null, {'n': 3, 'm': 3, 'flip': false});
    it['k'] = 'cucharilla';
    await mueveTiene(
      id,
      it,
      (cup['dx'] as num) - 2,
      (cup['dy'] as num) + 8,
      3,
    );
    // he stirs
    for (var i = 0; i < 4; i++) {
      it['dx'] = (it['dx'] as num) + (i % 2 != 0 ? 3 : -3);
      await wait(TICK * 2);
    }
    cup['sp'] = 1;
    cup['k'] = 'tazacu';
    SFX.blip();
    await suelta(id, it);
    await wait(TICK * 2);
  }

  // comer.js: dejaCuchara. Or he lays it down again (empty cups)
  Future<void> dejaCuchara(String id) async {
    final p = G(id)!, t = copa(id)!, tc = ob('tc_$id');
    if (tc == null || tc['vis'] != 0) return;
    final r = rel(id, (t['x'] as num) + 1, (t['y'] as num) - 16),
        hb = <String, dynamic>{'k': 'brazo', '_m': 1, 'gx': 0, 'gy': 0, 'sh': 1};
    (p['tiene'] as List).add(hb);
    final rr = restHand(id);
    hb['gx'] = rr[0];
    hb['gy'] = rr[1];
    await manoA(id, r[0], r[1], 3, 1);
    t['sp'] = 0;
    SFX.blip();
    final it = <String, dynamic>{'k': 'cucharilla', 'e': 1},
        c = centroPara(id, it, (t['x'] as num) + 1, (t['y'] as num) - 16);
    it['dx'] = c[0];
    it['dy'] = c[1];
    sinManos(id);
    (p['tiene'] as List).add(it);
    await wait(TICK);
    await pon(id, it, tc, tc['x'] as num, tc['y'] as num, 3);
    tc['vis'] = 1;
    await wait(TICK);
  }

  // comer.js: sorbos. Somebody drinks from the cup he holds: lift, sip, the cup is lower (niveles: what is in it after
  // each sip), down again
  Future<void> sorbos(
    String id,
    M it,
    List<String> niveles,
    num dx0,
    num dy0,
  ) async {
    final p = G(id)!;
    for (final nv in niveles) {
      await mueveTiene(id, it, jsTruthy(p['sent']) ? 10 : 12, bocaY(id, p) - 2, 4);
      await wait(TICK * 3);
      it['ang'] = .5;
      p['boca'] = 1;
      SFX.blip();
      await wait(TICK * 5);
      it['v'] = nv;
      await wait(TICK * 3);
      it['ang'] = 0;
      p['boca'] = 0;
      await wait(TICK * 2);
      await mueveTiene(id, it, dx0, dy0, 4);
      await wait(TICK * 3);
    }
  }

  // comer.js: mitad. The half-full state of a cup
  String mitad(Object? v) => '${_jsS(v).replaceFirst(RegExp(r'_$'), '')}_';

  /* ---------- moving: everybody walks, every thing is carried by a hand ---------- */

  // comer.js: mueve. A walk: a straight line at a steady pace (PASO_PX, 5 px a tick), one foot after the other
  Future<void> mueve(String id, num x, num y, [num? n0]) async {
    final p = G(id);
    if (p == null) return;
    final x0 = p['x'] as num, y0 = p['y'] as num, dist = _hypot(x - x0, y - y0);
    if (dist < .5) {
      p['x'] = x;
      p['y'] = y;
      return;
    }
    const PASO_PX = 5;
    final n = n0 != null && n0 != 0 ? n0 : math.max(1, (dist / PASO_PX).ceil());
    p['sent'] = 0;
    p['est'] = 0;
    p['paso'] = 1;
    if ((x - x0).abs() > 3) p['dir'] = x > x0 ? 1 : -1;
    for (var i = 1; i <= n; i++) {
      p['x'] = x0 + (x - x0) * i / n;
      p['y'] = y0 + (y - y0) * i / n;
      p['ci'] = _n(p['ci']) + 1;
      p['pie'] = const [1, 0, 2, 0][(p['ci'] as num).toInt() % 4];
      await wait(TICK);
    }
    p['x'] = x;
    p['y'] = y;
    p['paso'] = 0;
    p['pie'] = 0;
  }

  // comer.js: ruta
  Future<void> ruta(String id, List<List<num>> pts) async {
    for (final q in pts) {
      await mueve(id, q[0], q[1]);
    }
  }

  // comer.js: vuela. A thing falls or slides a short way (grains, a roll off a tipped tray, a drop): never from a table to
  // a hand
  Future<void> vuela(
    M o,
    num x0,
    num y0,
    num x1,
    num y1, [
    num? n0,
    num? arco,
  ]) async {
    final v = <String, dynamic>{'x': x0, 'y': y0, ...o};
    _vuelos.add(v);
    final n = n0 != null && n0 != 0 ? n0 : 5;
    for (var i = 1; i <= n; i++) {
      final t = i / n;
      v['x'] = x0 + (x1 - x0) * t;
      v['y'] = y0 + (y1 - y0) * t - (arco ?? 0) * math.sin(t * math.pi);
      await wait(TICK);
    }
    _splice(_vuelos, v);
  }

  // comer.js: mueveTiene. The thing a person holds changes place in his hand: it slides from where it is to (dx,dy) from
  // his feet
  Future<void> mueveTiene(String id, M it, num dx, num dy, [num? n0]) async {
    final n = n0 != null && n0 != 0 ? n0 : 5;
    final x0 = it['dx'] as num, y0 = it['dy'] as num;
    for (var i = 1; i <= n; i++) {
      it['dx'] = x0 + (dx - x0) * i / n;
      it['dy'] = y0 + (dy - y0) * i / n;
      await wait(TICK);
    }
    it['dx'] = dx;
    it['dy'] = dy;
  }

  // comer.js: corre. suelto: the act goes on while the story does; acts.ya waits for it
  Future<void> corre(M? o, Future<void> pr) {
    if (o != null && jsTruthy(o['suelto'])) {
      // (an act left running whose play is left meanwhile ends in "stop", as an unawaited promise did: not an error of
      // its own; acts.ya, which waits for it, still gets it)
      unawaited(pr.then((_) {}, onError: (Object _) {}));
      W['_mov'] = pr;
      return Future.value();
    }
    return pr;
  }

  // comer.js: ranaA (moves line 692: the hops counted on the old distance, each new place of the frog mapped to the old
  // one it stands for: HOPAT). A long way is several small hops (about 26 px each)
  Future<void> ranaA(num x, num y, [Object? h]) async {
    final q = _cq,
        d = _hypot(x - 16 - (q['x'] as num), y - 27 - (q['y'] as num));
    if (d < 3) return;
    List<num> k(List<num> a) => HOPAT['${_round(a[0])},${_round(a[1])}'] ?? a;
    final o = k([x, y]),
        f = k([(q['x'] as num) + 16, (q['y'] as num) + 27]),
        dd = _hypot(o[0] - f[0], o[1] - f[1]);
    await hopTo(
      _round(x - 16),
      _round(y - 27),
      (jsTruthy(h) ? _plus(h) : math.max(1, math.min(6, (dd / 26).ceil())))
          .toInt(),
    );
  }

  // comer.js: cx, pies
  num cx() => (_cq['x'] as num) + 16;
  num pies() => (_cq['y'] as num) + 27;

  // comer.js: detrasOK (moves line 695: DETRAS). Already behind the table
  bool detrasOK(M p) => DETRAS(p['x'] as num, p['y'] as num);

  // moves line 21: atras. A walk behind the table: by the lane behind the chairs (from a seat first a step back and to
  // the right) and the passage at its left end (PB)
  Future<void> atras(String id, num x, num y) async {
    final p = G(id)!, px = p['x'] as num, ln = SY(px, ATRAS);
    if ((p['y'] as num) > ln + 3 && px > 80 && !(x > XP - 8 && px > XP - 8)) {
      if (SILLA.any((s) => (s - px).abs() < 6)) {
        await mueve(id, px + 12, SY(px + 12, ASIENTO - 3));
      }
      await mueve(id, G(id)!['x'] as num, SY(G(id)!['x'] as num, ATRAS));
    }
    final q = G(id)!,
        a = (q['x'] as num) < 80 && (q['y'] as num) > PB[1] - 1,
        b = x < 80 && y > PB[1] - 1;
    if (b && !a && (q['x'] as num) > 86) await mueve(id, 86, SY(86, ATRAS));
    if (a != b) await mueve(id, PB[0], PB[1]);
    await mueve(id, x, y);
  }

  // comer.js: detras (moves lines 698 to 701: round the table's right end, XP, and along the lane behind the chairs). To
  // the lane behind the table
  Future<void> detras(String id, num x, [num? y0]) async {
    final p = G(id)!;
    final y = y0 ?? SY(x, ATRAS);
    if (detrasOK(p)) {
      await atras(id, x, y);
      return;
    }
    final px = p['x'] as num, pts = <List<num>>[];
    if (px < XP - 6 && (p['y'] as num) < FR - 2) pts.add([px, FR]);
    if (px < XP - 6) pts.add([XP, FR]);
    pts.add([math.max(XP, px), SY(math.max(XP, px), ATRAS)]);
    await ruta(id, pts);
    await atras(id, x, y);
  }

  // comer.js: delante (moves lines 702 to 705: out round the table's right end)
  Future<void> delante(String id, num x, num y) async {
    final p = G(id)!;
    if (!detrasOK(p)) {
      await mueve(id, x, y);
      return;
    }
    if ((p['x'] as num) < XP - 6) await atras(id, XP, SY(XP, ATRAS));
    final pts = <List<num>>[
      [math.max(XP, G(id)!['x'] as num), FR],
    ];
    if (x < XP - 8) pts.add([x, FR]);
    pts.add([x, y]);
    await ruta(id, pts);
  }

  // comer.js: entra. He walks in from the left (out of the picture)
  Future<void> entra(String id, num x, num y, [Object? dir]) async {
    final p = G(id)!;
    p['sent'] = 0;
    p['pose'] = 'idle';
    if (p['vis'] == 0) {
      p['vis'] = 1;
      p['x'] = PUERTA[0];
      p['y'] = y;
    }
    p['dir'] = 1;
    p['tiene'] ??= <dynamic>[];
    await mueve(id, x, y);
    if (jsTruthy(dir)) p['dir'] = dir;
  }

  // comer.js: sale (moves lines 707 to 710: from behind the table out by the doorway, DOOR)
  Future<void> sale(String id) async {
    final p = G(id)!;
    if (p['vis'] == 0) return;
    p['sent'] = 0;
    p['est'] = 0;
    p['come'] = null;
    p['cara'] = null;
    p['pose'] = 'idle';
    p['abre'] = 0;
    if (detrasOK(p)) {
      await atras(id, DOOR[0] + 6, DOOR[1] + 8);
      await mueve(id, DOOR[0], DOOR[1]);
      p['vis'] = 0;
      p['x'] = PUERTA[0];
      p['y'] = 190;
      return;
    } else if ((p['x'] as num) > 84 && (p['y'] as num) < FR - 2) {
      await mueve(id, p['x'] as num, FR);
    }
    await mueve(
      id,
      PUERTA[0],
      math.max(190, math.min(p['y'] as num, FR)),
    );
    p['vis'] = 0;
  }

  // comer.js: sienta (moves lines 712 to 714: in by the doorway, round the table's right end, along the lane; the seat
  // and its row by SY). To a chair behind the table, and sits: the last step down is in view
  Future<void> sienta(String id, int i) async {
    final p = G(id)!;
    if (p['vis'] != 0 &&
        jsTruthy(p['sent']) &&
        ((p['x'] as num) - SILLA[i]).abs() < 2) {
      return;
    }
    p['sent'] = 0;
    p['est'] = 0;
    if (p['vis'] == 0) {
      p['vis'] = 1;
      p['x'] = DOOR[0];
      p['y'] = DOOR[1];
      p['tiene'] ??= <dynamic>[];
    }
    await detras(id, SILLA[i] + 12, SY(SILLA[i] + 12, ATRAS));
    await mueve(id, SILLA[i] + 12, SY(SILLA[i] + 12, ASIENTO - 3), 2);
    await mueve(id, SILLA[i], SY(SILLA[i], ASIENTO), 2);
    p['dir'] = 1;
    p['pose'] = 'idle';
    p['tiene'] ??= <dynamic>[];
    p['sent'] = 1;
    p['y'] = SY(SILLA[i], ASIENTO);
    p['dy'] = -4;
    await wait(TICK * 4);
    p['dy'] = -2;
    await wait(TICK * 4);
    p['dy'] = 0;
    SFX.blip();
    await wait(TICK);
  }

  // comer.js: levanta (moves lines 718, 719: a step back and to the right, to the lane, SY). He stands up from his chair
  // in steps, and walks round the end of the table to (x,y) on the floor
  Future<void> levanta(String id, num x, num y) async {
    final p = G(id)!;
    p['pose'] = 'idle';
    // still sitting, rising: his head goes up in steps
    p['dy'] = -3;
    await wait(TICK * 4);
    p['dy'] = -6;
    await wait(TICK * 4);
    // upright, the legs under the cloth
    p['sent'] = 0;
    p['y'] = SY(p['x'] as num, ASIENTO);
    p['dy'] = 0;
    await wait(TICK * 4);
    await mueve(id, (p['x'] as num) + 12, SY((p['x'] as num) + 12, ASIENTO - 3), 1);
    await wait(TICK * 2);
    await mueve(id, p['x'] as num, SY(p['x'] as num, ATRAS), 2);
    await delante(id, x, y);
  }

  // comer.js: LEP (moves line 723). Where somebody stands to ask: to the left of the table's end, on the floor
  List<int> LEP(String id) => Comer.NINO(id) ? LEP_NINO : LEP_ADULTO;

  // (comer.js:724 platoNino, the plate a child holds in his back hand: made by the old file, used by none of its lines)

  /* ---------- hands: reach, take, carry, put down ---------- */

  // comer.js: rel. A point of the picture, from his feet, dx towards where he faces
  List<num> rel(String id, num wx, num wy) {
    final p = G(id)!, d = _d(p);
    return [(wx - (p['x'] as num)) * d, (p['y'] as num) - wy];
  }

  // comer.js: restHand
  List<num> restHand(String id) {
    final p = G(id)!, cu = CUE(id);
    return [
      cu.sx + 1.5,
      hombroY(id, p) - (jsTruthy(p['sent']) ? cu.L * 1.25 : cu.L * 1.7),
    ];
  }

  // comer.js: manoA. His empty hand goes to (gx,gy) (from his feet) in n ticks; s: the side of the picture of the
  // shoulder it comes from (0: the side he faces)
  Future<M> manoA(String id, num gx, num gy, [num? n0, num? s0]) async {
    final p = G(id)!, d = _d(p), s = s0 ?? 0;
    final sh = s != 0 ? s * d : 1, tag = s != 0 ? s : 9;
    p['tiene'] ??= <dynamic>[];
    var b = _find(p['tiene'], (t) => t['k'] == 'brazo' && t['_m'] == tag);
    if (b == null) {
      final r = restHand(id);
      b = <String, dynamic>{
        'k': 'brazo',
        '_m': tag,
        'gx': r[0] * sh,
        'gy': r[1],
        'sh': sh,
      };
      if (s == 0) b['gx'] = r[0];
      (p['tiene'] as List).add(b);
    }
    final x0 = b['gx'] as num, y0 = b['gy'] as num;
    final n = n0 != null && n0 != 0 ? n0 : 4;
    for (var i = 1; i <= n; i++) {
      b['gx'] = x0 + (gx - x0) * i / n;
      b['gy'] = y0 + (gy - y0) * i / n;
      await wait(TICK);
    }
    b['gx'] = gx;
    b['gy'] = gy;
    return b;
  }

  // comer.js: sinManos
  void sinManos(String id) {
    final p = G(id)!;
    p['tiene'] = [
      for (final t in (p['tiene'] as List?) ?? const [])
        if (!jsTruthy((t as Map)['_m'])) t,
    ];
  }

  // comer.js: centroPara. Where must the centre of the thing be for its (first) hand to be at the world point (wx,wy)
  List<num> centroPara(String id, M it, num wx, num wy) {
    final p = G(id)!, d = _d(p);
    final fl = it['flip'] ?? (CONASA.contains(_Draw._base(it)) ? d > 0 : false);
    final H = agarres(it, 0, 0, fl)[0];
    final ix = wx - H[0], iy = wy - H[1];
    return [(ix - (p['x'] as num)) * d, (p['y'] as num) - iy];
  }

  // comer.js: toma. He takes thing o off the table in his hand: the hand goes to it, the thing leaves the table in it,
  // and he holds it at (dx,dy) from his feet. Returns the item he holds
  Future<M> toma(String id, M o, num? dx, num? dy, [M? opt0]) async {
    final opt = opt0 ?? const <String, dynamic>{};
    final p = G(id)!,
        d = _d(p),
        im = cosaSpr(o['k'] as String, o['v']),
        e = _or(o['e'], 1),
        cxw = o['x'] as num,
        cyw = (o['y'] as num) - im.h * e / 2;
    final it = <String, dynamic>{
      'k': o['k'],
      'v': o['v'],
      'e': o['e'],
      'dx': (cxw - (p['x'] as num)) * d,
      'dy': (p['y'] as num) - cyw,
      ...?(opt['extra'] as M?),
    };
    if (opt['flip'] != null) it['flip'] = opt['flip'];
    if (jsTruthy(o['vapor']) && opt['vapor'] != 0) {
      it['vapor'] = o['vapor'];
      it['vn'] = _or(o['vn'], 1);
    }
    final fl = it['flip'] ?? (CONASA.contains('${o['k']}') ? d > 0 : false),
        H = agarres(it, cxw, cyw, fl);
    final n = _or(opt['n'], 3);
    if (H.length > 1) {
      final a1 = rel(id, H[0][0], H[0][1]), a2 = rel(id, H[1][0], H[1][1]);
      await Future.wait<void>([
        manoA(id, a1[0], a1[1], n, H[0][0] < H[1][0] ? -1 : 1),
        manoA(id, a2[0], a2[1], n, H[0][0] < H[1][0] ? 1 : -1),
      ]);
    } else {
      final a1 = rel(id, H[0][0], H[0][1]),
          sd = (H[0][0] - (p['x'] as num)).abs() < 3
              ? 0
              : H[0][0] > (p['x'] as num)
              ? 1
              : -1;
      await manoA(id, a1[0], a1[1], n, sd);
    }
    sinManos(id);
    o['vis'] = 0;
    (p['tiene'] as List).add(it);
    SFX.blip();
    await wait(TICK);
    if (dx != null) await mueveTiene(id, it, dx, dy!, _or(opt['m'], 4));
    return it;
  }

  // comer.js: pon. He sets the thing he holds down on the table, its foot at (x,y), and lets go: the hand goes back to
  // rest
  Future<void> pon(
    String id,
    M it,
    M o,
    num x,
    num y, [
    num? n,
    void Function(M o)? after,
  ]) async {
    final p = G(id)!,
        d = _d(p),
        im = cosaSpr(it['k'] as String, it['v']),
        e = _or(it['e'], 1),
        t = [(x - (p['x'] as num)) * d, (p['y'] as num) - (y - im.h * e / 2)];
    await mueveTiene(id, it, t[0], t[1], n != null && n != 0 ? n : 4);
    o.addAll({'v': it['v'], 'x': x, 'y': y, 'vis': 1});
    if (jsTruthy(it['sp'])) o['sp'] = it['sp'];
    if (after != null) after(o);
    SFX.blip();
    await suelta(id, it);
  }

  // comer.js: suelta. He lets go of the thing he holds (it stays where his hand is, or is gone) and his hand goes back to
  // rest
  Future<void> suelta(String id, M it) async {
    final p = G(id)!, d = _d(p);
    final fl = it['flip'] ?? (CONASA.contains('${it['k']}') ? d > 0 : false);
    final H = agarres(
      it,
      (p['x'] as num) + d * (it['dx'] as num),
      (p['y'] as num) - (it['dy'] as num),
      fl,
    )[0];
    final s = (H[0] - (p['x'] as num)).abs() < 3
        ? d
        : H[0] > (p['x'] as num)
        ? 1
        : -1;
    final r = rel(id, H[0], H[1]);
    _quita(p, it);
    final b = <String, dynamic>{
      'k': 'brazo',
      '_m': 9,
      'gx': r[0],
      'gy': r[1],
      'sh': s * d,
    };
    (p['tiene'] as List).add(b);
    final rr = restHand(id);
    await manoA(id, rr[0] * (b['sh'] as num), rr[1], 3);
    sinManos(id);
  }

  // comer.js: CUCH. The frog's spoon, in his right hand (0) or his left (1): the handle is as long as his forearm
  M CUCH(int lado) => lado != 0
      ? {
          'k': 'uten',
          'ax': -10,
          'ay': 12,
          'bx': -20,
          'by': 15,
          'load': '',
          'o': <String, dynamic>{'rx': 3, 'ry': 2},
          'gx': -10,
          'gy': 12,
        }
      : {
          'k': 'uten',
          'ax': 10,
          'ay': 12,
          'bx': 20,
          'by': 15,
          'load': '',
          'o': <String, dynamic>{'rx': 3, 'ry': 2},
          'gx': 10,
          'gy': 12,
        };

  /* ---------- the plates, the rolls ---------- */

  // comer.js: ROLLOS, quitaCesta
  List ROLLOS(M pl) => (pl['rollos'] as List?) ?? (pl['rollos'] = <dynamic>[]);
  num quitaCesta() {
    final ce = ob('cesta')!, n = nCesta();
    ce['v'] = '${jsNum(n - 1)}:0';
    return n - 1;
  }

  /* ---------- story 33: where things and people are ---------- */

  // comer.js: enEstacion
  bool enEstacion(String id) {
    final p = G(id), e = EST33[id];
    return e != null &&
        p != null &&
        p['vis'] != 0 &&
        ((p['x'] as num) - e.x).abs() < 3 &&
        ((p['y'] as num) - e.y).abs() < 3;
  }

  // comer.js: vaEstacion (moves line 762: in by the doorway). A child walks to his place (from the door or from the left
  // end of the table)
  Future<void> vaEstacion(String id) async {
    final p = G(id)!, e = EST33[id]!;
    if (p['vis'] == 0) {
      p['vis'] = 1;
      p['x'] = DOOR[0];
      p['y'] = DOOR[1];
      p['tiene'] ??= <dynamic>[];
    }
    p['sent'] = 0;
    p['pose'] = 'idle';
    await detras(id, e.x, e.y);
    p['dir'] = e.dir;
    p['est'] = 1;
  }

  // comer.js: desdeEstacion. And back to the left end
  Future<void> desdeEstacion(String id) async {
    final p = G(id)!, lp = LEP(id);
    p['pose'] = 'idle';
    p['est'] = 0;
    await delante(id, lp[0], lp[1]);
    p['dir'] = 1;
  }

  // comer.js: ponPlato. The roll in his hand goes onto his plate (the hand puts it down and goes back to rest)
  Future<void> ponPlato(String id, M it, M pl) async {
    final p = G(id)!, d = _d(p);
    await mueveTiene(
      id,
      it,
      ((pl['x'] as num) - (p['x'] as num)) * d,
      (p['y'] as num) - ((pl['y'] as num) - 6),
      4,
    );
    final v = _js(it['v']).split(':');
    ROLLOS(pl).add(<String, dynamic>{
      'st': v[0],
      'con': v.length > 1 ? v[1] : null,
      'dx': 0,
    });
    SFX.blip();
    await suelta(id, it);
  }

  // comer.js: tomaPlato. Or comes off it into his hand (a roll that was bitten and left stays on the plate: he takes the
  // new one)
  Future<M?> tomaPlato(String id, M pl) async {
    final p = G(id)!, rs = ROLLOS(pl);
    final ix = rs.indexWhere((r) => !jsTruthy((r as Map)['mal']));
    final r = ix >= 0 ? rs[ix] as M : null;
    if (r == null) return null;
    final w = [(pl['x'] as num) - 4, (pl['y'] as num) - 6],
        r0 = rel(id, w[0], w[1]);
    await manoA(id, r0[0], r0[1], 3);
    ROLLOS(pl).removeAt(ix);
    SFX.blip();
    final it = <String, dynamic>{
          'k': 'rollo',
          'v': '${_js(r['st'])}${jsTruthy(r['con']) ? ':${_js(r['con'])}' : ''}',
          'e': 1,
        },
        c = centroPara(id, it, w[0], w[1]);
    it['dx'] = c[0];
    it['dy'] = c[1];
    sinManos(id);
    (p['tiene'] as List).add(it);
    await wait(TICK * 2);
    return it;
  }

  // comer.js: rolloAFrog. The roll goes from the hand of the one who asks into the frog's hand: he holds it out, the
  // frog's hand comes to its other end, both hands are on it for a moment, then the first lets go
  Future<M> rolloAFrog(String id, M it) async {
    final p = G(id)!, q = _cq;
    await ranaA(HOME33[0], HOME33[1]);
    p['dir'] = 1;
    final c = centroPara(id, it, HO33[0], HO33[1]);
    await mueveTiene(id, it, c[0], c[1], 4);
    final wx = HO33[0] + 10,
        wy = HO33[1] - 1,
        hb = <String, dynamic>{'k': 'brazo', 'gx': -9, 'gy': 3},
        g1 = [wx - cx(), pies() - wy];
    (q['tiene'] as List).add(hb);
    for (var i = 1; i <= 3; i++) {
      hb['gx'] = -9 + (g1[0] + 9) * i / 3;
      hb['gy'] = 3 + (g1[1] - 3) * i / 3;
      await wait(TICK);
    }
    await wait(TICK * 3);
    final fit = <String, dynamic>{
      'k': 'rollo',
      'v': it['v'],
      'e': 1,
      'flip': true,
      'dx': HO33[0] + 5 - cx(),
      'dy': pies() - (HO33[1] - 2),
    };
    _quita(q, hb);
    (q['tiene'] as List).add(fit);
    SFX.blip();
    await suelta(id, it);
    await ranaMueve(fit, -17, 17, 3);
    return fit;
  }

  // comer.js: rolloDelFrog. And the other way: the frog holds the filled roll out, the hand of the one who asked comes to
  // its other end, both hands are on it, the frog lets go
  Future<M> rolloDelFrog(String id, M fit) async {
    final p = G(id)!, q = _cq;
    await ranaA(HOME33[0], HOME33[1]);
    p['dir'] = 1;
    await ranaMueve(fit, HO33[0] + 5 - cx(), pies() - (HO33[1] - 2), 4);
    final it = <String, dynamic>{'k': 'rollo', 'v': fit['v'], 'e': 1};
    final c = centroPara(id, it, HO33[0], HO33[1]);
    it['dx'] = c[0];
    it['dy'] = c[1];
    // his hand is on the roll's left end, the frog's on its right
    final r0 = rel(id, HO33[0], HO33[1]);
    await manoA(id, r0[0], r0[1], 3);
    await wait(TICK * 3);
    sinManos(id);
    (p['tiene'] as List).add(it);
    _quita(q, fit);
    SFX.blip();
    await wait(TICK * 2);
    return it;
  }

  // comer.js: ranaMueve. Something the frog holds moves in his hands to (dx,dy) from his feet
  Future<void> ranaMueve(M it, num dx, num dy, [num? n0]) async {
    final n = n0 != null && n0 != 0 ? n0 : 4;
    final x0 = it['dx'] as num, y0 = it['dy'] as num;
    for (var i = 1; i <= n; i++) {
      it['dx'] = x0 + (dx - x0) * i / n;
      it['dy'] = y0 + (dy - y0) * i / n;
      await wait(TICK);
    }
    it['dx'] = dx;
    it['dy'] = dy;
  }

  // comer.js: ranaFork. The frog eats at his plate with his fork (it lies by the plate): his hand takes it, he takes a
  // forkful from the plate (it has less), brings it to his mouth, and so three times; he lays the fork down again
  Future<void> ranaFork(List<String> niveles) async {
    final q = _cq, pl = ob('pl_rana')!, tf = ob('tf_rana')!;
    await ranaA(EAT34[0], EAT34[1]);
    final it = await ranaToma(tf, null, null, {'n': 3, 'm': 3, 'flip': false});
    it['k'] = 'tenedor';
    it['v'] = '';
    it['e'] = 1;
    _splice(_cosas, tf);
    await ranaMueve(it, 12, 9, 3);
    final pd = [PRANA[0] + 4 - cx(), pies() - (PRANA[1] - 1) + 1];
    for (final nv in niveles) {
      await ranaMueve(it, pd[0], pd[1], 3);
      await wait(TICK * 2);
      it['v'] = 'c';
      pl['v'] = nv;
      SFX.blip();
      await wait(TICK * 3);
      await ranaMueve(it, -3, 13, 3);
      await wait(TICK * 2);
      it['v'] = '';
      q['hace'] = 'come';
      await wait(TICK * 3);
      q['hace'] = null;
      await wait(TICK * 2);
      SFX.blip();
    }
    await ranaMueve(it, pd[0] + 8, pd[1] + 3, 3);
    _cosas.add(<String, dynamic>{
      'id': 'tf_rana',
      'k': 'tenedorH',
      'x': PRANA[0] + 12,
      'y': PRANA[1] - 1,
    });
    _quita(q, it);
    SFX.blip();
    await wait(TICK * 2);
  }

  // comer.js: inflar. His belly swells over three frames, and (vuelca) he tips over on his back over two more
  Future<void> inflar(bool vuelca) async {
    final q = _cq;
    q['lleno'] = 1;
    for (var i = 1; i <= 3; i++) {
      q['hinch'] = i;
      await wait(TICK * 4);
    }
    if (vuelca) {
      for (var i = 1; i <= 2; i++) {
        q['caida'] = i;
        await wait(TICK * 4);
      }
      q['espalda'] = 1;
      q['caida'] = 0;
      SFX.bonk();
      await wait(TICK * 5);
    }
  }

  // comer.js: desinflar. Deflating is the same the other way
  Future<void> desinflar() async {
    final q = _cq;
    if (jsTruthy(q['espalda'])) {
      q['espalda'] = 0;
      for (var i = 2; i >= 1; i--) {
        q['caida'] = i;
        await wait(TICK * 4);
      }
      q['caida'] = 0;
      await wait(TICK * 3);
    }
    for (var i = 2; i >= 0; i--) {
      q['hinch'] = i;
      await wait(TICK * 4);
    }
    q['lleno'] = 0;
    q['hinch'] = 3;
    await wait(TICK * 2);
  }
}
