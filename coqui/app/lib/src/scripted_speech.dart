/// The recogniser of the address switches `?mic=stub:` and `?mic=off`, for checks by machine. coqui_platform gives the
/// app the real recogniser only, so the scripted one is here.
library;

import 'dart:async';

import 'package:coqui_contracts/coqui_contracts.dart';

/// A recogniser that hears what `?mic=stub:<r1>|<r2>|...` says (docs/hablar/01-decisiones.md, "Machine tests"):
/// each turn takes the next result, in order, and when they run out he says nothing. A result is alternatives split by
/// "/", or "none" (no speech), or "error:<code>". With [off] (`?mic=off`) recognition is unavailable.
///
/// It keeps the old stub's pace (juego.js, habEmpieza with STUB): with alternatives, the first sound at 120 ms, the end
/// of speech at 300 ms, the result at 420 ms; "none": the error "no-speech" at 500 ms; "error:<code>": that code (or
/// "error") at 150 ms. A cancelled turn ends with the error "aborted", as the recogniser reports an abort.
class ScriptedSpeechListener implements SpeechListener {
  ScriptedSpeechListener(List<String> results, {this.off = false})
    : _results = [...results];

  final List<String> _results;
  final bool off;
  int _used = 0;

  @override
  Future<bool> available() async => !off;

  @override
  SpeechTurn listen({
    required String locale,
    required Duration limit,
    int maxAlternatives = 5,
  }) {
    final i = _used++;
    final r = i < _results.length && _results[i].isNotEmpty
        ? _results[i]
        : 'none';
    return _Turn(r);
  }
}

class _Turn implements SpeechTurn {
  _Turn(String r) {
    if (r == 'none') {
      _at(500, () => _finish(SpeechResult(error: 'no-speech')));
    } else if (r.startsWith('error:')) {
      final code = r.substring(6);
      _at(
        150,
        () => _finish(SpeechResult(error: code.isEmpty ? 'error' : code)),
      );
    } else {
      _at(300, _endOfSpeech);
      _at(
        420,
        () => _finish(SpeechResult(alternatives: r.split('/'), msToSound: 120)),
      );
    }
  }

  final Completer<SpeechResult> _result = Completer<SpeechResult>();
  final Completer<void> _speechEnd = Completer<void>();
  final List<Timer> _timers = [];

  void _at(int ms, void Function() f) =>
      _timers.add(Timer(Duration(milliseconds: ms), f));

  void _endOfSpeech() {
    if (!_speechEnd.isCompleted) _speechEnd.complete();
  }

  void _finish(SpeechResult r) {
    for (final t in _timers) {
      t.cancel();
    }
    _endOfSpeech();
    if (!_result.isCompleted) _result.complete(r);
  }

  @override
  Future<SpeechResult> get result => _result.future;

  @override
  Future<void> get speechEnd => _speechEnd.future;

  @override
  void cancel() => _finish(SpeechResult(error: 'aborted'));
}
