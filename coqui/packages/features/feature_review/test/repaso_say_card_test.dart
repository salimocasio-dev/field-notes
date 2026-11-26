// Issue #9: Speaking cards (Dilo) play and show the sentence the learner must say back, with the tested word
// highlighted from the moment it is asked, across every built place, while preserving real speech verification
// and zero layout shift.
import 'package:coqui_ui/coqui_ui.dart';
import 'package:feature_review/src/logic/repaso_plan.dart';
import 'package:feature_review/src/logic/repaso_session.dart';
import 'package:feature_review/src/logic/repaso_words.dart';
import 'package:feature_review/src/ui/noche_lesson_parts.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/repaso_course.dart';
import 'support/repaso_screen_rig.dart';

List<(String, Rect)> _geometry(WidgetTester t) {
  final out = <(String, Rect)>[];
  void add(String name, Finder f) {
    final n = f.evaluate().length;
    for (var i = 0; i < n; i++) {
      out.add(('$name[$i]', t.getRect(f.at(i))));
    }
  }

  add('instruction', find.byKey(const ValueKey('game-instruction')));
  add('chip', find.byType(NocheStreakChip));
  add('speaker', find.byType(NocheRoundSpeaker));
  add('prompt', find.byKey(const ValueKey('say-prompt')));
  add('mic', find.byKey(const ValueKey('noche_mic_disc')));
  add('reveal', find.byKey(const ValueKey('reveal')));
  add('next', find.byKey(const ValueKey('next-slot')));
  return out;
}

List<TextSpan> _highlightedSpans(WidgetTester t) {
  final richFinder = find.descendant(
    of: find.byKey(const ValueKey('say-sentence')),
    matching: find.byType(Text),
  );
  expect(richFinder, findsOneWidget);
  final rich = t.widget<Text>(richFinder);
  final root = rich.textSpan;
  expect(root, isA<TextSpan>());
  final out = <TextSpan>[];
  void walk(InlineSpan span) {
    if (span is TextSpan) {
      if (span.style?.backgroundColor == NocheColors.litSentence) {
        out.add(span);
      }
      for (final c in span.children ?? const <InlineSpan>[]) {
        walk(c);
      }
    }
  }

  walk(root!);
  return out;
}

