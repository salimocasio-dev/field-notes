// Acts of Los regalos (place 10, El fuerte, scene 3: `regalos`; stories 114 to 116).
// Part of regalos.dart: every act named in historia/notas/guiones/regalos.md's Needs list and
// historia/tools/gen_regalos.py. Acts with no spot in regalos-sheet.json are marked `OPEN:`.
part of 'regalos.dart';

typedef _TargetPos = ({int sx, int sy, int cueX, int cueY, bool up, double d});

extension _RegalosActs on Regalos {
  _TargetPos? _targetScreen(String? target, Map<String, dynamic> w) {
    if (target == null || target.isEmpty) return null;
    final gente = (w['gente'] as Map<String, dynamic>?) ?? const {};
    if (gente[target] is Map) {
      final p = gente[target] as Map<String, dynamic>;
      if (p['vis'] == 0) return null;
      final at = _atOf(p);
      final sx = _round(at.sx) + _n(p['dx']);
      final sy = _round(at.sy) + _n(p['dy']);
      final headTopOffset = switch (target) {
        'luis' || 'carmen' => 42,
        _ => 52,
      };
      return (
        sx: sx,
        sy: sy,
        cueX: sx,
        cueY: (sy - headTopOffset - 10).clamp(10, 180),
        up: false,
        d: at.d + .06,
      );
    }
    if (target == 'coqui') {
      final q = w['cq'] as Map<String, dynamic>?;
      if (q == null || !jsTruthy(q['vis'])) return null;
      final at = _frogPoint(q);
      final sx = _round(at.sx), sy = _round(at.sy);
      return (
        sx: sx,
        sy: sy,
        cueX: sx,
        cueY: sy - 34,
        up: false,
        d: at.d + .06,
      );
    }
    if (_p.has(target)) {
      final at = _p.at(target);
      final sx = _round(at.sx), sy = _round(at.sy);
      return (
        sx: sx,
        sy: sy,
        cueX: sx,
        cueY: (sy - 18).clamp(10, 180),
        up: false,
        d: at.d + .06,
      );
    }
    return null;
  }

  /// Canonical cord peg spot (`cuerda1..cuerda4`) for each of the four photos.
  static String _pegForFoto(String cual) => switch (cual) {
    'foto_3m' => 'cuerda1',
    'foto_7m' => 'cuerda2',
    'foto_3a' => 'cuerda3',
    'foto_7a' => 'cuerda4',
    _ => 'cuerda1',
  };

