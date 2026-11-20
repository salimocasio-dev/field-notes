// The readers' fixes to Repaso's games, as the screen shows them: A (a picture is its own, not an old one handed a new
// pair), B (the end lists every word and shows that it scrolls), C (a wrong touch reads as wrong, the right one is
// marked by the hand and is not a hit before it is touched), D (nothing moves after a touch), E (every item ends with
// Next, the sentence only after the answer), J (Arma la frase), K (Parejas), L (Dilo), M (¿Dónde?'s pictures).
import 'dart:async';
import 'dart:math' as math;

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_ui/coqui_ui.dart';
import 'package:feature_review/src/logic/lesson_base.dart';
import 'package:feature_review/src/logic/repaso_plan.dart';
import 'package:feature_review/src/logic/repaso_session.dart';
import 'package:feature_review/src/ui/repaso_screen.dart';
import 'package:flutter/scheduler.dart' show Ticker;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/repaso_course.dart';
import 'support/repaso_screen_rig.dart';

// ---- A: pictures that behave as coqui_scenes' do

/// A picture source whose pictures are made as `coqui_scenes`' `_ScenePicture` is (that package is not this one's to
/// import): a state with a single ticker that, when it is handed another picture, disposes its ticker and starts
/// another one, and that puts its own red box (0xFF3A1E24) with the error's text where a start failed. Flutter lets a
/// `SingleTickerProviderStateMixin` create one ticker in its life, so the second start fails.
class TickerPictures implements PictureSource {
  @override
  Widget of(
    PictureRef ref, {
    int width = 196,
    int height = 104,
    bool animated = false,
  }) => _TickerPicture(ref: ref, animated: animated);

  @override
  Future<void> warm(Iterable<PictureRef> refs) async {}
}

class _TickerPicture extends StatefulWidget {
  const _TickerPicture({required this.ref, required this.animated});
  final PictureRef ref;
  final bool animated;

  @override
  State<_TickerPicture> createState() => _TickerPictureState();
}

