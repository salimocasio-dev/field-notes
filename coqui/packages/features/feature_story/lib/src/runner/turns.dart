// Speaking turns: juego.js "speaking turns". The rules are docs/hablar/01-decisiones.md.
//
// A coquí clip marked "tu_turno" (its targets, each with the forms that count) is his turn when every target word is
// open for speaking, the Yo switch is on and the phone can recognise speech: the coquí's bubble shows only a mic, he
// taps the mic and says the line, the app hears it. Called ONLY from paso() (a plain line), ask() (the target's said
// clip) and elige() (the options' said clips); never from decide(), say() or playClip(). A turn never costs anything
// and never blocks.
part of 'story_runner.dart';

/// The errors that say speaking cannot work here (juego.js: `NODISP`).
const List<String> _nodisp = [
  'not-allowed',
  'service-not-allowed',
  'network',
  'audio-capture',
  'language-not-supported',
];

/// juego.js: `habClase`.
String _habClase(HabResult r) => r.cancel
    ? 'cancel'
    : _nodisp.contains(r.err)
    ? 'nodisp'
    : (r.alts != null && r.alts!.isNotEmpty)
    ? 'voz'
    : 'miss';

extension _Turns on StoryRunner {
  /// Whether the story's turns may use the mic at all: the recogniser's switches (juego.js: `habDisp`).
  bool _habDisp() =>
      !options.micOff && (options.micStub != null || _speechOk) && !session.unavailable;

  // juego.js: habPon
  /// An error showed that speaking cannot work here: no more turns this session.
  void habPon() => session.unavailable = true;

  // juego.js: habMarca
  /// The targets of a marked clip, or null.
  List<Target>? habMarca(String id) {
    final cl = LINES[id];
    final t = cl is Map ? cl['tu_turno'] : null;
    if (t is! List || t.isEmpty) return null;
    final out = <Target>[];
    for (final x in t) {
      if (x is! Map) return null;
      final p = x['palabra'], f = x['formas'];
      if (p is! String || f is! List || f.isEmpty) return null;
      out.add((palabra: p, formas: [for (final e in f) e as String]));
    }
    return out;
  }

  // juego.js: habAbierta
  bool habAbierta(String w) => options.allOpen || progress.openForSpeaking(w);

  // juego.js: habNueva
  /// He has not said this word yet: the model comes first.
  bool habNueva(String w) {
    final r = progress.word(w);
    return !(r != null && r.mouth.n > 0);
  }

  // juego.js: habBase
  bool habBase() =>
      !OIR &&
      !jsTruthy(S['callado']) &&
      progress.setting('habla') != 0 &&
      _habDisp();

  // juego.js: habVivo
  /// [ids]: the clips one turn is made of (one for a plain line or an ask, one per option for an elige). Live: first
  /// live occurrence in this play, fewer than 4 turns so far, every target word open.
  bool habVivo(List<String> ids) {
    if (ids.isEmpty || HAB.n >= 4 || !habBase()) return false;
    return ids.every((id) {
      final t = habMarca(id);
      return t != null && !HAB.hechos.contains(id) && t.every((x) => habAbierta(x.palabra));
    });
  }

  // juego.js: habCuadra
  /// Heard right: for EVERY target at least one accepted form is inside one of the alternatives (words whole, accents
  /// and case ignored, extra words fine).
  bool habCuadra(List<String>? alts, List<Target> T) {
    final ns = [for (final a in alts ?? const <String>[]) normalize(a)];
    return T.every(
      (x) => x.formas.any((f) {
        final g = normalize(f).trim();
        return g != '' && ns.any((a) => a.contains(' $g '));
      }),
    );
  }

  // juego.js: habGraba
  /// The mouth record: one answer per target word. The ear record is never written here.
  void habGraba(List<Target> T, bool ok, int? ms) {
    if (!options.recordsProgress) return;
    for (final x in T) {
      progress.answer(x.palabra, Skill.mouth, ok: ok, ms: ms ?? 0, intro: false);
    }
  }

