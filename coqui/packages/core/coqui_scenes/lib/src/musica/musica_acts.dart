// La música's story 111-113 acts (part of musica.dart).
part of 'musica.dart';

const List<String> _waitQueueSpots = ['pista4', 'espera2', 'espera3', 'ronda4'];

const List<String> _danceSpotsAdult = ['ronda1', 'ronda4', 'ronda5', 'pista4'];
const List<String> _danceSpotsChild = [
  'pista_baile',
  'ronda1',
  'ronda5',
  'ronda4',
  'pista4',
];

const Map<String, String> _rondaSpotForQue = {
  'baila': 'ronda1',
  'canta': 'ante_micro',
  'come': 'banco3',
  'rie': 'ronda4',
  'bosteza': 'ronda5',
};

extension _MusicaActs on Musica {
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
      ..['dy'] = 0
      ..['laugh'] = 0
      ..['yawn'] = 0
      ..['eat'] = 0
      ..['sing'] = 0
      ..['coverEars'] = 0
      ..['fan'] = 0
      ..['rondaRole'] = null;
  }

  bool _spotOccupied(String spot, {String? exceptId}) {
    final gente = (W['gente'] as Map<String, dynamic>?) ?? const {};
    for (final en in gente.entries) {
      if (en.key == exceptId) continue;
      final p = en.value as Map<String, dynamic>;
      if (p['vis'] != 0 && p['spot'] == spot) return true;
    }
    return false;
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

  /// Picks a free frog-clear waiting spot when Coquí sits at `centro_coqui` (`espera1` and `espera4` avoid overlap).
  String _pickWaitSpot(String rawSpot, String who) {
    // OPEN: musica-sheet.json has no `espera4`, and `espera1` (162,116) is 24 px across / 4 px down
    // from `centro_coqui` (138,112), failing `sprites-apart` (needs 28 across). Prefer frog-clear waiting spots;
    // in Story 113 use `ronda1` for `espera3` so `banqueta_abuela` (190,125) stays clear of Carmen.
    final is113 = _n(W['story']) == 113;
    final prefer = switch (rawSpot) {
      'espera1' => const ['pista4', 'espera2', 'espera3', 'ronda4'],
      'espera2' => const ['espera2', 'pista4', 'espera3', 'ronda4'],
      'espera3' =>
        is113
            ? const ['ronda1', 'espera2', 'pista4']
            : const ['espera3', 'espera2', 'pista4', 'ronda4'],
      'espera4' => const ['ronda4', 'espera2', 'pista4', 'espera3'],
      _ => _waitQueueSpots,
    };
    for (final s in prefer) {
      if (!_spotOccupied(s, exceptId: who)) return s;
    }
    return prefer.first;
  }

  String _pickDanceSpot(String who) {
    final prefer = (who == 'carmen' || who == 'luis')
        ? _danceSpotsChild
        : _danceSpotsAdult;
    for (final s in prefer) {
      if (!_spotOccupied(s, exceptId: who)) return s;
    }
    return prefer.first;
  }

  Future<void> _setWaitSpot(String who, String spot) async {
    final map =
        (W['waitSpotOf'] as Map?)?.cast<String, String>() ??
        (W['waitSpotOf'] = <String, String>{});
    map[who] = spot;
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
      final spot = (o['a'] as String?) ?? 'centro_coqui';
      if (spot == 'borde_coqui') {
        // Keep ante_micro free if anyone was singing there when Coquí hops to the stage edge
        _clearPersonAtSpot('ante_micro', 'coqui');
      }
      await _hopFrogTo(spot);
    }),
    'llega': (o) => _run(o, () async {
      final quien = (o['quien'] as String?) ?? '';
      final rawA = (o['a'] as String?) ?? '';
      final p = _personOf(quien);
      if (p == null) return;

      final isWait = rawA.startsWith('espera');
      final spot = isWait ? _pickWaitSpot(rawA, quien) : rawA;
      if (!_p.hasWorld(spot)) return;

      if (!isWait) {
        _clearPersonAtSpot(spot, quien);
      } else {
        await _setWaitSpot(quien, spot);
      }
      _placePerson(p, spot);
      if (spot.startsWith('banco') && _n(W['story']) == 113) {
        p['eat'] = 1;
      }
      if (spot == 'ante_micro') {
        W['micVis'] = 1;
        W['micMode'] = quien == 'carmen' || quien == 'luis' ? 'low' : 'high';
      }
      for (final d in const [-6, -3, 0]) {
        p['dx'] = d;
        await wait(65);
      }
    }),
    'sale': (o) => _run(o, () async {
      final quien = (o['quien'] as String?) ?? '';
      final p = _personOf(quien);
      if (p == null) return;
      for (final d in const [-3, -6, -10]) {
        p['dx'] = d;
        await wait(65);
      }
      p
        ..['vis'] = 0
        ..['dx'] = 0
        ..['dy'] = 0;
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
      final que = (o['que'] as String?) ?? '';
      final p = _personOf(quien);
      if (p == null) return;

      switch (que) {
        case 'saluda':
          p['pose'] = 'wave0';
          await wait(160);
          p['pose'] = 'wave1';
          await wait(160);
          p['pose'] = 'idle';
        case 'mira' || 'senala':
          if (quien == 'musico1') {
            // `taburete1` (37,74) sits near view edge x0=22; keep `idle` silhouette inside [25..49].
            for (final dy in const [-1, 0]) {
              p['dy'] = dy;
              await wait(75);
            }
          } else {
            p['pose'] = 'offer';
            await wait(150);
          }
        case 'reverencia':
          for (final dy in const [2, 3, 1, 0]) {
            p['dy'] = dy;
            await wait(70);
          }
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
        case 'pies':
          for (final dy in const [2, 2, 0]) {
            p['dy'] = dy;
            await wait(80);
          }
        case 'oido':
          for (final dx in const [2, 2, 0]) {
            p['dx'] = dx;
            await wait(80);
          }
        case 'rie':
          p['laugh'] = 1;
          for (final dy in const [-2, 0, -2, 0]) {
            p['dy'] = dy;
            await wait(80);
          }
        // Preserve `laugh = 1` so Carmen stays laughing through `c113_ab_rie` and `c113_q_rie`;
        // `_placePerson` / `ronda113` clears it when her activity changes.
        case 'abanico':
          p['fan'] = 1;
          for (final dx in const [-1, 1, 0]) {
            p['dx'] = dx;
            await wait(90);
          }
          p['fan'] = 0;
        default:
          await wait(120);
      }
    }),

    /* ---------- Story 111: La música ---------- */
    'parejas': (o) => _run(o, () async {
      final n = _n(o['n']).clamp(1, 3);
      for (final d in _DANCER_KEYS) {
        final p = _personOf(d);
        if (p != null) p['vis'] = 0;
      }
      final dancingCount = n * 2;
      for (var i = 0; i < _DANCER_KEYS.length; i++) {
        final p = _personOf(_DANCER_KEYS[i]);
        if (p == null) continue;
        if (i < dancingCount) {
          _placePerson(p, 'pista${i + 1}');
        } else {
          // Couples who walked off after a miss sit on `banco1..4`
          final benchIndex = (i - dancingCount) + 1;
          _placePerson(p, 'banco$benchIndex');
        }
      }
      await wait(140);
    }),
    'toca111': (o) => _run(o, () async {
      final quien = (o['quien'] as String?) ?? 'musico1';
      final que = (o['que'] as String?) ?? 'guitarra';
      final ok = _n(o['ok']) != 0;
      final q = W['cq'] as Map<String, dynamic>;
      for (final dy in const [-4, -2, 0]) {
        q['dy'] = dy;
        await wait(60);
      }

      if (que == 'guitarra') {
        W['guitarraHeldBy'] = quien;
      } else {
        W['tamborHeldBy'] = quien;
      }

      final holder = _personOf(quien);
      if (holder != null && quien != 'musico1') {
        holder['pose'] = 'offer';
      }

      if (ok) {
        W['notasFloat'] = que == 'tambor' ? 2 : 1;
        for (var i = 0; i < 2; i++) {
          for (final dk in _DANCER_KEYS) {
            final dp = _personOf(dk);
            if (dp != null &&
                dp['vis'] != 0 &&
                !Musica._isSeat(dp['spot'] as String?)) {
              dp['dy'] = i.isEven ? -2 : 0;
            }
          }
          await wait(130);
        }
        for (final dk in _DANCER_KEYS) {
          final dp = _personOf(dk);
          if (dp != null) dp['dy'] = 0;
        }
      } else {
        // Wrong instrument played with eyes shut: sour jagged notes, one couple covers its ears
        if (holder != null) holder['eyesShut'] = 1;
        W['notasFloat'] = 3;
        final gente = (W['gente'] as Map<String, dynamic>?) ?? const {};
        for (final dk in _DANCER_KEYS) {
          final dp = gente[dk] as Map<String, dynamic>?;
          if (dp != null &&
              dp['vis'] != 0 &&
              !Musica._isSeat(dp['spot'] as String?)) {
            dp['coverEars'] = 1;
          }
        }
        await wait(240);
        for (final dk in _DANCER_KEYS) {
          final dp = gente[dk] as Map<String, dynamic>?;
          if (dp != null) dp['coverEars'] = 0;
        }
        if (holder != null) holder['eyesShut'] = 0;
      }
    }),
    'cambian111': (o) => _run(o, () async {
      // Músico 2 (beard) plays guitar, Músico 1 (hat) plays drum
      W['guitarraHeldBy'] = 'musico2';
      W['tamborHeldBy'] = 'musico1';
      W['notasFloat'] = 2;
      final m2 = _personOf('musico2');
      if (m2 != null) m2['pose'] = 'offer';
      await wait(260);
    }),
    'cuelga111': (o) => _run(o, () async {
      W['guitarraHeldBy'] = null;
      W['tamborHeldBy'] = null;
      W['notasFloat'] = 0;
      for (final mid in const ['musico1', 'musico2']) {
        final mp = _personOf(mid);
        if (mp != null) {
          mp
            ..['pose'] = 'idle'
            ..['eyesShut'] = 0;
        }
      }
      await wait(140);
    }),
    'final111': (o) => _run(o, () async {
      final n = _n(o['n']).clamp(1, 3);
      W['guitarraHeldBy'] = 'musico1';
      W['tamborHeldBy'] = 'musico2';
      W['notasFloat'] = 2;
      W['corazonFx'] = n == 3 ? 1 : 0;
      W['estrellaFx'] = n == 3 ? 1 : 0;
      await wait(260);
    }),

    /* ---------- Story 112: ¿Quieres bailar? ---------- */
    'notas': (o) => _run(o, () async {
      W['notas'] = _n(o['n']).clamp(0, 3);
      W['notasVis'] = 1;
      await wait(120);
    }),
    'baila112': (o) => _run(o, () async {
      final quien = (o['quien'] as String?) ?? 'abuelo';
      final ok = _n(o['ok']) != 0;
      final p = _personOf(quien);
      if (p == null) return;
      final oldSpot = p['spot'] as String?;
      if (oldSpot != null && oldSpot.startsWith('espera')) {
        await _setWaitSpot(quien, oldSpot);
      }

      if (ok) {
        final target = _pickDanceSpot(quien);
        _placePerson(p, target);
        W['notasFloat'] = 1;
        for (final dy in const [-2, 0, -2, 0]) {
          p['dy'] = dy;
          await wait(70);
        }
      } else {
        // Wrong place: trips near the microphone, music stops (no mic pixels covered)
        // OPEN: place tripped dancer at `ronda1` / `ante_micro` clear of microfono [112,69,6,28]
        _clearPersonAtSpot('ante_micro', quien);
        _placePerson(p, 'ante_micro');
        W['notasFloat'] = 3;
        for (final dx in const [-2, 2, -2, 0]) {
          p['dx'] = dx;
          await wait(75);
        }
      }
    }),
    'canta112': (o) => _run(o, () async {
      final quien = (o['quien'] as String?) ?? 'carmen';
      final ok = _n(o['ok']) != 0;
      final p = _personOf(quien);
      if (p == null) return;
      final oldSpot = p['spot'] as String?;
      if (oldSpot != null && oldSpot.startsWith('espera')) {
        await _setWaitSpot(quien, oldSpot);
      }

      if (ok) {
        // Evict anyone currently at `ante_micro` to a clear floor spot so two sprites never overlap there
        final gente = (W['gente'] as Map<String, dynamic>?) ?? const {};
        for (final en in gente.entries) {
          if (en.key == quien) continue;
          final other = en.value as Map<String, dynamic>;
          if (other['vis'] != 0 && other['spot'] == 'ante_micro') {
            _placePerson(other, _pickDanceSpot(en.key));
          }
        }
        _placePerson(p, 'ante_micro');
        p['sing'] = 1;
        W['micVis'] = 1;
        W['micMode'] = quien == 'carmen' || quien == 'luis' ? 'low' : 'high';
        W['notasFloat'] = 1;
        await wait(220);
      } else {
        // Wrong place: sings out on the floor where nobody hears
        final target = _pickDanceSpot(quien);
        _placePerson(p, target);
        W['notasFloat'] = 0;
        for (final dx in const [-2, 2, 0]) {
          p['dx'] = dx;
          await wait(80);
        }
      }
    }),
    'vuelve112': (o) => _run(o, () async {
      final quien = (o['quien'] as String?) ?? '';
      final p = _personOf(quien);
      if (p != null) {
        final saved = ((W['waitSpotOf'] as Map?)?[quien] as String?);
        final spot = (saved != null && !_spotOccupied(saved, exceptId: quien))
            ? saved
            : _pickWaitSpot('espera2', quien);
        _placePerson(p, spot);
      }
      W['micMode'] = 'up';
      W['notasFloat'] = 0;
      await wait(140);
    }),
    'fuera112': (o) => _run(o, () async {
      // OPEN: clear dancers/singers off floor and seat abuela on `banco2` (clear of abuelo at `banco1` in step 9).
      for (final id in const ['abuelo', 'luis', 'carmen']) {
        final p = _personOf(id);
        if (p != null) p['vis'] = 0;
      }
      final abuela = _personOf('abuela');
      if (abuela != null) {
        _placePerson(abuela, 'banco2');
      }
      W['micMode'] = 'up';
      W['notas'] = 3;
      W['notasVis'] = 1;
      W['notasFloat'] = 0;
      await wait(200);
    }),
    'final112': (o) => _run(o, () async {
      final n = _n(o['n']).clamp(1, 3);
      final abuela = _personOf('abuela');
      if (abuela != null) _placePerson(abuela, 'banco2');
      final abuelo = _personOf('abuelo');
      if (abuelo != null) _placePerson(abuelo, 'ante_micro');
      final luis = _personOf('luis');
      if (luis != null) _placePerson(luis, 'ronda1');
      final carmen = _personOf('carmen');
      if (carmen != null) _placePerson(carmen, 'pista_baile');
      W['micMode'] = 'high';
      W['notas'] = n;
      W['notasFloat'] = n > 1 ? 2 : 1;
      W['corazonFx'] = n == 3 ? 1 : 0;
      W['estrellaFx'] = n == 3 ? 1 : 0;
      await wait(240);
    }),
    'coqui112': (o) => _run(o, () async {
      // OPEN: clear `ante_micro` before hopping Coquí onto `borde_coqui` (89,98) so they don't overlap sideways,
      // and tip mic low as Coquí sings into the microphone.
      _clearPersonAtSpot('ante_micro', 'coqui');
      await _hopFrogTo('borde_coqui');
      W['micMode'] = 'low';
      W['notasFloat'] = 2;
      await wait(240);
    }),

    /* ---------- Story 113: ¡Qué bueno! ---------- */
    'hojas': (o) => _run(o, () async {
      W['hojas'] = _n(o['n']).clamp(0, 3);
      W['hojasVis'] = 1;
      // Abuela hangs her camera round the frog's neck once the spare-sheet goal appears at step 5.
      if (((W['gente'] as Map?)?['abuela'] as Map?)?['spot'] ==
          'banqueta_abuela') {
        W['camaraCoqui'] = 1;
      }
      await wait(120);
    }),
    'ronda113': (o) => _run(o, () async {
      final quienes = ((o['quienes'] as String?) ?? '')
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      final que = ((o['que'] as String?) ?? '')
          .split(',')
          .map((s) => s.trim())
          .toList();

      // Hide everyone except musicians & abuela on `banqueta_abuela`, then place the 5 participants.
      final gente = (W['gente'] as Map<String, dynamic>?) ?? const {};
      final abuelaSpot = (gente['abuela'] as Map?)?['spot'] as String?;
      for (final en in gente.entries) {
        if (en.key == 'musico1' || en.key == 'musico2') continue;
        if (en.key == 'abuela' && abuelaSpot == 'banqueta_abuela') continue;
        (en.value as Map<String, dynamic>)['vis'] = 0;
      }

      W['camaraCoqui'] = 1;
      W['micVis'] = 1;
      W['micMode'] = 'up';

      // OPEN: gen_musica.py passes `que: "rie,canta,bosteza,baila,come"`, whereas musica-sheet.json assigns
      // each action to its own fixed spot (`baila`->`ronda1`, `canta`->`ante_micro`, `come`->`banco3`,
      // `rie`->`ronda4`, `bosteza`->`ronda5`). Place each participant by action so all 5 rule checks hold.
      for (var i = 0; i < quienes.length && i < que.length; i++) {
        final who = quienes[i];
        final action = que[i];
        final p = _personOf(who);
        if (p == null) continue;
        final spot = _rondaSpotForQue[action] ?? 'ronda${i + 1}';
        if (!_p.hasWorld(spot)) continue;
        _placePerson(p, spot);
        p['rondaRole'] = action;
        switch (action) {
          case 'rie':
            p['laugh'] = 1;
          case 'bosteza':
            p['yawn'] = 1;
          case 'come':
            p['eat'] = 1;
          case 'baila':
            p['pose'] = 'offer';
          case 'canta':
            p['sing'] = 1;
            W['micMode'] = who == 'carmen' || who == 'luis' ? 'low' : 'high';
        }
      }
      await wait(160);
    }),
    'foto113': (o) => _run(o, () async {
      final a = (o['a'] as String?) ?? '';
      final ok = _n(o['ok']) != 0;
      final target = _personOf(a);
      if (target != null) {
        target['dy'] = -1;
      }
      W['flashFx'] = 1;
      W['fotoFx'] = ok ? 1 : 2;
      await wait(180);
      W['flashFx'] = 0;
      if (target != null) {
        target['dy'] = 0;
      }
      await wait(140);
      W['fotoFx'] = 0;
    }),
    'final113': (o) => _run(o, () async {
      final n = _n(o['n']).clamp(1, 3);
      W['camaraCoqui'] = 0;
      W['hojas'] = n;
      W['corazonFx'] = n == 3 ? 1 : 0;
      W['estrellaFx'] = n == 3 ? 1 : 0;
      await wait(240);
    }),
  };
}
