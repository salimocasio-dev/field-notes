// comer.js:1056 to :1226, story 35 (Café con azúcar), line for line. The table is cleared. Abuelo and papá have black
// coffee; Luis and Carmen hold cups of hot milk at the left end; the frog stands by the sugar bowl, his own small cup by
// him. On the stove: the big blue coffee pot and the milk pan; the greca (the little red coffee pot) and abuela's own cup
// stand at the right end of the table; her stool stands by the stove. Canelo lies by his empty bowl.
// ignore_for_file: non_constant_identifier_names, constant_identifier_names
part of 'comer.dart';

extension _Acts35 on Comer {
  // the cup someone holds (`p.tiene.find(x => x.k === "taza" || x.k === "tazacu")`)
  M? _cup(M p) =>
      _find(p['tiene'], (x) => x['k'] == 'taza' || x['k'] == 'tazacu');

  M get _pote => W['pote'] as M;

  Map<String, Act> _acts35() => {
    // moves lines 1060, 1061: the seated and their cups and teaspoons on the rows there (SY)
    'inicio35': (o) async {
      List<dynamic> taza() => <dynamic>[
        TENE('taza', 13, 16, {'v': 'leche'}),
      ];
      W['gente'] = <String, dynamic>{
        'abuelo': <String, dynamic>{
          'x': SILLA[0],
          'y': SY(SILLA[0], ASIENTO),
          'sent': 1,
          'dir': 1,
          'tiene': <dynamic>[],
        },
        'papa': <String, dynamic>{
          'x': SILLA[3],
          'y': SY(SILLA[3], ASIENTO),
          'sent': 1,
          'dir': -1,
          'tiene': <dynamic>[],
        },
        'luis': <String, dynamic>{'x': 60, 'y': 178, 'dir': 1, 'tiene': taza()},
        'carmen': <String, dynamic>{
          'x': 80,
          'y': 186,
          'dir': 1,
          'tiene': taza(),
        },
        'abuela': <String, dynamic>{
          'x': FOGON[0],
          'y': FOGON[1],
          'dir': -1,
          'tiene': <dynamic>[],
        },
        'mama': <String, dynamic>{'vis': 0, 'tiene': <dynamic>[]},
      };
      W['sitio'] = <String, dynamic>{'abuelo': 0, 'papa': 3};
      W['cosas'] = <dynamic>[
        <String, dynamic>{
          'id': 'taburete',
          'k': 'taburete',
          'x': STOOL[0],
          'y': STOOL[1],
        },
        for (final (id, s) in [('abuelo', SILLA[0]), ('papa', SILLA[3])])
          <String, dynamic>{
            'id': 't_$id',
            'k': 'taza',
            'x': s,
            'y': SY(s, FILA),
            'v': 'negro',
            'vapor': 1,
            'vdy': 19,
            'vh': 6,
          },
        for (final (id, s) in [
          ('abuelo', SILLA[0] - 12),
          ('papa', SILLA[3] + 12),
        ])
          <String, dynamic>{
            'id': 'tc_$id',
            'k': 'cucharilla',
            'x': s,
            'y': SY(s, FILA) - 1,
          },
        for (final (id, k) in [('luis', K1), ('carmen', K2)])
          <String, dynamic>{
            'id': 't_$id',
            'k': 'taza',
            'x': k[0],
            'y': k[1],
            'v': 'leche',
            'vapor': 1,
            'vdy': 20,
            'vh': 5,
            'vis': 0,
          },
        <String, dynamic>{
          'id': 'azucarera',
          'k': 'azucarera',
          'x': AZU[0],
          'y': AZU[1],
          'spoons': 8,
        },
        <String, dynamic>{
          'id': 't_rana',
          'k': 'taza',
          'x': TRANA[0],
          'y': TRANA[1],
          'v': 'vacia',
          'vapor': 0,
        },
        <String, dynamic>{
          'id': 't_abuela',
          'k': 'taza',
          'x': TABU[0],
          'y': TABU[1],
          'v': 'vacia',
          'vapor': 0,
          'e': 1,
        },
        <String, dynamic>{
          'id': 'cafetera',
          'k': 'cafetera',
          'x': CAFE35[0],
          'y': CAFE35[1],
          'vapor': 1,
          'vdx': -2,
          'vdy': 26,
          'vn': 1,
          'vh': 6,
        },
        <String, dynamic>{
          'id': 'cazo',
          'k': 'cazo',
          'v': '1',
          'x': CAZO35[0],
          'y': CAZO35[1],
        },
        <String, dynamic>{
          'id': 'jarrita',
          'k': 'jarrita',
          'x': GRECA35[0],
          'y': GRECA35[1] + 4,
        },
        <String, dynamic>{
          'id': 'tazon',
          'k': 'tazon',
          'v': '0',
          'x': TAZON[0],
          'y': TAZON[1],
        },
      ];
      W['perro'] = <String, dynamic>{
        'x': CANELO[0],
        'y': CANELO[1],
        'pose': 'lie',
        'dir': 1,
      };
      W['pote'] = <String, dynamic>{};
      _cq.addAll({
        'x': CASA35[0] - 16,
        'y': CASA35[1] - 27,
        's': 1,
        'sobre': 1,
        'dy': 0,
        'vis': 1,
        'tiene': <dynamic>[],
        'lleno': 0,
        'espalda': 0,
        'piensa': null,
        'mal': 0,
        'nube': [...NUBE35],
        'nubeAim': [...AIM35],
        'ndir': 1,
      });
    },
    // the men take their cups in their hands and hold them out over the table, looking at the middle; or set them down
    'tienden35': (o) async {
      await Future.wait<void>([
        for (final id in _js(o['a']).split(','))
          () async {
            final t = copa(id)!, p = G(id)!;
            if (((p['tiene'] as List?) ?? const []).any(
              (x) => (x as Map)['k'] == 'taza' || x['k'] == 'tazacu',
            )) {
              return;
            }
            final it = await toma(id, t, 14, 16, {
              'n': 3,
              'm': 3,
              'vapor': 0,
              'extra': jsTruthy(t['sp'])
                  ? <String, dynamic>{'sp': t['sp']}
                  : <String, dynamic>{},
            });
            it['v'] = t['v'];
            it['vapor'] = 0;
            if (jsTruthy(t['sp'])) it['sp'] = t['sp'];
          }(),
      ]);
      await wait(TICK * 2);
    },
    'bajan35': (o) async {
      await Future.wait<void>([
        for (final id in _js(o['a']).split(','))
          () async {
            final p = G(id)!,
                it = _find(p['tiene'], (x) => x['k'] == 'taza'),
                t = copa(id)!;
            if (it == null) return;
            it['k'] = jsTruthy(it['sp']) ? 'tazacu' : 'taza';
            final x = t['x'] as num, y = t['y'] as num;
            t['v'] = it['v'];
            await pon(id, it, t, x, y, 3, (q) {
              q['v'] = it['v'];
              q['vapor'] = RegExp('vacia|azu').hasMatch(_js(it['v'])) ? 0 : 1;
              q['vh'] = 6;
              if (jsTruthy(it['sp'])) q['sp'] = 1;
            });
          }(),
      ]);
      await wait(TICK);
    },
    // abuela takes the big pot off the stove and walks behind the table to the empty chair between the two men (moves line
    // 1072: on the lane and the row there, SY)
    'trae35': (o) async {
      final ab = G('abuela')!, ce = ob('cafetera')!;
      ab['dir'] = -1;
      ab['pose'] = 'idle';
      if (!((ab['tiene'] as List?) ?? const []).any(
        (t) => (t as Map)['k'] == 'cafetera',
      )) {
        if (((ab['x'] as num) - AFOGON[0]).abs() > 6 ||
            ((ab['y'] as num) - AFOGON[1]).abs() > 6) {
          await ruta('abuela', [
            [AFOGON[0], AFOGON[1]],
          ]);
        }
        ab['dir'] = -1;
        await toma('abuela', ce, 9, 20, {'n': 3, 'm': 3, 'vapor': 0});
      }
      await detras('abuela', 150, SY(150, ATRAS));
      await mueve('abuela', 126, SY(126, ASIENTO - 2));
      ab['dir'] = -1;
    },
    // moves line 1073: back to the stove behind the table (atras)
    'vuelve35': (o) async {
      final ab = G('abuela')!,
          ce = ob('cafetera')!,
          it = _find(
            ab['tiene'],
            (t) => t['k'] == 'cafetera' || t['k'] == 'tiltcafetera',
          );
      if (it == null) return;
      it['k'] = 'cafetera';
      await atras('abuela', AFOGON[0], AFOGON[1]);
      ab['dir'] = -1;
      await pon('abuela', it, ce, CAFE35[0], CAFE35[1], 4);
      ce['vapor'] = 1;
    },
    // the frog fills a teaspoon at the sugar bowl: he takes the spoon that stands in it and dips it into the sugar
    'llena35': (o) async {
      await ranaCucharita();
    },
    // the frog brings the teaspoon of sugar to the cup of the one touched (mal: it already had its sugar: two heaps): the
    // grains fall into it in view, he stirs, and the spoon stays standing in the cup
    'azucar35': (o) async {
      final id = '${o['a']}', p = G(id)!, mal = _on(o['mal']);
      if (mal) W['lista35'] = 0;
      final pr = () async {
        final q = _cq;
        var sp = _find(q['tiene'], (t) => t['k'] == 'uten');
        if (sp == null || sp['load'] != 'azu') sp = await ranaCucharita();
        final it = _cup(p)!,
            d = _d(p),
            cxw = _round(p['x'] as num) + d * (it['dx'] as num),
            cyw = _round(p['y'] as num) - (it['dy'] as num);
        await azucarEn(cxw, cyw, sp, it, mal, id);
        if (!mal) it['k'] = 'tazacu';
        await ranaA(CASA35[0], CASA35[1]);
      }();
      return corre(o, pr);
    },
    // abuela pours coffee into a cup from the big pot she holds, from beside the man (mal: the last finger, into the same
    // cup): the cup fills in two stages
    'cafe35': (o) async {
      final id = '${o['a']}', t = copa(id)!, ab = G('abuela')!, p = G(id)!;
      final pr = () async {
        // she pours in the same move as the frog tips his spoon: she waits until he is at the cup with it
        if (_on(o['mal'])) {
          var n = 0;
          while (!jsTruthy(W['lista35']) && n++ < 200) {
            await wait(TICK);
          }
        }
        final cup = _cup(p), dd = _d(p);
        final cxx = cup != null
                ? _round(p['x'] as num) + dd * (cup['dx'] as num)
                : t['x'] as num,
            left = cxx < (ab['x'] as num),
            tx = cxx + (left ? 7 : -7),
            ty = cup != null
                ? _round(p['y'] as num) - (cup['dy'] as num) - 12
                : (t['y'] as num) - 24;
        ab['dir'] = left ? -1 : 1;
        final up = _find(ab['tiene'], (x) => x['k'] == 'cafetera'),
            tilt = await vierteA(
              'abuela',
              'cafetera',
              '',
              tx,
              ty,
              !left,
              12,
              '#2A160C',
              [ab['y'] as num],
            );
        _quita(ab, up);
        (ab['tiene'] as List).add(tilt);
        SFX.blip();
        if (cup != null) {
          await wait(_on(o['dedo']) ? TICK * 4 : TICK * 6);
          if (!_on(o['mal']) && _on(o['llena'])) cup['v'] = 'negro_';
          await wait(_on(o['dedo']) ? TICK * 4 : TICK * 8);
          if (_on(o['mal'])) {
            cup['v'] = 'azu';
          } else if (_on(o['llena'])) {
            cup['v'] = 'negro';
            cup['vapor'] = 0;
          }
        } else {
          await wait(TICK * 10);
          if (_on(o['mal'])) t['v'] = 'azu';
        }
        _quita(ab, tilt);
        (ab['tiene'] as List).add(up);
        await wait(TICK * 2);
      }();
      return corre(o, pr);
    },
    'prueba35': (o) async {
      for (final id in _js(o['a']).split(',')) {
        final p = G(id)!;
        p['dy'] = -2;
        await wait(TICK * 3);
        p['dy'] = 0;
        await wait(TICK * 3);
        p['dy'] = -2;
        await wait(TICK * 3);
        p['dy'] = 0;
        await wait(TICK * 2);
      }
    },
    // the man looks at his cup (two heaps of sugar) and sets it down at his own place; he is cross and stays so while it
    // stands in front of him
    'empuja35': (o) async {
      final id = '${o['a']}',
          p = G(id)!,
          it = _cup(p),
          t = copa(id)!,
          d = _d(p);
      await wait(TICK * 5);
      p['cara'] = 'mal';
      SFX.bonk();
      await wait(TICK * 6);
      if (it != null) {
        it['vapor'] = 0;
        it['v'] = 'azu';
        t['v'] = 'azu';
        t['vapor'] = 0;
        final x = t['x'] as num, y = t['y'] as num;
        await pon(id, it, t, x, y, 4, (q) {
          q['v'] = 'azu';
          q['vapor'] = 0;
          q['sp'] = 1;
        });
      }
      await wait(TICK * 3);
      {
        final hb = <String, dynamic>{
          'k': 'brazo',
          '_m': 7,
          'gx': 0,
          'gy': 0,
          'sh': 1,
        };
        List<num> hand() =>
            rel(id, (t['x'] as num) - d * 9, (t['y'] as num) - 7);
        final rr = restHand(id);
        (p['tiene'] as List).add(hb);
        final h1 = hand();
        for (var i = 1; i <= 3; i++) {
          hb['gx'] = rr[0] + (h1[0] - rr[0]) * i / 3;
          hb['gy'] = rr[1] + (h1[1] - rr[1]) * i / 3;
          await wait(TICK * 2);
        }
        // the cup slides towards the middle of the table under his hand
        for (var i = 0; i < 4; i++) {
          t['x'] = (t['x'] as num) + d * 3;
          t['y'] = (t['y'] as num) + 2;
          final h = hand();
          hb['gx'] = h[0];
          hb['gy'] = h[1];
          await wait(TICK * 2);
        }
        final h2 = hand();
        for (var i = 1; i <= 3; i++) {
          hb['gx'] = h2[0] + (rr[0] - h2[0]) * i / 3;
          hb['gy'] = h2[1] + (rr[1] - h2[1]) * i / 3;
          await wait(TICK * 2);
        }
        _quita(p, hb);
      }
      await wait(TICK * 3);
    },
    // abuela gives the frog the little pot: she takes the greca from the right end of the table (moves line 1096), carries
    // it to him (moves line 1097) and stops in front of him with it in her hands: "Toma." and his thanks come now
    'pote35': (o) async {
      final ab = G('abuela')!, jt = ob('jarrita')!;
      await ruta('abuela', [
        [FOGON[0], FR],
        [GRECA35[0] + 4, FR],
        [GRECA35[0] + 4, 206],
      ]);
      ab['dir'] = -1;
      final it = await toma('abuela', jt, 6, 22, {'n': 3, 'm': 3});
      it['flip'] = true;
      await ruta('abuela', [
        [GRECA35B[0] - 10, 211],
      ]);
      ab['dir'] = -1;
    },
    // then she sets it down for him, walks back to the stove, and the frog fetches the pot and takes it home
    'pote35b': (o) async {
      final ab = G('abuela')!,
          jt = ob('jarrita')!,
          it = _find(ab['tiene'], (t) => t['k'] == 'jarrita')!;
      await pon('abuela', it, jt, GRECA35B[0], GRECA35B[1], 4);
      await ruta('abuela', [
        [GRECA35B[0], FR],
        [FOGON[0], FR],
        [AFOGON[0], AFOGON[1]],
      ]);
      ab['dir'] = -1;
      await ranaA(GRECA35B[0] - 6, GRECA35B[1] - 6);
      final gi = await ranaToma(jt, -14, 14, {'n': 3, 'm': 3});
      gi['flip'] = true;
      await ranaA(CASA35[0], CASA35[1]);
    },
    // the children set their cups of milk in front of the frog (ponen), walk out (salen), walk in (vuelven), drink
    // (toman), set them down (dejan)
    'ninos35': (o) async {
      final l = G('luis')!,
          ca = G('carmen')!,
          tl = copa('luis')!,
          tc = copa('carmen')!;
      M? cupOf(M p) => _find(p['tiene'], (x) => x['k'] == 'taza');
      // a child with an empty cup walks out and comes back with a fresh cup of milk
      Future<void> fresco(String id, num x, num y) async {
        final p = G(id)!, it = cupOf(p);
        if (it != null && it['v'] == 'vacia') {
          await sale(id);
          it['v'] = 'leche';
          it['vapor'] = 0;
          await entra(id, x, y, 1);
        }
      }

      void milk(M q) {
        q['v'] = 'leche';
        q['vapor'] = 1;
        q['vh'] = 5;
      }

      if (o['que'] == 'ponen') {
        await Future.wait<void>([
          () async {
            await fresco('luis', _at(1104, 60), _at(1104, 178));
            final it = cupOf(l)!;
            await mueveTiene('luis', it, 16, 22, 2);
            await pon('luis', it, tl, K1[0], K1[1], 6, milk);
            await wait(TICK * 3);
          }(),
          () async {
            await wait(TICK * 3);
            await fresco('carmen', _at(1105, 80), _at(1105, 186));
            await mueve('carmen', _at(1105, 82), _at(1105, 186));
            final it = cupOf(ca)!;
            await mueveTiene('carmen', it, 16, 22, 2);
            await pon('carmen', it, tc, K2[0], K2[1], 6, milk);
            await wait(TICK * 3);
          }(),
        ]);
      } else if (o['que'] == 'salen') {
        await Future.wait<void>([
          sale('luis'),
          () async {
            await wait(TICK * 3);
            await sale('carmen');
          }(),
        ]);
      } else if (o['que'] == 'vuelven') {
        await Future.wait<void>([
          entra('luis', _at(1107, 60), _at(1107, 178), 1),
          () async {
            await wait(TICK * 3);
            await entra('carmen', _at(1107, 80), _at(1107, 186), 1);
          }(),
        ]);
      } else if (o['que'] == 'toman') {
        final pr = () async {
          // he keeps the empty cup in his hand
          Future<void> drink(String id, M t) async {
            final it = await toma(id, t, 13, 16, {'n': 3, 'm': 3, 'vapor': 0});
            it['v'] = t['v'];
            it['vapor'] = 0;
            final base = _js(t['v']).replaceFirst(RegExp(r'_$'), '');
            await sorbos(id, it, [mitad(base), 'vacia'], 13, 16);
          }

          await Future.wait<void>([
            drink('luis', tl),
            () async {
              await wait(TICK * 4);
              await drink('carmen', tc);
            }(),
          ]);
        }();
        return corre(o, pr);
      } else if (o['que'] == 'dejan') {
        await Future.wait<void>([
          for (final (i, e) in [('luis', tl, K1), ('carmen', tc, K2)].indexed)
            () async {
              await wait(TICK * 3 * i);
              final it = cupOf(G(e.$1)!);
              if (it == null) return;
              await pon(e.$1, it, e.$2, e.$3[0], e.$3[1], 4, (q) {
                q['v'] = it['v'];
                q['vapor'] = 0;
              });
            }(),
        ]);
      }
    },
    // the frog pours as told from the greca in his hand (moves line 1112: beside the cup on the cloth): a long pour (mucho)
    // turns the milk brown; a splash (poco) turns it pale
    'vierte35': (o) async {
      final id = '${o['a']}',
          t = copa(id)!,
          q = _cq,
          mucho = o['cant'] == 'mucho';
      final izq = (t['x'] as num) < 90;
      final fx = (t['x'] as num) + (izq ? 22 : -8), fy = (t['y'] as num) - 22;
      await ranaA(fx, fy);
      final jt = _find(q['tiene'], (i) => i['k'] == 'jarrita'), up = jt;
      final tilt = vierteItem(
        'rana',
        'jarrita',
        '',
        t['x'] as num,
        (t['y'] as num) - 22,
        !izq,
        12,
        '#3E2414',
      );
      _quita(q, jt);
      (q['tiene'] as List).add(tilt);
      SFX.blip();
      await wait(mucho ? TICK * 4 : TICK * 2);
      liq(id, 'palido', 1);
      if (mucho) {
        await wait(TICK * 10);
        liq(id, 'marron', 1);
        await wait(TICK * 6);
      } else {
        await wait(TICK * 4);
      }
      _quita(q, tilt);
      up!['flip'] = true;
      (q['tiene'] as List).add(up);
      await wait(TICK * 2);
      await ranaA(CASA35[0], CASA35[1]);
    },
    // the frog's own cup, the thoughts and answers of step 6
    'piensa35': (o) async {
      const CO = {'poco': 'palido', 'mucho': 'marron'};
      _cq['piensa'] = jsTruthy(o['k'])
          ? <String, dynamic>{'k': 'taza', 'v': CO[o['k']] ?? o['k'], 'e': 1}
          : null;
      if (jsTruthy(o['k'])) SFX.blip();
      await wait(TICK * 4);
    },
    // abuela pours for the frog: the frog sets the little pot down beside his cup; abuela takes the little pot from beside
    // his cup, pours a stream of coffee from it into his cup, sets it down; then, with her hands empty, she goes for the
    // milk pan (moves line 1124: on the floor in front of the stove's top) and pours the milk (a white stream); one pot at
    // a time
    'sirve6': (o) async {
      final mucho = o['cant'] == 'mucho',
          q = _cq,
          ab = G('abuela')!,
          t = copa('rana')!,
          cz = ob('cazo')!,
          pote = ob('jarrita')!;
      q['piensa'] = null;
      final jt = _find(q['tiene'], (i) => i['k'] == 'jarrita');
      if (jt != null) {
        await ranaA(TRANA[0] + 16, TRANA[1] - 2);
        await ranaPon(jt, pote, TRANA[0] + 16, TRANA[1] + 2, 3);
        await ranaA(CASA35[0], CASA35[1]);
      }
      await ruta('abuela', [
        [FOGON[0], FR],
        [TRANA[0] + 26, FR],
        [TRANA[0] + 26, 190],
      ]);
      ab['dir'] = -1;
      final gr = await toma('abuela', pote, -9, 20, {'n': 3, 'm': 3});
      gr['flip'] = false;
      final pot = await vierteA(
        'abuela',
        'jarrita',
        '',
        t['x'] as num,
        (t['y'] as num) - 24,
        false,
        14,
        '#2A160C',
      );
      _quita(ab, gr);
      (ab['tiene'] as List).add(pot);
      SFX.blip();
      await wait(TICK * 3);
      liq('rana', mucho ? 'negro_' : 'negro_', 1);
      await wait(mucho ? TICK * 8 : TICK * 3);
      liq('rana', 'negro', 1);
      await wait(mucho ? TICK * 3 : TICK * 2);
      _quita(ab, pot);
      (ab['tiene'] as List).add(gr);
      await wait(TICK * 2);
      await pon('abuela', gr, pote, TRANA[0] + 16, TRANA[1] + 2, 3);
      await ruta('abuela', [
        [TRANA[0] + 26, FR],
        [FOGON[0], FR],
        [AFOGON[0], AFOGON[1]],
        [CAZO35[0] - 4, 136],
      ]);
      ab['dir'] = -1;
      final pan = await toma('abuela', cz, 8, 18, {'n': 3, 'm': 3});
      await ruta('abuela', [
        [AFOGON[0], AFOGON[1]],
        [FOGON[0], FR],
        [TRANA[0] + 26, FR],
        [TRANA[0] + 26, 190],
      ]);
      ab['dir'] = -1;
      final mi = await vierteA(
        'abuela',
        'cazo',
        '1',
        t['x'] as num,
        (t['y'] as num) - 24,
        false,
        14,
        '#FBFBF4',
      );
      _quita(ab, pan);
      (ab['tiene'] as List).add(mi);
      SFX.blip();
      await wait(TICK * 4);
      liq('rana', 'marron', 1);
      await wait(mucho ? TICK * 7 : TICK * 3);
      liq('rana', mucho ? 'marron' : 'palido', 1);
      await wait(mucho ? TICK * 3 : TICK * 12);
      _quita(ab, mi);
      (ab['tiene'] as List).add(pan);
      await ruta('abuela', [
        [TRANA[0] + 26, FR],
        [FOGON[0], FR],
        [AFOGON[0], AFOGON[1]],
      ]);
      ab['dir'] = -1;
      await mueve('abuela', CAZO35[0] - 4, 136);
      ab['dir'] = -1;
      await pon('abuela', pan, cz, CAZO35[0], CAZO35[1], 4);
      SFX.blip();
    },
    // the frog drinks his own cup: he takes it in his hand, lifts it, sips (it is half empty), sips again (empty), and sets
    // it down
    'rana35bebe': (o) async {
      final q = _cq, t = copa('rana')!;
      await ranaA(TRANA[0] - 14, TRANA[1] - 2);
      final v = t['v'], it = await ranaToma(t, -4, 14, {'n': 3, 'm': 3});
      it['vapor'] = 0;
      for (final nv in [mitad(v), 'vacia']) {
        await wait(TICK * 2);
        q['hace'] = 'bebe';
        it['ang'] = .35;
        await wait(TICK * 5);
        it['v'] = nv;
        it['ang'] = 0;
        q['hace'] = null;
        await wait(TICK * 4);
      }
      await ranaPon(it, t, TRANA[0], TRANA[1], 3);
      t['v'] = 'vacia';
      t['vapor'] = 0;
      await ranaA(CASA35[0], CASA35[1]);
    },
    // the turn: the cups are empty; abuela pours the last of the big pot (a half cup each for abuelo, papá and herself;
    // moves line 1140: in front of the table's end); she brings the sugar bowl to each man (moves line 1143), who takes a
    // spoon from it himself, sweetens his own half cup and nods; the bowl back (moves line 1155); the last milk into the
    // children's cups (moves line 1158); the pan and the little pot back (moves lines 1163, 1164)
    'turno35': (o) async {
      final ab = G('abuela')!,
          ce = ob('cafetera')!,
          cz = ob('cazo')!,
          tab = copa('abuela')!,
          az = ob('azucarera')!;
      for (final id in const ['abuelo', 'papa', 'rana']) {
        liq(id, 'vacia', 0);
      }
      // each man lays his teaspoon down by his cup
      await Future.wait<void>([
        for (final (i, id) in const ['abuelo', 'papa'].indexed)
          () async {
            await wait(TICK * i * 4);
            if (jsTruthy(copa(id)!['sp'])) await dejaCuchara(id);
          }(),
      ]);
      // with their empty cups
      await Future.wait<void>([
        sale('luis'),
        () async {
          await wait(TICK * 3);
          await sale('carmen');
        }(),
      ]);
      await _act('trae35', {});
      await _act('tienden35', {'a': 'abuelo,papa'});
      for (final id in const ['abuelo', 'papa']) {
        await _act('cafe35', {'a': id, 'dedo': 0, 'llena': 1});
      }
      await _act('bajan35', {'a': 'abuelo,papa'});
      // her own cup, at the right end of the table, from the pot too (she stands in front of the table's end)
      await delante('abuela', 203, 176);
      ab['dir'] = -1;
      {
        final up = _find(ab['tiene'], (x) => x['k'] == 'cafetera'),
            tilt = await vierteA(
              'abuela',
              'cafetera',
              '',
              (tab['x'] as num) + 7,
              (tab['y'] as num) - 24,
              false,
              12,
              '#2A160C',
            );
        _quita(ab, up);
        (ab['tiene'] as List).add(tilt);
        SFX.blip();
        await wait(TICK * 5);
        liq('abuela', 'negro_', 1);
        await wait(TICK * 5);
        liq('abuela', 'negro', 1);
        _quita(ab, tilt);
        (ab['tiene'] as List).add(up);
        await wait(TICK * 2);
      }
      await mueve('abuela', AFOGON[0], AFOGON[1]);
      ab['dir'] = -1;
      {
        final it = _find(ab['tiene'], (x) => x['k'] == 'cafetera')!;
        await pon('abuela', it, ce, CAFE35[0], CAFE35[1], 4);
      }
      _pote['dedo'] = 1;
      // the sugar: she takes the bowl to the men, behind the table; each takes a spoon from it, sweetens his cup, tastes
      // and nods
      await ruta('abuela', [
        [FOGON[0], FR],
        [AZU[0] + 4, FR],
        [AZU[0] + 4, 210],
      ]);
      ab['dir'] = -1;
      final bowl = await toma('abuela', az, 9, 26, {'n': 3, 'm': 3});
      await ruta('abuela', [
        [_at(1144, 196), FR - 8],
      ]);
      await detras('abuela', _at(1144, 128), ATRAS);
      ab['dir'] = -1;
      List<num> bw() => [
        _round(ab['x'] as num) + D1(ab) * (bowl['dx'] as num) + 5,
        _round(ab['y'] as num) - (bowl['dy'] as num) - 8,
      ];
      Future<void> hombre(String id) async {
        final p = G(id)!, t = copa(id)!;
        final b = bw(), r0 = rel(id, b[0], b[1]);
        await manoA(id, r0[0], r0[1], 3);
        bowl['v'] = '0';
        SFX.blip();
        sinManos(id);
        final sp = <String, dynamic>{
          'k': 'uten',
          'ax': r0[0],
          'ay': r0[1],
          'bx': r0[0] + 6,
          'by': r0[1] + 2,
          'load': 'azu',
          'o': <String, dynamic>{'plata': 1, 'rx': 1, 'ry': 1},
        };
        (p['tiene'] as List).add(sp);
        await wait(TICK * 3);
        await cucharaA(id, sp, t['x'] as num, (t['y'] as num) - 14, 5);
        await wait(TICK * 3);
        sp['load'] = '';
        await granosCaen(t['x'] as num, (t['y'] as num) - 2);
        {
          final base = t['v'];
          t['v'] = '${_js(base)}+';
          await wait(TICK * 5);
          t['v'] = base;
        }
        // the big spoon goes back into the bowl, in his hand
        {
          final b2 = bw();
          await cucharaA(id, sp, b2[0] - 3, b2[1] - 8, 4);
        }
        _quita(p, sp);
        bowl['v'] = null;
        SFX.blip();
        final rr = restHand(id);
        await manoA(id, rr[0], rr[1], 3);
        sinManos(id);
        await wait(TICK * 2);
        await _act('tienden35', {'a': id});
        await revuelve(id);
        final it = _cup(p)!;
        await mueveTiene(id, it, 12, bocaY(id, p) - 2, 3);
        await wait(TICK * 4);
        p['dy'] = -2;
        await wait(TICK * 3);
        p['dy'] = 0;
        await wait(TICK * 3);
        p['dy'] = -2;
        await wait(TICK * 3);
        p['dy'] = 0;
        await wait(TICK * 2);
        await _act('bajan35', {'a': id});
      }

      await hombre('abuelo');
      await ruta('abuela', [
        [_at(1153, 176), ATRAS],
      ]);
      ab['dir'] = -1;
      await hombre('papa');
      // the bowl goes back to its place on the table, in front
      await delante('abuela', AZU[0] + 4, 210);
      ab['dir'] = -1;
      await pon('abuela', bowl, az, AZU[0], AZU[1], 4);
      az['tomada'] = 0;
      await Future.wait<void>([
        entra('luis', _at(1156, 60), _at(1156, 178), 1),
        () async {
          await wait(TICK * 3);
          await entra('carmen', _at(1156, 80), _at(1156, 186), 1);
        }(),
      ]);
      await _act('ninos35', {'que': 'dejan'});
      // the milk into the children's cups (they stand there with their hands empty)
      await ruta('abuela', [
        [AZU[0] + 4, FR - 8],
        [FOGON[0], FR],
        [AFOGON[0], AFOGON[1]],
      ]);
      ab['dir'] = -1;
      await mueve('abuela', CAZO35[0] - 4, 136);
      ab['dir'] = -1;
      await toma('abuela', cz, 8, 18, {'n': 3, 'm': 3});
      await ruta('abuela', [
        [FOGON[0], FR],
        [_at(1159, 130), FR],
      ]);
      ab['dir'] = -1;
      for (final (id, cup) in [('carmen', K2), ('luis', K1)]) {
        final pn = _find(ab['tiene'], (x) => x['k'] == 'cazo');
        ab['dir'] = -1;
        final mi = await vierteA(
          'abuela',
          'cazo',
          '1',
          cup[0],
          cup[1] - 24,
          false,
          14,
          '#FBFBF4',
        );
        _quita(ab, pn);
        (ab['tiene'] as List).add(mi);
        SFX.blip();
        await wait(TICK * 4);
        liq(id, 'leche', 1);
        await wait(TICK * 5);
        _quita(ab, mi);
        (ab['tiene'] as List).add(pn);
        await wait(TICK * 2);
      }
      _pote['leche'] = 1;
      // the pan goes back on the stove, the little pot, full, goes back to the right end of the table
      await ruta('abuela', [
        [FOGON[0], FR],
        [AFOGON[0], AFOGON[1]],
      ]);
      ab['dir'] = -1;
      {
        final pn = _find(ab['tiene'], (x) => x['k'] == 'cazo')!;
        await mueve('abuela', CAZO35[0] - 4, 136);
        ab['dir'] = -1;
        await pon('abuela', pn, cz, CAZO35[0], CAZO35[1], 4);
        cz['v'] = '1';
      }
      await ruta('abuela', [
        [FOGON[0], FR],
        [TRANA[0] + 26, FR],
        [TRANA[0] + 26, 190],
      ]);
      ab['dir'] = -1;
      {
        final jp = ob('jarrita')!;
        if (jp['vis'] != 0 &&
            (jp['x'] as num) > 140 &&
            (jp['x'] as num) < 190) {
          final it = await toma('abuela', jp, 6, 22, {'n': 3, 'm': 3});
          it['flip'] = true;
          await ruta('abuela', [
            [GRECA35[0] + 4, 206],
          ]);
          await pon('abuela', it, jp, GRECA35[0], GRECA35[1] + 4, 4);
        }
      }
      await mueve('luis', _at(1165, 60), _at(1165, 178));
      await mueve('carmen', _at(1165, 80), _at(1165, 186));
    },
    // she takes her own cup (from the table's end, or from the stool where it stands while she is up; moves line 1169),
    // walks to her stool and sits down with it
    'sientaAb35': (o) async {
      final ab = G('abuela')!,
          t = copa('abuela')!,
          enBanco = ((t['x'] as num) - STOOL[0]).abs() < 4;
      if (!((ab['tiene'] as List?) ?? const []).any(
        (x) => (x as Map)['k'] == 'taza',
      )) {
        if (enBanco) {
          await ruta('abuela', [
            [STOOL[0] - 16, STOOL[1] + 8],
          ]);
          ab['dir'] = 1;
        } else {
          await ruta('abuela', [
            [TABU[0] + 12, FR - 8],
            [TABU[0] + 12, 178],
          ]);
          ab['dir'] = -1;
        }
        final it = await toma('abuela', t, enBanco ? -8 : 8, 22, {
          'n': 3,
          'm': 3,
          'vapor': 0,
        });
        it['v'] = t['v'];
        it['vapor'] = 0;
      }
      await ruta('abuela', [
        [STOOL[0] - 8, STOOL[1] + 10],
        [STOOL[0], STOOL[1] + 8],
      ]);
      ab['dir'] = -1;
      {
        final it = _find(ab['tiene'], (x) => x['k'] == 'taza')!;
        await mueveTiene('abuela', it, 15, 18, 2);
      }
      ab['sent'] = 1;
      ab['taburete'] = 1;
      ab['y'] = STOOL[1] - 4;
      ab['x'] = STOOL[0];
      SFX.blip();
      await wait(TICK * 3);
    },
    // she gets up, sets her cup on the stool beside her (it stays with her), and goes for the pot
    'levantaAb35': (o) async {
      final ab = G('abuela')!,
          t = copa('abuela')!,
          cup = _find(ab['tiene'], (x) => x['k'] == 'taza');
      ab['sent'] = 0;
      ab['taburete'] = 0;
      ab['y'] = STOOL[1] + 4;
      ab['x'] = STOOL[0] - 14;
      ab['dir'] = -1;
      SFX.blip();
      await wait(TICK * 3);
      if (cup != null) {
        ab['dir'] = 1;
        await pon('abuela', cup, t, STOOL[0], STOOL[1] - 11, 4, (q) {
          q['v'] = cup['v'];
          q['vapor'] = 0;
          q['vis'] = 1;
        });
        ab['dir'] = -1;
      }
      await wait(TICK * 2);
    },
    // round A: abuela gets up from her stool and takes the big pot with its last pour; the men hold their half cups out,
    // looking at her (moves line 1178: on the lane and the row there, SY)
    'turnoA35': (o) async {
      final ab = G('abuela')!, ce = ob('cafetera')!;
      await _act('levantaAb35', {});
      await ruta('abuela', [
        [AFOGON[0], AFOGON[1] + 8],
        [AFOGON[0], AFOGON[1]],
      ]);
      ab['dir'] = -1;
      await toma('abuela', ce, 9, 20, {'n': 3, 'm': 3, 'vapor': 0});
      await detras('abuela', 150, SY(150, ATRAS));
      await mueve('abuela', 126, SY(126, ASIENTO - 2));
      ab['dir'] = -1;
      await _act('tienden35', {'a': 'abuelo,papa'});
      await _act('llena35', {});
    },
    // after A: abuela puts the empty big pot on the stove, takes the little pot from the right end of the table (moves line
    // 1182) and sets it by the frog's cup (moves line 1183); he stands it by his small cup; she goes back to her cup and
    // sits
    'despuesA35': (o) async {
      final ab = G('abuela')!, jt = ob('jarrita')!, ce = ob('cafetera')!;
      await _act('bajan35', {'a': 'abuelo,papa'});
      ce['v'] = '';
      await _act('vuelve35', {});
      await ruta('abuela', [
        [FOGON[0], FR],
        [GRECA35[0] + 4, FR],
        [GRECA35[0] + 4, 206],
      ]);
      ab['dir'] = -1;
      final it = await toma('abuela', jt, 6, 22, {'n': 3, 'm': 3});
      it['flip'] = true;
      await ruta('abuela', [
        [TRANA[0] + 26, 190],
      ]);
      ab['dir'] = -1;
      await pon('abuela', it, jt, TRANA[0] + 16, TRANA[1] + 2, 4);
      await _act('sientaAb35', {});
    },
    // abuela asks the frog: she gets up, takes the little pot from beside his cup and holds it out to him, looking at him
    // (moves line 1187)
    'pregunta35': (o) async {
      final ab = G('abuela')!, jt = ob('jarrita')!;
      await _act('levantaAb35', {});
      await ruta('abuela', [
        [STOOL[0] - 16, FR - 8],
        [TRANA[0] + 26, FR - 8],
        [TRANA[0] + 26, 190],
      ]);
      ab['dir'] = -1;
      final gr = await toma('abuela', jt, -9, 22, {'n': 3, 'm': 3});
      gr['flip'] = false;
      await wait(TICK * 3);
    },
    // round B: abuela pours from the little pot what he said into his cup, tips what is left of it into her own cup (on her
    // stool), fills his cup to the brim with milk from the pan (moves lines 1195 to 1197: the pan from the floor in front
    // of the stove's top); whatever is left in the pan she tips into Canelo's bowl, and Canelo gets up, laps it and lies
    // down again (moves line 1204)
    'sirveB35': (o) async {
      final ab = G('abuela')!,
          mucho = _js(o['cant']).replaceFirst(RegExp(r'^di_'), '') == 'mucho',
          cz = ob('cazo')!,
          tz = ob('tazon')!,
          pe = W['perro'] as M,
          t = copa('rana')!,
          ta = copa('abuela')!,
          q = _cq;
      q['piensa'] = null;
      // after a miss the same act comes round again with the right answer: everything is poured already
      if (jsTruthy(W['pote']) && jsTruthy(_pote['pan'])) return;
      final gr = _find(ab['tiene'], (x) => x['k'] == 'jarrita');
      ab['dir'] = -1;
      final pot = await vierteA(
        'abuela',
        'jarrita',
        '',
        t['x'] as num,
        (t['y'] as num) - 24,
        false,
        14,
        '#2A160C',
      );
      _quita(ab, gr);
      (ab['tiene'] as List).add(pot);
      SFX.blip();
      await wait(TICK * 3);
      liq('rana', 'negro_', 1);
      await wait(mucho ? TICK * 8 : TICK * 3);
      liq('rana', 'negro', 1);
      await wait(mucho ? TICK * 3 : TICK * 2);
      _quita(ab, pot);
      (ab['tiene'] as List).add(gr);
      await wait(TICK * 2);
      // what is left of the little pot goes into her own cup, which stands on her stool
      await ruta('abuela', [
        [TRANA[0] + 26, FR - 8],
        [STOOL[0] - 18, FR - 8],
        [STOOL[0] - 18, STOOL[1] + 8],
      ]);
      ab['dir'] = 1;
      {
        final pot2 = await vierteA(
          'abuela',
          'jarrita',
          '',
          ta['x'] as num,
          (ta['y'] as num) - 24,
          true,
          14,
          '#2A160C',
          [STOOL[1] + 8, STOOL[1] + 12],
        );
        _quita(ab, gr);
        (ab['tiene'] as List).add(pot2);
        SFX.blip();
        await wait(TICK * 4);
        ta['v'] = 'negro_';
        await wait(TICK * 4);
        ta['v'] = 'negro';
        _quita(ab, pot2);
        (ab['tiene'] as List).add(gr);
        await wait(TICK * 2);
      }
      await ruta('abuela', [
        [STOOL[0] - 18, FR - 8],
        [GRECA35[0] + 4, FR - 8],
        [GRECA35[0] + 4, 206],
      ]);
      ab['dir'] = -1;
      {
        final jt = ob('jarrita')!;
        await pon('abuela', gr!, jt, GRECA35[0], GRECA35[1] + 4, 4);
      }
      await ruta('abuela', [
        [GRECA35[0] + 4, FR],
        [FOGON[0], FR],
        [AFOGON[0], AFOGON[1]],
        [CAZO35[0] - 4, 136],
      ]);
      ab['dir'] = -1;
      final pan = await toma('abuela', cz, 8, 18, {'n': 3, 'm': 3});
      await ruta('abuela', [
        [AFOGON[0], AFOGON[1]],
        [FOGON[0], FR],
        [TRANA[0] + 26, FR],
        [TRANA[0] + 26, 190],
      ]);
      ab['dir'] = -1;
      {
        final mi = await vierteA(
          'abuela',
          'cazo',
          '1',
          t['x'] as num,
          (t['y'] as num) - 24,
          false,
          14,
          '#FBFBF4',
        );
        _quita(ab, pan);
        (ab['tiene'] as List).add(mi);
        SFX.blip();
        await wait(TICK * 4);
        liq('rana', mucho ? 'marron' : 'palido', 1);
        await wait(mucho ? TICK * 7 : TICK * 14);
        _quita(ab, mi);
        (ab['tiene'] as List).add(pan);
        await wait(TICK * 2);
      }
      // the rest of the milk into Canelo's bowl, and Canelo gets up, laps for a while and lies down again
      await ruta('abuela', [
        [TAZON[0] + 18, FR],
      ]);
      ab['dir'] = -1;
      {
        final mi2 = await vierteA(
          'abuela',
          'cazo',
          '1',
          TAZON[0],
          TAZON[1] - 26,
          false,
          18,
          '#FBFBF4',
        );
        _quita(ab, pan);
        (ab['tiene'] as List).add(mi2);
        SFX.blip();
        await wait(TICK * 7);
        tz['v'] = '1';
        _quita(ab, mi2);
        pan['v'] = '0';
        (ab['tiene'] as List).add(pan);
      }
      // he gets up over several frames (lying, sitting, standing, walking) and walks to the bowl
      pe['pose'] = 'sit';
      await wait(TICK * 7);
      pe['pose'] = 'walk';
      pe['dir'] = 1;
      await wait(TICK * 3);
      while ((pe['x'] as num) < TAZON[0] - 20) {
        pe['x'] = math.min(TAZON[0] - 20, (pe['x'] as num) + 3);
        await wait(TICK);
      }
      pe['pose'] = 'husmea';
      for (final nv in const ['1', '2', '0']) {
        pe['lengua'] = 1;
        await wait(TICK * 3);
        pe['lengua'] = 0;
        await wait(TICK * 2);
        tz['v'] = nv;
        await wait(TICK * 2);
      }
      pe['pose'] = 'walk';
      pe['dir'] = -1;
      while ((pe['x'] as num) > CANELO[0]) {
        pe['x'] = math.max(CANELO[0], (pe['x'] as num) - 3);
        await wait(TICK);
      }
      pe['dir'] = 1;
      pe['pose'] = 'sit';
      await wait(TICK * 4);
      pe['pose'] = 'lie';
      pe['x'] = CANELO[0];
      pe['y'] = CANELO[1];
      await wait(TICK * 2);
      await ruta('abuela', [
        [FOGON[0], FR],
        [AFOGON[0], AFOGON[1]],
      ]);
      ab['dir'] = -1;
      await mueve('abuela', CAZO35[0] - 4, 136);
      ab['dir'] = -1;
      await pon('abuela', pan, cz, CAZO35[0], CAZO35[1], 4);
      cz['v'] = '0';
      _pote['vacia'] = 1;
      _pote['pan'] = 1;
    },
    // the frog tastes his cup once: he takes it, lifts it, tips it, makes a plain sour face (a big one) and puts the cup
    // down by him, full to the brim and the wrong colour; the face stays sour while it stands there
    'pruebaB35': (o) async {
      final q = _cq, t = copa('rana')!;
      await ranaA(TRANA[0] - 14, TRANA[1] - 2);
      final it = await ranaToma(t, -4, 14, {'n': 3, 'm': 3});
      it['vapor'] = 0;
      await wait(TICK * 2);
      q['hace'] = 'come';
      it['ang'] = .35;
      await wait(TICK * 7);
      q['hace'] = null;
      it['ang'] = 0;
      q['mal'] = 1;
      SFX.bonk();
      await wait(TICK * 5);
      await ranaPon(it, t, TRANA[0], TRANA[1], 3);
      await wait(TICK * 3);
      await ranaA(CASA35[0], CASA35[1]);
    },
    // after a miss in B: abuela takes her own cup off her stool and drinks it off in view (sip after sip), a big pleased
    // "ah", a hand on her chest; then she holds the empty cup up
    'bebeAb35': (o) async {
      final ab = G('abuela')!, t = copa('abuela')!, q = _cq;
      q['mal'] = 0;
      await ruta('abuela', [
        [STOOL[0] - 18, FR - 8],
        [STOOL[0] - 18, STOOL[1] + 8],
      ]);
      ab['dir'] = 1;
      final it = await toma('abuela', t, -8, 22, {'n': 3, 'm': 3, 'vapor': 0});
      it['v'] = 'negro';
      it['vapor'] = 0;
      await mueveTiene('abuela', it, 12, 20, 3);
      await sorbos('abuela', it, const ['negro_', 'vacia'], 12, 20);
      ab['abre'] = 1;
      ab['pose'] = 'bless';
      SFX.blip();
      await wait(TICK * 8);
      ab['abre'] = 0;
      await wait(TICK * 3);
      ab['pose'] = 'idle';
      await mueveTiene('abuela', it, 10, 34, 3);
      await wait(TICK * 8);
    },
    // she shows what is empty: the cup she holds up, then the little pot (moves line 1216: from the first row in front of
    // the table's foot, FRONTROW) and the pan (moves line 1217) (she walks to each, takes it, tips it towards us for a
    // moment), and sets each back
    'muestra35': (o) async {
      final ab = G('abuela')!, k = o['k'];
      final cup = _find(ab['tiene'], (x) => x['k'] == 'taza');
      if (k == 'taza') {
        if (cup != null) {
          ab['dir'] = 1;
          await mueveTiene('abuela', cup, 12, 38, 3);
          await wait(TICK * 8);
        }
        return;
      }
      if (cup != null) {
        final t = copa('abuela')!;
        ab['dir'] = 1;
        await pon('abuela', cup, t, STOOL[0], STOOL[1] - 11, 4, (q) {
          q['v'] = 'vacia';
          q['vapor'] = 0;
          q['vis'] = 1;
        });
      }
      Future<void> mostrar(M ob_, num x, num y, [Object? v]) async {
        await ruta('abuela', [
          [x - 4, FR - 8],
          [x - 4, y],
        ]);
        ab['dir'] = -1;
        final it = await toma('abuela', ob_, -9, 22, {'n': 3, 'm': 3});
        it['flip'] = false;
        if (v != null) it['v'] = v;
        await mueveTiene('abuela', it, -4, 34, 3);
        it['ang'] = -.8;
        await wait(TICK * 10);
        it['ang'] = 0;
        await mueveTiene('abuela', it, -9, 22, 3);
        await pon('abuela', it, ob_, ob_['x'] as num, ob_['y'] as num, 3);
      }

      if (k == 'jarrita') {
        final jt = ob('jarrita')!;
        await mostrar(jt, (jt['x'] as num) + 4, FRONTROW(jt['x'] as num, 190));
      } else {
        final cz = ob('cazo')!;
        await ruta('abuela', [
          [FOGON[0], FR],
          [AFOGON[0], AFOGON[1]],
          [CAZO35[0] - 4, 136],
        ]);
        ab['dir'] = -1;
        final it = await toma('abuela', cz, 8, 18, {'n': 3, 'm': 3});
        it['v'] = '0';
        await mueveTiene('abuela', it, -2, 32, 3);
        it['ang'] = -.8;
        await wait(TICK * 10);
        it['ang'] = 0;
        await mueveTiene('abuela', it, 8, 18, 3);
        await pon('abuela', it, cz, CAZO35[0], CAZO35[1], 4);
        cz['v'] = '0';
      }
    },
    // the ending: everybody drinks (they lift their cups, sip, set them down); a spoiled cup stands in front of its owner;
    // abuela drinks at her stool
    'final35': (o) async {
      final ab = G('abuela')!;
      // after a miss in B she has been walking about: she sits down on her stool with her cup
      if (!jsTruthy(ab['sent'])) await _act('sientaAb35', {});
      await Future.wait<void>([
        if (G('luis')!['vis'] == 0) ...[
          entra('luis', _at(1220, 60), _at(1220, 178), 1),
          () async {
            await wait(TICK * 3);
            await entra('carmen', _at(1220, 80), _at(1220, 186), 1);
          }(),
        ],
      ]);
      final ninos = _later(_act('ninos35', {'que': 'toman'}));
      final men = _later(
        Future.wait<void>([
          for (final id in const ['abuelo', 'papa'])
            () async {
              final t = copa(id)!;
              if (t['v'] == 'azu' || t['vis'] == 0) return;
              final it = await toma(id, t, 13, 16, {
                'n': 3,
                'm': 3,
                'vapor': 0,
              });
              it['v'] = t['v'];
              it['vapor'] = 0;
              if (jsTruthy(t['sp'])) {
                it['sp'] = 1;
                it['k'] = 'tazacu';
              }
              await sorbos(id, it, [mitad(t['v']), 'vacia'], 13, 16);
              await pon(id, it, t, t['x'] as num, t['y'] as num, 3, (q) {
                q['v'] = 'vacia';
                q['vapor'] = 0;
                q['sp'] = 1;
              });
            }(),
        ]),
      );
      final cup = _find(ab['tiene'], (x) => x['k'] == 'taza');
      V['cafe'] = cup != null
          ? (cup['v'] != 'vacia' ? '1' : '')
          : (copa('abuela')!['v'] != 'vacia' ? '1' : '');
      if (jsTruthy(ab['sent']) && cup != null && jsTruthy(V['cafe'])) {
        await wait(TICK * 6);
        await sorbos('abuela', cup, [mitad(cup['v']), 'vacia'], 15, 18);
      }
      await men;
      await ninos;
      _cq['hace'] = null;
      await wait(TICK * 6);
    },
  };
}
