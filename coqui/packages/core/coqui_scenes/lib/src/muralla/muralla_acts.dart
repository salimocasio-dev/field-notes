part of 'muralla.dart';

extension on Muralla {
  static const List<String> _centroAdults = [
    'centro1',
    'centro2',
    'centro3',
    'centro4',
  ];
  static const List<String> _centroAll = [
    'centro1',
    'centro2',
    'centro3',
    'centro4',
    'centro5',
    'centro6',
    'centro7',
    'centro8',
  ];

  String _freeCentro({bool preferAdult = false}) {
    final used = <String>{};
    for (final en in _gente.entries) {
      final p = en.value as Map<String, dynamic>;
      if (p['vis'] != 0 && p['spot'] is String) {
        used.add(p['spot'] as String);
      }
    }
    final order = preferAdult
        ? [..._centroAdults, 'centro5', 'centro6', 'centro7', 'centro8']
        : ['centro8', 'centro5', 'centro6', 'centro7', ..._centroAdults];
    return order.firstWhere(
      (s) => !used.contains(s),
      orElse: () => _centroAll.firstWhere(
        (s) => !used.contains(s),
        orElse: () => 'centro8',
      ),
    );
  }

  void _placePerson(
    String who,
    String spot, {
    int? sentOverride,
    String? pose,
  }) {
    final resolved = _resolveSpot(who, spot);
    final at = _p.at(resolved);
    final p = _person(who);
    p['x'] = at.x;
    p['y'] = at.y;
    p['z'] = at.z;
    p['spot'] = resolved;
    p['sent'] = sentOverride ?? (resolved.startsWith('banco') ? 1 : 0);
    if (pose != null) {
      p['pose'] = pose;
    } else if (p['pose'] == 'mano') {
      p['pose'] = 'idle';
    }
    p['vis'] = 1;
  }

  String _resolveSpot(String who, String spot) {
    final sNum = _n(W['story']);
    // OPEN: story 118 moves músicos to banco2 & banco3 so musico1 never occludes `vela` at [76, 45, 8, 16].
    if (sNum == 118 && who == 'musico1' && spot == 'banco1') return 'banco2';
    if (sNum == 118 && who == 'musico2' && spot == 'banco2') return 'banco3';
    // OPEN: story 117 `ante_todos` stands behind `camara`/`abuela` (cov 92); route to `juego_coqui` (also clear of `junto_coqui`).
    if (sNum == 117 && who == 'coqui' && spot == 'ante_todos') {
      return 'juego_coqui';
    }
    // OPEN: story 119 names `pretil5` for the frog; sheet names `pretil_coqui`.
    if (spot == 'pretil5') return 'pretil_coqui';
    // OPEN: story 119 starts frog on the table (`mesa_coqui`); route to `junto_mesa_coqui` so `table-clear` holds.
    if (sNum == 119 && who == 'coqui' && spot == 'mesa_coqui') {
      return 'junto_mesa_coqui';
    }
    if (spot == 'centro8') return _freeCentro(preferAdult: false);
    return _p.has(spot) ? spot : 'centro8';
  }

  Future<void> _moveFrogTo(String target) async {
    final resolved = _resolveSpot('coqui', target);
    if (!_p.has(resolved)) return;
    final at = _p.at(resolved);
    final L = _frogAt(at);
    final q = W['cq'] as Map<String, dynamic>;
    final fx = ((q['x'] as num?) ?? L[0]).toDouble();
    final fy = ((q['y'] as num?) ?? L[1]).toDouble();
    final dx = L[0] - fx, dy = L[1] - fy;
    final dist = math.sqrt(dx * dx + dy * dy);
    if (dist >= 2) {
      final steps = (dist / 18).ceil().clamp(1, 5);
      for (var i = 1; i <= steps; i++) {
        final t = i / steps;
        q['x'] = _round(fx + dx * t).toDouble();
        q['y'] = _round(fy + dy * t).toDouble();
        q['dy'] = i < steps ? -4.0 : 0.0;
        await wait(60);
      }
    }
    _setFrogSpot(resolved);
  }

