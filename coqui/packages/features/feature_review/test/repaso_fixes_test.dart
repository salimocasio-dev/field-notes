// The readers' fixes to Repaso's games, as the screen shows them: A (a picture is its own, not an old one handed a new
// pair), B (the end lists every word and shows that it scrolls), C (a wrong touch reads as wrong, the right one is
// marked by the hand and is not a hit before it is touched), D (nothing moves after a touch), E (every item ends with
// Next, the sentence only after the answer), J (Arma la frase), K (Parejas), L (Dilo), M (¿Dónde?'s pictures), and the
// readers' third round: the bar tells how it went (N), a picture's frame never changes its size (O), the touch sign at a
// picture's corner (C), the end screen's order (B).
import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_ui/coqui_ui.dart';
import 'package:feature_review/src/logic/lesson_base.dart';
import 'package:feature_review/src/logic/repaso_plan.dart';
import 'package:feature_review/src/logic/repaso_session.dart';
import 'package:feature_review/src/ui/repaso_screen.dart';
import 'package:flutter/rendering.dart' show OffsetLayer;
import 'package:flutter/scheduler.dart' show Ticker;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/repaso_course.dart';
import 'support/repaso_screen_rig.dart';

// ---- A: pictures that behave as coqui_scenes' do

/// A picture source whose pictures are as strict as a picture can be (a stand-in: `coqui_scenes`' own once were, and
/// take another picture in place now): a state with a single ticker that, when it is handed another picture, disposes
/// its ticker and starts another one, and that puts its own red box (0xFF3A1E24) with the error's text where a start
/// failed. Flutter lets a `SingleTickerProviderStateMixin` create one ticker in its life, so the second start fails.
/// The screen keys the pictures of each item, so no picture is ever handed another.
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
  // the tiles of the game's own area; the tiles put on Arma la frase's line come and go, and the line itself does not
  final tiles = [
    for (final e in find.byType(WordTile).evaluate())
      if (e.findAncestorWidgetOfExactType<TileTray>()?.line != true) e.widget,
  ];
  for (var i = 0; i < tiles.length; i++) {
    out.add(('tile[$i]', t.getRect(find.byWidget(tiles[i]))));
  }
  add('line', find.byKey(const ValueKey('answer-line')));
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

/// The picture of the whole view as it is drawn now (what the screenshots tool saves): its pixels, and how many of them
/// make a logical pixel.
class Shot {
  Shot(this.width, this.height, this.rgba, this.scale);
  final int width;
  final int height;
  final Uint8List rgba;
  final double scale;

  /// The colour of the pixel at the logical point ([x], [y]).
  Color at(double x, double y) {
    final px = (x * scale).floor().clamp(0, width - 1);
    final py = (y * scale).floor().clamp(0, height - 1);
    final i = (py * width + px) * 4;
    return Color.fromARGB(255, rgba[i], rgba[i + 1], rgba[i + 2]);
  }
}

