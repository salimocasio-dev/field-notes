/// The call with Danny, without a screen: llamada.js (all but the connection) on a [CallSession], the
/// [Clock], the catalog and the progress store.
///
/// The old code's timers are deadlines on the [Clock], checked by [tick]: the screen calls [tick] every 50 ms
/// while [ticking] (llamada.js: `LOOP=setInterval(bucle,50)`), and a test calls it as it moves its clock. Nothing
/// here waits on the real time.
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:feature_speaking/src/call_start_reason.dart';
import 'package:feature_speaking/src/call_text.dart';
import 'package:flutter/foundation.dart';

/// llamada.js: `ST`, the screen's state (`data-s`).
enum CallState { idle, connecting, danny, you, proc, err, done }

// llamada.js: FIN_AT, MAX_AT (seconds of call time) and FIN_CAP (ms of real time).
const int finAtSeconds = 360;
const int maxAtSeconds = 420;
const int finCapMs = 15000;

// llamada.js: bucle's numbers. The loop runs every 50 ms.
const int tickMs = 50;
const double _floorStart = .008;
const double _floorMargin = .025;
const int _onsetAfterMs = 100;
const int _quietBeforeDotsMs = 600;

// llamada.js: the 400 ms between the goodbye line ending and the call ending; the help note's 5 s; the
// pressed Help button's 600 ms.
const int _afterGoodbyeMs = 400;
const int _helpNoteMs = 5000;
const int _helpPressedMs = 600;

class _Fin {
  _Fin({required this.n, required this.seen});
  int n;
  bool seen;
}

class _Turn {
  _Turn(this.t);
  final int t;
  int? loud0;
  int? lastLoud;
  int? onset;
  bool spoke = false;
}

/// One call, from the open screen to the summary. [place] and [brief] are the place and its call; with either
/// missing there is no call ([available] is false) and the screen is not opened.
class CallController extends ChangeNotifier {
  CallController({
    required this.session,
    required this.clock,
    required this.course,
    required this.progress,
    required this.placeId,
    this.clips,
    this.onClose,
  }) : place = _placeOf(course, placeId),
       brief = course.callFor(placeId);

  final CallSession session;
  final Clock clock;
  final CourseCatalog course;
  final ProgressStore progress;
  final String placeId;

  /// Stopped when a call starts (llamada.js: `hush(); SFX.calla()`).
  final ClipPlayer? clips;

  /// Closes the screen (llamada.js: `cierra`).
  final VoidCallback? onClose;

  final Place? place;
  final CallBrief? brief;

  static Place? _placeOf(CourseCatalog course, String id) {
    for (final p in course.places) {
      if (p.id == id) return p;
    }
    return null;
  }

  bool get available => place != null && brief != null;

  // ---- what the screen shows ----

  CallState _state = CallState.idle;
  CallState get state => _state;

  String _label = CallTexts.startCall;

  /// The mic's state label (`.ll`).
  String get label => _label;

  /// Danny's last line (`.ld`); before the call, "place · about N min" in grey ([lineMuted]).
  String dannyLine = '';
  bool lineMuted = false;

  /// What the app heard the learner say (`.lh`).
  String heardLine = '';

  /// The note under the label (`.lo`).
  String note = '';

  /// `.lt`.
  String timerText = '00:00';

  /// The Help button's pressed look (`.lhelp.p`).
  bool helpPressed = false;

  /// The ring's thickness in px (`--rt`) and the rings' reach (`--wv`).
  double ring = 3;
  double wave = 1.5;

  /// The word whose picture is shown (`dibuja`), and whether there is one (the canvas's `visibility`).
  String? pictureWord;
  bool pictureShown = false;

  /// `.lerr`, the plain line of the error state.
  String errorLine = '';

  /// `.ls1`, the summary's line.
  String summaryLine = '';

  /// Why the call ended (llamada.js: `C.why`): x, disc, fin, cap, max.
  String why = '';

  /// The words of the place the learner has said, in the order they were said (llamada.js: `Llamada.dicho`).
  List<String> get said => [..._said.keys];

