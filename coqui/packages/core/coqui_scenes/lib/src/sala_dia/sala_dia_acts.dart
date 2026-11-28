// Acts of La sala, de día (place 9, La casa, un día entero, scene 3: `sala_dia`; stories 102 to 104).
// Part of sala_dia.dart: every act named in historia/notas/guiones/sala_dia.md's Needs list and
// historia/tools/gen_sala_dia.py. Acts with no spot in sala_dia-sheet.json are marked `OPEN:`.
part of 'sala_dia.dart';

typedef _TargetPos = ({int sx, int sy, int cueX, int cueY, bool up, double d});

extension _SalaDiaActs on SalaDia {
  _TargetPos? _targetScreen(String? target, Map<String, dynamic> w) {
    if (target == null || target.isEmpty) return null;
    final gente = (w['gente'] as Map<String, dynamic>?) ?? const {};
    if (gente[target] is Map) {
      final p = gente[target] as Map<String, dynamic>;
      if (p['vis'] == 0) {
        if (target == 'abuela') {
          final at = _p.at('cocina');
          final sx = _round(at.sx), sy = _round(at.sy);
          return (sx: sx, sy: sy, cueX: sx, cueY: sy - 58, up: false, d: 5.0);
        }
        return null;
      }
      final at = _atOf(p);
      final sx = _round(at.sx) + _n(p['dx']);
      final sy = _round(at.sy) + _n(p['dy']);
      final headTopOffset = switch (target) {
        'abuela' => 50,
        'abuelo' => 38,
        _ => 32,
      };
      return (
        sx: sx,
        sy: sy,
        cueX: sx,
        cueY: (sy - headTopOffset - 10).clamp(18, 180),
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
    if (const [
      'computadora',
      'ventana',
      'oreja_abuelo',
      'boca_abuelo',
    ].contains(target)) {
      final b = _p.box(target);
      final cx = b[0] + b[2] ~/ 2;
      final cy = b[1] + b[3] ~/ 2;
      return (
        sx: cx,
        sy: cy,
        cueX: cx,
        cueY: (b[1] - 9).clamp(6, 180),
        up: false,
        d: 5.0,
      );
    }
    final spot = _resolveSpot(target);
    if (_p.has(spot)) {
      final at = _p.at(spot);
      final sx = _round(at.sx), sy = _round(at.sy);
      return (
        sx: sx,
        sy: sy,
        cueX: sx,
        cueY: (sy - 18).clamp(12, 180),
        up: false,
        d: at.d + .06,
      );
    }
    return null;
  }

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
        await _hopToSpot(a);
      }),

      'llega': (o) => run(o, () async {
        final quien = o['quien'] as String?;
        final a = o['a'] as String?;
        if (quien == null || a == null) return;
        final p = _gente[quien] as Map<String, dynamic>?;
        if (p == null) return;
        final resolved = _resolveSpot(a);
        if (!_p.has(resolved)) return;
        final isSeat = const {
          'cojin1',
          'cojin2',
          'escritorio',
          'butaca',
        }.contains(resolved);
        _placePerson(p, resolved, sent: isSeat ? 1 : 0);
        // When abuela goes to the kitchen in 102 (step 5), her hands are white with flour.
        if (quien == 'abuela' &&
            resolved == 'cocina' &&
            _n(W['story']) == 102) {
          W['abuelaHarina'] = 1;
        }
        if (quien == 'abuela' &&
            resolved == 'cocina' &&
            _n(W['story']) == 103) {
          // Abuela leaves the phone with the frog beside abuelo when she heads to the kitchen.
          W['abuelaPhone'] = null;
          W['abuelaSilencio'] = 0;
          W['telefonoHolder'] = 'coqui';
        }
        await wait(160);
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
        final p = _gente[quien] as Map<String, dynamic>?;
        if (p == null) return;
        switch (que) {
          case 'harina':
            W['abuelaHarina'] = 1;
            p['pose'] = 'yo';
            await wait(240);
            p['pose'] = 'idle';
          case 'oreja':
            W['abueloDoze'] = 0;
            W['abueloEar'] = 1;
            await wait(260);
            W['abueloEar'] = 0;
          case 'silencio':
            W['abuelaSilencio'] = 1;
            await wait(280);
            W['abuelaSilencio'] = 0;
          case 'si':
            if (quien == 'abuelo') {
              W['abueloNod'] = 1;
              W['abueloSmile'] = 1;
            }
            p['dy'] = 2;
            await wait(120);
            p['dy'] = 0;
            await wait(100);
            p['dy'] = 2;
            await wait(120);
            p['dy'] = 0;
            if (quien == 'abuelo') W['abueloNod'] = 0;
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
            if (quien == 'abuelo') W['abueloSmile'] = 1;
            p['dy'] = -1;
            await wait(140);
            p['dy'] = 0;
            p['pose'] = 'idle';
          case 'cuenta':
            p['pose'] = 'senala_der';
            for (var i = 0; i < 3; i++) {
              p['dy'] = -1;
              await wait(90);
              p['dy'] = 0;
              await wait(70);
            }
            p['pose'] = 'idle';
          case 'mira':
          case 'senala':
            // In story 104 step 4, Luis shuts his notebook, picks up his ball, and looks at abuela.
            if (quien == 'luis' &&
                _n(W['story']) == 104 &&
                o['a'] == 'abuela') {
              W['luisNotebook'] = 0;
              W['luisBall'] = 1;
            }
            final tgt = _targetScreen(o['a'] as String?, W);
            final at = _atOf(p);
            final dirLeft = tgt != null && tgt.sx < _round(at.sx);
            p['pose'] = dirLeft ? 'senala_izq' : 'senala_der';
            if (tgt != null) {
              W['gestoCue'] = {
                'cueX': tgt.cueX,
                'cueY': tgt.cueY,
                'up': tgt.up,
                'd': tgt.d,
              };
            }
            await wait(240);
            W['gestoCue'] = null;
            p['pose'] = 'idle';
          default:
            await wait(140);
        }
      }),

