// El cuarto's story 96-98 acts (part of cuarto.dart).
part of 'cuarto.dart';

extension _CuartoActs on Cuarto {
  Future<void> _run(Map<String, dynamic> o, Future<void> Function() body) {
    if (jsTruthy(o['suelto'])) {
      final f = body();
      _loose.add(f);
      return Future<void>.value();
    }
    return body();
  }

  /* ---------- acts (cuarto.md "Needs" + gen_cuarto.py) ---------- */

  Map<String, Act> _buildOwnActs() => {
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
      final rawSpot = (o['a'] as String?) ?? 'alfombra';
      // OPEN: 98 start (`ir alfombra`): gen_cuarto.py names `alfombra` (49,136), which is 20 px from `vestir`
      // (68,131); cuarto-sheet.json defines `alfombra2` (97,139) "for story 98" so `sprites-apart` holds (29 px).
      final spot = (_n(W['story']) == 98 && rawSpot == 'alfombra')
          ? 'alfombra2'
          : rawSpot;
      W['coquiDuerme'] = 0;
      if (spot == 'almohada_suelo') {
        // OPEN: 96 step 3 (`ir almohada_suelo`): frog hops onto pillow, bounces on it, and lands at `mesita_coqui`
        // so `almohada` stays clear (things-clear, matching cuarto-preview.html moment 2).
        await _hopToSpot('almohada_suelo');
        final q = W['cq'] as Map<String, dynamic>;
        for (final dy in const [-5, 0, -4, 0]) {
          q['dy'] = dy;
          await wait(60);
        }
        await _hopToSpot('mesita_coqui');
      } else {
        await _hopToSpot(spot);
      }
    }),
    'llega': (o) => _run(o, () async {
      final quien = (o['quien'] as String?) ?? '';
      final a = (o['a'] as String?) ?? '';
      if (quien == 'perro') {
        W['perroVis'] = 1;
        W['perroSpot'] = _p.has(a) ? a : 'bajo_cama';
        W['perroPose'] = a == 'bajo_cama' ? 'nariz' : 'sit';
        await wait(140);
        return;
      }
      final p = _gente[quien] as Map<String, dynamic>?;
      if (p == null || !_p.has(a)) return;
      final is96 = _n(W['story']) == 96;
      if (quien == 'abuela') {
        W['abuelaSilencio'] = 0;
        W['abuelaFoto'] = a == 'foto' ? 1 : 0;
        W['abuelaFotoUp'] = 0;
        _placePerson(p, a, sent: 0, dormido: false);
      } else if (quien == 'abuelo') {
        final inChair = a == 'butaca_abuelo';
        W['mantaAbueloVis'] = inChair ? 1 : 0;
        _placePerson(p, a, sent: inChair ? 1 : 0, dormido: inChair);
      } else if (quien == 'luis') {
        if (a == 'cama_luis') {
          W['mantaLuisVis'] = 1;
          _placePerson(p, a, sent: 0, dormido: true);
        } else if (a == 'sentado_luis') {
          W['mantaLuisVis'] = 1;
          _placePerson(p, a, sent: 0, dormido: is96);
        } else {
          if (a == 'pie_luis') W['mantaLuisVis'] = 0;
          _placePerson(p, a, sent: 0, dormido: false);
        }
      } else if (quien == 'carmen') {
        W['carmenPies'] = 0;
        if (a == 'cama_carmen') {
          W['mantaCarmenVis'] = 1;
          _placePerson(p, a, sent: 0, dormido: true);
        } else if (a == 'sentado_carmen') {
          W['mantaCarmenVis'] = 1;
          _placePerson(p, a, sent: 0, dormido: false);
        } else {
          W['mantaCarmenVis'] = 0;
          _placePerson(p, a, sent: 0, dormido: false);
        }
      }
      await wait(160);
    }),
    'sale': (o) => _run(o, () async {
      final quien = (o['quien'] as String?) ?? '';
      if (quien == 'perro') {
        W['perroVis'] = 0;
        await wait(120);
        return;
      }
      final p = _gente[quien] as Map<String, dynamic>?;
      if (p != null) {
        p['vis'] = 0;
        if (quien == 'abuela') {
          W['abuelaSilencio'] = 0;
          W['abuelaFotoUp'] = 0;
        }
      }
      await wait(120);
    }),
    'gesto': (o) => _run(o, () async {
      final quien = (o['quien'] as String?) ?? 'abuela';
      final que = (o['que'] as String?) ?? 'saluda';
      final target = o['a'] as String?;
      if (quien == 'coqui') {
        final q = W['cq'] as Map<String, dynamic>;
        for (final dy in const [-2, 0, -2, 0]) {
          q['dy'] = dy;
          await wait(65);
        }
        q['dy'] = 0;
        return;
      }
      final p = _gente[quien] as Map<String, dynamic>?;
      if (p == null) return;
      if (que == 'saluda') {
        for (var i = 0; i < 4; i++) {
          p['pose'] = i.isEven ? 'saluda0' : 'saluda1';
          await wait(80);
        }
        p['pose'] = 'idle';
      } else if (que == 'no') {
        for (final dx in const [-1, 1, -1, 0]) {
          p['dx'] = dx;
          await wait(65);
        }
        p['dx'] = 0;
      } else if (que == 'si') {
        for (final dy in const [1, 0, 1, 0]) {
          p['dy'] = dy;
          await wait(65);
        }
        p['dy'] = 0;
      } else if (que == 'silencio') {
        W['abuelaSilencio'] = 1;
        await wait(240);
        W['abuelaSilencio'] = 0;
      } else if (que == 'pies') {
        W['carmenPies'] = 1;
        await wait(240);
        W['carmenPies'] = 0;
      } else if (que == 'palpa') {
        p['pose'] = 'palpa';
        for (final dx in const [-1, 1, -1, 0]) {
          p['dx'] = dx;
          await wait(65);
        }
        p['dx'] = 0;
        p['pose'] = 'idle';
      } else if (que == 'bosteza') {
        for (final dy in const [-1, 0]) {
          p['dy'] = dy;
          await wait(110);
        }
        p['dy'] = 0;
      } else if (que == 'puntillas') {
        for (final dy in const [-1, 0, -1, 0]) {
          p['dy'] = dy;
          await wait(60);
        }
        p['dy'] = 0;
      } else if (que == 'senala' || que == 'mira') {
        final spkAt = _atOf(p);
        final spkX = _round(spkAt.sx);
        final tgt = _targetScreen(target, W);
        final isSelf = target == quien;
        final rawDir = tgt != null ? (tgt.sx - spkX).sign : 1;
        final dir = isSelf ? 0 : (rawDir == 0 ? 1 : rawDir);
        if (que == 'senala') {
          p['pose'] = isSelf ? 'yo' : (dir < 0 ? 'senala_izq' : 'senala_der');
        }
        if (tgt != null && que == 'senala') {
          W['gestoCue'] = <String, dynamic>{
            'kind': 'senala',
            'quien': quien,
            'a': target,
            'self': isSelf,
            'dir': dir,
            'cueX': tgt.cueX,
            'cueY': tgt.cueY,
            'up': tgt.up,
            'd': tgt.d,
          };
        }
        p['dx'] = que == 'mira' ? dir : 0;
        await wait(220);
        p['pose'] = 'idle';
        p['dx'] = 0;
        W['gestoCue'] = null;
      } else {
        // rie
        p['pose'] = que;
        for (final dy in const [-1, 0, -1, 0]) {
          p['dy'] = dy;
          await wait(60);
        }
        p['dy'] = 0;
        p['pose'] = 'idle';
      }
    }),

    /* ---------- Story 96 acts ---------- */
    'plato96': (o) => _run(o, () async {
      W['platoVis'] = 1;
      W['plato'] = _n(o['n']).clamp(0, 3);
      await wait(120);
    }),
    'luz96': (o) => _run(o, () async {
      W['luz'] = jsTruthy(o['on']) ? 1 : 0;
      await wait(160);
    }),
    'almohada96': (o) => _run(o, () async {
      W['almohadaPos'] = 'almohada_suelo';
      W['almohadaVis'] = 1;
      await wait(220);
    }),
    'busca96': (o) => _run(o, () async {
      final donde = (o['donde'] as String?) ?? 'cama';
      final que = (o['que'] as String?) ?? 'camisa';
      final ok = _n(o['ok']) == 1;
      final spot = 'busca_$donde';
      await _hopToSpot(_p.has(spot) ? spot : 'busca_cama');
      if (ok) {
        // OPEN: `busca96` found item shown at (54, 116) beside Luis's bed; if `camisa`, Luis also gets it on.
        W['found96'] = que;
        if (que == 'camisa') W['luisCamisa96'] = 1;
        await wait(220);
      } else {
        final q = W['cq'] as Map<String, dynamic>;
        for (final dx in const [-2, 2, -2, 0]) {
          q['dx'] = dx;
          await wait(55);
        }
        q['dx'] = 0;
        W['perroPose'] = 'lick';
        await wait(160);
        W['perroPose'] = 'sit';
      }
    }),
    'final96': (o) => _run(o, () async {
      final n = _n(o['n']).clamp(1, 3);
      // OPEN: `final96` clears temporary found item, keeps Luis at `sentado_luis` with his shirt,
      // frog hops to `mesita_coqui` (clear of plate and Canelo); n==1 sets Canelo licking his nose; n==3 celebrates.
      W['found96'] = null;
      W['luisCamisa96'] = 1;
      final luis = _gente['luis'] as Map<String, dynamic>;
      W['mantaLuisVis'] = 1;
      _placePerson(luis, 'sentado_luis', sent: 0, dormido: false);
      await _hopToSpot('mesita_coqui');
      W['platoVis'] = 1;
      W['plato'] = n == 2 ? 0 : (n == 3 ? 1 : 1);
      W['perroPose'] = n == 1 ? 'lick' : 'sit';
      W['finalCelebrar'] = n == 3 ? 1 : 0;
      await wait(260);
    }),
    'duerme96': (o) => _run(o, () async {
      // OPEN: `duerme96` puts sleeping frog at `busca_almohada` so `frog-seen` & `things-clear` hold.
      await _hopToSpot('busca_almohada');
      W['coquiDuerme'] = 1;
      await wait(220);
    }),

    /* ---------- Story 97 acts ---------- */
    'reloj97': (o) => _run(o, () async {
      final h = o['hora'];
      W['relojHora'] = h is num ? h.toDouble() : 7.0;
      await wait(120);
    }),
    'zetas': (o) => _run(o, () async {
      final n = _n(o['n']).clamp(0, 3);
      W['zetas'] = n;
      W['bebeState'] = n >= 3 ? 'sleep' : (n == 2 ? 'stir' : 'awake');
      await wait(140);
    }),
    'campana97': (o) => _run(o, () async {
      final quien = (o['quien'] as String?) ?? 'luis';
      final ok = _n(o['ok']) == 1;
      W['tinkleFx'] = 1;
      final q = W['cq'] as Map<String, dynamic>;
      q['dy'] = -2;
      await wait(100);
      q['dy'] = 0;
      final p = _gente[quien] as Map<String, dynamic>?;
      if (p != null) {
        if (quien == 'carmen') {
          W['mantaCarmenVis'] = 1;
          _placePerson(p, 'sentado_carmen', sent: 0, dormido: false);
        } else if (quien == 'luis') {
          if (p['spot'] != 'pie_luis') {
            W['mantaLuisVis'] = 1;
            _placePerson(p, 'sentado_luis', sent: 0, dormido: false);
          } else {
            p['dormido'] = 0;
          }
        } else if (quien == 'abuelo') {
          if (p['spot'] != 'pie_abuelo') {
            p['dormido'] = 0;
          } else {
            p['dormido'] = 0;
          }
        }
      }
      await wait(260);
      W['tinkleFx'] = 0;
      if (!ok && p != null) {
        for (final dx in const [-1, 1, -1, 0]) {
          p['dx'] = dx;
          await wait(55);
        }
        p['dx'] = 0;
      }
    }),
    'manta97': (o) => _run(o, () async {
      final quien = (o['quien'] as String?) ?? 'luis';
      final ok = _n(o['ok']) == 1;
      final q = W['cq'] as Map<String, dynamic>;
      for (final dx in const [-2, 2, 0]) {
        q['dx'] = dx;
        await wait(50);
      }
      q['dx'] = 0;
      final p = _gente[quien] as Map<String, dynamic>?;
      if (p != null) {
        if (quien == 'carmen') {
          W['mantaCarmenVis'] = 0;
          _placePerson(p, 'pie_carmen', sent: 0, dormido: false);
        } else if (quien == 'luis') {
          W['mantaLuisVis'] = 0;
          _placePerson(p, 'pie_luis', sent: 0, dormido: false);
        } else if (quien == 'abuelo') {
          W['mantaAbueloVis'] = 0;
          _placePerson(p, 'pie_abuelo', sent: 0, dormido: false);
        }
      }
      if (!ok && p != null) {
        W['gritoFx'] = 1;
        for (final dx in const [-1, 1, -1, 1, 0]) {
          p['dx'] = dx;
          await wait(55);
        }
        p['dx'] = 0;
        W['gritoFx'] = 0;
      } else {
        await wait(210);
      }
    }),
    'corre97': (o) => _run(o, () async {
      // OPEN: `corre97`: Luis runs from his spot toward the right door area (u=2.4, v=4.5 -> 182,125, clear of
      // `bebe`, `pie_carmen`, `puerta`, and `silla`), pauses on "¡Despacio, Luis!", and tiptoes.
      final luis = _gente['luis'] as Map<String, dynamic>;
      W['mantaLuisVis'] = 0;
      luis['dormido'] = 0;
      luis['spot'] = 'pie_luis';
      final start = _p.at('pie_luis');
      final dest = _p.e.R2;
      final targetU = 2.4, targetV = 4.5;
      final destX = (targetU + targetV) / dest;
      final destY = (targetV - targetU) / dest;
      for (var i = 1; i <= 4; i++) {
        final t = i / 4;
        luis['x'] = start.x + (destX - start.x) * t;
        luis['y'] = start.y + (destY - start.y) * t;
        luis['z'] = 0.0;
        luis['dy'] = i.isOdd ? -2 : 0;
        await wait(65);
      }
      luis['dy'] = 0;
      await wait(140);
      // Tiptoe gently in place
      for (final dy in const [-1, 0, -1, 0]) {
        luis['dy'] = dy;
        await wait(60);
      }
      luis['dy'] = 0;
    }),
    'final97': (o) => _run(o, () async {
      // OPEN: `final97`: puts everyone standing at `pie_*` (`cuarto-preview.html` moment 5), sets baby state by n,
      // and celebrates when n==3.
      final n = _n(o['n']).clamp(1, 3);
      W['mantaLuisVis'] = 0;
      W['mantaCarmenVis'] = 0;
      W['mantaAbueloVis'] = 0;
      _placePerson(
        _gente['luis'] as Map<String, dynamic>,
        'pie_luis',
        sent: 0,
        dormido: false,
      );
      _placePerson(
        _gente['carmen'] as Map<String, dynamic>,
        'pie_carmen',
        sent: 0,
        dormido: false,
      );
      _placePerson(
        _gente['abuelo'] as Map<String, dynamic>,
        'pie_abuelo',
        sent: 0,
        dormido: false,
      );
      W['zetas'] = n;
      W['bebeState'] = n >= 3 ? 'sleep' : (n == 2 ? 'stir' : 'awake');
      W['finalCelebrar'] = n == 3 ? 1 : 0;
      await wait(260);
    }),

    /* ---------- Story 98 acts ---------- */
    'pelo98': (o) => _run(o, () async {
      W['pelo98'] = _n(o['n']).clamp(1, 3);
      await wait(100);
    }),
    'silla98': (o) => _run(o, () async {
      final a = o['a'] as String?;
      final b = o['b'] as String?;
      W['sillaA'] = a;
      W['sillaB'] = b;
      // Step 4 puts camisa & zapatos on the chair: Luis takes his shoes off and waits in his socks.
      if (a == 'camisa' && b == 'zapatos') {
        W['luisShoes'] = 0;
      }
      await wait(120);
    }),
    'zapatos98': (o) => _run(o, () async {
      W['luisShoes'] = 1;
      W['luisTumbled'] = 1;
      final luis = _gente['luis'] as Map<String, dynamic>;
      for (final dy in const [-3, 0, -2, 0]) {
        luis['dy'] = dy;
        await wait(65);
      }
      luis['dy'] = 0;
    }),
    'corrige98': (o) => _run(o, () async {
      W['luisTumbled'] = 0;
      W['luisShoes'] = 0;
      W['sillaA'] = null;
      await wait(100);
      W['luisTrousers'] = 1;
      await wait(100);
      W['sillaB'] = null;
      W['luisShoes'] = 1;
      await wait(120);
    }),
    'viste98': (o) => _run(o, () async {
      final cual = (o['cual'] as String?) ?? 'ropa_a';
      final ok = _n(o['ok']) == 1;
      final firstKey = cual == 'ropa_a'
          ? (W['sillaA'] as String?)
          : (W['sillaB'] as String?);
      final otherKey = cual == 'ropa_a'
          ? (W['sillaB'] as String?)
          : (W['sillaA'] as String?);
      void wear(String? k) {
        switch (k) {
          case 'camisa':
            W['luisShirt'] = 1;
          case 'zapatos':
            W['luisShoes'] = 1;
          case 'sombrero':
            W['luisHat'] = 1;
          case 'reloj':
            W['luisWatch'] = 1;
          case 'pantalon':
            W['luisTrousers'] = 1;
        }
      }

      void unwear(String? k) {
        switch (k) {
          case 'camisa':
            W['luisShirt'] = 0;
          case 'zapatos':
            W['luisShoes'] = 0;
          case 'sombrero':
            W['luisHat'] = 0;
          case 'reloj':
            W['luisWatch'] = 0;
        }
      }

      final q = W['cq'] as Map<String, dynamic>;
      for (final dx in const [2, 0]) {
        q['dx'] = dx;
        await wait(55);
      }
      q['dx'] = 0;

      if (ok) {
        if (cual == 'ropa_a') {
          W['sillaA'] = null;
        } else {
          W['sillaB'] = null;
        }
        wear(firstKey);
        await wait(140);
        W['sillaA'] = null;
        W['sillaB'] = null;
        wear(otherKey);
        await wait(140);
      } else {
        // Put the wrong one on first, let Carmen correct, then take it off and put both on in her order.
        wear(firstKey);
        await wait(160);
        final luis = _gente['luis'] as Map<String, dynamic>;
        for (final dx in const [-1, 1, 0]) {
          luis['dx'] = dx;
          await wait(55);
        }
        luis['dx'] = 0;
        unwear(firstKey);
        await wait(90);
        W['sillaA'] = null;
        W['sillaB'] = null;
        wear(otherKey);
        await wait(100);
        wear(firstKey);
        await wait(100);
      }
    }),
    'final98': (o) => _run(o, () async {
      // OPEN: `final98`: ensures Luis has all clothes on at `vestir`, abuela raises camera + flash at `foto`,
      // and shows photo card at (169, 20) matching `pelo98` (3/2/1).
      final n = _n(o['n']).clamp(1, 3);
      W['pelo98'] = n;
      W['luisTrousers'] = 1;
      W['luisShoes'] = 1;
      W['luisShirt'] = 1;
      W['luisHat'] = 1;
      W['luisWatch'] = 1;
      W['sillaA'] = null;
      W['sillaB'] = null;
      W['abuelaFoto'] = 1;
      W['abuelaFotoUp'] = 1;
      await wait(110);
      W['flashFx'] = 1;
      await wait(120);
      W['flashFx'] = 0;
      W['abuelaFotoUp'] = 0;
      W['fotoCard'] = n;
      W['finalCelebrar'] = n == 3 ? 1 : 0;
      await wait(240);
    }),
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
