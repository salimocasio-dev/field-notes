/// The lesson frame: the dark full-screen frame of a story, Repaso, the level
/// check, the book and the call (cual.html:11-111, index.html:11-111).
library;

import 'package:coqui_ui/src/buttons.dart';
import 'package:coqui_ui/src/icons.dart';
import 'package:coqui_ui/src/pressable.dart';
import 'package:coqui_ui/src/layout.dart';
import 'package:coqui_ui/src/text_styles.dart';
import 'package:coqui_ui/src/tokens.dart';
import 'package:material_ui/material_ui.dart';

/// `#bar`: the progress as dashes, one per step: 6 px high, 3 px corners, 4 px
/// apart, grey (`#3A3A42`), green as the learner goes. With [dense] (many steps)
/// the dashes are 1 px apart with 1 px corners (`#bar.many`). The bar is at most
/// 480 px wide. cual.html:19-23
class LessonProgressDashes extends StatelessWidget {
  const LessonProgressDashes({
    super.key,
    required this.segments,
    required this.done,
    this.dense = false,
  });

  /// How many dashes.
  final int segments;

  /// How many are green (from the left).
  final int done;
  final bool dense;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Progress',
    value: '$done of $segments',
    excludeSemantics: true,
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: CoquiMetrics.lessonBarMax),
        child: Row(
          children: [
            for (var i = 0; i < segments; i++) ...[
              if (i > 0) SizedBox(width: dense ? 1 : 4),
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: CoquiMetrics.dotHeight,
                  decoration: BoxDecoration(
                    color: i < done
                        ? CoquiColors.lessonGreen
                        : CoquiColors.dotOff,
                    borderRadius: BorderRadius.circular(dense ? 1 : 3),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

/// `.lbbar`: the book's thin progress bar: one 6 px grey line with a green part,
/// [value] of the way (0 to 1), at most 480 px wide. app.html:109
class LessonProgressLine extends StatelessWidget {
  const LessonProgressLine({super.key, required this.value});
  final double value;

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: CoquiMetrics.lessonBarMax),
      child: Container(
        height: CoquiMetrics.dotHeight,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: CoquiColors.dotOff,
          borderRadius: BorderRadius.circular(3),
        ),
        alignment: Alignment.centerLeft,
        child: AnimatedFractionallySizedBox(
          duration: const Duration(milliseconds: 200),
          widthFactor: value.clamp(0.0, 1.0),
          heightFactor: 1,
          child: const ColoredBox(color: CoquiColors.lessonGreen),
        ),
      ),
    ),
  );
}

/// The frame of every lesson screen.
///
/// A calm dark grey (`#1B1B1F`) over the whole screen. A top bar 56 px high
/// (+ the safe area): the close X at the left (48 px), the [progress] in the
/// middle, and at the right the sound button, or [trailing] (the book's page
/// count and "Aa", the call's timer). Under it the [picture], centred in the
/// space above the bottom zone (112 px: the start disc and the 40 px under it),
/// its [caption] hanging 8 px under it, 18/24 medium white, centred, two lines at
/// most. The [bottom] zone sits at the foot: its widgets are centred, 16 px
/// apart, with 24 px under the last (+ the safe area). An [overlay] (a start or
/// end screen) covers the picture area and stays under the bottom zone.
///
/// On a phone on its side (`@media (orientation:landscape) and (max-height:600px)`)
/// the picture stands alone at the left, 16 px from the edges, and the top bar,
/// caption and bottom zone form a column at the right. cual.html:11-35, 51-52, 97-111
class LessonFrame extends StatelessWidget {
  const LessonFrame({
    super.key,
    this.onClose,
    this.showClose = true,
    this.progress,
    this.onSound,
    this.muted = false,
    this.showSound = true,
    this.trailing,
    this.picture,
    this.caption,
    this.bottom = const [],
    this.overlay,
    this.startState = false,
  });

  /// The close X. Null with [showClose]: still drawn, doing nothing.
  final VoidCallback? onClose;

  /// False: the X keeps its room but is not shown (`visibility:hidden`, the end of a Repaso).
  final bool showClose;

  /// [LessonProgressDashes] or [LessonProgressLine]; or nothing.
  final Widget? progress;

  /// The sound button's callback and state.
  final VoidCallback? onSound;
  final bool muted;

  /// False: the sound button keeps its room but is not shown.
  final bool showSound;

  /// Replaces the sound button (a page count and "Aa", a timer).
  final Widget? trailing;

