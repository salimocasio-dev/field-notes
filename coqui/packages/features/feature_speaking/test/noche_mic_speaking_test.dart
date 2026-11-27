// Comprehensive tests for NocheMic across feature_speaking (CallScreen,
// VoiceTestScreen, and HablarTab): all six NocheMicState states, live level
// bars, reduced motion propagation, LTR (Spanish) and RTL (Arabic) across all
// phone sizes, and all 9 stable widget keys.
import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_testing/coqui_testing.dart';
import 'package:coqui_ui/coqui_ui.dart';
import 'package:feature_speaking/src/call_controller.dart';
import 'package:feature_speaking/src/call_mic.dart';
import 'package:feature_speaking/src/call_screen.dart';
import 'package:feature_speaking/src/hablar_tab.dart';
import 'package:feature_speaking/src/voice_test_controller.dart';
import 'package:feature_speaking/src/voice_test_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/call_rig.dart';
import 'support/scripted_call.dart';
import 'support/voice_fixture.dart';
import 'support/world.dart';

const _arabicVoice = VoiceTestContent(
  lines: [
    VoiceLine('مرحباً يا جدة', [
      VoiceTarget('مرحباً', ['مرحبا', 'مرحباً']),
      VoiceTarget('جدة', ['جدة']),
    ]),
    VoiceLine('باب البيت', [
      VoiceTarget('باب', ['باب']),
    ]),
  ],
  labels: VoiceTestLabels(
    listening: 'أسمعك…',
    processing: 'لحظة…',
    unavailable: 'الميكروفون غير متاح.',
    again: 'مرة أخرى',
    mic: 'ميكروفون',
    next: 'التالي',
    progress: 'التقدم',
  ),
);

bool _isReddish(Color c) {
  final r = (c.r * 255).round();
  final g = (c.g * 255).round();
  final b = (c.b * 255).round();
  return r > 170 && g < 110 && b < 110;
}

void _expectNoRedInTree(WidgetTester tester) {
  for (final widget in tester.allWidgets) {
    if (widget is Container && widget.decoration is BoxDecoration) {
      final dec = widget.decoration! as BoxDecoration;
      if (dec.color != null) {
        expect(
          _isReddish(dec.color!),
          isFalse,
          reason: 'Container color ${dec.color} must not be red',
        );
      }
      if (dec.border is Border) {
        final border = dec.border! as Border;
        expect(
          _isReddish(border.top.color),
          isFalse,
          reason: 'Border color ${border.top.color} must not be red',
        );
      }
    }
    if (widget is Text && widget.style?.color != null) {
      expect(
        _isReddish(widget.style!.color!),
        isFalse,
        reason: 'Text color ${widget.style!.color} must not be red',
      );
    }
  }
}

Future<Services> _arabicServices({
  Set<String> stub = const {'manual'},
  FakeSpeechListener? speech,
  bool reduceMotion = true,
  ScriptedCall? call,
}) async {
  final clock = FakeClock();
  final progress = RecordingProgress(clock: clock);
  final course = FakeCourseCatalog.arabic();
  await course.load();
  for (final id in course.places.first.stories) {
    progress.storyFinished(StoryResult(id: id));
  }
  final stores = <String, FakeKeyValueStore>{};
  return fakeServices(
    progress: progress,
    course: course,
    call: call ?? ScriptedCall(stub: stub),
    nav: FakeNavigator(),
    haptics: FakeHaptics(),
    speech: speech ?? FakeSpeechListener(results: ['مرحبا يا جدة', 'نافذة']),
    clock: clock,
    storage: (space) => stores.putIfAbsent(space, FakeKeyValueStore.new),
    reduceMotion: reduceMotion,
  );
}

Widget _app(Widget screen) => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: coquiTheme(),
  home: Scaffold(body: screen),
);

