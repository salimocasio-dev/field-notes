/// The speech bubble over the picture (index.html `#bub`).
library;

import 'dart:math' as math;

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_ui/coqui_ui.dart';
import 'package:feature_story/src/runner/bubble_place.dart';
import 'package:feature_story/src/runner/story_view.dart';
import 'package:material_ui/material_ui.dart';

const Color _ink = Color(0xFF2A1810),
    _tickGreen = Color(0xFF17803F),
    _micRed = Color(0xFFD93025);

/// The bubble's text: 800 weight, 18 px on a line of 1.2, centred, brown-black on white. index.html:72
final TextStyle bubbleTextStyle = CoquiText.lessonCaption.copyWith(
  fontWeight: FontWeight.w800,
  fontSize: 18,
  height: 1.2,
  color: _ink,
);

/// A bubble's body: white, 3 px brown-black border, 12 px corners, 5/11/6 px padding. The tail is drawn by the caller.
class StoryBubbleBody extends StatefulWidget {
  const StoryBubbleBody({
    super.key,
    required this.kind,
    required this.text,
    required this.estate,
    this.reduceMotion = false,
    this.language,
  });

  final BubbleKind kind;
  final String text;

  /// `data-e`: the mic's state while a turn is on.
  final String estate;
  final bool reduceMotion;

  /// Course language for text direction, script font, and locale.
  final Language? language;

  @override
  State<StoryBubbleBody> createState() => _StoryBubbleBodyState();
}

class _StoryBubbleBodyState extends State<StoryBubbleBody>
    with TickerProviderStateMixin {
  late final AnimationController _a = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );

  bool get _moves =>
      !widget.reduceMotion &&
      ((widget.kind == BubbleKind.mic && widget.estate == 'listening') ||
          widget.kind == BubbleKind.dots);

  @override
  void initState() {
    super.initState();
    if (_moves) _a.repeat();
  }

  @override
  void didUpdateWidget(StoryBubbleBody old) {
    super.didUpdateWidget(old);
    if (_moves) {
      if (!_a.isAnimating) _a.repeat();
    } else {
      _a.stop();
    }
  }

  @override
  void dispose() {
    _a.dispose();
    super.dispose();
  }

  Language get _lang => widget.language ?? Language.spanish;

  TextStyle get _textStyle =>
      NocheType.forScript(bubbleTextStyle, _lang.script);

  Widget _content() {
    switch (widget.kind) {
      case BubbleKind.words:
        return Text(
          widget.text,
          textAlign: TextAlign.center,
          textDirection: _lang.textDirection,
          locale: _lang.locale,
          style: _textStyle,
        );
      case BubbleKind.mic:
        final listening = widget.estate == 'listening';
        // `#bub[data-e=listening] svg`: coral red, pulsing to 1.25
        return AnimatedBuilder(
          animation: _a,
          builder: (context, _) => Transform.scale(
            scale: listening && !widget.reduceMotion
                ? 1 + .25 * (1 - (2 * _a.value - 1).abs())
                : 1,
            child: CoquiIcon(
              CoquiIcons.lessonMic,
              size: 28,
              color: listening ? _micRed : _ink,
            ),
          ),
        );
      case BubbleKind.dots:
        // the same three dots, 28 px so the bubble keeps its size
        return AnimatedBuilder(
          animation: _a,
          builder: (context, _) => SizedBox(
            width: 28,
            height: 28,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < 3; i++) ...[
                  if (i > 0) const SizedBox(width: 4),
                  Opacity(
                    opacity: widget.reduceMotion
                        ? 1
                        : (.3 + .7 * _dotLevel(i * .15)).clamp(.3, 1),
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: _ink,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      case BubbleKind.tick:
        return Directionality(
          textDirection: _lang.textDirection,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CoquiIcon(
                CoquiIcons.badgeCheck,
                size: 28,
                color: _tickGreen,
              ),
              if (widget.text.isNotEmpty) ...[
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    widget.text,
                    textAlign: TextAlign.center,
                    textDirection: _lang.textDirection,
                    locale: _lang.locale,
                    style: _textStyle,
                  ),
                ),
              ],
            ],
          ),
        );
    }
  }

  double _dotLevel(double delay) {
    final c = (_a.value * 1.2 / .9 - delay / .9) % 1;
    return c < .35
        ? c / .35
        : c < .7
        ? 1 - (c - .35) / .35
        : 0;
  }

  @override
  Widget build(BuildContext context) {
    final turn = widget.kind != BubbleKind.words;
    return Container(
      constraints: turn
          ? const BoxConstraints(minWidth: 56, minHeight: 44)
          : null,
      padding: const EdgeInsetsDirectional.fromSTEB(11, 5, 11, 6),
      alignment: turn ? AlignmentDirectional.center : null,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _ink, width: 3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: _content(),
    );
  }
}

/// A tail: the white triangle with its dark edge, as the `::before` and `::after` of `#bub` draw it.
class _TailPainter extends CustomPainter {
  const _TailPainter(this.mode);

  final BubbleSideMode mode;