  /// llamada.js: `Llamada.fin`: the call is being ended (a goodbye was heard or the six minutes passed).
  bool get ending => _fin != null;

  /// llamada.js: `Llamada.ocupado`: one call at a time, from the tap until everything is cleaned up.
  bool get busy => _locked;

  /// llamada.js: `Llamada.activo` is false once the screen is closed.
  bool get closed => _closed;

  /// The words of the place (null before the tap loaded them).
  List<String>? get words => _words;

  /// True while the screen must call [tick] (llamada.js: `LOOP` is running).
  bool get ticking => !_closed && _t0 != null && !_done;

  /// The picture's pair, from the catalog (`it.si` of the item whose word is [pictureWord]).
  ReviewPair? get picturePair {
    final w = pictureWord;
    return w == null ? null : course.pairFor(w);
  }

  // ---- the call (llamada.js: CALL) ----

  int _run = 0;
  bool _locked = false;
  bool _closed = false;
  bool _done = false;
  bool _live = false; // C.conv
  int? _t0;
  _Fin? _fin;
  String _mode = 'listening';
  _Turn? _turn;
  double _floor = _floorStart;
  double _lvl = 0;
  bool _minutesCounted = false;
  String _err = '';
  int? _noteUntil;
  int? _helpUntil;
  int? _capAt;
  int? _finishAt;
  List<String>? _words;
  Future<List<String>>? _wordsFuture;
  final Map<String, int?> _said = {};
  StreamSubscription<CallEvent>? _sub;

  /// What `session.available` said when the screen opened (llamada.js: `precarga`: reading it starts the
  /// voice library's load, so it is ready before the tap).
  bool libraryReadyAtOpen = false;

  /// llamada.js: `abre`: the screen opens on the call's picture and "place · about N min"; the words and the
  /// library are ready before the tap.
  void open() {
    final p = place;
    final b = brief;
    if (p == null || b == null) return;
    final photo = b.photo;
    pictureWord = photo;
    pictureShown = photo != null && course.pairFor(photo) != null;
    dannyLine = CallTexts.aboutLine(p.name, b.minutes);
    lineMuted = true;
    _est(CallState.idle);
    unawaited(_wordsOf());
    libraryReadyAtOpen = session.available;
  }

  // llamada.js: est
  void _est(CallState s) {
    _state = s;
    switch (s) {
      case CallState.idle:
        _label = CallTexts.startCall;
      case CallState.connecting:
        _label = CallTexts.calling;
      case CallState.danny:
        _label = CallTexts.danny;
      case CallState.you:
        _label = CallTexts.yourTurn;
      case CallState.proc:
        _label = CallTexts.oneMoment;
      case CallState.err || CallState.done:
        break;
    }
    _changed();
  }

  void _changed() {
    if (!_closed) notifyListeners();
  }

  int _now() => clock.nowMs();

  // llamada.js: palabrasDe. The focus words of the place's stories, in the stories' order; a story that
  // cannot be read, or that belongs to another place, adds none. An empty answer is not kept.
  Future<List<String>> _wordsOf() {
    final cached = _wordsFuture;
    if (cached != null) return cached;
    final f = _loadWords().then((w) {
      if (w.isEmpty) _wordsFuture = null;
      return w;
    });
    return _wordsFuture = f;
  }

  Future<List<String>> _loadWords() async {
    final l = place!;
    final stories = await Future.wait(
      l.stories.map(
        (id) => course
            .story(id)
            .then<Map<String, dynamic>?>((j) => j, onError: (Object _) => null),
      ),
    );
    final out = <String>[];
    for (final j in stories) {
      if (j == null) continue;
      final jp = j['place'];
      if (jp != null && jp != '' && jp != l.name) continue;
      final fw = j['focus_words'];
      if (fw is! List) continue;
      for (final w in fw) {
        if (w is String && !out.contains(w)) out.add(w);
      }
    }
    return out;
  }

