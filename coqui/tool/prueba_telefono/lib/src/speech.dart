// The speech plugin under test (speech_to_text), with docs/hablar/01-decisiones.md's settings:
// lang "es-US", no interim results, not continuous, 5 alternatives (through the shim in web/coqui_meter.js,
// because the plugin's web code never sets maxAlternatives), stop() at 6 s, abort 2.5 s after that.
import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_to_text.dart';

import 'browser.dart';

const kLang = 'es-US';

class Heard {
  Heard(this.alts, this.error, this.statuses, this.ms);
  final List<String> alts;
  final String? error;
  final List<String> statuses;
  final double ms; // from listen() to the end
  String line() {
    final a = alts.isEmpty ? 'nothing' : alts.map((s) => '"$s"').join(' / ');
    final e =
        error ??
        (alts.isEmpty ? 'none (the recogniser ended with no result)' : 'none');
    return 'heard: $a; error: $e; ${ms.round()} ms; statuses: ${statuses.isEmpty ? 'none' : statuses.join(', ')}';
  }
}

class Speech {
  final SpeechToText stt = SpeechToText();
  bool? available;
  String note = 'not started';
  void Function(SpeechRecognitionError e)? _onErr;
  void Function(String s)? _onStatus;

  /// Before any tap, so that listen() inside a tap reaches the recogniser's start() with no wait.
  Future<void> init() async {
    try {
      final ok = await within(
        stt.initialize(
          onError: (e) => _onErr?.call(e),
          onStatus: (s) => _onStatus?.call(s),
        ),
        const Duration(seconds: 5),
      );
      available = ok ?? false;
      note = ok == null
          ? 'initialize() gave no answer in 5 s'
          : ok
          ? 'initialized'
          : 'initialize() returned false (no recogniser here)';
    } catch (e) {
      available = false;
      note = 'initialize() threw ${errText(e)}';
    }
  }

  /// What the recogniser the plugin made reports for its settings (through the shim's record of it).
  String settings() {
    final shim = coquiShim;
    if (shim == null) return 'shim: missing';
    final wrapped =
        shim.getProperty<JSBoolean?>('wrapped'.toJS)?.toDart ?? false;
    final last = shim.getProperty<JSObject?>('last'.toJS);
    if (last == null) return 'shim wrapped: $wrapped; no recogniser made yet';
    String p(String k) =>
        last.getProperty<JSAny?>(k.toJS)?.dartify()?.toString() ?? 'n/a';
    return 'recogniser: lang "${p('lang')}", maxAlternatives ${p('maxAlternatives')}, '
        'interimResults ${p('interimResults')}, continuous ${p('continuous')}';
  }

  /// Call inside the tap. Every wait has a limit: the plugin's stop at 6 s, cancel at 8.5 s, give up at 10 s.
  Future<Heard> listen() {
    final t0 = nowMs();
    final c = Completer<Heard>();
    var alts = <String>[];
    String? err;
    final statuses = <String>[];
    final timers = <Timer>[];
    void finish([String? why]) {
      if (c.isCompleted) return;
      for (final t in timers) {
        t.cancel();
      }
      _onErr = null;
      _onStatus = null;
      if (why != null) err ??= why;
      c.complete(Heard(alts, err, statuses, nowMs() - t0));
    }

    if (available != true) {
      finish('not available ($note)');
      return c.future;
    }
    _onErr = (e) => err ??= e.errorMsg;
    _onStatus = (s) {
      statuses.add(s);
      if (s == 'done' || s == 'doneNoResult') {
        timers.add(Timer(const Duration(milliseconds: 150), finish));
      }
    };
    try {
      stt
          .listen(
            onResult: (r) {
              alts = [for (final a in r.alternates) a.recognizedWords];
            },
            listenOptions: SpeechListenOptions(
              localeId: kLang,
              partialResults: false,
              cancelOnError: false,
              listenFor: const Duration(seconds: 6),
            ),
          )
          .catchError((Object e) => finish('listen() failed: ${errText(e)}'));
    } catch (e) {
      finish('listen() threw: ${errText(e)}');
      return c.future;
    }
    timers.add(
      Timer(const Duration(milliseconds: 8500), () {
        stt.cancel().catchError((Object _) {});
      }),
    );
    timers.add(
      Timer(
        const Duration(seconds: 10),
        () => finish('timeout: the recogniser did not end within 10 s'),
      ),
    );
    return c.future;
  }
}
