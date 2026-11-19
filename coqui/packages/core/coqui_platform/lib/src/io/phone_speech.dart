import 'dart:async';
import 'dart:io';

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_platform/src/speech/plugin_errors.dart';
import 'package:coqui_platform/src/speech/recognition.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// The phone's recogniser (speech_to_text), made to look like the browser's to the turn code
/// ([RecognizerSpeechListener]), so the turn's timing and its results are the web's: `stop()` at the
/// limit, `abort()` 2.5 s later, the same error names ([webSpeechError]).
///
/// What the plugin does not give: the moment speech starts (so `msToSound` is null), and how many
/// alternatives it is asked for (Android asks for 10; the first ones asked for are kept).
class PhoneSpeech {
  PhoneSpeech({this.networkProbeHost = 'www.google.com'});

  /// A name looked up to know the phone is online (the phone's recogniser sends the sound to it on
  /// Android, as Chrome does).
  final String networkProbeHost;

  final SpeechToText _stt = SpeechToText();
  bool _ready = false;
  _PluginRecognizer? _current;

  Future<bool> _init() async {
    if (_ready) return true;
    try {
      _ready = await _stt.initialize(
        onError: (e) => _current?._error(e),
        onStatus: (s) => _current?._status(s),
      );
    } catch (_) {
      _ready = false;
    }
    return _ready;
  }

  Future<bool> online() async {
    try {
      final a = await InternetAddress.lookup(networkProbeHost)
          .timeout(const Duration(seconds: 3));
      return a.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// "Denied": the permission was asked for and refused, or there is no recogniser. Before it was
  /// ever asked for, it is not denied: the first listen asks (as the browser asks at the first turn).
  Future<bool> micDenied() async {
    if (_ready) return false;
    if (_asked && !await _stt.hasPermission) return true;
    if (await _stt.hasPermission) return !await _init();
    return false;
  }

  bool _asked = false;

  bool _nd = false;

  SpeechListener listener() => RecognizerSpeechListener(
    makeRecognizer: () => _PluginRecognizer(this),
    online: online,
    micDenied: micDenied,
    unavailableThisSession: () => _nd,
    markUnavailable: () => _nd = true,
    afterRecognition: () {},
    nowMs: () => DateTime.now().microsecondsSinceEpoch / 1000,
  );
}

class _PluginRecognizer implements Recognizer {
  _PluginRecognizer(this.o);
  final PhoneSpeech o;

  String _lang = '';
  int _max = 5;
  void Function()? _speechEnd, _audioEnd, _end;
  void Function(List<String>)? _result;
  void Function(String?)? _err;
  bool _ended = false;

  @override
  set lang(String v) => _lang = v;

  @override
  set interimResults(bool v) {}

  @override
  set maxAlternatives(int v) => _max = v;

  @override
  set continuous(bool v) {}

  @override
  set onspeechstart(void Function()? f) {}

  @override
  set onspeechend(void Function()? f) => _speechEnd = f;

  @override
  set onaudioend(void Function()? f) => _audioEnd = f;

  @override
  set onresult(void Function(List<String> alternatives)? f) => _result = f;

  @override
  set onerror(void Function(String? error)? f) => _err = f;

  @override
  set onend(void Function()? f) => _end = f;

  void _finish() {
    if (_ended) return;
    _ended = true;
    if (identical(o._current, this)) o._current = null;
    _end?.call();
  }

  void _status(String s) {
    if (s == SpeechToText.notListeningStatus) {
      _speechEnd?.call();
      _audioEnd?.call();
    } else if (s == SpeechToText.doneStatus) {
      _finish();
    }
  }

  void _error(SpeechRecognitionError e) {
    _err?.call(webSpeechError(e.errorMsg));
    _finish();
  }

  void _onResult(SpeechRecognitionResult r) {
    final alts = [for (final a in r.alternates.take(_max)) a.recognizedWords];
    _result?.call(alts);
  }

  @override
  void start() => unawaited(_go());

  Future<void> _go() async {
    o._asked = true;
    if (!await o._init()) {
      _err?.call(
        await o._stt.hasPermission ? 'service-not-allowed' : 'not-allowed',
      );
      _finish();
      return;
    }
    if (_ended) return;
    o._current = this;
    try {
      await o._stt.listen(
        onResult: _onResult,
        listenOptions: SpeechListenOptions(
          partialResults: false,
          cancelOnError: true,
          localeId: _lang,
          listenMode: ListenMode.confirmation,
        ),
      );
    } catch (_) {
      _err?.call('aborted');
      _finish();
    }
  }

  @override
  void stop() => unawaited(o._stt.stop().catchError((Object _) {}));

  @override
  void abort() {
    unawaited(o._stt.cancel().catchError((Object _) {}));
    scheduleMicrotask(
      _finish,
    ); // the browser's "end" comes after abort() returns
  }
}