      /* ---------- Story 102: Lee y escribe ---------- */
      'hojas': (o) => run(o, () async {
        W['papelVis'] = 1;
        W['hojas'] = _n(o['n']).clamp(0, 5);
        await wait(120);
      }),

      'lee102': (o) => run(o, () async {
        final quien = (o['quien'] as String?) ?? 'luis';
        W['libroVis'] = 1;
        W['libroOpen'] = 1;
        W['libroScribbled'] = 0;
        W['libroCon'] = quien;
        if (W['papelCon'] == quien) W['papelCon'] = null;
        await bounceFrog(dx: 3, dy: -4, ms: 120);
        W['leeFx'] = {'quien': quien, 'kind': 'barco'};
        await wait(200);
        W['leeFx'] = {'quien': quien, 'kind': 'estrella'};
        await wait(200);
        W['leeFx'] = null;
      }),

      'escribe102': (o) => run(o, () async {
        final quien = (o['quien'] as String?) ?? 'carmen';
        W['papelVis'] = 1;
        W['papelCon'] = quien;
        if (W['libroCon'] == quien) W['libroCon'] = null;
        await bounceFrog(dx: 3, dy: -4, ms: 120);
        W['escribeFx'] = {'quien': quien, 'nombres': false};
        await wait(260);
        W['escribeFx'] = null;
      }),

      'nombres102': (o) => run(o, () async {
        W['escribeFx'] = {'quien': 'carmen', 'nombres': true};
        await wait(300);
        W['escribeFx'] = null;
      }),

      'cuenta102': (o) => run(o, () async {
        final carmen = _gente['carmen'] as Map<String, dynamic>?;
        if (carmen != null) {
          carmen['pose'] = 'senala_der';
          for (var i = 0; i < 3; i++) {
            carmen['dy'] = -1;
            await wait(90);
            carmen['dy'] = 0;
            await wait(70);
          }
          carmen['pose'] = 'idle';
        }
        W['miniFrog'] = 1;
        await wait(160);
      }),

