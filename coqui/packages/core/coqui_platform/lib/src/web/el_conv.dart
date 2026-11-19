import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:coqui_platform/src/call/conv.dart';
import 'package:web/web.dart' as web;

/// The ElevenLabs client in the page, by interop, loaded as llamada.js loads it (precarga): a module
/// script that imports [url] and sets `window.ELConv` to its `Conversation` (or `window.ELConvError`),
/// then fires "elconv". Never imported inside the tap.
class JsConvLibrary implements ConvLibrary {
  JsConvLibrary(this.url);

  /// The module to import (llamada.js: SDK).
  final String url;

  Future<bool>? _loading;
  bool? _loaded;

  static bool get _has => globalContext.has('ELConv');

  @override
  bool? get loaded => _has ? true : _loaded;

  // llamada.js: precarga
  @override
  Future<bool> load() {
    if (_has) return Future.value(true);
    final going = _loading;
    if (going != null) return going;
    final done = Completer<bool>();
    final f = _loading = done.future;
    web.window.addEventListener(
      'elconv',
      ((web.Event _) {
        if (!_has) _loading = null; // the next precarga tries again
        _loaded = _has;
        done.complete(_has);
      }).toJS,
      web.AddEventListenerOptions(once: true),
    );
    final s = web.document.createElement('script') as web.HTMLScriptElement;
    s.type = 'module';
    s.textContent =
        'try{const m=await import(${_jsString(url)});window.ELConv=m.Conversation;}'
        'catch(e){window.ELConvError=String(e);}dispatchEvent(new Event("elconv"));';
    web.document.head!.appendChild(s);
    return f;
  }

  static String _jsString(String s) =>
      '"${s.replaceAll(r'\', r'\\').replaceAll('"', r'\"')}"';

  @override
  Future<Conv> startSession(ConvOptions o) {
    final el = globalContext.getProperty<JSObject>('ELConv'.toJS);
    final tools = JSObject();
    for (final e in o.clientTools.entries) {
      tools.setProperty(
        e.key.toJS,
        ((JSAny? p) => e.value(p.dartify()).jsify()).toJS,
      );
    }
    final opts = JSObject()
      ..setProperty('agentId'.toJS, o.agentId.toJS)
      ..setProperty('connectionType'.toJS, o.connectionType.toJS)
      ..setProperty('dynamicVariables'.toJS, o.dynamicVariables.jsify())
      ..setProperty('clientTools'.toJS, tools)
      ..setProperty(
        'onConnect'.toJS,
        ((JSAny? d) => o.onConnect(d.dartify())).toJS,
      )
      ..setProperty(
        'onDisconnect'.toJS,
        ((JSAny? d) => o.onDisconnect(d.dartify())).toJS,
      )
      ..setProperty('onError'.toJS, ((JSAny? e) => o.onError(_err(e))).toJS)
      ..setProperty(
        'onMessage'.toJS,
        ((JSAny? m) => o.onMessage(m.dartify())).toJS,
      )
      ..setProperty(
        'onModeChange'.toJS,
        ((JSAny? m) => o.onModeChange(m.dartify())).toJS,
      );
    final done = Completer<Conv>();
    try {
      final p = el.callMethod<JSPromise<JSObject>>('startSession'.toJS, opts);
      p.callMethod(
        'then'.toJS,
        ((JSObject c) {
          done.complete(_JsConv(c));
        }).toJS,
        ((JSAny? e) {
          final x = _errParts(e);
          done.completeError(ConvStartError(x.$1, x.$2));
        }).toJS,
      );
    } catch (e) {
      done.completeError(ConvStartError('Error', '$e'));
    }
    return done.future;
  }

  /// An error as the page reads it: its message, or itself.
  static Object? _err(JSAny? e) {
    if (e == null) return null;
    if (e.isA<JSString>()) return (e as JSString).toDart;
    final o = e as JSObject;
    final m = o.getProperty<JSAny?>('message'.toJS);
    if (m != null && m.isA<JSString>()) {
      return {'message': (m as JSString).toDart};
    }
    return e.dartify();
  }

  static (String, String) _errParts(JSAny? e) {
    if (e == null) return ('Error', '');
    if (e.isA<JSString>()) return ('Error', (e as JSString).toDart);
    final o = e as JSObject;
    String s(String k) {
      final v = o.getProperty<JSAny?>(k.toJS);
      return v != null && v.isA<JSString>() ? (v as JSString).toDart : '';
    }

    final n = s('name');
    return (n.isEmpty ? 'Error' : n, s('message'));
  }
}

class _JsConv implements Conv {
  _JsConv(this.c);
  final JSObject c;

  @override
  void sendUserMessage(String text) =>
      c.callMethod<JSAny?>('sendUserMessage'.toJS, text.toJS);

  @override
  void endSession() => c.callMethod<JSAny?>('endSession'.toJS);

  double _num(String m) {
    final v = c.callMethod<JSAny?>(m.toJS);
    return v != null && v.isA<JSNumber>() ? (v as JSNumber).toDartDouble : 0;
  }

  @override
  double getInputVolume() => _num('getInputVolume');

  @override
  double getOutputVolume() => _num('getOutputVolume');

  @override
  void setVolume(double v) {
    if (!c.has('setVolume')) return;
    c.callMethod<JSAny?>('setVolume'.toJS, {'volume': v}.jsify());
  }
}
