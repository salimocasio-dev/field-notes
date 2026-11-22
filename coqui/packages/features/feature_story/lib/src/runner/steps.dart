// The kinds of step, an ask, an elige, a decide, and the wait for a touch: juego.js "reading a story", "an ask", "a
// decision" and "waiting for a touch".
part of 'story_runner.dart';

/// The kind of a step: the key that chooses its branch in `paso` (juego.js lines 319 to 336), in `paso`'s own order. A
/// bare string is a line. Anything else is "bad".
String stepKind(Object? st) {
  if (st is String) return 'line';
  if (st is! Map) return 'bad';
  if (jsTruthy(st['say'])) return 'say';
  if (st['wait'] != null) return 'wait';
  if (jsTruthy(st['cam'])) return 'cam';
  if (st['dots'] != null) return 'dots';
  if (jsTruthy(st['set'])) return 'set';
  if (jsTruthy(st['if'])) return 'if';
  if (jsTruthy(st['act'])) return 'act';
  if (jsTruthy(st['ask'])) return 'ask';
  if (jsTruthy(st['decide'])) return 'decide';
  if (jsTruthy(st['elige'])) return 'elige';
  if (jsTruthy(st['draw'])) return 'draw';
  if (jsTruthy(st['reparte'])) return 'reparte';
  if (jsTruthy(st['calc'])) return 'calc';
  if (jsTruthy(st['recuerda'])) return 'recuerda';
  if (jsTruthy(st['cost'])) return 'cost';
  return 'unknown';
}

extension _Steps on StoryRunner {
  // ---------- reading a story ----------

  // juego.js: sub
  /// `$name` filled from the story's variables; anything that is not a string as it is.
  Object? sub(Object? s) {
    if (s is! String) return s;
    return s.replaceAllMapped(RegExp(r'\$([a-z]+)'), (m) {
      final v = V[m[1]!];
      return v != null ? jsString(v) : m[0]!;
    });
  }

  String subS(Object? s) => sub(s) as String;

  List<String> subList(Object? l) => [
    for (final e in (l as List? ?? const [])) subS(e),
  ];

  // juego.js: val
  Object? val(String k) => V[k] ?? W[k];

  String valString(String k) => V[k] != null
      ? jsString(V[k])
      : jsString(W[k], missing: !W.containsKey(k));

  // juego.js: cond
  bool cond(String e0) {
    var e = e0;
    final neg = e.startsWith('!');
    if (neg) e = e.substring(1);
    final i = e.indexOf('=');
    final r = i < 0
        ? jsTruthy(val(e))
        : valString(e.substring(0, i)) == subS(e.substring(i + 1));
    return neg ? !r : r;
  }

  // juego.js: vmapa
  /// A map from answers to lines, with the story's variables filled in on both sides.
  Map<String, String>? vmapa(Object? m) {
    if (m == null) return null;
    return {for (final e in (m as Map).entries) subS(e.key): subS(e.value)};
  }

  /// Every position read from a story file goes through the scene's `remap`: a map with a number `x` and a number `y`
  /// (a place on the picture) is given the place the scene says it is today, and so is where the answer cards stand
  /// (`respEn`: `[x, y]`, juego.js respBox; order 33b, h-camino beats.5). The story file is not changed: this returns a
  /// copy.
  Object? remapPositions(Object? v) {
    if (v is Map) {
      final out = <String, dynamic>{
        for (final e in v.entries) e.key as String: remapPositions(e.value),
      };
      if (v['x'] is num && v['y'] is num) {
        final r = E.remap([v['x'] as num, v['y'] as num]);
        out['x'] = r[0];
        out['y'] = r[1];
      }
      final en = v['respEn'];
      if (en is List && en.length == 2 && en[0] is num && en[1] is num) {
        out['respEn'] = E.remap([en[0] as num, en[1] as num]);
      }
      return out;
    }
    if (v is List) return [for (final e in v) remapPositions(e)];
    return v;
  }