void main() {
  testWidgets(
    'every built place (casa, parque, cocina) renders a clear speaking card before speaking and verifies speech',
    (t) async {
      final builtPlaces = {for (final w in realRepaso.words) w.place};
      expect(builtPlaces, {'casa', 'parque', 'cocina'});

      for (final place in ['casa', 'parque', 'cocina']) {
        final placeWords = [
          for (final w in realRepaso.words)
            if (w.place == place && w.say.isNotEmpty) w,
        ];
        expect(placeWords, isNotEmpty, reason: 'place $place has say words');

        final w = placeWords.first;
        final line = w.say.first;
        final speech = HeldSpeech();
        final sc = Screen(
          t,
          json: everythingJson(realRepaso),
          listener: speech,
        );
        await sc.open();
        sc.s.queue = [QueueEntry.play(SayItem(word: w.word, line: line))];
        await t.tap(find.byType(NochePlayDisc));
        await sc.settle();
        await sc.vt.runUntil(() => sc.s.mic == MicState.ready);
        await sc.settle();

        // Before speaking (mic == ready, showText == false)
        expect(sc.s.mic, MicState.ready, reason: place);
        expect(sc.s.showText, isFalse, reason: place);
        expect(
          find.text(gameInstruction(GameKind.say)),
          findsOneWidget,
          reason: place,
        );
        expect(gameInstruction(GameKind.say), 'Listen. Say the sentence back.');
        expect(find.byKey(const ValueKey('say-prompt')), findsOneWidget);
        expect(find.byKey(const ValueKey('say-target-word')), findsOneWidget);
        expect(find.byKey(const ValueKey('say-sentence')), findsOneWidget);

        // Target-word callout
        final callout = find.byKey(const ValueKey('say-target-word'));
        expect(
          find.descendant(
            of: callout,
            matching: find.text(RepasoStrings.sayTargetWord),
          ),
          findsOneWidget,
          reason: place,
        );
        expect(
          find.descendant(of: callout, matching: find.text(w.word)),
          findsOneWidget,
          reason: place,
        );

        // Full sentence preserved verbatim with target word highlighted
        final sentenceFinder = find.byKey(const ValueKey('say-sentence'));
        expect(
          find.descendant(
            of: sentenceFinder,
            matching: find.textContaining(line.text, findRichText: true),
          ),
          findsOneWidget,
          reason: place,
        );
        final at = findWord(line.text, w.word);
        expect(at, isNotNull, reason: '$place: ${w.word} in ${line.text}');
        final highlighted = _highlightedSpans(t);
        expect(highlighted, hasLength(1), reason: place);
        expect(
          highlighted.single.text,
          line.text.substring(at!.start, at.end),
          reason: place,
        );
        expect(
          highlighted.single.style?.backgroundColor,
          NocheColors.litSentence,
          reason: place,
        );
        expect(
          highlighted.single.style?.decorationColor,
          NocheColors.listening,
          reason: place,
        );

        // Plays target sentence clip, NOT before clip
        expect(
          sc.clips.plays.where((p) => p['id'] == line.clip),
          isNotEmpty,
          reason: '$place: plays target clip ${line.clip}',
        );
        expect(
          sc.clips.plays.where((p) => p['id'] == line.before),
          isEmpty,
          reason: '$place: does not play before clip ${line.before}',
        );

        // No self-report bypass button: only NocheMic and "Can't speak now"
        expect(find.textContaining('I said it'), findsNothing);
        expect(find.textContaining('Skip'), findsNothing);
        expect(find.byType(NocheMic), findsOneWidget);
        expect(
          t.widget<NocheMic>(find.byType(NocheMic)).state,
          NocheMicState.ready,
        );
        final buttons = find.byType(NocheOutlineButton);
        expect(buttons, findsOneWidget);
        expect(
          t.widget<NocheOutlineButton>(buttons).label,
          RepasoStrings.cantSpeak,
        );

        final beforeSpeaking = _geometry(t);

        // First attempt: wrong text -> no mouth answer, Try again, mic in notYet state (ready to tap again)
        await t.tap(find.byType(NocheMic));
        await sc.vt.runUntil(() => sc.s.mic == MicState.listening);
        await t.pump();
        expect(
          t.widget<NocheMic>(find.byType(NocheMic)).state,
          NocheMicState.listening,
        );
        speech.hear('algo');
        await sc.vt.runUntil(() => sc.s.notHeard && sc.s.mic == MicState.ready);
        await sc.settle();
        final mouthAfterMiss = sc.store.calls.where(
          (c) => c['op'] == 'responde' && (c['args'] as List)[1] == 'mouth',
        );
        expect(mouthAfterMiss, isEmpty, reason: place);
        expect(sc.s.canNext, isFalse, reason: place);
        expect(find.text('Heard: algo'), findsOneWidget, reason: place);
        expect(
          find.text(RepasoStrings.tryAgain),
          findsOneWidget,
          reason: place,
        );
        expect(sc.s.mic, MicState.ready, reason: place);
        expect(
          t.widget<NocheMic>(find.byType(NocheMic)).state,
          NocheMicState.notYet,
        );
        expect(_geometry(t), beforeSpeaking, reason: '$place after miss');

        // Second attempt: accepted form -> Mouth answer written (ok: true), green Heard, right NocheMic, Next shown
        await t.tap(find.byType(NocheMic));
        await sc.vt.runUntil(() => sc.s.mic == MicState.listening);
        final accepted = line.forms.first;
        speech.hear(accepted);
        await sc.vt.runUntil(() => sc.s.heardRight && sc.s.canNext);
        await sc.settle();

        final mouthAfterHit = sc.store.calls
            .where(
              (c) => c['op'] == 'responde' && (c['args'] as List)[1] == 'mouth',
            )
            .toList();
        expect(mouthAfterHit, hasLength(1), reason: place);
        expect((mouthAfterHit.single['args'] as List).sublist(0, 3), [
          w.word,
          'mouth',
          true,
        ], reason: place);
        final heardText = t.widget<Text>(find.text('Heard: $accepted'));
        expect(heardText.style?.color, NocheColors.right, reason: place);
        expect(
          t.widget<NocheMic>(find.byType(NocheMic)).state,
          NocheMicState.right,
        );
        expect(find.text(RepasoStrings.next), findsOneWidget, reason: place);

        // Zero layout shift before vs after speaking
        expect(_geometry(t), beforeSpeaking, reason: '$place after hit');
      }
    },
  );

  test('data coverage: every speaking line across all built places highlights its target word and has accepted forms', () {
    var totalLines = 0;
    final placesWithSay = <String>{};
    for (final w in realRepaso.words) {
      for (final line in w.say) {
        totalLines++;
        placesWithSay.add(w.place);
        expect(
          findWord(line.text, w.word),
          isNotNull,
          reason: '${w.place}/${w.word}: "${line.text}"',
        );
        expect(
          line.forms,
          isNotEmpty,
          reason: '${w.place}/${w.word}: "${line.text}" has no forms',
        );
      }
    }
    expect(placesWithSay, {'casa', 'parque', 'cocina'});
    expect(totalLines, 63);
  });

  testWidgets(
    'disambiguation: two words sharing the exact same sentence clearly display and highlight their distinct target word before speaking',
    (t) async {
      final pairs = [
        ('abre', 'puerta', 'abre_puerta_tu'),
        ('leche', 'no hay', 'c30_cq_no_leche'),
      ];
      for (final (wordA, wordB, clipId) in pairs) {
        final spans = <String, String>{};
        for (final (target, other) in [(wordA, wordB), (wordB, wordA)]) {
          final w = realRepaso.word(target)!;
          final line = w.say.firstWhere((l) => l.clip == clipId);
          final speech = HeldSpeech();
          final sc = Screen(
            t,
            json: everythingJson(realRepaso),
            listener: speech,
          );
          await sc.open();
          sc.s.queue = [QueueEntry.play(SayItem(word: w.word, line: line))];
          await t.tap(find.byType(NochePlayDisc));
          await sc.settle();
          await sc.vt.runUntil(() => sc.s.mic == MicState.ready);
          await sc.settle();

          final callout = find.byKey(const ValueKey('say-target-word'));
          expect(
            find.descendant(of: callout, matching: find.text(target)),
            findsOneWidget,
            reason: 'callout shows $target',
          );
          expect(
            find.descendant(of: callout, matching: find.text(other)),
            findsNothing,
            reason: 'callout does not show $other when testing $target',
          );

          final at = findWord(line.text, target)!;
          final expectedSpan = line.text.substring(at.start, at.end);
          final highlighted = _highlightedSpans(t);
          expect(highlighted, hasLength(1), reason: '$target on $clipId');
          expect(
            highlighted.single.text,
            expectedSpan,
            reason: '$target highlights "$expectedSpan"',
          );
          spans[target] = highlighted.single.text!;
        }
        expect(
          spans[wordA],
          isNot(spans[wordB]),
          reason: '$wordA and $wordB highlight distinct spans on $clipId',
        );
      }
    },
  );

  testWidgets(
    'accessibility: long target phrases on narrow widths (320 px, 360 px) at 1.3x text scale wrap cleanly without overflow or layout shift',
    (t) async {
      for (final (width, wordName) in [
        (320.0, '¿qué es esto?'),
        (320.0, 'hasta mañana'),
        (360.0, '¿cómo estás?'),
        (390.0, 'no hay'),
      ]) {
        final w = realRepaso.word(wordName)!;
        final line = w.say.first;
        final speech = HeldSpeech();
        final sc = Screen(
          t,
          json: everythingJson(realRepaso),
          listener: speech,
        );
        await sc.open(w: width, h: 844, dpr: 2, text: 1.3);
        sc.s.queue = [QueueEntry.play(SayItem(word: w.word, line: line))];
        await t.tap(find.byType(NochePlayDisc));
        await sc.settle();
        final asked = _geometry(t);
        await sc.vt.runUntil(() => sc.s.mic == MicState.ready);
        await sc.settle();

        final tag = '$wordName @ ${width.toInt()}px 1.3x';
        expect(t.takeException(), isNull, reason: tag);
        expect(find.byType(ErrorWidget), findsNothing, reason: tag);
        expect(find.byKey(const ValueKey('say-prompt')), findsOneWidget);
        expect(find.byType(NocheMic), findsOneWidget);
        expect(_highlightedSpans(t), hasLength(1), reason: tag);

        // Prompt fits cleanly inside the viewport width and above the mic
        final promptRect = t.getRect(find.byKey(const ValueKey('say-prompt')));
        final micRect = t.getRect(find.byType(NocheMic));
        expect(promptRect.left, greaterThanOrEqualTo(0), reason: tag);
        expect(promptRect.right, lessThanOrEqualTo(width + 0.01), reason: tag);
        expect(
          promptRect.bottom,
          lessThanOrEqualTo(micRect.top - 24 + 0.01),
          reason: tag,
        );

        // On narrow 320 px at 1.3x, the long target phrase wraps onto two lines below the label
        if (width <= 320) {
          final callout = find.byKey(const ValueKey('say-target-word'));
          final labelRect = t.getRect(
            find.descendant(
              of: callout,
              matching: find.text(RepasoStrings.sayTargetWord),
            ),
          );
          final wordRect = t.getRect(
            find.descendant(of: callout, matching: find.text(wordName)),
          );
          expect(
            wordRect.top,
            greaterThan(labelRect.top),
            reason: '$tag: callout wraps cleanly onto a second line',
          );
        }

        // Zero layout shift across asked -> ready -> miss -> hit (allowing uniform scroll shift inside SingleChildScrollView
        // when the wider Ahem test font places the mic below the fold at 320 px / 1.3x; Next's slot stays strictly fixed)
        void expectUnmoved(String stage) {
          final now = _geometry(t);
          expect(now.length, asked.length, reason: '$tag $stage');
          final dy = now.first.$2.top - asked.first.$2.top;
          for (var i = 0; i < now.length; i++) {
            final fixed = now[i].$1.startsWith('next');
            expect(
              now[i].$2,
              fixed ? asked[i].$2 : asked[i].$2.shift(Offset(0, dy)),
              reason: '$tag $stage: ${now[i].$1} moved',
            );
          }
        }

        expectUnmoved('ready');

        final mic = find.byType(NocheMic);
        await t.ensureVisible(mic);
        await t.pump();
        await t.tap(mic);
        await sc.vt.runUntil(() => sc.s.mic == MicState.listening);
        speech.hear('algo');
        await sc.vt.runUntil(() => sc.s.notHeard && sc.s.mic == MicState.ready);
        await sc.settle();
        expectUnmoved('after miss');

        await t.ensureVisible(mic);
        await t.pump();
        await t.tap(mic);
        await sc.vt.runUntil(() => sc.s.mic == MicState.listening);
        speech.hear(line.forms.first);
        await sc.vt.runUntil(() => sc.s.heardRight && sc.s.canNext);
        await sc.settle();
        expectUnmoved('after hit');
        expect(t.takeException(), isNull, reason: '$tag end');
      }
    },
  );
}