  // llamada.js: inicia
  /// The tap on the green disc: the call starts. Completes when the session has started (or failed to).
  Future<void> start() async {
    final b = brief;
    final l = place;
    if (_locked ||
        _closed ||
        _state != CallState.idle ||
        b == null ||
        l == null) {
      return;
    }
    _locked = true;
    final my = ++_run;
    // every other sound stops before the microphone opens
    try {
      final c = clips;
      if (c != null) {
        unawaited(c.stop().catchError((Object _) {}));
        c.loop('rain', false);
      }
    } catch (_) {}
    _est(CallState.connecting);
    dannyLine = '';
    lineMuted = false;
    List<String> words;
    try {
      words = await _wordsOf();
    } catch (_) {
      words = [];
    }
    if (my != _run) return;
    if (words.isEmpty) {
      _fallo(CallTexts.notStarted);
      return;
    }
    _words = words;
    // every word of the place is open for speaking: words_open is the whole list, words_heard is empty
    final vars = <String, String>{
      'place': l.name,
      'job': b.job,
      'words_open': words.join(', '),
      'words_heard': '',
      'minutes': '${b.minutes}',
      'opening': b.opening,
    };
    unawaited(_sub?.cancel());
    _sub = session.events.listen((e) => _onEvent(my, e));
    try {
      await session.start(b, vars);
    } catch (e) {
      if (my != _run) return;
      _fallo(callStartLine(callStartReason(e)));
      return;
    }
    if (my != _run) {
      // he closed the screen while it was still calling
      _endSession();
      return;
    }
    _live = true;
  }

  void _onEvent(int my, CallEvent e) {
    switch (e) {
      case Connected():
        _conecta(my);
      case Ended():
        _desconecta(my);
      case AgentLine(:final text):
        _mensaje(my, text, user: false);
      case Heard(:final text):
        _mensaje(my, text, user: true);
      case Mode(:final mode):
        _modo(my, mode);
      case Tool(:final name, :final args):
        if (my == _run && name == 'show_picture') _muestra(args);
      case CallError(:final message):
        if (my == _run && !_closed) _err = message;
    }
  }

  // llamada.js: conecta
  void _conecta(int my) {
    if (my != _run || _closed || _t0 != null) return;
    _t0 = _now();
    _est(CallState.danny);
    timerText = '00:00';
    _changed();
  }

  // llamada.js: desconecta
  void _desconecta(int my) {
    if (my != _run || _closed || _done) return;
    if (_t0 == null) {
      _fallo(callDroppedLine(_err));
      return;
    }
    finish('disc');
  }

  // llamada.js: modo
  void _modo(int my, String m) {
    if (my != _run || _closed || _done) return;
    _mode = m;
    final f = _fin;
    if (f != null) {
      if (m == 'speaking') {
        f.seen = true;
      } else if (m == 'listening' && f.seen) {
        f.seen = false;
        if (--f.n <= 0) _finishAt ??= _now() + _afterGoodbyeMs;
      }
    }
    if (_t0 == null) return;
    if (m == 'speaking') {
      _turn = null;
      _est(CallState.danny);
    } else if (m == 'listening') {
      _turn = _Turn(_now());
      heardLine = '';
      _lvl = 0;
      ring = 3;
      _est(CallState.you);
    }
  }

  // llamada.js: mensaje
  void _mensaje(int my, String text, {required bool user}) {
    if (my != _run || _closed || _done || text.isEmpty) return;
    if (!user) {
      dannyLine = text;
      lineMuted = false;
      if (_fin == null && isGoodbye(text, course.goodbyeWords)) {
        _terminaDanny(); // he said goodbye on his own: the call ends after this line
      }
      _changed();
      return;
    }
    // our own "(ayuda)" and "(fin)" come back: not his words
    if (RegExp(r'^\s*\(').hasMatch(text)) return;
    heardLine = text;
    // his line is in: Danny is about to answer
    if (_state == CallState.you) _est(CallState.proc);
    _oye(text);
    if (_fin == null && isGoodbye(text, course.goodbyeWords)) {
      _enviaFin(); // any goodbye from him, at any time, ends the call
    }
    _changed();
  }

