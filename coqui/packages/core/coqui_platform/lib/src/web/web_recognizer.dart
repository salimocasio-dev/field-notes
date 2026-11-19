import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:coqui_platform/src/speech/recognition.dart';
import 'package:web/web.dart' as web;

/// juego.js: habSR, `window.SpeechRecognition || window.webkitSpeechRecognition`. Null when neither.
JSFunction? webRecognizerClass() {
  final g = globalContext;
  for (final k in const ['SpeechRecognition', 'webkitSpeechRecognition']) {
    final v = g.getProperty<JSAny?>(k.toJS);
    if (v != null && v.isA<JSFunction>()) return v as JSFunction;
  }
  return null;
}

/// The browser's recogniser, by interop.
class WebRecognizer implements Recognizer {
  WebRecognizer(JSFunction cls)
    : r = cls.callAsConstructor<web.SpeechRecognition>();

  final web.SpeechRecognition r;

  static JSFunction _fn(void Function() f) => ((web.Event _) => f()).toJS;

  @override
  set lang(String v) => r.lang = v;

  @override
  set interimResults(bool v) => r.interimResults = v;

  @override
  set maxAlternatives(int v) => r.maxAlternatives = v;

  @override
  set continuous(bool v) => r.continuous = v;

  @override
  set onspeechstart(void Function()? f) =>
      r.onspeechstart = f == null ? null : _fn(f);

  @override
  set onspeechend(void Function()? f) =>
      r.onspeechend = f == null ? null : _fn(f);

  @override
  set onaudioend(void Function()? f) =>
      r.onaudioend = f == null ? null : _fn(f);

  @override
  set onresult(void Function(List<String> alternatives)? f) {
    r.onresult = f == null
        ? null
        : ((web.SpeechRecognitionEvent e) {
            final rs = e.results.item(e.results.length - 1);
            f([for (var i = 0; i < rs.length; i++) rs.item(i).transcript]);
          }).toJS;
  }

  @override
  set onerror(void Function(String? error)? f) {
    r.onerror = f == null
        ? null
        : ((web.Event e) {
            final o = e as JSObject;
            final v = o.getProperty<JSAny?>('error'.toJS);
            f(v != null && v.isA<JSString>() ? (v as JSString).toDart : null);
          }).toJS;
  }

  @override
  set onend(void Function()? f) => r.onend = f == null ? null : _fn(f);

  @override
  void start() => r.start();

  @override
  void stop() => r.stop();

  @override
  void abort() => r.abort();
}
