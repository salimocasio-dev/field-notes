// Small helpers over the browser: page facts, timing, the audio session, storage.
import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:web/web.dart' as web;

/// Milliseconds since navigation start (performance.timeOrigin).
double nowMs() => web.window.performance.now();

/// Round to a whole number of ms, as text.
String ms(num v) => v.isFinite ? v.round().toString() : '?';

/// The text of a thrown JS or Dart error, short. (A JS error's own toString gives "Name: message".)
String errText(Object e) {
  var s = e.toString().replaceAll('\n', ' ');
  if (s.length > 300) s = '${s.substring(0, 300)}...';
  return s;
}

extension _Txt on JSAny? {
  String dartifyText() {
    final v = this;
    if (v == null) return '';
    if (v.isA<JSString>()) return (v as JSString).toDart;
    return v.dartify()?.toString() ?? '';
  }
}

/// Wait for [f], but never longer than [limit]. On timeout returns null.
Future<T?> within<T>(Future<T> f, Duration limit) async {
  try {
    return await f.timeout(limit);
  } on TimeoutException {
    return null;
  }
}

/// Opened from the home screen?
({bool standalone, String detail}) homeScreen() {
  bool mq(String q) {
    try {
      return web.window.matchMedia(q).matches;
    } catch (_) {
      return false;
    }
  }

  final dm = mq('(display-mode: standalone)');
  final fs = mq('(display-mode: fullscreen)');
  String nav = 'not present';
  bool navOn = false;
  try {
    final v = web.window.navigator.getProperty<JSAny?>('standalone'.toJS);
    if (v != null && v.isA<JSBoolean>()) {
      navOn = (v as JSBoolean).toDart;
      nav = navOn ? 'true' : 'false';
    }
  } catch (_) {}
  final on = dm || fs || navOn;
  return (
    standalone: on,
    detail:
        'display-mode standalone: ${dm ? 'yes' : 'no'}${fs ? ', fullscreen: yes' : ''}, navigator.standalone: $nav',
  );
}

/// navigator.audioSession: set the type to [type] where it exists, and say what happened.
String setAudioSession(String type) {
  try {
    final nav = web.window.navigator as JSObject;
    if (!nav.has('audioSession')) return 'navigator.audioSession: not present';
    final s = nav.getProperty<JSObject?>('audioSession'.toJS);
    if (s == null) return 'navigator.audioSession: null';
    final before = s.getProperty<JSAny?>('type'.toJS).dartifyText();
    String err = '';
    try {
      s.setProperty('type'.toJS, type.toJS);
    } catch (e) {
      err = ', setting it threw ${errText(e)}';
    }
    final after = s.getProperty<JSAny?>('type'.toJS).dartifyText();
    final state = s.has('state')
        ? ', state "${s.getProperty<JSAny?>('state'.toJS).dartifyText()}"'
        : '';
    return 'navigator.audioSession: present, type was "$before", set to "$type"$err, reads "$after"$state';
  } catch (e) {
    return 'navigator.audioSession: error ${errText(e)}';
  }
}

/// Does this browser have navigator.audioSession?
bool hasAudioSession() {
  try {
    return (web.window.navigator as JSObject).has('audioSession');
  } catch (_) {
    return false;
  }
}

/// Set navigator.audioSession.type to [type] and wait (up to 1 s) until it reads back as [type].
/// Never throws: a throw from the setter is reported in the line.
Future<({bool ok, String line})> switchAudioSession(String type) async {
  try {
    final s = (web.window.navigator as JSObject).getProperty<JSObject?>(
      'audioSession'.toJS,
    );
    if (s == null) return (ok: false, line: 'navigator.audioSession is null');
    final before = s.getProperty<JSAny?>('type'.toJS).dartifyText();
    try {
      s.setProperty('type'.toJS, type.toJS);
    } catch (e) {
      return (
        ok: false,
        line:
            'setting the type to "$type" threw ${errText(e)} (it reads "${s.getProperty<JSAny?>('type'.toJS).dartifyText()}")',
      );
    }
    final t0 = nowMs();
    var now = s.getProperty<JSAny?>('type'.toJS).dartifyText();
    while (now != type && nowMs() - t0 < 1000) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
      now = s.getProperty<JSAny?>('type'.toJS).dartifyText();
    }
    final took = ms(nowMs() - t0);
    return now == type
        ? (
            ok: true,
            line:
                'audio session type set to "$type" (was "$before"), reads "$now" after $took ms',
          )
        : (
            ok: false,
            line:
                'audio session type set to "$type" (was "$before"), but it still reads "$now" after $took ms',
          );
  } catch (e) {
    return (ok: false, line: 'audio session: ${errText(e)}');
  }
}

/// The current navigator.audioSession type, or '' when there is none.
String audioSessionType() {
  try {
    final nav = web.window.navigator as JSObject;
    if (!nav.has('audioSession')) return '';
    final s = nav.getProperty<JSObject?>('audioSession'.toJS);
    return s?.getProperty<JSAny?>('type'.toJS).dartifyText() ?? '';
  } catch (_) {
    return '';
  }
}

String userAgent() => web.window.navigator.userAgent;