      'da102': (o) => run(o, () async {
        final que = (o['que'] as String?) ?? 'libro';
        final a = (o['a'] as String?) ?? 'luis';
        final ok = _n(o['ok']) == 1;
        await bounceFrog(dx: 4, dy: -4, ms: 110);
        if (ok) {
          if (que == 'libro') {
            W['libroOpen'] = 1;
            W['libroScribbled'] = 0;
            W['libroCon'] = a;
            if (W['papelCon'] == a) W['papelCon'] = null;
            W['leeFx'] = {'quien': a, 'kind': 'barco'};
            await wait(180);
            W['leeFx'] = {'quien': a, 'kind': 'estrella'};
            await wait(180);
            W['leeFx'] = null;
          } else {
            W['papelCon'] = a;
            if (W['libroCon'] == a) W['libroCon'] = null;
            W['escribeFx'] = {'quien': a, 'nombres': false};
            await wait(260);
            W['escribeFx'] = null;
          }
        } else {
          if (que == 'papel') {
            // Wrong: clean sheet given to a reader -> folded into a paper plane that flies out the window!
            // OPEN: sala_dia-sheet.json has no flight path; animate plane from above child (y=64) to window (108, 22).
            if (W['papelCon'] == a) W['papelCon'] = null;
            final child = _gente[a] as Map<String, dynamic>?;
            final startX = child != null ? _round(_atOf(child).sx) : 120;
            final win = _p.box('ventana');
            final wx = win[0] + win[2] ~/ 2, wy = win[1] + win[3] ~/ 2;
            for (var i = 0; i <= 4; i++) {
              final t = i / 4;
              W['avionFx'] = {
                'x': _round(startX + (wx - startX) * t),
                'y': _round(64 + (wy - 64) * t),
              };
              await wait(80);
            }
            W['avionFx'] = null;
          } else {
            // Wrong: book given to a writer -> scribbled in; Carmen tears a clean sheet to patch the page.
            final prevLibroCon = W['libroCon'];
            W['libroOpen'] = 1;
            W['libroScribbled'] = 1;
            W['libroPatched'] = 0;
            W['libroCon'] = a;
            await wait(200);
            W['libroScribbled'] = 0;
            W['libroPatched'] = 1;
            W['libroCon'] = prevLibroCon;
            await wait(180);
          }
        }
      }),

      'final102': (o) => run(o, () async {
        final n = _n(o['n']).clamp(1, 3);
        W['dibujoFinal'] = n;
        W['celebrar'] = n >= 3 ? 2 : 0;
        final carmen = _gente['carmen'] as Map<String, dynamic>?;
        if (carmen != null) {
          carmen['pose'] = 'yo';
          await wait(240);
          carmen['pose'] = 'idle';
        } else {
          await wait(240);
        }
      }),

      /* ---------- Story 103: El teléfono ---------- */
      'bateria': (o) => run(o, () async {
        final n = _n(o['n']).clamp(0, 3);
        W['bateria'] = n;
        W['bateriaBlink'] = 0;
        await wait(120);
      }),

      'suena103': (o) => run(o, () async {
        W['telefonoVis'] = 1;
        W['telefonoLit'] = 1;
        W['telefonoRing'] = 1;
        W['telefonoHolder'] = 'mesa';
        W['telefonoDonde'] = null;
        W['abuelaPhone'] = null;
        await wait(320);
        W['telefonoRing'] = 0;
      }),

      'oido103': (o) => run(o, () async {
        W['telefonoLit'] = 1;
        W['telefonoHolder'] = 'abuela';
        W['telefonoDonde'] = null;
        W['abuelaPhone'] = 'ear';
        await wait(260);
      }),

      'boca103': (o) => run(o, () async {
        W['telefonoLit'] = 1;
        W['telefonoHolder'] = 'abuela';
        W['telefonoDonde'] = null;
        W['abuelaPhone'] = 'mouth';
        await wait(260);
      }),

      'anillos103': (o) => run(o, () async {
        W['anillosFx'] = 1;
        await bounceFrog(dy: -3, ms: 160);
        await wait(160);
        W['anillosFx'] = 0;
      }),

      'pone103': (o) => run(o, () async {
        final donde = (o['donde'] as String?) ?? 'oreja_abuelo';
        final ok = _n(o['ok']) == 1;
        W['abueloDoze'] = 0;
        W['telefonoLit'] = 1;
        W['telefonoHolder'] = 'coqui';
        W['telefonoDonde'] = donde;
        W['abuelaPhone'] = null;
        await bounceFrog(dx: 3, dy: -3, ms: 110);
        if (ok) {
          if (donde == 'oreja_abuelo') {
            // Mamá's voice pictures enter abuelo's ear; abuelo smiles.
            W['abueloSmile'] = 1;
            W['vozFx'] = {'kind': 'guagua', 'x': 166, 'y': 40};
            await wait(180);
            W['vozFx'] = {'kind': 'playa', 'x': 166, 'y': 40};
            await wait(180);
            W['vozFx'] = null;
          } else {
            // Abuelo speaks: his own small pictures (fish, hat) go into the telephone.
            W['vozFx'] = {'kind': 'pez', 'x': 166, 'y': 40};
            await wait(180);
            W['vozFx'] = {'kind': 'sombrero', 'x': 166, 'y': 40};
            await wait(180);
            W['vozFx'] = null;
          }
        } else {
          // Wrong end: pictures fall to the floor (open gap at x=164, y=92..100) while a battery bar blinks!
          W['bateriaBlink'] = 1;
          final k1 = donde == 'boca_abuelo' ? 'guagua' : 'pez';
          final k2 = donde == 'boca_abuelo' ? 'playa' : 'sombrero';
          W['vozFx'] = {'kind': k1, 'x': 164, 'y': 92};
          await wait(180);
          W['vozFx'] = {'kind': k2, 'x': 164, 'y': 98};
          await wait(200);
          W['vozFx'] = null;
          W['bateriaBlink'] = 0;
        }
      }),

