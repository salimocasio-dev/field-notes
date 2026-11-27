/// The voice test without a screen (habla-prueba.html): twelve lines to say, one attempt each, on a
/// [SpeechListener]; how many were heard right.
library;

import 'dart:async';
import 'dart:convert';

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:feature_speaking/src/wording.dart';
import 'package:flutter/foundation.dart';

/// One word to be heard in a line, with the forms of it that count (habla-prueba.html: `g`, `[word, forms]`).
class VoiceTarget {
  const VoiceTarget(this.word, this.forms);
  final String word;
  final List<String> forms;
}

/// One line to say (habla-prueba.html: `LINES`): its text, a hint under it, and the targets.
class VoiceLine {
  const VoiceLine(this.text, this.targets, {this.hint});
  final String text;
  final String? hint;
  final List<VoiceTarget> targets;
}

/// The Spanish words the page writes itself, beside the lines. They are course text, not code: they come with the
/// lines.
class VoiceTestLabels {
  const VoiceTestLabels({
    required this.listening,
    required this.processing,
    required this.unavailable,
    required this.again,
    required this.mic,
    required this.next,
    required this.progress,
  });

  /// `#st` while it listens, and while it thinks. habla-prueba.html:148
  final String listening;
  final String processing;

  /// `#note` when the recogniser cannot work. habla-prueba.html:168
  final String unavailable;

  /// The button of the end screen. habla-prueba.html:97
  final String again;

  /// The aria-labels of the mic disc, the next disc, and the progress bar. habla-prueba.html:78, 88, 89
  final String mic;
  final String next;
  final String progress;
}

/// What the voice test says and asks: its lines and its labels.
class VoiceTestContent {
  const VoiceTestContent({required this.lines, required this.labels});
  final List<VoiceLine> lines;
  final VoiceTestLabels labels;
}

/// habla-prueba.html: `data-s` of `#app`.
enum VoiceTestState { load, ready, listen, proc, done, end }

/// What one line has so far (habla-prueba.html: `RUN.lines[k]`).
class VoiceLineRun {
  VoiceLineRun(this.i, this.line);
  final int i;
  final String line;
  bool tried = false;
  bool ok = false;
  List<String> alts = [];
  int ms = 0;
  String err = '';

  Map<String, Object?> toJson() => {
    'i': i,
    'line': line,
    'tried': tried,
    'ok': ok,
    'alts': alts,
    // The listener gives the words and no confidences.
    'conf': const <double>[],
    'ms': ms,
    'err': err,
  };
}

// habla-prueba.html: STOP_AT, UNAVAIL
const Duration voiceTestLimit = Duration(milliseconds: 6000);
const Set<String> voiceTestUnavailable = {
  'not-allowed',
  'service-not-allowed',
  'network',
  'audio-capture',
  'language-not-supported',
};

/// The key the run is kept under, in the test's own storage space (habla-prueba.html: `coqui.hablaprueba`).
const String voiceTestSpace = 'hablaprueba';
const String voiceTestRunKey = 'run';

// habla-prueba.html: heard. The rule for "heard right" (docs/hablar/01-decisiones.md): for EVERY target, at least one
// accepted form is inside at least one alternative, on word boundaries.
bool voiceHeard(
  VoiceLine line,
  List<String> alternatives, {
  Language? language,
}) {
  final lang = language ?? Language.spanish;
  return line.targets.every(
    (g) => g.forms.any((f) {
      final k = ' ${lang.normalize(f).trim()} ';
      return alternatives.any((a) => lang.normalize(a).contains(k));
    }),
  );
}

class VoiceTestController extends ChangeNotifier {
  VoiceTestController({
    required this.speech,
    required this.clock,
    required this.content,
    this.store,
    Language? language,
  }) : language = language ?? Language.spanish;

  final SpeechListener speech;
  final Clock clock;
  final VoiceTestContent content;

  /// The test's own storage space, where the run is kept; null keeps nothing.
  final KeyValueStore? store;

  final Language language;

  VoiceTestState _state = VoiceTestState.load;
  VoiceTestState get state => _state;

  int i = 0;
  late List<VoiceLineRun> runLines;
  int right = 0;
  bool runDone = false;
  String unavailable = '';
  String _runTime = '';
  bool _disposed = false;

  int get n => content.lines.length;

