// El pedido's story 87-89 acts (part of pedido.dart).
part of 'pedido.dart';

/// Resolved screen position & non-overlapping cue anchor for a gesture target (`cabeza`, `senala`).
typedef _TargetPos = ({int sx, int sy, int cueX, int cueY, bool up, double d});

extension _PedidoActs on Pedido {
  Future<void> _run(Map<String, dynamic> o, Future<void> Function() body) {
    if (jsTruthy(o['suelto'])) {
      final f = body();
      _loose.add(f);
      return Future<void>.value();
    }
    return body();
  }

  /* ---------- acts (pedido.md "Needs" + gen_pedido.py) ---------- */

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
      final spot = (o['a'] as String?) ?? 'mesa_coqui';
      await _hopToSpot(spot);
      if (_n(W['story']) == 87 && spot == 'repisa_coqui') {
        W['gatoPose'] = 'mira';
      }
    }),
    'llega': (o) => _run(o, () async {
      final quien = (o['quien'] as String?) ?? '';
      final rawA = (o['a'] as String?) ?? '';
      final p = _gente[quien] as Map<String, dynamic>?;
      if (p == null) return;
      if (rawA == 'otra_mesa') {
        // OPEN: `otra_mesa` is a 2-seat group (`otra_mesa1`, `otra_mesa2`) with no waitress standing spot; seat
        // senor/joven at otra_mesa1 and senora/mujer at otra_mesa2 (hiding the replaced guest), and place mesera at lejos.
        if (quien == 'senor' || quien == 'joven') {
          final other = quien == 'senor' ? 'joven' : 'senor';
          (_gente[other] as Map<String, dynamic>)['vis'] = 0;
          _placePerson(p, 'otra_mesa1', sent: 1);
        } else if (quien == 'senora' || quien == 'mujer') {
          final other = quien == 'senora' ? 'mujer' : 'senora';
          (_gente[other] as Map<String, dynamic>)['vis'] = 0;
          _placePerson(p, 'otra_mesa2', sent: 1);
        } else if (quien == 'mesera') {
          _placePerson(p, 'lejos', sent: 0);
        }
      } else if (rawA == 'bandeja') {
        // OPEN: pedido-sheet.json has no `bandeja` spot; place mesero at `junto_mesa` while tray drinks stand at bebida1..3.
        _placePerson(p, 'junto_mesa', sent: 0);
        W['meseroPad'] = 0;
      } else if (_p.has(rawA)) {
        final isChair =
            rawA.startsWith('silla') || rawA.startsWith('otra_mesa');
        _placePerson(p, rawA, sent: isChair ? 1 : 0);
        if (quien == 'mesera' && rawA == 'junto_mesa') {
          W['meseraPad'] = 1;
          W['meseraPlato'] = null;
        }
        if (quien == 'mesero' && rawA == 'junto_mesa') {
          W['meseroPad'] = 1;
        }
        if (quien == 'mesera' && rawA == 'lejos' && _n(W['story']) == 87) {
          // OPEN: story 87 step 5 ("the fonda fills up") has no act; when mesera arrives at lejos for the game,
          // seat senor at otra_mesa1 and senora at otra_mesa2 (matching pedido-preview.html moments 2 and 3).
          W['meseraPad'] = 0;
          W['meseraPlato'] = null;
          _placePerson(
            _gente['senor'] as Map<String, dynamic>,
            'otra_mesa1',
            sent: 1,
          );
          _placePerson(
            _gente['senora'] as Map<String, dynamic>,
            'otra_mesa2',
            sent: 1,
          );
        }
      }
      await wait(160);
    }),
    'sale': (o) => _run(o, () async {
      final quien = (o['quien'] as String?) ?? '';
      final p = _gente[quien] as Map<String, dynamic>?;
      if (p != null) {
        p['vis'] = 0;
        if (quien == 'mesera') {
          W['meseraPad'] = 0;
          W['meseraPlato'] = null;
        }
      }
      await wait(120);
    }),
    'cuadro': (o) => _run(o, () async {
      final lit = W['litCuadros'] as Set<int>;
      final n = o['n'];
      if (n == 'todos') {
        for (var i = 1; i <= 4; i++) {
          lit.add(i);
          await wait(160);
          lit.remove(i);
        }
      } else {
        final idx = _n(n).clamp(1, 4);
        lit.add(idx);
        await wait(240);
        lit.remove(idx);
      }
    }),
    'pide87': (o) => _run(o, () async {
      final quien = (o['quien'] as String?) ?? '';
      final que = (o['que'] as String?) ?? 'sopa';
      if (quien.isNotEmpty) {
        (W['ordenes'] as Map<String, String>)[quien] = que;
      }
      await wait(180);
    }),
    'sirve87': (o) => _run(o, () async {
      final rep = W['repisa'] as List<String?>;
      for (var i = 0; i < 3; i++) {
        rep[i] = null;
      }
      final serv = W['servidos'] as Map<String, String>;
      serv['abuela'] = 'sopa';
      serv['abuelo'] = 'pescado';
      serv['carmen'] = 'ensalada';
      (W['ordenes'] as Map<String, String>).clear();
      W['meseraPlato'] = 'sopa';
      await wait(260);
      W['meseraPlato'] = null;
    }),
    'campana': (o) => _run(o, () async {
      final que = (o['que'] as String?) ?? 'carne';
      W['campanaFx'] = 1;
      W['llamaFx'] = 1;
      final rep = W['repisa'] as List<String?>;
      var slot = rep.indexOf(null);
      if (slot < 0) slot = 0;
      rep[slot] = que;
      await wait(220);
      W['campanaFx'] = 0;
      W['llamaFx'] = 0;
    }),
    'lleva87': (o) => _run(o, () async {
      final que = (o['que'] as String?) ?? 'carne';
      final a = (o['a'] as String?) ?? 'luis';
      final rep = W['repisa'] as List<String?>;
      final idx = rep.indexOf(que);
      if (idx >= 0) {
        rep[idx] = null;
      } else {
        rep[0] = null;
      }
      W['llevaPlato'] = que;
      await wait(220);
      W['llevaPlato'] = null;
      (W['servidos'] as Map<String, String>)[a] = que;
      W['vaporFx'] = 1;
      await wait(180);
      W['vaporFx'] = 0;
    }),
    'platos87': (o) => _run(o, () async {
      final rep = W['repisa'] as List<String?>;
      rep[0] = o['a'] as String?;
      rep[1] = o['b'] as String?;
      rep[2] = o['c'] as String?;
      W['meseraPlato'] = null;
      _placePerson(_gente['mesera'] as Map<String, dynamic>, 'lejos', sent: 0);
      W['campanaFx'] = 1;
      await wait(200);
      W['campanaFx'] = 0;
    }),
    'saca87': (o) => _run(o, () async {
      final cual = (o['cual'] as String?) ?? 'plato1';
      final ok = _n(o['ok']) == 1;
      final idx = (int.tryParse(cual.replaceFirst('plato', '')) ?? 1) - 1;
      final rep = W['repisa'] as List<String?>;
      final dish = (idx >= 0 && idx < 3) ? rep[idx] : null;
      final ms = _gente['mesera'] as Map<String, dynamic>;
      _placePerson(ms, 'borde', sent: 0);
      W['meseraPlato'] = dish;
      if (ok) {
        if (idx >= 0 && idx < 3) rep[idx] = null;
        await wait(220);
        _placePerson(ms, 'lejos', sent: 0);
        W['meseraPlato'] = null;
        final guest = _gente['senor'] as Map<String, dynamic>;
        guest['pose'] = 'come';
        await wait(180);
        guest['pose'] = 'idle';
      } else {
        final guest = _gente['senor'] as Map<String, dynamic>;
        for (final dx in const [-1, 1, -1, 0]) {
          guest['dx'] = dx;
          await wait(55);
        }
        W['gatoPose'] = 'pata';
        await wait(160);
        W['gatoPose'] = 'mira';
      }
    }),
    'platito': (o) => _run(o, () async {
      W['platito'] = _n(o['n']).clamp(0, 3);
      await wait(120);
    }),
    'final87': (o) => _run(o, () async {
      final n = _n(o['n']).clamp(1, 3);
      final rep = W['repisa'] as List<String?>;
      for (var i = 0; i < 3; i++) {
        rep[i] = null;
      }
      W['meseraPlato'] = null;
      _placePerson(_gente['mesera'] as Map<String, dynamic>, 'lejos', sent: 0);
      W['platito'] = n;
      // OPEN: pedido-sheet.json has no separate ending spot on the family table; place platito at bebida1 beside the frog.
      W['platitoEn'] = 'bebida1';
      W['gatoPose'] = n == 1 ? 'duerme' : (n == 2 ? 'lame' : 'sit');
      W['finalCelebrar'] = n == 3 ? 1 : 0;
      await wait(320);
    }),
    'frie88': (o) => _run(o, () async {
      final que = (o['que'] as String?) ?? 'tostones';
      final rep = W['repisa'] as List<String?>;
      if (que == 'tostones') {
        W['cocineroProp'] = 'platano';
        await wait(110);
        W['cocineroProp'] = 'sarten';
        W['llamaFx'] = 1;
        await wait(110);
        W['cocineroProp'] = 'prensa';
        await wait(110);
        W['llamaFx'] = 0;
        W['cocineroProp'] = null;
        rep[0] = 'tostones';
      } else {
        W['cocineroProp'] = 'pilon';
        W['llamaFx'] = 1;
        await wait(160);
        W['llamaFx'] = 0;
        W['cocineroProp'] = null;
        rep[1] = 'mofongo';
      }
      await wait(120);
    }),
    'tablero88': (o) => _run(o, () async {
      final orden = (o['orden'] as String?) ?? '';
      final parts = orden.split(',').where((s) => s.isNotEmpty).toList();
      if (parts.length == 4) {
        W['cuadros'] = parts;
      }
      await wait(120);
    }),
    'pide88': (o) => _run(o, () async {
      final cual = (o['cual'] as String?) ?? 'cuadro1';
      final ok = _n(o['ok']) == 1;
      final idx = (int.tryParse(cual.replaceFirst('cuadro', '')) ?? 1) - 1;
      final cuadros = (W['cuadros'] as List).cast<String>();
      final dish = (idx >= 0 && idx < cuadros.length)
          ? cuadros[idx]
          : 'carne_tostones';
      final rep = W['repisa'] as List<String?>;
      rep[0] = dish;
      rep[1] = null;
      rep[2] = null;
      W['campanaFx'] = 1;
      await wait(180);
      W['campanaFx'] = 0;
      if (ok) {
        rep[0] = null;
        await wait(160);
      } else {
        for (final gName in const ['joven', 'mujer']) {
          final g = _gente[gName] as Map<String, dynamic>;
          if (g['vis'] != 0) {
            for (final dx in const [-1, 1, -1, 0]) {
              g['dx'] = dx;
              await wait(45);
            }
          }
        }
        rep[0] = null;
      }
    }),
    'platanos': (o) => _run(o, () async {
      W['platanosVis'] = 1;
      W['platanos'] = _n(o['n']).clamp(0, 3);
      await wait(120);
    }),
    'final88': (o) => _run(o, () async {
      final n = _n(o['n']).clamp(1, 3);
      final rep = W['repisa'] as List<String?>;
      for (var i = 0; i < 3; i++) {
        rep[i] = null;
      }
      W['cocineroProp'] = 'sarten';
      W['llamaFx'] = 1;
      await wait(160);
      W['llamaFx'] = 0;
      W['cocineroProp'] = null;
      W['platanos'] = 0;
      W['platoRanaVis'] = 1;
      W['platoRana'] = n;
      // OPEN: pedido-sheet.json has no separate ending spot on the family table; place frog's plate at bebida1.
      W['platoRanaEn'] = 'bebida1';
      W['finalCelebrar'] = n == 3 ? 1 : 0;
      await wait(240);
    }),
    'bandeja89': (o) => _run(o, () async {
      final orden = (o['orden'] as String?) ?? '';
      final parts = orden.split(',').where((s) => s.isNotEmpty).toList();
      final tray = W['bandeja'] as List<String?>;
      for (var i = 0; i < 3; i++) {
        tray[i] = i < parts.length ? parts[i] : null;
      }
      W['alzaBebida'] = null;
      await wait(120);
    }),
    'alza89': (o) => _run(o, () async {
      W['alzaBebida'] = o['que'] as String?;
      await wait(200);
    }),
    'da89': (o) => _run(o, () async {
      final que = (o['que'] as String?) ?? '';
      final a = (o['a'] as String?) ?? '';
      final ok = _n(o['ok']) == 1;
      W['alzaBebida'] = null;
      final p = _gente[a] as Map<String, dynamic>?;
      if (ok) {
        final tray = W['bandeja'] as List<String?>;
        final idx = tray.indexOf(que);
        if (idx >= 0) tray[idx] = null;
        if (p != null) {
          p['pose'] = 'bebe';
          await wait(200);
          p['pose'] = 'idle';
        } else {
          await wait(160);
        }
      } else {
        if (p != null) {
          for (final dx in const [-1, 1, -1, 0]) {
            p['dx'] = dx;
            await wait(55);
          }
        } else {
          await wait(160);
        }
      }
    }),
    'sorbo89': (o) => _run(o, () async {
      W['meseroSorbo'] = 1;
      await wait(240);
      W['meseroSorbo'] = 0;
    }),
    'jugo': (o) => _run(o, () async {
      W['jugoVis'] = 1;
      W['jugo'] = _n(o['n']).clamp(0, 3);
      await wait(120);
    }),
    'final89': (o) => _run(o, () async {
      final n = _n(o['n']).clamp(1, 3);
      final tray = W['bandeja'] as List<String?>;
      for (var i = 0; i < 3; i++) {
        tray[i] = null;
      }
      W['alzaBebida'] = null;
      W['jugoVis'] = 1;
      W['jugo'] = n;
      // OPEN: pedido-sheet.json has no separate ending spot on the family table; place tall glass at bebida1 beside frog.
      W['vasitoEn'] = 'bebida1';
      W['finalCelebrar'] = n == 3 ? 1 : 0;
      await wait(320);
    }),
    'gesto': (o) => _run(o, () async {
      final quien = (o['quien'] as String?) ?? 'abuela';
      final que = (o['que'] as String?) ?? 'saluda';
      final target = o['a'] as String?;
      if (quien == 'coqui') {
        final q = W['cq'] as Map<String, dynamic>;
        if (que == 'si' || que == 'come' || que == 'bebe') {
          for (final dy in const [-2, 0, -2, 0]) {
            q['dy'] = dy;
            await wait(65);
          }
          q['dy'] = 0;
        } else {
          await wait(160);
        }
        return;
      }
      final p = _gente[quien] as Map<String, dynamic>?;
      if (p == null) return;
      if (que == 'saluda') {
        for (var i = 0; i < 4; i++) {
          p['pose'] = i % 2 == 0 ? 'saluda0' : 'saluda1';
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
      } else if (que == 'cabeza') {
        final spkAt = _atOf(p);
        final spkX = _round(spkAt.sx);
        final tgt = _targetScreen(target, W);
        final rawDir = tgt != null ? (tgt.sx - spkX).sign : 1;
        final dir = rawDir == 0 ? 1 : rawDir;
        if (tgt != null) {
          W['gestoCue'] = <String, dynamic>{
            'kind': 'cabeza',
            'quien': quien,
            'a': target,
            'self': target == quien,
            'dir': dir,
            'cueX': tgt.cueX,
            'cueY': tgt.cueY,
            'up': tgt.up,
            'd': tgt.d,
          };
        }
        for (final (dx, dy) in [(dir * 2, 1), (0, 0), (dir * 2, 1), (0, 0)]) {
          p['dx'] = dx;
          p['dy'] = dy;
          await wait(65);
        }
        p['dx'] = 0;
        p['dy'] = 0;
        W['gestoCue'] = null;
      } else if (que == 'senala') {
        final spkAt = _atOf(p);
        final spkX = _round(spkAt.sx);
        final tgt = _targetScreen(target, W);
        final isSelf = target == quien;
        final rawDir = tgt != null ? (tgt.sx - spkX).sign : 1;
        final dir = isSelf ? 0 : (rawDir == 0 ? 1 : rawDir);
        p['pose'] = isSelf ? 'yo' : (dir < 0 ? 'senala_izq' : 'senala_der');
        if (tgt != null) {
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
        if (quien == 'cocinero' &&
            target == 'platito' &&
            _n(W['story']) == 88) {
          W['cocineroProp'] = 'tres_platanos';
        }
        await wait(240);
        p['pose'] = 'idle';
        p['dx'] = 0;
        p['dy'] = 0;
        W['gestoCue'] = null;
        if (W['cocineroProp'] == 'tres_platanos') {
          W['cocineroProp'] = null;
        }
      } else if (que == 'guina') {
        W['cocineroGuina'] = 1;
        await wait(240);
        W['cocineroGuina'] = 0;
      } else if (que == 'abanico') {
        W['meseroAbanico'] = 1;
        await wait(280);
        W['meseroAbanico'] = 0;
      } else {
        // rie, mira, come, bebe
        p['pose'] = que;
        await wait(240);
        p['pose'] = 'idle';
      }
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
