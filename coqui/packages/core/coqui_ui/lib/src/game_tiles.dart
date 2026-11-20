/// The parts of Repaso's games (order 27, docs/proyecto/15-repaso-juegos.md) on the dark lesson frame: a written word
/// tile (with a speaker on it when the word can be heard alone), a speaker tile, the round speaker of a game, a tray
/// that lays tiles out, the "N in a row" chip and the sign for what to touch.
///
/// Dumb, as every widget here: values and callbacks. They follow the lesson's look (page 09): calm, plain, the
/// answer's rings as [PictureChoice] draws them (green right, red-orange wrong, white the one chosen), a right
/// answer never in a colour that reads as wrong, a wrong one marked by a round badge with an X where a right one has
/// its check, and the sign for what to touch big, over the middle of it. Targets are 56 px high at least (48 is the
/// floor), 8 px apart in a tray.
library;

import 'dart:math' as math;

import 'package:coqui_ui/src/icons.dart';
import 'package:coqui_ui/src/lesson_frame.dart'
    show CheckBadge, ChoiceRing, WrongBadge;
import 'package:coqui_ui/src/pressable.dart';
import 'package:coqui_ui/src/text_styles.dart';
import 'package:coqui_ui/src/tokens.dart';
import 'package:material_ui/material_ui.dart';

/// How a tile looks at a moment of a game.
enum TileLook {
  /// Ready to touch.
  normal,

  /// Shown while the sentence plays: there, dimmed, not touchable yet.
  waiting,

  /// Not the answer, after an answer.
  dim,

  /// The place of a tile that is not there: an empty slot of its size, a faint outline, nothing in it (a tile of the
  /// bank that has gone up into the sentence; a place in the sentence that is not filled).
  empty,
}

const double _tileHeight = 56;
const double _ringWidth = 3;

Color? _ringColor(ChoiceRing r) => switch (r) {
  ChoiceRing.none => null,
  ChoiceRing.right => CoquiColors.lessonGreen,
  ChoiceRing.wrong => CoquiColors.lessonBad,
  ChoiceRing.selected => CoquiColors.optionSelected,
};

/// The face every tile shares: 56 px high at least, radius 12, the tile colour, a 1.5 px `--line` frame or a 3 px
/// answer ring, dimmed when [look] says so; at its right edge the check badge of a right answer ([check]) or the
/// X badge of a wrong one ([cross]), with a small [number] badge beside it; the [TouchSign] over its middle when
/// [sign]. [shake] moves it side to side once each time it grows (a wrong tile jumps back), unless [still].
class _TileFace extends StatelessWidget {
  const _TileFace({
    required this.child,
    required this.look,
    required this.ring,
    required this.check,
    required this.cross,
    required this.number,
    required this.sign,
    required this.pressed,
    required this.shake,
    required this.still,
    this.minWidth = _tileHeight,
  });

  final Widget child;
  final TileLook look;
  final ChoiceRing ring;
  final bool check;
  final bool cross;
  final int? number;
  final bool sign;
  final bool pressed;
  final int shake;
  final bool still;
  final double minWidth;

