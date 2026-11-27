import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_platform/src/audio/graph_clip_player.dart';
import 'package:coqui_platform/src/audio/sound_core.dart';
import 'package:coqui_platform/src/call/call_session.dart';
import 'package:coqui_platform/src/call/call_stub.dart';
import 'package:coqui_platform/src/call/call_token.dart';
import 'package:coqui_platform/src/web/el_conv.dart';
import 'package:coqui_platform/src/info/app_info.dart';
import 'package:coqui_platform/src/speech/recognition.dart';
import 'package:coqui_platform/src/storage/spaces.dart';
import 'package:coqui_platform/src/web/web_audio_graph.dart';
import 'package:coqui_platform/src/web/web_recognizer.dart';
import 'package:web/web.dart' as web;

/// The page's one sound core: one AudioContext for the clips, the made sounds and the speech guard
/// (juego.js: AC).
final SoundCore webSoundCore = SoundCore(WebAudioGraph.create);

/// The [ClipPlayer] of the web: Web Audio by interop, as juego.js plays. A clip's file is
/// `base.resolve(clipInfo(id).url)`.
ClipPlayer createClipPlayer({
  required ClipLookup clipInfo,
  required Uri base,
}) => GraphClipPlayer(
  core: webSoundCore,
  clipInfo: clipInfo,
  base: base,
  fetch: webFetchBytes,
  onUnlock: _audioSession,
);

void _audioSession() {
  final type = iosAudioSessionType;
  if (type == null) return;
  try {
    final nav = web.window.navigator as JSObject;
    if (!nav.has('audioSession')) return;
    nav
        .getProperty<JSObject>('audioSession'.toJS)
        .setProperty('type'.toJS, type.toJS);
  } catch (_) {}
}

const _nodispKey = 'coqui.habla.nodisp';
var _nodisp = false; // juego.js: HAB.nd

/// The [SpeechListener] of the web: the browser's own recogniser, by interop, as juego.js uses it.
SpeechListener createSpeechListener() {
  final cls = webRecognizerClass();
  return RecognizerSpeechListener(
    makeRecognizer: cls == null ? null : () => WebRecognizer(cls),
    online: () async => web.window.navigator.onLine,
    micDenied: _micDenied,
    // juego.js: habNd
    unavailableThisSession: () {
      try {
        if (web.window.sessionStorage.getItem(_nodispKey) == '1') return true;
      } catch (_) {}
      return _nodisp;
    },
    // juego.js: habPon
    markUnavailable: () {
      _nodisp = true;
      try {
        web.window.sessionStorage.setItem(_nodispKey, '1');
      } catch (_) {}
    },
    afterRecognition: () {
      try {
        webSoundCore.ac().resume();
      } catch (_) {}
    },
    nowMs: () => web.window.performance.now().toDouble(),
  );
}

Future<bool> _micDenied() async {
  final nav = web.window.navigator as JSObject;
  if (!nav.has('permissions')) return false;
  final p = await web.window.navigator.permissions
      .query({'name': 'microphone'}.jsify() as JSObject)
      .toDart;
  return p.state == 'denied';
}

class _LocalStorage implements StringBackend {
  @override
  String? read(String key) {
    try {
      return web.window.localStorage.getItem(key);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> write(String key, String value) async {
    try {
      web.window.localStorage.setItem(key, value);
    } catch (_) {}
  }

  @override
  Future<void> delete(String key) async {
    try {
      web.window.localStorage.removeItem(key);
    } catch (_) {}
  }
}

/// The browser's localStorage, read and written directly (the old app's keys are simply there).
Future<CoquiStorage> openStorage() async => CoquiStorage(_LocalStorage());

/// The page as the browser tells it.
BrowserFacts browserFacts() {
  final nav = web.window.navigator;
  var standalone = false;
  try {
    standalone = web.window.matchMedia('(display-mode: standalone)').matches;
  } catch (_) {}
  try {
    final v = (nav as JSObject).getProperty<JSAny?>('standalone'.toJS);
    if (v != null && v.isA<JSBoolean>() && (v as JSBoolean).toDart) {
      standalone = true;
    }
  } catch (_) {}
  return BrowserFacts(
    userAgent: nav.userAgent,
    platform: nav.platform,
    maxTouchPoints: nav.maxTouchPoints,
    standalone: standalone,
  );
}

/// The tap tick: `navigator.vibrate(8)` (app.html, tick); nothing on an iPhone.
Haptics createHaptics() {
  final nav = web.window.navigator;
  final has = (nav as JSObject).has('vibrate');
  return WebHaptics(
    isIos: browserFacts().isIos,
    vibrate: has ? (ms) => nav.vibrate(ms.toJS) : null,
  );
}

AppInfo createAppInfo() => FixedAppInfo.web(browserFacts());

/// The call with Danny: the ElevenLabs client at the old page's pinned version, by interop. With [stub],
/// the old page's `?callstub=1` instead (a scripted call, no network). [libraryUrl] is for tests and the
/// dev screen: the module to import in place of the pinned client. When [tokenSource] is given, the
/// session requests a short-lived [CallToken] and omits `agentId` and client `dynamicVariables`.
CallSession createCallSession({
  required AppInfo appInfo,
  CallStub? stub,
  String libraryUrl = elevenLabsClientUrl,
  CallTokenSource? tokenSource,
}) => ConvCallSession(
  library: stub ?? JsConvLibrary(libraryUrl),
  callsAllowed: appInfo.callsAllowed,
  beforeStart: _suspendSound,
  afterCall: _resumeSound,
  tokenSource: tokenSource,
);

// order 19b: when the call is over, the sound comes back (the old page reloaded instead)
void _resumeSound() {
  final g = webSoundCore.context;
  if (g is! WebAudioGraph) return;
  final c = g.ctx;
  if (c.isA<web.AudioContext>()) {
    unawaited(
      (c as web.AudioContext).resume().toDart.catchError((Object _) => null),
    );
  }
}

// llamada.js, inicia: `try{if(AC)AC.suspend();}catch(e){}`, before the microphone opens
void _suspendSound() {
  final g = webSoundCore.context;
  if (g is! WebAudioGraph) return;
  final c = g.ctx;
  if (c.isA<web.AudioContext>()) {
    unawaited(
      (c as web.AudioContext).suspend().toDart.catchError((Object _) => null),
    );
  }
}