  /// The picture area's content (a `PixelView`). It is given the room between the
  /// side margins (16 px) and may be as wide as that.
  final Widget? picture;

  /// The line under the picture. Null: none.
  final String? caption;

  /// What stands in the bottom zone: [LessonStartButton], [LessonButton]s.
  final List<Widget> bottom;

  /// A start or end screen over the picture area.
  final Widget? overlay;

  /// On its side, the bottom zone is centred in the column while the lesson has
  /// not begun (`#app[data-s=start] #foot`). cual.html:109
  final bool startState;

  @override
  Widget build(BuildContext context) {
    final landscape = CoquiLayout.lessonLandscape(context);
    final safe = MediaQuery.paddingOf(context);
    return ColoredBox(
      color: CoquiColors.lessonBg,
      child: Padding(
        padding: EdgeInsets.only(
          left: safe.left,
          right: safe.right,
          bottom: safe.bottom,
          top: landscape ? safe.top : 0,
        ),
        child: landscape ? _landscape(context) : _portrait(context, safe.top),
      ),
    );
  }

  Widget _topBar({required double safeTop, required double height}) => SizedBox(
    height: height + safeTop,
    child: Padding(
      padding: EdgeInsets.fromLTRB(8, safeTop, 8, 0),
      child: Row(
        children: [
          Visibility(
            visible: showClose,
            maintainSize: true,
            maintainAnimation: true,
            maintainState: true,
            child: LessonCloseButton(onPressed: onClose),
          ),
          const SizedBox(width: CoquiMetrics.s16),
          Expanded(child: progress ?? const SizedBox.shrink()),
          const SizedBox(width: CoquiMetrics.s16),
          trailing ??
              Visibility(
                visible: showSound,
                maintainSize: true,
                maintainAnimation: true,
                maintainState: true,
                child: LessonSoundButton(onPressed: onSound, muted: muted),
              ),
        ],
      ),
    ),
  );

