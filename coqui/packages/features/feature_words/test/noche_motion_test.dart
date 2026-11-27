@TestOn('vm')
library;

import 'package:coqui_testing/coqui_testing.dart';
import 'package:coqui_ui/coqui_ui.dart';
import 'package:feature_words/src/motion.dart';
import 'package:feature_words/src/wording.dart';
import 'package:feature_words/src/words_tab.dart';
import 'package:feature_words/src/words_view.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support.dart';

Future<void> _pumpWordsArrival(
  WidgetTester tester,
  Rig rig, {
  bool disableAnimations = false,
  WordsSkill initialSkill = WordsSkill.listening,
  Size size = const Size(390, 844),
  double ratio = 3,
}) async {
  tester.view.physicalSize = size * ratio;
  tester.view.devicePixelRatio = ratio;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      theme: coquiTheme(),
      builder: disableAnimations
          ? (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(disableAnimations: true),
              child: child!,
            )
          : null,
      home: Scaffold(
        backgroundColor: NocheColors.ground,
        body: WordsTab(services: rig.services, initialSkill: initialSkill),
      ),
    ),
  );

  // Pump zero-duration frames until `_load()` populates `_view` and mounts
  // `NocheBarChart` and `NocheArrive`, anchoring animation tickers at t = 0.
  for (var i = 0; i < 8; i++) {
    await tester.pump();
    if (find.byType(NocheBarChart).evaluate().isNotEmpty) {
      break;
    }
  }
  expect(find.byType(NocheBarChart), findsOneWidget);
  expect(find.byKey(const Key('words-review-button')), findsOneWidget);
  // Anchor started tickers at elapsed = 0 without advancing the fake clock.
  await tester.pump();
}

double _tx(WidgetTester tester, Finder f) =>
    tester.widget<Transform>(f).transform.getTranslation().x;

double _ty(WidgetTester tester, Finder f) =>
    tester.widget<Transform>(f).transform.getTranslation().y;

double _descendantOpacity(WidgetTester tester, Finder ancestor) => tester
    .widget<Opacity>(
      find.descendant(of: ancestor, matching: find.byType(Opacity)).first,
    )
    .opacity;

double _ancestorOpacity(WidgetTester tester, Finder child) => tester
    .widget<Opacity>(
      find.ancestor(of: child, matching: find.byType(Opacity)).first,
    )
    .opacity;

double _barClipFraction(WidgetTester tester, int index) =>
    tester
        .widget<ClipRRect>(find.byKey(ValueKey('noche_bar_clip_$index')))
        .clipper!
        .getClip(const Size(20, 100))
        .height /
    100.0;

Rig _buildSpanishRig() {
  final rig = Rig(
    course: madeCourse(
      places: [
        place('casa', 1, 'La casa', ['s1']),
      ],
      stories: {
        's1': {
          'title': 'La cocina',
          'focus_words': [
            'la cuchara',
            'la leche',
            'la mesa',
            'el vaso',
            'el pan',
          ],
          'clips': {},
        },
      },
      pairs: ['la cuchara', 'la leche', 'la mesa', 'el vaso', 'el pan'],
    ),
  );
  rig.played('s1');
  // Five listening words spanning all 5 return buckets + 2 speaking words.
  rig.word('la cuchara', ear: 2, due: 0, mouth: 2, mouthN: 2, mouthDue: 0);
  rig.word('la leche', ear: 2, due: 1, mouth: 4, mouthN: 4, mouthDue: 3);
  rig.word('la mesa', ear: 3, due: 3);
  rig.word('el vaso', ear: 3, due: 5);
  rig.word('el pan', ear: 4, due: 21);
  return rig;
}

Rig _buildArabicRig() {
  final rig = Rig(course: FakeCourseCatalog.arabic());
  rig.played('la-lluvia');
  rig.word('باب', ear: 2, due: 0, mouth: 2, mouthN: 2, mouthDue: 0);
  rig.word('مرحباً', ear: 2, due: 1, mouth: 4, mouthN: 3, mouthDue: 3);
  rig.word('شمس', ear: 3, due: 5);
  rig.word('بيت', ear: 4, due: 21);
  return rig;
}