  Map<String, Act> _buildOwnActs() => {
    'marca': (o) => _run(o, () async {
      final m = W['marcas'];
      final list = m is List ? List<dynamic>.from(m) : <dynamic>[null, null];
      final idx = list.indexWhere((e) => e == null);
      if (idx >= 0) list[idx] = o['que'];
      W['marcas'] = list;
      await wait(140);
    }),
    'ya': (_) async {
      final pending = List<Future<void>>.from(_loose);
      _loose.clear();
      if (pending.isNotEmpty) await Future.wait(pending);
    },
    'fin': (_) async {
      W['talkAt'] = <String, dynamic>{};
      await wait(120);
    },
    'llega': (o) => _run(o, () async {
      final quien = o['quien'] as String?;
      final a = o['a'] as String?;
      if (quien == null || a == null) return;
      if (a == 'baja') {
        final p = _person(quien);
        p['vis'] = 0;
        p['spot'] = 'baja';
        p['pose'] = 'idle';
        if (quien == 'musico1') {
          W['guitarraMesa'] = 0;
          W['mu1Guitar'] = 1;
        }
        await wait(160);
        return;
      }
      _placePerson(quien, a, pose: 'idle');
      await wait(180);
    }),
    'sale': (o) => _run(o, () async {
      final quien = o['quien'] as String?;
      if (quien != null) {
        final p = _person(quien);
        p['vis'] = 0;
        p['pose'] = 'idle';
      }
      await wait(140);
    }),
    'ir': (o) => _run(o, () async {
      final a = o['a'] as String?;
      if (a != null) await _moveFrogTo(a);
    }),
    'gesto': (o) => _run(o, () async {
      final quien = (o['quien'] as String?) ?? 'abuela';
      final que = (o['que'] as String?) ?? 'si';
      if (quien == 'coqui') {
        final q = W['cq'] as Map<String, dynamic>;
        q['dy'] = que == 'saluda' ? -2 : -1;
        await wait(240);
        q['dy'] = 0;
        return;
      }
      final p = _person(quien);
      if (que == 'mano') {
        p['pose'] = 'mano';
        await wait(140);
        return;
      }
      p['pose'] = switch (que) {
        'saluda' => 'saluda0',
        'lengua' => 'lengua',
        'barriga' => 'barriga',
        'beso' => 'beso',
        'hombro' => 'hombro',
        'cuenta' => 'cuenta',
        'senala' => 'senala',
        'rie' => 'rie',
        'abanico' => 'abanico',
        _ => 'idle',
      };
      await wait(200);
      if (que == 'saluda') {
        p['pose'] = 'saluda1';
        await wait(160);
      }
      if (que != 'lengua' && que != 'barriga' && que != 'abanico') {
        p['pose'] = 'idle';
      }
    }),

    /* ---------- Story 117: Todos en la foto ---------- */
    'faroles': (o) => _run(o, () async {
      final n = _n(o['n']).clamp(0, 3);
      W['faroles'] = n;
      W['farolPresent'] = switch (n) {
        3 => [1, 1, 1],
        2 => [0, 1, 1],
        1 => [0, 1, 0],
        _ => [0, 0, 0],
      };
      W['farolLit'] = List<int>.from(W['farolPresent'] as List);
      await wait(120);
    }),
    'cuenta117': (o) => _run(o, () async {
      final ab = _person('abuela');
      ab['pose'] = 'cuenta';
      await wait(180);
      ab['pose'] = 'idle';
    }),
    'abre117': (o) => _run(o, () async {
      final cual = (o['cual'] as String?) ?? 'puerta_roja';
      final ok = _n(o['ok']) == 1;
      final isRed = cual == 'puerta_roja';
      if (isRed) {
        W['redDoorOpen'] = 1;
      } else {
        W['blueDoorOpen'] = 1;
      }
      final box = _p.box(cual);
      await _moveFrogTo(isRed ? 'ventana_roja' : 'ventana_azul');
      if (ok) {
        final insideSpot = isRed ? 'dentro_roja' : 'dentro_azul';
        String? hider;
        for (final en in _gente.entries) {
          final p = en.value as Map<String, dynamic>;
          if (p['vis'] != 0 && p['spot'] == insideSpot) {
            hider = en.key;
            break;
          }
        }
        if (hider != null) {
          final hp = _person(hider);
          hp['pose'] = 'boca';
          await wait(240);
          final dest = hider == 'carmen'
              ? _freeCentro(preferAdult: false)
              : _freeCentro(preferAdult: true);
          _placePerson(hider, dest, sentOverride: 0, pose: 'idle');
        } else {
          await wait(200);
        }
        if (isRed) {
          W['redDoorOpen'] = 0;
        } else {
          W['blueDoorOpen'] = 0;
        }
      } else {
        // Empty door opened: pigeons burst out & a lantern swings/gets knocked.
        W['pigeonBurst'] = 1;
        W['farolSwing'] = isRed ? 1 : 3;
        await wait(260);
        W['pigeonBurst'] = 0;
        W['farolSwing'] = 0;
        final _ = box;
        if (isRed) {
          W['redDoorOpen'] = 0;
        } else {
          W['blueDoorOpen'] = 0;
        }
      }
      await _moveFrogTo('juego_coqui');
    }),
    'paloma117': (o) => _run(o, () async {
      W['blueDoorOpen'] = 1;
      W['palomaLedge'] = 1;
      W['farolSwing'] = 3;
      await wait(260);
      W['palomaLedge'] = 0;
      W['farolSwing'] = 0;
      W['blueDoorOpen'] = 0;
    }),
    'viento117': (o) => _run(o, () async {
      final quien = o['quien'] as String?;
      final donde = (o['donde'] as String?) ?? 'puerta_roja';
      final insideSpot = donde == 'puerta_azul' ? 'dentro_azul' : 'dentro_roja';
      W['vientoDark'] = 1;
      W['redDoorOpen'] = 0;
      W['blueDoorOpen'] = 0;
      await wait(220);
      if (quien != null) {
        _placePerson(quien, insideSpot, sentOverride: 0, pose: 'idle');
      }
      await wait(140);
      W['vientoDark'] = 0;
    }),
    'mira117': (o) => _run(o, () async {
      _placePerson('luis', 'ventana_roja', sentOverride: 0, pose: 'senala');
      await wait(180);
      _placePerson('luis', 'ventana_azul', sentOverride: 0, pose: 'senala');
      await wait(180);
      _placePerson('luis', 'junto_coqui', sentOverride: 0, pose: 'idle');
    }),
    'final117': (o) => _run(o, () async {
      final n = _n(o['n']).clamp(1, 3);
      W['final117'] = n;
      final group = [
        ('abuelo', 'centro1'),
        ('pepe', 'centro2'),
        ('maestra', 'centro3'),
        ('piraguero', 'centro4'),
        ('senor', 'centro5'),
        ('senora', 'centro6'),
        ('luis', 'centro7'),
        ('carmen', 'centro8'),
      ];
      for (final (who, sp) in group) {
        _placePerson(who, sp, sentOverride: 0, pose: 'idle');
      }
      await _moveFrogTo('junto_camara');
      await wait(200);
    }),
    'foto117': (o) => _run(o, () async {
      final n = _n(o['n']).clamp(1, 3);
      W['flashFx'] = 1;
      await wait(160);
      W['flashFx'] = 0;
      W['fotoFx'] = n;
      await wait(320);
      W['fotoFx'] = 0;
    }),

    /* ---------- Story 118: ¿Por qué no bailas? ---------- */
    'aros': (o) => _run(o, () async {
      W['aros'] = _n(o['n']).clamp(0, 3);
      await wait(120);
    }),
    'trae118': (o) => _run(o, () async {
      final que = (o['que'] as String?) ?? 'jugo';
      final who = (o['a'] as String?) ?? 'maestra';
      final ok = _n(o['ok']) == 1;
      await _moveFrogTo('mesa_coqui');
      if (ok) {
        if (que == 'silla') {
          if (who == 'abuelo') {
            W['sillaAt'] = 'abuelo';
            _placePerson('abuelo', 'muro1', sentOverride: 1, pose: 'idle');
          } else {
            // OPEN: move maestra/piraguero with chair/drink/plate clearly to dancers row + muro3.
            _placePerson(
              who,
              who == 'maestra' ? 'baile6' : 'muro3',
              sentOverride: 0,
              pose: 'saluda0',
            );
          }
        } else {
          if (que == 'jugo') W['jugoAt'] = 'used';
          if (que == 'plato') W['platoAt'] = 'used';
          if (who == 'pepe' && que == 'plato') {
            final pm = Map<String, int>.from(
              (W['plateWho'] as Map?) ?? const {},
            );
            pm['pepe'] = 1;
            W['plateWho'] = pm;
          }
          // OPEN: story 118 dancers: luis -> baile4, pepe -> baile5, maestra -> baile6, piraguero -> muro3.
          final danceSpot = switch (who) {
            'luis' => 'baile4',
            'pepe' => 'baile5',
            'maestra' => 'baile6',
            _ => 'muro3',
          };
          _placePerson(who, danceSpot, sentOverride: 0, pose: 'saluda0');
        }
        await wait(240);
      } else {
        final p = _person(who);
        final prev = p['pose'];
        p['pose'] = 'idle';
        await wait(220);
        p['pose'] = prev;
      }
    }),
    'repone118': (o) => _run(o, () async {
      _placePerson('luis', 'junto_mesa', sentOverride: 0, pose: 'idle');
      await wait(140);
      W['sillaAt'] = 'mesa';
      W['jugoAt'] = 'mesa';
      W['platoAt'] = 'mesa';
      _placePerson('luis', 'baile4', sentOverride: 0, pose: 'saluda0');
      await wait(140);
    }),
    'cancion118': (o) => _run(o, () async {
      W['mu1GuitarLift'] = 1;
      final at = _p.at('banco2');
      W['notaFx'] = {'x': _round(at.sx) + 8, 'y': _round(at.sy) - 52};
      await wait(220);
    }),
    'final118': (o) => _run(o, () async {
      final n = _n(o['n']).clamp(1, 3);
      W['final118'] = n;
      W['mu1GuitarLift'] = 0;
      W['mu2Drum'] = 0;
      W['legUpWho'] = n == 1 ? 1 : 0;
      final dancers = const [
        ('abuela', 'baile1'),
        ('carmen', 'baile2'),
        ('abuelo', 'baile3'),
        ('luis', 'baile4'),
        ('pepe', 'baile5'),
        ('maestra', 'baile6'),
        ('piraguero', 'muro3'),
      ];
      for (final (who, sp) in dancers) {
        _placePerson(
          who,
          sp,
          sentOverride: 0,
          pose: n == 1 ? 'rie' : 'saluda0',
        );
      }
      await wait(260);
      W['notaFx'] = null;
      W['legUpWho'] = 0;
    }),

    /* ---------- Story 119: Nos vemos ---------- */
    'caras': (o) => _run(o, () async {
      W['caras'] = _n(o['n']).clamp(0, 4);
      await wait(120);
    }),
    'bocina119': (o) => _run(o, () async {
      W['guaguaBlink'] = 1;
      await wait(240);
      W['guaguaBlink'] = 0;
    }),
    'musicos119': (o) => _run(o, () async {
      W['muLejosVis'] = 1;
      await wait(240);
      W['muLejosVis'] = 0;
    }),
    'entrega119': (o) => _run(o, () async {
      final quien = (o['quien'] as String?) ?? 'pepe';
      final que = (o['que'] as String?) ?? 'caja';
      final ok = _n(o['ok']) == 1;
      if (ok) {
        final items = Map<String, String>.from(
          (W['items119'] as Map?) ?? const {},
        );
        items[que] = quien;
        W['items119'] = items;
        final hm = Map<String, String>.from((W['hugItem'] as Map?) ?? const {});
        hm[quien] = que;
        W['hugItem'] = hm;
        _person(quien)['vis'] = 0;
        W['caras'] = (_n(W['caras']) + 1).clamp(0, 4);
        await wait(220);
      } else {
        // Missed guest: goes down steps, climbs back out of breath, sits on banco1/banco2 fanning self.
        _placePerson(quien, 'escalera1', sentOverride: 0, pose: 'idle');
        await wait(160);
        final missed = List<String>.from(
          (W['missedGuests'] as List?) ?? const [],
        );
        if (!missed.contains(quien)) missed.add(quien);
        W['missedGuests'] = missed;
        // OPEN: first missed guest sits on `banco1`, second on `banco2`.
        final benchSpot = missed.length <= 1 ? 'banco1' : 'banco2';
        final fm = Map<String, int>.from((W['fanWho'] as Map?) ?? const {});
        fm[quien] = 1;
        W['fanWho'] = fm;
        _placePerson(quien, benchSpot, sentOverride: 1, pose: 'abanico');
        await wait(200);
      }
    }),
    'banco119': (o) => _run(o, () async {
      final quien = (o['quien'] as String?) ?? 'pepe';
      final que = (o['que'] as String?) ?? 'caja';
      final items = Map<String, String>.from(
        (W['items119'] as Map?) ?? const {},
      );
      items[que] = quien;
      W['items119'] = items;
      final hm = Map<String, String>.from((W['hugItem'] as Map?) ?? const {});
      hm[quien] = que;
      W['hugItem'] = hm;
      final fm = Map<String, int>.from((W['fanWho'] as Map?) ?? const {});
      fm[quien] = 0;
      W['fanWho'] = fm;
      _person(quien)['pose'] = 'saluda0';
      await wait(200);
    }),
    'final119': (o) => _run(o, () async {
      final n = _n(o['n']).clamp(2, 4);
      W['final119'] = n;
      W['caras'] = n;
      final missed = List<String>.from(
        (W['missedGuests'] as List?) ?? const [],
      );
      for (final g in const ['pepe', 'senora', 'senor', 'maestra']) {
        if (!missed.contains(g)) _person(g)['vis'] = 0;
      }
      final items = Map<String, String>.from(
        (W['items119'] as Map?) ?? const {},
      );
      for (final k in items.keys.toList()) {
        items[k] = 'gone';
      }
      W['items119'] = items;
      W['guaguaDoorOpen'] = 0;
      W['guaguaGone'] = 1;
      await wait(260);
    }),
    'apaga119': (o) => _run(o, () async {
      final lit = [1, 1, 1];
      for (var i = 0; i < 3; i++) {
        lit[i] = 0;
        W['farolLit'] = List<int>.from(lit);
        await wait(140);
      }
    }),
  };
}
