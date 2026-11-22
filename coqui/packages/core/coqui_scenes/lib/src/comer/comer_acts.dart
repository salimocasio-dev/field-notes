// comer.js:796 to :1230, the acts, line for line: the shared ones (marca, ya, g, nota), story 33 (¿Qué quieres?: the
// rolls), story 34 (Buen provecho: the rice, comer_acts34.dart) and story 35 (Café con azúcar: the coffee,
// comer_acts35.dart). Each place the sheet's rule keeps on a line is checked to be one the sheet names there ([_at]);
// the moved lines' own places are the moved source's (comer.dart: ComerPlaces.movesAre).
// ignore_for_file: non_constant_identifier_names, constant_identifier_names
part of 'comer.dart';

extension _Acts on Comer {
  // a place of comer.js's line [line] that the sheet's rule keeps (comer_places.dart: at)
  num _at(int line, num v) => _p.at(line, v);

  Future<void> _act(String k, M o) => acts[k]!(o);

  // a future the act starts and waits for later: a play left meanwhile ends it in "stop", which the wait gets
  Future<T> _later<T>(Future<T> f) {
    f.ignore();
    return f;
  }

  // comer.js: acts
  Map<String, Act> _comerActs() => {
    'marca': (o) async {
      marca(o['que']);
      SFX.blip();
      await wait(250);
    },
    'ya': (o) async {
      final p = W['_mov'];
      W['_mov'] = null;
      if (p is Future) await p;
    },
    'g': (o) async {
      final p = G(o['quien']);
      if (p == null) return;
      for (final k in o.keys) {
        if (!const ['act', 'quien', 'ms'].contains(k)) {
          p[k] = o[k] == '' ? null : o[k];
        }
      }
      if (jsTruthy(o['ms'])) await wait(_plus(o['ms']));
    },
    'nota': (o) async {
      V['${o['k']}'] = o['v'] == null ? '1' : _js(o['v']);
    },
    ..._acts33(),
    ..._acts34(),
    ..._acts35(),
    // everything at once, to look at the drawing
    'prueba': (o) async {
      W['gente'] = <String, dynamic>{};
      W['cosas'] = <dynamic>[];
    },
  };

  /* ----- story 33: ¿Qué quieres? ----- */