/// The meters script (web/coqui_meter.js) objects.
JSObject? get coquiMedia =>
    web.window.getProperty<JSObject?>('__coquiMedia'.toJS);
JSObject? get coquiShim =>
    web.window.getProperty<JSObject?>('__coquiShim'.toJS);

/// Errors the window saw (kept by coqui_meter.js).
List<String> windowErrors() {
  try {
    final a = web.window.getProperty<JSArray<JSString>?>('__coquiErrors'.toJS);
    if (a == null) return const [];
    return a.toDart.map((s) => s.toDart).toList();
  } catch (_) {
    return const [];
  }
}

/// The engine's "flutter-first-frame" time, ms since navigation start (null until it fires).
double? firstFrameMs() {
  final v = web.window.getProperty<JSAny?>('__coquiFirstFrame'.toJS);
  if (v == null || !v.isA<JSNumber>()) return null;
  return (v as JSNumber).toDartDouble;
}

/// Mirror text for scripts (window.__results) and a small state object (window.__state).
void mirror(String results, String stateJson) {
  web.window.setProperty('__results'.toJS, results.toJS);
  web.window.setProperty('__state'.toJS, stateJson.toJS);
}

/// localStorage, every call wrapped (it can throw in private modes).
String? lsGet(String k) {
  try {
    return web.window.localStorage.getItem(k);
  } catch (_) {
    return null;
  }
}

String? lsSet(String k, String v) {
  try {
    web.window.localStorage.setItem(k, v);
    return null;
  } catch (e) {
    return errText(e);
  }
}

List<String> lsKeys() {
  try {
    final s = web.window.localStorage;
    return [for (var i = 0; i < s.length; i++) s.key(i) ?? ''];
  } catch (_) {
    return const [];
  }
}

/// navigator.storage.persisted(), within 3 s.
Future<String> storagePersisted() async {
  try {
    final nav = web.window.navigator as JSObject;
    if (!nav.has('storage')) return 'navigator.storage: not present';
    final st = web.window.navigator.storage;
    final p = await within(st.persisted().toDart, const Duration(seconds: 3));
    if (p == null) return 'navigator.storage.persisted(): no answer in 3 s';
    return 'navigator.storage.persisted(): ${p.toDart}';
  } catch (e) {
    return 'navigator.storage.persisted(): ${errText(e)}';
  }
}

/// Copy text to the clipboard inside the tap. Returns null on success, else the error text.
Future<String?> copyText(String text) async {
  try {
    final nav = web.window.navigator as JSObject;
    if (!nav.has('clipboard')) return 'navigator.clipboard is not present';
    final p = web.window.navigator.clipboard.writeText(text);
    final r = await within(
      p.toDart.then((_) => true),
      const Duration(seconds: 3),
    );
    if (r == null) return 'no answer from the clipboard in 3 s';
    return null;
  } catch (e) {
    return errText(e);
  }
}

/// Resource timing: the bytes fetched over the network for the app files (0 when they came from the cache).
String loadedBytes() {
  try {
    final entries = web.window.performance.getEntriesByType('resource').toDart;
    var total = 0;
    var cached = 0;
    var count = 0;
    final named = <String>[];
    for (final e in entries) {
      final r = e as web.PerformanceResourceTiming;
      final name = r.name;
      if (!name.contains('/prueba/')) continue;
      count++;
      total += r.transferSize;
      if (r.transferSize == 0 && r.decodedBodySize > 0) cached++;
      final short = name.split('?').first.split('/').last;
      if (short == 'main.dart.js' ||
          short == 'canvaskit.wasm' ||
          short == 'skwasm.wasm' ||
          short == 'main.dart.wasm') {
        named.add(
          '$short ${(r.transferSize / 1024).round()} KB over the network'
          ' (${(r.decodedBodySize / 1024).round()} KB), ${ms(r.duration)} ms',
        );
      }
    }
    return 'app files: $count, ${(total / 1024).round()} KB over the network, $cached from the cache'
        '${named.isEmpty ? '' : '; ${named.join('; ')}'}';
  } catch (e) {
    return 'resource timing: ${errText(e)}';
  }
}

/// Navigation timing marks, ms since navigation start.
String navMarks() {
  try {
    final n = web.window.performance.getEntriesByType('navigation').toDart;
    if (n.isEmpty) return 'navigation timing: none';
    final t = n.first as web.PerformanceNavigationTiming;
    return 'page response ${ms(t.responseEnd)} ms, DOM ready ${ms(t.domContentLoadedEventEnd)} ms, '
        'load event ${ms(t.loadEventEnd)} ms, navigation type "${t.type}"';
  } catch (e) {
    return 'navigation timing: ${errText(e)}';
  }
}

/// How often the tap listener in coqui_meter.js found the audio context not running and resumed it.
String safetyNet() {
  final v = web.window.getProperty<JSAny?>('__coquiNet'.toJS);
  final n = v != null && v.isA<JSNumber>() ? (v as JSNumber).toDartInt : 0;
  return n == 0
      ? 'the tap safety net never had to resume the context'
      : 'the tap safety net found the context not running on $n tap events and resumed it';
}
