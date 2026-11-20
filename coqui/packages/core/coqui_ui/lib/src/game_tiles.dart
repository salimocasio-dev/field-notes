/// The parts of Repaso's games (order 27, docs/proyecto/15-repaso-juegos.md) on the dark lesson frame: a written word
/// tile (with a speaker on it when the word can be heard alone), a speaker tile, a tray that lays tiles out, the
/// "N in a row" chip and the big sign for what to touch.
///
/// Dumb, as every widget here: values and callbacks. They follow the lesson's look (page 09): calm, plain, the
/// answer's rings as [PictureChoice] draws them (green right, red-orange wrong, white the one chosen), a right
/// answer never in a colour that reads as wrong, and the sign for what to touch big. Targets are 56 px high at
/// least (48 is the floor), 8 px apart in a tray.
library;

import 'dart:math' as math;

import 'package:coqui_ui/src/icons.dart';
import 'package:coqui_ui/src/lesson_frame.dart' show ChoiceRing;
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

  /// Not the answer, after an answer; or a tile that has gone up into the sentence.
  dim,
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
/// answer ring, dimmed when [look] says so; the check badge of a right answer at its right edge; the big [TouchSign]
/// above it when [sign]. [shake] moves it side to side once each time it grows (a wrong tile jumps back), unless
/// [still].
class _TileFace extends StatelessWidget {
  const _TileFace({
    required this.child,
    required this.look,
    required this.ring,
    required this.check,
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
  final bool sign;
  final bool pressed;
  final int shake;
  final bool still;
  final double minWidth;

  @override
  Widget build(BuildContext context) {
    final rc = _ringColor(ring);
    Widget face = Container(
      constraints: BoxConstraints(minHeight: _tileHeight, minWidth: minWidth),
      padding: const EdgeInsets.symmetric(horizontal: CoquiMetrics.s16),
      decoration: BoxDecoration(
        color: pressed ? CoquiColors.lessonTilePressed : CoquiColors.lessonTile,
        borderRadius: BorderRadius.circular(CoquiMetrics.radiusButton),
        border: Border.all(
          color: rc ?? CoquiColors.lessonLine,
          width: rc == null ? CoquiMetrics.borderButton : _ringWidth,
        ),
      ),
      child: Align(widthFactor: 1, heightFactor: 1, child: child),
    );
    face = Opacity(
      opacity: switch (look) {
        TileLook.normal => 1,
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
        if (check) const Positioned(right: -6, top: -10, child: _CheckBadge()),
        // on a tile the sign sits inside its left end and points at the word (above it, it would cover the line
        // that says what to do)
        if (sign)
          Positioned(
            left: 6,
            top: 0,
            bottom: 0,
            child: Center(
              child: TouchSign(still: calm, pointing: AxisDirection.right),
            ),
          ),
      ],
    );
  }
}

/// The check badge of a right answer, as [PictureChoice] has it: 28 px green with a white tick and a white ring.
class _CheckBadge extends StatelessWidget {
  const _CheckBadge();

  @override
  Widget build(BuildContext context) => Container(
    width: CoquiMetrics.badgeSize,
    height: CoquiMetrics.badgeSize,
    decoration: const BoxDecoration(
      shape: BoxShape.circle,
      color: CoquiColors.lessonGreen,
      boxShadow: [
        BoxShadow(
          color: CoquiColors.lessonInk,
          spreadRadius: CoquiMetrics.badgeRing,
        ),
      ],
    ),
    child: const CoquiIcon(
      CoquiIcons.badgeCheck,
      size: CoquiMetrics.badgeSize,
      color: CoquiColors.lessonInk,
    ),
  );
}

/// The big sign for what to touch: a 44 px green disc with a white arrow pointing down at the thing, that grows and
/// shrinks a little (still with reduced motion, or [still]). Over a picture or a tile whose answer is shown.
class TouchSign extends StatefulWidget {
  const TouchSign({
    super.key,
    this.still = false,
    this.pointing = AxisDirection.down,
  });

  static const double size = 44;
  final bool still;

  /// Where the arrow points: down at a picture under it, right at a word beside it.
  final AxisDirection pointing;

  @override
  State<TouchSign> createState() => _TouchSignState();
}

class _TouchSignState extends State<TouchSign>
    with SingleTickerProviderStateMixin {
  late final AnimationController _a = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
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
  Widget build(BuildContext context) => Semantics(
    label: 'Touch here',
    child: AnimatedBuilder(
      animation: _a,
      builder: (context, child) =>
          Transform.scale(scale: 1 + .1 * _a.value, child: child),
      child: Container(
        width: TouchSign.size,
        height: TouchSign.size,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: CoquiColors.lessonGreen,
          boxShadow: [BoxShadow(color: CoquiColors.lessonInk, spreadRadius: 2)],
        ),
        child: RotatedBox(
          quarterTurns: widget.pointing == AxisDirection.down ? 1 : 0,
          child: CoquiIcon(
            CoquiIcons.right,
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
  final bool check;
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
    final speaker = onSpeaker;
    Widget tile = Pressable(
      onPressed: onTap,
      semanticLabel: word,
      builder: (context, pressed) => _TileFace(
        look: look,
        ring: ring,
        check: check,
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

/// "4 in a row": a small pill of right answers in a row. Nothing below [from].
class StreakChip extends StatelessWidget {
  const StreakChip({super.key, required this.count, this.from = 3});

  final int count;
  final int from;

  @override
  Widget build(BuildContext context) {
    if (count < from) return const SizedBox.shrink();
    return Semantics(
      label: '$count in a row',
      excludeSemantics: true,
      child: Container(
        height: 32,
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
  }
}
