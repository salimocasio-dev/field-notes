// Acts and movement helpers for La entrada (`part of 'entrada.dart'`).
part of 'entrada.dart';

extension _EntradaActs on Entrada {
  Future<void> _run(Map<String, dynamic> o, Future<void> Function() body) {
    if (jsTruthy(o['suelto'])) {
      final f = body();
      _loose.add(f);
      return Future<void>.value();
    }
    return body();
  }

  Future<void> _hopFrogTo(String spot) async {
    if (!_p.hasWorld(spot)) return;
    final at = _p.at(spot);
    final q = W['cq'] as Map<String, dynamic>;
    final dest = _frogAt(at);
    final sx = (q['x'] as num).toDouble(), sy = (q['y'] as num).toDouble();
    final dx = dest[0].toDouble() - sx, dy = dest[1].toDouble() - sy;
    final dist = math.sqrt(dx * dx + dy * dy);
    if (dist >= 2) {
      final steps = (dist / 18).ceil().clamp(1, 5);
      for (var i = 1; i <= steps; i++) {
        final t = i / steps;
        q['x'] = _round(sx + dx * t);
        q['y'] = _round(sy + dy * t);
        q['dy'] = i < steps ? -4 : 0;
        await wait(65);
      }
    }
    q['x'] = dest[0];
    q['y'] = dest[1];
    q['dy'] = 0;
    q['z'] = at.z;
    q['spot'] = spot;
  }

  Future<void> _walkPersonTo(
    String who,
    String spot, {
    int sent = 0,
    int steps = 4,
  }) async {
    if (!_p.hasWorld(spot)) return;
    final p = _gente[who] as Map<String, dynamic>?;
    if (p == null) return;
    final dest = _p.world(spot);
    if (p['vis'] == 0) {
      _placePerson(p, spot, vis: 1, sent: sent);
      await wait(60);
      return;
    }
    final x0 = (p['x'] as num).toDouble();
    final y0 = (p['y'] as num).toDouble();
    final z0 = (p['z'] as num).toDouble();
    p['sent'] = 0;
    for (var i = 1; i <= steps; i++) {
      final t = i / steps;
      p['x'] = x0 + (dest[0] - x0) * t;
      p['y'] = y0 + (dest[1] - y0) * t;
      p['z'] = z0 + (dest[2] - z0) * t;
      await wait(55);
    }
    _placePerson(p, spot, vis: 1, sent: sent);
  }

  Future<void> _crossMesero(String que) async {
    final mesero = _gente['mesero'] as Map<String, dynamic>?;
    if (mesero == null) return;
    W['meseroCarry'] = que;
    _placePerson(mesero, 'paso1', vis: 1);
    await wait(60);
    await _walkPersonTo('mesero', 'choque', steps: 3);
    await _walkPersonTo('mesero', 'paso2', steps: 3);
    mesero['vis'] = 0;
    W['meseroCarry'] = null;
  }

  Future<void> _seatWaitingPair84() async {
    // Seat whoever is currently waiting at cola1/cola2 at the best free table.
    // Round A wrong seats senor/senora at mesa3_c/d so mesa2_coqui stays clear; round B wrong seats hombre/mujer
    // at mesa2_a/b so mesera at tras_cuerda stays completely clear.
    final senor = _gente['senor'] as Map<String, dynamic>?;
    final senora = _gente['senora'] as Map<String, dynamic>?;
    final hombre = _gente['hombre'] as Map<String, dynamic>?;
    final mujer = _gente['mujer'] as Map<String, dynamic>?;
    final senorWaiting =
        senor != null && senor['vis'] == 1 && senor['spot'] == 'cola1';
    if (senorWaiting && senora != null) {
      await Future.wait([
        _walkPersonTo('senor', 'mesa3_c', sent: 1, steps: 4),
        _walkPersonTo('senora', 'mesa3_d', sent: 1, steps: 4),
      ]);
      return;
    }
    if (hombre != null && mujer != null) {
      final targetA = senor != null && senor['spot'] == 'mesa3_c'
          ? 'mesa2_a'
          : 'mesa3_c';
      final targetB = targetA == 'mesa2_a' ? 'mesa2_b' : 'mesa3_d';
      await Future.wait([
        _walkPersonTo('hombre', targetA, sent: 1, steps: 4),
        _walkPersonTo('mujer', targetB, sent: 1, steps: 4),
      ]);
    }
  }

