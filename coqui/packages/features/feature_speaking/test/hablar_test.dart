// The Hablar tab (order 25: one "Up next" call and a 10-stop journey by place) and its notes, in the states of the
// reference pictures. Runs on the fakes only: no real call is ever placed.
import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_testing/coqui_testing.dart';
import 'package:coqui_ui/coqui_ui.dart';
import 'package:feature_speaking/feature_speaking.dart';
import 'package:feature_speaking/src/call_controller.dart';
import 'package:feature_speaking/src/call_text.dart';
import 'package:feature_speaking/src/entitlements_hook.dart';
import 'package:feature_speaking/src/hablar_model.dart';
import 'package:feature_speaking/src/hablar_tab.dart';
import 'package:feature_speaking/src/speech_note.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/call_rig.dart';
import 'support/dev_app.dart' show devVoiceTestEntry;
import 'support/scripted_call.dart';
import 'support/world.dart';

/// A call session that counts how often it is asked whether it is available (the old page loaded the voice
/// library when Hablar showed an open card).
class CountingCall extends ScriptedCall {
  CountingCall({super.available});
  int asked = 0;
  @override
  bool get available {
    asked++;
    return super.available;
  }
}

class _CallsCourse extends FixtureCourse {
  _CallsCourse({required this.callsByPlace});

  final Map<String, List<CallBrief>> callsByPlace;

  @override
  List<CallBrief> callsFor(String placeId) => callsByPlace[placeId] ?? const [];

  @override
  CallBrief? callFor(String placeId) {
    final list = callsFor(placeId);
    if (list.isEmpty) return null;
    for (final c in list) {
      if (c.isMain) return c;
    }
    return list.first;
  }
}

/// The note is read after the first frame and shown on the next: two frames.
Future<void> settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump();
}

Widget tab(
  World w, {
  String? callsLater,
  String? entry,
  bool note = false,
  CallEntitlementCheck entitlementCheck = defaultCallEntitlement,
  Set<String> completedCallIds = const {},
  bool shortCallsEnabled = false,
}) => w.app(
  HablarTab(
    key: UniqueKey(), // a new tab each time: the note is read when the tab is made
    services: w.services,
    callsLater: callsLater,
    voiceTestLabel: entry,
    showSpeechNote: note,
    entitlementCheck: entitlementCheck,
    completedCallIds: completedCallIds,
    shortCallsEnabled: shortCallsEnabled,
  ),
);

