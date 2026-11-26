import 'dart:async';
import 'dart:io';

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_platform/src/speech/plugin_errors.dart';
import 'package:coqui_platform/src/speech/recognition.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// Minimal surface of [SpeechToText] used by [PhoneSpeech], allowing tests to
/// inject a fake without touching platform channels.
abstract interface class SpeechPlugin {
  Future<bool> get hasPermission;
  Future<bool> initialize({
    SpeechErrorListener? onError,
    SpeechStatusListener? onStatus,
  });
  Future<void> listen({
    SpeechResultListener? onResult,
    SpeechListenOptions? listenOptions,
  });
  Future<void> stop();
  Future<void> cancel();
}

class _SpeechToTextPlugin implements SpeechPlugin {
  _SpeechToTextPlugin(this._stt);
  final SpeechToText _stt;

  @override
  Future<bool> get hasPermission => _stt.hasPermission;

  @override
  Future<bool> initialize({
    SpeechErrorListener? onError,
    SpeechStatusListener? onStatus,
  }) => _stt.initialize(onError: onError, onStatus: onStatus);

  @override
  Future<void> listen({
    SpeechResultListener? onResult,
    SpeechListenOptions? listenOptions,
  }) => _stt.listen(onResult: onResult, listenOptions: listenOptions);

  @override
  Future<void> stop() => _stt.stop();

  @override
  Future<void> cancel() => _stt.cancel();
}

/// The phone's recogniser (speech_to_text), made to look like the browser's to the turn code
/// ([RecognizerSpeechListener]), so the turn's timing and its results are the web's: `stop()` at the
/// limit, `abort()` 2.5 s later, the same error names ([webSpeechError]).
///
/// Prefers on-device recognition (`onDevice: true`) when supported so offline speech works without
/// a network lookup; falls back to network recognition when on-device recognition is unsupported.
///
/// What the plugin does not give: the moment speech starts (so `msToSound` is null), and how many
/// alternatives it is asked for (Android asks for 10; the first ones asked for are kept).
class PhoneSpeech {
  PhoneSpeech({
    this.networkProbeHost,
    Future<bool> Function(String host)? lookupHost,
    this.onDeviceSupported,
    SpeechPlugin? plugin,
  }) : _lookupHost = lookupHost ?? _defaultLookupHost,
       _stt = plugin ?? _SpeechToTextPlugin(SpeechToText());

  /// Optional host looked up when on-device recognition is unavailable. Null by default:
  /// no external DNS probe is performed before listening.
  final String? networkProbeHost;

  final Future<bool> Function(String host) _lookupHost;
  final Future<bool> Function({String? localeId})? onDeviceSupported;
  final SpeechPlugin _stt;
  bool _ready = false;
  bool _deviceLacksOnDevice = false;
  final Set<String> _unsupportedOnDeviceLocales = {};
  _PluginRecognizer? _current;

  static Future<bool> _defaultLookupHost(String host) async {
    try {
      final a = await InternetAddress.lookup(host)
          .timeout(const Duration(seconds: 3));
      return a.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

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

  /// Whether on-device recognition should be attempted for [localeId].
  Future<bool> supportsOnDevice({String? localeId}) async {
    if (_deviceLacksOnDevice) return false;
    if (localeId != null &&
        localeId.isNotEmpty &&
        _unsupportedOnDeviceLocales.contains(localeId)) {
      return false;
    }
    final check = onDeviceSupported;
    if (check != null) {
      try {
        return await check(localeId: localeId);
      } catch (_) {
        return false;
      }
    }
    return true;
  }

  void _markOnDeviceUnsupported(String localeId) {
    if (localeId.isEmpty) {
      _deviceLacksOnDevice = true;
    } else {
      _unsupportedOnDeviceLocales.add(localeId);
    }
  }

  Future<bool> online() async {
    if (await supportsOnDevice()) return true;
    final host = networkProbeHost;
    if (host == null || host.isEmpty) return true;
    try {
      return await _lookupHost(host);
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
  bool _usedOnDevice = false;
  bool _retriedWithoutOnDevice = false;
  bool _retrying = false;

  static const _onDeviceErrors = {
    'onDeviceError',
    'error_language_unavailable',
    'error_language_not_supported',
  };

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
    if (_retrying) return;
    if (s == SpeechToText.notListeningStatus) {
      _speechEnd?.call();
      _audioEnd?.call();
    } else if (s == SpeechToText.doneStatus) {
      _finish();
    }
  }

  void _error(SpeechRecognitionError e) {
    if (_usedOnDevice &&
        !_retriedWithoutOnDevice &&
        !_ended &&
        _onDeviceErrors.contains(e.errorMsg)) {
      _retriedWithoutOnDevice = true;
      _retrying = true;
      _usedOnDevice = false;
      o._markOnDeviceUnsupported(_lang);
      unawaited(_listen(onDevice: false));
      return;
    }
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
    final useOnDevice = await o.supportsOnDevice(
      localeId: _lang.isEmpty ? null : _lang,
    );
    if (_ended) return;
    _usedOnDevice = useOnDevice;
    await _listen(onDevice: useOnDevice);
  }

  Future<void> _listen({required bool onDevice}) async {
    try {
      await o._stt.listen(
        onResult: _onResult,
        listenOptions: SpeechListenOptions(
          partialResults: false,
          cancelOnError: true,
          localeId: _lang,
          listenMode: ListenMode.confirmation,
          onDevice: onDevice,
        ),
      );
      _retrying = false;
      if (_ended) {
        unawaited(o._stt.cancel().catchError((Object _) {}));
      }
    } catch (_) {
      if (onDevice && !_retriedWithoutOnDevice && !_ended) {
        _retriedWithoutOnDevice = true;
        _retrying = true;
        _usedOnDevice = false;
        o._markOnDeviceUnsupported(_lang);
        await _listen(onDevice: false);
        return;
      }
      _retrying = false;
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