  // juego.js: habOcupado
  bool _habOcupado() => HAB.est == 'listening' || HAB.est == 'processing';

  // juego.js: habRana
  /// The frog is on screen.
  bool habRana() {
    final q = W['cq'];
    if (q is! Map<String, dynamic> || !jsTruthy(q['vis'])) return false;
    final b = px.frogBox(q), x = b.x + b.w / 2, y = b.y + b.h / 2;
    return x >= cam[0] && x <= cam[0] + cam[2] && y >= cam[1] && y <= cam[1] + cam[3];
  }

  // ---------- the screen of a turn ----------

  // juego.js: micEst
  /// The mic button's state; the turn's bubble agrees with it.
  void micEst(String s) {
    HAB.est = s;
    _habBubE(s);
    view.mic = s;
    view.changed();
  }

  // juego.js: habBubE
  // the turn's bubble agrees with the button: the mic icon (pulsing, in green, while he is listened to), three dots
  // while the app is thinking
  void _habBubE(String s) {
    if (!MBUB || (view.bubbleKind != BubbleKind.mic && view.bubbleKind != BubbleKind.dots)) return;
    view.bubbleEstate = s;
    if (s == 'processing' && view.bubbleKind != BubbleKind.dots) {
      view.bubbleKind = BubbleKind.dots;
    } else if (s != 'processing' && view.bubbleKind == BubbleKind.dots) {
      view.bubbleKind = BubbleKind.mic;
    }
  }

  // juego.js: habBub
  /// The coquí's bubble with only a mic icon ([k] "mic"), or the green tick ([k] "ok") with his words [txt].
  void habBub(String k, [String? txt]) {
    timers.clear(_bubT);
    view.bubbleKind = k == 'ok'
        ? BubbleKind.tick
        : HAB.est == 'processing'
        ? BubbleKind.dots
        : BubbleKind.mic;
    view.bubbleEstate = HAB.est;
    view.bubbleText = txt ?? '';
    MBUB = true;
    view.bubbleOn = true;
    if (HAB.q.isEmpty) {
      // where it sits is decided once for the whole turn: at the frog if he is on screen and the bubble covers
      // neither a person nor an answer bubble, else just above the mic button
      BUBQ = habRana() ? 'coqui' : 'mic';
      HAB.q = BUBQ == 'coqui' && _habCubre() ? 'mic' : BUBQ!;
    }
    BUBQ = HAB.q;
    view.bubbleWho = BUBQ;
    view.changed();
  }

  // juego.js: habCubre
  /// Would the bubble, where it stands beside or above the frog, cover a person or one of the answer bubbles? With no
  /// screen to measure it (`bubbleMetrics` null) it covers nothing.
  bool _habCubre() {
    final m = bubbleMetrics?.call();
    if (m == null) return false;
    final q = W['cq'] as Map<String, dynamic>, f = px.frogBox(q);
    final pl = placeBubble(
      who: 'coqui',
      cam: cam,
      cw: m.cw,
      ch: m.ch,
      bw: m.bw,
      bh: m.bh,
      frog: f,
      frogDy: q['dy'] as num,
      at: donde('coqui'),
    );
    if (pl == null) return false;
    final l = pl.left, t = pl.top, bw = m.bw, bh = m.bh;
    // the bubble with its tail
    final List<double> r = switch (pl.mode) {
      BubbleSideMode.right => [l - 11, t - bh / 2, bw + 11, bh],
      BubbleSideMode.left => [l - bw, t - bh / 2, bw + 11, bh],
      BubbleSideMode.above => [l - bw / 2, t - 10 - bh, bw, bh + 11],
    };
    final zx = m.cw / cam[2], zy = m.ch / cam[3];
    bool hit(List<double> a) =>
        r[0] < a[0] + a[2] && r[0] + r[2] > a[0] && r[1] < a[1] + a[3] && r[1] + r[3] > a[1];
    List<double> art(List<num> b, num mg) => [
      (b[0] - mg - cam[0]) * zx,
      (b[1] - mg - cam[1]) * zy,
      (b[2] + 2 * mg) * zx,
      (b[3] + 2 * mg) * zy,
    ];
    final resp = W['resp'];
    if (resp is List) {
      for (final k in resp) {
        final b = respBox(k as String);
        if (b != null && hit(art(b, 3))) return true;
      }
    }
    final gente = W['gente'];
    final who = <String>[if (gente is Map) ...gente.keys.cast<String>()];
    if (jsTruthy(W['ab'])) who.add('abuela');
    return who.any((k) {
      final a = E.talkAt(k, W);
      if (a == null) return false;
      // a person is where talkAt says (above his head); abuela in the first scenes has her own box
      List<num>? b = k == 'abuela' ? E.box('abuela', W) : null;
      if (b == null) {
        final p = (gente is Map && gente[k] is Map)
            ? gente[k] as Map
            : (W['ab'] is Map ? W['ab'] as Map : const {});
        final y = p['y'];
        b = [a[0] - 13, a[1] + 1, 26, math.max(24, y is num ? y - a[1] - 1 : 36)];
      }
      return hit(art(b, 4));
    });
  }

