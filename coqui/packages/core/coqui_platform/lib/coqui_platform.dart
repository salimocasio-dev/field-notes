/// Audio, speech recognition, the call connection, storage and haptics. The only package with plugins or browser code.
///
/// Order 18: the contracts' `ClipPlayer`, `SpeechListener`, `KeyValueStore` (per space, `CoquiStorage`),
/// `Haptics` and `AppInfo`, ported from how the old web app does these things (historia/juego.js,
/// app.html, palabras.js; docs/hablar/01-decisiones.md).
///
/// - On the web: the browser's own Web Audio, SpeechRecognition, localStorage and vibrate, by interop.
/// - In a phone build (Android, iOS): just_audio, speech_to_text, shared_preferences and the platform's
///   haptics. The browser code is behind a conditional import and is not loaded there.
///
/// Storage spaces: `CoquiStorage.progress` is the progress store's (its own key, `coqui.palabras.v1`, is
/// the key in storage); `space('juego')` holds `ult` and `mem` (the old `coqui.juego.ult`,
/// `coqui.juego.mem`); `space('leer')` holds `tam` (the old `coqui.leer.tam`).
library;

export 'package:coqui_platform/src/audio/graph_clip_player.dart'
    show ClipLookup;
export 'package:coqui_platform/src/call/call_session.dart'
    show elevenLabsClientUrl;
export 'package:coqui_platform/src/call/call_stub.dart'
    show CallStub, CallStubScript;
export 'package:coqui_platform/src/info/app_info.dart'
    show coquiBuild, coquiCallsAllowed, iosAudioSessionType;
export 'package:coqui_platform/src/io/io_platform.dart'
    if (dart.library.js_interop) 'package:coqui_platform/src/web/web_platform.dart'
    show
        createAppInfo,
        createCallSession,
        createClipPlayer,
        createHaptics,
        createSpeechListener,
        openStorage;
export 'package:coqui_platform/src/storage/spaces.dart' show CoquiStorage;