  @override
  void paint(Canvas canvas, Size size) {
    final dark = Paint()..color = _ink;
    final white = Paint()..color = Colors.white;
    switch (mode) {
      case BubbleSideMode.above:
        // 8 px triangle (dark) down from the border, 5 px (white) inside it
        canvas.drawPath(
          Path()
            ..moveTo(0, 0)
            ..lineTo(16, 0)
            ..lineTo(8, 9)
            ..close(),
          dark,
        );
        canvas.drawPath(
          Path()
            ..moveTo(3, 0)
            ..lineTo(13, 0)
            ..lineTo(8, 6)
            ..close(),
          white,
        );
      case BubbleSideMode.right:
        canvas.drawPath(
          Path()
            ..moveTo(9, 0)
            ..lineTo(9, 16)
            ..lineTo(0, 8)
            ..close(),
          dark,
        );
        canvas.drawPath(
          Path()
            ..moveTo(9, 3)
            ..lineTo(9, 13)
            ..lineTo(3, 8)
            ..close(),
          white,
        );
      case BubbleSideMode.left:
        canvas.drawPath(
          Path()
            ..moveTo(0, 0)
            ..lineTo(0, 16)
            ..lineTo(9, 8)
            ..close(),
          dark,
        );
        canvas.drawPath(
          Path()
            ..moveTo(0, 3)
            ..lineTo(0, 13)
            ..lineTo(6, 8)
            ..close(),
          white,
        );
    }
  }

  @override
  bool shouldRepaint(_TailPainter old) => old.mode != mode;
}

/// Where a bubble stands and the bubble itself, over a stage of [stage] size. [placement] is what [placeBubble] found.
///
/// The bubble takes no touch: a finger on it goes through to the picture under it, as in the old page (`#bub{pointer-events:none}`).
class StoryBubbleLayer extends StatelessWidget {
  const StoryBubbleLayer({
    super.key,
    required this.visible,
    required this.kind,
    required this.text,
    required this.estate,
    required this.placementFor,
    this.reduceMotion = false,
    this.language,
  });

  final bool visible;
  final BubbleKind kind;
  final String text;
  final String estate;

  /// Where it stands, given its measured size; null hides it (the speaker cannot be seen).
  final BubblePlacement? Function(Size bubble) placementFor;
  final bool reduceMotion;

  /// Course language for the text inside the bubble.
  final Language? language;

  @override
  Widget build(BuildContext context) {
    final first = placementFor(const Size(0, 0));
    if (!visible || first == null) return const SizedBox.shrink();
    return IgnorePointer(
      child: CustomSingleChildLayout(
        delegate: _BubbleDelegate(placementFor, first.maxWidth),
        child: AnimatedOpacity(
          opacity: 1,
          duration: const Duration(milliseconds: 120),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              StoryBubbleBody(
                kind: kind,
                text: text,
                estate: estate,
                reduceMotion: reduceMotion,
                language: language,
              ),
              Positioned.fill(child: _TailAnchor(placementFor: placementFor)),
            ],
          ),
        ),
      ),
    );
  }
}

/// The tail, placed from the bubble's own size in physical scene coordinates
/// (unmirrored pixel scene).
class _TailAnchor extends StatelessWidget {
  const _TailAnchor({required this.placementFor});

  final BubblePlacement? Function(Size bubble) placementFor;

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.ltr,
    child: LayoutBuilder(
      builder: (context, c) {
        final p = placementFor(Size(c.maxWidth, c.maxHeight));
        if (p == null) return const SizedBox.shrink();
        switch (p.mode) {
          case BubbleSideMode.above:
            // `--tx` is the tail's middle along the bubble; the dark triangle starts at the border's outer edge
            return Stack(
              clipBehavior: Clip.none,
              children: [
                PositionedDirectional(
                  start: (p.tail ?? c.maxWidth / 2) - 8,
                  bottom: -11,
                  child: const CustomPaint(
                    size: Size(16, 9),
                    painter: _TailPainter(BubbleSideMode.above),
                  ),
                ),
              ],
            );
          case BubbleSideMode.right:
            return Stack(
              clipBehavior: Clip.none,
              children: [
                PositionedDirectional(
                  start: -11,
                  top: c.maxHeight / 2 - 8,
                  child: const CustomPaint(
                    size: Size(9, 16),
                    painter: _TailPainter(BubbleSideMode.right),
                  ),
                ),
              ],
            );
          case BubbleSideMode.left:
            return Stack(
              clipBehavior: Clip.none,
              children: [
                PositionedDirectional(
                  end: -11,
                  top: c.maxHeight / 2 - 8,
                  child: const CustomPaint(
                    size: Size(9, 16),
                    painter: _TailPainter(BubbleSideMode.left),
                  ),
                ),
              ],
            );
        }
      },
    ),
  );
}

class _BubbleDelegate extends SingleChildLayoutDelegate {
  _BubbleDelegate(this.placementFor, this.sideMax);

  final BubblePlacement? Function(Size bubble) placementFor;
  final double? sideMax;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      BoxConstraints(maxWidth: sideMax ?? constraints.maxWidth * .72);

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final p = placementFor(childSize);
    if (p == null) return Offset(-10000, -10000);
    switch (p.mode) {
      // `#bub.on`: translate(-50%, calc(-100% - 10px)); `.der`: translate(0, -50%); `.izq`: translate(-100%, -50%)
      case BubbleSideMode.above:
        return Offset(
          p.left - childSize.width / 2,
          p.top - childSize.height - 10,
        );
      case BubbleSideMode.right:
        return Offset(p.left, p.top - childSize.height / 2);
      case BubbleSideMode.left:
        return Offset(p.left - childSize.width, p.top - childSize.height / 2);
    }
  }

  @override
  bool shouldRelayout(_BubbleDelegate old) => true;
}

/// The widest a bubble can be: `max-width:72%` of the stage, or the room beside the frog.
double bubbleMaxWidth(double stageWidth, BubblePlacement? p) =>
    p?.maxWidth ?? math.max(0, stageWidth * .72);
