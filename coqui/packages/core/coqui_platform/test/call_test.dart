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
          agentId: dannyAgentId,
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
      expect(lib.opts!.dynamicVariables.keys.toList(), [
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
          isA<CallStartException>().having(
            (e) => '$e',
            'text',
            'NotAllowedError: Permission denied',
          ),
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
          isA<CallStartException>().having(
            (e) => e.name,
            'name',
            'LibraryError',
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
          throwsA(isA<CallStartException>()),
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
          isA<CallStartException>().having(
            (e) => e.name,
            'name',
            'NotAvailable',
          ),
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
      expect(stub.opts!.dynamicVariables['place'], 'La casa');
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
        expect(
          err,
          isA<CallStartException>().having((e) => e.name, 'name', name),
        );
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