Future<Shot> shotOf(WidgetTester t) async {
  final view = t.binding.renderViews.first;
  final layer = view.debugLayer! as OffsetLayer;
  // the view's logical width: the image has as many pixels across as the device has
  final logical = t.view.physicalSize.width / t.view.devicePixelRatio;
  final out = await t.runAsync(() async {
    final image = await layer.toImage(view.paintBounds);
    final data = (await image.toByteData())!.buffer.asUint8List();
    final shot = Shot(image.width, image.height, data, image.width / logical);
    image.dispose();
    return shot;
  });
  return out!;
}

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
    'C: a wrong touch has the red-orange ring and a round X at the corner where a right one has its check; the right one then has the hand (inside the bottom-right corner of a picture, 12 px from both edges; at the right end of a word tile with the word clear of it), no ring and no check; touched, it gets the green ring and the check',
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
        // the right one: the hand, no ring, no check
        expect(
          find.byType(CheckBadge),
          findsNothing,
          reason: '$kind: not a hit yet',
        );
        expect(find.byType(TouchSign), findsOneWidget);
        final rightRect = t.getRect(tiles.at(r));
        final hand = t.getCenter(find.byType(TouchSign));
        if (kind == GameKind.hear) {
          // on a word: at the right end of its tile, inside it, level with its middle, and the word is not under it
          final sign = t.getRect(find.byType(TouchSign));
          final word = t.getRect(
            find.descendant(
              of: tiles.at(r),
              matching: find.text(sc.s.choices[r].label),
            ),
          );
          expect(hand.dy, closeTo(rightRect.center.dy, 1), reason: '$kind');
          expect(rightRect.right - sign.right, 6, reason: '$kind');
          expect(rightRect.contains(sign.topLeft), isTrue, reason: '$kind');
          expect(
            sign.inflate(2).overlaps(word),
            isFalse,
            reason: '$kind: the sign is over the word',
          );
          expect(word.center.dx, closeTo(rightRect.center.dx, .5));
        } else {
          // on a picture: inside its bottom-right corner, 12 px from both edges, never over its middle
          final sign = t.getRect(find.byType(TouchSign));
          expect(
            rightRect.right - sign.right,
            closeTo(12, .01),
            reason: '$kind',
          );
          expect(
            rightRect.bottom - sign.bottom,
            closeTo(12, .01),
            reason: '$kind',
          );
          expect(rightRect.contains(sign.topLeft), isTrue, reason: '$kind');
          expect(
            sign.contains(rightRect.center),
            isFalse,
            reason: '$kind: the sign is over the middle of the picture',
          );
        }
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
    'C (the hand on a word): after a wrong touch the hand is at the right end of the right tile, inside it and level with its middle; the word is whole, centred and not under it, with a speaker on the tile or none (both phones, text size 1.6)',
    (t) async {
      for (final (w, h) in [(390.0, 844.0), (412.0, 915.0)]) {
        for (final text in [1.0, 1.6]) {
          for (final speakers in [false, true]) {
            final reason = '$w x $h, text $text, speakers: $speakers';
            final sc = Screen(t);
            await sc.open(w: w, h: h, text: text);
            final base =
                sc.s.queue
                        .firstWhere((q) => q.item?.kind == GameKind.hear)
                        .item!
                    as HearItem;
            // the same item, with a clip of every word alone when [speakers]: the tiles have a speaker each
            final item = HearItem(
              word: base.word,
              sentence: base.sentence,
              tiles: base.tiles,
              answer: base.answer,
              solo: [for (final _ in base.tiles) speakers ? base.clip : null],
            );
            expect(item.speakers, speakers);
            sc.s.queue = [QueueEntry.scored(item)];
            await t.tap(find.byType(LessonStartButton));
            await sc.settle();
            await sc.vt.runUntil(() => sc.s.yourTurn);
            await sc.settle();
            final tiles = find.byType(WordTile);
            expect(tiles, findsNWidgets(3), reason: reason);
            final r = sc.s.choices.indexWhere((c) => c.right);
            await t.tap(tiles.at(r == 0 ? 1 : 0));
            await sc.vt.runUntil(() => sc.s.choices.any((c) => c.sign));
            await sc.settle();
            // every tile's word is centred in its tile; the right one's is clear of the hand
            expect(find.byType(TouchSign), findsOneWidget, reason: reason);
            final tile = t.getRect(tiles.at(r));
            final sign = t.getRect(find.byType(TouchSign));
            for (var k = 0; k < 3; k++) {
              final word = t.getRect(
                find.descendant(
                  of: tiles.at(k),
                  matching: find.text(sc.s.choices[k].label),
                ),
              );
              expect(
                word.center.dx,
                closeTo(t.getRect(tiles.at(k)).center.dx, .5),
                reason: '$reason: word $k is centred',
              );
              if (k == r) {
                expect(
                  sign.inflate(2).overlaps(word),
                  isFalse,
                  reason: '$reason: the sign $sign is over the word $word',
                );
              }
            }
            expect(sign.center.dy, closeTo(tile.center.dy, 1), reason: reason);
            expect(tile.right - sign.right, 6, reason: reason);
            expect(tile.contains(sign.topLeft), isTrue, reason: reason);
            expect(tile.contains(sign.bottomRight), isTrue, reason: reason);
            // the hand takes the speaker's place on its tile (the other two keep theirs), so a touch on it is a touch on
            // the tile
            expect(
              find.bySemanticsLabel('Hear the word'),
              findsNWidgets(speakers ? 2 : 0),
              reason: reason,
            );
            await t.tapAt(sign.center);
            await sc.vt.runUntil(() => sc.s.canNext);
            await sc.settle();
            expect(find.byType(TouchSign), findsNothing, reason: reason);
            expect(
              t.widget<WordTile>(tiles.at(r)).ring,
              ChoiceRing.right,
              reason: reason,
            );
          }
        }
      }
    },
  );

  testWidgets(
    'D and L: Dilo has the same fixed layout whether it listens, did not hear (the X badge beside the mic), or is done (the X on the mic); the mic pulses and "Listening…" shows while the app listens; Can\'t speak now stands where Next will',
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
      // ... and the X badge beside the mic, on the rim of its disc at the upper right
      expect(find.byType(WrongBadge), findsOneWidget);
      final mic = t.getRect(find.byType(RepasoMic));
      final badge = t.getCenter(find.byType(WrongBadge));
      expect(
        (badge - mic.center).distance,
        closeTo(CoquiMetrics.startDisc / 2, 3),
        reason: 'on the disc\'s rim',
      );
      expect(badge.dx, greaterThan(mic.center.dx));
      expect(badge.dy, lessThan(mic.center.dy));
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
      // after the second: the mic shows the X, the line in the reveal area, then Next, where Can't speak now was
      expect(find.text('Heard: eso no'), findsOneWidget);
      expect(find.text('Try again'), findsNothing);
      expect(find.byType(WrongBadge), findsNothing);
      final cross = find.descendant(
        of: find.byType(RepasoMic),
        matching: find.byWidgetPredicate(
          (w) => w is CoquiIcon && w.data == CoquiIcons.close,
        ),
      );
      expect(cross, findsOneWidget, reason: 'the mic shows the X');
      expect(t.widget<CoquiIcon>(cross).color, CoquiColors.lessonBad);
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
    'J: Arma la frase on screen: an empty line with a baseline, no places; its height for two rows is there from the start; a right tile goes onto it from the left and is green at once, leaving an empty place of its size in the bank; a wrong tile stays in the bank red-orange with an X for about a second; a tile on the line cannot be taken back; a check after the last tile',
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
      final lineBox = find.byKey(const ValueKey('answer-line'));
      final line = find.descendant(
        of: lineBox,
        matching: find.byType(WordTile),
      );
      final bank = find.descendant(
        of: find.byType(TileTray).last,
        matching: find.byType(WordTile),
      );
      // nothing on the line, and no empty places on it: the shapes of the words cannot be read
      expect(line, findsNothing);
      expect(
        t.widget<TileTray>(lineBox).lineRows,
        greaterThanOrEqualTo(2),
        reason: 'two rows are reserved',
      );
      final lineRect = t.getRect(lineBox);
      expect(
        lineRect.height,
        TileTray.lineHeight(
          t.widget<TileTray>(lineBox).lineRows,
          tileHeight: t.widget<TileTray>(lineBox).lineTileHeight,
        ),
        reason: 'as high as its rows from the start',
      );
      final bankRects = [
        for (var i = 0; i < it.pool.length; i++) t.getRect(bank.at(i)),
      ];
      // a tile of the bank goes onto the line: from the left of it, with the green border at once
      final k0 = sc.s.choices.indexWhere((c) => c.label == it.order[0]);
      await t.ensureVisible(bank.at(k0));
      await t.tap(bank.at(k0));
      await sc.settle();
      expect(line, findsOneWidget);
      expect(t.widget<WordTile>(line.at(0)).word, it.order[0]);
      expect(t.widget<WordTile>(line.at(0)).ring, ChoiceRing.right);
      expect(t.getRect(line.at(0)).left, closeTo(lineRect.left, .01));
      // the line did not move or change size; the bank keeps its shape, with an empty place where the tile was
      expect(t.getRect(lineBox), lineRect);
      expect([
        for (var i = 0; i < it.pool.length; i++) t.getRect(bank.at(i)),
      ], bankRects);
      expect(t.widget<WordTile>(bank.at(k0)).look, TileLook.empty);
      for (var i = 0; i < it.pool.length; i++) {
        if (i != k0) {
          expect(t.widget<WordTile>(bank.at(i)).look, isNot(TileLook.empty));
        }
      }
      // a tile that is not the next word: it stays in the bank, red-orange, with the X badge, for about a second
      final wrong = sc.s.choices.indexWhere(
        (c) => c.label != it.order[1] && !c.done,
      );
      await t.ensureVisible(bank.at(wrong));
      await t.tap(bank.at(wrong));
      await t.pump();
      expect(t.widget<WordTile>(bank.at(wrong)).ring, ChoiceRing.wrong);
      expect(find.byType(WrongBadge), findsOneWidget);
      final x = t.getRect(find.byType(WrongBadge));
      final wrongRect = t.getRect(bank.at(wrong));
      expect(x.right, closeTo(wrongRect.right + 6, .5));
      expect(x.top, closeTo(wrongRect.top - 10, .5));
      expect(line, findsOneWidget, reason: 'nothing went onto the line');
      expect(t.widget<WordTile>(bank.at(wrong)).look, isNot(TileLook.empty));
      await sc.vt.advance(900);
      await t.pump();
      expect(find.byType(WrongBadge), findsOneWidget, reason: 'about a second');
      await sc.vt.advance(200);
      await t.pump();
      expect(t.widget<WordTile>(bank.at(wrong)).ring, ChoiceRing.none);
      expect(find.byType(WrongBadge), findsNothing);
      // a tile on the line cannot be taken back
      await t.tap(line.at(0));
      await sc.settle();
      expect(line, findsOneWidget);
      expect(t.widget<WordTile>(bank.at(k0)).look, TileLook.empty);
      // the whole sentence: one tile after another, left to right (a row below when the row is full), a check after
      // the last, the sentence in the reveal, Next
      expect(find.byType(CheckBadge), findsNothing);
      for (var i = 1; i < it.order.length; i++) {
        final k = sc.s.choices.indexWhere(
          (c) => !c.done && c.label == it.order[i],
        );
        await t.ensureVisible(bank.at(k));
        await t.tap(bank.at(k));
        await sc.settle();
        expect(line, findsNWidgets(i + 1));
        final a = t.getRect(line.at(i - 1)), b = t.getRect(line.at(i));
        expect(
          b.left > a.right || b.top > a.bottom,
          isTrue,
          reason: 'one after another: to the right, or on the row below',
        );
        expect(t.widget<WordTile>(line.at(i)).ring, ChoiceRing.right);
      }
      expect(t.getRect(lineBox), lineRect, reason: 'the line never grew');
      expect(find.byType(CheckBadge), findsOneWidget);
      // after the last tile, on its row (the check's own test, 'J (the check)', has where and how far)
      final check = t.getRect(find.byType(CheckBadge));
      final lastTile = t.getRect(line.at(it.order.length - 1));
      expect(
        check.left > lastTile.right || check.top > lastTile.bottom,
        isTrue,
      );
      expect(find.textContaining(it.text, findRichText: true), findsOneWidget);
      expect(find.text(RepasoStrings.next), findsOneWidget);
    },
  );

  // Arma la frase's check, on sentences made here: three words are one row at 390 px wide and four are two (in the test
  // font, which is wider than the real one), and a width of its own puts the check after the last tile or below it. The
  // line is as high as the whole sentence and its check from the first moment, so nothing moves when they come.
  testWidgets(
    'J (the check): at the end of a whole sentence the check is 8 px after the last tile on its row, or at the start of a row below when that row has no room; it is never over a tile, and the line (as high as the sentence needs, two rows at least) and the bank do not move from the first moment',
    (t) async {
      const three = ['la', 'casa', 'azul'];
      const four = ['la', 'casa', 'es', 'azul'];
      const long = ['ayer', 'mi', 'abuela', 'cerro'];
      for (final (words, w, text, rows, sameRow) in [
        // (the sentence, the screen's width, text size, rows of tiles, whether the check is on the last tile's row)
        (three, 390.0, 1.0, 1, true), // one row, room after it
        (
          three,
          360.0,
          1.0,
          1,
          false,
        ), // one row, none: the check is alone on a row below
        (four, 390.0, 1.0, 2, true), // two rows, room after the last tile
        (long, 340.0, 1.0, 2, false), // two rows, none: a third row, reserved
        (three, 412.0, 1.6, null, null),
        (four, 412.0, 1.6, null, null),
        (four, 390.0, 1.6, null, null),
      ]) {
        final reason = '${words.length} words, $w wide, text $text';
        final sc = Screen(t);
        // tall, so that nothing scrolls and a tile is where it is whatever is done
        await sc.open(w: w, h: 3200, text: text);
        final built = playItemOf(sc, GameKind.build) as BuildItem;
        final item = BuildItem(
          word: built.word,
          sentence: built.sentence,
          order: words,
          pool: [...words.reversed],
        );
        sc.s.queue = [QueueEntry.play(item)];
        await t.tap(find.byType(LessonStartButton));
        await sc.settle();
        await sc.vt.runUntil(() => sc.s.yourTurn);
        await sc.settle();
        final lineBox = find.byKey(const ValueKey('answer-line'));
        final line = find.descendant(
          of: lineBox,
          matching: find.byType(WordTile),
        );
        final bank = find.descendant(
          of: find.byType(TileTray).last,
          matching: find.byType(WordTile),
        );
        expect(line, findsNothing, reason: reason);
        expect(find.byType(CheckBadge), findsNothing, reason: reason);
        expect(
          t.widget<TileTray>(lineBox).lineRows,
          greaterThanOrEqualTo(2),
          reason: reason,
        );
        final trayBefore = t.getRect(lineBox);
        final bankBefore = t.getRect(find.byType(TileTray).last);
        final nextBefore = t.getRect(find.byKey(const ValueKey('next-slot')));
        for (final word in words) {
          final k = sc.s.choices.indexWhere((c) => !c.done && c.label == word);
          await t.tap(bank.at(k));
          await sc.settle();
        }
        expect(line, findsNWidgets(words.length), reason: reason);
        expect(find.byType(CheckBadge), findsOneWidget, reason: reason);
        final tiles = [
          for (var i = 0; i < words.length; i++) t.getRect(line.at(i)),
        ];
        final badge = t.getRect(find.byType(CheckBadge));
        final last = tiles.last;
        final tray = t.getRect(lineBox);
        // nothing moved from the first moment: the line (as high as the whole sentence needs), the bank, Next
        expect(tray, trayBefore, reason: '$reason: the line');
        expect(t.getRect(find.byType(TileTray).last), bankBefore);
        expect(t.getRect(find.byKey(const ValueKey('next-slot'))), nextBefore);
        // the tiles and the check are inside the line, above its baseline
        for (final r in [...tiles, badge]) {
          expect(r.left, greaterThanOrEqualTo(tray.left), reason: reason);
          expect(r.right, lessThanOrEqualTo(tray.right + .01), reason: reason);
          expect(r.bottom, lessThanOrEqualTo(tray.bottom), reason: reason);
        }
        // the check is never over a tile (its white ring takes 2 px more)
        for (final r in tiles) {
          expect(
            badge.inflate(2).overlaps(r),
            isFalse,
            reason: '$reason: the check $badge is over a tile $r',
          );
        }
        final onRow = (badge.center.dy - last.center.dy).abs() < 1;
        final rowsOfTiles = {for (final r in tiles) r.top.round()}.length;
        if (sameRow != null) {
          expect(rowsOfTiles, rows, reason: '$reason: rows of tiles');
          expect(onRow, sameRow, reason: '$reason: on the last tile\'s row');
        }
        if (onRow) {
          // 8 px after the last tile, level with its middle
          expect(badge.left - last.right, closeTo(8, .01), reason: reason);
        } else {
          // at the start of a row below the last one, alone there; the last row had no room for it
          expect(
            badge.top,
            greaterThanOrEqualTo(
              tiles.map((r) => r.bottom).reduce(math.max) + 12 - .01,
            ),
            reason: '$reason: a row below the tiles',
          );
          expect(
            tray.right - last.right,
            lessThan(8 + badge.width),
            reason: '$reason: it would have fitted on the last row',
          );
        }
      }
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
      // the headline, then the words he missed, then the ones he got
      final headline = t.getRect(
        find.text('9 of 10 words right the first time'),
      );
      final soon = t.getRect(find.text('Coming back soon'));
      final got = t.getRect(find.text('Got it the first time'));
      expect(headline.bottom, lessThan(soon.top));
      expect(soon.bottom, lessThan(got.top));
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

  testWidgets(
    'L: Dilo heard right, on screen: the check on the mic, "Heard: ..." in green, the line in the reveal area with the word lit, Next at once; nothing moves',
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
      await t.tap(find.byType(RepasoMic));
      await sc.vt.runUntil(() => sc.s.mic == MicState.listening);
      final said = w.say.first.forms.first;
      speech.hear(said);
      await sc.vt.runUntil(() => sc.s.heardRight);
      await sc.settle();
      // no wait: Next is there as soon as it was heard
      expect(find.text(RepasoStrings.next), findsOneWidget);
      expect(find.text(RepasoStrings.cantSpeak), findsNothing);
      expect(find.text('Try again'), findsNothing);
      expect(find.byType(WrongBadge), findsNothing);
      final heard = t.widget<Text>(find.text('Heard: $said'));
      expect(heard.style!.color, CoquiColors.heard);
      final tick = find.descendant(
        of: find.byType(RepasoMic),
        matching: find.byWidgetPredicate(
          (w) => w is CoquiIcon && w.data == CoquiIcons.check,
        ),
      );
      expect(tick, findsOneWidget, reason: 'the check on the mic');
      expect(
        find.textContaining(w.say.first.text, findRichText: true),
        findsOneWidget,
        reason: 'the line in the reveal area',
      );
      expect(geometry(t), asked);
      await t.tap(find.text(RepasoStrings.next));
      await sc.vt.runUntil(() => sc.s.screen == LessonScreen.end);
    },
  );

  testWidgets(
    'N: the bar tells how it went: each dash takes the colour of its item\'s first answer and keeps it (green right, red-orange wrong, grey not reached); the item on screen has the white outline; a return has no dash and repaints nothing',
    (t) async {
      final sc = Screen(t);
      await sc.open();
      List<(Color?, bool)> dashes() => [
        for (final c in t.widgetList<AnimatedContainer>(
          find.descendant(
            of: find.byType(LessonProgressDashes),
            matching: find.byType(AnimatedContainer),
          ),
        ))
          (
            (c.decoration! as BoxDecoration).color,
            (c.decoration! as BoxDecoration).boxShadow != null,
          ),
      ];
      // the pictures or the tiles of the item on screen, whichever it has
      Finder choice(int k) =>
          (sc.s.item is HearItem
                  ? find.byType(WordTile)
                  : find.byType(PictureChoice))
              .at(k);
      const off = CoquiColors.dotOff;
      const ok = CoquiColors.lessonGreen;
      const bad = CoquiColors.lessonBad;
      await t.tap(find.byType(LessonStartButton));
      await sc.settle();
      await sc.vt.runUntil(() => sc.s.yourTurn && sc.s.index == 0);
      await t.pump(const Duration(milliseconds: 300));
      expect(dashes(), [(off, true), ...List.filled(12, (off, false))]);
      // the first answer wrong: the dash is red-orange (outlined: still the item on screen)
      final r = sc.s.choices.indexWhere((c) => c.right);
      await sc.down(choice(r == 0 ? 1 : 0));
      await t.pump(const Duration(milliseconds: 300));
      expect(dashes().first, (bad, true));
      await sc.vt.runUntil(() => sc.s.choices.any((c) => c.sign));
      await sc.down(choice(r));
      await sc.vt.runUntil(() => sc.s.canNext);
      await t.pump(const Duration(milliseconds: 300));
      expect(dashes().first, (bad, true), reason: 'it keeps the colour');
      await t.tap(find.text(RepasoStrings.next));
      await sc.vt.runUntil(() => sc.s.index == 1 && sc.s.yourTurn);
      await t.pump(const Duration(milliseconds: 300));
      expect(dashes(), [
        (bad, false),
        (off, true),
        ...List.filled(11, (off, false)),
      ]);
      // the next is answered right: green
      await sc.down(choice(sc.s.choices.indexWhere((c) => c.right)));
      await sc.vt.runUntil(() => sc.s.canNext);
      await t.pump(const Duration(milliseconds: 300));
      expect(dashes().take(2), [(bad, false), (ok, true)]);
      await t.tap(find.text(RepasoStrings.next));
      // the item between is answered right; then the return: the dash of the item it answers again is the outlined one
      QueueEntry? acted;
      for (var g = 0; g < 50; g++) {
        await sc.vt.runUntil(
          () =>
              sc.s.canNext ||
              sc.s.choices.any((c) => c.sign) ||
              (sc.s.yourTurn && !identical(acted, sc.s.entry)),
        );
        if (sc.s.entry?.again == true && sc.s.yourTurn) break;
        if (sc.s.canNext) {
          await t.tap(find.text(RepasoStrings.next));
        } else {
          acted = sc.s.entry;
          await sc.down(choice(sc.s.choices.indexWhere((c) => c.right)));
        }
      }
      expect(sc.s.entry?.again, isTrue);
      await t.pump(const Duration(milliseconds: 300));
      final d = dashes();
      expect(d, hasLength(13));
      expect(d.first, (bad, true));
      expect(d.where((x) => x.$2), hasLength(1));
      await sc.down(choice(sc.s.choices.indexWhere((c) => c.right)));
      await sc.vt.runUntil(() => sc.s.canNext);
      await t.pump(const Duration(milliseconds: 300));
      expect(
        dashes().first.$1,
        bad,
        reason: 'right on its return: not repainted',
      );
    },
  );

  testWidgets(
    'N: a skipped dash (Dilo, "Can\'t speak now") is a grey lighter than the one not reached, neither green nor red-orange',
    (t) async {
      final w = realRepaso.words.firstWhere(
        (x) => x.say.isNotEmpty && x.say.first.story == 'la-lluvia',
      );
      final sc = Screen(t);
      await sc.open();
      sc.s.queue = [
        QueueEntry.play(SayItem(word: w.word, line: w.say.first)),
        QueueEntry.play(SayItem(word: w.word, line: w.say.first)),
      ];
      sc.s.makeDots(2);
      await t.tap(find.byType(LessonStartButton));
      await sc.settle();
      await sc.vt.runUntil(() => sc.s.mic == MicState.ready);
      await sc.settle();
      await t.tap(find.text(RepasoStrings.cantSpeak));
      await sc.vt.runUntil(() => sc.s.screen == LessonScreen.end);
      await t.pump(const Duration(milliseconds: 300));
      final colors = [
        for (final c in t.widgetList<AnimatedContainer>(
          find.descendant(
            of: find.byType(LessonProgressDashes),
            matching: find.byType(AnimatedContainer),
          ),
        ))
          (c.decoration! as BoxDecoration).color,
      ];
      // the item that was on screen is skipped; the one that was never asked (Dilo is off) stays "not reached"
      expect(colors, [CoquiColors.dotSkipped, CoquiColors.dotOff]);
      expect(CoquiColors.dotSkipped, isNot(CoquiColors.dotOff));
    },
  );

  testWidgets(
    'O: a picture\'s frame has the same outer edge marked or not: the ring is drawn inside the picture\'s box, so the picture does not look bigger when it is marked (¿Cuál? and ¿Dónde?)',
    (t) async {
      final page = await bookPageStandIn(t);
      for (final kind in [GameKind.cual, GameKind.where]) {
        final sc = Screen(t);
        await sc.open(bookPicture: page);
        final item = kind == GameKind.cual
            ? sc.s.queue.firstWhere((q) => q.item?.kind == kind).item!
            : playItemOf(sc, kind);
        sc.s.queue = [QueueEntry.scored(item)];
        await t.tap(find.byType(LessonStartButton));
        await sc.settle();
        await sc.vt.runUntil(() => sc.s.yourTurn);
        await t.pump(const Duration(milliseconds: 300));
        final pics = find.byType(PictureChoice);
        for (var i = 0; i < pics.evaluate().length; i++) {
          expect(t.widget<PictureChoice>(pics.at(i)).inside, isTrue);
        }
        final w = sc.s.choices.indexWhere((c) => !c.right);
        final box = t.getRect(pics.at(w));
        // just outside the box (1 px), and in the box's outer 1 px, at the left edge, half way down
        Color out(Shot s) => s.at(box.left - 1, box.center.dy);
        Color edge(Shot s) => s.at(box.left + 1, box.center.dy);
        final before = await shotOf(t);
        expect(
          out(before),
          CoquiColors.lessonBg,
          reason: '$kind: nothing round it',
        );
        expect(
          edge(before),
          CoquiColors.lessonLine,
          reason: '$kind: the plain frame, inside',
        );
        // a wrong touch: the red-orange ring, 3 px, and the frame is not bigger
        await sc.down(pics.at(w));
        await t.pump(const Duration(milliseconds: 300));
        final after = await shotOf(t);
        expect(t.getRect(pics.at(w)), box);
        expect(
          edge(after),
          CoquiColors.lessonBad,
          reason: '$kind: the ring, inside',
        );
        expect(
          out(after),
          CoquiColors.lessonBg,
          reason: '$kind: nothing grew round it',
        );
        // the right one touched, too: the green ring, the same edge
        await sc.vt.runUntil(() => sc.s.choices.any((c) => c.sign));
        final r = sc.s.choices.indexWhere((c) => c.right);
        final rbox = t.getRect(pics.at(r));
        await sc.down(pics.at(r));
        await sc.vt.runUntil(() => sc.s.canNext);
        await t.pump(const Duration(milliseconds: 300));
        final done = await shotOf(t);
        expect(done.at(rbox.left + 1, rbox.center.dy), CoquiColors.lessonGreen);
        expect(done.at(rbox.left - 1, rbox.center.dy), CoquiColors.lessonBg);
        expect(done.at(rbox.right + 1, rbox.center.dy), CoquiColors.lessonBg);
        expect(done.at(rbox.center.dx, rbox.top - 1), CoquiColors.lessonBg);
        expect(done.at(rbox.center.dx, rbox.bottom + 1), CoquiColors.lessonBg);
      }
    },
  );
}