Rig _build96ListeningRig() {
  final words = [for (var i = 1; i <= 96; i++) 'palabra $i'];
  final rig = Rig(
    course: madeCourse(
      places: [
        place('casa', 1, 'La casa', ['s1']),
      ],
      stories: {
        's1': {'title': 'La cocina', 'focus_words': words, 'clips': {}},
      },
      pairs: words.take(10).toList(),
    ),
  );
  rig.played('s1');
  for (var i = 0; i < words.length; i++) {
    rig.word(words[i], ear: 1 + (i % 4), due: (i % 15).toDouble());
  }
  return rig;
}

Future<void> _verifySkillSwitch(
  WidgetTester tester, {
  required String tapLabel,
  required double expectedSign,
  required VoidCallback verifySettledContent,
}) async {
  final incoming = find.byKey(const ValueKey('noche_follow_incoming'));
  final outgoing = find.byKey(const ValueKey('noche_follow_outgoing'));

  await tester.tap(find.text(tapLabel));
  // Anchor the NocheFollow animation ticker at elapsed = 0.
  await tester.pump();
  // Start: midway through followAfter wait.
  await tester.pump(NocheMotion.followAfter ~/ 2);

  expect(outgoing, findsOneWidget);
  final outOpacity = tester.widget<Opacity>(outgoing).opacity;
  expect(outOpacity, greaterThan(0.0));
  expect(outOpacity, lessThan(1.0));

  expect(
    _tx(tester, incoming),
    closeTo(expectedSign * WordsMotion.skillListDistance, 0.01),
  );
  expect(_descendantOpacity(tester, incoming), closeTo(0.0, 0.01));

  // Middle: followAfter + move / 2 (170 ms >= press 90 ms, so outgoing is gone).
  await tester.pump(
    NocheMotion.followAfter -
        (NocheMotion.followAfter ~/ 2) +
        (NocheMotion.move ~/ 2),
  );

  expect(outgoing, findsNothing);
  final expectedP = NocheMotion.enter.transform(0.5);
  expect(
    _tx(tester, incoming),
    closeTo(
      expectedSign * WordsMotion.skillListDistance * (1 - expectedP),
      0.8,
    ),
  );
  expect(_descendantOpacity(tester, incoming), closeTo(expectedP, 0.04));

  // End: settled cleanly.
  await tester.pumpAndSettle();
  expect(outgoing, findsNothing);
  expect(_tx(tester, incoming), closeTo(0.0, 0.01));
  expect(_descendantOpacity(tester, incoming), closeTo(1.0, 0.01));
  verifySettledContent();
}

Future<void> _verifyReducedSkillSwitch(
  WidgetTester tester, {
  required String tapLabel,
  required VoidCallback verifySettledContent,
}) async {
  final incoming = find.byKey(const ValueKey('noche_follow_incoming'));

  await tester.tap(find.text(tapLabel));
  await tester.pump();

  // Start: during followAfter, zero horizontal travel and opacity 0.
  await tester.pump(NocheMotion.followAfter ~/ 2);
  expect(_tx(tester, incoming), closeTo(0.0, 0.01));
  expect(_descendantOpacity(tester, incoming), closeTo(0.0, 0.01));

  // Middle: followAfter + quick / 2, zero travel and opacity fading in quick.
  await tester.pump(
    NocheMotion.followAfter -
        (NocheMotion.followAfter ~/ 2) +
        (NocheMotion.quick ~/ 2),
  );
  final expectedP = NocheMotion.enter.transform(0.5);
  expect(_tx(tester, incoming), closeTo(0.0, 0.01));
  expect(_descendantOpacity(tester, incoming), closeTo(expectedP, 0.04));

  // End: settled cleanly.
  await tester.pumpAndSettle();
  expect(_tx(tester, incoming), closeTo(0.0, 0.01));
  expect(_descendantOpacity(tester, incoming), closeTo(1.0, 0.01));
  verifySettledContent();
}

