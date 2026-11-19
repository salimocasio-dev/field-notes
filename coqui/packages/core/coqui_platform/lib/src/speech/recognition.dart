import 'dart:async';

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_platform/src/audio/sound_core.dart';

/// The recogniser juego.js makes (`new (window.SpeechRecognition || window.webkitSpeechRecognition)()`),
/// as far as juego.js uses it. The web's is the browser's own, by interop; the tests' is a fake.
abstract interface class Recognizer {
  set lang(String v);
  set interimResults(bool v);
  set maxAlternatives(int v);
  set continuous(bool v);
  set onspeechstart(void Function()? f);
  set onspeechend(void Function()? f);
  set onaudioend(void Function()? f);

  /// The transcripts of the event's last result (juego.js: `e.results[e.results.length-1]`).
  set onresult(void Function(List<String> alternatives)? f);

  /// The event's `error` (null when it has none).
  set onerror(void Function(String? error)? f);
  set onend(void Function()? f);
  void start();
  void stop();
  void abort();
}

/// What makes the recogniser speaking needs, as juego.js and docs/hablar/01-decisiones.md say.
class SpeechSettings {
  /// Errors that show speaking cannot work here (juego.js: NODISP): no more turns this session.
  static const unavailableErrors = {
    'not-allowed',
    'service-not-allowed',
    'network',
    'audio-capture',
    'language-not-supported',
  };

  /// After `stop()` at the limit, how long the recogniser has to end before it is aborted
  /// (juego.js: HAB.force, 2500 ms).
  static const grace = Duration(milliseconds: 2500);
}

/// The speech listener of the web, ported from juego.js (`habSR`, `habDisp`, `habEmpieza`, `habCorta`'s
/// abort, `habNd` and `habPon`), on a [Recognizer] and whatever the page knows about the phone.
///
/// - [available]: a recogniser exists, the browser is not offline, the microphone permission is not
///   "denied", and no recognition this session has ended with one of
///   [SpeechSettings.unavailableErrors] (juego.js keeps that in sessionStorage, coqui.habla.nodisp).
/// - [listen]: lang = the locale passed in, interimResults false, maxAlternatives as asked (5 by
///   default), continuous false; `stop()` at `limit`, `abort()` [SpeechSettings.grace] later. The
///   recogniser is made and started inside the call (the phone wants that inside the tap).
/// - After every recognition, and after a cancel, [afterRecognition] runs (the iPhone guard: the audio
///   context is resumed).
class RecognizerSpeechListener implements SpeechListener {
  RecognizerSpeechListener({
    required this.makeRecognizer,
    required this.online,
    required this.micDenied,
    required this.unavailableThisSession,
    required this.markUnavailable,
    required this.afterRecognition,
    required this.nowMs,
    StartTimer? startTimer,
  }) : _startTimer = startTimer ?? ((d, f) => Timer(d, f));

  /// Null when this browser has no recogniser.
  final Recognizer Function()? makeRecognizer;
  final Future<bool> Function() online;
  final Future<bool> Function() micDenied;
  final bool Function() unavailableThisSession;
  final void Function() markUnavailable;
  final void Function() afterRecognition;

  /// performance.now()
  final double Function() nowMs;
  final StartTimer _startTimer;

  // juego.js: habDisp (without ?mic=off and the stub: those are the test fakes' now)
  @override
  Future<bool> available() async {
    if (makeRecognizer == null) return false;
    if (!await online()) return false;
    if (unavailableThisSession()) return false;
    try {
      if (await micDenied()) return false;
    } catch (_) {}
    return true;
  }

  @override
  SpeechTurn listen({
    required String locale,
    required Duration limit,
    int maxAlternatives = 5,
  }) => _Turn(this, locale, limit, maxAlternatives);
}

// juego.js: habEmpieza (the recogniser part) and habCorta (the cancel)
class _Turn implements SpeechTurn {
  _Turn(this.l, String locale, Duration limit, int maxAlternatives) {
    t0 = l.nowMs();
    final make = l.makeRecognizer;
    Recognizer rc;
    try {
      if (make == null) throw StateError('no recogniser');
      rc = make();
    } catch (_) {
      err = 'service-not-allowed';
      _fin();
      return;
    }
    rc.lang = locale;
    rc.interimResults = false;
    rc.maxAlternatives = maxAlternatives;
    rc.continuous = false;
    rec = rc;
    rc.onspeechstart = () {
      onset ??= l.nowMs();
    };
    rc.onspeechend = _proc;
    rc.onaudioend = _proc;
    rc.onresult = (a) => alts = [...a];
    rc.onerror = (e) => err = (e == null || e.isEmpty) ? 'error' : e;
    rc.onend = _fin;
    try {
      rc.start();
    } catch (_) {
      err = 'aborted';
      _fin();
      return;
    }
    stop6 = l._startTimer(limit, () {
      _proc();
      try {
        rc.stop();
      } catch (_) {}
      force = l._startTimer(SpeechSettings.grace, () {
        try {
          rc.abort();
        } catch (_) {}
        if (err.isEmpty && alts == null) err = 'aborted';
        _fin();
      });
    });
  }

  final RecognizerSpeechListener l;
  late final double t0;
  double? onset;
  List<String>? alts;
  String err = '';
  Recognizer? rec;
  Timer? stop6, force;
  bool listo = false;
  final Completer<SpeechResult> _result = Completer();
  final Completer<void> _speechEnd = Completer();

  void _proc() {
    if (!_speechEnd.isCompleted) _speechEnd.complete();
  }

  void _clear() {
    stop6?.cancel();
    force?.cancel();
    rec = null;
  }

  void _fin() {
    if (listo) return;
    listo = true;
    _clear();
    try {
      l.afterRecognition(); // iPhone: the sound comes back only after this
    } catch (_) {}
    if (SpeechSettings.unavailableErrors.contains(err)) l.markUnavailable();
    final o = onset;
    _proc();
    _result.complete(
      SpeechResult(
        alternatives: alts ?? const [],
        error: err.isEmpty ? null : err,
        // the tap to the recogniser's speechstart; none when there was none (juego.js passes 0 then)
        msToSound: o == null ? null : (o - t0 + .5).floor(),
      ),
    );
  }

  @override
  Future<SpeechResult> get result => _result.future;

  @override
  Future<void> get speechEnd => _speechEnd.future;

  /// juego.js: habCorta. The recogniser is aborted, the sound resumed, and the turn ends at once with
  /// "aborted" (juego.js: `{cancel: 1}`, which its turn code never counts).
  @override
  void cancel() {
    if (listo) return;
    listo = true;
    final r = rec;
    _clear();
    if (r != null) {
      try {
        r.abort();
      } catch (_) {}
      try {
        l.afterRecognition();
      } catch (_) {}
    }
    _proc();
    _result.complete(SpeechResult(error: 'aborted'));
  }
}