  // juego.js: paso
  /// One step. Every kind of step is a key `paso` looks for, in its order.
  Future<void> paso0(Object? st) async {
    final kind = stepKind(st);
    switch (kind) {
      case 'line':
        ronda.add(subS(st));
        return habLinea(subS(st), null);
      case 'bad':
        throw StoryError('a step the game does not know: $st');
    }
    final m = st as Map<String, dynamic>;
    switch (kind) {
      case 'say':
        ronda.add(subS(m['say']));
        return habLinea(subS(m['say']), m['gap'] as num?);
      case 'wait':
        return wait(m['wait'] as num);
      case 'cam':
        return camGo(m['cam'] as String, (m['n'] as num?)?.toInt());
      case 'dots':
        ronda.clear();
        step(m['dots'] as num);
        return;
      case 'set':
        // Object.assign(W, st.set)
        final set = remapPositions(m['set']) as Map<String, dynamic>;
        W.addAll(set);
        return;
      case 'if':
        return pasos(
          (cond(m['if'] as String) ? m['then'] : m['else']) as List<Object?>?,
        );
      case 'act':
        final o = <String, dynamic>{
          for (final e in m.entries) e.key: sub(e.value),
        };
        final fn = E.acts[m['act']];
        if (fn == null) throw StoryError('the scene has no act ${m['act']}');
        return fn(o);
      case 'ask':
        return _ask(m);
      case 'decide':
        return _decide(m);
      case 'elige':
        return _elige(m);
      case 'draw':
        final ops = subList(m['options']);
        final f = options.forced[m['draw'] as String];
        final v = f != null && ops.contains(f)
            ? f
            : ops[(rng.next() * ops.length).floor()];
        V[m['draw'] as String] = v;
        if (jsTruthy(m['other'])) {
          V[m['other'] as String] = ops.cast<String?>().firstWhere(
            (x) => x != v,
            orElse: () => null,
          );
        }
        return;
      case 'reparte':
        // deals the options out to several names, none twice; ?name=value fixes one
        final ops = [for (final e in m['options'] as List) e as String?];
        for (var i = ops.length - 1; i > 0; i--) {
          final j = (rng.next() * (i + 1)).floor();
          final t = ops[i];
          ops[i] = ops[j];
          ops[j] = t;
        }
        final names = [for (final k in m['reparte'] as List) k as String];
        for (final k in names) {
          final f = options.forced[k];
          if (f != null && ops.contains(f)) {
            ops.removeAt(ops.indexOf(f));
            V[k] = f;
          } else {
            V[k] = null;
          }
        }
        for (final k in names) {
          if (V[k] == null) V[k] = ops.isEmpty ? null : ops.removeAt(0);
        }
        return;
      case 'calc':
        V[m['calc'] as String] = cond(m['cond'] as String)
            ? sub(m['then'])
            : sub(m['else']);
        return;
      case 'recuerda':
        final k = m['recuerda'] as String;
        MEM[k] = subS(jsString(m['valor']));
        V['mem_$k'] = MEM[k];
        _saveMemory('mem', MEM);
        return;
      case 'cost':
        W['lost'] = (W['lost'] as num).toInt() + 1;
        return E.stake(
          W['lost'] as int,
          ((S['stake'] as Map)['steps'] as num).toInt(),
          subS(jsTruthy(m['en']) ? m['en'] : ''),
        );
    }
    throw StoryError('a step the game does not know: $st');
  }

  // ---------- an ask, with the big sign ----------

  // juego.js: baraja
  List<T> barajaList<T>(List<T> a) {
    final l = List<T>.of(a);
    for (var i = l.length - 1; i > 0; i--) {
      final j = (rng.next() * (i + 1)).floor();
      final t = l[i];
      l[i] = l[j];
      l[j] = t;
    }
    return l;
  }

  String? _bienId(Map<String, dynamic> st) =>
      st['bien'] is String ? st['bien'] as String : null;

  // juego.js: espera, as the recording tool wraps it
  Future<Pending> _esperaW(
    List<String> liveSet,
    List<Object?>? lead,
    String? line,
    EsperaOpts o,
  ) => obs.espera(() => _espera(liveSet, lead, line, o), () => pending, line);

  bool _quiet(Map<String, dynamic> st) =>
      sub(st['quieto']) == '1' || st['quieto'] == true;

  // juego.js: ask
  /// An ask, with the big sign. Nothing can go wrong here.
  Future<void> _ask(Map<String, dynamic> st) async {
    final t = subS(st['ask']),
        voz = vmapa(st['voces']),
        said = vmapa(st['said']);
    // an ask can use answer bubbles too: this is where a new kind of bubble is taught, with the big sign
    if (jsTruthy(st['resp']) && !OIR) {
      W['resp'] = subList(st['resp']);
      if (jsTruthy(st['baraja'])) W['resp'] = baraja(W['resp'] as List<String>);
      W['respVoz'] = voz;
    }
    final sa = said != null ? said[t] : null;
    // the target's said clip is marked "tu_turno": he may say the answer
    final tu = sa != null && sa.isNotEmpty && habVivo([sa])
        ? habMarca(sa)
        : null;
    final line = jsTruthy(st['line']) ? subS(st['line']) : null;
    final me = await _esperaW(
      [t],
      st['lead'] as List<Object?>?,
      line,
      EsperaOpts(
        sign: t,
        loose: jsTruthy(st['loose']),
        voces: voz,
        orden: voz != null ? (W['resp'] as List?)?.cast<String>() : null,
        turno: tu != null ? Turno.ask(sa!, tu) : null,
      ),
    );
    senal(t, me.p, _quiet(st));
    if (me.hablado) {
      await me.okP;
    } else if (sa != null && sa.isNotEmpty) {
      await wait(250);
      W['resp'] = null;
      await say(sa, 200);
    }
    W['resp'] = null;
    await pasos(st['after'] as List<Object?>?);
    await bien(_bienId(st));
    await pasos(st['then'] as List<Object?>?);
  }

