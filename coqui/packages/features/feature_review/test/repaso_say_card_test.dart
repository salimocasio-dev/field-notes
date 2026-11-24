// Issue #9: Speaking cards (Dilo) play and show the sentence the learner must say back, with the tested word
// highlighted from the moment it is asked, across every built place, while preserving real speech verification
// and zero layout shift.
import 'package:coqui_ui/coqui_ui.dart';
import 'package:feature_review/src/logic/repaso_plan.dart';
import 'package:feature_review/src/logic/repaso_session.dart';
import 'package:feature_review/src/logic/repaso_words.dart';
import 'package:feature_review/src/ui/repaso_screen.dart';
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

  add(
    'instruction',
    find.byWidgetPredicate((w) => w is Text && w.style == CoquiText.lessonHint),
  );
  add('chip', find.byType(StreakChip));
  add('speaker', find.byType(RoundSpeaker));
  add('prompt', find.byKey(const ValueKey('say-prompt')));
  add('mic', find.byType(RepasoMic));
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
      if (span.style?.backgroundColor == CoquiColors.bookLineLit) {
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
        await t.tap(find.byType(LessonStartButton));
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
          CoquiColors.bookLineLit,
          reason: place,
        );
        expect(
          highlighted.single.style?.decorationColor,
          CoquiColors.bookLineLitBar,
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

        // No self-report bypass button: only RepasoMic and "Can't speak now"
        expect(find.textContaining('I said it'), findsNothing);
        expect(find.textContaining('Skip'), findsNothing);
        expect(find.byType(RepasoMic), findsOneWidget);
        final buttons = find.byType(LessonButton);
        expect(buttons, findsOneWidget);
        expect(t.widget<LessonButton>(buttons).label, RepasoStrings.cantSpeak);

        final beforeSpeaking = _geometry(t);

        // First attempt: wrong text -> no mouth answer, Try again, mic ready
        await t.tap(find.byType(RepasoMic));
        await sc.vt.runUntil(() => sc.s.mic == MicState.listening);
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
        expect(_geometry(t), beforeSpeaking, reason: '$place after miss');

        // Second attempt: accepted form -> Mouth answer written (ok: true), green Heard, check on mic, Next shown
        await t.tap(find.byType(RepasoMic));
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
        expect(heardText.style?.color, CoquiColors.heard, reason: place);
        final micCheck = find.descendant(
          of: find.byType(RepasoMic),
          matching: find.byWidgetPredicate(
            (widget) => widget is CoquiIcon && widget.data == CoquiIcons.check,
          ),
        );
        expect(micCheck, findsOneWidget, reason: place);
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
          await t.tap(find.byType(LessonStartButton));
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
    'accessibility: multi-word speaking cards render without overflow at 390x844 with 1.3x text scale',
    (t) async {
      for (final wordName in ['¿cómo estás?', 'no hay']) {
        final w = realRepaso.word(wordName)!;
        final line = w.say.first;
        final speech = HeldSpeech();
        final sc = Screen(
          t,
          json: everythingJson(realRepaso),
          listener: speech,
        );
        await sc.open(w: 390, h: 844, dpr: 2, text: 1.3);
        sc.s.queue = [QueueEntry.play(SayItem(word: w.word, line: line))];
        await t.tap(find.byType(LessonStartButton));
        await sc.settle();
        await sc.vt.runUntil(() => sc.s.mic == MicState.ready);
        await sc.settle();

        expect(t.takeException(), isNull, reason: wordName);
        expect(find.byType(ErrorWidget), findsNothing, reason: wordName);
        expect(find.byKey(const ValueKey('say-prompt')), findsOneWidget);
        expect(find.byType(RepasoMic), findsOneWidget);
        expect(_highlightedSpans(t), hasLength(1), reason: wordName);
      }
    },
  );
}
