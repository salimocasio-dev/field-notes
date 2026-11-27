@TestOn('vm')
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_platform/coqui_platform.dart';
import 'package:coqui_platform/src/call/call_session.dart';
import 'package:coqui_platform/src/call/conv.dart';
import 'package:flutter_test/flutter_test.dart';

/// What the old stub does in each scenario of llamada_check.py (tool/llamada_stub.mjs, from llamada.js).
final Map<String, dynamic> _traces =
    (jsonDecode(
          File('test/fixtures/llamada_stub_trace.json').readAsStringSync(),
        ) as Map<String, dynamic>)['traces']
        as Map<String, dynamic>;

final _script = CallStubScript(
  jsonDecode(File('assets/call_stub.json').readAsStringSync())
      as Map<String, dynamic>,
);

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

final _goodbye = RegExp(
  r'\badi[oó]s\b|\bhasta ma[nñ]ana\b',
  caseSensitive: false,
);

/// Runs one scenario on the package's stub, as tool/llamada_stub.mjs runs it on the old one: the same
/// options, the same page side (the learner's goodbye sends "(fin)"; the call ends 400 ms after the goodbye
/// line is over, or at the cap), and writes the same log.
Future<List<List<Object?>>> _replay(WidgetTester tester, String name) async {
  final sc = _traces[name] as Map<String, dynamic>;
  final opts = (sc['opts'] as List).cast<String>().toSet();
  final fin =
      name != "Danny's own goodbye" &&
      name != "Danny's own goodbye followed by the loop" &&
      !opts.contains('mic') &&
      !opts.contains('fail');
  final endOnGoodbye = !opts.contains('nofin');
  final stub = CallStub(_script, options: opts);
  final log = <List<Object?>>[];
  var t = 0;
  Conv? conv;
  ({bool seen})? f;
  var ended = false;
  void end(String why) {
    if (ended) return;
    ended = true;
    log.add([t, 'endSession', why]);
    conv?.endSession();
  }

  void on(List<Object?> e) {
    if (e[0] == 'message' &&
        e[1] == 'user' &&
        fin &&
        f == null &&
        _goodbye.hasMatch(e[3]! as String)) {
      f = (seen: false);
      log.add([t, 'sendUserMessage', '(fin)']);
      conv!.sendUserMessage('(fin)');
      if (!endOnGoodbye) {
        Future<void>.delayed(
          const Duration(milliseconds: 15000),
          () => end('cap'),
        );
      }
    }
    if (e[0] == 'message' &&
        e[1] == 'agent' &&
        !fin &&
        f == null &&
        _goodbye.hasMatch(e[3]! as String)) {
      f = (seen: true);
    }
    if (f != null && e[0] == 'mode' && e[1] == 'speaking') f = (seen: true);
    if (f != null &&
        endOnGoodbye &&
        e[0] == 'mode' &&
        e[1] == 'listening' &&
        f!.seen) {
      Future<void>.delayed(const Duration(milliseconds: 400), () => end('fin'));
    }
  }

  void push(List<Object?> e) {
    log.add([t, ...e]);
    on(e);
  }

  stub
      .startSession(
        ConvOptions(
          agentId: _brief.agentId,
          connectionType: 'websocket',
          dynamicVariables: const {},
          clientTools: {
            'show_picture': (p) {
              push(['tool', p]);
              return 'shown';
            },
          },
          onConnect: (d) => push(['connect', d]),
          onDisconnect: (d) => push(['disconnect', (d as Map)['reason']]),
          onError: (e) => push(['error', '$e']),
          onMessage: (m) {
            final x = m! as Map;
            push(['message', x['role'], x['source'], x['message']]);
          },
          onModeChange: (m) => push(['mode', (m! as Map)['mode']]),
        ),
      )
      .then(
        (c) {
          conv = c;
          log.add([t, 'resolved']);
        },
        onError: (Object e) {
          final x = e as ConvStartError;
          log.add([t, 'rejected', x.name, x.message]);
        },
      );
  await tester.pump(); // the promises at 0 settle at 0
  while (t < 60000) {
    t += 10;
    await tester.pump(const Duration(milliseconds: 10));
  }
  stub.dispose();
  return log;
}