  // ---------- he picks what the frog says, and there is no wrong answer ----------

  // juego.js: elige
  Future<void> _elige(Map<String, dynamic> st) async {
    final ops = [for (final o in st['options'] as List) o as String];
    W['respVoz'] = null;
    W['resp'] = st['kind'] == 'say' && !OIR ? ops : null;
    final saidMap = st['said'] as Map?;
    final ids = [
      for (final k in ops)
        saidMap != null && jsTruthy(saidMap[k]) ? subS(saidMap[k]) : '',
    ];
    Turno? tu;
    if (ids.every((s) => s.isNotEmpty) && habVivo(ids)) {
      tu = Turno.elige(ids, ops, {
        for (var i = 0; i < ops.length; i++) ops[i]: habMarca(ids[i])!,
      });
    }
    final line = jsTruthy(st['line']) ? subS(st['line']) : null;
    final me = await _esperaW(
      ops,
      st['lead'] as List<Object?>?,
      line,
      EsperaOpts(kind: 'elige', turno: tu),
    );
    V['elegido'] = me.got;
    LOG.add(Decision(word: null, asked: 'libre', got: me.got, ok: true));
    SFX.blip();
    bounce(5);
    final said = saidMap != null && me.got != null ? saidMap[me.got] : null;
    if (me.hablado) {
      await me.okP;
    } else if (jsTruthy(said)) {
      await wait(250);
      W['resp'] = null;
      await say(subS(said), 300);
    }
    W['resp'] = null;
    await pasos(st[me.got] as List<Object?>?);
  }

  // ---------- a decision ----------

