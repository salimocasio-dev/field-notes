import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:coqui_platform/src/call/call_session.dart';
import 'package:coqui_platform/src/call/conv.dart';
import 'package:web/web.dart' as web;

const _packageRootAssetUrl = 'assets/assets/elevenlabs/lib.iife.js';
const _libsamplerateAssetUrl =
    'assets/packages/coqui_platform/assets/elevenlabs/libsamplerate.worklet.js';
const _packageRootLibsamplerateAssetUrl =
    'assets/assets/elevenlabs/libsamplerate.worklet.js';

/// The ElevenLabs client in the page, by interop, loaded as llamada.js loads it (precarga): a
/// classic script tag for [url] that exposes `window.ElevenLabsClient.Conversation` and sets
/// `window.ELConv` (or `window.ELConvError`). Never imported inside the tap, and uses no inline
/// script or `eval`.
class JsConvLibrary implements ConvLibrary {
  JsConvLibrary(this.url, {String packageRootAssetUrl = _packageRootAssetUrl})
    : _packageRootUrl = packageRootAssetUrl;

  /// The classic IIFE script to load (llamada.js: SDK).
  final String url;
  final String _packageRootUrl;

  Future<bool>? _loading;
  bool? _loaded;
  bool _loadedFromPackageRoot = false;

  static bool get _has => globalContext.has('ELConv');

  @override
  bool? get loaded => _has ? true : _loaded;

  /// Self-hosted `libsamplerate.worklet.js` path matching the asset layout that
  /// loaded `lib.iife.js` (published `assets/packages/coqui_platform/...` or
  /// package-root dev `assets/assets/...`).
  String get libsampleratePath {
    if (_loadedFromPackageRoot || url == _packageRootUrl) {
      return _packageRootLibsamplerateAssetUrl;
    }
    if (url == elevenLabsClientUrl &&
        web.document.querySelector(
              'script[data-coqui-elconv="1"][data-coqui-elconv-package-root="1"]',
            ) !=
            null) {
      return _packageRootLibsamplerateAssetUrl;
    }
    return _libsamplerateAssetUrl;
  }

  // llamada.js: precarga
  @override
  Future<bool> load() {
    if (_has) return Future.value(true);
    final going = _loading;
    if (going != null) return going;
    final done = Completer<bool>();
    final f = _loading = done.future;
    _loadUrl(
      url,
      done,
      canFallback: url == elevenLabsClientUrl && _packageRootUrl != url,
    );
    return f;
  }

  void _loadUrl(
    String currentUrl,
    Completer<bool> done, {
    required bool canFallback,
  }) {
    final s = web.document.createElement('script') as web.HTMLScriptElement;
    s.async = true;
    s.setAttribute('data-coqui-elconv', '1');
    if (currentUrl == _packageRootUrl) {
      s.setAttribute('data-coqui-elconv-package-root', '1');
    }
    final once = web.AddEventListenerOptions(once: true);
    s.addEventListener(
      'load',
      ((web.Event _) {
        if (done.isCompleted) return;
        if (!_has && globalContext.has('ElevenLabsClient')) {
          final client = globalContext.getProperty<JSAny?>(
            'ElevenLabsClient'.toJS,
          );
          if (client != null && client.isA<JSObject>()) {
            final conv = (client as JSObject).getProperty<JSAny?>(
              'Conversation'.toJS,
            );
            if (conv != null && !conv.isUndefinedOrNull) {
              globalContext.setProperty('ELConv'.toJS, conv);
            }
          }
        }
        if (_has) {
          if (globalContext.has('ELConvError')) {
            globalContext.delete('ELConvError'.toJS);
          }
          _loadedFromPackageRoot = currentUrl == _packageRootUrl;
          _loaded = true;
          done.complete(true);
          return;
        }
        s.remove();
        globalContext.setProperty(
          'ELConvError'.toJS,
          'ElevenLabs Conversation export not found.'.toJS,
        );
        _loading = null; // the next precarga tries again
        _loaded = false;
        _loadedFromPackageRoot = false;
        done.complete(false);
      }).toJS,
      once,
    );
    s.addEventListener(
      'error',
      ((web.Event _) {
        if (done.isCompleted) return;
        s.remove();
        if (canFallback) {
          _loadUrl(_packageRootUrl, done, canFallback: false);
          return;
        }
        globalContext.setProperty(
          'ELConvError'.toJS,
          'Failed to load $currentUrl'.toJS,
        );
        _loading = null; // the next precarga tries again
        _loaded = false;
        _loadedFromPackageRoot = false;
        done.complete(false);
      }).toJS,
      once,
    );
    s.src = currentUrl;
    web.document.head!.appendChild(s);
  }

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
      ..setProperty('connectionType'.toJS, o.connectionType.toJS)
      ..setProperty('libsampleratePath'.toJS, libsampleratePath.toJS)
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
    if (o.signedUrl != null) {
      opts.setProperty('signedUrl'.toJS, o.signedUrl!.toJS);
    } else if (o.conversationToken != null) {
      opts.setProperty('conversationToken'.toJS, o.conversationToken!.toJS);
    } else if (o.agentId != null) {
      opts.setProperty('agentId'.toJS, o.agentId!.toJS);
    }
    if (o.dynamicVariables != null) {
      opts.setProperty('dynamicVariables'.toJS, o.dynamicVariables!.jsify());
    }
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