void main() {
  group('N8.10 Words motion', () {
    testWidgets(
      'Spanish (LTR) skill switches slide from end on forward and start on backward',
      (tester) async {
        final rig = _buildSpanishRig();
        await _pumpWordsArrival(tester, rig);
        await tester.pumpAndSettle();

        expect(
          Directionality.of(tester.element(find.byKey(const Key('words-tab')))),
          TextDirection.ltr,
        );

        final listeningLabel = WordsWording.listeningTab(1);
        final speakingLabel = WordsWording.speakingTab(1);
        const readingLabel = WordsWording.readingLockedTab;

        // Forward: Listening -> Speaking (+tab)
        await _verifySkillSwitch(
          tester,
          tapLabel: speakingLabel,
          expectedSign: 1.0,
          verifySettledContent: () {
            expect(rowOrder(tester), ['la cuchara', 'la leche']);
          },
        );

        // Forward: Speaking -> Reading (+tab)
        await _verifySkillSwitch(
          tester,
          tapLabel: readingLabel,
          expectedSign: 1.0,
          verifySettledContent: () {
            expect(
              find.text(WordsWording.readingLockedMessage),
              findsOneWidget,
            );
            expect(rowOrder(tester), isEmpty);
          },
        );

        // Backward: Reading -> Speaking (-tab)
        await _verifySkillSwitch(
          tester,
          tapLabel: speakingLabel,
          expectedSign: -1.0,
          verifySettledContent: () {
            expect(rowOrder(tester), ['la cuchara', 'la leche']);
          },
        );

        // Backward: Speaking -> Listening (-tab)
        await _verifySkillSwitch(
          tester,
          tapLabel: listeningLabel,
          expectedSign: -1.0,
          verifySettledContent: () {
            expect(rowOrder(tester), [
              'la cuchara',
              'la leche',
              'la mesa',
              'el vaso',
              'el pan',
            ]);
          },
        );

        // Forward skip: Listening -> Reading (+tab)
        await _verifySkillSwitch(
          tester,
          tapLabel: readingLabel,
          expectedSign: 1.0,
          verifySettledContent: () {
            expect(
              find.text(WordsWording.readingLockedMessage),
              findsOneWidget,
            );
          },
        );

        // Backward skip: Reading -> Listening (-tab)
        await _verifySkillSwitch(
          tester,
          tapLabel: listeningLabel,
          expectedSign: -1.0,
          verifySettledContent: () {
            expect(rowOrder(tester), [
              'la cuchara',
              'la leche',
              'la mesa',
              'el vaso',
              'el pan',
            ]);
          },
        );
      },
    );

    testWidgets(
      'Arabic (RTL) skill switches mirror travel direction in both orders',
      (tester) async {
        final rig = _buildArabicRig();
        await _pumpWordsArrival(tester, rig);
        await tester.pumpAndSettle();

        expect(
          Directionality.of(tester.element(find.byKey(const Key('words-tab')))),
          TextDirection.rtl,
        );

        final listeningLabel = WordsWording.listeningTab(1);
        final speakingLabel = WordsWording.speakingTab(1);
        const readingLabel = WordsWording.readingLockedTab;

        // Forward in RTL: Listening -> Speaking (-tab, end side in RTL)
        await _verifySkillSwitch(
          tester,
          tapLabel: speakingLabel,
          expectedSign: -1.0,
          verifySettledContent: () {
            expect(rowOrder(tester), ['باب', 'مرحباً']);
          },
        );

        // Forward in RTL: Speaking -> Reading (-tab)
        await _verifySkillSwitch(
          tester,
          tapLabel: readingLabel,
          expectedSign: -1.0,
          verifySettledContent: () {
            expect(
              find.text(WordsWording.readingLockedMessage),
              findsOneWidget,
            );
            expect(rowOrder(tester), isEmpty);
          },
        );

        // Backward in RTL: Reading -> Speaking (+tab, start side in RTL)
        await _verifySkillSwitch(
          tester,
          tapLabel: speakingLabel,
          expectedSign: 1.0,
          verifySettledContent: () {
            expect(rowOrder(tester), ['باب', 'مرحباً']);
          },
        );

        // Backward in RTL: Speaking -> Listening (+tab)
        await _verifySkillSwitch(
          tester,
          tapLabel: listeningLabel,
          expectedSign: 1.0,
          verifySettledContent: () {
            expect(rowOrder(tester), ['باب', 'مرحباً', 'شمس', 'بيت']);
          },
        );

        // Forward skip in RTL: Listening -> Reading (-tab)
        await _verifySkillSwitch(
          tester,
          tapLabel: readingLabel,
          expectedSign: -1.0,
          verifySettledContent: () {
            expect(
              find.text(WordsWording.readingLockedMessage),
              findsOneWidget,
            );
          },
        );

        // Backward skip in RTL: Reading -> Listening (+tab)
        await _verifySkillSwitch(
          tester,
          tapLabel: listeningLabel,
          expectedSign: 1.0,
          verifySettledContent: () {
            expect(rowOrder(tester), ['باب', 'مرحباً', 'شمس', 'بيت']);
          },
        );
      },
    );

    testWidgets(
      'tall-to-short skill switch (96 words -> Reading A2 -> Listening) has zero overflow',
      (tester) async {
        final rig = _build96ListeningRig();
        await _pumpWordsArrival(tester, rig);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        final step = NocheMotion.press ~/ 3;
        final totalSteps =
            ((NocheMotion.followAfter + NocheMotion.move).inMilliseconds /
                    step.inMilliseconds)
                .ceil() +
            2;

        // 96-word Listening -> Reading A2 gate message.
        await tester.tap(find.text(WordsWording.readingLockedTab));
        await tester.pump();
        for (var i = 0; i < totalSteps; i++) {
          await tester.pump(step);
          expect(
            tester.takeException(),
            isNull,
            reason: 'Listening -> Reading step $i overflowed',
          );
        }
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text(WordsWording.readingLockedMessage), findsOneWidget);

        // Reading A2 -> 96-word Listening.
        await tester.tap(find.text(WordsWording.listeningTab(24)));
        await tester.pump();
        for (var i = 0; i < totalSteps; i++) {
          await tester.pump(step);
          expect(
            tester.takeException(),
            isNull,
            reason: 'Reading -> Listening step $i overflowed',
          );
        }
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(wordRow('palabra 1'), findsOneWidget);
      },
    );

    testWidgets(
      'chart bars grow in staggered order and Start review lands last on arrival; skill switch does not replay arrival',
      (tester) async {
        final rig = _buildSpanishRig();
        await _pumpWordsArrival(tester, rig);

        final arriveNext = find.byKey(const ValueKey('noche_arrive_next'));

        // t = 0: all 5 bars at clip 0.0; Start review at dy = row, opacity = 0.0.
        for (var i = 0; i < 5; i++) {
          expect(_barClipFraction(tester, i), closeTo(0.0, 0.01));
        }
        expect(_ty(tester, arriveNext), closeTo(NocheMotion.row, 0.01));
        expect(_descendantOpacity(tester, arriveNext), closeTo(0.0, 0.01));

        // Before rowsAfter (e.g. 60 ms): still waiting.
        await tester.pump(WordsMotion.reviewActionDelay);
        for (var i = 0; i < 5; i++) {
          expect(_barClipFraction(tester, i), closeTo(0.0, 0.01));
        }
        expect(_ty(tester, arriveNext), closeTo(NocheMotion.row, 0.01));
        expect(_descendantOpacity(tester, arriveNext), closeTo(0.0, 0.01));

        // At t = reviewActionDelay + nextDelay (140 ms):
        // Bar 0 started at chartArrivalDelay (120 ms) so it is already growing,
        // while Start review is still at start (landing last after nextDelay).
        await tester.pump(NocheMotion.nextDelay);
        expect(_barClipFraction(tester, 0), greaterThan(0.0));
        expect(_ty(tester, arriveNext), closeTo(NocheMotion.row, 0.01));
        expect(_descendantOpacity(tester, arriveNext), closeTo(0.0, 0.01));

        // At t = 250 ms (140 ms + move / 2):
        // All 5 bars are growing in strictly staggered order, and Start review is mid-rise.
        await tester.pump(NocheMotion.move ~/ 2);
        final fracs = [for (var i = 0; i < 5; i++) _barClipFraction(tester, i)];
        for (var i = 0; i < 5; i++) {
          expect(
            fracs[i],
            greaterThan(0.0),
            reason: 'bar $i should have started',
          );
          expect(
            fracs[i],
            lessThan(1.0),
            reason: 'bar $i should still be growing',
          );
        }
        for (var i = 0; i < 4; i++) {
          expect(
            fracs[i],
            greaterThan(fracs[i + 1]),
            reason: 'bar $i should lead bar ${i + 1}',
          );
        }

        final midDy = _ty(tester, arriveNext);
        final midOpacity = _descendantOpacity(tester, arriveNext);
        expect(midDy, greaterThan(0.0));
        expect(midDy, lessThan(NocheMotion.row));
        expect(midOpacity, greaterThan(0.0));
        expect(midOpacity, lessThan(1.0));

        // End: all 5 bars at 1.0, Start review at dy = 0, opacity = 1.0.
        await tester.pumpAndSettle();
        for (var i = 0; i < 5; i++) {
          expect(_barClipFraction(tester, i), closeTo(1.0, 0.01));
        }
        expect(_ty(tester, arriveNext), closeTo(0.0, 0.01));
        expect(_descendantOpacity(tester, arriveNext), closeTo(1.0, 0.01));

        // Switching skills afterward does NOT restart bar growth or Start review arrival.
        await tester.tap(find.text(WordsWording.speakingTab(1)));
        await tester.pump();
        await tester.pump(NocheMotion.followAfter ~/ 2);
        for (var i = 0; i < 5; i++) {
          expect(_barClipFraction(tester, i), closeTo(1.0, 0.01));
        }
        expect(_ty(tester, arriveNext), closeTo(0.0, 0.01));
        expect(_descendantOpacity(tester, arriveNext), closeTo(1.0, 0.01));
        await tester.pumpAndSettle();
      },
    );

    testWidgets(
      'reduced motion removes travel and stagger on arrival and skill switches (LTR and RTL)',
      (tester) async {
        // 1. Arrival under reduced motion (Spanish LTR).
        final esRig = _buildSpanishRig();
        await _pumpWordsArrival(tester, esRig, disableAnimations: true);

        final arriveNext = find.byKey(const ValueKey('noche_arrive_next'));

        // Frame 0: bars have clip fraction 1.0 (no height growth) and opacity 0;
        // Start review has dy = 0 (zero travel) and opacity 0.
        for (var i = 0; i < 5; i++) {
          expect(_barClipFraction(tester, i), closeTo(1.0, 0.01));
          expect(
            _ancestorOpacity(tester, find.byKey(ValueKey('noche_bar_clip_$i'))),
            closeTo(0.0, 0.01),
          );
        }
        expect(_ty(tester, arriveNext), closeTo(0.0, 0.01));
        expect(_descendantOpacity(tester, arriveNext), closeTo(0.0, 0.01));

        // At reviewActionDelay + quick / 2 (130 ms, before normal nextStart 140 ms):
        // Start review is already mid-fade in place with zero nextDelay and dy = 0.
        await tester.pump(
          WordsMotion.reviewActionDelay + (NocheMotion.quick ~/ 2),
        );
        expect(_ty(tester, arriveNext), closeTo(0.0, 0.01));
        expect(
          _descendantOpacity(tester, arriveNext),
          closeTo(NocheMotion.enter.transform(0.5), 0.04),
        );

        // At chartArrivalDelay + quick / 2 (190 ms):
        // All 5 bars keep clip fraction 1.0 and share identical opacity (no stagger).
        await tester.pump(
          WordsMotion.chartArrivalDelay - WordsMotion.reviewActionDelay,
        );
        final barOpacities = <double>[];
        for (var i = 0; i < 5; i++) {
          expect(_barClipFraction(tester, i), closeTo(1.0, 0.01));
          barOpacities.add(
            _ancestorOpacity(tester, find.byKey(ValueKey('noche_bar_clip_$i'))),
          );
        }
        final expectedBarOp = NocheMotion.enter.transform(0.5);
        for (var i = 0; i < 5; i++) {
          expect(barOpacities[i], closeTo(expectedBarOp, 0.04));
          expect(barOpacities[i], closeTo(barOpacities[0], 0.001));
        }

        await tester.pumpAndSettle();

        // Skill switches in Spanish (LTR) under reduced motion: forward & backward.
        await _verifyReducedSkillSwitch(
          tester,
          tapLabel: WordsWording.speakingTab(1),
          verifySettledContent: () {
            expect(rowOrder(tester), ['la cuchara', 'la leche']);
          },
        );
        await _verifyReducedSkillSwitch(
          tester,
          tapLabel: WordsWording.listeningTab(1),
          verifySettledContent: () {
            expect(rowOrder(tester), [
              'la cuchara',
              'la leche',
              'la mesa',
              'el vaso',
              'el pan',
            ]);
          },
        );

        // 2. Skill switches in Arabic (RTL) under reduced motion: forward & backward.
        await tester.pumpWidget(const SizedBox.shrink());
        final arRig = _buildArabicRig();
        await _pumpWordsArrival(tester, arRig, disableAnimations: true);
        await tester.pumpAndSettle();
        expect(
          Directionality.of(tester.element(find.byKey(const Key('words-tab')))),
          TextDirection.rtl,
        );

        await _verifyReducedSkillSwitch(
          tester,
          tapLabel: WordsWording.speakingTab(1),
          verifySettledContent: () {
            expect(rowOrder(tester), ['باب', 'مرحباً']);
          },
        );
        await _verifyReducedSkillSwitch(
          tester,
          tapLabel: WordsWording.listeningTab(1),
          verifySettledContent: () {
            expect(rowOrder(tester), ['باب', 'مرحباً', 'شمس', 'بيت']);
          },
        );
      },
    );

    testWidgets(
      'stable widget keys contract holds in Spanish (LTR) and Arabic (RTL)',
      (tester) async {
        final esRig = _buildSpanishRig();
        await pumpTab(tester, esRig);
        expect(find.byKey(const Key('words-tab')), findsOneWidget);
        expect(
          Directionality.of(tester.element(find.byKey(const Key('words-tab')))),
          TextDirection.ltr,
        );
        expect(find.byKey(const Key('words-due-count')), findsOneWidget);
        expect(dueCardCount(tester), '1');
        expect(find.byKey(const Key('words-review-button')), findsOneWidget);
        expect(
          find.byKey(const ValueKey('word-row:la cuchara')),
          findsOneWidget,
        );

        await tester.pumpWidget(const SizedBox.shrink());

        final arRig = _buildArabicRig();
        await pumpTab(tester, arRig);
        expect(find.byKey(const Key('words-tab')), findsOneWidget);
        expect(
          Directionality.of(tester.element(find.byKey(const Key('words-tab')))),
          TextDirection.rtl,
        );
        expect(find.byKey(const Key('words-due-count')), findsOneWidget);
        expect(dueCardCount(tester), '1');
        expect(find.byKey(const Key('words-review-button')), findsOneWidget);
        expect(find.byKey(const ValueKey('word-row:باب')), findsOneWidget);
      },
    );
  });
}