  void _seat(String who, String spot, {int sent = 1}) =>
      _placePerson(_gente[who] as Map<String, dynamic>, spot, sent: sent);

  void _seatFamily(String table) {
    _seat('abuela', '${table}_a');
    _seat('abuelo', '${table}_b');
    _seat('luis', '${table}_c');
    _seat('carmen', '${table}_d');
  }

  Future<void> _advancePastRope84() async {
    // OPEN: entrada-sheet.json has no standing spots for the family beyond the rope (u > -0.35),
    // so after unhooking the rope in round B we hop Coquí past the rope (paso1) and walk the family
    // through into the best free table's spots before final84 completes the ending.
    W['cuerda'] = 'abierta';
    final best = _n(W['mesas84']).clamp(1, 3);
    final table = best == 3 ? 'mesa3' : (best == 2 ? 'mesa2' : 'mesa1');
    final meseraSpot = best == 3 ? 'mesera_fin' : 'junto_mesa';
    if (best == 1) {
      // Shift hombre/mujer to mesa2_c/d so mesa1_coqui and heads stay clear
      final h = _gente['hombre'] as Map<String, dynamic>?;
      final m = _gente['mujer'] as Map<String, dynamic>?;
      if (h != null && jsTruthy(h['vis']) && h['spot'] == 'mesa2_a') {
        _seat('hombre', 'mesa2_c');
      }
      if (m != null && jsTruthy(m['vis']) && m['spot'] == 'mesa2_b') {
        _seat('mujer', 'mesa2_d');
      }
    }
    await _hopFrogTo('paso1');
    await Future.wait([
      _walkPersonTo('mesera', meseraSpot, steps: 2),
      _walkPersonTo('abuela', '${table}_a', steps: 3),
      _walkPersonTo('abuelo', '${table}_b', steps: 3),
      _walkPersonTo('luis', '${table}_c', steps: 3),
      _walkPersonTo('carmen', '${table}_d', steps: 3),
    ]);
    _seatFamily(table);
    await _hopFrogTo('${table}_coqui');
  }