  @override
  Widget build(BuildContext context) {
    final empty = look == TileLook.empty;
    final rc = empty ? null : _ringColor(ring);
    // the frame is drawn over the face (a foreground decoration): a ring that comes or goes takes no room, so a tile
    // never changes its size, and nothing round it moves, when it is touched
    Widget face = Container(
      constraints: BoxConstraints(minHeight: _tileHeight, minWidth: minWidth),
      padding: const EdgeInsets.symmetric(
        horizontal: CoquiMetrics.s16 + CoquiMetrics.borderButton,
      ),
      decoration: BoxDecoration(
        color: empty
            ? null
            : (pressed
                  ? CoquiColors.lessonTilePressed
                  : CoquiColors.lessonTile),
        borderRadius: BorderRadius.circular(CoquiMetrics.radiusButton),
      ),
      foregroundDecoration: BoxDecoration(
        borderRadius: BorderRadius.circular(CoquiMetrics.radiusButton),
        border: Border.all(
          color: empty
              ? CoquiColors.lessonLine.withValues(alpha: .6)
              : (rc ?? CoquiColors.lessonLine),
          width: rc == null ? CoquiMetrics.borderButton : _ringWidth,
        ),
      ),
      child: Align(
        widthFactor: 1,
        heightFactor: 1,
        // an empty slot keeps the room of what stood in it, and shows nothing of it
        child: empty ? Opacity(opacity: 0, child: child) : child,
      ),
    );
    face = Opacity(
      opacity: switch (look) {
        TileLook.normal || TileLook.empty => 1,
        TileLook.waiting => .5,
        TileLook.dim => .35,
      },
      child: face,
    );
    final calm = still || MediaQuery.maybeDisableAnimationsOf(context) == true;
    if (shake > 0 && !calm) {
      face = TweenAnimationBuilder<double>(
        key: ValueKey(shake),
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 360),
        builder: (context, t, child) => Transform.translate(
          offset: Offset(8 * (1 - t) * math.sin(t * 6 * math.pi), 0),
          child: child,
        ),
        child: face,
      );
    }
    return Stack(
      clipBehavior: Clip.none,
      // the face takes what its tile is given: as wide as its word, or the whole row when the tile is told to expand
      fit: StackFit.passthrough,
      children: [
        face,
        if (check) const Positioned(right: -6, top: -10, child: CheckBadge()),
        if (cross) const Positioned(right: -6, top: -10, child: WrongBadge()),
        if (number != null)
          Positioned(
            right: (check || cross) ? 28 : -4,
            top: (check || cross) ? -7 : -8,
            child: NumberBadge(number: number!),
          ),
        // the sign is over the middle of the tile, and takes no touch: a finger on it is a finger on the tile
        if (sign)
          Positioned.fill(
            child: IgnorePointer(
              child: Center(child: TouchSign(still: calm)),
            ),
          ),
      ],
    );
  }
}

/// A small round number (1 to 4) that marks which matched pair a tile belongs to (Parejas): white, with a dark digit.
class NumberBadge extends StatelessWidget {
  const NumberBadge({super.key, required this.number});

  /// The size of the disc.
  static const double size = 22;
  final int number;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Pair $number',
    excludeSemantics: true,
    child: Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: CoquiColors.lessonInk,
      ),
      child: Text(
        '$number',
        style: CoquiText.lessonChip.copyWith(
          fontSize: 13,
          height: 1,
          fontWeight: FontWeight.w700,
          color: CoquiColors.lessonBg,
        ),
      ),
    ),
  );
}

/// The sign for what to touch: Material's pointing hand (`touch_app`), white on a 44 px green disc, that bounces
/// gently (still with reduced motion, or [still]). It goes over the middle of the picture or tile whose answer is
/// shown, never on a border between two things; it takes no touch itself.
class TouchSign extends StatefulWidget {
  const TouchSign({super.key, this.still = false});

  static const double size = 44;

  /// How far up the bounce takes it.
  static const double bounce = 5;
  final bool still;

  @override
  State<TouchSign> createState() => _TouchSignState();
}

class _TouchSignState extends State<TouchSign>
    with SingleTickerProviderStateMixin {
  late final AnimationController _a = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );

  bool get _still =>
      widget.still || MediaQuery.maybeDisableAnimationsOf(context) == true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(TouchSign old) {
    super.didUpdateWidget(old);
    _sync();
  }

  void _sync() {
    if (_still) {
      _a.stop();
      _a.value = 0;
    } else if (!_a.isAnimating) {
      _a.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _a.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: Semantics(
      label: 'Touch here',
      child: AnimatedBuilder(
        animation: _a,
        builder: (context, child) => Transform.translate(
          offset: Offset(
            0,
            -TouchSign.bounce * Curves.easeInOut.transform(_a.value),
          ),
          child: child,
        ),
        child: Container(
          width: TouchSign.size,
          height: TouchSign.size,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: CoquiColors.lessonGreen,
            boxShadow: [
              BoxShadow(color: CoquiColors.lessonInk, spreadRadius: 2),
            ],
          ),
          child: const CoquiIcon(
            CoquiIcons.touchApp,
            size: 30,
            color: CoquiColors.lessonInk,
          ),
        ),
      ),
    ),
  );
}

/// A written word to touch. [onSpeaker] puts a speaker at its right end that plays the word alone (a word with no
/// such clip has none); touching the speaker does not touch the word. [onTap] null: it takes no touch.
class WordTile extends StatelessWidget {
  const WordTile({
    super.key,
    required this.word,
    this.onTap,
    this.onSpeaker,
    this.look = TileLook.normal,
    this.ring = ChoiceRing.none,
    this.check = false,
    this.cross = false,
    this.number,
    this.sign = false,
    this.shake = 0,
    this.still = false,
    this.expand = false,
  });

