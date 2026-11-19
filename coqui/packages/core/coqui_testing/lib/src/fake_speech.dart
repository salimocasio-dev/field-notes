import 'dart:async';

import 'package:coqui_contracts/coqui_contracts.dart';

/// A scripted recogniser in the shape of today's `?mic=stub:<r1>|<r2>|...` (juego.js, habStub and habEmpieza;
/// docs/hablar/01-decisiones.md). `?mic=off` is `available: false`.
///
/// Each [listen] takes the next result, in order; when they run out, he says nothing ("none"). A result is
/// alternatives split by "/", or "none" (no speech), or "error:<code>". The stub keeps the old stub's own pace:
/// alternatives: the first sound at 120 ms, the end of speech at 300 ms, the result at 420 ms; "none":
/// error "no-speech" at 500 ms; "error:<code>": that code (or "error") at 150 ms. `instant: true` makes every
/// wait zero. [SpeechTurn.cancel] ends a turn with error "aborted", as the recogniser reports an abort.
///
/// What it does not do: no microphone, no locale, no time limit (the real recogniser stops at [listen]'s
/// `limit`), no alternatives beyond the ones scripted.
class FakeSpeechListener implements SpeechListener {
  FakeSpeechListener({
    List<String> results = const [],
    this.isAvailable = true,
    this.instant = false,
  }) : results = [...results];

  /// `?mic=stub:` text: the results joined by "|".
  factory FakeSpeechListener.stub(String spec, {bool instant = false}) =>
      FakeSpeechListener(
        results: spec.isEmpty ? const [] : spec.split('|'),
        instant: instant,
      );

  /// The results still to come, in order.
  final List<String> results;

  /// What [available] answers.
  bool isAvailable;

  /// Every wait zero.
  final bool instant;

  /// How many results have been used (juego.js: HAB.si).
  int used = 0;

  /// Every listen, in order, with what it was asked.
  final List<({String locale, Duration limit, int maxAlternatives})> listens =
      [];

  @override
  Future<bool> available() async => isAvailable;

  @override
  SpeechTurn listen({
    required String locale,
    required Duration limit,
    int maxAlternatives = 5,
  }) {
    listens.add((
      locale: locale,
      limit: limit,
      maxAlternatives: maxAlternatives,
    ));
    final r = used < results.length ? results[used] : 'none';
    used++;
    return _FakeSpeechTurn(r, instant);
  }
}

class _FakeSpeechTurn implements SpeechTurn {
  _FakeSpeechTurn(String r, bool instant) {
    Duration ms(int v) => instant ? Duration.zero : Duration(milliseconds: v);
    if (r == 'none') {
      _later(ms(500), () => _finish(SpeechResult(error: 'no-speech')));
    } else if (r.startsWith('error:')) {
      final code = r.substring(6);
      _later(
        ms(150),
        () => _finish(SpeechResult(error: code.isEmpty ? 'error' : code)),
      );
    } else {
      final alts = r.split('/');
      _later(ms(300), _endSpeech);
      _later(
        ms(420),
        () => _finish(SpeechResult(alternatives: alts, msToSound: 120)),
      );
    }
  }

  final Completer<SpeechResult> _result = Completer();
  final Completer<void> _speechEnd = Completer();
  final List<Timer> _timers = [];

  void _later(Duration d, void Function() f) => _timers.add(Timer(d, f));

  void _endSpeech() {
    if (!_speechEnd.isCompleted) _speechEnd.complete();
  }

  void _finish(SpeechResult r) {
    _endSpeech();
    if (!_result.isCompleted) _result.complete(r);
  }

  @override
  Future<SpeechResult> get result => _result.future;

  @override
  Future<void> get speechEnd => _speechEnd.future;

  @override
  void cancel() {
    for (final t in _timers) {
      t.cancel();
    }
    _finish(SpeechResult(error: 'aborted'));
  }
}