/// A ConvLibrary the session tests drive by hand.
class _Lib implements ConvLibrary {
  _Lib({this.loads = true, this.error});
  bool loads;
  ConvStartError? error;
  int tries = 0;
  bool? _loaded;
  ConvOptions? opts;
  _Conv? conv;

  /// startSession waits for this (still calling).
  Completer<void>? gate;

  @override
  bool? get loaded => _loaded;

  @override
  Future<bool> load() async {
    tries++;
    await Future<void>.delayed(Duration.zero);
    return _loaded = loads;
  }

  @override
  Future<Conv> startSession(ConvOptions o) async {
    opts = o;
    await gate?.future;
    final e = error;
    if (e != null) throw e;
    return conv = _Conv();
  }
}

class _Conv implements Conv {
  final List<String> calls = [];
  @override
  void sendUserMessage(String text) => calls.add('send $text');
  @override
  void endSession() => calls.add('end');
  @override
  double getInputVolume() => .25;
  @override
  double getOutputVolume() => throw StateError('gone');
  @override
  void setVolume(double v) => calls.add('volume $v');
}

class _ConvCallSessionRig {
  _ConvCallSessionRig(this.lib) {
    s = ConvCallSession(
      library: lib,
      callsAllowed: true,
      beforeStart: () => calls.add('suspend'),
      afterCall: () => calls.add('resume'),
    );
  }
  final _Lib lib;
  final List<String> calls = [];
  late final ConvCallSession s;
}

ConvCallSession _session(
  _Lib lib, {
  bool allowed = true,
  void Function()? before,
}) => ConvCallSession(library: lib, callsAllowed: allowed, beforeStart: before);

