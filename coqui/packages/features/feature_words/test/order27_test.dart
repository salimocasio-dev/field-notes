// Order 27: what the redesigned Palabras tab does (the pills, the Today tag, the Good list, Find a word, the place
// counts, the picture's scale, the stage names on the sheet), and that it holds at both phone sizes and with large text.
import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_ui/coqui_ui.dart';
import 'package:feature_words/src/find_box.dart';
import 'package:feature_words/src/word_tile.dart';
import 'package:feature_words/src/words_view.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support.dart';

Map<String, Object?> story(
  String title, {
  List<String> focus = const [],
  Map<String, String> lines = const {},
}) => {
  'title': title,
  'focus_words': focus,
  'back_again': const <String>[],
  'clips': {
    for (final e in lines.entries) e.key: {'who': 'abuela', 'text': e.value},
  },
};

/// Fourteen words in two places; pair words: every one but `con` and `está`.
Rig fourteen() {
  const one = ['casa', 'puerta', 'ventana', 'abuela', 'con', 'está', 'mamá'];
  const two = ['parque', 'perro', 'árbol', 'gato', 'sol', 'flor', 'niño'];
  final rig = Rig(
    course: madeCourse(
      places: [
        place('a', 1, 'La casa', ['s1']),
        place('b', 2, 'El parque', ['s2']),
      ],
      stories: {
        's1': story(
          'S1',
          focus: one,
          lines: {
            'l1': 'Abuela está en la casa con mamá.',
            'l2': 'Está aquí.',
            'l0': 'Esta sí.', // shorter, but "esta", not "está"
            'l3': 'Con el gato.',
          },
        ),
        's2': story('S2', focus: two),
      },
      pairs: [
        for (final w in [...one, ...two])
          if (w != 'con' && w != 'está') w,
      ],
    ),
  );
  rig.played('s1');
  rig.played('s2');
  for (final w in [...one, ...two]) {
    rig.word(w, ear: 3, due: 5);
  }
  return rig;
}

Finder pill(String label) => find.descendant(
  of: find.byType(SegmentedPills),
  matching: find.text(label),
);

List<String> todayTagged(WidgetTester tester) => [
  for (final t in tester.widgetList<WordTile>(find.byType(WordTile)))
    if (t.today) t.word,
];