  // llamada.js: oye. Every word of the place he said (once per call each) becomes a mouth record;
  // ms = how long he took to start speaking.
  void _oye(String text) {
    final n = normalize(text);
    final turn = _turn;
    final onset = turn?.onset;
    final ms = onset == null ? null : math.max(0, onset - turn!.t);
    for (final w in _words ?? const <String>[]) {
      if (_said.containsKey(w) || !dice(n, w)) continue;
      _said[w] = ms;
      try {
        progress.answer(w, Skill.mouth, ok: true, ms: ms);
      } catch (_) {}
    }
  }

  // llamada.js: muestra. Only a word of this place; anything else is ignored.
  void _muestra(Map<String, dynamic> args) {
    if (_closed || _done) return;
    Object? k;
    for (final key in const ['picture', 'key', 'word', 'name', 'id']) {
      final v = args[key];
      if (v != null && v != '' && v != false && v != 0) {
        k = v;
        break;
      }
    }
    final n = normalize('${k ?? ''}');
    String? w;
    for (final x in _words ?? const <String>[]) {
      if (normalize(x) == n) {
        w = x;
        break;
      }
    }
    if (w == null) return;
    if (course.pairFor(w) != null) {
      pictureWord = w;
      pictureShown = true;
      _changed();
    }
  }

  // llamada.js: ayuda
  /// The Help button: Danny is sent "(ayuda)".
  void help() {
    if (_closed || _t0 == null || _done || !_live) return;
    _send(CallTexts.sendHelp);
    final now = _now();
    helpPressed = true;
    _helpUntil = now + _helpPressedMs;
    note = CallTexts.helpNote;
    _noteUntil = now + _helpNoteMs;
    _changed();
  }

  // llamada.js: enviar
  void _send(String t) {
    if (!_live) return;
    try {
      session.send(t);
    } catch (_) {}
  }

  // llamada.js: enviaFin. The page ends the call: "(fin)", then the session ends when Danny has finished his
  // goodbye (15 s at the latest).
  void _enviaFin() {
    if (_done || _fin != null) return;
    final speaking = _mode == 'speaking';
    // if he is mid-line, that line ends first: the goodbye is the second one
    _fin = _Fin(n: speaking ? 2 : 1, seen: speaking);
    _send(CallTexts.sendEnd);
    _capAt = _now() + finCapMs;
  }

  // llamada.js: terminaDanny. Danny said goodbye on his own: that line is the goodbye, so nothing is sent
  // ("(fin)" would only make him say it again) and the call ends when the line is finished (15 s at the latest).
  void _terminaDanny() {
    if (_done || _fin != null) return;
    _fin = _Fin(n: 1, seen: _mode == 'speaking');
    _capAt = _now() + finCapMs;
  }

  /// One step of the call's clock (llamada.js: `bucle`, every 50 ms), and the deadlines of its timers.
  void tick() {
    if (_closed) return;
    final now = _now();
    var changed = false;
    final noteUntil = _noteUntil;
    if (noteUntil != null && now >= noteUntil) {
      _noteUntil = null;
      note = '';
      changed = true;
    }
    final helpUntil = _helpUntil;
    if (helpUntil != null && now >= helpUntil) {
      _helpUntil = null;
      helpPressed = false;
      changed = true;
    }
    if (changed) _changed();
    final fin = _finishAt;
    if (fin != null && now >= fin) {
      _finishAt = null;
      finish('fin');
    }
    final cap = _capAt;
    if (cap != null && now >= cap && !_done) {
      _capAt = null;
      finish('cap');
    }
    _bucle(now);
  }

  double _safe(double Function() f) {
    try {
      return f();
    } catch (_) {
      return 0;
    }
  }

