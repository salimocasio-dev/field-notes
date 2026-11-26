import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_testing/coqui_testing.dart';
import 'package:coqui_ui/coqui_ui.dart';
import 'package:feature_speaking/feature_speaking.dart';
import 'package:feature_speaking/src/call_screen.dart';
import 'package:feature_speaking/src/call_start_reason.dart';
import 'package:feature_speaking/src/call_text.dart';
import 'package:feature_speaking/src/hablar_tab.dart';
import 'package:feature_speaking/src/voice_test_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/dev_app.dart';
import 'support/voice_fixture.dart';
import 'support/world.dart';

void main() {
  group('the module', () {
    test('it is speak, with the tab speak', () {
      const m = SpeakingModule();
      expect(m.id, 'speak');
      final s = fakeServices();
      final tab = m.tab(s)!;
      expect(tab.id, 'speak');
      expect(tab.label, 'Hablar');
    });

    testWidgets('it answers CallRoute and VoiceTestRoute, and no other', (
      tester,
    ) async {
      final w = await World.create(seed: 'todo');
      const m = SpeakingModule();
      expect(
        m.screenFor(const CallRoute('casa'), w.services),
        isA<CallScreen>(),
      );
      // a place with no call, or no such place: nothing to open
      expect(m.screenFor(const CallRoute('parque'), w.services), isNull);
      expect(m.screenFor(const CallRoute('nowhere'), w.services), isNull);
      // the twelve lines come from outside: with none, the route is not answered
      expect(m.screenFor(const VoiceTestRoute(), w.services), isNull);
      expect(
        const SpeakingModule(voiceTest: voiceFixture)
            .screenFor(const VoiceTestRoute(), w.services),
        isA<VoiceTestScreen>(),
      );
      expect(m.screenFor(const TabRoute('speak'), w.services), isNull);
      expect(m.screenFor(const StoryRoute('la-lluvia'), w.services), isNull);
      expect(m.screenFor(const ReviewRoute(), w.services), isNull);
      w.dispose();
    });

    testWidgets(
      'the tab is the Hablar tab; the entry to the voice test shows only with its lines and its title',
      (tester) async {
        Phone.android.use(tester);
        final w = await World.create(seed: 'todo');
        Widget tab(SpeakingModule m) =>
            w.app(Builder(builder: (c) => m.tab(w.services)!.builder(c)));
        await tester.pumpWidget(
          tab(const SpeakingModule(voiceTestEntry: devVoiceTestEntry)),
        );
        expect(find.byType(HablarTab), findsOneWidget);
        expect(
          find.text(devVoiceTestEntry),
          findsNothing,
          reason: 'no lines: no entry',
        );
        await tester.pumpWidget(
          tab(
            const SpeakingModule(
              voiceTest: voiceFixture,
              voiceTestEntry: devVoiceTestEntry,
            ),
          ),
        );
        await tester.scrollUntilVisible(
          find.text(devVoiceTestEntry),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.text(devVoiceTestEntry), findsOneWidget);
        w.dispose();
      },
    );
  });

  group('the dev entry', () {
    testWidgets('opens on the fakes, at Hablar', (tester) async {
      Phone.android.use(tester);
      await tester.pumpWidget(devApp());
      await tester.pumpAndSettle();
      expect(find.text('Speak'), findsOneWidget);
      expect(find.text('Hablar'), findsOneWidget);
      expect(find.text('De visita en la casa'), findsOneWidget);
    });

    testWidgets(
      'tapping the call disc opens the call; the X comes back to Speak',
      (tester) async {
        Phone.android.use(tester);
        await tester.pumpWidget(devApp(const {'reduce': '1'}));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('speak-call-disc')));
        await tester.pump();
        await tester.pump();
        expect(find.text('Start call'), findsOneWidget);
        expect(find.text('La casa · about 5 min'), findsOneWidget);
        await tester.tap(find.byType(LessonCloseButton));
        await tester.pumpAndSettle();
        expect(find.text('De visita en la casa'), findsOneWidget);
      },
    );

    testWidgets('?screen=call opens the call alone', (tester) async {
      Phone.android.use(tester);
      await tester.pumpWidget(devApp(const {'screen': 'call', 'reduce': '1'}));
      await tester.pumpAndSettle();
      expect(find.text('Start call'), findsOneWidget);
    });

    testWidgets('?screen=voice opens the voice test alone', (tester) async {
      Phone.android.use(tester);
      await tester.pumpWidget(devApp(const {'screen': 'voice', 'reduce': '1'}));
      await tester.pumpAndSettle();
      expect(
        find.text('Tap the mic and say each Spanish line.'),
        findsOneWidget,
      );
    });

    test('the steps of the address are read as name@ms', () {
      expect(parseSteps('connect@100,danny1@300,say:Hola.@900'), [
        ('connect', 100),
        ('danny1', 300),
        ('say:Hola.', 900),
      ]);
      expect(parseSteps(null), isEmpty);
    });
  });

  group('why a call did not start', () {
    test('a CallStartError says it by its kind, whatever its text says', () {
      const cases = {
        CallStartFailure.microphone: CallStartReason.microphone,
        CallStartFailure.library: CallStartReason.library,
        CallStartFailure.failed: CallStartReason.failed,
        CallStartFailure.unavailable: CallStartReason.unavailable,
      };
      for (final e in cases.entries) {
        // a text that the old reading would have taken for another reason
        expect(
          callStartReason(
            CallStartError(
              e.key,
              'microphone denied LibraryError NotAvailable',
            ),
          ),
          e.value,
          reason: '${e.key}',
        );
      }
      // its own text, too
      expect(
        callStartReason(
          const CallStartError(
            CallStartFailure.failed,
            'The call did not start.',
          ),
        ),
        CallStartReason.failed,
      );
      expect(
        callStartReason(
          const CallStartError(
            CallStartFailure.microphone,
            'Permission denied',
            name: 'NotAllowedError',
          ),
        ),
        CallStartReason.microphone,
      );
    });

    test(
      'a refused microphone, in the words the client and the platform use',
      () {
        for (final e in [
          Exception('NotAllowedError: Permission denied'),
          'NotAllowedError: Permission denied',
          'PermissionDeniedError: the page may not use the microphone',
          'NotFoundError: Requested device not found',
        ]) {
          expect(callStartReason(e), CallStartReason.microphone, reason: '$e');
        }
      },
    );

    test('anything else that came out of a start is read by its text, as llamada.js reads it: the library, the build with calls off, and the rest', () {
      expect(
        callStartReason('LibraryError: The voice library did not load.'),
        CallStartReason.library,
      );
      expect(
        callStartReason('NotAvailable: Calls are off on this build.'),
        CallStartReason.unavailable,
      );
      expect(
        callStartReason(Exception('The call did not start.')),
        CallStartReason.failed,
      );
      expect(callStartReason(StateError('socket')), CallStartReason.failed);
    });

    test('the line each reason shows (llamada.js\'s three)', () {
      expect(
        callStartLine(CallStartReason.microphone),
        'The microphone is off. Allow it in your browser to call.',
      );
      expect(
        callStartLine(CallStartReason.library),
        'The voice part did not load. Check your connection and try again.',
      );
      expect(
        callStartLine(CallStartReason.failed),
        'The call did not start. Check your connection and try again.',
      );
      expect(
        callStartLine(CallStartReason.unavailable),
        callStartLine(CallStartReason.failed),
      );
    });

    test('a call dropped before it connected: the microphone line only when the error says microphone or permission', () {
      expect(callDroppedLine('Permission denied'), CallTexts.micOff);
      expect(callDroppedLine('the microphone is busy'), CallTexts.micOff);
      expect(
        callDroppedLine('NotAllowedError'),
        CallTexts.notStarted,
        reason: 'llamada.js tests only microphone|permission here',
      );
      expect(callDroppedLine(''), CallTexts.notStarted);
    });
  });

  group('the old helpers', () {
    test('dice: on word boundaries, accents and capitals ignored, an empty word never matches', () {
      final n = normalizeText('¡Hola! Sí, quiero JUGO.');
      expect(dice(n, 'hola'), isTrue);
      expect(dice(n, 'sí'), isTrue);
      expect(dice(n, 'jugo'), isTrue);
      expect(dice(n, 'quiero jugo'), isTrue);
      expect(dice(n, 'jug'), isFalse);
      expect(dice(n, ''), isFalse);
      expect(dice(n, '¿?'), isFalse);
    });

    test('isGoodbye: either side\'s goodbye from the catalog\'s words', () {
      const words = ['adiós', 'hasta mañana'];
      expect(isGoodbye('Adiós.', words), isTrue);
      expect(isGoodbye('Sí. Hasta mañana.', words), isTrue);
      expect(isGoodbye('hasta  MANANA', words), isTrue);
      expect(isGoodbye('Hasta luego', words), isFalse);
      expect(isGoodbye('adiosito', words), isFalse);
      expect(isGoodbye('Adiós', const []), isFalse);
    });

    test('mmss: minutes and seconds, two digits each', () {
      expect(mmss(0), '00:00');
      expect(mmss(59.9), '00:59');
      expect(mmss(60), '01:00');
      expect(mmss(66.4), '01:06');
      expect(mmss(420), '07:00');
      expect(mmss(3600), '60:00');
    });

    test('the summary line and the chips', () {
      expect(CallTexts.summary(1, 1), '1 min · 1 word said');
      expect(CallTexts.summary(2, 0), '2 min · 0 words said');
      expect(CallTexts.summary(5, 7), '5 min · 7 words said');
      expect(CallTexts.chip('a<b>&c'), 'abc');
    });
  });
}

/// The normalised text, as `normalize` gives it.
String normalizeText(String s) => Language.spanish.normalize(s);