  // juego.js: habFin
  /// The turn's screen goes away.
  void habFin() {
    HAB.q = '';
    micEst('');
    MBUB = false;
    view.bubbleOn = false;
    view.bubbleText = '';
    view.bubbleEstate = '';
    BUBQ = null;
    view.bubbleWho = null;
    view.changed();
  }

  // juego.js: habTick
  /// The green tick always; his words in the bubble when TXT allows.
  void habTick(String txt) {
    micEst('ok');
    habBub('ok', TXT != TxtMode.no && !SINLETRAS ? txt : '');
  }

  // juego.js: habOkP
  /// The tick stays a moment, then the turn's screen goes.
  Future<void> habOkP(String txt) {
    habTick(txt);
    final p = wait(750).then((_) => habFin());
    p.ignore();
    return p;
  }

  // juego.js: habCorta
  /// Everything that a turn holds, let go: a new play, the X, or he touched an elige.
  void habCorta() {
    for (final id in HAB.t) {
      timers.clear(id);
    }
    HAB.t = [];
    final rec = HAB.rec;
    if (rec != null) {
      rec.cancel();
      HAB.rec = null;
    }
    final C = HAB.cur;
    HAB.cur = null;
    if (C != null) {
      timers.clear(C.idle);
      C.listo = true;
      if (!C.res.isCompleted) C.res.complete(HabResult(cancel: true));
    }
    habFin();
  }

  // juego.js: habLimpia
  void habLimpia() {
    habCorta();
    HAB.n = 0;
    HAB.hechos = {};
  }

  // ---------- one attempt ----------

  // juego.js: habIntento
  /// The mic is ready until he taps it; every 9 s of waiting, [repite] (the line that asks him again).
  Future<HabResult> habIntento(void Function()? repite) {
    final C = HabAttempt(Completer<HabResult>());
    HAB.cur = C;
    micEst('ready');
    if (repite != null) {
      C.idle = timers.setInterval(() {
        if (HAB.est == 'ready' && speaking == 0) repite();
      }, 9000 / FAST);
    }
    return C.res.future;
  }

  // juego.js: habStub
  /// The next stub result: the results are used in order; when they run out, he says nothing.
  ({String? err, List<String>? alts}) habStub() {
    final stub = options.micStub!;
    final i = HAB.si++;
    final r = i < stub.length && stub[i].isNotEmpty ? stub[i] : 'none';
    if (r == 'none') return (err: 'no-speech', alts: null);
    if (r.startsWith('error:')) {
      final c = r.substring(6);
      return (err: c.isEmpty ? 'error' : c, alts: null);
    }
    return (err: null, alts: r.split('/'));
  }