  // juego.js: decide
  // Two things he could do; only the Spanish says which. A wrong one costs a step of the thing at stake, what he did
  // stays done, and then the big sign shows the right one.
  Future<void> _decide(Map<String, dynamic> st) async {
    var ops = subList(st['options']);
    final asKey = jsTruthy(st['as']) ? st['as'] as String : null;
    final key = '$storyId.${asKey ?? 'x'}',
        voz = vmapa(st['voces']),
        said = vmapa(st['said']);
    late String pick;
    if (jsTruthy(st['baraja'])) {
      ops = baraja(ops); // which side each answer bubble is on is drawn fresh
    }
    if (jsTruthy(st['pick'])) {
      pick = subS(st['pick']);
    } else {
      final forced = options.forced[asKey ?? ''], last = ULT[key];
      if (forced != null && ops.contains(forced)) {
        pick = forced;
      } else if (jsTruthy(st['alterna']) && ops.contains(last)) {
        pick = ops.firstWhere((x) => x != last);
      } else {
        pick = ops[(rng.next() * ops.length).floor()];
      }
      ULT[key] = pick;
      _saveMemory('ult', ULT);
    }
    if (asKey != null) V[asKey] = pick;
    if (jsTruthy(st['other'])) {
      V[st['other'] as String] = ops.cast<String?>().firstWhere(
        (x) => x != pick,
        orElse: () => null,
      );
    }
    // burbujas: speaking bubbles that stand beside the things he can touch. gratis: answers that cost nothing: their
    // steps run and he chooses again
    final bur = subList(st['burbujas']);
    final gratis = st['gratis'] as Map<String, dynamic>?;
    if (st['decide'] == 'say' && !OIR) {
      W['resp'] = ops;
      W['respVoz'] = voz;
    } else if (bur.isNotEmpty && !OIR) {
      W['resp'] = bur;
      W['respVoz'] = voz;
    }
    final line = jsTruthy(st['line']) ? subS(st['line']) : null,
        vale = subList(st['vale']),
        enRonda = List<String>.of(ronda);
    late Pending me;
    var otra = false;
    for (;;) {
      me = await _esperaW(
        [...ops, ...vale, ...bur],
        otra ? const [] : st['lead'] as List<Object?>?,
        line,
        EsperaOpts(
          lock: jsTruthy(st['lock']),
          kind: 'decide',
          pick: pick,
          voces: otra ? null : voz,
          orden: voz != null && !otra ? (bur.isNotEmpty ? bur : ops) : null,
          mudo: jsTruthy(st['mudo']) || otra,
          ayuda: jsTruthy(st['libre']) ? pick : null,
          alias: st['alias'] as Map<String, dynamic>?,
          ronda: enRonda,
        ),
      );
      if (gratis != null &&
          jsTruthy(gratis[me.got]) &&
          me.got != pick &&
          !OIR) {
        SFX.blip();
        bounce(5);
        await wait(200);
        if (said != null && jsTruthy(said[me.got])) {
          await say(said[me.got]!, 300);
        }
        await pasos(gratis[me.got] as List<Object?>?);
        otra = true;
        continue;
      }
      break;
    }
    final first = me.got == pick || vale.contains(me.got);
    V['ok'] = first ? '1' : '';
    V['x'] = me.got;
    if (!OIR && !jsTruthy(st['libre'])) {
      final w0 = subS(jsTruthy(st['tests']) ? st['tests'] : pick);
      final palabras = S['palabras'];
      final w = palabras is Map && jsTruthy(palabras[w0])
          ? palabras[w0] as String
          : w0;
      if (w != '-') {
        LOG.add(
          Decision(
            word: w,
            asked: pick,
            got: me.got,
            ok: first,
            ms: me.ms ?? 0,
          ),
        );
      }
    }
    if (said != null && jsTruthy(said[me.got])) {
      SFX.blip();
      bounce(5);
      await wait(250);
      W['resp'] = null;
      await say(said[me.got]!, 300);
    }
    W['resp'] = null;
    if (jsTruthy(st['do'])) await _act(st['do'] as String, {'en': me.got});
    if (!first && jsTruthy(st['libre'])) {
      // Haz esto: a wrong touch costs nothing. "No." and the name of what he touched; then the sign.
      await wait(300);
      SFX.bonk();
      final k = '${course.fixedClip('story_routine_no_prefix')}${me.got}';
      final names = S['names'];
      final nm = names is Map ? names[me.got] as String? : null;
      if (LINES[k] != null) {
        await say(k, 300);
      } else if (nm != null && nm.isNotEmpty && LINES[nm] != null) {
        await say(nm, 300);
      }
    } else if (!first) {
      await wait(500);
      final costs = jsonEncode(st['wrong'] ?? const []).contains('"cost"');
      await pasos(st['wrong'] as List<Object?>?);
      if (!costs) {
        W['lost'] = (W['lost'] as num).toInt() + 1;
        await E.stake(
          W['lost'] as int,
          ((S['stake'] as Map)['steps'] as num).toInt(),
          me.got ?? '',
        );
      }
    }
    if (!first) {
      if (jsTruthy(st['noretry'])) {
        return; // one guess: the story shows the right one, then goes on
      }
      final habla = st['decide'] == 'say' || bur.contains(pick);
      if (st['decide'] == 'say') {
        W['resp'] = ops;
        W['respVoz'] = voz;
      } else if (bur.contains(pick)) {
        W['resp'] = bur;
        W['respVoz'] = voz;
      }
      me = await _esperaW(
        [pick],
        const [],
        line,
        EsperaOpts(
          sign: pick,
          voces: habla ? voz : null,
          orden: habla && voz != null ? [pick] : null,
          alias: st['alias'] as Map<String, dynamic>?,
          mudo: jsTruthy(st['mudo']),
          ronda: enRonda,
        ),
      );
      W['resp'] = null;
      if (jsTruthy(st['do'])) await _act(st['do'] as String, {'en': pick});
      if (habla && said != null && jsTruthy(said[pick])) {
        SFX.blip();
        bounce(5);
        await wait(200);
        await say(said[pick]!, 250);
      }
    }
    senal(pick, st['decide'] == 'say' ? null : me.p, _quiet(st));
    if (st['bien'] != false) await bien(_bienId(st));
    await pasos(st['right'] as List<Object?>?);
  }

  Future<void> _act(String name, Map<String, dynamic> o) {
    final fn = E.acts[name];
    if (fn == null) throw StoryError('the scene has no act $name');
    return fn(o);
  }

  // ---------- waiting for a touch ----------

