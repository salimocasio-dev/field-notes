import 'dart:async';

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_platform/src/speech/plugin_errors.dart';
import 'package:coqui_platform/src/speech/recognition.dart';
import 'package:flutter_test/flutter_test.dart';

import '../tool/dev_speech.dart';

/// A recogniser that keeps what it was set to and lets the test fire its events.
class FakeRecognizer implements Recognizer {
  final Map<String, Object> set = {};
  final List<String> calls = [];
  void Function()? speechstart, speechend, audioend, end;
  void Function(List<String>)? result;
  void Function(String?)? error;
  bool throwOnStart = false;

  @override
  set lang(String v) => set['lang'] = v;
  @override
  set interimResults(bool v) => set['interimResults'] = v;
  @override
  set maxAlternatives(int v) => set['maxAlternatives'] = v;
  @override
  set continuous(bool v) => set['continuous'] = v;
  @override
  set onspeechstart(void Function()? f) => speechstart = f;
  @override
  set onspeechend(void Function()? f) => speechend = f;
  @override
  set onaudioend(void Function()? f) => audioend = f;
  @override
  set onresult(void Function(List<String>)? f) => result = f;
  @override
  set onerror(void Function(String?)? f) => error = f;
  @override
  set onend(void Function()? f) => end = f;

  @override
  void start() {
    calls.add('start');
    if (throwOnStart) throw StateError('no');
  }

  @override
  void stop() => calls.add('stop');

  @override
  void abort() => calls.add('abort');
}

/// Timers the test fires by hand, and a clock it moves.
class _Rig {
  _Rig({this.hasRecognizer = true, this.makeThrows = false}) {
    listener = RecognizerSpeechListener(
      makeRecognizer: hasRecognizer
          ? () {
              if (makeThrows) throw StateError('not allowed');
              return rec = FakeRecognizer();
            }
          : null,
      online: () async => online,
      micDenied: () async => denied,
      unavailableThisSession: () => nodisp,
      markUnavailable: () => nodisp = true,
      afterRecognition: () => resumes++,
      nowMs: () => now,
      startTimer: (d, f) {
        final t = _T(d, f);
        timers.add(t);
        return t;
      },
    );
  }

  final bool hasRecognizer, makeThrows;
  late final RecognizerSpeechListener listener;
  FakeRecognizer? rec;
  bool online = true, denied = false, nodisp = false;
  int resumes = 0;
  double now = 1000;
  final List<_T> timers = [];

  SpeechTurn listen() =>
      listener.listen(locale: 'es-US', limit: const Duration(seconds: 6));

  /// Fires the oldest timer still running.
  void fire() => timers.firstWhere((t) => t.isActive).fire();
}

class _T implements Timer {
  _T(this.d, this.f);
  final Duration d;
  final void Function() f;
  bool _active = true;

  void fire() {
    _active = false;
    f();
  }

  @override
  void cancel() => _active = false;

  @override
  bool get isActive => _active;

  @override
  int get tick => 0;
}