  Map<String, Act> _entradaOwnActs() => {
    'ya': (o) async {
      while (_loose.isNotEmpty) {
        final batch = List<Future<void>>.from(_loose);
        _loose.clear();
        await Future.wait(batch);
      }
    },
    'brilla': (o) async {
      W['twinkle'] = o['a'] ?? o['que'] ?? o['en'];
      await wait(120);
    },
    'ir': (o) => _run(o, () async {
      final spot = (o['a'] as String?) ?? 'felpudo';
      // OPEN: gen_entrada.py step 4 calls `ir(a=felpudo)` immediately before `juntos(llega(familia, puerta1..4))`.
      // Because felpudo (46, 128) shares row 128 with atril3 (34, 128) and atril4 (58, 128), walk the family back
      // to puerta1..4 alongside the frog so sprites-apart holds after `ir` as well as after `ya`.
      if (_n(W['story']) == 84 &&
          spot == 'felpudo' &&
          (_gente['luis'] as Map?)?['spot'] == 'atril3') {
        await Future.wait([
          _hopFrogTo(spot),
          _walkPersonTo('abuela', 'puerta1', steps: 3),
          _walkPersonTo('abuelo', 'puerta2', steps: 3),
          _walkPersonTo('luis', 'puerta3', steps: 3),
          _walkPersonTo('carmen', 'puerta4', steps: 3),
        ]);
        return;
      }
      await _hopFrogTo(spot);
    }),
    'llega': (o) => _run(o, () async {
      final quien = o['quien'] as String?;
      final a = o['a'] as String?;
      if (quien == null || a == null || !_p.hasWorld(a)) return;
      final p = _gente[quien] as Map<String, dynamic>?;
      if (p == null) return;
      final sent =
          a.startsWith('banco') || a.contains('_') && a.startsWith('mesa')
          ? 1
          : 0;
      if (_n(W['story']) == 85 && a == 'ante_cuerda1') {
        final comp = Entrada._companionOf(quien);
        final cp = _gente[comp] as Map<String, dynamic>?;
        // Clear any previous couple waiting at ante_cuerda1/2 so spots never collide
        for (final en in _gente.entries) {
          if (en.key == quien || en.key == comp) continue;
          final other = en.value as Map<String, dynamic>;
          if (other['vis'] == 1 &&
              (other['spot'] == 'ante_cuerda1' ||
                  other['spot'] == 'ante_cuerda2')) {
            other['vis'] = 0;
          }
        }
        await Future.wait([
          _walkPersonTo(quien, 'ante_cuerda1', steps: 3),
          if (cp != null) _walkPersonTo(comp, 'ante_cuerda2', steps: 3),
        ]);
        return;
      }
      await _walkPersonTo(quien, a, sent: sent, steps: 3);
    }),
    'sale': (o) => _run(o, () async {
      final quien = o['quien'] as String?;
      if (quien == null) return;
      final p = _gente[quien] as Map<String, dynamic>?;
      if (p != null) p['vis'] = 0;
      await wait(60);
    }),
    'gesto': (o) => _run(o, () async {
      final quien = (o['quien'] as String?) ?? 'mesera';
      final que = (o['que'] as String?) ?? 'saluda';
      final p = _gente[quien] as Map<String, dynamic>?;
      if (p == null) return;
      if (que == 'saluda' || que == 'pasa') {
        for (var i = 0; i < 4; i++) {
          p['pose'] = i % 2 == 0 ? 'saluda0' : 'saluda1';
          await wait(70);
        }
        p['pose'] = 'idle';
      } else if (que == 'no') {
        for (final dx in const [-1, 1, -1, 0]) {
          p['dx'] = dx;
          await wait(60);
        }
        p['dx'] = 0;
      } else if (que == 'si' || que == 'reverencia') {
        p['pose'] = que == 'reverencia' ? 'reverencia' : 'idle';
        for (final dy in const [1, 2, 1, 0]) {
          p['dy'] = dy;
          await wait(60);
        }
        p['dy'] = 0;
        p['pose'] = 'idle';
      } else {
        // rie, mira, senala, mano, lista, baston
        p['pose'] = que;
        await wait(180);
        p['pose'] = 'idle';
      }
    }),

    /* ---------- Story 84 acts ---------- */
    'mesas84': (o) => _run(o, () async {
      W['mesas84'] = _n(o['n']).clamp(1, 3);
      W['floresVis'] = 1;
      await wait(100);
    }),
    'pasa84': (o) => _run(o, () async {
      final que = (o['que'] as String?) ?? 'platos';
      await _crossMesero(que);
    }),
    'avanza84': (o) => _run(o, () async {
      final tramo = (o['tramo'] as String?) ?? 'a';
      final ok = _n(o['ok']) == 1;
      if (ok) {
        if (tramo == 'a') {
          await Future.wait([
            _hopFrogTo('ante_atril'),
            _walkPersonTo('abuela', 'atril1', steps: 3),
            _walkPersonTo('abuelo', 'atril2', steps: 3),
            _walkPersonTo('luis', 'atril3', steps: 3),
            _walkPersonTo('carmen', 'atril4', steps: 3),
          ]);
        } else {
          final mesera = _gente['mesera'] as Map<String, dynamic>?;
          if (mesera != null) mesera['pose'] = 'pasa';
          await _advancePastRope84();
          if (mesera != null) mesera['pose'] = 'idle';
        }
      } else {
        // Frog hopped forward when told to wait: bumps into mesero's tray, pair behind gets best free table
        await _hopFrogTo('ante_atril');
        await _crossMesero('bandeja');
        await _seatWaitingPair84();
        await _hopFrogTo(tramo == 'a' ? 'felpudo' : 'ante_atril');
      }
    }),
    'espera84': (o) => _run(o, () async {
      final tramo = (o['tramo'] as String?) ?? 'a';
      final ok = _n(o['ok']) == 1;
      await _hopFrogTo('banco_coqui');
      if (ok) {
        await _crossMesero('bandeja');
        final mesera = _gente['mesera'] as Map<String, dynamic>?;
        if (mesera != null) mesera['pose'] = 'pasa';
        await wait(100);
        if (mesera != null) mesera['pose'] = 'idle';
        if (tramo == 'a') {
          await Future.wait([
            _hopFrogTo('ante_atril'),
            _walkPersonTo('abuela', 'atril1', steps: 3),
            _walkPersonTo('abuelo', 'atril2', steps: 3),
            _walkPersonTo('luis', 'atril3', steps: 3),
            _walkPersonTo('carmen', 'atril4', steps: 3),
          ]);
        } else {
          await _advancePastRope84();
        }
      } else {
        // Frog sat on bench when called forward: pair behind walks past to best free table
        await _seatWaitingPair84();
      }
    }),
    'final84': (o) => _run(o, () async {
      final n = _n(o['n']).clamp(1, 3);
      W['cuerda'] = 'abierta';
      W['mesas84'] = n;
      W['final84'] = n;
      W['meseroCarry'] = null;
      (_gente['mesero'] as Map<String, dynamic>?)?['vis'] = 0;
      if (n == 3) {
        // Matches preview moment 4: family at mesa3, senor/senora at mesa2_a/b, mesera at mesera_fin
        _seat('senor', 'mesa2_a');
        _seat('senora', 'mesa2_b');
        (_gente['hombre'] as Map<String, dynamic>)['vis'] = 0;
        (_gente['mujer'] as Map<String, dynamic>)['vis'] = 0;
        _seatFamily('mesa3');
        _seat('mesera', 'mesera_fin', sent: 0);
        W['abueloSombrero'] = 0;
        await _hopFrogTo('mesa3_coqui');
      } else if (n == 2) {
        // Family at mesa2; senor/senora at mesa3_c/d (keeps mesa2_coqui clear); mesera at junto_mesa
        _seat('senor', 'mesa3_c');
        _seat('senora', 'mesa3_d');
        (_gente['hombre'] as Map<String, dynamic>)['vis'] = 0;
        (_gente['mujer'] as Map<String, dynamic>)['vis'] = 0;
        _seatFamily('mesa2');
        _seat('mesera', 'junto_mesa', sent: 0);
        W['abueloSombrero'] = 0;
        await _hopFrogTo('mesa2_coqui');
      } else {
        // Family at mesa1 (by kitchen door); hombre/mujer at mesa2_c/d (keeps mesa1_coqui clear); senor/senora at mesa3_c/d
        _seat('senor', 'mesa3_c');
        _seat('senora', 'mesa3_d');
        _seat('hombre', 'mesa2_c');
        _seat('mujer', 'mesa2_d');
        _seatFamily('mesa1');
        _seat('mesera', 'junto_mesa', sent: 0);
        W['abueloSombrero'] = 1;
        await _hopFrogTo('mesa1_coqui');
      }
      await wait(160);
    }),

    /* ---------- Story 85 acts ---------- */
    'dulces': (o) => _run(o, () async {
      W['dulces'] = _n(o['n']).clamp(0, 3);
      await wait(100);
    }),
    'manteles': (o) => _run(o, () async {
      final a = o['a'] as String?;
      final b = o['b'] as String?;
      if (a != null) W['mantel2'] = a;
      if (b != null) W['mantel3'] = b;
      await wait(120);
    }),
    'corbata85': (o) => _run(o, () async {
      W['meseroCorbata'] = 0;
      await wait(120);
      W['coquiCorbata'] = 1;
      await wait(140);
    }),
    'sienta85': (o) => _run(o, () async {
      final quienes = (o['quienes'] as String?) ?? 'senora';
      final comp = Entrada._companionOf(quienes);
      final mesa = (o['mesa'] as String?) ?? 'mesa2';
      final otherMesa = mesa == 'mesa2' ? 'mesa3' : 'mesa2';
      final ok = _n(o['ok']) == 1;
      final qP = _gente[quienes] as Map<String, dynamic>?;
      final cP = _gente[comp] as Map<String, dynamic>?;
      if (ok) {
        await Future.wait([
          if (qP != null)
            _walkPersonTo(quienes, '${mesa}_a', sent: 1, steps: 3),
          if (cP != null) _walkPersonTo(comp, '${mesa}_b', sent: 1, steps: 3),
        ]);
        final mesero = _gente['mesero'] as Map<String, dynamic>?;
        if (mesero != null) {
          mesero['dy'] = 1;
          await wait(70);
          mesero['dy'] = 0;
        }
        await _hopFrogTo('taburete_coqui');
      } else {
        // Couple sits at taken table; vellonera pair returns; couple gets up, takes sweet, sits at other table.
        await Future.wait([
          if (qP != null)
            _walkPersonTo(quienes, '${mesa}_a', sent: 1, steps: 2),
          if (cP != null) _walkPersonTo(comp, '${mesa}_b', sent: 1, steps: 2),
        ]);
        await wait(120);
        await Future.wait([
          if (qP != null)
            _walkPersonTo(quienes, '${otherMesa}_a', sent: 1, steps: 3),
          if (cP != null)
            _walkPersonTo(comp, '${otherMesa}_b', sent: 1, steps: 3),
          _walkPersonTo('vecino', '${mesa}_a', sent: 1, steps: 3),
          _walkPersonTo('vecina', '${mesa}_b', sent: 1, steps: 3),
        ]);
        await _hopFrogTo('taburete_coqui');
      }
    }),
    'vuelven85': (o) => _run(o, () async {
      final mesa = (o['mesa'] as String?) ?? 'mesa3';
      await Future.wait([
        _walkPersonTo('vecino', '${mesa}_a', sent: 1, steps: 3),
        _walkPersonTo('vecina', '${mesa}_b', sent: 1, steps: 3),
      ]);
      // In story 85 step 3, joven speaks right after vuelven85 before banco85; place joven + amigo at the rope.
      _seat('joven', 'ante_cuerda1', sent: 0);
      _seat('amigo', 'ante_cuerda2', sent: 0);
      await wait(80);
    }),
    'banco85': (o) => _run(o, () async {
      final quien = (o['quien'] as String?) ?? 'joven';
      final comp = Entrada._companionOf(quien);
      await Future.wait([
        _walkPersonTo(quien, 'banco1', sent: 1, steps: 3),
        _walkPersonTo(comp, 'banco2', sent: 1, steps: 3),
      ]);
    }),
    'tarde85': (o) => _run(o, () async {
      // Clear mesa2, mesa3, ante_cuerda1/2, and bench; restore vecino + vecina to vellonera1/2.
      for (final en in _gente.entries) {
        if (en.key == 'mesero' || en.key == 'vecino' || en.key == 'vecina') {
          continue;
        }
        (en.value as Map<String, dynamic>)['vis'] = 0;
      }
      _seat('vecino', 'vellonera1', sent: 0);
      _seat('vecina', 'vellonera2', sent: 0);
      await _hopFrogTo('taburete_coqui');
      await wait(120);
    }),
    'final85': (o) => _run(o, () async {
      final n = _n(o['n']).clamp(1, 3);
      W['dulces'] = n;
      W['final85'] = n;
      W['musicaFx'] = 1;
      // Every table is taken (distinct characters, nobody at vellonera1/2 so mesa1_a/b stay clear)
      _seat('vecino', 'mesa1_a');
      _seat('vecina', 'mesa1_b');
      _seat('hombre', 'mesa2_a');
      _seat('mujer', 'mesa2_b');
      _seat('senor', 'mesa3_a');
      _seat('senora', 'mesa3_b');
      _seat('joven', 'banco1');
      _seat('amigo', 'banco2');
      _seat('mesero', 'taburete');
      final mesero = _gente['mesero'] as Map<String, dynamic>;
      mesero['pose'] = 'mano';
      await _hopFrogTo('taburete_coqui');
      await wait(160);
      mesero['pose'] = 'idle';
    }),

    /* ---------- Story 86 acts ---------- */
    'velas': (o) => _run(o, () async {
      final prev = _n(W['velas']);
      final next = _n(o['n']).clamp(0, 3);
      W['velas'] = next;
      if (next < prev) {
        W['velaSmoke'] = 1;
        await wait(140);
        W['velaSmoke'] = 0;
      } else {
        await wait(100);
      }
    }),
    'menu86': (o) => _run(o, () async {
      final mesera = _gente['mesera'] as Map<String, dynamic>?;
      if (mesera != null) mesera['pose'] = 'mano';
      W['menuVis'] = 1;
      await wait(100);
      W['menuOpen'] = 1;
      if (mesera != null) mesera['pose'] = 'idle';
      await wait(120);
    }),
    'bandeja86': (o) => _run(o, () async {
      W['trayVis'] = 1;
      W['trayQue'] = (o['que'] as String?) ?? 'agua';
      W['trayIzq'] = (o['izq'] as String?) ?? 'con';
      W['cosaAVis'] = 1;
      W['cosaBVis'] = 1;
      await wait(120);
    }),
    'da86': (o) => _run(o, () async {
      final cual = (o['cual'] as String?) ?? 'cosa_a';
      final a = (o['a'] as String?) ?? 'luis';
      final ok = _n(o['ok']) == 1;
      final q = W['cq'] as Map<String, dynamic>;
      final target = _gente[a] as Map<String, dynamic>?;
      q['dy'] = -3;
      await wait(70);
      q['dy'] = 0;
      if (ok) {
        if (cual == 'cosa_a') {
          W['cosaAVis'] = 0;
        } else {
          W['cosaBVis'] = 0;
        }
        if (target != null) {
          target['dy'] = 1;
          await wait(80);
          target['dy'] = 0;
        }
        if (_n(W['cosaAVis']) == 0 && _n(W['cosaBVis']) == 0) {
          W['trayVis'] = 0;
        }
      } else {
        // Recipient shakes head; mesero snatches back with transient splash; both items remain on tray for retry.
        if (target != null) {
          for (final dx in const [-1, 1, -1, 0]) {
            target['dx'] = dx;
            await wait(60);
          }
          target['dx'] = 0;
        }
        W['splashFx'] = 1;
        await wait(160);
        W['splashFx'] = 0;
      }
    }),
    'cafes86': (o) => _run(o, () async {
      W['cafesVis'] = 1;
      await wait(160);
    }),
    'vasito86': (o) => _run(o, () async {
      W['vasitoVis'] = 1;
      await wait(160);
    }),
    'final86': (o) => _run(o, () async {
      final n = _n(o['n']).clamp(1, 3);
      W['velas'] = n;
      W['final86'] = n;
      W['trayVis'] = 0;
      W['cosaAVis'] = 0;
      W['cosaBVis'] = 0;
      W['splashFx'] = 0;
      W['velaSmoke'] = 0;
      W['paneraVis'] = 1;
      W['menuCloseToFlame'] = n == 1 ? 1 : 0;
      await _hopFrogTo('mesa2_coqui');
      await wait(180);
    }),

    /* ---------- Shared card & ending ---------- */
    'marca': (o) async {
      final m = W['marcas'];
      if (m is List) {
        final i = m.indexOf(null);
        if (i >= 0) m[i] = o['que'];
      }
      await wait(120);
    },
    'fin': (o) async {
      final q = W['cq'] as Map<String, dynamic>;
      for (final dy in const [-4, -6, -3, 0]) {
        q['dy'] = dy;
        await wait(50);
      }
      await wait(200);
    },
  };
}
