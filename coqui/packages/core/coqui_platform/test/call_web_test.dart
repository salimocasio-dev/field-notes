@TestOn('browser')
library;

import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_platform/coqui_platform.dart'
    show CallStub, CallStubScript, CallToken, CallTokenSource;
import 'package:coqui_platform/src/call/call_session.dart';
import 'package:coqui_platform/src/call/conv.dart';
import 'package:coqui_platform/src/web/el_conv.dart';
import 'package:coqui_platform/src/web/web_platform.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fixtures/llamada_stub_js.dart';

// The interop, in Chrome, against the old page's own fake client: llamada.js's installStub, as it is
// (test/fixtures/llamada_stub_js.dart, made by tool/llamada_stub.mjs), run with the ?stub= options given.

final _brief = CallBrief(
  placeId: 'casa',
  minutes: 5,
  job: 'Say hello, say who you are, accept a drink and say thanks.',
  opening: '¡Hola! Soy Danny. ¿Cómo estás?',
  photo: 'casa',
);
const _vars = {
  'place': 'La casa',
  'words_open': 'hola, casa',
  'words_heard': '',
};

class _FixedTokenSource implements CallTokenSource {
  _FixedTokenSource(this.token);

  final CallToken token;
  int calls = 0;
  CallBrief? lastBrief;
  List<String>? lastWordsOpen;
  List<String>? lastWordsHeard;

  @override
  Future<CallToken> fetchToken(
    CallBrief brief, {
    List<String> wordsOpen = const [],
    List<String> wordsHeard = const [],
  }) async {
    calls++;
    lastBrief = brief;
    lastWordsOpen = wordsOpen;
    lastWordsHeard = wordsHeard;
    return token;
  }
}

void _install(List<String> opts) {
  globalContext.delete('ELConv'.toJS);
  globalContext.delete('CallStub'.toJS);
  globalContext.delete('ELConvError'.toJS);
  globalContext.delete('ElevenLabsClient'.toJS);
  globalContext.callMethod(
    'eval'.toJS,
    '(function(){const STUBOPT=new Set(${jsonEncode(opts)});const CLK=1;\n$llamadaInstallStub\ninstallStub();})()'
        .toJS,
  );
}

Object? _js(String expr) =>
    globalContext.callMethod<JSAny?>('eval'.toJS, expr.toJS).dartify();

ConvCallSession _session({CallTokenSource? tokenSource}) => ConvCallSession(
  library: JsConvLibrary(elevenLabsClientUrl),
  callsAllowed: true,
  tokenSource: tokenSource,
);

String _show(CallEvent e) => switch (e) {
  Connected() => 'Connected',
  AgentLine(:final text) => 'AgentLine $text',
  Heard(:final text) => 'Heard $text',
  Mode(:final mode) => 'Mode $mode',
  Tool(:final name, :final args) => 'Tool $name $args',
  CallError(:final message) => 'CallError $message',
  Ended(:final reason) => 'Ended $reason',
};

Future<void> _ms(int ms) => Future<void>.delayed(Duration(milliseconds: ms));