void main() {
  group('the package\'s stub is the old one: the same callbacks at the same times (llamada_check.py\'s scenarios)', () {
    for (final name in _traces.keys) {
      testWidgets(name, (tester) async {
        final want = (_traces[name] as Map)['log'] as List;
        final got = await _replay(tester, name);
        expect(jsonDecode(jsonEncode(got)), want);
      });
    }
    test('its lines are the old stub\'s, from the asset', () {
      expect(_script.line('danny1'), '¡Hola! Soy Danny. ¿Cómo estás?');
      expect(_script.picture, {'picture': 'jugo'});
      expect((_script.json['steps'] as List).length, 17);
    });
  });

  group('the session: what reaches the client', () {
    test('the call was started once, with the agent, websocket, no overrides, no signed URL', () async {
      final lib = _Lib();
      var suspended = 0;
      final s = _session(lib, before: () => suspended++);
      await s.start(_brief, _vars);
      final o = lib.opts!;
      expect(o.agentId, 'agent_3301m795q3xtfpx8c99zc0s870vm');
      expect(o.signedUrl, isNull);
      expect(o.conversationToken, isNull);
      expect(o.connectionType, 'websocket');
      expect(o.clientTools.keys, ['show_picture']);
      expect(suspended, 1); // AC.suspend() before the microphone opens
    });
    test('variables: place, job, words_open, words_heard, minutes 5, opening; the six variables, no more', () async {
      final lib = _Lib();
      await _session(lib).start(_brief, _vars);
      expect(lib.opts!.dynamicVariables, {
        'place': 'La casa',
        'job': 'Say hello, say who you are, accept a drink and say thanks.',
        'words_open': 'hola, casa',
        'words_heard': '',
        'minutes': '5',
        'opening': '¡Hola! Soy Danny. ¿Cómo estás?',
      });
      expect(lib.opts!.dynamicVariables!.keys.toList(), [
        'place',
        'job',
        'words_open',
        'words_heard',
        'minutes',
        'opening',
      ]);
    });
    test('Help sends (ayuda); the goodbye sends (fin); the volume; the levels; end', () async {
      final lib = _Lib();
      final s = _session(lib);
      await s.start(_brief, _vars);
      s.send('(ayuda)');
      s.send('(fin)');
      s.setVolume(.5);
      expect(s.inputVolume(), .25);
      expect(
        s.outputVolume(),
        0,
      ); // a level that throws is 0 (llamada.js: safe)
      await s.end();
      s.send('late');
      expect(lib.conv!.calls, [
        'send (ayuda)',
        'send (fin)',
        'volume 0.5',
        'end',
      ]);
    });
    test('the callbacks as events, in the order they come; show_picture answers "shown"', () async {
      final lib = _Lib();
      final s = _session(lib);
      final ev = <CallEvent>[];
      s.events.listen(ev.add);
      await s.start(_brief, _vars);
      final o = lib.opts!;
      o.onConnect({'conversationId': 'x'});
      o.onModeChange({'mode': 'speaking'});
      o.onMessage({'role': 'agent', 'source': 'ai', 'message': 'Hola.'});
      expect(o.clientTools['show_picture']!({'picture': 'jugo'}), 'shown');
      expect(o.clientTools['show_picture']!('nada'), 'shown');
      o.onModeChange({'mode': 'listening'});
      o.onMessage({
        'source': 'user',
        'message': 'Sí.',
      }); // the old "source" alone
      o.onMessage({
        'role': 'user',
        'message': '(fin)',
      }); // the page's own messages come back: the caller drops them
      o.onMessage({'role': 'agent', 'message': ''}); // no text: nothing
      o.onError('socket closed');
      o.onError({'message': 'x'});
      o.onDisconnect({'reason': 'agent'});
      expect(ev.map(_show), [
        'Connected',
        'Mode speaking',
        'AgentLine Hola.',
        'Tool show_picture {picture: jugo}',
        'Tool show_picture {picture: nada}',
        'Mode listening',
        'Heard Sí.',
        'Heard (fin)',
        'CallError socket closed',
        'CallError x',
        'Ended agent',
      ]);
    });
    test('refused microphone: start throws "NotAllowedError: ..."', () async {
      final lib = _Lib(
        error: const ConvStartError('NotAllowedError', 'Permission denied'),
      );
      expect(
        () => _session(lib).start(_brief, _vars),
        throwsA(
          isA<CallStartError>()
              .having((e) => '$e', 'text', 'NotAllowedError: Permission denied')
              .having((e) => e.kind, 'kind', CallStartFailure.microphone),
        ),
      );
    });
    test('X while calling: the late answer is ended at once', () async {
      final lib = _Lib()..gate = Completer<void>();
      final s = _session(lib);
      final f = s.start(_brief, _vars);
      while (lib.opts == null) {
        await Future<void>.delayed(Duration.zero);
      }
      await s.end(); // still calling
      lib.gate!.complete(); // then it answers
      await f;
      expect(lib.conv!.calls, ['end']);
      s.send('x');
      expect(lib.conv!.calls, ['end']);
    });
    test('X before the library has loaded: no call is asked for', () async {
      final lib = _Lib();
      final s = _session(lib);
      final f = s.start(_brief, _vars);
      await s.end();
      await f;
      expect(lib.opts, isNull);
    });
    test('the call can be opened again', () async {
      final lib = _Lib();
      final s = _session(lib);
      await s.start(_brief, _vars);
      final first = lib.conv!;
      await s.end();
      await s.start(_brief, _vars);
      s.send('again');
      expect(first.calls, ['end']);
      expect(lib.conv!.calls, ['send again']);
    });
  });

  group('a failed start: llamada.js\'s three lines as the contract\'s kinds (order 19b)', () {
    for (final (name, message, kind) in [
      ('NotAllowedError', 'Permission denied', CallStartFailure.microphone),
      (
        'NotFoundError',
        'Requested device not found',
        CallStartFailure.microphone,
      ),
      ('Error', 'Permission dismissed', CallStartFailure.microphone),
      ('Error', 'The call did not start.', CallStartFailure.failed),
      ('SessionConnectionError', 'socket closed', CallStartFailure.failed),
    ]) {
      test('"$name: $message" is $kind', () async {
        final lib = _Lib(error: ConvStartError(name, message));
        await expectLater(
          _session(lib).start(_brief, _vars),
          throwsA(
            isA<CallStartError>()
                .having((e) => e.kind, 'kind', kind)
                .having((e) => '$e', 'text', '$name: $message'),
          ),
        );
      });
    }
  });

  group('the sound after a call (order 19b): suspended at start, back when it is over', () {
    _ConvCallSessionRig rig({bool loads = true, ConvStartError? error}) =>
        _ConvCallSessionRig(_Lib(loads: loads, error: error));
    test('Ended gives it back, once', () async {
      final r = rig();
      await r.s.start(_brief, _vars);
      expect(r.calls, ['suspend']);
      r.lib.opts!.onDisconnect({'reason': 'agent'});
      await r.s.end();
      expect(r.calls, ['suspend', 'resume']);
    });
    test(
      'end() gives it back (and the Ended after it does not again)',
      () async {
        final r = rig();
        await r.s.start(_brief, _vars);
        await r.s.end();
        r.lib.opts!.onDisconnect({'reason': 'user'});
        expect(r.calls, ['suspend', 'resume']);
      },
    );
    test(
      'a failed start gives it back: the library, the microphone, the call',
      () async {
        for (final r in [
          rig(loads: false),
          rig(error: const ConvStartError('NotAllowedError', 'x')),
          rig(error: const ConvStartError('Error', 'y')),
        ]) {
          await expectLater(
            r.s.start(_brief, _vars),
            throwsA(isA<CallStartError>()),
          );
          expect(r.calls, ['suspend', 'resume']);
        }
      },
    );
    test('X while calling gives it back at once', () async {
      final r = rig();
      r.lib.gate = Completer<void>();
      final f = r.s.start(_brief, _vars);
      while (r.lib.opts == null) {
        await Future<void>.delayed(Duration.zero);
      }
      await r.s.end();
      expect(r.calls, ['suspend', 'resume']);
      r.lib.gate!.complete();
      await f;
      expect(r.calls, ['suspend', 'resume']);
    });
    test('no calls here: nothing suspended, nothing to give back', () async {
      final calls = <String>[];
      final s = ConvCallSession(
        library: null,
        callsAllowed: false,
        beforeStart: () => calls.add('suspend'),
        afterCall: () => calls.add('resume'),
      );
      await expectLater(s.start(_brief, _vars), throwsA(isA<CallStartError>()));
      await s.end();
      expect(calls, isEmpty);
    });
  });

  group('available', () {
    test('without the library: false after trying, and start throws', () async {
      final lib = _Lib(loads: false);
      final s = _session(lib);
      expect(
        s.available,
        isTrue,
      ); // not tried yet: reading it starts the load (precarga)
      await Future<void>.delayed(Duration.zero);
      expect(lib.tries, 1);
      expect(s.available, isFalse);
      await expectLater(
        s.start(_brief, _vars),
        throwsA(
          isA<CallStartError>().having(
            (e) => e.kind,
            'kind',
            CallStartFailure.library,
          ),
        ),
      );
      lib.loads = true; // a failed load is tried again
      expect(s.available, isFalse);
      await Future<void>.delayed(Duration.zero);
      expect(s.available, isTrue);
    });
    test(
      'callsAllowed false: false, and start throws without loading',
      () async {
        final lib = _Lib();
        final s = _session(lib, allowed: false);
        expect(s.available, isFalse);
        await expectLater(
          s.start(_brief, _vars),
          throwsA(
            isA<CallStartError>().having(
              (e) => e.kind,
              'kind',
              CallStartFailure.unavailable,
            ),
          ),
        );
        expect(lib.tries, 0);
      },
    );
    test('a phone build: false, and start throws', () async {
      final s = createCallSession(appInfo: createAppInfo());
      expect(s.available, isFalse);
      await expectLater(
        s.start(_brief, _vars),
        throwsA(
          isA<CallStartError>()
              .having((e) => e.name, 'name', 'NotAvailable')
              .having((e) => e.kind, 'kind', CallStartFailure.unavailable),
        ),
      );
    });
  });

  group('the stub through the session (the shell\'s ?callstub)', () {
    testWidgets('natural call: the events the call screen gets, in order', (
      tester,
    ) async {
      final stub = CallStub(_script);
      final s = ConvCallSession(library: stub, callsAllowed: true);
      final ev = <String>[];
      s.events.listen((e) {
        ev.add(_show(e));
        if (e is Heard && e.text == 'Adiós.') s.send('(fin)');
        if (e is Mode &&
            e.mode == 'listening' &&
            stub.sent.contains('(fin)') &&
            ev.where((x) => x == 'Mode speaking').length == 3) {
          s.end();
        }
      });
      var started = false;
      s.start(_brief, _vars).then((_) => started = true);
      await tester.pump();
      expect(started, isTrue);
      for (var i = 0; i < 3000; i++) {
        await tester.pump(const Duration(milliseconds: 10));
      }
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
      expect(stub.sent, ['(fin)']);
      expect(stub.ended, isTrue);
      expect(stub.opts!.dynamicVariables!['place'], 'La casa');
      stub.dispose();
    });
    testWidgets('refused microphone and failed start throw', (tester) async {
      for (final (o, name) in [('mic', 'NotAllowedError'), ('fail', 'Error')]) {
        final s = ConvCallSession(
          library: CallStub(_script, options: {o}),
          callsAllowed: true,
        );
        Object? err;
        s.start(_brief, _vars).catchError((Object e) => err = e);
        await tester.pump(const Duration(milliseconds: 700));
        expect(err, isA<CallStartError>().having((e) => e.name, 'name', name));
      }
    });
    testWidgets('manual: nothing moves until go; Danny ends the call', (
      tester,
    ) async {
      final stub = CallStub(_script, options: {'manual'});
      final s = ConvCallSession(library: stub, callsAllowed: true);
      final ev = <String>[];
      s.events.listen((e) => ev.add(_show(e)));
      s.start(_brief, _vars);
      await tester.pump(const Duration(seconds: 5));
      expect(ev, isEmpty);
      stub.go('connect');
      stub.go('danny1');
      stub.go('end');
      stub.go('danny2'); // after the end only connect runs
      await tester.pump();
      expect(ev, [
        'Connected',
        'Mode speaking',
        'AgentLine ¡Hola! Soy Danny. ¿Cómo estás?',
        'Ended agent',
      ]);
      stub.dispose();
    });
  });

  group('agentId from CallBrief (N2.5)', () {
    test('Spanish fallback CallBrief passes Language.spanish.callAgentId to ConvOptions.agentId via _Lib and CallStub', () async {
      final brief = CallBrief(
        placeId: 'casa',
        minutes: 5,
        job: 'job',
        opening: 'opening',
        photo: 'casa',
      );
      expect(brief.agentId, spanishCallAgentId);
      expect(brief.agentId, Language.spanish.callAgentId);

      final lib = _Lib();
      await _session(lib).start(brief, _vars);
      expect(lib.opts!.agentId, Language.spanish.callAgentId);

      final stub = CallStub(_script, options: {'manual'});
      final s = ConvCallSession(library: stub, callsAllowed: true);
      final started = s.start(brief, _vars);
      while (stub.opts == null) {
        await Future<void>.delayed(Duration.zero);
      }
      expect(stub.opts!.agentId, Language.spanish.callAgentId);
      stub.go('connect');
      await started;
      await s.end();
      stub.dispose();
    });

    test('custom non-Spanish Language passes its callAgentId via CallBrief into ConvOptions.agentId via _Lib and CallStub', () async {
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
      final brief = CallBrief(
        placeId: 'casa',
        minutes: 5,
        job: 'job',
        opening: 'أهلاً',
        photo: 'casa',
        agentId: arabic.callAgentId,
      );

      final lib = _Lib();
      await _session(lib).start(brief, _vars);
      expect(lib.opts!.agentId, 'agent_test_arabic_001');

      final stub = CallStub(_script, options: {'manual'});
      final s = ConvCallSession(library: stub, callsAllowed: true);
      final started = s.start(brief, _vars);
      while (stub.opts == null) {
        await Future<void>.delayed(Duration.zero);
      }
      expect(stub.opts!.agentId, 'agent_test_arabic_001');
      stub.go('connect');
      await started;
      await s.end();
      stub.dispose();
    });
  });

  group('vendored @elevenlabs/client bundle (S8)', () {
    test(
      'elevenLabsClientUrl points to the bundled local asset, not jsdelivr',
      () {
        expect(
          elevenLabsClientUrl,
          'assets/packages/coqui_platform/assets/elevenlabs/lib.iife.js',
        );
        expect(elevenLabsClientUrl, isNot(startsWith('http://')));
        expect(elevenLabsClientUrl, isNot(startsWith('https://')));
        expect(elevenLabsClientUrl, isNot(contains('jsdelivr')));
      },
    );

    test(
      'bundled @elevenlabs/client@1.25.0 IIFE and MIT LICENSE files exist',
      () {
        final jsFile = File('assets/elevenlabs/lib.iife.js');
        expect(jsFile.existsSync(), isTrue);
        final js = jsFile.readAsStringSync();
        expect(js.length, greaterThan(100000));
        expect(js, contains('var ElevenLabsClient'));
        expect(js, contains('Conversation'));

        final licenseFile = File('assets/elevenlabs/LICENSE');
        expect(licenseFile.existsSync(), isTrue);
        final license = licenseFile.readAsStringSync();
        expect(license, contains('MIT License'));
        expect(license, contains('ElevenLabs'));
      },
    );
  });

  group('signed link / token source (#249)', () {
    test('CallToken.signedUrl passes signedUrl, websocket, clientTools without agentId or dynamicVariables, forwards wordsOpen/wordsHeard, and runs events/send/end', () async {
      final lib = _Lib();
      const signedUrl = 'wss://call-api.example.com/v1/call/ws?ticket=abc123';
      final token = CallToken.signedUrl(
        signedUrl,
        expiresAt: DateTime.utc(2026, 11, 26, 18, 1),
        maxDurationSeconds: 420,
        dailyLimit: 3,
        remainingToday: 2,
      );
      expect(token.signedUrl, signedUrl);
      expect(token.conversationToken, isNull);
      expect(token.connectionType, 'websocket');
      expect(token.expiresAt, DateTime.utc(2026, 11, 26, 18, 1));
      expect(token.maxDurationSeconds, 420);
      expect(token.dailyLimit, 3);
      expect(token.remainingToday, 2);

      final source = _FakeTokenSource(token: token);
      final calls = <String>[];
      final s = ConvCallSession(
        library: lib,
        callsAllowed: true,
        beforeStart: () => calls.add('suspend'),
        afterCall: () => calls.add('resume'),
        tokenSource: source,
      );
      final ev = <String>[];
      s.events.listen((e) => ev.add(_show(e)));

      // First start: empty words_heard
      await s.start(_brief, _vars);
      expect(source.calls, 1);
      expect(source.lastBrief, _brief);
      expect(source.lastWordsOpen, ['hola', 'casa']);
      expect(source.lastWordsHeard, isEmpty);

      final o = lib.opts!;
      expect(o.signedUrl, signedUrl);
      expect(o.conversationToken, isNull);
      expect(o.agentId, isNull);
      expect(o.dynamicVariables, isNull);
      expect(o.connectionType, 'websocket');
      expect(o.clientTools.keys, ['show_picture']);

      o.onConnect({'conversationId': 'conv_1'});
      o.onMessage({'role': 'agent', 'message': '¡Hola!'});
      expect(o.clientTools['show_picture']!({'picture': 'jugo'}), 'shown');
      s.send('(ayuda)');
      await s.end();
      expect(ev, [
        'Connected',
        'AgentLine ¡Hola!',
        'Tool show_picture {picture: jugo}',
      ]);
      expect(lib.conv!.calls, ['send (ayuda)', 'end']);
      expect(calls, ['suspend', 'resume']);

      // Second start: non-empty words_heard with extra whitespace/empty segments
      await s.start(_brief, {
        'place': 'La casa',
        'words_open': ' hola ,  puerta , ',
        'words_heard': ' agua , jugo ',
      });
      expect(source.calls, 2);
      expect(source.lastWordsOpen, ['hola', 'puerta']);
      expect(source.lastWordsHeard, ['agua', 'jugo']);
      await s.end();
    });

    test('CallToken.conversationToken passes conversationToken and webrtc without agentId, signedUrl, or dynamicVariables', () async {
      final lib = _Lib();
      final source = _FakeTokenSource(
        token: CallToken.conversationToken('conv_tok_xyz'),
      );
      final s = ConvCallSession(
        library: lib,
        callsAllowed: true,
        tokenSource: source,
      );
      await s.start(_brief, _vars);
      final o = lib.opts!;
      expect(o.conversationToken, 'conv_tok_xyz');
      expect(o.connectionType, 'webrtc');
      expect(o.agentId, isNull);
      expect(o.signedUrl, isNull);
      expect(o.dynamicVariables, isNull);
      expect(o.clientTools.keys, ['show_picture']);
    });

    test('tokenSource.fetchToken throwing CallStartError rethrows intact, resumes once, and does not startSession', () async {
      final lib = _Lib();
      const err = CallStartError(
        CallStartFailure.failed,
        'Daily call limit reached.',
        name: 'DailyLimitReached',
      );
      final source = _FakeTokenSource(error: err);
      final calls = <String>[];
      final s = ConvCallSession(
        library: lib,
        callsAllowed: true,
        beforeStart: () => calls.add('suspend'),
        afterCall: () => calls.add('resume'),
        tokenSource: source,
      );
      await expectLater(s.start(_brief, _vars), throwsA(same(err)));
      expect(calls, ['suspend', 'resume']);
      expect(lib.opts, isNull);
    });

    test('tokenSource.fetchToken throwing arbitrary exception wraps in CallStartFailure.failed, resumes once, and does not startSession', () async {
      final lib = _Lib();
      final source = _FakeTokenSource(error: StateError('network down'));
      final calls = <String>[];
      final s = ConvCallSession(
        library: lib,
        callsAllowed: true,
        beforeStart: () => calls.add('suspend'),
        afterCall: () => calls.add('resume'),
        tokenSource: source,
      );
      await expectLater(
        s.start(_brief, _vars),
        throwsA(
          isA<CallStartError>()
              .having((e) => e.kind, 'kind', CallStartFailure.failed)
              .having((e) => e.message, 'message', contains('network down')),
        ),
      );
      expect(calls, ['suspend', 'resume']);
      expect(lib.opts, isNull);
    });

    test('library.load() returning false skips tokenSource.fetchToken, throws library, and resumes once', () async {
      final lib = _Lib(loads: false);
      final source = _FakeTokenSource(
        token: CallToken.signedUrl('wss://call-api.example.com/v1/call/ws?t=1'),
      );
      final calls = <String>[];
      final s = ConvCallSession(
        library: lib,
        callsAllowed: true,
        beforeStart: () => calls.add('suspend'),
        afterCall: () => calls.add('resume'),
        tokenSource: source,
      );
      await expectLater(
        s.start(_brief, _vars),
        throwsA(
          isA<CallStartError>().having(
            (e) => e.kind,
            'kind',
            CallStartFailure.library,
          ),
        ),
      );
      expect(source.calls, 0);
      expect(calls, ['suspend', 'resume']);
      expect(lib.opts, isNull);
    });

    test('end() while tokenSource.fetchToken is pending resumes once and does not call startSession when token resolves', () async {
      final lib = _Lib();
      final gate = Completer<void>();
      final source = _FakeTokenSource(
        token: CallToken.signedUrl('wss://call-api.example.com/v1/call/ws?t=2'),
        gate: gate,
      );
      final calls = <String>[];
      final s = ConvCallSession(
        library: lib,
        callsAllowed: true,
        beforeStart: () => calls.add('suspend'),
        afterCall: () => calls.add('resume'),
        tokenSource: source,
      );
      final startFuture = s.start(_brief, _vars);
      while (source.calls == 0) {
        await Future<void>.delayed(Duration.zero);
      }
      await s.end();
      expect(calls, ['suspend', 'resume']);
      gate.complete();
      await startFuture;
      expect(lib.opts, isNull);
      expect(calls, ['suspend', 'resume']);
    });

    test(
      'CallToken constructor enforces credential and connectionType invariants',
      () {
        expect(() => CallToken(), throwsArgumentError);
        expect(
          () => CallToken(
            signedUrl: 'wss://example.com/ws',
            conversationToken: 'tok_1',
          ),
          throwsArgumentError,
        );
        expect(() => CallToken.signedUrl(''), throwsArgumentError);
        expect(() => CallToken.signedUrl('   '), throwsArgumentError);
        expect(() => CallToken.conversationToken(''), throwsArgumentError);
        expect(() => CallToken.conversationToken('   '), throwsArgumentError);
        expect(
          () => CallToken.signedUrl(
            'wss://example.com/ws',
            connectionType: 'webrtc',
          ),
          throwsArgumentError,
        );
        expect(
          () => CallToken.signedUrl('wss://example.com/ws', connectionType: ''),
          throwsArgumentError,
        );
        expect(
          () => CallToken.conversationToken('tok_1', connectionType: '  '),
          throwsArgumentError,
        );
      },
    );

    test('ConvOptions constructor enforces credential, dynamicVariables, and connectionType invariants', () {
      ConvOptions make({
        String? agentId,
        String? signedUrl,
        String? conversationToken,
        String connectionType = 'websocket',
        Map<String, String>? dynamicVariables,
      }) => ConvOptions(
        agentId: agentId,
        signedUrl: signedUrl,
        conversationToken: conversationToken,
        connectionType: connectionType,
        dynamicVariables: dynamicVariables,
        clientTools: const {},
        onConnect: (_) {},
        onDisconnect: (_) {},
        onError: (_) {},
        onMessage: (_) {},
        onModeChange: (_) {},
      );

      // Neither credential
      expect(() => make(), throwsArgumentError);
      // Multiple credentials
      expect(
        () => make(agentId: 'agent_1', signedUrl: 'wss://example.com/ws'),
        throwsArgumentError,
      );
      expect(
        () => make(agentId: 'agent_1', conversationToken: 'tok_1'),
        throwsArgumentError,
      );
      expect(
        () =>
            make(signedUrl: 'wss://example.com/ws', conversationToken: 'tok_1'),
        throwsArgumentError,
      );
      // Blank credentials / connectionType
      expect(() => make(agentId: ''), throwsArgumentError);
      expect(() => make(agentId: '   '), throwsArgumentError);
      expect(() => make(signedUrl: '  '), throwsArgumentError);
      expect(() => make(conversationToken: ''), throwsArgumentError);
      expect(
        () => make(agentId: 'agent_1', connectionType: ''),
        throwsArgumentError,
      );
      expect(
        () => make(agentId: 'agent_1', connectionType: '   '),
        throwsArgumentError,
      );
      // signedUrl must be websocket
      expect(
        () => make(signedUrl: 'wss://example.com/ws', connectionType: 'webrtc'),
        throwsArgumentError,
      );
      // dynamicVariables forbidden with signedUrl or conversationToken
      expect(
        () => make(
          signedUrl: 'wss://example.com/ws',
          dynamicVariables: const {'place': 'La casa'},
        ),
        throwsArgumentError,
      );
      expect(
        () => make(
          conversationToken: 'tok_1',
          connectionType: 'webrtc',
          dynamicVariables: const {},
        ),
        throwsArgumentError,
      );
    });

    test('phone build createCallSession with tokenSource still throws unavailable without calling tokenSource', () async {
      final source = _FakeTokenSource(
        token: CallToken.signedUrl('wss://call-api.example.com/v1/call/ws?t=3'),
      );
      final s = createCallSession(
        appInfo: createAppInfo(),
        tokenSource: source,
      );
      expect(s.available, isFalse);
      await expectLater(
        s.start(_brief, _vars),
        throwsA(
          isA<CallStartError>()
              .having((e) => e.name, 'name', 'NotAvailable')
              .having((e) => e.kind, 'kind', CallStartFailure.unavailable),
        ),
      );
      expect(source.calls, 0);
    });
  });
}

class _FakeTokenSource implements CallTokenSource {
  _FakeTokenSource({this.token, this.error, this.gate});

  final CallToken? token;
  final Object? error;
  final Completer<void>? gate;
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
    await gate?.future;
    final e = error;
    if (e != null) throw e;
    return token!;
  }
}

String _show(CallEvent e) => switch (e) {
  Connected() => 'Connected',
  AgentLine(:final text) => 'AgentLine $text',
  Heard(:final text) => 'Heard $text',
  Mode(:final mode) => 'Mode $mode',
  Tool(:final name, :final args) => 'Tool $name $args',
  CallError(:final message) => 'CallError $message',
  Ended(:final reason) => 'Ended $reason',
};
