// comer.js:912 to :1055, story 34 (Buen provecho), line for line. Lunch: yellow rice. Mamá, Carmen and abuelo sit, a fork
// in each hand; papá's chair and plate are empty; the baby sits in his high chair on the floor at the right end; Luis
// stands in front of the table by the pot of rice, his plate and the frog's small plate; abuela is at the stove with the
// big spoon. The platter waits on the stove top, empty, with papá's fork: abuela carries it to the table at the turn.
// ignore_for_file: non_constant_identifier_names, constant_identifier_names
part of 'comer.dart';

extension _Acts34 on Comer {
  Map<String, Act> _acts34() => {
    // moves line 916: the seated on their seats' row (SY); line 917: the plates at the seats on the row there
    'inicio34': (o) async {
      M tf() => TENE('tenedor', 7, 12, {'e': 1});
      W['gente'] = <String, dynamic>{
        for (final (k, i) in const [('mama', 0), ('carmen', 1), ('abuelo', 2)])
          k: <String, dynamic>{
            'x': SILLA[i],
            'y': SY(SILLA[i], ASIENTO),
            'sent': 1,
            'dir': 1,
            'tiene': <dynamic>[tf()],
          },
        'papa': <String, dynamic>{'vis': 0, 'tiene': <dynamic>[]},
        'luis': <String, dynamic>{
          'x': LUIS34[0],
          'y': LUIS34[1],
          'dir': 1,
          'tiene': <dynamic>[
            TENE('tenedor', -9, 19, {'e': 1}),
          ],
        },
        'abuela': <String, dynamic>{
          'x': FOGON[0],
          'y': FOGON[1],
          'dir': -1,
          'tiene': <dynamic>[
            bigSpoon({'ax': 9, 'ay': 23, 'bx': 15, 'by': 32}),
          ],
        },
      };
      W['sitio'] = <String, dynamic>{...Comer.SEAT34};
      W['turno'] = 0;
      W['nO'] = 0;
      M pl(String id, num x, [String? v]) => {
        'id': id,
        'k': 'plato',
        'x': x,
        'y': SY(x, FILA),
        'v': v ?? '',
        'rollos': <dynamic>[],
      };
      W['cosas'] = <dynamic>[
        pl('pl_mama', SILLA[0], 'r'),
        pl('pl_carmen', SILLA[1], 'r'),
        pl('pl_papa', SILLA[3]),
        pl('pl_abuelo', SILLA[2], 'r'),
        <String, dynamic>{
          'id': 'pl_luis',
          'k': 'plato',
          'x': PLUIS[0],
          'y': PLUIS[1],
          'v': 'r',
          'rollos': <dynamic>[],
        },
        <String, dynamic>{
          'id': 'pl_rana',
          'k': 'platito',
          'x': PRANA[0],
          'y': PRANA[1],
        },
        <String, dynamic>{
          'id': 'tf_rana',
          'k': 'tenedorH',
          'x': PRANA[0] + 12,
          'y': PRANA[1] - 1,
        },
        <String, dynamic>{
          'id': 'olla',
          'k': 'olla',
          'v': 'lleno0',
          'x': OLLA[0],
          'y': OLLA[1],
          'vapor': 1,
        },
        <String, dynamic>{
          'id': 'silla_bebe',
          'k': 'sillaBebe',
          'v': '1',
          'x': HIJA[0],
          'y': HIJA[1],
        },
        <String, dynamic>{
          'id': 'fuente',
          'k': 'fuente',
          'v': 'c',
          'x': PLAT34[0],
          'y': PLAT34[1],
          'montones': <dynamic>[],
          'tenedor': <String, dynamic>{'dx': -4, 'dy': 3},
        },
      ];
      _cq.addAll({
        'x': CASA34[0] - 16,
        'y': CASA34[1] - 27,
        's': 1,
        'sobre': 1,
        'dy': 0,
        'vis': 1,
        'tiene': <dynamic>[],
        'lleno': 0,
        'espalda': 0,
        'piensa': null,
        'nube': [...NUBE34['barriga']!],
        'nubeAim': [...AIM34],
        'ndir': -1,
      });
    },
    // everybody lifts the fork he holds and waits
    'tenedores34': (o) async {
      await Future.wait<void>([
        for (final id in const ['mama', 'carmen', 'abuelo', 'luis'])
          () async {
            final p = G(id)!, f = tenedorDe(id);
            if (f != null) await mueveTiene(id, f, 12, bocaY(id, p) + 8, 4);
          }(),
      ]);
      SFX.blip();
      await wait(TICK * 10);
    },
    // they eat: two forkfuls each (the rice on the plate goes down), then the fork lies by the plate
    'come34': (o) async {
      final pr = () async {
        await Future.wait<void>([
          for (final (i, id) in const ['mama', 'carmen', 'abuelo'].indexed)
            () async {
              await wait(TICK * i * 3);
              await forkfuls(id, ob('pl_$id')!, const ['r2', 'r1']);
              await dejaTenedor(id);
            }(),
        ]);
      }();
      return corre(o, pr);
    },
    // Luis eats his last forkfuls: three, and his plate is clean
    'luisCome34': (o) async {
      final pr = () async {
        await forkfuls('luis', ob('pl_luis')!, const ['r2', 'r1', '']);
      }();
      return corre(o, pr);
    },
    // Luis walks along the front to abuela, who stands at the stove with the big spoon in her hand; she steps out to meet
    // him, holds it out, he takes it (both hands on it for a moment) and walks back to his place with it in his hand
    'cuchara34': (o) async {
      final ab = G('abuela')!;
      await aEncuentro34();
      await mueve('abuela', FOGON[0] - 2, _at(930, 176));
      ab['dir'] = -1;
      final sp = spoonOf('abuela')!;
      await cucharaA(
        'abuela',
        sp,
        (ab['x'] as num) - 17,
        (ab['y'] as num) - 22,
        4,
      );
      await wait(TICK * 3);
      final sp2 = (await pasaCuchara('abuela', 'luis'))!;
      final lr = luisRest();
      await cucharaA('luis', sp2, lr[0], lr[1], 5);
      await wait(TICK * 2);
      await mueve('abuela', FOGON[0], FOGON[1]);
      ab['dir'] = -1;
      await deEncuentro34();
    },
    // Luis: sirve (he serves himself one mound onto his plate), come (he eats it with his fork, two forkfuls), cuchara (he
    // lifts a mound onto the big spoon and holds it out to the frog: tiende), entrega (he hands the frog the spoon with the
    // mound on it); de "p": the mound comes from papá's three. The one big spoon is always in somebody's hand
    'luis34': (o) async {
      final pl = ob('pl_luis')!;
      final pr = () async {
        final sp = spoonOf('luis');
        final g = o['de'] == 'p' ? 'p' : 'm';
        Future<void> toma() async {
          var s = fuenteMonton(g);
          if (s != null && (s.fu['x'] as num) > 200) s = null;
          if (g == 'p' && s == null) s = fuenteMonton('m');
          final src = origen();
          final pt = s != null ? (x: s.x, y: s.y) : (x: src.x, y: src.y);
          await cucharaA('luis', sp!, pt.x, pt.y + 3, 6);
          await wait(TICK * 2);
          sp['load'] = 'monton';
          if (s != null) {
            (s.fu['montones'] as List).remove(s.m);
          } else {
            final ol = ob('olla');
            W['nO'] = _n(W['nO']) + 1;
            if (ol != null && ol['vis'] != 0) {
              ol['v'] = nivelOlla(W['nO'] as num);
            }
          }
          SFX.blip();
          await wait(TICK * 4);
        }

        Future<void> reposo([num? n]) async {
          final r = luisRest();
          await cucharaA('luis', sp!, r[0], r[1], n != null && n != 0 ? n : 5);
        }

        if (o['que'] == 'sirve') {
          await toma();
          await cucharaA('luis', sp!, PLUIS[0], PLUIS[1] - 6, 6);
          await wait(TICK * 2);
          sp['load'] = '';
          pl['v'] = 'o';
          SFX.blip();
          await wait(TICK * 3);
          await reposo(4);
        } else if (o['que'] == 'come') {
          await forkfuls('luis', pl, const ['o1', '']);
        } else if (o['que'] == 'cuchara') {
          // he holds it out over the frog's plate
          await toma();
          await cucharaA('luis', sp!, PRANA[0] - 2, PRANA[1] - 9, 6);
          await wait(TICK * 3);
        } else if (o['que'] == 'entrega') {
          await toma();
          await cucharaA('luis', sp!, PRANA[0] - 5, PRANA[1] - 10, 5);
          await pasaCuchara('luis', 'rana');
          SFX.blip();
          await wait(TICK * 2);
        }
      }();
      return corre(o, pr);
    },
    // a thought over the frog: what he would like (quiere) or his round belly with a hand on it beside the clean plate
    // (lleno). Its trail leads to him
    'piensa34': (o) async {
      final q = _cq, lleno = o['k'] == 'lleno';
      q['nube'] = [...(lleno ? NUBE34['barriga']! : NUBE34['montoncor']!)];
      q['nubeAim'] = [...AIM34];
      q['piensa'] = <String, dynamic>{'k': lleno ? 'barriga' : 'montoncor'};
      SFX.blip();
      await wait(TICK * 4);
    },
    'calla34': (o) async {
      _cq['piensa'] = null;
    },
    // the mound on Luis's spoon goes onto the frog's plate (he tips the spoon over it, then lowers it); the frog eats it at
    // his plate with his fork, in three forkfuls; right after "lleno" his belly swells over three frames, and (entera) he
    // tips over on his back
    'ranaCome34': (o) async {
      final pl = ob('pl_rana')!, q = _cq;
      final pr = () async {
        q['piensa'] = null;
        final sp = spoonOf('luis');
        if (sp != null) {
          await cucharaA('luis', sp, PRANA[0], PRANA[1] - 7, 6);
          await wait(TICK * 2);
          sp['load'] = '';
          pl['v'] = 'o';
          SFX.blip();
          await wait(TICK * 3);
          final r = luisRest();
          await cucharaA('luis', sp, r[0], r[1], 4);
        }
        await ranaFork(const ['o2', 'o1', '']);
        pl['v'] = 'mi';
        SFX.blip();
        if (jsTruthy(o['entera'])) {
          await inflar(true);
          await wait(TICK * 6);
        } else {
          if (jsTruthy(o['lleno'])) await inflar(false);
          await ranaA(CASA34[0], CASA34[1]);
        }
      }();
      return corre(o, pr);
    },
    'levantaRana34': (o) async {
      await desinflar();
      SFX.blip();
      await wait(TICK * 2);
      await ranaA(CASA34[0], CASA34[1]);
    },
    // Luis eats the mound on the spoon too (the spoon goes up to his mouth): two bites
    'luisCome2': (o) async {
      final l = G('luis')!;
      final pr = () async {
        _cq['piensa'] = null;
        final sp = spoonOf('luis');
        if (sp != null) {
          await cucharaA(
            'luis',
            sp,
            (l['x'] as num) + 9,
            (l['y'] as num) - bocaY('luis', l) - 2,
            5,
          );
          await wait(TICK * 2);
          for (final ld in const ['monton1', '']) {
            sp['load'] = ld;
            SFX.blip();
            for (var i = 0; i < 2; i++) {
              l['boca'] = 1;
              await wait(TICK * 2);
              l['boca'] = 0;
              await wait(TICK * 2);
            }
          }
          final r = luisRest();
          await cucharaA('luis', sp, r[0], r[1], 4);
        }
      }();
      return corre(o, pr);
    },
    // Luis glances at papá's fork (his head turns to the platter) and takes one of papá's three for the frog (rana) or for
    // himself (luis)
    'luisPapa34': (o) async {
      final l = G('luis')!;
      l['dir'] = -1;
      await wait(TICK * 9);
      l['dir'] = 1;
      await wait(TICK * 2);
      if (o['para'] == 'rana') {
        await _act('luis34', {'que': 'cuchara', 'de': 'p'});
        await _act('ranaCome34', {});
      } else {
        await _act('luis34', {'que': 'sirve', 'de': 'p'});
        await _act('luis34', {'que': 'come'});
      }
    },
    // steps 5 and 6: the three at the table; whoever says "Yo estoy lleno/llena" puts a hand on his belly
    'mano34': (o) async {
      final p = G(o['a'])!;
      p['pose'] = jsTruthy(o['pose']) ? o['pose'] : 'yo';
      SFX.blip();
      await wait(TICK * 3);
    },
    'plato34': (o) async {
      final pl = ob('pl_${_js(o['a'])}')!;
      pl['v'] = jsTruthy(o['v']) ? o['v'] : '';
    },
    // she eats what is left on her plate, in view (a forkful), and lays her fork down: her plate is clean
    'limpia34': (o) async {
      final id = '${o['a']}', pl = ob('pl_$id')!;
      await forkfuls(id, pl, const ['']);
      await dejaTenedor(id);
    },
    // the frog hops along the cloth with the spoon (Luis handed it to him) to the plate of the one at his seat and tips the
    // mound onto it, where it mixes into his rice (mezcla), or the one eats it with his fork; then he takes the spoon back
    // to Luis (moves line 971: on the cloth beside Luis)
    'tipa34': (o) async {
      final id = '${o['a']}', p = G(id)!, pl = ob('pl_$id')!, q = _cq, l = G('luis')!;
      final pr = () async {
        q['piensa'] = null;
        final L = lado34(pl['x'] as num),
            sp = _find(q['tiene'], (t) => t['k'] == 'uten');
        if (sp == null) return;
        await ranaA(L.fx, L.fy);
        await cucharaAR(
          sp,
          (pl['x'] as num) + (L.izq ? -3 : 3),
          (pl['y'] as num) - 8,
          L.izq,
          5,
        );
        await wait(TICK * 3);
        sp['load'] = '';
        if (_on(o['mezcla'])) {
          pl['v'] = 'h';
          SFX.bonk();
          await wait(TICK * 8);
        } else {
          pl['v'] = 'rm';
          SFX.blip();
          await wait(TICK * 4);
          p['pose'] = 'idle';
          await forkfuls(id, pl, const ['r2', 'r1', '']);
          await dejaTenedor(id);
        }
        while (jsTruthy(l['come']) || jsTruthy(l['boca'])) {
          await wait(TICK);
        }
        await ranaA(144, 172);
        await cucharaAR(sp, 127, 172, true, 4);
        await wait(TICK * 2);
        final sp2 = await cucharaDeRana('luis');
        final r = luisRest();
        if (sp2 != null) await cucharaA('luis', sp2, r[0], r[1], 3);
        await ranaA(CASA34[0], CASA34[1]);
      }();
      return corre(o, pr);
    },
    // whoever was full only now puts a hand on his belly and pushes his plate a little away, and holds it so for a moment
    'llenoAhora34': (o) async {
      final id = '${o['a']}', p = G(id)!, pl = ob('pl_$id')!;
      p['pose'] = 'yo';
      SFX.blip();
      await wait(TICK * 6);
      final r = rel(id, pl['x'] as num, (pl['y'] as num) - 6),
          hb = <String, dynamic>{
            'k': 'brazo',
            '_m': 9,
            'gx': r[0],
            'gy': r[1],
            'sh': 1,
          };
      p['pose'] = 'idle';
      (p['tiene'] as List).add(hb);
      for (var i = 0; i < 3; i++) {
        pl['y'] = (pl['y'] as num) + 2;
        hb['gy'] = (p['y'] as num) - ((pl['y'] as num) - 6);
        await wait(TICK * 2);
      }
      final rr = restHand(id);
      await manoA(id, rr[0], rr[1], 2);
      sinManos(id);
      p['pose'] = 'yo';
      await wait(TICK * 8);
    },
    // gets up and says it to the table (a line follows). mamá walks to the high chair and takes the baby in both hands (in
    // the game she walks out with him; moves line 981); with a plate he lays his fork down, takes his plate, carries it to
    // the counter (moves line 985: behind the table, by the passage), sets it on the counter top (it stays there) and goes
    // out; otherwise he goes out
    'levanta34': (o) async {
      final id = '${o['a']}',
          p = G(id)!,
          pl = ob('pl_$id'),
          sb = ob('silla_bebe'),
          juego = jsTruthy(W['turno']);
      p['pose'] = 'idle';
      SFX.blip();
      final llevaPlato =
          id != 'mama' && (_on(o['plato']) || (juego && pl!['v'] != 'h'));
      if (llevaPlato) {
        await dejaTenedor(id);
      } else if (tenedorDe(id) != null) {
        await dejaTenedor(id);
      }
      // he stands up in steps (his head goes up 3, 6, then upright)
      p['dy'] = -3;
      await wait(TICK * 4);
      p['dy'] = -6;
      await wait(TICK * 4);
      p['sent'] = 0;
      p['dy'] = 0;
      await wait(TICK * 4);
      if (id == 'mama') {
        await delante(id, 188, 206);
        p['dir'] = 1;
        // both her hands go to the baby, under his arms (from his left side, so that she does not stand in front of him)
        final bc = [HIJA[0], HIJA[1] - 26];
        final rL = rel(id, bc[0] - 6, bc[1] + 7), rR = rel(id, bc[0] + 1, bc[1] + 7);
        await Future.wait<void>([
          manoA(id, rL[0], rL[1], 3, -1),
          manoA(id, rR[0], rR[1], 3, 1),
        ]);
        await wait(TICK * 3);
        final it = <String, dynamic>{'k': 'bebeH', 'e': 1, 'dos': 3.5},
            c = centroPara(id, it, bc[0] - 6, bc[1] + 7);
        it['dx'] = c[0];
        it['dy'] = c[1];
        sinManos(id);
        p['tiene'] = <dynamic>[it];
        sb!['v'] = '0';
        SFX.blip();
        await wait(TICK * 2);
        // he is in her hands in the same moment the chair is empty
        await mueveTiene(id, it, 3, 26, 5);
        if (juego) await sale(id);
      } else if (llevaPlato) {
        final it = await toma(id, pl!, null, null, {'n': 3});
        await mueveTiene(id, it, 12, 20, 3);
        await atras(id, 190, 124);
        p['dir'] = -1;
        await mueveTiene(id, it, -8, (p['y'] as num) - CONT34[1] + 2, 4);
        await pon(
          id,
          it,
          pl,
          CONT34[0],
          CONT34[1],
          3,
          (q) => q['z'] = CONT34[1],
        );
        await wait(TICK * 3);
        p['dir'] = 1;
        if (juego) await sale(id);
      } else {
        await sale(id);
      }
    },
    // she comes back to her chair: mamá puts the baby back in his chair first (both arms, over a few frames); Carmen takes
    // her plate from the counter (moves line 993), carries it to her place, sets it down in front of her and sits (moves
    // line 994: at her seat's row, SY)
    'vuelve34': (o) async {
      final id = '${o['a']}',
          p = G(id)!,
          pl = ob('pl_$id'),
          sb = ob('silla_bebe'),
          seat = Comer.SEAT34[id];
      if (id == 'mama') {
        await delante(id, _at(990, 188), _at(990, 206));
        p['dir'] = 1;
        final it = _find(p['tiene'], (t) => t['k'] == 'bebeH')!;
        await mueveTiene(
          id,
          it,
          (HIJA[0] - (p['x'] as num)) * 1,
          (p['y'] as num) - (HIJA[1] - 26),
          5,
        );
        sb!['v'] = '1';
        SFX.blip();
        final px = p['x'] as num, py = p['y'] as num;
        final hs = agarres(
              it,
              px + (it['dx'] as num),
              py - (it['dy'] as num),
              false,
            ),
            hb = [
              for (final h in hs)
                () {
                  final r = rel(id, h[0], h[1]),
                      left = h[0] < px + (it['dx'] as num);
                  return <String, dynamic>{
                    'k': 'brazo',
                    '_m': left ? 1 : 2,
                    'gx': r[0],
                    'gy': r[1],
                    'sh': left ? -1 : 1,
                  };
                }(),
            ];
        _quita(p, it);
        for (final h in hb) {
          (p['tiene'] as List).add(h);
        }
        final rr = restHand(id);
        await Future.wait<void>([
          for (final h in hb)
            manoA(
              id,
              rr[0] * (h['sh'] as num),
              rr[1],
              3,
              h['sh'] as num,
            ),
        ]);
        sinManos(id);
        await wait(TICK * 2);
        await sienta(id, seat!);
        return;
      }
      if (_on(o['plato'])) {
        await atras(id, 190, 124);
        p['dir'] = -1;
        final cp = ob('pl_$id')!;
        final it = await toma(id, cp, null, null, {'n': 3});
        await mueveTiene(id, it, 12, 20, 3);
        await detras(id, SILLA[seat!] - 8, SY(SILLA[seat] - 8, ASIENTO));
        p['dir'] = 1;
        pl!['z'] = null;
        await pon(id, it, pl, SILLA[seat], SY(SILLA[seat], FILA), 4);
        await sienta(id, seat);
      }
    },
    // after a miss: a second mound, from papá's three, for the one who asked: Luis takes it with the spoon, hands it to the
    // frog, the frog tips it onto his plate and he eats it
    'papaB34': (o) async {
      await _act('luis34', {'que': 'entrega', 'de': 'p'});
      await _act('tipa34', {'a': o['a']});
    },
    // the one who asked looks at the platter (his head turns to it)
    'mira34': (o) async {
      final p = G(o['a']);
      if (p == null) return;
      p['dir'] = -1;
      await wait(TICK * 10);
      p['dir'] = 1;
    },
    // the turn. Luis walks to abuela at the stove and gives her the big spoon (both hands on it), and goes to wait at the
    // left end (moves line 1005); abuela takes the platter off the stove top in one hand (the spoon in the other) and
    // carries it along the front to its place (moves line 1007); she lifts the pot by its handle (moves line 1009),
    // carries it along the front and round the right end to BEHIND the table, and serves the three plates from behind
    // (moves line 1010); she carries the pot back and sets it on the table (moves line 1014); then she stands between the
    // pot and the platter (moves line 1017) and scoops the pot onto the platter, mound by mound (seven: four helpings at
    // the left, papá's three at his end), the rice going down at every scoop; she pushes papá's fork behind his three,
    // lifts the pot (moves line 1026), tips it towards us: empty; gives the spoon back to Luis at the stove (moves line
    // 1028) and walks out with the pot
    'turno34': (o) async {
      final ab = G('abuela')!, l = G('luis')!, ol = ob('olla')!, fu = ob('fuente')!;
      W['turno'] = 1;
      // his belly goes down again in view (three steps) while the turn starts: the game begins with a frog of his own size
      if (jsTruthy(_cq['lleno'])) _later(desinflar());
      await aEncuentro34();
      await mueve('abuela', FOGON[0] - 2, _at(1003, 176));
      ab['dir'] = -1;
      {
        final sL = spoonOf('luis')!;
        await cucharaA(
          'luis',
          sL,
          (l['x'] as num) + 13,
          (l['y'] as num) - 22,
          3,
        );
        await wait(TICK * 2);
      }
      final spA = (await pasaCuchara('luis', 'abuela'))!;
      spA['side'] = -1;
      await cucharaA('abuela', spA, (ab['x'] as num) - 17, (ab['y'] as num) - 22, 3);
      await wait(TICK * 2);
      final lw = _later(
        ruta('luis', [
          [ENC34[0], FR],
          [58, FR],
          [58, 190],
        ]).then((_) {
          l['dir'] = 1;
        }),
      );
      await mueve('abuela', AFOGON[0], AFOGON[1]);
      ab['dir'] = -1;
      final pf = await toma('abuela', fu, 0, 20, {
        'n': 3,
        'm': 3,
        'extra': <String, dynamic>{
          'una': 1,
          'tenedor': fu['tenedor'],
          'montones': fu['montones'],
        },
      });
      pf['v'] = '';
      await ruta('abuela', [
        [SIDE34[0], SIDE34[1]],
        [SIDE34[0], FR],
        [FU34[0], FR],
        [FU34[0], 193],
      ]);
      ab['dir'] = -1;
      await pon('abuela', pf, fu, FU34[0], FU34[1], 4);
      fu['tenedor'] = <String, dynamic>{'dx': -4, 'dy': 3};
      await wait(TICK * 3);
      await lw;
      // the pot: she goes to its right side, takes it by its handle, and carries it with the spoon in her other hand
      await mueve('abuela', OLLA[0] + 22, 206);
      ab['dir'] = -1;
      final pot = await toma('abuela', ol, -9, 19, {
        'n': 3,
        'm': 3,
        'extra': <String, dynamic>{'una': 'h'},
      });
      pot['vapor'] = 0;
      Future<void> sirve(String id) async {
        final pl = ob('pl_$id')!;
        final x = (pl['x'] as num) + 13;
        await detras('abuela', x, SY(x, 130));
        ab['dir'] = -1;
        ab['est'] = 1;
        await wait(TICK);
        // the spoon dips into the pot she holds: the rice in it is lower
        await cucharaA(
          'abuela',
          spA,
          _round(ab['x'] as num) + 9,
          _round(ab['y'] as num) - 25,
          4,
        );
        await wait(TICK * 2);
        spA['load'] = 'monton';
        W['nO'] = _n(W['nO']) + 1;
        pot['v'] = nivelOlla(W['nO'] as num);
        SFX.blip();
        await wait(TICK * 4);
        await cucharaA('abuela', spA, pl['x'] as num, (pl['y'] as num) - 5, 5);
        await wait(TICK * 2);
        spA['load'] = '';
        pl['v'] = 'o';
        SFX.blip();
        await wait(TICK * 3);
        pl['v'] = 'r';
        await wait(TICK * 3);
      }

      for (final id in const ['abuelo', 'carmen', 'mama']) {
        await sirve(id);
      }
      ab['est'] = 0;
      await delante('abuela', OLLA[0] - 14, 204);
      ab['dir'] = 1;
      pot['dx'] = 9;
      await pon('abuela', pot, ol, OLLA[0], OLLA[1], 4);
      ol['v'] = nivelOlla(W['nO'] as num);
      await wait(TICK * 3);
      // she stands between the pot and the platter and scoops it onto the platter with the big spoon, in view
      await mueve('abuela', OLLA[0] - 16, 203);
      ab['dir'] = -1;
      const xs = [-9, -4, -9, -4, 4, 9, 7], ys = [-4, -4, -8, -8, -8, -8, -4];
      Future<void> scoop() async {
        await cucharaA('abuela', spA, OLLA[0], OLLA[1] - 14, 4);
        await wait(TICK * 2);
        spA['load'] = 'monton';
        W['nO'] = _n(W['nO']) + 1;
        ol['v'] = nivelOlla(W['nO'] as num);
        SFX.blip();
        await wait(TICK * 4);
      }

      for (var i = 0; i < 7; i++) {
        await scoop();
        await cucharaA(
          'abuela',
          spA,
          (fu['x'] as num) + xs[i],
          (fu['y'] as num) + ys[i] - 6,
          5,
        );
        await wait(TICK * 2);
        spA['load'] = '';
        (fu['montones'] as List).add(<String, dynamic>{
          'dx': xs[i],
          'dy': ys[i],
          'g': i < 4 ? 'm' : 'p',
        });
        SFX.blip();
        await wait(TICK * 3);
      }
      ol['v'] = 'vacio';
      await wait(TICK * 2);
      // she pushes papá's fork behind his three mounds with the spoon (the fork lies along the back rim of the platter,
      // hiding none of them)
      final f0 = fu['tenedor'] as M, fx0 = f0['dx'] as num, fy0 = f0['dy'] as num;
      await cucharaA(
        'abuela',
        spA,
        (fu['x'] as num) + fx0 - 6,
        (fu['y'] as num) - fy0 - 2,
        4,
      );
      for (var i = 1; i <= 5; i++) {
        f0['dx'] = fx0 + (8 - fx0) * i / 5;
        f0['dy'] = fy0 + (15 - fy0) * i / 5;
        await cucharaA(
          'abuela',
          spA,
          (fu['x'] as num) + (f0['dx'] as num) - 6,
          (fu['y'] as num) - (f0['dy'] as num) - 2,
          1,
        );
        await wait(TICK);
      }
      await wait(TICK * 4);
      // the pot: she goes to its left side, takes it by its handle, lifts it and tips it towards us: empty
      await mueve('abuela', OLLA[0] - 22, 200);
      ab['dir'] = 1;
      final pot2 = await toma('abuela', ol, 9, 19, {
        'n': 3,
        'm': 3,
        'extra': <String, dynamic>{'una': 'h'},
      });
      pot2['v'] = 'vacio';
      pot2['vapor'] = 0;
      await mueveTiene('abuela', pot2, 5, 26, 3);
      pot2['ang'] = .7;
      await wait(TICK * 10);
      pot2['ang'] = 0;
      await mueveTiene('abuela', pot2, 9, 19, 3);
      // she walks to the stove with the pot and the spoon; Luis comes to her, takes the spoon (both hands on it) and goes
      // back; she walks out with the pot
      await ruta('abuela', [
        [OLLA[0] - 22, FR],
        [FOGON[0] - 2, FR],
        [FOGON[0] - 2, 176],
      ]);
      ab['dir'] = -1;
      pot2['dx'] = -9;
      await cucharaA('abuela', spA, (ab['x'] as num) - 17, (ab['y'] as num) - 22, 3);
      await aEncuentro34();
      final spL2 = (await pasaCuchara('abuela', 'luis'))!;
      final lr = luisRest();
      await cucharaA('luis', spL2, lr[0], lr[1], 4);
      _quita(ab, spA);
      final back = _later(deEncuentro34());
      await mueveTiene('abuela', pot2, -3, 16, 3);
      await sale('abuela');
      await back;
    },
    // papá walks in and sits; abuela walks in, Luis gives her the big spoon (both hands on it); she takes the platter with
    // what is left of it (papá's end) in one hand, the spoon in the other (moves line 1036), carries it along the front and
    // round the right end to behind papá's chair (moves line 1038), and moves his mounds onto his plate one at a time with
    // the spoon, each leaving the platter in the spoon, in view; then his fork; she walks back to the stove with the platter
    // (moves line 1047), Luis takes the spoon back from her there, and she puts the platter on the stove
    'final34': (o) async {
      final ab = G('abuela')!,
          pa = G('papa')!,
          l = G('luis')!,
          fu = ob('fuente')!,
          pl = ob('pl_papa')!;
      pa['vis'] = 0;
      ab['vis'] = 0;
      pa['tiene'] = <dynamic>[];
      ab['tiene'] = <dynamic>[];
      ab['pose'] = 'idle';
      final pr = _later(sienta('papa', Comer.SEAT34['papa']!));
      await wait(TICK * 7);
      await entra('abuela', FU34[0] - 18, FR, 1);
      await pr;
      ab['dir'] = 1;
      await mueve('abuela', FU34[0] - 18, 184);
      ab['dir'] = 1;
      {
        final sp0 = spoonOf('luis')!;
        await cucharaA(
          'luis',
          sp0,
          (l['x'] as num) - 13,
          (l['y'] as num) - 22,
          3,
        );
        l['dir'] = -1;
        await wait(TICK);
      }
      final spA = (await pasaCuchara('luis', 'abuela'))!;
      spA['side'] = 1;
      await cucharaA('abuela', spA, (ab['x'] as num) + 14, (ab['y'] as num) - 22, 3);
      l['dir'] = 1;
      await wait(TICK * 2);
      await mueve('abuela', FU34[0], 193);
      ab['dir'] = -1;
      final pf = await toma('abuela', fu, 0, 20, {
        'n': 3,
        'm': 3,
        'extra': <String, dynamic>{
          'una': 1,
          'tenedor': fu['tenedor'],
          'montones': fu['montones'],
        },
      });
      pf['v'] = '';
      // along the front, round the right end, behind papá: the platter at her side, the spoon in her other hand
      await mueveTiene('abuela', pf, -11, 22, 3);
      final bx = (pl['x'] as num) + 16;
      await detras('abuela', bx, SY(bx, 130));
      ab['dir'] = -1;
      ab['est'] = 1;
      await wait(TICK * 2);
      final n = (fu['montones'] as List).where((m) => (m as Map)['g'] == 'p').length;
      for (var i = 0; i < n; i++) {
        final m = _find(fu['montones'], (m) => m['g'] == 'p');
        if (m == null) break;
        await cucharaA(
          'abuela',
          spA,
          _round(ab['x'] as num) - (pf['dx'] as num) + (m['dx'] as num),
          _round(ab['y'] as num) -
              (pf['dy'] as num) +
              6 +
              (m['dy'] == null ? -4 : m['dy'] as num) -
              3,
          5,
        );
        await wait(TICK * 2);
        spA['load'] = 'monton';
        (fu['montones'] as List).remove(m);
        SFX.blip();
        await wait(TICK * 3);
        await cucharaA('abuela', spA, pl['x'] as num, (pl['y'] as num) - 5, 5);
        await wait(TICK * 2);
        spA['load'] = '';
        pl['v'] = 'p${i + 1}';
        SFX.blip();
        await wait(TICK * 4);
      }
      if (jsTruthy(fu['tenedor'])) {
        final f0 = fu['tenedor'] as M,
            tx = (pl['x'] as num) + 15,
            ty = (pl['y'] as num) - 3;
        await cucharaA(
          'abuela',
          spA,
          _round(ab['x'] as num) - (pf['dx'] as num) + (f0['dx'] as num) - 4,
          _round(ab['y'] as num) - (pf['dy'] as num) + 4 - (f0['dy'] as num),
          5,
        );
        await wait(TICK * 2);
        fu['tenedor'] = null;
        pf['tenedor'] = null;
        await cucharaA('abuela', spA, tx - 5, ty - 5, 5);
        _cosas.add(<String, dynamic>{
          'id': 'tenedor_papa',
          'k': 'tenedorH',
          'x': tx,
          'y': ty,
          'z': (pl['y'] as num) + .5,
        });
        SFX.blip();
        await wait(TICK * 3);
      }
      V['pmont'] = '$n';
      await wait(TICK * 2);
      // back along the lane and the front to the stove; Luis takes the spoon; the platter goes back on the stove
      ab['est'] = 0;
      await delante('abuela', XP, FR);
      await ruta('abuela', [
        [FOGON[0] - 2, FR],
        [FOGON[0] - 2, 176],
      ]);
      ab['dir'] = -1;
      await cucharaA('abuela', spA, (ab['x'] as num) - 17, (ab['y'] as num) - 22, 3);
      await aEncuentro34();
      final sL = (await pasaCuchara('abuela', 'luis'))!;
      final lr = luisRest();
      await cucharaA('luis', sL, lr[0], lr[1], 3);
      final back = _later(deEncuentro34());
      _quita(ab, spA);
      await mueve('abuela', AFOGON[0], AFOGON[1]);
      ab['dir'] = -1;
      pf['v'] = 'c';
      await pon('abuela', pf, fu, PLAT34[0], PLAT34[1], 4);
      fu['x'] = PLAT34[0];
      fu['y'] = PLAT34[1];
      await back;
    },
    // he takes his fork off his plate and eats his mounds, forkful by forkful (three, two or one)
    'papaCome34': (o) async {
      final pa = G('papa')!, pl = ob('pl_papa')!;
      final pr = () async {
        final fk = ob('tenedor_papa');
        if (fk != null && fk['vis'] != 0) {
          final it = await toma('papa', fk, null, null, {'n': 3});
          it['k'] = 'tenedor';
          it['e'] = 1;
          it['v'] = '';
          await mueveTiene('papa', it, 7, 12, 3);
        } else if (tenedorDe('papa') == null) {
          (pa['tiene'] as List).add(<String, dynamic>{
            'k': 'tenedor',
            'e': 1,
            'dx': 7,
            'dy': 12,
          });
        }
        final n0 = _plus(_js(pl['v']).replaceAll(RegExp(r'\D'), ''));
        final n = n0.isNaN || n0 == 0 ? 0 : n0;
        if (jsTruthy(o['fin'])) {
          final lv = <String>[
            for (var i = n - 1; i >= 0; i--) i != 0 ? 'p${jsNum(i)}' : 'mi',
          ];
          await forkfuls('papa', pl, lv.isNotEmpty ? lv : const ['mi']);
        } else if (n > 0) {
          await forkfuls('papa', pl, ['p${jsNum(n - 1)}']);
        }
      }();
      return corre(o, pr);
    },
    'papaMira34': (o) async {
      final pa = G('papa')!;
      pa['dir'] = 1;
      pa['pose'] = 'idle';
      await wait(TICK * 13);
    },
  };
}