class _TickerPictureState extends State<_TickerPicture>
    with SingleTickerProviderStateMixin {
  Ticker? _ticker;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void didUpdateWidget(_TickerPicture old) {
    super.didUpdateWidget(old);
    if (old.ref != widget.ref || old.animated != widget.animated) {
      _ticker?.dispose();
      _ticker = null;
      _error = null;
      _start();
    }
  }

  void _start() {
    try {
      if (widget.animated) {
        final ticker = createTicker((_) {});
        _ticker = ticker;
        unawaited(ticker.start());
      }
    } catch (e) {
      _error = e;
    }
  }

  @override
  void dispose() {
    _ticker?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _error != null
      ? ColoredBox(
          color: const Color(0xFF3A1E24),
          child: Center(child: Text('$_error')),
        )
      : const SizedBox.expand();
}

/// Where the fixed parts of a game are (the instruction line, the chip's place, the round speaker, the tiles, the
/// pictures, the sounds, Dilo's mic, the reveal's place, Next's place).
List<(String, Rect)> geometry(WidgetTester t) {
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
  add('picture', find.byType(PictureChoice));
  add('tile', find.byType(WordTile));
  add('sound', find.byType(SpeakerTile));
  add('mic', find.byType(RepasoMic));
  add('reveal', find.byKey(const ValueKey('reveal')));
  add('next', find.byKey(const ValueKey('next-slot')));
  return out;
}

String? sentenceOf(GameItem it) => switch (it) {
  SayItem() => it.line.text,
  _ => it.text,
};

Finder get sceneError => find.byWidgetPredicate(
  (w) => w is ColoredBox && w.color == const Color(0xFF3A1E24),
);

CualItem cualOf(Screen sc, RepasoWord w) => CualItem(
  word: w.word,
  pair: sc.services.course.pairFor(w.word)!,
  line: sc.s.planner.cualLines(w).first,
  rightPanel: 0,
);

/// A play item of [kind] for the session's words, made as the plan makes one.
GameItem playItemOf(Screen sc, GameKind kind) {
  sc.s.planner.nextKind = playKinds.indexOf(kind);
  final it = sc.s.planner.playItem(sc.s.words, canSay: false);
  expect(it?.kind, kind, reason: 'the data has material for $kind');
  return it!;
}

void main() {
  testWidgets(
    'A: consecutive ¿Cuál? items each get their own pictures: a picture handed another pair in place starts a second ticker and fails',
    (t) async {
      final sc = Screen(t, pictures: TickerPictures());
      await sc.open();
      final words = [
        for (final w in sc.s.words)
          if (sc.s.planner.cualLines(w).isNotEmpty) w,
      ].take(3).toList();
      expect(words, hasLength(3));
      sc.s.queue = [for (final w in words) QueueEntry.scored(cualOf(sc, w))];
      await t.tap(find.byType(LessonStartButton));
      await sc.settle();
      for (var n = 0; n < 3; n++) {
        await sc.vt.runUntil(() => sc.s.yourTurn && sc.s.index == n);
        await sc.settle();
        expect(sceneError, findsNothing, reason: 'item $n asked');
        expect(find.byType(PictureChoice), findsNWidgets(2));
        await sc.down(
          find
              .byType(PictureChoice)
              .at(sc.s.choices.indexWhere((c) => c.right)),
        );
        await sc.vt.runUntil(() => sc.s.canNext);
        await sc.settle();
        expect(sceneError, findsNothing, reason: 'item $n answered');
        await t.tap(find.text(RepasoStrings.next));
        await sc.settle();
      }
    },
  );

  testWidgets(
    'C: a wrong touch has the red-orange ring and a round X at the corner where a right one has its check; the right one then has the hand over its middle, no ring and no check; touched, it gets the green ring and the check',
    (t) async {
      for (final kind in [GameKind.cual, GameKind.hear, GameKind.where]) {
        final sc = Screen(t);
        await sc.open();
        final GameItem item;
        if (kind == GameKind.where) {
          item = playItemOf(sc, kind);
        } else {
          item = sc.s.queue.firstWhere((q) => q.item?.kind == kind).item!;
        }
        sc.s.queue = [QueueEntry.scored(item)];
        await t.tap(find.byType(LessonStartButton));
        await sc.settle();
        await sc.vt.runUntil(() => sc.s.yourTurn);
        await sc.settle();
        final tiles = kind == GameKind.hear
            ? find.byType(WordTile)
            : find.byType(PictureChoice);
        final r = sc.s.choices.indexWhere((c) => c.right);
        final w = r == 0 ? 1 : 0;
        if (kind == GameKind.hear) {
          await t.tap(tiles.at(w));
        } else {
          await sc.down(tiles.at(w));
        }
        await sc.vt.runUntil(() => sc.s.choices.any((c) => c.sign));
        await sc.settle();
        // his: the badge with an X, at the corner of a check
        expect(find.byType(WrongBadge), findsOneWidget, reason: '$kind');
        final wrongRect = t.getRect(tiles.at(w));
        final x = t.getRect(find.byType(WrongBadge));
        if (kind == GameKind.hear) {
          expect(x.right, closeTo(wrongRect.right + 6, .5));
          expect(x.top, closeTo(wrongRect.top - 10, .5));
        } else {
          expect(
            x.right,
            closeTo(wrongRect.right - CoquiMetrics.badgeInset, .5),
          );
          expect(x.top, closeTo(wrongRect.top + CoquiMetrics.badgeInset, .5));
        }
        // the right one: the hand over the middle of it, no ring, no check
        expect(
          find.byType(CheckBadge),
          findsNothing,
          reason: '$kind: not a hit yet',
        );
        expect(find.byType(TouchSign), findsOneWidget);
        final rightRect = t.getRect(tiles.at(r));
        final hand = t.getCenter(find.byType(TouchSign));
        expect(
          (hand - rightRect.center).distance,
          lessThan(1),
          reason: '$kind',
        );
        // over the middle, not on a border between two things
        expect(
          rightRect.deflate(TouchSign.size / 2 - 1).contains(hand),
          isTrue,
        );
        if (kind == GameKind.hear) {
          expect(t.widget<WordTile>(tiles.at(r)).ring, ChoiceRing.none);
        } else {
          expect(t.widget<PictureChoice>(tiles.at(r)).ring, ChoiceRing.none);
        }
        // touched: the green ring and the check, the hand gone
        if (kind == GameKind.hear) {
          await t.tap(tiles.at(r));
        } else {
          await sc.down(tiles.at(r));
        }
        await sc.vt.runUntil(() => sc.s.canNext);
        await sc.settle();
        expect(find.byType(TouchSign), findsNothing);
        expect(find.byType(CheckBadge), findsOneWidget);
        expect(
          find.byType(WrongBadge),
          findsOneWidget,
          reason: 'his keeps its X',
        );
        if (kind == GameKind.hear) {
          expect(t.widget<WordTile>(tiles.at(r)).ring, ChoiceRing.right);
        } else {
          expect(t.widget<PictureChoice>(tiles.at(r)).ring, ChoiceRing.right);
        }
        await sc.vt.runUntil(() => false, limit: 1);
      }
    },
  );

  for (final (name, w, h, dpr, text) in [
    ('390 x 844', 390.0, 844.0, 3.0, 1.0),
    ('412 x 915', 412.0, 915.0, 2.625, 1.0),
    ('390 x 844, text 1.3x', 390.0, 844.0, 3.0, 1.3),
  ]) {
    testWidgets(
      'D and E, $name: each game has one layout from the moment it is asked (nothing moves after a touch, when the reveal or Next comes), starts under the top bar, and shows no sentence before the answer',
      (t) async {
        final sc = Screen(t);
        await sc.open(w: w, h: h, dpr: dpr, text: text);
        final base = <QueueEntry, List<(String, Rect)>>{};
        final speakers = <GameKind, Rect>{};
        final seen = <String>{};
        await sc.play(
          each: (moment) async {
            final it = sc.s.item!;
            final geo = geometry(t);
            final sentence = sentenceOf(it);
            if (moment.startsWith('asked')) {
              base[sc.s.entry!] = geo;
              // content starts under the top bar: the instruction line is its first block
              final line = geo.firstWhere((g) => g.$1 == 'instruction[0]').$2;
              expect(line.top, lessThan(56 + 24), reason: moment);
              final room = geo
                  .where((g) => g.$1.startsWith('speaker'))
                  .toList();
              if (room.isNotEmpty) speakers[it.kind] = room.single.$2;
            } else if (moment != 'mic') {
              final first = base[sc.s.entry!]!;
              expect(geo.length, first.length, reason: moment);
              // the game's own scroll view may have been scrolled to reach a tile (the test font is wider than the
              // real one): what is in it moves together; Next's place is not in it and does not move at all
              final dy = geo.first.$2.top - first.first.$2.top;
              for (var i = 0; i < geo.length; i++) {
                final fixed = geo[i].$1.startsWith('next');
                expect(
                  geo[i].$2,
                  fixed ? first[i].$2 : first[i].$2.shift(Offset(0, dy)),
                  reason: '$moment: ${geo[i].$1} moved',
                );
              }
            }
            // E: no sentence before the answer, in any game; after it, the sentence and Next
            if (sentence != null) {
              final shown = find
                  .textContaining(sentence, findRichText: true)
                  .evaluate()
                  .isNotEmpty;
              final answered = moment.startsWith('next');
              expect(shown, answered, reason: '$moment: "$sentence"');
            }
            expect(
              find.text(RepasoStrings.next).evaluate().isNotEmpty,
              moment.startsWith('next'),
              reason: moment,
            );
            seen.add(
              moment.split(' ').first +
                  (moment.contains(' ') ? ' ${it.kind.name}' : ''),
            );
          },
        );
        // the round speaker: the same size and place in every game that plays a sentence
        expect(
          speakers.keys,
          containsAll([
            GameKind.cual,
            GameKind.hear,
            GameKind.build,
            GameKind.where,
          ]),
        );
        expect(speakers.values.toSet(), hasLength(1), reason: '$speakers');
        expect(
          speakers.values.first.size,
          const Size(
            RoundSpeaker.size + 2 * RoundSpeaker.pulse,
            RoundSpeaker.size + 2 * RoundSpeaker.pulse,
          ),
        );
        // every game ended with Next, ¿Cuál? too
        for (final k in [
          GameKind.cual,
          GameKind.hear,
          GameKind.build,
          GameKind.match,
          GameKind.where,
        ]) {
          expect(seen, contains('next ${k.name}'));
        }
      },
    );
  }

  testWidgets(
    'D and L: Dilo has the same fixed layout whether it listens, did not hear, or is done; the mic pulses and "Listening…" shows while the app listens; Can\'t speak now stands where Next will',
    (t) async {
      final w = realRepaso.words.firstWhere(
        (x) => x.say.isNotEmpty && x.say.first.story == 'la-lluvia',
      );
      final speech = HeldSpeech();
      final sc = Screen(t, listener: speech);
      await sc.open();
      sc.s.queue = [QueueEntry.play(SayItem(word: w.word, line: w.say.first))];
      await t.tap(find.byType(LessonStartButton));
      await sc.settle();
      final asked = geometry(t);
      await sc.vt.runUntil(() => sc.s.mic == MicState.ready);
      await sc.settle();
      expect(geometry(t), asked);
      expect(find.text(RepasoStrings.cantSpeak), findsOneWidget);
      expect(find.text('Listening…'), findsNothing);
      final cant = t.getRect(find.text(RepasoStrings.cantSpeak));
      await t.tap(find.byType(RepasoMic));
      await sc.vt.runUntil(() => sc.s.mic == MicState.listening);
      await t.pump();
      // while the app listens: the ring pulses round the mic, and "Listening…" is under it
      expect(find.byKey(const ValueKey('mic-pulse')), findsOneWidget);
      expect(find.text('Listening…'), findsOneWidget);
      expect(geometry(t), asked);
      expect(
        t.getTopLeft(find.text('Listening…')).dy,
        greaterThan(t.getRect(find.byType(RepasoMic)).bottom),
      );
      speech.hear('no sé');
      await sc.vt.runUntil(() => sc.s.notHeard && sc.s.mic == MicState.ready);
      await sc.settle();
      // a try not heard right: "Heard: ..." in normal-size text, and "Try again" under the mic
      expect(find.text('Heard: no sé'), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
      expect(find.text('Listening…'), findsNothing);
      expect(find.byKey(const ValueKey('mic-pulse')), findsNothing);
      final heard = t.widget<Text>(find.text('Heard: no sé'));
      expect(heard.style!.fontSize, greaterThanOrEqualTo(16));
      expect(
        t.getTopLeft(find.text('Try again')).dy,
        greaterThan(t.getRect(find.byType(RepasoMic)).bottom),
      );
      expect(geometry(t), asked);
      await t.tap(find.byType(RepasoMic));
      await sc.vt.runUntil(() => sc.s.mic == MicState.listening);
      speech.hear('eso no');
      await sc.vt.runUntil(() => sc.s.canNext);
      await sc.settle();
      // after the second: the line in the reveal area, then Next, where Can't speak now was
      expect(find.text('Heard: eso no'), findsOneWidget);
      expect(find.text('Try again'), findsNothing);
      expect(
        find.textContaining(w.say.first.text, findRichText: true),
        findsOneWidget,
      );
      expect(find.text(RepasoStrings.next), findsOneWidget);
      expect(find.text(RepasoStrings.cantSpeak), findsNothing);
      expect(
        t.getRect(find.text(RepasoStrings.next)).center.dy,
        closeTo(cant.center.dy, 8),
      );
      expect(geometry(t), asked);
    },
  );

  testWidgets(
    'J: Arma la frase on screen: a row of empty places before anything is placed; a placed tile goes to its place and leaves an empty slot of its size in the bank, nothing else moves; touched in the line it goes back; a check at the end of the whole line',
    (t) async {
      final sc = Screen(t);
      // a tall screen: the test font is wider than the real one, and nothing here should need scrolling to be reached
      await sc.open(h: 1600);
      sc.s.queue = [QueueEntry.play(playItemOf(sc, GameKind.build))];
      final it = sc.s.queue.single.item! as BuildItem;
      await t.tap(find.byType(LessonStartButton));
      await sc.settle();
      await sc.vt.runUntil(() => sc.s.yourTurn);
      await sc.settle();
      final line = find.descendant(
        of: find.byType(TileTray).first,
        matching: find.byType(WordTile),
      );
      final bank = find.descendant(
        of: find.byType(TileTray).last,
        matching: find.byType(WordTile),
      );
      // the answer line is a row of empty places, one for each word of the sentence
      expect(line, findsNWidgets(it.order.length));
      for (var i = 0; i < it.order.length; i++) {
        expect(t.widget<WordTile>(line.at(i)).look, TileLook.empty);
      }
      final lineRects = [
        for (var i = 0; i < it.order.length; i++) t.getRect(line.at(i)),
      ];
      final bankRects = [
        for (var i = 0; i < it.pool.length; i++) t.getRect(bank.at(i)),
      ];
      // a tile of the bank goes into the line
      final k0 = sc.s.choices.indexWhere((c) => c.label == it.order[0]);
      await t.ensureVisible(bank.at(k0));
      await t.tap(bank.at(k0));
      await sc.settle();
      expect(t.widget<WordTile>(line.at(0)).look, TileLook.normal);
      expect(t.widget<WordTile>(line.at(0)).word, it.order[0]);
      // the line did not move or change size; the bank keeps its shape, with an empty slot where the tile was
      expect([
        for (var i = 0; i < it.order.length; i++) t.getRect(line.at(i)),
      ], lineRects);
      expect([
        for (var i = 0; i < it.pool.length; i++) t.getRect(bank.at(i)),
      ], bankRects);
      expect(t.widget<WordTile>(bank.at(k0)).look, TileLook.empty);
      for (var i = 0; i < it.pool.length; i++) {
        if (i != k0) {
          expect(t.widget<WordTile>(bank.at(i)).look, isNot(TileLook.empty));
        }
      }
      // a wrong tile: its border flashes red-orange, once
      final wrong = sc.s.choices.indexWhere(
        (c) => c.label != it.order[1] && !c.done,
      );
      await t.ensureVisible(bank.at(wrong));
      await t.tap(bank.at(wrong));
      await t.pump();
      expect(t.widget<WordTile>(bank.at(wrong)).ring, ChoiceRing.wrong);
      await sc.vt.advance(700);
      await t.pump();
      expect(t.widget<WordTile>(bank.at(wrong)).ring, ChoiceRing.none);
      // touched in the line, the tile goes back to the bank
      await t.tap(line.at(0));
      await sc.settle();
      expect(t.widget<WordTile>(line.at(0)).look, TileLook.empty);
      expect(t.widget<WordTile>(bank.at(k0)).look, isNot(TileLook.empty));
      expect([
        for (var i = 0; i < it.pool.length; i++) t.getRect(bank.at(i)),
      ], bankRects);
      // the whole sentence: a check badge at the end of the line, the sentence in the reveal, Next
      expect(find.byType(CheckBadge), findsNothing);
      for (final word in it.order) {
        final k = sc.s.choices.indexWhere((c) => !c.done && c.label == word);
        await t.ensureVisible(bank.at(k));
        await t.tap(bank.at(k));
        await sc.settle();
      }
      expect(find.byType(CheckBadge), findsOneWidget);
      final lineBox = t.getRect(find.byType(TileTray).first);
      final check = t.getRect(find.byType(CheckBadge));
      expect(check.right, greaterThan(lineBox.right - 40));
      // at the end of the line: on the level of its last row
      expect(
        check.center.dy,
        closeTo(t.getRect(line.at(it.order.length - 1)).center.dy, 2),
      );
      expect(find.textContaining(it.text, findRichText: true), findsOneWidget);
      expect(find.text(RepasoStrings.next), findsOneWidget);
    },
  );

  testWidgets(
    'K: Parejas on screen: a wrong pair marks both tiles with the X for about a second, then clears; a matched pair has the same number on both tiles beside the check',
    (t) async {
      final sc = Screen(t);
      await sc.open();
      sc.s.queue = [QueueEntry.play(playItemOf(sc, GameKind.match))];
      final it = sc.s.queue.single.item! as MatchItem;
      await t.tap(find.byType(LessonStartButton));
      await sc.settle();
      await sc.vt.runUntil(() => sc.s.yourTurn);
      await sc.settle();
      final sounds = find.byType(SpeakerTile);
      final words = find.descendant(
        of: find.byType(Row),
        matching: find.byType(WordTile),
      );
      await t.tap(sounds.at(0));
      final wrong = (it.wordOrder.indexOf(0) + 1) % 4;
      await t.tap(words.at(wrong));
      await t.pump();
      expect(find.byType(WrongBadge), findsNWidgets(2));
      expect(t.widget<SpeakerTile>(sounds.at(0)).ring, ChoiceRing.wrong);
      expect(t.widget<WordTile>(words.at(wrong)).ring, ChoiceRing.wrong);
      await sc.vt.advance(1100);
      await t.pump();
      expect(find.byType(WrongBadge), findsNothing);
      // the pairs, each number on both of its tiles, beside a check
      for (var n = 0; n < 4; n++) {
        final i = [1, 3, 0, 2][n];
        await t.tap(sounds.at(i));
        await sc.settle();
        await t.tap(words.at(it.wordOrder.indexOf(i)));
        await sc.settle();
        expect(t.widget<SpeakerTile>(sounds.at(i)).number, n + 1);
        expect(
          t.widget<WordTile>(words.at(it.wordOrder.indexOf(i))).number,
          n + 1,
        );
      }
      expect(find.byType(NumberBadge), findsNWidgets(8));
      for (var n = 1; n <= 4; n++) {
        expect(find.widgetWithText(NumberBadge, '$n'), findsNWidgets(2));
      }
      expect(find.byType(CheckBadge), findsNWidgets(8));
    },
  );

  testWidgets(
    'M: ¿Dónde? shows two big pictures, one above the other, never three small ones in a row',
    (t) async {
      for (final (w, h, dpr) in [
        (390.0, 844.0, 2.0),
        (390.0, 844.0, 3.0),
        (412.0, 915.0, 2.625),
      ]) {
        final sc = Screen(t);
        await sc.open(w: w, h: h, dpr: dpr);
        sc.s.queue = [QueueEntry.play(playItemOf(sc, GameKind.where))];
        await t.tap(find.byType(LessonStartButton));
        await sc.settle();
        await sc.vt.runUntil(() => sc.s.yourTurn);
        await sc.settle();
        final pics = find.byType(PictureChoice);
        final n = pics.evaluate().length;
        expect(n, anyOf(2, 3));
        final rects = [for (var i = 0; i < n; i++) t.getRect(pics.at(i))];
        // stacked: the same left edge and size, each under the one before
        for (var i = 1; i < n; i++) {
          expect(rects[i].left, rects[0].left, reason: '$dpr');
          expect(rects[i].size, rects[0].size);
          expect(rects[i].top, greaterThan(rects[i - 1].bottom));
        }
        // three only when each is at least 150 px wide; always a whole scale ...
        if (n == 3) expect(rects[0].width, greaterThanOrEqualTo(150));
        final k = rects[0].width * dpr / 196;
        expect(
          (k - k.roundToDouble()).abs(),
          lessThan(.01),
          reason: 'a whole scale',
        );
        // ... and the largest that fits: a scale more would not fit the width or the room under the line
        final viewportBottom =
            t.getRect(find.byKey(const ValueKey('next-slot'))).top - 16;
        final contentBottom =
            t.getRect(find.byKey(const ValueKey('reveal'))).bottom + 16;
        final more =
            n *
            216 /
            dpr; // what one more scale adds, at least (scale 1 of the height)
        final widthLimit = 196 * (k.round() + 1) / dpr > math.min(480, w - 32);
        expect(
          widthLimit || contentBottom + more > viewportBottom,
          isTrue,
          reason: '$dpr: a bigger scale would have fitted: $rects',
        );
        await sc.vt.runUntil(() => false, limit: 1);
      }
    },
  );

  testWidgets(
    'B: the end screen lists every word of a session in one of two lists, shows that it scrolls, and keeps the button where it is',
    (t) async {
      final sc = Screen(t);
      await sc.open();
      await sc.play();
      expect(sc.s.screen, LessonScreen.end);
      expect(find.text('9 of 10 words right the first time'), findsOneWidget);
      expect(find.text('Got it the first time'), findsOneWidget);
      expect(find.text("You'll see these less often"), findsOneWidget);
      expect(find.text('Coming back soon'), findsOneWidget);
      expect(find.text("You'll see these again soon"), findsOneWidget);
      // ten rows, one for each word, each with its sentence and its speaker
      final rows = [
        for (final g in sc.s.end!.groups)
          for (final r in g.rows) r,
      ];
      expect(rows, hasLength(10));
      for (final r in rows) {
        expect(
          find.bySemanticsLabel('${r.word}: ${r.text}'),
          findsOneWidget,
          reason: r.word,
        );
      }
      expect(
        find
            .descendant(
              of: find.byType(RepasoEndView),
              matching: find.byWidgetPredicate(
                (w) => w is CoquiIcon && w.data == CoquiIcons.lessonSound,
              ),
            )
            .evaluate()
            .length,
        10,
      );
      // the list is a scrolling one and says so; the button is always there
      final back = find.text('Back to Palabras');
      final buttonTop = t.getRect(back).top;
      expect(find.byType(Scrollbar), findsOneWidget);
      expect(
        t.widget<Scrollbar>(find.byType(Scrollbar)).thumbVisibility,
        isTrue,
      );
      final scroll = find.descendant(
        of: find.byType(Scrollbar),
        matching: find.byType(Scrollable),
      );
      final before = t.getRect(
        find.bySemanticsLabel('${rows.last.word}: ${rows.last.text}'),
      );
      // the last row is not above the button until the list is scrolled
      expect(before.bottom, greaterThan(buttonTop));
      await t.drag(scroll, const Offset(0, -2000));
      await t.pump();
      final after = t.getRect(
        find.bySemanticsLabel('${rows.last.word}: ${rows.last.text}'),
      );
      expect(after.bottom, lessThanOrEqualTo(buttonTop));
      expect(t.getRect(back).top, buttonTop);
      expect(t.getRect(back).bottom, lessThanOrEqualTo(844));
    },
  );
}