  // llamada.js: bucle
  void _bucle(int now) {
    final t0 = _t0;
    if (_done || t0 == null) return;
    final el = (now - t0) / 1000;
    var changed = false;
    final t = mmss(el);
    if (timerText != t) {
      timerText = t;
      changed = true;
    }
    if (_live) {
      if (_state == CallState.danny) {
        final o = _safe(session.outputVolume);
        wave = 1.3 + math.min(1, o * 4) * .6;
        changed = true;
      }
      final turn = _turn;
      if (_state == CallState.you && turn != null) {
        // the level: a quiet floor that follows the room, and a threshold just above it
        final raw = _safe(session.inputVolume);
        final thr = _floor + _floorMargin;
        final loud = raw > thr;
        if (!loud) _floor = _floor * .98 + raw * .02;
        final target = loud ? math.min(1.0, (raw - _floor) * 5) : 0.0;
        _lvl += (target - _lvl) * .5;
        ring = 3 + _lvl * 9;
        changed = true;
        if (loud) {
          turn.lastLoud = now;
          turn.loud0 ??= now;
          if (now - turn.loud0! >= _onsetAfterMs) {
            turn.spoke = true;
            turn.onset ??= turn.loud0;
          }
        } else {
          turn.loud0 = null;
          final last = turn.lastLoud;
          // he spoke, and has been quiet for 600 ms (short pauses mid-sentence do not count): the dots,
          // until Danny speaks
          if (turn.spoke && last != null && now - last >= _quietBeforeDotsMs) {
            _est(CallState.proc);
          }
        }
      }
    }
    if (changed) _changed();
    if (_fin == null && el >= finAtSeconds) _enviaFin();
    if (el >= maxAtSeconds) finish('max');
  }

  // llamada.js: cuenta. A call counts like a story: its minutes go into the minutes listened, and a day with
  // a call keeps the streak (progress.addMinutes does both).
  void _cuenta(double secs) {
    if (_minutesCounted || _t0 == null) return;
    _minutesCounted = true;
    try {
      progress.addMinutes(secs / 60);
    } catch (_) {}
  }

  double _elapsed() {
    final t0 = _t0;
    return t0 == null ? 0 : (_now() - t0) / 1000;
  }

  void _endSession() {
    try {
      unawaited(session.end().catchError((Object _) {}));
    } catch (_) {}
  }

  // llamada.js: finish. Every way out ends here once: the session, the timers, the lock.
  void finish(String reason) {
    if (_done) return;
    _done = true;
    _stopTimers();
    final secs = _elapsed();
    final wasLive = _live;
    _live = false;
    if (wasLive) _endSession();
    _cuenta(secs);
    _locked = false;
    _noteUntil = null;
    if (_closed) return;
    final dicho = _said.keys.toList();
    final min = math.max(1, (secs / 60 + 0.5).floor());
    summaryLine = CallTexts.summary(min, dicho.length);
    why = reason;
    _est(CallState.done);
  }

  void _stopTimers() {
    _capAt = null;
    _finishAt = null;
  }

  // llamada.js: fallo. One plain line and the X.
  void _fallo(String text) {
    if (_closed) return;
    _done = true;
    _stopTimers();
    errorLine = text;
    _est(CallState.err);
    _locked = false;
  }

  // llamada.js: cierraX
  /// The X: a live call ends, with its summary; a call still being placed is hung up; then the screen closes.
  void closeX() {
    if (_closed) return;
    if (_t0 != null && !_done) {
      finish('x'); // a live call: the X ends it, with the summary
      return;
    }
    if (_t0 == null && _locked) {
      // still calling: hang up before it picks up (a late answer is ended in start)
      _run++;
      _done = true;
      _stopTimers();
      _locked = false;
      _endSession();
    }
    close();
  }

  // llamada.js: cierra
  /// "Back to Hablar", or the X on every screen but a live call.
  void close() {
    if (_closed) return;
    _closed = true;
    unawaited(_sub?.cancel());
    _sub = null;
    onClose?.call();
  }

  // llamada.js: the pagehide handler
  /// The page is going away (or the screen is): a live call is ended, its minutes counted, the lock freed.
  void pageHide() {
    if (!_live) return;
    final secs = _elapsed();
    _live = false;
    _done = true;
    _stopTimers();
    _endSession();
    _cuenta(secs);
    _locked = false;
  }

  /// The screen is leaving.
  void leave() {
    pageHide();
    // still calling: hang up before it picks up
    if (_locked && !_live && !_done) _endSession();
    _run++;
    _closed = true;
    unawaited(_sub?.cancel());
    _sub = null;
  }

  @override
  void dispose() {
    leave();
    super.dispose();
  }
}
