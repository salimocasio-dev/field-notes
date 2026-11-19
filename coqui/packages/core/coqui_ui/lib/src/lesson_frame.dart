/// The lesson frame: the dark full-screen frame of a story, Repaso, the level
/// check, the book and the call (cual.html:11-111, index.html:11-111).
library;

import 'package:coqui_ui/src/buttons.dart';
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
