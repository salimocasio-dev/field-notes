// El baño's story 99-101 acts (part of bano.dart).
part of 'bano.dart';

extension _BanoActs on Bano {
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
      final steps = (dist / 22).ceil().clamp(1, 5);
      for (var i = 1; i <= steps; i++) {
        final t = i / steps;
        q['x'] = sx + dx * t;
        q['y'] = sy + dy * t;
        q['dy'] = -math.sin(t * math.pi) * 9;
        await wait(65);
      }
    }
    q
      ..['x'] = dest[0]
      ..['y'] = dest[1]
      ..['dy'] = 0
      ..['spot'] = spot
      ..['z'] = at.z;
  }

  Map<String, dynamic>? _personOf(String? id) {
    if (id == null) return null;
    final gente = W['gente'] as Map<String, dynamic>?;
    return gente?[id] as Map<String, dynamic>?;
  }

  void _placePerson(Map<String, dynamic> p, String spot) {
    final w = _p.world(spot);
    p
      ..['x'] = w[0]
      ..['y'] = w[1]
      ..['z'] = w[2]
      ..['spot'] = spot
      ..['vis'] = 1
      ..['pose'] = 'idle'
      ..['dx'] = 0
      ..['dy'] = 0;
  }

  void _clearPersonAtSpot(String spot, String exceptId) {
    final gente = (W['gente'] as Map<String, dynamic>?) ?? const {};
    for (final en in gente.entries) {
      if (en.key == exceptId) continue;
      final p = en.value as Map<String, dynamic>;
      if (p['vis'] != 0 && p['spot'] == spot) {
        p['vis'] = 0;
      }
    }
  }

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
      final spot = (o['a'] as String?) ?? 'repisa_coqui';
      await _hopFrogTo(spot);
    }),
    'llega': (o) => _run(o, () async {
      final quien = (o['quien'] as String?) ?? '';
      final rawA = (o['a'] as String?) ?? '';

      if (quien == 'perro') {
        // OPEN: gen_bano.py sends Canelo to `ducha_dentro` where abuela stands; use `ducha_perro` so both fit inside the shower.
        final target = rawA == 'ducha_dentro' ? 'ducha_perro' : rawA;
        if (_p.hasWorld(target)) {
          W['perroSpot'] = target;
          W['perroVis'] = 1;
          if (target == 'ducha_perro') W['perroMuddy'] = 0;
        }
        await wait(120);
        return;
      }

      final p = _personOf(quien);
      if (p == null) return;

      // OPEN: `fuera` (story 100 step 5: abuelo waiting on a chair outside the door) has no world point; hide him off-screen.
      if (rawA == 'fuera') {
        p
          ..['vis'] = 0
          ..['spot'] = 'fuera';
        await wait(100);
        return;
      }

      // OPEN: `ducha_abuela` and `junto_puerta` map to `ducha_dentro` and `puerta1` (bano-sheet.json).
      final spot = switch (rawA) {
        'ducha_abuela' => 'ducha_dentro',
        'junto_puerta' => 'puerta1',
        _ => rawA,
      };
      if (!_p.hasWorld(spot)) return;

      // OPEN: in story 101 step 4, Luis arrives at `lavamanos2` while Carmen is on `banquito` (`8` px across, `9` px
      // down); step Carmen onto `lavamanos1` so she is clear of Luis and `cepillito` is uncovered.
      if (quien == 'luis' &&
          spot == 'lavamanos2' &&
          _personAt(W, 'carmen', 'banquito')) {
        final carmen = _personOf('carmen');
        if (carmen != null) {
          _placePerson(carmen, 'lavamanos1');
        }
      }

      _clearPersonAtSpot(spot, quien);
      _placePerson(p, spot);

      if (spot == 'ducha_dentro') {
        p['raincoat'] = 0;
        p['mudHands'] = 0;
        p['mudFace'] = 0;
        if (quien == 'abuelo') p['robe'] = 1;
      } else if (spot == 'ante_espejo' && quien == 'abuelo') {
        p['robe'] = 0;
        p['flatHair'] = 1;
      }

      for (final d in const [-6, -3, 0]) {
        p['dx'] = d;
        await wait(70);
      }
    }),
    'sale': (o) => _run(o, () async {
      final quien = (o['quien'] as String?) ?? '';
      if (quien == 'perro') {
        W['perroVis'] = 0;
        await wait(90);
        return;
      }
      final p = _personOf(quien);
      if (p == null) return;
      for (final d in const [-3, -6, -10]) {
        p['dx'] = d;
        await wait(70);
      }
      p
        ..['vis'] = 0
        ..['dx'] = 0
        ..['dy'] = 0
        ..['towelHead'] = 0
        ..['raincoat'] = 0;
      if (_n(W['story']) == 99 && (quien == 'luis' || quien == 'carmen')) {
        // Story 99 step 6: children run out to the patio and come back muddy again
        p['mudHands'] = 1;
        p['mudFace'] = 1;
        p['shine'] = 0;
      }
    }),
    'marca': (o) async {
      final m = W['marcas'];
      if (m is List) {
        final i = m.indexWhere((x) => x == null);
        if (i >= 0) m[i] = o['que'] == 'ok' ? 'ok' : 'x';
      }
      await wait(140);
    },
    'gesto': (o) => _run(o, () async {
      final quien = (o['quien'] as String?) ?? '';
      final que = (o['que'] as String?) ?? 'saluda';
      final p = _personOf(quien);
      if (p == null) return;

      switch (que) {
        case 'manos':
          // OPEN: story 99 step 1 & story 100 step 3: move Luis to `lavamanos1` (so `manos_luis` matches his hands)
          // and Carmen to `lavamanos2` if still in the door.
          if (_n(W['story']) == 99 &&
              quien == 'luis' &&
              p['spot'] == 'puerta1') {
            _placePerson(p, 'lavamanos1');
          } else if (_n(W['story']) == 100 &&
              quien == 'carmen' &&
              p['spot'] == 'puerta2') {
            _placePerson(p, 'lavamanos2');
          }
          p['pose'] = 'yo';
          await wait(200);
        case 'huele':
          p['smellFace'] = 1;
          for (final dx in const [-1, 1, 0]) {
            p['dx'] = dx;
            await wait(80);
          }
          p['smellFace'] = 0;
        case 'dientes':
          p['teeth'] = 1;
          await wait(220);
        case 'toca':
          p['pose'] = 'offer';
          await wait(200);
          p['pose'] = 'idle';
        case 'saluda':
          p['pose'] = 'wave0';
          await wait(180);
          p['pose'] = 'idle';
        case 'no':
          for (final dx in const [-2, 2, -2, 0]) {
            p['dx'] = dx;
            await wait(70);
          }
        case 'si':
          for (final dy in const [2, 0, 2, 0]) {
            p['dy'] = dy;
            await wait(70);
          }
        case 'rie':
          for (final dy in const [-2, 0, -2, 0]) {
            p['dy'] = dy;
            await wait(80);
          }
        case 'mira' || 'senala':
          p['pose'] = 'offer';
          await wait(160);
          p['pose'] = 'idle';
      }
    }),

    /* ---------- Story 99: Limpio y sucio ---------- */
    'jabon': (o) => _run(o, () async {
      W['jabon'] = _n(o['n']).clamp(1, 3);
      W['jabonVis'] = 1;
      await wait(120);
    }),
    'lava99': (o) => _run(o, () async {
      final quien = (o['quien'] as String?) ?? 'luis';
      final p = _personOf(quien);
      if (p == null) return;
      // OPEN: story 99 step 3 washes Carmen's face while she stands at puerta2; step her to `lavamanos2` at the sink.
      if (quien == 'carmen' && p['spot'] == 'puerta2') {
        _placePerson(p, 'lavamanos2');
      }
      W['bubblesAt'] = quien;
      p['pose'] = 'yo';
      await wait(240);
      p
        ..['mudHands'] = 0
        ..['mudFace'] = 0
        ..['shine'] = 1
        ..['pose'] = 'idle';
      W['bubblesAt'] = null;
      await wait(100);
    }),
    'toallas99': (o) => _run(o, () async {
      // OPEN: in story 99 step 4, place green/yellow towels on the stool (`toalla_a`, `toalla_b`) as well as abuela holding them.
      W['toallaA'] = (o['a'] as String?) ?? 'verde';
      W['toallaB'] = (o['b'] as String?) ?? 'amarillo';
      W['toallasVis'] = 1;
      final ab = _personOf('abuela');
      if (ab != null && ab['spot'] == 'abuela_bano') {
        ab['holdingTowel'] = 1;
      }
      await wait(140);
    }),
    'seca99': (o) => _run(o, () async {
      final a = (o['a'] as String?) ?? 'carmen';
      final ok = _n(o['ok']) != 0;
      final p = _personOf(a);
      final q = W['cq'] as Map<String, dynamic>;
      for (final dy in const [-5, -2, 0]) {
        q['dy'] = dy;
        await wait(65);
      }
      if (p != null) {
        if (ok) {
          p
            ..['mudHands'] = 0
            ..['mudFace'] = 0
            ..['shine'] = 1
            ..['pose'] = 'idle';
          final ab = _personOf('abuela');
          if (ab != null) ab['holdingTowel'] = 0;
        } else {
          p
            ..['mudHands'] = 1
            ..['mudFace'] = 1
            ..['shine'] = 0;
          for (final dx in const [-2, 2, -2, 0]) {
            p['dx'] = dx;
            await wait(70);
          }
          // Needs list: "muddy again, and washed again"
          W['bubblesAt'] = a;
          await wait(220);
          W['bubblesAt'] = null;
          p
            ..['mudHands'] = 0
            ..['mudFace'] = 0
            ..['shine'] = 1;
        }
      }
    }),
    'final99': (o) => _run(o, () async {
      final n = _n(o['n']).clamp(1, 3);
      W['jabon'] = n;
      W['coquiFoam'] = n;
      W['coquiMuddy'] = 0;
      W['corazonFx'] = n == 3 ? 1 : 0;
      W['estrellaFx'] = n == 3 ? 1 : 0;
      await wait(280);
    }),
    'agua99': (o) => _run(o, () async {
      W['agua99'] = (o['que'] as String?) ?? 'caliente';
      W['coquiMuddy'] = 0;
      await wait(260);
    }),

    /* ---------- Story 100: Se baña ---------- */
    'barras': (o) => _run(o, () async {
      W['barras'] = _n(o['n']).clamp(0, 3);
      W['barrasVis'] = 1;
      await wait(120);
    }),
    'ducha100': (o) => _run(o, () async {
      W['duchaOn'] = _n(o['on']) != 0 ? 1 : 0;
      await wait(120);
    }),
    'llave100': (o) => _run(o, () async {
      W['llaveOn'] = _n(o['on']) != 0 ? 1 : 0;
      await wait(120);
    }),
    'espejo100': (o) => _run(o, () async {
      W['espejoCoqui'] = 1;
      await wait(200);
    }),
    'capa100': (o) => _run(o, () async {
      final quien = (o['quien'] as String?) ?? 'luis';
      final p = _personOf(quien);
      if (p == null) return;
      _clearPersonAtSpot('centro', quien);
      _placePerson(p, 'centro');
      p['raincoat'] = 1;
      await wait(140);
    }),
    'va100': (o) => _run(o, () async {
      final quien = (o['quien'] as String?) ?? 'luis';
      final a = (o['a'] as String?) ?? 'ducha_dentro';
      final ok = _n(o['ok']) != 0;
      final p = _personOf(quien);
      if (p == null) return;
      if (ok && _p.hasWorld(a)) {
        _clearPersonAtSpot(a, quien);
        _placePerson(p, a);
        p['raincoat'] = 0;
        if (a == 'ducha_dentro') {
          W['vaporDucha'] = 1;
          await wait(220);
          W['vaporDucha'] = 0;
        } else {
          await wait(200);
        }
      } else {
        // Wrong water runs; child waits at centro
        for (final dx in const [-2, 2, 0]) {
          p['dx'] = dx;
          await wait(70);
        }
      }
    }),
    'final100': (o) => _run(o, () async {
      final n = _n(o['n']).clamp(1, 3);
      W['barras'] = n;
      W['duchaOn'] = 1;
      W['vaporDucha'] = n >= 2 ? 1 : 0;
      W['notasDucha'] = n >= 2 ? 1 : 0;
      W['corazonFx'] = n == 3 ? 1 : 0;
      W['estrellaFx'] = n == 3 ? 1 : 0;
      await wait(300);
      W['duchaOn'] = 0;
      W['vaporDucha'] = 0;
      W['notasDucha'] = 0;
    }),

    /* ---------- Story 101: Los dientes ---------- */
    'tubo': (o) => _run(o, () async {
      W['tubo'] = _n(o['n']).clamp(0, 4);
      W['tuboVis'] = 1;
      await wait(120);
    }),
    'cepilla101': (o) => _run(o, () async {
      final quien = (o['quien'] as String?) ?? 'carmen';
      final p = _personOf(quien);
      if (p != null) {
        W['bubblesAt'] = quien;
        p['teeth'] = 1;
        await wait(240);
        W['bubblesAt'] = null;
      }
    }),
    'peina101': (o) => _run(o, () async {
      final quien = (o['quien'] as String?) ?? 'carmen';
      final p = _personOf(quien);
      if (p != null) {
        p['flatHair'] = 1;
        await wait(220);
      }
    }),
    'toalla101': (o) => _run(o, () async {
      final quien = (o['quien'] as String?) ?? 'luis';
      final p = _personOf(quien);
      if (p != null) {
        p
          ..['towelHead'] = 1
          ..['pasteHair'] = 0
          ..['combMouth'] = 0
          ..['pose'] = 'offer';
        await wait(140);
      }
    }),
    'repisa101': (o) => _run(o, () async {
      final izq = (o['izq'] as String?) ?? 'cepillo';
      W['cosaA'] = izq == 'peinilla' ? 'peinilla' : 'cepillo';
      W['cosaB'] = izq == 'peinilla' ? 'cepillo' : 'peinilla';
      W['cepilloPaste'] = 1;
      W['cosasVis'] = 1;
      await wait(120);
    }),
    'da101': (o) => _run(o, () async {
      final cual = (o['cual'] as String?) ?? 'cosa_a';
      final a = (o['a'] as String?) ?? 'luis';
      final ok = _n(o['ok']) != 0;
      final p = _personOf(a);
      final q = W['cq'] as Map<String, dynamic>;
      final given = cual == 'cosa_b' ? W['cosaB'] : W['cosaA'];
      for (final dy in const [-5, -2, 0]) {
        q['dy'] = dy;
        await wait(65);
      }
      if (p != null) {
        if (ok) {
          p
            ..['towelHead'] = 0
            ..['pasteHair'] = 0
            ..['combMouth'] = 0
            ..['pose'] = 'idle';
          if (given == 'cepillo') {
            p['teeth'] = 1;
          } else {
            p['flatHair'] = 1;
          }
          await wait(200);
        } else {
          // Wrong item used under towel, then pulls towel off
          p['towelHead'] = 0;
          if (given == 'cepillo') {
            p['pasteHair'] = 1;
          } else {
            p['combMouth'] = 1;
          }
          for (final dx in const [-2, 2, -2, 0]) {
            p['dx'] = dx;
            await wait(75);
          }
          // Brush is washed and fresh squeeze goes on
          p
            ..['pasteHair'] = 0
            ..['combMouth'] = 0;
        }
      }
    }),
    'final101': (o) => _run(o, () async {
      final n = _n(o['n']).clamp(1, 3);
      W['cepillitoPaste'] = n;
      W['coquiFoam'] = n;
      W['corazonFx'] = n == 3 ? 1 : 0;
      W['estrellaFx'] = n == 3 ? 1 : 0;
      await wait(280);
    }),
    'brilla101': (o) => _run(o, () async {
      W['espejoCoqui'] = 1;
      W['espejoSparkle'] = 1;
      await wait(220);
    }),
  };
}