  // The five rolls come split in the basket (cut open, empty), steaming; the second tray waits on the stove. Whoever asks
  // walks in to the left end of the table, takes a roll from the basket with his hand and holds it up (a beat at rest);
  // he gives it into the frog's hand (both hands on it for a moment) and walks out to wash his hands; the frog fills the
  // roll with the spoon and closes it; the asker walks in again, takes the roll from the frog's hand and eats it at his
  // place, in three bites.
  Map<String, Act> _acts33() => {
    // moves line 807: the plates at the seats on the row there (SY); line 812: the tray on the stove's top
    'inicio33': (o) async {
      W['gente'] = <String, dynamic>{
        'abuela': <String, dynamic>{
          'x': FOGON[0],
          'y': FOGON[1],
          'dir': -1,
          'tiene': <dynamic>[],
        },
        for (final id in const ['abuelo', 'mama', 'papa', 'luis', 'carmen'])
          id: <String, dynamic>{'vis': 0, 'tiene': <dynamic>[]},
      };
      W['sitio'] = <String, dynamic>{};
      M pl(String id, num x) => {
        'id': id,
        'k': 'plato',
        'x': x,
        'y': SY(x, FILA),
        'rollos': <dynamic>[],
      };
      W['cosas'] = <dynamic>[
        <String, dynamic>{
          'id': 'pl_abuela',
          'k': 'plato',
          'x': PA33S[0],
          'y': PA33S[1],
          'rollos': <dynamic>[],
        },
        pl('pl_abuelo', SILLA[Comer.SEAT33['abuelo']!]),
        pl('pl_mama', SILLA[Comer.SEAT33['mama']!]),
        pl('pl_papa', SILLA[Comer.SEAT33['papa']!]),
        <String, dynamic>{
          'id': 'pl_luis',
          'k': 'platoc',
          'x': EST33['luis']!.pl[0],
          'y': EST33['luis']!.pl[1],
          'rollos': <dynamic>[],
        },
        <String, dynamic>{
          'id': 'pl_carmen',
          'k': 'platoc',
          'x': EST33['carmen']!.pl[0],
          'y': EST33['carmen']!.pl[1],
          'rollos': <dynamic>[],
        },
        <String, dynamic>{
          'id': 'cesta',
          'k': 'cesta',
          'v': '5:0',
          'x': CE33[0],
          'y': CE33[1],
          'vapor': 1,
          'vdx': 2,
          'vdy': 18,
          'vn': 2,
        },
        <String, dynamic>{
          'id': 'mant',
          'k': 'mantequilla',
          'v': '5',
          'x': BU33[0],
          'y': BU33[1],
        },
        <String, dynamic>{
          'id': 'choc',
          'k': 'choc',
          'v': '5',
          'x': CH33[0],
          'y': CH33[1],
        },
        <String, dynamic>{
          'id': 'bandeja',
          'k': 'bandeja',
          'v': 4,
          'x': BANDEJA[0],
          'y': BANDEJA[1],
          'vapor': 1,
          'vdx': 0,
          'vdy': 12,
          'vn': 2,
        },
      ];
      _cq.addAll({
        'x': REST33[0] - 16,
        'y': REST33[1] - 27,
        's': 1,
        'sobre': 1,
        'dy': 0,
        'vis': 1,
        'tiene': <dynamic>[CUCH(0)],
        'lleno': 0,
        'espalda': 0,
        'piensa': null,
      });
    },
    // abuela walks from the stove along the floor in front of the table, to stand in front of her plate; with one hand on
    // its rim she slides it a little towards the basket, a step at a time; she lets go and walks out to the yard (moves
    // line 816: in front of the table's foot)
    'plato33': (o) async {
      final ab = G('abuela')!, pl = ob('pl_abuela')!;
      final pr = () async {
        await ruta('abuela', [
          [FOGON[0], FR],
          [PA33S[0] - 2, FR],
          [PA33S[0] - 2, 192],
        ]);
        ab['dir'] = -1;
        await wait(TICK * 2);
        final hb = <String, dynamic>{
          'k': 'brazo',
          '_m': 1,
          'gx': 0,
          'gy': 0,
          'sh': 1,
        };
        (ab['tiene'] as List).add(hb);
        List<num> hand() => [
          ((pl['x'] as num) - (ab['x'] as num)) * -1,
          (ab['y'] as num) - ((pl['y'] as num) - 1),
        ];
        final h0 = restHand('abuela'), h1 = hand();
        hb['gx'] = h0[0];
        hb['gy'] = h0[1];
        for (var i = 1; i <= 3; i++) {
          hb['gx'] = h0[0] + (h1[0] - h0[0]) * i / 3;
          hb['gy'] = h0[1] + (h1[1] - h0[1]) * i / 3;
          await wait(TICK);
        }
        await wait(TICK * 2);
        const n = 4;
        final x0 = pl['x'] as num, ax0 = ab['x'] as num;
        SFX.blip();
        for (var i = 1; i <= n; i++) {
          pl['x'] = x0 + (PA33[0] - x0) * i / n;
          ab['x'] = ax0 + (PA33[0] - 2 - ax0) * i / n;
          final h = hand();
          hb['gx'] = h[0];
          hb['gy'] = h[1];
          await wait(TICK * 2);
        }
        await wait(TICK * 2);
        final rr = restHand('abuela');
        await manoA('abuela', rr[0], rr[1], 3, 1);
        sinManos('abuela');
        await wait(TICK * 3);
        await sale('abuela');
      }();
      return corre(o, pr);
    },
    // a person walks in to the left end of the table (on the floor, to the left of it); his hand takes a roll from the
    // basket and he holds it up, cut open and empty, for a moment (the frog sees it)
    'viene33': (o) async {
      final id = '${o['a']}', p = G(id)!, ce = ob('cesta')!, lp = LEP(id);
      if (p['vis'] != 0 && jsTruthy(p['sent'])) {
        await levanta(id, lp[0], lp[1]);
      } else if (p['vis'] != 0 && EST33[id] != null) {
        await desdeEstacion(id);
      } else {
        await entra(id, lp[0], lp[1], 1);
      }
      p['dir'] = 1;
      p['pose'] = 'idle';
      if (_on(o['rollo'])) {
        // his hand takes a roll out of the basket
        final w = [(ce['x'] as num) - 9, (ce['y'] as num) - 5],
            r0 = rel(id, w[0], w[1]);
        await manoA(id, r0[0], r0[1], 3);
        quitaCesta();
        SFX.blip();
        final it = <String, dynamic>{'k': 'rollo', 'v': 'ab', 'e': 1},
            c = centroPara(id, it, w[0], w[1]);
        it['dx'] = c[0];
        it['dy'] = c[1];
        sinManos(id);
        (p['tiene'] as List).add(it);
        await wait(TICK * 2);
        // held up beside his face, the open side towards us, for a moment at rest
        await mueveTiene(id, it, 15, Comer.NINO(id) ? 29 : 36, 4);
        await wait(TICK * 14);
      }
    },
    // he gives the roll into the frog's hand (both hands on it for a moment), and walks out to wash his hands
    'sale33': (o) async {
      final id = '${o['a']}', p = G(id)!;
      if (_on(o['fin'])) return;
      final it = _find(p['tiene'], (t) => t['k'] == 'rollo');
      if (it != null) {
        await rolloAFrog(id, it);
        await wait(TICK * 3);
      }
      await sale(id);
    },
    // the frog fills the roll in his left hand with his spoon (in his right): if he has none he goes to the right of the
    // basket and takes one out of it; he goes to the dish, dips the spoon (the dish has less) and tips it into the roll
    // and closes it
    'rellena33': (o) async {
      final k = _js(o['k']),
          dish = ob(k == 'choc' ? 'choc' : 'mant')!,
          ce = ob('cesta')!,
          q = _cq;
      q['piensa'] = null;
      final sp = _find(q['tiene'], (t) => t['k'] == 'uten')!;
      var fit = _find(q['tiene'], (t) => t['k'] == 'rollo');
      if (fit == null) {
        await ranaA(FETCH33[0], FETCH33[1]);
        final ro = <String, dynamic>{
          'k': 'rollo',
          'v': 'ab',
          'x': (ce['x'] as num) + 10,
          'y': (ce['y'] as num) - 5,
          'vis': 1,
        };
        fit = await ranaToma(ro, -17, 17, {'n': 3, 'm': 3, 'flip': true});
        quitaCesta();
        await wait(TICK * 2);
      }
      // the spoon into the dish (he stands to the left of it, the spoon in his right hand), up full
      await ranaA((dish['x'] as num) - 20, (dish['y'] as num) - 2);
      sp['load'] = '';
      SFX.blip();
      final bx = (dish['x'] as num) - cx(),
          by = pies() - ((dish['y'] as num) - 7),
          bx0 = sp['bx'] as num,
          by0 = sp['by'] as num;
      for (var i = 1; i <= 3; i++) {
        sp['bx'] = bx0 + (bx - bx0) * i / 3;
        sp['by'] = by0 + (by - by0) * i / 3;
        await wait(TICK);
      }
      await wait(TICK * 3);
      sp['load'] = k == 'choc' ? 'c' : 'm';
      dish['v'] = jsNum(math.max(1, _plus(dish['v']) - 1));
      SFX.blip();
      await wait(TICK * 4);
      // the roll is held in front of him, the spoon comes over it, tips it in; he closes the roll
      await ranaMueve(fit, -9, 16, 3);
      await cucharaAR(sp, cx() - 9, pies() - 27, false, 4);
      await wait(TICK * 3);
      sp['load'] = '';
      fit['v'] = 'ab:${k == 'choc' ? 'c' : 'm'}';
      SFX.blip();
      await wait(TICK * 6);
      fit['v'] = 'ce:${k == 'choc' ? 'c' : 'm'}';
      SFX.blip();
      await wait(TICK * 5);
      sp.addAll(CUCH(0));
      sp['load'] = '';
      await ranaMueve(fit, -17, 17, 3);
      await ranaA(HOME33[0], HOME33[1]);
    },
    // he walks in again; the frog holds the filled roll out and the asker's hand takes it from his; he goes to his chair
    // (the children to their place at the table, where they set it on their plate)
    'regresa33': (o) async {
      final id = '${o['a']}',
          p = G(id)!,
          nino = Comer.NINO(id),
          lp = LEP(id),
          seat = Comer.SEAT33[id];
      // after a miss he is still at his place with the bitten roll: he walks round to the new one
      if (p['vis'] != 0 && jsTruthy(p['sent'])) {
        await levanta(id, lp[0], lp[1]);
      } else if (p['vis'] != 0 && EST33[id] != null) {
        await desdeEstacion(id);
      } else {
        await entra(id, lp[0], lp[1], 1);
      }
      p['dir'] = 1;
      p['pose'] = 'idle';
      final it = await rolloDelFrog(
        id,
        _find(_cq['tiene'], (t) => t['k'] == 'rollo')!,
      );
      await mueveTiene(id, it, 13, nino ? 20 : 24, 4);
      if (!nino) {
        await sienta(id, seat!);
        final i2 = _find(p['tiene'], (t) => t['k'] == 'rollo');
        if (i2 != null) {
          i2['dx'] = 8;
          i2['dy'] = 22;
        }
      } else {
        await vaEstacion(id);
        final i2 = _find(p['tiene'], (t) => t['k'] == 'rollo')!;
        await ponPlato(id, i2, ob('pl_$id')!);
        await wait(TICK * 3);
      }
    },
    // he eats the roll in three bites: right, he chews happily and eats it all; wrong, he bites once, makes a face, puts it
    // down on his plate with the bite out of it and pushes the plate a little away: there it stays
    'come33': (o) async {
      final id = '${o['a']}',
          p = G(id)!,
          nino = Comer.NINO(id),
          pl = ob('pl_$id')!;
      final pr = () async {
        var it = _find(p['tiene'], (t) => t['k'] == 'rollo');
        if (it == null && nino) it = await tomaPlato(id, pl);
        if (it == null) return;
        final parts = _js(it['v']).split(':'),
            con = parts.length > 1 ? parts[1] : null,
            d = _d(p);
        it['flip'] = d < 0;
        Future<void> chew(int n) async {
          for (var i = 0; i < n; i++) {
            p['boca'] = 1;
            await wait(TICK * 3);
            p['boca'] = 0;
            await wait(TICK * 3);
          }
        }

        final dxB = jsTruthy(p['sent'])
            ? 8
            : nino
            ? 10
            : 12;
        Future<void> alBoca() async {
          await mueveTiene(id, it!, dxB, bocaY(id, p) - 2, 3);
          await wait(TICK * 2);
        }

        Future<void> baja() async {
          await mueveTiene(
            id,
            it!,
            jsTruthy(p['sent']) ? 8 : 13,
            jsTruthy(p['sent'])
                ? 22
                : nino
                ? 20
                : 24,
            3,
          );
          await wait(TICK * 3);
        }

        await alBoca();
        it['v'] = 'mo:${_js(con)}';
        SFX.blip();
        if (_on(o['bien'])) {
          // the second bite and the last
          await chew(2);
          await baja();
          await alBoca();
          it['v'] = 'm2:${_js(con)}';
          SFX.blip();
          await chew(2);
          await baja();
          await alBoca();
          _quita(p, it);
          SFX.blip();
          final rr = restHand(id);
          await manoA(id, rr[0], rr[1], 3);
          sinManos(id);
          await chew(3);
          pl['v'] = 'mi';
          await wait(TICK * 2);
          return;
        }
        p['cara'] = 'mal';
        SFX.bonk();
        p['dy'] = -2;
        await wait(TICK * 3);
        p['dy'] = 0;
        await wait(TICK * 10);
        // the roll down on his plate with the bite out of it; he pushes the plate a little away with his hand, and the
        // roll stays
        await mueveTiene(
          id,
          it,
          ((pl['x'] as num) - (p['x'] as num)) * d,
          (p['y'] as num) - ((pl['y'] as num) - 7),
          5,
        );
        ROLLOS(pl)
            .add(<String, dynamic>{'st': 'mo', 'con': con, 'dx': 0, 'mal': 1});
        SFX.blip();
        _quita(p, it);
        final r0 = rel(id, pl['x'] as num, (pl['y'] as num) - 6),
            hb = <String, dynamic>{
              'k': 'brazo',
              '_m': 9,
              'gx': r0[0],
              'gy': r0[1],
              'sh': 1,
            };
        (p['tiene'] as List).add(hb);
        await wait(TICK * 2);
        for (var i = 0; i < 2; i++) {
          pl['y'] = (pl['y'] as num) + 2;
          hb['gy'] = (p['y'] as num) - ((pl['y'] as num) - 6);
          hb['gx'] = ((pl['x'] as num) - (p['x'] as num)) * d;
          await wait(TICK * 2);
        }
        await wait(TICK);
        final rr = restHand(id);
        await manoA(id, rr[0], rr[1], 3);
        sinManos(id);
        p['cara'] = null;
        await wait(TICK * 3);
      }();
      return corre(o, pr);
    },
    // the turn: the frog steps aside (moves line 869: to the right of the basket); abuela walks in from the yard along the
    // floor below the table to the stove (moves line 870: round the table's right end, behind it), takes the tray in both
    // hands, carries it back along the same way (moves line 872), stands at the left end of the table and tips the tray
    // towards the basket: the four hot rolls slide off its low edge into it, one after the other
    'turno33': (o) async {
      final ab = G('abuela')!, ce = ob('cesta')!, tr = ob('bandeja')!;
      ab['tiene'] = <dynamic>[];
      ab['pose'] = 'idle';
      ab['vis'] = 1;
      ab['x'] = PUERTA[0];
      ab['y'] = 190;
      ab['dir'] = 1;
      final aparte = _later(ranaA(124, 162));
      await ruta('abuela', [
        [46, FR],
        [XP, FR],
        [XP, SY(XP, ATRAS)],
        [AFOGON[0], AFOGON[1]],
      ]);
      ab['dir'] = -1;
      await wait(TICK * 2);
      await aparte;
      final t0 = await toma('abuela', tr, 0, 20, {
        'n': 3,
        'vapor': 0,
        'm': 3,
        'extra': <String, dynamic>{'dos': 10},
      });
      t0['vapor'] = 0;
      await ruta('abuela', [
        [XP, SY(XP, ATRAS)],
        [XP, FR],
        [54, FR],
        [56, 178],
      ]);
      ab['dir'] = 1;
      await mueveTiene('abuela', t0, 11, 28, 3);
      await wait(TICK * 3);
      // she tips the tray towards the basket, and the rolls slide off its low edge into the basket, one after the other
      final n0 = _plus(t0['v']);
      t0['ang'] = .28;
      await wait(TICK * 3);
      List<num> base() => [
        _round(ab['x'] as num) + (t0['dx'] as num),
        _round(ab['y'] as num) - (t0['dy'] as num),
      ];
      for (var i = 0; i < n0; i++) {
        final b = base();
        t0['v'] = jsNum(n0 - 1 - i);
        await vuela(
          <String, dynamic>{'k': 'rollo', 'v': 'ab'},
          b[0] + 11 - i * 2,
          b[1] + 3,
          (ce['x'] as num) - 4 + i * 6,
          (ce['y'] as num) - 10,
          4,
          0,
        );
        ce['v'] = '${i + 1}:0';
        SFX.blip();
        await wait(TICK * 2);
      }
      t0['ang'] = 0;
      await wait(TICK * 3);
    },
    'apunta33': (o) async {
      final ab = G('abuela')!,
          t0 = _find(ab['tiene'], (t) => t['k'] == 'bandeja');
      if (t0 != null) {
        t0['dos'] = 0;
        t0['una'] = 1;
        await mueveTiene('abuela', t0, -6, 20, 3);
      }
      ab['dir'] = 1;
      ab['pose'] = 'offer';
      SFX.blip();
      await wait(TICK * 12);
      ab['pose'] = 'idle';
    },
    'sale33a': (o) async {
      final ab = G('abuela')!;
      final t0 = _find(ab['tiene'], (t) => t['k'] == 'bandeja');
      if (t0 != null) {
        t0['una'] = 0;
        t0['dos'] = 10;
        await mueveTiene('abuela', t0, 0, 20, 3);
      }
      await sale('abuela');
      ab['tiene'] = <dynamic>[];
    },
    // papá and Carmen come in for the first time, stop at the left end, look at the full basket (a hand towards it), and
    // go out again
    'miran33': (o) async {
      final pa = G('papa')!, ca = G('carmen')!;
      pa['vis'] = ca['vis'] = 0;
      pa['tiene'] = <dynamic>[];
      ca['tiene'] = <dynamic>[];
      await Future.wait<void>([
        entra('papa', _at(881, 54), _at(881, 184), 1),
        () async {
          await wait(TICK * 6);
          await entra('carmen', _at(881, 40), _at(881, 174), 1);
        }(),
      ]);
      pa['pose'] = 'offer';
      ca['pose'] = 'tu';
      SFX.blip();
      await wait(TICK * 4);
      pa['dy'] = -2;
      await wait(TICK * 3);
      pa['dy'] = 0;
      await wait(TICK * 8);
      ca['dy'] = -2;
      await wait(TICK * 3);
      ca['dy'] = 0;
      await wait(TICK * 4);
      pa['pose'] = 'idle';
      ca['pose'] = 'idle';
      await Future.wait<void>([
        sale('papa'),
        () async {
          await wait(TICK * 4);
          await sale('carmen');
        }(),
      ]);
    },
    // the ending: the grown-ups who are not at the table walk in and sit, the children walk to their corners; abuela walks
    // in to the left end of the table (moves line 890), takes a roll from the basket; if a second roll is left she takes
    // the towel from the rim of the basket, holds it over that roll and lays it over it, in view; she walks round along
    // the front with the roll in her hand to her plate (moves line 902), lays the roll on it, takes the plate in both
    // hands and carries it round the end of the table and along the lane to her chair (moves line 904), sets it down at
    // her place and sits; she eats the roll plain, in three bites, at her place
    'final33': (o) async {
      final ce = ob('cesta')!, ab = G('abuela')!, n = nCesta();
      ab['tiene'] = <dynamic>[];
      final kids = [
        for (final id in const ['luis', 'carmen'])
          if (!enEstacion(id)) id,
      ];
      final mayores = [
        for (final id in const ['abuelo', 'mama', 'papa'])
          if (!(G(id)!['vis'] != 0 && jsTruthy(G(id)!['sent']))) id,
      ];
      await Future.wait<void>([
        for (final (i, id) in mayores.indexed)
          () async {
            await wait(TICK * i * 6);
            await sienta(id, Comer.SEAT33[id]!);
          }(),
      ]);
      final kp = _later(
        Future.wait<void>([
          for (final (i, id) in kids.indexed)
            () async {
              await wait(TICK * i * 10);
              await vaEstacion(id);
            }(),
        ]),
      );
      const lp = [66, 176];
      await entra('abuela', lp[0], lp[1], 1);
      ab['dir'] = 1;
      V['pan'] = n > 0 ? '1' : '';
      M? it;
      if (n > 0) {
        final w = [(ce['x'] as num) - 9, (ce['y'] as num) - 5],
            r0 = rel('abuela', w[0], w[1]);
        await manoA('abuela', r0[0], r0[1], 3, 1);
        quitaCesta();
        SFX.blip();
        it = <String, dynamic>{'k': 'rollo', 'v': 'ce', 'e': 1, 'sh': 1};
        final c = centroPara('abuela', it, w[0], w[1]);
        it['dx'] = c[0];
        it['dy'] = c[1];
        sinManos('abuela');
        (ab['tiene'] as List).add(it);
        await wait(TICK * 2);
        // the roll comes to her belly and goes into her other hand
        await mueveTiene('abuela', it, -3, 24, 3);
        await wait(TICK * 2);
        it['sh'] = -1;
        await wait(TICK * 2);
      }
      if (n > 1) {
        // the towel: she takes it off the rim, holds it over the roll that is left and lays it over it
        final tw = [(ce['x'] as num) - 13, (ce['y'] as num) - 11],
            r0 = rel('abuela', tw[0], tw[1]);
        await manoA('abuela', r0[0], r0[1], 3, 1);
        ce['v'] = '1:4';
        SFX.blip();
        sinManos('abuela');
        final pn = <String, dynamic>{
          'k': 'pano',
          'e': 1,
          'dx': r0[0],
          'dy': r0[1],
          'sh': 1,
        };
        (ab['tiene'] as List).add(pn);
        await wait(TICK * 3);
        final ov = rel('abuela', (ce['x'] as num) - 7, (ce['y'] as num) - 15);
        await mueveTiene('abuela', pn, ov[0], ov[1], 3);
        await wait(TICK * 3);
        _quita(ab, pn);
        ce['v'] = '1:1';
        ce['vapor'] = 0;
        SFX.blip();
        final hb2 = <String, dynamic>{
          'k': 'brazo',
          '_m': 1,
          'gx': ov[0],
          'gy': ov[1],
          'sh': 1,
        };
        (ab['tiene'] as List).add(hb2);
        await wait(TICK * 3);
        final rr = restHand('abuela');
        await manoA('abuela', rr[0], rr[1], 3, 1);
        sinManos('abuela');
      } else {
        ce['vapor'] = 0;
      }
      final pa = ob('pl_abuela')!;
      if (it != null) {
        // the roll goes onto her own plate (she stands in front of it, within reach), she takes the plate in her hands and
        // carries it, with the roll on it, to her chair
        await ruta('abuela', [
          [54, FR],
          [PA33[0] - 2, FR],
          [PA33[0] - 2, 187],
        ]);
        ab['dir'] = 1;
        await ponPlato('abuela', it, pa);
        await wait(TICK * 3);
        final pit = await toma('abuela', pa, null, null, {
          'n': 3,
          'extra': <String, dynamic>{'rollos': pa['rollos'], 'dos': 7},
        });
        await mueveTiene('abuela', pit, 0, 18, 3);
        await ruta('abuela', [
          [PA33[0], FR],
        ]);
        final sx = SILLA[Comer.SEAT33['abuela']!] - 11;
        await detras('abuela', sx, SY(sx, ASIENTO));
        ab['dir'] = 1;
        ab['est'] = 1;
        await pon('abuela', pit, pa, PA0[0], PA0[1], 4);
        await wait(TICK * 2);
      } else {
        await ruta('abuela', [
          [_at(905, 54), FR],
        ]);
      }
      await sienta('abuela', Comer.SEAT33['abuela']!);
      await kp;
      if (it != null) {
        final r2 = await tomaPlato('abuela', pa);
        if (r2 != null) {
          ab['dir'] = 1;
          r2['flip'] = false;
          await mueveTiene('abuela', r2, 8, bocaY('abuela', ab) - 1, 3);
          await wait(TICK * 2);
          for (var i = 0; i < 3; i++) {
            r2['v'] = i == 0 ? 'mo' : 'm2';
            SFX.blip();
            for (var j = 0; j < 2; j++) {
              ab['boca'] = 1;
              await wait(TICK * 3);
              ab['boca'] = 0;
              await wait(TICK * 3);
            }
            if (i < 2) {
              await mueveTiene('abuela', r2, 8, 22, 3);
              await wait(TICK * 3);
              await mueveTiene('abuela', r2, 8, bocaY('abuela', ab) - 1, 3);
              await wait(TICK * 2);
            }
          }
          _quita(ab, r2);
          pa['v'] = 'mi';
          final rr = restHand('abuela');
          await manoA('abuela', rr[0], rr[1], 2);
          sinManos('abuela');
        }
      }
      _cq['hace'] = n > 0 ? 'come' : null;
      await wait(TICK * 8);
    },
  };
}