  /// How many lines were tried (the bar's green dashes).
  int get tried => runLines.where((e) => e.tried).length;

  VoiceLine get line => content.lines[i];
  VoiceLineRun get current => runLines[i];

  /// `#st`.
  String get status => _state == VoiceTestState.listen
      ? content.labels.listening
      : _state == VoiceTestState.proc
      ? content.labels.processing
      : '';

  int get _count => runLines.where((e) => e.ok).length;

  void _set(VoiceTestState s) {
    _state = s;
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  // habla-prueba.html: newRun
  void _newRun() {
    i = 0;
    right = 0;
    runDone = false;
    unavailable = '';
    _runTime = DateTime.fromMillisecondsSinceEpoch(
      clock.nowMs(),
      isUtc: true,
    ).toIso8601String();
    runLines = [
      for (var k = 0; k < n; k++) VoiceLineRun(k + 1, content.lines[k].text),
    ];
  }

  // habla-prueba.html: save
  void _save() {
    final s = store;
    if (s == null) return;
    try {
      unawaited(
        s
            .write(
              voiceTestRunKey,
              jsonEncode({
                'v': 1,
                't': _runTime,
                'lang': language.recognitionLocale,
                'src': 'mic',
                'ua': '',
                'n': n,
                'right': right,
                'done': runDone,
                'unavailable': unavailable,
                'lines': [for (final e in runLines) e.toJson()],
              }),
            )
            .catchError((Object _) {}),
      );
    } catch (_) {}
  }

  // habla-prueba.html: start (and "Otra vez")
  /// Begins a run: can he speak at all? (a recogniser, online, the microphone not denied)
  Future<void> start() async {
    _newRun();
    _set(VoiceTestState.load);
    bool ok;
    try {
      ok = await speech.available();
    } catch (_) {
      ok = false;
    }
    if (_disposed) return;
    if (!ok) {
      // nothing was tried: an earlier saved run stays as it was
      unavailable = 'unavailable';
      runDone = true;
      _showEnd();
      return;
    }
    _showLine();
  }

  // habla-prueba.html: showLine
  void _showLine() => _set(VoiceTestState.ready);

  // habla-prueba.html: showEnd
  void _showEnd() {
    right = _count;
    _set(VoiceTestState.end);
  }

  /// The mic disc: one attempt for this line. habla-prueba.html: onMic, listen
  Future<void> onMic() async {
    if (_state != VoiceTestState.ready) return;
    _set(VoiceTestState.listen);
    final k = i;
    var proc = false;
    var settled = false;
    SpeechResult r;
    try {
      final turn = speech.listen(
        locale: language.recognitionLocale,
        limit: voiceTestLimit,
        maxAlternatives: 5,
      );
      // the end of speech first: "Un momento…"
      unawaited(
        turn.speechEnd
            .then((_) {
              if (settled || proc) return;
              proc = true;
              if (_state == VoiceTestState.listen) _set(VoiceTestState.proc);
            })
            .catchError((Object _) {}),
      );
      r = await turn.result;
    } catch (_) {
      r = SpeechResult(
        error: 'not-allowed',
      ); // start() refused: the microphone cannot be used
    }
    settled = true;
    if (_disposed || k != i || _state == VoiceTestState.end) return;
    final e = runLines[k];
    e.tried = true;
    e.alts = [...r.alternatives];
    e.ms = r.msToSound == null ? 0 : (r.msToSound! < 0 ? 0 : r.msToSound!);
    e.err = r.error ?? '';
    if (e.err.isNotEmpty && voiceTestUnavailable.contains(e.err)) {
      // cannot work: stop here
      e.ok = false;
      unavailable = e.err;
      runDone = true;
      _save();
      _showEnd();
      return;
    }
    // no-speech, aborted, nothing heard or the wrong words: a miss
    e.ok =
        e.alts.isNotEmpty &&
        voiceHeard(content.lines[k], e.alts, language: language);
    right = _count;
    _save();
    _set(VoiceTestState.done);
  }

  // habla-prueba.html: onNext
  void onNext() {
    if (_state != VoiceTestState.done) return;
    if (i < n - 1) {
      i++;
      _showLine();
    } else {
      runDone = true;
      _save();
      _showEnd();
    }
  }

  /// `#res`: "Heard right: N of 12".
  String get result => SpeakWording.voiceTestResult(right, n);

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