  final String word;
  final VoidCallback? onTap;
  final VoidCallback? onSpeaker;
  final TileLook look;
  final ChoiceRing ring;

  /// The check badge of a right touch; the X badge of a wrong one; a pair's number beside either.
  final bool check;
  final bool cross;
  final int? number;
  final bool sign;
  final int shake;
  final bool still;

  /// As wide as its row gives (a column of answers); otherwise as wide as its word.
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final text = Text(
      word,
      textAlign: TextAlign.center,
      style: CoquiText.lessonTile,
    );
    final speaker = look == TileLook.empty ? null : onSpeaker;
    Widget tile = Pressable(
      onPressed: look == TileLook.empty ? null : onTap,
      semanticLabel: look == TileLook.empty ? '' : word,
      builder: (context, pressed) => _TileFace(
        look: look,
        ring: ring,
        check: check,
        cross: cross,
        number: number,
        sign: sign,
        pressed: pressed,
        shake: shake,
        still: still,
        child: Padding(
          padding: EdgeInsets.symmetric(
            vertical: 12,
            // room for the speaker, which sits over the tile's right end
            horizontal: speaker == null ? 0 : 40,
          ),
          child: text,
        ),
      ),
    );
    if (expand) tile = SizedBox(width: double.infinity, child: tile);
    if (speaker == null) return tile;
    // the speaker is its own target, over the tile: a touch on it is not a touch on the word
    return Stack(
      children: [
        tile,
        Positioned(
          right: 6,
          top: 0,
          bottom: 0,
          child: Center(child: _SpeakerButton(onPressed: speaker)),
        ),
      ],
    );
  }
}

/// The small speaker on a word tile: a 40 px round target (inside the tile, the tile's own 56 px around it).
class _SpeakerButton extends StatelessWidget {
  const _SpeakerButton({required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Pressable(
    onPressed: onPressed,
    semanticLabel: 'Hear the word',
    builder: (context, pressed) => Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: pressed ? CoquiColors.iconPressed : null,
      ),
      child: const CoquiIcon(
        CoquiIcons.lessonSound,
        size: 24,
        color: CoquiColors.lessonInk2,
      ),
    ),
  );
}

/// A tile that is a sound: a speaker to touch (Parejas' sentences; a play game's "hear it again"). [playing]: it is
/// sounding now (the speaker is white, not grey).
class SpeakerTile extends StatelessWidget {
  const SpeakerTile({
    super.key,
    required this.onTap,
    this.label = 'Play',
    this.look = TileLook.normal,
    this.ring = ChoiceRing.none,
    this.check = false,
    this.cross = false,
    this.number,
    this.playing = false,
    this.still = false,
    this.width = 88,
  });

  final VoidCallback? onTap;

  /// What a screen reader says.
  final String label;
  final TileLook look;
  final ChoiceRing ring;
  final bool check;
  final bool cross;
  final int? number;
  final bool playing;
  final bool still;
  final double width;

  @override
  Widget build(BuildContext context) => Pressable(
    onPressed: onTap,
    semanticLabel: label,
    builder: (context, pressed) => _TileFace(
      look: look,
      ring: ring,
      check: check,
      cross: cross,
      number: number,
      sign: false,
      pressed: pressed,
      shake: 0,
      still: still,
      minWidth: width,
      child: CoquiIcon(
        CoquiIcons.lessonSound,
        size: 28,
        color: playing ? CoquiColors.lessonInk : CoquiColors.lessonInk2,
      ),
    ),
  );
}

/// Tiles laid out in rows that wrap, centred, 8 px apart across and 12 down (the answer's ring takes no room, the
/// check badge and the sign stand out of their tile). With [line], the tray is the place a sentence is put
/// together: at least one tile high, with a 1.5 px line under it.
class TileTray extends StatelessWidget {
  const TileTray({super.key, required this.children, this.line = false});

  final List<Widget> children;
  final bool line;

  @override
  Widget build(BuildContext context) {
    final wrap = Wrap(
      alignment: WrapAlignment.center,
      spacing: CoquiMetrics.s8,
      runSpacing: CoquiMetrics.s12,
      children: children,
    );
    if (!line) return wrap;
    return Container(
      constraints: const BoxConstraints(minHeight: _tileHeight + 16),
      padding: const EdgeInsets.only(bottom: CoquiMetrics.s8, top: 8),
      alignment: Alignment.bottomCenter,
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: CoquiColors.lessonLine,
            width: CoquiMetrics.borderButton,
          ),
        ),
      ),
      child: wrap,
    );
  }
}