  // juego.js: habEmpieza
  void habEmpieza(HabAttempt C) {
    timers.clear(C.idle);
    hush(); // nothing is playing while he is listened to
    HAB.guard = true;
    micEst('listening');
    final t0 = now();
    int? onset;
    List<String>? alts;
    var err = '';
    void fin() {
      if (C.listo) return;
      C.listo = true;
      for (final id in HAB.t) {
        timers.clear(id);
      }
      HAB.t = [];
      HAB.rec = null;
      if (identical(HAB.cur, C)) HAB.cur = null;
      // ms: the tap to the recogniser's speechstart; 0 when there was none
      C.res.complete(HabResult(alts: alts, err: err, ms: onset != null && onset != 0 ? onset! - t0 : 0));
    }

    void proc() {
      if (HAB.est == 'listening') micEst('processing');
    }

    if (options.micStub != null) {
      // the stub keeps its own pace (not sped up by ?fast), so every state can be seen
      final r = habStub();
      void T(void Function() f, num ms) => HAB.t.add(timers.setTimeout(f, ms));
      if (r.alts != null) {
        T(() => onset = now(), 120);
        T(proc, 300);
        T(() {
          alts = r.alts;
          fin();
        }, 420);
      } else {
        T(() {
          err = r.err!;
          fin();
        }, r.err == 'no-speech' ? 500 : 150);
      }
      return;
    }
    final turn = speech.listen(
      locale: 'es-US',
      limit: Duration(milliseconds: (6000 / FAST).floor()),
      maxAlternatives: 5,
    );
    HAB.rec = turn;
    unawaited(turn.speechEnd.then((_) => proc(), onError: (Object _) {}));
    turn.result.then(
      (r) {
        alts = r.alternatives.isEmpty ? null : r.alternatives;
        err = r.error ?? '';
        if (r.msToSound != null) onset = t0 + (r.msToSound ?? 0);
        fin();
      },
      onError: (Object _) {
        err = 'aborted';
        fin();
      },
    );
  }

  // ---------- a plain line ----------

  // juego.js: habLinea
  /// A plain line (called from paso): his turn, or the line as today. Inside the lead of an ask or decide a touch may
  /// arrive at any time: no turn there.
  Future<void> habLinea(String id, num? gap) async {
    if (!habVivo([id]) || (pending != null && !pending!.done)) return say(id, gap);
    return turnoLinea(id, habMarca(id)!, gap);
  }

  // juego.js: turnoLinea
  Future<void> turnoLinea(String id, List<Target> T, num? gap) async {
    final my = runId;
    HAB.hechos.add(id);
    HAB.n++;
    final reg = <String, dynamic>{'id': id, 'tipo': 'linea', 'est': '', 'intentos': 0};
    HAB.log.add(reg);
    micEst('dead');
    if (T.any((x) => habNueva(x.palabra))) {
      // a word he has not said yet: the coquí's recording first, then "Ahora tú."
      await say(id, gap);
      await say(course.fixedClip('story_your_turn'), 200);
    }
    habBub('mic');
    for (var n = 1;; n++) {
      final r = await habIntento(() => unawaited(playClip(course.fixedClip('story_your_turn'))));
      if (my != runId) throw const StopSignal();
      final k = _habClase(r);
      reg['intentos'] = n;
      if (k == 'nodisp') {
        habPon();
        reg['est'] = 'nodisp';
        habFin();
        return say(id, gap); // speaking cannot work: the line plays as today, nothing recorded
      }
      if (k == 'voz' && habCuadra(r.alts, T)) {
        reg['est'] = 'ok';
        habGraba(T, true, r.ms);
        habTick(r.alts![0]);
        senal('coqui', null, false);
        await wait(750);
        habFin();
        return; // his voice was the line: the recording does not play again
      }
      if (n == 1) {
        micEst('dead');
        await say(course.fixedClip('story_your_turn'), 200);
        continue; // first miss: "Ahora tú." again, the mic ready again
      }
      reg['est'] = 'fallo';
      habGraba(T, false, r.ms);
      habFin();
      SFX.suave();
      await wait(250);
      return say(id, gap); // second miss: a soft sound, the model, and on
    }
  }