void main() {
  group(
    'settings (docs/hablar/01-decisiones.md, "What counts as heard right")',
    () {
      test('the language passed in, interimResults false, 5 alternatives, continuous false', () {
        final r = _Rig();
        r.listen();
        expect(r.rec!.set, {
          'lang': 'es-US',
          'interimResults': false,
          'maxAlternatives': 5,
          'continuous': false,
        });
        expect(r.rec!.calls, ['start']);
      });
      test('no language is chosen here: whatever is passed goes through', () {
        final r = _Rig();
        r.listener.listen(
          locale: 'es-PR',
          limit: const Duration(seconds: 6),
          maxAlternatives: 3,
        );
        expect(r.rec!.set['lang'], 'es-PR');
        expect(r.rec!.set['maxAlternatives'], 3);
      });
      test('stop() at the limit, abort() 2.5 s later', () {
        final r = _Rig();
        r.listen();
        expect(r.timers.single.d, const Duration(seconds: 6));
        r.fire();
        expect(r.rec!.calls, ['start', 'stop']);
        expect(r.timers.last.d, const Duration(milliseconds: 2500));
        expect(SpeechSettings.grace, const Duration(milliseconds: 2500));
      });
    },
  );

  group('results', () {
    test(
      'the last result\'s alternatives; ms from the start to speechstart',
      () async {
        final r = _Rig();
        final t = r.listen();
        var ended = false;
        unawaited(t.speechEnd.then((_) => ended = true));
        r.now += 712.4;
        r.rec!.speechstart!();
        r.now += 300;
        r.rec!.speechstart!(); // only the first counts
        r.rec!.speechend!();
        await Future<void>.delayed(Duration.zero);
        expect(ended, isTrue);
        r.rec!.result!(['hola abuela', 'ola abuela']);
        r.rec!.end!();
        final res = await t.result;
        expect(res.alternatives, ['hola abuela', 'ola abuela']);
        expect(res.error, isNull);
        expect(res.msToSound, 712);
        expect(r.resumes, 1); // the iPhone guard
        expect(r.timers.every((x) => !x.isActive), isTrue);
      },
    );
    test('audioend also starts processing', () async {
      final r = _Rig();
      final t = r.listen();
      var ended = false;
      unawaited(t.speechEnd.then((_) => ended = true));
      r.rec!.audioend!();
      await Future<void>.delayed(Duration.zero);
      expect(ended, isTrue);
    });
    test('an error: its code; no speechstart: no ms', () async {
      final r = _Rig();
      final t = r.listen();
      r.rec!.error!('no-speech');
      r.rec!.end!();
      final res = await t.result;
      expect(res.alternatives, isEmpty);
      expect(res.error, 'no-speech');
      expect(res.msToSound, isNull);
      expect(r.nodisp, isFalse);
    });
    test('an error event with no code is "error"', () async {
      final r = _Rig();
      final t = r.listen();
      r.rec!.error!(null);
      r.rec!.end!();
      expect((await t.result).error, 'error');
    });
    test('only "end" ends it; later events change nothing', () async {
      final r = _Rig();
      final t = r.listen();
      r.rec!.result!(['sí']);
      r.rec!.end!();
      r.rec!.result!(['no']);
      r.rec!.end!();
      expect((await t.result).alternatives, ['sí']);
      expect(r.resumes, 1);
    });
  });

  group('the time limit', () {
    test('the recogniser ends after stop(): its own result', () async {
      final r = _Rig();
      final t = r.listen();
      r.fire(); // 6 s: stop()
      r.rec!.result!(['gracias']);
      r.rec!.end!();
      final res = await t.result;
      expect(res.alternatives, ['gracias']);
      expect(res.error, isNull);
    });
    test('it never ends: aborted 2.5 s after stop(), with "aborted"; it cannot hang', () async {
      final r = _Rig();
      final t = r.listen();
      var ended = false;
      unawaited(t.speechEnd.then((_) => ended = true));
      r.fire(); // 6 s
      await Future<void>.delayed(Duration.zero);
      expect(ended, isTrue); // processing shows at the stop
      r.fire(); // 8.5 s
      expect(r.rec!.calls, ['start', 'stop', 'abort']);
      final res = await t.result;
      expect(res.error, 'aborted');
      expect(res.alternatives, isEmpty);
      expect(r.resumes, 1);
    });
    test(
      'aborted at the grace with a result already in: the result, no error',
      () async {
        final r = _Rig();
        final t = r.listen();
        r.fire();
        r.rec!.result!(['adiós']);
        r.fire();
        final res = await t.result;
        expect(res.alternatives, ['adiós']);
        expect(res.error, isNull);
      },
    );
  });

  group('cannot start', () {
    test('the recogniser cannot be made: service-not-allowed', () async {
      final r = _Rig(makeThrows: true);
      final res = await r.listen().result;
      expect(res.error, 'service-not-allowed');
      expect(r.resumes, 1);
      expect(r.nodisp, isTrue);
    });
    test('start() throws: aborted', () async {
      final r = _Rig();
      final l = RecognizerSpeechListener(
        makeRecognizer: () => FakeRecognizer()..throwOnStart = true,
        online: () async => true,
        micDenied: () async => false,
        unavailableThisSession: () => false,
        markUnavailable: () {},
        afterRecognition: () => r.resumes++,
        nowMs: () => 0,
      );
      final res = await l
          .listen(locale: 'es-US', limit: const Duration(seconds: 6))
          .result;
      expect(res.error, 'aborted');
    });
  });

  group('cancel', () {
    test(
      'aborts the recogniser, resumes the sound, ends at once with "aborted"',
      () async {
        final r = _Rig();
        final t = r.listen();
        t.cancel();
        expect(r.rec!.calls, ['start', 'abort']);
        expect(r.resumes, 1);
        expect((await t.result).error, 'aborted');
        r.rec!.end!(); // the browser's end comes later: nothing changes
        expect(r.resumes, 1);
        expect(r.timers.every((x) => !x.isActive), isTrue);
      },
    );
  });

  group('available', () {
    test('a recogniser, online, the mic not denied', () async {
      expect(await _Rig().listener.available(), isTrue);
    });
    test('no recogniser', () async {
      expect(await _Rig(hasRecognizer: false).listener.available(), isFalse);
    });
    test('offline', () async {
      final r = _Rig()..online = false;
      expect(await r.listener.available(), isFalse);
    });
    test('the microphone denied', () async {
      final r = _Rig()..denied = true;
      expect(await r.listener.available(), isFalse);
    });
    test('the permission query fails: not denied', () async {
      final l = RecognizerSpeechListener(
        makeRecognizer: FakeRecognizer.new,
        online: () async => true,
        micDenied: () => Future.error(StateError('no query')),
        unavailableThisSession: () => false,
        markUnavailable: () {},
        afterRecognition: () {},
        nowMs: () => 0,
      );
      expect(await l.available(), isTrue);
    });
    for (final code in SpeechSettings.unavailableErrors) {
      test('after "$code", not for the rest of the session', () async {
        final r = _Rig();
        final t = r.listen();
        r.rec!.error!(code);
        r.rec!.end!();
        expect((await t.result).error, code);
        expect(r.nodisp, isTrue);
        expect(await r.listener.available(), isFalse);
      });
    }
    test('"no-speech" and "aborted" are misses, not unavailable', () async {
      for (final code in ['no-speech', 'aborted']) {
        final r = _Rig();
        final t = r.listen();
        r.rec!.error!(code);
        r.rec!.end!();
        await t.result;
        expect(r.nodisp, isFalse, reason: code);
      }
    });
    test('the five unavailable codes are juego.js\'s NODISP', () {
      expect(SpeechSettings.unavailableErrors, {
        'not-allowed',
        'service-not-allowed',
        'network',
        'audio-capture',
        'language-not-supported',
      });
    });
  });

  group('the phone plugin\'s errors, as the web\'s names', () {
    test('misses and unavailable', () {
      expect(webSpeechError('error_no_match'), 'no-speech');
      expect(webSpeechError('error_speech_timeout'), 'no-speech');
      expect(webSpeechError('error_network'), 'network');
      expect(webSpeechError('error_permission'), 'not-allowed');
      expect(webSpeechError('error_audio_error'), 'audio-capture');
      expect(
        webSpeechError('error_language_unavailable'),
        'language-not-supported',
      );
      expect(webSpeechError('error_busy'), 'aborted');
      expect(webSpeechError('something_new'), 'something_new');
    });
  });

  group('dev page speech recogniser (N2.5)', () {
    test('defaults to Language.spanish.recognitionLocale (es-US)', () async {
      final r = _Rig();
      final future = runDevSpeech(r.listener);
      while (r.rec == null) {
        await Future<void>.delayed(Duration.zero);
      }
      expect(r.rec!.set['lang'], Language.spanish.recognitionLocale);
      expect(r.rec!.set['lang'], 'es-US');
      r.rec!.result!(['hola']);
      r.rec!.end!();
      final probe = await future;
      expect(probe.report['locale'], 'es-US');
      expect(probe.summary, contains('listen(es-US, 6 s)'));
    });

    test(
      'uses custom non-Spanish Language.recognitionLocale (ar-EG)',
      () async {
        final arabic = Language(
          code: 'ar',
          englishName: 'Arabic',
          nativeName: 'العربية',
          recognitionLocale: 'ar-EG',
          direction: LanguageDirection.rtl,
          script: 'Arab',
          partnerName: 'Nadia',
          callAgentId: 'agent_test_arabic_001',
          micWords: const {
            'ready': 'r',
            'listening': 'l',
            'thinking': 't',
            'theySpeak': 's',
            'right': 'ok',
            'notYet': 'no',
          },
          tabNames: const {
            'library': '1',
            'words': '2',
            'map': '3',
            'speak': '4',
            'me': '5',
          },
        );
        final r = _Rig();
        final future = runDevSpeech(r.listener, language: arabic);
        while (r.rec == null) {
          await Future<void>.delayed(Duration.zero);
        }
        expect(r.rec!.set['lang'], 'ar-EG');
        r.rec!.result!(['أهلاً']);
        r.rec!.end!();
        final probe = await future;
        expect(probe.report['locale'], 'ar-EG');
        expect(probe.summary, contains('listen(ar-EG, 6 s)'));
      },
    );
  });
}