  Map<String, Act> _buildOwnActs() {
    Future<void> run(Map<String, dynamic> o, Future<void> Function() body) {
      if (jsTruthy(o['suelto'])) {
        final f = body();
        _loose.add(f);
        return Future<void>.value();
      }
      return body();
    }

    Future<void> bounceFrog({int dx = 0, int dy = -5, int ms = 120}) async {
      final q = W['cq'] as Map<String, dynamic>;
      q['dx'] = dx;
      q['dy'] = dy;
      await wait(ms);
      q['dx'] = 0;
      q['dy'] = 0;
    }

    return <String, Act>{
      'ya': (o) async {
        final pending = List<Future<void>>.from(_loose);
        _loose.clear();
        await Future.wait(pending);
      },

      'marca': (o) async {
        final que = o['que'];
        final m = W['marcas'];
        if (m is List) {
          final i = m.indexWhere((e) => e == null);
          if (i >= 0) m[i] = que;
        }
        await wait(160);
      },

      'ir': (o) => run(o, () async {
        final a = o['a'] as String?;
        if (a == null) return;
        // OPEN: Story 115's photos lie at fotos1..fotos4 where mesa_coqui sits; use banqueta_coqui (preview m4/m5).
        final spot = (_n(W['story']) == 115 && a == 'mesa_coqui')
            ? 'banqueta_coqui'
            : a;
        await _hopToSpot(spot);
      }),

      'llega': (o) => run(o, () async {
        final quien = o['quien'] as String?;
        final a = o['a'] as String?;
        if (quien == null || a == null) return;
        final p = _gente[quien] as Map<String, dynamic>?;
        if (p == null) return;
        // regalos-sheet.json notes: `escondidos` hides behind the table (no sprite drawn until final114 jumps up).
        if (a == 'escondidos') {
          p['vis'] = 0;
          p['spot'] = 'escondidos';
          await wait(140);
          return;
        }
        if (!_p.has(a)) return;
        _placePerson(p, a);
        await wait(140);
      }),

      'sale': (o) => run(o, () async {
        final quien = o['quien'] as String?;
        if (quien == null) return;
        final p = _gente[quien] as Map<String, dynamic>?;
        if (p == null) return;
        p['vis'] = 0;
        await wait(140);
      }),

      'gesto': (o) => run(o, () async {
        final quien = o['quien'] as String?;
        final que = o['que'] as String?;
        if (quien == null || que == null) return;
        if (quien == 'coqui') {
          if (que == 'senala' || que == 'mira') {
            final tgt = _targetScreen(o['a'] as String?, W);
            if (tgt != null) {
              W['gestoCue'] = {
                'cueX': tgt.cueX,
                'cueY': tgt.cueY,
                'up': tgt.up,
                'd': tgt.d,
              };
            }
            await bounceFrog(dy: -4, ms: 180);
            W['gestoCue'] = null;
          } else {
            await bounceFrog(dy: -4, ms: 160);
          }
          return;
        }
        final p = _gente[quien] as Map<String, dynamic>?;
        if (p == null) return;
        final manosSet = (W['manosWho'] as Set<String>?) ?? <String>{};
        W['manosWho'] = manosSet;
        final aplaudeSet = (W['aplaudeWho'] as Set<String>?) ?? <String>{};
        W['aplaudeWho'] = aplaudeSet;
        switch (que) {
          case 'silencio':
            if (quien == 'luis') W['luisSilencio'] = 1;
            await wait(240);
            if (quien == 'luis') W['luisSilencio'] = 0;
          case 'dedos':
            if (quien == 'luis') W['luisDedos'] = 1;
            for (var i = 0; i < 3; i++) {
              p['dy'] = -1;
              await wait(100);
              p['dy'] = 0;
              await wait(80);
            }
            if (quien == 'luis') W['luisDedos'] = 0;
          case 'quieto':
            p['pose'] = 'idle';
            await wait(220);
          case 'manos':
            manosSet.add(quien);
            await wait(160);
          case 'aplaude':
            manosSet.remove(quien);
            aplaudeSet.add(quien);
            for (var i = 0; i < 2; i++) {
              p['dy'] = -1;
              await wait(100);
              p['dy'] = 0;
              await wait(80);
            }
            aplaudeSet.remove(quien);
          case 'salta':
            p['dy'] = -5;
            await wait(140);
            p['dy'] = 0;
          case 'si':
            p['dy'] = 2;
            await wait(120);
            p['dy'] = 0;
          case 'no':
            for (final d in const [-2, 2, -2, 0]) {
              p['dx'] = d;
              await wait(70);
            }
          case 'saluda':
            p['pose'] = 'saluda0';
            await wait(140);
            p['pose'] = 'saluda1';
            await wait(140);
            p['pose'] = 'idle';
          case 'rie':
            p['pose'] = 'rie';
            p['dy'] = -1;
            await wait(140);
            p['dy'] = 0;
            p['pose'] = 'idle';
          case 'mira':
          case 'senala':
            final tgt = _targetScreen(o['a'] as String?, W);
            final at = _atOf(p);
            final dirLeft = tgt != null && tgt.sx < _round(at.sx);
            p['pose'] = dirLeft ? 'senala_izq' : 'senala_der';
            await wait(180);
            p['pose'] = 'idle';
          default:
            await wait(120);
        }
      }),

      /* ---------- Story 114: La sorpresa ---------- */
      'pinzas': (o) => run(o, () async {
        W['pinzas'] = _n(o['n']).clamp(1, 3);
        await wait(120);
      }),

      'cortina114': (o) => run(o, () async {
        final como = (o['como'] as String?) ?? 'cierra';
        await bounceFrog(dx: -4, dy: -4, ms: 120);
        if (como == 'cierra') {
          W['cortinaState'] = 'shut';
          // Carmen dances behind the shut curtain (not seen until final114).
          final carmen = _gente['carmen'] as Map<String, dynamic>?;
          if (carmen != null) carmen['vis'] = 0;
        } else {
          W['cortinaState'] = 'open';
        }
        await wait(180);
      }),

      'tapa114': (o) => run(o, () async {
        await bounceFrog(dx: -4, dy: -4, ms: 120);
        W['bizcochoRed'] = 0;
        await wait(160);
      }),

      'suena114': (o) => run(o, () async {
        final quien = (o['quien'] as String?) ?? 'abuelo';
        W['regaloShaken'] = 1;
        if (quien == 'coqui') {
          await bounceFrog(dy: -4, ms: 160);
        } else {
          final p = _gente[quien] as Map<String, dynamic>?;
          if (p != null) {
            for (final d in const [-1, 1, -1, 0]) {
              p['dx'] = d;
              await wait(60);
            }
          } else {
            await wait(180);
          }
        }
        W['regaloShaken'] = 0;
      }),

      'mantel114': (o) => run(o, () async {
        final ab = _gente['abuela'] as Map<String, dynamic>?;
        W['mantelFx'] = 1;
        if (ab != null) {
          ab['pose'] = 'yo';
          await wait(220);
          ab['pose'] = 'idle';
        } else {
          await wait(220);
        }
        W['mantelFx'] = 0;
      }),

      'sombra114': (o) => run(o, () async {
        W['sombraFx'] = 1;
        await wait(300);
        W['sombraFx'] = 0;
      }),

      'lleva114': (o) => run(o, () async {
        final que = (o['que'] as String?) ?? 'regalo';
        final ok = _n(o['ok']) == 1;
        await bounceFrog(dx: -4, dy: -4, ms: 110);
        if (ok) {
          if (que == 'regalo') {
            W['regaloAt'] = 'mesa1';
          } else if (que == 'bizcocho') {
            W['bizcochoAt'] = 'mesa2';
          } else if (que == 'flores') {
            W['floresAt'] = 'mesa3';
          }
          await bounceFrog(dx: 4, dy: -4, ms: 120);
        } else {
          // Wrong thing carried briefly, then hurried back to the bench; frog bumps curtain edge and a peg flies off!
          final prev = switch (que) {
            'regalo' => W['regaloAt'],
            'bizcocho' => W['bizcochoAt'],
            _ => W['floresAt'],
          };
          if (que == 'regalo') W['regaloAt'] = 'mesa1';
          if (que == 'bizcocho') W['bizcochoAt'] = 'mesa2';
          if (que == 'flores') W['floresAt'] = 'mesa3';
          await wait(160);
          if (que == 'regalo') W['regaloAt'] = prev ?? 'banco2';
          if (que == 'bizcocho') W['bizcochoAt'] = prev ?? 'banco1';
          if (que == 'flores') W['floresAt'] = prev ?? 'banco3';
          W['pinzaVolandoFx'] = 1;
          await wait(200);
          W['pinzaVolandoFx'] = 0;
        }
      }),

      'final114': (o) => run(o, () async {
        final n = _n(o['n']).clamp(1, 3);
        W['pinzas'] = n;
        // Luis puts the flowers on the table; everybody jumps up from behind the table (regalos-preview.html m3).
        W['regaloAt'] = 'mesa1';
        W['bizcochoAt'] = 'mesa2';
        W['floresAt'] = 'mesa3';
        W['cortinaState'] = 'shut';
        _placePerson(_gente['abuela'] as Map<String, dynamic>, 'tras_mesa');
        _placePerson(_gente['luis'] as Map<String, dynamic>, 'tras_mesa3');
        _placePerson(_gente['abuelo'] as Map<String, dynamic>, 'junto_banco');
        _placePerson(_gente['carmen'] as Map<String, dynamic>, 'arco');
        W['carmenOjos'] = n == 1 ? 1 : 0;
        W['celebrar'] = n >= 3 ? 1 : 0;
        for (final who in const ['abuela', 'luis', 'abuelo', 'carmen']) {
          (_gente[who] as Map<String, dynamic>)['dy'] = -4;
        }
        await wait(180);
        for (final who in const ['abuela', 'luis', 'abuelo', 'carmen']) {
          (_gente[who] as Map<String, dynamic>)['dy'] = 0;
        }
      }),

      /* ---------- Story 115: Las velas ---------- */
      'velas115': (o) => run(o, () async {
        // Frog carries the 7 candles from caja_velas to the cake.
        await bounceFrog(dx: -4, dy: -4, ms: 120);
        W['cajaVelasEmpty'] = 1;
        W['velasOnCake'] = 1;
        await bounceFrog(dx: 4, dy: -4, ms: 140);
      }),

      'foto115': (o) => run(o, () async {
        final cual = (o['cual'] as String?) ?? 'foto_3m';
        final ok = _n(o['ok']) == 1;
        final pos =
            (W['fotoPos'] as Map<String, String>?) ?? <String, String>{};
        W['fotoPos'] = pos;
        final peg = _pegForFoto(cual);
        await bounceFrog(dy: -4, ms: 120);
        if (ok) {
          pos[cual] = peg;
          // Let StoryRunner's 5-tick (350 ms) post-ask bounce(8) finish landing on banqueta_coqui before returning.
          await wait(260);
        } else {
          // Wrong photo hung briefly, abuelo looks, takes it back down onto its table spot; wind blows 2 candles out.
          final prev = pos[cual] ?? 'fotos1';
          pos[cual] = peg;
          await wait(180);
          W['vientoFx'] = 1;
          pos[cual] = prev;
          W['velasSmoked'] = 1;
          await wait(200);
          W['vientoFx'] = 0;
        }
      }),

      'viento115': (o) => run(o, () async {
        // Gust blows all four photos down onto fotos1..fotos4 in the drawn order.
        // OPEN: gen_regalos.py never moves the frog off mesa_coqui before dropping photos onto fotos1..4 (where
        // mesa_coqui overlaps fotos1 & fotos2). Hop frog to banqueta_coqui (matching regalos-preview.html m5).
        W['vientoFx'] = 1;
        final pos = <String, String>{};
        for (var i = 1; i <= 4; i++) {
          final k = o['fotos$i'] as String?;
          if (k != null && k.isNotEmpty) pos[k] = 'fotos$i';
        }
        if (pos.length < 4) {
          for (var i = 0; i < REGALOS_FOTOS.length; i++) {
            pos.putIfAbsent(REGALOS_FOTOS[i], () => 'fotos${i + 1}');
          }
        }
        W['fotoPos'] = pos;
        await _hopToSpot('banqueta_coqui');
        await wait(160);
        W['vientoFx'] = 0;
      }),

      'prende115': (o) => run(o, () async {
        W['abuelaFosforo'] = 1;
        W['velasOnCake'] = 1;
        W['velasLit'] = 7;
        W['velasSmoked'] = 0;
        await wait(240);
        W['abuelaFosforo'] = 0;
      }),

      'velas': (o) => run(o, () async {
        final n = _n(o['n']).clamp(0, 7);
        W['velasOnCake'] = 1;
        W['velasLit'] = n;
        if (n < 7) W['velasSmoked'] = 1;
        await wait(120);
      }),

      'final115': (o) => run(o, () async {
        final n = _n(o['n']).clamp(0, 7);
        // Abuelo hangs the remaining photos on their pegs and steps down to junto_banco.
        W['fotoPos'] = <String, String>{
          'foto_3m': 'cuerda1',
          'foto_7m': 'cuerda2',
          'foto_3a': 'cuerda3',
          'foto_7a': 'cuerda4',
        };
        _placePerson(_gente['abuelo'] as Map<String, dynamic>, 'junto_banco');
        W['velasLit'] = n;
        if (n < 7) W['velasSmoked'] = 1;
        W['celebrar'] = n >= 7 ? 1 : 0;
        await wait(200);
      }),

      'sopla115': (o) => run(o, () async {
        // Carmen blows out the remaining lit candles.
        W['velasLit'] = 0;
        W['velasSmoked'] = 1;
        final carmen = _gente['carmen'] as Map<String, dynamic>?;
        if (carmen != null) {
          carmen['dy'] = -2;
          await wait(180);
          carmen['dy'] = 0;
        } else {
          await wait(180);
        }
      }),

      /* ---------- Story 116: Para ti ---------- */
      'sorpresas': (o) => run(o, () async {
        W['sorpresas'] = _n(o['n']).clamp(1, 3);
        await wait(120);
      }),

      'etiquetas116': (o) => run(o, () async {
        W['vientoFx'] = 1;
        W['paquetesTagged'] = 0;
        await wait(240);
        W['vientoFx'] = 0;
      }),

      'pareja116': (o) => run(o, () async {
        final quien = o['quien'] as String?;
        if (quien != null && _gente[quien] is Map<String, dynamic>) {
          _placePerson(_gente[quien] as Map<String, dynamic>, 'banqueta_der');
        }
        // Abuelo puts the next packet from the table onto the low stool.
        final pm = _n(W['paquetesMesa']);
        if (pm > 1) W['paquetesMesa'] = pm - 1;
        W['paqueteStoolVis'] = 1;
        W['paqueteStoolTorn'] = 0;
        await wait(160);
      }),

      'empuja116': (o) => run(o, () async {
        final a = (o['a'] as String?) ?? 'carmen';
        final ok = _n(o['ok']) == 1;
        W['paqueteStoolVis'] = 1;
        await bounceFrog(dx: a == 'carmen' ? -3 : 3, dy: -4, ms: 120);
        if (ok) {
          final manosSet = (W['manosWho'] as Set<String>?) ?? <String>{};
          manosSet.clear();
          await wait(160);
        } else {
          // Wrong push: the giver opens it on the spot -> paper torn, bow off!
          W['paqueteStoolTorn'] = 1;
          await wait(200);
        }
      }),

      'abre116': (o) => run(o, () async {
        final quien = (o['quien'] as String?) ?? 'carmen';
        final que = (o['que'] as String?) ?? 'sombrero';
        if (quien == 'carmen' && que == 'sombrero') {
          W['carmenSombrero'] = 1;
        } else if (quien == 'abuelo' && que == 'abanico') {
          W['abueloAbanico'] = 1;
        } else if (quien == 'coqui' && que == 'sombrerito') {
          W['coquiSombrerito'] = 1;
          await bounceFrog(dy: -5, ms: 160);
        }
        await wait(180);
      }),

      'final116': (o) => run(o, () async {
        final n = _n(o['n']).clamp(1, 3);
        W['sorpresas'] = n;
        W['papelesRotos'] = (3 - n).clamp(0, 2);
        W['paqueteStoolVis'] = 1;
        W['paqueteStoolTorn'] = 0;
        W['paquetesMesa'] = 0;
        final manosSet = (W['manosWho'] as Set<String>?) ?? <String>{};
        manosSet.clear();
        W['celebrar'] = n >= 3 ? 1 : 0;
        await wait(200);
      }),

      'fin': (o) => run(o, () async {
        await bounceFrog(dy: -5, ms: 160);
        await wait(200);
      }),
    };
  }
}