void main() {
  setUp(resetSpeechNoteDay);

  group(
    'CallsCatalog wiring, readiness gating, and persisted call completion',
    () {
      test('reads id, title, jobEn ({partner}), minutes, isMain, and nullable photo from course.callsFor', () async {
        final course = _CallsCourse(
          callsByPlace: {
            'casa': [
              CallBrief(
                id: 'casa_agua',
                placeId: 'casa',
                title: 'Un vaso de agua',
                jobEn: 'Ask {partner} for water and say thanks.',
                minutes: 2,
                job: 'Ask for water',
                opening: '¡Hola! ¿Quieres agua?',
                isMain: false,
              ),
              CallBrief(
                id: 'casa_main',
                placeId: 'casa',
                title: 'De visita en la casa',
                jobEn:
                    'Greet {partner}, introduce yourself, and accept a drink.',
                minutes: 5,
                job: 'Greet and accept a drink',
                opening: '¡Hola! Soy Danny.',
                photo: 'casa_pixel',
                isMain: true,
              ),
            ],
          },
        );
        await course.load();
        final p = RecordingProgress();
        for (final id in course.places.first.stories) {
          p.storyFinished(StoryResult(id: id));
        }

        final snap = buildHablarSnapshot(
          course: course,
          progress: p,
          callsAvailable: () => true,
          shortCallsEnabled: true,
        );
        final casa = snap.stops.first;
        expect(casa.calls.length, 2);

        final agua = casa.smallerCalls.single;
        expect(agua.spec.id, 'casa_agua');
        expect(agua.spec.titleEs, 'Un vaso de agua');
        expect(agua.spec.jobEn, 'Ask Danny for water and say thanks.');
        expect(agua.spec.minutes, 2);
        expect(agua.spec.isMain, isFalse);
        expect(agua.spec.pixelAsset, isNull);
        expect(agua.state, HablarCallState.ready);

        final main = casa.mainCall!;
        expect(main.spec.id, 'casa_main');
        expect(main.spec.titleEs, 'De visita en la casa');
        expect(
          main.spec.jobEn,
          'Greet Danny, introduce yourself, and accept a drink.',
        );
        expect(main.spec.minutes, 5);
        expect(main.spec.isMain, isTrue);
        expect(main.spec.pixelAsset, 'casa_pixel');
        expect(main.state, HablarCallState.ready);
      });

      test('gating on authored opening: empty/whitespace opening stays soon and blocks SpeakingModule and CallController', () async {
        final course = _CallsCourse(
          callsByPlace: {
            'casa': [
              CallBrief(
                id: 'casa_agua',
                placeId: 'casa',
                title: 'Un vaso de agua',
                jobEn: 'Ask for water.',
                minutes: 2,
                job: 'Ask for water',
                opening: '',
                isMain: false,
              ),
              CallBrief(
                id: 'casa_main',
                placeId: 'casa',
                title: 'De visita en la casa',
                jobEn: 'Greet {partner}.',
                minutes: 5,
                job: 'Visit',
                opening: '¡Hola! Soy Danny.',
                isMain: true,
              ),
            ],
            'parque': [
              CallBrief(
                id: 'parque_main',
                placeId: 'parque',
                title: 'El perro en el parque',
                jobEn: 'Describe the park.',
                minutes: 5,
                job: 'Park',
                opening: '   ',
                isMain: true,
              ),
            ],
          },
        );
        await course.load();
        final p = RecordingProgress();
        for (final place in course.places) {
          for (final id in place.stories) {
            p.storyFinished(StoryResult(id: id));
          }
        }

        final snap = buildHablarSnapshot(
          course: course,
          progress: p,
          callsAvailable: () => true,
          shortCallsEnabled: true,
        );
        final casa = snap.stopById('casa')!;
        expect(casa.mainCall!.state, HablarCallState.ready);
        expect(casa.mainCall!.canStart, isTrue);

        final agua = casa.smallerCalls.single;
        expect(agua.state, HablarCallState.soon);
        expect(agua.canStart, isFalse);
        expect(agua.statusLine, 'Coming soon · La casa');
        expect(agua.cardMetaLine, '2 min · coming soon');

        final parque = snap.stopById('parque')!;
        expect(parque.mainCall!.state, HablarCallState.soon);
        expect(parque.mainCall!.canStart, isFalse);
        expect(parque.mainCall!.statusLine, 'Coming soon · El parque');

        final call = ScriptedCall();
        final services = fakeServices(progress: p, course: course, call: call);
        const module = SpeakingModule(shortCallsEnabled: true);
        expect(module.screenFor(const CallRoute('casa'), services), isNotNull);
        expect(
          module.screenFor(
            const CallRoute('casa', callId: 'casa_main'),
            services,
          ),
          isNotNull,
        );
        expect(
          module.screenFor(
            const CallRoute('casa', callId: 'casa_agua'),
            services,
          ),
          isNull,
        );
        expect(module.screenFor(const CallRoute('parque'), services), isNull);

        final unreadyCtrl = CallController(
          session: call,
          clock: FakeClock(),
          course: course,
          progress: p,
          placeId: 'casa',
          callId: 'casa_agua',
        );
        expect(unreadyCtrl.available, isFalse);
        unreadyCtrl.dispose();
        call.dispose();
      });

      testWidgets(
        'progress.callDone persists across restarts, updates completedCount/meta/featuredCall, and keeps done main call replayable',
        (tester) async {
          final course = _CallsCourse(
            callsByPlace: {
              'casa': [
                CallBrief(
                  id: 'casa_agua',
                  placeId: 'casa',
                  title: 'Un vaso de agua',
                  jobEn: 'Ask for water.',
                  minutes: 2,
                  job: 'Ask for water',
                  opening: '¡Hola! ¿Agua?',
                  isMain: false,
                ),
                CallBrief(
                  id: 'casa_saludo',
                  placeId: 'casa',
                  title: '¿Cómo estás?',
                  jobEn: 'Say how you are doing.',
                  minutes: 2,
                  job: 'Greet',
                  opening: '¡Hola! ¿Cómo estás?',
                  isMain: false,
                ),
                CallBrief(
                  id: 'casa_main',
                  placeId: 'casa',
                  title: 'De visita en la casa',
                  jobEn: 'Greet {partner} and accept a drink.',
                  minutes: 5,
                  job: 'Visit',
                  opening: '¡Hola! Soy Danny.',
                  isMain: true,
                ),
              ],
            },
          );
          await course.load();
          final p1 = RecordingProgress();
          for (final id in course.places.first.stories) {
            p1.storyFinished(StoryResult(id: id));
          }

          // Complete the first smaller call and simulate app restart via export/import.
          p1.markCallDone('casa_agua');
          final p2 = FakeProgressStore(json: p1.export());
          expect(p2.callDone('casa_agua'), isTrue);

          final snapAfterOne = buildHablarSnapshot(
            course: course,
            progress: p2,
            callsAvailable: () => true,
            shortCallsEnabled: true,
          );
          expect(snapAfterOne.completedCount, 1);
          final casa1 = snapAfterOne.stopById('casa')!;
          expect(casa1.featuredCall!.spec.id, 'casa_saludo');
          final aguaItem = casa1.calls.firstWhere(
            (c) => c.spec.id == 'casa_agua',
          );
          expect(aguaItem.state, HablarCallState.done);
          expect(aguaItem.cardMetaLine, '2 min · done');

          // Complete remaining calls too; main call stays replayable in HablarTab.
          p2.markCallDone('casa_saludo');
          p2.markCallDone('casa_main');
          final p3 = FakeProgressStore(json: p2.export());
          final snapAllDone = buildHablarSnapshot(
            course: course,
            progress: p3,
            callsAvailable: () => true,
            shortCallsEnabled: true,
          );
          expect(snapAllDone.completedCount, 3);
          final casaAll = snapAllDone.stopById('casa')!;
          expect(casaAll.featuredCall!.spec.id, 'casa_main');
          expect(casaAll.featuredCall!.state, HablarCallState.done);
          expect(casaAll.otherCalls.map((c) => c.cardMetaLine).toList(), [
            '2 min · done',
            '2 min · done',
          ]);

          Phone.android.use(tester);
          final call = ScriptedCall();
          final nav = FakeNavigator();
          final services = fakeServices(
            progress: p3,
            course: course,
            call: call,
            nav: nav,
          );
          await tester.pumpWidget(
            MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: coquiTheme(),
              home: Scaffold(
                body: HablarTab(services: services, shortCallsEnabled: true),
              ),
            ),
          );
          expect(find.text('2 min · done'), findsNWidgets(2));
          expect(find.byKey(const Key('speak-call-disc')), findsOneWidget);
          await tester.tap(find.byKey(const Key('speak-call-disc')));
          await tester.pump();
          expect(nav.routes, [const CallRoute('casa')]);
          call.dispose();
        },
      );
    },
  );

  group('hablar: the snapshot without a widget', () {
    test('the old rule on a plain store, by place', () async {
      final course = FixtureCourse();
      await course.load();
      final p = RecordingProgress();
      HablarSnapshot snap({Set<String> done = const {}}) => buildHablarSnapshot(
        course: course,
        progress: p,
        callsAvailable: () => true,
        completedCallIds: done,
      );
      expect(snap().stops.map((s) => s.state).toSet(), {
        HablarCallState.upcoming,
      });
      for (final l in course.places.take(3)) {
        for (final id in l.stories) {
          p.storyFinished(StoryResult(id: id));
        }
      }
      final s = snap();
      expect(s.stops.map((c) => c.state).take(4), [
        HablarCallState.ready,
        HablarCallState.soon,
        HablarCallState.soon,
        HablarCallState.upcoming,
      ]);
      expect(s.stops[1].statusLine, 'Coming soon · El parque');
      expect(s.stops[3].statusLine, 'Opens when you finish El colmado');
      expect(s.nextCall!.spec.id, 'casa');
      expect(s.nextCall!.spec.minutes, course.callFor('casa')!.minutes);
      expect(s.completedCount, 0);
      // FixtureCourse only supplies legacy casa, so places without calls get a single placeholder card
      expect(s.stops.first.smallerCalls, isEmpty);
      expect(s.stops[1].mainCall!.spec.titleEs, 'El parque');
      expect(s.stops[1].mainCall!.spec.jobEn, isEmpty);
      expect(s.stops[1].mainCall!.state, HablarCallState.soon);
      // once the main call is done it is offered again
      final again = snap(done: const {'casa'});
      expect(again.stops.first.state, HablarCallState.done);
      expect(again.nextCall!.spec.id, 'casa');
      expect(again.nextCall!.state, HablarCallState.done);
      expect(again.completedCount, 1);
    });
  });

  group('hablar: Noche Speak card and reached places', () {
    testWidgets(
      'nothing played: shows Speak header, De visita en la casa, Opens when you finish La casa, and no call disc',
      (tester) async {
        Phone.android.use(tester);
        final w = await World.create(seed: 'vacio');
        await tester.pumpWidget(tab(w));
        expect(find.text('SPANISH'), findsOneWidget);
        expect(find.text('Speak'), findsOneWidget);
        expect(find.text('Call Danny'), findsNothing);
        expect(find.text('De visita en la casa'), findsOneWidget);
        expect(find.text('Opens when you finish La casa'), findsOneWidget);
        expect(find.byKey(const Key('speak-call-disc')), findsNothing);
        expect(find.text('I said it'), findsNothing);
        await tester.tap(find.text('Opens when you finish La casa'));
        await tester.pump();
        expect(w.nav.routes, isEmpty);
        expect(w.haptics.ticks, 0);
        w.dispose();
      },
    );

    testWidgets('10 of 11 stories of La casa played: still locked', (
      tester,
    ) async {
      Phone.android.use(tester);
      final w = await World.create(seed: null);
      for (final id in w.course.places.first.stories.take(10)) {
        w.progress.storyFinished(StoryResult(id: id));
      }
      await tester.pumpWidget(tab(w));
      expect(find.text('Opens when you finish La casa'), findsOneWidget);
      expect(find.byKey(const Key('speak-call-disc')), findsNothing);
      w.dispose();
    });

    testWidgets(
      'open: featured call card with 96 px orange mic disc that goes to the call with a tick',
      (tester) async {
        Phone.android.use(tester);
        final w = await World.create(seed: 'todo');
        await tester.pumpWidget(tab(w));
        expect(find.text('NEXT CALL WITH DANNY · 5 MIN'), findsOneWidget);
        expect(find.text('De visita en la casa'), findsOneWidget);
        expect(
          find.text('Greet Danny, introduce yourself, and accept a drink.'),
          findsOneWidget,
        );
        expect(find.text('Call Danny'), findsOneWidget);
        final discFinder = find.byKey(const Key('speak-call-disc'));
        expect(discFinder, findsOneWidget);
        final discSize = tester.getSize(discFinder);
        expect(discSize.width, 96);
        expect(discSize.height, 96);

        await tester.tap(discFinder);
        await tester.pump();
        expect(w.nav.routes, [const CallRoute('casa')]);
        expect(w.haptics.ticks, 1);
        w.dispose();
      },
    );

    testWidgets(
      'reached places without course calls show coming soon placeholder and tapping a reached place switches the card',
      (tester) async {
        Phone.android.use(tester);
        final w = await World.create(seed: 'todo');
        await tester.pumpWidget(tab(w));
        expect(find.text('La casa'), findsOneWidget);
        expect(find.text('El parque'), findsOneWidget);
        expect(find.text('La cocina'), findsOneWidget);
        expect(
          find.byKey(const Key('speak-locked-place-pill')),
          findsOneWidget,
        );

        // FixtureCourse only provides legacy casa; no hardcoded smaller calls appear.
        expect(find.text('Un vaso de agua'), findsNothing);

        // Tapping another reached place switches to its coming-soon placeholder card.
        await tester.tap(find.text('El parque'));
        await tester.pump();
        expect(find.text('Coming soon · El parque'), findsOneWidget);
        w.dispose();
      },
    );

    testWidgets(
      'the level check counts: after it, La casa\'s call can start (its 11 stories count as played)',
      (tester) async {
        Phone.android.use(tester);
        final w = await World.create(seed: 'nivel');
        await tester.pumpWidget(tab(w));
        expect(find.byKey(const Key('speak-call-disc')), findsOneWidget);
        w.dispose();
      },
    );

    testWidgets('mid-course: La casa\'s call can start', (tester) async {
      Phone.android.use(tester);
      final w = await World.create(seed: 'curso');
      await tester.pumpWidget(tab(w));
      expect(find.byKey(const Key('speak-call-disc')), findsOneWidget);
      expect(find.text('De visita en la casa'), findsOneWidget);
      w.dispose();
    });

    testWidgets(
      'the call opens as soon as the last story is played, with the tab showing',
      (tester) async {
        Phone.android.use(tester);
        final w = await World.create(seed: null);
        final stories = w.course.places.first.stories;
        for (final id in stories.take(10)) {
          w.progress.storyFinished(StoryResult(id: id));
        }
        await tester.pumpWidget(tab(w));
        expect(find.byKey(const Key('speak-call-disc')), findsNothing);
        w.progress.storyFinished(StoryResult(id: stories.last));
        await tester.pump();
        await tester.pump();
        expect(find.byKey(const Key('speak-call-disc')), findsOneWidget);
        w.dispose();
      },
    );

    testWidgets('a done main call is offered again', (tester) async {
      Phone.android.use(tester);
      final w = await World.create(seed: 'todo');
      await tester.pumpWidget(tab(w, completedCallIds: const {'casa'}));
      expect(find.byKey(const Key('speak-call-disc')), findsOneWidget);
      await tester.tap(find.byKey(const Key('speak-call-disc')));
      await tester.pump();
      expect(w.nav.routes, [const CallRoute('casa')]);
      w.dispose();
    });

    testWidgets(
      'no horizontal overflow at the sizes of the old checks, with vacio and todo',
      (tester) async {
        for (final phone in [
          Phone.android,
          Phone.iphone,
          Phone.small,
          Phone.side,
        ]) {
          for (final seed in ['vacio', 'todo']) {
            phone.use(tester);
            final w = await World.create(seed: seed);
            await tester.pumpWidget(tab(w));
            expect(
              tester.takeException(),
              isNull,
              reason: '${phone.name} $seed',
            );
            final box = tester.getRect(find.byType(HablarTab));
            expect(
              box.right,
              lessThanOrEqualTo(phone.width),
              reason: phone.name,
            );
            await tester.tap(find.text('La casa'));
            await tester.pump();
            expect(
              tester.takeException(),
              isNull,
              reason: '${phone.name} $seed, La casa tapped',
            );
            w.dispose();
          }
        }
      },
    );
  });

  group('hablar: entitlements', () {
    testWidgets('tier locked: a calm plan line instead of the call disc', (
      tester,
    ) async {
      Phone.android.use(tester);
      final w = await World.create(seed: 'todo');
      await tester.pumpWidget(
        tab(w, entitlementCheck: () => CallEntitlement.upgradeRequired),
      );
      expect(find.byKey(const Key('speak-call-disc')), findsNothing);
      expect(find.text(HablarTexts.tierLockedLine), findsOneWidget);
      await tester.tap(find.text(HablarTexts.tierLockedLine));
      await tester.pump();
      expect(w.nav.routes, isEmpty);
      w.dispose();
    });
  });

  group('hablar: calls come later on this build', () {
    testWidgets(
      'call.available false: no call disc, nothing goes to the call; by default it says "Calls with Danny open later."',
      (tester) async {
        Phone.android.use(tester);
        final w = await World.create(seed: 'todo', callAvailable: false);
        await tester.pumpWidget(tab(w));
        expect(find.byKey(const Key('speak-call-disc')), findsNothing);
        expect(find.text('Calls with Danny open later.'), findsOneWidget);
        await tester.tap(find.text('Calls with Danny open later.'));
        await tester.pump();
        expect(w.nav.routes, isEmpty);
        w.dispose();
      },
    );

    testWidgets('the module\'s `callsLater` overrides the default line', (
      tester,
    ) async {
      Phone.android.use(tester);
      final w = await World.create(seed: 'todo', callAvailable: false);
      await tester.pumpWidget(tab(w, callsLater: 'Calls are coming.'));
      expect(find.text('Calls are coming.'), findsOneWidget);
      expect(find.text('Calls with Danny open later.'), findsNothing);
      w.dispose();
    });

    testWidgets('an empty `callsLater` leaves no line and nothing to start', (
      tester,
    ) async {
      Phone.android.use(tester);
      final w = await World.create(seed: 'todo', callAvailable: false);
      await tester.pumpWidget(tab(w, callsLater: ''));
      expect(find.byKey(const Key('speak-call-disc')), findsNothing);
      expect(find.byKey(const Key('speak-locked-status')), findsNothing);
      expect(find.text('Calls with Danny open later.'), findsNothing);
      w.dispose();
    });

    testWidgets('the line is only there when this build cannot place a call', (
      tester,
    ) async {
      Phone.android.use(tester);
      final w = await World.create(seed: 'todo'); // the call can be placed
      await tester.pumpWidget(tab(w));
      expect(find.text('Calls with Danny open later.'), findsNothing);
      expect(find.byKey(const Key('speak-call-disc')), findsOneWidget);
      w.dispose();
    });

    testWidgets(
      'the voice library is asked for only when an open call is shown (the old precarga)',
      (tester) async {
        Phone.android.use(tester);
        final locked = await World.create(seed: 'vacio', call: CountingCall());
        await tester.pumpWidget(tab(locked));
        expect((locked.call as CountingCall).asked, 0);
        locked.dispose();
        final open = await World.create(seed: 'todo', call: CountingCall());
        await tester.pumpWidget(tab(open));
        expect((open.call as CountingCall).asked, greaterThan(0));
        open.dispose();
      },
    );
  });

  group('hablar: a call library that did not load', () {
    testWidgets(
      'the failed answer is kept: the tab does not ask again at each rebuild, only when it is made again',
      (tester) async {
        Phone.android.use(tester);
        // a call session whose library did not load: `available` is false, and each read of it is counted (each read
        // of the real one starts another try at the network)
        final call = CountingCall(available: false);
        final w = await World.create(seed: 'todo', call: call);
        await tester.pumpWidget(tab(w));
        expect(call.asked, 1);
        expect(find.text('Calls with Danny open later.'), findsOneWidget);
        expect(find.byKey(const Key('speak-call-disc')), findsNothing);
        // the tab is built again at every change of the progress
        for (var i = 0; i < 7; i++) {
          w.progress.add('word $i');
          await tester.pump();
        }
        expect(call.asked, 1);
        expect(find.text('Calls with Danny open later.'), findsOneWidget);
        // a screen opened afresh asks again, once
        await tester.pumpWidget(tab(w));
        expect(call.asked, 2);
        w.progress.add('another word');
        await tester.pump();
        expect(call.asked, 2);
        w.dispose();
      },
    );

    testWidgets(
      'an answer of true is not kept: the call can start and follows the session',
      (tester) async {
        Phone.android.use(tester);
        final call = CountingCall();
        final w = await World.create(seed: 'todo', call: call);
        await tester.pumpWidget(tab(w));
        expect(find.byKey(const Key('speak-call-disc')), findsOneWidget);
        final first = call.asked;
        w.progress.add('a word');
        await tester.pump();
        expect(call.asked, greaterThan(first));
        expect(find.byKey(const Key('speak-call-disc')), findsOneWidget);
        w.dispose();
      },
    );
  });

  group('hablar: words open for speaking', () {
    testWidgets(
      'nothing met: header says 0 words ready to say, the sheet shows the plain sentence',
      (tester) async {
        Phone.android.use(tester);
        final w = await World.create(seed: 'vacio');
        await tester.pumpWidget(tab(w));
        await tester.tap(find.text('0 words ready to say'));
        await tester.pumpAndSettle();
        expect(find.text(HablarTexts.wordsTitle), findsOneWidget);
        expect(find.text(HablarTexts.wordsNone), findsOneWidget);
        await tester.tap(find.bySemanticsLabel('Close'));
        await tester.pumpAndSettle();
        expect(find.text(HablarTexts.wordsTitle), findsNothing);
        w.dispose();
      },
    );

    testWidgets(
      'the words whose ear stage is 3 or more, in the order the store has them, one chip each in the sheet',
      (tester) async {
        Phone.android.use(tester);
        final w = await World.create(seed: 'todo');
        await tester.pumpWidget(tab(w));
        final open = [
          for (final r in w.progress.words)
            if (r.ear.etapa >= 3) r.w,
        ];
        expect(open.length, greaterThan(50));
        expect(wordsOpenForSpeaking(w.progress), open);
        await tester.tap(find.text('${open.length} words ready to say'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(
          find.descendant(
            of: find.byType(NocheSheet),
            matching: find.text(CallTexts.chip(open.first)),
          ),
          findsOneWidget,
        );
        w.dispose();
      },
    );

    test('a word he has said but whose ear stage is under 3 is not listed (the old page asks the stage only)', () {
      final p = RecordingProgress();
      p.heard('hola'); // ear etapa 1
      p.answer('hola', Skill.mouth, ok: true);
      expect(p.openForSpeaking('hola'), isTrue);
      expect(wordsOpenForSpeaking(p), isEmpty);
    });
  });

  group('hablar: the entry to the voice test, the note', () {
    testWidgets(
      'with a label there is an entry that goes to VoiceTestRoute; without one there is none',
      (tester) async {
        Phone.android.use(tester);
        final w = await World.create(seed: 'todo');
        await tester.pumpWidget(tab(w));
        expect(find.text(devVoiceTestEntry), findsNothing);
        await tester.pumpWidget(tab(w, entry: devVoiceTestEntry));
        await tester.scrollUntilVisible(
          find.text(devVoiceTestEntry),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(find.text(devVoiceTestEntry));
        await tester.pump();
        expect(w.nav.routes, [const VoiceTestRoute()]);
        w.dispose();
      },
    );

    testWidgets(
      'notaHabla: a phone that can take a speaking turn is told nothing',
      (tester) async {
        Phone.android.use(tester);
        final can = await World.create(seed: 'todo');
        await tester.pumpWidget(tab(can, note: true));
        await settle(tester);
        expect(find.text(speechNoteText), findsNothing);
        expect(can.progress.setting('notaHabla'), isNull);
        can.dispose();
      },
    );

    testWidgets(
      'notaHabla: a phone that cannot is told once a day: kept in the settings, kept on screen while the app stays open, not again after a reload the same day, again the next day',
      (tester) async {
        Phone.android.use(tester);
        final cannot = await World.create(
          seed: 'todo',
          speech: FakeSpeechListener(isAvailable: false),
        );
        await tester.pumpWidget(tab(cannot, note: true));
        await settle(tester);
        expect(find.text(speechNoteText), findsOneWidget);
        expect(cannot.progress.setting('notaHabla'), '2026-11-19');
        // it stays while the app stays open
        await tester.pumpWidget(tab(cannot, note: true));
        await settle(tester);
        expect(find.text(speechNoteText), findsOneWidget);
        // after a reload the same day it does not come back; the next day it does
        resetSpeechNoteDay();
        await tester.pumpWidget(tab(cannot, note: true));
        await settle(tester);
        expect(find.text(speechNoteText), findsNothing);
        cannot.clock.advance(const Duration(days: 1));
        resetSpeechNoteDay();
        await tester.pumpWidget(tab(cannot, note: true));
        await settle(tester);
        expect(find.text(speechNoteText), findsOneWidget);
        expect(cannot.progress.setting('notaHabla'), '2026-11-20');
        cannot.dispose();
      },
    );

    testWidgets(
      'the note is not on the tab unless it is asked for (v=39 shows it in Yo)',
      (tester) async {
        Phone.android.use(tester);
        final w = await World.create(
          seed: 'todo',
          speech: FakeSpeechListener(isAvailable: false),
        );
        await tester.pumpWidget(tab(w));
        await settle(tester);
        expect(find.text(speechNoteText), findsNothing);
        w.dispose();
      },
    );
  });
}