void main() {
  tearDown(() => _js('window.CallStub&&(window.CallStub.ended=true),0'));

  test('legacy no-token-source path: agentId, websocket, six dynamicVariables, no signedUrl/conversationToken/overrides', () async {
    _install(['manual']);
    final s = _session();
    unawaited(s.start(_brief, _vars));
    await _ms(10);
    expect(
      _js(
        "(()=>{const o=CallStub.opts;return [o.agentId,o.connectionType,!('overrides' in o)&&!('signedUrl' in o)&&!('conversationToken' in o),Object.keys(o.dynamicVariables).join(','),o.dynamicVariables.minutes,o.dynamicVariables.opening,typeof o.clientTools.show_picture,o.libsampleratePath]})()",
      ),
      [
        'agent_3301m795q3xtfpx8c99zc0s870vm',
        'websocket',
        true,
        'place,job,words_open,words_heard,minutes,opening',
        '5',
        '¡Hola! Soy Danny. ¿Cómo estás?',
        'function',
        'assets/packages/coqui_platform/assets/elevenlabs/libsamplerate.worklet.js',
      ],
    );
  });

  test('token-source signedUrl path (#249): passes signedUrl and websocket without agentId, dynamicVariables, conversationToken, or overrides', () async {
    _install(['manual']);
    const signedUrl = 'wss://call-api.example.com/v1/call/ws?ticket=tok_web_1';
    final source = _FixedTokenSource(CallToken.signedUrl(signedUrl));
    final s = _session(tokenSource: source);
    final ev = <String>[];
    s.events.listen((e) => ev.add(_show(e)));
    final started = s.start(_brief, {
      'place': 'La casa',
      'words_open': 'hola, casa',
      'words_heard': 'agua',
    });
    await _ms(10);
    expect(source.calls, 1);
    expect(source.lastBrief, _brief);
    expect(source.lastWordsOpen, ['hola', 'casa']);
    expect(source.lastWordsHeard, ['agua']);
    expect(
      _js(
        "(()=>{const o=CallStub.opts;return [o.signedUrl,o.connectionType,!('agentId' in o),!('dynamicVariables' in o),!('conversationToken' in o),!('overrides' in o),typeof o.clientTools.show_picture,o.libsampleratePath]})()",
      ),
      [
        signedUrl,
        'websocket',
        true,
        true,
        true,
        true,
        'function',
        'assets/packages/coqui_platform/assets/elevenlabs/libsamplerate.worklet.js',
      ],
    );
    _js("CallStub.go('connect')");
    await started;
    expect(ev, ['Connected']);
    await s.end();
  });

  test('token-source conversationToken path (#249): passes conversationToken and webrtc without agentId, dynamicVariables, signedUrl, or overrides', () async {
    _install(['manual']);
    const conversationToken = 'conv_tok_web_2';
    final source = _FixedTokenSource(
      CallToken.conversationToken(conversationToken),
    );
    final s = _session(tokenSource: source);
    final started = s.start(_brief, _vars);
    await _ms(10);
    expect(source.calls, 1);
    expect(
      _js(
        "(()=>{const o=CallStub.opts;return [o.conversationToken,o.connectionType,!('agentId' in o),!('dynamicVariables' in o),!('signedUrl' in o),!('overrides' in o),typeof o.clientTools.show_picture,o.libsampleratePath]})()",
      ),
      [
        conversationToken,
        'webrtc',
        true,
        true,
        true,
        true,
        'function',
        'assets/packages/coqui_platform/assets/elevenlabs/libsamplerate.worklet.js',
      ],
    );
    _js("CallStub.go('connect')");
    await started;
    await s.end();
  });

  test('createCallSession forwards tokenSource on web (#249)', () async {
    _install(['manual']);
    const signedUrl = 'wss://call-api.example.com/v1/call/ws?ticket=tok_web_3';
    final source = _FixedTokenSource(CallToken.signedUrl(signedUrl));
    final s = createCallSession(appInfo: createAppInfo(), tokenSource: source);
    final started = s.start(_brief, _vars);
    await _ms(10);
    expect(source.calls, 1);
    expect(
      _js(
        "(()=>{const o=CallStub.opts;return [o.signedUrl,o.connectionType,!('agentId' in o),!('dynamicVariables' in o)]})()",
      ),
      [signedUrl, 'websocket', true, true],
    );
    _js("CallStub.go('connect')");
    await started;
    await s.end();
  });

  test('custom non-Spanish CallBrief.agentId reaches JsConvLibrary.startSession (N2.5)', () async {
    _install(['manual']);
    final s = _session();
    final brief = CallBrief(
      placeId: 'casa',
      minutes: 5,
      job: 'job',
      opening: 'أهلاً',
      photo: 'casa',
      agentId: 'agent_test_arabic_001',
    );
    unawaited(s.start(brief, _vars));
    await _ms(10);
    expect(_js('CallStub.opts.agentId'), 'agent_test_arabic_001');
  });

  test('stepped call (stub=manual,nofin): connect, Danny, your turn, heard, the picture, Help, (fin), Danny ends it', () async {
    _install(['manual', 'nofin']);
    final s = _session();
    final ev = <String>[];
    s.events.listen((e) => ev.add(_show(e)));
    var started = false;
    unawaited(s.start(_brief, _vars).then((_) => started = true));
    await _ms(10);
    expect(started, isFalse);
    for (final n in ['connect', 'danny1', 'you1', 'talk1']) {
      _js("CallStub.go('$n')");
    }
    await _ms(0); // the answer settles
    expect(s.inputVolume(), greaterThan(.09)); // talk1: the learner's level
    expect(s.outputVolume(), 0);
    for (final n in ['heard1', 'danny2']) {
      _js("CallStub.go('$n')");
    }
    await _ms(600); // the picture comes 500 ms after Danny's second line
    expect(started, isTrue);
    expect(
      _js(
        "[CallStub.o.clientTools.show_picture({picture:'zzz'}),CallStub.o.clientTools.show_picture('nada')]",
      ),
      ['shown', 'shown'], // the tool answers "shown", whatever the key
    );
    expect(s.outputVolume(), greaterThan(.09)); // Danny is speaking
    expect(s.inputVolume(), .004);
    s.send('(ayuda)');
    s.send('(fin)');
    s.setVolume(.5); // the old stub has no setVolume: nothing breaks
    expect(_js("CallStub.sent.join(' ')"), '(ayuda) (fin)');
    _js("CallStub.go('end')");
    await _ms(10);
    expect(ev, [
      'Connected',
      'Mode speaking',
      'AgentLine ¡Hola! Soy Danny. ¿Cómo estás?',
      'Mode listening',
      'Heard Hola. Bien, gracias.',
      'Mode speaking',
      'AgentLine Eso. Mira. ¿Quieres jugo?',
      'Tool show_picture {picture: jugo}',
      'Tool show_picture {picture: zzz}',
      'Tool show_picture {picture: nada}',
      'Ended agent',
    ]);
  });

  test('X while calling: the late answer is ended at once', () async {
    _install(['manual']);
    final s = _session();
    final f = s.start(_brief, _vars);
    await _ms(10);
    await s.end();
    _js("CallStub.go('connect')");
    await f;
    await _ms(100);
    expect(_js('CallStub.ended'), isTrue);
  });

  test(
    'pagehide / the X during the call: end() ends the session (Ended "user")',
    () async {
      _install(['manual']);
      final s = _session();
      final ev = <String>[];
      s.events.listen((e) => ev.add(_show(e)));
      final f = s.start(_brief, _vars);
      await _ms(10);
      _js("CallStub.go('connect')");
      await f;
      await s.end();
      await _ms(100);
      expect(_js('CallStub.ended'), isTrue);
      expect(ev, ['Connected', 'Ended user']);
    },
  );

  test('refused microphone: start throws NotAllowedError', () async {
    _install(['mic']);
    await expectLater(
      _session().start(_brief, _vars),
      throwsA(
        isA<CallStartError>().having(
          (e) => '$e',
          'text',
          'NotAllowedError: Permission denied',
        ),
      ),
    );
  });

  test('failed start: start throws', () async {
    _install(['fail']);
    await expectLater(
      _session().start(_brief, _vars),
      throwsA(
        isA<CallStartError>().having(
          (e) => e.message,
          'message',
          'The call did not start.',
        ),
      ),
    );
  });

  test('natural call, in real time (17 s): the events in the old check\'s order; the goodbye sends (fin); the call ends after Danny\'s goodbye', () async {
    _install([]);
    final s = _session();
    final ev = <String>[];
    var speaking = 0;
    s.events.listen((e) {
      ev.add(_show(e));
      if (e is Heard && e.text == 'Adiós.') s.send('(fin)');
      if (e is Mode && e.mode == 'speaking') speaking++;
      if (e is Mode && e.mode == 'listening' && speaking == 3) {
        Timer(const Duration(milliseconds: 400), s.end);
      }
    });
    await s.start(_brief, _vars);
    final done = Completer<void>();
    s.events.where((e) => e is Ended).first.then((_) => done.complete());
    await done.future.timeout(const Duration(seconds: 30));
    expect(ev, [
      'Connected',
      'Mode speaking',
      'AgentLine ¡Hola! Soy Danny. ¿Cómo estás?',
      'Mode listening',
      'Heard Hola. Bien, gracias.',
      'Mode speaking',
      'AgentLine Eso. Mira. ¿Quieres jugo?',
      'Tool show_picture {picture: jugo}',
      'Mode listening',
      'Heard Sí, quiero jugo.',
      'Mode listening',
      'Heard Adiós.',
      'Mode speaking',
      'AgentLine Eso. Hasta mañana.',
      'Mode listening',
      'Ended user',
    ]);
    expect(_js("CallStub.sent.join(' ')"), '(fin)');
  }, timeout: const Timeout(Duration(seconds: 60)));

  group(
    'the sound after a call (order 19b), on the web player\'s own context',
    () {
      final script = CallStubScript({
        'lines': {
          for (final k in [
            'danny1',
            'heard1',
            'danny2',
            'heard2',
            'heard3',
            'danny3',
            'finReply',
            'heard3Hasta',
            'loopEven',
            'loopOdd',
          ])
            k: k,
        },
        'picture': {'picture': 'p'},
        'connect': {'conversationId': 'stub'},
        'micError': {'name': 'NotAllowedError', 'message': 'Permission denied'},
        'failError': {'name': 'Error', 'message': 'The call did not start.'},
      });
      // flutter test's Chrome lets no AudioContext run without a tap, so the context's own suspend and
      // resume are watched here (tool/dev_check.mjs sees the real states, with autoplay allowed).
      List<Object?> calls() => _js('window.__acCalls.slice()') as List<Object?>;
      setUpAll(() {
        _js(
          "window.__acCalls=[];for(const k of ['suspend','resume']){const f=AudioContext.prototype[k];"
          "AudioContext.prototype[k]=function(){window.__acCalls.push(k);return Promise.resolve();};}0",
        );
        webSoundCore.ac();
      });
      setUp(() => _js('window.__acCalls.length=0,0'));

      test('suspended at start, resumed at its Ended', () async {
        final stub = CallStub(script, options: {'manual'});
        final s = createCallSession(appInfo: createAppInfo(), stub: stub);
        final f = s.start(_brief, _vars);
        while (stub.opts == null) {
          await _ms(1);
        }
        stub.go('connect');
        await f;
        expect(calls(), ['suspend']);
        stub.go('end'); // Danny ends it
        await _ms(10);
        expect(calls(), ['suspend', 'resume']);
        await s.end();
        expect(calls(), ['suspend', 'resume']); // once
        stub.dispose();
      });
      test('resumed at end()', () async {
        final stub = CallStub(script, options: {'manual'});
        final s = createCallSession(appInfo: createAppInfo(), stub: stub);
        final f = s.start(_brief, _vars);
        while (stub.opts == null) {
          await _ms(1);
        }
        stub.go('connect');
        await f;
        await s.end();
        await _ms(100);
        expect(calls(), ['suspend', 'resume']);
        stub.dispose();
      });
      test('resumed after a failed start (microphone refused)', () async {
        final stub = CallStub(script, options: {'mic'});
        final s = createCallSession(appInfo: createAppInfo(), stub: stub);
        await expectLater(
          s.start(_brief, _vars),
          throwsA(
            isA<CallStartError>().having(
              (e) => e.kind,
              'kind',
              CallStartFailure.microphone,
            ),
          ),
        );
        expect(calls(), ['suspend', 'resume']);
        stub.dispose();
      });
    },
  );

  group('loading the library (precarga)', () {
    void clearLibraryState() {
      globalContext.delete('ELConv'.toJS);
      globalContext.delete('ELConvError'.toJS);
      globalContext.delete('ElevenLabsClient'.toJS);
      globalContext.delete('__capturedOpts'.toJS);
      _js(
        'document.querySelectorAll("script[data-coqui-elconv]").forEach(e=>e.remove()),0',
      );
    }

    ConvOptions dummyOpts() => ConvOptions(
      agentId: 'agent_test',
      connectionType: 'websocket',
      clientTools: const {},
      onConnect: (_) {},
      onDisconnect: (_) {},
      onError: (_) {},
      onMessage: (_) {},
      onModeChange: (_) {},
    );

    setUp(clearLibraryState);
    tearDown(clearLibraryState);

    test('a classic script that gives ElevenLabsClient.Conversation: loaded, available', () async {
      final url =
          'data:text/javascript,${Uri.encodeComponent('window.ElevenLabsClient={Conversation:{startSession(){return Promise.reject(new Error("no"))},v:"local"}};')}';
      final lib = JsConvLibrary(url);
      final s = ConvCallSession(library: lib, callsAllowed: true);
      expect(lib.loaded, isNull);
      expect(s.available, isTrue); // reading it starts the load
      expect(await lib.load(), isTrue);
      expect(_js('window.ELConv.v'), 'local');
      expect(
        _js('document.querySelectorAll("script[data-coqui-elconv]").length'),
        1,
      );
      expect(s.available, isTrue);
      expect(await lib.load(), isTrue); // once there, never loaded again
      expect(
        _js('document.querySelectorAll("script[data-coqui-elconv]").length'),
        1,
      );
    });
    test('without the library: available false after trying, start throws, the next read tries again', () async {
      final lib = JsConvLibrary('http://127.0.0.1:9/nothing-here.js');
      final s = ConvCallSession(library: lib, callsAllowed: true);
      expect(s.available, isTrue);
      expect(await lib.load(), isFalse);
      expect(_js('typeof window.ELConvError'), 'string');
      expect(
        _js('document.querySelectorAll("script[data-coqui-elconv]").length'),
        0,
      );
      expect(s.available, isFalse);
      await expectLater(
        s.start(_brief, _vars),
        throwsA(
          isA<CallStartError>().having((e) => e.name, 'name', 'LibraryError'),
        ),
      );
    });
    test('callsAllowed false: not available, nothing loaded', () {
      final s = createCallSession(
        appInfo: _NoCalls(),
        libraryUrl: 'http://127.0.0.1:9/x.js',
      );
      expect(s.available, isFalse);
    });
    test('package-root library URL passes package-root libsampleratePath to startSession', () async {
      _js(
        'window.ELConv={startSession(o){window.__capturedOpts=o;return Promise.reject(new Error("no"));}};0',
      );
      final lib = JsConvLibrary('assets/assets/elevenlabs/lib.iife.js');
      await expectLater(
        lib.startSession(dummyOpts()),
        throwsA(isA<ConvStartError>()),
      );
      expect(
        _js('window.__capturedOpts.libsampleratePath'),
        'assets/assets/elevenlabs/libsamplerate.worklet.js',
      );
    });
    test('primary asset failure falls back to package-root URL and passes package-root libsampleratePath', () async {
      final fallbackDataUrl =
          'data:text/javascript,${Uri.encodeComponent('window.ElevenLabsClient={Conversation:{startSession(o){window.__capturedOpts=o;return Promise.reject(new Error("no"));}}};')}';
      final lib = JsConvLibrary(
        elevenLabsClientUrl,
        packageRootAssetUrl: fallbackDataUrl,
      );
      expect(await lib.load(), isTrue);
      expect(
        _js(
          'document.querySelectorAll("script[data-coqui-elconv=\\"1\\"][data-coqui-elconv-package-root=\\"1\\"]").length',
        ),
        1,
      );
      expect(
        _js('document.querySelectorAll("script[data-coqui-elconv]").length'),
        1,
      );
      await expectLater(
        lib.startSession(dummyOpts()),
        throwsA(isA<ConvStartError>()),
      );
      expect(
        _js('window.__capturedOpts.libsampleratePath'),
        'assets/assets/elevenlabs/libsamplerate.worklet.js',
      );

      _js('window.__capturedOpts=null;0');
      final secondLib = JsConvLibrary(elevenLabsClientUrl);
      await expectLater(
        secondLib.startSession(dummyOpts()),
        throwsA(isA<ConvStartError>()),
      );
      expect(
        _js('window.__capturedOpts.libsampleratePath'),
        'assets/assets/elevenlabs/libsamplerate.worklet.js',
      );
    });
  });
}

class _NoCalls implements AppInfo {
  @override
  String get build => 'dev';
  @override
  bool get isWeb => true;
  @override
  bool get isIos => false;
  @override
  bool get isAndroid => false;
  @override
  bool get installed => false;
  @override
  bool get callsAllowed => false;
}