  /// The picture with its caption hanging under it: the caption has no height of
  /// its own, so the picture alone is what gets centred. cual.html:30-33
  Widget _stage() => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      ?picture,
      SizedBox(
        height: 0,
        width: double.infinity,
        child: OverflowBox(
          alignment: Alignment.topCenter,
          minHeight: 0,
          maxHeight: 56,
          child: Padding(
            padding: const EdgeInsets.only(top: CoquiMetrics.s8),
            child: AnimatedOpacity(
              opacity: caption == null || caption!.isEmpty ? 0 : 1,
              duration: const Duration(milliseconds: 120),
              child: Text(
                caption ?? '',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: CoquiText.lessonCaption,
              ),
            ),
          ),
        ),
      ),
    ],
  );

  Widget _foot({required EdgeInsets padding}) => Padding(
    padding: padding,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        for (var i = 0; i < bottom.length; i++) ...[
          if (i > 0) const SizedBox(height: CoquiMetrics.s16),
          bottom[i],
        ],
      ],
    ),
  );

  Widget _portrait(BuildContext context, double safeTop) => Column(
    children: [
      _topBar(safeTop: safeTop, height: CoquiMetrics.lessonTopBar),
      Expanded(
        child: Stack(
          fit: StackFit.expand,
          children: [
            Padding(
              padding: const EdgeInsets.only(
                left: CoquiMetrics.s16,
                right: CoquiMetrics.s16,
                bottom: CoquiMetrics.lessonFootReserve,
              ),
              child: Center(child: _stage()),
            ),
            ?overlay,
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _foot(
                padding: const EdgeInsets.fromLTRB(
                  CoquiMetrics.s16,
                  0,
                  CoquiMetrics.s16,
                  CoquiMetrics.s24,
                ),
              ),
            ),
          ],
        ),
      ),
    ],
  );

  Widget _landscape(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return Row(
      children: [
        Padding(
          padding: const EdgeInsets.all(CoquiMetrics.s16),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: width * 0.5),
              child: picture ?? const SizedBox.shrink(),
            ),
          ),
        ),
        Expanded(
          child: Column(
            children: [
              _topBar(safeTop: 0, height: CoquiMetrics.lessonTopBar),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: CoquiMetrics.s16),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Center(
                        child: Text(
                          caption ?? '',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: CoquiText.lessonCaption,
                        ),
                      ),
                      ?overlay,
                      if (startState)
                        Center(child: _foot(padding: EdgeInsets.zero))
                      else
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: _foot(
                            padding: const EdgeInsets.only(
                              bottom: CoquiMetrics.s16,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The frame of the book reader (`#libro`): the same dark frame as [LessonFrame], laid out for a page of
/// reading. A top bar (close X, a thin [progress] line, the page [count] "3 / 9", the text size button
/// [trailing]); the [picture] centred in the room that is left; the [lines] under it (gap 4,
/// at most 55% of the screen's height, scrolling); the [foot] (a [LessonButtonRow], "Fin") at the bottom,
/// 8 px above, 16 at the sides and below, 8 apart. Everything is at most 560 px wide and centred. The
/// last page ([last]) takes no extra room under the picture for its "Fin" (the other pages keep 72 px,
/// so the picture stands in the same place on every page). app.html:103-123
class LessonReaderFrame extends StatelessWidget {
  const LessonReaderFrame({
    super.key,
    this.onClose,
    this.progress,
    this.count,
    this.trailing,
    this.picture,
    this.lines = const [],
    this.foot = const [],
    this.last = false,
  });

  final VoidCallback? onClose;
  final Widget? progress;

  /// The page count, e.g. `3 / 9`.
  final String? count;

  /// The text size button ([LessonTextSizeButton]).
  final Widget? trailing;
  final Widget? picture;

  /// [BookLine]s.
  final List<Widget> lines;
  final List<Widget> foot;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final safe = MediaQuery.paddingOf(context);
    return ColoredBox(
      color: CoquiColors.lessonBg,
      child: Padding(
        padding: EdgeInsets.only(
          left: safe.left,
          right: safe.right,
          bottom: safe.bottom,
        ),
        child: Column(
          children: [
            SizedBox(
              height: CoquiMetrics.lessonTopBar + safe.top,
              child: Padding(
                padding: EdgeInsets.fromLTRB(8, safe.top, 8, 0),
                child: Row(
                  children: [
                    LessonCloseButton(onPressed: onClose),
                    const SizedBox(width: CoquiMetrics.s16),
                    Expanded(child: progress ?? const SizedBox.shrink()),
                    if (count != null) ...[
                      const SizedBox(width: CoquiMetrics.s16),
                      ConstrainedBox(
                        constraints: const BoxConstraints(minWidth: 40),
                        child: Text(
                          count!,
                          textAlign: TextAlign.right,
                          style: CoquiText.lessonCount,
                        ),
                      ),
                    ],
                    if (trailing != null) ...[
                      const SizedBox(width: CoquiMetrics.s16),
                      trailing!,
                    ],
                  ],
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: CoquiMetrics.readerColumnMax,
                  ),
                  child: LayoutBuilder(
                    builder: (context, box) => Column(
                      children: [
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(
                              CoquiMetrics.s16,
                              CoquiMetrics.s8,
                              CoquiMetrics.s16,
                              CoquiMetrics.s8 + (last ? 0 : 72),
                            ),
                            child: Center(child: picture),
                          ),
                        ),
                        ConstrainedBox(
                          constraints: BoxConstraints(
                            maxHeight: box.maxHeight * 0.55,
                          ),
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                for (var i = 0; i < lines.length; i++) ...[
                                  if (i > 0) const SizedBox(height: 4),
                                  lines[i],
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: CoquiMetrics.readerColumnMax,
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var i = 0; i < foot.length; i++) ...[
                        if (i > 0) const SizedBox(height: 8),
                        foot[i],
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// `.lbfin`: "Fin" above the last page's buttons: 24/32 semibold white, centred, 16 px above and below.
/// app.html:121
class LessonFin extends StatelessWidget {
  const LessonFin(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: CoquiMetrics.s16),
    child: Text(text, textAlign: TextAlign.center, style: CoquiText.lessonFin),
  );
}

/// `.lbl`: one line of a book: at least 48 px high, 12 px corners, padding 9 / 12, the text 20 on 30 (24 on
/// 36 with [big]) white, a speaker glyph (20 px in a 24 px box, `#9A9AA6`) at the right, 12 px from the
/// text; an optional [who] label above (12/16 semibold). The line playing ([lit]) is `#245A3B` with a
/// 4 px `#3DDC84` bar down its left edge and a green speaker; a pressed line is `#2A2A32`. app.html:114-117
class BookLine extends StatelessWidget {
  const BookLine({
    super.key,
    required this.text,
    this.who,
    this.lit = false,
    this.big = false,
    this.onTap,
  });

  /// The line: a [Text] (or a [Text.rich] with the dotted words).
  final Widget text;
  final String? who;
  final bool lit;
  final bool big;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Pressable(
    onPressed: onTap,
    semanticsButton: onTap != null,
    builder: (context, pressed) {
      final body = Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 30),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (who != null) Text(who!, style: CoquiText.bookWho),
                    DefaultTextStyle(
                      style: big ? CoquiText.bookLineBig : CoquiText.bookLine,
                      child: text,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 24,
                height: 24,
                child: Center(
                  child: CoquiIcon(
                    CoquiIcons.volume,
                    size: 20,
                    color: lit
                        ? CoquiColors.bookLineLitBar
                        : CoquiColors.bookSpeaker,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
      final surface = lit
          ? CoquiColors.bookLineLit
          : (pressed ? CoquiColors.bookLinePressed : null);
      return ClipRRect(
        borderRadius: BorderRadius.circular(CoquiMetrics.radiusButton),
        child: lit
            ? Stack(
                children: [
                  const Positioned.fill(
                    child: ColoredBox(color: CoquiColors.bookLineLitBar),
                  ),
                  // The inset 4 px bar: the lit surface, 4 px to the right, rounded as the line is.
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: surface,
                        borderRadius: BorderRadius.circular(
                          CoquiMetrics.radiusButton,
                        ),
                      ),
                      child: body,
                    ),
                  ),
                ],
              )
            : ColoredBox(
                color: surface ?? const Color(0x00000000),
                child: body,
              ),
      );
    },
  );
}

/// How the ring round a [PictureChoice] shows the answer.
enum ChoiceRing {
  /// The plain 1.5 px frame, `--line`. cual.html:66
  none,

  /// A right answer: a 3 px green ring. cual.html:67
  right,

  /// A wrong answer: a 3 px red-orange ring. cual.html:68
  wrong,

  /// The touched one in the level check: a 3 px white ring. cual.html:69
  selected,
}

/// How a [PictureChoice] is dimmed.
enum ChoiceDim {
  none,

  /// Both pictures while the sentence plays: `rgba(6,14,28,.5)` over the picture. cual.js:39
  whileSentence,

  /// The picture that is not the answer: `rgba(6,14,28,.55)`. cual.js:39
  unchosen,
}

/// One picture of the choice in Repaso and the level check (`.opt`): the picture in a frame that is a
/// ring outside its box (1.5 px `--line`; 3 px green, red-orange or white to show an answer), a dim over
/// the picture, and the check badge of a right answer. The ring takes no room. cual.html:49, 66-69; cual.js:39
///
/// The badge ([check]) is a 28 px green circle with a white tick (the 28 px SVG, stroke 3) and a 2 px
/// white ring outside it, 8 px from the picture's top and right edges. cual.html:49
class PictureChoice extends StatelessWidget {
  const PictureChoice({
    super.key,
    required this.child,
    this.ring = ChoiceRing.none,
    this.dim = ChoiceDim.none,
    this.check = false,
    this.onTap,
    this.semanticLabel,
  });

  final Widget child;
  final ChoiceRing ring;
  final ChoiceDim dim;
  final bool check;
  final VoidCallback? onTap;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final (color, width) = switch (ring) {
      ChoiceRing.none => (CoquiColors.lessonLine, 1.5),
      ChoiceRing.right => (CoquiColors.lessonGreen, 3.0),
      ChoiceRing.wrong => (CoquiColors.lessonBad, 3.0),
      ChoiceRing.selected => (CoquiColors.optionSelected, 3.0),
    };
    final dimColor = switch (dim) {
      ChoiceDim.none => null,
      ChoiceDim.whileSentence => CoquiColors.optionDimWhileSentence,
      ChoiceDim.unchosen => CoquiColors.optionDimUnchosen,
    };
    final picture = Stack(
      clipBehavior: Clip.none,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            boxShadow: [BoxShadow(color: color, spreadRadius: width)],
          ),
          child: Stack(
            children: [
              child,
              if (dimColor != null)
                Positioned.fill(child: ColoredBox(color: dimColor)),
            ],
          ),
        ),
        if (check)
          Positioned(
            right: CoquiMetrics.badgeInset,
            top: CoquiMetrics.badgeInset,
            child: Container(
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
            ),
          ),
      ],
    );
    if (onTap == null) return picture;
    return Pressable(
      onPressed: onTap,
      semanticLabel: semanticLabel,
      builder: (context, pressed) => picture,
    );
  }
}