  // ---------- inside a signed ask ----------

  // juego.js: turnoAsk
  /// He answers from the picture and the question. No sign and no speaking bubbles until two misses. true: he said it.
  Future<bool> turnoAsk(Pending me, EsperaOpts o, String? line, int my) async {
    final tu = o.turno!, T = tu.T;
    HAB.hechos.add(tu.id!);
    HAB.n++;
    final reg = <String, dynamic>{'id': tu.id, 'tipo': 'ask', 'est': '', 'intentos': 0};
    HAB.log.add(reg);
    me.turnoOn = true;
    me.lock = true;
    micEst('dead');
    if (line != null && line.isNotEmpty) await say(line, 0);
    habBub('mic');
    for (var n = 1;; n++) {
      final r = await habIntento(me.repite);
      if (my != runId) throw const StopSignal();
      final k = _habClase(r);
      reg['intentos'] = n;
      if (k == 'nodisp') {
        habPon();
        reg['est'] = 'nodisp';
        break;
      }
      if (k == 'voz' && habCuadra(r.alts, T)) {
        reg['est'] = 'ok';
        habGraba(T, true, r.ms);
        hush();
        me.hablado = true;
        me.got = me.live[0];
        me.ms = r.ms;
        me.p = null;
        me.done = true;
        me.turnoOn = false;
        me.okP = habOkP(r.alts![0]);
        me.res();
        return true; // said[t] does not play again
      }
      if (n >= 2) {
        reg['est'] = 'fallo';
        habGraba(T, false, r.ms);
        break; // the other option, or nothing that matches, is a miss
      }
    }
    habFin();
    me.turnoOn = false;
    me.lock = o.lock || o.voces != null;
    return false; // two misses (or speaking cannot work): the sign, the voices and the touch come back as today
  }

  // ---------- inside an elige ----------

  // juego.js: turnoEligeInicio
  /// The mic comes beside the bubbles. He may speak or touch, whichever comes first.
  void turnoEligeInicio(Pending me, EsperaOpts o) {
    final tu = o.turno!;
    tu.ids.forEach(HAB.hechos.add);
    HAB.n++;
    me.reg = <String, dynamic>{'id': tu.ids.join('|'), 'tipo': 'elige', 'est': '', 'intentos': 0};
    HAB.log.add(me.reg!);
    me.turnoOn = true;
    micEst('dead');
    habBub('mic');
  }

  // juego.js: turnoElige
  Future<void> turnoElige(Pending me, EsperaOpts o, int my) async {
    final tu = o.turno!, reg = me.reg!;
    try {
      for (var n = 1;; n++) {
        final r = await habIntento(null);
        if (my != runId || me.done || r.cancel) return; // the question line is repeated by espera's own timer
        final k = _habClase(r);
        reg['intentos'] = n;
        if (k == 'nodisp') {
          habPon();
          reg['est'] = 'nodisp';
          habFin();
          me.turnoOn = false;
          return;
        }
        final m = k == 'voz' ? tu.ops.where((op) => habCuadra(r.alts, tu.Ts[op]!)).toList() : <String>[];
        if (m.length == 1) {
          reg['est'] = 'ok';
          reg['op'] = m[0];
          habGraba(tu.Ts[m[0]]!, true, r.ms);
          hush();
          me.hablado = true;
          me.got = m[0];
          me.ms = r.ms;
          me.p = null;
          me.done = true;
          me.turnoOn = false;
          me.okP = habOkP(r.alts![0]);
          me.res(); // exactly one option matches: taken
          return;
        }
        if (n >= 2) {
          // two misses: the mic goes away, the bubbles are the way (nothing is written: elige has no wrong answer)
          reg['est'] = 'fallo';
          habFin();
          me.turnoOn = false;
          return;
        }
      }
    } on StopSignal {
      return;
    }
  }
}
