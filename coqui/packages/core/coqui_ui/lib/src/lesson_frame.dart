/// Lesson choice/progress enums and legacy picture-choice pieces still
/// referenced by `feature_review` and `coqui/app/tool/repaso_shots_test.dart`.
///
/// Unused v=39 frame widgets (`LessonFrame`, `LessonProgressDashes`,
/// `LessonProgressLine`, `LessonFin`, `LessonGridPlan`, `lessonGridPlan`,
/// `LessonGridCell`, `LessonPictureGrid`) were removed in N1.4 (#82).
library;

import 'package:coqui_ui/src/icons.dart';
import 'package:coqui_ui/src/pressable.dart';
import 'package:coqui_ui/src/tokens.dart';
import 'package:material_ui/material_ui.dart';

/// What a dash of Repaso's bar says about its item (the result of that item's first answer).
enum DashMark {
  /// Not reached yet.
  none,

  /// The first answer was right.
  right,

  /// The first answer was wrong.
  wrong,

  /// Skipped, not answered at all.
  skipped,
}

/// How the ring round a choice shows the answer.
enum ChoiceRing {
  /// Plain frame.
  none,

  /// A right answer.
  right,

  /// A wrong answer.
  wrong,

  /// The touched one in the level check.
  selected,
}

/// How a choice is dimmed.
enum ChoiceDim {
  none,

  /// Both pictures while the sentence plays.
  whileSentence,

  /// The picture that is not the answer.
  unchosen,
}

/// Legacy picture choice widget still referenced by `app/tool/repaso_shots_test.dart`.
class PictureChoice extends StatelessWidget {
  const PictureChoice({
    super.key,
    required this.child,
    this.ring = ChoiceRing.none,
    this.dim = ChoiceDim.none,
    this.check = false,
    this.cross = false,
    this.inside = false,
    this.onTap,
    this.semanticLabel,
  });

  final Widget child;
  final ChoiceRing ring;
  final ChoiceDim dim;
  final bool inside;
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
        if (inside)
          Stack(
            children: [
              child,
              if (dimColor != null)
                Positioned.fill(child: ColoredBox(color: dimColor)),
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.all(color: color, width: width),
                    ),
                  ),
                ),
              ),
            ],
          )
        else
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
          const PositionedDirectional(
            end: CoquiMetrics.badgeInset,
            top: CoquiMetrics.badgeInset,
            child: CheckBadge(),
          )
        else if (cross)
          const PositionedDirectional(
            end: CoquiMetrics.badgeInset,
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

/// The check badge of a right answer: 28 px green with a white tick and a white ring.
class CheckBadge extends StatelessWidget {
  const CheckBadge({super.key});

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

/// The round badge with an X that marks a wrong touch on legacy tiles.
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
