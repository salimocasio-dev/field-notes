/// The lesson frame: the dark full-screen frame of a story, Repaso, the level
/// check, the book and the call (cual.html:11-111, index.html:11-111).
library;

import 'dart:math' as math;

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
    this.missed = const {},
  });

  /// How many dashes.
  final int segments;

  /// How many are green (from the left).
  final int done;
  final bool dense;

  /// Dashes (by place, from 0) that are red-orange, not green or grey: a Repaso item that was missed and has not yet
  /// been answered when it came back. Shown whether or not [done] reaches them.
  final Set<int> missed;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Progress',
    value: missed.isEmpty
        ? '$done of $segments'
        : '$done of $segments, ${missed.length} to come back',
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
                    color: missed.contains(i)
                        ? CoquiColors.lessonBad
                        : i < done
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
    this.underPicture,
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

  /// A story's end: the title (24 px semibold, left) hangs 16 px under the picture, wherever the picture
  /// stands: the frame places it from the picture's own bottom edge, not from a fixed place, so it is the
  /// same 16 px under the picture on a tall phone and on a short one (`finFit()`, juego.js:391-395; the
  /// picture is centred above the bottom zone and stays where it was). It is at most 480 px wide, in the
  /// 16 px side margins. The old page drops it when it does not fit between the picture and the buttons;
  /// that check needs the height of the buttons, so the caller that can run into it makes it (feature_story's
  /// `StoryEndTitle` does). Null: none.
  final Widget? underPicture;

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

  /// The picture with its caption (8 px under it) and a story's end title ([underPicture], 16 px under it)
  /// hanging under it: neither has a height of its own, so the picture alone is what gets centred.
  /// cual.html:30-33; juego.js:391-395
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
      if (underPicture != null)
        SizedBox(
          height: 0,
          width: double.infinity,
          child: OverflowBox(
            alignment: Alignment.topCenter,
            minHeight: 0,
            maxHeight: double.infinity,
            child: Padding(
              padding: const EdgeInsets.only(top: CoquiMetrics.s16),
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: CoquiMetrics.lessonColumnMax,
                  ),
                  child: SizedBox(width: double.infinity, child: underPicture),
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
    this.cross = false,
    this.onTap,
    this.semanticLabel,
  });

  final Widget child;
  final ChoiceRing ring;
  final ChoiceDim dim;

  /// The check badge of a right touch, or (the same corner) the round X badge of a wrong one.
  final bool check;
  final bool cross;
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
          )
        else if (cross)
          const Positioned(
            right: CoquiMetrics.badgeInset,
            top: CoquiMetrics.badgeInset,
            child: WrongBadge(),
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

/// The round badge with an X that marks a wrong touch, where a right one has its check: 28 px red-orange with a
/// white X and a white ring (the twin of the check badge: the same size, the same ring).
class WrongBadge extends StatelessWidget {
  const WrongBadge({super.key});

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Wrong',
    excludeSemantics: true,
    child: Container(
      width: CoquiMetrics.badgeSize,
      height: CoquiMetrics.badgeSize,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: CoquiColors.lessonBad,
        boxShadow: [
          BoxShadow(
            color: CoquiColors.lessonInk,
            spreadRadius: CoquiMetrics.badgeRing,
          ),
        ],
      ),
      child: const CoquiIcon(
        CoquiIcons.badgeCross,
        size: CoquiMetrics.badgeSize,
        color: CoquiColors.lessonInk,
      ),
    ),
  );
}

/// How the end of a Repaso lays out the pictures of its words: [columns] to a row at a whole number
/// [scale] of device pixels per picture pixel, each picture [cellWidth] logical pixels wide. cual.js:
/// `cualGrid()` (cual.js:60-65).
class LessonGridPlan {
  const LessonGridPlan({
    required this.columns,
    required this.scale,
    required this.cellWidth,
  });

  final int columns;

  /// Device pixels per picture pixel: a whole number, never below 1.
  final int scale;

  /// A cell, and so its picture, as wide as `pictureWidth * scale / devicePixelRatio`.
  final double cellWidth;

  /// `gap:16px` between the cells, across and down. cual.html:46
  static const double gap = 16;

  /// The grid, and the title and lines above it, are one block this wide, centred
  /// (`#fin.lis>*{max-width:var(--gw)}`, `--gw` set by `cualGrid()`). cual.html:41
  double get blockWidth => columns * cellWidth + (columns - 1) * gap;
}

/// `cualGrid()` (cual.js:60-65): three or two pictures to a row, at the largest whole scale that fits;
/// a tie goes to three; a picture is at most about 140 px wide (`top`: the words are small things to look
/// at, ten fit a screen); where not even two fit at scale 1, one to a row.
///
/// [contentWidth] is the width of the end screen inside its 16 px side padding (`#fin`'s `clientWidth`
/// minus its padding), [pictureWidth] the art's width in picture pixels (`DW`, 196).
LessonGridPlan lessonGridPlan({
  required double contentWidth,
  required double devicePixelRatio,
  required int pictureWidth,
}) {
  final w = math.min(CoquiMetrics.lessonColumnMax, contentWidth);
  final top = math.max(
    1,
    (140 * devicePixelRatio / pictureWidth + .001).floor(),
  );
  int? columns;
  int? scale;
  for (final n in const [3, 2]) {
    final fit =
        (((w - (n - 1) * LessonGridPlan.gap) / n) *
                    devicePixelRatio /
                    pictureWidth +
                .001)
            .floor();
    final kd = math.min(top, fit);
    if (kd >= 1 && (scale == null || kd > scale)) {
      columns = n;
      scale = kd;
    }
  }
  final kd = scale ?? 1;
  return LessonGridPlan(
    columns: columns ?? 1,
    scale: kd,
    cellWidth: pictureWidth * kd / devicePixelRatio,
  );
}

/// One word of the end screen's grid: its [picture] (a [PixelView] as wide as its cell: it draws itself
/// at the plan's whole scale) and the [word] under it.
class LessonGridCell {
  const LessonGridCell({required this.picture, required this.word});
  final Widget picture;
  final String word;
}

/// `.gw`: the words of a group, each a picture in a 1.5 px ring (`box-shadow:0 0 0 1.5px var(--line)`: a
/// ring outside the picture that takes no room) and the word under it, 8 px below, 16/24 white; the cells
/// [LessonGridPlan.gap] apart. The widget is [LessonGridPlan.blockWidth] wide; the picture of a cell
/// is exactly as wide as its cell, so at the plan's scale it fills it, with no strip. cual.html:46-50
class LessonPictureGrid extends StatelessWidget {
  const LessonPictureGrid({super.key, required this.plan, required this.cells});

  final LessonGridPlan plan;
  final List<LessonGridCell> cells;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: plan.blockWidth,
    child: Wrap(
      spacing: LessonGridPlan.gap,
      runSpacing: LessonGridPlan.gap,
      children: [
        for (final cell in cells)
          SizedBox(
            width: plan.cellWidth,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DecoratedBox(
                  decoration: const BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: CoquiColors.lessonLine,
                        spreadRadius: 1.5,
                      ),
                    ],
                  ),
                  child: SizedBox(width: plan.cellWidth, child: cell.picture),
                ),
                const SizedBox(height: CoquiMetrics.s8),
                Text(cell.word, style: CoquiText.lessonWord),
              ],
            ),
          ),
      ],
    ),
  );
}