      'final103': (o) => run(o, () async {
        final n = _n(o['n']).clamp(1, 3);
        W['abueloHoldPhone'] = 1;
        W['telefonoHolder'] = 'abuelo';
        W['telefonoDonde'] = null;
        W['abuelaPhone'] = null;
        if (n >= 3) {
          // Three bars: sings twice; mamá's laugh comes out as hearts + stars!
          for (var i = 0; i < 2; i++) {
            W['anillosFx'] = 1;
            await bounceFrog(dy: -4, ms: 160);
            W['anillosFx'] = 0;
            await wait(100);
          }
          W['celebrar'] = 2;
        } else if (n == 2) {
          // Two bars: sings once; a heart.
          W['anillosFx'] = 1;
          await bounceFrog(dy: -4, ms: 180);
          W['anillosFx'] = 0;
          W['celebrar'] = 1;
        } else {
          // One bar: brief chirp, then screen goes dark.
          W['anillosFx'] = 1;
          await wait(140);
          W['anillosFx'] = 0;
          W['bateria'] = 0;
          W['telefonoLit'] = 0;
          W['celebrar'] = 0;
        }
        await wait(160);
      }),

      /* ---------- Story 104: Por la tarde ---------- */
      'estrellas': (o) => run(o, () async {
        W['estrellasVis'] = 1;
        W['estrellas'] = _n(o['n']).clamp(0, 3);
        await wait(120);
      }),

      'pantalla104': (o) => run(o, () async {
        W['pantalla'] = 1;
        W['luisNotebook'] = 1;
        await wait(220);
      }),

      'pagina104': (o) => run(o, () async {
        final n = _n(o['n']).clamp(1, 3);
        W['paginasVis'] = 1;
        W['paginaGlow'] = n;
        await wait(220);
        W['paginaGlow'] = 0;
      }),

      'foto104': (o) => run(o, () async {
        W['foto'] = o['que'] as String?;
        W['fotoTorn'] = 0;
        await wait(180);
      }),

      'aveces104': (o) => run(o, () async {
        // Two small pictures change places over Luis at the desk: computer, book, computer.
        for (final kind in const ['compu', 'libro', 'compu']) {
          W['avecesFx'] = kind;
          await wait(220);
        }
        W['avecesFx'] = null;
      }),

      'pega104': (o) => run(o, () async {
        final pag = (o['pagina'] as String?) ?? 'pagina2';
        final ok = _n(o['ok']) == 1;
        final idx = switch (pag) {
          'pagina1' => 1,
          'pagina2' => 2,
          'pagina3' => 3,
          _ => 2,
        };
        await bounceFrog(dx: 4, dy: -4, ms: 120);
        final photosByPage =
            (W['paginaPhotos'] as Map<int, List<String>>?) ??
            <int, List<String>>{};
        W['paginaPhotos'] = photosByPage;
        final torns = (W['paginaTorn'] as Set<int>?) ?? <int>{};
        W['paginaTorn'] = torns;
        if (ok) {
          final que = (W['foto'] as String?) ?? 'foto';
          final list = photosByPage.putIfAbsent(idx, () => <String>[]);
          list.add(que);
          W['paginaGlow'] = idx;
          W['foto'] = null;
          await wait(220);
          W['paginaGlow'] = 0;
        } else {
          // Wrong page: stuck briefly, peeled off -> corner tears -> gold star goes on the tear.
          W['paginaGlow'] = idx;
          W['fotoTorn'] = 1;
          await wait(220);
          torns.add(idx);
          W['paginaGlow'] = 0;
          await wait(180);
        }
      }),

      'final104': (o) => run(o, () async {
        final n = _n(o['n']).clamp(1, 3);
        W['foto'] = null;
        W['portadaFinal'] = n;
        W['celebrar'] = n >= 3 ? 2 : 0;
        await wait(260);
      }),

      'fin': (o) => run(o, () async {
        await bounceFrog(dy: -5, ms: 160);
        await wait(200);
      }),
    };
  }
}
