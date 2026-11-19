// The Hablar tab (app.html: hablar) and its notes, in the states of the reference pictures.
import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_testing/coqui_testing.dart';
import 'package:coqui_ui/coqui_ui.dart';
import 'package:feature_speaking/src/hablar_model.dart';
import 'package:feature_speaking/src/hablar_tab.dart';
import 'package:feature_speaking/src/speech_note.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/call_rig.dart';
import 'support/dev_app.dart' show devCallsLater, devVoiceTestEntry;
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

/// The note is read after the first frame and shown on the next: two frames.
Future<void> settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump();
}

Widget tab(World w, {String? callsLater, String? entry, bool note = false}) =>
    w.app(
      HablarTab(
        key: UniqueKey(), // a new tab each time: the note is read when the tab is made
        services: w.services,
        callsLater: callsLater,
        voiceTestLabel: entry,
        showSpeechNote: note,
      ),
    );

void main() {
  setUp(resetSpeechNoteDay);

  group('hablar: the cards', () {
    testWidgets(
      'nothing played: ten Call Danny cards, all locked; La casa says Opens when you finish La casa; no disc',
      (tester) async {
        Phone.android.use(tester);
        final w = await World.create(seed: 'vacio');
        await tester.pumpWidget(tab(w));
        expect(find.text('Call Danny'), findsNWidgets(10));
        expect(find.text('Opens when you finish La casa'), findsOneWidget);
        expect(find.byType(PlayButton), findsNothing);
        expect(find.textContaining('Coming soon'), findsNothing);
        // the old page's ten places, in place order, each with its own name
        for (final l in w.course.places.skip(1)) {
          expect(find.text('Opens when you finish ${l.name}'), findsOneWidget);
        }
        // the title is the tab's name
        expect(find.text('Hablar'), findsOneWidget);
        w.dispose();
      },
    );

    testWidgets('a touch on a locked card opens nothing', (tester) async {
      Phone.android.use(tester);
      final w = await World.create(seed: 'vacio');
      await tester.pumpWidget(tab(w));
      await tester.tap(find.text('Call Danny').first);
      await tester.pump();
      expect(w.nav.routes, isEmpty);
      expect(w.haptics.ticks, 0);
      w.dispose();
    });

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
      expect(find.byType(PlayButton), findsNothing);
      w.dispose();
    });

    testWidgets(
      'open: La casa\'s card is first and open, "Call Danny" / "La casa · about 5 min", a green 48 px disc; the places with all stories played and no call say Coming soon',
      (tester) async {
        Phone.android.use(tester);
        final w = await World.create(seed: 'todo');
        await tester.pumpWidget(tab(w));
        expect(find.byType(PlayButton), findsOneWidget);
        final disc = tester.getSize(find.byType(PlayButton));
        expect([disc.width, disc.height], [48, 48]);
        expect(find.text('La casa · about 5 min'), findsOneWidget);
        // first card
        final first = tester.getTopLeft(find.text('Call Danny').first).dy;
        final disc0 = tester.getCenter(find.byType(PlayButton)).dy;
        expect(disc0, lessThan(first + 80));
        expect(find.text('Coming soon · El parque'), findsOneWidget);
        expect(find.text('Coming soon · La cocina'), findsOneWidget);
        expect(find.text('Opens when you finish El colmado'), findsOneWidget);
        // the disc is green
        final decorated = tester.widget<Container>(
          find
              .descendant(
                of: find.byType(PlayButton),
                matching: find.byType(Container),
              )
              .first,
        );
        expect((decorated.decoration! as BoxDecoration).color, CoquiColors.ok);
        // the phone icon, and the label for a screen reader
        expect(find.bySemanticsLabel('Call Danny: La casa'), findsOneWidget);
        w.dispose();
      },
    );

    testWidgets(
      'a touch on the open card, or on its disc, goes to the call (once) with a tick',
      (tester) async {
        Phone.android.use(tester);
        final w = await World.create(seed: 'todo');
        await tester.pumpWidget(tab(w));
        await tester.tap(find.text('La casa · about 5 min'));
        await tester.pump();
        expect(w.nav.routes, [const CallRoute('casa')]);
        expect(w.haptics.ticks, 1);
        await tester.tap(find.byType(PlayButton));
        await tester.pump();
        expect(w.nav.routes, [
          const CallRoute('casa'),
          const CallRoute('casa'),
        ]);
        expect(w.haptics.ticks, 2);
        w.dispose();
      },
    );

    testWidgets(
      'the level check counts: after it, La casa\'s card is open (its 11 stories count as played)',
      (tester) async {
        Phone.android.use(tester);
        final w = await World.create(seed: 'nivel');
        await tester.pumpWidget(tab(w));
        expect(find.byType(PlayButton), findsOneWidget);
        expect(find.text('Opens when you finish El parque'), findsOneWidget);
        w.dispose();
      },
    );

    testWidgets(
      'mid-course: La casa open, El parque (begun) and La cocina locked',
      (tester) async {
        Phone.android.use(tester);
        final w = await World.create(seed: 'curso');
        await tester.pumpWidget(tab(w));
        expect(find.byType(PlayButton), findsOneWidget);
        expect(find.text('Opens when you finish El parque'), findsOneWidget);
        expect(find.text('Opens when you finish La cocina'), findsOneWidget);
        w.dispose();
      },
    );

    testWidgets(
      'the card opens as soon as the last story is played, with the tab showing',
      (tester) async {
        Phone.android.use(tester);
        final w = await World.create(seed: null);
        final stories = w.course.places.first.stories;
        for (final id in stories.take(10)) {
          w.progress.storyFinished(StoryResult(id: id));
        }
        await tester.pumpWidget(tab(w));
        expect(find.byType(PlayButton), findsNothing);
        w.progress.storyFinished(StoryResult(id: stories.last));
        await tester.pump();
        await tester.pump();
        expect(find.byType(PlayButton), findsOneWidget);
        w.dispose();
      },
    );

    testWidgets(
      'no horizontal overflow at the sizes of the old checks (no exception while laying out)',
      (tester) async {
        for (final phone in [Phone.android, Phone.iphone, Phone.small]) {
          phone.use(tester);
          final w = await World.create(seed: 'todo');
          await tester.pumpWidget(tab(w));
          expect(tester.takeException(), isNull, reason: phone.name);
          final box = tester.getRect(find.byType(TabPage));
          expect(box.right, lessThanOrEqualTo(phone.width), reason: phone.name);
          w.dispose();
        }
      },
    );
  });

  group('hablar: calls come later on this build', () {
    testWidgets(
      'call.available false: the open card is grey, has no disc and does not go to the call; it says the line it is given',
      (tester) async {
        Phone.android.use(tester);
        final w = await World.create(seed: 'todo', callAvailable: false);
        await tester.pumpWidget(tab(w, callsLater: devCallsLater));
        expect(find.byType(PlayButton), findsNothing);
        expect(find.text(devCallsLater), findsOneWidget);
        expect(find.text('La casa · about 5 min'), findsNothing);
        await tester.tap(find.text(devCallsLater));
        await tester.pump();
        expect(w.nav.routes, isEmpty);
        w.dispose();
      },
    );

    testWidgets('with no line given the card says nothing under its title', (
      tester,
    ) async {
      Phone.android.use(tester);
      final w = await World.create(seed: 'todo', callAvailable: false);
      await tester.pumpWidget(tab(w));
      expect(find.byType(PlayButton), findsNothing);
      expect(find.text('Call Danny'), findsNWidgets(10));
      w.dispose();
    });

    testWidgets(
      'the voice library is asked for only when an open card is shown (the old precarga)',
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

  group('hablar: words open for speaking', () {
    testWidgets('nothing met: the plain sentence', (tester) async {
      Phone.android.use(tester);
      final w = await World.create(seed: 'vacio');
      await tester.pumpWidget(tab(w));
      expect(find.text('Words open for speaking'), findsOneWidget);
      expect(
        find.text(
          'None yet. A word opens once your ear has held it for a few days.',
        ),
        findsOneWidget,
      );
      w.dispose();
    });

    testWidgets(
      'the words whose ear stage is 3 or more, in the order the store has them, with commas',
      (tester) async {
        Phone.android.use(tester);
        final w = await World.create(seed: 'todo');
        await tester.pumpWidget(tab(w));
        final open = [
          for (final r in w.progress.words)
            if (r.ear.etapa >= 3) r.w,
        ];
        expect(open.length, greaterThan(50));
        expect(find.text(open.join(', ')), findsOneWidget);
        expect(wordsOpenForSpeaking(w.progress), open);
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

  group('hablar: the cards without a widget', () {
    test('hablarCards: the old rule on a plain store', () async {
      final course = FixtureCourse();
      await course.load();
      final p = RecordingProgress();
      List<HablarCard> cards() =>
          hablarCards(course: course, progress: p, callsAvailable: () => true);
      expect(cards().map((k) => k.kind).toSet(), {HablarCardKind.locked});
      for (final l in course.places.take(3)) {
        for (final id in l.stories) {
          p.storyFinished(StoryResult(id: id));
        }
      }
      final k = cards();
      expect(k.map((c) => c.kind).take(4), [
        HablarCardKind.open,
        HablarCardKind.soon,
        HablarCardKind.soon,
        HablarCardKind.locked,
      ]);
      expect(k.first.minutes, 5);
      expect(k[1].subtitle, 'Coming soon · El parque');
    });
  });
}