/// "4 in a row": a small pill of right answers in a row. Nothing below [from]. With [reserve] the pill's place is
/// kept when there is nothing to show (a line that stands beside it does not change its width when the pill comes).
class StreakChip extends StatelessWidget {
  const StreakChip({
    super.key,
    required this.count,
    this.from = 3,
    this.reserve = false,
  });

  /// The width a reserved place has: room for "99 in a row".
  static const double reservedWidth = 132;
  static const double height = 32;

  final int count;
  final int from;
  final bool reserve;

  @override
  Widget build(BuildContext context) {
    if (count < from) {
      return reserve
          ? const SizedBox(width: reservedWidth, height: height)
          : const SizedBox.shrink();
    }
    final chip = Semantics(
      label: '$count in a row',
      excludeSemantics: true,
      child: Container(
        height: height,
        padding: const EdgeInsets.symmetric(horizontal: CoquiMetrics.s12),
        decoration: BoxDecoration(
          color: CoquiColors.lessonChip,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CoquiIcon(
              CoquiIcons.check,
              size: 16,
              color: CoquiColors.bookLineLitBar,
            ),
            const SizedBox(width: 6),
            Text('$count in a row', style: CoquiText.lessonChip),
          ],
        ),
      ),
    );
    if (!reserve) return chip;
    // inside its reserved place the pill shrinks to fit (a larger text size, a longer count), never overflows it
    return SizedBox(
      width: reservedWidth,
      height: height,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerRight,
        child: chip,
      ),
    );
  }
}

/// The round speaker of a game that plays a sentence: 64 px, the same size and place in every such game. A touch
/// plays the sentence again. While the sentence sounds ([playing]) a ring pulses round it (a still ring with
/// reduced motion, or [still]).
class RoundSpeaker extends StatefulWidget {
  const RoundSpeaker({
    super.key,
    required this.onTap,
    this.playing = false,
    this.still = false,
    this.label = 'Hear it again',
  });

  /// The disc.
  static const double size = 64;

  /// The room the pulse needs round the disc (the ring grows by this much on every side).
  static const double pulse = 10;

  final VoidCallback? onTap;
  final bool playing;
  final bool still;

  /// What a screen reader says.
  final String label;

  @override
  State<RoundSpeaker> createState() => _RoundSpeakerState();
}

class _RoundSpeakerState extends State<RoundSpeaker>
    with SingleTickerProviderStateMixin {
  late final AnimationController _a = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  bool get _calm =>
      widget.still || MediaQuery.maybeDisableAnimationsOf(context) == true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(RoundSpeaker old) {
    super.didUpdateWidget(old);
    _sync();
  }

  void _sync() {
    if (widget.playing && !_calm) {
      if (!_a.isAnimating) _a.repeat();
    } else {
      _a.stop();
      _a.value = 0;
    }
  }

  @override
  void dispose() {
    _a.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const box = RoundSpeaker.size + 2 * RoundSpeaker.pulse;
    return SizedBox(
      width: box,
      height: box,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (widget.playing)
            IgnorePointer(
              child: AnimatedBuilder(
                animation: _a,
                builder: (context, _) {
                  final t = _calm ? .5 : _a.value;
                  final r = RoundSpeaker.size / 2 + RoundSpeaker.pulse * t;
                  return Container(
                    width: 2 * r,
                    height: 2 * r,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: CoquiColors.bookLineLitBar.withValues(
                          alpha: .9 * (1 - t),
                        ),
                        width: 3,
                      ),
                    ),
                  );
                },
              ),
            ),
          Pressable(
            onPressed: widget.onTap,
            semanticLabel: widget.label,
            builder: (context, pressed) => Container(
              width: RoundSpeaker.size,
              height: RoundSpeaker.size,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: pressed
                    ? CoquiColors.lessonTilePressed
                    : CoquiColors.lessonTile,
                border: Border.all(
                  color: widget.playing
                      ? CoquiColors.bookLineLitBar
                      : CoquiColors.lessonLine,
                  width: CoquiMetrics.borderButton,
                ),
              ),
              child: CoquiIcon(
                CoquiIcons.lessonSound,
                size: 30,
                color: widget.playing
                    ? CoquiColors.lessonInk
                    : CoquiColors.lessonInk2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
