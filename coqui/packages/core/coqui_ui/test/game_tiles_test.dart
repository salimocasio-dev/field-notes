// The parts of Repaso's games: the word tile, the speaker tile, the tray, the streak chip, the sign.
import 'package:coqui_ui/coqui_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

Widget _app(Widget child, {bool still = false, double text = 1}) => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: coquiTheme(),
  home: Builder(
    builder: (context) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(disableAnimations: still, textScaler: TextScaler.linear(text)),
      child: ColoredBox(
        color: CoquiColors.lessonBg,
        child: Center(child: child),
      ),
    ),
  ),
);

Border? _border(WidgetTester t, Finder of) {
  final c = t
      .widgetList<Container>(
        find.descendant(of: of, matching: find.byType(Container)),
      )
      .firstWhere(
        (c) =>
            c.decoration is BoxDecoration &&
            (c.decoration! as BoxDecoration).border != null,
      );
  return (c.decoration! as BoxDecoration).border as Border?;
}

void main() {
  testWidgets(
    'a word tile: the word, 56 px high at least, a touch on it; its speaker is its own touch',
    (t) async {
      var taps = 0, heard = 0;
      await t.pumpWidget(
        _app(
          WordTile(
            word: 'puerta',
            onTap: () => taps++,
            onSpeaker: () => heard++,
          ),
        ),
      );
      expect(find.text('puerta'), findsOneWidget);
      expect(t.getSize(find.byType(WordTile)).height, greaterThanOrEqualTo(56));
      await t.tap(find.text('puerta'));
      expect((taps, heard), (1, 0));
      await t.tap(find.bySemanticsLabel('Hear the word'));
      expect((taps, heard), (1, 1));
      // no speaker when the word has no clip of its own
      await t.pumpWidget(_app(WordTile(word: 'mesa', onTap: () {})));
      expect(find.bySemanticsLabel('Hear the word'), findsNothing);
    },
  );

  testWidgets(
    'a tile\'s ring: the line, then 3 px green for right, red-orange for wrong, white for chosen',
    (t) async {
      for (final (ring, color, width) in [
        (ChoiceRing.none, CoquiColors.lessonLine, 1.5),
        (ChoiceRing.right, CoquiColors.lessonGreen, 3.0),
        (ChoiceRing.wrong, CoquiColors.lessonBad, 3.0),
        (ChoiceRing.selected, CoquiColors.optionSelected, 3.0),
      ]) {
        await t.pumpWidget(_app(WordTile(word: 'sol', ring: ring)));
        final b = _border(t, find.byType(WordTile))!;
        expect((b.top.color, b.top.width), (color, width), reason: '$ring');
      }
      // a right answer is never drawn in the wrong colour
      expect(CoquiColors.lessonGreen, isNot(CoquiColors.lessonBad));
    },
  );

  testWidgets(
    'waiting and dim tiles are faded; the check badge and the big sign show',
    (t) async {
      for (final (look, o) in [
        (TileLook.normal, 1.0),
        (TileLook.waiting, .5),
        (TileLook.dim, .35),
      ]) {
        await t.pumpWidget(_app(WordTile(word: 'sol', look: look)));
        expect(t.widget<Opacity>(find.byType(Opacity).first).opacity, o);
      }
      await t.pumpWidget(
        _app(WordTile(word: 'sol', check: true, sign: true), still: true),
      );
      expect(find.byType(TouchSign), findsOneWidget);
      expect(t.getSize(find.byType(TouchSign)).width, TouchSign.size);
    },
  );

  testWidgets('the sign moves, and is still with reduced motion', (t) async {
    await t.pumpWidget(_app(const TouchSign()));
    await t.pump(const Duration(milliseconds: 450));
    final moving = t.widget<Transform>(
      find.descendant(
        of: find.byType(TouchSign),
        matching: find.byType(Transform),
      ),
    );
    expect(moving.transform.getMaxScaleOnAxis(), greaterThan(1.01));
    await t.pumpWidget(_app(const TouchSign(), still: true));
    await t.pump(const Duration(milliseconds: 450));
    final still = t.widget<Transform>(
      find.descendant(
        of: find.byType(TouchSign),
        matching: find.byType(Transform),
      ),
    );
    expect(still.transform.getMaxScaleOnAxis(), 1);
    expect(t.hasRunningAnimations, isFalse);
  });

  testWidgets('a wrong tile shakes back once; not with reduced motion', (
    t,
  ) async {
    await t.pumpWidget(_app(const WordTile(word: 'sol', shake: 1)));
    await t.pump(const Duration(milliseconds: 60));
    expect(t.hasRunningAnimations, isTrue);
    await t.pumpAndSettle();
    await t.pumpWidget(
      _app(const WordTile(word: 'sol', shake: 2), still: true),
    );
    expect(find.byType(TweenAnimationBuilder<double>), findsNothing);
  });

  testWidgets(
    'a speaker tile: a speaker to touch, as wide as asked, 56 px high',
    (t) async {
      var n = 0;
      await t.pumpWidget(
        _app(SpeakerTile(onTap: () => n++, label: 'Sound 1', width: 96)),
      );
      expect(t.getSize(find.byType(SpeakerTile)), const Size(96, 56));
      await t.tap(find.bySemanticsLabel('Sound 1'));
      expect(n, 1);
      await t.pumpWidget(
        _app(
          const SpeakerTile(onTap: null, ring: ChoiceRing.right, check: true),
        ),
      );
      expect(
        _border(t, find.byType(SpeakerTile))!.top.color,
        CoquiColors.lessonGreen,
      );
    },
  );

  testWidgets(
    'a tray wraps its tiles, centred; with a line it keeps a tile\'s height empty',
    (t) async {
      await t.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => t.binding.setSurfaceSize(null));
      await t.pumpWidget(
        _app(
          SizedBox(
            width: 358,
            child: TileTray(
              children: [
                for (final w in [
                  'el',
                  'pájaro',
                  'come',
                  'pan',
                  'aquí',
                  'ahora',
                  'mesa',
                ])
                  WordTile(word: w, onTap: () {}),
              ],
            ),
          ),
        ),
      );
      final ys = {
        for (final e in find.byType(WordTile).evaluate())
          t.getTopLeft(find.byWidget(e.widget)).dy,
      };
      expect(ys.length, greaterThan(1)); // more than one row
      await t.pumpWidget(
        _app(
          const SizedBox(width: 358, child: TileTray(line: true, children: [])),
        ),
      );
      expect(t.getSize(find.byType(TileTray)).height, greaterThanOrEqualTo(72));
    },
  );

  testWidgets(
    'tiles hold at 1.3x text size: the word wraps inside, nothing overflows',
    (t) async {
      await t.pumpWidget(
        _app(
          SizedBox(
            width: 160,
            child: WordTile(
              word: '¿cómo estás?',
              onTap: () {},
              onSpeaker: () {},
              expand: true,
            ),
          ),
          text: 1.3,
        ),
      );
      expect(t.takeException(), isNull);
    },
  );

  testWidgets(
    'expand: the tile, its face and ring, as wide as its row; otherwise as wide as its word',
    (t) async {
      await t.pumpWidget(
        _app(
          SizedBox(
            width: 300,
            child: WordTile(
              word: 'sol',
              expand: true,
              onTap: () {},
              ring: ChoiceRing.right,
            ),
          ),
        ),
      );
      final face = find
          .descendant(
            of: find.byType(WordTile),
            matching: find.byType(Container),
          )
          .first;
      expect(t.getSize(face).width, 300);
      await t.pumpWidget(
        _app(
          SizedBox(
            width: 300,
            child: Center(
              child: WordTile(word: 'sol', onTap: () {}),
            ),
          ),
        ),
      );
      final narrow = find
          .descendant(
            of: find.byType(WordTile),
            matching: find.byType(Container),
          )
          .first;
      expect(t.getSize(narrow).width, lessThan(150));
    },
  );

  testWidgets('the streak chip: nothing under three, then "N in a row"', (
    t,
  ) async {
    await t.pumpWidget(_app(const StreakChip(count: 2)));
    expect(find.text('2 in a row'), findsNothing);
    await t.pumpWidget(_app(const StreakChip(count: 3)));
    expect(find.text('3 in a row'), findsOneWidget);
    expect(t.getSize(find.byType(StreakChip)).height, 32);
    await t.pumpWidget(_app(const StreakChip(count: 12)));
    expect(find.text('12 in a row'), findsOneWidget);
  });

  test('the new text styles are complete, with ligatures off', () {
    for (final s in [
      CoquiText.lessonTile,
      CoquiText.lessonHint,
      CoquiText.lessonChip,
    ]) {
      expect(s.inherit, isFalse);
      expect(s.fontFeatures, containsAll(coquiNoLigatures));
    }
    expect(CoquiText.lessonTile.fontSize, 20);
    expect(CoquiText.lessonHint.fontSize, 16);
  });
}