  // juego.js: espera
  // Wait for a touch on one of the live things. A touch on one of them counts from the first word of the lead-in.
  Future<Pending> _espera(
    List<String> liveSet,
    List<Object?>? lead,
    String? line,
    EsperaOpts o,
  ) async {
    final my = runId;
    final me = Pending(
      live: liveSet,
      line: line,
      loose: o.loose,
      lock: o.lock || o.voces != null,
      sign: o.turno != null && o.turno!.kind == 'ask' ? null : o.sign,
      kind: o.kind ?? 'ask',
      pick: o.pick,
      alias: o.alias,
    );
    pending = me;
    for (final st in lead ?? const <Object?>[]) {
      if (me.done) break;
      if (st is String) {
        W['twinkle'] = me.sign;
        await say(subS(st));
      } else {
        W['twinkle'] = null;
        await paso(st);
      }
    }
    W['twinkle'] = null;
    int? timer;
    final voz = o.voces != null ? (o.orden ?? liveSet) : const <String>[];
    me.voz = voz.isNotEmpty;
    // each speaking bubble says its line in turn, with no words on screen: he picks by ear
    Future<void> voces() async {
      for (var i = 0; i < voz.length; i++) {
        if (me.done || !identical(pending, me) || my != runId) break;
        final id = o.voces![voz[i]];
        W['respOn'] = voz[i];
        SINLETRAS = true;
        if (id != null && VOICE && _has(id)) {
          await playClip(id);
        } else {
          await sleep(dur(id ?? '') * 1000 / FAST);
        }
        SINLETRAS = false;
        W['respOn'] = null;
        if (i < voz.length - 1) await sleep(700 / FAST);
      }
      W['respOn'] = null;
    }

    me.repite = () {
      if (identical(pending, me) &&
          !me.done &&
          my == runId &&
          speaking == 0 &&
          !me.rep &&
          !_habOcupado()) {
        me.rep = true;
        me.nrep++;
        // a routine: after the second repeat the sign shows what to touch
        if (o.ayuda != null && o.ayuda!.isNotEmpty && me.nrep >= 2) {
          W['spot'] = o.ayuda;
        }
        // a decision's round with more than one line (two people speak, or one says two things): the whole round
        // again, in order (page 13, orders 58 to 61); otherwise its line alone, as before
        final r = o.ronda;
        Future<void> first;
        if (r != null && r.length > 1) {
          first = playClip(r[0]).then((_) => sleep(300 / FAST));
          for (final l in r.skip(1)) {
            first = first
                .then((_) => playClip(l))
                .then((_) => sleep(300 / FAST));
          }
        } else {
          first = line != null && line.isNotEmpty
              ? playClip(line).then((_) => sleep(300 / FAST))
              : Future<void>.value();
        }
        // during a turn the question is repeated, the bubbles do not speak
        first.then((_) => me.turnoOn ? null : voces()).then((_) {
          me.rep = false;
        });
      }
    };
    if (OIR) {
      // told straight through: the story answers itself
      if (line != null && line.isNotEmpty) await say(line, 350);
      final w = o.pick != null && o.pick!.isNotEmpty
          ? o.pick!
          : (o.sign != null && o.sign!.isNotEmpty ? o.sign! : liveSet[0]);
      final b = bx(w);
      me.done = true;
      me.got = w;
      me.ms = 0;
      me.p = (x: jsRound(b[0] + b[2] / 2), y: jsRound(b[1] + b[3] / 2));
      pending = null;
      return me;
    }
    if (!me.done) {
      final bool dijo =
          o.turno != null && o.turno!.kind == 'ask' && habVivo([o.turno!.id!])
          ? await turnoAsk(me, o, line, my)
          : false; // his turn inside a signed ask: true when he said the answer
      if (!dijo) {
        me.sign = o.sign;
        if (o.sign != null && o.sign!.isNotEmpty) W['spot'] = o.sign;
        final tuE =
            o.turno != null &&
            o.turno!.kind == 'elige' &&
            !me.done &&
            habVivo(o.turno!.ids);
        if (tuE) turnoEligeInicio(me, o);
        if (!me.voz) me.asked = true;
        if (line != null && line.isNotEmpty && !o.mudo) {
          await say(line, me.voz ? 300 : 0);
        }
        if (!me.done) await voces();
        me.asked = true; // the bubbles are dead until both have spoken once
        me.tEnd = now();
        if (tuE && !me.done) unawaited(turnoElige(me, o, my));
        // he waits: the line plays again. It costs nothing.
        if (!me.done && ((line != null && line.isNotEmpty) || me.voz)) {
          timer = timers.setInterval(me.repite, 9000 / FAST);
        }
      }
    }
    await me.gotFuture;
    timers.clear(timer);
    if (me.turnoOn && !me.hablado) habCorta();
    if (identical(pending, me)) pending = null;
    W['spot'] = null;
    W['twinkle'] = null;
    W['respOn'] = null;
    if (my != runId) throw const StopSignal();
    return me;
  }
}
