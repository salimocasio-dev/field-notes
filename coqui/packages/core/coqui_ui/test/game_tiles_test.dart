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

/// Whether [inner] is wholly inside [outer].
bool _contains(Rect outer, Rect inner) =>
    inner.left >= outer.left &&
    inner.top >= outer.top &&
    inner.right <= outer.right &&
    inner.bottom <= outer.bottom;

Border? _border(WidgetTester t, Finder of) {
  final c = t
      .widgetList<Container>(
        find.descendant(of: of, matching: find.byType(Container)),
      )
      .firstWhere(
        (c) =>
            c.foregroundDecoration is BoxDecoration &&
            (c.foregroundDecoration! as BoxDecoration).border != null,
      );
  return (c.foregroundDecoration! as BoxDecoration).border as Border?;
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

  testWidgets(
    'the sign is the pointing hand (touch_app) white on a green disc, at the right end of its word tile, and takes no touch',
    (t) async {
      var taps = 0;
      await t.pumpWidget(
        _app(
          SizedBox(
            width: 300,
            child: WordTile(
              word: 'puerta',
              expand: true,
              sign: true,
              onTap: () => taps++,
            ),
          ),
          still: true,
        ),
      );
      // the hand, not a chevron or an arrow
      final icon = t.widget<CoquiIcon>(
        find.descendant(
          of: find.byType(TouchSign),
          matching: find.byType(CoquiIcon),
        ),
      );
      expect(icon.data, same(CoquiIcons.touchApp));
      expect(icon.color, CoquiColors.lessonInk);
      final disc =
          t
                  .widget<Container>(
                    find
                        .descendant(
                          of: find.byType(TouchSign),
                          matching: find.byType(Container),
                        )
                        .first,
                  )
                  .decoration!
              as BoxDecoration;
      expect(
        (disc.shape, disc.color),
        (BoxShape.circle, CoquiColors.lessonGreen),
      );
      // the right end of the tile, inside it, level with its middle: the middle is the word's
      final tile = t.getRect(find.byType(WordTile));
      final sign = t.getRect(find.byType(TouchSign));
      expect(sign.center.dy, closeTo(tile.center.dy, .5));
      expect(tile.right - sign.right, 6);
      expect(tile.contains(sign.topLeft), isTrue);
      expect(tile.contains(sign.bottomRight), isTrue);
      // a touch on the sign is a touch on the tile, and so is one on the word
      await t.tapAt(sign.center);
      expect(taps, 1);
      await t.tapAt(tile.center);
      expect(taps, 2);
    },
  );

  // the two phones the app is checked on, and the large text size
  const phones = [(390.0, 844.0), (412.0, 915.0)];
  const sizes = [1.0, 1.6];

  /// Shows [tile] on a phone of [w] x [h] at text size [text], in a column [width] wide: [width] null is the width of
  /// the screen between its 16 px sides.
  Future<void> onPhone(
    WidgetTester t,
    double w,
    double h,
    double text,
    Widget tile,
  ) async {
    t.view.devicePixelRatio = 1;
    t.view.physicalSize = Size(w, h);
    addTearDown(t.view.reset);
    await t.pumpWidget(
      _app(
        Align(
          alignment: Alignment.topCenter,
          child: SizedBox(width: w - 32, child: tile),
        ),
        still: true,
        text: text,
      ),
    );
  }

  testWidgets(
    'the sign never hides the word: it sits at the right end, the word stays whole and centred where it was (both phones, text size 1.6)',
    (t) async {
      // a ¿Qué oyes? tile (the whole row), with and without a speaker of its word alone; a Parejas tile (the row less
      // a sound's tile); long words that wrap at the large text size
      var kept = 0, wrapped = 0;
      for (final (w, h) in phones) {
        for (final text in sizes) {
          for (final word in ['sol', 'puerta', 'desayuno', 'refrigerador']) {
            for (final speaker in [false, true]) {
              final reason = '$w x $h, text $text, $word, speaker: $speaker';
              Widget tile({required bool sign}) => WordTile(
                word: word,
                expand: true,
                sign: sign,
                onTap: () {},
                onSpeaker: speaker ? () {} : null,
              );
              await onPhone(t, w, h, text, tile(sign: false));
              final plain = (
                t.getRect(find.byType(WordTile)),
                t.getRect(find.text(word)),
              );
              await onPhone(t, w, h, text, tile(sign: true));
              expect(find.byType(TouchSign), findsOneWidget, reason: reason);
              final box = t.getRect(find.byType(WordTile));
              final sign = t.getRect(find.byType(TouchSign));
              final label = t.getRect(find.text(word));
              // the sign's white ring (2 px) is part of what it covers
              expect(
                sign.inflate(2).overlaps(label),
                isFalse,
                reason: '$reason: the sign $sign covers the word $label',
              );
              // at the right end of the tile, inside it, level with its middle
              expect(_contains(box, sign.inflate(2)), isTrue, reason: reason);
              expect(
                sign.center.dy,
                closeTo(box.center.dy, .5),
                reason: reason,
              );
              expect(sign.center.dx, greaterThan(label.right), reason: reason);
              expect(box.right - sign.right, 6, reason: reason);
              // the word is centred in its tile
              expect(
                label.center.dx,
                closeTo(box.center.dx, .5),
                reason: '$reason: the word is centred',
              );
              if (label.size == plain.$2.size) {
                // it still fits on its line: the tile and the word are as they were
                kept++;
                expect(
                  box,
                  plain.$1,
                  reason: '$reason: the tile does not change',
                );
                expect(
                  label,
                  plain.$2,
                  reason: '$reason: the word did not move',
                );
              } else {
                // a word as wide as the room the sign needs wraps, whole and centred, rather than go under the sign
                wrapped++;
                expect(label.width, lessThan(plain.$2.width));
              }
              // a speaker gives its place to the sign while it shows
              expect(
                find.bySemanticsLabel('Hear the word'),
                findsNothing,
                reason: reason,
              );
            }
          }
          // Parejas' tile: beside a sound's tile
          final reason = '$w x $h, text $text, Parejas';
          await onPhone(
            t,
            w,
            h,
            text,
            Row(
              children: [
                SpeakerTile(onTap: () {}),
                const SizedBox(width: 16),
                Expanded(
                  child: WordTile(
                    word: 'desayuno',
                    expand: true,
                    sign: true,
                    onTap: () {},
                  ),
                ),
              ],
            ),
          );
          final sign = t.getRect(find.byType(TouchSign)).inflate(2);
          expect(
            sign.overlaps(t.getRect(find.text('desayuno'))),
            isFalse,
            reason: reason,
          );
          expect(
            _contains(t.getRect(find.byType(WordTile)), sign),
            isTrue,
            reason: reason,
          );
        }
      }
      expect(kept, greaterThan(0), reason: 'words that fit were tried');
      expect(wrapped, greaterThan(0), reason: 'words that wrap were tried');
    },
  );

  testWidgets(
    'a tile that is only as wide as its word (Arma la frase) grows by the sign\'s room on both sides, the word centred and clear of the sign',
    (t) async {
      for (final text in sizes) {
        await t.pumpWidget(
          _app(const WordTile(word: 'puerta'), still: true, text: text),
        );
        final plain = t.getRect(find.byType(WordTile));
        await t.pumpWidget(
          _app(
            const WordTile(word: 'puerta', sign: true),
            still: true,
            text: text,
          ),
        );
        final box = t.getRect(find.byType(WordTile));
        final sign = t.getRect(find.byType(TouchSign)).inflate(2);
        final label = t.getRect(find.text('puerta'));
        expect(box.width, plain.width + 80, reason: 'text $text');
        expect(box.height, plain.height, reason: 'text $text');
        expect(label.center.dx, closeTo(box.center.dx, .5));
        expect(sign.overlaps(label), isFalse, reason: 'text $text');
        expect(_contains(box, sign), isTrue, reason: 'text $text');
      }
    },
  );

  testWidgets(
    'the sign bounces gently, and is still with reduced motion (the hand does not turn into an arrow)',
    (t) async {
      Offset at() {
        final m = t
            .widget<Transform>(
              find.descendant(
                of: find.byType(TouchSign),
                matching: find.byType(Transform),
              ),
            )
            .transform
            .getTranslation();
        return Offset(m.x, m.y);
      }

      await t.pumpWidget(_app(const TouchSign()));
      await t.pump(const Duration(milliseconds: 350));
      expect(at().dy, lessThan(-1));
      expect(at().dy, greaterThanOrEqualTo(-TouchSign.bounce));
      expect(at().dx, 0);
      await t.pumpWidget(_app(const TouchSign(), still: true));
      await t.pump(const Duration(milliseconds: 350));
      expect(at().dy, 0);
      expect(t.hasRunningAnimations, isFalse);
    },
  );

  testWidgets(
    'a wrong touch: the red-orange ring and a round X badge at the corner where a right one has its check',
    (t) async {
      Future<Rect> badge(Widget w) async {
        await t.pumpWidget(_app(SizedBox(width: 300, height: 100, child: w)));
        final b = find.byType(WrongBadge);
        return b.evaluate().isEmpty ? Rect.zero : t.getRect(b);
      }

      final tile = WordTile(
        word: 'sol',
        expand: true,
        ring: ChoiceRing.wrong,
        cross: true,
      );
      final cross = await badge(
        Align(alignment: Alignment.topLeft, child: tile),
      );
      final tileBox = t.getRect(find.byType(WordTile));
      expect(find.byType(WrongBadge), findsOneWidget);
      expect(
        cross.size,
        const Size(CoquiMetrics.badgeSize, CoquiMetrics.badgeSize),
      );
      final b = _border(t, find.byType(WordTile))!;
      expect((b.top.color, b.top.width), (CoquiColors.lessonBad, 3.0));
      final ok = WordTile(
        word: 'sol',
        expand: true,
        ring: ChoiceRing.right,
        check: true,
      );
      await badge(Align(alignment: Alignment.topLeft, child: ok));
      final check = t.getRect(find.byType(CoquiIcon).last);
      // the same corner: the right edge and the top of the tile
      expect((cross.right - tileBox.right), closeTo(6, .5));
      expect((cross.top - tileBox.top), closeTo(-10, .5));
      expect(check.right, closeTo(cross.right, .5));
      expect(check.top, closeTo(cross.top, .5));
      // a picture: the same corner as its check
      await t.pumpWidget(
        _app(
          const PictureChoice(
            ring: ChoiceRing.wrong,
            cross: true,
            child: SizedBox(width: 120, height: 80),
          ),
        ),
      );
      final pic = t.getRect(find.byType(PictureChoice));
      final x = t.getRect(find.byType(WrongBadge));
      expect(x.right, closeTo(pic.right - CoquiMetrics.badgeInset, .5));
      expect(x.top, closeTo(pic.top + CoquiMetrics.badgeInset, .5));
      expect(find.bySemanticsLabel('Wrong'), findsOneWidget);
    },
  );

  testWidgets(
    'a number badge sits beside the check, on a tile and on a speaker tile',
    (t) async {
      await t.pumpWidget(
        _app(
          const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SpeakerTile(onTap: null, check: true, number: 2),
              SizedBox(width: 24),
              WordTile(word: 'sol', check: true, number: 2),
            ],
          ),
        ),
      );
      expect(find.text('2'), findsNWidgets(2));
      final ticks = find.byWidgetPredicate(
        (w) => w is CoquiIcon && w.data == CoquiIcons.badgeCheck,
      );
      expect(ticks, findsNWidgets(2));
      for (var i = 0; i < 2; i++) {
        final n = t.getRect(find.byType(NumberBadge).at(i));
        final c = t.getRect(ticks.at(i));
        // beside the check, to its left, on the same line
        expect(n.right, lessThanOrEqualTo(c.left + 6));
        expect((n.center.dy - c.center.dy).abs(), lessThan(6));
        expect(n.size, const Size(NumberBadge.size, NumberBadge.size));
      }
    },
  );

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

  testWidgets(
    'the streak chip with its place reserved: the same room whether it shows or not, so a line beside it never moves',
    (t) async {
      Future<(Size, Size)> sizes(int n) async {
        await t.pumpWidget(
          _app(
            SizedBox(
              width: 358,
              child: Row(
                children: [
                  const Expanded(
                    child: Text('Listen. Touch the word you heard.'),
                  ),
                  StreakChip(count: n, reserve: true),
                ],
              ),
            ),
            // half size: the test font (every glyph a whole em wide) is wider than Roboto
            text: .5,
          ),
        );
        return (
          t.getSize(find.byType(StreakChip)),
          t.getSize(find.byType(Expanded)),
        );
      }

      final none = await sizes(0);
      final shown = await sizes(7);
      final long = await sizes(99);
      expect(none.$1, const Size(StreakChip.reservedWidth, 32));
      expect(shown, none);
      expect(long, none);
      expect(find.text('99 in a row'), findsOneWidget);
    },
  );

  testWidgets(
    'the round speaker: 64 px, plays on a touch, pulses while the sentence sounds, still with reduced motion',
    (t) async {
      var n = 0;
      await t.pumpWidget(_app(RoundSpeaker(onTap: () => n++)));
      expect(
        t.getSize(find.bySemanticsLabel('Hear it again')),
        const Size(RoundSpeaker.size, RoundSpeaker.size),
      );
      await t.tap(find.bySemanticsLabel('Hear it again'));
      expect(n, 1);
      // not sounding: no ring, nothing animates
      expect(t.hasRunningAnimations, isFalse);
      Size ring() => t.getSize(
        find
            .descendant(
              of: find.byType(RoundSpeaker),
              matching: find.byType(Container),
            )
            .first,
      );
      await t.pumpWidget(_app(RoundSpeaker(onTap: () {}, playing: true)));
      expect(t.hasRunningAnimations, isTrue);
      final a = ring();
      await t.pump(const Duration(milliseconds: 400));
      final b = ring();
      expect(a, isNot(b)); // it grows
      // its own room does not change: a sentence that starts or ends moves nothing
      final room = t.getSize(find.byType(RoundSpeaker));
      await t.pumpWidget(_app(RoundSpeaker(onTap: () {})));
      expect(t.getSize(find.byType(RoundSpeaker)), room);
      await t.pumpWidget(
        _app(RoundSpeaker(onTap: () {}, playing: true), still: true),
      );
      await t.pump(const Duration(milliseconds: 400));
      expect(t.hasRunningAnimations, isFalse);
      expect(find.byType(RoundSpeaker), findsOneWidget);
    },
  );

  testWidgets(
    'an empty slot keeps the room of the tile that left it, shows nothing, and takes no touch',
    (t) async {
      var taps = 0;
      await t.pumpWidget(
        _app(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              WordTile(word: 'pájaro', onTap: () => taps++),
              WordTile(
                word: 'pájaro',
                look: TileLook.empty,
                onTap: () => taps++,
              ),
            ],
          ),
        ),
      );
      final full = t.getSize(find.byType(WordTile).first);
      final empty = t.getSize(find.byType(WordTile).last);
      expect(empty, full);
      // the word is not drawn in the slot
      expect(
        t
            .widgetList<Opacity>(find.byType(Opacity))
            .where((o) => o.opacity == 0),
        isNotEmpty,
      );
      await t.tap(find.byType(WordTile).last);
      expect(taps, 0);
    },
  );

  testWidgets(
    'a tile keeps its size, and so does everything round it, when a ring, a badge or the sign comes',
    (t) async {
      Future<List<Size>> sizes(
        ChoiceRing ring, {
        bool check = false,
        bool cross = false,
        bool sign = false,
        bool row = false,
      }) async {
        final first = WordTile(
          word: 'puerta',
          expand: row,
          ring: ring,
          check: check,
          cross: cross,
          sign: sign,
        );
        await t.pumpWidget(
          _app(
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // a tile that is given its row does not change for the sign (one that is as wide as its word grows by
                // the sign's room: see its own test)
                if (row) SizedBox(width: 240, child: first) else first,
                const SizedBox(width: 8),
                const WordTile(word: 'sol'),
              ],
            ),
            still: true,
          ),
        );
        final next = t.getTopLeft(find.byType(WordTile).last);
        return [
          t.getSize(find.byType(WordTile).first),
          t.getSize(find.byType(WordTile).last),
          Size(next.dx, next.dy),
        ];
      }

      final plain = await sizes(ChoiceRing.none);
      expect(await sizes(ChoiceRing.right, check: true), plain);
      expect(await sizes(ChoiceRing.wrong, cross: true), plain);
      final given = await sizes(ChoiceRing.none, row: true);
      expect(await sizes(ChoiceRing.none, sign: true, row: true), given);
    },
  );

  testWidgets(
    'the progress bar: a missed item\'s dash is red-orange (not green, not grey) wherever it stands',
    (t) async {
      await t.pumpWidget(
        _app(
          const SizedBox(
            width: 300,
            child: LessonProgressDashes(segments: 5, done: 3, missed: {1, 4}),
          ),
        ),
      );
      await t.pumpAndSettle();
      final colors = [
        for (final c in t.widgetList<AnimatedContainer>(
          find.byType(AnimatedContainer),
        ))
          (c.decoration! as BoxDecoration).color,
      ];
      expect(colors, [
        CoquiColors.lessonGreen,
        CoquiColors.lessonBad,
        CoquiColors.lessonGreen,
        CoquiColors.dotOff,
        CoquiColors.lessonBad,
      ]);
    },
  );

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
