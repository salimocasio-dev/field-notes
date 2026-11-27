// The voice test: the rule for "heard right", its states, its count and result,
// what it keeps, and its Noche screen.
import 'dart:convert';

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_testing/coqui_testing.dart';
import 'package:coqui_ui/coqui_ui.dart';
import 'package:feature_speaking/src/voice_test_controller.dart';
import 'package:feature_speaking/src/voice_test_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/voice_fixture.dart';
import 'support/world.dart';

VoiceLine line(int i) => voiceFixture.lines[i];

Future<VoiceTestController> started(
  WidgetTester tester,
  SpeechListener speech, {
  FakeKeyValueStore? store,
}) async {
  final c = VoiceTestController(
    speech: speech,
    clock: FakeClock(),
    content: voiceFixture,
    store: store,
  );
  await c.start();
  return c;
}

/// One attempt: the mic, then the fake recogniser's own time.
Future<void> say(WidgetTester tester, VoiceTestController c) async {
  final f = c.onMic();
  await tester.pump(const Duration(milliseconds: 700));
  await f;
}

void main() {
  group('the rule for "heard right" (docs/hablar/01-decisiones.md)', () {
    test('every target needs one accepted form inside some alternative, on word boundaries', () {
      final hola = line(0); // Hola, abuela
      expect(voiceHeard(hola, ['hola abuela']), isTrue);
      expect(voiceHeard(hola, ['Hola, Abuela!']), isTrue);
      expect(voiceHeard(hola, ['hola']), isFalse);
      // the two targets may come from two alternatives
      expect(voiceHeard(hola, ['hola', 'abuela']), isTrue);
      expect(voiceHeard(hola, ['holaabuela']), isFalse);
    });

    test(
      'accents and capitals are ignored; a word inside another is not heard',
      () {
        final si = line(1);
        expect(voiceHeard(si, ['sí']), isTrue);
        expect(voiceHeard(si, ['Si']), isTrue);
        expect(voiceHeard(si, ['sin']), isFalse);
        expect(voiceHeard(si, []), isFalse);
        expect(
          voiceHeard(line(4), ['adiós']),
          isTrue,
        ); // Adiós: accepted form "adios"
        expect(voiceHeard(line(10), ['¿Cómo estás?']), isTrue);
      },
    );

    test('digits count for the numbers; a name is never a target', () {
      final numeros = line(11);
      expect(voiceHeard(numeros, ['uno dos tres']), isTrue);
      expect(voiceHeard(numeros, ['1 2 3']), isTrue);
      expect(voiceHeard(numeros, ['uno dos']), isFalse);
      expect(voiceHeard(line(9), ['me llamo Ana']), isTrue);
      expect(voiceHeard(line(9), ['me llamo']), isTrue);
    });
  });

  group('the run', () {
    testWidgets(
      'load > ready; one attempt: ready > listen > proc > done, with its recogniser asked as the old page asked',
      (tester) async {
        final speech = FakeSpeechListener(results: ['hola abuela']);
        final c = VoiceTestController(
          speech: speech,
          clock: FakeClock(),
          content: voiceFixture,
        );
        final seq = <VoiceTestState>[c.state];
        c.addListener(() {
          if (seq.last != c.state) seq.add(c.state);
        });
        await c.start();
        expect(c.state, VoiceTestState.ready);
        expect(c.status, '');
        final f = c.onMic();
        expect(c.state, VoiceTestState.listen);
        expect(c.status, 'Escuchando…');
        await tester.pump(const Duration(milliseconds: 350));
        expect(c.state, VoiceTestState.proc);
        expect(c.status, 'Un momento…');
        await tester.pump(const Duration(milliseconds: 100));
        await f;
        expect(c.state, VoiceTestState.done);
        expect(seq, [
          VoiceTestState.load,
          VoiceTestState.ready,
          VoiceTestState.listen,
          VoiceTestState.proc,
          VoiceTestState.done,
        ]);
        expect(c.current.ok, isTrue);
        expect(c.current.alts, ['hola abuela']);
        expect(c.current.ms, 120);
        expect(speech.listens.single.locale, 'es-US');
        expect(speech.listens.single.limit, const Duration(milliseconds: 6000));
        expect(speech.listens.single.maxAlternatives, 5);
      },
    );

    testWidgets(
      'the mic does nothing unless the line is ready; the next arrow does nothing unless it is done',
      (tester) async {
        final speech = FakeSpeechListener(results: ['hola abuela']);
        final c = await started(tester, speech);
        c.onNext();
        expect(c.i, 0);
        final f = c.onMic();
        c.onMic(); // a second touch while it listens
        await tester.pump(const Duration(milliseconds: 700));
        await f;
        expect(speech.used, 1);
        c.onMic(); // done, not ready
        expect(speech.used, 1);
        c.onNext();
        expect(c.i, 1);
        expect(c.state, VoiceTestState.ready);
      },
    );

    testWidgets(
      'twelve lines with the reference pictures\' own results: 10 of 12, and the result line says so',
      (tester) async {
        final store = FakeKeyValueStore();
        final c = await started(
          tester,
          FakeSpeechListener.stub(voiceStubOfPictures),
          store: store,
        );
        for (var k = 0; k < 12; k++) {
          expect(c.i, k);
          await say(tester, c);
          expect(c.state, VoiceTestState.done);
          c.onNext();
        }
        expect(c.state, VoiceTestState.end);
        expect(c.right, 10);
        expect(c.result, 'Heard right: 10 of 12');
        // line 2 heard nothing, line 6 "la caza" is a miss, the rest are right
        expect(
          [for (final e in c.runLines) e.ok],
          [
            true,
            false,
            true,
            true,
            true,
            false,
            true,
            true,
            true,
            true,
            true,
            true,
          ],
        );
        expect(c.runLines[1].err, 'no-speech');
        expect(c.runLines[1].alts, isEmpty);
        expect(c.runLines[2].alts, ['no', 'nó']);
        expect(c.runLines[5].alts, ['la caza']);
        expect(c.unavailable, isEmpty);
        expect(c.runDone, isTrue);
      },
    );

    testWidgets(
      'what is kept: the run, as the old page kept it, under the test\'s own space',
      (tester) async {
        final store = FakeKeyValueStore();
        final c = await started(
          tester,
          FakeSpeechListener.stub('hola abuela|none'),
          store: store,
        );
        expect(store.values, isEmpty);
        await say(tester, c);
        c.onNext();
        await say(tester, c);
        final run =
            jsonDecode(store.values[voiceTestRunKey]!) as Map<String, dynamic>;
        expect(
          run.keys,
          containsAll([
            'v',
            't',
            'lang',
            'src',
            'ua',
            'n',
            'right',
            'done',
            'unavailable',
            'lines',
          ]),
        );
        expect(run['v'], 1);
        expect(run['lang'], 'es-US');
        expect(run['n'], 12);
        expect(run['right'], 1);
        expect(run['done'], isFalse);
        expect(run['t'], '2026-11-19T15:00:00.000Z');
        final lines = (run['lines'] as List).cast<Map<String, dynamic>>();
        expect(lines.length, 12);
        expect(lines[0], {
          'i': 1,
          'line': 'Hola, abuela',
          'tried': true,
          'ok': true,
          'alts': ['hola abuela'],
          'conf': <Object?>[],
          'ms': 120,
          'err': '',
        });
        expect(lines[1]['tried'], isTrue);
        expect(lines[1]['ok'], isFalse);
        expect(lines[1]['err'], 'no-speech');
        expect(lines[2]['tried'], isFalse);
        expect(voiceTestSpace, 'hablaprueba');
      },
    );

    testWidgets(
      'an error that says speaking cannot work stops the test there: the line is tried and a miss, the note is on',
      (tester) async {
        for (final code in voiceTestUnavailable) {
          final store = FakeKeyValueStore();
          final c = await started(
            tester,
            FakeSpeechListener(results: ['error:$code']),
            store: store,
          );
          await say(tester, c);
          expect(c.state, VoiceTestState.end, reason: code);
          expect(c.unavailable, code);
          expect(c.runLines[0].tried, isTrue);
          expect(c.runLines[0].ok, isFalse);
          expect(c.result, 'Heard right: 0 of 12');
          final run = jsonDecode(
            store.values[voiceTestRunKey]!,
          ) as Map<String, dynamic>;
          expect(run['done'], isTrue);
          expect(run['unavailable'], code);
        }
      },
    );

    testWidgets('any other error is only a miss: the test goes on', (
      tester,
    ) async {
      final c = await started(
        tester,
        FakeSpeechListener(results: ['error:aborted']),
      );
      await say(tester, c);
      expect(c.state, VoiceTestState.done);
      expect(c.current.ok, isFalse);
      expect(c.current.err, 'aborted');
      c.onNext();
      expect(c.i, 1);
    });

    testWidgets(
      'no recogniser, no network or the microphone denied: the end screen at once, nothing tried, nothing kept',
      (tester) async {
        final store = FakeKeyValueStore({
          voiceTestRunKey: '{"an":"earlier run"}',
        });
        final c = await started(
          tester,
          FakeSpeechListener(isAvailable: false),
          store: store,
        );
        expect(c.state, VoiceTestState.end);
        expect(c.unavailable, isNotEmpty);
        expect(c.result, 'Heard right: 0 of 12');
        expect(c.tried, 0);
        expect(
          store.values[voiceTestRunKey],
          '{"an":"earlier run"}',
          reason: 'an earlier saved run stays as it was',
        );
      },
    );

    testWidgets('Otra vez: a new run from line 1', (tester) async {
      final c = await started(
        tester,
        FakeSpeechListener.stub('hola abuela|none|no'),
      );
      for (var k = 0; k < 3; k++) {
        await say(tester, c);
        c.onNext();
      }
      expect(c.i, 3);
      expect(c.tried, 3);
      await c.start();
      expect(c.i, 0);
      expect(c.tried, 0);
      expect(c.state, VoiceTestState.ready);
      expect(c.right, 0);
    });

    testWidgets(
      'a recogniser that cannot start counts as the microphone refused',
      (tester) async {
        final c = await started(tester, _Refusing());
        final f = c.onMic();
        await tester.pump();
        await f;
        expect(c.state, VoiceTestState.end);
        expect(c.unavailable, 'not-allowed');
      },
    );
  });

  group('the screen', () {
    Future<World> pump(
      WidgetTester tester, {
      String stub = voiceStubOfPictures,
      bool off = false,
      Phone phone = Phone.android,
    }) async {
      phone.use(tester);
      final w = await World.create(
        seed: null,
        speech: off
            ? FakeSpeechListener(isAvailable: false)
            : FakeSpeechListener.stub(stub),
        reduceMotion: true,
      );
      await tester.pumpWidget(
        w.app(VoiceTestScreen(services: w.services, content: voiceFixture)),
      );
      await tester.pump();
      await tester.pump();
      return w;
    }

    Future<void> tapMic(WidgetTester tester, World w, {int ms = 700}) async {
      await tester.tap(find.byKey(const Key('voice-test-mic')));
      await w.elapse(tester, ms);
    }

    testWidgets(
      'line 1, before the mic: Noche lessonGround, instruction, 1 / 12, line, NocheMic ready, NocheDashes, no state label',
      (tester) async {
        final w = await pump(tester);
        expect(find.byKey(const Key('voice-test-screen')), findsOneWidget);
        expect(
          tester
              .widget<ColoredBox>(find.byKey(const Key('voice-test-screen')))
              .color,
          NocheColors.lessonGround,
        );
        expect(
          find.text('Tap the mic and say each Spanish line.'),
          findsOneWidget,
        );
        expect(find.text('1 / 12'), findsOneWidget);
        expect(find.text('Hola, abuela'), findsOneWidget);
        expect(find.text('Escuchando…'), findsNothing);
        expect(find.text('Un momento…'), findsNothing);
        expect(find.text('Sí'), findsNothing);
        expect(
          tester
              .widget<NocheMic>(find.byKey(const Key('voice-test-mic')))
              .state,
          NocheMicState.ready,
        );
        expect(find.byType(NocheDashes), findsOneWidget);
        await w.close(tester);
      },
    );

    testWidgets(
      'listening uses NocheMic listening + Escuchando…, thinking uses NocheMic thinking + Un momento…, then NocheMic right + heard in NocheColors.right',
      (tester) async {
        final w = await pump(tester);
        await tester.tap(find.byKey(const Key('voice-test-mic')));
        await w.elapse(tester, 100);
        expect(find.text('Escuchando…'), findsOneWidget);
        expect(
          tester
              .widget<NocheMic>(find.byKey(const Key('voice-test-mic')))
              .state,
          NocheMicState.listening,
        );
        await w.elapse(tester, 250);
        expect(find.text('Un momento…'), findsOneWidget);
        expect(
          tester
              .widget<NocheMic>(find.byKey(const Key('voice-test-mic')))
              .state,
          NocheMicState.thinking,
        );
        await w.elapse(tester, 200);
        expect(find.text('Un momento…'), findsNothing);
        expect(
          tester
              .widget<NocheMic>(find.byKey(const Key('voice-test-mic')))
              .state,
          NocheMicState.right,
        );
        final heard = find.text('hola abuela');
        expect(heard, findsOneWidget);
        expect(tester.widget<Text>(heard).style!.color, NocheColors.right);
        await w.close(tester);
      },
    );

    testWidgets(
      'nothing heard: em dash, NocheMic notYet (calm, no red), NocheDashes progress, and primary Next button',
      (tester) async {
        final w = await pump(tester);
        await tapMic(tester, w);
        await tester.tap(find.byKey(const Key('voice-test-next')));
        await w.elapse(tester, 100);
        expect(find.text('2 / 12'), findsOneWidget);
        final dashes = tester.widget<NocheDashes>(find.byType(NocheDashes));
        expect(dashes.states[0], NocheDashState.done);
        expect(dashes.states[1], NocheDashState.current);
        await tapMic(tester, w, ms: 900);
        expect(find.text('—'), findsOneWidget);
        expect(
          tester
              .widget<NocheMic>(find.byKey(const Key('voice-test-mic')))
              .state,
          NocheMicState.notYet,
        );
        await w.close(tester);
      },
    );

    testWidgets('a line with a hint shows it under the line', (tester) async {
      final w = await pump(tester, stub: 'x|x|x|x|x|x|x|x|x');
      for (var k = 0; k < 9; k++) {
        await tapMic(tester, w, ms: 900);
        await tester.tap(find.byKey(const Key('voice-test-next')));
        await w.elapse(tester, 100);
      }
      expect(find.text('10 / 12'), findsOneWidget);
      expect(find.text('Me llamo…'), findsOneWidget);
      expect(find.text('tu nombre'), findsOneWidget);
      await w.close(tester);
    });

    testWidgets(
      'the end: Heard right: 10 of 12, a row for each line with what was heard, the second thing heard in small grey, Otra vez',
      (tester) async {
        final w = await pump(tester);
        for (var k = 0; k < 12; k++) {
          await tapMic(tester, w, ms: 900);
          await tester.tap(find.byKey(const Key('voice-test-next')));
          await w.elapse(tester, 100);
        }
        expect(find.text('Heard right: 10 of 12'), findsOneWidget);
        expect(find.byKey(const Key('voice-test-again')), findsOneWidget);
        expect(find.text('Otra vez'), findsOneWidget);
        expect(find.text('Hola, abuela'), findsOneWidget);
        expect(find.text('hola abuela'), findsOneWidget);
        expect(find.text('nó'), findsOneWidget);
        expect(tester.widget<Text>(find.text('nó')).style!.fontSize, 12);
        expect(find.text('El micrófono no está disponible.'), findsNothing);
        // Otra vez: line 1 again
        await tester.tap(find.byKey(const Key('voice-test-again')));
        await w.elapse(tester, 100);
        expect(find.text('1 / 12'), findsOneWidget);
        await w.close(tester);
      },
    );

    testWidgets(
      'no microphone: the result and the note, with a dash for every line',
      (tester) async {
        final w = await pump(tester, off: true);
        expect(find.text('Heard right: 0 of 12'), findsOneWidget);
        expect(find.text('El micrófono no está disponible.'), findsOneWidget);
        expect(find.text('—'), findsNWidgets(12));
        expect(find.text('Otra vez'), findsOneWidget);
        await w.close(tester);
      },
    );

    testWidgets(
      'at all four phone sizes nothing overflows across ready, listen, and done',
      (tester) async {
        for (final phone in [
          Phone.android,
          Phone.iphone,
          Phone.small,
          Phone.side,
        ]) {
          final w = await pump(tester, phone: phone);
          expect(tester.takeException(), isNull, reason: '${phone.name} ready');
          await tester.tap(find.byKey(const Key('voice-test-mic')));
          await w.elapse(tester, 100);
          expect(
            tester.takeException(),
            isNull,
            reason: '${phone.name} listen',
          );
          await w.elapse(tester, 700);
          expect(tester.takeException(), isNull, reason: '${phone.name} done');
          await w.close(tester);
        }
      },
    );
  });
}

class _Refusing implements SpeechListener {
  @override
  Future<bool> available() async => true;

  @override
  SpeechTurn listen({
    required String locale,
    required Duration limit,
    int maxAlternatives = 5,
  }) => throw StateError('start() refused');
}