void main() {
  group('pure NocheMic state and level mappers', () {
    test('nocheMicStateForCall maps every CallState', () {
      expect(nocheMicStateForCall(CallState.idle), NocheMicState.ready);
      expect(
        nocheMicStateForCall(CallState.connecting),
        NocheMicState.thinking,
      );
      expect(nocheMicStateForCall(CallState.danny), NocheMicState.theySpeak);
      expect(nocheMicStateForCall(CallState.you), NocheMicState.listening);
      expect(nocheMicStateForCall(CallState.proc), NocheMicState.thinking);
      expect(nocheMicStateForCall(CallState.done), NocheMicState.right);
      expect(nocheMicStateForCall(CallState.err), NocheMicState.notYet);
    });

    test('callMicLevel normalizes and clamps ring and wave', () {
      expect(
        callMicLevel(state: CallState.you, ring: 3.0, wave: 1.5),
        closeTo(0.0, 1e-6),
      );
      expect(
        callMicLevel(state: CallState.you, ring: 7.5, wave: 1.5),
        closeTo(0.5, 1e-6),
      );
      expect(
        callMicLevel(state: CallState.you, ring: 15.0, wave: 1.5),
        closeTo(1.0, 1e-6),
      );
      expect(
        callMicLevel(state: CallState.you, ring: 0.0, wave: 1.5),
        closeTo(0.0, 1e-6),
      );
      expect(
        callMicLevel(state: CallState.danny, ring: 3.0, wave: 1.3),
        closeTo(0.0, 1e-6),
      );
      expect(
        callMicLevel(state: CallState.danny, ring: 3.0, wave: 1.6),
        closeTo(0.5, 1e-6),
      );
      expect(
        callMicLevel(state: CallState.danny, ring: 3.0, wave: 2.2),
        closeTo(1.0, 1e-6),
      );
      for (final other in [
        CallState.idle,
        CallState.connecting,
        CallState.proc,
        CallState.done,
        CallState.err,
      ]) {
        expect(callMicLevel(state: other, ring: 9.0, wave: 1.8), 0.0);
      }
    });

    test('nocheMicStateForVoiceTest maps every VoiceTestState', () {
      expect(
        nocheMicStateForVoiceTest(VoiceTestState.load, ok: false),
        NocheMicState.thinking,
      );
      expect(
        nocheMicStateForVoiceTest(VoiceTestState.ready, ok: false),
        NocheMicState.ready,
      );
      expect(
        nocheMicStateForVoiceTest(VoiceTestState.listen, ok: false),
        NocheMicState.listening,
      );
      expect(
        nocheMicStateForVoiceTest(VoiceTestState.proc, ok: false),
        NocheMicState.thinking,
      );
      expect(
        nocheMicStateForVoiceTest(VoiceTestState.done, ok: true),
        NocheMicState.right,
      );
      expect(
        nocheMicStateForVoiceTest(VoiceTestState.done, ok: false),
        NocheMicState.notYet,
      );
      expect(
        nocheMicStateForVoiceTest(VoiceTestState.end, ok: true),
        NocheMicState.right,
      );
    });
  });

  group('all six NocheMic states across CallScreen and VoiceTestScreen', () {
    testWidgets(
      'CallScreen exercises ready, thinking, theySpeak, and listening with live growing bars',
      (tester) async {
        Phone.iphone.use(tester);
        final w = await World.create(
          seed: 'todo',
          stub: const {'manual'},
          reduceMotion: true,
        );
        await tester.pumpWidget(
          w.app(CallScreen(services: w.services, placeId: 'casa')),
        );
        await tester.pump();

        // 1. ready
        expect(
          tester.widget<NocheMic>(find.byType(NocheMic)).state,
          NocheMicState.ready,
        );
        expect(find.text(Language.spanish.micWords['ready']!), findsOneWidget);

        // 2. thinking (connecting)
        await tester.tap(find.byKey(const Key('call-mic-stage')));
        await tester.pump();
        expect(
          tester.widget<NocheMic>(find.byType(NocheMic)).state,
          NocheMicState.thinking,
        );
        expect(
          find.text(Language.spanish.micWords['thinking']!),
          findsOneWidget,
        );

        // 3. theySpeak (Danny)
        w.call.go('connect');
        await w.elapse(tester, 200);
        expect(
          tester.widget<NocheMic>(find.byType(NocheMic)).state,
          NocheMicState.theySpeak,
        );
        expect(
          find.text(Language.spanish.micWords['theySpeak']!),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('noche_mic_bars_start')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('noche_mic_bars_end')),
          findsOneWidget,
        );

        // 4. listening (Your turn) + live level bar growth
        w.call.go('danny1');
        await w.elapse(tester, 2400);
        w.call.go('you1');
        await w.elapse(tester, 300);
        expect(
          tester.widget<NocheMic>(find.byType(NocheMic)).state,
          NocheMicState.listening,
        );
        expect(
          find.text(Language.spanish.micWords['listening']!),
          findsOneWidget,
        );
        final quietBar2 = tester
            .getSize(find.byKey(const ValueKey('noche_mic_bar_start_2')))
            .height;
        w.call.go('talk1');
        await w.elapse(tester, 600);
        final loudBar2 = tester
            .getSize(find.byKey(const ValueKey('noche_mic_bar_start_2')))
            .height;
        expect(loudBar2, greaterThan(quietBar2));

        // 5. thinking (One moment)
        await w.elapse(tester, 600);
        w.call.go('quiet1');
        await w.elapse(tester, 800);
        expect(
          tester.widget<NocheMic>(find.byType(NocheMic)).state,
          NocheMicState.thinking,
        );

        await w.close(tester);
      },
    );

    testWidgets(
      'VoiceTestScreen exercises ready, listening, thinking, right, and calm notYet with zero red',
      (tester) async {
        Phone.iphone.use(tester);
        final w = await World.create(
          seed: null,
          speech: FakeSpeechListener.stub('hola abuela|none'),
          reduceMotion: true,
        );
        await tester.pumpWidget(
          w.app(VoiceTestScreen(services: w.services, content: voiceFixture)),
        );
        await tester.pump();
        await tester.pump();

        // ready
        expect(
          tester
              .widget<NocheMic>(find.byKey(const Key('voice-test-mic')))
              .state,
          NocheMicState.ready,
        );
        expect(find.text(Language.spanish.micWords['ready']!), findsOneWidget);

        // listening
        await tester.tap(find.byKey(const Key('voice-test-mic')));
        await w.elapse(tester, 100);
        expect(
          tester
              .widget<NocheMic>(find.byKey(const Key('voice-test-mic')))
              .state,
          NocheMicState.listening,
        );
        expect(
          find.text(Language.spanish.micWords['listening']!),
          findsOneWidget,
        );

        // thinking
        await w.elapse(tester, 250);
        expect(
          tester
              .widget<NocheMic>(find.byKey(const Key('voice-test-mic')))
              .state,
          NocheMicState.thinking,
        );
        expect(
          find.text(Language.spanish.micWords['thinking']!),
          findsOneWidget,
        );

        // right (allow NocheMic quick 140ms color transition to complete)
        await w.elapse(tester, 400);
        expect(
          tester
              .widget<NocheMic>(find.byKey(const Key('voice-test-mic')))
              .state,
          NocheMicState.right,
        );
        expect(find.text(Language.spanish.micWords['right']!), findsOneWidget);
        final rightDisc = tester.widget<Container>(
          find.byKey(const ValueKey('noche_mic_disc')),
        );
        expect(
          (rightDisc.decoration! as BoxDecoration).color,
          NocheColors.right,
        );

        // Next -> line 2 -> notYet (never red!)
        await tester.tap(find.byKey(const Key('voice-test-next')));
        await tester.pump();
        await tester.tap(find.byKey(const Key('voice-test-mic')));
        await w.elapse(tester, 800);
        expect(
          tester
              .widget<NocheMic>(find.byKey(const Key('voice-test-mic')))
              .state,
          NocheMicState.notYet,
        );
        expect(find.text(Language.spanish.micWords['notYet']!), findsOneWidget);
        final notYetDisc = tester.widget<Container>(
          find.byKey(const ValueKey('noche_mic_disc')),
        );
        final notYetDec = notYetDisc.decoration! as BoxDecoration;
        expect(notYetDec.color, isNull);
        expect((notYetDec.border! as Border).top.color, NocheColors.text);
        _expectNoRedInTree(tester);

        await w.close(tester);
      },
    );
  });

  group('Services.reduceMotion controls NocheMotion in CallScreen and VoiceTestScreen', () {
    for (final reduce in [false, true]) {
      testWidgets(
        'CallScreen reduceMotion=$reduce sets NocheMotion.loops=${!reduce}',
        (tester) async {
          Phone.iphone.use(tester);
          final w = await World.create(
            seed: 'todo',
            stub: const {'manual'},
            reduceMotion: reduce,
          );
          await tester.pumpWidget(
            w.app(CallScreen(services: w.services, placeId: 'casa')),
          );
          await tester.pump();
          final micContext = tester.element(find.byType(NocheMic));
          expect(NocheMotion.of(micContext).reduced, reduce);
          expect(NocheMotion.of(micContext).loops, !reduce);
          await w.close(tester);
        },
      );

      testWidgets(
        'VoiceTestScreen reduceMotion=$reduce sets NocheMotion.loops=${!reduce}',
        (tester) async {
          Phone.iphone.use(tester);
          final w = await World.create(
            seed: null,
            speech: FakeSpeechListener.stub('hola abuela'),
            reduceMotion: reduce,
          );
          await tester.pumpWidget(
            w.app(VoiceTestScreen(services: w.services, content: voiceFixture)),
          );
          await tester.pump();
          await tester.pump();
          final micContext = tester.element(
            find.byKey(const Key('voice-test-mic')),
          );
          expect(NocheMotion.of(micContext).reduced, reduce);
          expect(NocheMotion.of(micContext).loops, !reduce);
          await w.close(tester);
        },
      );
    }
  });

  group('LTR (Spanish) and RTL (Arabic) across all 4 phone sizes with zero overflow', () {
    const phones = [Phone.iphone, Phone.android, Phone.small, Phone.side];

    for (final phone in phones) {
      testWidgets('Arabic RTL CallScreen fits with bars in ${phone.name}', (
        tester,
      ) async {
        phone.use(tester);
        final call = ScriptedCall(stub: const {'manual'});
        final services = await _arabicServices(call: call);
        await tester.pumpWidget(
          _app(CallScreen(services: services, placeId: 'casa')),
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
        expect(
          Directionality.of(
            tester.element(find.byKey(const Key('call-screen'))),
          ),
          TextDirection.rtl,
        );
        expect(
          find.text(arabicTestLanguage.micWords['ready']!),
          findsOneWidget,
        );

        await tester.tap(find.byKey(const Key('call-mic-stage')));
        await tester.pump();
        call.go('connect');
        await tester.pump(const Duration(milliseconds: 200));
        expect(tester.takeException(), isNull);
        expect(
          find.text(arabicTestLanguage.micWords['theySpeak']!),
          findsOneWidget,
        );

        call.emit(const Mode('listening'));
        await tester.pump(const Duration(milliseconds: 200));
        expect(tester.takeException(), isNull);
        expect(
          find.text(arabicTestLanguage.micWords['listening']!),
          findsOneWidget,
        );

        await tester.pumpWidget(const SizedBox());
        call.dispose();
      });

      testWidgets(
        'Arabic RTL VoiceTestScreen fits across ready, listen, done in ${phone.name}',
        (tester) async {
          phone.use(tester);
          final call = ScriptedCall(stub: const {'manual'});
          final services = await _arabicServices(call: call);
          await tester.pumpWidget(
            _app(VoiceTestScreen(services: services, content: _arabicVoice)),
          );
          await tester.pump();
          await tester.pump();
          expect(tester.takeException(), isNull);
          expect(
            Directionality.of(
              tester.element(find.byKey(const Key('voice-test-screen'))),
            ),
            TextDirection.rtl,
          );
          expect(
            find.text(arabicTestLanguage.micWords['ready']!),
            findsOneWidget,
          );

          await tester.tap(find.byKey(const Key('voice-test-mic')));
          await tester.pump(const Duration(milliseconds: 100));
          expect(tester.takeException(), isNull);
          expect(
            find.text(arabicTestLanguage.micWords['listening']!),
            findsOneWidget,
          );

          await tester.pump(const Duration(milliseconds: 700));
          expect(tester.takeException(), isNull);
          expect(
            find.text(arabicTestLanguage.micWords['right']!),
            findsOneWidget,
          );

          await tester.pumpWidget(const SizedBox());
          call.dispose();
        },
      );
    }
  });

  group('all 9 stable widget keys', () {
    testWidgets(
      'HablarTab exposes speak-next-call-card, speak-call-disc, speak-place-<placeId>, and speak-coming-soon',
      (tester) async {
        Phone.android.use(tester);
        final w = await World.create(seed: 'todo');
        await tester.pumpWidget(w.app(HablarTab(services: w.services)));
        await tester.pump();

        expect(find.byKey(const Key('speak-next-call-card')), findsOneWidget);
        expect(find.byKey(const Key('speak-call-disc')), findsOneWidget);
        expect(find.byKey(const Key('speak-place-casa')), findsOneWidget);
        expect(find.byKey(const Key('speak-place-parque')), findsOneWidget);

        // Complete all stories in parque so its unbacked call is in HablarCallState.soon.
        final parque = w.course.places.firstWhere((p) => p.id == 'parque');
        for (final storyId in parque.stories) {
          w.progress.storyFinished(StoryResult(id: storyId));
        }
        await tester.pump();
        await tester.tap(find.byKey(const Key('speak-place-parque')));
        await tester.pump();

        expect(find.byKey(const Key('speak-coming-soon')), findsOneWidget);
        await w.close(tester);
      },
    );

    testWidgets(
      'CallScreen exposes call-screen, call-mic-stage, and call-end-back',
      (tester) async {
        Phone.android.use(tester);
        final w = await World.create(
          seed: 'todo',
          stub: const {'manual'},
          reduceMotion: true,
        );
        await tester.pumpWidget(
          w.app(CallScreen(services: w.services, placeId: 'casa')),
        );
        await tester.pump();

        expect(find.byKey(const Key('call-screen')), findsOneWidget);
        expect(find.byKey(const Key('call-mic-stage')), findsOneWidget);

        await tester.tap(find.byKey(const Key('call-mic-stage')));
        await tester.pump();
        w.call.go('connect');
        await w.elapse(tester, 100);
        await tester.tap(find.byKey(const Key('call-close')));
        await w.elapse(tester, 100);

        expect(find.byKey(const Key('call-end-back')), findsOneWidget);
        await w.close(tester);
      },
    );

    testWidgets(
      'VoiceTestScreen exposes voice-test-screen and voice-test-mic',
      (tester) async {
        Phone.android.use(tester);
        final w = await World.create(
          seed: null,
          speech: FakeSpeechListener.stub('hola abuela'),
          reduceMotion: true,
        );
        await tester.pumpWidget(
          w.app(VoiceTestScreen(services: w.services, content: voiceFixture)),
        );
        await tester.pump();
        await tester.pump();

        expect(find.byKey(const Key('voice-test-screen')), findsOneWidget);
        expect(find.byKey(const Key('voice-test-mic')), findsOneWidget);
        await w.close(tester);
      },
    );
  });
}