void main() {
  group('the pills', () {
    testWidgets(
      'Today lists the words today\'s Repaso asks, in its order, and only those; in All their cards say "Today"',
      (tester) async {
        final rig = fourteen();
        // due, most overdue first: perro, casa; con is due but has no picture, so Repaso does not ask it
        rig.word('casa', ear: 3, due: -1);
        rig.word('perro', ear: 3, due: -2);
        rig.word('con', ear: 3, due: -3);
        await pumpTab(tester, rig);
        expect(repaso(tester).line, '2 words today · about 1 min');
        expect(find.text('14 words · 2 today · 0 good'), findsOneWidget);
        expect(todayTagged(tester)..sort(), ['casa', 'perro']);
        expect(find.byType(TodayTag), findsNWidgets(2));

        await tester.tap(pill('Today'));
        await tester.pumpAndSettle();
        expect(cardOrder(tester), ['perro', 'casa']);
        expect(placeHeadings(tester), isEmpty);
        expect(find.text('Repaso asks these 2 words today.'), findsOneWidget);
        expect(find.byType(TodayTag), findsNothing, reason: 'all are today');
        expect(rig.haptics.ticks, 1);

        await tester.tap(pill('All'));
        await tester.pumpAndSettle();
        expect(cardOrder(tester).length, 14);
      },
    );

    testWidgets('Today with nothing due says so and lists nothing', (
      tester,
    ) async {
      final rig = fourteen();
      await pumpTab(tester, rig);
      await tester.tap(pill('Today'));
      await tester.pumpAndSettle();
      expect(find.byType(WordTile), findsNothing);
      expect(find.text('Nothing comes back today.'), findsOneWidget);
    });

    testWidgets(
      'at most ten words are today\'s, as many as the Repaso card counts',
      (tester) async {
        final rig = fourteen();
        for (final w in ['casa', 'puerta', 'ventana', 'abuela', 'mamá']) {
          rig.word(w, ear: 3, due: -1);
        }
        for (final w in ['parque', 'perro', 'árbol', 'gato', 'sol', 'flor']) {
          rig.word(w, ear: 3, due: -2);
        }
        await pumpTab(tester, rig);
        expect(repaso(tester).line, '10 words today · about 2 min');
        expect(todayTagged(tester).length, 10);
        // the most overdue first: the six of El parque, then four of La casa
        await tester.tap(pill('Today'));
        await tester.pumpAndSettle();
        expect(cardOrder(tester).take(6).toSet(), {
          'parque',
          'perro',
          'árbol',
          'gato',
          'sol',
          'flor',
        });
        expect(cardOrder(tester).length, 10);
      },
    );

    testWidgets(
      'Good lists the words good by ear (stage 4), by place; with none it says how a word gets there',
      (tester) async {
        final rig = fourteen();
        await pumpTab(tester, rig);
        await tester.tap(pill('Good'));
        await tester.pumpAndSettle();
        expect(find.byType(WordTile), findsNothing);
        expect(
          find.text(
            'No word is good yet. A word is good once you get it right three times when it comes back, over two weeks or more.',
          ),
          findsOneWidget,
        );

        rig.word('gato', ear: 4, due: 20);
        rig.word('casa', ear: 4, mouth: 2, mouthN: 2, due: 20);
        await tester.pumpAndSettle();
        expect(cardOrder(tester), ['casa', 'gato']);
        expect(placeHeadings(tester), ['La casa', 'El parque']);
        expect(dots(tester, card('casa')), [4, 2]);
        // a place's line counts all its words, whatever the list shows
        expect(find.text('7 words · 1 good'), findsNWidgets(2));
      },
    );
  });

  testWidgets(
    'each place heading says how many words it has and how many are good',
    (tester) async {
      final rig = fourteen();
      rig.word('sol', ear: 4, due: 20);
      rig.word('flor', ear: 4, due: 20);
      await pumpTab(tester, rig);
      expect(placeHeadings(tester), ['La casa', 'El parque']);
      expect(find.text('7 words · 0 good'), findsOneWidget);
      expect(find.text('7 words · 2 good'), findsOneWidget);
      expect(find.text('14 words · 0 today · 2 good'), findsOneWidget);
    },
  );

  group('Find a word', () {
    testWidgets('no find button with twelve words or fewer', (tester) async {
      final rig = Rig(
        course: madeCourse(
          places: [
            place('a', 1, 'La casa', ['s1']),
          ],
          stories: {
            's1': story('S1', focus: ['casa', 'puerta']),
          },
        ),
      );
      rig.played('s1');
      rig.word('casa');
      rig.word('puerta');
      await pumpTab(tester, rig);
      expect(find.byType(FindButton), findsNothing);
      expect(find.byType(FindBox), findsNothing);
    });

    testWidgets(
      'the button opens the field; a part of a word finds it, accents and case aside; the button again closes it and lets every word back',
      (tester) async {
        final rig = fourteen();
        await pumpTab(tester, rig);
        expect(find.byType(FindBox), findsNothing);
        await tester.tap(find.byType(FindButton));
        await tester.pumpAndSettle();
        expect(find.byType(FindBox), findsOneWidget);
        // the add field is the other one
        final field = find.descendant(
          of: find.byType(FindBox),
          matching: find.byType(TextField),
        );
        expect(tester.widget<TextField>(field).autofocus, isTrue);

        await tester.enterText(field, 'ARBO');
        await tester.pumpAndSettle();
        expect(cardOrder(tester), ['árbol']);
        expect(placeHeadings(tester), ['El parque']);

        await tester.enterText(field, 'a');
        await tester.pumpAndSettle();
        expect(cardOrder(tester), [
          'casa',
          'puerta',
          'ventana',
          'abuela',
          'está',
          'mamá',
          'parque',
          'árbol',
          'gato',
        ]);

        await tester.enterText(field, 'xyz');
        await tester.pumpAndSettle();
        expect(find.byType(WordTile), findsNothing);
        expect(find.text('No word has "xyz" in it.'), findsOneWidget);

        // the clear button empties the field
        await tester.tap(find.bySemanticsLabel('Clear'));
        await tester.pumpAndSettle();
        expect(cardOrder(tester).length, 14);

        await tester.enterText(field, 'gato');
        await tester.pumpAndSettle();
        await tester.tap(find.byType(FindButton));
        await tester.pumpAndSettle();
        expect(find.byType(FindBox), findsNothing);
        expect(cardOrder(tester).length, 14);
      },
    );

    testWidgets('it finds within the pill chosen', (tester) async {
      final rig = fourteen();
      rig.word('gato', ear: 4, due: 20);
      rig.word('casa', ear: 4, due: 20);
      await pumpTab(tester, rig);
      await tester.tap(pill('Good'));
      await tester.tap(find.byType(FindButton));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.descendant(
          of: find.byType(FindBox),
          matching: find.byType(TextField),
        ),
        'ca',
      );
      await tester.pumpAndSettle();
      expect(cardOrder(tester), ['casa']);
    });
  });

  group('the cards', () {
    testWidgets(
      'a word with no picture shows the shortest line he heard it in with its own accents, the word bold in it',
      (tester) async {
        final rig = fourteen();
        await pumpTab(tester, rig);
        expect(tester.widget<WordTile>(card('está')).line, 'Está aquí.');
        expect(tester.widget<WordTile>(card('con')).line, 'Con el gato.');
        expect(tester.widget<WordTile>(card('casa')).line, isNull);
        final rich = tester
            .widgetList<RichText>(
              find.descendant(
                of: card('está'),
                matching: find.byType(RichText),
              ),
            )
            .firstWhere((r) => r.text.toPlainText() == 'Está aquí.');
        // Text.rich puts the card's span inside its own
        final outer = (rich.text as TextSpan).children!.single as TextSpan;
        final spans = outer.children!.cast<TextSpan>();
        expect(spans.first.text, 'Está');
        expect(spans.first.style!.fontWeight, FontWeight.w700);
      },
    );

    testWidgets(
      'a word heard in no line he can see: the panel holds the word, large, and the card does not say it twice',
      (tester) async {
        final rig = Rig(
          course: madeCourse(
            places: [
              place('a', 1, 'La casa', ['s1']),
            ],
            stories: {
              's1': story('S1', focus: ['toca']),
            },
          ),
        );
        rig.played('s1');
        rig.word('toca');
        await pumpTab(tester, rig);
        final t = find.descendant(
          of: card('toca'),
          matching: find.text('toca'),
        );
        expect(t, findsOneWidget);
        expect(tester.widget<Text>(t).style, CoquiText.cardWordLarge);
      },
    );

    test('the picture\'s scale: the largest that fits, or one more when that leaves it under 3/4 of the card', () {
      // 390 px phone, two cards of 171 px
      expect(WordPictureArea.scaleFor(171, 2), 2); // 1 would be 98 px of 171
      expect(WordPictureArea.scaleFor(171, 3), 2); // 131 px of 171
      // 412 px phone at 2.625: cards of 182 px
      expect(WordPictureArea.scaleFor(182, 2.625), 2); // 149 px of 182
      expect(WordPictureArea.scaleFor(156, 2), 2); // a 360 px phone
    });

    testWidgets(
      'every card of a grid has a top area of the same height, the picture at a whole scale; a picture wider than the card is cut at its sides',
      (tester) async {
        final rig = fourteen();
        await pumpTab(tester, rig, ratio: 2);
        final areas = find.byType(WordPictureArea);
        final h = tester.getSize(areas.first).height;
        expect(h, 104, reason: '104 picture px at 2 device px each, / 2');
        final cardW = tester.getSize(card('casa')).width;
        expect(tester.getSize(areas.first).width, cardW);
        final panel = find.descendant(
          of: card('con'),
          matching: find.byWidgetPredicate(
            (x) => x is ColoredBox && x.color == CoquiColors.coverFill,
          ),
        );
        expect(tester.getSize(panel).height, h);
      },
    );

    testWidgets(
      'a card says to a screen reader its word, its meters, and Today',
      (tester) async {
        final rig = fourteen();
        rig.word('casa', ear: 3, mouth: 1, mouthN: 1, due: -1);
        await pumpTab(tester, rig);
        expect(
          find.bySemanticsLabel(
            'casa: ear 3 of 4, mouth 1 of 4, in today\'s Repaso',
          ),
          findsOneWidget,
        );
        expect(
          find.bySemanticsLabel('gato: ear 3 of 4, mouth 0 of 4'),
          findsOneWidget,
        );
      },
    );
  });

  testWidgets('the word sheet names the stage of each meter', (tester) async {
    final rig = fourteen();
    rig.word('casa', ear: 3, mouth: 1, mouthN: 1, due: 2);
    rig.word('con', ear: 4, due: 20);
    await pumpTab(tester, rig);
    await tapCard(tester, 'casa');
    expect(inSheet(find.text('Holding')), findsOneWidget);
    expect(inSheet(find.text('Heard')), findsOneWidget);
    await tester.tap(find.byType(CoquiCloseButton));
    await tester.pumpAndSettle();
    await tapCard(tester, 'con');
    expect(inSheet(find.text('Good')), findsOneWidget);
    expect(inSheet(find.text('Not yet')), findsOneWidget);
    expect(
      [
        for (final n in [0, 1, 2, 3, 4]) stageName(n),
      ],
      ['Not yet', 'Heard', 'Found', 'Holding', 'Good'],
    );
  });

  group('sizes and text size', () {
    for (final (name, size, ratio) in [
      ('390 x 844', const Size(390, 844), 3.0),
      ('412 x 915', const Size(412, 915), 2.625),
      ('360 x 640', const Size(360, 640), 2.0),
    ]) {
      for (final scale in [1.0, 1.3, 2.0]) {
        testWidgets(
          '$name, text x$scale: no overflow, nothing wider than the screen',
          (tester) async {
            final rig = fourteen();
            rig.word('casa', ear: 3, due: -1);
            tester.platformDispatcher.textScaleFactorTestValue = scale;
            addTearDown(
              tester.platformDispatcher.clearTextScaleFactorTestValue,
            );
            await pumpTab(tester, rig, size: size, ratio: ratio);
            expect(tester.takeException(), isNull);
            await tester.tap(find.byType(FindButton));
            await tester.pumpAndSettle();
            for (final p in ['Today', 'Good', 'All']) {
              await tester.tap(pill(p));
              await tester.pumpAndSettle();
              expect(tester.takeException(), isNull, reason: p);
            }
            // (the fake picture's own label is left out: a picture may be cut at the card's sides)
            final skip = tester
                .widgetList<Text>(
                  find.descendant(
                    of: find.byType(WordPictureArea),
                    matching: find.byType(Text),
                  ),
                )
                .toSet();
            for (final t in tester.widgetList<Text>(find.byType(Text))) {
              if (skip.contains(t)) continue;
              final r = tester.getRect(find.byWidget(t));
              expect(r.right, lessThanOrEqualTo(size.width + 0.5));
              expect(r.left, greaterThanOrEqualTo(-0.5), reason: t.data);
            }
            await tapCard(tester, 'con');
            expect(tester.takeException(), isNull);
          },
        );
      }
    }

    testWidgets('with reduced motion the tab and its sheet work the same', (
      tester,
    ) async {
      final rig = fourteen();
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      await pumpTab(tester, rig);
      await tester.tap(pill('Today'));
      await tester.pumpAndSettle();
      await tester.tap(pill('All'));
      await tester.pumpAndSettle();
      await tapCard(tester, 'casa');
      expect(sheet, findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  test('matchesQuery ignores accents, case and punctuation', () {
    expect(matchesQuery('¿cómo estás?', 'como'), isTrue);
    expect(matchesQuery('¿cómo estás?', 'ESTAS'), isTrue);
    expect(matchesQuery('árbol', 'xyz'), isFalse);
    expect(matchesQuery('árbol', '  '), isTrue);
  });

  test(
    'shownGroups keeps place order and leaves out a place with no word left',
    () {
      WordEntry e(String w, {int ear = 3, bool today = false}) => WordEntry(
        WordRecord(
          w: w,
          primera: 0,
          ear: SkillRecord(etapa: ear),
        ),
        null,
        today: today,
      );
      final v = WordsView(
        groups: [
          PlaceGroup('A', [e('uno', ear: 4), e('dos', today: true)]),
          PlaceGroup('B', [e('tres', today: true)]),
        ],
        reviewText: '',
        reviewButton: '',
        reviewOff: false,
        practice: false,
        added: const [],
        todayWords: const ['tres', 'dos'],
      );
      expect(
        [for (final g in shownGroups(v, WordFilter.good, '')) g.name],
        ['A'],
      );
      final today = shownGroups(v, WordFilter.today, '');
      expect([for (final x in today.single.words) x.record.w], ['tres', 'dos']);
      expect(shownGroups(v, WordFilter.all, 'tr').single.name, 'B');
      expect(v.count, 3);
      expect(v.goodCount, 1);
    },
  );
}
